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
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/geos_cf.yaml

background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: cube sphere history
  state variables: &stateVars [${varlist}]
  datapath: ${data_input_dir}/ens01/holding/geoscf_jedi
  filename: codas_c90_nudge.geoscf_jedi.${yyyy_last}${mm_last}${dd_last}_${hh_last}00z.nc4 

input variables: [${var}]

bump:
  general:
    universe length-scale: 5000.0e3
  io:
    data directory: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh_first}_${var}
    files prefix: var-mom_${yyyymmddhh_first}_${var}

  drivers:
    multivariate strategy: univariate
    read local sampling: true
    read moments: true
  ensemble sizes:
    sub-ensembles: 1
  diagnostics:
    target ensemble size: 5
  variance:
    objective filtering: true
    filtering iterations: 1
    initial length-scale:
    - variables:
      - ${var} 
      value: 5000.0e3  

  grids:
  - model:
      variables:
      - ${var}

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
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    filename: var.nc
- parameter: m4
  component: ${comp}
  file:
    set datetime on read: true
    datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    filename: m4.nc
EOF
   done
cat<< EOF >> ${yaml_dir}/${job}.yaml
output:
- parameter: stddev
  file:
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename: stddev.nc
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
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/geos_cf.yaml

background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: cube sphere history
  state variables: &stateVars [${varlist}]
  datapath: ${data_input_dir}/ens01/holding/geoscf_jedi
  filename: codas_c90_nudge.geoscf_jedi.${yyyy_last}${mm_last}${dd_last}_${hh_last}00z.nc4 

input variables: [${var}]

bump:

  general:
    universe length-scale: 5000.0e3

  io:
    data directory: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh_first}_${var}
    files prefix: var-mom_${yyyymmddhh_first}_${var}

    #overriding sampling file: var-mom_2021080100_volume_mixing_ratio_of_no2_sampling
    #overriding moments file:
    #- var-mom_2021080100_volume_mixing_ratio_of_no2_mom_000001_1

  drivers:
    compute covariance: true
    compute correlation: true
    multivariate strategy: univariate
    read local sampling: true
    read moments: true
    write diagnostics: true

  ensemble sizes:
    total ensemble size: 5
    sub-ensembles: 1
  sampling:
    distance classes: 10
    distance class width: 500.0e3
    reduced levels: 15
  diagnostics:
    target ensemble size: 5

#  fit:
#    vertical filtering length-scale: 0.1
#    number of components: 2

#  grids:
#  - model:
#      variables:
#      -${var} 
#    io:
#      files prefix:  cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#      overriding sampling file: var-mom_3D_2020121421_gfs_sampling
#      overriding moments file:
#      - var-mom_3D_2020121421_gfs_mom_000001_1
#      - var-mom_3D_2020121500_gfs_mom_000001_1
#      - var-mom_3D_2020121503_gfs_mom_000001_1

#  - model:
#      variables:
#      - surface_pressure
#    io:
#      files prefix: cor_2D_gfs
#      overriding sampling file: var-mom_2D_2020121421_gfs_sampling
#      overriding moments file:
#      - var-mom_2D_2020121421_gfs_mom_000001_1
#      - var-mom_2D_2020121500_gfs_mom_000001_1
#      - var-mom_2D_2020121503_gfs_mom_000001_1

output:
- parameter: cor_rh
  file:
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename: cor_rh.nc

- parameter: cor_rv
  file:   
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename: cor_rv.nc
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
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/geos_cf.yaml
background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: cube sphere history
  state variables: &stateVars [${varlist}]
  datapath: ${data_input_dir}/ens01/holding/geoscf_jedi
  filename: codas_c90_nudge.geoscf_jedi.${yyyy_last}${mm_last}${dd_last}_${hh_last}00z.nc4 
input variables: [${var}]

bump:
  io:
    data directory: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    files prefix: nicas
  drivers:
    multivariate strategy: univariate
    compute nicas: true
    write local nicas: true
  nicas:
    resolution: 6
    explicit length-scales: true
    horizontal length-scale:
    - groups:
      - ${var}
      value: 2500000.0
    vertical length-scale:
    - groups:
      - ${var}
      value: 0.3

input fields:
- parameter: universe radius
  file:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename: cor_rh.nc

- parameter: rh
  file:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename: cor_rh.nc

- parameter: rv
  file:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename: cor_rv.nc

output:
- parameter: nicas_norm
  file:
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename: nicas_norm.nc
EOF

   # NICAS sbatch
   qos=long
   ntasks=${ntasks_def}
   cpus_per_task=2
   threads=2
   time=3:00:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe} ${qos}
done
