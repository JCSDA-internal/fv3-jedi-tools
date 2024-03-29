# (C) Copyright 2021 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import matplotlib.pyplot as plt
import numpy as np
import os
import re

import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package da_block_convergence
#
#  This application can be triggered by using "application name: da_block_convergence"
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

def da_block_convergence(datetime, conf):

    # Log file to parse
    try:
        log_file = conf['log file']
    except:
        utils.abort('\'log file\' must be present in the configuration')

    # Get the number of members
    try:
        members = conf['members']
    except:
        utils.abort('\'members\' must be present in the configuration')

    # Get output path for plots
    try:
        output_path = conf['output path']
    except:
        output_path = './'

    # Create output path
    if not os.path.exists(output_path):
        os.makedirs(output_path)

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
    search_patterns.append("   Norm reduction all members .")
    search_patterns.append("   Quadratic cost function all members: J .") 

    # Labels for the figures
    ylabels = []
    ylabels.append(minimizer+" normalized gradient reduction")
    ylabels.append("Quadratic cost function J   ")

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
    stats = np.zeros((members, len(search_patterns), maxiterations))
    for search_pattern in search_patterns:

        index = [i for i, s in enumerate(search_patterns) if search_pattern in s]

        # Loop over the matches and fill stats
        for match in matches:
            reg = re.compile(search_pattern) 
            if bool(re.match(reg, match)):
                x = match.split()[-members:]
                x2 = [sub.replace(',' , '') for sub in x]
                for member in range(members):
                    stats[member,index,count[index]]=x2[member]
                count[index] = count[index] + 1


    niter = count[0]
    stat = np.zeros((members, niter))


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
        savename = os.path.join(output_path,savename)
        fig, ax = plt.subplots(figsize=(15, 7.5))
        for member in range(members):
            stat[member,0:niter] = stats[member,index,0:niter]
            stat_plot = stat[member,np.nonzero(stat[member,:])]
            iter = np.arange(1, len(stat_plot[0])+1)
            ax.plot(iter, stat_plot[0], linestyle='-', marker='x',label = 'member %s'%member) 
        ax.tick_params(labelbottom=True, labeltop=False, labelleft=True, labelright=True)
        plt.title("JEDI variational assimilation convergence statistics | "+isodatestr)
        plt.legend()
        plt.xlabel("Iteration number")
        plt.ylabel(ylabel)
        plt.yscale(yscale)

        print(" Saving figure as", savename, "\n")
        plt.savefig(savename)

# --------------------------------------------------------------------------------------------------
