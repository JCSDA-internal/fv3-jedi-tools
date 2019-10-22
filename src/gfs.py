# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import model_utils as mu

import os
import subprocess
import datetime

class GFS:

  # Initialize
  # ----------

  def __init__(self):
    self.myName = 'gfs'                               # Name for this model
    self.hpssRoot = '/NCEPPROD/hpssprod/runhistory/'  # Path to archived files
    self.nGrps = 8                                    # Number of ensemble groups per cycle
    self.stageDir = 'stageGFS'

  def __del__(self):
    if not os.listdir(self.stageDir) :
      os.rmdir(self.stageDir)
    else:
      print("WARNING: directory ",self.stageDir, " was not left empty.")

  # Method to get an ensemble member and stage it
  # ---------------------------------------------

  def getEnsembleMembers(self,datetime):

    for g in range(self.nGrps):

      Y = datetime.strftime('%Y')
      m = datetime.strftime('%m')
      d = datetime.strftime('%d')
      H = datetime.strftime('%H')

      path = self.hpssRoot+'rh'+Y+'/'+Y+m+'/'+Y+m+d+'/'
      file = ('gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas'
             '.'+Y+m+d+'_'+H+'.enkfgdas_restart_grp'+str(g+1)+'.tar')

      print(" Working on "+path+file)

      # Create directory to stage files
      if not os.path.exists(self.stageDir):
        os.makedirs(self.stageDir)

      remote_file_ls = subprocess.check_output(['ls', '-l', path+file]).split(" ")
      archive_size = remote_file_ls[7]

      print(archive_size)

      exit()
