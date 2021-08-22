#/usr/bin/env python
# -*- coding: latin-1 -*-
TelemacdicoEn = {
'ATMOSPHERE_WATER_EXCHANGE_MODEL' : {
    0:"NO MODEL",
    1:"LINEARISED FORMULA AT THE FREE SURFACE",
    2:"MODEL WITH COMPLETE BALANCE",
  },
'LIGHTNESS_OF_THE_SKY' : {
    1:"VERY BRIGHT, PURE SKY",
    2:"MODERATELY BRIGHT SKY",
    3:"FOGGY LIKE THE SKY OF INDUSTRIAL AREA ",
  },
'FORMULA_OF_ATMOSPHERIC_RADIATION' : {
    1:"IDSO AND JACKSON (1969)",
    2:"SWINBANK (1963)",
    3:"BRUTSAERT (1975)",
    4:"YAJIMA TONO DAM (2014)",
  },
}
TelemacdicoFr = {
'ATMOSPHERE_WATER_EXCHANGE_MODEL' : {
    0:"PAS DE MODELE D ECHANGES EAU-ATMOSPHERE",
    1:"FORMULE LINEARISEE A LA SURFACE",
    2:"MODELE A BILAN COMPLET",
  },
'LIGHTNESS_OF_THE_SKY' : {
    1:"CIEL TRES CLAIRE, TRES PURE",
    2:"CIEL MOYENNEMENT CLAIRE",
    3:"CIEL D UNE ZONE INDUSRTIELLE, OPAQUE",
  },
'FORMULA_OF_ATMOSPHERIC_RADIATION' : {
    1:"IDSO AND JACKSON (1969)",
    2:"SWINBANK (1963)",
    3:"BRUTSAERT (1975)",
    4:"YAJIMA TONO DAM (2014)",
  },
}

DicoCasFrToCata = {
  "FICHIER DES PARAMETRES":"STEERING_FILE",
  "FICHIER FORTRAN":"FORTRAN_FILE",
  "TITRE DU CAS QE":"WAQ_CASE_TITLE",
  "PERIODE POUR LES SORTIES QUALITE D'EAU":"WATER_QUALITY_PRINTOUT_PERIOD",
  "VARIABLES POUR LES SORTIES QE":"VARIABLES_FOR_WAQ_PRINTOUTS",
  "VARIABLES QE A IMPRIMER":"WAQ_VARIABLES_TO_BE_PRINTED",
  "FICHIER DES RESULTATS":"RESULTS_FILE",
  "FORMAT DU FICHIER DES RESULTATS":"RESULTS_FILE_FORMAT",
  "NUMERO DE VERSION":"RELEASE",
  "FICHIER DE GEOMETRIE":"GEOMETRY_FILE",
  "FORMAT DU FICHIER DE GEOMETRIE":"GEOMETRY_FILE_FORMAT",
  "FICHIER DES CONDITIONS AUX LIMITES":"BOUNDARY_CONDITIONS_FILE",
  "FICHIER HYDRODYNAMIQUE":"HYDRODYNAMIC_FILE",
  "FORMAT DU FICHIER HYDRODYNAMIQUE":"HYDRODYNAMIC_FILE_FORMAT",
  "FICHIER DE REFERENCE":"REFERENCE_FILE",
  "FORMAT DU FICHIER DE REFERENCE":"REFERENCE_FILE_FORMAT",
  "BILAN DE MASSE":"MASS_BALANCE",
  "VALIDATION":"VALIDATION",
  "MASSE VOLUMIQUE DE L'EAU":"WATER_DENSITY",
  "VISCOSITE CINEMATIQUE EAU":"KINEMATIC_WATER_VISCOSITY",
  "DISPERSION LONGITUDINALE":"DISPERSION_ALONG_THE_FLOW",
  "DISPERSION TRANSVERSALE":"DISPERSION_ACROSS_THE_FLOW",
  "DICTIONNAIRE":"DICTIONARY",
  "DEBUGGER":"DEBUGGER",
  "CONSTANTE DE DEGRADATION DE LA CHARGE ORGANIQUE K120":"CONSTANT_OF_DEGRADATION_OF_ORGANIC_LOAD_K120",
  "CONSTANTE DE LA CINETIQUE DE NITRIFICATION K520":"CONSTANT_FOR_THE_NITRIFICATION_KINETIC_K520",
  "OXYGENE PRODUIT PAR PHOTOSYNTHESE":"OXYGENE_PRODUCED_BY_PHOTOSYNTHESIS",
  "OXYGENE CONSOMME PAR NITRIFICATION":"CONSUMED_OXYGEN_BY_NITRIFICATION",
  "DEMANDE BENTHIQUE":"BENTHIC_DEMAND",
  "COEFFICIENT DE REAERATION K2":"K2_REAERATION_COEFFICIENT",
  "FORMULE DE CALCUL DE K2":"FORMULA_FOR_COMPUTING_K2",
  "CONCENTRATION DE SATURATION EN O2 DE L'EAU (CS)":"O2_SATURATION_DENSITY_OF_WATER__CS_",
  "FORMULE DE CALCUL DE CS":"FORMULA_FOR_COMPUTING_CS",
  "VITESSE DE SEDIMENTATION DU PHOSPHORE ORGANIQUE":"SEDIMENTATION_VELOCITY_OF_ORGANIC_PHOSPHORUS",
  "VITESSE DE SEDIMENTATION DE L'AZOTE NON ALGALE":"SEDIMENTATION_VELOCITY_OF_NON_ALGAL_NITROGEN",
  "TAUX DE CROISSANCE ALGALE MAXIMUM A 20C":"MAXIMUM_ALGAL_GROWTH_RATE_AT_20C",
  "PROFONDEUR DE SECCHI":"SECCHI_DEPTH",
  "COEFFICIENT DE TURBIDITE VEGETALE SANS PHYTO":"VEGETAL_TURBIDITY_COEFFICIENT_WITHOUT_PHYTO",
  "PARAMETRE DE CALAGE DE LA FORMULE DE SMITH":"PARAMETER_OF_CALIBRATION_OF_SMITH_FORMULA",
  "CONSTANTE DE DEMI-SATURATION EN PHOSPHATE":"CONSTANT_OF_HALF_SATURATION_WITH_PHOSPHATE",
  "CONSTANTE DE DEMI-SATURATION EN AZOTE":"CONSTANT_OF_HALF_SATURATION_WITH_NITROGEN",
  "COEFFICIENTS DE TOXICITE POUR LES ALGUES":"ALGAL_TOXICITY_COEFFICIENTS",
  "TAUX DE RESPIRATION DE LA BIOMASSE ALGALE":"RESPIRATION_RATE_OF_ALGAL_BIOMASS",
  "PROPORTION DE PHOSPHORE DANS LES CELLULES DU PHYTO":"PROPORTION_OF_PHOSPHORUS_WITHIN_PHYTO_CELLS",
  "POURCENTAGE DE PHOSPHORE ASSIMILABLE DANS LE PHYTO MORT":"PERCENTAGE_OF_PHYSPHORUS_ASSIMILABLE_IN_DEAD_PHYTO",
  "TAUX DE TRANSFORMATION DU POR EN PO4":"RATE_OF_TRANSFORMATION_OF_POR_TO_PO4",
  "PROPORTION D'AZOTE DANS LES CELLULES DU PHYTO":"PROPORTION_OF_NITROGEN_WITHIN_PHYTO_CELLS",
  "PERCENTAGE D'AZOTE ASSIMILABLE DANS LE PHYTO MORT":"PERCENTAGE_OF_NITROGEN_ASSIMILABLE_IN_DEAD_PHYTO",
  "TAUX DE TRANSFORMATION DU NOR EN NO3":"RATE_OF_TRANSFORMATION_OF_NOR_TO_NO3",
  "COEFFICIENTS DE MORTALITE ALGALE A 20C":"COEFFICIENTS_OF_ALGAL_MORTALITY_AT_20C",
  "VITESSE DE SEDIMENTATION DE LA CHARGE ORGANIQUE":"SEDIMENTATION_VELOCITY_OF_ORGANIC_LOAD",
  "CONSTANTE DE DEGRADATION DE LA CHARGE ORGANIQUE K1":"CONSTANT_OF_DEGRADATION_OF_ORGANIC_LOAD_K1",
  "CONSTANTE DE CINETIQUE DE NITRIFICATION K4":"CONSTANT_OF_NITRIFICATION_KINETIC_K4",
  "PHOTOSYNTHESE P":"PHOTOSYNTHESIS_P",
  "RESPIRATION VEGETALE R":"VEGERAL_RESPIRATION_R",
  "TEMPERATURE DE L'EAU":"WATER_TEMPERATURE",
  "COEFFICIENT DE REAERATION DU SEUIL RS":"WEIR_REAERATION_COEFFICIENT_RS",
  "FORMULE DE CALCUL DE RS":"FORMULA_FOR_COMPUTING_RS",
  "COEFFICIENTS A ET B POUR LA FORMULE DE RS":"COEFFICIENTS_A_AND_B_FOR_RS_FORMULA",
  "TAUX D'EROSION":"EROSION_RATE",
  "CONTRAINTE CRITIQUE DE SEDIMENTATION":"SEDIMENTATION_CRITICAL_STRESS",
  "CONTRAINTE CRITIQUE DE REMISE EN SUSPENSION":"CRITICAL_STRESS_OF_RESUSPENSION",
  "VITESSE DE CHUTE DES MES":"SEDIMENT_SETTLING_VELOCITY",
  "CONSTANTE DE DESINTEGRATION EXPONENETIELLE":"EXPONENETIAL_DESINTEGRATION_CONSTANT",
  "COEFFICIENT DE DISTRIBUTION":"COEFFICIENT_OF_DISTRIBUTION",
  "CONSTANTE CINETIQUE DE DESORPTION":"CONSTANT_OF_DESORPTION_KINETIC",
  "CHALEUR SPECIFIQUE DE L'EAU":"WATER_SPECIFIC_HEAT",
  "CHALEUR SPECIFIQUE DE L'AIR":"AIR_SPECIFIC_HEAT",
  "COEFFICIENTS DE LA FORMULE D'AERATION":"COEFFICIENTS_OF_AERATION_FORMULA",
  "COEFFICIENT REPRESENTATIF DE LA COUVERTURE NUAGEUSE":"COEFFICIENT_OF_CLOUDING_RATE",
  "COEFFICIENTS DE CALAGE DU RAYONNEMENT ATMOSPHERIQUE":"COEFFICIENTS_FOR_CALIBRATING_ATMOSPHERIC_RADIATION",
  "COEFFICIENTS DE CALAGE DU RAYONNEMENT DU PLAN D'EAU":"COEFFICIENTS_FOR_CALIBRATING_SURFACE_WATER_RADIATION",
  "DENSITE DE FLUX DU RAYONNEMENT SOLAIRE A LA SURFACE":"SUNSHINE_FLUX_DENSITY_ON_WATER_SURFACE",
  "MODELE D'ECHANGES EAU-ATMOSPHERE":"ATMOSPHERE_WATER_EXCHANGE_MODEL",
  "CLARTE DU CIEL":"LIGHTNESS_OF_THE_SKY",
  "COEFFICIENT DE CALAGE DU MODELE D'ECHANGES EAU-ATMOSPHERE":"COEFFICIENT_TO_CALIBRATE_THE_ATMOSPHERE_WATER_EXCHANGE_MODEL",
  "TAUX D'EVAPORATION":"EVAPORATION_RATE",
  "METHODE DE CALCUL DU COEFFICIENT D'EXTINCTION DU RAY":"METHOD_OF_COMPUTATION_OF_RAY_EXCTINCTION_COEFFICIENT",
  "FORMULE DU RAYONNEMENT ATMOSPHERIQUE":"FORMULA_OF_ATMOSPHERIC_RADIATION",
  "FICHIER DES PARAMETRES AED2":"AED2_STEERING_FILE",
  "FICHIER DES PARAMETRES PHYTOPLANCTON AED2":"AED2_PHYTOPLANKTON_STEERING_FILE",
  "FICHIER DES PARAMETRES ZOOPLANCTON AED2":"AED2_ZOOPLANKTON_STEERING_FILE",
  "FICHIER DES PARAMETRES PATHOGENES AED2":"AED2_PATHOGEN_STEERING_FILE",
  "FICHIER DES PARAMETRES BIVALVES AED2":"AED2_BIVALVE_STEERING_FILE",
  "LISTE DES FICHIERS":"LIST_OF_FILES",
  "DESCRIPTION DES LIBRAIRIES":"DESCRIPTION_OF_LIBRARIES",
  "EXECUTABLE PAR DEFAUT":"DEFAULT_EXECUTABLE",
  "EXECUTABLE PARALLELE PAR DEFAUT":"DEFAULT_PARALLEL_EXECUTABLE",
}

DicoCasEnToCata = {
  'STEERING FILE':'STEERING_FILE',
  'FORTRAN FILE':'FORTRAN_FILE',
  'WAQ CASE TITLE':'WAQ_CASE_TITLE',
  'WATER QUALITY PRINTOUT PERIOD':'WATER_QUALITY_PRINTOUT_PERIOD',
  'VARIABLES FOR WAQ PRINTOUTS':'VARIABLES_FOR_WAQ_PRINTOUTS',
  'WAQ VARIABLES TO BE PRINTED':'WAQ_VARIABLES_TO_BE_PRINTED',
  'RESULTS FILE':'RESULTS_FILE',
  'RESULTS FILE FORMAT':'RESULTS_FILE_FORMAT',
  'RELEASE':'RELEASE',
  'GEOMETRY FILE':'GEOMETRY_FILE',
  'GEOMETRY FILE FORMAT':'GEOMETRY_FILE_FORMAT',
  'BOUNDARY CONDITIONS FILE':'BOUNDARY_CONDITIONS_FILE',
  'HYDRODYNAMIC FILE':'HYDRODYNAMIC_FILE',
  'HYDRODYNAMIC FILE FORMAT':'HYDRODYNAMIC_FILE_FORMAT',
  'REFERENCE FILE':'REFERENCE_FILE',
  'REFERENCE FILE FORMAT':'REFERENCE_FILE_FORMAT',
  'MASS-BALANCE':'MASS_BALANCE',
  'VALIDATION':'VALIDATION',
  'WATER DENSITY':'WATER_DENSITY',
  'KINEMATIC WATER VISCOSITY':'KINEMATIC_WATER_VISCOSITY',
  'DISPERSION ALONG THE FLOW':'DISPERSION_ALONG_THE_FLOW',
  'DISPERSION ACROSS THE FLOW':'DISPERSION_ACROSS_THE_FLOW',
  'DICTIONARY':'DICTIONARY',
  'DEBUGGER':'DEBUGGER',
  'CONSTANT OF DEGRADATION OF ORGANIC LOAD K120':'CONSTANT_OF_DEGRADATION_OF_ORGANIC_LOAD_K120',
  'CONSTANT FOR THE NITRIFICATION KINETIC K520':'CONSTANT_FOR_THE_NITRIFICATION_KINETIC_K520',
  'OXYGENE PRODUCED BY PHOTOSYNTHESIS':'OXYGENE_PRODUCED_BY_PHOTOSYNTHESIS',
  'CONSUMED OXYGEN BY NITRIFICATION':'CONSUMED_OXYGEN_BY_NITRIFICATION',
  'BENTHIC DEMAND':'BENTHIC_DEMAND',
  'K2 REAERATION COEFFICIENT':'K2_REAERATION_COEFFICIENT',
  'FORMULA FOR COMPUTING K2':'FORMULA_FOR_COMPUTING_K2',
  'O2 SATURATION DENSITY OF WATER (CS)':'O2_SATURATION_DENSITY_OF_WATER__CS_',
  'FORMULA FOR COMPUTING CS':'FORMULA_FOR_COMPUTING_CS',
  'SEDIMENTATION VELOCITY OF ORGANIC PHOSPHORUS':'SEDIMENTATION_VELOCITY_OF_ORGANIC_PHOSPHORUS',
  'SEDIMENTATION VELOCITY OF NON ALGAL NITROGEN':'SEDIMENTATION_VELOCITY_OF_NON_ALGAL_NITROGEN',
  'MAXIMUM ALGAL GROWTH RATE AT 20C':'MAXIMUM_ALGAL_GROWTH_RATE_AT_20C',
  'SECCHI DEPTH':'SECCHI_DEPTH',
  'VEGETAL TURBIDITY COEFFICIENT WITHOUT PHYTO':'VEGETAL_TURBIDITY_COEFFICIENT_WITHOUT_PHYTO',
  'PARAMETER OF CALIBRATION OF SMITH FORMULA':'PARAMETER_OF_CALIBRATION_OF_SMITH_FORMULA',
  'CONSTANT OF HALF-SATURATION WITH PHOSPHATE':'CONSTANT_OF_HALF_SATURATION_WITH_PHOSPHATE',
  'CONSTANT OF HALF-SATURATION WITH NITROGEN':'CONSTANT_OF_HALF_SATURATION_WITH_NITROGEN',
  'ALGAL TOXICITY COEFFICIENTS':'ALGAL_TOXICITY_COEFFICIENTS',
  'RESPIRATION RATE OF ALGAL BIOMASS':'RESPIRATION_RATE_OF_ALGAL_BIOMASS',
  'PROPORTION OF PHOSPHORUS WITHIN PHYTO CELLS':'PROPORTION_OF_PHOSPHORUS_WITHIN_PHYTO_CELLS',
  'PERCENTAGE OF PHYSPHORUS ASSIMILABLE IN DEAD PHYTO':'PERCENTAGE_OF_PHYSPHORUS_ASSIMILABLE_IN_DEAD_PHYTO',
  'RATE OF TRANSFORMATION OF POR TO PO4':'RATE_OF_TRANSFORMATION_OF_POR_TO_PO4',
  'PROPORTION OF NITROGEN WITHIN PHYTO CELLS':'PROPORTION_OF_NITROGEN_WITHIN_PHYTO_CELLS',
  'PERCENTAGE OF NITROGEN ASSIMILABLE IN DEAD PHYTO':'PERCENTAGE_OF_NITROGEN_ASSIMILABLE_IN_DEAD_PHYTO',
  'RATE OF TRANSFORMATION OF NOR TO NO3':'RATE_OF_TRANSFORMATION_OF_NOR_TO_NO3',
  'COEFFICIENTS OF ALGAL MORTALITY AT 20C':'COEFFICIENTS_OF_ALGAL_MORTALITY_AT_20C',
  'SEDIMENTATION VELOCITY OF ORGANIC LOAD':'SEDIMENTATION_VELOCITY_OF_ORGANIC_LOAD',
  'CONSTANT OF DEGRADATION OF ORGANIC LOAD K1':'CONSTANT_OF_DEGRADATION_OF_ORGANIC_LOAD_K1',
  'CONSTANT OF NITRIFICATION KINETIC K4':'CONSTANT_OF_NITRIFICATION_KINETIC_K4',
  'PHOTOSYNTHESIS P':'PHOTOSYNTHESIS_P',
  'VEGERAL RESPIRATION R':'VEGERAL_RESPIRATION_R',
  'WATER TEMPERATURE':'WATER_TEMPERATURE',
  'WEIR REAERATION COEFFICIENT RS':'WEIR_REAERATION_COEFFICIENT_RS',
  'FORMULA FOR COMPUTING RS':'FORMULA_FOR_COMPUTING_RS',
  'COEFFICIENTS A AND B FOR RS FORMULA':'COEFFICIENTS_A_AND_B_FOR_RS_FORMULA',
  'EROSION RATE':'EROSION_RATE',
  'SEDIMENTATION CRITICAL STRESS':'SEDIMENTATION_CRITICAL_STRESS',
  'CRITICAL STRESS OF RESUSPENSION':'CRITICAL_STRESS_OF_RESUSPENSION',
  'SEDIMENT SETTLING VELOCITY':'SEDIMENT_SETTLING_VELOCITY',
  'EXPONENETIAL DESINTEGRATION CONSTANT':'EXPONENETIAL_DESINTEGRATION_CONSTANT',
  'COEFFICIENT OF DISTRIBUTION':'COEFFICIENT_OF_DISTRIBUTION',
  'CONSTANT OF DESORPTION KINETIC':'CONSTANT_OF_DESORPTION_KINETIC',
  'WATER SPECIFIC HEAT':'WATER_SPECIFIC_HEAT',
  'AIR SPECIFIC HEAT':'AIR_SPECIFIC_HEAT',
  'COEFFICIENTS OF AERATION FORMULA':'COEFFICIENTS_OF_AERATION_FORMULA',
  'COEFFICIENT OF CLOUDING RATE':'COEFFICIENT_OF_CLOUDING_RATE',
  'COEFFICIENTS FOR CALIBRATING ATMOSPHERIC RADIATION':'COEFFICIENTS_FOR_CALIBRATING_ATMOSPHERIC_RADIATION',
  'COEFFICIENTS FOR CALIBRATING SURFACE WATER RADIATION':'COEFFICIENTS_FOR_CALIBRATING_SURFACE_WATER_RADIATION',
  'SUNSHINE FLUX DENSITY ON WATER SURFACE':'SUNSHINE_FLUX_DENSITY_ON_WATER_SURFACE',
  'ATMOSPHERE-WATER EXCHANGE MODEL':'ATMOSPHERE_WATER_EXCHANGE_MODEL',
  'LIGHTNESS OF THE SKY':'LIGHTNESS_OF_THE_SKY',
  'COEFFICIENT TO CALIBRATE THE ATMOSPHERE-WATER EXCHANGE MODEL':'COEFFICIENT_TO_CALIBRATE_THE_ATMOSPHERE_WATER_EXCHANGE_MODEL',
  'EVAPORATION RATE':'EVAPORATION_RATE',
  'METHOD OF COMPUTATION OF RAY EXCTINCTION COEFFICIENT':'METHOD_OF_COMPUTATION_OF_RAY_EXCTINCTION_COEFFICIENT',
  'FORMULA OF ATMOSPHERIC RADIATION':'FORMULA_OF_ATMOSPHERIC_RADIATION',
  'AED2 STEERING FILE':'AED2_STEERING_FILE',
  'AED2 PHYTOPLANKTON STEERING FILE':'AED2_PHYTOPLANKTON_STEERING_FILE',
  'AED2 ZOOPLANKTON STEERING FILE':'AED2_ZOOPLANKTON_STEERING_FILE',
  'AED2 PATHOGEN STEERING FILE':'AED2_PATHOGEN_STEERING_FILE',
  'AED2 BIVALVE STEERING FILE':'AED2_BIVALVE_STEERING_FILE',
  'LIST OF FILES':'LIST_OF_FILES',
  'DESCRIPTION OF LIBRARIES':'DESCRIPTION_OF_LIBRARIES',
  'DEFAULT EXECUTABLE':'DEFAULT_EXECUTABLE',
  'DEFAULT PARALLEL EXECUTABLE':'DEFAULT_PARALLEL_EXECUTABLE',
}
DicoEnumCasFrToEnumCasEn = {
'VARIABLES_FOR_WAQ_PRINTOUTS':{
  "editer !!!":"to edit !!!",
},

'RESULTS_FILE_FORMAT':{
  "SERAFIN":"SERAFIN",
  "SERAFIND":"SERAFIND",
  "MED":"MED",
},

'GEOMETRY_FILE_FORMAT':{
  "SERAFIN":"SERAFIN",
  "SERAFIND":"SERAFIND",
  "MED":"MED",
},

'HYDRODYNAMIC_FILE_FORMAT':{
  "SERAFIN":"SERAFIN",
  "SERAFIND":"SERAFIND",
  "MED":"MED",
},

'REFERENCE_FILE_FORMAT':{
  "SERAFIN":"SERAFIN",
  "SERAFIND":"SERAFIND",
  "MED":"MED",
},

}
