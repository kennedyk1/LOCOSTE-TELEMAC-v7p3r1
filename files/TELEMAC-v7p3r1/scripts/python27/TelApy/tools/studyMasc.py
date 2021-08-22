import numpy as np
import os
from TelApy.api.masc import Mascaret

class StudyMascaret:
    def __init__(self,studyFiles,printKey=0):
        # creation of the mascaret instance
        self.masc= Mascaret()
        self.masc.create_mascaret(self.printKey)

    def import_model_and_initialisation(self):
        file_type = []
        file_name = []
        for key_val in studyFiles.items():
            if type(key_val[1])==list:
                for i, sub in enumerate(key_val[1]):
                    file_name.append(sub)
                    file_type.append(key_val[0])
            else: 
                file_name.append(key_val[1])
                file_type.append(key_val[0])
        print file_name,len(file_name)
        self.masc.import_model_mascaret(file_name,file_type)
        self.masc.init_etat_mascaret(studyFiles['lig'])
        
    def error_message(self):
        self.masc.error_message()
        
    def run_model(self):

        Dt = self.masc.get_double_mascaret('Model.DT',0,0,0)
        Tini = self.masc.get_double_mascaret('Model.InitTime',0,0,0)
        Tfin = self.masc.get_double_mascaret('Model.MaxCompTime',0,0,0)
        
        self.masc.calcul_mascaret(Tini,Tfin,Dt)
        
    def run_model_boucle(self):
        Dt = self.masc.get_double_mascaret('Model.DT',0,0,0)
        Tini = self.masc.get_double_mascaret('Model.InitTime',0,0,0)
        Tfin = self.masc.get_double_mascaret('Model.MaxCompTime',0,0,0)
        T0=Tini
        Tplus = T0+Dt
        while Tplus<=Tfin:
            self.masc.calcul_mascaret(T0,Tplus,Dt)
            T0=Tplus
            Tplus=Tplus+Dt
    def finalize(self):
        del(self.masc)

    
if __name__ == "__main__":

    studyFiles={'xcas' : 'mascaret0.xcas',\
            'geo' : 'mascaret0.geo',\
            'res' : 'mascaret0.opt',\
            'res_casier' : 'mascaret0.opt_casier',\
            'res_liaison' : 'mascaret0.opt_liaison',\
            'listing' : 'mascaret0.lis',\
            'listing_casier' : 'mascaret0.lis_casier',\
            'lig' : 'mascaret0.lig',\
            'casier' : 'mascaret0.casier',\
            'rep' : 'mascaret0_ecr.rep',\
            'listing_liaison' : 'mascaret0.lis_liaison',\
            'loi' : ['mascaret0_0.loi','mascaret0_1.loi']}
    printKey=0 # 1 pour avoir le listing
    masc=StudyMascaret(studyFiles,printKey)
    masc.error_message()
    masc.import_model_and_initialisation()
    masc.error_message()
    masc.run_model_boucle()
    masc.error_message()
    masc.finalize()
