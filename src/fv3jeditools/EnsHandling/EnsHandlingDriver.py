#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import argparse
import os

import fv3jeditools.EnsHandling.EnsHandling as EnsHandling
import fv3jeditools.Utils.utils as utils

def main():

    sargs = argparse.ArgumentParser()
    sargs.add_argument("-s", "--start_date",    default='2019010000')
    sargs.add_argument("-f", "--final_date",    default='2020123100')
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

    for dt in dts:

        process_date = dt.strftime(dtformat)

        os.environ['PDATE'] = process_date
        os.environ['CFILE'] = conf

        eh = EnsHandling.EnsembleHandling()

        eh.downloadGeosEnsRestartArchive()

    exit()


if __name__ == "__main__":
    main()
