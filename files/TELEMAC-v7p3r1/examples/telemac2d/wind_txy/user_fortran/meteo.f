!                    ****************
                     SUBROUTINE METEO
!                    ****************
!
     &(PATMOS,WINDX,WINDY,FUAIR,FVAIR,X,Y,AT,LT,NPOIN,VENT,ATMOS,
     & HN,GRAV,ROEAU,PRIVE,ATMFILEA,ATMFILEB,FILES,LISTIN,
     & PATMOS_VALUE,AWATER_QUALITY,PLUIE,AOPTWIND,AWIND_SPD)
!
!***********************************************************************
! TELEMAC2D   V7P2
!***********************************************************************
!
!brief    COMPUTES ATMOSPHERIC PRESSURE AND WIND VELOCITY FIELDS
!+               (IN GENERAL FROM INPUT DATA FILES).
!
!warning  CAN BE ADAPTED BY USER
!
!history  J-M HERVOUET (LNHE)
!+        02/01/2004
!+        V5P4
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
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        30/01/2013
!+        V6P3
!+   Now 2 options with an example for reading a file. Extra arguments.
!
!history  C.-T. PHAM (LNHE)
!+        09/07/2014
!+        V7P0
!+   Reading a file of meteo data for exchange with atmosphere
!+   Only the wind is used here
!
!history R.ATA (LNHE)
!+        09/11/2014
!+        V7P0
!+  introducion of water quality option + pluie is introduced as
!+   an optional parameter + remove of my_option which is replaced
!+   by a new keyword + value of patmos managed also with a new keyword
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        07/01/2015
!+        V7P0
!+  Adding optional arguments to remove USE DECLARATIONS_TELEMAC2D.
!
!history R.ATA (LNHE)
!+        16/11/2015
!+        V7P0
!+  Adding USE WAQTEL...
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        16/02/2015
!+        V7P0
!+   Shifting the stations coordinates removed in case of wind varying
!+   in time and space (option 99). Managing the divisions by 0 is now
!+   done by subroutine IDWM_T2D, and this does not spoil parallelism.
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        16/02/2015
!+        V7P0
!+   Shifting the stations coordinates removed in case of wind varying
!+   in time and space (option 99). Managing the divisions by 0 is now
!+   done by subroutine IDWM_T2D, and this does not spoil parallelism.
!
!history A. LEROY (LNHE)
!+        25/11/2015
!+        V7P1
!+  INTERPMETEO now writes directly in variables of WAQTEL which
!+  can be used by the other modules. This makes it possible to
!+  remove subsequent calls to INTERPMETEO in TELEMAC3D
!
!history  P. PRODANOVIC (RIGGS ENGINEERING LTD)
!+        15/06/2016
!+        V7P0
!+   Converts the wind data to cartesian form, then interpolates. This
!+   eliminates errors when interpolating direction between 359 and 1
!+   degrees azimuth.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| AT             |-->| TIME
!| ATMFILEA       |-->| LOGICAL UNIT OF THE ASCII ATMOSPHERIC FILE
!| ATMFILEB       |-->| LOGICAL UNIT OF THE BINARY ATMOSPHERIC FILE
!| ATMOS          |-->| YES IF PRESSURE TAKEN INTO ACCOUNT
!| FILES          |-->| BIEF_FILES STRUCTURES OF ALL FILES
!| FUAIR          |<->| VELOCITY OF WIND ALONG X, IF CONSTANT
!| FVAIR          |<->| VELOCITY OF WIND ALONG Y, IF CONSTANT
!| GRAV           |-->| GRAVITY ACCELERATION
!| HN             |-->| DEPTH
!| LISTIN         |-->| IF YES, PRINTS INFORMATION
!| LT             |-->| ITERATION NUMBER
!| NPOIN          |-->| NUMBER OF POINTS IN THE MESH
!| PATMOS         |<--| ATMOSPHERIC PRESSURE
!| PRIVE          |-->| USER WORKING ARRAYS (BIEF_OBJ BLOCK)
!| ROEAU          |-->| WATER DENSITY
!| VENT           |-->| YES IF WIND TAKEN INTO ACCOUNT
!| WINDX          |<--| FIRST COMPONENT OF WIND VELOCITY
!| WINDY          |<--| SECOND COMPONENT OF WIND VELOCITY
!| X              |-->| ABSCISSAE OF POINTS
!| Y              |-->| ORDINATES OF POINTS
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_WAQTEL,ONLY: PVAP,RAY3,NWIND,NEBU,TAIR,
     &                              TAIR_VALUE,HREL,RAINFALL,
     &                              EVAPORATION,ATMOSEXCH
      USE DECLARATIONS_TELEMAC2D, ONLY : AT1_METEO,AT2_METEO,
     &                                   FUAIR1_METEO,FUAIR2_METEO,
     &                                   FVAIR1_METEO,FVAIR2_METEO
      USE DECLARATIONS_SPECIAL
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)             :: LT,NPOIN,ATMFILEA,ATMFILEB
      LOGICAL, INTENT(IN)             :: ATMOS,VENT,LISTIN
      DOUBLE PRECISION, INTENT(IN)    :: X(NPOIN),Y(NPOIN),HN(NPOIN)
      DOUBLE PRECISION, INTENT(INOUT) :: WINDX(NPOIN),WINDY(NPOIN)
      DOUBLE PRECISION, INTENT(INOUT) :: PATMOS(NPOIN)
      DOUBLE PRECISION, INTENT(IN)    :: AT,GRAV,ROEAU,PATMOS_VALUE
      DOUBLE PRECISION, INTENT(INOUT) :: FUAIR,FVAIR
      TYPE(BIEF_OBJ), INTENT(INOUT)   :: PRIVE
      TYPE(BIEF_FILE), INTENT(IN)     :: FILES(*)
!     OPTIONAL
      LOGICAL, INTENT(IN)          ,OPTIONAL :: AWATER_QUALITY
      TYPE(BIEF_OBJ), INTENT(INOUT),OPTIONAL :: PLUIE
      INTEGER, INTENT(IN)          ,OPTIONAL :: AOPTWIND
      DOUBLE PRECISION, INTENT(IN) ,OPTIONAL :: AWIND_SPD(2)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      LOGICAL WATER_QUALITY
      INTEGER UL,OPTWIND
      DOUBLE PRECISION COEF
      DOUBLE PRECISION UAIR,VAIR,WIND_SPD(2)
!     EXCHANGE WITH ATMOSPHERE
      DOUBLE PRECISION PATM,WW,TA
!
      DOUBLE PRECISION, PARAMETER :: EPS = 1.D-3
!
!     ######################################################################
!     IDWM WIND INTERPOLATION CUSTOM VARIABLES
!     ######################################################################
!
      INTEGER I, NUMSTA, NUMPOINTS, A, B, J, K, JUNK
      DOUBLE PRECISION THETA_RAD, TMPDIR, TMPSPD
!
!     COORDINATES OF THE STATIONS UTM
!
      DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE :: XX, YY, AT_WIND
      DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE :: OUT_WSPD
      DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE :: OUT_WDIRX
      DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE :: OUT_WDIRY
      DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE :: WIND, POINTS
      DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE :: INPSTA_S
      DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE :: INPSTA_D
      
!     ADDED ON 2016.05.26
!     THIS IS THE X AND Y COMPONENT OF THE WIND READ FROM FILE
      DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE :: INPSTA_WINDX
      DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE :: INPSTA_WINDY
!
!     ######################################################################
!
!-----------------------------------------------------------------------
!
!     DATA THAT YOU DECLARE AND READ HERE ONCE IN A FILE MAY HAVE TO BE
!     KEPT BECAUSE THIS SUBROUTINE IS CALLED AT EVERY TIME STEP.
!     WITHOUT THE SAVE COMMAND, ALL LOCAL DATA ARE FORGOTTEN IN THE NEXT
!     CALL.
!
      SAVE
!
!-----------------------------------------------------------------------
!
!     DEFAULT VALUES OF PARAMETERS WHEN THEY ARE NOT GIVEN
!
      WATER_QUALITY=.FALSE.
      IF(PRESENT(AWATER_QUALITY)) WATER_QUALITY=AWATER_QUALITY
      OPTWIND=1
      IF(PRESENT(AOPTWIND)) OPTWIND=AOPTWIND
      WIND_SPD(1)=0.D0
      WIND_SPD(2)=0.D0
      IF(PRESENT(AWIND_SPD)) THEN
        WIND_SPD(1)=AWIND_SPD(1)
        WIND_SPD(2)=AWIND_SPD(2)
      ENDIF
!
!-----------------------------------------------------------------------
!
!     AT FIRST TIMESTEP
!
      IF(LT.EQ.0) THEN
!
        UL = FILES(ATMFILEA)%LU
!
!       ATMOSPHERIC PRESSURE
!
        IF(ATMOS.OR.WATER_QUALITY) THEN
          CALL OV( 'X=C     ' , PATMOS,Y,Y,PATMOS_VALUE,NPOIN )
        ENDIF
        IF(WATER_QUALITY) THEN
          CALL OV( 'X=C     ' , TAIR%R,Y,Y,TAIR_VALUE,NPOIN )
        ENDIF
!
!       WIND :
!
        IF(VENT.OR.WATER_QUALITY) THEN
          IF(OPTWIND.EQ.1)THEN
!           IN THIS CASE THE WIND IS CONSTANT, VALUE GIVEN IN STEERING FILE.
            CALL OV( 'X=C     ' ,WINDX,WINDX,WINDX, FUAIR , NPOIN )
            CALL OV( 'X=C     ' ,WINDY,WINDY,WINDY, FVAIR , NPOIN )
!
          ELSEIF(OPTWIND.EQ.2) THEN
            IF(FILES(ATMFILEA)%NAME(1:1).NE.' ') THEN
!             JUMPING TWO LINES OF COMMENTS
              READ(UL,*)
              READ(UL,*)
!             READING THE FIRST TWO LINES OF DATA
              READ(UL,*) AT1_METEO,FUAIR1_METEO,FVAIR1_METEO
              IF(AT.LT.AT1_METEO) THEN
                WRITE(LU,*) ' '
                WRITE(LU,*) 'METEO'
                IF(LNG.EQ.1) WRITE(LU,*) 'DEBUT TARDIF DU FICHIER DE
     &                                    VENT'
                IF(LNG.EQ.2) WRITE(LU,*) 'LATE BEGINNING OF THE WIND
     &                                    FILE'
                CALL PLANTE(1)
                STOP
              ENDIF
            ENDIF
!
!         ######################################################################
!         IDWM WIND INTERPOLATION; THIS IS EXECUTED ONLY ONCE AT THE START
!         ######################################################################
!
          ELSEIF(OPTWIND.EQ.3) THEN
        ! READ BLANK LINE AT BEGINING OF FILE
            READ(UL,*)
        ! READ NUMSTA AND NUMPOINTS
            READ(UL,*) NUMSTA, NUMPOINTS

          !ALLOCATE THE ARRAYS
            ALLOCATE(XX(NUMSTA), YY(NUMSTA), AT_WIND(NUMPOINTS))
            ALLOCATE(WIND(NUMPOINTS,NUMSTA*2+1), POINTS(NPOIN,2))
            ALLOCATE(INPSTA_S(NUMSTA,3), INPSTA_D(NUMSTA,3))
            ALLOCATE(INPSTA_WINDX(NUMSTA,3), INPSTA_WINDY(NUMSTA,3))
            ALLOCATE(OUT_WSPD(NPOIN),OUT_WDIRX(NPOIN),OUT_WDIRY(NPOIN))
!
          ! READ STATION COORDINATES
            DO B = 1,NUMSTA
              READ(UL,*) XX(B), YY(B)
           !WRITE(*,*) XX(B), YY(B)
            ENDDO
!
          ! READ THE WIND TIME SERIES FROM THE INPUT FILE
          ! FIRST COLUMN IS TIME IN SECONDS, REST OF COLUMNS ARE WSPD
          ! AND WDIR FOR EACH STATION READ
            DO A = 1,NUMPOINTS
              READ(UL,*) (WIND(A,B), B=1,NUMSTA*2+1)
            ENDDO
!
          ! EXTRACT AT_WIND FROM WIND(A,B); FIRST COLUMN IS TIME IN SECONDS
            DO A = 1,NUMPOINTS
              AT_WIND(A) = WIND(A,1)
            ENDDO
!
          ! ASSEMBLE THE POINTS ARRAY FOR IDWM FUNCTION
            DO I = 1,NPOIN
              POINTS(I,1) = X(I)
              POINTS(I,2) = Y(I)
            ENDDO
!
! #######################################################################
!
          ENDIF
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
!     FOR THE REMAINING TIME STEPS
!
      IF(VENT.OR.WATER_QUALITY) THEN
!
!       WATER QUALITY
!
        IF(FILES(ATMFILEA)%NAME(1:1).NE.' ')THEN

          IF(WATER_QUALITY) THEN
!         TIME VARYING WATER QUALITY
            IF(ATMOSEXCH.EQ.0)THEN
              CALL INTERPMETEO2(NWIND,UAIR,VAIR,TA,PATM,NEBU,RAINFALL,
     &                          PVAP,RAY3,AT,UL)
!
              CALL OV('X=C     ',WINDX,WINDX,WINDX,UAIR,NPOIN)
              CALL OV('X=C     ',WINDY,WINDY,WINDY,VAIR,NPOIN)
              CALL OV('X=C     ',PATMOS,PATMOS,PATMOS,PATM,NPOIN)
              CALL OV('X=C     ',TAIR%R,TAIR%R,TAIR%R,TA  ,NPOIN)
              IF(PRESENT(PLUIE))THEN
                CALL OS('X=C     ',X = PLUIE, C=RAINFALL) ! MM/S
              ENDIF
!
!         TIME VARYING WATER QUALITY WITH HEAT EXCHANGE WITH ATMOSPHERE
            ELSEIF(ATMOSEXCH.EQ.1.OR.ATMOSEXCH.EQ.2) THEN
              CALL INTERPMETEO(WW,UAIR,VAIR,TA,PATM,
     &                         HREL,NEBU,RAINFALL,EVAPORATION,AT,UL)
              CALL OV('X=C     ',WINDX,Y,Y,UAIR,NPOIN)
              CALL OV('X=C     ',WINDY,Y,Y,VAIR,NPOIN)
!
              CALL OV('X=C     ',PATMOS,Y,Y,PATM,NPOIN)
              CALL OV('X=C     ',TAIR%R,Y,Y,TA  ,NPOIN)
            ENDIF
!
          ELSEIF (VENT) THEN
!
!           WIND VARYING IN TIME CONSTANT IN SPACE
            IF(OPTWIND.EQ.2)THEN
10            CONTINUE
              IF(AT.GE.AT1_METEO.AND.AT.LT.AT2_METEO) THEN
                IF(AT2_METEO-AT1_METEO.GT.1.D-6) THEN
                  COEF=(AT-AT1_METEO)/(AT2_METEO-AT1_METEO)
                ELSE
                  COEF=0.D0
                ENDIF
                UAIR=FUAIR1_METEO+COEF*(FUAIR2_METEO-FUAIR1_METEO)
                VAIR=FVAIR1_METEO+COEF*(FVAIR2_METEO-FVAIR1_METEO)
                IF(LISTIN) THEN
                  IF(LNG.EQ.1) WRITE(LU,*) 'VENT A T=',AT,' UAIR=',UAIR,
     &                                     ' VAIR=',VAIR
                  IF(LNG.EQ.2) WRITE(LU,*) 'WIND AT T=',AT,' UAIR=',
     &                                      UAIR,' VAIR=',VAIR
                ENDIF
              ELSE
                AT1_METEO=AT2_METEO
                FUAIR1_METEO=FUAIR2_METEO
                FVAIR1_METEO=FVAIR2_METEO
                READ(UL,*,ERR=100,END=200) AT2_METEO,FUAIR2_METEO,
     &                                     FVAIR2_METEO
                GO TO 10
!
!-----------------------------------------------------------------------
!
100             CONTINUE
                WRITE(LU,*) ' '
                WRITE(LU,*) 'METEO'
                IF(LNG.EQ.1) WRITE(LU,*) 'ERREUR DANS LE FICHIER DE
     &                                    VENT'
                IF(LNG.EQ.2) WRITE(LU,*) 'ERROR IN THE WIND FILE'
                CALL PLANTE(1)
                STOP
200             CONTINUE
                WRITE(LU,*) ' '
                WRITE(LU,*) 'METEO'
                IF(LNG.EQ.1)WRITE(LU,*)'FIN PREMATUREE DU FICHIER DE
     &                                  VENT'
                IF(LNG.EQ.2)WRITE(LU,*) 'WIND FILE TOO SHORT'
                CALL PLANTE(1)
                STOP
              ENDIF
              CALL OV('X=C     ',WINDX,Y,Y,UAIR,NPOIN)
              CALL OV('X=C     ',WINDY,Y,Y,VAIR,NPOIN)
!
              FUAIR = UAIR
              FVAIR = VAIR
!
!         WIND VARYING IN TIME AND SPACE
!
            ELSEIF(OPTWIND.EQ.3)THEN
!            IF(LNG.EQ.1) THEN
!              WRITE(LU,*) 'CETTE OPTION N EST PAS ENCORE PROGRAMMEE'
!              WRITE(LU,*) 'VOIR CAS DE VALIDATION WIND_TXY '
!              WRITE(LU,*) 'DANS LE DOSSIER EXAMPLES/TELEMAC2D'
!            ELSE
!              WRITE(LU,*) 'THIS OPTION IS NOT IMPLEMENTED YET'
!              WRITE(LU,*) 'SEE VALIDATION CASE WIND_TXY '
!              WRITE(LU,*) 'LOCATED AT THE FOLDER EXAMPLES/TELEMAC2D'
!            ENDIF
!            CALL PLANTE(1)
!            STOP
!
! #######################################################################
!         IDWM WIND INTERPOLATION CODE
! #######################################################################
!
!
!       ASSEMBLE THE ARRAYS OF X,Y,WNDSPD AND X,Y,WNDDIR FOR EACH ITERATION
            DO A = 1,NUMPOINTS
              IF(AT_WIND(A).EQ.AT) THEN
                WRITE(LU,*) 'METEO: WIND READ AT: ', AT
                DO B = 1,NUMSTA
                  ! ASSEMBLE THE ARRAYS FOR THIS TIME STEP
                  ! DIRECTIONS FROM INPUT FILE
                  INPSTA_D(B,1) = XX(B)
                  INPSTA_D(B,2) = YY(B)
                  INPSTA_D(B,3) = WIND(A,B*2+1)

                  ! SPEEDS FROM INPUT FILE
                  INPSTA_S(B,1) = XX(B)
                  INPSTA_S(B,2) = YY(B)
                  INPSTA_S(B,3) = WIND(A,B*2)
                  
                  ! ADDED ON 2016.06.15
                  ! CHECK IF WIND SPEED IS +VE, AND IF WIND DIRECTION
                  ! IS BETWEEN 0 AND 360 DEG; 
                  IF (INPSTA_S(B,3) < 1.0E-6) THEN
                    INPSTA_S(B,3) = 1.0E-6
                  END IF
                  
                  IF (INPSTA_D(B,3) .LT. 1.0E-6) THEN
                    INPSTA_D(B,3) = 1.0E-6
                  END IF
                  
                  IF (INPSTA_D(B,3) .GT. 360.0) THEN
                    INPSTA_D(B,3) = 360.0
                  END IF                  
                
                  ! ADDED ON 2016.05.26
                  ! RATHER THAN INTERPOLATING THE DIRECTION VARIABLE
                  ! CONVERT INPSTA_D TO ITS X AND Y COMPONENTS,
                  ! INTERPOLATE BOTH
                  
                  ! THIS IS NEEDED BECAUSE INTERPOLATING A DIRECTION 
                  ! VARIABLE THAT TAKES ON VALUES BETWEEN 0 AND 360 HAS 
                  ! PROBLEMS WHEN INTERPOLATING NODES LOCATED CLOSE TO 
                  ! STATIONS WITH  DIR~0'S AND DIR~350'S
                  
                  ! ASSIGN X AND Y COORDINATES
                  INPSTA_WINDX(B,1) = XX(B) 
                  INPSTA_WINDX(B,2) = YY(B)
                  
                  INPSTA_WINDY(B,1) = XX(B) 
                  INPSTA_WINDY(B,2) = YY(B) 

                  ! THIS IS JUST TO KEEP VARIABLE NAMES SHORT
                  TMPSPD = INPSTA_S(B,3)
                  TMPDIR = INPSTA_D(B,3)
                  
                  ! CONVERT INP_STA_D TO INPSTA_WINDX AND INPSTA_WINDY
                  ! THESE ARE CARTESIAN VECTORS OF THE WIND
                  IF (TMPDIR >= 0 .AND. TMPSPD >= 0.0) THEN             
                    IF ((TMPDIR >= 0) .AND. (TMPDIR <= 90)) THEN
                      THETA_RAD = TMPDIR * 3.141592654 / 180.0
                      INPSTA_WINDX(B,3) = -1.0 * SIN(THETA_RAD) * TMPSPD
                      INPSTA_WINDY(B,3) = -1.0 * COS(THETA_RAD) * TMPSPD
                    END IF
!
                    IF ((TMPDIR > 90) .AND. (TMPDIR <= 180)) THEN
                      THETA_RAD = (180 - TMPDIR) * 3.141592654 / 180.0
                        INPSTA_WINDX(B,3) =-1.0*SIN(THETA_RAD)*TMPSPD
                        INPSTA_WINDY(B,3) = COS(THETA_RAD)*TMPSPD
                    END IF
!
                    IF ((TMPDIR > 180) .AND. (TMPDIR <= 270)) THEN
                      THETA_RAD = (TMPDIR-180) * 3.141592654 / 180.0
                        INPSTA_WINDX(B,3) = SIN(THETA_RAD)*TMPSPD
                        INPSTA_WINDY(B,3) = COS(THETA_RAD)*TMPSPD
                    END IF
!
                    IF ((TMPDIR > 270) .AND. (TMPDIR <= 360)) THEN
                      THETA_RAD = (360-TMPDIR) * 3.141592654 / 180.0
                        INPSTA_WINDX(B,3) = SIN(THETA_RAD)*TMPSPD
                        INPSTA_WINDY(B,3) =-1.0 * COS(THETA_RAD)*TMPSPD
                    END IF
                  ELSE
                    INPSTA_WINDX(B,3) = -999.D0
                    INPSTA_WINDY(B,3) = -999.D0
                  ENDIF
                ENDDO ! B
              ENDIF !IF(AT_WIND(A).EQ.AT)
            ENDDO ! A
            
            CALL IDWM_T2D(INPSTA_WINDX,POINTS,OUT_WDIRX,NPOIN,NUMSTA)
            CALL IDWM_T2D(INPSTA_WINDY,POINTS,OUT_WDIRY,NPOIN,NUMSTA)
            

!       FINAL WINDX AND WINDY OUTPUT
            DO K = 1,NPOIN
              WINDX(K) = OUT_WDIRX(K)
              WINDY(K) = OUT_WDIRY(K)
            END DO
!
! #######################################################################
!
          ENDIF ! OPTWIND.EQ.3
          ENDIF
        ENDIF
!
!       WIND AND/OR WATER QUALITY VARIABLES
!       VARYING IN SPACE AND TIME, FROM A BINARY FILE
!
        IF(FILES(ATMFILEB)%NAME(1:1).NE.' ') THEN
          IF(FILES(ATMFILEA)%NAME(1:1).NE.' ')THEN
            IF(LNG.EQ.1.AND.LISTIN) THEN
              WRITE(LU,*) 'METEO : LES DONNEES DU FICHIER'
              WRITE(LU,*) 'DE METEO ASCII PRESENTES DANS LE'
              WRITE(LU,*) 'FICHIER METEO BINAIRE VONT ETRE ECRASEES'
            ENDIF
            IF(LNG.EQ.2.AND.LISTIN) THEN
              WRITE(LU,*) 'METEO: THE DATA FROM THE ASCII METEO'
              WRITE(LU,*) 'FILE WILL BE OVERWRITTEN BY THE'
              WRITE(LU,*) 'CORRESPONDING BINARY FILE DATA'
            ENDIF
          ENDIF
          CALL METEO_FROM_BINARY_FILE(PATMOS,WINDX,WINDY,AT,NPOIN,VENT,
     &                                ATMOS,ATMFILEB,FILES,LISTIN,
     &                                WATER_QUALITY,PLUIE,OPTWIND,
     &                                WIND_SPD)
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
      END
      
