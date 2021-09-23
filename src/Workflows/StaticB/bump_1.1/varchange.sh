#!/bin/bash

# Date
yyyymmddhh=$1

# Internal parameters
yyyy=${yyyymmddhh:0:4}
mm=${yyyymmddhh:4:2}
dd=${yyyymmddhh:6:2}
hh=${yyyymmddhh:8:2}

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/${yyyymmddh}
for imem in $(seq 1 1 1); do #${nmem}); do
   imemp=$(printf "%.3d" "${imem}")
   mkdir -p ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem${imemp}
done
mkdir -p ${work_dir}/varchange_${yyyymmddhh}

# VARCHANGE yaml
yaml_name="varchange_${yyyymmddhh}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
input geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [6,6]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
output geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [6,6]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
variable changes:
- variable change: Control2Analysis
  input variables: &controlVars [psi,chi,tv,ps,rh]
  output variables: &ensVars [psi,chi,t,tv,delp,ps,sphum]
  do inverse: true
  skip femps initialization: true
states:
EOF
for imem in $(seq 16 1 16); do #${nmem}); do
   imemp=$(printf "%.3d" "${imem}")
cat<< EOF >> ${yaml_dir}/${yaml_name}
- input:
    filetype: gfs
    state variables: *ensVars
    psinfile: 1
    datapath: ${data_dir_c384}/${yyyymmddhh}/mem${imemp}
    filename_core: bvars.fv_core.res.nc
    filename_trcr: bvars.fv_tracer.res.nc
    filename_cplr: bvars.coupler.res
    date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  output:
    filetype: gfs
    state variables: *controlVars
    prepend files with date: 0
    datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem${imemp}
    filename_core: bvars.fv_core.res.nc
    filename_trcr: bvars.fv_tracer.res.nc
    filename_cplr: bvars.coupler.res
    date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
EOF
done

# VARCHANGE sbatch
sbatch_name="varchange_${yyyymmddhh}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=varchange_${yyyymmddhh}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH -e ${work_dir}/varchange_${yyyymmddhh}/varchange_${yyyymmddhh}.err
#SBATCH -o ${work_dir}/varchange_${yyyymmddhh}/varchange_${yyyymmddhh}.out

source ${env_script}

cd ${work_dir}/varchange_${yyyymmddhh}
mpirun -n 216 ${bin_dir}/fv3jedi_convertstate.x ${yaml_dir}/${yaml_name}
#rm -fr ${data_dir_c384}/${yyyymmddhh}

exit 0
EOF

# Run sbatch script
cmd="sbatch ${sbatch_dir}/${sbatch_name}"
pid=$(eval ${cmd})
pid=${pid##* }
echo `date`": ${cmd} > "${pid}
