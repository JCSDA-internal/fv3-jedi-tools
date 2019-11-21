#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime
import argparse
import numpy as np
import os
import shutil
import gzip
import glob
import sys
import pathlib
import time

import ObsProcessing.modules.gsid2ioda_driver as gsid2ioda_driver
#import ObsProcessing.modules.gsi_ncdiag as gsi_ncdiag
import Utils.modules.utils as utils

sargs=argparse.ArgumentParser()
sargs.add_argument( "-s", "--start_date",    default='2019101706')
sargs.add_argument( "-f", "--final_date",    default='')
sargs.add_argument( "-q", "--freq",          default='6')
sargs.add_argument( "-i", "--ioda_con_path")
sargs.add_argument( "-w", "--work_dir")

args    = sargs.parse_args()
start   = args.start_date
final   = args.final_date
freq    = int(args.freq)
ioda_con_path = args.ioda_con_path
workdir = args.work_dir

sys.path.append(ioda_con_path+'/lib/pyiodaconv')
import gsi_ncdiag as gsi_ncdiag

# --------------------------------------------------------------------------------------------------

dtformat = '%Y%m%d%H'

# Set datetime and delta objects based on total range
datetime_start = datetime.datetime.strptime(start, dtformat)
if final != '':
  datetime_final = datetime.datetime.strptime(final, dtformat)
else:
  datetime_final = datetime.datetime.now()

totaldelta = datetime_final-datetime_start
totalhour = totaldelta.total_seconds()/3600

# List of dates to process
ntcycs = int(totalhour / freq) + 1
tdatetimes = np.array([datetime_start + datetime.timedelta(hours=6*i) for i in range(ntcycs)])

# Create work directory
if not os.path.exists(workdir):
  os.makedirs(workdir)

working_flag = os.path.join(workdir,'working')

if os.path.exists(working_flag):
  if (time.time()-os.path.getmtime(working_flag))/(60*60) > 3.0:
    print("Working flag exists but is over 3 hours old. Deleting and running again")
    os.remove(working_flag)
  else:
    print(working_flag+" exists. Already running or failed last time")
    exit()

pathlib.Path(working_flag).touch()

# Files that converters can't handle
skip_files = ['diag_conv_sst_ges',       # Conventional
              'diag_gome_metop-a_ges',   # Ozone
              'diag_sbuv2_n19_ges',
              'diag_omi_aura_ges',
              'diag_gome_metop-b_ges',
              'diag_ompstc8_npp_ges',
              'diag_ompsnp_npp_ges']

for n in range(ntcycs):

  print('Processing: ',tdatetimes[n])

  hpssroot = '/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_D/gfsv16/v16rt2'

  Y = tdatetimes[n].strftime('%Y')
  m = tdatetimes[n].strftime('%m')
  d = tdatetimes[n].strftime('%d')
  H = tdatetimes[n].strftime('%H')

  YmdH = Y+m+d+H

  workdirdate = os.path.join(workdir,YmdH)
  workdirgsid = os.path.join(workdirdate,'gsid')
  workdirioda = os.path.join(workdirdate,'ioda')
  workdiriodatmp = os.path.join(workdirioda,'tmp')

  if not os.path.exists(workdirdate):
    os.makedirs(workdirdate)
  if not os.path.exists(workdirgsid):
    os.makedirs(workdirgsid)
  if not os.path.exists(workdirioda):
    os.makedirs(workdirioda)
  if not os.path.exists(workdiriodatmp):
    os.makedirs(workdiriodatmp)

  lastdate = False
  if os.path.exists(os.path.join(workdirdate,'done')):
    print('Date complete, skipping')
    continue
  else:
    lastdate = True

  remote_path = os.path.join(hpssroot,YmdH)
  remote_file = os.path.join(remote_path,'gdas.tar')

  # Observation types to get
  types = ['rad','cnv','ozn']

  dirs = []
  for t in range(len(types)):
    dirs.append(os.path.join(workdirgsid,types[t]))
    if not os.path.exists(dirs[t]):
      os.makedirs(dirs[t])

  # Loop over obs types and retrieve from archive
  for t in range(len(types)):

    os.chdir(dirs[t])

    if not os.path.exists(os.path.join(dirs[t],'extractdone')):

      path_in_file = os.path.join('./gdas.'+Y+m+d,H,'gdas.t'+H+'z.'+types[t]+'stat')
      utils.run_bash_command(dirs[t], "/apps/hpss/htar -xvf "+remote_file+" "+path_in_file)
      utils.run_bash_command(dirs[t], 'tar -xvf '+path_in_file)

      # Remove the tar files
      shutil.rmtree(os.path.join(dirs[t],'gdas.'+Y+m+d))

      # Unzip each observation file
      for item in os.listdir(dirs[t]): # loop through items in dir
        if item.endswith('gz'):
          gzfilename = os.path.join(dirs[t],item)
          with gzip.open(gzfilename, 'rb') as file_gz:
            base_name = os.path.basename(gzfilename)
            new_name = os.path.splitext(base_name)[0]
            with open(os.path.join(dirs[t],new_name), 'wb') as f_out:
              shutil.copyfileobj(file_gz, f_out)
              os.remove(gzfilename)

      # Keep only ges
      fileList = glob.glob(os.path.join(dirs[t],'*anl*'))
      for filePath in fileList:
        os.remove(filePath)

      # Tag files to skip
      fileList = glob.glob(os.path.join('diag_*'))
      for filePath in fileList:
        for f in range(len(skip_files)):
          if skip_files[f] in filePath:
            os.rename(filePath,'_'+filePath)

      pathlib.Path(os.path.join(dirs[t],'extractdone')).touch()

    # Call converters for all files
    platform = ''

    fileList = glob.glob(os.path.join('diag_*'))
    for filePath in fileList:

      print(" GSI diag to IODA, converting: ",filePath)

      file_done = False
      if types[t] == 'rad':
        if os.path.exists(os.path.join(workdirioda,filePath[5:].replace('_ges.','_obs_'))):
          file_done = True

      if types[t] == 'cnv':
        if 'diag_conv_gps_ges' in filePath:
          platform = gsi_ncdiag.conv_platforms['conv_gps']
          file_tmp = 'bend'
        elif 'diag_conv_q_ges' in filePath:
          platform = gsi_ncdiag.conv_platforms['conv_q']
          file_tmp = 'q'
        elif 'diag_conv_t_ges' in filePath:
          platform = gsi_ncdiag.conv_platforms['conv_t']
          platform = list(filter(lambda a: a != 'rass', platform)) # not rass
          file_tmp = 'tsen'
        elif 'diag_conv_ps_ges' in filePath:
          platform = gsi_ncdiag.conv_platforms['conv_ps']
          file_tmp = 'ps'
        elif 'diag_conv_uv_ges' in filePath:
          platform = gsi_ncdiag.conv_platforms['conv_uv']
          file_tmp = 'uv'

        doneallplat = True
        for p in range(len(platform)):
          out_file = platform[p]+'_'+file_tmp+'_obs_'+YmdH+'.nc4'
          if not os.path.exists(os.path.join(workdirioda,out_file)):
            doneallplat = False
        file_done = doneallplat

      if not file_done:
        gsid2ioda_driver.gsid_to_ioda_driver(ioda_con_path,filePath,workdiriodatmp,types[t],platform)
        #Move file to normal ioda directory
        files = os.listdir(workdiriodatmp)
        for f in files:
          shutil.move(os.path.join(workdiriodatmp,f), os.path.join(workdirioda,f))
      else:
        print(" Already converted")

    os.chdir(workdirdate)


  print(os.path.join(workdirdate,'done'))
  pathlib.Path(os.path.join(workdirdate,'done')).touch()

  if lastdate:
    print("One date at a time, all done")
    os.remove(os.path.join(workdir,'working'))
    exit()
