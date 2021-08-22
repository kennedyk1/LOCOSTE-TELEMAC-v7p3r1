!                    *******************
                     SUBROUTINE MV0404_2
!                    *******************
!
     &(OP, X , DA,TYPDIA,XA,TYPEXT, Y,C,IKLE1,IKLE2,IKLE3,IKLE4,
     & NPOIN,NELEM,W1,W2,W3,W4,DIM1XA)
!
!***********************************************************************
! BIEF   V7P2
!***********************************************************************
!
!brief    MATRIX VECTOR OPERATIONS FOR Q1 QUADRILATERALS.
!
!warning  This is inspired from MV0404, but the dimensions of XA are
!         swapped.
!
!code
!+   OP IS A STRING OF 8 CHARACTERS, WHICH INDICATES THE OPERATION TO BE
!+   PERFORMED ON VECTORS X,Y AND MATRIX M.
!+
!+   THE RESULT IS VECTOR X.
!+
!+   THESE OPERATIONS ARE DIFFERENT DEPENDING ON THE DIAGONAL TYPE
!+   AND THE TYPE OF EXTRADIAGONAL TERMS.
!+
!+   IMPLEMENTED OPERATIONS:
!+
!+      OP = 'X=AY    '  : X = AY
!+      OP = 'X=CAY   '  : X = CAY
!+      OP = 'X=-AY   '  : X = - AY
!+      OP = 'X=X+AY  '  : X = X + AY
!+      OP = 'X=X-AY  '  : X = X - AY
!+      OP = 'X=X+CAY '  : X = X + C AY
!+      OP = 'X=TAY   '  : X = TA Y (TRANSPOSE OF A)
!+      OP = 'X=-TAY  '  : X = - TA Y (- TRANSPOSE OF A)
!+      OP = 'X=X+TAY '  : X = X + TA Y
!+      OP = 'X=X-TAY '  : X = X - TA Y
!+      OP = 'X=X+CTAY'  : X = X + C TA Y
!
!history  J-M HERVOUET (EDF LAB, LNHE)
!+        22/03/2016
!+        V7P2
!+   First version.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| C              |-->| A GIVEN CONSTANT
!| DA             |-->| MATRIX DIAGONAL
!| IKLE1          |-->| FIRST POINTS OF ELEMENTS
!| IKLE2          |-->| SECOND POINTS OF ELEMENTS
!| IKLE3          |-->| THIRD POINTS OF ELEMENTS
!| IKLE4          |-->| FOURTH POINTS OF ELEMENTS
!| NELEM          |-->| NUMBER OF ELEMENTS
!| NPOIN          |-->| NUMBER OF LINEAR POINTS
!| OP             |-->| OPERATION TO BE DONE (SEE ABOVE)
!| TYPDIA         |-->| TYPE OF DIAGONAL:
!|                |   | TYPDIA = 'Q' : ANY VALUE
!|                |   | TYPDIA = 'I' : IDENTITY
!|                |   | TYPDIA = '0' : ZERO
!| TYPEXT         |-->| TYPE OF OFF-DIAGONAL TERMS
!|                |   | TYPEXT = 'Q' : ANY VALUE
!|                |   | TYPEXT = 'S' : SYMMETRIC
!|                |   | TYPEXT = '0' : ZERO
!| W1             |<->| RESULT IN NON ASSEMBLED FORM
!| W2             |<->| RESULT IN NON ASSEMBLED FORM
!| W3             |<->| RESULT IN NON ASSEMBLED FORM
!| W4             |<->| RESULT IN NON ASSEMBLED FORM
!| X              |<->| RESULT IN ASSEMBLED FORM
!| XA13           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA14           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA21           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA23           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA24           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA31           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA32           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA34           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA41           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA42           |-->| OFF-DIAGONAL TERM OF MATRIX
!| XA43           |-->| OFF-DIAGONAL TERM OF MATRIX
!| Y              |-->| VECTOR USED IN THE OPERATION
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF, EX_MV0404_2 => MV0404_2
      USE DECLARATIONS_SPECIAL
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN) :: NELEM,NPOIN,DIM1XA
!
      INTEGER, INTENT(IN) :: IKLE1(*),IKLE2(*),IKLE3(*),IKLE4(*)
!
      DOUBLE PRECISION, INTENT(INOUT) :: W1(*),W2(*),W3(*),W4(*)
      DOUBLE PRECISION, INTENT(IN)    :: Y(*),DA(*)
      DOUBLE PRECISION, INTENT(INOUT) :: X(*)
      DOUBLE PRECISION, INTENT(IN)    :: XA(DIM1XA,*)
      DOUBLE PRECISION, INTENT(IN)    :: C
!
      CHARACTER(LEN=8), INTENT(IN) :: OP
      CHARACTER(LEN=1), INTENT(IN) :: TYPDIA,TYPEXT
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER IELEM
      DOUBLE PRECISION Z(1)
!
!-----------------------------------------------------------------------
!
      IF(OP(1:8).EQ.'X=AY    ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) =     XA(1,IELEM)  * Y(IKLE2(IELEM))
     &                    + XA(2,IELEM)  * Y(IKLE3(IELEM))
     &                    + XA(3,IELEM)  * Y(IKLE4(IELEM))
            W2(IELEM) =     XA(7,IELEM)  * Y(IKLE1(IELEM))
     &                    + XA(4,IELEM)  * Y(IKLE3(IELEM))
     &                    + XA(5,IELEM)  * Y(IKLE4(IELEM))
            W3(IELEM) =     XA(8,IELEM)  * Y(IKLE1(IELEM))
     &                    + XA(10,IELEM) * Y(IKLE2(IELEM))
     &                    + XA(6,IELEM)  * Y(IKLE4(IELEM))
            W4(IELEM) =     XA(9,IELEM)  * Y(IKLE1(IELEM))
     &                    + XA(11,IELEM) * Y(IKLE2(IELEM))
     &                    + XA(12,IELEM) * Y(IKLE3(IELEM))
          ENDDO
!
        ELSEIF(TYPEXT(1:1).EQ.'0') THEN
!
          CALL OV ('X=C     ', W1 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W2 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W3 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W4 , Y , Z , 0.D0 , NELEM )
!
        ELSE
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL:
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=YZ    ', X , Y , DA , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=Y     ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'0') THEN
          CALL OV ('X=C     ', X , Y , Z  , 0.D0 , NPOIN )
        ELSE
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=CAY   ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) =  C * (   XA(1,IELEM)  * Y(IKLE2(IELEM))
     &                         + XA(2,IELEM)  * Y(IKLE3(IELEM))
     &                         + XA(3,IELEM)  * Y(IKLE4(IELEM)) )
            W2(IELEM) =  C * (   XA(7,IELEM)  * Y(IKLE1(IELEM))
     &                         + XA(4,IELEM)  * Y(IKLE3(IELEM))
     &                         + XA(5,IELEM)  * Y(IKLE4(IELEM)) )
            W3(IELEM) =  C * (   XA(8,IELEM)  * Y(IKLE1(IELEM))
     &                         + XA(10,IELEM) * Y(IKLE2(IELEM))
     &                         + XA(6,IELEM)  * Y(IKLE4(IELEM)) )
            W4(IELEM) =  C * (   XA(9,IELEM)  * Y(IKLE1(IELEM))
     &                         + XA(11,IELEM) * Y(IKLE2(IELEM))
     &                         + XA(12,IELEM) * Y(IKLE3(IELEM)) )
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).EQ.'0') THEN
!
          CALL OV ('X=C     ', W1 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W2 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W3 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W4 , Y , Z , 0.D0 , NELEM )
!
        ELSE
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL:
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=CYZ   ', X , Y , DA , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=CY    ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'0') THEN
          CALL OV ('X=C     ', X , Y , Z  , 0.D0 , NPOIN )
        ELSE
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=-AY   ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).NE.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) =   - XA(1,IELEM)  * Y(IKLE2(IELEM))
     &                    - XA(2,IELEM)  * Y(IKLE3(IELEM))
     &                    - XA(3,IELEM)  * Y(IKLE4(IELEM))
            W2(IELEM) =   - XA(7,IELEM)  * Y(IKLE1(IELEM))
     &                    - XA(4,IELEM)  * Y(IKLE3(IELEM))
     &                    - XA(5,IELEM)  * Y(IKLE4(IELEM))
            W3(IELEM) =   - XA(8,IELEM)  * Y(IKLE1(IELEM))
     &                    - XA(10,IELEM) * Y(IKLE2(IELEM))
     &                    - XA(6,IELEM)  * Y(IKLE4(IELEM))
            W4(IELEM) =   - XA(9,IELEM)  * Y(IKLE1(IELEM))
     &                    - XA(11,IELEM) * Y(IKLE2(IELEM))
     &                    - XA(12,IELEM) * Y(IKLE3(IELEM))
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).EQ.'0') THEN
!
          CALL OV ('X=C     ', W1 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W2 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W3 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W4 , Y , Z , 0.D0 , NELEM )
!
        ELSE
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL:
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=-YZ   ', X , Y , DA , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=-Y    ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'0') THEN
          CALL OV ('X=C     ', X , Y , Z  , 0.D0 , NPOIN )
        ELSE
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=X+AY  ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) = W1(IELEM) + XA(1,IELEM)  * Y(IKLE2(IELEM))
     &                            + XA(2,IELEM)  * Y(IKLE3(IELEM))
     &                            + XA(3,IELEM)  * Y(IKLE4(IELEM))
            W2(IELEM) = W2(IELEM) + XA(7,IELEM)  * Y(IKLE1(IELEM))
     &                            + XA(4,IELEM)  * Y(IKLE3(IELEM))
     &                            + XA(5,IELEM)  * Y(IKLE4(IELEM))
            W3(IELEM) = W3(IELEM) + XA(8,IELEM)  * Y(IKLE1(IELEM))
     &                            + XA(10,IELEM) * Y(IKLE2(IELEM))
     &                            + XA(6,IELEM)  * Y(IKLE4(IELEM))
            W4(IELEM) = W4(IELEM) + XA(9,IELEM)  * Y(IKLE1(IELEM))
     &                            + XA(11,IELEM) * Y(IKLE2(IELEM))
     &                            + XA(12,IELEM) * Y(IKLE3(IELEM))
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).NE.'0') THEN
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL:
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=X+YZ  ', X , Y , DA , C , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=X+Y   ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).NE.'0') THEN
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=X-AY  ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) = W1(IELEM) - XA(1,IELEM)  * Y(IKLE2(IELEM))
     &                            - XA(2,IELEM)  * Y(IKLE3(IELEM))
     &                            - XA(3,IELEM)  * Y(IKLE4(IELEM))
            W2(IELEM) = W2(IELEM) - XA(7,IELEM)  * Y(IKLE1(IELEM))
     &                            - XA(4,IELEM)  * Y(IKLE3(IELEM))
     &                            - XA(5,IELEM)  * Y(IKLE4(IELEM))
            W3(IELEM) = W3(IELEM) - XA(8,IELEM)  * Y(IKLE1(IELEM))
     &                            - XA(10,IELEM) * Y(IKLE2(IELEM))
     &                            - XA(6,IELEM)  * Y(IKLE4(IELEM))
            W4(IELEM) = W4(IELEM) - XA(9,IELEM)  * Y(IKLE1(IELEM))
     &                            - XA(11,IELEM) * Y(IKLE2(IELEM))
     &                            - XA(12,IELEM) * Y(IKLE3(IELEM))
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).NE.'0') THEN
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL:
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=X-YZ  ', X , Y , DA , C , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=X-Y   ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).NE.'0') THEN
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=X+CAY ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) = W1(IELEM)
     &              + C * (      XA(1,IELEM)  * Y(IKLE2(IELEM))
     &                         + XA(2,IELEM)  * Y(IKLE3(IELEM))
     &                         + XA(3,IELEM)  * Y(IKLE4(IELEM)) )
            W2(IELEM) = W2(IELEM)
     &              + C * (      XA(7,IELEM)  * Y(IKLE1(IELEM))
     &                         + XA(4,IELEM)  * Y(IKLE3(IELEM))
     &                         + XA(5,IELEM)  * Y(IKLE4(IELEM)) )
            W3(IELEM) = W3(IELEM)
     &              + C * (      XA(8,IELEM)  * Y(IKLE1(IELEM))
     &                         + XA(10,IELEM) * Y(IKLE2(IELEM))
     &                         + XA(6,IELEM)  * Y(IKLE4(IELEM)) )
            W4(IELEM) = W4(IELEM)
     &              + C * (      XA(9,IELEM)  * Y(IKLE1(IELEM))
     &                         + XA(11,IELEM) * Y(IKLE2(IELEM))
     &                         + XA(12,IELEM) * Y(IKLE3(IELEM)) )
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).NE.'0') THEN
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL:
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=X+CYZ  ', X , Y , DA , C , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=X+CY   ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).NE.'0') THEN
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=TAY   ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) =   + XA(7,IELEM)  * Y(IKLE2(IELEM))
     &                    + XA(8,IELEM)  * Y(IKLE3(IELEM))
     &                    + XA(9,IELEM)  * Y(IKLE4(IELEM))
            W2(IELEM) =   + XA(1,IELEM)  * Y(IKLE1(IELEM))
     &                    + XA(10,IELEM) * Y(IKLE3(IELEM))
     &                    + XA(11,IELEM) * Y(IKLE4(IELEM))
            W3(IELEM) =   + XA(2,IELEM)  * Y(IKLE1(IELEM))
     &                    + XA(4,IELEM)  * Y(IKLE2(IELEM))
     &                    + XA(12,IELEM) * Y(IKLE4(IELEM))
            W4(IELEM) =   + XA(3,IELEM)  * Y(IKLE1(IELEM))
     &                    + XA(5,IELEM)  * Y(IKLE2(IELEM))
     &                    + XA(6,IELEM)  * Y(IKLE3(IELEM))
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).EQ.'0') THEN
!
          CALL OV ('X=C     ', W1 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W2 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W3 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W4 , Y , Z , 0.D0 , NELEM )
!
        ELSE
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=YZ    ', X , Y , DA , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=Y     ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'0') THEN
          CALL OV ('X=C     ', X , Y , DA , 0.D0 , NPOIN )
        ELSE
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=-TAY  ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) =   - XA(7,IELEM)  * Y(IKLE2(IELEM))
     &                    - XA(8,IELEM)  * Y(IKLE3(IELEM))
     &                    - XA(9,IELEM)  * Y(IKLE4(IELEM))
            W2(IELEM) =   - XA(1,IELEM)  * Y(IKLE1(IELEM))
     &                    - XA(10,IELEM) * Y(IKLE3(IELEM))
     &                    - XA(11,IELEM) * Y(IKLE4(IELEM))
            W3(IELEM) =   - XA(2,IELEM)  * Y(IKLE1(IELEM))
     &                    - XA(4,IELEM)  * Y(IKLE2(IELEM))
     &                    - XA(12,IELEM) * Y(IKLE4(IELEM))
            W4(IELEM) =   - XA(3,IELEM)  * Y(IKLE1(IELEM))
     &                    - XA(5,IELEM)  * Y(IKLE2(IELEM))
     &                    - XA(6,IELEM)  * Y(IKLE3(IELEM))
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).EQ.'0') THEN
!
          CALL OV ('X=C     ', W1 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W2 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W3 , Y , Z , 0.D0 , NELEM )
          CALL OV ('X=C     ', W4 , Y , Z , 0.D0 , NELEM )
!
        ELSE
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=-YZ   ', X , Y , DA , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=-Y    ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'0') THEN
          CALL OV ('X=C     ', X , Y , DA , 0.D0 , NPOIN )
        ELSE
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=X+TAY ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) = W1(IELEM) + XA(7,IELEM)  * Y(IKLE2(IELEM))
     &                            + XA(8,IELEM)  * Y(IKLE3(IELEM))
     &                            + XA(9,IELEM)  * Y(IKLE4(IELEM))
            W2(IELEM) = W2(IELEM) + XA(1,IELEM)  * Y(IKLE1(IELEM))
     &                            + XA(10,IELEM) * Y(IKLE3(IELEM))
     &                            + XA(11,IELEM) * Y(IKLE4(IELEM))
            W3(IELEM) = W3(IELEM) + XA(2,IELEM)  * Y(IKLE1(IELEM))
     &                            + XA(4,IELEM)  * Y(IKLE2(IELEM))
     &                            + XA(12,IELEM) * Y(IKLE4(IELEM))
            W4(IELEM) = W4(IELEM) + XA(3,IELEM)  * Y(IKLE1(IELEM))
     &                            + XA(5,IELEM)  * Y(IKLE2(IELEM))
     &                            + XA(6,IELEM)  * Y(IKLE3(IELEM))
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).NE.'0') THEN
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=X+YZ  ', X , Y , DA , C , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=X+Y   ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).NE.'0') THEN
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=X-TAY ') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) = W1(IELEM) - XA(7,IELEM)  * Y(IKLE2(IELEM))
     &                            - XA(8,IELEM)  * Y(IKLE3(IELEM))
     &                            - XA(9,IELEM)  * Y(IKLE4(IELEM))
            W2(IELEM) = W2(IELEM) - XA(1,IELEM)  * Y(IKLE1(IELEM))
     &                            - XA(10,IELEM) * Y(IKLE3(IELEM))
     &                            - XA(11,IELEM) * Y(IKLE4(IELEM))
            W3(IELEM) = W3(IELEM) - XA(2,IELEM)  * Y(IKLE1(IELEM))
     &                            - XA(4,IELEM)  * Y(IKLE2(IELEM))
     &                            - XA(12,IELEM) * Y(IKLE4(IELEM))
            W4(IELEM) = W4(IELEM) - XA(3,IELEM)  * Y(IKLE1(IELEM))
     &                            - XA(5,IELEM)  * Y(IKLE2(IELEM))
     &                            - XA(6,IELEM)  * Y(IKLE3(IELEM))
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).NE.'0') THEN
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=X-YZ  ', X , Y , DA , C , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=X-Y   ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).NE.'0') THEN
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSEIF(OP(1:8).EQ.'X=X+CTAY') THEN
!
!   CONTRIBUTION OF EXTRADIAGONAL TERMS:
!
        IF(TYPEXT(1:1).EQ.'Q'.OR.TYPEXT(1:1).EQ.'S') THEN
!
          DO IELEM = 1 , NELEM
            W1(IELEM) = W1(IELEM)
     &                + C * (    + XA(7,IELEM)  * Y(IKLE2(IELEM))
     &                           + XA(8,IELEM)  * Y(IKLE3(IELEM))
     &                           + XA(9,IELEM)  * Y(IKLE4(IELEM)) )
            W2(IELEM) = W2(IELEM)
     &                + C * (    + XA(1,IELEM)  * Y(IKLE1(IELEM))
     &                           + XA(10,IELEM) * Y(IKLE3(IELEM))
     &                           + XA(11,IELEM) * Y(IKLE4(IELEM)) )
            W3(IELEM) = W3(IELEM)
     &                + C * (    + XA(2,IELEM)  * Y(IKLE1(IELEM))
     &                           + XA(4,IELEM)  * Y(IKLE2(IELEM))
     &                           + XA(12,IELEM) * Y(IKLE4(IELEM)) )
            W4(IELEM) = W4(IELEM)
     &                + C * (    + XA(3,IELEM)  * Y(IKLE1(IELEM))
     &                           + XA(5,IELEM)  * Y(IKLE2(IELEM))
     &                           + XA(6,IELEM)  * Y(IKLE3(IELEM)) )
          ENDDO ! IELEM
!
        ELSEIF(TYPEXT(1:1).NE.'0') THEN
!
          IF (LNG.EQ.1) WRITE(LU,1000) TYPEXT
          IF (LNG.EQ.2) WRITE(LU,1001) TYPEXT
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!   CONTRIBUTION OF THE DIAGONAL
!
        IF(TYPDIA(1:1).EQ.'Q') THEN
          CALL OV ('X=X+CYZ ', X , Y , DA , C , NPOIN )
        ELSEIF(TYPDIA(1:1).EQ.'I') THEN
          CALL OV ('X=X+CY  ', X , Y , Z  , C  , NPOIN )
        ELSEIF(TYPDIA(1:1).NE.'0') THEN
          IF (LNG.EQ.1) WRITE(LU,2000) TYPDIA
          IF (LNG.EQ.2) WRITE(LU,2001) TYPDIA
          CALL PLANTE(1)
          STOP
        ENDIF
!
!-----------------------------------------------------------------------
!
      ELSE
!
        IF (LNG.EQ.1) WRITE(LU,3000) OP
        IF (LNG.EQ.2) WRITE(LU,3001) OP
        CALL PLANTE(1)
        STOP
!
!-----------------------------------------------------------------------
!
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
!
1000  FORMAT(1X,'MV0404_2 (BIEF) : TERMES EXTRADIAG. TYPE INCONNU: ',A1)
1001  FORMAT(1X,'MV0404_2 (BIEF) : EXTRADIAG. TERMS  UNKNOWN TYPE: ',A1)
2000  FORMAT(1X,'MV0404_2 (BIEF) : DIAGONALE : TYPE INCONNU: ',A1)
2001  FORMAT(1X,'MV0404_2 (BIEF) : DIAGONAL : UNKNOWN TYPE : ',A1)
3000  FORMAT(1X,'MV0404_2 (BIEF) : OPERATION INCONNUE : ',A8)
3001  FORMAT(1X,'MV0404_2 (BIEF) : UNKNOWN OPERATION : ',A8)
!
!-----------------------------------------------------------------------
!
      END
