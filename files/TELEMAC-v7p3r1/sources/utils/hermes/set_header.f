!                    *******************
                     SUBROUTINE SET_HEADER
!                    *******************
!
     &(FFORMAT,FILE_ID,TITLE,NVAR,VAR_NAME,IERR)
!
!***********************************************************************
! HERMES   V7P0                                               01/05/2014
!***********************************************************************
!
!brief    Writes the Title and the name and units of the variables
!
!history  Y AUDOUIN (LNHE)
!+        24/03/2014
!+        V7P0
!+
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FFORMAT        |-->| FORMAT OF THE FILE
!| FILE_ID        |-->| FILE DESCRIPTOR
!| TITLE          |-->| TITLE OF THE MESH
!| NVAR           |-->| NUMBER OF VARIABLES
!| VAR_NAME       |-->| NAME AND UNITS OF THE VARIABLES
!| IERR           |<--| 0 IF NO ERROR DURING THE EXECUTION
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE UTILS_SERAFIN
      USE UTILS_MED
      USE UTILS_VTK
      USE UTILS_CGNS
      USE DECLARATIONS_SPECIAL
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      CHARACTER(LEN=8),  INTENT(IN)  :: FFORMAT
      INTEGER,           INTENT(IN)  :: FILE_ID
      CHARACTER(LEN=80), INTENT(IN)  :: TITLE
      INTEGER,           INTENT(IN)  :: NVAR
      CHARACTER(LEN=32), INTENT(IN)  :: VAR_NAME(NVAR)
      INTEGER,           INTENT(OUT) :: IERR
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER :: I
      SELECT CASE (FFORMAT(1:7))
        CASE ('SERAFIN')
          CALL SET_HEADER_SRF(FILE_ID,TITLE,NVAR,VAR_NAME,IERR)
        CASE ('MED    ')
          CALL SET_HEADER_MED(FILE_ID,TITLE,IERR)
        CASE ('VTK    ')
          CALL SET_HEADER_VTK(FILE_ID,TITLE,NVAR,IERR)
        CASE ('CGNS   ')
          CALL SET_HEADER_CGNS(FILE_ID,TITLE,NVAR,VAR_NAME,IERR)
        CASE DEFAULT
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'SET_HEADER : MAUVAIS FORMAT : ',FFORMAT
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE(LU,*) 'SET_HEADER: BAD FILE FORMAT: ',FFORMAT
          ENDIF
          CALL PLANTE(1)
          STOP
      END SELECT
!
!-----------------------------------------------------------------------
!
      RETURN
      END

