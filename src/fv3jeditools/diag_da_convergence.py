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

    # Get output path for plots
    try:
        output_path = conf['output path']
    except:
        output_path = './'

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

    # Create output path
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    # Replace datetime in logfile name
    isodatestr = datetime.strftime("%Y-%m-%dT%H:%M:%S")
    log_file = utils.stringReplaceDatetimeTemplate(isodatestr, log_file)


    # Read file and gather norm information
    print(" Reading convergence from ", log_file)


    # Check the file exists
    if not os.path.exists(log_file):
        utils.abort('Log file not found.')

    # Convert file to list
    lines = []
    with open(log_file) as file:
        for line in file:
            lines.append(line)

    # Get unique minizers used in run, e.g. DRIPCG + GMRES
    minimizers = []
    for line in lines:
        if " end of iteration " in line:
            minimizers.append(line.split()[0])
    minimizers=set(minimizers) # Unique only


    # Loop over minimizers
    for minimizer in minimizers:

        print('Processing ', minimizer)

        grad_red  = []
        norm_red  = []
        quad_j    = []
        quad_jb   = []
        quad_JoJc = []
        for num, line in enumerate(lines, 1):
            if minimizer+" end of iteration " in line:
                grad_red.append(lines[num].split()[-1])
                norm_red.append(lines[num+1].split()[-1])
                if (lines[num+3].split()[0] == 'Quadratic'):
                    quad_j.append(lines[num+3].split()[-1])
                if (lines[num+3].split()[0] == 'Quadratic'):
                    quad_jb.append(lines[num+4].split()[-1])
                if (lines[num+3].split()[0] == 'Quadratic'):
                    quad_JoJc.append(lines[num+5].split()[-1])


        # Loop over metrics
        for s in range(5):

            if (s==0):
                stat_str = grad_red
                ylabel = 'Gradient reduction'
            elif (s==1):
                stat_str = norm_red
                ylabel = 'Norm reduction'
            elif (s==2):
                stat_str = quad_j
                ylabel = 'Quadratic cost function: J'
            elif (s==3):
                stat_str = quad_jb
                ylabel = 'Quadratic cost function: Jb'
            elif (s==4):
                stat_str = quad_JoJc
                ylabel = 'Quadratic cost function: JoJc'

            niter = len(stat_str)

            if niter > 1:

                stat = np.zeros(len(stat_str))
                stat[0:niter] = stat_str

                stat_plot = stat[np.nonzero(stat)]
                iter = np.arange(1, len(stat_plot)+1)

                savename = minimizer.lower()+"-"+ylabel.lower().strip()
                savename = savename.replace(":", "")
                savename = savename.replace(" ", "-")
                savename = savename+"_"+datetime.strftime("%Y%m%d_%H%M%S")+"."+plotformat
                savename = os.path.join(output_path,savename)

                fig, ax = plt.subplots(figsize=(15, 7.5))
                ax.plot(iter, stat_plot, linestyle='-', marker='x')
                ax.tick_params(labelbottom=True, labeltop=False, labelleft=True, labelright=True)
                plt.title("JEDI variational assimilation convergence statistics | "+isodatestr)
                plt.xlabel("Iteration number")
                plt.ylabel(ylabel)
                plt.yscale(yscale)
                plt.xlim([0.9, niter+0.1])
                print(" Saving figure as", savename, "\n")
                plt.savefig(savename)


# --------------------------------------------------------------------------------------------------
