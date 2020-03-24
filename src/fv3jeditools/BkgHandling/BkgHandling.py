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

__all__ = ['BackgroundHandling']

# --------------------------------------------------------------------------------------------------


class BackgroundHandling:

    def __init__(self):

        self.myName = 'BackgroundHandling'

# --------------------------------------------------------------------------------------------------

    def setup(self):

        # Date/time
        self.process_date_str = os.getenv('PDATE')

        # Configuration
        configfile = os.getenv('CFILE')
        with open(configfile) as file:
            self.cf = yaml.load(file, Loader=yaml.FullLoader)

        # Analysis time
        self.analysis_date = datetime.datetime.strptime(
            self.process_date_str, '%Y%m%d%H')

        # Background time
        self.winbeg_date = self.analysis_date - \
            datetime.timedelta(hours=int(self.cf['window_length'])/2)
        self.winend_date = self.analysis_date + \
            datetime.timedelta(hours=int(self.cf['window_length'])/2)

# --------------------------------------------------------------------------------------------------

    def downloadGeosRestartArchive(self):

        # Environment variables and config
        self.setup()

        # Set times in path and filename
        rst_sourcepath = self.winbeg_date.strftime(self.cf['rst_sourcepath'])
        rst_file = self.winbeg_date.strftime(self.cf['rst_tarfile'])

        # Create path
        utils.createPath(self.cf['rst_targetpath'])

        # Full paths
        remot_path_tarfile = os.path.join(rst_sourcepath, rst_file)

        # Open the tar file
        tf = tarfile.open(remot_path_tarfile)

        # All members of tar file
        members = tf.getmembers()

        # Loop over restart files
        for rst_file in self.cf['rst_files']:

            # File name with correct date
            rst_int_file = self.winbeg_date.strftime(rst_file)

            # Get file size in tar
            remote_file_size = -1
            memnum = 0
            for n in range(len(members)):
                if members[n].name == rst_int_file:
                    remote_file_size = members[n].size
                    break

            # Fail if not in restart file
            if remote_file_size == -1:
                utils.abort("BackgroundHandling.downloadGeosRestartArchive restart file " +
                            rst_int_file+" not available in restart tar")

            # Local file
            local_path_file = os.path.join(
                self.cf['rst_targetpath'], rst_int_file)

            # Get local size
            local_file_size = utils.getFileSize(local_path_file)

            # Extract file
            if local_file_size != remote_file_size:
                print("downloadGeosRestartArchive: getting restart ", rst_int_file)
                tf.extractall(self.cf['rst_targetpath'],
                              members=members[n:n+1])
            else:
                print("downloadGeosRestartArchive: already have restart ", rst_int_file)

        tf.close()

# --------------------------------------------------------------------------------------------------

    def getGeosBackgrounds(self):

        # Environment variables and config
        self.setup()

        # Loop over datetimes
        dtformat = '%Y%m%d_%H%M'
        start = self.winbeg_date.strftime(dtformat)
        final = self.winend_date.strftime(dtformat)

        # Loop over timesteps of window
        dts = utils.getDateTimes(
            start, final, float(self.cf['timestep']), dtformat)

        restart_date = self.winbeg_date - datetime.timedelta(hours=6)

        bkg_sourcepath = restart_date.strftime(self.cf['bkg_sourcepath'])

# TODO dmget the files first

        # Copy the background file
        for dt in dts:

            bkg_file_ = self.cf['bkg_file'].split('+')

            bkg_file_1 = restart_date.strftime(bkg_file_[0])
            bkg_file_2 = dt.strftime(bkg_file_[1])

            bkg_file = bkg_file_1+'+'+bkg_file_2

            bkg_path_file_source = os.path.join(bkg_sourcepath, bkg_file)
            bkg_path_file_target = os.path.join(
                self.cf['bkg_targetpath'], bkg_file)

            source_file_size = utils.getFileSize(bkg_path_file_source)
            target_file_size = utils.getFileSize(bkg_path_file_target)

            if source_file_size == -1:
                utils.abort("BackgroundHandling.getGeosBackgrounds background file " +
                            bkg_path_file_source+" not available")

            if source_file_size != target_file_size:
                print("getGeosBackgrounds: copying background ", bkg_file)
                shutil.copyfile(bkg_path_file_source, bkg_path_file_target)
            else:
                print("getGeosBackgrounds: already have background ", bkg_file)

# --------------------------------------------------------------------------------------------------

    def removeBkgTar(self):

        # Environment variables and config
        self.setup()

# --------------------------------------------------------------------------------------------------

    def removeBkgFiles(self):

        # Environment variables and config
        self.setup()

# --------------------------------------------------------------------------------------------------
