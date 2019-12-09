#!/usr/bin/env python

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import subprocess
import os
import pathlib

# --------------------------------------------------------------------------------------------------

# Datetime formats
dtformat = '%Y%m%d%H'
dtformatprnt = '%Y%m%d %Hz'

# --------------------------------------------------------------------------------------------------

def run_bash_command(path,command,tail='',verbose='yes'):

  fname = os.path.join(path,'bash_command.sh')

  if tail=='':
    full_command = command
  else:
    full_command = command+' > '+tail+' 2>&1'

  # Create file with bash command
  fh = open(fname, "w")
  fh.write("#!/bin/bash \n")
  fh.write(full_command)
  fh.close()

  # Make executable
  os.chmod(fname, 0o755)

  # Run
  if (verbose=='yes'):
    print(" Run bash command: "+full_command)
  cwd = os.getcwd()
  os.chdir(path)
  subprocess.call(['./bash_command.sh'])
  os.chdir(cwd)

  # Remove file
  os.remove(fname)

  # User didn't request any output
  #if (tail=='tail.txt'):
    #os.remove(os.path.join(path,'tail.txt'))

# --------------------------------------------------------------------------------------------------

def lines_that_contain(string, fp):
    return [line for line in fp if string in line]

# --------------------------------------------------------------------------------------------------

def abort(message):

  print('ABORT: '+message)
  raise(SystemExit)

# --------------------------------------------------------------------------------------------------

def isDone(path,funcname):

  filename = os.path.join(path,funcname)

  if os.path.exists(filename):
    print(" \n Function: "+funcname+" is complete")
    return True
  else:
    print(" \n Function: "+funcname)
    return False

# ------------------------------------------------------------------------------------------------

def setDone(path,funcname):

  print(" Function: "+funcname+" is complete")
  filename = os.path.join(path,funcname)
  pathlib.Path(filename).touch()

# --------------------------------------------------------------------------------------------------

def depends(path,func,funcdepends):

  filename = os.path.join(path,funcdepends)

  if os.path.exists(filename):
    print(" Dependencies of "+func+" are complete")
    return
  else:
    abort(" dependencies of "+func+" are not complete")

# ------------------------------------------------------------------------------------------------

def ship2S3(localpath,localfile,s3path):


  # Local file
  # ----------
  file2ship = os.path.join(localpath,localfile)


  # Path on S3
  # ----------
  s3file = os.path.join(s3path,localfile)


  # File size locally
  # -----------------
  local_file_size = -1
  if (os.path.exists(file2ship)):
    local_file_size = int(os.path.getsize(file2ship))


  # File size on S3
  # ---------------
  tailfile = os.path.join(localpath,"ls_remote_file.txt")
  run_bash_command(localpath, "aws2 s3 ls "+s3file, tailfile)


  # Check size on S3 if existing
  # ----------------------------
  remote_file_size = -1
  with open(tailfile, "r") as fp:
    for line in lines_that_contain(localfile, fp):
      remote_file_size = int(line.split()[2])
  os.remove(tailfile)


  # Copy if sizes do not match
  # --------------------------
  if local_file_size != remote_file_size:

    # Copy file to S3
    run_bash_command(localpath, "aws2 s3 cp "+file2ship+" "+s3file)

    # Recheck File size on S3
    # -----------------------
    tailfile = os.path.join(localpath,"ls_remote_file.txt")
    run_bash_command(localpath, "aws2 s3 ls "+s3file, tailfile)

    remote_file_size = -1
    with open(tailfile, "r") as fp:
      for line in lines_that_contain(localfile, fp):
        remote_file_size = int(line.split()[2])
    os.remove(tailfile)

    # Fail if not matching
    if local_file_size != remote_file_size:
      abort("utils.ship2S3, local size ("+str(local_file_size)+") does not match S3 size ("+str(remote_file_size)+")")

  else:

    print("utils.ship2S3 file of same size already on S3")

# ------------------------------------------------------------------------------------------------
