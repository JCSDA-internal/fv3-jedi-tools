echo "MyDir"
pwd

# Modules
# -------

# Purge any existing modules
source $MODULESHOME/init/sh
module purge

# Load fv3-jedi-tools
module use -a /scratch1/NCEPDEV/da/Daniel.Holdaway/opt/modulefiles
module load core/fv3-jedi-tools

# JEDI modules
module use -a /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/modules/
module load jedi-stack/intel-impi-18.0.5
module unload intelpython/3.6.8

# Load Python 3
module use -a /scratch2/NCEPDEV/marineda/Jong.Kim/save/modulefiles
module load anaconda/3.15.1

# Load HPSS for tape access
module load hpss/hpss

# List loaded modules
module list


# Prepare yaml files
# ------------------
fv3jeditools.x $DATETIME $HOMEDIR/stage_jedi_config.yaml


# Run conversions
# ---------------
cd $WORKDIR
/apps/slurm/default/bin/srun $JEDIBLD/bin/fv3jedi_convertstate.x Config/convertstate_readwrite.yaml

e=$?
if [[ $e -gt 0 ]]; then
    echo -e "convertstate_readwrite failed to run executable. Error code: $e \n"
    exit $e
fi

/apps/slurm/default/bin/srun $JEDIBLD/bin/fv3jedi_convertstate.x Config/convertstate_cold2bvars.yaml

e=$?
if [[ $e -gt 0 ]]; then
    echo -e "convertstate_cold2bvars failed to run executable. Error code: $e \n"
    exit $e
fi
