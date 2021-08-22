!                 ****************
                  MODULE UTILS_MED
!                 ****************
!
!***********************************************************************
! HERMES  V7P0                                                 2015
!***********************************************************************
!
!brief    INTERFACES OF MED PUBLIC SUBROUTINES
!
!warning  NOTE THAT THIS INTERFACE IS FOR THE LIBRARY INCLUDED IN MED
!+     V3.0.4 CHANGES MIGHT BE REQUIRED WITH FUTURE VERSIONS OF MED.
!
!history YOANN AUDOUIN
!+       25/05/2015
!+       V7P0
!+       ADAPTING CODE TO MED V3.0.4
!
!history VINCENT STOBIAC
!+       23/05/2014
!+       V6P3
!+       ADDING GENERAL MED SUBROUTINES
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_SPECIAL
      USE HASH_TABLE
!
      IMPLICIT NONE
#if defined (HAVE_MED)
      INCLUDE 'med.hf'
#endif
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!     NEW OBJECT RELATED TO MESHES IN A MED FILE
      TYPE MED_INFO
        INTEGER :: ID
        INTEGER :: NCLI
        INTEGER, ALLOCATABLE :: NBOR(:)
        ! Numbering for boundary segment
        INTEGER, ALLOCATABLE :: NBOR_SEG(:)
        ! For each boundary point gives segments containing it
        INTEGER, ALLOCATABLE :: PT2SEG(:,:)
        ! Contains for each boundary element type if it is indeed a boundary
        LOGICAL, ALLOCATABLE :: IS_BND(:)
        LOGICAL :: NO_BND
        ! Number of boundary groups
        INTEGER :: NBND_GRP
        ! Contains for each boundary group its values for h u v tracer
        INTEGER, ALLOCATABLE :: BND_GRP_VAL(:,:)
        ! Contains for each family its number and the index of the boundary group associated
        ! 0 if it is not a boundary family
        INTEGER, ALLOCATABLE :: BND_FAM(:,:)
#if defined HAVE_MED
        CHARACTER(LEN=MED_NAME_SIZE) :: MESH_NAME
        ! Contains for boundary group its name
        CHARACTER(LEN=MED_LNAME_SIZE), ALLOCATABLE :: BND_GRP_NAME(:)
#endif
      END TYPE MED_INFO
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
!
!     HASH TABLE FOR FILES
      INTEGER :: HASH(MAX_FILE) = 0
!
      TYPE(MED_INFO) :: MED_OBJ_TAB(MAX_FILE)
      ! Value of lihbor for a solid boundary
      INTEGER, PARAMETER :: SOL_BND = 2
      ! OFFSET for families on points when in parallel
      INTEGER,PARAMETER :: OFFSET = 1000
!
!-----------------------------------------------------------------------
!
      CONTAINS
!
!-----------------------------------------------------------------------
!
      SUBROUTINE OPEN_MESH_MED(FILE_NAME,FILE_ID,OPEN_MODE,IERR)
!
!BRIEF    OPENS A MESH FILE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_NAME      |<--| NAME OF THE MED FILE
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| OPEN_MODE      |<--| OPENING MODE (READ/READWRITE/WRITE)
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      CHARACTER(LEN=*), INTENT(IN)  :: FILE_NAME
      INTEGER,          INTENT(OUT)  :: FILE_ID
      CHARACTER(LEN=9), INTENT(IN)  :: OPEN_MODE
      INTEGER,          INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      LOGICAL :: HDFOK, MEDOK ! CHECK COMPATIBILITY
      INTEGER :: MED_MODE ! MED OPENING MODE
      INTEGER :: MAJOR, MINOR, REL ! MED VERSION OF THE FILE
      INTEGER :: MED_ID
      CHARACTER(LEN=200) :: CFILE_NAME
      CHARACTER(LEN=MED_NAME_SIZE)    :: TITLE_MED
      CHARACTER(LEN=MED_SNAME_SIZE)   :: DT_UNIT
      CHARACTER(LEN=MED_SNAME_SIZE),ALLOCATABLE :: COOR_NAME(:)
      CHARACTER(LEN=MED_SNAME_SIZE),ALLOCATABLE :: COOR_UNIT(:)
      CHARACTER(LEN=MED_COMMENT_SIZE) :: COMMENT
!
      INTEGER :: IMESH             ! MESH DESCRIPTOR
      INTEGER :: NB_DIM_PB         ! NUMBER OF PHYSICAL DIMENSIONS
      INTEGER :: NB_DIM_MESH       ! NUMBER OF MESH DIMENSIONS
      INTEGER :: MESH_TYPE         ! TYPE OF THE MESH
      INTEGER :: ORDER             ! SORTING ORDER FOR IT AND DT
      INTEGER :: NCOMP             ! NUMBER OF COMPUTATION STEPS
      INTEGER :: COOR_TYPE         ! TYPE OF COORDINATES
      INTEGER :: NAXIS             ! NUMBER OF AXES
!
!-----------------------------------------------------------------------
!
!     CHECK THE MODE. POSSIBLE MODES ARE READONLY, WRITEONLY OR
!     READWRITE. OTHER MODES ARE INVALID
      SELECT CASE(OPEN_MODE)
        CASE('READ     ')
          MED_MODE = MED_ACC_RDONLY
        CASE('READWRITE')
          MED_MODE = MED_ACC_RDWR
        CASE('WRITE    ')
          MED_MODE = MED_ACC_CREAT
        CASE DEFAULT
!         OPEN MODE IS INVALID
          IERR = HERMES_INVALID_OPEN_MODE_ERR
      END SELECT
      CFILE_NAME = TRIM(FILE_NAME)//CHAR(0)
!
      HDFOK = .TRUE.
      MEDOK = .TRUE.
      IF(MED_MODE.EQ.MED_ACC_RDONLY) THEN
!       CHECK IF THE FILE IS BOTH A MED & HDF5 FILE
        CALL MFICOM(CFILE_NAME, HDFOK, MEDOK, IERR)
        CALL CHECK_CALL(IERR,'OPEN_MESH_MED:MFICOM')
      ENDIF
!
!     MESH FILE NOT COMPATIBLE WITH HDF5 OR MED
      IF (.NOT. HDFOK) IERR = HERMES_WRONG_HDF_FORMAT_ERR
      IF (.NOT. MEDOK) IERR = HERMES_WRONG_MED_FORMAT_ERR
!
!     OPEN THE MED FILE AND CHECK RETURN CODE
      CALL MFIOPE(FILE_ID, CFILE_NAME, MED_MODE, IERR)
      CALL CHECK_CALL(IERR,'OPEN_MESH_MED:MFIOPE')
!
      IF(MED_MODE.EQ.MED_ACC_RDONLY) THEN
!       CHECK COMPATIBILITY (EXPECTED)
        CALL MFINVR (FILE_ID, MAJOR, MINOR, REL, IERR)
        CALL CHECK_CALL(IERR,'OPEN_MESH_MED:MFINVR')
!       MED FILE IS TOO OLD AND SHOULD BE CONVERTED WITH MEDIMPORT
        IF (MAJOR.LT.3) THEN
          IERR = HERMES_WRONG_MED_VERSION_ERR
          RETURN
        ENDIF
      ENDIF
!
!     CREATE A NEW OBJECT FOR THE NEW MED FILE
      CALL ADD_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'OPEN_MESH_MED:ADD_OBJ')
!
!     Identify the name of the mesh if in read only
      IF(MED_MODE.EQ.MED_ACC_RDONLY) THEN
!       ONLY ONE MESH PER FILE FOR NOW
        IMESH = 1
!
        CALL MMHNAX(FILE_ID,IMESH,NAXIS,IERR)
        CALL CHECK_CALL(IERR,'OPEN_MESH_MED:MMHMII')
        ALLOCATE(COOR_NAME(NAXIS),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'OPEN_MESH_MED:COOR_NAME')
        ALLOCATE(COOR_UNIT(NAXIS),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'OPEN_MESH_MED:COOR_UNIT')
!
!       READ MESH TITLE
        CALL MMHMII(FILE_ID,IMESH,TITLE_MED,NB_DIM_PB,NB_DIM_MESH,
     &    MESH_TYPE,COMMENT,DT_UNIT,ORDER,NCOMP,COOR_TYPE,COOR_NAME,
     &    COOR_UNIT,IERR)
        CALL CHECK_CALL(IERR,'OPEN_MESH_MED:MMHMII')
        DEALLOCATE(COOR_NAME)
        DEALLOCATE(COOR_UNIT)
!
        MED_OBJ_TAB(MED_ID)%MESH_NAME = TITLE_MED
      ENDIF
!
#else
!
      FILE_ID = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE CLOSE_MESH_MED (FILE_ID, IERR)
!
!BRIEF    CLOSES A MESH FILE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(OUT) :: IERR
!
      INTEGER MED_ID
!
!-----------------------------------------------------------------------
!
#if defined (HAVE_MED)
!
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'CLOSE_MESH_MED:GET_OBJ')
!
      ! Clearing id in the hash table
      HASH(MED_ID) = 0
!
!     CLOSE MED FILE
      CALL MFICLO(FILE_ID, IERR)
      CALL CHECK_CALL(IERR,'CLOSE_MESH_MED:MFICLO')
!
      ! CLEAN UP OF STRUCTURE
      MED_OBJ_TAB(MED_ID)%ID = 0
      MED_OBJ_TAB(MED_ID)%NCLI = 0
      MED_OBJ_TAB(MED_ID)%NO_BND = .TRUE.
      MED_OBJ_TAB(MED_ID)%NBND_GRP = 0
      MED_OBJ_TAB(MED_ID)%MESH_NAME = REPEAT(' ',MED_NAME_SIZE)
      IF(ALLOCATED(MED_OBJ_TAB(MED_ID)%BND_GRP_VAL)) THEN
        DEALLOCATE(MED_OBJ_TAB(MED_ID)%BND_GRP_VAL)
      ENDIF
      IF(ALLOCATED(MED_OBJ_TAB(MED_ID)%BND_GRP_NAME)) THEN
        DEALLOCATE(MED_OBJ_TAB(MED_ID)%BND_GRP_NAME)
      ENDIF
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!
!-----------------------------------------------------------------------
!
      SUBROUTINE OPEN_BND_MED(FILE_NAME,FILE_ID,OPEN_MODE,IERR)
!
!BRIEF    OPEN BOUNDARY FILE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_NAME      |<--| NAME OF THE BOUNDARY FILE
!| FILE_ID        |<--| ID OF THE FILE
!| OPEN_MODE      |<--| OPENING MODE (READ/READWRITE/WRITE)
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
        IMPLICIT NONE
!
        CHARACTER(LEN=*), INTENT(IN)  :: FILE_NAME
        INTEGER,          INTENT(IN)  :: FILE_ID
        CHARACTER(LEN=9), INTENT(IN)  :: OPEN_MODE
        INTEGER,          INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
        INTEGER :: MED_ID,NCLI,NBND_GRP,I
        LOGICAL :: ISOPENED
!
!-----------------------------------------------------------------------
!
        CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
        CALL CHECK_CALL(IERR,'OPEN_BND_MED:GET_OBJ')
!
        ! First we check if the file is already opened
        ! Telemac is using one boundary file for all the mesh file
        ! so it could have been opened by another mesh before hand
        INQUIRE(FILE=FILE_NAME,OPENED=ISOPENED)
        IF(ISOPENED) THEN
          ! Id the file is already opened get its id
          INQUIRE(FILE=FILE_NAME,NUMBER=MED_OBJ_TAB(MED_ID)%NCLI)
        ELSE
          ! Otherwise open the file
          CALL GET_FREE_ID(MED_OBJ_TAB(MED_ID)%NCLI)
          OPEN(UNIT=MED_OBJ_TAB(MED_ID)%NCLI,FILE=FILE_NAME,
     &         FORM='FORMATTED',ACTION=OPEN_MODE,IOSTAT=IERR)
        ENDIF
        IF(OPEN_MODE(1:4).EQ.'READ') THEN
          ! Getting the name of the boundary groups
          NCLI = MED_OBJ_TAB(MED_ID)%NCLI
          REWIND(NCLI)
!         LOOP ON THE INFO IN THE FILE
          READ(UNIT=NCLI,FMT=*,IOSTAT=IERR) NBND_GRP
          CALL CHECK_CALL(IERR,'OPEN_BND_MED:READ')
          MED_OBJ_TAB(MED_ID)%NBND_GRP = NBND_GRP
          ALLOCATE(MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(NBND_GRP,4),
     &             STAT=IERR)
          CALL CHECK_ALLOCATE(IERR,'BND_GRP_VAL')
          ALLOCATE(MED_OBJ_TAB(MED_ID)%BND_GRP_NAME(NBND_GRP),STAT=IERR)
          CALL CHECK_ALLOCATE(IERR,'BND_GRP_NAME')
          DO I=1,NBND_GRP
            READ(UNIT=NCLI,FMT=*,IOSTAT=IERR)
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(I,1),
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(I,2),
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(I,3),
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(I,4),
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_NAME(I)
            CALL CHECK_CALL(IERR,'OPEN_BND_MED:READ')
          ENDDO
        ELSE
          MED_OBJ_TAB(MED_ID)%NBND_GRP = 0
        ENDIF

#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!
!-----------------------------------------------------------------------
!
      SUBROUTINE CLOSE_BND_MED (FILE_ID, IERR)
!
!BRIEF    CLOSES A MESH BOUNDARY FILE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
        IMPLICIT NONE
!
        INTEGER, INTENT(IN)  :: FILE_ID
        INTEGER, INTENT(OUT) :: IERR
!
        INTEGER MED_ID
        LOGICAL ISOPENED
!
!-----------------------------------------------------------------------
!
        CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
        CALL CHECK_CALL(IERR,'CLOSE_BND_MED:GET_OBJ')
!
        ISOPENED = .FALSE.
        ! CHECK IF THE FILE IS STILL OPENED AS IT COULD HAVE BEEN CLOSED
        ! BY ANOTHER MESH FILE (SEE OPEN_BND_SRF FOR MORE INFORMATION)
        INQUIRE(UNIT=MED_OBJ_TAB(MED_ID)%NCLI,OPENED=ISOPENED)
        IERR = 0
        IF(ISOPENED) THEN
          CLOSE(MED_OBJ_TAB(MED_ID)%NCLI,IOSTAT=IERR)
        ENDIF
        CALL CHECK_CALL(IERR,'CLOSE_BND_MED:CLOSE')
        IF(ALLOCATED(MED_OBJ_TAB(MED_ID)%NBOR)) THEN
          DEALLOCATE(MED_OBJ_TAB(MED_ID)%NBOR)
        ENDIF
        IF(ALLOCATED(MED_OBJ_TAB(MED_ID)%NBOR_SEG)) THEN
          DEALLOCATE(MED_OBJ_TAB(MED_ID)%NBOR_SEG)
        ENDIF
        IF(ALLOCATED(MED_OBJ_TAB(MED_ID)%IS_BND)) THEN
          DEALLOCATE(MED_OBJ_TAB(MED_ID)%IS_BND)
        ENDIF
        IF(ALLOCATED(MED_OBJ_TAB(MED_ID)%BND_FAM)) THEN
          DEALLOCATE(MED_OBJ_TAB(MED_ID)%BND_FAM)
        ENDIF
        IF(ALLOCATED(MED_OBJ_TAB(MED_ID)%PT2SEG)) THEN
          DEALLOCATE(MED_OBJ_TAB(MED_ID)%PT2SEG)
        ENDIF
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_TITLE_MED (FILE_ID, TITLE, IERR)
!
!BRIEF    READS THE MESH TITLE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TITLE          |-->| MESH TITLE OR NAME
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER,           INTENT(IN)  :: FILE_ID
      CHARACTER(LEN=80), INTENT(OUT) :: TITLE
      INTEGER,           INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
!
      INTEGER :: MED_ID
      CHARACTER(LEN=MED_COMMENT_SIZE) :: TITLE_MED
!
!-----------------------------------------------------------------------
!
!     STORE THE NAME OF THE MESH IN THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_TITLE_MED:GET_OBJ')
      TITLE_MED = REPEAT(' ',MED_COMMENT_SIZE)
!     READS THE TITLE OF THE MESH IF ther is one
      CALL MFICOR(FILE_ID,TITLE_MED,IERR)
      IF (IERR.LT.0) THEN
        TITLE = 'NO TITLE'
        IERR = 0
      ELSE
        TITLE = TITLE_MED(1:80)
      ENDIF
!
#else
!
      TITLE = REPEAT(' ', 80)
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_NELEM_MED (FILE_ID, TYPE_ELEM, NELEM, IERR)
!
!BRIEF    READS TOTAL NUMBER OF ELEMENTS FOR A GIVEN TYPE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_ELEM      |<--| TYPE OF ELEMENT
!| NELEM          |-->| NUMBER OF ELEMENTS
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(IN)  :: TYPE_ELEM
      INTEGER, INTENT(OUT) :: NELEM
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER :: TYPE_ELEM_MED   ! ELEMENT TYPE IN MED NUMBERING
      INTEGER :: CHGT,TSF        ! INDICATORS OF MESH MODIF
      INTEGER :: MED_ID
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NELEM_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_ELEM, TYPE_ELEM_MED, IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NELEM_MED:CONVERT_ELEM_TYPE')
!
!     READ TOTAL NUMBER OF ELEMENTS
      NELEM = 0
      CALL MMHNME(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &  TYPE_ELEM_MED,MED_CONNECTIVITY,MED_NODAL,CHGT,TSF,NELEM,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NELEM_MED:MMHNME')
!
#else
!
      NELEM = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_NPOIN_PER_ELEMENT_MED (TYPE_ELEM, NDP, IERR)
!
!BRIEF    READS NUMBER OF NODES PER ELEMENT
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| TYPE_ELEM      |<--| TYPE OF ELEMENT
!| NDP            |-->| NUMBER OF NODES PER ELEMENT
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: TYPE_ELEM
      INTEGER, INTENT(OUT) :: NDP
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
!
      INTEGER :: TYPE_ELEM_MED   ! ELEMENT TYPE IN MED NUMBERING
!
!-----------------------------------------------------------------------
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_ELEM, TYPE_ELEM_MED, IERR)
      CALL CHECK_CALL(IERR,
     &         'GET_MESH_NPOIN_PER_ELEMENT_MED:CONVERT_ELEM_TYPE')
!
!     DEDUCES NUMBER OF NODES PER ELEMENT FROM THE ELEMENT TYPE
      CALL NDP_FROM_ELEMENT_TYPE_MED(TYPE_ELEM_MED,NDP,IERR)
      CALL CHECK_CALL(IERR,
     &  'GET_MESH_NPOIN_PER_ELEMENT_MED:NDP_FROM_ELEMENT_TYPE_MED')
!
#else
!
      NDP = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_CONNECTIVITY_MED (FILE_ID,TYPE_ELEM,IKLE,
     &                              NELEM,NDP,IERR)
!
!BRIEF    READS THE CONNECTIVITY TABLE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_ELEM      |<--| TYPE OF THE ELEMENT IN FORMAT SLF
!| IKLE           |-->| CONNECTIVITY TABLE
!| NELEM          |<--| NUMBER OF ELEMENTS
!| NDP            |<--| NUMBER OF NODES PER ELEMENT
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(IN)  :: TYPE_ELEM
      INTEGER, INTENT(IN)  :: NELEM
      INTEGER, INTENT(IN)  :: NDP
      INTEGER, INTENT(INOUT) :: IKLE(NELEM*NDP)
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER :: MED_ID, TYPE_ELEM_MED
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_CONNECTIVITY_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_ELEM, TYPE_ELEM_MED, IERR)
      CALL CHECK_CALL(IERR,
     &                'GET_MESH_CONNECTIVITY_MED:CONVERT_ELEM_TYPE')
!
!     READ THE CONNECTIVITY TABLE
      CALL MMHCYR(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &  TYPE_ELEM_MED,MED_NODAL,MED_FULL_INTERLACE,IKLE,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_CONNECTIVITY_MED:MMHCYR')
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_NPOIN_MED (FILE_ID,TYPE_ELEM,NPOIN,IERR)
!
!BRIEF    READS TOTAL NUMBER OF NODES IN A MED FILE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_ELEM      |<--| ELEMENT TYPE IN SLF FORMAT
!| NPOIN          |-->| TOTAL NUMBER OF NODES
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(IN)  :: TYPE_ELEM
      INTEGER, INTENT(OUT) :: NPOIN
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER :: CHGT,TSF     ! INDICATORS OF MESH MODIF
      INTEGER :: MED_ID, TYPE_ELEM_MED
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NPOIN_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_ELEM, TYPE_ELEM_MED, IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NPOIN_MED:CONVERT_ELEM_TYPE')
!
!     READ THE TOTAL NUMBER OF NODES
      CALL MMHNME(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_NODE,
     &  TYPE_ELEM_MED,MED_COORDINATE,MED_NODAL,CHGT,TSF,NPOIN,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NPOIN_MED:MMHNME')
!
#else
!
      NPOIN = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_DIMENSION_MED (FILE_ID, NDIM, IERR)
!
!BRIEF    READS THE NUMBER OF DIMENSION OF THE MESH
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| NDIM           |-->| NUMBER OF DIMENSION OF THE MESH
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(OUT) :: NDIM
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE)    :: TITLE_MED
      CHARACTER(LEN=MED_NAME_SIZE)    :: DT_UNIT
      CHARACTER(LEN=MED_SNAME_SIZE),ALLOCATABLE :: COOR_NAME(:)
      CHARACTER(LEN=MED_SNAME_SIZE),ALLOCATABLE :: COOR_UNIT(:)
      CHARACTER(LEN=MED_COMMENT_SIZE) :: COMMENT
!
      INTEGER :: IMESH             ! MESH DESCRIPTOR
      INTEGER :: NB_DIM_PB         ! NUMBER OF PHYSICAL DIMENSIONS
      INTEGER :: MESH_TYPE         ! TYPE OF THE MESH
      INTEGER :: ORDER             ! SORTING ORDER FOR IT AND DT
      INTEGER :: NCOMP             ! NUMBER OF COMPUTATION STEPS
      INTEGER :: COOR_TYPE         ! TYPE OF COORDINATES
      INTEGER :: NAXIS             ! NUMBER OF AXES
!
!----------------------------------------------------------------------
!
!     ONLY ONE MESH PER FILE FOR NOW
      IMESH = 1
!
      CALL MMHNAX(FILE_ID,IMESH,NAXIS,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_DIMENSION_MED:MMHMII')
      ALLOCATE(COOR_NAME(NAXIS),STAT=IERR)
      CALL CHECK_ALLOCATE(IERR,'GET_MESH_DIMENSION_MED:COOR_NAME')
      ALLOCATE(COOR_UNIT(NAXIS),STAT=IERR)
      CALL CHECK_ALLOCATE(IERR,'GET_MESH_DIMENSION_MED:COOR_UNIT')
!
!     READ MESH INFORMATIONS
      CALL MMHMII(FILE_ID,IMESH,TITLE_MED,NB_DIM_PB,NDIM,MESH_TYPE,
     &  COMMENT,DT_UNIT,ORDER,NCOMP,COOR_TYPE,COOR_NAME,COOR_UNIT,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_DIMENSION_MED:MMHMII')
      DEALLOCATE(COOR_NAME)
      DEALLOCATE(COOR_UNIT)
!
#else
!
      NDIM = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_COORD_MED(FILE_ID,JDIM,NDIM,NPOIN,COORD_AXE,
     &  IERR)
!
!BRIEF    READS THE COORDINATES OF THE MESH
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| JDIM           |<--| DIMENSION NUMBER (X, Y OR Z)
!| NDIM           |<--| NUMBER OF DIMENSION OF THE MESH
!| NPOIN          |<--| TOTAL NUMBER OF NODES
!| COORD_AXE      |-->| COORDINATES OF THE MESH
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID, JDIM, NDIM, NPOIN
      INTEGER, INTENT(OUT) :: IERR
      DOUBLE PRECISION, INTENT(INOUT) :: COORD_AXE(NPOIN)
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER :: MED_ID
      DOUBLE PRECISION, ALLOCATABLE :: COORD(:)
!
!----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'COORD_MED:GET_MESH_OBJ_FILE')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     TEMPORARY TABLE ALLOCATION
      ALLOCATE(COORD(3*NPOIN),STAT=IERR)
      CALL CHECK_ALLOCATE(IERR,'GET_MESH_COORD_MED:COORD')
!
!     READ THE COORDINATES OF THE MESH
      CALL MMHCOR(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_NO_INTERLACE,
     &  COORD,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_COORD_MED:MMHCOR')
!
!     STORE ONLY THE DIMENSION DEFINED BY JDIM
      IF ((JDIM.GE.0).AND.(JDIM.LE.NDIM)) THEN
        COORD_AXE(1:NPOIN)=COORD((JDIM-1)*NPOIN+1:JDIM*NPOIN)
      ELSE
!       ERROR ON JDIM
        IERR = HERMES_WRONG_AXE_ERR
      ENDIF
      DEALLOCATE(COORD)
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_L2G_NUMBERING_MED(FILE_ID, KNOLG, NPOIN, IERR)
!
!BRIEF    READS THE INDEX TABLE OF NODES WHICH CONVERT THE LOCAL
!         NUMBERING TO THE GLOBAL
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| KNOLG          |-->| NODES INDEX TABLE FROM LOCAL TO GLOBAL
!| NPOIN          |<--| TOTAL NUMBER OF NODES
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(IN)  :: NPOIN
      INTEGER, INTENT(OUT) :: IERR
      INTEGER, INTENT(INOUT) :: KNOLG(NPOIN)
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER :: MED_ID
!
!----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_L2G_NUMBERING_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     READ THE NODES INDEX TABLE FROM LOCAL TO GLOBAL
      CALL MMHGNR(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_NODE,MED_NONE,
     &  KNOLG,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_L2G_NUMBERING_MED:MMHGNR')
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_NPTIR_MED (FILE_ID, NPTIR, IERR)
!
!BRIEF    READS TOTAL NUMBER OF INTERFACE NODES IN A MED FILE
!         ONLY FOR PARALLEL MODE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| NPTIR          |-->| NUMBER OF INTERFACE NODES FOR THE SUB-DOMAIN
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(OUT) :: NPTIR
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      INTEGER :: MED_ID
      CHARACTER(LEN=MED_NAME_SIZE) :: PNAME
      INTEGER :: NSTEP,ITYP,NPARAM,I
      CHARACTER(LEN=MED_NAME_SIZE) :: DTUNIT
      CHARACTER(LEN=MED_COMMENT_SIZE) :: DESC
      LOGICAL :: FOUND
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NPTIR_MED:GET_OBJ')
!

!     INITIALISATION
      NPTIR = 0
      ! Looping on all parameter to check if nplan is in
      CALL MPRNPR(FILE_ID,NPARAM,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NPTIR_MED:MPRNPR')
      FOUND = .FALSE.
      DO I=1,NPARAM
        CALL MPRPRI(FILE_ID,I,PNAME,ITYP,DESC,DTUNIT,NSTEP,IERR)
        CALL CHECK_CALL(IERR,'GET_MESH_NPTIR_MED:MPRNPR')
        IF(PNAME(1:5).EQ.'NPTIR') THEN
          FOUND = .TRUE.
        ENDIF
      ENDDO
      IF(FOUND) THEN
        PNAME = 'NPTIR'//CHAR(0)
        CALL MPRIVR(FILE_ID,PNAME,MED_NO_DT,MED_NO_IT,NPTIR,IERR)
        CALL CHECK_CALL(IERR,'GET_MESH_NPTIR_MED:MPRIVR')
      ELSE
        NPTIR = 0
      ENDIF
!
#else
!
      NPTIR = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_NPLAN_MED (FILE_ID, NPLAN, IERR)
!
!BRIEF    READS NUMBER OF PLANES (3D)
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| NPLAN          |-->| NUMBER OF PLANES
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(OUT) :: NPLAN
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      INTEGER :: MED_ID,NSTEP,ITYP,NPARAM,I
      CHARACTER(LEN=MED_NAME_SIZE) :: PNAME,DTUNIT
      CHARACTER(LEN=MED_COMMENT_SIZE) :: DESC
      LOGICAL :: FOUND
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NPLAN_MED:GET_OBJ')
!
      NPLAN = 0
!     INITIALISATION
      ! Looping on all parameter to check if nplan is in
      CALL MPRNPR(FILE_ID,NPARAM,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NPLAN_MED:MPRNPR')
      FOUND = .FALSE.
      DO I=1,NPARAM
        CALL MPRPRI(FILE_ID,I,PNAME,ITYP,DESC,DTUNIT,NSTEP,IERR)
        CALL CHECK_CALL(IERR,'GET_MESH_NPLAN_MED:MPRNPR')
        IF(PNAME(1:5).EQ.'NPLAN') THEN
          FOUND = .TRUE.
        ENDIF
      ENDDO
      IF(FOUND) THEN
        PNAME = 'NPLAN'//CHAR(0)
        CALL MPRIVR(FILE_ID,PNAME,MED_NO_DT,MED_NO_IT,NPLAN,IERR)
        CALL CHECK_CALL(IERR,'GET_MESH_NPLAN_MED:MPRIVR')
      ELSE
        NPLAN = 0
      ENDIF
!
#else
!
      NPLAN = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_MESH_DATE_MED (FILE_ID, DATE, IERR)
!
!BRIEF    READS NUMBER OF PLANES (3D)
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| NPLAN          |-->| NUMBER OF PLANES
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(OUT) :: DATE(6)
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      INTEGER :: MED_ID,NSTEP,ITYP,NPARAM,I
      CHARACTER(LEN=MED_NAME_SIZE) :: PNAME,DTUNIT
      CHARACTER(LEN=MED_COMMENT_SIZE) :: DESC
      LOGICAL :: FOUND
      INTEGER :: MYDATE
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NPLAN_MED:GET_OBJ')
!
!     INITIALISATION
      ! Looping on all parameter to check if nplan is in
      CALL MPRNPR(FILE_ID,NPARAM,IERR)
      CALL CHECK_CALL(IERR,'GET_MESH_NPLAN_MED:MPRNPR')
      FOUND = .FALSE.
      DO I=1,NPARAM
        CALL MPRPRI(FILE_ID,I,PNAME,ITYP,DESC,DTUNIT,NSTEP,IERR)
        CALL CHECK_CALL(IERR,'GET_MESH_NPLAN_MED:MPRNPR')
        IF(PNAME(1:5).EQ.'DATE') THEN
          FOUND = .TRUE.
        ENDIF
      ENDDO
      IF(FOUND) THEN
        PNAME = 'DATE'//CHAR(0)
        CALL MPRIVR(FILE_ID,PNAME,MED_NO_DT,MED_NO_IT,MYDATE,IERR)
        CALL CHECK_CALL(IERR,'GET_MESH_NPLAN_MED:MPRIVR')
        DATE(1) = MYDATE/10000
        MYDATE = MYDATE - DATE(1)*10000
        DATE(2) = MYDATE/100
        MYDATE = MYDATE - DATE(2)*100
        DATE(3) = MYDATE
        PNAME = 'TIME'//CHAR(0)
        CALL MPRIVR(FILE_ID,PNAME,MED_NO_DT,MED_NO_IT,MYDATE,IERR)
        CALL CHECK_CALL(IERR,'GET_MESH_NPLAN_MED:MPRIVR')
        DATE(4) = MYDATE/10000
        MYDATE = MYDATE - DATE(4)*10000
        DATE(5) = MYDATE/100
        MYDATE = MYDATE - DATE(5)*100
        DATE(6) = MYDATE
      ELSE
        DATE(:) = 0
      ENDIF
!
#else
!
      DATE(:) = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_BND_IPOBO_MED(FILE_ID,TYPE_ELEM_BND,NPOIN,
     &  IPOBO,IERR)
!
!BRIEF    DETERMINES THE TABLE IPOBO: 1 IF BOUNDARY NODE, 0 OTHERWISE
!
!WARNING  ONLY WORKS FOR ONE TYPE OF BOUNDARY ELEMENTS
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_ELEM_BND  |<--| BOUNDARY ELEMENT TYPE IN SLF FORMAT
!| NPOIN          |<--| TOTAL NUMBER OF NODES
!| IPOBO          |-->| LOGICAL TABLE FOR BOUNDARY NODES
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN) :: FILE_ID, TYPE_ELEM_BND, NPOIN
      INTEGER, INTENT(INOUT) :: IPOBO(NPOIN)
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
!
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER :: I,J, MED_ID
      INTEGER :: NDP_BND_ELE  ! NUMBER OF NODES PER ELEMENT
      INTEGER :: TYPE_ELEM_MED
      INTEGER, ALLOCATABLE :: BND_IKLE(:)
      INTEGER, ALLOCATABLE :: NBOR(:)
      INTEGER :: NELEM
      INTEGER :: NPTFR
!
!-----------------------------------------------------------------------
!
!     INITIALISATION
      DO I = 1, NPOIN
        IPOBO(I) = 0
      ENDDO
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_IPOBO_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
      IF(MED_OBJ_TAB(MED_ID)%NO_BND) THEN
        IERR = 0
        RETURN
      ENDIF
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_ELEM_BND, TYPE_ELEM_MED, IERR)
      CALL CHECK_CALL(IERR,'GET_BND_IPOBO_MED:CONVERT_ELEM_TYPE')
!
!     Identify bnd element if necessary
      CALL IDENTIFY_BND_ELMT(FILE_ID,TYPE_ELEM_BND,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_IPOBO_MED:IDENTIFY_BND_ELMT')
!
!     DETERMINE THE NUMBER OF NODES PER ELEMENT FROM THE TYPE
      CALL NDP_FROM_ELEMENT_TYPE_MED(TYPE_ELEM_MED,NDP_BND_ELE,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_IPOBO_MED:NDP_FROM_ELT_TYPE_MED')
!
!     Get the number of element of the boundary type
      CALL GET_MESH_NELEM_MED(FILE_ID,TYPE_ELEM_BND,NELEM,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_IPOBO_MED:GET_BND_NELEM_MED')
!
!
      IF(TYPE_ELEM_BND.EQ.POINT_BND_ELT_TYPE) THEN
        CALL GET_BND_NPOIN_MED(FILE_ID,TYPE_ELEM_BND,NPTFR,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_IPOBO_MED:GET_BND_NPOIN')
        ALLOCATE(NBOR(NPTFR),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'NBOR')

        CALL GET_BND_NUMBERING_MED(FILE_ID,TYPE_ELEM_BND,NPTFR,
     &                             NBOR,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_IPOBO_MED:GET_BND_NPOIN')
        DO I = 1, NPTFR
          IPOBO(NBOR(I)) = 1
        ENDDO
        DEALLOCATE(NBOR)
      ELSE
!       READ THE ONNECTIVITY TABLE OF THE BOUNDARY ELEMENTS
        ALLOCATE(BND_IKLE(NDP_BND_ELE*NELEM),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_IPOBO_MED:BND_IKLE')
!
        CALL MMHCYR(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &    TYPE_ELEM_MED,MED_NODAL,MED_NO_INTERLACE,BND_IKLE,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_IPOBO_MED:MMHCYR')
!       LOOP ON THE BOUNDARY ELEMENTS TO MODIFY IPOBO
        DO I = 1, NELEM
          ! Skipping non boundary elements
          IF(.NOT.MED_OBJ_TAB(MED_ID)%IS_BND(I)) CYCLE
          DO J=1,NDP_BND_ELE
            IPOBO(BND_IKLE((J-1)*NELEM+I)) = 1
          ENDDO
        ENDDO
!
!       FREE MEMORY
        DEALLOCATE(BND_IKLE)
      ENDIF
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_BND_NUMBERING_MED(FILE_ID,TYPE_ELEM_BND,NPTFR,
     & NBOR,IERR)
!
!BRIEF    GET THE TABLE OF THE BOUNDARY NODES
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_ELEM_BND  |<--| BOUNDARY ELEMENT TYPE IN SLF FORMAT
!| NPTFR          |<--| TOTAL NUMBER OF BOUNDARY NODES
!| NBOR           |-->| LOGICAL TABLE FOR BOUNDARY NODES
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN) :: FILE_ID,NPTFR,TYPE_ELEM_BND
      INTEGER, INTENT(INOUT) :: NBOR(NPTFR)
      INTEGER, INTENT(OUT) :: IERR
!
#if defined HAVE_MED
!
      INTEGER :: NELEBD,NDP,I,J
      INTEGER :: MED_ID,TYPE_ELEM_MED
      INTEGER, ALLOCATABLE :: IKLE(:)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER :: ISUIV, NOEUD1, NOEUD2
      INTEGER :: IILE,NILE,NPOIN,NELEM
      INTEGER, ALLOCATABLE :: TRAV1(:,:)
      INTEGER, ALLOCATABLE :: KP1BOR(:)
      DOUBLE PRECISION :: SOM1,SOM2,Y2
      DOUBLE PRECISION, PARAMETER :: EPSILO = 1.D-6
      DOUBLE PRECISION, ALLOCATABLE :: X(:),Y(:)
      LOGICAL :: SWAP
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NUMBERING_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
      IF(MED_OBJ_TAB(MED_ID)%NO_BND) THEN
        IERR = 0
        RETURN
      ENDIF

      IF(TYPE_ELEM_BND.EQ.POINT_BND_ELT_TYPE) THEN
!
        CALL MMHCYR(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &    MED_POINT1,MED_NODAL,MED_NO_INTERLACE,NBOR,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_CONNECTIVITY_MED:MMHCYR')
!
      ELSE IF(ALLOCATED(MED_OBJ_TAB(MED_ID)%NBOR)) THEN
!
        DO I=1,NPTFR
          NBOR(I) = MED_OBJ_TAB(MED_ID)%NBOR(I)
        ENDDO
!
      ELSE
!
!       OTHERWISE COMPUTING NBOR
!       CONVERTS TYPE OF ELEMENTS
        CALL CONVERT_ELEM_TYPE(TYPE_ELEM_BND, TYPE_ELEM_MED, IERR)
        CALL CHECK_CALL(IERR,'GET_BND_NUMBERING_MED:CONVERT_ELEM_TYPE')
!
!       Identify bnd element if necessary
        CALL IDENTIFY_BND_ELMT(FILE_ID,TYPE_ELEM_BND,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_IPOBO_MED:IDENTIFY_BND_ELMT')
!
!       DETERMINE THE NUMBER OF NODES PER ELEMENT FROM THE TYPE
        CALL NDP_FROM_ELEMENT_TYPE_MED(TYPE_ELEM_MED,NDP,IERR)
        CALL CHECK_CALL(IERR,
     &                  'GET_BND_NUMBERING_MED:NDP_FROM_ELT_TYPE_MED')
!
!       Get the number of element of the boundary type
        CALL GET_MESH_NELEM_MED(FILE_ID,TYPE_ELEM_BND,NELEM,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_NUMBERING_MED:GET_BND_NELEM_MED')
!
!       READ THE CONNECTIVITY TABLE OF THE ELEMENTS
        ALLOCATE(IKLE(NDP*NELEM),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_NUMBERING_MED:BND_IKLE')
!
        CALL MMHCYR(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &    TYPE_ELEM_MED,MED_NODAL,MED_NO_INTERLACE,IKLE,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_NUMBERING_MED:MMHCYR')
!
!       REORDER THE BOUNDARY POINT TO COMPLY WITH TELEMAC CONVENTION (SEE DOCUMENTATION)
        CALL GET_MESH_NPOIN_MED(FILE_ID,TYPE_ELEM_BND,NPOIN,IERR)
        CALL CHECK_CALL(IERR,
     &                  'GET_BND_NUMBERING_MED:GET_MESH_COORD_MED:X')
!
        ALLOCATE(TRAV1(NPTFR,2),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_NUMBERING_MED:TRAV1')
        ALLOCATE(KP1BOR(NPTFR*2),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_NUMBERING_MED:KP1BOR')
        ALLOCATE(MED_OBJ_TAB(MED_ID)%PT2SEG(NPTFR,2),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_NUMBERING_MED:PT2SEG')
!
!       Only take into account the real boundary elements
        NELEBD = 0
        DO I=1,NELEM
          ! Skipping non boundary elements
          IF(.NOT.MED_OBJ_TAB(MED_ID)%IS_BND(I)) CYCLE
          NELEBD = NELEBD + 1
          TRAV1(NELEBD,1) = IKLE(I)
          TRAV1(NELEBD,2) = IKLE(I+NELEM)
        ENDDO
        ! Initialising boundary element renumbering
        ALLOCATE(MED_OBJ_TAB(MED_ID)%NBOR_SEG(NELEBD))
        J = 0
        DO I=1,NELEM
          ! Skipping non boundary elements
          IF(.NOT.MED_OBJ_TAB(MED_ID)%IS_BND(I)) CYCLE
          J = J + 1
          MED_OBJ_TAB(MED_ID)%NBOR_SEG(J) = J
        ENDDO
!
!       GET MESH COORDINATES
        ALLOCATE(X(NPOIN),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_NUMBERING_MED:X')
        ALLOCATE(Y(NPOIN),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_NUMBERING_MED:Y')
        CALL GET_MESH_COORD_MED(FILE_ID,1,2,NPOIN,X,IERR)
        CALL CHECK_CALL(IERR,
     &                  'GET_BND_NUMBERING_MED:GET_MESH_COORD_MED:X')
        CALL GET_MESH_COORD_MED(FILE_ID,2,2,NPOIN,Y,IERR)
        CALL CHECK_CALL(IERR,
     &                  'GET_BND_NUMBERING_MED:GET_MESH_COORD_MED:Y')
!
!       EDGE ARE STORED CONTINUOUSLY
!       IT STARTS WITH SOUTH-WESTERNMOST POINT (OR SOUTHMORE POINT IN CASE OF
!       CONFLICT) IN ORDER TO START ON THE BOUNDARY AND NOT ON A ISLAND
        SOM2 = X(1) + Y(1)
        Y2   = Y(1)
!
        DO I=1,NPTFR
!
          SOM1 = X(TRAV1(I,1)) + Y(TRAV1(I,1))
          IF (ABS(SOM1-SOM2).LE.ABS(EPSILO*SOM1)) THEN
            IF (Y(TRAV1(I,1)).LE.Y2) THEN
              Y2    = Y(TRAV1(I,1))
              SOM2  = SOM1
              ISUIV = I
            ENDIF
          ELSEIF (SOM1.LE.SOM2) THEN
            Y2    = Y(TRAV1(I,1))
            SOM2  = SOM1
            ISUIV = I
          ENDIF
!
        ENDDO
!
        NOEUD1 = TRAV1(ISUIV,1)
        NOEUD2 = TRAV1(ISUIV,2)
        TRAV1(ISUIV,1) = TRAV1(1,1)
        TRAV1(ISUIV,2) = TRAV1(1,2)
        TRAV1(1,1) = NOEUD1
        TRAV1(1,2) = NOEUD2
        NOEUD1 = MED_OBJ_TAB(MED_ID)%NBOR_SEG(ISUIV)
        MED_OBJ_TAB(MED_ID)%NBOR_SEG(ISUIV) =
     &    MED_OBJ_TAB(MED_ID)%NBOR_SEG(1)
        MED_OBJ_TAB(MED_ID)%NBOR_SEG(1) = NOEUD1
!
        IILE = 0
        NILE = 1
!
        DO I=2,NPTFR
          SWAP = .FALSE.
          MED_OBJ_TAB(MED_ID)%PT2SEG(I,1) =
     &      MED_OBJ_TAB(MED_ID)%NBOR_SEG(I-1)
!
!         SEACH OF THE EDGE WHOSE FIRST NODE IS IDENTICAL TO THE SECOND ONE
!         OF THE PREVIOUS EDGE
          DO ISUIV=I,NPTFR
!
            IF (TRAV1(ISUIV,1).EQ.TRAV1(I-1,2)) THEN
!
!             PERMUTATION OF EDGE WITH NUMBER I+1 AND ISUIV
              NOEUD1 = TRAV1(ISUIV,1)
              NOEUD2 = TRAV1(ISUIV,2)
              TRAV1(ISUIV,1) = TRAV1(I,1)
              TRAV1(ISUIV,2) = TRAV1(I,2)
              TRAV1(I,1) = NOEUD1
              TRAV1(I,2) = NOEUD2
              NOEUD1 = MED_OBJ_TAB(MED_ID)%NBOR_SEG(ISUIV)
              MED_OBJ_TAB(MED_ID)%NBOR_SEG(ISUIV) =
     &          MED_OBJ_TAB(MED_ID)%NBOR_SEG(I)
              MED_OBJ_TAB(MED_ID)%NBOR_SEG(I) = NOEUD1
              KP1BOR(I+NPTFR) = I-1
              KP1BOR(I-1) = I
              SWAP = .TRUE.
              EXIT
!
            ENDIF
!
          ENDDO! ISUIV
          IF(.NOT.SWAP) THEN
            DO ISUIV=I,NPTFR
!
              IF (TRAV1(ISUIV,2).EQ.TRAV1(I-1,2)) THEN
!
!               PERMUTATION OF EDGE WITHIN ITSELF
                NOEUD1 = TRAV1(ISUIV,2)
                NOEUD2 = TRAV1(ISUIV,1)
                TRAV1(ISUIV,1) = TRAV1(I,1)
                TRAV1(ISUIV,2) = TRAV1(I,2)
                TRAV1(I,1) = NOEUD1
                TRAV1(I,2) = NOEUD2
                NOEUD1 = MED_OBJ_TAB(MED_ID)%NBOR_SEG(ISUIV)
                MED_OBJ_TAB(MED_ID)%NBOR_SEG(ISUIV) =
     &            MED_OBJ_TAB(MED_ID)%NBOR_SEG(I)
                MED_OBJ_TAB(MED_ID)%NBOR_SEG(I) = NOEUD1
                KP1BOR(I+NPTFR) = I-1
                KP1BOR(I-1) = I
                SWAP = .TRUE.
                EXIT
!
              ENDIF
!
            ENDDO! ISUIV
          ENDIF
          MED_OBJ_TAB(MED_ID)%PT2SEG(I,2) =
     &          MED_OBJ_TAB(MED_ID)%NBOR_SEG(I)
          IF(SWAP) CYCLE
!
!         IF NO FOLLOWING POINT IS FOUND, WE VERIFY THAT THE LAST AND THE FIRST
!         POINTS ARE IDENTICAL. IT MEANS WE FOUND AN ISLAND, SO WE RETURN TO THE
!         GLOBAL LOOP
          IF (TRAV1(NILE,1).NE.TRAV1(I-1,2)) THEN
!
!           OTHERWISE IT IS AN ERROR
            WRITE(*,4500) TRAV1(I-1,2)
4500        FORMAT(1X,'ERROR IN THE EDGE SEGMENTS MISSING SEGMENT',/,
     &             1X,'FOR THE NODE ',I5)
            CALL PLANTE(1)
            STOP
          ENDIF
!
          KP1BOR(NILE+NPTFR) = I-1
          KP1BOR(I-1) = NILE
          MED_OBJ_TAB(MED_ID)%PT2SEG(NILE,1) =
     &      MED_OBJ_TAB(MED_ID)%NBOR_SEG(I-1)
          MED_OBJ_TAB(MED_ID)%PT2SEG(NILE,2) =
     &      MED_OBJ_TAB(MED_ID)%NBOR_SEG(NILE)
          IILE = IILE+1
          NILE = I
!
        ENDDO! I
!
!       WE VERIFY THAT THE LAST ISLAND IS CLOSED
        IF (TRAV1(NILE,1).NE.TRAV1(NPTFR,2)) THEN
          WRITE(*,5000) TRAV1(NILE,1),TRAV1(NPTFR,2)
5000      FORMAT(1X,'ERROR, THE BOUNDARY IS NOT CLOSED :',/,
     &           1X,'FIRST POINT :',I5,2X,'LAST POINT : ',I5)
          CALL PLANTE(1)
          STOP
        ENDIF
!
        KP1BOR(NILE+NPTFR) = NPTFR
        KP1BOR(NPTFR) = NILE
        MED_OBJ_TAB(MED_ID)%PT2SEG(NILE,1) =
     &    MED_OBJ_TAB(MED_ID)%NBOR_SEG(NPTFR)
        MED_OBJ_TAB(MED_ID)%PT2SEG(NILE,2) =
     &    MED_OBJ_TAB(MED_ID)%NBOR_SEG(NILE)
!
!       THE TABLE NBOR IS FILLED AND THE COLOR OF THE BOUNDARY NODES IS STORED
!       IN THE TABLE NCOLFR
        ALLOCATE(MED_OBJ_TAB(MED_ID)%NBOR(NPTFR))
        DO I=1,NPTFR
          NBOR(I      ) = TRAV1(I,1)
          MED_OBJ_TAB(MED_ID)%NBOR(I) = NBOR(I)
        ENDDO

        DEALLOCATE(IKLE)
        DEALLOCATE(X,Y)
        DEALLOCATE(TRAV1)
        DEALLOCATE(KP1BOR)
      ENDIF
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_BND_NELEM_MED (FILE_ID, TYPE_ELEM, BND_NELEM, IERR)
!
!BRIEF    READS THE TOTAL NUMBER OF BOUNDARY ELEMENTS FOR A GIVEN TYPE
!         OF BOUNDARY ELEMENT
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_ELEM      |<--| TYPE OF ELEMENT IN SLF FORMAT
!| BND_NELEM      |-->| NUMBER OF BOUNDARY ELEMENTS
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(IN)  :: TYPE_ELEM
      INTEGER, INTENT(OUT) :: BND_NELEM
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      INTEGER :: MED_ID, TYPE_ELEM_MED
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NELEM_MED:MMHCYR')
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_ELEM, TYPE_ELEM_MED, IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NELEM_MED:CONVERT_ELEM_TYPE')
!
!     Identify bnd element if necessary
      CALL IDENTIFY_BND_ELMT(FILE_ID,TYPE_ELEM,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NELEM_MED:IDENTIFY_BND_ELMT')
!
      IF(MED_OBJ_TAB(MED_ID)%NO_BND) THEN
        IERR = 0
        BND_NELEM = 0
        RETURN
      ENDIF
!
!     Compute the total number of element
      BND_NELEM = COUNT(MED_OBJ_TAB(MED_ID)%IS_BND)
!
#else
!
      BND_NELEM = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_BND_CONNECTIVITY_MED (FILE_ID, TYPE_ELEM, NELEBD,
     &                              NDP, BND_IKLE, IERR)
!
!BRIEF    READS THE CONNECTIVITY TABLE OF BOUNDARY ELEMENTS FOR A GIVEN
!         TYPE OF BOUNDARY ELEMENT
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_ELEM      |<--| TYPE OF THE ELEMENT IN MED FORMAT
!| NELEBD         |<--| TOTAL NUMBER OF ELEMENTS
!| NDP            |<--| NUMBER OF NODES PER ELEMENT
!| BND_IKLE       |-->| CONNECTIVITY TABLE OF BOUNDARY ELEMENTS
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(IN)  :: NELEBD
      INTEGER, INTENT(IN)  :: NDP
      INTEGER, INTENT(IN)  :: TYPE_ELEM
      INTEGER, INTENT(INOUT) :: BND_IKLE(NELEBD*NDP)
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER :: TYPE_ELEM_MED,MED_ID
      INTEGER,ALLOCATABLE :: IKLE(:)
      INTEGER :: IBND,NELEM,I
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_CONNECTIVITY_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME

!
!     CONVERT
      CALL CONVERT_ELEM_TYPE(TYPE_ELEM, TYPE_ELEM_MED, IERR)
      CALL CHECK_CALL(IERR,'GET_BND_CONNECTIVITY_MED:CONVERT')
!
!     Identify bnd element if necessary
      CALL IDENTIFY_BND_ELMT(FILE_ID,TYPE_ELEM,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_CONNECTIVITY_MED:IDENTIFY_BND_ELMT')

      IF(MED_OBJ_TAB(MED_ID)%NO_BND) THEN
        IERR = 0
        RETURN
      ENDIF
!
      CALL GET_MESH_NELEM_MED(FILE_ID,TYPE_ELEM,NELEM,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_CONNECTIVITY_MED:GET_MESH_NELEM')
      IF(NELEM.GT.0) THEN
        ALLOCATE(IKLE(NELEM*NDP),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_CONNECTIVITY_MED:IKLE')
!       Read the connectivity table of the elements
        CALL MMHCYR(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &    TYPE_ELEM_MED,MED_NODAL,MED_NO_INTERLACE,IKLE,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_CONNECTIVITY_MED:MMHCYR')
!
        ! Compute the boundary elements connectivity table
        IBND = 0
        DO I=1,NELEM
          ! Skipping no boundary elements
          IF(.NOT.MED_OBJ_TAB(MED_ID)%IS_BND(I)) CYCLE
          IBND = IBND + 1
          BND_IKLE(IBND) = IKLE(I)
          BND_IKLE(IBND+NELEBD) = IKLE(I+NELEM)
        ENDDO
        DEALLOCATE(IKLE)
      ENDIF
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_BND_GRP_VALUE_MED (FILE_ID, GRP_NAME, VALUE, IERR)
!
!BRIEF    GIVES THE VALUE OF THE BOUNDARY CONDITIONS ASSOCIATED TO A
!         FAMILY NAME
!
!WARNING  THIS FUNCTION COULD BE OPTIMIZED BY READING ALL THE INFO AT
!         THE BEGINNING. HOWEVER THE COST IT LOW AS THE SIZE OF THE FILE
!         IS LIMITED (I.E. TOTAL NUMBER OF GROUP
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| GRP_NAME       |<--| NAME OF THE FAMILY
!| VALUE          |-->| VALUE OF THE BOUNDARY CONDITIONS
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN) :: FILE_ID
      CHARACTER(LEN=16), INTENT(IN)  :: GRP_NAME
      INTEGER, INTENT(INOUT) :: VALUE
      INTEGER, INTENT(OUT) :: IERR
!
      INTEGER :: NCLI,MED_ID,I1,I2,I3,I4,I
      INTEGER :: NGROUP
      CHARACTER(LEN=16) :: TEMP_NAME
      LOGICAL :: FOUND
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NELEM_MED:MMHCYR')
      NCLI = MED_OBJ_TAB(MED_ID)%NCLI
      IF(MED_OBJ_TAB(MED_ID)%NO_BND) THEN
        IERR = 0
        RETURN
      ENDIF
!
!     INITIALIZATION
      FOUND = .FALSE.
      IERR = 0
      REWIND(NCLI)
!
!     LOOP ON THE INFO IN THE FILE
      READ(UNIT=NCLI,FMT=*,IOSTAT=IERR) NGROUP
      CALL CHECK_CALL(IERR,'GET_BND_GRP_VALUE:READ')
      DO I=1,NGROUP
        READ(UNIT=NCLI,FMT=*,IOSTAT=IERR) I1,I2,I3,I4,TEMP_NAME
        CALL CHECK_CALL(IERR,'GET_BND_GRP_VALUE:READ')
!
!       IF THE FAMILY IS FOUND, THE VALUE IS STORED
        IF (TEMP_NAME .EQ. GRP_NAME) THEN
          FOUND = .TRUE.
          VALUE = I1*1000+I2*100+I3*10+I4
          EXIT
        ENDIF
      ENDDO
!
      IF(.NOT.FOUND) IERR = HERMES_UNKNOWN_GROUP_ERR
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_BND_FAMILY_MED (FILE_ID, TYPE_BND_ELEM, NELEBD,
     &  FAMILY, IERR)
!
!BRIEF    CREATE THE FAMILY NAME FOR EACH BOUNDARY ELEMENT
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_BND_ELEM  |<--| TYPE OF THE BOUNDARY ELEMENT
!| NELEBD         |<--| TOTAL NUMBER OF BOUNDARY ELEMENTS
!| FAMILY         |-->| TABLE OF BOUNDARY ELEMENT'S FAMILY NAME
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID, TYPE_BND_ELEM, NELEBD
      INTEGER, DIMENSION(NELEBD), INTENT(INOUT) :: FAMILY
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER ::  IELEM, IGRP
      INTEGER :: MED_ID, TYPE_ELEM_MED, NB_FAMILY
      INTEGER, DIMENSION(:), ALLOCATABLE :: NUM_FAMILY
      INTEGER :: NELEM, IBND
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_FAMILY_MED:GET_OBJ_FILE')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_BND_ELEM, TYPE_ELEM_MED, IERR)
      CALL CHECK_CALL(IERR,'GET_BND_FAMILY_MED:CONVERT_ELEM_TYPE')
!
!     Identify bnd element if necessary
      CALL IDENTIFY_BND_ELMT(FILE_ID,TYPE_BND_ELEM,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_FAMILY_MED:IDENTIFY_BND_ELMT')
!
      IF(TYPE_BND_ELEM.EQ.POINT_BND_ELT_TYPE) THEN
!       Get the number of elements
        CALL GET_BND_NELEM_MED(FILE_ID,TYPE_BND_ELEM,NELEM,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_FAMILY_MED:GET_MESH_NELEM')
      ELSE
!       Get the number of elements
        CALL GET_MESH_NELEM_MED(FILE_ID,TYPE_BND_ELEM,NELEM,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_FAMILY_MED:GET_MESH_NELEM')
      ENDIF
!
!     READ THE FAMILY NUMBER FOR EACH ELEMENT
      ALLOCATE(NUM_FAMILY(NELEM),STAT=IERR)
      CALL CHECK_ALLOCATE(IERR,'NUM_FAMILY')

      CALL MMHFNR(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &            TYPE_ELEM_MED,NUM_FAMILY,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_FAMILY_MED:MMHFNR')
!
!     READ THE TOTAL NUMBER OF FAMILY
      CALL MFANFA(FILE_ID,MNAME,NB_FAMILY,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_FAMILY_MED:MFANFA')
!
      IBND = 0
      DO IELEM = 1, NELEM
!
        IF(.NOT.MED_OBJ_TAB(MED_ID)%IS_BND(IELEM)) CYCLE
!       LOOP ON FAMILY
        IBND = IBND + 1
        DO IGRP = 1, NB_FAMILY
          ! Skipping non boundary families
          IF(MED_OBJ_TAB(MED_ID)%BND_FAM(IGRP,2).EQ.0) CYCLE
          IF (NUM_FAMILY(IELEM).EQ.
     &        MED_OBJ_TAB(MED_ID)%BND_FAM(IGRP,1)) THEN
            FAMILY(IBND) = MED_OBJ_TAB(MED_ID)%BND_FAM(IGRP,2)
          ENDIF
        ENDDO
      ENDDO
!
!     FREE MEMORY
      DEALLOCATE(NUM_FAMILY)
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_BND_NPOIN_MED(FILE_ID,TYPE_BND_ELEM,NPTFR,IERR)
!
!BRIEF    DETERMINE THE NUMBER OF BOUNDARY POINTS
!
!WARNING  FIND ANOTHER SOLUTION THIS ONE IS WAY TOO EXPENSIVE
!         SEE WITH MED PEOPLE IF THER IS ANOTHER WAY
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_BND_ELEM  |<--| TYPE OF THE BOUNDARY ELEMENT
!| NPTFR          |-->| NUMBER OF BOUNDARY NODES
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
        IMPLICIT NONE
!
        INTEGER, INTENT(IN) :: FILE_ID, TYPE_BND_ELEM
        INTEGER, INTENT(OUT) :: NPTFR
        INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
!
      INTEGER :: CHGT,TSF     ! INDICATORS OF MESH MODIF
      INTEGER :: MED_ID, TYPE_BND_ELEM_MED
      INTEGER :: NELEBD, NPOIN, I, J, NDP
      INTEGER, ALLOCATABLE :: IKLE(:)
      LOGICAL, ALLOCATABLE :: IS_BND(:)
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NPOIN_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_BND_ELEM, TYPE_BND_ELEM_MED, IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NPOIN_MED:CONVERT_ELEM_TYPE')
!
      NELEBD = 0
!     GET THE NUMBER OF BOUNDARY ELEMENTS
      CALL GET_BND_NELEM_MED(FILE_ID,TYPE_BND_ELEM,NELEBD,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NPOIN_MED:GET_BND_NELEM_MED')
      IF(TYPE_BND_ELEM.EQ.POINT_BND_ELT_TYPE) THEN
        NPTFR = NELEBD
        RETURN
      ENDIF
!
!     CONTINUE ONLY IF BOUNDARY ELEMENTS EXIST
      IF(NELEBD.GT.0) THEN
!
!       GET THE NUMBER OF POINT IN THE MESH
        CALL MMHNME(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_NODE,
     &            TYPE_BND_ELEM_MED,MED_COORDINATE,MED_NODAL,
     &            CHGT,TSF,NPOIN,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_NPOIN_MED:MMHNME')
!
!       GET THE NUMBER OF POINTS PER ELEMENT
        CALL GET_NODES_PER_ELEMENT(TYPE_BND_ELEM,NDP)
!
!       ALLOCATE CONNECTIVITY TABLE OF BOUNDARY ELEMENTS
        ALLOCATE(IKLE(NELEBD*NDP),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_NPOIN_MED:IKLE')
!
!       GET THE CONNECTIVITY TABLE FOR THE BOUNDARY ELEMENTS
        CALL GET_BND_CONNECTIVITY_MED(FILE_ID, TYPE_BND_ELEM, NELEBD,
     &                        NDP, IKLE, IERR)
        CALL CHECK_CALL(IERR,
     &                  'GET_BND_NPOIN_MED:GET_BND_CONNECTIVITY_MED')
!
        ALLOCATE(IS_BND(NPOIN),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'GET_BND_NPOIN_MED:IKLE')
!
!       INITIALIZE
        DO I=1,NPOIN
          IS_BND(I)  = .FALSE.
        ENDDO
!
!       Loop on all the points of the boundary elements set their value to true
        DO I=1,NELEBD
          DO J=1,NDP
            IS_BND(IKLE(I+(J-1)*NELEBD)) = .TRUE.
          ENDDO
        ENDDO
!
!       COUNT THE NUMBER OF TRUE THIS WILL GIVE US THE NUMBER OF BOUNDARY POINTS
        NPTFR = COUNT(IS_BND.EQV..TRUE.)
        DEALLOCATE(IKLE)
        DEALLOCATE(IS_BND)
!
      ELSE
        NPTFR = 0
      ENDIF
!
#else
!
      NPTFR = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_BND_VALUE_MED(FILE_ID,TYPE_BND_ELEM,NELEBD,
     &                             LIHBOR,LIUBOR,LIVBOR,TRAC,LITBOR,
     &                             NPTFR,NBOR,IERR)
!
!BRIEF    DETERMINE THE NUMBER OF BOUNDARY POINTS
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_BND_ELEM  |<--| TYPE OF THE BOUNDARY ELEMENT
!| NELEBD         |<--| NUMBER OF BOUNDARY ELEMENTS
!| LIHBOR         |-->| TYPE OF BOUNDARY CONDITIONS ON DEPTH
!| LIUBOR         |-->| TYPE OF BOUNDARY CONDITIONS ON U
!| LIVBOR         |-->| TYPE OF BOUNDARY CONDITIONS ON V
!| TRAC           |-->| IF YES, THERE ARE TRACERS
!| LITBOR         |-->| PHYSICAL BOUNDARY CONDITIONS FOR TRACERS
!| NPTFR          |<--| NUMBER OF BOUNDARY NODES
!| NBOR           |<--| LOGICAL TABLE FOR BOUNDARY NODES
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
        IMPLICIT NONE
!
        INTEGER, INTENT(IN) :: FILE_ID
        INTEGER, INTENT(IN) :: TYPE_BND_ELEM
        INTEGER, INTENT(IN) :: NELEBD
        INTEGER, INTENT(IN) :: NPTFR
        INTEGER, INTENT(INOUT) :: LIUBOR(NPTFR),LIVBOR(NPTFR)
        INTEGER, INTENT(INOUT) :: LIHBOR(NPTFR),LITBOR(*)
        LOGICAL, INTENT(IN)    :: TRAC
        INTEGER, INTENT(IN) :: NBOR(NPTFR)
        INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
        CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
        INTEGER, ALLOCATABLE :: FAMILY(:)
        INTEGER, ALLOCATABLE :: IKLE(:)
        INTEGER :: NDP,IGRP,MED_ID
        INTEGER :: INODE,IELEM,K,IPTFR
        INTEGER :: TYPE_ELEM_MED
        INTEGER :: IGRP_CUR, IGRP_NXT
        INTEGER :: BND_TYP_CUR, BND_TYP_NXT
        INTEGER :: CURRENT, NEXT
        INTEGER :: NPTIR
        INTEGER :: IELEB
!
!-----------------------------------------------------------------------
!
!       GET INFO FROM THE MED FILE OBJECT
        CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_VALUE_MED:GET_OBJ')
        MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!       CONVERTS TYPE OF ELEMENTS
        CALL CONVERT_ELEM_TYPE(TYPE_BND_ELEM, TYPE_ELEM_MED, IERR)
        CALL CHECK_CALL(IERR,'GET_BND_VALUE_MED:CONVERT_ELEM_TYPE')
!
!       DETERMINE THE NUMBER OF NODES PER ELEMENT FROM THE TYPE
        CALL NDP_FROM_ELEMENT_TYPE_MED(TYPE_ELEM_MED,NDP,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_VALUE_MED:NDP_FROM_ELT_TYPE_MED')
!
!       Identify bnd element if necessary
        CALL IDENTIFY_BND_ELMT(FILE_ID,TYPE_BND_ELEM,IERR)
        CALL CHECK_CALL(IERR,'GET_BND_VALUE_MED:IDENTIFY_BND_ELMT')
!
        CALL GET_MESH_NPTIR_MED(FILE_ID, NPTIR, IERR)
        CALL CHECK_CALL(IERR,'GET_BND_VALUE_MED:GET_MESH_NPTIR_MED')

        IF(MED_OBJ_TAB(MED_ID)%NO_BND) THEN
          IERR = 0
          RETURN
        ENDIF
!
        DO IPTFR=1,NPTFR
          LIHBOR(IPTFR) = 0
          LIUBOR(IPTFR) = 0
          LIVBOR(IPTFR) = 0
          IF (TRAC) THEN
            LITBOR(IPTFR) =  0
          ENDIF
        ENDDO

        ! IF we have a partitionned file groups are on points
        ! otherwise they are on elements
        IF(NPTIR.NE.0) THEN
          ALLOCATE(FAMILY(NPTFR),STAT=IERR)
          CALL CHECK_ALLOCATE(IERR,'GET_BND_VALUE_MED:FAMILY')
          CALL GET_BND_FAMILY_MED(FILE_ID, TYPE_BND_ELEM, NPTFR,
     &                        FAMILY,IERR)
!         WRITE FAMILY NUMBER IN THE MED FILE

          CALL CHECK_CALL(IERR,'GET_BND_VALUE_MED:GET_BND_FAMILY_MED')
          DO IPTFR=1,NPTFR
            IGRP = FAMILY(IPTFR)
            LIHBOR(IPTFR) = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP,1)
            LIUBOR(IPTFR) = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP,2)
            LIVBOR(IPTFR) = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP,3)
            IF (TRAC) THEN
              LITBOR(IPTFR) = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP,4)
            ENDIF
          ENDDO
          DEALLOCATE(FAMILY)
        ELSE
          ALLOCATE(FAMILY(NELEBD),STAT=IERR)
          CALL CHECK_ALLOCATE(IERR,'GET_BND_VALUE_MED:FAMILY')
          CALL GET_BND_FAMILY_MED(FILE_ID,TYPE_BND_ELEM,NELEBD,
     &                            FAMILY,IERR)
          CALL CHECK_CALL(IERR,'GET_BND_VALUE_MED:GET_BND_FAMILY_MED')
!
          ALLOCATE(IKLE(NELEBD*NDP),STAT=IERR)
          CALL CHECK_ALLOCATE(IERR,'GET_BND_VALUE_MED:IKLE')
!
!         GET THE CONNECTIVITY TABLE
          CALL GET_BND_CONNECTIVITY_MED(FILE_ID, TYPE_BND_ELEM, NELEBD,
     &                                  NDP, IKLE, IERR)
          CALL CHECK_CALL(IERR,'GET_BND_VALUE_MED:GET_BND_CONN_MED')
!
!         LOOP ON ALL BOUNDARY POINTS
          DO IPTFR=1,NPTFR
            CURRENT = MED_OBJ_TAB(MED_ID)%PT2SEG(IPTFR,1)
            NEXT = MED_OBJ_TAB(MED_ID)%PT2SEG(IPTFR,2)
            INODE = MED_OBJ_TAB(MED_ID)%NBOR(IPTFR)
!
!           STORE VALUE OF THE GIVEN NODE
            IGRP_CUR = FAMILY(CURRENT)
            IGRP_NXT = FAMILY(NEXT)
            BND_TYP_CUR = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP_CUR,1)
            BND_TYP_NXT = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP_NXT,1)
            ! Identifying which boundary to take
            CALL SEG2POINT(CURRENT,NEXT,BND_TYP_CUR,BND_TYP_NXT,IELEB)
            IGRP = FAMILY(IELEB)
            ! Defining values
            LIHBOR(IPTFR) = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP,1)
            LIUBOR(IPTFR) = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP,2)
            LIVBOR(IPTFR) = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP,3)
            IF (TRAC) THEN
              LITBOR(IPTFR) = MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IGRP,4)
            ENDIF
          ENDDO
!
!         FREE MEMORY
          DEALLOCATE(FAMILY)
          DEALLOCATE(IKLE)
        ENDIF
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_DATA_NVAR_MED (FILE_ID, NVAR, IERR)
!
!BRIEF    READS THE NUMBER OF DATA IN A MED FILE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| NVAR           |-->| NUMBER OF DATA
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(OUT) :: NVAR
      INTEGER, INTENT(OUT) :: IERR
!
!-----------------------------------------------------------------------
!
#if defined (HAVE_MED)
!
!     READ THE NUMBER OF DATA
      CALL MFDNFD(FILE_ID,NVAR,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_NVAR_MED:MFDNFD')
!
#else
!
      NVAR = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_DATA_VAR_LIST_MED (FILE_ID, NVAR, VAR_LIST,
     &                                  UNIT_LIST, IERR)
!
!BRIEF    READS THE LIST OF THE DATA NAME
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| NVAR           |<--| NUMBER OF DATA
!| VAR_LIST       |-->| LIST OF THE DATA NAME
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(IN)  :: NVAR
      CHARACTER(LEN=16), DIMENSION(:), INTENT(OUT) :: VAR_LIST
      CHARACTER(LEN=16), DIMENSION(:), INTENT(OUT) :: UNIT_LIST
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: VAR_NAME, MNAME
      CHARACTER(LEN=MED_SNAME_SIZE) :: CUNIT, CNAME, DTUNIT
!
      INTEGER :: MED_ID, I, ITYPE, NSTEP, IMESH
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_VAR_LIST_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     LOOP ON THE VARIABLES
      DO I = 1, NVAR
!
!       READ THE NAME OF THE VARIABLE
        CALL MFDFDI(FILE_ID,I,VAR_NAME,MNAME,IMESH,ITYPE,
     &    CNAME,CUNIT,DTUNIT,NSTEP,IERR)
        CALL CHECK_CALL(IERR,'GET_DATA_VAR_LIST_MED:MFDFDI')
!
!       CONVERT MED FORMAT TO SLF
        VAR_LIST(I) = VAR_NAME(1:16)
        UNIT_LIST(I) = CUNIT
      ENDDO
!
#else
!
      VAR_LIST = ' '
      UNIT_LIST = ' '
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_DATA_NTIMESTEP_MED (FILE_ID, NTIMESTEP, IERR)
!
!BRIEF    READS THE NUMBER OF TIME STEP FOR A GIVEN VARIABLE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| NTIMESTEP      |-->| NUMBER OF TIME STEP
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(OUT) :: NTIMESTEP
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: VAR_NAME_MED, MNAME
      CHARACTER(LEN=MED_SNAME_SIZE) :: CUNIT,CNAME,DTUNIT
!
      INTEGER :: ITYPE, MED_ID, IMESH, NVAR
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_NTIMESTEP_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     READ THE NUMBER OF VARIABLES
      CALL MFDNFD(FILE_ID,NVAR,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_NTIMESTEP_MED:MFDNFD')
!
      IF(NVAR.NE.0) THEN
!
!       READ THE NUMBER OF TIME STEP FROM THE FIRST VARIABLE AS ALL
!       VARIABLE HAVE THE SAME NUMBER OF TIMESTEP
        CALL MFDFDI(FILE_ID,1,VAR_NAME_MED,MNAME,IMESH,
     &    ITYPE,CUNIT,CNAME,DTUNIT,NTIMESTEP,IERR)
        CALL CHECK_CALL(IERR,'GET_DATA_NTIMESTEP_MED:MFDFDI')
      ELSE

        NTIMESTEP = 0
      ENDIF
!
#else
!
      NTIMESTEP = 0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_DATA_TIME_MED (FILE_ID, RECORD, TIME, IERR)
!
!BRIEF    READS PHYSICAL TIME FOR A GIVEN ITERATION NUMBER
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| RECORD         |<--| ITERATION NUMBER
!| TIME           |-->| PHYSICAL TIME
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID, RECORD
      DOUBLE PRECISION, INTENT(OUT) :: TIME
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: VAR_NAME_MED
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
      CHARACTER(LEN=MED_SNAME_SIZE) :: CNAME,CUNIT,DTUNIT
      INTEGER :: N, MED_ID, LMESH
      INTEGER :: FTYPE
      INTEGER :: DT,IT
      INTEGER :: MED_ITER
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_TIME_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     GET THE NAME OF THE FIRST FIELD TO HAVE ACCESS TO THE TIME
      CALL MFDFDI(FILE_ID,1,VAR_NAME_MED,MNAME,LMESH,FTYPE,
     &            CNAME,CUNIT,DTUNIT,N,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_TIME_MED:MFDFDI')
!
!     READ THE PHYSICAL TIME TIME
      DT=MED_NO_DT
      IT=MED_NO_IT
      ! Iterations start from 1 and records start from 0
      MED_ITER = RECORD + 1
      CALL MFDCSI(FILE_ID,VAR_NAME_MED,MED_ITER,DT,IT,
     &            TIME,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_TIME_MED:MFDCSI')
!
#else
!
      TIME = 0.0
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
        RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE GET_DATA_VALUE_MED (FILE_ID,RECORD,VAR_NAME,
     &  RES_VALUE,N,IERR)
!
!BRIEF    READS DATA VALUES FOR A GIVEN ITERATION
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| RECORD         |<--| ITERATION NUMBER
!| VAR_NAME       |<--| NAME OF THE DATA
!| RES_VALUE      |-->| VECTOR WITH THE VALUE OF THE VARIABLE
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN) :: FILE_ID, RECORD, N
      CHARACTER(LEN=16), INTENT(IN) :: VAR_NAME
      DOUBLE PRECISION, INTENT(INOUT) :: RES_VALUE(N)
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: VAR_NAME_MED
!
      INTEGER :: MED_ID
      INTEGER :: LMESH, ITYPE, NSTEP
      CHARACTER(LEN=MED_SNAME_SIZE) :: CNAME,CUNIT,DTUNIT
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
      INTEGER :: NCOMP
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_VALUE_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     CONVERT SLF FORMAT TO MED
      VAR_NAME_MED = TRIM(VAR_NAME)//CHAR(0)
!
!     CHECKING THAT THE VARIABLE IS THE FILE
      CALL MFDNCN(FILE_ID,VAR_NAME_MED,NCOMP,IERR)
      IF(IERR.NE.0) THEN
        IERR = HERMES_VAR_UNKNOWN_ERR
        RETURN
      ENDIF
!
!     CHECKING THAT THE RECORD IS A VALID ONE (BETWEEN 0 AND NTIMESTEP-1)
!     READ THE NAME OF THE VARIABLE
      CALL MFDFIN(FILE_ID,VAR_NAME_MED,MNAME,LMESH,ITYPE,
     &  CNAME,CUNIT,DTUNIT,NSTEP,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_VALUE_MED:MFDFIN')
      IF(RECORD.GE.NSTEP.OR.RECORD.LT.0) THEN
        IERR = HERMES_RECORD_UNKNOWN_ERR
        RETURN
      ENDIF
!
!     READ THE VALUE FOR THIS VARIABLE AT THIS TIMESTEP
      CALL MFDRVR(FILE_ID,VAR_NAME_MED,RECORD,MED_NO_IT,MED_NODE,
     &  MED_NONE,MED_NO_INTERLACE,1,RES_VALUE,IERR)
      CALL CHECK_CALL(IERR,'GET_DATA_VALUE_MED:MFDRVR')
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE SET_HEADER_MED(FILE_ID,TITLE,IERR)
!
!BRIEF    WRITES THE TITLE OF THE MESH
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TITLE          |<--| TITLE OF THE MESH
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)  :: FILE_ID
      CHARACTER(LEN=80), INTENT(IN)  :: TITLE
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_COMMENT_SIZE) :: TITLE_MED
      INTEGER :: MED_ID
!
!-----------------------------------------------------------------------
!
!     CONVERSION FROM SLF FORMAT TO MED
      TITLE_MED = TITLE
!
!     WRITES THE TITLE OF THE MESH
      CALL MFICOW(FILE_ID,TITLE_MED,IERR)
      CALL CHECK_CALL(IERR,'SET_HEADER_MED:MFICOW')
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'SET_HEADER_MED:GET_OBJ')
      MED_OBJ_TAB(MED_ID)%MESH_NAME = 'MESH'
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE SET_MESH_MED(FILE_ID,NB_DIM_PB,NB_DIM_MESH,TYPE_ELEM,
     &  NDP,NPTIR,NELEM,NPOIN,IKLE,KNOLG,COORD,NPLAN,
     &  DATE,TIME,IERR)
!
!BRIEF    WRITES A MESH IN A MED FILE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| NB_DIM_PB      |<--| NUMBER OF DIMENSION OF THE PHYSICAL DOMAIN
!| NB_DIM_MESH    |<--| NUMBER OF DIMENSION OF THE MESH
!| TYPE_ELEM      |<--| TYPE OF THE ELEMENT IN SLF FORMAT
!| NDP            |<--| NUMBER OF POINTS PER ELEMENT
!| NPTIR          |<--| NUMBER OF INTERFACE NODES FOR THE SUB-DOMAIN
!| NELEM          |<--| TOTAL NUMBER OF ELEMENTS
!| NPOIN          |<--| TOTAL NUMBER OF NODES
!| IKLE           |<--| CONNECTIVITY TABLE
!| KNOLG          |<--| NODES INDEX TABLE FROM LOCAL TO GLOBAL
!| COORD          |<--| COORDINATES OF THE NODES
!| NPLAN          |<--| NUMBER OF PLANES
!| DATE           |<--| DATE OF THE FILE
!| TIME           |<--| TIME OF THE FILE
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN) :: FILE_ID, NB_DIM_PB, NB_DIM_MESH
      INTEGER, INTENT(IN) :: NELEM, NPOIN, TYPE_ELEM, NDP, NPTIR
      INTEGER, INTENT(IN) :: NPLAN
      INTEGER, INTENT(IN) :: IKLE(NDP*NELEM), KNOLG(NPOIN)
      DOUBLE PRECISION, INTENT(IN) :: COORD(NB_DIM_MESH*NPOIN)
      INTEGER, INTENT(IN) :: DATE(3), TIME(3)
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE)    :: MNAME
      CHARACTER(LEN=MED_NAME_SIZE)    :: DT_UNIT_MED
      CHARACTER(LEN=MED_NAME_SIZE)    :: FAM_ZERO
      CHARACTER(LEN=MED_NAME_SIZE)    :: PNAME
      CHARACTER(LEN=MED_SNAME_SIZE),ALLOCATABLE :: COOR_NAME_MED(:)
      CHARACTER(LEN=MED_SNAME_SIZE),ALLOCATABLE :: COOR_UNIT_MED(:)
      CHARACTER(LEN=MED_SNAME_SIZE)   :: COOR_X, COOR_Y, COOR_Z
      CHARACTER(LEN=MED_SNAME_SIZE)   :: COOR_UNIT
      CHARACTER(LEN=MED_COMMENT_SIZE) :: COMMENT
!
      INTEGER :: IFAM, MED_ID, TYPE_ELEM_MED,I, MYDATE
      INTEGER :: NPLAN_TMP
!
!-----------------------------------------------------------------------
!
!     INITIALISE COORDINATE UNIT AND NAME
      COMMENT = 'TELEMAC GENERATED MESH'//CHAR(0)
      COOR_X = 'X'//CHAR(0)
      COOR_Y = 'Y'//CHAR(0)
      COOR_Z = 'Z'//CHAR(0)
      COOR_UNIT = 'M'//CHAR(0)
      ALLOCATE(COOR_NAME_MED(NB_DIM_PB),STAT=IERR)
      CALL CHECK_ALLOCATE(IERR,'COOR_NAME_MED')
      ALLOCATE(COOR_UNIT_MED(NB_DIM_PB),STAT=IERR)
      CALL CHECK_ALLOCATE(IERR,'COOR_UNIT_MED')
      COOR_NAME_MED(1) = COOR_X
      COOR_NAME_MED(2) = COOR_Y
      IF (NB_DIM_PB.EQ.3) COOR_NAME_MED(3) = COOR_Z
      DO I=1,NB_DIM_PB
        COOR_UNIT_MED(I) = COOR_UNIT
      ENDDO
!
!     INITIALISE TIME UNIT
      DT_UNIT_MED = 'S'//CHAR(0)
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_ELEM,TYPE_ELEM_MED,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:CONVERT_ELEM_TYPE')
!
!     CREATES A MESH IN THE MED FILE
      CALL MMHCRE(FILE_ID,MNAME,NB_DIM_PB,NB_DIM_MESH,
     &  MED_UNSTRUCTURED_MESH,COMMENT,DT_UNIT_MED,MED_SORT_DTIT,
     &  MED_CARTESIAN,COOR_NAME_MED,COOR_UNIT_MED,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MMHCRE')
      DEALLOCATE(COOR_NAME_MED)
      DEALLOCATE(COOR_UNIT_MED)
!
!     WRITES NODE COORDINATES
      CALL MMHCOW(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,0.D0,
     &  MED_NO_INTERLACE,NPOIN,COORD,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MMHCOW')
!
!     WRITES CONNECTIVITY TABLE
      CALL MMHCYW(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,0.0,MED_CELL,
     &  TYPE_ELEM_MED,MED_NODAL,MED_NO_INTERLACE,NELEM,IKLE,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MMHCYW')
!
!     WRITES THE NUMBER OF PMANES
      PNAME = 'NPLAN'//char(0)
      COMMENT = 'Number of planes'//char(0)
!
!     CREATES THE PARAMETER
      CALL MPRCRE(FILE_ID,PNAME,MED_INT,COMMENT,DT_UNIT_MED,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MPRCRE')
!
!     SETS THE VALUE
      IF(NPLAN.LE.1) THEN
        NPLAN_TMP = 0
      ELSE
        NPLAN_TMP = NPLAN
      ENDIF
      CALL MPRIVW(FILE_ID,PNAME,MED_NO_DT,MED_NO_IT,0.0,NPLAN_TMP,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MPRIVW')
!
!     WRITES THE DATE
      PNAME = 'DATE'//char(0)
      COMMENT = 'Date of the file'//char(0)
!
!     CREATES THE PARAMETER
      CALL MPRCRE(FILE_ID,PNAME,MED_INT,COMMENT,DT_UNIT_MED,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MPRCRE')
!
!     SETS THE VALUE
      MYDATE = DATE(1)*10000 +
     &         DATE(2)*100 +
     &         DATE(3)
      CALL MPRIVW(FILE_ID,PNAME,MED_NO_DT,MED_NO_IT,0.0,MYDATE,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MPRIVW')
!
!     WRITES THE TIME
      PNAME = 'TIME'//char(0)
      COMMENT = 'Time of the file'//char(0)
!
!     CREATES THE PARAMETER
      CALL MPRCRE(FILE_ID,PNAME,MED_INT,COMMENT,DT_UNIT_MED,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MPRCRE')
!
!     SETS THE VALUE
      MYDATE = TIME(1)*10000 +
     &         TIME(2)*100 +
     &         TIME(3)
      CALL MPRIVW(FILE_ID,PNAME,MED_NO_DT,MED_NO_IT,0.0,MYDATE,IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MPRIVW')
!
!     IF PARTITIONNED FILE
      IF(NPTIR.NE.0) THEN
!
!       WRITES THE GLOBAL NUMBERING
        CALL MMHGNW(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_NODE,
     &              MED_NONE,NPOIN,KNOLG,IERR)
        CALL CHECK_CALL(IERR,'SET_MESH_MED:MMHGNW')
!
!       WRITES THE NUMBER OF INTERFACE POINT AS A SCALAR PARAMETER
        PNAME = 'NPTIR'//char(0)
        COMMENT = 'Number of interface points'//char(0)
!
!       CREATES THE PARAMETER
        CALL MPRCRE(FILE_ID,PNAME,MED_INT,COMMENT,DT_UNIT_MED,IERR)
        CALL CHECK_CALL(IERR,'SET_MESH_MED:MPRCRE')
!
!       SETS THE VALUE
        CALL MPRIVW(FILE_ID,PNAME,MED_NO_DT,MED_NO_IT,0.0,NPTIR,IERR)
        CALL CHECK_CALL(IERR,'SET_MESH_MED:MPRIVW')
      ENDIF
!
!     CREATE FAMILLY ZERO
!     DEFAULT FAMILY NEEDED BY MED FILE
      FAM_ZERO = 'FAMILY_ZERO'//CHAR(0)
      IFAM = 0
      CALL MFACRE(FILE_ID,MNAME,FAM_ZERO,IFAM,0,' ',IERR)
      CALL CHECK_CALL(IERR,'SET_MESH_MED:MFACRE')
!
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE ADD_DATA_MED (FILE_ID, VAR_NAME, TIME, RECORD,
     &  VAR_VALUE, N, IERR)
!
!BRIEF    WRITE DATA VALUES FOR A GIVEN VARIABLE
!         ONLY FOR VALUES WITH DOUBLE PRECISION, ONE COMPONENT AND VALUE
!         ON THE NODES
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| VAR_NAME       |<--| NAME OF THE DATA
!| TIME           |<--| PHYSICAL TIME
!| RECORD         |<--| ITERATION NUMBER
!| VAR_VALUE      |<--| TABLE OF VARIABLE VALUES
!| N              |<--| NUMBER OF ELEMENTS
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN) :: FILE_ID, N
      INTEGER, INTENT(IN) :: RECORD
      CHARACTER(LEN=32), INTENT(IN) :: VAR_NAME
      DOUBLE PRECISION, INTENT(IN) :: TIME
      DOUBLE PRECISION, INTENT(IN) :: VAR_VALUE(N)
      INTEGER, INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME, VAR_NAME_MED
      CHARACTER(LEN=MED_SNAME_SIZE) :: VAR_COMP_MED, UNIT_VAR_MED
      CHARACTER(LEN=MED_SNAME_SIZE) :: UNIT_TIME_MED
      INTEGER :: NB_COMP
      INTEGER :: MED_ID
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR, 'ADD_DATA_MED:GET_MED_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
      NB_COMP = 1! ONLY ONE COMPONENT
!
!     CONVERT SLF FORMAT TO MED
      VAR_NAME_MED  = TRIM(VAR_NAME(1:16))//CHAR(0)
      VAR_COMP_MED  = TRIM(VAR_NAME(1:16))//CHAR(0)
      UNIT_VAR_MED  = TRIM(VAR_NAME(17:32))//CHAR(0)
      UNIT_TIME_MED = 'S'//CHAR(0)
!
      IF(RECORD.EQ.0) THEN
!       CREATE A NEW VARIABLE (DOUBLE PRECISION WITH ONE COMPONENT)
        CALL MFDCRE(FILE_ID,VAR_NAME_MED,MED_FLOAT64,NB_COMP,
     &    VAR_COMP_MED,UNIT_VAR_MED,UNIT_TIME_MED,MNAME,IERR)
        CALL CHECK_CALL(IERR,'ADD_DATA_MED:MFDCRE')
      ENDIF
!
!     WRITE DATA VALUES FOR A GIVEN VARIABLE
      CALL MFDRVW(FILE_ID,VAR_NAME_MED,RECORD,MED_NO_IT,TIME,MED_NODE,
     &  MED_NONE,MED_NO_INTERLACE,NB_COMP,N,VAR_VALUE,IERR)
      CALL CHECK_CALL(IERR,'ADD_DATA_MED:MFDRVW')
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      RETURN
      END SUBROUTINE
#if defined HAVE_MED
      SUBROUTINE TRANSFER_GROUP_INFO_COMMON_MED(SOURCE_ID,DEST_ID,
     &                    MNAME_SRC,MNAME_DST,HAS_FAM_ON_POINT,IERR)
!BRIEF    Transfer group and families definition from source_id into dest_id
!
!history  Y AUDOUIN (LNHE)
!+        24/03/2014
!+        V7P0
!+
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| SOURCE_ID       |-->| FILE DESCRIPTOR OF INPUT FILE
!| DEST_ID         |-->| FILE DESCRIPTOR OF OUTPUT FILE
!| MNAME_SRC       |<->| MESH NAME FOR INPUT FILE
!| MNAME_DST       |<->| MESH NAME FOR OUTPUT FILE
!| HAS_FAM_ON_POINT|-->| CONNECTIVITY FOR OUTPUT FILE BOUNDARY ELEMENTS
!| IERR            |<--| 0 IF NO ERROR DURING THE EXECUTION
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER,          INTENT(IN)  :: SOURCE_ID
      INTEGER,          INTENT(IN)  :: DEST_ID
      CHARACTER(LEN=MED_NAME_SIZE), INTENT(INOUT):: MNAME_SRC, MNAME_DST
      LOGICAL, INTENT(OUT) :: HAS_FAM_ON_POINT
      INTEGER,          INTENT(OUT) :: IERR
!
      INTEGER :: MED_ID_SRC, MED_ID_DST
      INTEGER :: NB_GRP, NBND_GRP
      CHARACTER(LEN=MED_LNAME_SIZE),ALLOCATABLE :: GRP_NAME(:)
      CHARACTER(LEN=MED_NAME_SIZE) FAM_NAME
      INTEGER :: I
      INTEGER :: INUM, IFAM, NB_FAMILY
      INTEGER :: NPTIR

!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,SOURCE_ID,MED_ID_SRC,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NELEM_MED:GET_OBJ')
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,DEST_ID,MED_ID_DST,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NELEM_MED:GET_OBJ')
      MNAME_SRC = MED_OBJ_TAB(MED_ID_SRC)%MESH_NAME
      MNAME_DST = MED_OBJ_TAB(MED_ID_DST)%MESH_NAME

      CALL MFANFA(SOURCE_ID,MNAME_SRC,NB_FAMILY,IERR)
      CALL CHECK_CALL(IERR,'TRANSFER_GROUP_COMMON:MFANFA')
!
      HAS_FAM_ON_POINT = .FALSE.
      ! Creating all the families that are in src into dest
      DO IFAM = 1, NB_FAMILY
!
!       READ THE NUMBER OF GROUP PER FAMILY
        CALL MFANFG(SOURCE_ID,MNAME_SRC,IFAM,NB_GRP,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_COMMON:MFANFG')
!
        ALLOCATE(GRP_NAME(MAX(NB_GRP,1)),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'TRANSFER_GROUP_COMMON:GRP_NAME')
        GRP_NAME(:) = REPEAT(' ',MED_LNAME_SIZE)

!       READ THE TYPE OF FAMILY
        CALL MFAFAI(SOURCE_ID,MNAME_SRC,IFAM,FAM_NAME,INUM,
     &              GRP_NAME,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_COMMON:MFAFAI')
        ! Skipping famille_zero
        IF(INUM.EQ.0) THEN
          DEALLOCATE(GRP_NAME)
          CYCLE
        ENDIF
        ! Families on point have a positive number
        IF(INUM.GT.0) HAS_FAM_ON_POINT = .TRUE.
!
        ! WRITE THE FAMILY
        CALL MFACRE(DEST_ID,MNAME_DST,FAM_NAME,INUM,MAX(NB_GRP,1),
     &              GRP_NAME,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_COMMON:MFACRE')
!
        DEALLOCATE(GRP_NAME)
      ENDDO

      CALL GET_MESH_NPTIR_MED(DEST_ID, NPTIR, IERR)
      CALL CHECK_CALL(IERR,'GET_BND_VALUE_MED:GET_MESH_NPTIR_MED')

      ! Only writing grp info if not in a partitionned file
      IF(NPTIR.EQ.0) THEN
        ! Transfering group values from SRC_ID
        MED_OBJ_TAB(MED_ID_DST)%NBND_GRP =
     &          MED_OBJ_TAB(MED_ID_SRC)%NBND_GRP
        NBND_GRP = MED_OBJ_TAB(MED_ID_DST)%NBND_GRP
        ALLOCATE(MED_OBJ_TAB(MED_ID_DST)%BND_GRP_VAL(NBND_GRP,4),
     &           STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'BND_GRP_VAL')
        ALLOCATE(MED_OBJ_TAB(MED_ID_DST)%BND_GRP_NAME(NBND_GRP),
     &           STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'BND_GRP_NAME')
        DO I=1,NBND_GRP
          MED_OBJ_TAB(MED_ID_DST)%BND_GRP_VAL(I,1) =
     &           MED_OBJ_TAB(MED_ID_SRC)%BND_GRP_VAL(I,1)
          MED_OBJ_TAB(MED_ID_DST)%BND_GRP_VAL(I,2) =
     &           MED_OBJ_TAB(MED_ID_SRC)%BND_GRP_VAL(I,2)
          MED_OBJ_TAB(MED_ID_DST)%BND_GRP_VAL(I,3) =
     &           MED_OBJ_TAB(MED_ID_SRC)%BND_GRP_VAL(I,3)
          MED_OBJ_TAB(MED_ID_DST)%BND_GRP_VAL(I,4) =
     &           MED_OBJ_TAB(MED_ID_SRC)%BND_GRP_VAL(I,4)
          MED_OBJ_TAB(MED_ID_DST)%BND_GRP_NAME(I)(:) =
     &           MED_OBJ_TAB(MED_ID_SRC)%BND_GRP_NAME(I)
        ENDDO
      ENDIF
      END SUBROUTINE
#endif
!
      SUBROUTINE TRANSFER_GROUP_PART_INFO_MED(
     &     SOURCE_ID, DEST_ID,
     &     TYP_BND_ELEM, IKLE_BND_DEST, NELEBD_DEST,
     &     NDP_DEST, NELEBD_SRC, KNOGL_BND,
     &     TRANS_POINT, NPOIN_SRC, NPOIN_DEST, KNOLG, IERR)
!BRIEF    Transfer group information from source_id into dest_id
!+        Writes boundary elements as well where dest_id is a partition
!+        of source_id
!
!history  Y AUDOUIN (LNHE)
!+        24/03/2014
!+        V7P0
!+
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| SOURCE_ID      |-->| FILE DESCRIPTOR OF INPUT FILE
!| DEST_ID        |-->| FILE DESCRIPTOR OF OUTPUT FILE
!| TYPE_ELEM      |-->| TYPE OF THE ELEMENTS
!| TYPE_BND_ELEM  |-->| TYPE OF THE BOUNDARY ELEMENTS
!| IKLE_BND_DEST  |-->| CONNECTIVITY FOR OUTPUT FILE BOUNDARY ELEMENTS
!| NELEBD_DEST    |-->| NUMBER OF BOUNDARY ELEMENTS IN OUTPUT FILE
!| NDP_DEST       |-->| Number of node per element in output file
!| NELEBD_SRC     |-->| Number of noudary elements in the input file
!| KNOGL_BND      |-->| Local to global numbering for boundary elements
!| TRANS_POINT    |-->| IF TRUE TRANSFERING GROUP ON POINTS AS WELL
!| NPOIN_SRC      |-->| Number of points in input file
!| NPOIN_DEST     |-->| Number if points in output file
!| KNOLG          |-->| Local to global numbering
!| IERR           |<--| 0 IF NO ERROR DURING THE EXECUTION
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
!
      IMPLICIT NONE
!
      INTEGER,          INTENT(IN)  :: SOURCE_ID
      INTEGER,          INTENT(IN)  :: DEST_ID
      INTEGER,          INTENT(IN)  :: NELEBD_DEST
      INTEGER,          INTENT(IN)  :: NDP_DEST
      INTEGER,      INTENT(IN)  :: IKLE_BND_DEST(NELEBD_DEST*NDP_DEST)
      INTEGER,          INTENT(IN)  :: TYP_BND_ELEM
      INTEGER,          INTENT(IN)  :: NELEBD_SRC
      INTEGER,          INTENT(IN)  :: KNOGL_BND(NELEBD_SRC)
      LOGICAL,          INTENT(IN)  :: TRANS_POINT
      INTEGER,          INTENT(IN)  :: NPOIN_SRC
      INTEGER,          INTENT(IN)  :: NPOIN_DEST
      INTEGER,          INTENT(IN)  :: KNOLG(NPOIN_DEST)
      INTEGER,          INTENT(OUT) :: IERR
!
#if defined HAVE_MED
      CHARACTER(LEN=MED_NAME_SIZE)    :: MNAME, MNAME2
      INTEGER :: TYPE_ELEM_MED
      INTEGER, ALLOCATABLE :: FAM_NUM(:)
      INTEGER, ALLOCATABLE :: FAM_NUM_DEST(:)
      INTEGER :: I,J
      INTEGER :: NELEM_SRC
      LOGICAL :: HAS_FAM_ON_POINT
      INTEGER :: MED_ID
!

      ! Transferring families and group info
      CALL TRANSFER_GROUP_INFO_COMMON_MED(SOURCE_ID, DEST_ID, MNAME,
     &                 MNAME2, HAS_FAM_ON_POINT, IERR)
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,SOURCE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'GET_BND_NELEM_MED:GET_OBJ')

      ! For boundary elements
      IF(TYP_BND_ELEM.NE.0.AND.NELEBD_DEST.NE.0) THEN
!       READ THE FAMILY NUMBER FOR EACH ELEMENT
        CALL CONVERT_ELEM_TYPE(TYP_BND_ELEM, TYPE_ELEM_MED, IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_PART:CONVERT_ELEM_TYPE')

!       WRITES CONNECTIVITY TABLE
        CALL MMHCYW(DEST_ID,MNAME2,MED_NO_DT,MED_NO_IT,0.0,MED_CELL,
     &    TYPE_ELEM_MED,MED_NODAL,MED_NO_INTERLACE,NELEBD_DEST,
     &    IKLE_BND_DEST,IERR)
        CALL CHECK_CALL(IERR,'SET_MESH_MED:MMHCYW:BND')

        ! Number of element of type typ_bnd_elem
        CALL GET_MESH_NELEM_MED(SOURCE_ID, TYP_BND_ELEM,
     &                          NELEM_SRC, IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:CONVERT_ELEM_TYPE')

        ! Getting family number of every boundary element in input file
        ALLOCATE(FAM_NUM(NELEM_SRC),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'TRANSFER_GROUP_PART:FAM_NUM:BND')

        CALL MMHFNR(SOURCE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &              TYPE_ELEM_MED,FAM_NUM,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_PART:MMHFNR:BND')

        ! Building family number for ouput file using knolg_bnd
        ALLOCATE(FAM_NUM_DEST(NELEBD_DEST),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'FAM_NUM_DEST:BND')
        J = 0
        DO I=1,NELEM_SRC
          IF(MED_OBJ_TAB(MED_ID)%IS_BND(I)) THEN
            J = J+1
            IF(KNOGL_BND(J).EQ.0) THEN
              CYCLE
            ENDIF
            FAM_NUM_DEST(KNOGL_BND(J)) = FAM_NUM(I)
          ENDIF
        ENDDO
        ! Writting family number for boundary element
        CALL MMHFNW(DEST_ID,MNAME2,MED_NO_DT,MED_NO_IT,MED_CELL,
     &              TYPE_ELEM_MED,NELEBD_DEST,FAM_NUM_DEST,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_PART:MMHFNW:BND')

        DEALLOCATE(FAM_NUM)
        DEALLOCATE(FAM_NUM_DEST)
      ENDIF

      ! For nodes
      IF(TRANS_POINT.AND.HAS_FAM_ON_POINT) THEN
!       READ THE FAMILY NUMBER FOR EACH ELEMENT

        ALLOCATE(FAM_NUM(NPOIN_SRC),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'TRANSFER_GROUP_PART:FAM_NUM')

        CALL MMHFNR(SOURCE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_NODE,
     &              MED_NONE,FAM_NUM,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_PART:MMHFNR')

        ! Building family number for ouput file using knolg
        ALLOCATE(FAM_NUM_DEST(NPOIN_DEST),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'FAM_NUM_DEST')
        DO I=1,NPOIN_DEST
          FAM_NUM_DEST(I) = FAM_NUM(KNOLG(I))
        ENDDO
        ! Writting family number for point
        CALL MMHFNW(DEST_ID,MNAME2,MED_NO_DT,MED_NO_IT,MED_NODE,
     &              MED_NONE,NPOIN_DEST,FAM_NUM_DEST,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_PART:MMHFNW')

        DEALLOCATE(FAM_NUM)
        DEALLOCATE(FAM_NUM_DEST)
      ENDIF
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      END SUBROUTINE
!
      SUBROUTINE TRANSFER_GROUP_INFO_MED(SOURCE_ID, DEST_ID, TYP_ELEM,
     &                               TYP_BND_ELEM, IKLE_BND, NELEBD,
     &                               NDP, TRANS_ELEM,
     &                               TRANS_POINT, IERR)
!BRIEF    Transfer group information from source_id into dest_id
!         Writes boundary elements as well
!
!history  Y AUDOUIN (LNHE)
!+        24/03/2014
!+        V7P0
!+
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FFORMAT        |-->| FORMAT OF THE FILE
!| FID            |-->| FILE DESCRIPTOR OF INPUT FILE
!| FID2           |-->| FILE DESCRIPTOR OF OUTPUT FILE
!| TYPE_ELT       |-->| TYPE OF THE ELEMENTS
!| TYPE_BND_ELT   |-->| TYPE OF THE BOUNDARY ELEMENTS
!| TRANS_ELEM     |-->| IF TRUE TRANSFERING GROUP ON TYP_ELT AS WELL
!| TRANS_POINT    |-->| IF TRUE TRANSFERING GROUP ON POINTS AS WELL
!| IERR           |<--| 0 IF NO ERROR DURING THE EXECUTION
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
!
      IMPLICIT NONE
!
      INTEGER,          INTENT(IN)  :: SOURCE_ID
      INTEGER,          INTENT(IN)  :: DEST_ID
      INTEGER,          INTENT(IN)  :: NELEBD
      INTEGER,          INTENT(IN)  :: NDP
      INTEGER,          INTENT(IN)  :: IKLE_BND(NELEBD*NDP)
      INTEGER,          INTENT(IN)  :: TYP_ELEM
      INTEGER,          INTENT(IN)  :: TYP_BND_ELEM
      LOGICAL,          INTENT(IN)  :: TRANS_ELEM
      LOGICAL,          INTENT(IN)  :: TRANS_POINT
      INTEGER,          INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE)    :: MNAME_SRC, MNAME_DST
      INTEGER :: TYPE_ELEM_MED
      INTEGER, ALLOCATABLE :: FAM_NUM_SRC(:), FAM_NUM_DST(:)
      INTEGER :: NPOIN
      INTEGER :: NELEM,NELEBD_SRC
      LOGICAL :: HAS_FAM_ON_POINT
      INTEGER :: I,J
      INTEGER :: MED_ID
!
      CALL GET_OBJ(HASH,SOURCE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'OPEN_BND_MED:GET_OBJ')
      ! Transferring families and group info
      CALL TRANSFER_GROUP_INFO_COMMON_MED(SOURCE_ID, DEST_ID, MNAME_SRC,
     &                 MNAME_DST, HAS_FAM_ON_POINT, IERR)
      ! For boundary elements
      IF(TYP_BND_ELEM.NE.0.AND.NELEBD.NE.0) THEN
!       READ THE FAMILY NUMBER FOR EACH ELEMENT
        CALL CONVERT_ELEM_TYPE(TYP_BND_ELEM, TYPE_ELEM_MED, IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:CONVERT_ELEM_TYPE')

!       WRITES CONNECTIVITY TABLE
        CALL MMHCYW(DEST_ID,MNAME_DST,MED_NO_DT,MED_NO_IT,0.0,MED_CELL,
     &    TYPE_ELEM_MED,MED_NODAL,MED_NO_INTERLACE,NELEBD,
     &    IKLE_BND,IERR)
        CALL CHECK_CALL(IERR,'SET_MESH_MED:MMHCYW')

        CALL GET_MESH_NELEM_MED(SOURCE_ID, TYP_BND_ELEM,
     &                          NELEBD_SRC, IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:CONVERT_ELEM_TYPE')

        ALLOCATE(FAM_NUM_SRC(NELEBD_SRC),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'TRANSFER_GROUP_INFO:FAM_NUM_DST')

        CALL MMHFNR(SOURCE_ID,MNAME_SRC,MED_NO_DT,MED_NO_IT,MED_CELL,
     &              TYPE_ELEM_MED,FAM_NUM_SRC,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:MMHFNR')

        ALLOCATE(FAM_NUM_DST(NELEBD),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'TRANSFER_GROUP_INFO:FAM_NUM_DST')
        J = 0
        DO I=1,NELEBD_SRC
          IF(MED_OBJ_TAB(MED_ID)%IS_BND(I)) THEN
            J = J+1
            FAM_NUM_DST(J) = FAM_NUM_SRC(I)
          ENDIF
        ENDDO

        CALL MMHFNW(DEST_ID,MNAME_DST,MED_NO_DT,MED_NO_IT,MED_CELL,
     &              TYPE_ELEM_MED,NELEBD,FAM_NUM_DST,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:MMHFNW')
        DEALLOCATE(FAM_NUM_DST)
        DEALLOCATE(FAM_NUM_SRC)
      ENDIF

      IF(TRANS_ELEM) THEN
        ! For elements
        CALL GET_MESH_NELEM_MED(SOURCE_ID, TYP_ELEM, NELEM, IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:CONVERT_ELEM_TYPE')
!       READ THE FAMILY NUMBER FOR EACH ELEMENT
        CALL CONVERT_ELEM_TYPE(TYP_ELEM, TYPE_ELEM_MED, IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:CONVERT_ELEM_TYPE')

        ALLOCATE(FAM_NUM_DST(NELEM),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'TRANSFER_GROUP_INFO:FAM_NUM:ELEM')
        FAM_NUM_DST(:) = 0

        CALL MMHFNR(SOURCE_ID,MNAME_SRC,MED_NO_DT,MED_NO_IT,MED_CELL,
     &              TYPE_ELEM_MED,FAM_NUM_DST,IERR)
        ! If the function crashed that means we do not have
        ! families on the elements
        IF(IERR.GE.0) THEN
          CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:MMHFNR:ELEM')

          CALL MMHFNW(DEST_ID,MNAME_DST,MED_NO_DT,MED_NO_IT,MED_CELL,
     &                TYPE_ELEM_MED,NELEM,FAM_NUM_DST,IERR)
          CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:MMHFNW:ELEM')
        ELSE
          IERR = 0
        ENDIF
        DEALLOCATE(FAM_NUM_DST)
      ENDIF

      ! For nodes
      IF(TRANS_POINT.AND.HAS_FAM_ON_POINT) THEN
        CALL GET_MESH_NPOIN_MED(SOURCE_ID, TYP_ELEM, NPOIN, IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:CONVERT_ELEM_TYPE')
!       READ THE FAMILY NUMBER FOR EACH ELEMENT

        ALLOCATE(FAM_NUM_DST(NPOIN),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'TRANSFER_GROUP_INFO:FAM_NUM_DST')

        CALL MMHFNR(SOURCE_ID,MNAME_SRC,MED_NO_DT,MED_NO_IT,MED_NODE,
     &              MED_NONE,FAM_NUM_DST,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:MMHFNR')

        CALL MMHFNW(DEST_ID,MNAME_DST,MED_NO_DT,MED_NO_IT,MED_NODE,
     &              MED_NONE,NPOIN,FAM_NUM_DST,IERR)
        CALL CHECK_CALL(IERR,'TRANSFER_GROUP_INFO:MMHFNW')
        DEALLOCATE(FAM_NUM_DST)
      ENDIF
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      END SUBROUTINE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| SOURCE_ID     |<--| MED FILE DESCRIPTOR
!| FILEID        |<--| MED FILE DESCRIPTOR
!| IERR          |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
!-----------------------------------------------------------------------
!
      SUBROUTINE SET_BND_MED(FILE_ID,TYPE_BND_ELT,NELEBD,NDP,IKLE_BND,
     &                       NPTFR,LIHBOR,LIUBOR,LIVBOR,LITBOR,IERR)
!
!BRIEF    WRITE DATA VALUES FOR A GIVEN VARIABLE
!         ONLY FOR VALUES WITH DOUBLE PRECISION, ONE COMPONENT AND VALUE
!         ON THE NODES
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |<--| MED FILE DESCRIPTOR
!| TYPE_BND_ELT   |<--| TYPE OF THE BOUNDARY ELEMENT
!| NELEBD         |<--| NUMBER OF BOUNDARY ELEMENT
!| NDP            |<--| NUMBER OF NODES PER ELEMENT
!| IKLE           |<--| CONNECTIVITY TABLE OF THE BOUNDARY ELEMENTS
!| LIHBOR         |-->| TYPE OF BOUNDARY CONDITIONS ON DEPTH
!| LIUBOR         |-->| TYPE OF BOUNDARY CONDITIONS ON U
!| LIVBOR         |-->| TYPE OF BOUNDARY CONDITIONS ON V
!| LITBOR         |-->| PHYSICAL BOUNDARY CONDITIONS FOR TRACERS
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER,          INTENT(IN)  :: FILE_ID
      INTEGER,          INTENT(IN)  :: TYPE_BND_ELT
      INTEGER,          INTENT(IN)  :: NELEBD
      INTEGER,          INTENT(IN)  :: NDP
      INTEGER,          INTENT(IN)  :: IKLE_BND(NELEBD*NDP)
      INTEGER,          INTENT(IN)  :: NPTFR
      INTEGER,          INTENT(IN)  :: LIUBOR(NPTFR),LIVBOR(NPTFR)
      INTEGER,          INTENT(IN)  :: LIHBOR(NPTFR),LITBOR(NPTFR)
      INTEGER,          INTENT(OUT) :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE)    :: MNAME
      INTEGER :: MED_ID, TYPE_BND_ELEM_MED
      CHARACTER(LEN=MED_LNAME_SIZE) GRP_NAME
      CHARACTER(LEN=MED_NAME_SIZE) FAM_NAME
      INTEGER :: NCLI,I,J,K,IPTFR
      INTEGER,ALLOCATABLE :: FAM_NUM(:)
      INTEGER, PARAMETER :: NVAL(3) = (/3,5,3/)
      INTEGER :: H_VAL(NVAL(1))
      INTEGER :: U_VAL(NVAL(2))
      INTEGER :: T_VAL(NVAL(3))
      INTEGER :: LIST_VAL(NVAL(1)*NVAL(2)*NVAL(3))
      INTEGER :: IFAM
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'SET_BND_MED:GET_OBJ')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
      NCLI = MED_OBJ_TAB(MED_ID)%NCLI
!
!     CONVERTS TYPE OF ELEMENTS
      CALL CONVERT_ELEM_TYPE(TYPE_BND_ELT,TYPE_BND_ELEM_MED,IERR)
      CALL CHECK_CALL(IERR,'SET_BND_MED:CONVERT_ELEM_TYPE')
!
      ! If we do not have families in the file creating somes
      IF(MED_OBJ_TAB(MED_ID)%NBND_GRP.EQ.0) THEN
!       WRITES CONNECTIVITY TABLE
        CALL MMHCYW(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,0.0,MED_CELL,
     &    TYPE_BND_ELEM_MED,MED_NODAL,MED_NO_INTERLACE,NELEBD,
     &    IKLE_BND,IERR)
        CALL CHECK_CALL(IERR,'SET_BND_MED:MMHCYW')
!
        ! Create all the types of boundary conditions
        H_VAL = (/ 4,5,2/)
        U_VAL = (/ 6,0,4,5,2/)
        T_VAL = (/ 4,5,2/)
        MED_OBJ_TAB(MED_ID)%NBND_GRP = NVAL(1)*NVAL(2)*NVAL(3)
        ALLOCATE(MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(
     &               MED_OBJ_TAB(MED_ID)%NBND_GRP,4), STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'MEDOBJ%BND_GRP_VAL')
        ALLOCATE(MED_OBJ_TAB(MED_ID)%BND_GRP_NAME(
     &               MED_OBJ_TAB(MED_ID)%NBND_GRP), STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'MEDOBJ%GRP_NAME')

        IFAM = 1
        DO I=1,NVAL(1)
          DO J=1,NVAL(2)
            DO K=1,NVAL(3)
              MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IFAM,1) = H_VAL(I)
              MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IFAM,2) = U_VAL(J)
              MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IFAM,3) = U_VAL(J)
              MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(IFAM,4) = T_VAL(K)
              LIST_VAL(IFAM) =
     &              H_VAL(I)*1000 + U_VAL(J)*100
     &              + U_VAL(J)*10 + T_VAL(K)
              GRP_NAME = REPEAT(' ',MED_LNAME_SIZE)
              GRP_NAME = 'CONLIM_'//TRIM(I2CHAR(H_VAL(I)))//
     &                   TRIM(I2CHAR(U_VAL(J)))//
     &                   TRIM(I2CHAR(U_VAL(J)))//
     &                   TRIM(I2CHAR(T_VAL(K)))
              MED_OBJ_TAB(MED_ID)%BND_GRP_NAME(IFAM) = GRP_NAME
              FAM_NAME = 'FAM_'//TRIM(GRP_NAME)
!             CREATING THE FAMILIES FOR EACH BOUNDARY TYPES
              CALL MFACRE(FILE_ID,MNAME,FAM_NAME,IFAM+OFFSET,1,
     &                    GRP_NAME,IERR)
              CALL CHECK_CALL(IERR,
     &               'SET_BND_MED:MFACRE:'//TRIM(GRP_NAME))
              IFAM = IFAM + 1
            ENDDO
          ENDDO
        ENDDO
!
!       DEFINE FAMILY NUMBER
        IF(NPTFR.GT.0) THEN
          ALLOCATE(FAM_NUM(NPTFR),STAT=IERR)
          CALL CHECK_ALLOCATE(IERR,'FAM_NUM')
          FAM_NUM = 0
          DO IPTFR=1,NPTFR
            FAM_NUM(IPTFR) = 0
            DO J=1,MED_OBJ_TAB(MED_ID)%NBND_GRP
              IF(
     &      LIHBOR(IPTFR).EQ.MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(J,1).AND.
     &      LIUBOR(IPTFR).EQ.MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(J,2).AND.
     &      LIVBOR(IPTFR).EQ.MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(J,3).AND.
     &      LITBOR(IPTFR).EQ.MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(J,4))
     &        THEN
                FAM_NUM(IPTFR) = J + OFFSET
                EXIT
              ENDIF
            ENDDO
            IF(FAM_NUM(IPTFR).EQ.0) THEN
              IERR = HERMES_UNKNOWN_BND_CONDITION
              CALL CHECK_CALL(IERR,'SET_BND')
            ENDIF
          ENDDO
!
!         WRITE FAMILY NUMBER IN THE MED FILE
          CALL MMHFNW(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &                TYPE_BND_ELEM_MED,NPTFR,FAM_NUM,IERR)
          DEALLOCATE(FAM_NUM)
        ENDIF
!
      ENDIF

!     WRITING THE BOUNDARY FILE
      WRITE(NCLI,*) MED_OBJ_TAB(MED_ID)%NBND_GRP
      DO I=1,MED_OBJ_TAB(MED_ID)%NBND_GRP
        WRITE(NCLI,*)
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(I,1),
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(I,2),
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(I,3),
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_VAL(I,4),
     &               MED_OBJ_TAB(MED_ID)%BND_GRP_NAME(I)
      ENDDO

#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      END SUBROUTINE
!
!
!-----------------------------------------------------------------------
!
      SUBROUTINE UPDATE_DATA_MESH_MED (FILE_ID,TIME,RECORD,NB_DIM_MESH,
     &                                 NPOIN,COORD,IERR)
!
!BRIEF    UPDATE MESH COORDINATES
!         ONLY FOR MOVING MESH
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_ID        |-->| MED FILE DESCRIPTOR
!| TIME           |-->| PHYSICAL TIME
!| RECORD         |-->| ITERATION NUMBER
!| NB_DIM_MESH    |-->| DIMENSION OF THE MESH
!| NPOIN          |-->| NUMBER OF POINTS IN THE MESH
!| COORD          |-->| COORDINATES TABLE
!| IERR           |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN)          :: FILE_ID
      INTEGER, INTENT(IN)          :: RECORD
      DOUBLE PRECISION, INTENT(IN) :: TIME
      INTEGER, INTENT(IN)          :: NB_DIM_MESH, NPOIN
      DOUBLE PRECISION, INTENT(IN) :: COORD(NB_DIM_MESH*NPOIN)
      INTEGER, INTENT(OUT)         :: IERR
!
#if defined (HAVE_MED)
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME
      INTEGER :: MED_ID
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!
!     UPDATE MESH COORDINATES IF NECESSARY
      CALL MMHCOW(FILE_ID,MNAME,RECORD,MED_NO_IT,TIME,
     &            MED_NO_INTERLACE,NPOIN,COORD,IERR)
      CALL CHECK_CALL(IERR,'UPDATE_DATA_MESH_MED:MMHCOW')
!
#else
!
!     MED LIBRARY NOT LOADED
      IERR = HERMES_MED_NOT_LOADED_ERR
!
#endif
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE IFVECTOR_(STRING,COMP_NUM,ISVECTOR)
!
!BRIEF    FIND ' U ' ' V ' ' W ' ' X ' ' Y ' ' Z ' IN NAME FIELD OF SCALAR
!         OR VECTOR
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| STRING         |<->| THE NAME OF THE VARIABLE TO TEST
!| COMP_NUM       |<--| DIRECTION OF VECTOR
!| ISVECTOR       |<--| TRUE IF VECTOR
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      CHARACTER(LEN=32), INTENT(INOUT) :: STRING
      INTEGER, INTENT(INOUT)             :: COMP_NUM
      LOGICAL, INTENT(INOUT)             :: ISVECTOR
!
      INTEGER :: J
!
!-----------------------------------------------------------------------
!
      ISVECTOR = .FALSE.
      COMP_NUM = 0
      RETURN

      IF (STRING(1:6)/='COTE Z') THEN
      DO J = 2,31
        IF (STRING(J-1:J+1) .EQ. ' U ') THEN
          STRING(J:J) = '*'
          COMP_NUM = 1
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. ' V ') THEN
          STRING(J:J) = '*'
          COMP_NUM = 2
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. ' W ') THEN
          STRING(J:J) = '*'
          COMP_NUM = 3
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. ' X ') THEN
          STRING(J:J) = '*'
          COMP_NUM = 1
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. ' Y ') THEN
          STRING(J:J) = '*'
          COMP_NUM = 2
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. ' Z ') THEN
          STRING(J:J) = '*'
          COMP_NUM = 3
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. 'QX ') THEN
          STRING(J-1:J) = 'Q*'
          COMP_NUM = 1
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. 'QY ') THEN
          STRING(J-1:J) = 'Q*'
          COMP_NUM = 2
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. 'QZ ') THEN
          STRING(J-1:J) = 'Q*'
          COMP_NUM = 3
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. 'U0 ') THEN
          STRING(J-1:J) = '*0'
          COMP_NUM = 1
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. 'V0 ') THEN
          STRING(J-1:J) = '*0'
          COMP_NUM = 2
          ISVECTOR = .TRUE.
        ELSEIF (STRING(J-1:J+1) .EQ. 'W0 ') THEN
          STRING(J-1:J) = '*0'
          COMP_NUM = 3
          ISVECTOR = .TRUE.
        ENDIF
      ENDDO
      ENDIF
!
      RETURN
      END SUBROUTINE IFVECTOR_
!
!-----------------------------------------------------------------------
!
      SUBROUTINE CONVERT_ELEM_TYPE(TYPE_ELEM,TYPE_ELEM_MED,IERR)
!
!BRIEF    CONVERTS ELEMENT TYPE FROM SLF FORMAT TO MED
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| TYPE_ELEM         |<--| ELEMENT TYPE WITH SLF FORMAT
!| TYPE_ELEM_MED     |-->| ELEMENT TYPE WITH MED FORMAT
!| IERR              |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      INTEGER, INTENT(IN)  :: TYPE_ELEM
      INTEGER, INTENT(INOUT) :: TYPE_ELEM_MED
      INTEGER, INTENT(OUT) :: IERR
!
!-----------------------------------------------------------------------
!
#if defined HAVE_MED
!     INITIALISATION
      IERR = 0
!
!     CONVERSION FROM BIEF NUMBERING TO MED
      SELECT CASE(TYPE_ELEM)
!
!       1 NODES OR 1 SEGMENT WITH 1 NODES
        CASE(POINT_BND_ELT_TYPE)
          TYPE_ELEM_MED = MED_POINT1
!
!       SEGMENT WITH 2 NODES
        CASE(EDGE_BND_ELT_TYPE)
          TYPE_ELEM_MED = MED_SEG2
!
!       TRIANGLE WITH 3 NODES
        CASE(TRIANGLE_ELT_TYPE, TRIANGLE_BND_ELT_TYPE,
     &       TRIANGLE_3D_BND_ELT_TYPE)
          TYPE_ELEM_MED = MED_TRIA3
!
!       QUADRANGLE WITH 4 NODES
        CASE(QUADRANGLE_ELT_TYPE, QUADRANGLE_BND_ELT_TYPE)
          TYPE_ELEM_MED = MED_QUAD4
!
!       TETRAHEDRA WITH 4 NODES
        CASE(TETRAHEDRON_ELT_TYPE)
          TYPE_ELEM_MED = MED_TETRA4
!
!       PRISM WITH 6 NODES
        CASE(PRISM_ELT_TYPE, SPLIT_PRISM_ELT_TYPE)
          TYPE_ELEM_MED = MED_PENTA6
!
!       ERROR CASE
        CASE DEFAULT
          IERR = HERMES_UNKNOWN_ELEMENT_TYPE_ERR
!
      END SELECT
#endif
!
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE NDP_FROM_ELEMENT_TYPE_MED(TYPE_ELEM_MED,NDP,IERR)
!
!brief    DEDUCES NUMBER OF NODES FROM ELEMENT TYPE IN MED NUMBERING
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| TYPE_ELEM_MED     |-->| ELEMENT TYPE WITH MED NUMBERING
!| NDP               |-->| NUMBER OF NODES PER ELEMENT
!| IERR              |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      INTEGER, INTENT(IN)  :: TYPE_ELEM_MED
      INTEGER, INTENT(INOUT) :: NDP
      INTEGER, INTENT(OUT) :: IERR
!
!-----------------------------------------------------------------------
!
!     INITIALISATION
      IERR = 0
      NDP  = -99
#if defined HAVE_MED
!
!     CONVERSION FROM BIEF NUMBERING TO MED
!
!     1D ELEMENTS
      IF (TYPE_ELEM_MED .EQ. MED_POINT1) NDP = 1 ! SEGM WITH 1 NODES
      IF (TYPE_ELEM_MED .EQ. MED_SEG2)   NDP = 2 ! SEGM WITH 2 NODES
!
!     2D ELEMENTS
      IF (TYPE_ELEM_MED .EQ. MED_TRIA3)  NDP = 3 ! TRIA WITH 3 NODES
      IF (TYPE_ELEM_MED .EQ. MED_QUAD4)  NDP = 4 ! QUAD WITH 4 NODES
!
!     3D ELEMENTS
      IF (TYPE_ELEM_MED .EQ. MED_TETRA4) NDP = 4 ! TETRA WITH 4 NODES
      IF (TYPE_ELEM_MED .EQ. MED_PENTA6) NDP = 6 ! PRISM WITH 6 NODES
!
!     ERROR IF UNKNOWN ELEMNT TYPE
      IF (NDP .EQ. -99) IERR = HERMES_UNKNOWN_ELEMENT_TYPE_ERR
!
#endif
      RETURN
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      SUBROUTINE IDENTIFY_BND_ELMT(FILE_ID,TYPE_BND_ELEM,IERR)
!
!brief    DEDUCES NUMBER OF NODES FROM ELEMENT TYPE IN MED NUMBERING
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| TYPE_BND_ELEM     |-->| ELEMENT TYPE WITH BIEF NUMBERING
!| FILE_ID           |-->| ID OF THE MED FILE
!| IERR              |-->| ERROR TAG
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      INTEGER, INTENT(IN)  :: FILE_ID
      INTEGER, INTENT(IN)  :: TYPE_BND_ELEM
      INTEGER, INTENT(OUT) :: IERR
!
!-----------------------------------------------------------------------
!
#if defined HAVE_MED
      CHARACTER(LEN=MED_NAME_SIZE) :: MNAME, TEMP_FAM
      CHARACTER(LEN=MED_LNAME_SIZE),ALLOCATABLE :: GRP_NAME(:)
      INTEGER ::  INUM,IFAM,I,MED_ID,TYPE_ELEM_MED
      INTEGER :: J
      INTEGER :: NELEM,NB_FAMILY,NB_GRP
      INTEGER, ALLOCATABLE :: NUM_FAMILY(:)
      LOGICAL :: FOUND
!
!-----------------------------------------------------------------------
!
!     GET INFO FROM THE MED FILE OBJECT
      CALL GET_OBJ(HASH,FILE_ID,MED_ID,IERR)
      CALL CHECK_CALL(IERR,'IDENTIFY_BND_ELMT:GET_OBJ_FILE')
      MNAME = MED_OBJ_TAB(MED_ID)%MESH_NAME
!     Only computing the array if it was not done before
      IF(.NOT.ALLOCATED(MED_OBJ_TAB(MED_ID)%IS_BND)) THEN
!       CONVERTS TYPE OF ELEMENTS
        CALL CONVERT_ELEM_TYPE(TYPE_BND_ELEM, TYPE_ELEM_MED, IERR)
        CALL CHECK_CALL(IERR,'IDENTIFY_BND_ELMT:CONVERT_ELEM_TYPE')
!
        CALL GET_MESH_NELEM_MED(FILE_ID,TYPE_BND_ELEM,NELEM,IERR)
        CALL CHECK_CALL(IERR,'IDENTIFY_BND_ELMT:GET_BND_NELEM_MED')
        ! In case we do not have boundary element in the mesh
        ALLOCATE(MED_OBJ_TAB(MED_ID)%IS_BND(MAX(NELEM,1)),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'IDENTIFY_BND_ELMT:is_bnd')

        IF(NELEM.NE.0) THEN
!
!         READ THE FAMILY NUMBER FOR EACH ELEMENT
          MED_OBJ_TAB(MED_ID)%NO_BND = .FALSE.
          ALLOCATE(NUM_FAMILY(NELEM),STAT=IERR)
          CALL CHECK_ALLOCATE(IERR,'IDENTIFY_BND_ELMT:num_family')
!
          CALL MMHFNR(FILE_ID,MNAME,MED_NO_DT,MED_NO_IT,MED_CELL,
     &                TYPE_ELEM_MED,NUM_FAMILY,IERR)
          CALL CHECK_CALL(IERR,'IDENTIFY_BND_ELMT:MMHFNR')
        ELSE
          MED_OBJ_TAB(MED_ID)%NO_BND = .TRUE.
          MED_OBJ_TAB(MED_ID)%IS_BND(:) = .FALSE.
          RETURN
        ENDIF
!
!       READ THE TOTAL NUMBER OF FAMILY
        CALL MFANFA(FILE_ID,MNAME,NB_FAMILY,IERR)
        CALL CHECK_CALL(IERR,'IDENTIFY_BND_ELMT:MFANFA')
        ALLOCATE(MED_OBJ_TAB(MED_ID)%BND_FAM(NB_FAMILY,2),STAT=IERR)
        CALL CHECK_ALLOCATE(IERR,'BND_FAM')
!
        DO IFAM = 1, NB_FAMILY
!
!         READ THE NUMBER OF GROUP PER FAMILY
          CALL MFANFG(FILE_ID,MNAME,IFAM,NB_GRP,IERR)
          CALL CHECK_CALL(IERR,'IDENTIFY_BND_ELMT:MFANFG')
!
          ALLOCATE(GRP_NAME(MAX(NB_GRP,1)),STAT=IERR)
          CALL CHECK_ALLOCATE(IERR,'IDENTIFY_BND_ELMT:GRP_NAME')

!         READ THE TYPE OF FAMILY
          CALL MFAFAI(FILE_ID,MNAME,IFAM,TEMP_FAM,INUM,GRP_NAME,IERR)
          CALL CHECK_CALL(IERR,'IDENTIFY_BND_ELMT:MFAFAI')
          MED_OBJ_TAB(MED_ID)%BND_FAM(IFAM,1) = INUM
          MED_OBJ_TAB(MED_ID)%BND_FAM(IFAM,2) = 0
          IF(TYPE_BND_ELEM.EQ.POINT_BND_ELT_TYPE) THEN
            ! Only check for families on points i.e. num > 0
            IF(INUM.LE.0) THEN
              DEALLOCATE(GRP_NAME)
              CYCLE
            ENDIF
          ELSE
            ! Only check for families on elements i.e. num < 0
            IF(INUM.GE.0) THEN
              DEALLOCATE(GRP_NAME)
              CYCLE
            ENDIF
          ENDIF
          FOUND = .FALSE.
          DO J=1,MED_OBJ_TAB(MED_ID)%NBND_GRP
            IF(FOUND) EXIT
            ! looping on the family groups and if one is in bnd_grp
            ! adding it to bnd_fam
            IF(NB_GRP.EQ.0) EXIT
            DO I=1,NB_GRP
              IF(GRP_NAME(I).EQ.
     &           MED_OBJ_TAB(MED_ID)%BND_GRP_NAME(J)) THEN
                FOUND = .TRUE.
                MED_OBJ_TAB(MED_ID)%BND_FAM(IFAM,2) = J
                EXIT
              ENDIF
            ENDDO
          ENDDO
          DEALLOCATE(GRP_NAME)
        ENDDO
        IF(NELEM.NE.0) THEN
          ! Looping on all element and checking if their family is in bnd_fam
          DO I=1,NELEM
            MED_OBJ_TAB(MED_ID)%IS_BND(I) = .FALSE.
            DO IFAM=1,NB_FAMILY
              IF(NUM_FAMILY(I).EQ.
     &           MED_OBJ_TAB(MED_ID)%BND_FAM(IFAM,1)) THEN
                MED_OBJ_TAB(MED_ID)%IS_BND(I) =
     &                MED_OBJ_TAB(MED_ID)%BND_FAM(IFAM,2).NE.0
                EXIT
              ENDIF
            ENDDO
          ENDDO
          DEALLOCATE(NUM_FAMILY)
        ENDIF
      ENDIF
!
#endif
      RETURN
      END SUBROUTINE

      SUBROUTINE SEG2POINT(P1,P2,BND_TYP_P1,BND_TYP_P2,POINT)
      IMPLICIT NONE
      INTEGER, INTENT(IN) :: P1,P2
      INTEGER, INTENT(IN) :: BND_TYP_P1
      INTEGER, INTENT(IN) :: BND_TYP_P2
      INTEGER, INTENT(OUT):: POINT

      IF (BND_TYP_P1.EQ.SOL_BND.AND.
     &    BND_TYP_P2.EQ.SOL_BND) THEN
        POINT = P1
      ELSE IF(BND_TYP_P1.EQ.SOL_BND) THEN
        POINT = P2
      ELSE IF(BND_TYP_P2.EQ.SOL_BND) THEN
        POINT = P1
      ELSE
        IF(BND_TYP_P1.LT.BND_TYP_P2) THEN
          POINT = P1
        ELSE
          POINT = P2
        ENDIF
      ENDIF
      END SUBROUTINE

      SUBROUTINE POINT2SEG(P1,P2,BND_TYP_P1,BND_TYP_P2,SEG)
      IMPLICIT NONE
      INTEGER, INTENT(IN) :: P1,P2
      INTEGER, INTENT(IN) :: BND_TYP_P1
      INTEGER, INTENT(IN) :: BND_TYP_P2
      INTEGER, INTENT(OUT):: SEG

      IF(BND_TYP_P1.NE.SOL_BND .AND.
     &   BND_TYP_P2.NE.SOL_BND) THEN
        IF(BND_TYP_P1.LT.BND_TYP_P2) THEN
          SEG = P1
        ELSE
          SEG = P2
        ENDIF
      ELSE IF (BND_TYP_P1.EQ.SOL_BND) THEN
        SEG = P1
      ELSE
        SEG = P2
      ENDIF
      END SUBROUTINE
!
!-----------------------------------------------------------------------
!
      END MODULE UTILS_MED

