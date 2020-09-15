#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.


"""

Tool to obtain ensemble restarts from archive.

"""

import datetime as dt
import argparse
import glob
import os
import sys
import yaml

try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader

import fv3jeditools.Utils.utils as utils

# --------------------------------------------------------------------------------------------------

def main():

    # Retrieve command-line arguments
    # -------------------------------

    parser = argparse.ArgumentParser(description='Retrieve a random sample of ensemble restarts')
    parser.add_argument('config', metavar='config', type=str, help='configuration (.yaml .yml)')

    args = parser.parse_args()


    # Get the environment
    # -------------------

    cfg_file = args.config


    # Generate sample of datetimes
    # ----------------------------

    with open(cfg_file) as file:
        cfg = yaml.load(file, Loader=Loader)

    datetimes = utils.randomDateTimes(cfg['datetime_start'], cfg['datetime_final'],
                                        cfg['frequency'], cfg['seed'], cfg['number_samples'])


    # Print ensembles to be extracted
    # -------------------------------

    print("Files: ")
    for dts in datetimes:

      # File to extract
      member_rst = dts.strftime(cfg['tar_files'])

      # Print
      print(" "+member_rst)


    # Loop over datetimes and check files exist
    # -----------------------------------------

    for dts in datetimes:

      # File to extract
      member_rst = dts.strftime(cfg['tar_files'])


      # Check existence
      if not os.path.exists(member_rst):
        utils.abort("File "+member_rst+" does not exist")


    # Loop over datetimes and extract the ensemble
    # ---------------------------------------------

    for dts in datetimes:

      # File to extract
      member_rst = dts.strftime(cfg['tar_files'])

      # Perform extraction
      utils.tarExtract(member_rst, cfg['intenal_files'], cfg['extract_path'])


# --------------------------------------------------------------------------------------------------

if __name__ == "__main__":
    main()

# --------------------------------------------------------------------------------------------------
