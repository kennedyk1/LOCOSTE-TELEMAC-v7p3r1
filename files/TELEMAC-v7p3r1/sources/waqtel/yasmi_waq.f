!                       ***********************
                        SUBROUTINE YASMI_WAQ
!                       ***********************
     &  (YASMI)
!
!
!***********************************************************************
! TELEMAC2D   V7P0
!***********************************************************************
!
!brieF tells which tracers will have implicit source terms
!
!
!history  R.ATA
!+        12/02/2016
!+        V7P2
!+        CREATION
!
!         R. ATA 
!+        07/07/2016
!+        V7P3
!+        ADAPTATION FOR THE NEW MANAGEMENT OF TRACERS
!              
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| YASMI          |<--| LOGICS FOR IMPLICIT SOURCE TERMS
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_SPECIAL
      USE DECLARATIONS_WAQTEL
      USE INTERFACE_WAQTEL, EX_YASMI_WAQ => YASMI_WAQ
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
!
      LOGICAL          , INTENT(INOUT)::  YASMI(*)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
!
!-----------------------------------------------------------------------
!
      SELECT CASE(WAQPROCESS)
!
!       O2 MODULE
!
        CASE(1)
!         DISSOLVED O2
          YASMI(IND_O2)=.FALSE.
!         ORGANIC LOAD
          YASMI(IND_OL)=.TRUE.
!         NH4 LOAD
          YASMI(IND_NH4)=.TRUE.
!
!       BIOMASS MODULE
!
        CASE(2)
!         PHYTO BIOMASS
          YASMI(IND_PHY)=.FALSE.
!         DISSOLVED PO4
          YASMI(IND_PO4)=.FALSE.
!         POR NON ASSIM
          YASMI(IND_POR)=.FALSE.
!         DISSOLVED NO3
          YASMI(IND_NO3)=.FALSE.
!         NO3 NON ASSIM
          YASMI(IND_NO3)=.FALSE.
!
!       EUTRO MODULE
!
        CASE(3)
!         PHYTO BIOMASS
          YASMI(IND_PHY)=.FALSE.
!         DISSOLVED PO4
          YASMI(IND_PO4)=.FALSE.
!         POR NON ASSIM
          YASMI(IND_POR)=.FALSE.
!         DISSOLVED NO3
          YASMI(IND_NO3)=.FALSE.
!         NOR NON ASSIM
          YASMI(IND_NOR)=.FALSE.
!         CHARGE NH4
          YASMI(IND_NH4)=.TRUE.
!         ORGANIC LOAD
          YASMI(IND_OL)=.TRUE.
!         DISSOLVED O2
          YASMI(IND_O2)=.FALSE.
!
!       MICROPOL MODULE
!
        CASE(4)
!         SUSPENDED LOAD
          YASMI(IND_SS)=.FALSE.
!         BED SEDIMENTS
          YASMI(IND_SF)=.FALSE.
!         MICRO POLLUTANT
          YASMI(IND_C)=.TRUE.
!         ABS. SUSP. LOAD
          YASMI(IND_CSS)=.TRUE.
!         ABSORB. BED SED
          YASMI(IND_CSF)=.FALSE.
!
!      THERMIC MODULE
!
        CASE(5)
          YASMI(IND_T)=.FALSE.
        CASE DEFAULT
          IF(LNG.EQ.1) THEN
            WRITE(LU,10)WAQPROCESS
          ELSE
            WRITE(LU,20)WAQPROCESS
          ENDIF
          CALL PLANTE(1)
          STOP

      END SELECT
!
      RETURN
!-----------------------------------------------------------------------
!     MESSAGES
10    FORMAT(1X,'YASMI_WAQ: MODULE WAQ INCONNU : ',I4)
20    FORMAT(1X,'YASMI_WAQ: UNKNOWN WAQ MODULE : ',I4)
!-----------------------------------------------------------------------
!
      RETURN
      END
