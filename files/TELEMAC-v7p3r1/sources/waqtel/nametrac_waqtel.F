!                     **************************
                      SUBROUTINE NAMETRAC_WAQTEL
!                     **************************
!
     &  (NAMETRAC,NTRAC,PROCESS)
!
!
!***********************************************************************
! WAQTEL      V7P3
!***********************************************************************
!
!brief    Gives names to tracers added by the water quality
!
!
!history  R.ATA
!+        12/09/2014
!+        V7P0
!+        CREATION
!
!history  M.JODEAU
!+        05/2016
!+        V7P3
!+        AED2 coupling
!
!history  S.E. BOURBAN (HRW)
!+        07/06/2017
!+        V7P3
!+        Re-working NAMETRAC to avoid conflicting naming convention
!+        between user defined tracers, water quality processes and
!+        ice processes.
!+
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| NAMETRAC       |<->| ARRAY OF NAMES OF TRACERS
!| NTRAC          |-->| MODIFYING NUMBER OF TRACER IF NECESARY
!| PROCESS        |-->| ALSO WAQPROCESS, DEFINES THE WATER PROCESSES
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_SPECIAL
      USE DECLARATIONS_WAQTEL
      USE INTERFACE_WAQTEL, EX_NAMETRAC_WAQTEL => NAMETRAC_WAQTEL
#if defined HAVE_AED2
      USE T3D_AED2
#endif
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
!
      INTEGER          , INTENT(IN   )::  PROCESS
      INTEGER          , INTENT(INOUT)::  NTRAC
      CHARACTER(LEN=32), INTENT(INOUT)::  NAMETRAC(*)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
! AED2
#if defined HAVE_AED2
      CHARACTER(LEN=16),ALLOCATABLE :: NAMESAED2(:)
      INTEGER I
#endif
!
!-----------------------------------------------------------------------
!
      WAQPROCESS = PROCESS
!     FOR THE CASE AED2 (6), WAQTR HAS BEEN CALCULATED BEFORE, WHEN
!     CALLING INIT_AED2_MODELS IN LECDON_TELEMAC3D
!     WAQTR = 0
      RANKTR = 0
!
      IND_T = 0     ! TEMPERATURE
      IND_O2 = 0    ! DISSOLVED O2
      IND_OL = 0    ! ORGANIC LOAD
      IND_NH4 = 0   ! NH4 LOAD
      IND_PHY = 0   ! PHYTO BIOMASS
      IND_PO4 = 0   ! DISSOLVED PO4
      IND_POR = 0   ! POR NON ASSIM
      IND_NO3 = 0   ! DISSOLVED NO3
      IND_NOR = 0   ! NOR NON ASSIM
      IND_SS = 0    ! SUSPENDED LOAD
      IND_SF = 0    ! BED SEDIMENTS
      IND_C = 0     ! MICRO POLLUTANT
      IND_CSS = 0   ! ABS. SUSP. LOAD.
      IND_CSF = 0   ! ABSORB. BED SED.
      IND_AED2 = 0  ! ARRAY FOR AED2 WQ LIBRARY

!
      SELECT CASE(WAQPROCESS)
!
!       O2 MODULE
        CASE(1)
          WAQTR = 3
!       1. ~~> DISSOLVED O2
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_O2,
     &      'O2 DISSOUS      ','DISSOLVED O2    ','   mgO2/l       ')
          RANKTR(1) = IND_O2
!       2. ~~> ORGANIC LOAD
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_OL,
     &      'CHARGE ORGANIQUE','ORGANIC LOAD    ','   mgO2/l       ')
          RANKTR(2) = IND_OL
!       3. ~~> NH4 LOAD
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_NH4,
     &      'CHARGE NH4      ','NH4 LOAD        ','   mgNH4/l      ')
          RANKTR(3) = IND_NH4
!
!       BIOMASS MODULE
        CASE(2)
          WAQTR = 5
!       1. ~~> PHYTO BIOMASS
          CALL ADDTRACER(NAMETRAC, NTRAC,
     &      IND_PHY,
     &      'BIOMASSE PHYTO  ','PHYTO BIOMASS   ',' micro_g/l      ')
          RANKTR(1) = IND_PHY
!       2. ~~> DISSOLVED PO4
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_PO4,
     &      'PO4 DISSOUS     ','DISSOLVED PO4   ','   mg/l         ')
          RANKTR(2) = IND_PO4
!       3. ~~> POR NON ASSIM
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_POR,
     &      'POR NON ASSIMILE','POR NON ASSIM   ','   mg/l         ')
          RANKTR(3) = IND_POR
!       4. ~~> DISSOLVED NO3
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_NO3,
     &      'NO3 DISSOUS     ','DISSOLVED NO3   ','   mg/l         ')
          RANKTR(4) = IND_NO3
!       5. ~~> NOR NON ASSIM
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_NOR,
     &      'NOR NON ASSIMILE','NOR NON ASSIM   ','   mg/l         ')
          RANKTR(5) = IND_NOR
!
!       EUTRO MODULE
!
        CASE(3)
          WAQTR = 8
!       1. ~~> PHYTO BIOMASS
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_PHY,
     &      'BIOMASSE PHYTO  ','PHYTO BIOMASS   ',' micro_g/l      ')
          RANKTR(1) = IND_PHY
!       2. ~~> DISSOLVED PO4
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_PO4,
     &      'PO4 DISSOUS     ','DISSOLVED PO4   ','   mg/l         ')
          RANKTR(2) = IND_PO4
!       3. ~~> POR NON ASSIMIL
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_POR,
     &      'POR NON ASSIMILE','POR NON ASSIMIL ','   mg/l         ')
          RANKTR(3) = IND_POR
!       4. ~~> DISSOLVED NO3
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_NO3,
     &      'NO3 DISSOUS     ','DISSOLVED NO3   ','   mg/l         ')
          RANKTR(4) = IND_NO3
!       5. ~~> NOR NON ASSIM
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_NOR,
     &      'NOR NON ASSIMILE','NOR NON ASSIM   ','   mg/l         ')
          RANKTR(5) = IND_NOR
!       6. ~~> NH4 LOAD
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_NH4,
     &      'CHARGE NH4      ','NH4 LOAD        ','   mgNH4/l      ')
          RANKTR(6) = IND_NH4
!       7. ~~> ORGANIC LOAD
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_OL,
     &      'CHARGE ORGANIQUE','ORGANIC LOAD    ','   mgO2/l       ')
          RANKTR(7) = IND_OL
!       8. ~~> DISSOLVED O2
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_O2,
     &      'O2 DISSOUS      ','DISSOLVED O2    ','   mgO2/l       ')
          RANKTR(8) = IND_O2
!
!       MICROPOL MODULE
!
        CASE(4)
          WAQTR = 5
!       1. ~~> SUSPENDED LOAD
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_SS,
     &      'MAT. EN SUSP.   ','SUSPENDED LOAD  ','   mg/l         ')
          RANKTR(1) = IND_SS
!       2. ~~> BED SEDIMENTS
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_SF,
     &      'SEDIMENT DU FOND','BED SEDIMENTS   ','   mg/l         ')
          RANKTR(2) = IND_SF
!       3. ~~> MICRO POLLUTANT
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_C,
     &      'MICRO POLLUANT  ','MICRO POLLUTANT ','   mg/l         ')
          RANKTR(3) = IND_C
!       4. ~~> ABS. SUSP. LOAD.
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_CSS,
     &      'MES ABSORBEE    ','ABS. SUSP. LOAD.','   mg/l         ')
          RANKTR(4) = IND_CSS
!       5. ~~> ABSORB. BED SED.
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_CSF,
     &      'SED. FOND. ABS. ','ABSORB. BED SED.','   mg/l         ')
          RANKTR(5) = IND_CSF
!
!      THERMIC MODULE
!
        CASE(5)
          WAQTR = 1
!       1. ~~> TEMPERATURE
          CALL ADDTRACER(NAMETRAC,NTRAC,
     &      IND_T,
     &      'TEMPERATURE     ','TEMPERATURE     ','   oC           ')
          RANKTR(1) = IND_T
!
!      AED2 COUPLING
!
        CASE(6)
#if defined HAVE_AED2
          CALL NAMES_VAR_AED2(WAQTR,NAMESAED2)
          DO I = 1,WAQTR
            CALL ADDTRACER(NAMETRAC,NTRAC,
     &        IND_AED2(I),
     &        NAMESAED2(I),NAMESAED2(I),'   mmol/m3      ')
            RANKTR(I) = IND_AED2(I)
          ENDDO
#else
          IF(LNG.EQ.1) WRITE(LU,*)
     &      'ERREUR : BIBLIOTHEQUE AED2 NON COMPILEE'
          IF(LNG.EQ.2) WRITE(LU,*) 'ERROR: AED2 LIBRARY NOT COMPILED'
          CALL PLANTE(1)
          STOP
#endif
!
        CASE DEFAULT
          IF(LNG.EQ.1) THEN
            WRITE(LU,10) WAQPROCESS
          ELSE
            WRITE(LU,20) WAQPROCESS
          ENDIF
          CALL PLANTE(1)
          STOP

      END SELECT
!
!-----------------------------------------------------------------------
!     MESSAGES
10    FORMAT(1X,'NAMETRAC_WAQTEL: MODULE WAQ INCONNU : ',I4)
20    FORMAT(1X,'NAMETRAC_WAQTEL: UNKNOWN WAQ MODULE : ',I4)
!-----------------------------------------------------------------------
!
      RETURN
      END SUBROUTINE NAMETRAC_WAQTEL
