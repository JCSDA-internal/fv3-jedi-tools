#!/bin/bash

# Source functions
source ${script_dir}/functions.sh

# Create data directories
for yyyymmddhh in ${yyyymmddhh_list}; do
   mkdir -p ${data_dir_def}/vbal_${yyyymmddhh}${rr}
   mkdir -p ${data_dir_def}/${yyyymmddhh}${rr}
   for imem in $(seq 1 1 ${nmem}); do
      imemp=$(printf "%.3d" "${imem}")
      mkdir -p ${data_dir_def}/${yyyymmddhh}${rr}/mem${imemp}
   done
   for var in ${vars}; do
      mkdir -p ${data_dir_def}/var-mom_${yyyymmddhh}${rr}_${var}
   done
done

for yyyymmddhh in ${yyyymmddhh_list}; do
   # Date
   yyyy=${yyyymmddhh:0:4}
   mm=${yyyymmddhh:4:2}
   dd=${yyyymmddhh:6:2}
   hh=${yyyymmddhh:8:2}

   # Forecast date
   yyyymmddhh_fc=`date -d "${yyyy}${mm}${dd} +${hh} hours ${rr_fc} hours" '+%Y%m%d%H'`
   yyyy_fc=${yyyymmddhh_fc:0:4}
   mm_fc=${yyyymmddhh_fc:4:2}
   dd_fc=${yyyymmddhh_fc:6:2}
   hh_fc=${yyyymmddhh_fc:8:2}

   ####################################################################
   # STATE_TO_CONTROL #################################################
   ####################################################################

   # Job name
   job=state_to_control_${yyyymmddhh}${rr}

   # STATE_TO_CONTROL yaml
   cat<< EOF > ${yaml_dir}/${job}.yaml
input geometry:
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
output geometry:
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
variable change:
  variable change name: Control2Analysis
  output variables: [eastward_wind,northward_wind,stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  do inverse: true
  femps_iterations: 20
  femps_ngrids: 2
  femps_path2fv3gridfiles: ${femps_dir}/test/Data/
  femps_checkconvergence: false
states:
EOF
   for imem in $(seq 1 1 ${nmem}); do
      imemp=$(printf "%.3d" "${imem}")
      cat<< EOF >> ${yaml_dir}/${job}.yaml
- input:
    datetime: ${yyyy_fc}-${mm_fc}-${dd_fc}T${hh_fc}:00:00Z
    filetype: fms restart
    state variables: [ua,va,air_temperature,delp,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    datapath: ${ensemble_dir}/c${cdef}/${yyyy}-${mm}-${dd}T${hh}:00:00Z
    filename_core: gfs.oper.fc_ens.PT${r}H.${yyyy}-${mm}-${dd}T${hh}:00:00Z.c${cdef}.fv_core.${imem}.res.nc
    filename_trcr: gfs.oper.fc_ens.PT${r}H.${yyyy}-${mm}-${dd}T${hh}:00:00Z.c${cdef}.fv_tracer.${imem}.res.nc
    filename_sfcd: gfs.oper.fc_ens.PT${r}H.${yyyy}-${mm}-${dd}T${hh}:00:00Z.c${cdef}.sfc_data.${imem}.nc
    filename_sfcw: gfs.oper.fc_ens.PT${r}H.${yyyy}-${mm}-${dd}T${hh}:00:00Z.c${cdef}.fv_srf_wnd.${imem}.res.nc
    filename_cplr: ${yyyy}-${mm}-${dd}T${hh}:00:00Z.PT${r}H.coupler.res.${imem}
  output:
    filetype: fms restart
    datapath: ${data_dir_def}/${yyyymmddhh}${rr}/mem${imemp}
    prepend files with date: false
    filename_core: balanced.fv_core.res.nc
    filename_trcr: balanced.fv_tracer.res.nc
    filename_sfcd: balanced.sfc_data.res.nc
    filename_sfcw: balanced.fv_srf_wnd.res.nc
    filename_cplr: balanced.coupler.res
EOF
   done

   # STATE_TO_CONTROL sbatch
   ntasks=${ntasks_def}
   cpus_per_task=1
   threads=1
   time=02:00:00
   exe=fv3jedi_convertstate.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

   ####################################################################
   # VBAL #############################################################
   ####################################################################

   # Job name
   job=vbal_${yyyymmddhh}${rr}

   # VBAL yaml
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
background:
  datetime: ${yyyy_fc}-${mm_fc}-${dd_fc}T${hh_fc}:00:00Z
  filetype: fms restart
  state variables: &stateVars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh}${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
input variables: [stream_function,velocity_potential,air_temperature,surface_pressure]
bump:
  general:
    universe length-scale: 2000.0e3
  io:
    data directory: ${data_dir_def}
    files prefix: vbal_${yyyymmddhh}${rr}/vbal_${yyyymmddhh}${rr}
  drivers:
    compute vertical covariance: true
    iterative algorithm: true
    write vertical covariance: true
    compute vertical balance: true
    write vertical balance: true
    write local sampling: true
  sampling:
    computation grid size: 5000
    diagnostic grid size: 3500
    averaging length-scale: 2000.0e3
    interpolation type: 'si'
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
  ensemble:
    members from template:
      template:
        datetime: ${yyyy_fc}-${mm_fc}-${dd_fc}T${hh_fc}:00:00Z
        filetype: fms restart
        psinfile: true
        datapath: ${data_dir_def}/${yyyymmddhh}${rr}/mem%mem%
        filename_core: balanced.fv_core.res.nc
        filename_trcr: balanced.fv_tracer.res.nc
        filename_cplr: balanced.coupler.res
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
   # UNBAL ############################################################
   ####################################################################

   # Job name
   job=unbal_${yyyymmddhh}${rr}

   # UNBAL yaml
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
background:
  datetime: ${yyyy_fc}-${mm_fc}-${dd_fc}T${hh_fc}:00:00Z
  filetype: fms restart
  state variables: &stateVars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh}${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
input variables: *stateVars
bump:
  general:
    universe length-scale: 2000.0e3
  io:
    data directory: ${data_dir_def}
    files prefix: unbal_${yyyymmddhh}${rr}/unbal_${yyyymmddhh}${rr}
    overriding sampling file: vbal_${yyyymmddhh}${rr}/vbal_${yyyymmddhh}${rr}_sampling
    overriding vertical balance file: vbal_${yyyymmddhh}${rr}/vbal_${yyyymmddhh}${rr}_vbal
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
  operators application:
EOF
   for imem in $(seq 1 1 ${nmem}); do
      imemp=$(printf "%.3d" "${imem}")
      cat<< EOF >> ${yaml_dir}/${job}.yaml
  - input:
      datetime: ${yyyy_fc}-${mm_fc}-${dd_fc}T${hh_fc}:00:00Z
      filetype: fms restart
      psinfile: true
      datapath: ${data_dir_def}/${yyyymmddhh}${rr}/mem${imemp}
      filename_core: balanced.fv_core.res.nc
      filename_trcr: balanced.fv_tracer.res.nc
      filename_cplr: balanced.coupler.res
    bump operators: [inverseMultiplyVbal]
    output:
      filetype: fms restart
      datapath: ${data_dir_def}/${yyyymmddhh}${rr}/mem${imemp}
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
      job=var-mom_${yyyymmddhh}${rr}_${var}

      # VAR-MOM yaml
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
background:
  datetime: ${yyyy_fc}-${mm_fc}-${dd_fc}T${hh_fc}:00:00Z
  filetype: fms restart
  state variables: &stateVars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  general:
    universe length-scale: 4000.0e3
  io:
    data directory: ${data_dir_def}
    files prefix: var-mom_${yyyymmddhh}${rr}_${var}/var-mom_${yyyymmddhh}${rr}_${var}
  drivers:
    compute correlation: true
    multivariate strategy: univariate
    compute variance: true
    iterative algorithm: true
    write local sampling: true
    compute moments: true
    write moments: true
    write diagnostics: true
  sampling:
    computation grid size: 5000
    diagnostic grid size: 1000
    distance classes: 50
    distance class width: 75.0e3
    reduced levels: 15
    local diagnostic: true
    averaging length-scale: 2000.0e3
  fit:
    vertical filtering length-scale: 0.1
  ensemble:
    members from template:
      template:
        datetime: ${yyyy_fc}-${mm_fc}-${dd_fc}T${hh_fc}:00:00Z
        filetype: fms restart
        psinfile: true
        datapath: ${data_dir_def}/${yyyymmddhh}${rr}/mem%mem%
        filename_core: unbal.fv_core.res.nc
        filename_trcr: unbal.fv_tracer.res.nc
        filename_cplr: unbal.coupler.res
      pattern: %mem%
      nmembers: ${nmem}
      zero padding: 3
output:
- parameter: var
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/var-mom_${yyyymmddhh}${rr}_${var}
    prepend files with date: false
    filename_core: var.fv_core.res.nc
    filename_trcr: var.fv_tracer.res.nc
    filename_cplr: var.coupler.res
- parameter: m4
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/var-mom_${yyyymmddhh}${rr}_${var}
    prepend files with date: false
    filename_core: m4.fv_core.res.nc
    filename_trcr: m4.fv_tracer.res.nc
    filename_cplr: m4.coupler.res
- parameter: cor_rh
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/var-mom_${yyyymmddhh}${rr}_${var}
    prepend files with date: false
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- parameter: cor_rv
  file:
    filetype: fms restart
    datapath: ${data_dir_def}/var-mom_${yyyymmddhh}${rr}_${var}
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
