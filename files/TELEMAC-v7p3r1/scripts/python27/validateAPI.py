#!/usr/bin/env python

from __future__ import print_function
import numpy as np
import os
import sys
import glob
import shutil
import argparse
import filecmp
from os import path, sep, walk, chdir, remove, environ, mkdir, \
               listdir, getcwd
from config import parseConfigFile
from mpi4py import MPI
# ~~> dependencies towards other pytel/modules
from utils.messages import MESSAGES, filterMessage, banner
from parsers.parserKeywords import scanCAS,readCAS,getKeyWord,setKeyValue,scanDICO,getIOFilesSubmit
from utils.files import getFileContent
from TelApy.api.t2d import Telemac2d

def run_telemac_api(cas, ncsize, user_fortran):
    """
    Running a cas using the api

    @param cas The name of the steering file
    @param ncsize Number of parallel processors
    @param ncsize Name of the user fortran None if none
    """
    cmd = "mpiexec -n {ncsize} template.py -i {cas} {fortran} > run.log"

    if user_fortran is not None:
        fortran = " -f "+user_fortran
    else:
        fortran = ''

    print(cmd.format(cas=cas, ncsize=ncsize, fortran=fortran))
    os.system(cmd.format(cas=cas, ncsize=ncsize, fortran=fortran))

    passed = False
    with open('run.log','r') as f:
        for line in f.readlines():
            if "My work is done" in line:
                passed = True

    return passed

def run_telemac_normal(cas, ncsize):
    """
    Normale run of telemac

    @param cas The name of the steering file
    @param ncsize Number of parallel processors
    """
    cmd = 'telemac2d.py --ncsize='+str(ncsize)+' '+cas+' > run.log'
    print(cmd)
    os.system(cmd)

    passed = False
    with open('run.log','r') as f:
        for line in f.readlines():
            if "My work is done" in line:
                passed = True

    return passed

def process_config(config_name, config_file, root_dir):
    """
       Main function

       :param: config_name Name of the telemac configuration
       :param: config_file Name of the configuration file
       :param: root_dir Path to the root folder of telemac
    """

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Environment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # path to the root
    hometel = ''
    if 'HOMETEL' in environ:
        hometel = environ['HOMETEL']
    if root_dir == '':
        root_dir = hometel
    # user configuration name
    usetelcfg = ''
    if 'USETELCFG' in environ:
        usetelcfg = environ['USETELCFG']
    if config_name == '':
        config_name = usetelcfg
    # user configuration file
    systelcfg = path.join(hometel, 'configs')
    if 'SYSTELCFG' in environ:
        systelcfg = environ['SYSTELCFG']
    if config_file != '':
        systelcfg = config_file
    if path.isdir(systelcfg):
        systelcfg = path.join(systelcfg, 'systel.cfg')
    config_file = systelcfg

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Works for all configurations unless specified ~~~~~~~~~~~~~~~
    if not path.isfile(config_file):
        print( '\nNot able to get to the configuration file: '\
              + config_file + '\n' )
        dircfg = path.abspath(path.dirname(config_file))
        if path.isdir(dircfg):
            print( ' ... in directory: ' + dircfg + '\n ... use instead: ' )
            _, _, filenames = walk(dircfg).next()
            for fle in filenames:
                _, tail = path.splitext(fle)
                if tail == '.cfg':
                    print( '    +> '+ fle )
        raise Exception('Error in configuration file')

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Reporting errors ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    xcptss = MESSAGES()
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Works for all configurations unless specified ~~~~~~~~~~~~~~~
    cfgs = parseConfigFile(config_file, config_name)

    for cfgname in cfgs:
        # still in lower case
        if 'root' not in cfgs[cfgname]:
            cfgs[cfgname]['root'] = root_dir
        # parsing for proper naming
        #cfg = parseConfig_CompileTELEMAC(cfgs[cfgname])
    return xcptss, root_dir

def copy_file_to_tmp(test_dir, tmp_dir, module, root_dir):
    """
       Copy all the files needed by the test case into the temporary folder

       :param: path to the test case to validate
    """

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    if not path.exists(tmp_dir):
        mkdir(tmp_dir)
    else:
        shutil.rmtree(tmp_dir)
        mkdir(tmp_dir)
    chdir(tmp_dir)

    # Getting list on input/output files from the dictionary
    dicoFile = path.join(root_dir,'sources', module, module+'.dico')
    frgb,dico = scanDICO(dicoFile)
    iFS,oFS = getIOFilesSubmit(frgb,dico)
    # Getting list of steering file
    casFilesPath = glob.glob(test_dir +sep+'*.cas')

    list_file = []
    for casFile in casFilesPath:
        shutil.copyfile(casFile,path.basename(casFile))
        cas = readCAS(scanCAS(getFileContent(casFile)),dico,frgb)
        user_fortran = None
        # Looping on input files
        for key in iFS:
            value,defaut = getKeyWord(key,cas,dico,frgb)
            if value != []:
                ffile=value[0].strip("'")
                # if we have a user fortran
                if 'FORTRAN' in key:
                    if path.exists(path.join(tmp_dir, ffile)):
                        shutil.rmtree(path.join(tmp_dir, ffile))
                    user_fortran = ffile
                    shutil.copytree(test_dir+sep+ffile,ffile)
                else:
                    shutil.copyfile(test_dir+sep+ffile,ffile)
        list_file.append((path.basename(casFile),user_fortran))
    return list_file

def get_result_file_name(Cas):
    """
       Returns the name of the result file for a given case

       :param: name of the telemac steering file
    """
    dicoFile = path.join(environ['HOMETEL'],'sources', 'telemac2d','telemac2d.dico')
    frgb,dico = scanDICO(dicoFile)
    _,oFS = getIOFilesSubmit(frgb,dico)
    cas = readCAS(scanCAS(getFileContent(Cas)),dico,frgb)
    value,defaut = getKeyWord('RESULTS FILE',cas,dico,frgb)
    res_file = value[0].strip("'")
    return res_file

def main(configName, configFile, validationFolder, example, nncsize, clean):
# Running main function
    XCPTS, root_dir = process_config(configName, configFile, '')

    if path.exists('ValidationTelApy.log'):
        remove('ValidationTelApy.log')
    fichier = open('ValidationTelApy.log','a')
    fichier.write("-----Listing Validation TelApy-------\n")

    if validationFolder == 'telemac2d':
        module = validationFolder
        fichier.write("-- For module " + module + "\n")
        module_dir = path.join(root_dir, 'examples', module)
        list_test_case = []
        if example != '':
            list_test_case.append(example)
        else:
            list_test_case = sorted(listdir(module_dir))
        # Sequential only test_case
        seq_only = []
        seq_only.append('t2d_hydraulic_jump_v1p0.cas')
        seq_only.append('t2d_hydraulic_jump_v2p0.cas')
        seq_only.append('t2d_wesel.cas')
        seq_only.append('t2d_wesel_pos.cas')
        seq_only.append('t2d_delwaq.cas')
        seq_only.append('t2d_ruptmoui.cas')
        seq_only.append('t2d_triangular_shelf.cas')
        seq_only.append('t2d_island.cas')
        seq_only.append('t2d_tide-jmj_real_gen.cas')
        seq_only.append('t2d_tide-jmj_type_gen.cas')
        seq_only.append('t2d_dambreak_v1p0.cas')
        # Test case that can not work with api
        skip_test = []
        # Using homere_adj not handle by api
        skip_test.append('estimation')
        # Reruning telemac from homere not handled by api
        skip_test.append('convergence')
        # Case that are not run by validation
        skip_test.append('t2d_tide-jmj_type_med.cas')
        skip_test.append('t2d_tide-ES_real.cas')
        for i,test_case in enumerate(list_test_case):
            if test_case in skip_test:
                continue
            case_dir = path.join(module_dir,test_case)
            tmp_dir = path.join(case_dir,'tmp')
            print( "<"str(i+1)+"/"+str(len(list_test_case))+'> '+str(test_case))
            fichier.write('Running test case '+test_case+'\n')
            list_file = copy_file_to_tmp(case_dir, tmp_dir, module, root_dir)

            chdir(tmp_dir)

            for cas,fortran in list_file:
                #
                # Running Telemac based on TelApy
                #
                if cas in skip_test:
                    continue
                # Get results names
                res_file = get_result_file_name(cas)
                api_res_file = res_file+'_api'

                # Running in sequential mode if the case does not run in parallel
                if cas in seq_only:
                    ncsize = 1
                else:
                    ncsize = nncsize
                passed_api = run_telemac_api(cas, ncsize, fortran)

                if passed_api:
                    shutil.move(res_file, api_res_file)
                # Running Telemac classical way
                #
                passed_normal = run_telemac_normal(cas, ncsize)

                #
                # Result comparison between api and classical Telemac computation
                #
                if not passed_normal:
                    fichier.write('   Normal run crashed\n')
                if not passed_api:
                    fichier.write('   Api run crashed\n')
                if not passed_api or not passed_normal:
                    fichier.write(str(cas)+'                       FAILED'+'\n')
                    continue
                # TODO: is test still usefull ?
                if not path.exists(res_file):
                    fichier.write('   Missing '+res_file+"\n")
                    fichier.write(str(cas)+'                       FAILED'+'\n')
                    continue
                if not path.exists(api_res_file):
                    fichier.write('   Missing '+api_res_file+"\n")
                    fichier.write(str(cas)+'                       FAILED'+'\n')
                    continue
                compare = filecmp.cmp(res_file, api_res_file)

                if compare:
                    fichier.write(str(cas)+'                       PASSED'+'\n')
                else:
                    fichier.write(str(cas)+'                       FAILED'+'\n')

            if clean:
                chdir(module_dir+sep+test_case)
                shutil.rmtree(module_dir+sep+test_case+sep+'tmp')

        fichier.write('my work is done '+'\n')

if __name__ == "__main__":
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~ Reads config file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    print( '\n\nLoading Options and Configurations\n'+72*'~'+'\n' )
    PARSER = argparse.ArgumentParser(\
        description='Make the validation of Telemac-Mascaret API '\
            'and/or executable using the API')
    PARSER.add_argument(\
        "-c", "--configname",
        dest='configName',
        default="",
        help="specify configuration name, default is randomly \
                    found in the configuration file")
    PARSER.add_argument(\
        "-f", "--configfile",
        dest='configFile',
        default="",
        help="specify configuration file, default is systel.cfg")
    PARSER.add_argument(\
        "-v", "--valdir",
        dest='validationFolder',
        default="telemac2d",
        help="specify the folder to validate")
    PARSER.add_argument(\
        "--clean",
        action="store_true",
        dest="clean",
        default=False,
        help="Remove tmp folders" )
    PARSER.add_argument(\
        "-n", "--cnsize",
        dest='ncsize',
        default=4,
        help="specify the number of processor the test case will be run with")
    PARSER.add_argument(\
        "-e", "--example",
        dest='example',
        #            default="gouttedo",
        default="",
        help="specify the name of the test case to compute")
    ARGS = PARSER.parse_args()
    main(ARGS.configName, ARGS.configFile, ARGS.validationFolder,
         ARGS.example, ARGS.ncsize, ARGS.clean)

