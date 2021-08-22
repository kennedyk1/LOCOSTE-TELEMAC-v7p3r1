!                    *********************
                       SUBROUTINE SOLAR1
!                    *********************
     & (DN,T1,T2,PHCL,PHRI,PHPS,IW)
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
     &  PHID,ALPHSD,ALPHRD,ALSM,ALLM,CC,
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
      DOUBLE PRECISION :: PI,VA,AA,DTHR
      DOUBLE PRECISION :: ALPHA,ALPHR,ALPHS,ALHA
      DOUBLE PRECISION :: R,BB,AMO,AM,CR,DELTA,EO,ET,HRIS,HSS
      DOUBLE PRECISION :: PAPO,PHISO,PHRR,PHS,RHS1,RHS2,SIA,ALR
      DOUBLE PRECISION :: HS1,HS2,HSET
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
!
      IF (HS1.LT.HRIS .AND. HS2.GT.HRIS) THEN
        RHS1=(12.-HRIS)*PI/12.
        HS1=HRIS
      ENDIF
      IF (HS2.GT.HSET.AND.HS1.LT.HSET) THEN
        RHS2=(12.0-HSET)*PI/12.
        HS2=HSET
      ENDIF
!
!  AVERAGE SOLAR TIME ANGLE
!
      ALHA = (RHS1 + RHS2) / 2.  ! RADIANS
!  TOTAL SOLAR RADIATION T1 TO T2, PER UNIT AREA, (4.13)-RADIANS, (4.14)-HOURS
      PHISO = 12./PI*SIO*EO*((RHS1-RHS2)*SIN(DELTA)*SIN(PHS)+
     &        (SIN(RHS1)-SIN(RHS2))*COS(DELTA)*COS(PHS))
!
      SIA = SIN(DELTA) * SIN(PHS) + COS(DELTA) * COS(PHS) * COS(ALHA)
!     LINE ABOVE -- (4.7)
      ALPHA = ASIN( SIA ) * 180. / PI  ! CONVERT TO DEGREES
!
      AMO = 1. / (SIA + 0.15 * (ALPHA + 3.885) ** (-1.253))  ! (4.17)
      PAPO = EXP(-0.0001184 * ZH)  ! (4.18)
      AM = AMO * PAPO  ! (4.16)
      AM = 0.99 - 0.17 * AM  ! (4.15)
      PHCL = AM * PHISO  ! ENERGY FLUX, REACHING GROUND UNDER CLEAR SKY
!
      IF (PHCL.LT.0.0) PHCL=0.0
      PHRI = PHCL * ( 1. - 0.0065 * CC **2. )  ! (4.19)
!  SOLAR RADIATION REACHING THE EARTH UNDER CLOUDY SKIES (ABOVE)
!
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
!
!  USE THE ALBEDO SPECIFIED TO INCLUDE REFLECTIVE EFFECTS OF ICE PRESENT
!
      ELSE
        PHRR = ALBE * PHRI  ! (4.20)
        IF (PHCL.EQ.0.) PHRR=0.
      ENDIF
!
      PHPS = PHRI - PHRR  ! NET SOLAR RADIATION BETWEEN T1-T2, (4.20)
!
      RETURN
      END SUBROUTINE SOLAR1