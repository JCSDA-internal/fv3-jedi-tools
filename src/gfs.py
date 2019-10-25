# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import model_utils as mu

import os
import subprocess
import datetime
import pathlib
import tarfile

class GFS:

  # Initialize
  # ----------

  def __init__(self):
    self.myName = 'gfs'                               # Name for this model
    self.hpssRoot = '/NCEPPROD/hpssprod/runhistory/'  # Path to archived files
    self.nGrps = 8                                    # Number of ensemble groups per cycle
    self.nEns = 80                                    # Number of ensemble members
    self.stageDir = 'stageGFS'
    self.nRstFiles = 38
    self.nEnsPerGrp = int(self.nEns/self.nGrps)

    # String datetimes
    self.Y = ''
    self.m = ''
    self.d = ''
    self.H = ''

    # Directories
    self.homeDir = ''
    self.workDir = ''
    self.ArchDone = 'ArchDone'
    self.ExtcDone = 'ExtcDone'
    self.ConvDone = 'ConvDone'
    self.ReArDone = 'ReArDone'

  # Set time for cycle
  # ------------------
  def cycleTime(self,datetime):

    self.Y = datetime.strftime('%Y')
    self.m = datetime.strftime('%m')
    self.d = datetime.strftime('%d')
    self.H = datetime.strftime('%H')
    self.YmD = self.Y+self.m+self.d

    print(" Cycle time: "+self.Y+self.m+self.d+' '+self.H+" \n")

  # Work and home directories
  # -------------------------
  def setDirectories(self):

    self.homeDir = os.getcwd()
    self.workDir = 'enswork_'+self.Y+self.m+self.d+self.H

    # Create working directory
    if not os.path.exists(self.workDir):
      os.makedirs(self.workDir)

    print(" Home directory: "+self.homeDir)
    print(" Work directory: "+self.workDir,"\n")

  # Method to get an ensemble member and stage it
  # ---------------------------------------------
  def getEnsembleMembersFromArchive(self):

    print(" getEnsembleMembersFromArchive \n")

    # Short cuts
    Y = self.Y
    m = self.m
    d = self.d
    H = self.H

    # Move to work directory
    os.chdir(self.workDir)

    all_done = True

    # Loop over groups of members
    for g in range(self.nGrps):

      # Path and file for this group of restarts
      path = self.hpssRoot+'rh'+Y+'/'+Y+m+'/'+Y+m+d+'/'
      file = ('gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas'
             '.'+Y+m+d+'_'+H+'.enkfgdas_restart_grp'+str(g+1)+'.tar')
      print(" Acquiring on "+path+file)

      # Run hsi ls command on the current file for expected size
      tailfile = "ls_remote_member.txt"
      mu.run_bash_command("hsi ls -l "+path+file,tailfile)

      # Search tail for line with file size
      remote_file_size = -1
      with open(tailfile, "r") as fp:
        for line in mu.lines_that_contain("rstprod", fp):
          remote_file_size = line.split()[4]
      os.remove(tailfile)

      # Fail if unable to determine remote file size
      if (remote_file_size == -1):
        print("ABORT: unable to find size of remote file")
        exit()

      #  Logic to determine whether to copy member. Only copied if group
      #  - Does not exist at all
      #  - The local size does not match remote size, indicating previous copy fail

      if (not os.path.exists(file)):

        print(" No attempt to get this member group yet, copying...")
        get_member_set = True

      else:

        print(" Member group copy already attempted, checking size matches remote")

        # Git size of the local file
        proc = subprocess.Popen(['ls', '-l', file], stdout=subprocess.PIPE)
        local_file_size = proc.stdout.readline().decode('utf-8').split()[4]

        # If size matches no get required, already staged
        if (local_file_size == remote_file_size):
          print(" Local size matches remote, not copying again.")
          get_member_set = False
        else:
          print(" Remote size "+str(remote_file_size)+" does not match local size ")
          print(   str(local_file_size)+" copying again.")
          get_member_set = True


      # Copy the file to stage directory
      if (get_member_set):
        print(" Copyng member group")
        tailfile = "copy_remote_member.txt"
        mu.run_bash_command("hsi get "+path+file, tailfile)

      # Check that the files are copied properly
      if (not os.path.exists(file)):
        mem_failed = True
      else:
        proc = subprocess.Popen(['ls', '-l', file], stdout=subprocess.PIPE)
        new_local_file_size = proc.stdout.readline().decode('utf-8').split()[4]
        if (new_local_file_size == remote_file_size):
          mem_failed = False
        else:
          mem_failed = True

      if (mem_failed):
        all_done = False

    # Create file to indicate this part is done
    if (all_done):
      pathlib.Path(self.ArchDone).touch()

    os.chdir(self.homeDir)


  # Check for expected number of restarts in path
  # ---------------------------------------------
  def checkGfsRestartFiles(self,path):
    if os.path.exists(path):
      return len(os.listdir(path)) == self.nRstFiles
    else:
      return False


  # Extract each group of ensemble members
  # --------------------------------------
  def extractEnsembleMembers(self):

    print(" extractEnsembleMembers \n")

    # Move to work directory
    os.chdir(self.workDir)

    all_done = True

    # Loop over groups of members
    for g in range(self.nGrps):

      # File to extract
      file = ('gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas'
             '.'+self.Y+self.m+self.d+'_'+self.H+'.enkfgdas_restart_grp'+str(g+1)+'.tar')
      print(" Extracting "+file)

      # Member range for group
      memStart = g*self.nEnsPerGrp+1
      memFinal = g*self.nEnsPerGrp+10

      # Check whether extracted files already exist
      do_untar = False
      for e in range(memStart,memFinal+1):
        path_rst = 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/RESTART/'
        done_mem = self.checkGfsRestartFiles(path_rst)
        if (not done_mem):
          do_untar = True

      # Extract file
      if (do_untar):
        tailfile = "untar_remote_member.txt"
        mu.run_bash_command("tar -xvf ./"+file, tailfile)

      # Clean up non-restart files
      for e in range(memStart,memFinal+1):
        files = ['enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/gdas.t06z.abias',
                 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/gdas.t06z.abias_air',
                 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/gdas.t06z.abias_int',
                 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/gdas.t06z.abias_pc',
                 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/gdas.t06z.atminc.nc',
                 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/gdas.t06z.cnvstat',
                 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/gdas.t06z.gsistat',
                 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/gdas.t06z.oznstat',
                 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/gdas.t06z.radstat']
        for f in range(len(files)):
          if os.path.exists(files[f]):
            os.remove(files[f])

      # Recheck for success
      do_untar = False
      for e in range(memStart,memFinal+1):
        path_rst = 'enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e).zfill(3)+'/RESTART/'
        done_mem = self.checkGfsRestartFiles(path_rst)
        if (not done_mem):
          do_untar = True

      if do_untar:
        all_done = False

    # Create file to indicate this part is done
    if (all_done):
      pathlib.Path(self.ExtcDone).touch()

    os.chdir(self.homeDir)


  # Remove tar files obtained from the arhcive
  # ------------------------------------------

  def removeEnsembleArchiveFiles(self):

    print(" removeEnsembleArchiveFiles \n")

    # Move to work directory
    os.chdir(self.workDir)

    # Loop over groups of members
    for g in range(self.nGrps):

      # File to extract
      file = ('gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas'
             '.'+self.Y+self.m+self.d+'_'+self.H+'.enkfgdas_restart_grp'+str(g+1)+'.tar')

      # Remove the file
      if os.path.exists(file):
        print( " Removing "+file)
        os.remove(file)

    os.chdir(self.homeDir)


  # Prepare directories for the members and the yaml files
  # ------------------------------------------------------
  def prepareConvertDirsYamls(self):

    print(" prepareConvertDirsYamls")

    # Move to work directory
    os.chdir(self.workDir)

    # Create directories for converted members
    dir_convert = self.Y+self.m+self.d+'_'+self.H
    if not os.path.exists(dir_convert):
      os.makedirs(dir_convert)

    os.chdir(dir_convert)

    # Loop over groups of members
    for g in range(self.nEns):

      memdir = 'mem'+str(g+1).zfill(3)
      if not os.path.exists(memdir):
        os.makedirs(memdir)

      # Create the yaml files


    os.chdir(self.homeDir)





#  def convertMembersUnbalanced(command,tail='tail.txt'):
#
#    # Create slurm file
#    fname = 'run.sh'
#    fh = open(fname, "w")
#
#    fh.write("#!/bin/bash \n\n")
#    fh.write("#SBATCH --export=NONE \n")
#    fh.write("#SBATCH --job-name=convert_gfs_ens \n")
#    fh.write("#SBATCH --output=convert_gfs_ens.o%log \n")
#    fh.write("#SBATCH --ntasks=96 \n")
#    fh.write("#SBATCH --ntasks-per-node=32 \n")
#    fh.write("#SBATCH --constraint=da \n")
#    fh.write("#SBATCH --time=08:00:00 \n")
