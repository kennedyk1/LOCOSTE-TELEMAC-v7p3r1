!                    ************************
                     SUBROUTINE LECDON_RICE2D
!                    ************************
!
     & (FILE_DESC,PATH,NCAR,CODE)
!
!***********************************************************************
! RICE-2D   V7P2                                             02/11/2016
!***********************************************************************
!
!brief    READS THE STEERING FILE THROUGH A DAMOCLES CALL.
!
!history  F. HUANG (CLARKSON U.) AND S.E. BOURBAN (HRW)
!+        11/11/2016
!+        V7P3
!+        Coupling TELEMAC-2D with RICE-2D (ice modelling component)
!+        Initial developments
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| CODE           |-->| NAME OF CALLING PROGRAMME
!| FILE_DESC      |-->| STORES THE FILES 'SUBMIT' ATTRIBUTES
!|                |   | IN DICTIONARIES. IT IS FILLED BY DAMOCLES.
!| NCAR           |-->| LENGTH OF PATH
!| PATH           |-->| NAME OF CURRENT DIRECTORY
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_SPECIAL
      USE DECLARATIONS_TELEMAC
      USE DECLARATIONS_RICE2D
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      CHARACTER(LEN=24), INTENT(IN)     :: CODE
      CHARACTER(LEN=144), INTENT(INOUT) :: FILE_DESC(4,MAXKEYWORD)
      INTEGER, INTENT(IN)               :: NCAR
      CHARACTER(LEN=250), INTENT(IN)    :: PATH
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      CHARACTER(LEN=8) ::   MNEMO(MAXICEVAR)
      INTEGER          ::   K,I
!
      CHARACTER(LEN=250) :: NOM_CAS
      CHARACTER(LEN=250) :: NOM_DIC
!
!-----------------------------------------------------------------------
!
! ARRAYS USED IN THE DAMOCLES CALL
!
      INTEGER            ADRESS(4,MAXKEYWORD),DIMEN(4,MAXKEYWORD)
      DOUBLE PRECISION   MOTREA(MAXKEYWORD)
      INTEGER            MOTINT(MAXKEYWORD)
      LOGICAL            MOTLOG(MAXKEYWORD)
      CHARACTER(LEN=144) MOTCAR(MAXKEYWORD)
      CHARACTER(LEN=72)  MOTCLE(4,MAXKEYWORD,2)
      INTEGER            TROUVE(4,MAXKEYWORD)
      LOGICAL            DOC
      INTEGER :: ID_DICO, ID_CAS
!
! END OF DECLARATIONS FOR DAMOCLES CALL
!
!***********************************************************************
!
      IF (LNG.EQ.1) WRITE(LU,1)
      IF (LNG.EQ.2) WRITE(LU,2)
1     FORMAT(1X,/,19X, '********************************************',/,
     &            19X, '*     SOUS-PROGRAMME LECDON_RICE2D         *',/,
     &            19X, '*           APPEL DE DAMOCLES              *',/,
     &            19X, '*     VERIFICATION DES DONNEES LUES        *',/,
     &            19X, '*           SUR LE FICHIER CAS             *',/,
     &            19X, '********************************************',/)
2     FORMAT(1X,/,19X, '********************************************',/,
     &            19X, '*        SUBROUTINE LECDON_RICE2D          *',/,
     &            19X, '*           CALL OF DAMOCLES               *',/,
     &            19X, '*        VERIFICATION OF READ DATA         *',/,
     &            19X, '*            ON STEERING FILE              *',/,
     &            19X, '********************************************',/)
!
!-----------------------------------------------------------------------
!
! INITIALISES THE VARIABLES FOR DAMOCLES CALL :
!
      DO K=1,MAXKEYWORD
!       A FILENAME NOT GIVEN BY DAMOCLES WILL BE RECOGNIZED AS A WHITE SPACE
!       (IT MAY BE THAT NOT ALL COMPILERS WILL INITIALISE LIKE THAT)
        MOTCAR(K)(1:1)=' '
!
        DIMEN(1,K) = 0
        DIMEN(2,K) = 0
        DIMEN(3,K) = 0
        DIMEN(4,K) = 0
      ENDDO
!
!     WRITES OUT INFO
      DOC = .FALSE.
!
!-----------------------------------------------------------------------
!     OPENS DICTIONNARY AND STEERING FILES
!-----------------------------------------------------------------------
!
      IF(NCAR.GT.0) THEN
!
        NOM_DIC=PATH(1:NCAR)//'ICEDICO'
        NOM_CAS=PATH(1:NCAR)//'ICECAS'
!
      ELSE
!
        NOM_DIC='ICEDICO'
        NOM_CAS='ICECAS'
!
      ENDIF
!
      CALL GET_FREE_ID(ID_DICO)
      OPEN(ID_DICO,FILE=NOM_DIC,FORM='FORMATTED',ACTION='READ')
      CALL GET_FREE_ID(ID_CAS)
      OPEN(ID_CAS,FILE=NOM_CAS,FORM='FORMATTED',ACTION='READ')
!
      CALL DAMOCLE
     &( ADRESS, DIMEN , MAXKEYWORD  , DOC    , LNG   , LU    , MOTINT,
     &  MOTREA, MOTLOG, MOTCAR, MOTCLE , TROUVE, ID_DICO, ID_CAS,
     &  .FALSE.,FILE_DESC)
!-----------------------------------------------------------------------
!     CLOSES DICTIONNARY AND STEERING FILES
!-----------------------------------------------------------------------
!
      CLOSE(ID_DICO)
      CLOSE(ID_CAS)
!
!     DECODES 'SUBMIT' CHAINS
!
      CALL READ_SUBMIT(ICE_FILES,MAXLU_ICE,CODE,FILE_DESC,300)
!
!-----------------------------------------------------------------------
!
!     RETRIEVES FILE NUMBERS FROM RICE2D FORTRAN PARAMETERS
!     AT THIS LEVEL LOGICAL UNITS ARE EQUAL TO THE FILE NUMBER
!
      DO I=1,MAXLU_ICE
        IF    (ICE_FILES(I)%TELNAME.EQ.'ICECLI') THEN
          ICECLI=I
        ELSEIF(ICE_FILES(I)%TELNAME.EQ.'ICEGEO') THEN
          ICEGEO=I
        ELSEIF(ICE_FILES(I)%TELNAME.EQ.'ICEHYD') THEN
          ICEHYD=I
        ELSEIF(ICE_FILES(I)%TELNAME.EQ.'ICEREF') THEN
          ICEREF=I
        ELSEIF(ICE_FILES(I)%TELNAME.EQ.'ICERES') THEN
          ICERES=I
        ENDIF
      ENDDO
!
!-----------------------------------------------------------------------
!
!     ASSIGNS THE STEERING FILE VALUES TO THE PARAMETER FORTRAN NAME
!
!-----------------------------------------------------------------------
!*******************************
!     INTEGER KEYWORDS         *
!*******************************
!
!     PRINTOUT RICE2D PERIOD
      LEOPRD    = MOTINT( ADRESS(1,  1) )
!
!     WEATHER TYPE
!      IWEATYPE = MOTINT( ADRESS(1, 14) )
!
!*******************************
!     REAL KEYWORDS            *
!*******************************
!       RHOW = MOTREA( ADRESS(2,1) )
!       RHOICE = MOTREA( ADRESS(2,2) )
!       RHOAIR = MOTREA( ADRESS(2,3) )
!       ROI = MOTREA( ADRESS(2,4) )
!       XLATEN = MOTREA( ADRESS(2,5) )
!       CP = MOTREA( ADRESS(2,6) )
!       CI = MOTREA( ADRESS(2,7) )
!       XNU = MOTREA( ADRESS(2,8) )
!       LDISP = MOTREA( ADRESS(2,9) )
!       TDISP = MOTREA( ADRESS(2,10) )
!       PHID = MOTREA( ADRESS(2,11) )
!       Z1 = MOTREA( ADRESS(2,12) )
!       ZH = MOTREA( ADRESS(2,13) )
!       ALPHSD = MOTREA( ADRESS(2,14) )
!       SIO = MOTREA( ADRESS(2,15) )
!       ALSM = MOTREA( ADRESS(2,16) )
!       ALLM = MOTREA( ADRESS(2,17) )
!
!       ETADIR = MOTREA( ADRESS(2,18) )
!       HWA = MOTREA( ADRESS(2,19) )
!       HIA = MOTREA( ADRESS(2,20) )
!       ALP = MOTREA( ADRESS(2,21) )
!
!       CWI1 = MOTREA( ADRESS(2,22) )
!       CIW1 = MOTREA( ADRESS(2,23) )
!       ATA = MOTREA( ADRESS(2,24) )
!       XKI = MOTREA( ADRESS(2,25) )
!       XKW = MOTREA( ADRESS(2,26) )
!
!       XKS = MOTREA( ADRESS(2,27) )
!       RHOS = MOTREA( ADRESS(2,28) )
!       SGMA = MOTREA( ADRESS(2,29) )
!       TMELT = MOTREA( ADRESS(2,30) )
!
!       TC = MOTREA( ADRESS(2,31) )
!       VCRSKM = MOTREA( ADRESS(2,32) )
!       VCRBOM = MOTREA( ADRESS(2,33) )
!       ANMAXBORDER = MOTREA( ADRESS(2,34) )
!
!       HI0 = MOTREA( ADRESS(2,35) )
!       HF0 = MOTREA( ADRESS(2,36) )
!       ANMAXFRA = MOTREA( ADRESS(2,37) )
!       ANMINFRA = MOTREA( ADRESS(2,38) )
!
!       EF = MOTREA( ADRESS(2,39) )
!       VNU = MOTREA( ADRESS(2,40) )
!       DF = MOTREA( ADRESS(2,41) )
!       DE = MOTREA( ADRESS(2,42) )
!
!       TUN = MOTREA( ADRESS(2,43) )
!       CA0 = MOTREA( ADRESS(2,44) )
!       CV0 = MOTREA( ADRESS(2,45) )
!       XKWP = MOTREA( ADRESS(2,46) )
!
!       UNPSIZE = MOTREA( ADRESS(2,47) )
!       UNTHETAC = MOTREA( ADRESS(2,48) )
!       UNMAXANP = MOTREA( ADRESS(2,49) )
!       UNALPHAV = MOTREA( ADRESS(2,50) )
!
!       STPV = MOTREA( ADRESS(2,51) )
!       CRIFR = MOTREA( ADRESS(2,52) )
!       UEROS = MOTREA( ADRESS(2,53) )
!       VCRFRZ = MOTREA( ADRESS(2,54) )
!       STRENGTH = MOTREA( ADRESS(2,55) )
!       ALBE = MOTREA( ADRESS(2,56) )
!       ALPW = MOTREA(ADRESS(2,57))
!       ALPHRD = MOTREA(ADRESS(2,58))
!*******************************
!     LOGICAL KEYWORDS         *
!*******************************
!
!      ICEBILMAS= MOTLOG( ADRESS(3,  1) )
!      ICEVALID = MOTLOG( ADRESS(3,  3) )
!       ICEDYNAMICS = MOTLOG(ADRESS(3,9))
!       ITHERMOSWITCH = MOTLOG(ADRESS(3,10))
!       IUNDERCOVERTRANSPORTSWITCH = MOTLOG(ADRESS(3,11))
!       IBREAKUPSWITCH = MOTLOG(ADRESS(3,12))
!
!*******************************
!     STRING KEYWORDS          *
!*******************************
!
      TITICECAS = MOTCAR( ADRESS(4, 3) )(1:72)
!
! FILES IN THE STEERING FILE
!
      ICE_FILES(ICECLI)%NAME=MOTCAR( ADRESS(4,4 ) )
      ICE_FILES(ICEGEO)%NAME=MOTCAR( ADRESS(4,5 ) )
      ICE_FILES(ICEGEO)%FMT=MOTCAR( ADRESS(4,35) )(1:8)
      ICE_FILES(ICEREF)%NAME=MOTCAR( ADRESS(4,6) )
      ICE_FILES(ICEREF)%FMT=MOTCAR( ADRESS(4,36) )(1:8)
      ICE_FILES(ICERES)%NAME=MOTCAR( ADRESS(4,7 ) )
      ICE_FILES(ICERES)%FMT=MOTCAR( ADRESS(4,37) )(1:8)
      ICE_FILES(ICEHYD)%NAME=MOTCAR( ADRESS(4,8) )
      ICE_FILES(ICEHYD)%FMT=MOTCAR( ADRESS(4,38) )(1:8)
!
!
!-----------------------------------------------------------------------
!  NAME OF THE VARIABLES FOR THE RESULTS AND GEOMETRY FILES:
!-----------------------------------------------------------------------
!
!-----------------------------------------------------------------------
!
!      IF(ITHERMOSWITCH) THEN
!        IND_F = NTRAC
!        NAMETRAC(IND_F) = 'FRAZIL                          '
!      ENDIF

      RETURN
      END SUBROUTINE
