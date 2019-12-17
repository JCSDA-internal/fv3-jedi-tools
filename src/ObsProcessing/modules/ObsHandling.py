# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime as dt
import os
import shutil
import tarfile
import yaml

import Utils.modules.utils as utils

# --------------------------------------------------------------------------------------------------

class ObservationHandling:

  def __init__(self):

    self.myName = 'ObservationHandling'

# --------------------------------------------------------------------------------------------------

  def setup(self):

    # Date/time
    self.process_date_str = os.getenv('PDATE')

    # Configuration
    configfile = os.getenv('CFILE')
    with open(configfile) as file:
      self.config = yaml.load(file, Loader=yaml.FullLoader)

    # Process date datetime structure
    process_date = dt.datetime.strptime(self.process_date_str, '%Y%m%d%H')

    # Observation file
    self.obstarfile = process_date.strftime(self.config['obs_fileformat'])

# --------------------------------------------------------------------------------------------------

  def downloadObsS3(self):

    # Environment variables and config
    self.setup()

    # Create path
    utils.createdir(self.config['obs_targetpath'])

    # Retrieve from S3
    utils.recvS3(self.config['obs_targetpath'],self.obstarfile,self.config['obs_sourcepath'])

# --------------------------------------------------------------------------------------------------

  def downloadObsArchive(self):

    # Environment variables and config
    self.setup()

    # Retrieve from archive
    remote_path_file = os.path.join(self.config['obs_targetpath'],self.obstarfile)
    if os.path.exists(remote_path_file):
      shutil.copyfile(remote_path_file, self.config['obs_targetpath'])

# --------------------------------------------------------------------------------------------------

  def extractObs(self):

    # Environment variables and config
    self.setup()

    # Extract observations
    tar = tarfile.open(os.path.join(self.config['obs_targetpath'],self.obstarfile))
    tar.extractall(self.config['obs_targetpath'])
    tar.close()

# --------------------------------------------------------------------------------------------------

  def removeObsTar(self):

    # Environment variables and config
    self.setup()

    # Remove tar file
    local_path_file = os.path.join(self.config['obs_targetpath'],self.obstarfile)
    if os.path.exists(local_path_file):
      os.remove(local_path_file)

# --------------------------------------------------------------------------------------------------

  def removeObsFiles(self):

    # Environment variables and config
    self.setup()

    # Remove tar file
    local_path_file = os.path.join(self.config['obs_targetpath'],self.obstarfile)
    if os.path.exists(local_path_file):
      os.remove(local_path_file)

# --------------------------------------------------------------------------------------------------
