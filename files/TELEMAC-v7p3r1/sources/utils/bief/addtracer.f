!                     **************************
                         SUBROUTINE ADDTRACER
!                     **************************
!
     &  (NAMETRAC,MTRAC,ITRAC,NAME1,NAME2,UNIT0)
!
!
!***********************************************************************
! BIEF      V7P3
!***********************************************************************
!
!brief    adds tracer to the existing list of tracers
!
!        Re-working NAMETRAC to avoid conflicting naming convention
!        between user defined tracers, water quality processes and
!        ice processes.
!
!history  S.E. BOURBAN (HRW)
!+        07/06/2017
!+        V7P3
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| ITRAC          |<->| FINAL INDEX OF THE TRACER
!| MTRAC          |<->| TOTAL NUMBER OF TRACERS, COULD VARY HERE
!| NAME1,NAME2    |-->| NAMES IN FRENCH AND ENGLISH OF THE TRACER TO ADD
!| NAMETRAC       |<->| TABLE CONTAINING TRACERS' NAMES
!| UNIT0          |-->| UNIT OF THE TRACER TO ADD
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_SPECIAL
      USE BIEF, EX_ADDTRACER => ADDTRACER
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
!
      INTEGER,           INTENT(INOUT):: MTRAC,ITRAC
      CHARACTER(LEN=32), INTENT(INOUT):: NAMETRAC(*)
      CHARACTER(LEN=16), INTENT(IN)   :: NAME1,NAME2,UNIT0
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
!-----------------------------------------------------------------------
      INTEGER :: I
!-----------------------------------------------------------------------
      ITRAC = 0
      DO I = 1,MTRAC
        IF( NAMETRAC(I)(1:16) .EQ. NAME1 ) THEN
          ITRAC = I
        ELSEIF( NAMETRAC(I)(1:16) .EQ. NAME2 ) THEN
          ITRAC = I
        ENDIF
      ENDDO
      IF( ITRAC.EQ.0 ) THEN
        MTRAC = MTRAC + 1
        ITRAC = MTRAC
        IF(LNG.EQ.1)THEN
          NAMETRAC(ITRAC) = NAME1 // UNIT0
        ELSE
          NAMETRAC(ITRAC) = NAME2 // UNIT0
        ENDIF
      ENDIF
!-----------------------------------------------------------------------
      RETURN
      END SUBROUTINE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!