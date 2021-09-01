# (C) Copyright 2021 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import matplotlib.pyplot as plt
import netCDF4
import numpy as np
import os

import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package obs_scatter
#
#  This application can be triggered by using "application name: obs_scatter"
#
#  Configuration options:
#  ----------------------
#
#
#
#  This function can be used to plot observation type data comparing two experiments in a scatter
#
# --------------------------------------------------------------------------------------------------



def obs_scatter(datetime, conf):


    # Parse configuration
    # -------------------
    # Files containing experiment hofx files
    ioda_exp_files = utils.configGet(conf, 'ioda experiment files')
    ioda_ref_files = utils.configGet(conf, 'ioda reference files')

    # Get metrics to plot
    exp_metrics = utils.configGet(conf, 'experiment metrics')
    ref_metrics = utils.configGet(conf, 'reference metrics')

    # Marker size for scatter
    marker_size = utils.configGet(conf, 'marker size', 2)

    # Output path
    output_path = utils.configGet(conf, 'output path', './')

    # Figure file type (pdf, png, etc)
    file_type = utils.configGet(conf, 'figure file type', 'png')


    # Loop over hofx files
    # --------------------
    for ioda_exp_file, ioda_ref_file in zip(ioda_exp_files, ioda_ref_files):

        # Replace datetime in input filenames
        isodatestr = datetime.strftime("%Y-%m-%dT%H:%M:%S")
        ioda_exp_file = utils.stringReplaceDatetimeTemplate(isodatestr, ioda_exp_file)
        ioda_ref_file = utils.stringReplaceDatetimeTemplate(isodatestr, ioda_ref_file)

        # Message files being read
        print(" Experiment file: "+ioda_exp_file)
        print(" Reference file:  "+ioda_ref_file)

        # Output filename
        pathfile = os.path.split(ioda_exp_file)
        source_file = pathfile[1]

        # Get platform name
        platform = source_file.split(".")[4]
        platform_long_name = utils.ioda_platform_dict(platform)

        # Open the file
        fh_exp = netCDF4.Dataset(ioda_exp_file)
        fh_ref = netCDF4.Dataset(ioda_ref_file)

        # Get potential variables
        variables = fh_exp.groups['ObsValue'].variables.keys()

        # Check for channels
        try:
            number_channels = fh_exp.dimensions["nchans"].size
            has_chan = True
        except:
            number_channels = 1
            has_chan = False

        # Check for similarity of channels
        if has_chan:
            channels_exp = fh_exp.variables['nchans'][:]
            channels_ref = fh_ref.variables['nchans'][:]
            assert not any(channels_exp != channels_ref), \
                         "Files being compared have different channels"

        # Loop over metrics
        # -----------------
        for exp_metric, ref_metric in zip(exp_metrics, ref_metrics):

            print("\n  Metric: ", exp_metric, " versus ", ref_metric)

            # Long names for metrics
            exp_metric_long_name = utils.ioda_group_dict(exp_metric)
            ref_metric_long_name = utils.ioda_group_dict(ref_metric)

            # Loop over variables
            # -------------------
            for variable in variables:

                variable_name = variable
                variable_name_no_ = variable.replace("_", " ")
                variable_name_no_ = variable_name_no_.capitalize()
                variable_name_no_fix = variable_name_no_

                # Loop over channels
                # -------------------
                for channel_idx in range(number_channels):


                    # Read the data
                    # -------------
                    if has_chan:

                        channel = channels_exp[channel_idx]

                        # Add channel number to name
                        variable_name     = variable             + "-channel_" + str(channel)
                        variable_name_no_ = variable_name_no_fix + " channel " + str(channel)

                        print("\n    Variable: ", variable_name_no_, "(", str(channel_idx+1),
                              " of ", str(number_channels),")\n")

                        data_exp = utils.read_ioda_variable(fh_exp, exp_metric, variable, channel_idx)
                        data_ref = utils.read_ioda_variable(fh_ref, ref_metric, variable, channel_idx)

                    else:

                        print("\n    Variable: ", variable_name_no_, "\n")

                        data_exp = utils.read_ioda_variable(fh_exp, exp_metric, variable)
                        data_ref = utils.read_ioda_variable(fh_ref, ref_metric, variable)


                    # Remove missing values (<-10e10)
                    # -------------------------------
                    remove_idx_exp = np.where(data_exp < -10e10)[0]
                    remove_idx_ref = np.where(data_ref < -10e10)[0]
                    remove_idx = np.unique(np.concatenate([remove_idx_exp,remove_idx_ref]))

                    make_plot = True
                    if len(remove_idx) > 0:
                        print('      Missing values: removing ', len(remove_idx), ' values. ',
                              'Original number of locations:', len(data_exp))
                        if (len(remove_idx) != len(data_exp)):
                            data_exp = np.delete(data_exp, remove_idx)
                            data_ref = np.delete(data_ref, remove_idx)
                        else:
                            make_plot = False
                            print('      No data for this variable/channel, skip plotting')


                    # Create and save the figure
                    # --------------------------
                    if make_plot:
                        print("      Creating figure")

                        # Create output filename
                        output_path_fig = os.path.join(output_path, platform, variable_name)
                        utils.createPath(output_path_fig)
                        output_file = source_file.split(".")
                        output_file[4] = output_file[4]+'-'+exp_metric+'_vs_'+ref_metric
                        output_file = os.path.join(output_path_fig, ".".join(output_file))
                        output_file = os.path.splitext(output_file)[0]+'.'+file_type

                        # Limits for the figure
                        data_min = min(min(data_exp), min(data_ref))
                        data_max = max(max(data_exp), max(data_ref))
                        data_dif = data_max - data_min

                        # Create and save figure
                        fig = plt.figure()
                        ax = fig.add_subplot(111)
                        plt.scatter(data_ref, data_exp, s=marker_size)
                        plt.title(platform_long_name + ' | ' + variable_name_no_)
                        plt.ylabel(exp_metric_long_name)
                        plt.xlabel(ref_metric_long_name)
                        ax.set_aspect('equal', adjustable='box')
                        plt.xlim(data_min - 0.1*data_dif, data_max + 0.1*data_dif)
                        plt.ylim(data_min - 0.1*data_dif, data_max + 0.1*data_dif)
                        plt.axline((0, 0), slope=1.0, color='k')
                        plt.savefig(output_file)
                        plt.close('all')

        # Close files
        fh_exp.close()
        fh_ref.close()
        print("\n\n\n")
