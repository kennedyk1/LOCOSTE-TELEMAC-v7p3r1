!                    ************************
                     SUBROUTINE SOURCE_RICE2D
!                    ************************
!
     &( NPOIN,NTRAC,IND_T,TEXP,TIMP,TN,HPROP,U,V,
     &  PLUIE,WINDX,WINDY,
     &  LATIT,LONGIT,DT,AT,MARDAT,MARTIM,DEBUG )
!
!***********************************************************************
! RICE-2D   V7P2                                             02/11/2016
!***********************************************************************
!
!brief    COMPUTES CONTRIBUTION TO TRACER SOURCE TERMS RESULTING
!+        FROM ICE PROCESSES.
!+        IN PARTICULAR (DEPENDING ON ICEPROCESS):
!+          #2.- THERMAL BALANCE
!+          #3.- ...
!
!history  F. HUANG (CLARKSON U.) AND S.E. BOURBAN (HRW)
!+        19/11/2016
!+        V7P2
!+        INITIAL DEVELOPMENTS
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| NPOIN      |-->| NUMBER OF NODES IN THE MESH
!| IND_T      |-->| TRACER INDEX FOR WATER TEMPERATURE
!| LONGIT     |-->| LONGITUTE OF ORIGIN POINT
!| LATIT      |-->| LATITUDE OF ORIGIN POINT
!| DT         |-->| TIME STEP
!| AT         |-->| TIME IN SECONDS
!| NTRAC      |-->| NUMBER OF TRACERS
!| TEXP       |<--| EXPLICIT SOURCE TERM.
!| TIMP       |<--| IMPLICIT SOURCE TERM.
!| TN         |-->| TRACERS AT TIME N
!| HPROP      |-->| PROPAGATION DEPTH
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_SPECIAL
      USE DECLARATIONS_WAQTEL, ONLY : RO0,CP_EAU,TAIR,TDEW,NEBU,VISBI
      USE DECLARATIONS_RICE2D, ONLY : PHCL,PHRI,PHPS,PHIB,PHIE,PHIH,
     &                          PHIP,PHIWI,SUMPH,ANFEM,TMELT,ICEPROCESS,
     &                          CV_F
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)            :: DEBUG,NPOIN,NTRAC
      INTEGER, INTENT(IN)            :: IND_T, MARDAT(3),MARTIM(3)
!
      DOUBLE PRECISION,INTENT(IN)    :: LATIT,LONGIT,DT,AT
!
      TYPE(BIEF_OBJ), INTENT(IN)     :: TN
      TYPE(BIEF_OBJ), INTENT(INOUT)  :: TEXP
      TYPE(BIEF_OBJ), INTENT(INOUT)  :: TIMP
      TYPE(BIEF_OBJ), INTENT(IN)     :: HPROP,U,V,PLUIE,WINDX,WINDY
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER                     :: I,CICE
      DOUBLE PRECISION, PARAMETER :: EPS=1.D-3
      DOUBLE PRECISION            :: CONSTSS
!      DOUBLE PRECISION            :: THERMIC
      DOUBLE PRECISION            :: DH,VELMAG,WDMAG,HWIN

      DOUBLE PRECISION :: TIM0,TAIR0,CLD0,TDEW0,VISB0,SNOW0,RAIN0,WIND0
!
      INTRINSIC MAX
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
! ICEPROCESS:
!    PRIME NUMBER DEFINING WHICH PROCESS IS SWITCHED ON:
!    - 2: THERMAL BALANCE
!    - 3:
!    - 0: ALL PROCESSES ABOVE BECAUSE N*INT(0/N) = 0
!    - 1: NONE OF THE PROCESSES BECAUSE N*INT(1/N) <> 1
!
!-----------------------------------------------------------------------
!
!     MAJORATED RADIATION
!
      CONSTSS = 1.D0/(RO0*CP_EAU)
!
! ~~>     INITIALISES ICE CONCENTRATION
!     TODO: MOVE THIS INTO A NEW SUBROUTINE
!
!        CALL OS('X=C     ', X=ANFEM, C=0.D0 )
!! TDEW, VISBI and PLUIE are coming with random value here
!! -> need to check their computation ...
!        !  input data from meteo.file   fbh 2016-12-14
!        !  define in meteo.file
!        CALL OS('X=C     ', X=TDEW, C=0.D0 )
!        CALL OS('X=C     ', X=VISBI, C=0.D0 )

!
!-----------------------------------------------------------------------
!
!       THERMAL BALANCE
      IF( INT(ICEPROCESS/2)*2 .EQ. ICEPROCESS ) THEN

        ! input weather data 2016-12-14 fbh
!        read(112,*) tim0,tair0,cld0,tdew0,visb0,snow0,rain0,wind0

        DO I = 1,NPOIN
! ~~>     WIND SPEED EFFECTS ON ICE
          WDMAG = SQRT(WINDX%R(I)**2 + WINDY%R(I)**2)
!         WDMAG = 0.0

          TAIR%R(I) =  -10.0  ! tair0
          TDEW%R(I) = 0.0  !tdew0
          NEBU =  0.0 ! cld0
          VISBI%R(I) = 0.0 !  visb0
          WDMAG = 0.0 ! wind0
          PLUIE%R(I) = 0.0 ! rain0
!          TN%ADR(IND_T)%P%R(I) = 1.0
! ~~>     OPEN WATER CONDITIONS
          CICE = 0
! ~~>     ICE COVER CONDITIONS
          IF( ANFEM%R(I).GT.0.D0 ) CICE = 1
!
!          PLUIE%R(I) = 0.0
!          NEBU = 10. ! cloud

          CALL THERMAL_RICE2D(TAIR%R(I),TN%ADR(IND_T)%P%R(I),TDEW%R(I),
     &         NEBU,VISBI%R(I),WDMAG,PLUIE%R(I),
     &         PHCL%R(I),PHRI%R(I),
     &         PHPS%R(I),PHIB%R(I),PHIE%R(I),PHIH%R(I),PHIP%R(I),
     &         CICE,DT,AT,MARDAT,MARTIM,SUMPH%R(I))
!          SUMPH%R(I) =
!     &      - ( -PHPS%R(I)+PHIB%R(I)+PHIE%R(I)+PHIH%R(I)+PHIP%R(I) )
!
!     EXPLICITE SOURCE TERM - HOW ABOUT IMPLICITE ?
!
          TEXP%ADR(IND_T)%P%R(I) =
     &    CONSTSS*SUMPH%R(I)*( 1.D0-ANFEM%R(I) ) / MAX(HPROP%R(I),EPS)
!
        ENDDO

!        !  output
!        write(111,'(10f15.6)')(AT/3600.),SUMPH%R(1),PHPS%R(1),PHIB%R(1),
!     &  PHIE%R(1),PHIH%R(1),PHIP%R(1),TN%ADR(IND_T)%P%R(1),
!     &  CV_F%R(1),TAIR%R(1)      ! TN%ADR(IND_T)%P%R(1)

        DO I=1,NPOIN

          VELMAG = SQRT(U%R(I)**2 + V%R(I)**2)
          IF (ANFEM%R(I).GT.0.5) THEN   ! consider ice effects
            DH = 2.0*HPROP%R(I)  ! subject to htmin, used to calc hwin
            CALL FHC_RICE2D(HWIN,DH,VELMAG,TN%ADR(IND_T)%P%R(I))
          ELSE   ! no ice effects
            DH = 4.0*HPROP%R(I)  ! subject to htmin, used to calc hwin
            CALL FHC_RICE2D(HWIN,DH,VELMAG,TN%ADR(IND_T)%P%R(I))
          ENDIF

          PHIWI%R(I) = -HWIN*(TN%ADR(IND_T)%P%R(I)-TMELT)

          TEXP%ADR(IND_T)%P%R(I) = TEXP%ADR(IND_T)%P%R(I) +
     &  CONSTSS*PHIWI%R(I)*(ANFEM%R(I))/ MAX(HPROP%R(I),EPS)


!   COEF FOR IMPLICITE
!         TIMP%ADR(IND_T)%P%R(I) = TIMP%ADR(IND_T)%P%R(I) +
!     &   CONSTSS*ANFEM%R(I)*HWIN/
!     &   MAX(HPROP%R(I),EPS)

!    EXPLICIT SOURCE PART
!         TEXP%ADR(IND_T)%P%R(I) = TEXP%ADR(IND_T)%P%R(I) -
!     &   CONSTSS*ANFEM%R(I)*HWIN*TMELT/
!     &   MAX(HPROP%R(I),EPS)

        ENDDO
!
      ENDIF
!-----------------------------------------------------------------------
!
      RETURN
      END
