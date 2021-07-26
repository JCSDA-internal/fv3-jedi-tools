#!/bin/bash

####################################################################
# REGRIDDING #######################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/regridding_${yyyymmddhh_first}-${yyyymmddhh_last}

# Create output directory
mkdir -p ${data_dir_c192}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_c192}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}

# REGRIDDING yaml
yaml_name="regridding_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
    state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  output:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c192}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
- input:
    filetype: gfs
    state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  output:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c192}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

# REGRIDDING sbatch
sbatch_name="regridding_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regridding_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/regridding_${yyyymmddhh_first}-${yyyymmddhh_last}/regridding_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/regridding_${yyyymmddhh_first}-${yyyymmddhh_last}/regridding_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/regridding_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_convertstate.x ${yaml_dir}/${yaml_name}

exit 0
EOF
