# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import model_utils as mu

import os
import subprocess
import datetime as dt
import pathlib
import tarfile
import shutil

import yaml
import gfs_yaml as myam
import fileinput


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

    self.nProcNx = '4' # Number of processors on cube face, x direction
    self.nProcNy = '4' # Number of processors on cube face, y direction

    self.ensRes = '384' # Horizontal resolution, e.g. 384 where there are 384 by 384 per cube face.
    self.ensLev = '64'  # Number of vertical levels

    # String datetimes
    self.dateTime    = dt.datetime(1900,1,1)
    self.dateTimeRst = dt.datetime(1900,1,1)
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

    self.dirConvert = ''

  # Set time for cycle
  # ------------------
  def cycleTime(self,datetime):

    self.dateTime = datetime

    six_hours = dt.timedelta(hours=6)
    self.dateTimeRst = self.dateTime + six_hours

    self.Y = self.dateTime.strftime('%Y')
    self.m = self.dateTime.strftime('%m')
    self.d = self.dateTime.strftime('%d')
    self.H = self.dateTime.strftime('%H')
    self.YmD = self.Y+self.m+self.d

    print(" Cycle time: "+self.Y+self.m+self.d+' '+self.H+" \n")

  # Work and home directories
  # -------------------------
  def setDirectories(self):

    self.homeDir = os.getcwd()
    self.workDir = self.homeDir+'/enswork_'+self.Y+self.m+self.d+self.H

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

  # Dictionary for converting a state to psi/chi
  # --------------------------------------------
  def convertStateDict(self,path_fv3files,path_bkg,path_write):

    # Input variables
    variables = ["u","v","T","DELP","sphum","ice_wat","liq_wat","o3mr","phis"]

    # Setup
    setup = myam.setup_dict(path_fv3files)

    # Geometry
    inputresolution  = myam.geometry_dict('inputresolution' ,path_fv3files)
    outputresolution = myam.geometry_dict('outputresolution',path_fv3files)

    # States
    input  = myam.state_dict('input',path_bkg,self.dateTimeRst,variables)
    output = myam.output_dict('output',path_write)

    # Variable change
    varcha = myam.varcha_a2c_dict(path_fv3files)

    return {**setup, **inputresolution, **outputresolution, **input, **output}


  # Prepare directories for the members and the yaml files
  # ------------------------------------------------------
  def prepareConvertDirsYamls(self):

    print(" prepareConvertDirsYamls \n")

    # Move to work directory
    os.chdir(self.workDir)

    # Create directories for converted members
    Y = self.dateTimeRst.strftime('%Y')
    m = self.dateTimeRst.strftime('%m')
    d = self.dateTimeRst.strftime('%d')
    H = self.dateTimeRst.strftime('%H')

    # Path
    self.dirConvert = self.workDir+'/'+Y+m+d+'_'+H
    if not os.path.exists(self.dirConvert):
      os.makedirs(self.dirConvert)

    # Path for fv3files
    path_fv3files = self.dirConvert+'/fv3files'
    if os.path.exists(path_fv3files):
      shutil.rmtree(path_fv3files)

    # Copy fv3files
    fv3files_src = self.homeDir+'/fv3files'
    shutil.copytree(fv3files_src, path_fv3files)
    os.rename(path_fv3files+'/input.nml_template',path_fv3files+'/input.nml')

    # Update input.nml for this run
    nml_in = open(path_fv3files+'/input.nml').read()
    nml_in = nml_in.replace('NPX_DIM', str(int(self.ensRes)+1))
    nml_in = nml_in.replace('NPY_DIM', str(int(self.ensRes)+1))
    nml_in = nml_in.replace('NPZ_DIM', self.ensLev)
    nml_in = nml_in.replace('NPX_PROC', self.nProcNx)
    nml_in = nml_in.replace('NPY_PROC', self.nProcNy)
    nml_out = open(path_fv3files+'/input.nml', 'w')
    nml_out.write(nml_in)
    nml_out.close()

    # Loop over groups of members
    for e in range(self.nEns):

      memdir_done = self.dirConvert+'/mem'+str(e+1).zfill(3)

      if not os.path.exists(memdir_done):

        # Create member directory
        memdir = self.dirConvert+'/_mem'+str(e+1).zfill(3)
        if not os.path.exists(memdir):
          os.makedirs(memdir)

        # Symbolic links to prevent long paths
        path = memdir+'/fv3files'
        if os.path.exists(path):
          os.remove(path)
        os.symlink(path_fv3files, path)

        path = memdir+'/RESTART'
        if os.path.exists(path):
          os.remove(path)
        os.symlink(self.workDir+'/enkfgdas.'+self.YmD+'/'+self.H+'/mem'+str(e+1).zfill(3)+'/RESTART', path)

        # Create the yaml files
        csdict = self.convertStateDict('./fv3files','./RESTART/','./')

        # Write dictionary to yaml
        yaml_file = memdir+'/convert_state.yaml'
        with open(yaml_file, 'w') as outfile:
          yaml.dump(csdict, outfile, default_flow_style=False)

    os.chdir(self.homeDir)


  # Submit MPI job that converts the ensemble members
  # -------------------------------------------------
  def convertMembersUnbalanced(self,jbuild):

    print(" convertMembersUnbalanced \n")

    os.chdir(self.dirConvert)

    # Number of processors for job
    nprocs = str(6*int(self.nProcNx)*int(self.nProcNy))

    # Bash shell script that runs through all members
    fname = 'run.sh'
    fh = open(fname, "w")
    fh.write("#!/bin/bash\n")
    fh.write("\n")
    fh.write("#SBATCH --export=NONE\n")
    fh.write("#SBATCH --job-name=fv3jedi_ensbal\n")
    fh.write("#SBATCH --output=fv3jedi_ensbal.o%j\n")
    fh.write("#SBATCH --ntasks="+nprocs+"\n")
    fh.write("#SBATCH --account=da-cpu\n")
    fh.write("#SBATCH --time=04:00:00\n")
    fh.write("\n")
    fh.write("module use -a /scratch1/NCEPDEV/stmp4/Daniel.Holdaway/opt/modulefiles/\n")
    fh.write("module load apps/jedi/intel-17.0.5.239\n")
    fh.write("module list\n")
    fh.write("\n")
    fh.write("members=`ls -d _mem*`\n")
    fh.write("\n")
    fh.write("for mem in $members\n")
    fh.write("do\n")
    fh.write("  cd $mem\n")
    fh.write("  echo \"Working in \"$PWD\n")
    fh.write("  export build="+jbuild+"\n")
    fh.write("  mpirun -np "+nprocs+" $build/bin/fv3jedi_convertstate.x convert_state.yaml\n")
    fh.write("  export numfiles=`ls -1 *nc | wc -l`\n")
    fh.write("  cd ..\n")
    fh.write("  if [ \"$numfiles\" == \"12\" ]\n")
    fh.write("  then\n")
    fh.write("    export newdir=`echo $mem | cut -c2-`\n")
    fh.write("    mv $mem $newdir\n")
    fh.write("  fi\n")
    fh.write("done\n")
    fh.write("\n")
    fh.write("resmembers=`ls -d _mem*`\n")
    fh.write("if [ \"$resmembers\" == \"\" ]\n")
    fh.write("then\n")
    fh.write("  echo \"All members processed successfully\"\n")
    fh.write("  touch ../ConvertDone\n")
    fh.write("fi\n")

    fh.close()

    # Submit job
    mu.run_bash_command("sbatch run.sh")

    os.chdir(self.homeDir)

  # Submit MPI job that converts the ensemble members
  # -------------------------------------------------
  def tarconvertedMembers(self):




    #
