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

      # Run hsi ls command on the current file
      hsils_file = "ls_remote_member.txt"
      mu.run_bash_command("hsi ls -l "+path+file,hsils_file)

      # Search for line with file size
      found = False
      with open(hsils_file, "r") as fp:
        for line in mu.lines_that_contain("", fp):
          found = True
          size_line = line
          print (size_line)

      remote_file_size = size_line[0]

      print(remote_file_size)

      # Fail safety if unable to determine file size
      if (not found):
        print("ABORT: unable to find size of remote file")
        exit()

      exit()
