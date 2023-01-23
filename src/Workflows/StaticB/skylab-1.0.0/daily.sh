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
   # VBAL #############################################################
   ####################################################################

   # Job name
   job=vbal_${yyyymmddhh}

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
  datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh}/mem001
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps]
bump:
  datadir: ${data_dir_def}/${bump_dir}
  prefix: vbal_${yyyymmddhh}/vbal_${yyyymmddhh}
  universe_rad: 2000.0e3
  update_vbal_cov: true
  write_vbal_cov: true
  new_vbal: true
  write_vbal: true
  write_samp_local: true
  nc1: 5000
  nc2: 3500
  vbal_block: [true, true,false, true,false,false]
  vbal_rad: 2000.0e3
  vbal_diag_auto: [true, true,false, true,false,false]
  vbal_diag_reg: [true, true,false, true,false,false]
  ensemble:
    members from template:
      template:
        datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
        filetype: fms restart
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh}/mem%mem%
        filename_core: bvars.fv_core.res.nc
        filename_trcr: bvars.fv_tracer.res.nc
        filename_cplr: bvars.coupler.res
      pattern: %mem%
      nmembers: ${nmem}
      zero padding: 3
EOF

   # VBAL sbatch
   ntasks=${ntasks_def}
   cpus_per_task=1
   threads=1
   time=00:30:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

   ####################################################################
   # Unbal ############################################################
   ####################################################################

   # Job name
   job=unbal_${yyyymmddhh}

   # Unbal yaml
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
  datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh}/mem001
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: *stateVars
bump:
  datadir: ${data_dir_def}/${bump_dir}
  prefix: unbal_${yyyymmddhh}/unbal_${yyyymmddhh}
  universe_rad: 2000.0e3
  load_vbal: true
  fname_samp: vbal_${yyyymmddhh}/vbal_${yyyymmddhh}_sampling
  fname_vbal: vbal_${yyyymmddhh}/vbal_${yyyymmddhh}_vbal
  load_samp_local: true
  vbal_block: [true, true,false, true,false,false]
  operators application:
EOF
   for imem in $(seq 1 1 ${nmem}); do
      imemp=$(printf "%.3d" "${imem}")
cat<< EOF >> ${yaml_dir}/${job}.yaml
  - input:
      datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
      filetype: fms restart
      psinfile: true
      datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh}/mem${imemp}
      filename_core: bvars.fv_core.res.nc
      filename_trcr: bvars.fv_tracer.res.nc
      filename_cplr: bvars.coupler.res
    bump operators: [inverseMultiplyVbal]
    output:
      filetype: fms restart
      datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh}/mem${imemp}
      prepend files with date: false
      filename_core: unbal.fv_core.res.nc
      filename_trcr: unbal.fv_tracer.res.nc
      filename_cplr: unbal.coupler.res
EOF
   done

   # Unbal sbatch
   ntasks=${ntasks_def}
   cpus_per_task=1
   threads=1
   time=01:00:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

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
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-aerosol.yaml
background:
  datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  filetype: fms restart
  state variables: &stateVars [${varlist}]
  psinfile: true
  datapath: ${data_input_dir}/enkfgdas.${yyyy_o}${mm_o}${dd_o}/${hh_o}/mem001/RESTART
  filename_core: ${yyyy}${mm}${dd}.${hh}0000.fv_core.res.ges.nc
  filename_trcr: ${yyyy}${mm}${dd}.${hh}0000.fv_tracer.res.ges.nc
  filename_cplr: ${yyyy}${mm}${dd}.${hh}0000.coupler.res.ges
input variables: [${var}]
bump:
  prefix: var-mom_${yyyymmddhh}_${var}/var-mom_${yyyymmddhh}_${var}
  datadir: ${data_dir_def}/${bump_dir}
  universe_rad: 4000.0e3
  method: cor
  strategy: specific_univariate
  update_var: true
  update_mom: true
  write_mom: true
  new_hdiag: true
  write_hdiag: true
  write_samp_local: true
  nc1: 5000
  nc2: 1000
  nc3: 50
  dc: 75.0e3
  nl0r: 15
  local_diag: true
  local_rad: 2000.0e3
  diag_rvflt: 0.1
  ensemble:
    members from template:
      template:
        datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
        filetype: fms restart
        psinfile: true
        datapath: ${data_input_dir}/enkfgdas.${yyyy_o}${mm_o}${dd_o}/${hh_o}/mem%mem%/RESTART
        filename_core: ${yyyy}${mm}${dd}.${hh}0000.fv_core.res.ges.nc
        filename_trcr: ${yyyy}${mm}${dd}.${hh}0000.fv_tracer.res.ges.nc
        filename_cplr: ${yyyy}${mm}${dd}.${hh}0000.coupler.res.ges
      pattern: %mem%
      nmembers: ${nmem}
      zero padding: 3
output:
  - parameter: var
    file:
      filetype: fms restart
      datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
      prepend files with date: false
      filename_core: var.fv_core.res.nc
      filename_trcr: var.fv_tracer.res.nc
      filename_cplr: var.coupler.res
  - parameter: m4
    file:
      filetype: fms restart
      datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
      prepend files with date: false
      filename_core: m4.fv_core.res.nc
      filename_trcr: m4.fv_tracer.res.nc
      filename_cplr: m4.coupler.res
  - parameter: cor_rh
    file:
      filetype: fms restart
      datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
      prepend files with date: false
      filename_core: cor_rh.fv_core.res.nc
      filename_trcr: cor_rh.fv_tracer.res.nc
      filename_cplr: cor_rh.coupler.res
  - parameter: cor_rv
    file:
      filetype: fms restart
      datapath: ${data_dir_def}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
      prepend files with date: false
      filename_core: cor_rv.fv_core.res.nc
      filename_trcr: cor_rv.fv_tracer.res.nc
      filename_cplr: cor_rv.coupler.res
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
