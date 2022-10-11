#!/bin/bash

# Source functions
source ./functions.sh

# Create data directories
mkdir -p ${data_dir_def}/${bump_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_full_c2a_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}

####################################################################
# DIRAC_COR_LOCAL ##################################################
####################################################################

# Job name
job=dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COR_LOCAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &active_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input field:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: [stream_function,stream_function,stream_function,stream_function,stream_function,stream_function,velocity_potential,velocity_potential,velocity_potential,velocity_potential,velocity_potential,velocity_potential,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,specific_humidity,specific_humidity,specific_humidity,specific_humidity,specific_humidity,specific_humidity,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,surface_pressure,surface_pressure,surface_pressure,surface_pressure,surface_pressure,surface_pressure]
EOF

# DIRAC_COR_LOCAL sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_COR_GLOBAL #################################################
####################################################################

# Job name
job=dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COR_GLOBAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &active_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_global: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
    - parameter: nicas_norm
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: nicas_norm.fv_core.res.nc
        filename_trcr: nicas_norm.fv_tracer.res.nc
        filename_cplr: nicas_norm.coupler.res
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: [stream_function,stream_function,stream_function,stream_function,stream_function,stream_function,velocity_potential,velocity_potential,velocity_potential,velocity_potential,velocity_potential,velocity_potential,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,specific_humidity,specific_humidity,specific_humidity,specific_humidity,specific_humidity,specific_humidity,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,surface_pressure,surface_pressure,surface_pressure,surface_pressure,surface_pressure,surface_pressure]
EOF

# DIRAC_COR_GLOBAL sbatch
ntasks=${ntasks_def}
cpus_per_task=2
threads=1
time=01:00:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_COV_LOCAL ##################################################
####################################################################

# Job name
job=dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_LOCAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &control_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: [stream_function,stream_function,stream_function,stream_function,stream_function,stream_function,velocity_potential,velocity_potential,velocity_potential,velocity_potential,velocity_potential,velocity_potential,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,specific_humidity,specific_humidity,specific_humidity,specific_humidity,specific_humidity,specific_humidity,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,surface_pressure,surface_pressure,surface_pressure,surface_pressure,surface_pressure,surface_pressure]
EOF

# DIRAC_COV_LOCAL sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_COV_GLOBAL #################################################
####################################################################

# Job name
job=dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_GLOBAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &control_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_global: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
    - parameter: nicas_norm
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: nicas_norm.fv_core.res.nc
        filename_trcr: nicas_norm.fv_tracer.res.nc
        filename_cplr: nicas_norm.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: [stream_function,stream_function,stream_function,stream_function,stream_function,stream_function,velocity_potential,velocity_potential,velocity_potential,velocity_potential,velocity_potential,velocity_potential,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,specific_humidity,specific_humidity,specific_humidity,specific_humidity,specific_humidity,specific_humidity,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,cloud_liquid_water,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,ozone_mass_mixing_ratio,surface_pressure,surface_pressure,surface_pressure,surface_pressure,surface_pressure,surface_pressure]
EOF

# DIRAC_COV_GLOBAL sbatch
ntasks=${ntasks_def}
cpus_per_task=2
threads=1
time=01:00:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_COV_MULTI_LOCAL ############################################
####################################################################

# Job name
job=dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_MULTI_LOCAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &control_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_COV_MULTI_LOCAL sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_COV_MULTI_GLOBAL ###########################################
####################################################################

# Job name
job=dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_MULTI_GLOBAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &control_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_global: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
    - parameter: nicas_norm
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: nicas_norm.fv_core.res.nc
        filename_trcr: nicas_norm.fv_tracer.res.nc
        filename_cplr: nicas_norm.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_global: true
      vbal_block: [true, true,false, true,false,false]
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_COV_MULTI_GLOBAL sbatch
ntasks=${ntasks_def}
cpus_per_task=2
threads=1
time=01:00:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_FULL_C2A_LOCAL #############################################
####################################################################

# Job name
job=dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_C2A_LOCAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &state_vars [ua,va,air_temperature,delp,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  datapath: ${ensemble_dir}/c${cdef}/${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filename_core: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.fv_core.1.res.nc
  filename_trcr: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.fv_tracer.1.res.nc
  filename_sfcd: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.sfc_data.1.nc
  filename_sfcw: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.fv_srf_wnd.1.res.nc
  filename_cplr: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.PT3H.coupler.res.1
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *state_vars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_FULL_C2A_LOCAL sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_FULL_PSICHITOUV_LOCAL ######################################
####################################################################

# Job name
job=dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_PSICHITOUV_LOCAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &state_vars [ua,va,air_temperature,delp,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  datapath: ${ensemble_dir}/c${cdef}/${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filename_core: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.fv_core.1.res.nc
  filename_trcr: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.fv_tracer.1.res.nc
  filename_sfcd: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.sfc_data.1.nc
  filename_sfcw: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.fv_srf_wnd.1.res.nc
  filename_cplr: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.PT3H.coupler.res.1
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  - saber block name: BUMP_PsiChiToUV
    active variables: [stream_function,velocity_potential,ua,va]
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_wind_local: true
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_FULL_PSICHITOUV_LOCAL sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_FULL_C2A_GLOBAL ################################################
####################################################################

# Job name
job=dirac_full_c2a_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_C2A_GLOBAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &state_vars [ua,va,air_temperature,delp,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  datapath: ${ensemble_dir}/c${cdef}/${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filename_core: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.fv_core.1.res.nc
  filename_trcr: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.fv_tracer.1.res.nc
  filename_sfcd: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.sfc_data.1.nc
  filename_sfcw: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cdef}.fv_srf_wnd.1.res.nc
  filename_cplr: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.PT3H.coupler.res.1
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_global: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
    - parameter: nicas_norm
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: nicas_norm.fv_core.res.nc
        filename_trcr: nicas_norm.fv_tracer.res.nc
        filename_cplr: nicas_norm.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_global: true
      vbal_block: [true, true,false, true,false,false]
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *state_vars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_full_c2a_global_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_FULL_C2A_GLOBAL sbatch
ntasks=${ntasks_def}
cpus_per_task=2
threads=1
time=01:00:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_FULL_REGRID_LOCAL ##########################################
####################################################################

# Job name
job=dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_REGRID_LOCAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &state_vars [ua,va,air_temperature,delp,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  datapath: ${ensemble_dir}/c${cregrid}/${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filename_core: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cregrid}.fv_core.1.res.nc
  filename_trcr: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cregrid}.fv_tracer.1.res.nc
  filename_sfcd: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cregrid}.sfc_data.1.nc
  filename_sfcw: gfs.oper.fc_ens.PT3H.${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.c${cregrid}.fv_srf_wnd.1.res.nc
  filename_cplr: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z.PT3H.coupler.res.1
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_regrid}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_regrid}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *state_vars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_regrid}/${bump_dir}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid}]
  iydir: [${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid}]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_FULL_REGRID_LOCAL sbatch
ntasks=${ntasks_regrid}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
