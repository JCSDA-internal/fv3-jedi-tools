#!/bin/bash

# Source functions
source ./functions.sh

# Create data directories
mkdir -p ${data_dir_def}/${bump_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_def}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
for var in ${vars}; do
   mkdir -p ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
   mkdir -p ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
   mkdir -p ${data_dir_def}/${bump_dir}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
   mkdir -p ${data_dir_def}/${bump_dir}/nicas_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
   mkdir -p ${data_dir_def}/${bump_dir}/nicas_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
done

####################################################################
# PSICHITOUV #######################################################
####################################################################

# Job name
job=psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# PSICHITOUV yaml
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
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
bump:
  datadir: ${data_dir_def}/${bump_dir}
  prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
  verbosity: main
  universe_rad: 2000.0e3
  new_wind: true
  write_wind_local: true
  wind_nlon: 400
  wind_nlat: 200
  wind_nsg: 5
  wind_inflation: 1.1
EOF

# PSICHITOUV sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:20:00
exe=fv3jedi_error_covariance_training.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# VBAL #############################################################
####################################################################

# Job name
job=vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

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
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [stream_function,velocity_potential,air_temperature,surface_pressure]
bump:
  datadir: ${data_dir_def}/${bump_dir}
  prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal_cov: true
  new_vbal: true
  write_vbal: true
  fname_samp: vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling
  fname_vbal_cov:
EOF
for yyyymmddhh in ${yyyymmddhh_list}; do
  echo "  - vbal_${yyyymmddhh}+${rr}/vbal_${yyyymmddhh}+${rr}_vbal_cov" >> ${yaml_dir}/${job}.yaml
done
cat<< EOF >> ${yaml_dir}/${job}.yaml
  ens1_nsub: ${yyyymmddhh_size}
  load_samp_local: true
  write_samp_global: true
  vbal_block: [true, true,false, true,false,false]
  vbal_rad: 2000.0e3
  vbal_diag_auto: [true, true,false, true,false,false]
  vbal_diag_reg: [true, true,false, true,false,false]
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
   job=var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}

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
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
  datadir: ${data_dir_def}/${bump_dir}
  verbosity: main
  universe_rad: 3000.0e3
  ens1_nsub: ${yyyymmddhh_size}
  var_filter: true
  var_niter: 1
  var_rhflt:
    stream_function: [3000.0e3]
    velocity_potential: [3000.0e3]
    air_temperature: [3000.0e3]
    surface_pressure: [3000.0e3]
    specific_humidity: [3000.0e3]
    cloud_liquid_water: [3000.0e3]
    ozone_mass_mixing_ratio: [3000.0e3]
  ne: $((nmem*yyyymmddhh_size))
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
    datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}+${rr}_${var}
    psinfile: true
    filename_core: var.fv_core.res.nc
    filename_trcr: var.fv_tracer.res.nc
    filename_cplr: var.coupler.res
- parameter: m4
  file:
    datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}+${rr}_${var}
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
    datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
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
   job=cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}

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
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
  datadir: ${data_dir_def}/${bump_dir}
  verbosity: main
  method: cor
  strategy: specific_univariate
  universe_rad: 4000.0e3
  load_mom: true
  new_hdiag: true
  write_hdiag: true
  fname_mom:
EOF
   for yyyymmddhh in ${yyyymmddhh_list}; do
      echo "    - var-mom_${yyyymmddhh}+${rr}_${var}/var-mom_${yyyymmddhh}+${rr}_${var}_mom" >> ${yaml_dir}/${job}.yaml
   done
cat<< EOF >> ${yaml_dir}/${job}.yaml
  fname_samp: var-mom_${yyyymmddhh_last}+${rr}_${var}/var-mom_${yyyymmddhh_last}+${rr}_${var}_sampling
  ens1_ne: $((nmem*yyyymmddhh_size))
  ens1_nsub: ${yyyymmddhh_size}
  load_samp_local: true
  nc1: 5000
  nc2: 1000
  nc3: 50
  dc: 75.0e3
  nl0r: 15
  local_diag: true
  local_rad: 2000.0e3
  diag_rvflt: 0.1
  ne: $((nmem*yyyymmddhh_size))
output:
- parameter: cor_rh
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    prepend files with date: false
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: cor_rv
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
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
# NICAS_C0 #########################################################
####################################################################

for var in ${vars}; do
   # Job name
   job=nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}

   # NICAS_C0 yaml
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
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
  datadir: ${data_dir_def}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  new_nicas: true
  write_nicas_local: true
  write_nicas_global: true
  resol: 10.0
  nc1max: 50000
  nicas_draw_type: octahedral
  min_lev:
    cloud_liquid_water: 76
input fields:
- parameter: universe radius
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: rh
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: rv
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
output:
- parameter: nicas_norm
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    prepend files with date: false
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
EOF

   # NICAS_C0 sbatch
   ntasks=${ntasks_def}
   cpus_per_task=2
   threads=2
   time=03:00:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
done

####################################################################
# NICAS_C1 #########################################################
####################################################################

for var in ${vars}; do
   # Job name
   job=nicas_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}

   # NICAS_C1 yaml
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
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: nicas_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}/nicas_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
  datadir: ${data_dir_def}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  new_nicas: true
  write_nicas_local: true
  write_nicas_global: true
  resol: 10.0
  nc1max: 50000
  nicas_draw_type: octahedral
  min_lev:
    cloud_liquid_water: 76
  nicas_interp_type:
    stream_function: c1
    velocity_potential: c1
    air_temperature: c1
    surface_pressure: c1
input fields:
- parameter: universe radius
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: rh
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: rv
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
output:
- parameter: nicas_norm
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/nicas_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    prepend files with date: false
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
EOF

   # NICAS_C1 sbatch
   ntasks=${ntasks_def}
   cpus_per_task=2
   threads=2
   time=03:00:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
done

####################################################################
# NICAS_SI #########################################################
####################################################################

for var in ${vars}; do
   # Job name
   job=nicas_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}

   # NICAS_SI yaml
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
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: nicas_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}/nicas_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
  datadir: ${data_dir_def}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  new_nicas: true
  write_nicas_local: true
  write_nicas_global: true
  resol: 10.0
  nc1max: 50000
  nicas_draw_type: octahedral
  min_lev:
    cloud_liquid_water: 76
  nicas_interp_type:
    stream_function: si
    velocity_potential: si
    air_temperature: si
    surface_pressure: si
input fields:
- parameter: universe radius
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: rh
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: rv
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
output:
- parameter: nicas_norm
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/nicas_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    prepend files with date: false
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
EOF

   # NICAS_SI sbatch
   ntasks=${ntasks_def}
   cpus_per_task=2
   threads=2
   time=03:00:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
done
