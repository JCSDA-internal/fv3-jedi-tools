# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import glob
import os
import shutil
import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package remove
#  This function takes a yaml file configuration as well as a datetime. It will remove files or
#  directories
# --------------------------------------------------------------------------------------------------

def remove(datetime, conf):

    # Remove files
    # ------------
    try:
      all_groups = conf['files to remove']
    except:
      all_groups = []

    for group in all_groups:
        directory  = os.path.expandvars(group['directory'])
        for file_wild in group['files']:
            pathfiles = glob.glob(os.path.join(directory, file_wild))
            for pathfile in pathfiles:
                os.remove(pathfile)

    # Remove directories
    # ------------------
    try:
      directories = conf['directories to remove']
    except:
      directories = []

    for directory_wild in directories:
        directory  = os.path.expandvars(directory_wild)
        try:
            shutil.rmtree(directory)
        except OSError as e:
            utils.abort("Problem removing directory: "+directory)

# --------------------------------------------------------------------------------------------------
