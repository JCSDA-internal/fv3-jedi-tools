#!/bin/bash

source /etc/bashrc
module purge
export JEDI_OPT=/work/noaa/da/grubin/opt/modules
module use $JEDI_OPT/modulefiles/core
#module load jedi/intel-impi
module load git/2.28.0 git-lfs/2.11.0 python/3.7.5 intel/2020 szip/2.1.1 zlib/1.2.11 udunits/2.2.26 gsl_lite/0.37.0 impi/2020 hdf5/1.10.06-parallel pnetcdf/1.12.1 netcdf/4.7.4 boost-headers/1.73.0 eigen/3.3.7 pybind11/2.5.0 pio/2.5.1-debug cmake/3.18.1 ecbuild/ecmwf-3.6.1 eckit/ecmwf-1.16.0 fckit/ecmwf-0.9.2 atlas/ecmwf-0.24.1 jedi/intel-impi/2020 
module list
ulimit -s unlimited
ulimit -v unlimited
export SLURM_EXPORT_ENV=ALL
export HDF5_USE_FILE_LOCKING=FALSE
