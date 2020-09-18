source $MODULESHOME/init/sh

# Purge any existing modules
module purge

# Load fv3-jedi-tools
module use -a /scratch1/NCEPDEV/da/Daniel.Holdaway/opt/modulefiles
module load core/fv3-jedi-tools

# Load Python 3
module use -a /scratch2/NCEPDEV/marineda/Jong.Kim/save/modulefiles
module load anaconda/3.15.1

# Load HPSS for tape access
module load hpss/hpss

# List loaded modules
module list
