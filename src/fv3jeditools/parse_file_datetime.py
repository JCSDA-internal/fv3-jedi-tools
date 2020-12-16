# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import fv3jeditools
import os

# --------------------------------------------------------------------------------------------------
## @package hpss_untar
#  This function takes a yaml file configuration as well as a datetime.
#
#  More details.
# --------------------------------------------------------------------------------------------------

def parse_file_datetime(datetime, conf):

    # Files to parse
    try:
        input_files = conf['files to parse']
    except:
        fv3jeditools.utils.abort("Config should contain files to parse")

    # Datetime formats to replace
    try:
        formats = conf['formats to parse']
    except:
        fv3jeditools.utils.abort("Config should contain files to parse")

    # Output directory
    try:
        output_directory = os.path.expandvars(conf['output directory'])
    except:
        output_directory = './'

    os.makedirs(output_directory, exist_ok=True)

    # Loop over input files, parse datetime and write new file
    for input_file in input_files:

       # Open file and read
       fi = open(os.path.expandvars(input_file))
       lines = fi.read().splitlines()
       fi.close()

       # Output file
       output_file = os.path.join(output_directory,os.path.split(input_file)[1])
       fo = open(output_file, 'w')

       # Write new file
       for line in lines:

         # Format with datetime
         for format in formats:
           new_line = fv3jeditools.utils_datetime.parseDatetimeString(datetime, line)
           line = new_line

         fo.write(line+'\n')

       fo.close()

# --------------------------------------------------------------------------------------------------
