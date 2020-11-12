# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import matplotlib.pyplot as plt
import numpy as np
import os
import re

import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package da_convergence
#
#  This application can be triggered by using "application name: da_convergence"
#
#  Configuration options:
#  ----------------------
#  log file    | The log file to parse the statistics from
#  yscale      | Whether to use log or linear scale for the yaxis
#  plot format | The extension used for the file name, png or pdf
#
#
#  This function takes a yaml file configuration as well as a datetime. It will plot the convergence
#  statistics from the log of a variational data assimilation run, provided through the yaml.
#  It will search for the Minimizer norm gradient, J, Jb, JoJc and GMRESR
#
#
# --------------------------------------------------------------------------------------------------

def da_convergence(datetime, conf):

    # Log file to parse
    try:
        log_file = conf['log file']
    except:
        utils.abort('\'log file\' must be present in the configuration')

    # Replace datetime in logfile name
    isodatestr = datetime.strftime("%Y-%m-%dT%H:%M:%S")
    log_file = utils.stringReplaceDatetimeTemplate(isodatestr, log_file)


    # Read file and gather norm information
    print(" Reading convergence from ", log_file)


    # Open the file ready for reading
    if os.path.exists(log_file):
        file = open(log_file, "r")
    else:
        utils.abort('Log file not found.')


    # Search for the type of minimizer used for the assimilation
    for line in file:
        if "Minimizer algorithm=" in line:
            minimizer = line.split('=')[1].rstrip()
            break


    # Patterns to search for from the file
    search_patterns = []
    search_patterns.append(minimizer+" end of iteration .")
    search_patterns.append("  Quadratic cost function: J   .")
    search_patterns.append("  Quadratic cost function: Jb  .")
    search_patterns.append("  Quadratic cost function: JoJc.")
    search_patterns.append("GMRESR end of iteration .")

    # Labels for the figures
    ylabels = []
    ylabels.append(minimizer+" norm gradient")
    ylabels.append("Quadratic cost function J   ")
    ylabels.append("Quadratic cost function Jb  ")
    ylabels.append("Quadratic cost function JoJc")
    ylabels.append("GMRESR norm gradient")

    # Get all lines that match the search patterns
    matches = []
    for line in file:
        for search_pattern in search_patterns:
            reg = re.compile(search_pattern)
            if bool(re.match(reg, line.rstrip())):
                matches.append(line.rstrip())


    # Close the file
    file.close()

    # Loop over stats to be searched on
    maxiterations = 10000
    count = np.zeros(len(search_patterns), dtype=int)
    stats = np.zeros((len(search_patterns), maxiterations))
    for search_pattern in search_patterns:

        index = [i for i, s in enumerate(search_patterns) if search_pattern in s]

        # Loop over the matches and fill stats
        for match in matches:

            reg = re.compile(search_pattern)
            if bool(re.match(reg, match)):

                stats[index,count[index]] = match.split()[-1]
                count[index] = count[index] + 1

    niter = count[0]
    stat = np.zeros(niter)


    # Create figures
    # --------------

    # Scale for y-axis
    try:
        yscale = conf['yscale']
    except:
        yscale = 'linear'

    # Format for plots
    try:
        plotformat = conf['plot format']
    except:
        plotformat = 'png'

    for ylabel in ylabels:

        index = [i for i, s in enumerate(ylabels) if ylabel in s]
        savename = ylabel.lower().strip()
        savename = savename.replace(" ", "-")
        savename = savename+"_"+datetime.strftime("%Y%m%d_%H%M%S")+"."+plotformat
        savename = os.path.join(os.path.dirname(log_file),savename)

        stat[0:niter] = stats[index,0:niter]
        stat_plot = stat[np.nonzero(stat)]

        iter = np.arange(1, len(stat_plot)+1)

        fig, ax = plt.subplots(figsize=(15, 7.5))
        ax.plot(iter, stat_plot, linestyle='-', marker='x')
        ax.tick_params(labelbottom=True, labeltop=False, labelleft=True, labelright=True)
        plt.title("JEDI variational assimilation convergence statistics | "+isodatestr)
        plt.xlabel("Iteration number")
        plt.ylabel(ylabel)
        plt.yscale(yscale)
        plt.savefig(savename)

# --------------------------------------------------------------------------------------------------
