# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import glob
import os
import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package tar
#  This function takes a yaml file configuration as well as a datetime. It will create a tar of a
#  list of files
# --------------------------------------------------------------------------------------------------

def tar(datetime, conf):

    # Get starting directory
    home_dir = os.getcwd()

    # Output path to use
    try:
        output_path = os.path.expandvars(conf['path to compress from'])
    except:
        output_path = './'

    # Create output directory if need be
    if not os.path.exists(output_path):
        utils.abort("Path to compress from does not exist")

    # Tar command to use
    try:
        tar_command = conf['tar command']
    except:
        tar_command = 'tar'

    # Check for valid tar command
    mylist = [tar_command=='tar', tar_command=='htar']
    if not any([tar_command=='tar', tar_command=='htar']):
      utils.abort('\'tar command\' must be tar or htar')

    # Change to output directory
    os.chdir(output_path)

    # Get list of files to tar (may include wildcards)
    files_to_tar_wild = conf['files to tar']

    # List of files to untar
    files_to_tar = []

    # Loop over wildcard files and fill complete list
    for file_to_tar_wild in files_to_tar_wild:

        files_to_tar = files_to_tar + glob.glob(file_to_tar_wild)

    # Create long string
    files_to_tar_str = ' '.join(files_to_tar)

    # Tar file to create
    tar_file = conf['created tar file']

    # Create issue-command, but with potential datetime template
    issue_command_template = tar_command + ' -cvf ' + tar_file + ' ' + files_to_tar_str

    # Create issue-command with actual datetime
    issue_command = datetime.strftime(issue_command_template)

    # Do compress
    utils.run_shell_command(issue_command)

    # Change back to starting directory
    os.chdir(home_dir)

# --------------------------------------------------------------------------------------------------
