!                    ***********************
                     SUBROUTINE POINT_RICE2D
!                    ***********************
!
     &( MESH,IELM1 )
!
!***********************************************************************
! RICE2D   V7P3
!***********************************************************************
!
!brief    Memory allocation of structures, aliases, blocks...
!
!history  F. HUANG (CLARKSON U.) AND S.E. BOURBAN (HRW)
!+        11/11/2016
!+        V7P3
!+        Coupling TELEMAC-2D with RICE-2D (ice modelling component)
!+        Initial developments
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_SPECIAL
      USE DECLARATIONS_RICE2D
!      USE DECLARATIONS_WAQTEL, ONLY: TDEW,VISBI
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER,         INTENT(IN) :: IELM1
      TYPE(BIEF_MESH), INTENT(IN) :: MESH
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
!     RICE-2D DEPENDENCIES:
!     - WATER TEMPERATURE TAKEN FROM TELEMAC-2D
!     - AIR TEMPERATURE TAKEN FROM WAQTEL
!     - WIND TAKEN FROM TELEMAC-2D
!
!      CALL BIEF_ALLVEC(1,ANFEM, 'ANFEM ',IELM1,1,1,MESH)
!
!      CALL BIEF_ALLVEC(1,SUMPH, 'SUMPH ',IELM1,1,1,MESH)
      CALL BIEF_ALLVEC(1,PHCL,  'PHCL  ',IELM1,1,1,MESH)
      CALL BIEF_ALLVEC(1,PHRI,  'PHRI  ',IELM1,1,1,MESH)
      CALL BIEF_ALLVEC(1,PHPS,  'PHPS  ',IELM1,1,1,MESH)
      CALL BIEF_ALLVEC(1,PHIB,  'PHIB  ',IELM1,1,1,MESH)
      CALL BIEF_ALLVEC(1,PHIE,  'PHIE  ',IELM1,1,1,MESH)
      CALL BIEF_ALLVEC(1,PHIH,  'PHIH  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,PHIP,  'PHIP  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,PHIWI,  'PHIWI ',IELM1,1,1,MESH)
!
!      CALL BIEF_ALLVEC(1,TDEW,  'TDEW  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,VISBI,  'VISBI ',IELM1,1,1,MESH)
!
!      CALL BIEF_ALLVEC(1,CV_F,  'CV_F  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,TW,  'TW    ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,HTW,  'HTW   ',IELM1,1,1,MESH)
!
!      CALL BIEF_ALLVEC(1,THETA0, 'THETA0',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,THETA1, 'THETA1',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,GAMC  , 'GAMC  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,GAMA  , 'GAMA  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,BETA1 , 'BETA1 ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,VBB   ,'VBB   ',IELM1,1,1,MESH)
!
!      CALL BIEF_ALLVEC(1,ZWI   ,'ZWI   ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,THIFEM,'THIFEM',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,THIFEMF,'THIFEMF',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,DTHIFEM,'DTHIFE',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,UICE  ,'UICE  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,VICE  ,'VICE  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,ZICE  ,'ZICE  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,ZWAT  ,'ZWAT  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,UQX   ,'UQX   ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,UQY   ,'UQY   ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,QX    ,'QX    ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,QY    ,'QX    ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,HBED  ,'HBED  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,HICE  ,'HICE  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,ETA   ,'ETA   ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,ETAB  ,'ETAB  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,DETAX ,'DETAX ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,DETAY ,'DETAY ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,TMICE ,'TMICE ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,CNIEND,'CNIEND',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,THIFEMS ,'THIFEMS',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,THIFEMF ,'THIFEMF',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,TISFEM,'TISFEM',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,THUN,'THUN  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,HUN,'HUN   ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,TIWX,'TIWX  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(1,TIWY,'TIWY  ',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(2,JAMFEM,'JAMFEM',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(2,ISBORDER,'ISBORDER',IELM1,1,1,MESH)
!      CALL BIEF_ALLVEC(2,ICEREGION,'ICEREGION',IELM1,1,1,MESH)
!
!
!      CNI = 0.02 ! ice roughness
!      CNISLD = 0.02 ! ice island roughness
!      CNIMAX = 0.06 ! max ice roughness
!      THI0 = 0.2  ! single layer ice thickness
!      ANMAX = 0.6 ! max ice concentration
!      DARCYILD = 0.0
!      DARCYRUB = 0.0

!     ice parcels
!
!      CALL BIEF_ALLVEC(1,upx,      'upx   ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,upy,      'upy   ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,xp,       'xp    ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,yp,       'yp    ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,strfx,    'strfx ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,strfy,    'strfy ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(2,nparel,   'nparel',0,2,0,MESH)
!      CALL BIEF_ALLVEC(2,idv,      'idv   ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(2,idelta,   'idelta',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,dudxt,    'dudxt ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,dvdyt,    'dvdyt ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,dudydvdxt,'duvdyx',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,sigxx,    'sigxx ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,sigyy,    'sigyy ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,sigxy,    'sigxy ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,tisp,     'tisp  ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,tipp,     'tipp  ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,ep,       'ep    ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,thips,    'thips ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,thipf,    'thipf ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,areap,    'areap ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,um,       'um    ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,pms,      'pms   ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,pmf,      'pmf   ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,pm,       'pm    ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,thi0p,    'thi0p ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(2,iceOrgP,  'iceOrg',0,2,0,MESH)
!      CALL BIEF_ALLVEC(2,iceTypeP, 'iceTyp',0,2,0,MESH)
!      CALL BIEF_ALLVEC(2,nparelm,  'nparel',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,upx0,     'upx0  ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,upy0,     'upy0  ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,xp0,      'xp0   ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,yp0,      'yp0   ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,hpi0p,    'hpi0p ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,umi0p,    'umi0p ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,HydroPr,  'HydrPr',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,nsort,    'nsort ',0,2,0,MESH)
!      CALL BIEF_ALLVEC(1,KSTRSTATE,'KSTRST',0,2,0,MESH)
!
!-----------------------------------------------------------------------
!
      RETURN
      END
