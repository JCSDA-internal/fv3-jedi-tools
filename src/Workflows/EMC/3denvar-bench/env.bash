# Modules to run with
source $MODULESHOME/init/bash
module purge
OPT=/discover/swdev/jcsda/modules
module use $OPT/modulefiles/apps
module use $OPT/modulefiles/core
module load jedi/intel-impi/19.1.0.166
module list

# Bin directory for build
JEDIBIN=/discover/nobackup/drholdaw/JediDev/fv3-bundle/work/build-intel-impi-19.1.0.166-release-fv3/bin
YAMLDIR=config

# Data directory
DATADIR=/gpfsm/dnb31/drholdaw/JediWork/3denvar-bench/Data
