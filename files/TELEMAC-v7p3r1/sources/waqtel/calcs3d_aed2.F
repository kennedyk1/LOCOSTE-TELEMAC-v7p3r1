!                     ***********************
                      SUBROUTINE CALCS3D_AED2
!                     ***********************
     &(NPOIN3,NPOIN2,NPLAN,Z,IND_T,IND_S,TA,TEXP,TIMP,LONGIT,
     & LATIT,LISTIN,AT,MARDAT,MARTIM,NTRAC,EXTCAED2)
!
!
!***********************************************************************
! WAQTEL      V7P3
!***********************************************************************
!
!brief    COMPUTES SOURCE TERMS WHEN COUPLING WITH AED2 FOR 3D CASE
!         INCLUDES WAQ THERMIC PROCESS
!
!history  M JODEAU
!+        18/05/2016
!+        V7P3
!+       Creation
!
!history  M.-J. JODEAU
!+        20/09/2017
!+        V7P3
!+  Taking into account the extinction coefficient 
!+  when coupling with T3D for the temperature
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| AT            |-->| TIME IN SECONDS
!| EXTCAED2      |<--| EXTINCTION COEFFICIENT CALCULATED BY AED2
!| FLUXAED2      |<--| EXPLICIT SOURCE TERM CALCULATED BY AED2
!| IND_S         |-->| INDEX OF THE SALINITY IN THE TRACER TABLE
!| IND_T         |-->| INDEX OF THE TEMPERATURE IN THE TRACER TABLE
!| LATIT         |-->| LATITUDE OF ORIGIN POINT
!| LISTIN        |-->| LOGICAL FOR LISTING
!| LONGIT        |-->| LONGITUTE OF ORIGIN POINT
!| MARDAT        |-->| DATE (YEAR,MONTH,DAY)
!| MARTIM        |-->| TIME (HOUR,MINUTE,SECOND)
!| NPLAN         |-->| NUMBER OF VERTICAL PLANES
!| NPOIN2        |-->| NUMBER OF NODES IN THE 2D MESH
!| NPOIN3        |-->| NUMBER OF NODES IN THE 3D MESH
!| NTRAC         |-->| TOTAL NUMBER OF TRACERS
!| TEXP          |<--| EXPLICIT SOURCE TERM.
!| TIMP          |-->| IMPLICIT SOURCE TERM.
!| Z             |-->| Z COORDINATES FOR NODES
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_SPECIAL
      USE DECLARATIONS_WAQTEL,ONLY:NEBU,ZSD,CP_EAU,RO0
      USE EXCHANGE_WITH_ATMOSPHERE
#if defined HAVE_AED2
      USE T3D_AED2
      USE DECLARATIONS_WAQTEL,ONLY:FLUXAED2,DEJA_CA
#endif
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)           :: NPOIN3,NPOIN2,NPLAN
      INTEGER, INTENT(IN)           :: IND_T,IND_S,NTRAC
      INTEGER, INTENT(IN)           :: MARDAT(3),MARTIM(3)
      DOUBLE PRECISION, INTENT(IN)  :: Z(NPOIN3),LATIT,LONGIT,AT
      TYPE(BIEF_OBJ), INTENT(INOUT) :: TEXP,TIMP
      TYPE(BIEF_OBJ), INTENT(IN)    :: TA
      LOGICAL,        INTENT(IN)    :: LISTIN
      DOUBLE PRECISION, INTENT(INOUT) :: EXTCAED2(NPOIN2,NPLAN)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER I,J,K,IPLAN,IERR
      DOUBLE PRECISION TREEL,SAL,RO,LAMB,RAY_SOL
!
      INTRINSIC EXP,MAX
!
!----------------------------------------------------------------------
!
#if defined HAVE_AED2
      IF(.NOT.DEJA_CA) THEN
        ALLOCATE(FLUXAED2(NPOIN2,NTRAC,NPLAN),STAT=IERR)
        DEJA_CA = .TRUE.
      ENDIF
! INITIALIZATION OF SOURCE TERMS
      DO J=3,NTRAC
        CALL OS('X=0     ',X=TEXP%ADR(J)%P)
      ENDDO
!
! COMPUTATION OF THE SOURCE TERMS BY AED2
!
      CALL DO_AED2_MODELS(NPOIN3,NPOIN2,FLUXAED2,EXTCAED2,TA)
!
      DO J=3,NTRAC
        TEXP%ADR(J)%P%TYPR='Q'
        DO I=1,NPOIN2
          DO K=1,NPLAN
            TEXP%ADR(J)%P%R(I+(K-1)*NPOIN2) = FLUXAED2(I,J-2,K)
          ENDDO
        ENDDO
      ENDDO
!
!-----------------------------------------------------------------------
!
!     MASS BALANCE: MASS ADDED BY EXPLICIT TERMS (TO CHECK)
!
!     ACTIVATE BIEF_OBJ FOR FURTHER CALCULATIONS
!      TEXP%ADR(RANKTR1)%P%TYPR='Q'
!      TIMP%ADR(RANKTR2)%P%TYPR='Q'
!      TIMP%ADR(NTRAC  )%P%TYPR='Q'
!
!-----------------------------------------------------------------------
!
!     THERMIC PART, NOT A CALL TO CALCS3D_THERMICV
!
!-----------------------------------------------------------------------
!
!     SOURCE IN TEMPERATURE NOT EQUAL TO ZERO

      TEXP%ADR(IND_T)%P%TYPR='Q'
!
!     INCIDENT SOLAR RADIATION
!
      CALL SOLRAD(RAY_SOL,NEBU,MARDAT,MARTIM,AT,LATIT,LONGIT)
!
!     EXTINCTION COEFFICIENT CALCULATED BY AED2
!     TAKES INTO ACCOUNT BIOEXTINCTION & CO
!
      SAL = 0.D0
      DO I=1,NPOIN2
        DO IPLAN=1,NPLAN
          J = I + (IPLAN-1)*NPOIN2
          TREEL=TA%ADR(IND_T)%P%R(NPOIN3-NPOIN2+I)
          IF (IND_S.NE.0) THEN
            SAL = TA%ADR(IND_S)%P%R(NPOIN3-NPOIN2+I)
          ENDIF
          RO=RO0*(1.D0-(7.D0*(TREEL-4.D0)**2-750.D0*SAL)*1.D-6)
          LAMB=RO*CP_EAU
          TEXP%ADR(IND_T)%P%R(J) =
     &             EXTCAED2(I,IPLAN)
     &            *EXP(EXTCAED2(I,IPLAN)*(Z(J)-Z(I+(NPLAN-1)*NPOIN2)))
     &            *RAY_SOL/LAMB
        ENDDO
      ENDDO
#endif
!
!-----------------------------------------------------------------------
!
      RETURN
      END
