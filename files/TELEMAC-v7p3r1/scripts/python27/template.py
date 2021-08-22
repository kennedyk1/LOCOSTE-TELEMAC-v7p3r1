#!/usr/bin/env python
# Class Telemac2d import
from __future__ import print_function
from TelApy.api.t2d import Telemac2d
from mpi4py import MPI
from os import  path,environ
from optparse import OptionParser
from parsers.parserKeywords import scanCAS,readCAS,getKeyWord,setKeyValue,scanDICO,getIOFilesSubmit
from utils.files import getFileContent
import shutil

def run_telemac(t2d,comm):
    t2d.set_case()
    t2d.init_state_default()
    t2d.run_all_time_steps()
    comm.Barrier()
    t2d.finalize()


if __name__=="__main__":

    # Define a parser for the program options
    parser = OptionParser("Usage: %prog input-file-name -o output-file-name [options]\n"+
         "Example: template.py -i t2d.gouttedo.cas -f t2d.gouttedo.f -o r2d_gouttedo.slf")
    # output name option
    parser.add_option("-o","--output-file",
             type="string",
             dest="outputFile",
             default="",
             help="name of the output file")
    # output fomrat
    parser.add_option("-f","--fortran-file",
             type="string",
             dest="fortranFile",
             default="",
             help="name of the fortran file")
    # output fomrat
    parser.add_option("-i","--input-format",
             type="string",
             dest="inputFile",
             default="",
             help="name of the input format")
    # reading the options
    options, args = parser.parse_args()

    casFile = options.inputFile
    forFile = options.fortranFile
    # Creation of the instance Telemac2d
    comm = MPI.COMM_WORLD
    if forFile!='':
        t2d = Telemac2d(casFile, user_fortran=forFile, comm=comm)
    else:
        t2d = Telemac2d(casFile, comm=comm)
    ierr = 0
    # Running telemac
    run_telemac(t2d,comm)
    # Instance delete
    del(t2d)

    print("My work is done")
