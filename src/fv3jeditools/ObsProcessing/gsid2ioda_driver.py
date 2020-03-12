# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import sys
#import ObsProcessing.modules.gsi_ncdiag as gsi_ncdiag

def gsid_to_ioda_driver(ioda_con_path,infile,outdir,type,platform=''):

  # Import from ioda converters
  sys.path.append(ioda_con_path+'/lib/pyiodaconv')
  import gsi_ncdiag as gsi_ncdiag


  # Constructor
  if (type == 'cnv'):
    diag = gsi_ncdiag.Conv(infile)
  elif (type == 'rad'):
    diag = gsi_ncdiag.Radiances(infile)
  elif (type == 'aod'):
    diag = gsi_ncdiag.AOD(infile)
  elif (type == 'ozn'):
    diag = gsi_ncdiag.Ozone(infile)
  elif (type == 'radar'):
    diag = gsi_ncdiag.Radar(infile)
  else:
    raise ValueError

  # Read ncdiag files
  diag.read()

  # Convert to IODA format
  if (type == 'conv'):
    if platform == '':
      print("ABORT: if calling gsid_to_ioda_driver with cnv, provide platform")
    diag.toIODAobs(outdir, platforms=[platform])
  else:
      diag.toIODAobs(outdir)

  # Write Geovals file
  #diag.toGeovals(outdir)
