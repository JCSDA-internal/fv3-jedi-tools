#!/bin/bash

# Source functions
source ./functions.sh

# Create data directories
mkdir -p ${data_dir_def}/${bump_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_def}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
for var in ${vars}; do
   mkdir -p ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
   mkdir -p ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
   mkdir -p ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
done

# Date Offset
yyyymmddhh_o=$(date +%Y%m%d%H -d "$yyyy_last$mm_last$dd_last $hh_last - $offset hour")

yyyy_o=${yyyymmddhh_o:0:4}
mm_o=${yyyymmddhh_o:4:2}
dd_o=${yyyymmddhh_o:6:2}
hh_o=${yyyymmddhh_o:8:2}

# Generic variable names
declare -A vars_generic
vars_generic+=(["psi"]="stream_function")
vars_generic+=(["chi"]="velocity_potential")
vars_generic+=(["t"]="air_temperature")
vars_generic+=(["sphum"]="specific_humidity")
vars_generic+=(["liq_wat"]="cloud_liquid_water")
vars_generic+=(["o3mr"]="ozone_mass_mixing_ratio")
vars_generic+=(["ps"]="surface_pressure")

####################################################################
# PSICHITOUV #######################################################
####################################################################

# Job name
job=psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}

# PSICHITOUV yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
bump:
  datadir: ${data_dir_def}/${bump_dir}
  prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
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
job=vbal_${yyyymmddhh_first}-${yyyymmddhh_last}

# VBAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [psi,chi,t,ps]
bump:
  datadir: ${data_dir_def}/${bump_dir}
  prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal_cov: true
  new_vbal: true
  write_vbal: true
  fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
  fname_vbal_cov:
EOF
for yyyymmddhh in ${yyyymmddhh_list}; do
  echo "  - vbal_${yyyymmddhh}/vbal_${yyyymmddhh}_vbal_cov" >> ${yaml_dir}/${job}.yaml
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
   job=var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

   # VAR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-aerosol.yaml
background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [${varlist}]
  psinfile: true
  datapath: ${data_input_dir}/enkfgdas.${yyyy_o}${mm_o}${dd_o}/${hh_o}/mem001/RESTART
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.ges.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.ges.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res.ges
input variables: [${var}]
bump:
  prefix: var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_def}/${bump_dir}
  verbosity: main
  universe_rad: 3000.0e3
  ens1_nsub: ${yyyymmddhh_size}
  var_filter: true
  var_niter: 1
  var_rhflt:
    ${var}: [3000.0e3]
  ne: $((nmem*yyyymmddhh_size))
input fields:
EOF
   comp=0
   for yyyymmddhh in ${yyyymmddhh_list}; do
      let "comp+=1"
      yyyy=${yyyymmddhh:0:4}
      mm=${yyyymmddhh:4:2}
      dd=${yyyymmddhh:6:2}
      hh=${yyyymmddhh:8:2}
cat<< EOF >> ${yaml_dir}/${job}.yaml
- parameter: var
  component: ${comp}
  file:
    set datetime on read: true
    datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    psinfile: true
    filename_core: var.fv_core.res.nc
    filename_trcr: var.fv_tracer.res.nc
    filename_cplr: var.coupler.res
- parameter: m4
  component: ${comp}
  file:
    set datetime on read: true
    datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
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
    datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
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
   job=cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

   # COR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-aerosol.yaml
background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [${varlist}]
  psinfile: true
  datapath: ${data_input_dir}/enkfgdas.${yyyy_o}${mm_o}${dd_o}/${hh_o}/mem001/RESTART
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.ges.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.ges.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res.ges
input variables: [${var}]
bump:
  prefix: cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
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
      echo "    - var-mom_${yyyymmddhh}_${var}/var-mom_${yyyymmddhh}_${var}_mom" >> ${yaml_dir}/${job}.yaml
   done
cat<< EOF >> ${yaml_dir}/${job}.yaml
  fname_samp: var-mom_${yyyymmddhh_last}_${var}/var-mom_${yyyymmddhh_last}_${var}_sampling
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
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    prepend files with date: false
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: cor_rv
  file:   
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
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
   job=nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

   # NICAS yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-aerosol.yaml
background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [${varlist}]
  psinfile: true
  datapath: ${data_input_dir}/enkfgdas.${yyyy_o}${mm_o}${dd_o}/${hh_o}/mem001/RESTART
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.ges.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.ges.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res.ges
input variables: [${var}]
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_def}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  new_nicas: true
  write_nicas_local: true
  write_nicas_global: true
  resol: 4.0
  nc1max: 5000
  universe_rad: 3000.0e3
  forced_radii: true
  rh:
    ${var}: [3000000.0]
  rv:
    ${var}: [0.2]
input fields:
#- parameter: universe radius
#  file:
#    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
#    filetype: fms restart
#    psinfile: true
#    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#    filename_core: cor_rh.fv_core.res.nc
#    filename_trcr: cor_rh.fv_tracer.res.nc
#    filename_cplr: cor_rh.coupler.res
- parameter: rh
  file:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: rv
  file:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
output:
- parameter: nicas_norm
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    prepend files with date: false
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
EOF

   # NICAS sbatch
   ntasks=${ntasks_def}
   cpus_per_task=2
   threads=2
   time=06:00:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
done
