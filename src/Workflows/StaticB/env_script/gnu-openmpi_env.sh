#!/bin/bash

source /etc/bashrc
module purge
module use /work/noaa/da/role-da/spack-stack/modulefiles
module load miniconda/3.9.7
module load ecflow/5.8.4
module use /work/noaa/da/role-da/spack-stack/spack-stack-v1/envs/skylab-3.0.0-gnu-10.2.0/install/modulefiles/Core
module load stack-gcc/10.2.0
module load stack-openmpi/4.0.4
module load stack-python/3.9.7
module load jedi-ewok-env/1.0.0 jedi-fv3-env/1.0.0 soca-env/1.0.0

ulimit -s unlimited
ulimit -v unlimited
export SLURM_EXPORT_ENV=ALL
export HDF5_USE_FILE_LOCKING=FALSE
export MALLOC_MMAP_MAX_=0
export MALLOC_TRIM_THRESHOLD_=-1
