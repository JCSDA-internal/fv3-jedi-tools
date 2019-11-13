# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import os
import subprocess
import datetime as dt
import pathlib
import tarfile
import shutil
import time
import yaml
import json
from random import randint
import inspect
import re
import glob

import Config.modules.gfs_conf as modconf
import Utils.modules.utils as utils

# --------------------------------------------------------------------------------------------------

class GFS:

  def __init__(self):

    # Initialize

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

    self.yamlOrJson = 'yaml'

    # String datetimes
    self.dateTime    = dt.datetime(1900,1,1)
    self.dateTimeRst = dt.datetime(1900,1,1)
    self.Y = ''
    self.m = ''
    self.d = ''
    self.H = ''
    self.YRst = ''
    self.mRst = ''
    self.dRst = ''
    self.HRst = ''
    self.YmDRst = ''
    self.YmD_HRst = ''

    # Directories
    self.homeDir = ''
    self.rootDir = ''
    self.workDir = ''
    self.dataDir = ''
    self.fv3fDir = ''
    self.trakDir = ''
    self.convertDir = ''

    # Section done markers
    self.Working = 'no'

    # Tar file for finished product
    self.tarFile = ''

    # Path on S3 for GFS
    self.s3path = 's3://fv3-jedi/StaticB/gfs_ensemble/'


  # ------------------------------------------------------------------------------------------------

  def cycleTime(self,datetime):

    # Set time information for this cycle

    self.dateTime = datetime

    six_hours = dt.timedelta(hours=6)
    self.dateTimeRst = self.dateTime + six_hours

    self.Y = self.dateTime.strftime('%Y')
    self.m = self.dateTime.strftime('%m')
    self.d = self.dateTime.strftime('%d')
    self.H = self.dateTime.strftime('%H')
    self.YRst = self.dateTimeRst.strftime('%Y')
    self.mRst = self.dateTimeRst.strftime('%m')
    self.dRst = self.dateTimeRst.strftime('%d')
    self.HRst = self.dateTimeRst.strftime('%H')

    self.YmD   = self.Y+self.m+self.d
    self.YmD_H = self.Y+self.m+self.d+"_"+self.H
    self.YmDRst   = self.YRst+self.mRst+self.dRst
    self.YmD_HRst = self.YRst+self.mRst+self.dRst+"_"+self.HRst

    print("\n")
    print(" Cycle time: "+self.Y+self.m+self.d+' '+self.H)
    print(" -----------------------\n")

  # ------------------------------------------------------------------------------------------------

  def abort(self,message):

    print('ABORT: '+message)
    os.remove(self.Working)
    raise(SystemExit)

  # ------------------------------------------------------------------------------------------------

  def setDirectories(self,work_dir,data_dir):

    # Setup the work and home directories

    self.homeDir = os.getcwd()
    self.dataDir = data_dir
    self.rootDir = work_dir
    self.workDir = os.path.join(work_dir,'enswork_'+self.Y+self.m+self.d+self.H)
    self.trakDir = os.path.join(self.workDir,'Tracking')

    # Create working directory
    if not os.path.exists(self.workDir):
      os.makedirs(self.workDir)

    # Create tracking directory
    if not os.path.exists(self.trakDir):
      os.makedirs(self.trakDir)

    # Working flag
    self.Working = os.path.join(self.trakDir,'working')

    if (os.path.exists(self.Working)):
      print('ABORT: '+self.Working+' exists. Already running or previous fail ...')
      raise(SystemExit)

    # Directory for converted members
    self.convertDir = os.path.join(self.workDir,self.YRst+self.mRst+self.dRst+'_'+self.HRst)

    if not os.path.exists(self.convertDir):
      os.makedirs(self.convertDir)

    # Create working file
    pathlib.Path(self.Working).touch()

    # Path for fv3files
    self.fv3fDir = os.path.join(self.convertDir,'fv3files')

    # Tar file name for finished product
    self.tarFile = 'ens_'+self.YmD_HRst+'.tar'

    print(" Home directory: "+self.homeDir)
    print(" Work directory: "+self.workDir)

  # ------------------------------------------------------------------------------------------------

  def finished(self):

    # Remove the working flag
    os.remove(self.Working)

  # ------------------------------------------------------------------------------------------------

  def getEnsembleMembersFromArchive(self):

    # Method to get an ensemble member and stage it
    myname = 'getEnsembleMembersFromArchive'

    # Check if done
    if utils.isDone(self.trakDir,myname):
      return

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

      # File name
      file = ('gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas'
             '.'+Y+m+d+'_'+H+'.enkfgdas_restart_grp'+str(g+1)+'.tar')

      # File on hpss
      remote_file = os.path.join(self.hpssRoot+'rh'+Y,Y+m,Y+m+d,file)

      print(" Acquiring "+remote_file)

      # Run hsi ls command on the current file for expected size
      tailfile = "ls_remote_member.txt"
      utils.run_bash_command(self.workDir, "hsi ls -l "+remote_file,tailfile)

      # Search tail for line with file size
      remote_file_size = -1
      with open(tailfile, "r") as fp:
        for line in utils.lines_that_contain("rstprod", fp):
          remote_file_size = line.split()[4]
      os.remove(tailfile)

      # Fail if unable to determine remote file size
      if (remote_file_size == -1):
        self.abort('unable to determine size of remote file')

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
        utils.run_bash_command(self.workDir, "hsi get "+remote_file)

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
      utils.setDone(self.trakDir,myname)

    os.chdir(self.homeDir)

  # ------------------------------------------------------------------------------------------------

  def checkGfsRestartFiles(self,path):

    # Check for expected number of restarts in path

    if os.path.exists(path):
      return len(os.listdir(path+'/')) == self.nRstFiles
    else:
      return False

  # ------------------------------------------------------------------------------------------------

  def extractEnsembleMembers(self):

    # Extract each group of ensemble members

    myname = 'extractEnsembleMembers'

    # Check if done and depends
    if utils.isDone(self.trakDir,myname):
      return
    utils.depends(self.trakDir,myname,'getEnsembleMembersFromArchive')

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
        path_rst = os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'RESTART')
        done_mem = self.checkGfsRestartFiles(path_rst)
        if (not done_mem):
          do_untar = True

      # Extract file
      if (do_untar):
        utils.run_bash_command(self.workDir, "tar -xvf "+file)
      else:
        print("  Extraction already done")

      # Clean up non-restart files
      for e in range(memStart,memFinal+1):
        files = [os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t'+self.H+'z.abias'),
                 os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t'+self.H+'z.abias_air'),
                 os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t'+self.H+'z.abias_int'),
                 os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t'+self.H+'z.abias_pc'),
                 os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t'+self.H+'z.atminc.nc'),
                 os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t'+self.H+'z.cnvstat'),
                 os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t'+self.H+'z.gsistat'),
                 os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t'+self.H+'z.oznstat'),
                 os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t'+self.H+'z.radstat')]
        for f in range(len(files)):
          if os.path.exists(files[f]):
            os.remove(files[f])

      # Recheck for success
      do_untar = False
      for e in range(memStart,memFinal+1):
        path_rst = os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'RESTART')
        done_mem = self.checkGfsRestartFiles(path_rst)
        if (not done_mem):
          do_untar = True

      if do_untar:
        all_done = False

    # Create file to indicate this part is done
    if (not all_done):
      self.abort("extractEnsembleMembers failed")

    # Rename from month to convertDir
    os.rename(os.path.join(self.workDir,'enkfgdas.'+self.YmD,self.H), self.convertDir)

    utils.setDone(self.trakDir,myname)

    os.chdir(self.homeDir)

  # ------------------------------------------------------------------------------------------------

  def postExtractEnsembleMembers(self):

    myname = 'postExtractEnsembleMembers'

    # Check if done and depends
    if utils.isDone(self.trakDir,myname):
      return
    utils.depends(self.trakDir,myname,'extractEnsembleMembers')

    removes = ['*sfcanl_data*','*fv_srf_wnd*','*phy_data*','*sfc_data*','fv_core.res.nc']

    # Remove files not needed again
    for e in range(1,self.nEns+1):

      for r in range(len(removes)):
        file_list = glob.glob(os.path.join(self.convertDir,'mem'+str(e).zfill(3),'RESTART',removes[r]))
        for file_path in file_list:
          os.remove(file_path)

    # Remove residual directories
    dir = os.path.join(self.workDir,'enkfgdas.'+self.YmD)
    if os.path.exists(dir):
      shutil.rmtree(dir)

    dir = os.path.join(self.workDir,'tmpnwprd1')
    if os.path.exists(dir):
      shutil.rmtree(dir)

    utils.setDone(self.trakDir,myname)

  # ------------------------------------------------------------------------------------------------

  def removeEnsembleArchiveFiles(self):

    # Remove tar files obtained from the arhcive

    # Check if done and depends
    myname = 'removeEnsembleArchiveFiles'
    if utils.isDone(self.trakDir,myname):
      return
    utils.depends(self.trakDir,myname,'postExtractEnsembleMembers')

    # Loop over groups of members
    for g in range(self.nGrps):

      # File to extract
      file = ('gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas'
             '.'+self.Y+self.m+self.d+'_'+self.H+'.enkfgdas_restart_grp'+str(g+1)+'.tar')

      pathfile = os.path.join(self.workDir,file)

      # Remove the file
      if os.path.exists(pathfile):
        print( " Removing "+pathfile)
        os.remove(pathfile)

    # Set as done
    utils.setDone(self.trakDir,myname)

  # ------------------------------------------------------------------------------------------------

  def __preparefv3Files(self):

    # First remove fv3files path if it exists
    if os.path.exists(self.fv3fDir):
      shutil.rmtree(self.fv3fDir)

    # Copy from the user provided Data directory
    shutil.copytree(os.path.join(self.dataDir,'fv3files'), self.fv3fDir)

    # Update input.nml for this run
    nml_in = open(os.path.join(self.fv3fDir,'input.nml_template')).read()
    nml_in = nml_in.replace('NPX_DIM', str(int(self.ensRes)+1))
    nml_in = nml_in.replace('NPY_DIM', str(int(self.ensRes)+1))
    nml_in = nml_in.replace('NPZ_DIM', self.ensLev)
    nml_in = nml_in.replace('NPX_PROC', self.nProcNx)
    nml_in = nml_in.replace('NPY_PROC', self.nProcNy)
    nml_out = open(os.path.join(self.fv3fDir,'input.nml'), 'w')
    nml_out.write(nml_in)
    nml_out.close()

  # ------------------------------------------------------------------------------------------------

  # Dictionary for converting a state to psi/chi

  def __convertStatesDict(self,varchange='id',output_name=''):


    # Geometry
    inputresolution  = modconf.geometry_dict('inputresolution' ,'fv3files')
    outputresolution = modconf.geometry_dict('outputresolution','fv3files')

    # Variable change
    if (varchange == 'a2c'):
      varcha = modconf.varcha_a2c_dict('fv3files')
    else:
      varcha = modconf.varcha_id_dict(["u","v","T","DELP","sphum","ice_wat","liq_wat","o3mr","phis"])

    input  = {}
    output = {}

    dict_states = {}
    dict_states["states"] = []

    for e in range(1,self.nEns+1):

      path_mem_in  = 'mem'+str(e).zfill(3)+'/RESTART/'
      path_mem_out = 'mem'+str(e).zfill(3)+'/'

      # Input/output for member
      input  = modconf.state_dict('input', path_mem_in, self.dateTimeRst)
      output = modconf.output_dict('output', path_mem_out, output_name)
      inputout = {**input, **output}

      dict_states["states"].append(inputout)

    return {**inputresolution, **outputresolution, **varcha, **dict_states}

  # ------------------------------------------------------------------------------------------------

  def prepare2Convert(self):

    # Prepare directories for the members and the configuration files

    # Check if done and depends
    myname = 'prepare2Convert'
    if utils.isDone(self.trakDir,myname):
      return
    utils.depends(self.trakDir,myname,'removeEnsembleArchiveFiles')

    self.__preparefv3Files()

    # Create the config files
    csdict = self.__convertStatesDict('a2c','')

    # Write dictionary to config file
    conf_file = os.path.join(self.convertDir,'convert_states.'+self.yamlOrJson)
    with open(conf_file, 'w') as outfile:
      if self.yamlOrJson == 'yaml':
        yaml.dump(csdict, outfile, default_flow_style=False)
      elif self.yamlOrJson == 'json':
        json.dump(csdict, outfile)

    # Set as done
    utils.setDone(self.trakDir,myname)

  # ------------------------------------------------------------------------------------------------

  # Submit MPI job that converts the ensemble members

  def convertMembersSlurm(self,machine,nodes,taskspernode,hours,jbuild):

    # Check if done and depends
    myname = 'convertMembersSlurm'
    if utils.isDone(self.trakDir,myname):
      return
    utils.depends(self.trakDir,myname,'prepare2Convert')


    # Number of processors for job
    nprocs = str(6*int(self.nProcNx)*int(self.nProcNy))

    # Filename
    fname = os.path.join(self.convertDir,'run.sh')

    # Job ID
    jobid = randint(1000000,9999999)
    jobnm = "convertstates."+str(jobid)

    # Hours
    hh = str(hours).zfill(2)

    # Bash shell script that runs through all members
    fh = open(fname, "w")
    fh.write("#!/bin/bash\n")
    fh.write("\n")

    fh.write("#SBATCH --export=NONE\n")
    fh.write("#SBATCH --job-name="+jobnm+"\n")
    fh.write("#SBATCH --output="+jobnm+".log\n")
    if machine == 'discover':
      fh.write("#SBATCH --partition=compute\n")
      fh.write("#SBATCH --account=g0613\n")
      fh.write("#SBATCH --qos=advda\n")
    elif machine == 'hera':
      fh.write("#SBATCH --account=da-cpu\n")
    fh.write("#SBATCH --nodes="+str(nodes)+"\n")
    fh.write("#SBATCH --ntasks-per-node="+str(taskspernode)+"\n")
    fh.write("#SBATCH --time="+hh+":00:00\n")

    fh.write("\n")

    fh.write("source /usr/share/modules/init/bash\n")
    fh.write("module purge\n")
    if machine == 'discover':
      fh.write("module use -a /discover/nobackup/projects/gmao/obsdev/rmahajan/opt/modulefiles\n")
      fh.write("module load apps/jedi/intel-17.0.7.259\n")
    elif machine == 'hera':
      fh.write("module use -a /scratch1/NCEPDEV/da/Daniel.Holdaway/opt/modulefiles/\n")
      fh.write("module load apps/jedi/intel-19.0.5.281\n")
    fh.write("module list\n")

    fh.write("\n")
    fh.write("cd "+self.convertDir+"\n")
    fh.write("\n")
    #fh.write("export OOPS_TRACE=1\n")
    fh.write("export build="+jbuild+"\n")
    fh.write("mpirun -np "+nprocs+" $build/bin/fv3jedi_convertstate.x convert_states."+self.yamlOrJson+"\n")
    fh.write("\n")
    fh.close()


    # Submit job
    os.chdir(self.convertDir)
    utils.run_bash_command(self.convertDir, "sbatch "+fname)
    os.chdir(self.homeDir)

    # Wait for finish
    print(" Waiting for sbatch job to finish")

    done_convert = False
    print_job = True
    while not done_convert:

      proc = subprocess.Popen(['squeue', '-l', '-h', '-n', jobnm], stdout=subprocess.PIPE)
      squeue_res = proc.stdout.readline().decode('utf-8')

      if print_job:
        print(" Slurm job info: ")
        print(squeue_res)
        print_job = False

      if squeue_res is '':
        done_convert = True
        print(' Slurm job is finished, checking for success...')
        break

      # If not finished wait another minute
      time.sleep(60)

    # Grep for success
    with open(jobnm+'.log', "r") as fp:
      for line in fp:
        if re.search("status = 0", line):
          print(' convertMembersSlurm finished successfully')
        else:
          self.abort("convertMembersSlurm failed. Job name: "+jobnm)

    # Remove slurm job script
    os.remove(fname)

    # Set as done
    utils.setDone(self.trakDir,myname)

  # ------------------------------------------------------------------------------------------------

  def postConvertCleanUp(self):

    # Clean up large files

    # Check if done and depends
    myname = 'cleanUp'
    if utils.isDone(self.trakDir,myname):
      return
    utils.depends(self.trakDir,myname,'convertMembersSlurm')

    # Remove restart directories
    for e in range(1,self.nEns+1):

      path_mem_in  = os.path.join(self.convertDir,'mem'+str(e).zfill(3),'RESTART')
      shutil.rmtree(path_mem_in)

    # Clean up convert directory
    shutil.rmtree(os.path.join(self.convertDir,'fv3files'))
    os.remove(os.path.join(self.convertDir,'logfile.000000.out'))

    # Clean up work directory
    shutil.rmtree(os.path.join(self.workDir,'enkfgdas.'+self.YmD))

    # Set as done
    utils.setDone(self.trakDir,myname)

  # ------------------------------------------------------------------------------------------------

  def tarWorkDirectory(self):

    # Check if done and depends
    myname = 'tarWorkDirectory'
    if utils.isDone(self.trakDir,myname):
      return
    utils.depends(self.trakDir,myname,'removeEnsembleArchiveFiles')

    # Avoid absolute paths in tar file
    os.chdir(self.rootDir)

    if not os.path.exists(os.path.join(self.tarFile)):
      utils.run_bash_command(self.rootDir, "tar -cvf "+self.tarFile+" "+"enswork_"+self.Y+self.m+self.d+self.H)
    else:
      print(" Tar file for converted members already created")

    # Search tail for line with file size
    for e in range(1,self.nEns+1):

      # Check tarring process worked
      filesearch = os.path.join('enswork_'+self.Y+self.m+self.d+self.H,self.YmD_HRst,'mem'+str(e).zfill(3),'RESTART',self.YRst+self.mRst+self.dRst+'.'+self.HRst+'0000.fv_core.res.tile1.nc')

      tailfile = "tar_check.txt"
      utils.run_bash_command(self.rootDir, "tar -tvf "+self.tarFile+" "+filesearch, tailfile, 'no')

      filesearch_found = ''
      with open(tailfile, "r") as fp:
        for line in utils.lines_that_contain('failure', fp):
          filesearch_found = line
      os.remove(tailfile)

      # Abort if the check fails
      if filesearch_found != '':
        self.abort('tarWorkDirectory failed:, '+filesearch+' not found in tar file.')

    os.chdir(self.homeDir)

    # Remove the convertdir directory
    shutil.rmtree(self.convertDir)

    # Set as done
    utils.setDone(self.trakDir,myname)

  # ------------------------------------------------------------------------------------------------

  def membersFromHera(self):

    # Check if done and depends
    myname = 'membersFromHera'
    if utils.isDone(self.trakDir,myname):
      return

    # Move to root directory
    os.chdir(self.rootDir)

    hera_path = os.path.join('/scratch1','NCEPDEV','da','Daniel.Holdaway','JediScratch','StaticB','wrk','enswork_'+self.Y+self.m+self.d+self.H)
    tailfile = "ls_hera_tar.txt"
    utils.run_bash_command(self.workDir,"ssh Daniel.Holdaway@dtn-hera.fairmont.rdhpcs.noaa.gov ls -l "+hera_path+self.tarFile, tailfile)

    # Search tail for line with file size
    hera_file_size = -1
    with open(tailfile, "r") as fp:
      for line in utils.lines_that_contain(self.tarFile, fp):
        print(line)
        hera_file_size = line.split()[4]
    os.remove(tailfile)

    # Check if copy already attempted
    disc_file_size = -1
    if (os.path.exists(self.tarFile)):
      proc = subprocess.Popen(['ls', '-l', self.tarFile], stdout=subprocess.PIPE)
      disc_file_size = proc.stdout.readline().decode('utf-8').split()[4]

    # If not matching in file size copy
    if not hera_file_size == disc_file_size:
      print(' Copying:')
      tailfile = "scp_hera_tar.txt"
      utils.run_bash_command(self.workDir,"scp Daniel.Holdaway@dtn-hera.fairmont.rdhpcs.noaa.gov:"+hera_path+self.tarFile+" ./", tailfile)
      os.remove(tailfile)

    # Check copy was successful
    disc_file_size = -1
    if (os.path.exists(self.tarFile)):
      proc = subprocess.Popen(['ls', '-l', self.tarFile], stdout=subprocess.PIPE)
      disc_file_size = proc.stdout.readline().decode('utf-8').split()[4]

    if not hera_file_size == disc_file_size:
      self.abort(' In copying from hera there\'s a size discrepancy')

    # Set as done
    utils.setDone(self.trakDir,myname)

    os.chdir(self.homeDir)

  # ------------------------------------------------------------------------------------------------

  # Untar the converted members

  def extractWorkDirectory(self):

    myname = 'extractWorkDirectory'
    if utils.isDone(self.trakDir,myname):
      return
    utils.depends(self.trakDir,myname,'membersFromHera')

    # Move to root directory
    os.chdir(self.rootDir)

    # Move to work directory
    os.chdir(self.workDir)

    tailfile = "untar_converted_members.txt"
    utils.run_bash_command(self.workDir, "tar -xvf "+self.tarFile, tailfile)

    # Move to root directory
    os.chdir(self.homeDir)

    # Set as done
    utils.setDone(self.trakDir,myname)

  # ------------------------------------------------------------------------------------------------

  def ship2S3(self):

    myname = 'ship2S3'
    if utils.isDone(self.trakDir,myname):
      return
    utils.depends(self.trakDir,myname,'membersFromHera')

    utils.run_bash_command(self.workDir, "aws s3 cp "+self.rootDir+self.tarFile+" "+self.s3path)

    # File size on Discover
    local_file = os.path.join(self.rootDir,self.tarFile)
    local_file_size = -1
    if (os.path.exists(local_file)):
      proc = subprocess.Popen(['ls', '-l', local_file], stdout=subprocess.PIPE)
      local_file_size = proc.stdout.readline().decode('utf-8').split()[4]

    # File size on S3
    tailfile = "ls_remote_file.txt"
    utils.run_bash_command(self.workDir, "aws s3 ls "+os.path.join(self.s3path,self.tarFile), tailfile)

    # Search tail for line with file size
    remote_file_size = -1
    with open(tailfile, "r") as fp:
      for line in utils.lines_that_contain("rstprod", fp):
        remote_file_size = line.split()[4]
    os.remove(tailfile)

    # Fail if not matching
    if local_file_size != remote_file_size:
      self.abort("Local size does not match S3 size")

    # Set as done
    utils.setDone(self.trakDir,myname)

  # ------------------------------------------------------------------------------------------------
