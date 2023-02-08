#!/bin/bash

# Source functions
source ./functions.sh

# Create data directories
for yyyymmddhh in ${yyyymmddhh_list}; do
   mkdir -p ${data_dir_def}/${bump_dir}/vbal_${yyyymmddhh}
   mkdir -p ${data_dir_def}/${bump_dir}/${yyyymmddhh}
   for imem in $(seq 1 1 ${nmem}); do
      imemp=$(printf "%.3d" "${imem}")
      mkdir -p ${data_dir_def}/${bump_dir}/${yyyymmddhh}/mem${imemp}
   done
   for var in ${vars}; do
      mkdir -p ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
   done
done

echo ${yyyymmddhh_list}

for yyyymmddhh in ${yyyymmddhh_list}; do

   yyyy=${yyyymmddhh:0:4}
   mm=${yyyymmddhh:4:2}
   dd=${yyyymmddhh:6:2}
   hh=${yyyymmddhh:8:2}

   # Date
   yyyymmddhh_o=$(date +%Y%m%d%H -d "$yyyy$mm$dd $hh - $offset hour")

   yyyy_o=${yyyymmddhh_o:0:4}
   mm_o=${yyyymmddhh_o:4:2}
   dd_o=${yyyymmddhh_o:6:2}
   hh_o=${yyyymmddhh_o:8:2}   

   ####################################################################
   # VAR-MOM ##########################################################
   ####################################################################

   for var in ${vars}; do
      # Job name
      job=var-mom_${yyyymmddhh}_${var}

      # VAR-MOM yaml
echo ${yaml_dir}/${job}.yaml
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
  datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  filetype: cube sphere history
  state variables: &stateVars [${varlist}]
  #psinfile: true
  datapath: ${data_input_dir}/ens01/holding/geoscf_jedi
  filename: codas_c90_nudge.geoscf_jedi.${yyyy}${mm}${dd}_${hh}00z.nc4 
input variables: [${var}]

bump:
  general:
    universe length-scale: 5000.0e3
  io:
    data directory: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    files prefix: var-mom_${yyyy}${mm}${dd}${hh}_${var}
  drivers:
    multivariate strategy: univariate
    write local sampling: true
    compute variance: true
    iterative algorithm: true
    compute moments: true
    write moments: true
  sampling:
    computation grid size: 1000
    distance classes: 10
    distance class width: 500.0e3
    reduced levels: 15
    grid type: octahedral
  ensemble:
    members from template:
      template:
        #datetime: 2021-08-01T00:00:00Z
        datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
        filetype: cube sphere history
        datapath: ${data_input_dir}/ens%mem%/holding/geoscf_jedi
        filename: codas_c90_nudge.geoscf_jedi.${yyyy}${mm}${dd}_${hh}00z.nc4
      pattern: '%mem%'
      nmembers: 5
      zero padding: 2

output:
- parameter: var
  file:
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    filename: var.nc 

- parameter: m4
  file:
    filetype: cube sphere history
    datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    filename: m4.nc

EOF

      # VAR-MOM sbatch
      ntasks=${ntasks_def}
      cpus_per_task=1
      threads=1
      time=01:00:00
      exe=fv3jedi_error_covariance_training.x
      prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
   done
done
