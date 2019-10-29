# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime
import yaml

import gfs_yaml as myam

def convertStateDict(datetime,cube,path_fv3files,path_bkg,path_output)

  # variables
  variables = ["u","v","T","DELP","sphum","ice_wat","liq_wat","o3mr"]

  # Setup
  setup = myam.setup_dict(path_fv3files)

  # Geometry
  inputresolution  = myam.geometry_dict('inputresolution' ,path_fv3files,cube)
  outputresolution = myam.geometry_dict('outputresolution',path_fv3files,cube)

  # States
  input  = myam.state_dict('input',path_bkg,dt,variables)
  output = myam.output_dict('output',path_output)

  # Variable change
  varcha = myam.varcha_a2c_dict('Data')

  return {**setup, **inputresolution, **outputresolution, **input, **output, **varcha}
