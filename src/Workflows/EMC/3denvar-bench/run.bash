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

# Run 3DEnVar analysis
# --------------------
rm -rf Data/analysis Data/hofx
mkdir -p Data/analysis Data/hofx
#mpirun -np 36 $JEDIBIN/fv3jedi_var.x $YAMLDIR/3denvar_c192.yaml # Low res
mpirun -np 384 $JEDIBIN/fv3jedi_var.x $YAMLDIR/3denvar.yaml # Regular

# Clean up
# --------
rm -f logfile.000000.out input.nml field_table
