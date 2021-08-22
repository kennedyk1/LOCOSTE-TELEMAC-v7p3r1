!                    ************************
                     PROGRAM HOMERE_TELEMAC2D
!                    ************************
!
!
!***********************************************************************
! TELEMAC2D   V7P3
!***********************************************************************
!
!brief    1) READS ALL NECESSARY DATA.
!+
!+            2) CALLS TELEMAC2D AND SISYPHE IN CASE OF COUPLING.
!
!note     IN CASE OF PARAMETER ESTIMATION, HOMERE_ADJ_T2D IS
!+            CALLED INSTEAD OF HOMERE_TELEMAC2D.
!
!history  R. ATA
!+        10/11/2014
!+        V7P0
!+        add waq variables for lecdon_telemac2d
!
!history  F. HUANG (CLARKSON U.) AND S.E. BOURBAN (HRW)
!+        19/11/2016
!+        V7P3
!+        Coupling TELEMAC-2D with RICE-2D (ice modelling component)
!
!history  A. LEROY (LNHE) & J-M HERVOUET (jubilado)
!+        26/09/2017
!+        V7P3
!+        Convergence procedure updated.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TELEMAC, ONLY : COUPLING,DEJA_PDEPT,INDIC_PDEPT,
     &                                 DEJA_CPOS,INDIC_CPOS,
     &                                 DEJA_CPOS2,INDIC_CPOS2
      USE DECLARATIONS_TELEMAC2D
      USE DECLARATIONS_SISYPHE, ONLY : SIS_FILES,MAXLU_SIS
      USE DECLARATIONS_TOMAWAC, ONLY : WAC_FILES,MAXLU_WAC
      USE DECLARATIONS_WAQTEL,  ONLY : WAQ_FILES,MAXLU_WAQ,WAQPROCESS
      USE DECLARATIONS_RICE2D,  ONLY : ICE_FILES,MAXLU_ICE
      USE INTERFACE_TELEMAC2D
      USE INTERFACE_WAQTEL
      USE INTERFACE_STBTEL
      USE DECLARATIONS_SPECIAL
!
      IMPLICIT NONE
!
      INTEGER TDEB(8),TFIN(8),NCAR,IFLOT
!
      CHARACTER(LEN=24), PARAMETER :: CODE2='SISYPHE                 '
      CHARACTER(LEN=24), PARAMETER :: CODE3='TOMAWAC                 '
      CHARACTER(LEN=24), PARAMETER :: CODE4='WAQTEL                  '
      CHARACTER(LEN=24), PARAMETER :: CODE5='RICE2D                  '
!
      CHARACTER(LEN=MAXLENTMPDIR) PATH
      CHARACTER(LEN=144) MOTCAR(MAXKEYWORD),FILE_DESC(4,MAXKEYWORD)
      CHARACTER(LEN=144) DUMMY
!
      INTEGER IERR,ITRAC
      INTEGER, DIMENSION(:,:), TARGET, ALLOCATABLE :: CORRESP
!
!======================================================================
!
!##>JR @ ADJOINTWARE: ALGORITHMIC DIFFERENTIATION
#if defined COMPAD
      CALL AD_TELEMAC2D_MAIN_INIT
#endif
!##<JR @ ADJOINTWARE
!
!-----------------------------------------------------------------------
!
!     INITIALISES FILES (NAMES OF FILES=' ' AND LOGICAL UNITS =0)
!     GETTING NCSIZE BY CALLING P_INIT
!
      CALL BIEF_INIT(CODE1,PATH,NCAR,.TRUE.)
!
!     INITIAL TIME FOR COMPUTATION DURATION
!
      CALL DATE_AND_TIME(VALUES=TDEB)
!
!     PRINTS BANNER TO LISTING
!
      CALL PRINT_HEADER(CODE1,'                        ')
!
!-----------------------------------------------------------------------
!
!     READS THE STEERING FILE
!
      DUMMY = ' '
!
      CALL LECDON_TELEMAC2D(MOTCAR,FILE_DESC,
     &                      PATH,NCAR,DUMMY,DUMMY)
!
!-----------------------------------------------------------------------
!
!##>JR @ ADJOINTWARE: ALGORITHMIC DIFFERENTIATION
#if defined COMPAD
      CALL AD_TELEMAC2D_MAIN_AFTER_LECDON_TELEMAC2D
#endif
!##<JR @ ADJOINTWARE
!
!-----------------------------------------------------------------------
!
!     OPENS THE FILES FOR TELEMAC2D
!
      IFLOT = 0
      CALL BIEF_OPEN_FILES(CODE1,T2D_FILES,MAXLU_T2D,PATH,NCAR,
     &                     1,.FALSE.)
!
!-----------------------------------------------------------------------
!
!     ALLOCATES MEMORY (AND LEVEL 0 OF REFINEMENT IF CONVERGENCE STUDY)
!
      RLEVEL=0
      CALL POINT_TELEMAC2D
!
!-----------------------------------------------------------------------
!
!     INITIALISES SISYPHE
!
      IF(INCLUS(COUPLING,'SISYPHE')) THEN
!
        CALL PRINT_HEADER(CODE2,CODE1)
!
      CALL LECDON_SISYPHE(MOTCAR,FILE_DESC,PATH,NCAR,
     &                    CODE1,DUMMY,DUMMY)
!
!-----------------------------------------------------------------------
!
!##>JR @ ADJOINTWARE: ALGORITHMIC DIFFERENTIATION
#if defined COMPAD
      CALL AD_TELEMAC2D_MAIN_AFTER_LECDON_SISYPHE
#endif
!##<JR @ ADJOINTWARE
!
!-----------------------------------------------------------------------
!
      CALL BIEF_OPEN_FILES(CODE2,SIS_FILES,MAXLU_SIS,PATH,NCAR,
     &                     2,.FALSE.)
!
!     RESETS TELEMAC2D CONFIGURATION
!
      CALL CONFIG_CODE(1)
!
!     MEMORY ORGANISATION
!
      CALL POINT_SISYPHE
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!     INITIALISES TOMAWAC
!
      IF(INCLUS(COUPLING,'TOMAWAC')) THEN
!
        CALL PRINT_HEADER(CODE3,CODE1)
!
      CALL LECDON_TOMAWAC(FILE_DESC,PATH,NCAR,CODE3)
!
!-----------------------------------------------------------------------
!
!##>JR @ ADJOINTWARE: ALGORITHMIC DIFFERENTIATION
#if defined COMPAD
      CALL AD_TELEMAC2D_MAIN_AFTER_LECDON_TOMAWAC
#endif
!##<JR @ ADJOINTWARE
!
!-----------------------------------------------------------------------
!
      CALL BIEF_OPEN_FILES(CODE3,WAC_FILES,MAXLU_WAC,PATH,NCAR,
     &                     3,.FALSE.)
!
!     RESETS TELEMAC2D CONFIGURATION
!
      CALL CONFIG_CODE(1)
!
!     MEMORY ORGANISATION
!
      CALL POINT_TOMAWAC
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!     INITIALISES WAQTEL
!
      IF(INCLUS(COUPLING,'WAQTEL')) THEN
!
!
        CALL PRINT_HEADER(CODE4,CODE1)
!
        CALL LECDON_WAQTEL(FILE_DESC,PATH,NCAR,CODE4)
        CALL BIEF_OPEN_FILES(CODE4,WAQ_FILES,MAXLU_WAQ,PATH,NCAR,
     &                       4,.FALSE.)
!
!       RESETS TELEMAC2D CONFIGURATION
!
        CALL CONFIG_CODE(1)
!
!       MEMORY ORGANISATION
!
        CALL POINT_WAQTEL(MESH,IELM1,VENT,WINDX,WINDY,ATMOS,
     &                    PATMOS)
!
      ENDIF

!-----------------------------------------------------------------------
!
!     INITIALISES RICE2D
!
      IF(INCLUS(COUPLING,'RICE2D')) THEN
!
        CALL PRINT_HEADER(CODE5,CODE1)
!
        CALL LECDON_RICE2D(FILE_DESC,PATH,NCAR,CODE5)
        CALL BIEF_OPEN_FILES(CODE5,ICE_FILES,MAXLU_ICE,PATH,NCAR,
     &                       5,.FALSE.)
!
!       RESETS TELEMAC2D CONFIGURATION
!
        CALL CONFIG_CODE(1)
!
!       MEMORY ORGANISATION
!
        CALL POINT_RICE2D(MESH,IELM1)
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!=======================================================================
!
      IF(ESTIME.EQ.' '.AND..NOT.CONVERGENCE) THEN
!
!-----------------------------------------------------------------------
!
!       STANDARD MODE: ONE TELEMAC2D CALL
!
        CALL TELEMAC2D(PASS=-1,ATDEP=0.D0,NITER=0,CODE='       ')
!
!-----------------------------------------------------------------------
!
      ELSE IF (ESTIME.EQ.' '.AND.CONVERGENCE) THEN
!
!       CONVERGENCE MODE
!       MESH REFINEMENT WITH RLEVELS DIVISIONS
!
        WRITE(LU,*) 'TELEMAC2D LAUNCHED IN CONVERGENCE MODE'
        WRITE(LU,*) '--------------------------------------'
        WRITE(LU,*) 'GENERATE THE FINEST MESH'
        WRITE(LU,*) 'WITH ', FINEMESH%NELMAX, 'ELEMENTS MAX'
        WRITE(LU,*) 'WITH ', FINEMESH%NELEM, 'INITIAL ELEMENTS'
        WRITE(LU,*) 'WITH ', FINEMESH%NPMAX, 'POINTS MAX'
        WRITE(LU,*) 'WITH ', FINEMESH%NPOIN, 'INITIAL POINTS'
        WRITE(LU,*) 'WITH ', FINEMESH%NPTFRX, 'BOUNDARY POINTS MAX'
        WRITE(LU,*) 'WITH ', FINEMESH%NPTFR, 'INITIAL BOUNDARY POINTS'
        ALLOCATE(CORRESP(FINEMESH%NELMAX,RLEVELS))
        CALL REFINE_MESH(RLEVELS,FINEMESH,FINEMESH%NELMAX,
     &                   FINEMESH%NPTFRX,NTRAC,.FALSE.,CORRESP=CORRESP)
        WRITE(LU,*) 'END OF THE FINE MESH GENERATION'
!
!       RLEVELS+1 TELEMAC2D CALLS WITH SUCCESSIVE REFINEMENTS
!
        WRITE(LU,*) 'ENTERING THE LOOP OF TELEMAC2D CALLS'
        DO RLEVEL = 1,RLEVELS+1
!
          WRITE(LU,*) 'CALL NUMBER ',RLEVEL,' TO TELEMAC2D'
          CALL TELEMAC2D(PASS=-1,ATDEP=0.D0,NITER=0,CODE='       ',
     &                   CONVERGENCE_LEVEL=RLEVEL)
!
          IF(NTRAC.GT.0) THEN
            DO ITRAC=1,NTRAC
              WRITE(LU,*) 'ERROR ON THE TRACER',ITRAC
              CALL ERROR_COMPUTATION(T%ADR(ITRAC)%P%R,MESH,FINEMESH,
     &                               FINEMESH%NELMAX,MESH%NPOIN,
     &                               CORRESP,RLEVELS,RLEVEL,MESH%IKLE%I,
     &                               FINEMESH%IKLE%I)
            ENDDO
          ENDIF
!
          IF(RLEVEL.EQ.RLEVELS+1) EXIT
          CALL REFINE_MESH(1,MESH,MESH%NELMAX,MESH%NPTFRX,
     &                     NTRAC,.TRUE.,LIHBOR=LIHBOR%I,LIUBOR=LIUBOR%I,
     &                     LIVBOR=LIVBOR%I,LITBOR=LITBOR,HBOR=HBOR%R,
     &                     UBOR=UBOR%R,VBOR=VBOR%R,CHBORD=CHBORD%R,
     &                     TBOR=TBOR,ATBOR=ATBOR,BTBOR=BTBOR,ZF=ZF,
     &                     H=H,TEXP=TEXP,TTILD=TTILD,TN=TN)
!         NEW SIZES OF ARRAYS
          CALL POINT_TELEMAC2D
          IF(DEJA_PDEPT) THEN
            DEALLOCATE(INDIC_PDEPT)
            DEJA_PDEPT=.FALSE.
          ENDIF
          IF(DEJA_CPOS) THEN
            DEALLOCATE(INDIC_CPOS)
            DEJA_CPOS=.FALSE.
          ENDIF
          IF(DEJA_CPOS2) THEN
            DEALLOCATE(INDIC_CPOS2)
            DEJA_CPOS2=.FALSE.
          ENDIF
!
        ENDDO
!
!-----------------------------------------------------------------------
!
      ELSE
!
!-----------------------------------------------------------------------
!
!       PARAMETER ESTIMATION MODE : CALLS HOMERE_ADJ_T2D
!
        CALL HOMERE_ADJ_T2D
!
      ENDIF
!
!=======================================================================
!
!     CLOSES FILES
!
      CALL BIEF_CLOSE_FILES(CODE1,T2D_FILES,MAXLU_T2D,.TRUE.)
!
      IF(INCLUS(COUPLING,'SISYPHE')) THEN
        CALL CONFIG_CODE(2)
        CALL BIEF_CLOSE_FILES(CODE2,SIS_FILES,MAXLU_SIS,.FALSE.)
      ENDIF
!
      IF(INCLUS(COUPLING,'TOMAWAC')) THEN
        CALL CONFIG_CODE(3)
        CALL BIEF_CLOSE_FILES(CODE3,WAC_FILES,MAXLU_WAC,.FALSE.)
      ENDIF
      IF(INCLUS(COUPLING,'WAQTEL')) THEN
        CALL CONFIG_CODE(4)
        CALL BIEF_CLOSE_FILES(CODE4,WAQ_FILES,MAXLU_WAQ,.FALSE.)
      ENDIF
      IF(INCLUS(COUPLING,'RICE2D')) THEN
        CALL CONFIG_CODE(5)
        CALL BIEF_CLOSE_FILES(CODE5,ICE_FILES,MAXLU_ICE,.FALSE.)
      ENDIF
!
!-----------------------------------------------------------------------
!
!##>JR @ ADJOINTWARE: ALGORITHMIC DIFFERENTIATION
#if defined COMPAD
      CALL AD_TELEMAC2D_MAIN_FINALIZE
#endif
!##<JR @ ADJOINTWARE
!
!-----------------------------------------------------------------------
!
      IF(LNG.EQ.1) WRITE(LU,10)
      IF(LNG.EQ.2) WRITE(LU,11)
10    FORMAT(1X,///,1X,'FIN NORMALE DU PROGRAMME',///)
11    FORMAT(1X,///,1X,'CORRECT END OF RUN',///)
!
!-----------------------------------------------------------------------
!
!     TIME OF END OF COMPUTATION
!
      CALL DATE_AND_TIME(VALUES=TFIN)
      CALL ELAPSE(TDEB,TFIN)
!
!-----------------------------------------------------------------------
!
      STOP 0
      END

