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
## @package log_timing
#
#  This application can be triggered by using "application name: log_timing"
#
#  Configuration options:
#  ----------------------
#  log file          | The log file to parse the statistics from
#  number of methods | Number of methods to show in the pie chart. Code will pick n most expensive [10]
#  plot format       | The extension used for the file name, png or pdf
#
#
#  This function takes a yaml file configuration as well as a datetime. It will plot the timing
#  statistics from the log of a JEDI run, this log file is provided through the yaml.
#
# --------------------------------------------------------------------------------------------------

def log_timing(datetime, conf):


    # Log file to parse
    # -----------------
    try:
        log_file = conf['log file']
    except:
        utils.abort('\'log file\' must be present in the configuration')

    # Largest N times to plot
    # -----------------------
    try:
        nplot = conf['number of methods']
    except:
        nplot = 9

    # Format for plots
    # ----------------
    try:
        plotformat = conf['plot format']
    except:
        plotformat = 'png'

    # Get output path for plots
    # -------------------------
    try:
        output_path = conf['output path']
    except:
        output_path = './'

    # Create output path
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    # Replace datetime in logfile name
    # --------------------------------
    isodatestr = datetime.strftime("%Y-%m-%dT%H:%M:%S")
    log_file = utils.stringReplaceDatetimeTemplate(isodatestr, log_file)


    # Read file and gather norm information
    # -------------------------------------
    print(" Reading timings from ", log_file)


    # Open the file ready for reading
    # -------------------------------
    if os.path.exists(log_file):
        file = open(log_file, "r")
    else:
        utils.abort('Log file not found.')


    # Get all lines that match the search patterns
    # --------------------------------------------
    oops_stats = []
    reg = re.compile("OOPS_STATS")
    for line in file:
        if bool(re.match(reg, line.rstrip())):
            oops_stats.append(line.rstrip())


    # Extract lines containing raw stats
    # ---------------------------------------
    search_str = "------------------------- Timing Statistics"
    reg = re.compile("OOPS_STATS oops")
    raw_timings = []
    take_line = -1
    for oops_stat in oops_stats:
        if re.search(search_str, oops_stat):
            take_line *= -1
        if take_line == 1 and bool(re.match(reg, oops_stat)):
            raw_timings.append(oops_stat)
    del raw_timings[0:2]

    # Remove totals
    del raw_timings[-1]


    # Extract lines containing parallel stats
    # ---------------------------------------
    search_str = "Parallel Timing Statistics"
    reg = re.compile("OOPS_STATS oops")
    par_timings = []
    take_line = -1
    for oops_stat in oops_stats:
        if re.search(search_str, oops_stat):
            take_line *= -1
        if take_line == 1 and bool(re.match(reg, oops_stat)):
            par_timings.append(oops_stat)
    del par_timings[0:3]

    # Remove totals
    del par_timings[-2:]


    # Place times and names in to numpy arrays
    # ----------------------------------------
    raw_timing_mname = np.empty(len(raw_timings), dtype='object')
    raw_timing_ttime = np.empty(len(raw_timings))
    raw_timing_pcall = np.empty(len(raw_timings))
    n = 0
    for raw_timing in raw_timings:
        raw_timing_mname[n] = raw_timing.split(": ")[0].split()[1]
        raw_timing_ttime[n] = float(raw_timing.split(": ")[1].split()[0])
        raw_timing_pcall[n] = float(raw_timing.split(": ")[1].split()[3])
        n += 1

    # Total time for times being considered
    # -------------------------------------
    raw_total_time = np.sum(raw_timing_ttime)

    # Get N largest times for all calls of a method
    ind_for_ttime_plot = np.argpartition(raw_timing_ttime, -(nplot))[-(nplot):]
    raw_timing_ttime_time_plot = raw_timing_ttime[ind_for_ttime_plot]
    raw_timing_ttime_name_plot = raw_timing_mname[ind_for_ttime_plot]

    # Append all other to the arrays as single time
    raw_timing_ttime_time_plot = np.append(raw_timing_ttime_time_plot, raw_total_time-np.sum(raw_timing_ttime_time_plot))
    raw_timing_ttime_name_plot = np.append(raw_timing_ttime_name_plot, "Other")

    for n in range(len(raw_timing_ttime_name_plot)):
       raw_timing_ttime_name_plot[n] = raw_timing_ttime_name_plot[n] + " (" + '{:.2f}'.format(raw_timing_ttime_time_plot[n]) + " ms)"

    # Get N largest times for all method per call
    ind_for_pcall_plot = np.argpartition(raw_timing_pcall, -(nplot))[-(nplot):]
    raw_timing_pcall_time_plot = raw_timing_pcall[ind_for_ttime_plot]
    raw_timing_pcall_name_plot = raw_timing_mname[ind_for_ttime_plot]

    for n in range(len(raw_timing_pcall_name_plot)):
       raw_timing_pcall_name_plot[n] = raw_timing_pcall_name_plot[n] + " (" + '{:.2f}'.format(raw_timing_pcall_time_plot[n]) + " ms)"

    # Create figures
    # --------------
    savename = os.path.basename(log_file)
    savename = os.path.splitext(savename)[0]
    savename_total = savename+"_method_total_time_"+datetime.strftime("%Y%m%d_%H%M%S")+"."+plotformat
    savename_total = os.path.join(output_path,savename_total)

    savename_percall = savename+"_method_per_call_"+datetime.strftime("%Y%m%d_%H%M%S")+"."+plotformat
    savename_percall = os.path.join(output_path,savename_percall)

    fig, ax = plt.subplots(figsize=(20, 7.5))
    wedges, texts, autotexts = ax.pie(raw_timing_ttime_time_plot, autopct='%1.1f%%',
                                      shadow=True, startangle=90)
    plt.title("JEDI application timings per method (total time = "+'{:.1f}'.format(np.sum(raw_timing_ttime_time_plot)) + "ms)")
    ax.legend(wedges, raw_timing_ttime_name_plot, title="Methods", loc="center left",
              bbox_to_anchor=(1, 0, 0.5, 1))
    print(" Saving figure as", savename_total, "\n")
    plt.savefig(savename_total)

    fig, ax = plt.subplots(figsize=(20, 7.5))
    wedges, texts, autotexts = ax.pie(raw_timing_pcall_time_plot, autopct=lambda p: '{:.1f}'.format(p * np.sum(raw_timing_pcall_time_plot) / 100),
                                      shadow=True, startangle=90)
    plt.title("JEDI application timings per method per call (ms)")
    ax.legend(wedges, raw_timing_pcall_name_plot, title="Methods", loc="center left",
              bbox_to_anchor=(1, 0, 0.5, 1))
    print(" Saving figure as", savename_percall, "\n")
    plt.savefig(savename_percall)

# --------------------------------------------------------------------------------------------------
