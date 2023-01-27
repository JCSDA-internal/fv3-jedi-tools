#!/bin/bash

source /etc/bashrc
module purge
module use /work/noaa/da/role-da/spack-stack/modulefiles
module load miniconda/3.9.7
module load ecflow/5.8.4
module use /work/noaa/da/role-da/spack-stack/spack-stack-v1/envs/skylab-3.0.0-intel-2022.0.2/install/modulefiles/Core
module load stack-intel/2022.0.2
module load stack-intel-oneapi-mpi/2021.5.1
module load stack-python/3.9.7
module load jedi-ewok-env/1.0.0 jedi-fv3-env/1.0.0 soca-env/1.0.0
module load nco
module list
ulimit -s unlimited
ulimit -v unlimited
export SLURM_EXPORT_ENV=ALL
export HDF5_USE_FILE_LOCKING=FALSE
export MALLOC_MMAP_MAX_=0
export MALLOC_TRIM_THRESHOLD_=-1
