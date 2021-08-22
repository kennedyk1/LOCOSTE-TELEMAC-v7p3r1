!                       *****************************
                        DOUBLE PRECISION FUNCTION FC1
!                       *****************************
!
     &(X)
!
!***********************************************************************
! PROGICIEL : TELEMAC        07/12/88    J-M HERVOUET (LNH) 30 71 80 18
!
!***********************************************************************
!
!  FONCTION  : CALCULE UN POLYNOME DU TROISIEME DEGRE
!
!-----------------------------------------------------------------------
!                             ARGUMENTS
! .________________.____.______________________________________________
! |      NOM       |MODE|                   ROLE
! |________________|____|______________________________________________
! |   X            | -->| ARGUMENT DE LA FONCTION.
! |________________|____|______________________________________________
! MODE : -->(DONNEE NON MODIFIEE), <--(RESULTAT), <-->(DONNEE MODIFIEE)
!***********************************************************************
!
      USE DECLARATIONS_SPECIAL
      IMPLICIT NONE
!
      DOUBLE PRECISION A(4),X
!
      COMMON/FORFC1/A
!
!-----------------------------------------------------------------------
!
      FC1 = A(1)*X**3 + A(2)*X**2 + A(3)*X + A(4)
!
!-----------------------------------------------------------------------
!
      RETURN
      END
