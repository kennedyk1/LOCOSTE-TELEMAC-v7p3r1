#!/usr/bin/env python
from TelApy.api.t2d import Telemac2d
from mpi4py import MPI
import shutil
from os import path, chdir, environ, getcwd
# Creation of the instance Telemac3d
comm = MPI.COMM_WORLD

root = environ.get('HOMETEL',path.join('..', '..', '..'))

pwd = getcwd()

chdir(path.join(root,'examples','telemac2d','pildepon'))

t2d = Telemac2d('t2d_pildepon.cas',user_fortran ='user_fortran',comm=comm)
ierr = 0
rank = comm.Get_rank()
ncsize = comm.Get_size()
# Running partel
if ( rank == 0 and ncsize > 1):
    ierr = t2d.api_inter.run_partel(t2d.my_id,'geo_pildepon.slf','geo_pildepon.cli',ncsize,1,'SERAFIN ',' ',' ',' ')
    for i in xrange(ncsize):
        shutil.copyfile('t2d_pildepon.lqd','t2d_pildepon.lqd'+"{0:05d}-{1:05d}".format(ncsize-1,i))
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
    t2d.api_inter.run_gretel(t2d.my_id,'geo_pildepon.slf','SERAFIN ','geo_pildepon.cli','r2d_pildepon.slf','SERAFIN ',ncsize,0)
# Instance delete
del(t2d)
chdir(pwd)
