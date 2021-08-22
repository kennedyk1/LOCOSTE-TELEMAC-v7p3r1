# -*- coding: utf-8 -*-
"""
Evaluate the cost function and gradients

Author(s) : Fabrice Zaoui

Copyright EDF 2017

:param 'x': the local point
:param 'nproc': the number of processors to use
:param 'dx', 'vdx': FD step sizes
:param 'fname': name of the cost function
:return: the cost function and its first derivatives
"""

import multiprocessing as mp
import numpy as np

def numv(x, nproc, dx, vdx, fname):
    """
    Compute the cost function and 1st order derivative values
    """
    dimx = x.size
    xp = np.zeros((dimx, 1))
    if vdx is None:
        for i in xrange(dimx):
            xp[i] = x[i] + dx
    else:
        for i in xrange(dimx):
            xp[i] = x[i] + vdx[i]
    pop = np.array([]).reshape(0, dimx)
    pop = np.vstack([pop, x])
    for i in xrange(dimx):
        pop = np.vstack([pop, x])
        pop[1+i, i] = xp[i]
    pool = mp.Pool(processes=nproc)
    feval = pool.map(fname, pop)
    pool.close()
    pool.join()
    val = np.asarray(feval[0])
    if vdx is None:
        jac = (np.asarray(feval[1:]) - val) / dx
    else:
        jac = np.zeros(dimx)
        for i in xrange(dimx):
            jac[i] = (np.asarray(feval[i+1]) - val) / vdx[i]
    return val, jac
