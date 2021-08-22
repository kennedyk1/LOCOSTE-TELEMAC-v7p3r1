!                       *****************
                        SUBROUTINE TOM_CORFON
!                       *****************
!
!***********************************************************************
! PROGICIEL : TOMAWAC                          F. MARCOS
! FUSION TOMAWAC/COWADIS       12/01/01        OPTIMER (02 98 44 24 51)
!***********************************************************************
!
!  USER SUBROUTINE CORFON
!
!  FONCTION  : MODIFICATION DE LA TOPOGRAPHIE
!  FUNCTION  : MODIFICATION OF THE BOTTOM TOPOGRAPHY
!
!-----------------------------------------------------------------------
!  ARGUMENTS TO USE
! .________________.____._______________________________________________
! |      NAME      |MODE|                 FUNCTION
! |________________|____|_______________________________________________
! |      ZF        |<-->| BOTTOM
! |      X,Y       |<-->| MESH COORDINATES
! |      NPOIN2    | -->| NUMBER OF POINTS IN THE MESH
! |      LISFON    | -->| NUMBER OF BOTTOM SMOOTHINGS
! |      T1,2      |<-->| WORKING TABLES
! |      W1        |<-->| WORKING TABLE
! |________________|____|_______________________________________________
! MODE : -->(DONNEE NON MODIFIEE), <--(RESULTAT), <-->(DONNEE MODIFIEE)
!-----------------------------------------------------------------------
!
! PROGRAMME APPELANT :
! PROGRAMMES APPELES : RIEN EN STANDARD
!
!***********************************************************************
!
      USE BIEF
      USE DECLARATIONS_TOMAWAC
!
      IMPLICIT NONE
!
!      INTEGER LNG,LU
!      COMMON/INFO/LNG,LU
!
      INTEGER K
!
      DO K=1,NPOIN2
        IF (ZF(K).LT.-10.D0) THEN
          ZF(K)=ZF(K)
        ELSE
          ZF(K)=-10.D0
        ENDIF
      ENDDO
!
      RETURN
      END
!                       *****************
                        SUBROUTINE CORRXY(X,Y,NPOIN)
!                       *****************
!
!***********************************************************************
! PROGICIEL : BIEF 5.0          01/03/90    J-M HERVOUET
!***********************************************************************
!
!  USER SUBROUTINE CORRXY
!
!  FUNCTION  : MODIFICATION OF THE COORDINATES OF THE POINTS IN THE MESH
!
!              LINES WITH AN INITIAL CEX ARE AN EXAMPLE
!              WITH TELEMAC-2D
!
!              THIS SUBROUTINE MUST BE MODIFIED ACCORDING TO
!              THE CALLING PROGRAM AND THE NEEDED MODIFICATION
!              BY ADDING USE DECLARATIONS_"NAME OF CALLING CODE"
!              ALL THE DATA STRUCTURE OF THIS CODE IS
!              AVAILABLE
!
!-----------------------------------------------------------------------
!  ARGUMENTS USED IN THE EXAMPLE
! .________________.____.______________________________________________
! |      NOM       |MODE|                   ROLE
! |________________|____|_______________________________________________
! |    X,Y         | -->|  COORDONNEES DU MAILLAGE .                   |
! |    NPOIN2       | -->|  NOMBRE DE POINTS DU MAILLAGE                |
! |________________|____|______________________________________________
! MODE : -->(DONNEE NON MODIFIEE), <--(RESULTAT), <-->(DONNEE MODIFIEE)
!-----------------------------------------------------------------------
!
! PROGRAMME APPELANT :
! PROGRAMMES APPELES : RIEN EN STANDARD
!
!***********************************************************************
!
! APPELE PAR : INBIEF
!
! SOUS-PROGRAMME APPELE : NEANT
!
!***********************************************************************
!
      USE BIEF, EX_CORRXY => CORRXY
!
      USE DECLARATIONS_SPECIAL
!
      IMPLICIT NONE
      INTEGER, INTENT(IN) :: NPOIN
      DOUBLE PRECISION, INTENT(INOUT) :: X(NPOIN),Y(NPOIN)
!      INTEGER LNG,LU
!      COMMON/INFO/LNG,LU
      INTEGER I
      DOUBLE PRECISION R,TG23P,PI
!
!
      PI=3.1415926D0
      R=6400.D3
      TG23P=TAN(23.D0*PI/60.D0)
      DO I=1,NPOIN
        X(I)=X(I)*180.D0/R/PI
        Y(I)=360.D0/PI*ATAN(EXP(Y(I)/R)*TG23P)-90.D0
      ENDDO
!
      RETURN
      END
!                    *****************
                     SUBROUTINE LIMWAC
!                    *****************
!
     &(F     , FBOR  , LIFBOR, NPTFR , NPLAN , NF    ,  TETA , FREQ  ,
     & NPOIN2, NBOR  , AT    , LT    , DDC   , LIMSPE, FPMAXL, FETCHL,
     & SIGMAL, SIGMBL, GAMMAL, FPICL , HM0L  , APHILL, TETA1L, SPRE1L,
     & TETA2L, SPRE2L, XLAMDL, X ,Y  , KENT  , KSORT , NFO1  , NBI1  ,
     & FMTBI1, UV    , VV    , SPEULI, VENT  , VENSTA, GRAVIT,
     & PRIVE , NPRIV , SPEC  , FRA   , DEPTH , FRABL ,BOUNDARY_COLOUR,
     & IMP_FILE)
!
!***********************************************************************
! TOMAWAC   V7P3                                   23/02/2017
!***********************************************************************
!
!brief    BOUNDARY CONDITIONS.
!
!warning  BY DEFAULT, THE BOUNDARY CONDITIONS SPECIFIED IN THE FILE
!+            DYNAM ARE DUPLICATED ON ALL THE DIRECTIONS AND FREQUENCIES
!
!history  F. MARCOS (LNH)
!+        01/02/95
!+        V1P0
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
!history  G.MATTAROLO (EDF - LNHE)
!+        20/06/2011
!+        V6P1
!+   Translation of French names of the variables in argument
!
!history  E. GAGNAIRE-RENOU & J.-M. HERVOUET (EDF R&D, LNHE)
!+        12/03/2013
!+        V6P3
!+   A line IF(LIMSPE.EQ.0...) RETURN removed.
!
!history  A. JOLY (EDF R&D, LNHE)
!+        23/02/2017
!+        V7P3
!+   SPECTRA READ FROM AN EXTERNAL MESH CAN NOW BE IMPOSED ON THE
!+   OPEN BOUNDARIES.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| APHILL         |-->| BOUNDARY PHILLIPS CONSTANT
!| AT             |-->| COMPUTATION TIME
!| FMTBI1         |-->| BINARY FILE 1 FORMAT
!| BOUNDARY_COLOUR|-->| COLOUR OF BOUNDARY POINT (DEFAULT: ITS RANK)
!| DDC            |-->| DATE OF COMPUTATION BEGINNING
!| DEPTH          |-->| WATER DEPTH
!| F              |-->| VARIANCE DENSITY DIRECTIONAL SPECTRUM
!| FBOR           |<->| SPECTRAL VARIANCE DENSITY AT THE BOUNDARIES
!| FETCHL         |-->| BOUNDARY MEAN FETCH VALUE
!| FPICL          |-->| BOUNDARY PEAK FREQUENCY
!| FPMAXL         |-->| BOUNDARY MAXIMUM PEAK FREQUENCY
!| FRA            |<--| DIRECTIONAL SPREADING FUNCTION VALUES
!| FRABL          |-->| BOUNDARY ANGULAR DISTRIBUTION FUNCTION
!| FREQ           |-->| DISCRETIZED FREQUENCIES
!| GAMMAL         |-->| BOUNDARY PEAK FACTOR
!| GRAVIT         |-->| GRAVITY ACCELERATION
!| HM0L           |-->| BOUNDARY SIGNIFICANT WAVE HEIGHT
!| IMP_FILE       |-->| MESH FILE WITH THE IMPOSED SPECTRA
!| KENT           |-->| B.C.: A SPECTRUM IS PRESCRIBED AT THE BOUNDARY
!| KSORT          |-->| B.C.: FREE BOUNDARY: NO ENERGY ENTERING THE DOMAIN
!| LIFBOR         |-->| TYPE OF BOUNDARY CONDITION ON F
!| LIMSPE         |-->| TYPE OF BOUNDARY DIRECTIONAL SPECTRUM
!| LT             |-->| NUMBER OF THE TIME STEP CURRENTLY SOLVED
!| NBI1           |-->| LOGICAL UNIT NUMBER OF THE USER BINARY FILE
!| NBOR           |-->| GLOBAL NUMBER OF BOUNDARY POINTS
!| NF             |-->| NUMBER OF FREQUENCIES
!| NFO1           |-->| LOGICAL UNIT NUMBER OF THE USER FORMATTED FILE
!| NPLAN          |-->| NUMBER OF DIRECTIONS
!| NPOIN2         |-->| NUMBER OF POINTS IN 2D MESH
!| NPRIV          |-->| NUMBER OF PRIVATE ARRAYS
!| NPTFR          |-->| NUMBER OF BOUNDARY POINTS
!| PRIVE          |-->| USER WORK TABLE
!| SIGMAL         |-->| BOUNDARY SPECTRUM VALUE OF SIGMA-A
!| SIGMBL         |-->| BOUNDARY SPECTRUM VALUE OF SIGMA-B
!| SPEC           |<--| VARIANCE DENSITY FREQUENCY SPECTRUM
!| SPEULI         |-->| INDICATES IF B.C. SPECTRUM IS MODIFIED BY USER
!| SPRE1L         |-->| BOUNDARY DIRECTIONAL SPREAD 1
!| SPRE2L         |-->| BOUNDARY DIRECTIONAL SPREAD 2
!| TETA           |-->| DISCRETIZED DIRECTIONS
!| TETA1L         |-->| BOUNDARY MAIN DIRECTION 1
!| TETA2L         |-->| BOUNDARY MAIN DIRECTION 2
!| UV, VV         |-->| WIND VELOCITIES AT THE MESH POINTS
!| VENSTA         |-->| INDICATES IF THE WIND IS STATIONARY
!| VENT           |-->| INDICATES IF WIND IS TAKEN INTO ACCOUNT
!| X              |-->| ABSCISSAE OF POINTS IN THE MESH
!| XLAMDL         |-->| BOUNDARY WEIGHTING FACTOR FOR ANGULAR
!|                |   | DISTRIBUTION FUNCTION
!| Y              |-->| ORDINATES OF POINTS IN THE MESH
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE INTERFACE_TOMAWAC, EX_LIMWAC => LIMWAC
      USE DECLARATIONS_TOMAWAC, ONLY : UV2D,VV2D,PROF,FB_CTE,NPB
      USE DECLARATIONS_SPECIAL
      USE BND_SPECTRA
      USE BIEF_DEF, ONLY : BIEF_FILE
      IMPLICIT NONE
!
!
      INTEGER, INTENT(IN)            :: NPTFR,NPLAN,NF,NPOIN2,LT,NPRIV
      INTEGER, INTENT(IN)            :: LIMSPE,KENT,KSORT,FRABL
      INTEGER, INTENT(IN)            :: NFO1,NBI1
      INTEGER, INTENT(IN)            :: LIFBOR(NPTFR),NBOR(NPTFR)
      INTEGER, INTENT(IN)            :: BOUNDARY_COLOUR(NPTFR)
      DOUBLE PRECISION, INTENT(IN)   :: TETA(NPLAN),FREQ(NF)
      DOUBLE PRECISION, INTENT(IN)   :: X(NPOIN2),Y(NPOIN2)
      DOUBLE PRECISION, INTENT(IN)   :: UV(NPOIN2),VV(NPOIN2)
      DOUBLE PRECISION, INTENT(INOUT):: SPEC(NF)
      DOUBLE PRECISION, INTENT(IN)   ::PRIVE(NPOIN2,NPRIV),DEPTH(NPOIN2)
      DOUBLE PRECISION, INTENT(IN)   :: AT,DDC,FPMAXL,FETCHL,SIGMAL
      DOUBLE PRECISION, INTENT(IN)   :: GAMMAL,FPICL, SIGMBL
      DOUBLE PRECISION, INTENT(IN)   :: HM0L  , APHILL,TETA1L,SPRE1L
      DOUBLE PRECISION, INTENT(IN)   :: SPRE2L,XLAMDL,TETA2L
      DOUBLE PRECISION, INTENT(IN)   :: GRAVIT
      LOGICAL,          INTENT(IN)   :: SPEULI, VENT, VENSTA
      CHARACTER(LEN=8), INTENT(IN)   :: FMTBI1
      TYPE(BIEF_FILE), INTENT(IN)    :: IMP_FILE
      DOUBLE PRECISION, INTENT(INOUT):: F(NPOIN2,NPLAN,NF), FRA(NPLAN)
      DOUBLE PRECISION, INTENT(INOUT):: FBOR(NPTFR,NPLAN,NF)
!
      INTEGER NPCL
      PARAMETER (NPCL=21)
      INTEGER IFF,IPLAN,IPTFR,NPCLI
!
!     DOUBLE PRECISION, ALLOCATABLE :: TRAV(:)
      DOUBLE PRECISION E2FMIN
      LOGICAL FLAG
      DOUBLE PRECISION AT1,AT2,COEF2,ATT,C,FCL1,FCL2,COEF
      DOUBLE PRECISION CL1(12,25,NPCL),CL2(12,25,NPCL)
      INTEGER IFRM,IFRP,NBP,NBM,NENR,NPB2(NPCL),IP,I
!
      SAVE AT1,AT2,CL1,CL2,NENR,NPCLI,NPB2
!
!
!***********************************************************************
!
!     MODIFIES THE TYPE OF BOUNDARY CONDITION (OPTIONAL)
!
!     CAN BE CODED BY THE USER (SPEULI=.TRUE.)
!
!     LIFBOR(IPTFR)=KENT OR KSORT
!
      FLAG=.FALSE.
      IF (VENT .AND. (LIMSPE.EQ.1 .OR. LIMSPE.EQ.2 .OR. LIMSPE.EQ.3
     & .OR. LIMSPE.EQ.5)) FLAG=.TRUE.
!
!     THE FIRST TIME, ALLOCATES MEMORY FOR THE USEFUL ARRAYS
!     ---------------------------------------------------------------
!
      IF(LT.LT.1) THEN
        NPB=1
        IF(FLAG) THEN
          ALLOCATE(UV2D(1:NPTFR),VV2D(1:NPTFR))
          NPB=NPTFR
        ENDIF
        IF(LIMSPE.EQ.7 .OR. SPEULI) THEN
          IF (.NOT.ALLOCATED(PROF)) ALLOCATE(PROF(1:NPTFR))
          NPB=NPTFR
        ENDIF
        IF(NPB.EQ.1) THEN
          IF (.NOT.ALLOCATED(FB_CTE)) ALLOCATE(FB_CTE(1:NPLAN,1:NF))
        ENDIF
      ENDIF
      IF (.NOT.ALLOCATED(UV2D)) ALLOCATE(UV2D(NPTFR))
      IF (.NOT.ALLOCATED(VV2D)) ALLOCATE(VV2D(NPTFR))
      IF (.NOT.ALLOCATED(PROF)) ALLOCATE(PROF(NPTFR))
      IF (.NOT.ALLOCATED(FB_CTE)) ALLOCATE(FB_CTE(1:NPLAN,1:NF))
!
!     THE FIRST TIME (AND POSSIBLY SUBSEQUENTLY IF THE WIND IS NOT
!     STATIONARY AND IF THE BOUNDARY SPECTRUM DEPENDS ON IT),
!     COMPUTES THE BOUNDARY SPECTRUM
!
      IF(LT.LT.1 .OR. (.NOT.VENSTA.AND.FLAG) .OR. SPEULI .OR.
     &   (IMP_FILE%NAME(1:1).NE.' ')) THEN
        IF(FLAG) THEN
          DO IPTFR=1,NPTFR
            UV2D(IPTFR)=UV(NBOR(IPTFR))
            VV2D(IPTFR)=VV(NBOR(IPTFR))
          ENDDO
        ENDIF
        IF(LIMSPE.EQ.7 .OR. SPEULI) THEN
          DO IPTFR=1,NPTFR
            PROF(IPTFR)=DEPTH(NBOR(IPTFR))
          ENDDO
        ENDIF
!
        E2FMIN = 1.D-30
!
!       WHEN NPB=1 FBOR ONLY FILLED FOR FIRST POINT
!
!       SPECTRUM ON BOUNDARIES
!
        IF(NPB.EQ.NPTFR) THEN
          CALL SPEINI
     &(   FBOR  ,SPEC  ,FRA   ,UV2D  ,VV2D  ,FREQ ,
     &    TETA  ,GRAVIT,FPMAXL,FETCHL,SIGMAL,SIGMBL,GAMMAL,FPICL,
     &    HM0L  ,APHILL,TETA1L,SPRE1L,TETA2L,SPRE2L,XLAMDL,
     &    NPB   ,NPLAN ,NF    ,LIMSPE,E2FMIN,PROF  ,FRABL )
        ELSE
          CALL SPEINI
     &(   FB_CTE,SPEC  ,FRA   ,UV2D  ,VV2D  ,FREQ ,
     &    TETA  ,GRAVIT,FPMAXL,FETCHL,SIGMAL,SIGMBL,GAMMAL,FPICL,
     &    HM0L  ,APHILL,TETA1L,SPRE1L,TETA2L,SPRE2L,XLAMDL,
     &    NPB   ,NPLAN ,NF    ,LIMSPE,E2FMIN,PROF  ,FRABL )
        ENDIF
!
!       IF THERE IS A MESHED FILE WITH THE BOUNDARY SPECTRA
!       THEY NEED TO BE IMPOSED
!
        IF(IMP_FILE%NAME(1:1).NE.' ')THEN
          CALL IMPOSE_BND_SPECTRA(IMP_FILE,LT,AT,FBOR,NPTFR,NPLAN,NF)
        ENDIF
!
!     ===========================================================
!     TO BE MODIFIED BY USER - RESU CAN BE CHANGED
!     ===========================================================
!
        IF (SPEULI) THEN
          IF (LT.EQ.0) THEN
            REWIND NFO1
            READ(NFO1,1000) NPCLI
            IF (NPCLI.NE.0) THEN
              READ(NFO1,2000) (NPB2(I),I=1,NPCLI)
              READ(NFO1,3000) AT1
              ATT=AT1
              CALL TEMP(AT1,ATT,DDC)
              IF (AT1.GT.AT) THEN
                PRINT*,'ERREUR DEMARAGE LECTURE',AT1,AT
                CALL PLANTE(0)
              ENDIF
50            CONTINUE
              DO 40 IP=1,NPCLI
                READ(NFO1,4000) ((CL1(I,IFF,IP),I=1,NPLAN),IFF=1,NF)
40            CONTINUE
              READ(NFO1,3000) AT2
              ATT=AT2
              CALL TEMP(AT2,ATT,DDC)
              IF (AT2.LT.AT) THEN
                AT1=AT2
                GOTO 50
              ENDIF
              DO 60 IP=1,NPCLI
                READ(NFO1,4000) ((CL2(I,IFF,IP),I=1,NPLAN),IFF=1,NF)
60            CONTINUE
              NENR=2
            ENDIF !NPCLI.NE.0
          ELSE !LT.EQ.0
            IF (NPCLI.NE.0) THEN
              IF (AT.GT.AT2) THEN
                AT1=AT2
                CALL OV('X=Y     ', CL1 , CL2 , CL1 , C , 300*NPCLI)
                PRINT*,'NOUVEL ENREGISTREMENT LIMWAC'
                READ(NFO1,3000) AT2
                NENR=NENR+1
                ATT=AT2
                CALL TEMP(AT2,ATT,DDC)
                IF (AT2.LT.AT) THEN
                  PRINT*,'LIMWAC : ON SAUTE 2 ENREGISTREMENT',AT,AT2
                  CALL PLANTE(0)
                ENDIF
                DO 70 IP=1,NPCLI
                  READ(NFO1,4000) ((CL2(I,IFF,IP),I=1,NPLAN),IFF=1,NF)
 70             CONTINUE
              ENDIF
            ENDIF
          ENDIF
          COEF=(AT-AT1)/(AT2-AT1)
          DO 5 IP=1,NPCLI-1
            IFRP=NPCLI-IP+1
            IFRM=NPCLI-IP
            NBP=NPB2(IFRP)
            NBM=NPB2(IFRM)
            IF (NBP.GT.NBM) NBM=NPTFR
            DO 10 IPTFR=NBP,NBM
              DO 20 IPLAN=1,NPLAN
                DO 30 IFF=1,NF
                  IF (LIFBOR(IPTFR).EQ.KENT) THEN
                    COEF2=REAL(IPTFR-NBM)/REAL(NBP-NBM)
                    FCL1=CL1(IPLAN,IFF,IFRM)+COEF2*
     &                (CL1(IPLAN,IFF,IFRP)-CL1(IPLAN,IFF,IFRM))
                    FCL2=CL2(IPLAN,IFF,IFRM)+COEF2*
     &                (CL2(IPLAN,IFF,IFRP)-CL2(IPLAN,IFF,IFRM))
                    FBOR(IPTFR,IPLAN,IFF)=FCL1+(FCL2-FCL1)*COEF
                  ENDIF
30              CONTINUE
20            CONTINUE
10          CONTINUE
 5        CONTINUE
        ENDIF !SPEULI
1000  FORMAT(I5)
2000  FORMAT(21I5)
3000  FORMAT(F9.1)
4000  FORMAT(5G16.7)
!     ===========================================================
!     END OF USER MODIFICATIONS
!     ===========================================================
!
      ENDIF !SPEULI.OR.LT.LT.1.OR....
!
!     -----------------------------------------------------------------
!     DUPLICATES THE BOUNDARY CONDITION FROM DYNAM ON ALL THE
!     DIRECTIONS AND FREQUENCIES, IF LIQUID BOUNDARY
!     -----------------------------------------------------------------
!
      IF(FLAG.OR.LIMSPE.EQ.7.OR.SPEULI.OR.
     &   (IMP_FILE%NAME(1:1).NE.' ')) THEN
        DO IPTFR=1,NPTFR
          IF(LIFBOR(IPTFR).EQ.KENT) THEN
            DO IFF=1,NF
              DO IPLAN=1,NPLAN
                F(NBOR(IPTFR),IPLAN,IFF)=FBOR(IPTFR,IPLAN,IFF)
              ENDDO
            ENDDO
          ENDIF
        ENDDO
      ELSE
        DO IPTFR=1,NPTFR
          IF(LIFBOR(IPTFR).EQ.KENT) THEN
            DO IFF=1,NF
              DO IPLAN=1,NPLAN
                F(NBOR(IPTFR),IPLAN,IFF)=FB_CTE(IPLAN,IFF)
              ENDDO
            ENDDO
          ENDIF
        ENDDO
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
      END
!                       ***************
                        SUBROUTINE TEMP
!                       ***************
!
     &(TV ,DAT,DDC)
!
!***********************************************************************
!  TOMAWAC VERSION 1.0    01/02/95        F.MARCOS     (LNH) 30 87 72 66
!***********************************************************************
!
!   FONCTION : CE SOUS-PROGRAMME CALCULE LE TEMPS EN SECONDE
!              ENTRE LES DATES DAT ET DDC
!
!-----------------------------------------------------------------------
!                             ARGUMENTS
! .________________.____.______________________________________________.
! !      NOM       !MODE!                   ROLE                       !
! !________________!____!______________________________________________!
! !    TV          !<-- !  ECART DE TEMPS EN SECONDES                  !
! !    DAT         ! -->!  DATE D'UN ENREGISTREMENT DES VENTS          !
! !    DDC         ! -->!  DATE DU DEBUT DU CALCUL                     !
! !________________!____!______________________________________________!
! MODE : -->(DONNEE NON MODIFIEE), <--(RESULTAT), <-->(DONNEE MODIFIEE)
!
!-----------------------------------------------------------------------
!
! APPELE PAR : LECVEN
!
! SOUS-PROGRAMME APPELE : AUCUN
!
!***********************************************************************
!
      IMPLICIT NONE
!
      INTEGER ADC,MDC,JDC,HDC,MNDC,ADT,MDT,JDT,HDT,MNDT
      INTEGER NJDM(0:12)
      DOUBLE PRECISION TV,DDC,DAT
!
!-----------------------------------------------------------------------
!
      DATA NJDM /0,0,31,59,90,120,151,181,212,243,273,304,334/
!       ON NE TRAITE PAS LES ANNEES BISSEXTILES !!
!
!  DECODAGE DE LA DATE DU DEBUT DU CALCUL
!
      ADC=INT(DDC*1.D-8)
      MDC=INT(DDC*1.D-6)
      JDC=INT(DDC*1.D-4)
      HDC=INT(DDC*1.D-2)
      MNDC=INT(DDC-100.D0*HDC)
      HDC =HDC-100*JDC
      JDC =JDC-100*MDC
      MDC =MDC-100*ADC
!
!  DECODAGE DE LA DATE DE L'ENREGISTREMENT DU VENT
!
      ADT=INT(DAT*1.D-8)
      MDT=INT(DAT*1.D-6)
      JDT=INT(DAT*1.D-4)
      HDT=INT(DAT*1.D-2)
      MNDT=INT(DAT-100.D0*HDT)
      HDT =HDT-100*JDT
      JDT =JDT-100*MDT
      MDT =MDT-100*ADT
!
      TV=((((ADT-ADC)*365+(JDT+NJDM(MDT)-JDC-NJDM(MDC)))*24 +
     &     HDT-HDC)*60 + MNDT-MNDC)*60
!
      RETURN
      END
