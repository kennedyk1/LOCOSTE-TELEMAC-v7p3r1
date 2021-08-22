"""@author Christophe Coulet
"""

"""@note ...

       _,^>,_            ARTELIA
    ,</   -._`           6 rue de Lorraine
  <%/        `*>         38130 Echirolles
                         France
A  R  T  E  L  I  A      www.arteliagroup.com

"""
"""@history 27/06/2017 -- Christophe Coulet:
         Creation of parser of XCAS file
         Return the list of Mascaret Input File
   
   @history 20/07/2017 -- Christophe Coulet:
         Rename the parser which become parserMascaret
         Adding capabilities to read Opthyca and Rubens results
"""

"""@brief
"""

# _____          ___________________________________________________
# ____/ Imports /__________________________________________________/
#
# ~~> dependencies towards standard python
import xml.etree.ElementTree as ET
import numpy as np
import sys
from struct import unpack
# ~~> dependencies towards other pytel/modules


def scan_xcas(file):
    """
    @brief : read the xml file to extract the list of input file
    :param file: xcas file of mascaret computation
    :return: list of file needed for computation
    """
    inputfile=[]
    tree = ET.parse(file)
    root = tree.getroot()
    root2 = root[0]

    # looking for geometry
    inputfile.append(root2.find('parametresGeometrieReseau').find('geometrie').find('fichier').text)

    # looking for laws
    lois = root2.find('parametresLoisHydrauliques').find('lois')
    for loi in lois:
        inputfile.append(loi.find('donnees').find('fichier').text)

    #looking for initial conditions
    linits = root2.find('parametresConditionsInitiales').find('ligneEau')
    if linits.find('LigEauInit').text == 'true':
        inputfile.append(linits.find('fichLigEau').text)

    #looking for "casier"
    if root2.find('parametresCasier') is not(None):
        inputfile.append((root2.find('parametresCasier').find('fichierGeomCasiers').text))

    return inputfile


def lit_header_opt(resultfile):
    """
    @brief : read the header of an opthyca result file
    :param resultfile: opthyca result file
    :return: liste of variables available (name, short name, unit, indicator)
    """
    var_liste=[]

    try:
        line = resultfile.readline()
        pass
    except:
        print("\n\nlit_header_opt: Wrong file format\n\n")
        return

    if '[variables]' not in line:
        print("\n\nlit_header_opt: Wrong first line\n\n")
        return

    line = resultfile.readline()
    while '[resultats]' not in line:
        var_liste.append(line.split(';',-1))
        line = resultfile.readline()


    return var_liste


def lit_res_opt(file):
    """
    @brief : read the opthyca result file
    :param file: opthyca result file
    :return: liste of time, reach, section and PK available and values
    """
    time_res=[]
    reach_idx=[]
    section_idx=[]
    section_pk=[]

    rf = open(file, 'r')
    varliste = lit_header_opt(rf)
    lines = rf.readlines()
    for line in lines:
        t, r, s1, s2, w = line.split(';', 4)
        if t not in time_res:
            time_res.append(t)
        if r not in reach_idx:
            reach_idx.append(r)
        if s1 not in section_idx:
            section_idx.append(s1)
        if s2 not in section_pk:
            section_pk.append(s2)
    rf.close()
    return time_res, reach_idx, section_idx, section_pk


def getEndianFromChar(f,nchar):
   pointer = f.tell()
   endian = ">"       # "<" means little-endian, ">" means big-endian
   l,c,chk = unpack(endian+'i'+str(nchar)+'si',f.read(4+nchar+4))
   if chk!=nchar:
      endian = "<"
      f.seek(pointer)
      l,c,chk = unpack(endian+'i'+str(nchar)+'si',f.read(4+nchar+4))
   if l!=chk:
      print( '... Cannot read '+str(nchar)+' characters from your binary file' )
      print( '     +> Maybe it is the wrong file format ?' )
      sys.exit(1)
   f.seek(pointer)
   return endian


def lit_res_rub(file):
    """
    @brief : read the rubens result file
    :param file: rubens result file
    :return: liste of time, reach, section and PK available and values
    """

    rf = open(file, 'rb')
    ftype = getEndianFromChar(rf, 72)

    l, titre, chk = unpack(ftype + 'i72si', rf.read(4 + 72 + 4))
    l, titre, chk = unpack(ftype + 'i72si', rf.read(4 + 72 + 4))
    l, titre, chk = unpack(ftype + 'i72si', rf.read(4 + 72 + 4))
    l, clu, chk = unpack(ftype + 'i4si', rf.read(4 + 4 + 4))
    l, clu, chk = unpack(ftype + 'i4si', rf.read(4 + 4 + 4))
    l, cfin, chk = unpack(ftype + 'i4si', rf.read(4 + 4 + 4))
    l, nbief1, nbief2, chk = unpack(ftype + 'iiii', rf.read(4 + 4 + 4 + 4))

    orig_bief = []
    for _ in range(nbief1):
        l, ilu, chk = unpack(ftype + 'iii', rf.read(4 + 4 + 4))
        orig_bief.append(ilu)
    fin_bief = []
    for _ in range(nbief1):
        l, ilu, chk = unpack(ftype + 'iii', rf.read(4 + 4 + 4))
        fin_bief.append(ilu)

    nomvar_indep = []
    l, clu, chk = unpack(ftype + 'i4si', rf.read(4 + 4 + 4))
    while clu != cfin:
        nomvar_indep.append(clu)
        l, clu, chk = unpack(ftype + 'i4si', rf.read(4 + 4 + 4))
    l, nsto1, nsto2, chk = unpack(ftype + 'iiii', rf.read(4 + 4 + 4 + 4))

    valvar_indep = []
    for ivar in enumerate(nomvar_indep):
        rf.seek(4,1)
        varlu = np.array(unpack(ftype+str(nsto1)+'f', rf.read(nsto1 * 4)))
        rf.seek(4,1)
        valvar_indep.append(varlu)

    nomvar_dep = []
    l, clu, chk = unpack(ftype + 'i4si', rf.read(4 + 4 + 4))
    while clu != cfin:
        nomvar_dep.append(clu)
        l, clu, chk = unpack(ftype + 'i4si', rf.read(4 + 4 + 4))

    itemps = []
    temps = []
    valvar_dep = []
    while True:
        try:
            l, ilu, ilu, chk = unpack(ftype + 'iiii', rf.read(4 + 4 + 4 + 4))
            itemps.append(ilu)
            rf.seek(4,1)
            flu, flu = unpack(ftype+'ff', rf.read(4 + 4))
            temps.append(flu)
            rf.seek(4,1)
            l, nsto1, nsto2, chk = unpack(ftype + 'iiii', rf.read(4 + 4 + 4 + 4))
            for ivar in enumerate(nomvar_dep):
                rf.seek(4,1)
                varlu = np.array(unpack(ftype+str(nsto1)+'f', rf.read(nsto1 * 4)))
                rf.seek(4,1)
                valvar_dep.append(varlu)
        except:
            break

    rf.close()

    return


# _____             ________________________________________________
# ____/ MAIN CALL  /_______________________________________________/
#

__author__= "Christophe Coulet"
__date__ = "$27-Jun-2017 12:13:25$"

if __name__ == "__main__":
#    time_res, reach_idx, section_idx, section_pk = lit_res_opt('mascaret_imp_ecr.opt')
    lit_res_rub('mascaret.rub')
'''
    print( time_res )
    print( reach_idx )
    print( section_idx )
    print( section_pk )
'''
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# ~~~~ Jenkins' success message ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print( '\n\nMy work is done\n\n' )
