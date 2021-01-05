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
import scipy.interpolate

import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package hofx_innovations
#
#  This application can be triggered by using "application name: hofx_innovations"
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
#  hofx files            | File(s) to parse. E.g. aircraft_hofx_%Y%m%d%H.nc4
#  variable              | Variable to plot (either something from the file or variable@omb)
#  number of outer loops | Number of outer loops used in the assimilation
#  number of bins        | Number of bins to use in histogram of the data
#  units                 | Units of the field being plotted
#  window length         | Window length (hours)
#  time offset           | Offset of time in filename from window center (hours), e.g. -3, +3 or 0
#  plot format           | Output format for plots ([png] or pdf)
#
#
#  This function can be used to plot innovation statistics for the variational assimilation output.
#
# --------------------------------------------------------------------------------------------------

def hofx_innovations(datetime, conf):


    # Parse configuration
    # -------------------

    # File containing hofx files
    hofx_files_template = utils.configGetOrFail(conf, 'hofx files')


    # Get variable to plot
    variable = utils.configGetOrFail(conf, 'variable')


    # Get number of outer loops used in the assimilation
    nouter = utils.configGetOrFail(conf, 'number of outer loops')


    # Get window length
    window_length = dt.timedelta(hours=int(utils.configGetOrFail(conf, 'window length')))


    # Get time offset from center of window
    time_offset = dt.timedelta(hours=int(utils.configGetOrFail(conf, 'time offset')))


    # Get units of variable being plotted
    try:
        units = conf['units']
    except:
        units = None

    # Format for plots
    try:
        plotformat = conf['plot format']
    except:
        plotformat = 'png'

    # Number of bins for the histograms
    try:
        nbins = conf['number of bins']
    except:
        nbins = 1000

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


    # Variable name and units
    # -----------------------
    varname = variable
    vmetric = 'innovations'


    # Figure filename
    # ---------------
    savename = os.path.join(output_path, varname+"_"+vmetric+"_"+datetime.strftime("%Y%m%d_%H%M%S")+"."+plotformat)


    # Compute window begin time
    # -------------------------
    window_begin = datetime + time_offset - window_length/2


    # Loop over data files and read
    # -----------------------------
    nlocs = 0
    print(" Reading all files to get global nlocs")
    for hofx_file in hofx_files:

        # Open the file
        fh = netCDF4.Dataset(hofx_file)
        nlocs = nlocs + fh.dimensions['nlocs'].size
        fh.close()

    print(" Number of locations for this platform: ", nlocs)

    # Array to hold hofx data
    obs = np.zeros((nlocs))
    hofx = np.zeros((nlocs, nouter+1))

    # Missing values
    missing = 9.0e+30

    # Loop over files and read h(x) files
    nlocs_start = 0
    print(" Reading all files to get data")
    for hofx_file in hofx_files:

        # Open file for reading
        fh = netCDF4.Dataset(hofx_file)

        # Number of locations in this file
        nlocs_final = nlocs_start + fh.dimensions['nlocs'].size

        # Background
        obs[nlocs_start:nlocs_final] = fh.variables[variable+'@ObsValue'][:]

        # Set missing values to nans
        obs[nlocs_start:nlocs_final] = np.where(np.abs(obs[nlocs_start:nlocs_final]) < missing,
                                       obs[nlocs_start:nlocs_final], float("NaN"))

        # Loop over outer loops
        for n in range(nouter+1):
            hofx[nlocs_start:nlocs_final,n] = fh.variables[variable+'@hofx'+str(n)][:] - \
                                              obs[nlocs_start:nlocs_final]

        # Set start ready for next file
        nlocs_start = nlocs_final

        fh.close()

    # Statistics arrays
    hist  = np.zeros((nbins, nouter+1))
    edges = np.zeros((nbins, nouter+1))
    splines = np.zeros((nbins, nouter+1))
    stddev = np.zeros(nouter+1)

    # Create figure
    fig, ax = plt.subplots(figsize=(12, 7.5))

    # Loop over outer loops, compute stats and plot
    for n in range(nouter+1):

        # Generate histograms
        hist[:,n], edges_hist = np.histogram(hofx[~np.isnan(hofx[:,n]),n], bins=nbins)
        edges[:,n] = edges_hist[:-1] + (edges_hist[1] - edges_hist[0])/2

        # Generate splines for plotting
        spline = scipy.interpolate.UnivariateSpline(edges[:,n], hist[:,n], s=None)
        splines[:,n] = spline(edges[:,n])

        # Standard deviation
        stddev[n] = np.nanstd(hofx[:, n])

        # Print basic statistics
        print("\n Statisitcs for outer loop", n)
        print("  Mean observation minus h(x) = ", np.nanmean(hofx[:, n]))
        print("  Sdev observation minus h(x) = ", stddev[n])

        if n == 0:
            label = "Obs minus background"
        else:
            label = "Obs minus h(x) after "+utils.ordinalNumber(n)+" outer loop"

        ax.plot(edges[:,n], splines[:,n], label=label)
        plt.xlim(-2*stddev[n], 2*stddev[n])

    plt.legend(loc='upper left')
    ax.tick_params(labelbottom=True, labeltop=True, labelleft=True, labelright=True)
    plt.title("Observation statistics: "+varname.replace("_"," ")+" "+vmetric+" | "+
              window_begin.strftime("%Y%m%d %Hz")+" to "+
              (window_begin+window_length).strftime("%Y%m%d %Hz"), y=1.08)
    if not units==None:
        plt.xlabel("Observation minus h(x) ["+units+"]")
    else:
        plt.xlabel("Observation minus h(x)")
    plt.ylabel("Frequency")
    print(" Saving figure as", savename, "\n")
    plt.savefig(savename)

# --------------------------------------------------------------------------------------------------
