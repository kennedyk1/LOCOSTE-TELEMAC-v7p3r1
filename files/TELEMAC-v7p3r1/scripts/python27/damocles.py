#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""@author Yoann Audouin

   @note ... this work is based on a collaborative effort between
  .________.                                                          ,--.
  |        |                                                      .  (  (
  |,-.    /   HR Wallingford                EDF - LNHE           / \_ \_/ .--.
  /   \  /    Howbery Park,                 6, quai Watier       \   )   /_   )
   ,.  `'     Wallingford, Oxfordshire      78401 Cedex           `-'_  __ `--
  /  \   /    OX10 8BA, United Kingdom      Chatou, France        __/ \ \ `.
 /    `-'|    www.hrwallingford.com         innovation.edf.com   |    )  )  )
!________!                                                        `--'   `--

   @history 15/02/2013 -- Y. Audouin
         Adding the file in pytel

   @brief Scripts to Manipulate the dictionary using damocles
"""
# _____          ___________________________________________________
# ____/ Imports /__________________________________________________/
#
# ~~> dependencies towards standard python
import sys
from os import remove, walk, environ, path
from argparse import ArgumentParser,RawDescriptionHelpFormatter
import re
# ~~> dependencies towards the root of pytel
from config import parseConfigFile,parseConfig_ValidateTELEMAC
# ~~> dependencies towards other pytel/modules
from utils.messages import MESSAGES
from utils.files import getFileContent
# _____             ________________________________________________
# ____/ MAIN CALL  /_______________________________________________/
#
__author__ = "Yoann Audouin"
__date__ = "$21-Sep-2012 16:51:09$"

def eficas_translation(ts_file, new_ts_file, lang):
    """
    Apllying modification to the translation file for eficas

    param ts_file The ts_file generated by damocles
    param new_ts_file The modified one
    """
    dicoCataToLabel={}
    dicoCataToTelemac={}
    header  = '<?xml version="1.0" encoding="utf-8"?>'
    header +='<!DOCTYPE TS><TS version="1.1" language="'+lang+'">'
    header +='<context>\n'
    header +='    <name>@deafult</name>\n'

    end ='</context>\n</TS>\n'

    pattern_In=re.compile(r'^\s*<source>(?P<ident>.*)</source>\s*$')
    pattern_Out=re.compile(r'^\s*<translation>(?P<traduit>.*)</translation>\s*$')
    pattern_In2=re.compile(r'^\s*<source2>(?P<ident>.*)</source2>\s*$')
    pattern_Out2=re.compile(r'^\s*<translation2>(?P<traduit>.*)</translation2>\s*$')
    listeMaj=[]
    listeMaj.append(('for h','for H'))
    listeMaj.append(('pour h','pour H'))
    listeMaj.append(('for u','for U'))
    listeMaj.append(('pour u','pour U'))
    listeMaj.append(('of k','of K'))
    listeMaj.append(('de k','de K'))
    listeMaj.append(('of h','of H'))
    listeMaj.append(('de h','de H'))
    listeMaj.append(('u and v','U and V'))
    listeMaj.append(('u et v','U et V'))
    listeMaj.append(('on h','on H'))
    listeMaj.append(('sur h','sur H'))
    listeMaj.append(('supg','SUPG'))
    listeMaj.append(('k and epsilon','K and Epsilon'))
    listeMaj.append(('k-epsilon','K-Epsilon'))
    listeMaj.append(('gmres','GMRES'))
    listeMaj.append(('cgstab','CGSTAB'))
    listeMaj.append(('q(z)','Q(Z)'))
    listeMaj.append(('z(q)','Z(Q)'))
    listeMaj.append(('wgs84','WGS84'))
    listeMaj.append(('wgs84','UTM'))
    listeMaj.append(('n-scheme','N-Scheme'))
    listeMaj.append(('scheme n','Scheme N'))
    listeMaj.append(('psi-scheme','PSI-Scheme'))
    listeMaj.append((' psi',' PSI'))
    listeMaj.append(('f(t90)','F(T90)'))
    listeMaj.append(('(pa)','(Pa)'))
    listeMaj.append(('h clipping','H clipping'))
    listeMaj.append(('delwaq','DELWAQ'))
    listeMaj.append(('tomawac','TOMAWAC'))
    listeMaj.append(('chezy','CHEZY'))
    listeMaj.append(('hllc','HLLC'))
    listeMaj.append(('c-u','C-U'))
    listeMaj.append(('c,u,v','C,U,V'))
    listeMaj.append(('h,u,v','H,U,V'))
    listeMaj.append(('previmer','PREVIMER'))
    listeMaj.append(('fes20xx','FES20XX'))
    listeMaj.append(('legos-nea','LEGOS-NEA'))
    listeMaj.append(('tpxo','TPXO'))
    listeMaj.append((' x',' X'))
    listeMaj.append((' y',' Y'))
    listeMaj.append(('waf','WAF'))
    listeMaj.append(('(w/kg)','(W/kg)'))
    listeMaj.append(('(j/kg)','(W/kg)'))
    listeMaj.append(('zokagoa','Zokagoa'))
    listeMaj.append(('nikuradse','Nikuradse'))
    listeMaj.append(('froude','Froude'))
    listeMaj.append(('gauss','Gauss'))
    listeMaj.append(('seidel','Seidel'))
    listeMaj.append(('leo','Leo'))
    listeMaj.append(('postma','Postma'))
    listeMaj.append(('crout','Crout'))
    listeMaj.append(('okada','Okada'))
    listeMaj.append(('jmj','JMJ'))
    listeMaj.append(('haaland','HAALAND'))
    listeMaj.append(('grad(u)','grad(U)'))
    listeMaj.append(('variable z','variable Z'))
    listeMaj.append(('variable r','variable R'))
    listeMaj.append(('ascii','ASCII'))

    with open(ts_file, 'r') as f:
        for ligne in f.readlines():
         if pattern_In.match(ligne):
            m = pattern_In.match(ligne)
            ident = m.group('ident')
         if pattern_Out.match(ligne):
            m = pattern_Out.match(ligne)
            traduit = m.group('traduit')
            dicoCataToTelemac[ident] = traduit
            traduitMin = traduit.lower()
            for t in listeMaj :
               traduit = traduitMin.replace(t[0], t[1])
               traduitMin = traduit
            chaine = traduitMin[0].upper() + traduitMin[1:]
            dicoCataToLabel[ident] = chaine
         if pattern_In2.match(ligne):
            m = pattern_In2.match(ligne)
            ident = m.group('ident')
         if pattern_Out2.match(ligne):
            m = pattern_Out2.match(ligne)
            traduit = m.group('traduit')
            dicoCataToTelemac[ident] = traduit
            dicoCataToLabel[ident] = traduit

    with open(new_ts_file, 'w') as f:
        f.write(header)
        for k in dicoCataToTelemac :
            text = "    <message>\n        <source>"
            text += k
            text += "</source>\n        <translation>"
            text += dicoCataToLabel[k]
            text += "</translation>\n    </message>\n"
            f.write(text)
        f.write(end)


def runDamocles(exePath,paramFile,logFile=''):
   """
      Running the damocles executable
      param exePath Path the damocles executable
      param paramFile Path to the input aprameters file
      param logFile Redirecting ouput to that file if present
   """
   if not path.exists(exePath):
      print( "You need to compile damocles to use it..." )
      sys.exit(1)
   # Run Fortran program
   mes = MESSAGES(size=10)
   # TODO: Error handling when damocles crashes
   try:
      if logFile == '':
         print( "%s < %s " % (exePath,paramFile) )
         tail, code = mes.runCmd("%s < %s" % (exePath,paramFile), False)
      else:
         print( "%s < %s > %s" % (exePath,paramFile,logFile) )
         tail, code = mes.runCmd("%s < %s > %s" % (exePath,paramFile,logFile), False)
   except OSError as exc:
      print( repr(exc.message) )
      sys.exit(1)
   if code !=0:
      raise Exception([
            {'name':'damocles',
             'msg':'Could not execute damocles'\
                   +'\n\nHere is the log:\n'
                   +'\n'.join(getFileContent(logFile))
            }])

def genDump(exePath,inputDict,outputDict):
   """
      Run damocles to generate a reordered dictionary
      param exePath Path to the damocles executable
      param inputDict Input Telemac dictionary
      param ouputDict Resorted dictionary
   """
   paramFile = path.join(path.dirname(inputDict),'damo.par')
   with open(paramFile,'w') as f:
      f.write('DUMP'+'\n')
      f.write(inputDict+'\n')
      f.write(outputDict)
   runDamocles(exePath, paramFile)
   remove(paramFile)

def genCata(codeName,exePath,inputDict,inputDep,cataName,enumName,tsPath):
   """
      Run damocles to generate an eficas catalogue
      param exePath Path to the damocles executable
      param inputDict Input Telemac dictionary
      param inputDep Input Telemac depnedancies file
      param cataName Name of the eficas Catalogue
      param enumName Name of the enum for CHOIX
      param tsPath Path for where the ts file will be generated
   """
   paramFile = path.join(path.dirname(inputDict),'damo.par')
   with open(paramFile,'w') as f:
      f.write('CATA'+'\n')
      f.write(codeName+'\n')
      f.write(inputDict+'\n')
      f.write(inputDep+'\n')
      f.write(cataName+'\n')
      f.write(enumName+'\n')
      f.write(tsPath)
   # Removing files if they exist
   if path.exists(cataName):
       remove(cataName)
   if path.exists(enumName):
       remove(enumName)
   if path.exists(tsPath+path.sep+"labelCataToIhm_en.ts"):
       remove(tsPath+path.sep+"labelCataToIhm_en.ts")
   if path.exists(tsPath+path.sep+"labelCataToIhm_fr.ts"):
       remove(tsPath+path.sep+"labelCataToIhm_fr.ts")

   runDamocles(exePath, paramFile)
   # Running modification on the ts files
   eficas_translation(path.join(tsPath,"cata_name2eng_name.ts"),
                      path.join(tsPath,"labelCataToIhm_en.ts"), "en")
   eficas_translation(path.join(tsPath,"cata_name2fra_name.ts"),
                      path.join(tsPath,"labelCataToIhm_fr.ts"), "fr")
   remove(path.join(tsPath,"cata_name2eng_name.ts"))
   remove(path.join(tsPath,"cata_name2fra_name.ts"))
   remove(paramFile)

def genLatex(exePath,inputDict,latexName,lng):
   """
      Run damocles to generate an LaTeX file for the reference manual
      param exePath Path to the damocles executable
      param inputDict Input Telemac dictionary
      param latexName Name of the LaTeX file
      param lng Language of the documentation
   """
   paramFile = path.join(path.dirname(inputDict),'damo.par')
   with open(paramFile,'w') as f:
      f.write('LATEX'+'\n')
      f.write(inputDict+'\n')
      f.write(latexName+'\n')
      f.write(lng)
   runDamocles(exePath, paramFile)
   remove(paramFile)

def main():
   """
      Main program for the execution of damocles
   """
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~ Reads config file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   print( '\n\nLoading Options and Configurations\n'+'~'*72+'\n' )
   parser = ArgumentParser()
   parser.add_argument("-c", "--configname",
                 dest="configName",
                 default='',
                 help="specify configuration name, default is the "\
                     "first found in the configuration file" )
   parser.add_argument("-f", "--configfile",
                 dest="configFile",
                 default='',
                 help="specify configuration file, "\
                     "default is systel.cfg" )
   parser.add_argument("-r", "--root_dir",
                 dest="root_dir",
                 default='',
                 help="specify the root, default is "\
                     "taken from config file" )
   parser.add_argument("-m", "--modules",
                 dest="modules",
                 default='',
                 help="specify the list modules, default is "\
                     "taken from config file" )
   parser.add_argument("--dump",
                 action="store_true",
                 dest="dump",
                 default=False,
                 help="Will dump a reformated dictionary" )
   parser.add_argument("--eficas",
                 action="store_true",
                 dest="eficas",
                 default=False,
                 help="Will generate the eficas Catalogue from the dictionary" )
   parser.add_argument("--latex",
                 action="store_true",
                 dest="latex",
                 default=False,
                 help="Will generate the LaTeX file for the reference manual" )

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Environment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   args = parser.parse_args()
   # path to the root
   PWD = path.dirname(path.dirname(path.dirname(sys.argv[0])))
   if args.root_dir != '': PWD = args.root_dir
   # The path to the python scripts is defined by the script launched
   PYT = path.dirname(__file__)
   # user configuration name
   USETELCFG = ''
   if 'USETELCFG' in environ: USETELCFG = environ['USETELCFG']
   if args.configName == '': args.configName = USETELCFG
   # user configuration file
   SYSTELCFG = path.join(PWD,'configs')
   if 'SYSTELCFG' in environ: SYSTELCFG = environ['SYSTELCFG']
   if args.configFile != '': SYSTELCFG = args.configFile
   if path.isdir(SYSTELCFG): SYSTELCFG = path.join(SYSTELCFG,'systel.cfg')
   args.configFile = SYSTELCFG

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Works for all configurations unless specified ~~~~~~~~~~~~~~~
   if not path.isfile(args.configFile):
      print( '\nNot able to get to the configuration file: %s\n' % \
           args.configFile )
      dircfg = path.abspath(path.dirname(args.configFile))
      if path.isdir(dircfg) :
         print( ' ... in directory: ' + dircfg + '\n ... use instead: ' )
         _, _, filenames = walk(dircfg).next()
         for fle in filenames:
            _, tail = path.splitext(fle)
            if tail == '.cfg' :
               print( '    +> '+ fle )
      sys.exit(1)

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Works for all configurations unless specified ~~~~~~~~~~~~~~~
   cfgs = parseConfigFile(args.configFile, args.configName)
   cfgname = cfgs.iterkeys().next()
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   # Defining which modules to use
   if args.modules is '':
      moduleList = ['artemis','postel3d','stbtel','sisyphe',
                   'telemac2d','telemac3d','tomawac','waqtel']
   else:
      moduleList = args.modules.split(';')
   # Identify Root value
   if 'root' not in cfgs[cfgname]: cfgs[cfgname]['root'] = PWD
   cfgs[cfgname]['pytel'] = PYT
   if args.root_dir != '':
      cfgs[cfgname]['root'] = path.abspath(args.root_dir)
      root = path.abspath(args.root_dir)
   else :
      root = cfgs[cfgname]['root']
   cfg = parseConfig_ValidateTELEMAC(cfgs[cfgname])
   exePath = path.join(root,'builds',cfgname,\
             'bin','damocles'+\
             cfg['SYSTEM']['sfx_exe'])
   # Looping on all modules
   for module in moduleList:
      modulePath = path.join(root,
                             'sources',
                             module)
      if(args.dump):
         inputDict = path.join(modulePath, module+".dico")
         outputDict = path.join(modulePath, module+"2.dico")
         genDump(exePath, inputDict, outputDict)

      if(args.eficas):
         inputDict = path.join(modulePath,
                               module+".dico")
         inputDep = path.join(modulePath,
                               module+".dico.dep")
         fancyModule = module[0].upper()+module[1:]
         cataName = path.join(modulePath,
                              'eficas',
                              fancyModule+"_cata_auto.py")
         enumName = path.join(modulePath,
                              'eficas',
                              'enum_'+fancyModule+"_auto.py")
         tsPath = path.join(modulePath,
                              'eficas')
         genCata(module.upper(), exePath, inputDict, inputDep, cataName, \
                 enumName, tsPath+path.sep)

      if(args.latex):
         inputDict = path.join(modulePath, module+".dico")
         latexName = path.join(root,'documentation',module,'reference',\
                               'latex','Corpus.tex')
         # English only
         lng = '2'
         genLatex(exePath, inputDict, latexName, lng)

# ~~~~ Compile the valiation documentation

   print( '\n\n'+'~'*72 )

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Jenkins' success message ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   print( '\n\nMy work is done\n\n' )

   sys.exit(0)

if __name__ == "__main__":
    main()