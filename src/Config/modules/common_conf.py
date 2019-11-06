# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime

# --------------------------------------------------------------------------------------------------

def varcha_a2c_dict(path_femps):

  varchadict = {
    "varchange": "Control2Analysis",
    "femps_iterations": "75",
    "femps_ngrids": "6",
    "femps_levelprocs": "64",
    "femps_checkconvergence": "false",
    "femps_path2fv3gridfiles": path_femps,
    "doinverse": "1",
    "inputVariables": {
    "variables": ["u","v","T","DELP","sphum","ice_wat","liq_wat","o3mr","phis"],
    },
    "outputVariables": {
    "variables": ["psi","chi","vort","divg","T","tv","DELP","ps","sphum","rh","ice_wat","liq_wat","o3mr","phis"],
    },
  }

  return varchadict

# --------------------------------------------------------------------------------------------------
