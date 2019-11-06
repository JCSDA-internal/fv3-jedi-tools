# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime

# Geometry config
# ---------------
def geometry_dict(section_name,path):

  geomdict = {
    section_name: {
      "nml_file_mpp": path+"/fmsmpp.nml",
      "nml_file": path+"/input.nml",
      "trc_file": path+"/field_table",
      "pathfile_akbk": path+"/akbk64.nc4",
    },
  }
  return geomdict

# State config
# ------------
def state_dict(section_name,path,dt,variables=''):

  datetime_str = dt.strftime('%Y%m%d.%H%M%S.')

  if not variables=='':

    statedict = {
      section_name: {
        "filetype": "gfs",
        "datapath_tile": path,
        "filename_core": datetime_str+"fv_core.res.nc",
        "filename_trcr": datetime_str+"fv_tracer.res.nc",
        "filename_sfcd": datetime_str+"sfc_data.nc",
        "filename_sfcw": datetime_str+"fv_srf_wnd.res.nc",
        "filename_cplr": datetime_str+"coupler.res",
        "variables": variables
      },
    }

  else:

    statedict = {
      section_name: {
        "filetype": "gfs",
        "nml_file_mpp": "fv3files/fmsmpp.nml",
        "datapath_tile": path,
        "filename_core": datetime_str+"fv_core.res.nc",
        "filename_trcr": datetime_str+"fv_tracer.res.nc",
        "filename_sfcd": datetime_str+"sfc_data.nc",
        "filename_sfcw": datetime_str+"fv_srf_wnd.res.nc",
        "filename_cplr": datetime_str+"coupler.res"
      },
    }

  return statedict

def output_dict(section_name,path,name=''):

  outputdict = {
    section_name: {
      "filetype": "gfs",
      "nml_file_mpp": "fv3files/fmsmpp.nml",
      "datapath_tile": path,
      "filename_core": name+"fv_core.res.nc",
      "filename_trcr": name+"fv_tracer.res.nc",
      "filename_sfcd": name+"sfc_data.nc",
      "filename_sfcw": name+"fv_srf_wnd.res.nc",
      "filename_cplr": name+"coupler.res",
    },
  }

#  outputdict = {
#    section_name: {
#      "filetype": "geos",
#      "datapath": path,
#      "filename": "geos",
#    },
#  }

  return outputdict

# Analysis to control config
# --------------------------

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
