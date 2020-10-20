# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import fv3jeditools.utils as utils
import glob
import os
import shutil
import sys

# --------------------------------------------------------------------------------------------------

def gsidiag_to_ioda(datetime, conf):

    # Import from ioda-converters in program to avoid needing by default
    import gsi_ncdiag as gsi_ncdiag
    import combine_conv as combine_conv

    # Input and output directories
    idir_ = conf['input directory']
    odir_ = conf['output directory']

    idir = datetime.strftime(idir_)
    odir = datetime.strftime(odir_)

    # Filename template
    ftemp_ = conf['filename template']
    ftemp = datetime.strftime(ftemp_)
    ftemp = ftemp.replace("$INPUTDIR", idir)

    # Conventional
    conv_types = conf['conventional types']

    conv_platforms = []
    if not conf['conventional platforms']==None:
        conv_platforms = conf['conventional platforms']

    # Radiances
    radiance_platforms = []
    if not conf['radiance platforms']==None:
        radiance_platforms = conf['radiance platforms']

    # Ozone
    ozone_platforms = []
    if not conf['ozone platforms']==None:
        ozone_platforms = conf['ozone platforms']

    # Aod
    aod_platforms = []
    if not conf['aod platforms']==None:
        aod_platforms = conf['aod platforms']

    # Radar
    radar_platforms = []
    if not conf['radar platforms']==None:
        radar_platforms = conf['radar platforms']


    # Create output directory
    # -----------------------

    if not os.path.exists(odir):
      os.makedirs(odir)


    # Loop over all files and run conversion
    # --------------------------------------

    platforms = conv_platforms + radiance_platforms + ozone_platforms + aod_platforms + radar_platforms

    for platform in platforms:

        pathfile = ftemp
        pathfile = pathfile.replace("$PLATFORM", platform)

        print("\nConverting: ", pathfile)

        # Constructor depends on observation type
        type = ''
        if (platform in conv_platforms):
            type = 'conv'
            diag = gsi_ncdiag.Conv(pathfile)
        elif (platform in radiance_platforms):
            type = 'radiance'
            diag = gsi_ncdiag.Radiances(pathfile)
        elif (platform in ozone_platforms):
            diag = gsi_ncdiag.AOD(pathfile)
        elif (platform in aod_platforms):
            diag = gsi_ncdiag.Ozone(pathfile)
        elif (platform in radar_platforms):
            diag = gsi_ncdiag.Radar(pathfile)
        else:
            raise ValueError

        # Read ncdiag files
        diag.read()

        # Convert to IODA format
        if (type == 'conv'):
            conv_type_platforms = gsi_ncdiag.conv_platforms[platform]
            diag.toIODAobs(odir, platforms=conv_type_platforms)
        elif (type == 'radiance'):
            diag.toIODAobs(odir, False, False, False)
        else:
            diag.toIODAobs(odir)


        diag.close()

    # Combine the conventional data
    # -----------------------------
    for type in conv_types:

      print("\nCombining ", type)

      # Create list of files to combine
      infiles_list = glob.glob(os.path.join(odir, type+'_*_obs_*'))
      infiles = ' '.join(infiles_list)

      # Ouput file
      date = datetime.strftime("%Y%m%d")
      time = datetime.strftime("%H")
      outfile = os.path.join(odir, type+'_obs_'+date+time+'.nc4')

      # Perform combine
      combine_conv.concat_ioda(infiles_list, outfile, False)

      # Remove input files
      if (os.path.exists(outfile)):
          for infile in infiles_list:
              os.remove(infile)


# --------------------------------------------------------------------------------------------------

if __name__ == "__main__":
    main()

# --------------------------------------------------------------------------------------------------
