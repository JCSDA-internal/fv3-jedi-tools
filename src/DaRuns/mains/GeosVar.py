#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import argparse
import datetime
import os
import shutil
import yaml

import BkgHandling.modules.BkgHandling as BkgHandling
import EnsHandling.modules.EnsHandling as EnsHandling
import ObsProcessing.modules.ObsHandling as ObsHandling

import Utils.modules.utils as utils

sargs=argparse.ArgumentParser()
sargs.add_argument( "-s", "--start_date",    default='2019111809')
sargs.add_argument( "-f", "--final_date",    default='2020123121')
sargs.add_argument( "-q", "--freq",          default='6')
sargs.add_argument( "-c", "--config",        default='config.yaml')

args    = sargs.parse_args()
start   = args.start_date
final   = args.final_date
freq    = int(args.freq)
conf    = args.config

# --------------------------------------------------------------------------------------------------

# Directory to track output
# -------------------------
workdir = '/gpfsm/dnb31/drholdaw/JediScratch/RealTime4DVarGeos/'
workflowdir = '/gpfsm/dnb31/drholdaw/JediScratch/RealTime4DVarGeos/WorkflowTracking/GeosVar'
jediworkdir = '/gpfsm/dnb31/drholdaw/JediScratch/RealTime4DVarGeos/JediRuns/'

# Keep track of whether file is running
# -------------------------------------
working = os.path.join(workflowdir,'working')

# This directory
# --------------
cwd = os.getcwd()

if (os.path.exists(working)):
  utils.abort('GeosEns0HourFcsts, '+working+' exists. Already running or previous fail ...')

open(working, 'a').close()


dtformat = '%Y%m%d%H'

dts = utils.getDateTimes(start,final,3600*freq,dtformat)

# Create objects of needed modules
# --------------------------------
eh = EnsHandling.EnsembleHandling()
bh = BkgHandling.BackgroundHandling()
oh = ObsHandling.ObservationHandling()

# Loop over times
# ---------------

for dt in dts:

  # Dates to pass to scripts
  # ------------------------
  window_beg = dt.strftime(dtformat)
  window_mid = (dt + datetime.timedelta(seconds=10800)).strftime(dtformat)
  window_end = (dt + datetime.timedelta(seconds=21600)).strftime(dtformat)

  window_net = (dt + datetime.timedelta(seconds=43200)).strftime(dtformat)

  window_prv = (dt + datetime.timedelta(seconds=-21600)).strftime(dtformat)

  window_beg_ = dt.strftime('%Y%m%d_%H')
  window_net_ = (dt + datetime.timedelta(seconds=43200)).strftime('%Y%m%d_%H')


  # Track of times completed
  # ------------------------
  donefile = os.path.join(workflowdir,'done_'+window_beg)

  print('GeosVar: process date: '+window_beg)

  if (os.path.exists(donefile)):
    print(' '+window_beg+' marked comlete, skipping')
    continue




  # Set environment variables
  # -------------------------
  os.environ['PDATE'] = window_beg
  os.environ['WINBEG'] = window_beg
  os.environ['WINMID'] = window_mid
  os.environ['WINEND'] = window_end
  os.environ['CFILE'] = conf


  # Set the configuration scripts
  # -----------------------------
  configfile = os.getenv('CFILE')
  with open(configfile) as file:
    cf = yaml.load(file, Loader=yaml.FullLoader)

  config_files_in  = cf['config_files_in'].split()
  config_files_out = cf['config_files_out'].split()

  for n in range(len(config_files_in)):

    utils.setDateConfigFile(window_beg,config_files_in [n],config_files_out[n],'WBEG')
    utils.setDateConfigFile(window_mid,config_files_out[n],config_files_out[n],'WMID')
    utils.setDateConfigFile(window_end,config_files_out[n],config_files_out[n],'WEND')
    utils.setDateConfigFile(window_prv,config_files_out[n],config_files_out[n],'WPRV')
    utils.setDateConfigFile(window_net,config_files_out[n],config_files_out[n],'WENT')


  # Prepare the observations
  # ------------------------

  filecheck = os.path.join(jediworkdir,'Data','Observations','windprof_uv_obs_'+window_mid+'.nc4')
  if not os.path.exists(filecheck):
    oh.downloadObsS3()
    oh.extractObs()
    oh.removeObsTar()
    oh.convertPressures()
  else:
    print("Observations already downloaded")


  # Prepare the ensemble
  # --------------------
  filecheck = os.path.join(jediworkdir,'Data','Ensemble','f522_dh.atmens_erst.'+window_beg+'z','mem032','f522_dh.fvcore_internal_rst.'+window_beg+'z.nc4')
  if not os.path.exists(filecheck):
    eh.downloadGeosEnsRestartArchive()
  else:
    print("Ensemble already downloaded")


  # Run the jobs
  # ------------
  print('Calling Cycle Jobs')

  driverscript = os.path.join(jediworkdir,'runs.csh')
  command = 'qsub -W block=true '+driverscript

  os.chdir(jediworkdir)
  utils.run_shell_command(command,False)
  os.chdir(cwd)

  # Wait for job to complete
  username = 'drholdaw'
  jobname = 'jedicycle'
  utils.wait_for_batch_job(username,jobname)


  # Pre clean up success check
  # --------------------------
  filecheck = os.path.join(workdir,'Archive',window_beg,'RestartAnalysis','fvcore_internal_rst')
  if not os.path.exists(filecheck):
    utils.abort("Aborting, jobs do not seem to have completed properly")


  # Clean up
  # --------
  print("All done, cleaning up")
  obsdir = os.path.join(jediworkdir,'Data','Observations')
  bkgdir = os.path.join(jediworkdir,'Data','Background')
  anadir = os.path.join(jediworkdir,'Data','Analysis')
  incdir = os.path.join(jediworkdir,'Data','Increment')
  bmpdir = os.path.join(jediworkdir,'Data','Bump','864_ens')
  rnedir = os.path.join(jediworkdir,'Data','RestartNew')
  ensdir = os.path.join(jediworkdir,'Data','Ensemble','f522_dh.atmens_erst.'+window_beg_+'z')

  shutil.rmtree(obsdir)
  shutil.rmtree(bkgdir)
  shutil.rmtree(anadir)
  shutil.rmtree(incdir)
  shutil.rmtree(bmpdir)
  shutil.rmtree(rnedir)
  shutil.rmtree(ensdir)

  os.mkdir(obsdir)
  os.mkdir(bkgdir)
  os.mkdir(anadir)
  os.mkdir(incdir)
  os.mkdir(bmpdir)
  os.mkdir(rnedir)


  # Done
  # ----
  open(donefile, 'a').close()
  os.remove(working)

  exit()
