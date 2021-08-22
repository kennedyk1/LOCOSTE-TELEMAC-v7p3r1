!                    *****************
                     SUBROUTINE DIRI09
!                    *****************
!
     &(X1,X2,X3,
     & A11,A12,A13,A21,A22,A23,A31,A32,A33,
     & SM1,SM2,SM3,T1,T2,T3,T4,T5,T6,
     & XBOR1,XBOR2,XBOR3,LIDIR1,LIDIR2,LIDIR3,
     & MESH,KDIR,MSK,MASKPT)
!
!***********************************************************************
! BIEF   V6P1                                   21/08/2010
!***********************************************************************
!
!brief    TREATS THE DIRICHLET POINTS FOR THE FOLLOWING
!+                SYSTEM (BLOCK OF 9 MATRICES):
!code
!+         (     A11          A12         A13  )  ( X1 )   ( SM1 )
!+         (                                   )  (    )   (     )
!+         (    T                              )  (    )   (     )
!+         (     A21          A22         A23  )  ( X2 ) = ( SM2 )
!+         (                                   )  (    )   (     )
!+         (    T            T                 )  (    )   (     )
!+         (     A31          A32         A33  )  ( X3 )   ( SM3 )
!
!note     TRANSPOSING A21 A31 AND A32 MAKES IT POSSIBLE TO USE ONLY
!+         ONE CALL FOR A12 AND A21, A31 AND A13, A32 AND A23 WHEN
!+         THE BLOCK IS SYMMETRICAL.
!
!history  J-M HERVOUET (LNH)
!+        30/01/95
!+        V5P1
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
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| A12            |<->| MATRIX IN THE 3x3 LINEAR SYSTEM
!| A13            |<->| MATRIX IN THE 3x3 LINEAR SYSTEM
!| A21            |<->| MATRIX IN THE 3x3 LINEAR SYSTEM
!| A22            |<->| MATRIX IN THE 3x3 LINEAR SYSTEM
!| A23            |<->| MATRIX IN THE 3x3 LINEAR SYSTEM
!| A31            |<->| MATRIX IN THE 3x3 LINEAR SYSTEM
!| A32            |<->| MATRIX IN THE 3x3 LINEAR SYSTEM
!| A33            |<->| MATRIX IN THE 3x3 LINEAR SYSTEM
!| KDIR           |-->| CONVENTION FOR DIRICHLET BOUNDARY CONDITIONS
!| LIDIR1         |-->| TYPES OF BOUNDARY CONDITIONS FOR VARIABLE 1
!|                |   | IF LIMDIR(K) = KDIR LE KTH BOUNDARY POINT
!|                |   | IS OF DIRICHLET TYPE.
!| LIDIR2         |-->| TYPES OF BOUNDARY CONDITIONS FOR VARIABLE 2
!|                |   | IF LIMDIR(K) = KDIR THE KTH BOUNDARY POINT
!|                |   | IS OF DIRICHLET TYPE.
!| LIDIR2         |-->| TYPES OF BOUNDARY CONDITIONS FOR VARIABLE 2
!|                |   | IF LIMDIR(K) = KDIR THE KTH BOUNDARY POINT
!|                |   | IS OF DIRICHLET TYPE.
!| LIDIR3         |-->| TYPES OF BOUNDARY CONDITIONS FOR VARIABLE 3
!|                |   | IF LIMDIR(K) = KDIR THE KTH BOUNDARY POINT
!|                |   | IS OF DIRICHLET TYPE.
!| MASKPT         |-->| MASKING PER POINT.
!|                |   | =1. : NORMAL   =0. : MASKED
!| MESH           |-->| MESH STRUCTURE
!| MSK            |-->| IF YES, THERE IS MASKED ELEMENTS.
!| SM1            |-->| FIRST RIGHT-HAND SIDE OF THE SYSTEM.
!| SM2            |-->| SECOND RIGHT-HAND SIDE OF THE SYSTEM.
!| SM3            |-->| THIRD RIGHT-HAND SIDE OF THE SYSTEM.
!| T1             |<->| WORK DOUBLE PRECISION ARRAY IN A BIEF_OBJ
!| T2             |<->| WORK DOUBLE PRECISION ARRAY IN A BIEF_OBJ
!| T3             |<->| WORK DOUBLE PRECISION ARRAY IN A BIEF_OBJ
!| T4             |<->| WORK DOUBLE PRECISION ARRAY IN A BIEF_OBJ
!| T5             |<->| WORK DOUBLE PRECISION ARRAY IN A BIEF_OBJ
!| T6             |<->| WORK DOUBLE PRECISION ARRAY IN A BIEF_OBJ
!| XBOR1          |-->| DIRICHLET BOUNDARY CONDITIONS OF VARIABLE 1
!| XBOR2          |-->| DIRICHLET BOUNDARY CONDITIONS OF VARIABLE 2
!| XBOR3          |-->| DIRICHLET BOUNDARY CONDITIONS OF VARIABLE 3
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF, EX_DIRI09 => DIRI09
!
      USE DECLARATIONS_SPECIAL
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      TYPE(BIEF_OBJ), INTENT(INOUT) :: X1,X2,X3,SM1,SM2,SM3
      TYPE(BIEF_OBJ), INTENT(INOUT) :: T1,T2,T3,T4,T5,T6
      TYPE(BIEF_OBJ), INTENT(INOUT) :: A11,A12,A13,A21,A22
      TYPE(BIEF_OBJ), INTENT(INOUT) :: A23,A31,A32,A33
      TYPE(BIEF_OBJ), INTENT(IN)    :: XBOR1,XBOR2,XBOR3,MASKPT
      INTEGER, INTENT(IN)           :: LIDIR1(*),LIDIR2(*),LIDIR3(*)
      INTEGER, INTENT(IN)           :: KDIR
      TYPE(BIEF_MESH), INTENT(INOUT):: MESH
      LOGICAL, INTENT(IN)           :: MSK
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      DOUBLE PRECISION C,Z(1)
!
      CHARACTER(LEN=1) STODIA
!
!-----------------------------------------------------------------------
!
! 1) BUILDS ARRAYS T1,T2,T3 CONTAINING:
!    THE X1, X2 AND X3 IMPOSED VALUES IF THE POINT IS OF TYPE DIRICHLET
!    0 OTHERWISE
!
!    X1,X2,X3 TAKE THEIR DIRICHLET VALUE
!
!=======================================================================
!
!   BOUNDARY CONDITION FOR X1 : "XBOR1" IMPOSED
!
      CALL CPSTVC(X1,T1)
      CALL OS  ( 'X=C     ' , T1 , T1 , T1 , 0.D0 )
      CALL OSDBIF ( 'X=Y     ',T1,XBOR1,LIDIR1,KDIR,MESH)
!
!-----------------------------------------------------------------------
!
!   BOUNDARY CONDITION FOR X2 : "XBOR2" IMPOSED
!
      CALL CPSTVC(X2,T2)
      CALL OS  ( 'X=C     ' , T2 , T2 , T2 , 0.D0 )
      CALL OSDBIF ( 'X=Y     ',T2,XBOR2,LIDIR2,KDIR,MESH)
!
!-----------------------------------------------------------------------
!
!   BOUNDARY CONDITION FOR X3 : "XBOR3" IMPOSED
!
      CALL CPSTVC(X3,T3)
      CALL OS  ( 'X=C     ' , T3 , T3 , T3 , 0.D0 )
      CALL OSDBIF ( 'X=Y     ',T3,XBOR3,LIDIR3,KDIR,MESH)
!
!=======================================================================
!
!   2) COMPUTES THE PRODUCT OF THE MATRIX FOR THE SYSTEM TO SOLVE
!      AND T1,T2,T3
!      THE RESULT IS DEDUCTED FROM THE SECOND MEMBERS
!
      CALL MATVEC('X=AY    ',T4,A11,T1,C,MESH,LEGO=.FALSE.)
      CALL MATVEC('X=X+AY  ',T4,A12,T2,C,MESH,LEGO=.FALSE.)
      CALL MATVEC('X=X+AY  ',T4,A13,T3,C,MESH,LEGO=.TRUE. )
      CALL MATVEC('X=AY    ',T5,A21,T1,C,MESH,LEGO=.FALSE.)
      CALL MATVEC('X=X+AY  ',T5,A22,T2,C,MESH,LEGO=.FALSE.)
      CALL MATVEC('X=X+AY  ',T5,A23,T3,C,MESH,LEGO=.TRUE. )
      CALL MATVEC('X=AY    ',T6,A31,T1,C,MESH,LEGO=.FALSE.)
      CALL MATVEC('X=X+AY  ',T6,A32,T2,C,MESH,LEGO=.FALSE.)
      CALL MATVEC('X=X+AY  ',T6,A33,T3,C,MESH,LEGO=.TRUE. )
!
      CALL CPSTVC(X1,SM1)
      CALL CPSTVC(X2,SM2)
      CALL CPSTVC(X3,SM3)
      CALL OS( 'X=X-Y   ' , SM1 , T4 , T4 , C )
      CALL OS( 'X=X-Y   ' , SM2 , T5 , T5 , C )
      CALL OS( 'X=X-Y   ' , SM3 , T6 , T6 , C )
!
!=======================================================================
!
!  SECOND MEMBERS OF THE EQUATIONS FOR DIRICHLET POINTS
!  PREPARES THE LINEAR SYSTEM
!
      CALL DIRAUX(SM1,A11%D,XBOR1,T1,X1,LIDIR1,KDIR,MESH)
      CALL DIRAUX(SM2,A22%D,XBOR2,T2,X2,LIDIR2,KDIR,MESH)
      CALL DIRAUX(SM3,A33%D,XBOR3,T3,X3,LIDIR3,KDIR,MESH)
!
! CALLS OV RATHER THAN OS BECAUSE SM1 AND MASKPT DON'T ALWAYS
! HAVE THE SAME LENGTH
!
      IF(MSK) THEN
        CALL OV( 'X=XY    ',SM1%R,MASKPT%R,Z,C,SM1%DIM1)
        CALL OV( 'X=XY    ', X1%R,MASKPT%R,Z,C,X1%DIM1)
        CALL OV( 'X=XY    ', T1%R,MASKPT%R,Z,C,T1%DIM1)
        CALL OV( 'X=XY    ',SM2%R,MASKPT%R,Z,C,SM2%DIM1)
        CALL OV( 'X=XY    ', X2%R,MASKPT%R,Z,C,X2%DIM1)
        CALL OV( 'X=XY    ', T2%R,MASKPT%R,Z,C,T2%DIM1)
        CALL OV( 'X=XY    ',SM3%R,MASKPT%R,Z,C,SM3%DIM1)
        CALL OV( 'X=XY    ', X3%R,MASKPT%R,Z,C,X3%DIM1)
        CALL OV( 'X=XY    ', T3%R,MASKPT%R,Z,C,T3%DIM1)
      ENDIF
!
!=======================================================================
!
!   ERASES THE LINES AND COLUMNS FOR DIRICHLET POINTS
!
!   IT'S EQUIVALENT TO A DIAGONAL PRECONDITIONING WITH ARRAYS
!   T1,T2,T3
!
!   DOES NOT ALTER A11,A22,A33 DIAGONALS
!   BY GIVING THEM A DUMMY TYPE : '0'
!
!
!=======================================================================
! A11 PRECONDITIONING :
!=======================================================================
!
      STODIA = A11%TYPDIA
      A11%TYPDIA='0'
      CALL OM( 'M=DMD   ' , A11,A11 ,T1,C,MESH)
      A11%TYPDIA=STODIA
!
!=======================================================================
! A12 PRECONDITIONING :
!=======================================================================
!
      CALL OM( 'M=DM    ' , A12,A12 ,T1,C,MESH)
      CALL OM( 'M=MD    ' , A12,A12 ,T2,C,MESH)
!
!=======================================================================
! A13 PRECONDITIONING :
!=======================================================================
!
      CALL OM( 'M=DM    ' , A13,A13 ,T1,C,MESH)
      CALL OM( 'M=MD    ' , A13,A13 ,T3,C,MESH)
!
!=======================================================================
! A21 PRECONDITIONING :
!=======================================================================
!
      CALL OM( 'M=DM    ' , A21,A21 ,T2,C,MESH)
      CALL OM( 'M=MD    ' , A21,A21 ,T1,C,MESH)
!
!=======================================================================
! A22 PRECONDITIONING :
!=======================================================================
!
      STODIA = A22%TYPDIA
      A22%TYPDIA='0'
      CALL OM( 'M=DMD   ' , A22,A22 ,T2,C,MESH)
      A22%TYPDIA=STODIA
!
!=======================================================================
! A23 PRECONDITIONING :
!=======================================================================
!
      CALL OM( 'M=DM    ' , A23,A23 ,T2,C,MESH)
      CALL OM( 'M=MD    ' , A23,A23 ,T3,C,MESH)
!
!=======================================================================
! A31 PRECONDITIONING :
!=======================================================================
!
      CALL OM( 'M=DM    ' , A31,A31 ,T3,C,MESH)
      CALL OM( 'M=MD    ' , A31,A31 ,T1,C,MESH)
!
!=======================================================================
! A32 PRECONDITIONING :
!=======================================================================
!
      CALL OM( 'M=DM    ' , A32,A32 ,T3,C,MESH)
      CALL OM( 'M=MD    ' , A32,A32 ,T2,C,MESH)
!
!=======================================================================
! A33 PRECONDITIONING :
!=======================================================================
!
      STODIA = A33%TYPDIA
      A33%TYPDIA='0'
      CALL OM( 'M=DMD   ' , A33,A33 ,T3,C,MESH)
      A33%TYPDIA=STODIA
!
!-----------------------------------------------------------------------
!
      RETURN
      END
