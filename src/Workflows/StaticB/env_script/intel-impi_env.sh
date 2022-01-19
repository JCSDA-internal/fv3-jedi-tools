#!/bin/bash

source /etc/bashrc
module purge
export JEDI_OPT=/work/noaa/da/jedipara/opt/modules
module use $JEDI_OPT/modulefiles/core
module load jedi/intel-impi
module list
ulimit -s unlimited
ulimit -v unlimited
export SLURM_EXPORT_ENV=ALL
export HDF5_USE_FILE_LOCKING=FALSE
