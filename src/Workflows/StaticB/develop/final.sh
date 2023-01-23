#!/bin/bash

# Source functions
source ${script_dir}/functions.sh

# Create data directories
mkdir -p ${data_dir_def}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}
for var in ${vars}; do
   mkdir -p ${data_dir_def}/var_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
   mkdir -p ${data_dir_def}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
   mkdir -p ${data_dir_def}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
done

####################################################################
# VBAL #############################################################
####################################################################

# Job name
job=vbal_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}

# VBAL yaml
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
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [stream_function,velocity_potential,air_temperature,surface_pressure]
bump:
  general:
    universe length-scale: 2000.0e3
  io:
    data directory: ${data_dir_def}
    files prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}
    overriding sampling file: vbal_${yyyymmddhh_last}${rr}/vbal_${yyyymmddhh_last}${rr}_sampling
    overriding vertical covariance file:
EOF
for yyyymmddhh in ${yyyymmddhh_list}; do
  echo "    - vbal_${yyyymmddhh}${rr}/vbal_${yyyymmddhh}${rr}_vbal_cov" >> ${yaml_dir}/${job}.yaml
done
cat<< EOF >> ${yaml_dir}/${job}.yaml
  drivers:
    read local sampling: true
    write global sampling: true
    read vertical covariance: true
    compute vertical balance: true
    write vertical balance: true
  ensemble sizes:
    sub-ensembles: ${yyyymmddhh_size}
  sampling:
    averaging length-scale: 2000.0e3 
  vertical balance:
    vbal:
    - balanced variable: velocity_potential
      unbalanced variable: stream_function
      diagonal autocovariance: true
      diagonal regression: true
    - balanced variable: air_temperature
      unbalanced variable: stream_function
      diagonal autocovariance: true
      diagonal regression: true
    - balanced variable: surface_pressure
      unbalanced variable: stream_function
      diagonal autocovariance: true
      diagonal regression: true
EOF

# VBAL sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:30:00
exe=fv3jedi_error_covariance_training.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# VAR ##############################################################
####################################################################

for var in ${vars}; do
   # Job name
   job=var_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}

   # VAR yaml
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
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  general:
    universe length-scale: 3000.0e3
  io:
    data directory: ${data_dir_def}
    files prefix: var_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}/var_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
  ensemble sizes:
    sub-ensembles: ${yyyymmddhh_size}
  variance:
    objective filtering: true
    filtering iterations: 1
    initial length-scale:
    - variables: *stateVars
      value: 3000.0e3
  diagnostics:
    target ensemble size: $((nmem*yyyymmddhh_size))
input fields:
EOF
   for yyyymmddhh in ${yyyymmddhh_list}; do
      yyyy=${yyyymmddhh:0:4}
      mm=${yyyymmddhh:4:2}
      dd=${yyyymmddhh:6:2}
      hh=${yyyymmddhh:8:2}
cat<< EOF >> ${yaml_dir}/${job}.yaml
- parameter: var
  file:
    datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_def}/var-mom_${yyyymmddhh}${rr}_${var}
    psinfile: true
    filename_core: var.fv_core.res.nc
    filename_trcr: var.fv_tracer.res.nc
    filename_cplr: var.coupler.res
- parameter: m4
  file:
    datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_def}/var-mom_${yyyymmddhh}${rr}_${var}
    psinfile: true
    filename_core: m4.fv_core.res.nc
    filename_trcr: m4.fv_tracer.res.nc
    filename_cplr: m4.coupler.res
EOF
   done
cat<< EOF >> ${yaml_dir}/${job}.yaml
output:
- parameter: stddev
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/var_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
    prepend files with date: false
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
EOF

   # VAR sbatch
   ntasks=${ntasks_def}
   cpus_per_task=1
   threads=1
   time=01:00:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
done

####################################################################
# COR ##############################################################
####################################################################

for var in ${vars}; do
   # Job name
   job=cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}

   # COR yaml
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
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  general:
    universe length-scale: 4000.0e3
  io:
    data directory: ${data_dir_def}
    files prefix: cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
    overriding moments file:
EOF
   for yyyymmddhh in ${yyyymmddhh_list}; do
      echo "      - var-mom_${yyyymmddhh}${rr}_${var}/var-mom_${yyyymmddhh}${rr}_${var}_mom_000001_1" >> ${yaml_dir}/${job}.yaml
   done
cat<< EOF >> ${yaml_dir}/${job}.yaml
    overriding sampling file: var-mom_${yyyymmddhh_last}${rr}_${var}/var-mom_${yyyymmddhh_last}${rr}_${var}_sampling
  drivers:
    compute correlation: true
    multivariate strategy: specific_univariate
    read local sampling: true
    read moments: true
    write diagnostics: true
  ensemble sizes:
    total ensemble size: $((nmem*yyyymmddhh_size))
    sub-ensembles: ${yyyymmddhh_size}
  sampling:
    computation grid size: 5000
    diagnostic grid size: 1000
    distance classes: 50
    distance class width: 75.0e3
    reduced levels: 15
    local diagnostic: true
    averaging length-scale: 2000.0e3
  diagnostics:
    target ensemble size: $((nmem*yyyymmddhh_size))
  fit:
    vertical filtering length-scale: 0.1
output:
- parameter: cor_rh
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
    prepend files with date: false
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: cor_rv
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
    prepend files with date: false
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
EOF

   # COR sbatch
   ntasks=${ntasks_def}
   cpus_per_task=2
   threads=2
   time=00:30:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
done

####################################################################
# NICAS ############################################################
####################################################################

for var in ${vars}; do
   # Job name
   job=nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}

   # NICAS yaml
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
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  io:
    data directory: ${data_dir_def}
    files prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
  drivers:
    multivariate strategy: specific_univariate
    compute nicas: true
    write local nicas: true
    write global nicas: true
  nicas:
    resolution: 10.0
    max horizontal grid size: 50000
    grid type: octahedral
    minimum level:
    - variables: [cloud_liquid_water]
      value: 76
    interpolation type:
    - variables: [stream_function,velocity_potential,air_temperature,surface_pressure]
      type: si
input fields:
- parameter: universe radius
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: rh
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: rv
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
output:
- parameter: nicas_norm
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}
    prepend files with date: false
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
EOF

   # NICAS sbatch
   ntasks=${ntasks_def}
   cpus_per_task=2
   threads=2
   time=03:00:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
done
