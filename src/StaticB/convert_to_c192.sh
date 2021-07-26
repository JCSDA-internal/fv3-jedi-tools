#!/bin/bash

# Parameters
yyyymmddhh="2020011000"

# Directories
export data_dir="/work/noaa/da/menetrie/StaticBTraining"
export xp_dir="${HOME}/xp"
export build_dir="${HOME}/build/gnu-openmpi"

####################################################################
# No edition needed beyond this line ###############################
####################################################################

# Date
yyyy=${yyyymmddhh:0:4}
mm=${yyyymmddhh:4:2}
dd=${yyyymmddhh:6:2}
hh=${yyyymmddhh:8:2}
echo `date`": date is ${yyyymmddhh}"

# Define directories
echo `date`": define directories"
export bin_dir="${build_dir}/bundle/bin"
export sbatch_dir="${xp_dir}/sbatch"
export work_dir="${xp_dir}/work"
export yaml_dir="${xp_dir}/yaml"

# Create directories
echo `date`": create directories"
mkdir -p ${data_dir_c192}/${first_member_dir}
mkdir -p ${data_dir_c192}/${bkg_dir}
mkdir -p ${yaml_dir}
mkdir -p ${sbatch_dir}
mkdir -p ${work_dir}

# Create specific work directory
mkdir -p ${work_dir}/convert_to_c192_${yyyymmddhh}

# CONVERT_TO_C192 yaml
yaml_name="convert_to_c192_${yyyymmddhh}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
input geometry:
  nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
  trc_file: ${data_dir}/fv3files/field_table
  akbk: ${data_dir}/fv3files/akbk127.nc4
  layout: [6,6]
  io_layout: [1,1]
  npx: 385
  npy: 385
  npz: 127
  ntiles: 6
  fieldsets:
    - fieldset: ${data_dir}/fieldsets/dynamics.yaml
output geometry:
  nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
  trc_file: ${data_dir}/fv3files/field_table
  akbk: ${data_dir}/fv3files/akbk127.nc4
  layout: [6,6]
  io_layout: [1,1]
  npx: 193
  npy: 193
  npz: 127
  ntiles: 6
  fieldsets:
    - fieldset: ${data_dir}/fieldsets/dynamics.yaml
states:
- input:
    filetype: gfs
    state variables: [ua,va,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    datapath: ${data_dir_c384}/${bkg_dir}
    filename_core: ${yyyy}${mm}${dd}.${hh}0000.fv_core.res.nc
    filename_trcr: ${yyyy}${mm}${dd}.${hh}0000.fv_tracer.res.nc
    filename_cplr: ${yyyy}${mm}${dd}.${hh}0000.coupler.res
  output:
    filetype: gfs
    datapath: ${data_dir_c192}/${bkg_dir}
    filename_core: fv_core.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_cplr: coupler.res
- input:
    filetype: gfs
    state variables: [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    datapath: ${data_dir_c384}/${first_member_dir}
    filename_core: bvars.fv_core.res.nc
    filename_trcr: bvars.fv_tracer.res.nc
    filename_cplr: bvars.coupler.res
  output:
    filetype: gfs
    datapath: ${data_dir_c192}/${first_member_dir}
    filename_core: bvars.fv_core.res.nc
    filename_trcr: bvars.fv_tracer.res.nc
    filename_cplr: bvars.coupler.res
EOF

# CONVERT_TO_C192 sbatch
sbatch_name="convert_to_c192_${yyyymmddhh}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=convert_to_c192_${yyyymmddhh}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/convert_to_c192_${yyyymmddhh}/convert_to_c192_${yyyymmddhh}.err
#SBATCH -o ${work_dir}/convert_to_c192_${yyyymmddhh}/convert_to_c192_${yyyymmddhh}.out

source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/convert_to_c192_${yyyymmddhh}
mpirun -n 216 ${bin_dir}/fv3jedi_convertstate.x ${yaml_dir}/${yaml_name}

for i in $(seq 1 6); do
   mv ${data_dir_c192}/${first_member_dir}/${yyyy}${mm}${dd}.${hh}0000.bvars.fv_core.res.tile${i}.nc ${data_dir_c192}/${first_member_dir}/bvars.fv_core.res.tile${i}.nc
   mv ${data_dir_c192}/${first_member_dir}/${yyyy}${mm}${dd}.${hh}0000.bvars.fv_tracer.res.tile${i}.nc ${data_dir_c192}/${first_member_dir}/bvars.fv_tracer.res.tile${i}.nc
done
mv ${data_dir_c192}/${first_member_dir}/${yyyy}${mm}${dd}.${hh}0000.bvars.coupler.res ${data_dir_c192}/${first_member_dir}/bvars.coupler.res

exit 0
EOF

# Run convert_to_c192
echo `date`": sbatch ${sbatch_name}"
sbatch ${sbatch_dir}/${sbatch_name}

exit 0
