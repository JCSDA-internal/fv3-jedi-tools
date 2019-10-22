#!/usr/bin/env python

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import subprocess
import os

# Datetime formats
dtformat = '%Y%m%d%H'
dtformatprnt = '%Y%m%d %Hz'


def run_bash_command(command,output):

  fname = 'bash_command.sh'

  # Create file with bash command
  fh = open(fname, "w")
  fh.write("#!/bin/bash \n")
  fh.write(command+' &> '+output)
  fh.close()

  # Make executable and run
  os.chmod(fname, 0o755)
  subprocess.call(['./bash_command.sh'])

  # Remove file
  os.remove(fname)


def lines_that_contain(string, fp):
    return [line for line in fp if string in line]
