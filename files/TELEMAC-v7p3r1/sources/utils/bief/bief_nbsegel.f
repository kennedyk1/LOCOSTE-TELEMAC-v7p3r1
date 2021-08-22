!                    *****************************
                     INTEGER FUNCTION BIEF_NBSEGEL
!                    *****************************
!
     &(IELM,MESH)
!
!***********************************************************************
! BIEF   V7P3
!***********************************************************************
!
!brief    GIVES THE NUMBER OF SEGMENTS PER ELEMENT
!+                FOR EACH TYPE OF ELEMENT.
!
!history  J-M HERVOUET (LNH)
!+        08/04/2004
!+        V5P5
!+   Adding argument MESH.
!
!history  N.DURAND (HRW), S.E.BOURBAN (HRW)
!+        13/07/2010
!+        V6P0
!+   Translation of French comments within the FORTRAN sources into
!+   English comments.
!
!history  N.DURAND (HRW), S.E.BOURBAN (HRW)
!+        21/08/2010
!+        V6P0
!+   Creation of DOXYGEN tags for automated documentation and
!+   cross-referencing of the FORTRAN sources.
!
!history  J-M HERVOUET (LNH)
!+        23/09/2017
!+        V7P3
!+   Removing argument REFINE added in version 7.2.
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
 200    FORMAT(1X,'BIEF_NBSEGEL : MAUVAIS ARGUMENT : ',1I6)
 201    FORMAT(1X,'BIEF_NBSEGEL: WRONG ARGUMENT: ',1I6)
        CALL PLANTE(1)
        STOP
      ELSE
        BIEF_NBSEGEL = MESH%NDS(IELM,6)
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
      END
