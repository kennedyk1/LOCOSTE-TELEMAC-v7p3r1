#! /usr/bin/python
# -*- coding: utf-8 -*-
"""
    Python wrapper to the Fortran APIs of Telemac-Mascaret

    Author(s): Fabrice Zaoui, Yoann Audouin, Cedric Goeury, Renaud Barate

    Copyright EDF 2017
"""
import logging
import ctypes
import os
import sys

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

class Mascaret(object):
    """The Python class for MASCARET APIs"""
    libmascaret = None
    logger = logging.getLogger(__name__)

    _error = 0
    nb_nodes = None

    @property
    def error(self):
        """Error property
        """
        return self._error

    @error.setter
    def error(self, value):
        """Detect errors

        Overwright attribute setter to detect API errors.
        If :attr:`error` is not set null, an error is raised and the programme
        is terminated.

        :param int value: value to assign
        """
        if value != 0:
            self.logger.error("API error:\n{}".format(self.error_message()))
            raise SystemExit
        self._error = 0

    def error_message(self):
        """Error message wrapper

        :return: Error message
        :rtype: str
        """
        err_mess_c = ctypes.POINTER(ctypes.c_char_p)()
        error = self.libmascaret.C_GET_ERREUR_MASCARET(self.id_masc,
                                                       ctypes.byref(err_mess_c))
        if error != 0:
            return 'Error could not be retrieved from MASCARET...'
        return ctypes.string_at(err_mess_c)

    def load_mascaret(self, libmascaret):
        """Load Mascaret library

        :param str libmascaret: path to the library
        """
        ld_library = os.environ['LD_LIBRARY_PATH']
        self.logger.debug('LD_LIBRARY_PATH: {}'.format(ld_library))
        self.logger.info('Loading {}...'.format(libmascaret))
        if sys.platform.startswith('linux') \
           or sys.platform.startswith('darwin'):
            try:
                self.libmascaret = ctypes.CDLL(libmascaret)
            except Exception as tbe:
                self.logger.exception("Unable to load: mascaret.so. Check the "
                                      "environment variable LIBMASCARET: {}"
                                      .format(tbe))
                raise SystemExit
            else:
                self.logger.info('Library loaded.')
        else:
            self.logger.error('Unsupported OS. Only macOS or Unix!')
            raise SystemExit

    def __init__(self, log_level='INFO'):
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
        if log_level == 'INFO':
            i_log = logging.INFO
        elif log_level == 'DEBUG':
            i_log = logging.DEBUG
        else:
            i_log = logging.CRITICAL
        logging.basicConfig(level=i_log)
        self.logger.info('Using MascaretApi')
        # Load the library libmascaret.so
        libmascaret = 'libmascaret.so'
        self.load_mascaret(libmascaret)
        self.iprint = 0
        self.id_masc = None

    def create_mascaret(self, iprint):
        """Create an instance of Mascaret

        Uses Mascaret Api :meth:`C_CREATE_MASCARET`

        @oaram iprint integer flag value for the Mascaret listing files
        """
        id_masc = ctypes.c_int()
        self.logger.debug('Creating a model...')
        self.error = self.libmascaret.C_CREATE_MASCARET(ctypes.byref(id_masc))
        self.logger.debug('Model created.')
        self.id_masc = ctypes.c_int(id_masc.value)
        # .opt and .lis written only if iprint = 1 at import AND calcul steps
        self.iprint = iprint

    def import_model(self, files_name, files_type):
        """Read model from Mascaret files

        Uses Mascaret Api :meth:`C_IMPORT_MODELE_MASCARET`

        @param str files_name: array of the Mascaret data files
        @param str files_type: array of the file name extensions
        """
        len_file = len(files_name)
        file_type = []
        file_name = []
        for name, typ in zip(files_name, files_type):
            file_type.append(typ.encode('utf8'))
            file_name.append(name.encode('utf8'))
        file_name_c = (ctypes.c_char_p * len_file)(*file_name)
        file_type_c = (ctypes.c_char_p * len_file)(*file_type)
        self.logger.debug('Importing a model...')
        self.error = self.libmascaret.C_IMPORT_MODELE_MASCARET(\
                self.id_masc, file_name_c,\
                file_type_c, len_file, self.iprint)
        self.logger.info("Model imported with:\n"+\
                         "-> file_name: {}\n-> file_type: {}."\
                         .format(file_name, file_type))
    def __del__(self):
        """Delete a model."""
        self.logger.debug('Deleting instance #{}...'.format(self.id_masc.value))
        self.error = self.libmascaret.C_DELETE_MASCARET(self.id_masc)
        self.logger.debug("Model #{} deleted.".format(self.id_masc.value))

    def save_state(self):
        """Save a state

        Mascaret Api :meth:`C_SAVE_ETAT_MASCARET`

        :return: id number for the saved state
        :rtype: int
        """
        saved_state_c = ctypes.c_int()
        self.logger.debug('Save MASCARET state...')
        self.error = self.libmascaret.C_SAVE_ETAT_MASCARET(
            self.id_masc, ctypes.byref(saved_state_c))
        self.logger.debug('Save MASCARET state done.')

        return saved_state_c.value

    def free_saved_state(self, saved_state):
        """Free all the saved states

        Mascaret Api :meth:`C_FREE_SAVE_ETAT_MASCARET`

        @param int saved_state: id number of the state to delete
        """
        saved_state_c = ctypes.c_int(saved_state)
        self.logger.debug('Free saved state mascaret...')
        self.error = self.libmascaret.C_FREE_SAVE_ETAT_MASCARET(
            id_state_c)
        self.logger.debug('Free save etat mascaret done.')

    def get_hydro(self):
        """Get the water levels (m) and discharge values (m3/s)

        :return: water levels and discharges for all 1D nodes
        :rtype: list
        """
        if self.nb_nodes is None:
            self.nb_nodes, _, _ = self.get_var_size('Model.X')
        var_z = []
        var_q = []
        for i in range(self.nb_nodes):
            var_z.append(i)
            var_z[i] = self.get('State.Z', i, 0, 0)
            var_q.append(i)
            var_q[i] = self.get('State.Q', i, 0, 0)
        return var_z, var_q

    def set_state(self, id_state):
        """Set state of a Mascaret model

        Mascaret Api :meth:`C_SET_ETAT_MASCARET`

        @param: int id_state: id number of the state to restore
        """
        id_state_c = ctypes.c_int(id_state)
        self.logger.debug('Set MASCARET state...')
        self.error = self.libmascaret.C_SET_ETAT_MASCARET(
            self.id_masc, id_state_c)
        self.logger.debug('Set MASCARET state done.')

    def free_all_saved_states(self):
        """
        Mascaret Api :meth:`C_FREE_ALL_SAVE_ETAT_MASCARET`
        """
        self.logger.debug('Free all saved states mascaret...')
        self.error = self.libmascaret.C_FREE_ALL_SAVE_ETAT_MASCARET(
            self.id_masc)
        self.logger.debug('Free all saved states mascaret done.')

    def init_hydro(self, z_val, q_val):
        """Initialize the model from hydraulic values

        Mascaret Api :meth:`C_INIT_LIGNE_MASCARET`

        @param z_val list or array: water levels (m)
        @param q_val list or array: discharges (m3/s)
        """
        if self.nb_nodes is None:
            self.nb_nodes, _, _ = self.get_var_size('Model.X')
        # Initialize Mascaret Model from values
        q_c = (ctypes.c_double * self.nb_nodes)(*q_val)
        z_c = (ctypes.c_double * self.nb_nodes)(*z_val)
        self.logger.debug('Initilizing MASCARET from constant value...')
        self.error = self.libmascaret.C_INIT_LIGNE_MASCARET(
            self.id_masc, ctypes.byref(q_c), ctypes.byref(z_c), self.nb_nodes)
        self.logger.debug(
            'State constant initialisation successfull from constant value.')

    def init_hydro_from_file(self, hydro_file):
        """Initialize the model from a .lig file

        Mascaret Api :meth:`C_INIT_LIGNE_MASCARET`

        @param str hydro_file: '.lig' Mascaret file
        """
        init_file_name_c = (ctypes.c_char_p)(*[hydro_file])
        self.logger.debug('Initializing MASCARET from .lig ...')
        self.error = self.libmascaret.C_INIT_ETAT_MASCARET(
            self.id_masc, init_file_name_c, self.iprint)
        self.logger.debug('State initialisation successfull from .lig')

    def get_double(self, var_name, i=0, j=0, k=0):
        """Get the real value of a Mascaret variable

        Mascaret Api :meth:`C_GET_DOUBLE_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param int i: first index of the Mascaret variable
        @param int j: second index of the Mascaret variable
        @param int k: third index of the Mascaret variable
        :return: scalar value
        :rtype: float
        """
        val_c = ctypes.c_double()
        i_c = ctypes.c_int(i)
        j_c = ctypes.c_int(j)
        k_c = ctypes.c_int(k)
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        self.logger.debug('Getting {}...'.format(var_name))
        self.error = self.libmascaret.C_GET_DOUBLE_MASCARET(
            self.id_masc, var_name_c, i_c, j_c, k_c, ctypes.byref(val_c))
        self.logger.debug('Value: val={}.'.format(val_c.value))

        return val_c.value

    def get_int(self, var_name, i=0, j=0, k=0):
        """Get the integer value of a Mascaret variable

        Mascaret Api :meth:`C_GET_INT_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param int i: first index of the Mascaret variable
        @param int j: second index of the Mascaret variable
        @param int k: third index of the Mascaret variable
        :return: scalar value
        :rtype: int
        """
        val_c = ctypes.c_int()
        i_c = ctypes.c_int(i)
        j_c = ctypes.c_int(j)
        k_c = ctypes.c_int(k)
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        self.logger.debug('Getting {}...'.format(var_name))
        self.error = self.libmascaret.C_GET_INT_MASCARET(
            self.id_masc, var_name_c, i_c, j_c, k_c, ctypes.byref(val_c))
        self.logger.debug('Value: val={}.'.format(val_c.value))

        return val_c.value

    def get_bool(self, var_name, i=0, j=0, k=0):
        """Get the boolean value of a Mascaret variable

        Mascaret Api :meth:`C_GET_BOOL_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param int i: first index of the Mascaret variable
        @param int j: second index of the Mascaret variable
        @param int k: third index of the Mascaret variable
        :return: scalar value
        :rtype: bool
        """
        val_c = ctypes.c_int()
        i_c = ctypes.c_int(i)
        j_c = ctypes.c_int(j)
        k_c = ctypes.c_int(k)
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        self.logger.debug('Getting {}...'.format(var_name))
        self.error = self.libmascaret.C_GET_BOOL_MASCARET(
            self.id_masc, var_name_c, i_c, j_c, k_c, ctypes.byref(val_c))
        self.logger.debug('Value: val={}.'.format(val_c.value))

        return val_c.value == 0

    def get_string(self, var_name, i=0, j=0, k=0):
        """Get the string value of a Mascaret variable

        Mascaret Api :meth:`C_GET_STRING_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param int i: first index of the Mascaret variable
        @param int j: second index of the Mascaret variable
        @param int k: third index of the Mascaret variable
        :return: scalar value
        :rtype: str
        """
        val_c = ctypes.POINTER(ctypes.c_char_p)()
        i_c = ctypes.c_int(i)
        j_c = ctypes.c_int(j)
        k_c = ctypes.c_int(k)
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        self.logger.debug('Getting {}...'.format(var_name))
        self.error = self.libmascaret.C_GET_STRING_MASCARET(
            self.id_masc, var_name_c, i_c, j_c, k_c, ctypes.byref(val_c))
        self.logger.debug('Value: val={}.'.format(ctypes.string_at(val_c)))

        return ctypes.string_at(val_c)

    def set_int(self, var_name, val, i=0, j=0, k=0):
        """Set the integer value of a Mascaret variable

        Mascaret Api :meth:`C_SET_INT_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param int val: scalar value to set
        @param int i: first index of the Mascaret variable
        @param int j: second index of the Mascaret variable
        @param int k: third index of the Mascaret variable
        """
        val_c = ctypes.c_int(val)
        i_c = ctypes.c_int(i)
        j_c = ctypes.c_int(j)
        k_c = ctypes.c_int(k)
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        self.logger.debug('Setting {}...'.format(var_name))
        self.error = self.libmascaret.C_SET_INT_MASCARET(
            self.id_masc, var_name_c, i_c, j_c, k_c, val_c)
        self.logger.debug('Value: val={}.'.format(val.value))

    def set_bool(self, var_name, val, i=0, j=0, k=0):
        """Set the boolean value of a Mascaret variable

        Mascaret Api :meth:`C_SET_BOOL_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param bool val: scalar value to set
        @param int i: first index of the Mascaret variable
        @param int j: second index of the Mascaret variable
        @param int k: third index of the Mascaret variable
        """
        val_c = ctypes.c_int(val)
        i_c = ctypes.c_int(i)
        j_c = ctypes.c_int(j)
        k_c = ctypes.c_int(k)
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        self.logger.debug('Setting {}...'.format(var_name))
        self.error = self.libmascaret.C_SET_BOOL_MASCARET(
            self.id_masc, var_name_c, i_c, j_c, k_c, val_c)
        self.logger.debug('Value: val={}.'.format(val.value))

    def set_string(self, var_name, val, i=0, j=0, k=0):
        """Set the string value of a Mascaret variable

        Mascaret Api :meth:`C_SET_STRING_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param str val: scalar value to set
        @param int i: first index of the Mascaret variable
        @param int j: second index of the Mascaret variable
        @param int k: third index of the Mascaret variable
        """
        i_c = ctypes.c_int(i)
        j_c = ctypes.c_int(j)
        k_c = ctypes.c_int(k)
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        val_c = ctypes.c_char_p(val.encode("utf-8"))
        self.logger.debug('Setting {}...'.format(var_name))
        self.error = self.libmascaret.C_SET_STRING_MASCARET(
            self.id_masc, var_name_c, i_c, j_c, k_c, val_c)
        self.logger.debug('Value: val={}.'.format(val))

    def set_double(self, var_name, val, i=0, j=0, k=0):
        """Set the real value of a Mascaret variable

        Mascaret Api :meth:`C_SET_DOUBLE_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param float val: scalar value to set
        @param int i: first index of the Mascaret variable
        @param int j: second index of the Mascaret variable
        @param int k: third index of the Mascaret variable
        """
        val_c = ctypes.c_int(val)
        i_c = ctypes.c_int(i)
        j_c = ctypes.c_int(j)
        k_c = ctypes.c_int(k)
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        self.logger.debug('Setting {}...'.format(var_name))
        self.error = self.libmascaret.C_SET_DOUBLE_MASCARET(
            self.id_masc, var_name_c, i_c, j_c, k_c, val_c)
        self.logger.debug('Value: val={}.'.format(val))

    def get_type_var(self, var_name):
        """Get the type of a Mascaret variable

        Use Mascaret Api :meth:`C_GET_TYPE_VAR_MASCARET`

        @param str var_name: name of the Mascaret variable
        :return: type, category, modifiable, dimension
        :rtype: str, str, int, int
        """
        var_name_c = ctypes.c_char_p(var_name.encode('utf-8'))
        var_type_c = ctypes.POINTER(ctypes.c_char_p)()
        category_c = ctypes.POINTER(ctypes.c_char_p)()
        acces_c = ctypes.c_int()
        var_dim_c = ctypes.c_int()

        self.logger.debug('Getting the type of {}...'.format(var_name))
        self.error = self.libmascaret.C_GET_TYPE_VAR_MASCARET(  \
                self.id_masc, var_name_c, ctypes.byref(var_type_c), \
                ctypes.byref(category_c), ctypes.byref(acces_c),\
                ctypes.byref(var_dim_c))

        return ctypes.string_at(var_type_c), ctypes.string_at(category_c), \
               acces_c.value, var_dim_c.value

    def get_var_size(self, var_name, index=0):
        """Get the size(s) of a Mascaret variable

        Use Mascaret Api :meth:`C_GET_TAILLE_VAR_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param int index: only for cross-sections, graphs, weirs, junctions, storage areas
        :return: sizes
        :rtype: int, int, int
        """
        var_name_c = ctypes.c_char_p(var_name.encode('utf-8'))

        index = ctypes.c_int(index)
        size1 = ctypes.c_int()
        size2 = ctypes.c_int()
        size3 = ctypes.c_int()
        self.logger.debug('Getting the size of {}...'.format(var_name))
        self.error = self.libmascaret.C_GET_TAILLE_VAR_MASCARET(
            self.id_masc, var_name_c, index, ctypes.byref(size1),
            ctypes.byref(size2), ctypes.byref(size3))
        self.logger.debug('size = {} {} {}.'
                          .format(size1.value, size2.value, size3.value))

        return size1.value, size2.value, size3.value

    def set_var_size(self, var_name, size1, size2, size3, index=0):
        """Set the size(s) of a Mascaret variable

        Use Mascaret Api :meth:`C_SET_TAILLE_VAR_MASCARET`

        @param str var_name: name of the Mascaret variable
        @param int size1, size2, size3: size values to set
        @param int index: only for cross-sections, graphs, weirs, junctions, storage areas
        """
        var_name_c = ctypes.c_char_p(var_name.encode('utf-8'))

        index = ctypes.c_int(index)
        size1_c = ctypes.c_int(size1)
        size2_c = ctypes.c_int(size2)
        size3_c = ctypes.c_int(size3)
        self.logger.debug('Setting the size of {}...'.format(var_name))
        self.error = self.libmascaret.C_SET_TAILLE_VAR_MASCARET(
            self.id_masc, var_name_c, index, size1_c,
            size2_c, size3_c)
        self.logger.debug('size = {} {} {}.'
                          .format(size1.value, size2.value, size3.value))

    def compute(self, t_0, t_end, time_step):
        """Direct computation of Mascaret

        Use Mascaret Api :meth:`C_CALCUL_MASCARET`.

        @param float t_0: initial time of the computation (s)
        @param float t_end: end time of the computation (s)
        @param float time_step: time step of the computation (s)
        """
        t0_c = ctypes.c_double(t_0)
        tend_c = ctypes.c_double(t_end)
        dt_c = ctypes.c_double(time_step)
        self.logger.debug('Running Mascaret... from {}'.format(t_0))
        self.error = self.libmascaret.C_CALCUL_MASCARET(self.id_masc, t0_c,\
            tend_c, dt_c, self.iprint)
        self.logger.debug('Running Mascaret... to {}'.format(t_end))

    def compute_bc(self, t_0, t_end, time_step, tab_timebc, nb_timebc,  \
                   nb_bc, tab_cl1, tab_cl2):
        """Indirect computation of Mascaret with a control on the boundary conditions

        Use Mascaret Api :meth:`C_CALCUL_MASCARET_CONDITION_LIMITE`.

        @param float t_0: initial time of the computation (s)
        @param float t_end: end time of the computation (s)
        @param float time_step: time step of the computation (s)
        @param float tab_timebc: array of time values for boundary conditions
        @param int nb_timebc: size of tab_timebc
        @param int nb_bc: total number of boundary conditions
        @param float tab_cl1: values of boundary conditions
        @param float tab_cl2: values of boundary conditions
        """
        t0_c = ctypes.c_double(t_0)
        tend_c = ctypes.c_double(t_end)
        dt_c = ctypes.c_double(time_step)
        nb_timebc_c = ctypes.c_int(nb_timebc)

        tab_timebc_c = (ctypes.c_double*nb_timebc)()
        for j in range(nb_timebc):
            tab_timebc_c[j] = tab_timebc[j]
            tab_cl1_c = (ctypes.POINTER(ctypes.c_double)*nb_bc)()
            tab_cl2_c = (ctypes.POINTER(ctypes.c_double)*nb_bc)()
            for i in range(nb_bc):
                tab_cl1_c[i] = (ctypes.c_double*nb_timebc)()
                tab_cl2_c[i] = (ctypes.c_double*nb_timebc)()
                for j in range(nb_timebc):
                    tab_cl1_c[i][j] = tab_cl1[j][i]
                    tab_cl2_c[i][j] = tab_cl2[j][i]

        self.logger.debug('Running Mascaret cl...from {}'.format(t_0))
        self.error = self.libmascaret.C_CALCUL_MASCARET_CONDITION_LIMITE(\
                 self.id_masc, t0_c,\
                 tend_c, dt_c, ctypes.byref(tab_timebc_c),\
                 nb_timebc_c, ctypes.byref(tab_cl1_c), ctypes.byref(tab_cl2_c),\
                 self.iprint)
        self.logger.debug('Running Mascaret cl...to {}'.format(t_end))

    def get_var_desc(self):
        """Get info on the Mascaret variables

        Use Mascaret Api :meth:`C_GET_DESC_VAR_MASCARET`

        :return: information on all the Mascaret variables ('Model' or 'State')
        :rtype: str, str, int
        """
        tab_name_c = ctypes.POINTER(ctypes.c_char_p)()
        tab_desc_c = ctypes.POINTER(ctypes.c_char_p)()
        size_c = ctypes.c_int()

        self.logger.info('Get var desc MASCARET...')
        self.error = self.libmascaret.C_GET_DESC_VAR_MASCARET(self.id_masc, \
                ctypes.byref(tab_name_c), ctypes.byref(tab_desc_c), \
                ctypes.byref(size_c))
        self.logger.info('Get var desc MASCARET done.')

        return ctypes.string_at(tab_name_c), ctypes.string_at(tab_desc_c), \
               size_c.value

    def version(self):
        """Version info wrapper

        Use Mascaret Api :meth:`C_VERSION_MASCARET`

        :return: Version X.Y.Z
        :rtype: str
        """
        v_c1 = ctypes.c_int()
        v_c2 = ctypes.c_int()
        v_c3 = ctypes.c_int()
        error = self.libmascaret.C_VERSION_MASCARET(\
                ctypes.byref(v_c1), ctypes.byref(v_c2), ctypes.byref(v_c3))
        if error != 0:
            return 'Version number could not be retrieved from MASCARET...'
        return str(v_c1.value) + '.' + str(v_c2.value) + '.' + str(v_c3.value)

    def import_xml(self, file_name, import_model):
        """Import Model or State of Mascaret from xml files

        Use Mascaret Api :meth:`C_IMPORT_XML`

        @param str file_name: name the xml file
        @param int import_model: flag to import Model or State
        """
        import_model_c = ctypes.c_int(import_model)
        file_name_c = ctypes.c_char_p(file_name.encode("utf-8"))

        self.logger.debug('Import XML...')
        self.error = self.libmascaret.C_IMPORT_XML( \
            self.id_masc, file_name_c, import_model_c)
        self.logger.debug('Import XML done.')

    def export_xml(self, file_name, description, export_model):
        """Export Model or State of Mascaret to xml files

        Use Mascaret Api :meth:`C_EXPORT_XML`

        @param str file_name: name the xml file
        @param int description:  flag to add info on variables
        @param int export_model: flag to export Model or State
        """
        export_model_c = ctypes.c_int(export_model)
        description_c = ctypes.c_int(description)
        file_name_c = ctypes.c_char_p(file_name.encode("utf-8"))

        self.logger.debug('Export XML...')
        self.error = self.libmascaret.C_EXPORT_XML( \
            self.id_masc, file_name_c, description_c, export_model_c)
        self.logger.debug('Export XML done.')

    def export_xml_saint_venant(self, file_name):
        """Export data for the SVT code

        Use Mascaret Api :meth:`C_EXPORT_XML_SAINT_VENANT`

        @param str file_name: name of the xml file
        """
        file_name_c = ctypes.c_char_p(file_name.encode("utf-8"))

        self.logger.debug('Export XML SAINT-VENANT...')
        self.error = self.libmascaret.C_EXPORT_XML_SAINT_VENANT( \
            self.id_masc, file_name_c)
        self.logger.debug('Export XML SAINT-VENANT done.')

    def open_tag_xml(self, file_name, unit, anchor):
        """Open xml file and root tag

        Use Mascaret Api :meth:`C_OUVERTURE_BALISE_XML`

        @param str file_name: name of the xml file
        @param int unit: logical unit
        @param str anchor: root tag name
        """
        file_name_c = ctypes.c_char_p(file_name.encode("utf-8"))
        anchor_c = ctypes.c_char_p(anchor.encode("utf-8"))
        unit_c = ctypes.c_int(unit)

        self.logger.debug('Open XML anchor...')
        self.error = self.libmascaret.C_OUVERTURE_BALISE_XML( \
            self.id_masc, file_name_c, unit_c, anchor_c)
        self.logger.debug('Open XML anchor done.')

    def export_var_xml(self, unit, var_name, description):
        """Export of a Mascaret variable to xml file

        Use Mascaret Api :meth:`C_EXPORT_VAR_XML`

        @param int unit: logical unit
        @param str var_name: name of the Mascaret variable
        @param int description: flag to add info of the variable
        """
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        unit_c = ctypes.c_int(unit)
        description_c = ctypes.c_int(description)

        self.logger.debug('Export variable in xml...')
        self.error = self.libmascaret.C_EXPORT_VAR_XML( \
        self.id_masc, unit_c, var_name_c, description_c)
        self.logger.debug('Export variable in xml done.')

    def export_uservar_xml(self, unit, var_name, var_type, description, \
                           var_val):
        """Export of user variable to xml file

        Use Mascaret Api :meth:`C_EXPORT_USERVAR_XML`.

        @param int unit: logical unit
        @param str var_name: name of the user variable
        @param str var_type: type of the user variable
        @param str description: info of the user variable
        @param str var_val: info to write on the xml tag
        """
        var_name_c = ctypes.c_char_p(var_name.encode("utf-8"))
        var_type_c = ctypes.c_char_p(var_type.encode("utf-8"))
        var_val_c = ctypes.c_char_p(var_val.encode("utf-8"))
        unit_c = ctypes.c_int(unit)
        description_c = ctypes.c_char_p(description.encode("utf-8"))

        self.logger.debug('Export user variable in xml...')
        self.error = self.libmascaret.C_EXPORT_USERVAR_XML( \
        self.id_masc, unit_c, var_name_c, var_type_c, description_c, var_val_c)
        self.logger.debug('Export user variable in xml done.')

    def close_tag_xml(self, unit, anchor):
        """Close xml file and root tag

        Use Mascaret Api :meth:`C_FERMETURE_BALISE_XML`

        @param int unit: logical unit
        @param str anchor: root tag name
        """
        anchor_c = ctypes.c_char_p(anchor.encode("utf-8"))
        unit_c = ctypes.c_int(unit)

        self.logger.debug('Close xml anchor...')
        self.error = self.libmascaret.C_FERMETURE_BALISE_XML( \
        self.id_masc, unit_c, anchor_c)
        self.logger.debug('Close xml anchor done.')

    def get_nb_cl(self):
        """Get the number of boundary conditions

        Use Mascaret Api :meth:`C_GET_NB_CONDITION_LIMITE_MASCARET`

        :return: the number of BC
        :rtype: int
        """
        nb_bc_c = ctypes.c_int()
        self.logger.debug('Getting the number of boundary conditions...')
        self.error = self.libmascaret.C_GET_NB_CONDITION_LIMITE_MASCARET(
            self.id_masc, ctypes.byref(nb_bc_c))
        self.logger.debug('Number of boundary conditions: {}.'\
                          .format(nb_bc_c.value))

        return nb_bc_c.value

    def get_name_cl(self, num_cl):
        """Get the names of boundary conditions

        Use Mascaret Api :meth:`C_GET_NOM_CONDITION_LIMITE_MASCARET`

        @param int num_cl: number of the boundary condition to consider
        :return: the number of BC and name
        :rtype: int, str
        """
        num_cl_c = ctypes.c_int(num_cl)
        name_all_bc = ctypes.POINTER(ctypes.c_char_p)()
        n_law = ctypes.c_int()
        self.error = self.libmascaret.C_GET_NOM_CONDITION_LIMITE_MASCARET(
            self.id_masc, num_cl_c, ctypes.byref(name_all_bc),\
            ctypes.byref(n_law))

        return n_law.value, ctypes.string_at(name_all_bc)

    def get(self, varname, i=0, j=0, k=0):
        """
        Get the value of a variable of Mascaret

        @param varname Name of the variable
        @param i index on first dimension
        @param j index on second dimension
        @param k index on third dimension

        :return: scalar value
        """
        value = None
        vartype, _, _, ndim = self.get_type_var(varname)
        dim1, dim2, dim3 = self.get_var_size(varname)

        # Checking that index are within bound
        if ndim >= 1:
            if not 0 <= i < dim1:
                raise Exception("i=%i is not within [0,%i]"%(i, dim1))
            index_i = i + 1
        else:
            index_i = 0

        if ndim >= 2:
            if not 0 <= j < dim2:
                raise Exception("j=%i is not within [0,%i]"%(i, dim2))
            index_j = j + 1
        else:
            index_j = 0

        if ndim == 3:
            if not 0 <= k < dim3:
                raise Exception("k=%i is not within [0,%i]"%(i, dim3))
            index_k = k + 1
        else:
            index_k = 0

        # Getting value depending on type
        if "DOUBLE" in vartype:
            value = self.get_double(varname, index_i, index_j, index_k)
        elif "INT" in vartype:
            value = self.get_int(varname, index_i, index_j, index_k)
        elif "STRING" in vartype:
            value = self.get_string(varname, index_i, index_j, index_k)
        elif "BOOL" in vartype:
            value = self.get_bool(varname, index_i, index_j, index_k)
        else:
            raise Exception("Unknown data type %s for %s"%(vartype, varname))

        return value

    def set(self, varname, value, i=0, j=0, k=0):
        """
        Set the value of a variable of Mascaret

        @param varname Name of the variable
        @param value to set
        @param i index on first dimension
        @param j index on second dimension
        @param k index on third dimension
        """
        vartype, _, readonly, ndim = self.get_type_var(varname)
        dim1, dim2, dim3 = self.get_var_size(varname)

        # Check readonly value
        if readonly != 0:
            raise Exception("Variable %s is readonly"%varname)

        # Checking that index are within bound
        if ndim >= 1:
            if not 0 <= i < dim1:
                raise Exception("i=%i is not within [0,%i]"%(i, dim1))
            index_i = i + 1
        else:
            index_i = 0

        if ndim >= 2:
            if not 0 <= j < dim2:
                raise Exception("j=%i is not within [0,%i]"%(i, dim2))
            index_j = j + 1
        else:
            index_j = 0
        if ndim == 3:
            if not 0 <= k < dim3:
                raise Exception("k=%i is not within [0,%i]"%(i, dim3))
            index_k = k + 1
        else:
            index_k = 0

        # Getting value depending on type
        if "DOUBLE" in vartype:
            self.set_double(varname, value, index_i, index_j, index_k)
        elif "INT" in vartype:
            self.set_int(varname, value, index_i, index_j, index_k)
        elif "STRING" in vartype:
            self.set_string(varname, value, index_i, index_j, index_k)
        elif "BOOL" in vartype:
            self.set_bool(varname, value, index_i, index_j, index_k)
        else:
            raise Exception("Unknown data type %s for %s"%(vartype, varname))