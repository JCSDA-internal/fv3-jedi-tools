#!/bin/bash

# Source functions
source ${script_dir}/functions.sh

# Create data directories
mkdir -p ${data_dir_def}/dirac_${suffix}
mkdir -p ${data_dir_regrid}/dirac_regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_${suffix}

####################################################################
# DIRAC ############################################################
####################################################################

# Job name
job=dirac_${suffix}

# DIRAC yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  logp: true
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    read:
      io:
        data directory: ${data_dir_def}
        files prefix: nicas_${suffix}/nicas_${suffix}
        overriding universe radius file: cor_${suffix}/cor_${suffix}_universe_radius
        overriding nicas file: nicas_${suffix}/nicas_${suffix}_nicas
      drivers:
        multivariate strategy: univariate
        read universe radius: true
        read local nicas: true
      grids:
      - model:
          variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      - model:
          variables: [surface_pressure]
  saber outer blocks:  
  - saber block name: StdDev
    input model files:
    - parameter: StdDev
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/var_${suffix}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    read:
      general:
        universe length-scale: 2000.0e3
      io:
        data directory: ${data_dir_def}
        files prefix: vbal_${suffix}/vbal_${suffix}
        overriding sampling file: vbal_${yyyymmddhh_last}${rr}/vbal_${yyyymmddhh_last}${rr}_sampling
      drivers:
        read local sampling: true
        read vertical balance: true
      vertical balance:
        vbal:
        - balanced variable: velocity_potential
          unbalanced variable: stream_function
        - balanced variable: air_temperature
          unbalanced variable: stream_function
        - balanced variable: surface_pressure
          unbalanced variable: stream_function
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *stateVars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/dirac_${suffix}
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

# DIRAC sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_REGRID #####################################################
####################################################################

# Job name
job=dirac_c${cregrid}_${nlx_regrid}x${nly_regrid}_${suffix}

# DIRAC_REGRID yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  logp: true
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_regrid}/${yyyymmddhh_last}${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    read:
      io:
        data directory: ${data_dir_regrid}
        files prefix: nicas_${suffix}/nicas_${suffix}
        overriding universe radius file: cor_${suffix}/cor_${suffix}_universe_radius
        overriding nicas file: nicas_${suffix}/nicas_${suffix}_nicas
      drivers:
        multivariate strategy: univariate
        read universe radius: true
        read local nicas: true
      grids:
      - model:
          variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      - model:
          variables: [surface_pressure]
  saber outer blocks:
  - saber block name: StdDev
    input model files:
    - parameter: StdDev
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_regrid}/var_${suffix}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    read:
      general:
        universe length-scale: 2000.0e3
      io:
        data directory: ${data_dir_regrid}
        files prefix: vbal_${suffix}/vbal_${suffix}
        overriding sampling file: vbal_${yyyymmddhh_last}${rr}/vbal_${yyyymmddhh_last}${rr}_sampling
      drivers:
        read local sampling: true
        read vertical balance: true
      vertical balance:
        vbal:
        - balanced variable: velocity_potential
          unbalanced variable: stream_function
        - balanced variable: air_temperature
          unbalanced variable: stream_function
        - balanced variable: surface_pressure
          unbalanced variable: stream_function
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *stateVars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_regrid}/dirac_regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_${suffix}
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

# DIRAC_REGRID sbatch
ntasks=${ntasks_regrid}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
