#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import argparse
import datetime
import os
import shutil
import subprocess
import tarfile
import sys

import Utils.modules.utils as utils

# --------------------------------------------------------------------------------------------------

sargs=argparse.ArgumentParser()
sargs.add_argument( "-s", "--start_date",    default='2019111809')
sargs.add_argument( "-q", "--freq",          default='6')

args    = sargs.parse_args()
start   = args.start_date
freq    = int(args.freq)

# --------------------------------------------------------------------------------------------------

print("GeosEns0HourFcsts")

# Directory to track output
# -------------------------
workflowdir = '/gpfsm/dnb31/drholdaw/JediScratch/RealTime4DVarGeos/WorkflowTracking/GeosEns0HourFcsts'


# Keep track of whether file is running
# -------------------------------------
working = os.path.join(workflowdir,'working')

if (os.path.exists(working)):
  utils.abort('GeosEns0HourFcsts, '+working+' exists. Already running or previous fail ...')

open(working, 'a').close()


# This directory
# --------------
cwd = os.getcwd()


# Directory to run GEOS
# ---------------------
geosrundir = '/discover/nobackup/drholdaw/JediScratch/RealTime4DVarGeos/GeosRunDirEns'

# Files and paths that need datetime
# ----------------------------------
enstarpath_ = '/nfs3m/archive/sfa_cache01/projects/dao_ops/GEOS-5.22/GEOSadas-5_22/f522_fp/atmens/Y%Y/M%m/'
enstarfile_ = 'f522_fp.atmens_erst.%Y%m%d_%Hz'
centarfile_ = '/nfs3m/archive/sfa_cache01/projects/dao_ops/GEOS-5.22/GEOSadas-5_22/f522_fp/rs/Y%Y/M%m/f522_fp.rst.%Y%m%d_%Hz.tar'

newtarpath_ = '/nfs3m/archive/sfa_cache05/users/g00/drholdaw/f522_c180_dh/atmens/Y%Y/M%m/'
newtarfile_ = 'f522_dh.atmens_erst.%Y%m%d_%Hz'

rstlcvfile_ = 'f522_fp.rst.lcv.%Y%m%d_%Hz.bin'

# Date formats
# ------------
yyyymmdd    = '%Y%m%d'
yyyymmddhh  = '%Y%m%d%H'
yyyymmdd_hh = '%Y%m%d_%H'


# Set final to be now - 5 days - 3hours (need to stay behind operations a bit)
# ----------------------------------------------------------------------------
today_str = datetime.datetime.today().strftime(yyyymmdd)
datetime_final = datetime.datetime.strptime(today_str, yyyymmdd) - datetime.timedelta(hours=123)
final = datetime_final.strftime(yyyymmddhh)


# Loop over date times
# --------------------
dts = utils.getDateTimes(start,final,3600*freq,yyyymmddhh)

for dt in dts:

  # Date to pass to script
  # ----------------------
  process_date = dt.strftime(yyyymmdd_hh)


  # Track of times completed
  # ------------------------
  donefile = os.path.join(workflowdir,'done_'+process_date)

  print('GeosEns0HourFcsts: process date: '+process_date)

  if (os.path.exists(donefile)):
    print(' '+process_date+' marked comlete, skipping')
    continue

  # Fill date specific templates
  # ----------------------------
  rstlcvfile = dt.strftime(rstlcvfile_)
  centarfile = dt.strftime(centarfile_)
  enstarpath = dt.strftime(enstarpath_)
  enstarfile = dt.strftime(enstarfile_)
  newtarpath = dt.strftime(newtarpath_)
  newtarfile = dt.strftime(newtarfile_)


  # Get the d_rst file from central
  # -------------------------------
  print('Getting d_rst from file')
  tf = tarfile.open(centarfile)
  cenmembers = tf.getmembers()

  for n in range(len(cenmembers)):
    if cenmembers[n].name == rstlcvfile:
      break
  tf.extractall(geosrundir,members=cenmembers[n:n+1])
  tf.close()

  os.rename(os.path.join(geosrundir,rstlcvfile),os.path.join(geosrundir,'d_rst'))


  # Extract tar file with all ens members
  # -------------------------------------
  #print('Extracting ensemble tar file')
  #tf = tarfile.open(os.path.join(enstarpath,enstarfile+'.tar'))
  #tf.extractall(geosrundir)
  #tf.close()


  # Call driver script
  # ------------------
  print('Calling GEOS model for members')

  driverscript = os.path.join(geosrundir,'driver.csh')
  command = 'qsub -W block=true '+driverscript+' '+process_date

  os.chdir(geosrundir)
  utils.run_shell_command(command)
  os.chdir(cwd)


  # Tar up netcdf restarts
  # ----------------------
  print('Tarring up the netCDF members')
  if not os.path.exists(newtarpath):
    os.makedirs(newtarpath)
  newtarpathfile = os.path.join(newtarpath,newtarfile+'.tar')

  os.chdir(geosrundir)
  with tarfile.open(newtarpathfile, "w") as tf:
    tf.add(newtarfile)
  os.chdir(cwd)

  # Clean up
  # --------
  print('Cleaning up')
  os.remove(os.path.join(geosrundir,'d_rst'))
  shutil.rmtree(os.path.join(geosrundir,newtarfile))
  shutil.rmtree(os.path.join(geosrundir,enstarfile))

  # Done
  # ----
  open(donefile, 'a').close()

  # One at a time and resubmit via cron
  # -----------------------------------
  os.remove(working)

  print("All done, resubmit job for next time")

  exit()
