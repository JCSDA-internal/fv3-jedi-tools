#!/bin/bash

# Source functions
source ./functions.sh

for yyyymmddhh in ${yyyymmddhh_list}; do
   # Date
   yyyy=${yyyymmddhh:0:4}
   mm=${yyyymmddhh:4:2}
   dd=${yyyymmddhh:6:2}
   hh=${yyyymmddhh:8:2}

   ####################################################################
   # VBAL #############################################################
   ####################################################################

   # Job name
   job=vbal_${yyyymmddhh}

   # Create directories
   mkdir -p ${data_dir_c384}/${bump_dir}/${job}
   mkdir -p ${work_dir}/${job}

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
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem001
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps]
bump:
  datadir: ${data_dir_c384}/${bump_dir}
  prefix: vbal_${yyyymmddhh}/vbal_${yyyymmddhh}
  verbosity: main
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
  vbal_diag_reg: [true, false,false, false,false,false]
  vbal_pseudo_inv: true
  vbal_pseudo_inv_var_th: 0.1
  ensemble:
    members from template:
      template:
        datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
        filetype: fms restart
        state variables: *stateVars
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem%mem%
        filename_core: bvars.fv_core.res.nc
        filename_trcr: bvars.fv_tracer.res.nc
        filename_cplr: bvars.coupler.res
        date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
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

   # Create directories
   mkdir -p ${data_dir_c384}/${bump_dir}/${yyyymmddhh}
      for imem in $(seq 1 1 ${nmem}); do
      imemp=$(printf "%.3d" "${imem}")
      mkdir -p ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem${imemp}
   done
   mkdir -p ${work_dir}/${job}

   # Unbal yaml
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
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem001
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: *stateVars
bump:
  datadir: ${data_dir_c384}/${bump_dir}
  prefix: unbal_${yyyymmddhh}/unbal_${yyyymmddhh}
  verbosity: main
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
      state variables: *stateVars
      psinfile: true
      datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem${imemp}
      filename_core: bvars.fv_core.res.nc
      filename_trcr: bvars.fv_tracer.res.nc
      filename_cplr: bvars.coupler.res
    bump operators: [inverseMultiplyVbal]
    output:
      filetype: fms restart
      datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem${imemp}
      prepend files with date: false
      filename_core: unbal.fv_core.res.nc
      filename_trcr: unbal.fv_tracer.res.nc
      filename_cplr: unbal.coupler.res
    date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
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

      # Create directories
      mkdir -p ${data_dir_c384}/${bump_dir}/${job}
      mkdir -p ${work_dir}/${job}

      # VAR-MOM yaml
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
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: var-mom_${yyyymmddhh}_${var}/var-mom_${yyyymmddhh}_${var}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
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
        state variables: *stateVars
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem%mem%
        filename_core: unbal.fv_core.res.nc
        filename_trcr: unbal.fv_tracer.res.nc
        filename_cplr: unbal.coupler.res
        date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
      pattern: %mem%
      nmembers: ${nmem}
      zero padding: 3
  output:
  - parameter: var
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    prepend files with date: false
    filename_core: var.fv_core.res.nc
    filename_trcr: var.fv_tracer.res.nc
    filename_cplr: var.coupler.res
    date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  - parameter: m4
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    prepend files with date: false
    filename_core: m4.fv_core.res.nc
    filename_trcr: m4.fv_tracer.res.nc
    filename_cplr: m4.coupler.res
    date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  - parameter: cor_rh
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    prepend files with date: false
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
    date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  - parameter: cor_rv
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}_${var}
    prepend files with date: false
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
    date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
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
