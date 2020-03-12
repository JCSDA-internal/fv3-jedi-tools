# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime
import os
import shutil
import tarfile
import yaml

import fv3jeditools.Utils.utils as utils

# --------------------------------------------------------------------------------------------------

class EnsembleHandling:

  def __init__(self):

    self.myName = 'EnsembleHandling'

# --------------------------------------------------------------------------------------------------

  def setup(self):

    # Date/time
    self.process_date_str = os.getenv('WINMID')

    # Configuration
    configfile = os.getenv('CFILE')
    with open(configfile) as file:
      self.cf = yaml.load(file, Loader=yaml.FullLoader)

    # Number of members
    self.nEns = self.cf['ensemble_size']

    # Analysis time
    self.analysis_date = datetime.datetime.strptime(self.process_date_str, '%Y%m%d%H')

    # Window times
    self.winbeg_date = self.analysis_date - datetime.timedelta(hours = int(self.cf['window_length'])/2)
    self.winend_date = self.analysis_date + datetime.timedelta(hours = int(self.cf['window_length'])/2)

# --------------------------------------------------------------------------------------------------

  def downloadGeosEnsRestartArchive(self):

    # Environment variables and config
    self.setup()

    # Set times in path and filename
    ens_sourcepath = self.winbeg_date.strftime(self.cf['ens_sourcepath'])
    ens_tarfile = self.winbeg_date.strftime(self.cf['ens_tarfile'])

    # Full paths
    remot_path_tarfile = os.path.join(ens_sourcepath,ens_tarfile)

    # Open the tar file
    tf = tarfile.open(remot_path_tarfile)

    # All members of tar file
    tarmembers = tf.getmembers()

    # Loop over ensemble size
    for n in range(1,self.nEns+1):

      print("Working on ensemble member: ",n," of ",self.nEns)

      memstr = 'mem'+str(n).zfill(3)

      # Loop over restart files
      for ens_file in self.cf['ens_files']:

        # Split off extension
        ens_tarfile_nam, ens_tarfile_ext = os.path.splitext(ens_tarfile)

        # File name with correct date
        ens_int_file = os.path.join(ens_tarfile_nam,memstr,self.winbeg_date.strftime(ens_file))

        # Get file size in tar and position
        remote_file_size = -1
        for n in range(len(tarmembers)):
          if tarmembers[n].name == ens_int_file:
            remote_file_size = tarmembers[n].size
            break

        # Fail if not in restart file
        if remote_file_size == -1:
          utils.abort("EnsembleHandling.downloadGeosEnsRestartArchive restart file "+ens_int_file+" not available in restart tar")

        # Local file
        local_path_file = os.path.join(self.cf['ens_targetpath'],ens_int_file)

        # Get local size
        local_file_size = utils.getFileSize(local_path_file)

        # Extract file
        if local_file_size != remote_file_size:
          print("downloadGeosRestartArchive: getting restart ",ens_int_file)
          tf.extractall(self.cf['ens_targetpath'],members=tarmembers[n:n+1])
        else:
          print("downloadGeosRestartArchive: already have restart ",ens_int_file)

    tf.close()

# --------------------------------------------------------------------------------------------------
