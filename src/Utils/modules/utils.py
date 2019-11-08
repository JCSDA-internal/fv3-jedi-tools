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

def run_bash_command(path,command,tail='tail.txt'):

  fname = os.path.join(path,'bash_command.sh')

  full_command = command+' > '+tail+' 2>&1'

  # Create file with bash command
  fh = open(fname, "w")
  fh.write("#!/bin/bash \n")
  fh.write(full_command)
  fh.close()

  # Make executable
  os.chmod(fname, 0o755)

  # Run
  print(" Run bash command: "+full_command)
  cwd = os.getcwd()
  os.chdir(path)
  subprocess.call(['./bash_command.sh'])
  os.chdir(cwd)

  # Remove file
  os.remove(fname)

  # User didn't request any output
  if (tail=='tail.txt'):
    os.remove(os.path.join(path,'tail.txt'))

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
