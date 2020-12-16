# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import glob
import os
import shutil
import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package stage_files
#  This function takes a yaml file configuration as well as a datetime. It will untar all the files
# --------------------------------------------------------------------------------------------------

def stage_files(datetime, conf):

    # Copy files
    # ----------
    try:
      all_groups = conf['files to copy']
    except:
      all_groups = []

    for group in all_groups:
        input_dir  = os.path.expandvars(group['input path'])
        output_dir = os.path.expandvars(group['output path'])
        os.makedirs(output_dir, exist_ok=True)
        for file_wild in group['files']:
            pathfiles = glob.glob(os.path.join(input_dir, file_wild))
            for pathfile in pathfiles:
                file = os.path.basename(pathfile)
                input_file  = os.path.join(input_dir,  file)
                output_file = os.path.join(output_dir, file)
                shutil.copy(input_file, output_file)

    # Link files
    # ----------
    try:
      all_groups = conf['files to link']
    except:
      all_groups = []

    for group in all_groups:
        input_dir  = os.path.expandvars(group['input path'])
        output_dir = os.path.expandvars(group['output path'])
        os.makedirs(output_dir, exist_ok=True)
        for file_wild in group['files']:
            pathfiles = glob.glob(os.path.join(input_dir, file_wild))
            for pathfile in pathfiles:
                file = os.path.basename(pathfile)
                input_file  = os.path.join(input_dir,  file)
                output_file = os.path.join(output_dir, file)
                if os.path.exists(output_file):
                    os.remove(output_file)
                os.symlink(input_file, output_file)


# --------------------------------------------------------------------------------------------------
