#!/usr/bin/env bash

# Slurm
# -----
#SBATCH --account=g0613
#SBATCH --qos=advda
#SBATCH --job-name=bench-prep
#SBATCH --output=bench-prep.o%j
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=36
#SBATCH --time=00:30:00
#SBATCH --constraint=sky

# Setup the environment
# ---------------------
source env.bash

# Link in data directory
# ----------------------
rm -f Data
ln -s $DATADIR ./

# Convert background and state to low resolution
# ----------------------------------------------
#mpirun -np 36 $JEDIBIN/fv3jedi_convertstate.x $YAMLDIR/convert_bkg.yaml
#mpirun -np 36 $JEDIBIN/fv3jedi_convertstate.x $YAMLDIR/convert_ensemble.yaml

# Compute localization model
# --------------------------
rm -rf Data/localization
mkdir -p Data/localization
#mpirun -np 36 $JEDIBIN/fv3jedi_parameters.x $YAMLDIR/localization_c96.yaml # Low res
mpirun -np 384 $JEDIBIN/fv3jedi_parameters.x $YAMLDIR/localization.yaml      # Regular

# Clean up
# --------
rm -f logfile.000000.out input.nml field_table
