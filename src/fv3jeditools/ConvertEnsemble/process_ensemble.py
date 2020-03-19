#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

"""

Tool to obtain ensemble restarts from archive.

User provides a date range, the number of cycles and a random seed. If number of cycles is set
to 0 then a list of dates will be read from a file called datetimes_to_process.txt. This should be
formated as e.g.:
2019061200
2019061300
2019061406
etc

Looping over number of cycles the algorithm is:

1. Get all ensemble memebers for the cycle.
2. Untar the data
3. Convert to B matrix variables, psi chi etc using an parallel job.
4. Check for sucessful conversion.
5. Remove the original data

"""


# External libraries
# ------------------

import numpy as np
import os
import datetime
import argparse
import random
import yaml

import fv3jeditools.Utils.utils as utils
import fv3jeditools.ConvertEnsemble.fv3mod_ens_proc as fv3model


def main():

    # User input
    # ----------

    sargs = argparse.ArgumentParser()

    # Configuration file
    sargs.add_argument("-c", "--config")

    # Optional datetime configuration
    sargs.add_argument("-f", "--readdatetimes", default='0')
    sargs.add_argument("-s", "--start",         default='2019061200')  # yyyymmddHH
    sargs.add_argument("-e", "--end",           default='2019101506')  # yyyymmddHH
    sargs.add_argument("-q", "--freq",          default='6')           # Hours
    sargs.add_argument("-n", "--ncycs",         default='100')
    sargs.add_argument("-r", "--rseed",         default='1')

    args = sargs.parse_args()
    readdts = int(args.readdatetimes) == 1
    start = args.start
    final = args.end
    freq = int(args.freq)
    ncycs = int(args.ncycs)
    rseed = int(args.rseed)

    # Load configuraiton file
    conffile = args.config
    with open(conffile, 'r') as ystream:
        try:
            conf = yaml.safe_load(ystream)
        except yaml.YAMLError as exc:
            print(exc)

    jedidir = conf['jedi_dir']
    workdir = conf['work_dir']
    datadir = conf['data_dir']
    model = conf['model']
    compt = conf['machine']

    if jedidir == '':
        print("ABORT: please provide path to JEDI build with -j or --jedi_dir")
        exit()

    if workdir == '':
        print("ABORT: please provide diretory to work from with -w or --work_dir")
        exit()

    if datadir == '':
        print("ABORT: please provide data directory with -d or --data_dir")
        exit()

    if compt == '':
        print("ABORT: please provide maching to run on, hera or discover")
        exit()

    print("\n Ensemble processing for Static B ... \n")
    if (readdts):
        print(" Will read date times to process from datetimes_to_process.txt")
    else:
        print(" Not reading from file will geneate processing dates from the following: ")
        print("  - Start datetime: "+start)
        print("  - Final datetime: "+final)
        print("  - Frequency of cycles: "+str(freq))
        print("  - Number cycles:  "+str(ncycs))
        print("  - Random seed:    "+str(rseed))

    print("  - Model being used is "+model)
    print("  - JEDI build path: "+jedidir)
    print("  - Working directory: "+workdir)
    print("  - Data directory: "+datadir)

    print("\n")


    # Construct class with model specific methods
    # -------------------------------------------
    fv3model = fv3model.factory.create(model.upper())


    # Set up list of dates to process
    # -------------------------------

    if (readdts):

        with open(os.path.join(workdir, 'datetimes_to_process.txt'), 'r') as fh:
            datetimes_str = fh.readlines()

        ncycs = len(datetimes_str)
        tmp = datetimes_str[0]
        start = tmp[0:10]
        tmp = datetimes_str[ncycs-1]
        final = tmp[0:10]
        freq = 0
        rseed = -1

        datetimes = np.empty([ncycs], dtype=datetime.datetime)

        for n in range(ncycs):
            tmp = str(datetimes_str[n])
            datetimes[n] = datetime.datetime.strptime(tmp[0:10], utils.dtformat)

    else:

        # Set datetime and delta objects based on total range
        datetime_start = datetime.datetime.strptime(start, utils.dtformat)
        datetime_final = datetime.datetime.strptime(final, utils.dtformat)
        totaldelta = datetime_final-datetime_start
        totalhour = totaldelta.total_seconds()/3600

        # Check user provided sensible frequency
        resi = totalhour/freq - float(int(totalhour/freq))
        if (resi != 0.0):
            print(" ABORT: (final-start)/freq is not a whole number")
            exit()

        # Total number of cyles
        ntcycs = int(totalhour / freq) + 1

        # Array to sample from
        tdatetimes = np.array(
            [datetime_start + datetime.timedelta(hours=6*i) for i in range(ntcycs)])

        # Check that number of cycles user wants is compatible with provided range
        if (ntcycs < ncycs):
            print(" WARNING: total date range does not contain enough cycles for input choice, "
                "reducing to every datetime in the range.")
            ncycs = ntcycs

        # Non replacement random sample of size ncycs
        random.seed(rseed)
        datetimes_index = np.sort(random.sample(range(ntcycs), ncycs))

        # Fill up array of datetimes using random selection
        datetimes = np.empty([ncycs], dtype=datetime.datetime)
        for n in range(ncycs):
            datetimes[n] = tdatetimes[datetimes_index[n]]


    # Write the datetimes being processed to file
    # -------------------------------------------
    with open('datetimes_processed.txt', 'w') as fh:
        for item in datetimes:
            fh.write("%s\n" % item.strftime(utils.dtformat))


    # Loop over cycles and process the ensemble
    # -----------------------------------------
    n = 0
    num2stage = 4
    num_staged = 0

    while num_staged < num2stage:

        # Datetime and directories for this cycle
        fv3model.cycleTime(datetimes[n])
        fv3model.setDirectories(workdir, datadir)

        # Get the members for this cycle from archive
        fv3model.getEnsembleMembersFromArchive()

        # Untar the members
        fv3model.extractEnsembleMembers()

        # Post extract clean up
        fv3model.postExtractEnsembleMembers()

        # Remove ensemble tar files
        fv3model.removeEnsembleArchiveFiles()

        # # Prepare for converting members
        # fv3model.prepare2Convert()

        # # Convert to psi/chi
        # fv3model.convertMembersSlurm(compt,6,16,1,jedidir)

        # Tar converted members for transfer
        fv3model.tarWorkDirectory()

        # Send tar file to s3
        fv3model.ship2S3(conf['s3path'])

        # Finished
        fv3model.finished()

        # Count number of staged
        if os.path.exists(os.path.join(fv3model.rootDir, fv3model.tarFile)):
            num_staged = num_staged + 1
        print("\n Number staged: "+str(num_staged))

        # Cycle
        n = n + 1

    print("Number of staged cycles is " +
        str(num2stage)+", no more processing for now.")


if __name__ == "__main__":
    main()
