# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime

# Setup config
# ------------
def setup_dict(path):

  dict = {
    "nml_file": path+"fmsmpp.nml",
  }

  return dict

# Geometry config
# ---------------
def geometry_dict(section_name,path,cube):

  dict = {
    section_name: {
      "nml_file": path+"/input_gfs_c"+cube+".nml",
      "trc_file": path+"/field_table",
      "pathfile_akbk": path+"/akbk.nc",
    },
  }
  return dict

# State config
# ------------
def state_dict(section_name,path,dt,variables):

  datetime_str = dt.strftime('%Y%m%d.%H%M%S.')

  dict = {
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

  return dict

def output_dict(section_name,path):

  dict = {
    section_name: {
      "filetype": "gfs",
      "datapath_tile": path,
      "filename_core": "fv_core.res.nc",
      "filename_trcr": "fv_tracer.res.nc",
      "filename_sfcd": "sfc_data.nc",
      "filename_sfcw": "fv_srf_wnd.res.nc",
      "filename_cplr": "coupler.res",
    },
  }

  return dict

# Analysis to control config
# --------------------------

def varcha_a2c_dict(path_femps):
  dict = {
    "varchange": "Control2Analysis",
    "femps_iterations": "50",
    "femps_ngrids": "5",
    "femps_path2fv3gridfiles": path_femps+"/femps",
    "doinverse": "1",
    "outputVariables": {
    "variables": ["psi","chi","vort","divg","t","tv","delp","ps","q","rh","qi","ql","o3"],
    },
  }

  return dict
