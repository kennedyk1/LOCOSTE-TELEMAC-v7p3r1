!       *************************
        SUBROUTINE THERMAL_RICE2D
!       *************************
!
     &  ( TAIR,TWAT,TDEW,CC,VISB,WIND,PLUIE,
     &    PHCL,PHRI,PHPS,PHIB,PHIE,PHIH,
     &    PHIP,IW,TINTVL,AT,MARDAT,MARTIM,SUMPH )
!
!***********************************************************************
! RICE-2D    V7P2                                          11/11/2016
!***********************************************************************
!
!brief
!
!history  F. HUANG (CLARKSON U.) AND S.E. BOURBAN (HRW)
!+   11/11/2016
!+   V7P2
!+   IMPLEMENTATION
!
!reference
!+
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| DN      |-->| CURRENT TIME
!| MARDAT  |-->| DATE (YEAR, MONTH,DAY)
!| MARTIM  |-->| TIME (HOUR, MINUTE,SECOND)
!| AT      |-->| CURRENT TIME
!| T1      |-->| STARTING HOUR FOR SOLAR RADIATION CALCULATION (HRS)
!| T2      |-->| ENDING HOUR FOR SOLAR RADIATION CALCULATION (HRS)
!| PHCL    |-->|
!| PHRI    |-->|
!| PHPS    |-->|
!| ALBE    |-->|
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_SPECIAL
      USE EXCHANGE_WITH_ATMOSPHERE, ONLY: LEAP,DAYNUM

      USE DECLARATIONS_RICE2D, ONLY: IWEATYPE,XLATEN,Z1,HWA,
     &  PHID,ALPHSD,ALPHRD,ALSM,ALLM,
     &  SIO,ETADIR,ALBE,ZH,SGMA,CP,CI,HIA,ALPW,ALP
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)             :: MARDAT(3),MARTIM(3)
      INTEGER, INTENT(IN)             :: IW
!
      DOUBLE PRECISION, INTENT(INOUT) :: CC
      DOUBLE PRECISION, INTENT(IN)    :: TAIR,TWAT,TDEW,VISB,WIND,PLUIE
      DOUBLE PRECISION, INTENT(INOUT) :: TINTVL,AT
      DOUBLE PRECISION, INTENT(INOUT) :: PHCL,PHRI
      DOUBLE PRECISION, INTENT(INOUT) :: PHPS,PHIB,PHIE,PHIH,PHIP,SUMPH
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
!  DAY NUMBER, ORBITAL CORRECTION
!
      INTEGER IYEAR,IMONTH,IDAY,IHOUR,IMIN,ISEC
      INTEGER NDLT
!
      INTEGER          I
      DOUBLE PRECISION DN, DAY,DAYREEL,NDAYS,DTHR
!###> TODO: YOU NEED TO GET WIND FROM THE APPROPRIATE TELEMAC-2D MODULE
!      DOUBLE PRECISION
!###<
!
      DOUBLE PRECISION PHBA,PHBC,PHBR,PHBW
      DOUBLE PRECISION ES1,EA1,EPINA,AKN,VA,ASV
      DOUBLE PRECISION T1,T2,T10,T20,PCL,PRI,PPS,TAK,TSK,TDK
!
!      DOUBLE PRECISION SGMA,CP,CI
!      DATA SGMA, CP, CI /5.67E-8, 4.1855E+03, 2.04E+03/
!
!-----------------------------------------------------------------------
!
      IYEAR  = MARDAT(1)
      IMONTH = MARDAT(2)
      IDAY   = MARDAT(3)
      IHOUR  = MARTIM(1)
      IMIN   = MARTIM(2)
      ISEC   = MARTIM(3)
!
!-----------------------------------------------------------------------
!
!     PHCL: SOLAR RAD (FLUX) REACHING SURFACE, UNDER CLEAR SKY
!     PHRI: SOLAR RAD (FLUX) REACHING SURFACE, UNDER CLOUDY SKY
!     PHPS: NET SOLAR RAD (FLUX) AFTER REFLECTION
!     PHIB: EFFECTIVE BACK RADIATION (OPEN WATER OR ICE)
!     PHIE: EVAPORATIVE HEAT TRANSFER
!     PHIH: CONVECTIVE HEAT TRANSFER
!     PHIP: HEAT TRANSFER DUE TO PRECIPITATION
!
!-----------------------------------------------------------------------
!
!     DAY NUMBER, ORBITAL CORRECTION
      DAY = DAYNUM(IYEAR,IMONTH,IDAY,IHOUR,IMIN,ISEC)
     &    + FLOOR(AT/86400.D0)            ! DAY FROM JAN.1
      NDAYS = 365.D0 + REAL(LEAP(IYEAR))
      DAYREEL = MODULO(DAY, NDAYS)        ! DAY NUMBER IN DATE
!
      DN = DAY       ! INT # OF DAYS FROM JAN 1 = DAYREEL
      DTHR = TINTVL / 3600.0

      PHCL = 0.0
      PHRI = 0.0
      PHPS = 0.0

      PHIB = 0.0
      PHIE = 0.0
      PHIH = 0.0
      PHIP = 0.0

!      MSEC = NDAYS * 86400 + IHOUR * 3600 + IMIN * 60 + ISEC
!
!     T10 = FRACTION # OF HOURS FROM 0:00 @ CURRENT TIME (TSUM1)
!     T20 = FRACTION # OF HOURS FROM 0:00 AFTER DTHR
!
      T10 = IHOUR + MODULO(AT,86400.D0)/3600.D0
      T20 = T10 + DTHR
      T1 = T10
!
      IF (DTHR.GE.1.0) THEN  ! IF TIME INTERVAL > 1.0 HR (RARE)
        NDLT = INT(DTHR + 0.001)
        DO I = 1,NDLT
          T2 = T1 + 1.
          IF (T2.GT.T20) THEN
            CALL SOLAR1(DN,T1,T20,PCL,PRI,PPS,IW) !FH
            PHCL = PHCL + PCL  ! ADD FRACTION OF HOUR LEFT
            PHRI = PHRI + PRI
            PHPS = PHPS + PPS
            EXIT
          ELSE
            CALL SOLAR1(DN,T1,T2,PCL,PRI,PPS,IW) !FH
            PHCL = PHCL + PCL  ! ADD HOUR INCREMENTS
            PHRI = PHRI + PRI
            PHPS = PHPS + PPS
          ENDIF
          T1 = T2
        ENDDO
      ELSE
        CALL SOLAR1(DN,T10,T20,PCL,PRI,PPS,IW) !FH
        PHCL = PHCL + PCL  ! IF TIME INTERVAL A FRACTION OF AN HOUR
        PHRI = PHRI + PRI
        PHPS = PHPS + PPS
      ENDIF
!
      PHPS = PHPS / DTHR  ! NET SOLAR RAD AT SURFACE, W/M^2
!
!-----------------------------------------------------------------------
!
!     LINEAR HEAT TRANSFER FOR AIR-WATER INTERFACE ONLY, + = HEAT LOSS
!
      IF( IWEATYPE.EQ.0 ) THEN
        SUMPH = ( TAIR-TWAT )*HWA
      ELSEIF( IWEATYPE.EQ.1 ) THEN
        IF(IW.EQ.1) THEN  ! ICE
          SUMPH = PHPS + ALP -(TAIR-0.0)*HIA
        ELSE              ! OPEN WATER
          SUMPH = PHPS + ALPW -(TAIR-TWAT)*HWA
        ENDIF
      ELSE
!
!-----------------------------------------------------------------------
!
!       FBH 2016-11
        TAK = TAIR + 273.16  ! TAK = AIR TEMPERATURE
        TSK = TWAT + 273.16  ! TSK = WATER TEMP
        TDK = TDEW + 273.16  ! TDK = DEW POINT
!
        IF (IW.EQ.0) THEN  ! OPEN WATER ONLY, NO ICE EFFECTS
!
!  FOR WATER SURFACE, ES1 FOUND USING WATER TEMP (TSK), (4.32)
          ES1 = 7.95357242E+10*EXP((-18.1972839*373.16/TSK)+
     &          5.02808*LOG(373.16/TSK)-20242.1852*
     &          EXP(-26.1205253*TSK/373.16)+
     &          58.0691913*EXP(-8.039282*373.16/TSK))
          EA1 = 7.95357242E+10*EXP((-18.1972839*373.16/TDK)+
     &          5.02808*LOG(373.16/TDK)-20242.1852*
     &          EXP(-26.1205253*TDK/373.16)+
     &          58.0691913*EXP(-8.039282*373.16/TDK))
        ELSE
!
!  FOR ICE SURFACE, ES1 FOUND USING AIR TEMP (TAK), (4.33)
!  USUALLY CONSIDERED WHEN ANFEM(I) > 0.5, MORE ICE THAN WATER AT SURFACE
          ES1 = 5.75185606E+10*EXP((-20.947031*273.16/TAK)-
     &          3.56654*LOG(273.16/TAK)-2.01889049/273.16*TAK)
          EA1 = 5.75185606E+10*EXP((-20.947031*273.16/TDK)-
     &        3.56654*LOG(273.16/TDK)-2.01889049/273.16*TDK)
        ENDIF
!
!  EMISSIVITY OF ATMOSPHERE = PHBA (INCL. EFFECTS OF CLOUDS)
        IF (TAIR.LT.0) THEN
          EPINA = 1.08 * (1. - EXP(-EA1 ** (TAK / 2016.))) ! (4.31) SATTERLUND (1979)
        ELSE
          EPINA = 1-0.261*EXP(-0.000777*(273.16-TAK)**2.)  ! TK 03-2010 IDSO-JACKSON(1969)
        ENDIF
        PHBC = EPINA * SGMA * TAK ** 4  ! (4.30)
        PHBA = PHBC * (1. + 0.0017 * CC **2)  ! = ATMOSPHERIC RADIATION UNDER CLOUDY SKY (TELEMAC 2D)
!  EMISSIVITY OF RIVER SURFACE = PHBW
        PHBW = 0.97 * SGMA * TSK ** 4  ! (4.29), TSK = WATER TEMP (ALWAYS)

!  REFLECTED LONG WAVE RADIATION = PHBR
        PHBR = 0.03 * PHBA  ! (4.36)

        PHIB = PHBR + PHBW - PHBA  ! EFFECTIVE BACK RADIATION

!  EVAPORATIVE HEAT FLUX AND CONVECTIVE HEAT FLUX
        AKN = 8.0 + 0.35 * (TWAT - TAIR)
        VA = (2./Z1) ** 0.15 * WIND  !
!     Z1 = HEIGHT WIND VELOCITY IS MEASURED (*.PAR)

!   EVAPORATIVE AND CONDUCTIVE HEAT TRANSFER ONLY OCCURS OVER WATER
!   HEAT TRANSFER BETWEEN ICE AND WATER IS CALCULATED USING HIW (FROM FHC)

        PHIE = (1.56*AKN + 6.08 * VA) * (ES1-EA1)*4.1855/8.64  !   EVAPORATION
        PHIH = (AKN + 3.9*VA) * (TSK-TAK)*4.1855/8.64  !  CONDUCTIVE HEAT TRANSFER

!  HEAT TRANSFER DUE TO PRECIPITATION

        IF (VISB.GT.0.0.AND.VISB.LT.1.0) THEN
!         MIN VALUE = 1.0 KM, PHIP = 380.28 W/M^2
          ASV = 78.5 / 86400.
        ELSE
!         AT VISB = 10 KM, PHIP = 1.604 W/M^2
          ASV = 78.5 / 86400. * VISB ** (-2.375)
        ENDIF
!
! ~~>   NO SNOW
        IF(VISB.LT.1E-5) THEN ! NO SNOW
           ASV = 0.0
        ENDIF
! ~~>   SNOW FALL
        IF(IW.EQ.0) THEN
          PHIP = ASV * (XLATEN + CI * (TWAT - TAIR))
        ELSE
          PHIP = 0.0
        ENDIF
!
! ~~> RAIN FALL
        IF(PLUIE.GT.0) THEN
          ASV = PLUIE/3600.0
          IF(IW.EQ.0) THEN   ! WATER
            IF(TAIR.LT.0) THEN
              PHIP = - ASV*CP*(TWAT-0.0)  ! HEAT LOSS
            ELSE
              PHIP = - ASV*CP*(TWAT - TAIR) ! HEAT GAIN
            ENDIF
          ELSE              ! ICE
            IF(TAIR.GT.0) THEN
              PHIP = - ASV*CP*(0.0 - TAIR) ! HEAT GAIN
            ELSE
              PHIP = 0.0
            ENDIF
          ENDIF
        ENDIF
!
!    SUMMATION AND OUTPUT /!\ this is now done outside in SOURCE_RICED2D
        SUMPH = - PHPS + PHIB + PHIE + PHIH + PHIP
        SUMPH = - SUMPH
!
!  OUTPUT, DETAILED THERMAL BUDGET AT RIVER SURFACE, + = HEAT LOSS
!  NET SOLAR RAD (PHPS) ASSUMED TO BE ABSORBED BY WATER COLUMN (HEAT GAIN)
!     RAY3 = PHPS    SOLAR RADIATION
!     RA = - PHBR + PHBA = 0.97*PHBA

!     RE = PHBW
!     CV = PHIH
!     CE = PHIE
!     RAY3+RA-RE-CV-CE
!
      ENDIF

      RETURN
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      CONTAINS
!
!-----------------------------------------------------------------------
!
        SUBROUTINE SOLAR1
     &                  (DN,T1,T2,PHCL,PHRI,PHPS,IW)
!
!***********************************************************************
!
!brief
!+
!
!history  F. HUANG (CLARKSON U.) AND S.E. BOURBAN (HRW)
!+        19/11/2016
!+        V7P2
!+        INITIAL DEVELOPMENTS
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| DN      |-->| CURRENT TIME
!| T1      |-->| STARTING HOUR FOR SOLAR RADIATION CALCULATION (HRS)
!| T2      |-->| ENDING HOUR FOR SOLAR RADIATION CALCULATION (HRS)
!| PHCL    |-->|
!| PHRI    |-->|
!| PHPS    |-->|
!| IW      |-->|
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_RICE2D, ONLY: IWEATYPE,XLATEN,Z1,HWA,
     &  PHID,ALPHSD,ALPHRD,ALSM,ALLM,
     &  SIO,ETADIR,ALBE,ZH,SGMA,CP,CI,HIA,ALPW,ALP
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER         , INTENT(IN)    :: IW
      DOUBLE PRECISION, INTENT(IN)    :: DN,T1,T2
      DOUBLE PRECISION, INTENT(INOUT) :: PHCL,PHRI,PHPS
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER          :: I
!
      DOUBLE PRECISION :: PI
      DOUBLE PRECISION :: VA,AA,DTHR,
     &  ALPHA,ALPHR,ALPHS,ALHA
      DOUBLE PRECISION R,BB,AMO,AM,CR,DELTA,EO,ET,HRIS,HSS,
     &  PAPO,PHISO,PHRR,PHS,RHS1,RHS2,SIA,ALR,HS1,HS2,HSET
!
!-----------------------------------------------------------------------
!
! DN = THE NUMBER OF DAYS FROM JAN. 1 (INPUT)
! PHID = THE LATITUDE, DEGREES, NORTH (+), SOUTH (-), (*.PAR FILE)
! DELTA = SOLAR DECLINATION OF THE SUN;
! HSS = LOCAL HOUR ANGLE OF THE SUNSET, RADIANS;
! HSR = LOCAL HOUR ANGLE OF THE SUNRISE, RADIANS;
! ALMST = LOCAL MEAN SOLAR TIME IN HRS;
! ALST = STANDARD TIME OF THE TIME ZONE, IN HRS, COUNTED FROM MIDNIGHT, 0-24.0;
! ALSM = LONGITUDE OF THE STANDARD MERIDEAN, IN DEGREE; (*.PAR FILE)
! ALLM = LONGITUDE OF THE LOCAL MERIDEAN, IN DEGREES; (*.PAR FILE)
! ETA = -1, FOR WEST; + FOR EAST; (*.PAR FILE)
! ZH = ELEVATION ABOVE SEA LEVEL, M. (*.PAR FILE)
! ALPHSD = SUN EXIT ANGLE, 180 FOR HORIZONTAL; (*.PAR FILE)
! ALPHRD = SUN EMISION ANGLE, 0 DEGREE FOR HORIZONTAL; (*.PAR FILE)
! NM = NUMBER OF MONTH
! ND = DAY NUMBER IN THE DATE
! T1 = STARTING HOUR FOR SOLAR RADIATION CALCULATION, HRS (INPUT)
! T2 = ENDING HOUR FOR SOLAR RADIATION CALCULATION, HRS (INPUT)
! CC = CLOUD COVER, IN THENTHS, 0-10
!
!-----------------------------------------------------------------------
!
      PI  = 4.D0*ATAN(1.D0)
!      CC = NEBU    ! cloud

!  LOCAL GEOGRAPHIC LATITUDE, CONVERT TO RADIANS
      PHS = PHID * PI / 180.  ! LATITUDE
      ALPHS = ALPHSD * PI / 180.  ! EXIT ANGLE, RADIANS
      ALPHR = ALPHRD * PI / 180.  ! EMISSION ANGLE, RADIANS

!  COOPER 1969 SOLAR DECLINATION, IN RADIANS  (4.6)
      DELTA = 23.45 * PI / 180. * SIN(360.*(284.+DN) / 365. * PI / 180.)

!  DIFFERENCE BETWEEN TRUE SOLAR TIME AND MEAN SOLAR TIME
      R = 2. * PI * (DN - 1.) / 365.   ! (4.3)
!  DUFFIE AND BECKMAN 1959, ECCENTRICITY CORRECTION FACTION OF THE EARTH ORBIT
      EO = 1. + 0.033 * COS(2. * PI / 365. * DN)  ! (4.5)
!  EQUATION OF TIME, IN HRS  (4.2)
      ET = 3.8197 * (0.000075 + 0.001868 * COS(R) - 0.032077 * SIN(R)
     &     -0.014615 * COS(2. * R) - 0.04089 * SIN(2. * R))

!  HOUR ANGLE AT SUNRISE, RADIANS  (4.9)
      HSS = ACOS( -TAN(PHS) * TAN(DELTA) )
      IF (HSS.LT.0.0) THEN
        HSS=-HSS
      ENDIF
!  SUN SET, HRS  (4.11)
      HSET = 12. + HSS * 12. / PI - (PI - ALPHS) / PI * 12.0
!  SUN RISE, HRS  (4.10)
      HRIS = 12. - HSS * 12. / PI + ALPHR / PI * 12.0
!  CALCULATE HOUR ANGLE, TIME CORRECTION  (4.4)
      HS1 = T1 - ETADIR / 15. * (ALSM - ALLM) + ET  ! HOURS
      RHS1 = (12. - HS1) * PI / 12.   ! RADIANS
      HS2 = T2 - ETADIR / 15. * (ALSM - ALLM) + ET  ! HOURS
      RHS2 = (12. - HS2) * PI / 12.   ! RADIANS
!  RHS1/RHS2 IS # OF RADIANS OFF OF NOON, + BEFORE, - AFTER

! =========NET SOLAR RADIATION, PHPS

      PHCL = 0.0  ! CLEAR SKY SOLAR RADIATION
      PHRI = 0.0  ! INCL. CLOUD EFFECTS, IF ANY
      PHPS = 0.0  ! NET SOLAR, AFTER REFLECTION AT EARTH SURFACE

!  NO SUN, BEFORE SUNRISE OR AFTER SUNSET
      IF (HS1.GT.HSET.AND.HS2.GT.HSET) THEN
        RETURN
      ENDIF
      IF (HS1.LT.HRIS.AND.HS2.LT.HRIS) THEN
        RETURN
      ENDIF

      IF (HS1.LT.HRIS .AND. HS2.GT.HRIS) THEN
        RHS1=(12.-HRIS)*PI/12.
        HS1=HRIS
      ENDIF
      IF (HS2.GT.HSET.AND.HS1.LT.HSET) THEN
        RHS2=(12.0-HSET)*PI/12.
        HS2=HSET
      ENDIF

!  AVERAGE SOLAR TIME ANGLE
      ALHA = (RHS1 + RHS2) / 2.  ! RADIANS
!  TOTAL SOLAR RADIATION T1 TO T2, PER UNIT AREA, (4.13)-RADIANS, (4.14)-HOURS
      PHISO = 12./PI*SIO*EO*((RHS1-RHS2)*SIN(DELTA)*SIN(PHS)+
     &        (SIN(RHS1)-SIN(RHS2))*COS(DELTA)*COS(PHS))

      SIA = SIN(DELTA) * SIN(PHS) + COS(DELTA) * COS(PHS) * COS(ALHA)
!     LINE ABOVE -- (4.7)
      ALPHA = ASIN( SIA ) * 180. / PI  ! CONVERT TO DEGREES

      AMO = 1. / (SIA + 0.15 * (ALPHA + 3.885) ** (-1.253))  ! (4.17)
      PAPO = EXP(-0.0001184 * ZH)  ! (4.18)
      AM = AMO * PAPO  ! (4.16)
      AM = 0.99 - 0.17 * AM  ! (4.15)
      PHCL = AM * PHISO  ! ENERGY FLUX, REACHING GROUND UNDER CLEAR SKY

      IF (PHCL.LT.0.0) PHCL=0.0
      PHRI = PHCL * ( 1. - 0.0065 * CC **2. )  ! (4.19)
!  SOLAR RADIATION REACHING THE EARTH UNDER CLOUDY SKIES (ABOVE)

      IF (IW.EQ.0) THEN  ! IF ALBE = 0, "OPEN WATER" CONDITIONS
        IF (PHCL.EQ.0.) THEN
          PHRR=0.
        ELSE  ! ESTIMATE REFLECTIVITY OF OPEN WATER SURFACE
          CR = AMAX1(1. - PHRI / PHCL,0.0)  ! (4.25) - CLOUDINESS RATIO
          AA = 2.2 + CR ** 0.7 / 4.0 - (CR ** 0.7 - 0.4) ** 2 / 0.16
          BB = -1.02 + CR ** 0.7 / 16. + (CR ** 0.7 - 0.4) ** 2 / 0.64
          ALR = AA * ALPHA ** BB ! ESTIMATE OPEN WATER ALBEDO (4.22-4.24)
          PHRR = ALR * PHRI  ! AMOUNT OF SOLAR RADIATION REFLECTED
        ENDIF

!  USE THE ALBEDO SPECIFIED TO INCLUDE REFLECTIVE EFFECTS OF ICE PRESENT
      ELSE
        PHRR = ALBE * PHRI  ! (4.20)
        IF (PHCL.EQ.0.) PHRR=0.
      ENDIF

      PHPS = PHRI - PHRR  ! NET SOLAR RADIATION BETWEEN T1-T2, (4.20)

      RETURN
      END SUBROUTINE SOLAR1
!
!-----------------------------------------------------------------------
!
      END SUBROUTINE THERMAL_RICE2D
