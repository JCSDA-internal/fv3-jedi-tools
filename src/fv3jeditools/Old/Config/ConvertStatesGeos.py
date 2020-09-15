#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import argparse
import os
import yaml

import fv3jeditools.Config.geos_conf as geosconf
import fv3jeditools.Config.common_conf as commconf
import fv3jeditools.Utils.utils as utils


def main():

    sargs = argparse.ArgumentParser()
    sargs.add_argument("-s", "--start_date",    default='2019111809')
    sargs.add_argument("-f", "--final_date",    default='2019111809')
    sargs.add_argument("-q", "--freq",          default='6')
    sargs.add_argument("-c", "--config",        default='config.yaml')

    args = sargs.parse_args()
    start = args.start_date
    final = args.final_date
    freq = int(args.freq)
    conf = args.config

    # --------------------------------------------------------------------------------------------------

    dtformat = '%Y%m%d%H'

    dts = utils.getDateTimes(start, final, 3600*freq, dtformat)

    # Configuration
    with open(conf) as file:
        cf = yaml.load(file, Loader=yaml.FullLoader)

    for dt in dts:

        # Geometry
        inputresolution = geosconf.geometry_dict(
            'inputresolution', 'Data/fv3files', cf['levels'])
        outputresolution = geosconf.geometry_dict(
            'outputresolution', 'Data/fv3files', cf['levels'])

        # Variable change
        invars = cf['invars']
        outvars = cf['outvars']

        varcha = commconf.varcha_d2a_dict(invars, outvars)

        # Path / filesname input
        input_path_ = dt.strftime(cf['input_path'])
        input_filename_bkgd = dt.strftime(cf['input_filename_bkgd'])
        input_filename_crtm = dt.strftime(cf['input_filename_crtm'])
        input_filename_core = dt.strftime(cf['input_filename_core'])
        input_filename_mois = dt.strftime(cf['input_filename_mois'])
        input_filename_surf = dt.strftime(cf['input_filename_surf'])

        # Path / filesname output
        output_path_ = dt.strftime(cf['input_path'])
        output_filename_bkgd = dt.strftime(cf['output_filename_bkgd'])
        output_filename_crtm = dt.strftime(cf['output_filename_crtm'])
        output_filename_core = dt.strftime(cf['output_filename_core'])
        output_filename_mois = dt.strftime(cf['output_filename_mois'])
        output_filename_surf = dt.strftime(cf['output_filename_surf'])

        input = {}
        output = {}

        dict_states = {}
        dict_states["states"] = []

        for e in range(1, cf['nstates']+1):

            input_path = input_path_.replace('$STATE', str(e).zfill(3))
            output_path = output_path_.replace('$STATE', str(e).zfill(3))

            # Input/output for member
            input = geosconf.state_dict('input', input_path, input_filename_bkgd, input_filename_crtm, input_filename_core,
                                        input_filename_mois, input_filename_surf, variables=invars)
            output = geosconf.output_dict('output', output_path, output_filename_bkgd, output_filename_crtm, output_filename_core,
                                          output_filename_mois, output_filename_surf)

            inputout = {**input, **output}

            dict_states["states"].append(inputout)

        dict = {**inputresolution, **outputresolution, **varcha, **dict_states}

        # Write to yaml file
        with open(cf['yamlout'], 'w') as outfile:
            yaml.dump(dict, outfile, default_flow_style=False)

    exit()

# --------------------------------------------------------------------------------------------------

if __name__ == "__main__":
    main()

# --------------------------------------------------------------------------------------------------
