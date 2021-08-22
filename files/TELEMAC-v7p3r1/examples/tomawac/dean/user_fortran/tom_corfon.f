!                    *****************
                     SUBROUTINE TOM_CORFON
!                    *****************
!
!
!***********************************************************************
! TOMAWAC   V6P1                                   14/06/2011
!***********************************************************************
!
!brief    MODIFIES THE BOTTOM TOPOGRAPHY.
!
!warning  USER SUBROUTINE; MUST BE CODED BY THE USER
!
!history  F. MARCOS
!+
!+
!+
!
!history  OPTIMER (    )
!+        12/01/2001
!+
!+   TOMAWAC/COWADIS MERGE
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
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TOMAWAC
!
      USE DECLARATIONS_SPECIAL
      IMPLICIT NONE
!
!
!
!VB---------------------------------MODIF Dean, 1991
      INTEGER IP
!
      DO IP=1,NPOIN2
!        ZF(IP) = -5.D0
        ZF(IP) = - 0.25D0*(300.D0 - X(IP))**(2./3.)
      ENDDO
!VB---------------------------------MODIF fin
!
!
      RETURN
      END

