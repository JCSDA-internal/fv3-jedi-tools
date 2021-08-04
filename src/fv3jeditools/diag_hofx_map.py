# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import cartopy.crs as ccrs
import datetime as dt
import glob
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import netCDF4
import numpy as np
import os

import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package hofx_map
#
#  This application can be triggered by using "application name: hofx_map"
#
#  Configuration options:
#  ----------------------
#
#  The datetime passed to this program is used to parse the file.
#
#  The datetime passed to this file is used to parse the file and so should match any datetime
#  in the file name. If this time is not equivalent to the central time of the window the time
#  offset option described below can be used.
#
#  hofx files       | File(s) to parse. E.g. aircraft_hofx_%Y%m%d%H.nc4
#  variable         | Variable to plot (either something from the file or variable@omb)
#  units            | Units of the field being plotted
#  window length    | Window length (hours)
#  time offset      | Offset of time in filename from window center (hours), e.g. -3, +3 or 0
#  plot format      | Output format for plots ([png] or pdf)
#  colorbar minimum | User defined colorbar minimum
#  colorbar maximum | User defined colorbar maximum
#
#
#  This function can be used to plot fields that are on a lon/lat grid as written by fv3-jedi.
#
# --------------------------------------------------------------------------------------------------

def hofx_map(datetime, conf):


    # Parse configuration
    # -------------------

    # File containing hofx files
    hofx_files_template = utils.configGetOrFail(conf, 'hofx files')


    # Get metric to plot
    metric = utils.configGetOrFail(conf, 'metric')


    # Get field to plot
    field = utils.configGetOrFail(conf, 'field')


    # Get window length
    window_length = dt.timedelta(hours=int(utils.configGetOrFail(conf, 'window length')))


    # Get time offset from center of window
    time_offset = dt.timedelta(hours=int(utils.configGetOrFail(conf, 'time offset')))


    # Get optional colorbar min and max
    try:
        colmin = conf['colorbar minimum']
    except:
        colmin = None
    try:
        colmax = conf['colorbar maximum']
    except:
        colmax = None

    # Get units of field being plotted
    try:
        units = conf['units']
    except:
        units = None

    # Format for plots
    try:
        plotformat = conf['plot format']
    except:
        plotformat = 'png'

    # Get output path for plots
    try:
        output_path = conf['output path']
    except:
        output_path = './'

    # Create output path
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    # Get list of hofx files to read
    # ------------------------------

    # Replace datetime in logfile name
    isodatestr = datetime.strftime("%Y-%m-%dT%H:%M:%S")
    hofx_files_template = utils.stringReplaceDatetimeTemplate(isodatestr, hofx_files_template)

    hofx_files = glob.glob(hofx_files_template)

    if hofx_files==[]:
        utils.abort("No hofx files matching the input string")


    # Compute window begin time
    # -------------------------
    window_begin = datetime + time_offset - window_length/2


    # Loop over data files and read
    # -----------------------------
    odat = []
    lons = []
    lats = []
    time = []
    for hofx_file in hofx_files:

        # Message file being read
        print(" Reading "+hofx_file)

        # Open the file
        fh = netCDF4.Dataset(hofx_file)

        # Check for channels
        try:
            nchans = fh.dimensions["nchans"].size
        except:
            nchans = 0

        # User must provide channel number
        if nchans != 0:
            chan = utils.configGetOrFail(conf, 'channel')

            # Read metric
            if metric=='omb':
                odat_proc = fh.groups['ObsValue'].variables[field][:,chan-1] - fh.groups['hofx'].variables[field][:,chan-1]
            else:
                odat_proc = fh.groups[metric].variables[field][:,chan-1]

        else:

            # Read metric
            if metric=='omb':
                odat_proc = fh.groups['ObsValue'].variables[field][:] - fh.groups['hofx'].variables[field][:]
            else:
                odat_proc = fh.groups[metric].variables[field][:]

        # Read metadata
        lons_proc = fh.groups['MetaData'].variables['longitude'][:]
        lats_proc = fh.groups['MetaData'].variables['latitude'][:]
        time_proc = fh.groups['MetaData'].variables['datetime'][:]


        for m in range(len(odat_proc)):
            odat.append(odat_proc[m])
            lons.append(lons_proc[m])
            lats.append(lats_proc[m])

        fh.close()

    # Figure filename
    # ---------------
    field_savename = field
    if nchans != 0:
        field_savename = field_savename+"-channel"+str(chan)
    savename = os.path.join(output_path, field_savename+"_"+metric+"_"+datetime.strftime("%Y%m%d_%H%M%S")+"."+plotformat)


    numobs = len(odat)

    obarray = np.empty([numobs, 3])

    obarray[:, 0] = odat
    obarray[:, 1] = lons
    obarray[:, 2] = lats


    # Compute and print some stats for the data
    # -----------------------------------------
    stdev = np.nanstd(obarray[:, 0])  # Standard deviation
    omean = np.nanmean(obarray[:, 0]) # Mean of the data
    datmi = np.nanmin(obarray[:, 0])  # Min of the data
    datma = np.nanmax(obarray[:, 0])  # Max of the data

    print("Plotted data statistics: ")
    print("Mean: ", omean)
    print("Standard deviation: ", stdev)
    print("Minimum ", datmi)
    print("Maximum: ", datma)


    # Norm for scatter plot
    # ---------------------
    norm = None


    # Min max for colorbar
    # --------------------
    if np.nanmin(obarray[:, 0]) < 0:
      cmax = datma
      cmin = datmi
      cmap = 'RdBu'
    else:
      cmax = omean+stdev
      cmin = np.maximum(omean-stdev, 0.0)
      cmap = 'viridis'

    if metric == 'PreQC' or metric == 'EffectiveQC':
      cmin = datmi
      cmax = datma

      # Specialized colorbar for integers
      cmap = plt.cm.jet
      cmaplist = [cmap(i) for i in range(cmap.N)]
      cmaplist[1] = (.5, .5, .5, 1.0)
      cmap = matplotlib.colors.LinearSegmentedColormap.from_list('Custom cmap', cmaplist, cmap.N)
      bounds = np.insert(np.linspace(0.5, int(cmax)+0.5, int(cmax)+1), 0, 0)
      norm = matplotlib.colors.BoundaryNorm(bounds, cmap.N)

    # If using omb then use standard deviation for the cmin/cmax
    if metric=='omb' or metric=='ombg' or metric=='oman':
      cmax = stdev
      cmin = -stdev

    # Override with user chosen limits
    if (colmin!=None):
      print("Using user provided minimum for colorbar")
      cmin = colmin
    if (colmax!=None):
      print("Using user provided maximum for colorbar")
      cmax = colmax


    # Create figure
    # -------------

    fig = plt.figure(figsize=(10, 5))

    # initialize the plot pointing to the projection
    ax = plt.axes(projection=ccrs.PlateCarree(central_longitude=0))

    # plot grid lines
    gl = ax.gridlines(crs=ccrs.PlateCarree(central_longitude=0), draw_labels=True,
                      linewidth=1, color='gray', alpha=0.5, linestyle='-')

    gl.xlabel_style = {'size': 10, 'color': 'black'}
    gl.ylabel_style = {'size': 10, 'color': 'black'}
    gl.xlocator = mticker.FixedLocator(
        [-180, -135, -90, -45, 0, 45, 90, 135, 179.9])
    ax.set_ylabel("Latitude",  fontsize=7)
    ax.set_xlabel("Longitude", fontsize=7)

    ax.tick_params(labelbottom=False, labeltop=False, labelleft=False, labelright=False)

    # scatter data
    sc = ax.scatter(obarray[:, 1], obarray[:, 2],
                    c=obarray[:, 0], s=4, linewidth=0,
                    transform=ccrs.PlateCarree(), cmap=cmap, vmin=cmin, vmax = cmax, norm=norm)

    # colorbar
    cbar = plt.colorbar(sc, ax=ax, orientation="horizontal", pad=.1, fraction=0.06,)
    if not units==None:
        cbar.ax.set_ylabel(units, fontsize=10)

    # plot globally
    ax.set_global()

    # draw coastlines
    ax.coastlines()

    # figure labels
    plt.title("Observation statistics: "+field.replace("_"," ")+" "+metric+" | "+
              window_begin.strftime("%Y%m%d %Hz")+" to "+
              (window_begin+window_length).strftime("%Y%m%d %Hz"), y=1.08)
    ax.text(0.45, -0.1,   'Longitude', transform=ax.transAxes, ha='left')
    ax.text(-0.08, 0.4, 'Latitude', transform=ax.transAxes,
            rotation='vertical', va='bottom')

    # show plot
    print(" Saving figure as", savename, "\n")
    plt.savefig(savename)



# --------------------------------------------------------------------------------------------------
