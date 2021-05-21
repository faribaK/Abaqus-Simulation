C234567890123456789012345678901234567890123456789012345678901234567890
C
      SUBROUTINE UMAT(STRESS,STATEV,DDSDDE,SSE,SPD,SCD,
     1 RPL,DDSDDT,DRPLDE,DRPLDT,
     2 STRAN,DSTRAN,TIME,DTIME,TEMP,DTEMP,PREDEF,DPRED,CMNAME,
     3 NDI,NSHR,NTENS,NSTATEV,PROPS,NPROPS,COORDS,DROT,PNEWDT,
     4 CELENT,DFGRD0,DFGRD1,NOEL,NPT,LAYER,KSPT,KSTEP,KINC)
C
      INCLUDE 'ABA_PARAM.INC'
C
      CHARACTER*8 CMNAME
      DIMENSION STRESS(NTENS),STATEV(NSTATEV),
     1 DDSDDE(NTENS,NTENS),DDSDDT(NTENS),DRPLDE(NTENS),
     2 STRAN(NTENS),DSTRAN(NTENS),TIME(2),PREDEF(1),DPRED(1),
     3 PROPS(NPROPS),COORDS(3),DROT(3,3),DFGRD0(3,3),DFGRD1(3,3)
C
C     LOCAL ARRAYS
C---------------------------------------------------------------------
C     EELAS  - LOGARITHMIC ELASTIC STRAINS
C     EELASP - PRINCIPAL ELASTIC STRAINS
C     BBAR   - DEVIATORIC RIGHT CAUCHY-GREEN TENSOR
C     BBARP  - PRINCIPAL VALUES OF BBAR
C     BBARN  - PRINCIPAL DIRECTION OF BBAR (AND EELAS)
C     DISTGR - DEVIATORIC DEFORMATION GRADIENT (DISTORTION TENSOR)
C----------------------------------------------------------------------
C
      DIMENSION EELAS(6), EELASP(3), BBAR(6), BBARP(3), BBARN(3,3),
     1          DISTGR(3,3)
C
      PARAMETER(ZERO = 0.D0, ONE = 1.D0, TWO = 2.D0, THREE = 3.D0,
     1          FOUR = 4.D0)
C
C----------------------------------------------------------------------
C     UMAT FOR COMPRESSIBLE NEO-HOOKEAN HYPERELASTICITY 
C     CANNOT BE USED FOR PLANE STRESS
C----------------------------------------------------------------------
C     PROPS(1)  - E
C     PROPS(2)  - NU
C----------------------------------------------------------------------
C
C     ELASTIC PROPERTIES
C
c      EMOD = PROPS(1)
c      ENU  = PROPS(2)
c      C10  = EMOD / (FOUR * (ONE + ENU))
c      D1   = 6.0 * (ONE - TWO * ENU) / EMOD
      C10  = PROPS(1)
      D1   = PROPS(2)
C
C     JACOBIAN AND DISTORTION TENSOR
C
      DET = DFGRD1(1,1) * DFGRD1(2,2) * DFGRD1(3,3)
     1    - DFGRD1(1,2) * DFGRD1(2,1) * DFGRD1(3,3)
C
      IF (NSHR .EQ. 3) THEN
          DET = DET + DFGRD1(1,2) * DFGRD1(2,3) * DFGRD1(3,1)
     1              + DFGRD1(1,3) * DFGRD1(3,2) * DFGRD1(2,1)
     2              - DFGRD1(1,3) * DFGRD1(3,1) * DFGRD1(2,2)
     3              - DFGRD1(2,3) * DFGRD1(3,2) * DFGRD1(1,1)
      END IF
      SCALE = DET**(-ONE /THREE)
C
      DO K1 = 1, 3
        DO K2 = 1, 3
          DISTGR(K2,K1) = SCALE * DFGRD1(K2,K1)
        END DO
      END DO
C
C     CALCULATE LEFT CAUCHY-GREEN TENSOR
C
      BBAR(1) = DISTGR(1,1)**2 + DISTGR(1,2)**2 + DISTGR(1,3)**2
      BBAR(2) = DISTGR(2,1)**2 + DISTGR(2,2)**2 + DISTGR(2,3)**2
      BBAR(3) = DISTGR(3,3)**2 + DISTGR(3,1)**2 + DISTGR(3,2)**2
      BBAR(4) = DISTGR(1,1)*DISTGR(2,1) + DISTGR(1,2)*DISTGR(2,2) 
     1        + DISTGR(1,3)*DISTGR(2,3)
      IF (NSHR .EQ. 3) THEN
        BBAR(5) = DISTGR(1,1)*DISTGR(3,1) + DISTGR(1,2)*DISTGR(3,2) 
     1          + DISTGR(1,3)*DISTGR(3,3)
        BBAR(6) = DISTGR(2,1)*DISTGR(3,1) + DISTGR(2,2)*DISTGR(3,2) 
     1          + DISTGR(2,3)*DISTGR(3,3)
      END IF
C
C     CALCULATE THE STRESS
C
      TRBBAR = (BBAR(1) + BBAR(2) + BBAR(3)) / THREE
      EG     = TWO * C10 / DET
      EK     = TWO / D1 * (TWO * DET - ONE)
      PR     = TWO / D1 * (DET - ONE)
      DO K1 = 1, NDI
        STRESS(K1) = EG * (BBAR(K1) - TRBBAR) + PR
      END DO
C
      DO K1 = NDI+1, NDI+NSHR
        STRESS(K1) = EG * BBAR(K1)
      END DO
C
C     CALCULATE THE STIFFNESS
C
      EG23 = EG * TWO / THREE
      DDSDDE(1,1) = EG23 * (BBAR(1) + TRBBAR) + EK
      DDSDDE(2,2) = EG23 * (BBAR(2) + TRBBAR) + EK
      DDSDDE(3,3) = EG23 * (BBAR(3) + TRBBAR) + EK
      DDSDDE(1,2) =-EG23 * (BBAR(1) + BBAR(2) - TRBBAR) + EK
      DDSDDE(1,3) =-EG23 * (BBAR(1) + BBAR(3) - TRBBAR) + EK
      DDSDDE(2,3) =-EG23 * (BBAR(2) + BBAR(3) - TRBBAR) + EK
      DDSDDE(1,4) = EG23 * BBAR(4) / TWO
      DDSDDE(2,4) = EG23 * BBAR(4) / TWO
      DDSDDE(3,4) =-EG23 * BBAR(4)
      DDSDDE(4,4) = EG * (BBAR(1) + BBAR(2)) / TWO
      IF (NSHR .EQ. 3) THEN
        DDSDDE(1,5) = EG23 * BBAR(5) / TWO
        DDSDDE(2,5) =-EG23 * BBAR(5)
        DDSDDE(3,5) = EG23 * BBAR(5) / TWO
        DDSDDE(1,6) =-EG23 * BBAR(6)
        DDSDDE(2,6) = EG23 * BBAR(6) / TWO
        DDSDDE(3,6) = EG23 * BBAR(6) / TWO
        DDSDDE(5,5) = EG * (BBAR(1) + BBAR(3)) / TWO
        DDSDDE(6,6) = EG * (BBAR(2) + BBAR(3)) / TWO
        DDSDDE(4,5) = EG * BBAR(6) / TWO
        DDSDDE(4,6) = EG * BBAR(5) / TWO
        DDSDDE(5,6) = EG * BBAR(4) / TWO
      END IF
      DO K1 = 1, NTENS
        DO K2 = 1, K1 - 1
          DDSDDE(K1, K2) = DDSDDE(K2, K1)
        END DO
      END DO
C
C     CALCULATE LOGARITHMIC ELASTIC STRAINS (OPTIONAL)
C
C      CALL SPRIND (BBAR, BBARP, BBARN, 1, NDI, NSHR)
C      EELASP(1) = LOG(SQRT(BBARP(1))/SCALE)
C      EELASP(2) = LOG(SQRT(BBARP(2))/SCALE)
C      EELASP(3) = LOG(SQRT(BBARP(3))/SCALE)
C      EELAS(1) = EELASP(1) * BBARN(1,1)**2 + EELASP(2) * BBARN(2,1)**2
C     1         + EELASP(3) * BBARN(3,1)**2
C      EELAS(2) = EELASP(1) * BBARN(1,2)**2 + EELASP(2) * BBARN(2,2)**2
C     1         + EELASP(3) * BBARN(3,2)**2
C      EELAS(3) = EELASP(1) * BBARN(1,3)**2 + EELASP(2) * BBARN(2,3)**2
C     1         + EELASP(3) * BBARN(3,3)**2
C      EELAS(4) = TWO * (EELASP(1) * BBARN(1,1) * BBARN(1,2)
C     1               +  EELASP(2) * BBARN(2,1) * BBARN(2,2)
C     2               +  EELASP(3) * BBARN(3,1) * BBARN(3,2))
C      IF (NSHR .EQ. 3) THEN
C        EELAS(5) = TWO * (EELASP(1) * BBARN(1,1) * BBARN(1,3)
C     1                 +  EELASP(2) * BBARN(2,1) * BBARN(2,3)
C     2                 +  EELASP(3) * BBARN(3,1) * BBARN(3,3))
C        EELAS(6) = TWO * (EELASP(1) * BBARN(1,2) * BBARN(1,3)
C     1                 +  EELASP(2) * BBARN(2,2) * BBARN(2,3)
C     2                 +  EELASP(3) * BBARN(3,2) * BBARN(3,3))
C      END IF
C
C     STORE ELASTIC STRAINS IN STATE VARIABLE ARRAY
C
C      DO K1 = 1, NTENS
C        STATEV(K1) = EELAS(K1)
C      END DO
	  
	  
	  
	  open(105,file='C:\Users\khanfari\Box\Asymmetric Tensor_Fariba\Abaqus Examples\solidsphere\job umat\solidsphere_dg.txt',position='append')
	  WRITE(105,*)DFGRD1
	  close(105)
	  
C	  open(105,file='C:\AbaqusTemp\flatsheet_dg.txt',position='append')
C	  WRITE(105,*) 'test'
C	  close(105)
	  
	  open(105,file='C:\Users\khanfari\Box\Asymmetric Tensor_Fariba\Abaqus Examples\solidsphere\job umat\solidsphere_stress.txt',position='append')
	  WRITE(105,*)STRESS
	  close(105)
	  
C	  open(105,file='C:\AbaqusTemp\flatsheet_stress.txt',position='append')
C	  WRITE(105,*) 'test'
C	  close(105)
	  
C
      RETURN
      END

    
