!                      **************************
                       SUBROUTINE NAMETRAC_RICE2D
!                      **************************
!
     &  (NAMETRAC,NTRAC,PROCESS)
!
!
!***********************************************************************
! RICE2D      V7P3
!***********************************************************************
!
!brief    Gives names to tracers added by the ice modelling component
!
!history  F. HUANG (CLARKSON U.) AND S.E. BOURBAN (HRW)
!+        11/11/2016
!+        V7P3
!+        Coupling TELEMAC-2D with RICE-2D (ice modelling component)
!+        Initial developments
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| NAMETRAC       |<--| ARRAY OF NAMES OF TRACERS
!| NTRAC          |-->| MODIFYING NUMBER OF TRACER IF NECESARY
!| PROCESS        |-->| ALSO ICEPROCESS, DEFINES THE ICE PROCESSES
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_SPECIAL
      USE DECLARATIONS_RICE2D
!      USE INTERFACE_RICE2D, EX_NAMETRAC_RICE2D => NAMETRAC_RICE2D
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
!
      INTEGER          , INTENT(IN   )::  PROCESS
      INTEGER          , INTENT(INOUT)::  NTRAC
      CHARACTER(LEN=32), INTENT(INOUT)::  NAMETRAC(*)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER :: I
!     TODO: THIS SHOULD BE MOVED TO DECLARATIONS_RICE2D,
!     EVEN IF SOME ARE DUPLICATED IN TELEMAC
      INTEGER :: IND_F,IND_T
!
!-----------------------------------------------------------------------
!
      ICEPROCESS = PROCESS
      ICETR = 0
!
!       THERMAL BUDGET WITH FRAZIL PRODUCTION
!
      IF( 2*INT(ICEPROCESS/2) .EQ. ICEPROCESS ) THEN
!     1. ~~> FRAZIL
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_F,
     &      'FRASIL          ','FRAZIL          ','  mgIce/l       ')
!     2. ~~> TEMPERATURE
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_T,
     &      'TEMPERATURE     ','TEMPERATURE     ','   oC           ')
!
      ELSEIF( ICETR.EQ.0 .AND. ICEPROCESS.NE.1 ) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,10) ICEPROCESS
        ELSE
          WRITE(LU,20) ICEPROCESS
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!     MESSAGES
10    FORMAT(1X,'NAMETRAC_RICE2D: PROCESSUS DES GLACES INCONNU : ',I4)
20    FORMAT(1X,'NAMETRAC_RICE2D: UNKNOWN ICE PROCESS: ',I4)
!-----------------------------------------------------------------------
!
      RETURN
      CONTAINS
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
        SUBROUTINE ADDTRACER(NAMETRAC,MTRAC,ITRAC,NAME1,NAME2,UNIT0)
!-----------------------------------------------------------------------
        INTEGER,           INTENT(INOUT):: MTRAC,ITRAC
        CHARACTER(LEN=32), INTENT(INOUT):: NAMETRAC(*)
        CHARACTER(LEN=16) :: NAME1,NAME2,UNIT0
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
      END SUBROUTINE
