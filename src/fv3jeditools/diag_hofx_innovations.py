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
from scipy.interpolate import UnivariateSpline

import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package hofx_innovations
#
#  This application can be triggered by using "application name: hofx_innovations"
#
#  Configuration options:
#  ----------------------
#
#
#
#  This function can be used to plot fields that are on a lon/lat grid as written by fv3-jedi.
#
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
    savename = os.path.join(os.path.dirname(hofx_files_template),
                          varname+"_"+vmetric+"_"+datetime.strftime("%Y%m%d_%H%M%S")+"."+plotformat)


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
    nbins = 1250
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
        spline = UnivariateSpline(edges[:,n], hist[:,n], s=None)
        splines[:,n] = spline(edges[:,n])

        # Standard deviation
        stddev[n] = np.nanstd(hofx[:, n])

        # Print basic statistics
        print("\n Statisitcs for outer loop", n)
        print("  Mean observation minus h(x) = ", np.nanmean(hofx[:, n]))
        print("  Sdev observation minus h(x) = ", stddev[n])

        #print(ordinal(n+1))

        if n == 0:
            label = "Obs minus background"
        else:
            label = "Obs minus h(x) after "+utils.ordinalNumber(n)+" outer loop"

        ax.plot(edges[:,n], splines[:,n], label=label)
        plt.xlim(-2*stddev[n], 2*stddev[n])

    plt.legend(loc='upper left')
    ax.tick_params(labelbottom=True, labeltop=False, labelleft=True, labelright=True)
    plt.title("Observaton minus h(x) innovation statistics")
    plt.xlabel("Observation minus h(x)")
    plt.ylabel("Frequency")
    plt.savefig(savename)

# --------------------------------------------------------------------------------------------------
