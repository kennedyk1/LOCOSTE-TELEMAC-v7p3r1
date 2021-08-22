!                       *****************
                        SUBROUTINE NOEROD
!                       *****************
!
     & (H , ZF , ZR , Z , X , Y , NPOIN , CHOIX , NLISS )
!
!***********************************************************************
! SISYPHE VERSION 5.1                             C. LENORMANT
!
! COPYRIGHT EDF-DTMPL-SOGREAH-LHF-GRADIENT
!***********************************************************************
!
!     FONCTION  : IMPOSE LA VALEUR DE LA COTE DU FOND NON ERODABLE  ZR
!
!
!     RQ: LES METHODES DE TRAITEMENT DES FONDS NON ERODABLES PEUVENT CONDUIRE
!     A ZF < ZR A CERTAINS PAS DE TEMPS, POUR PALLIER A CELA ON PEUT CHOISIR
!     CHOISIR DE LISSER LA SOLUTION OBTENUE i.e NLISS > 0.
!
!     FUNCTION  : IMPOSE THE RIGID BED LEVEL  ZR
!
!-----------------------------------------------------------------------
!                             ARGUMENTS
! .________________.____.______________________________________________
! |      NOM       |MODE|                   ROLE
! |________________|____|______________________________________________
! |   H            | -->| WATER DEPTH
! |   ZF           | -->| BED LEVEL
! |   ZR           |<-- | RIGID BED LEVEL
! |   Z            | -->| FREE SURFACE
! |   X,Y          | -->| 2D COORDINATES
! |   NPOIN        | -->| NUMBER OF 2D POINTS
! |   CHOIX        | -->| SELECTED METHOD FOR THE TREATMENT OF RIGID BEDS
! |   NLISS        |<-->| NUMBER OF SMOOTHINGS
! |________________|____|______________________________________________
! MODE : -->(INPUT), <--(RESULT), <-->(MODIFIED DATA)
!-----------------------------------------------------------------------
!
      USE BIEF
      USE DECLARATIONS_SPECIAL
      IMPLICIT NONE
!
      INTEGER, INTENT(IN):: NPOIN , CHOIX
      INTEGER, INTENT(INOUT):: NLISS
!
      DOUBLE PRECISION, INTENT(IN)::  Z(NPOIN) , ZF(NPOIN)
      DOUBLE PRECISION , INTENT(IN)::  X(NPOIN) , Y(NPOIN), H(NPOIN)
      DOUBLE PRECISION , INTENT(INOUT)::  ZR(NPOIN)
!
!-----------------------------------------------------------------------
      INTEGER I
!
      INTEGER NPMAX2
      INTEGER ND
      INTEGER NG
!
! deja defini dans bief
!      PARAMETER (NPMAX=2000)
      PARAMETER (NPMAX2=200)
      DOUBLE PRECISION XD(NPMAX2),YD(NPMAX2)
      DOUBLE PRECISION XG(NPMAX2),YG(NPMAX2)
!--------------------
! RIGID BEDS POSITION
!---------------------
!
!       DEFAULT VALUE:       ZR=ZF-100
!
        CALL OV( 'X=Y+C     ',ZR,ZF,ZF,-1000.D0,NPOIN)
!
!------------------
! SMOOTHING OPTION
!------------------
!       NLISS : NUMBER OF SMOOTHING IF  (ZF - ZR ) NEGATIVE
!                DEFAULT VALUE : NLISS = 0 (NO SMOOTHING)
!
      NLISS = 0
      ND=17
!
      XD(01)=462.665
      YD(01)=1186.187
      XD(02)=449.843
      YD(02)=1184.821
      XD(03)=446.900
      YD(03)=1181.878
      XD(04)=463.611
      YD(04)=1148.455
      XD(05)=480.638
      YD(05)=1118.921
      XD(06)=494.617
      YD(06)=1098.005
      XD(07)=504.181
      YD(07)=1082.765
      XD(08)=511.854
      YD(08)=1070.783
      XD(09)=527.199
      YD(09)=1046.504
      XD(10)=544.331
      YD(10)=1017.811
      XD(11)=548.325
      YD(11)=1011.505
      XD(12)=552.529
      YD(12)=1004.358
      XD(13)=558.625
      YD(13)= 993.847
      XD(14)= 568.715
      YD(14)= 972.091
      XD(15)= 620.952
      YD(15)= 861.942
      XD(16)=627.468
      YD(16)= 869.615
      XD(17)= 652.378
      YD(17)= 934.779
!
      NG=13
!
      XG(01)=400.759
      YG(01)=1162.329
      XG(02)=413.372
      YG(02)=1166.112
      XG(03)=431.134
      YG(03)=1129.116
      XG(04)=481.584
      YG(04)=1031.474
      XG(05)=491.043
      YG(05)=1014.868
      XG(06)=494.407
      YG(06)=1008.667
      XG(07)=518.896
      YG(07)= 966.941
      XG(08)=530.142
      YG(08)= 948.232
      XG(09)=557.574
      YG(09)= 899.884
      XG(10)=567.559
      YG(10)= 880.230
      XG(11)=573.129
      YG(11)= 866.146
      XG(12)=581.538
      YG(12)= 844.915
      XG(13)=568.400
      YG(13)= 840.606
!
      DO I = 1 , NPOIN

        IF (INPOLY(X(I),Y(I),XD,YD,ND)) THEN
          ZR(I) = ZF(I)
          ENDIF

        IF (INPOLY(X(I),Y(I),XG,YG,NG)) THEN
          ZR(I) = ZF(I)
          ENDIF

      ENDDO
!
      RETURN
      END SUBROUTINE NOEROD

