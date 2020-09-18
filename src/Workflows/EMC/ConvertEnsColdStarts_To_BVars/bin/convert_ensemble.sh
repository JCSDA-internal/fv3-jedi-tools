echo "MyDir"
pwd



source $MODULESHOME/init/sh
module use -a /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/modules/
module load jedi-stack/intel-impi-18.0.5
module list

#/apps/slurm/default/bin/srun $JEDIBLD/bin/fv3jedi_convertstate.x Config/cold_start_to_bvars.yaml
