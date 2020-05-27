#!/usr/bin/env python

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import subprocess
import os
import datetime as dt
import numpy as np
import random
import shlex
import subprocess
import sys
import tarfile
import time

__all__ = ['dtformat', 'dtformatprnt',
           'setDateConfigFile', 'setDone', 'isDone',
           'getDateTimes', 'createPath',
           'run_csh_command', 'run_bash_command', 'run_shell_command',
           'getFileSize', 'wait_for_batch_job', 'abort',
           'depends', 'ship2S3', 'recvS3', 'lines_that_contain']

# --------------------------------------------------------------------------------------------------

# Datetime formats
dtformat = '%Y%m%d%H'
dtformatprnt = '%Y%m%d %Hz'

# ------------------------------------------------------------------------------------------------


def setDateConfigFile(date, config_in, config_out, prefix=''):

    datetime = dt.datetime.strptime(date, '%Y%m%d%H')

    yyyy = datetime.strftime("%Y")
    mm = datetime.strftime("%m")
    dd = datetime.strftime("%d")
    hh = datetime.strftime("%H")

    # Read template and set datetime
    conf_in = open(config_in).read()
    conf_in = conf_in.replace('%Y'+prefix, yyyy)
    conf_in = conf_in.replace('%m'+prefix, mm)
    conf_in = conf_in.replace('%d'+prefix, dd)
    conf_in = conf_in.replace('%H'+prefix, hh)

    # Write the new conf file
    conf_out = open(config_out, 'w')
    conf_out.write(conf_in)
    conf_out.close()

# ------------------------------------------------------------------------------------------------

def randomDateTimes(start, final, freq, rseed, num_random):

    totaldelta = final - start
    totalhour = totaldelta.total_seconds()/3600

    # Check user provided sensible frequency
    resi = totalhour/freq - float(int(totalhour/freq))
    if (resi != 0.0):
        abort("utils.getDateTimes: (final-start)/freq is not a whole number")

    # Total number of cyles
    ntcycs = int(totalhour / freq) + 1

    # Build array of datetimes
    tdatetimes = np.array([start + dt.timedelta(hours=freq*i) for i in range(ntcycs)])

    # Check that number of cycles user wants is compatible with provided range
    ncycs = num_random
    if (ntcycs < ncycs):
        print(" WARNING: total date range does not contain enough cycles for input choice, "
              "reducing to every datetime in the range.")
        ncycs = ntcycs

    # Non replacement random sample of size ncycs
    random.seed(rseed)
    datetimes_index = np.sort(random.sample(range(ntcycs), ncycs))

    # Fill up array of datetimes using random selection
    datetimes = np.empty([ncycs], dtype=dt.datetime)
    for n in range(ncycs):
        datetimes[n] = tdatetimes[datetimes_index[n]]

    return datetimes

# ------------------------------------------------------------------------------------------------


def getDateTimes(start, final, freq, dtform=dtformat):

    # Set datetime and delta objects based on total range
    datetime_start = dt.datetime.strptime(start, dtform)
    if final != '':
        datetime_final = dt.datetime.strptime(final, dtform)
    else:
        datetime_final = dt.datetime.now()

    totaldelta = datetime_final-datetime_start
    totalseconds = totaldelta.total_seconds()

    # List of dates to process
    ntcycs = int(totalseconds / float(freq)) + 1

    # Check for proper freuqncey
    resi = totalseconds/freq - float(int(totalseconds/freq))
    if (resi != 0.0):
        abort("utils.getDateTimes: (final-start)/freq is not a whole number")

    # Array of date times
    dts = np.array([datetime_start + dt.timedelta(seconds=freq*i)
                    for i in range(ntcycs)])

    return dts

# --------------------------------------------------------------------------------------------------

def tarExtract(filename, extract_files=None, extract_path='.'):

    print("utils.tarExtract: Opening file: "+filename)

    # Searches for everything matching extract_files and extracts from filename to extract path.

    # Open file
    tar = tarfile.open(filename)

    # Build list of members that match input strings
    all_members = tar.getmembers()
    ext_members = []
    for mem in all_members:
      for file in extract_files:
        if (file in mem.name):
          ext_members.append(mem)

    # Extract from tar file
    tar.extractall(path=extract_path, members=ext_members)

    # Close the tar file
    tar.close()

# --------------------------------------------------------------------------------------------------

def createPath(dirpath):

    if not os.path.exists(dirpath):
        os.makedirs(dirpath)

# --------------------------------------------------------------------------------------------------


def getFileSize(path_file):

    file_size = -1
    if os.path.exists(path_file):
        file_size = int(os.path.getsize(path_file))

    return file_size

# --------------------------------------------------------------------------------------------------


def run_shell_command(command_line, wait=True):

    command_line_args = shlex.split(command_line)

    print('utils.run_shell_command: Running command '+command_line)

    try:

        # Submit the job
        shell_job = subprocess.Popen(
            command_line_args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

        # Wait for completion
        if wait:
            shell_job.wait()

    except (OSError, subprocess.CalledProcessError) as exception:

        # Abort if failure detected
        abort("utils.run_shell_command subprocess failed")

    else:

        # All done
        print('utils.run_shell_command: subprocess finished')

# --------------------------------------------------------------------------------------------------


def wait_for_batch_job(username, jobname):

    job_finished = False
    print_job = True

    # Wait incase job has not registered yet
    time.sleep(5)

    # Wait for job to finish
    while not job_finished:

        proc = subprocess.Popen(
            ['squeue', '-l', '-h', '-n', jobname, '-u', username], stdout=subprocess.PIPE)
        squeue_result = proc.stdout.readline().decode('utf-8')

        if print_job:
            print(" Waiting for the following job to complete/fail: ")
            print(" Slurm job info: ")
            print(squeue_result)
            print_job = False

        if squeue_result is '':
            job_finished = True
            print(' Slurm job is finished')
            break

        # If not finished wait another minute
        time.sleep(60)

# --------------------------------------------------------------------------------------------------


def run_csh_command(path, command, tail='', verbose='yes'):

    fname = os.path.join(path, 'csh_command.sh')

    print(fname)

    if tail == '':
        full_command = command
    else:
        full_command = command+' >& '+tail

    # Create file with bash command
    fh = open(fname, "w")
    fh.write("#!/bin/csh -fx \n")
    fh.write("\n")
    fh.write(full_command)
    fh.close()

    # Make executable
    os.chmod(fname, 0o755)

    # Run
    if (verbose == 'yes'):
        print(" Run csh command: "+full_command)
    cwd = os.getcwd()
    os.chdir(path)
    subprocess.call(['./csh_command.sh'])
    os.chdir(cwd)

    # Remove file
    # os.remove(fname)

# --------------------------------------------------------------------------------------------------


def run_bash_command(path, command, tail='', verbose='yes'):

    fname = os.path.join(path, 'bash_command.sh')

    if tail == '':
        full_command = command
    else:
        full_command = command+' > '+tail+' 2>&1'

    # Create file with bash command
    fh = open(fname, "w")
    fh.write("#!/bin/bash \n")
    fh.write(full_command)
    fh.close()

    # Make executable
    os.chmod(fname, 0o755)

    # Run
    if (verbose == 'yes'):
        print(" Run bash command: "+full_command)
    cwd = os.getcwd()
    os.chdir(path)
    subprocess.call(['./bash_command.sh'])
    os.chdir(cwd)

    # Remove file
    os.remove(fname)

    # User didn't request any output
    # if (tail=='tail.txt'):
    # os.remove(os.path.join(path,'tail.txt'))

# --------------------------------------------------------------------------------------------------


def lines_that_contain(string, fp):
    return [line for line in fp if string in line]

# --------------------------------------------------------------------------------------------------


def abort(message):

    print('ABORT: '+message)
    raise(SystemExit)

# --------------------------------------------------------------------------------------------------


def isDone(path, funcname):

    filename = os.path.join(path, funcname)

    if os.path.exists(filename):
        print(" \n Function: "+funcname+" is complete")
        return True
    else:
        print(" \n Function: "+funcname)
        return False

# ------------------------------------------------------------------------------------------------


def setDone(path, funcname):

    print(" Function: "+funcname+" is complete")
    filename = os.path.join(path, funcname)
    open(filename, 'a').close()

# --------------------------------------------------------------------------------------------------


def depends(path, func, funcdepends):

    filename = os.path.join(path, funcdepends)

    if os.path.exists(filename):
        print(" Dependencies of "+func+" are complete")
        return
    else:
        abort(" dependencies of "+func+" are not complete")

# ------------------------------------------------------------------------------------------------


def ship2S3(localpath, localfile, s3path):

    # Local file
    # ----------
    file2ship = os.path.join(localpath, localfile)

    # Path on S3
    # ----------
    s3file = os.path.join(s3path, localfile)

    # File size locally
    # -----------------
    local_file_size = -1
    if (os.path.exists(file2ship)):
        local_file_size = int(os.path.getsize(file2ship))

    # File size on S3
    # ---------------
    tailfile = os.path.join(localpath, "ls_remote_file.txt")
    run_bash_command(localpath, "aws2 s3 ls "+s3file, tailfile)

    # Check size on S3 if existing
    # ----------------------------
    remote_file_size = -1
    with open(tailfile, "r") as fp:
        for line in lines_that_contain(localfile, fp):
            remote_file_size = int(line.split()[2])
    os.remove(tailfile)

    # Copy if sizes do not match
    # --------------------------
    if local_file_size != remote_file_size:

        # Copy file to S3
        run_bash_command(localpath, "aws2 s3 cp "+file2ship+" "+s3file)

        # Recheck File size on S3
        # -----------------------
        tailfile = os.path.join(localpath, "ls_remote_file.txt")
        run_bash_command(localpath, "aws2 s3 ls "+s3file, tailfile)

        remote_file_size = -1
        with open(tailfile, "r") as fp:
            for line in lines_that_contain(localfile, fp):
                remote_file_size = int(line.split()[2])
        os.remove(tailfile)

        # Fail if not matching
        if local_file_size != remote_file_size:
            abort("utils.ship2S3, local size ("+str(local_file_size) +
                  ") does not match S3 size ("+str(remote_file_size)+")")

    else:

        print("utils.ship2S3 file of same size already on S3")

# ------------------------------------------------------------------------------------------------


def recvS3(localpath, localfile, s3path):

    # Local file
    # ----------
    file2recv = os.path.join(localpath, localfile)

    # Path on S3
    # ----------
    s3file = os.path.join(s3path, localfile)

    # File size locally
    # -----------------
    local_file_size = -1
    if (os.path.exists(file2recv)):
        local_file_size = int(os.path.getsize(file2recv))

    print("utils.recvS3: local file size = ", local_file_size)

    # File size on S3
    # ---------------
    tailfile = os.path.join(localpath, "ls_remote_file.txt")
    run_bash_command(localpath, "aws2 s3 ls "+s3file, tailfile)

    # Check size on S3 if existing
    # ----------------------------
    remote_file_size = -1
    with open(tailfile, "r") as fp:
        for line in lines_that_contain(localfile, fp):
            remote_file_size = int(line.split()[2])
    os.remove(tailfile)

    if remote_file_size == -1:
        abort("utils.recvS3: file "+localfile+" not available on S3")

    print("utils.recvS3: s3 file size = ", remote_file_size)

    # Copy if sizes do not match
    # --------------------------
    if local_file_size != remote_file_size:

        # Copy file from S3
        run_bash_command(localpath, "aws2 s3 cp "+s3file+" "+file2recv)

        # Recheck File size on S3
        # -----------------------
        local_file_size = -1
        if (os.path.exists(file2recv)):
            local_file_size = int(os.path.getsize(file2recv))

        # Fail if not matching
        if local_file_size != remote_file_size:
            abort("utils.recvS3, local size ("+str(local_file_size) +
                  ") does not match S3 size ("+str(remote_file_size)+")")

    else:

        print("utils.recvS3 file of same size already copied from S3")

# ------------------------------------------------------------------------------------------------
