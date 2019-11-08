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

import Utils.modules.utils as utils

sargs=argparse.ArgumentParser()
sargs.add_argument( "-s", "--start_date",    default='2019101706')
sargs.add_argument( "-f", "--final_date",    default='')
sargs.add_argument( "-q", "--freq",          default='6')
sargs.add_argument( "-e", "--ioda_con_path")
sargs.add_argument( "-w", "--work_dir")

args    = sargs.parse_args()
start   = args.start_date
final   = args.final_date
freq    = int(args.freq)
workdir = args.work_dir

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

  if not os.path.exists(workdirdate):
    os.makedirs(workdirdate)
    os.makedirs(workdirgsid)
    os.makedirs(workdirioda)

  remote_path = os.path.join(hpssroot,YmdH)
  remote_file = os.path.join(remote_path,'gdas.tar')

  # Observation types to get
  types = ['rad','cnv','ozn']

  # Loop over obs types and retrieve from archive
  for t in range(len(types)):
    path_in_file = os.path.join('./gdas.'+Y+m+d,H,'gdas.t'+H+'z.'+types[t]+'stat')
    utils.run_bash_command(workdirgsid, "hpsstar get "+remote_file+" "+path_in_file)
    utils.run_bash_command(workdirgsid, 'tar -xvf '+path_in_file)

  # Remove the tar files
  shutil.rmtree(os.path.join(workdirgsid,'gdas.'+Y+m+d))

  # Unzip each observation file
  for item in os.listdir(workdirgsid): # loop through items in dir
    if item.endswith('gz'):
      gzfilename = os.path.join(workdirgsid,item)
      with gzip.open(gzfilename, 'rb') as file_gz:
        base_name = os.path.basename(gzfilename)
        new_name = os.path.splitext(base_name)[0]
        with open(os.path.join(workdirgsid, new_name), 'wb') as f_out:
          shutil.copyfileobj(file_gz, f_out)
          os.remove(gzfilename)

  # Keep only ges
  fileList = glob.glob(os.path.join(workdirgsid,'*anl*'))
  for filePath in fileList:
    os.remove(filePath)


  exit()




##
