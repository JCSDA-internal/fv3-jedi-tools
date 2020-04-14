#!/usr/bin/env python

# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime
import os
import sys
import yaml
#print(sys.path)

# --------------------------------------------------------------------------------------------------

def main():

    # Get the CYLC Environment
    # ========================

    cylc_run_path = '/gpfsm/dnb31/drholdaw/JediWF/GMAOGsiDiag2Ioda'  #os.environ['CYLC_SUITE_RUN_DIR']
    cylc_def_path = '/gpfsm/dnb31/drholdaw/JediWF/GMAOGsiDiag2Ioda'  #os.environ['CYLC_SUITE_DEF_PATH']
    cylc_cycle_point = '2020040100' #os.environ['CYLC_TASK_CYCLE_POINT']

    date = cylc_cycle_point[0:8]
    time = cylc_cycle_point[9:11]
    cfg_file = os.path.join(cylc_def_path,'config.yml')


    # Parse the configuration
    # =======================

    with open(cfg_file) as file:
        cfg = yaml.load(file)

    envcfg = cfg['environment']
    mycfg = cfg['gsi-diag2ioda']

    idir_ = mycfg['IDIR']
    odir_ = mycfg['ODIR']
    expid = envcfg['EXPID']

    icpath = mycfg['ioda_converters_build_path']

    # Observation types to process
    obsv_types = mycfg['types']

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

    # Observing systems to skip over
    skip_type = mycfg['observing_systems_to_skip']


    # Import gsi diag converter from ioda-converters
    # ==============================================
    sys.path.append(icpath+'/lib/pyiodaconv')
    import gsi_ncdiag as gsi_ncdiag


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

    #all_files = conv_files + radiance_files + ozone_files + aod_files + radar_files
    all_files = radiance_files

    for file in all_files:

        filename = os.path.split(file)[1]

        print("Converting: ", file)

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



# --------------------------------------------------------------------------------------------------

if __name__ == "__main__":
    main()

# --------------------------------------------------------------------------------------------------
