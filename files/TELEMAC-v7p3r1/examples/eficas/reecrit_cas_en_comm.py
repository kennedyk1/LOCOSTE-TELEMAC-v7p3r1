#!/usr/bin/env python
# -*- coding: utf-8 -*-
#            CONFIGURATION MANAGEMENT OF EDF VERSION
# ======================================================================
# COPYRIGHT (C) 1991 - 2002  EDF R&D                  WWW.CODE-ASTER.ORG
# THIS PROGRAM IS FREE SOFTWARE; YOU CAN REDISTRIBUTE IT AND/OR MODIFY
# IT UNDER THE TERMS OF THE GNU GENERAL PUBLIC LICENSE AS PUBLISHED BY
# THE FREE SOFTWARE FOUNDATION; EITHER VERSION 2 OF THE LICENSE, OR
# (AT YOUR OPTION) ANY LATER VERSION.
#
# THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT
# WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. SEE THE GNU
# GENERAL PUBLIC LICENSE FOR MORE DETAILS.
#
# YOU SHOULD HAVE RECEIVED A COPY OF THE GNU GENERAL PUBLIC LICENSE
# ALONG WITH THIS PROGRAM; IF NOT, WRITE TO EDF R&D CODE_ASTER,
#    1 AVENUE DU GENERAL DE GAULLE, 92141 CLAMART CEDEX, FRANCE.
#
#
# ======================================================================

"""
"""
# Modules Python
from __future__ import absolute_import
from __future__ import print_function

import sys,os
from os import path, listdir, system, chdir
import shutil
import re

# Modules Eficas
try:
  import Telemac.prefs
except:
  print("Add the path to eficas to PYTHONPATH")
if hasattr(Telemac.prefs,'encoding'):
   # Hack pour changer le codage par defaut des strings
   import sys
   reload(sys)
   sys.setdefaultencoding(prefs.encoding)
   del sys.setdefaultencoding
   # Fin hack


from InterfaceQT4 import eficas_go

from PyQt5.QtWidgets import QApplication

class bcolors:
        HEADER = '\033[95m'
        OKBLUE = '\033[94m'
        OKGREEN = '\033[92m'
        WARNING = '\033[93m'
        FAIL = '\033[91m'
        ENDC = '\033[0m'
        BOLD = '\033[1m'
        UNDERLINE = '\033[4m'

def clean_up_diff(cas_file, eficas_cas_file, tmp_diff):
    """
    Remove obsolete lines from diff
    """
    new_diff = []
    with open(tmp_diff,'r') as fle:
        for line in fle:
            if cas_file in line or \
               eficas_cas_file in line or\
               'mpirun' in line or \
               '---' in line or \
               re.match('[0-9]+(,[0-9]*)?[ca][0-9]+(,[0-9]*)?',line):
                continue
            new_diff.append(line)

    return new_diff


def validate_catalog(module, val_folder, rootDir, leger, lang=''):
    """
    """
    app = QApplication(sys.argv)
    print(" "*2,"~> For module",val_folder)
    examples_dir = path.join(rootDir,'examples',val_folder)
    output_dir = path.join(rootDir,'examples','eficas')

    crashed = []
    different = []
    for example in sorted(listdir(examples_dir)):
    #for example in ['Negretti2D']:
        example_dir = path.join(examples_dir,example)
        chdir(example_dir)
        for case in sorted(listdir(example_dir)):
            if case.endswith('.cas') and \
               "_reecrit" not in case and \
               case[0:3] == "t2d" and \
               "_reecrit" not in case and \
               "_ori" not in case:
                # Adding lang extension (.fr for translated french case)
                mycase = case + lang
                print(" "*6,"~> For test case ",mycase)

                root, ext = path.splitext(case)
                if lang != '':
                    ori = "_ori_fr"
                else:
                    ori = "_ori"
                ori_case = root + ori + ".cas"
                if leger:
                    eficas_case = root + ori +"_reecrit.Lcas"
                else:
                    eficas_case = root + ori +"_reecrit.cas"

                run_log = ori_case+".log"
                run_eficas_log = eficas_case+".log"
                tmp_diff_file = path.join(output_dir,"tmp_"+root+'.log')

                # Creating a temporary case file with &ETA at the end
                shutil.copyfile(mycase, ori_case)
                with open(ori_case,'a') as fle:
                    fle.write('\n&ETA\n')

                # Import and export in eficas
                try:
                    eficas_go.lance_eficas_ssIhm_reecrit(code='TELEMAC',
                        fichier = ori_case,
                        ou = '.',
                        cr=False,
                        leger=leger,
                        langue=lang[1:])
                except Exception as e:
                    print(e)
                    crashed.append(mycase)
                    print(" "*8+bcolors.FAIL+"FAILED"+bcolors.ENDC)
                    print(" "*8+"Crashed in eficas")
                    continue

                # Running original case
                cmd = "%s.py %s --use-link -w %s > %s"%(module, ori_case, ori_case+"_dir", run_log)
                system(cmd)

                # Running eficas case
                cmd = "%s.py %s --use-link -w %s > %s"%(module, eficas_case, eficas_case+"_dir", run_eficas_log)
                system(cmd)

                # Creating diff file
                cmd = "diff %s %s > %s"%(run_log, run_eficas_log, tmp_diff_file)
                system(cmd)

                # Cleanup of diff file
                new_diff = clean_up_diff(ori_case, eficas_case, tmp_diff_file)
                if new_diff != []:
                    different.append(case)
                    print(" "*8+bcolors.FAIL+"FAILED"+bcolors.ENDC)
                    print(" "*8+"Diff in steering case")
                    continue

                # Clean up of files
                os.remove(ori_case)
                os.remove(eficas_case)
                os.remove(run_log)
                os.remove(run_eficas_log)
                os.remove(tmp_diff_file)
                if os.path.exists("out_user_fortran"):
                    os.remove("out_user_fortran")
                shutil.rmtree(ori_case+"_dir")
                shutil.rmtree(eficas_case+"_dir")

                # Passed the test case
                print(" "*8+bcolors.OKGREEN+"PASSED"+bcolors.ENDC)

    if crashed != []:
        print("The following test in",val_folder," crashed in eficas:",crashed)
    if different != []:
        print("The following test in",val_folder," have a difference with normal run:",different)

if __name__ == "__main__":
    # Testing Telemac2d english test cases
    validate_catalog('telemac2d','telemac2d','/home/B61570/opentelemac/git/trunk', leger=False)
    #validate_catalog('telemac2d','telemac2d','/home/B61570/opentelemac/git/trunk', leger=True)

    # Testing Telemac2d french test cases
    # Need to have run validation first so translated cases are created
    #system("bash copy_fr_case.sh ~/opentelemac/git/trunk/examples/telemac2d")
    #validate_catalog('telemac2d','telemac2d','/home/B61570/opentelemac/git/trunk', False, lang='.fr')

    #validate_catalog('telemac2d','sisyphe','/home/B61570/opentelemac/git/trunk', False)
