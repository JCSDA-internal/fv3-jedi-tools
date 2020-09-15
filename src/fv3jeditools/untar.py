# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import os
import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package hpss_untar
#  This function takes a yaml file configuration as well as a datetime. It will untar all the files
#
#  More details.
# --------------------------------------------------------------------------------------------------

def untar(datetime, conf):

    # Get starting directory
    home_dir = os.getcwd()

    # Output path to use
    try:
        output_path = conf['path to extract to']
    except:
        output_path = './'

    # Change to output directory
    os.chdir(output_path)

    # Tar command to use
    try:
        tar_command = conf['tar command']
    except:
        tar_command = 'tar'

    # Check for valid tar command
    mylist = [tar_command=='tar', tar_command=='htar']
    if not any([tar_command=='tar', tar_command=='htar']):
      utils.abort('\'tar command\' must be tar or htar')

    # List of files to untar
    tar_files = conf['tar files']

    # List of internal files to untar
    internal_files = ' '.join(conf['internal files'])

    # Loop over tar files and untar the
    for tar_file in tar_files:

        # Create issue-command, but with potential datetime template
        issue_command_template = tar_command + ' -xvf ' + tar_file + ' ' + internal_files

        # Create issue-command with actual datetime
        issue_command = utils.stringReplaceDatetimeTemplate(datetime, issue_command_template)

        # Do untar
        utils.run_shell_command(issue_command)

    # Change back to starting directory
    os.chdir(home_dir)

# --------------------------------------------------------------------------------------------------
