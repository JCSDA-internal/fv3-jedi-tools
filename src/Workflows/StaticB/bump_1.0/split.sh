#!/bin/bash

####################################################################
# PSICHITOUV #######################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}

# PSICHITOUV yaml
yaml_name="split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nsplit},${nsplit}]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  datadir: ${data_dir_c384}/${bump_dir}
  prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  new_wind: 1
  write_wind_local: 1
  wind_nlon: 400
  wind_nlat: 200
  wind_nsg: 5
  wind_inflation: 1.1
EOF

# PSICHITOUV sbatch
sbatch_name="split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nsplit*nsplit))
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}/split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}/split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.out

export OMP_NUM_THREADS=2
source ${env_script}

cd ${work_dir}/split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n $((6*nsplit*nsplit)) ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# VBAL #############################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}

# VBAL yaml
yaml_name="split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nsplit},${nsplit}]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  datadir: ${data_dir_c384}/${bump_dir}
  prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal: 1
  write_vbal: 1
  fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
  ens1_nsub: ${yyyymmddhh_size}
  load_samp_global: 1
  write_samp_local: 1
  vbal_block: [1,1,0,1]
EOF

# VBAL sbatch
sbatch_name="split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nsplit*nsplit))
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}/split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}/split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n $((6*nsplit*nsplit)) ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# NICAS ############################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}

# NICAS yaml
yaml_name="split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nsplit},${nsplit}]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  load_nicas_global: 1
  write_nicas_local: 1
  min_lev:
    liq_wat: 76
  grids:
  - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
  - variables: [surface_pressure]
    fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
universe radius:
  filetype: gfs
  psinfile: 1
  datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

# NICAS sbatch
sbatch_name="split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nsplit*nsplit))
#SBATCH --cpus-per-task=2
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}/split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}/split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.out

export OMP_NUM_THREADS=2
source ${env_script}

cd ${work_dir}/split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n $((6*nsplit*nsplit)) ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF
