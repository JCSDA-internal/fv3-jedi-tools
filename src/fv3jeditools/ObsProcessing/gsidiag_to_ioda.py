#!/usr/bin/env python

# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime
import argparse
import glob
import os
import sys
import yaml
import gsi_ncdiag as gsi_ncdiag

# --------------------------------------------------------------------------------------------------

def main():

    # Retrieve command-line arguments
    # ===============================

    parser = argparse.ArgumentParser(description='Convert GSI Diag files to IODA format.')
    parser.add_argument('datetime', metavar='datetime', type=str,
                    help='ISO datetime as ccyy-mm-ddThh:mm:ss')
    parser.add_argument('config', metavar='config', type=str,
                    help='configuration file (.yml)')

    args = parser.parse_args()

    # Get the environment
    # ===================

    date = args.datetime[0:10].replace('-','')
    time = args.datetime[11:13]

    cfg_file = args.config

    # Parse the configuration
    # =======================

    with open(cfg_file) as file:
        cfg = yaml.load(file)

    envcfg = cfg['environment']
    mycfg = cfg['gsi-diag2ioda']

    idir_ = mycfg['IDIR']
    odir_ = mycfg['ODIR']
    expid = envcfg['EXPID']


    # Conventional
    conv_types = mycfg['conventional_types']

    conv_files = []
    if not mycfg['conventional_files']==None:
        conv_files = mycfg['conventional_files']

    # Radiances
    radiance_files = []
    if not mycfg['radiance_files']==None:
        radiance_files = mycfg['radiance_files']

    # Ozone
    ozone_files = []
    if not mycfg['ozone_files']==None:
        ozone_files = mycfg['ozone_files']

    # Aod
    aod_files = []
    if not mycfg['aod_files']==None:
        aod_files = mycfg['aod_files']

    # Radar
    radar_files = []
    if not mycfg['radar_files']==None:
        radar_files = mycfg['radar_files']


    # Replace date time in files
    # ==========================
    obs_datetime = datetime.datetime.strptime(date+time, '%Y%m%d%H')

    idir = obs_datetime.strftime(idir_)
    odir = obs_datetime.strftime(odir_)

    for i in range(len(conv_files)):
        conv_files[i] = obs_datetime.strftime(conv_files[i])

    for i in range(len(radiance_files)):
        radiance_files[i] = obs_datetime.strftime(radiance_files[i])

    for i in range(len(ozone_files)):
        ozone_files[i] = obs_datetime.strftime(ozone_files[i])

    for i in range(len(aod_files)):
        aod_files[i] = obs_datetime.strftime(aod_files[i])

    for i in range(len(radar_files)):
        radar_files[i] = obs_datetime.strftime(radar_files[i])

    # Replace experiment specifics
    # ============================

    for i in range(len(conv_files)):
        conv_files[i] = conv_files[i].replace("$IDIR", idir)
        conv_files[i] = conv_files[i].replace("$EXPID", expid)

    for i in range(len(radiance_files)):
        radiance_files[i] = radiance_files[i].replace("$IDIR", idir)
        radiance_files[i] = radiance_files[i].replace("$EXPID", expid)

    for i in range(len(ozone_files)):
        ozone_files[i] = ozone_files[i].replace("$IDIR", idir)
        ozone_files[i] = ozone_files[i].replace("$EXPID", expid)

    for i in range(len(aod_files)):
        aod_files[i] = aod_files[i].replace("$IDIR", idir)
        aod_files[i] = aod_files[i].replace("$EXPID", expid)

    for i in range(len(radar_files)):
        radar_files[i] = radar_files[i].replace("$IDIR", idir)
        radar_files[i] = radar_files[i].replace("$EXPID", expid)

    # Create output directory
    # =======================

    if not os.path.exists(odir):
      os.makedirs(odir)


    # Loop over all files and run conversion
    # ======================================

    all_files = conv_files + radiance_files + ozone_files + aod_files + radar_files

    for file in all_files:

        filename = os.path.split(file)[1]

        print("\nConverting: ", file)

        # Constructor depends on observation type
        type = ''
        if (file in conv_files):
            type = 'conv'
            diag = gsi_ncdiag.Conv(file)
        elif (file in radiance_files):
            type = 'radiance'
            diag = gsi_ncdiag.Radiances(file)
        elif (file in ozone_files):
            diag = gsi_ncdiag.AOD(file)
        elif (file in aod_files):
            diag = gsi_ncdiag.Ozone(file)
        elif (file in radar_files):
            diag = gsi_ncdiag.Radar(file)
        else:
            raise ValueError

        # Read ncdiag files
        diag.read()

        # Convert to IODA format
        if (type == 'conv'):
            fnamesplit = filename.split("_")
            platform_name = fnamesplit[2]+'_'+fnamesplit[3]
            platforms = gsi_ncdiag.conv_platforms[platform_name]
            diag.toIODAobs(odir, platforms=platforms)
        elif (type == 'radiance'):
            diag.toIODAobs(odir, False, False, False)
        else:
            diag.toIODAobs(odir)


        diag.close()

    # Combine the conventional data
    # =============================
    for type in conv_types:

      print("\nCombining ", type)

      # Create list of files to combine
      infiles_list = glob.glob(os.path.join(odir, type+'_*_obs_*'))
      infiles = ' '.join(infiles_list)

      # Ouput file
      outfile = os.path.join(odir, type+'_obs_'+date+time+'.nc4')

      # Perform combine
      os.system('combine_conv.py -i ' + infiles + ' -o ' + outfile)


# --------------------------------------------------------------------------------------------------

if __name__ == "__main__":
    main()

# --------------------------------------------------------------------------------------------------
