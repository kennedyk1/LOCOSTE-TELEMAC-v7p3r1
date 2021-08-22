#!/usr/bin/env python
# Class Telemac2d import
from TelApy.api.t2d import Telemac2d
from mpi4py import MPI
import shutil
from os import path, chdir, environ, getcwd
# Creation of the instance Telemac3d
comm = MPI.COMM_WORLD

root = environ.get('HOMETEL',path.join('..', '..', '..'))

pwd = getcwd()

chdir(path.join(root,'examples','telemac2d','breach'))

t2d = Telemac2d('t2d_breach.cas',comm=comm)
ierr = 0
rank = comm.Get_rank()
ncsize = comm.Get_size()
# Running partel
if ( rank == 0 and ncsize > 1):
    ierr = t2d.api_inter.run_partel(t2d.my_id,'geo_breach.slf','geo_breach.cli',ncsize,1,'SERAFIN ',' ',' ',' ')
    ierr = t2d.api_inter.run_partel(t2d.my_id,'ini_breach.slf','geo_breach.cli',ncsize,1,'SERAFIN ',' ',' ',' ')
    for i in xrange(ncsize):
        shutil.copyfile('t2d_breach.liq','t2d_breach.liq'+"{0:05d}-{1:05d}".format(ncsize-1,i))
comm.Barrier()
t2d.set_case()
# Initalization
t2d.init_state_default()
# Run all time steps
t2d.run_all_time_steps()
# Running gretel
comm.Barrier()
# Ending the run
t2d.finalize()
if ( rank == 0 and ncsize > 1):
    t2d.api_inter.run_gretel(t2d.my_id,'geo_breach.slf','SERAFIN ','geo_breach.cli','r2d_breach.slf','SERAFIN ',ncsize,0)
# Instance delete
del(t2d)
chdir(pwd)
