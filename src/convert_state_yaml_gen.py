# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime
import yaml

import gfs_yaml as myam

cube = '384'
path_fv3files = 'Data/fv3files/'
path_bkg = 'Data/inputs/gfs_c384/bkg/'
path_wrt = 'Data/'

dt = datetime.datetime.strptime('20191001.000000', '%Y%m%d.%H%M%S')

# variables
variables = ["u","v","T","DELP","sphum","ice_wat","liq_wat","o3mr"]

# Setup
setup = myam.setup_dict(path_fv3files)

# Geometry
inputresolution  = myam.geometry_dict('inputresolution' ,path_fv3files,cube)
outputresolution = myam.geometry_dict('outputresolution',path_fv3files,cube)

# States
input  = myam.state_dict('input',path_bkg,dt,variables)
output = myam.output_dict('output',path_wrt)

# Variable change
varcha = myam.varcha_a2c_dict('Data')

convert_state_gfs = {**setup, **inputresolution, **outputresolution, **input, **output, **varcha}

with open('convert_state_gfs.yml', 'w') as outfile:
  yaml.dump(convert_state_gfs, outfile)
