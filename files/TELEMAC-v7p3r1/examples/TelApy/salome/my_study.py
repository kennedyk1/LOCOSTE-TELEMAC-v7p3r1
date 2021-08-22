#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Class Telemac2d import
from TelApy.api.t2d import Telemac2d
from mpi4py import MPI
import os

def study_function(q0=10.0, q1=100.0):
    comm = MPI.COMM_WORLD
    # Moving to the study folder (folder containing the steering file)
    os.chdir(os.path.dirname('/home/B61570/opentelemac/git/branches/weirdfish/examples/telemac2d/gouttedo/t2d_gouttedo.cas'))
    # Creation of the instance Telemac2d
    my_case = Telemac2d('/home/B61570/opentelemac/git/branches/weirdfish/examples/telemac2d/gouttedo/t2d_gouttedo.cas', user_fortran='/home/B61570/opentelemac/git/branches/weirdfish/examples/telemac2d/gouttedo/user_fortran/condin.f', comm=comm)
    
    # Reading the steering file informations
    my_case.set_case()
    
    # Initalization
    my_case.init_state_default()
    my_case.set('MODEL.DEBIT', q0, i=1, j=0, k=0)
    my_case.set('MODEL.DEBIT', q1, i=2, j=0, k=0)
    
    # Run all time steps
    my_case.run_all_time_steps()
    h0 = my_case.get('MODEL.WATERDEPTH', i=25, j=0, k=0)
    h1 = my_case.get('MODEL.WATERDEPTH', i=666, j=0, k=0)
    
    # Ending the run
    my_case.finalize()
    
    # Instance delete
    del(my_case)

    return h0, h1

if __name__ == "__main__":
    study_function()
