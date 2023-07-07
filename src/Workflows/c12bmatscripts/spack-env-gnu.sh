#!/bin/bash

source /etc/bashrc
module purge
module use /work/noaa/da/role-da/spack-stack/modulefiles
module load miniconda/3.9.7
module load ecflow/5.8.4
module load mysql/8.0.31
module use /work/noaa/epic-ps/role-epic-ps/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core
module load stack-gcc/10.2.0
module load stack-openmpi/4.0.4
module load stack-python/3.9.7
module load jedi-fv3-env/unified-dev
module load jedi-ewok-env/unified-dev
module load soca-env/unified-dev
ulimit -s unlimited
ulimit -v unlimited
export SLURM_EXPORT_ENV=ALL
export HDF5_USE_FILE_LOCKING=FALSE
export MALLOC_MMAP_MAX_=0
export MALLOC_TRIM_THRESHOLD_=-1
