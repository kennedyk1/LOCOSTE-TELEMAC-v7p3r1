#!/usr/bin/env python
# Class Telemac2d import
from TelApy.api.t2d import Telemac2d
from mpi4py import MPI
from os import path, chdir, environ, getcwd
# Creation of the instance Telemac3d
comm = MPI.COMM_WORLD

root = environ.get('HOMETEL',path.join('..', '..', '..'))

pwd = getcwd()

chdir(path.join(root,'examples','telemac2d','gouttedo'))

t2d = Telemac2d('t2d_gouttedo.cas',user_fortran ='user_fortran',comm=comm)
ierr = 0
t2d.set_case()
# Initalization
varnames,varinfo = t2d.list_variables()
for name,info in zip(varnames,varinfo):
    print name
    print info

t2d.init_state_default()
# Run all time steps
t2d.run_all_time_steps()
# Running gretel
comm.Barrier()
# Ending the run
t2d.finalize()
# Instance delete
del(t2d)
chdir(pwd)
