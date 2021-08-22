!                    ***************************
                     INTEGER FUNCTION BIEF_NBFEL
!                    ***************************
!
     &(IELM,MESH)
!
!***********************************************************************
! BIEF   V6P1                                   21/08/2010
!***********************************************************************
!
!brief    GIVES THE NUMBER OF SIDES PER ELEMENT,
!+                3 FOR A TRIANGLE FOR EXAMPLE.
!
!history  J-M HERVOUET (LNH)
!+        08/04/04
!+        V5P5
!+
!
!history  N.DURAND (HRW), S.E.BOURBAN (HRW)
!+        13/07/2010
!+        V6P0
!+   Translation of French comments within the FORTRAN sources into
!+   English comments
!
!history  N.DURAND (HRW), S.E.BOURBAN (HRW)
!+        21/08/2010
!+        V6P0
!+   Creation of DOXYGEN tags for automated documentation and
!+   cross-referencing of the FORTRAN sources
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| IELM           |-->| TYPE OF ELEMENT
!| MESH           |-->| MESH STRUCTURE
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF_DEF
      USE DECLARATIONS_SPECIAL
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)         :: IELM
      TYPE(BIEF_MESH), INTENT(IN) :: MESH
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      IF(IELM.LT.0.OR.IELM.GT.81) THEN
        IF(LNG.EQ.1) WRITE(LU,200) IELM
        IF(LNG.EQ.2) WRITE(LU,201) IELM
 200    FORMAT(1X,'BIEF_NBFEL : MAUVAIS ARGUMENT : ',1I6)
 201    FORMAT(1X,'BIEF_NBFEL: WRONG ARGUMENT: ',1I6)
        CALL PLANTE(1)
        STOP
      ENDIF
!
      BIEF_NBFEL = MESH%NDS(IELM,4)
!
!-----------------------------------------------------------------------
!
      RETURN
      END