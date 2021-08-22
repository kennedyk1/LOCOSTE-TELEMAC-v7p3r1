#! /usr/bin/python
# -*- coding: utf-8 -*-
"""
    Python wrapper to the Fortran APIs of Telemac-Mascaret

    Author(s): Fabrice Zaoui, Yoann Audouin, Cedric Goeury, Renaud Barate

    Copyright EDF 2016
"""
from __future__ import print_function
import sys
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from mpl_toolkits.mplot3d import Axes3D
from scipy.spatial.distance import cdist
import shutil
#
from compileAPI import get_api_ld_flags, get_api_incs_flags,\
                       compile_princi_lib, build_config
from TelApy.tools.polygon import is_in_polygon
from ctypes import cdll
import os
from os import path
from parsers.parserKeywords import scanCAS,readCAS,getKeyWord,setKeyValue,scanDICO,getIOFilesSubmit
from utils.files import getFileContent

def decode_range(string):
    """
    Transform a string in format [1,2:8,..,4] into a list
    """
    res = []
    # Checking that beginning and end of the string are [ ]
    if string[0] != '[' and string[:-1] != "]":
        raise Exception("Invalid range format for %s"%string)

    # Splitting values that should be separated by commas
    tmp_list = string[1:-1].split(",")

    for item in tmp_list:
        # Wide range item
        if ":" in item:
            i, j = item.split(":")
            for val in xrange(int(i), int(j)+1):
                res.append(val)
        # Isolated item
        else:
            res.append(int(item))

    return res


class ApiModule(object):
    """The Generic Python class for TELEMAC-MASCARET APIs"""
    _api = None

    def __init__(self, name, casfile,
                 user_fortran,
                 dicofile,
                 lang, stdout,
                 comm, recompile,
                 code=None):
        """
        Constructor for apiModule

        @param name Name of the code (t2d, sis, ...)
        @param casFile Name of the steering file
        @param user_fortran Name of the user Fortran
        @param dicofile Path to the dictionary
        @param lang Language for ouput (1: French, 2:English)
        @param stdout Where to put the listing
        @param comm MPI communicator
        @param recompile If true recompiling the API
        @param code For coupling
        """

        self.name = name

        self.nbnodes = 0
        self.bottom = None
        self.nelem = 0
        self.tri = None
        self.coordx = None
        self.coordy = None
        self.parallel_run = False

        self.user_fortran_lib = None
        self.user_fortran_lib_path = None
        # User Fortran MUST be loaded before apit2d importation
        rank = 0
        if comm is not None:
            rank = comm.Get_rank()
            self.parallel_run = comm.Get_size() > 1
        if recompile:
            # Compiling API with user_fortran
            if user_fortran is not None:
                # compile user fortran
                cfgs = build_config('', '', '')
                cfgname = cfgs.keys()[0]
                if rank == 0:
                    incs_flags = get_api_incs_flags(cfgs, cfgname)
                    ld_flags = get_api_ld_flags(cfgs, cfgname, False)
                    compile_princi_lib(user_fortran, cfgname, cfgs,
                                       incs_flags, ld_flags)

                # Waiting for proc 0 to finish recompiling API
                if comm is not None:
                    comm.barrier()
                        # Load user fortran
                self.user_fortran_lib_path = path.join(os.getcwd(),'libuser_fortran' + \
                                             cfgs[cfgname]['sfx_lib'])
                print( 'self.user_fortran_lib_path '+self.user_fortran_lib_path )
                self.user_fortran_lib = cdll.LoadLibrary(self.user_fortran_lib_path)

        # Load api
        try:
            if ApiModule._api is None:
                import _api
            else:
                reload(ApiModule._api)
        except Exception as execpt:
            if sys.platform.startswith('linux'):
                ext = 'so'
            elif sys.platform.startswith('darwin'):
                ext = 'dylib'
            elif sys.platform.startswith('win'):
                ext = 'dll'
            else:
                raise Exception('Error: unsupported Operating System!')
            raise Exception('Error: unable to load the dynamic library '+\
                            '_api.'+ext+\
                        '\nYou can check the environment variable PYTHONPATH'+\
                        '\n'+str(execpt))
        ApiModule._api = sys.modules['_api']
        self.api_inter = ApiModule._api.api_interface

        # Making links to all the functions
        self.run_set_config = getattr(self.api_inter, \
                                      "run_set_config_"+self.name)
        self.run_read_case = getattr(self.api_inter, "run_read_case_"+self.name)
        self.run_allocation = getattr(self.api_inter, \
                                      "run_allocation_"+self.name)
        self.run_init = getattr(self.api_inter, "run_init_"+self.name)
        self.run_timestep = getattr(self.api_inter, "run_timestep_"+self.name)
        self.run_finalize = getattr(self.api_inter, "run_finalize_"+self.name)
        self.api_get_integer = getattr(self.api_inter, "get_integer_"+self.name)
        self.api_set_integer = getattr(self.api_inter, "set_integer_"+self.name)
        self.api_get_double = getattr(self.api_inter, "get_double_"+self.name)
        self.api_set_double = getattr(self.api_inter, "set_double_"+self.name)
        self.api_get_string = getattr(self.api_inter, "get_string_"+self.name)
        self.api_set_string = getattr(self.api_inter, "set_string_"+self.name)
        self.api_get_boolean = getattr(self.api_inter, "get_boolean_"+self.name)
        self.api_set_boolean = getattr(self.api_inter, "set_boolean_"+self.name)
        self.get_var_type = getattr(self.api_inter, "get_var_type_"+self.name)
        self.get_var_size = getattr(self.api_inter, "get_var_size_"+self.name)
        self.mod_handle_var = getattr(ApiModule._api, "api_handle_var_"+self.name)

        self.api_handle_error = ApiModule._api.api_handle_error

        self.lang = lang
        self.stdout = stdout
        self.casfile = casfile
        self.dicofile = dicofile
        if comm is not None:
            self.fcomm = comm.py2f()
            self.ncsize = comm.Get_size()
            self.rank = comm.Get_rank()
        else:
            self.fcomm = 0
            self.ncsize = 0
            self.rank = 0
        self.comm = comm
        self.code = code
        self._initstate = 0

        # run_set_config
        self.my_id, self.ierr = self.run_set_config(self.stdout,\
                                                 self.lang, self.fcomm)
        if self.ierr != 0:
            raise Exception('Error: unable to initialize Telemac2d.\n\
                             Try to use get_error_message for more information')
        # Running partitionning step if in parallel
        if self.ncsize > 1:
            if self.rank == 0:
                self.paritionning_step()
            self.comm.Barrier()

    def paritionning_step(self):
        """
           Partition function
           It will run partel for the files that needs to be split and copy the others

        """
        frgb,dico = scanDICO(self.dicofile)
        iFS,_ = getIOFilesSubmit(frgb,dico)
        cas = readCAS(scanCAS(getFileContent(self.casfile)),dico,frgb)

        # Get the name of the boundary conditions file
        value,defaut = getKeyWord('BOUNDARY CONDITIONS FILE',cas,dico,frgb)
        cli_file = value[0].strip("'")

        # Check if we have some of the optionnals file for
        sec_file=' '
        weirs_file = ' '
        zone_file = ' '
        type_s = 0

        value,defaut = getKeyWord('SECTIONS INPUT FILE',cas,dico,frgb)
        if value!= []:
            sec_file =value[0].strip("'")
        value,defaut = getKeyWord('ZONES FILE',cas,dico,frgb)
        if value!= []:
            zone_file =value[0].strip("'")

        value,defaut = getKeyWord('WEIRS DATA FILE',cas,dico,frgb)
        if value!= []:
            weirs_file =value[0].strip("'")
            value,defaut = getKeyWord('TYPE OF WEIRS',cas,dico,frgb)
            if value != []:
                type_s = value[0]
            else:
                type_s = defaut[0]
            if type_s != 2:
                weirs_file = ' '

        # Loop on all input files
        for key in iFS:
            value,defaut = getKeyWord(key,cas,dico,frgb)
            if value != []:
                ffile=value[0].strip("'")
                if key =='GEOMETRY FILE':
                    print("Running partitioning of geometry file")
                    ierr = self.api_inter.run_partel(self.my_id, ffile, cli_file,
                                                     self.ncsize, 1, 'SERAFIN ',
                                                     sec_file, zone_file, weirs_file)
                elif iFS[key].split(';')[5][0:7] == 'SELAFIN':
                    print("Running partitioning of ",ffile)
                    ierr = self.api_inter.run_partel(self.my_id, ffile, cli_file,
                                                     self.ncsize,1,'SERAFIN ',
                                                     ' ', ' ', ' ')
                elif iFS[key].split(';')[5][0:7] == 'PARAL' or \
                     (key == 'WEIRS DATA FILE' and type_s != 2):
                    for i in range(self.ncsize):
                        print("Copying of ",ffile)
                        shutil.copyfile(ffile,ffile+'{0:05d}-{1:05d}'.format(self.ncsize-1,i))

    def concatenation_step(self):
        """
           Concatenate function
           will run gretel for the file where it is necessary
        """
        frgb,dico = scanDICO(self.dicofile)
        _,oFS = getIOFilesSubmit(frgb,dico)
        cas = readCAS(scanCAS(getFileContent(self.casfile)),dico,frgb)

        # Get name of the geometry file
        value,defaut = getKeyWord('GEOMETRY FILE',cas,dico,frgb)
        geo_file = value[0].strip("'")

        # Get the name of the boundary conditions file
        value,defaut = getKeyWord('BOUNDARY CONDITIONS FILE',cas,dico,frgb)
        cli_file = value[0].strip("'")

        # Get name of the geometry file
        value,defaut = getKeyWord('NUMBER OF HORIZONTAL LEVELS',cas,dico,frgb)
        nplan = value[0] if value != [] else 0
        print("nplan", nplan)

        # Loop on all output files
        for key in oFS:
            value,defaut = getKeyWord(key,cas,dico,frgb)
            if value != []:
                ffile=value[0].strip("'")
                if oFS[key].split(';')[5][0:7] == 'SELAFIN':
                    ierr = self.api_inter.run_gretel(self.my_id ,geo_file, 'SERAFIN ',
                                                     cli_file, ffile, 'SERAFIN ',
                                                     self.ncsize, nplan)
                if oFS[key].split(';')[5][0:6] == 'DELWAQ':
                    print("Delwaq is not handled yet merging will have to be done by hand.")

    def set_case(self):
        """
           Read the steering file and run allocation
        """
        # run_read_case
        if self.name == "sis":
            self.ierr = self.run_read_case(self.my_id, self.code, self.casfile,\
                                                    self.dicofile)
        else:
            self.ierr = self.run_read_case(self.my_id, self.casfile, \
                                                    self.dicofile)
        if self.ierr != 0:
            raise Exception('Error: unable to read_case for Telemac2d.\n\
                           Try to use get_error_message for more information')
        self._initstate = 1

        return self.ierr

    def init_state_default(self):
        """
        Initialize the state of the model Telemac 2D with the values of
        disharges and water levels as indicated by the steering file
        """
        if self._initstate == 0:
            raise Exception('Error: the object is not a Telemac 2D instance')
        else:
            # run_allocation
            self.ierr = self.run_allocation(self.my_id)
            if self.ierr != 0:
                raise Exception('Error: unable to run_allocation for \
                                 Telemac2d.\n\
                               Try to use get_error_message for more \
                               information')
            self.ierr = self.run_init(self.my_id)
            if self.ierr == 0:
                self._initstate = 2
            else:
                raise Exception('Error: unable to set the initial conditions' \
                        '\nTry to use get_error_message for more information')
        return self.ierr

    def run_one_time_step(self):
        """
        Run one time step
        """
        if self._initstate != 2:
            raise Exception('Error: the initial conditions are not set\n\
                       Use init_state_default first')
        else:
            self.ierr = self.run_timestep(self.my_id)
            if self.ierr:
                raise Exception('Error: the computation does not perform.\n\
                           Try to use get_error_message for more information')
        return self.ierr

    def run_all_time_steps(self):
        """
        Run all the time steps

        @retuns the number of computed time steps
        """

        ntimesteps = self.get("MODEL.NTIMESTEPS")
        # Check if we are in finite volume
        equation = ''
        try:
            equation = self.get("MODEL.EQUATION")
            print("equation",equation)
            if 'VF' in equation or 'FV' in equation:
                ntimesteps = 1
        except Exception as e:
            # If the keyword does not exist then the module does not have finite volumes
            # TODO: Check that it is true
            pass

        for _ in xrange(ntimesteps):
            self.ierr = self.run_one_time_step()
            if self.ierr:
                raise Exception('Error: the computation does not perform' \
                        '\nTry to use get_error_message for more information')
        return ntimesteps

    def get_mesh(self):
        """
        Get the 2D mesh of triangular cells

        @returns X, Y coordinates and connectivity
        """
        self.nbnodes = self.get('MODEL.NPOIN')
        self.coordx = np.zeros((self.nbnodes, ))
        self.coordy = np.zeros((self.nbnodes, ))
        for i in xrange(self.nbnodes):
            self.coordx[i] = self.get('MODEL.X', i=i, global_num=not(self.parallel_run))
            self.coordy[i] = self.get('MODEL.Y', i=i, global_num=not(self.parallel_run))
        self.nelem = self.get('MODEL.NELEM')
        self.tri = np.zeros((self.nelem, 3), dtype=np.int)
        for i in xrange(self.nelem):
            for j in xrange(3):
                self.tri[i, j] = self.get('MODEL.IKLE', i=i, j=j) - 1
        return self.coordx, self.coordy, self.tri

    def get_node(self, xval, yval):
        """
        Get the nearest node number for the coordinates (xval, yval).

        @param xval X coordinate.
        @param yval Y coordinate.

        @returns An integer value from 0 to (nbnode-1).
        """
        pt_val = np.array([[xval, yval]])
        if self.coordx is None:
            _, _, _ = self.get_mesh()
        xy_array = np.array([self.coordx, self.coordy]).transpose()
        return np.argmin(cdist(xy_array, pt_val))

    def get_elem(self, xval, yval):
        """
        Get the triangle where the point (xval, yval) is

        @param xval X coordinate
        @param yval Y coordinate

        @return integer value from 0 to (nbtriangle-1)
                 (-1 if no triangle found)
        """
        if self.coordx is None:
            _, _, _ = self.get_mesh()
        xy_array = np.array([self.coordx, self.coordy]).transpose()
        pt_val = np.array([xval, yval])
        dimtri = self.tri.shape
        triangle = -1
        for i in range(dimtri[0]):
            pt1 = xy_array[self.tri[i, 0]]
            pt2 = xy_array[self.tri[i, 1]]
            pt3 = xy_array[self.tri[i, 2]]
            vec0 = pt3 - pt1
            vec1 = pt2 - pt1
            vec2 = pt_val - pt1
            dot00 = np.dot(vec0, vec0)
            dot01 = np.dot(vec0, vec1)
            dot02 = np.dot(vec0, vec2)
            dot11 = np.dot(vec1, vec1)
            dot12 = np.dot(vec1, vec2)
            invden = 1. / (dot00 * dot11 - dot01 * dot01)
            dist_u = (dot11 * dot02 - dot01 * dot12) * invden
            dist_v = (dot00 * dot12 - dot01 * dot02) * invden
            if (dist_u >= 0) & (dist_v >= 0) & (dist_u + dist_v < 1):
                triangle = i
                break
        return triangle


    def show_mesh(self, show=True, visu2d=True):
        """
        Show the 2D mesh with topography

        @param show Display the graph (Default True)
        @param visu2d 2d display (Default True)

        @retuns the figure object
        """
        if self.coordx is None:
            print( "[debug] getting_bottom" )
            print( "[debug] getting_mesh" )
            _, _, _ = self.get_mesh()
        if self.bottom is None:
            self.bottom = np.zeros((self.nbnodes, ))
            for i in xrange(self.nbnodes):
                self.bottom[i] = \
                    self.get('MODEL.BOTTOMELEVATION', i=i)
        fig = plt.figure()
        if visu2d:
            plt.tripcolor(self.coordx, self.coordy, self.tri, self.bottom,
                          shading='flat', edgecolor='w', cmap=cm.terrain)
            plt.colorbar()
        else:
            axe = Axes3D(fig)
            axe.plot_trisurf(self.coordx, self.coordy, self.tri, self.bottom,\
                             cmap=cm.terrain, linewidth=0.1)
        plt.title('2D mesh (%d triangles, %d nodes) \
                   with the bottom elevation (m)' % (self.nelem, self.nbnodes))
        plt.xlabel('X-coordinate (m)')
        plt.ylabel('Y-coordinate (m)')
        if show:
            plt.show()
        return fig

    def list_variables(self):
        """
        List the names and the meaning of available variables and parameters

        @retuns two lists of strings (name and meaning)
        """
        nb_var = getattr(self.mod_handle_var, "nb_var_"+self.name)
        var_len = getattr(self.mod_handle_var, self.name+"_var_len")
        info_len = getattr(self.mod_handle_var, self.name+"_info_len")

        vnames = []
        vinfo = []
        varnames = []
        varinfo = []
        # Reordering string array for variable names
        tmp = getattr(self.mod_handle_var, "vname_"+self.name)
        for j in range(var_len):
            for i in range(nb_var):
                varnames.append(tmp[i][j])
        # Reordering string array for variable info
        tmp = getattr(self.mod_handle_var, "vinfo_"+self.name)
        for j in range(info_len):
            for i in range(nb_var):
                varinfo.append(tmp[i][j])
        # Extracting name and info into a list
        for i in range(nb_var):
            vnames.append(''.join(varnames[i*var_len:(i+1)*var_len]).strip())
            vinfo.append(''.join(varinfo[i*info_len:(i+1)*info_len]).strip())
        return vnames, vinfo


    def get(self, varname, i=0, j=0, k=0, global_num=True):
        """
        Get the value of a variable of Telemac 2D

        @param varname Name of the variable
        @param i index on first dimension
        @param j index on second dimension
        @param k index on third dimension
        @param global_num Are the index on local/global numbering

        @retuns variable value
        """
        value = None
        vartype, _, ndim, _, _, _, _, _, self.ierr = self.get_var_type(varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while getting variable %s type"%varname)
        dim1, dim2, dim3, self.ierr = self.get_var_size(self.my_id, varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while getting variable %s dimension"%varname)
        # If we have a string the first dimension is the size of the string
        if "STRING" in vartype:
            ndim -= 1
            dim0 = dim1
            dim1 = dim2
            dim2 = dim3

        # Checking that index are within bound
        # Only doing that for local numbering and sequential runs
        # TODO: See how to hand that so that it works for both
        if not global_num or not self.parallel_run:
            if ndim >= 1:
                if not 0 <= i < dim1:
                    raise Exception("i=%i is not within [0,%i]"%(i, dim1))

            if ndim >= 2:
                if not 0 <= j < dim2:
                    raise Exception("j=%i is not within [0,%i]"%(j, dim2))

            if ndim == 3:
                if not 0 <= k < dim3:
                    raise Exception("k=%i is not within [0,%i]"%(k, dim3))

        # Getting value depending on type
        if "DOUBLE" in vartype:
            value, self.ierr = \
                 self.api_get_double(self.my_id, varname, global_num, i+1, j+1, k+1)
        elif "INTEGER" in vartype:
            value, self.ierr = self.api_get_integer(self.my_id, varname,
                                                    i+1, j+1, k+1)
        elif "STRING" in vartype:
            tmp_value, self.ierr = self.api_get_string(self.my_id, varname,
                                                       dim0, i+1, j+1)
            value = tmp_value.tostring().strip()
        elif "BOOLEAN" in vartype:
            value, self.ierr = self.api_get_boolean(self.my_id, varname,
                                                    i+1, j+1, k+1)
        else:
            raise Exception("Unknown data type %s for %s"%(vartype, varname))

        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error retrieving data from variable %s"%varname)

        return value

    def set(self, varname, value, i=0, j=0, k=0, global_num=True):
        """
        Get the value of a variable of Telemac 2D

        @param varname Name of the variable
        @param i index on first dimension
        @param j index on second dimension
        @param k index on third dimension
        @param global_num Are the index on local/global numbering

        @retuns variable value
        """
        vartype, readonly, ndim, _, _, _, _, _, self.ierr = self.get_var_type(varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while setting variable %s type"%varname)

        dim1, dim2, dim3, self.ierr = self.get_var_size(self.my_id, varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while getting variable %s dimension"%varname)

        # Check readonly value
        if readonly:
            raise Exception("Variable %s is readonly"%varname)

        # Checking that index are within bound
        # Only doing that for local numbering and sequential runs
        # TODO: See how to hand that so that it works for both
        if not global_num or not self.parallel_run:
            if ndim >= 1:
                if not 0 <= i < dim1:
                    raise Exception("i=%i is not within [0,%i]"%(i, dim1))

            if ndim >= 2:
                if not 0 <= j < dim2:
                    raise Exception("j=%i is not within [0,%i]"%(j, dim2))

            if ndim == 3:
                if not 0 <= k < dim3:
                    raise Exception("k=%i is not within [0,%i]"%(k, dim3))

        # Getting value depending on type
        if "DOUBLE" in vartype:
            self.ierr = \
               self.api_set_double(self.my_id, varname, value, global_num,
                                   i+1, j+1, k+1)
        elif "INTEGER" in vartype:
            self.ierr = self.api_set_integer(self.my_id, varname, value,
                                             i+1, j+1, k+1)
        elif "STRING" in vartype:
            # Filling value with spaces to reach dim1
            tmp_str = value + ' '*(dim1 - len(value))
            self.ierr = self.api_set_string(self.my_id, varname, tmp_str,
                                            i+1, j+1)
        elif "BOOLEAN" in vartype:
            self.ierr = self.api_set_boolean(self.my_id, varname, value,
                                             i+1, j+1, k+1)
        else:
            raise Exception("Unknown data type %s for %s"%(vartype, varname))

        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error retrieving data from variable %s"%varname)

        return self.ierr

    def get_array(self, varname):
        """
        Retrieves all the values from a variable into a numpy array

        @param Name of the variable

        @returns A numpy array containing the values
        """
        _, _, ndim, _, _, _, _, _, self.ierr = self.get_var_type(varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while getting variable %s type"%varname)
        dim1, dim2, dim3, self.ierr = self.get_var_size(self.my_id, varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while getting variable %s dimension"%varname)

        if ndim == 1:
            # Initialising array
            res = np.full((dim1), self.get(varname, i=1))
            # Looping on all indexes
            for i in xrange(dim1):
                res[i] = self.get(varname, i=i)
        elif ndim == 2:
            # Initialising array
            res = np.full((dim1, dim2), self.get(varname, i=0, j=0))
            # Looping on all indexes
            for i in xrange(dim1):
                for j in xrange(dim2):
                    res[i, j] = self.get(varname, i=i, j=j)
        elif ndim == 3:
            # Initialising array
            res = np.full((dim1, dim2, dim3), self.get(varname, i=0, j=0, k=0))
            # Looping on all indexes
            for i in xrange(dim1):
                for j in xrange(dim2):
                    for k in xrange(dim3):
                        res[i, j, k] = self.get(varname, i=i, j=j, k=k)
        else:
            raise Exception("Getting array of a 0d variable!!\n\
                             Use basic get instead")

        return res

    def set_array(self, varname, values):
        """
        Retrieves all the values from a variable into a numpy array

        @param varname Name of the variable
        @param values Value for each index of the array
        """
        _, _, ndim, _, _, _, _, _, self.ierr = self.get_var_type(varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while getting variable %s type"%varname)
        dim1, dim2, dim3, self.ierr = self.get_var_size(self.my_id, varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while getting variable %s dimension"%varname)

        if ndim == 1:
            # Initialising array
            if values.shape != (dim1,):
                raise Exception("Error in shape of values is %s should be %s"\
                                 %(str(values.shape), str((dim1,))))
            # Looping on all indexes
            for i in xrange(dim1):
                self.set(varname, values[i], i=i)
        elif ndim == 2:
            # Initialising array
            if values.shape != (dim1, dim2):
                raise Exception("Error in shape of values is %s should be %s"\
                                 %(str(values.shape), str((dim1, dim2))))
            # Looping on all indexes
            for i in xrange(dim1):
                for j in xrange(dim2):
                    self.set(varname, values[i, j], i=i, j=j)
        elif ndim == 3:
            # Initialising array
            if values.shape != (dim1, dim2, dim3):
                raise Exception("Error in shape of values is %s should be %s"\
                                 %(str(values.shape), str((dim1, dim2, dim3))))
            # Looping on all indexes
            for i in xrange(dim1):
                for j in xrange(dim2):
                    for k in xrange(dim3):
                        self.set(varname, values[i, j, k], i=i, j=j, k=k)
        else:
            raise Exception("Setting array of a 0d variable!!\n\
                             Use basic set instead")


    def get_on_polygon(self, varname, poly):
        """
        Retrieves values for point within the polygon poly
        Warning this works only on array that are of size NPOIN

        @param varname Name of the variable
        @param poly List of tuple containing the x and y
                    on the points of the polygon

        @retuns A numpy array containing all the values
        """
        if self.coordx is None:
            _, _, _ = self.get_mesh()

        points_in_poly = []

        # Detect the points that are within the polygon
        for i, pt_x, pt_y in zip(xrange(self.nbnodes),
                                 self.coordx,
                                 self.coordy):
            if is_in_polygon(pt_x, pt_y, poly):
                points_in_poly.append(i)

        if points_in_poly == []:
            raise Exception("No points are within the polygon")
        # Build the numpy array
        res = np.full((len(points_in_poly)),
                      self.get(varname, i=points_in_poly[0]))
        # Looping on all the points that are within the polygon
        for i, point in enumerate(points_in_poly):
            res[i] = self.get(varname, i=point, global_num=not(self.parallel_run))

        return res

    def set_on_polygon(self, varname, value, poly):
        """
        Set varname to value on all points that are within the polygon poly
        Warning this works only on array that are of size NPOIN

        @param varname Name of the variable
        @param value The value to set
        @param poly List of tuple containing the x and y
                    on the points of the polygon
        """
        if self.coordx is None:
            _, _, _ = self.get_mesh()

        for i, pt_x, pt_y in zip(xrange(self.nbnodes),
                                 self.coordx,
                                 self.coordy):
            if is_in_polygon(pt_x, pt_y, poly):
                self.set(varname, value, i=i, global_num=not(self.parallel_run))


    def get_on_range(self, varname, irange, jrange="", krange=""):
        """
        Retrieves the values of the variable on the range given as argument

        @param varname Name of the variable
        @param irange Range for index i (first dimension)
        @param jrange Range for index j (second dimension)
        @param krange Range for index k (third dimension)

        @retruns A numpy array containing the values
        """
        _, _, ndim, _, _, _, _, _, self.ierr = self.get_var_type(varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while getting variable %s type"%varname)

        if ndim == 1:
            # Checking range
            if irange == "":
                raise Exception("Missing range for first dimension")
            # Decoding ranges
            my_irange = decode_range(irange)

            # Initialising array
            res = np.full((len(my_irange)), self.get(varname, i=0))

            # Looping on all indexes
            for i, val_i in enumerate(my_irange):
                res[i] = self.get(varname, i=val_i)
        elif ndim == 2:
            # Checking range
            if irange == "":
                raise Exception("Missing range for first dimension")
            if jrange == "":
                raise Exception("Missing range for second dimension")
            # Decoding ranges
            my_irange = decode_range(irange)
            my_jrange = decode_range(jrange)

            # Initialising array
            res = np.full((len(my_irange), len(my_jrange)),
                          self.get(varname))

            # Looping on all indexes
            for i, val_i in enumerate(my_irange):
                for j, val_j in enumerate(my_jrange):
                    res[i, j] = self.get(varname, i=val_i, j=val_j)
        elif ndim == 3:
            # Checking range
            if irange == "":
                raise Exception("Missing range for first dimension")
            if jrange == "":
                raise Exception("Missing range for second dimension")
            if krange == "":
                raise Exception("Missing range for third dimension")
            # Decoding ranges
            my_irange = decode_range(irange)
            my_jrange = decode_range(jrange)
            my_krange = decode_range(krange)

            # Initialising array
            res = np.full((len(my_irange), len(my_jrange), len(my_krange)),
                          self.get(varname))

            # Looping on all indexes
            for i, val_i in enumerate(my_irange):
                for j, val_j in enumerate(my_jrange):
                    for k, val_k in enumerate(my_krange):
                        res[i, j, k] = self.get(varname, i=val_i,
                                                j=val_j, k=val_k)
        else:
            raise Exception("Getting range of a 0d variable!!\n\
                             Use basic set instead")

        return res

    def set_on_range(self, varname, value, irange, jrange="", krange=""):
        """
        Retrieves the values of the variable on the range given as argument

        @param varname Name of the variable
        @param value  Value to apply on the ranges
        @param irange Range for index i (first dimension)
        @param jrange Range for index j (second dimension)
        @param krange Range for index k (third dimension)
        """
        _, _, ndim, _, _, _, _, _, self.ierr = self.get_var_type(varname)
        if self.ierr != 0:
            print( self.get_error_message() )
            raise Exception("Error while getting variable %s type"%varname)

        if ndim == 1:
            # Checking range
            if irange == "":
                raise Exception("Missing range for first dimension")
            # Decoding ranges
            my_irange = decode_range(irange)

            # Looping on all indexes
            for i, val_i in enumerate(my_irange):
                self.set(varname, value, i=val_i)

        elif ndim == 2:
            # Checking range
            if irange == "":
                raise Exception("Missing range for first dimension")
            if jrange == "":
                raise Exception("Missing range for second dimension")
            # Decoding ranges
            my_irange = decode_range(irange)
            my_jrange = decode_range(jrange)

            # Looping on all indexes
            for i, val_i in enumerate(my_irange):
                for j, val_j in enumerate(my_jrange):
                    self.set(varname, value, i=val_i, j=val_j)

        elif ndim == 3:
            # Checking range
            if irange == "":
                raise Exception("Missing range for first dimension")
            if jrange == "":
                raise Exception("Missing range for second dimension")
            if krange == "":
                raise Exception("Missing range for third dimension")
            # Decoding ranges
            my_irange = decode_range(irange)
            my_jrange = decode_range(jrange)
            my_krange = decode_range(krange)

            # Looping on all indexes
            for i, val_i in enumerate(my_irange):
                for j, val_j in enumerate(my_jrange):
                    for k, val_k in enumerate(my_krange):
                        self.set(varname, value, i=val_i,
                                 j=val_j, k=val_k)
        else:
            raise Exception("Setting range of a 0d variable!!\n\
                             Use basic set instead")

    def get_error_message(self):
        """
        Get the error message from the Fortran sources of Telemac 2D

        @retuns character string of the error message
        """
        return self.api_handle_error.err_mess.tostring().strip()

    def finalize(self):
        """
        Delete the Telemac 2D instance

        @retuns error code
        """
        ierr = self.run_finalize(self.my_id)
        if ierr:
            print( self.get_error_message() )
            raise Exception('Error: no deletion')

        # Running merging step if in parallel
        if self.ncsize > 1:
            if self.rank == 0:
                self.concatenation_step()
            self.comm.Barrier()
        return ierr

    def generate_var_info(self):
        """
        Returns a dictionary containg specific informations for each variable

        @returns the dictionary
        """

        var_info = {}

        vnames, vinfo = self.list_variables()

        for varname, varinfo in zip(vnames, vinfo):
            vartype, _, _, _, _, _, get_pos, set_pos, self.ierr = self.get_var_type(varname)
            var_info[varname.rstrip()] = {'get_pos':get_pos,
                                          'set_pos':set_pos,
                                          'info':varinfo.rstrip(),
                                          'type':vartype.rstrip()}

        return var_info

    def dump_var_info(self):
        """
        Print Missing information for each variable
        """
        var_info = {}

        vnames, vinfo = self.list_variables()

        for varname, varinfo in zip(vnames, vinfo):
            print( "For Variable "+varname.strip() )
            vartype, readonly, ndim, ient, jent, kent, get_pos, set_pos, self.ierr = self.get_var_type(varname)
            if self.ierr != 0:
                print( "- Missing in get_var_type" )
            dim1, dim2, dim3, self.ierr = self.get_var_size(self.my_id, varname)

            if get_pos == -1:
                print( " - Missing get position" )
            if set_pos == -1:
                print( " - Missing set position" )
            if vartype == '':
                print( " - Missing vartype" )
            if ndim != 0:
                if ndim >= 1:
                    if dim1 == 0:
                        print( " - Missing dim1" )
                if ndim >= 2:
                    if dim2 == 0:
                        print( " - Missing dim2" )
                if ndim >= 3:
                    if dim3 == 0:
                        print( " - Missing dim3" )

        return var_info
