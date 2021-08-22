import numpy as np
import os
from TelApy.api.t2d import Telemac2d
from mpi4py import MPI
import TelApy.tools.polygon as polygon

class StudyTelemac2D:

    def __init__(self,studyFiles,tps_obs,poly_obs=None):
        # creation of the telemac instance with compilation of the user  fortran      
        self.t2d = Telemac2d(studyFiles['t2d.cas'],user_fortran = studyFiles['t2d.f'], comm=MPI.COMM_WORLD)
        #self.t2d = Telemac2d(studyFiles['t2d.cas'],user_fortran = studyFiles['t2d.f'])
        #self.t2d = Telemac2d(studyFiles['t2d.cas'],user_fortran = studyFiles['t2d.f'])
        # Telemac Steering file reading
        self.t2d.set_case()
        self.tps_obs = tps_obs
        # This is the initialization part      
        self.t2d.init_state_default()
        self.initial_state = self.t2d.get_state()
        self.npoin = self.t2d.get('MODEL.NPOIN')
        self.final_time = self.t2d.get("MODEL.NTIMESTEPS")
        # Initialization of the observation part
        self.point_obs = []
        if poly_obs!=None:
            for i in xrange(self.npoin):
                if polygon.is_in_polygon(self.t2d.get('MODEL.X',i),self.t2d.get('MODEL.Y',i),poly_obs):
                    self.point_obs.append(i)

    def Run_telemac_case(self,finalize=False):
        self.t2d.set_state(self.initial_state[0][:],self.initial_state[1][:],self.initial_state[2][:])
        self.t2d.set("MODEL.NTIMESTEPS",self.final_time)
        ierr = self.t2d.run_all_time_steps()
        if finalize==True:
            self.t2d.finalize()
            del(self.t2d)

    def Run_Telemac_case_T1_to_T2(self,Tdeb,Tfin,finalize=False):
        for i in xrange(Tdeb,Tfin):
            ierr = self.t2d.run_one_time_step()
        if finalize==True:
            self.t2d.finalize()
            del(self.t2d)

    def Run_and_record_telemac_state_new(self,X):
        LT = 0
        AT = 0.0
        # Change the Strickler coefficient in all domain
        for i in xrange(self.npoin):
            self.t2d.set('MODEL.CHESTR',X,i)
        self.t2d.set_state(self.initial_state[0][:],self.initial_state[1][:],self.initial_state[2][:])
        self.t2d.set("MODEL.LT",LT)
        self.t2d.set("MODEL.AT",AT)
        self.t2d.set("MODEL.COMPLEO",LT)
        self.t2d.set("MODEL.NTIMESTEPS",self.final_time)
        H = []
        U = []
        V = []
        if 0 in self.tps_obs:
            if len(self.point_obs)>0:
                H.append(np.zeros((1,len(self.point_obs))))
                U.append(np.zeros((1,len(self.point_obs))))
                V.append(np.zeros((1,len(self.point_obs))))
                for k in self.point_obs:
                    H[self.tps_obs.index(0)][self.point_obs.index(k)] = self.t2d.get('MODEL.WATERDEPTH',k)
                    U[self.tps_obs.index(0)][self.point_obs.index(k)] = self.t2d.get('MODEL.VELOCITYU',k)
                    V[self.tps_obs.index(0)][self.point_obs.index(k)] = self.t2d.get('MODEL.VELOCITYV',k)
        # Beginning of the computation
        ntimesteps = self.t2d.get("MODEL.NTIMESTEPS")
        for i in xrange(ntimesteps):
            ierr = self.t2d.run_one_time_step()
            if (i+1) in self.tps_obs:
                if len(self.point_obs)>0:
                    H.append(np.zeros((1,len(self.point_obs))))
                    U.append(np.zeros((1,len(self.point_obs))))
                    V.append(np.zeros((1,len(self.point_obs))))
                    for k in self.point_obs:
                        H[self.tps_obs.index(i+1)][self.point_obs.index(k)] = self.t2d.get('MODEL.WATERDEPTH',k)
                        U[self.tps_obs.index(i+1)][self.point_obs.index(k)] = self.t2d.get('MODEL.VELOCITYU',k)
                        V[self.tps_obs.index(i+1)][self.point_obs.index(k)] = self.t2d.get('MODEL.VELOCITYV',k)
        return H,U,V

    def HX(self,K):
        # K : Strickler coefficient
        H,U,V = self.Run_and_record_telemac_state_new(K)
        Y = np.asmatrix(np.ravel(H)).T
        return Y

