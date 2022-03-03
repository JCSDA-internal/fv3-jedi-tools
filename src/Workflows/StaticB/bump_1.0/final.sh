#!/bin/bash

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

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}

# PSICHITOUV yaml
yaml_name="psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
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
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
bump:
  datadir: ${data_dir_c384}/${bump_dir}
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
sbatch_name="psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_error_covariance_training.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# VBAL #############################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}

# VBAL yaml
yaml_name="vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
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
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [psi,chi,t,ps]
bump:
  datadir: ${data_dir_c384}/${bump_dir}
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
  echo "  - vbal_${yyyymmddhh}/vbal_${yyyymmddhh}_vbal_cov" >> ${yaml_dir}/${yaml_name}
done
cat<< EOF >> ${yaml_dir}/${yaml_name}
  ens1_nsub: ${yyyymmddhh_size}
  load_samp_local: true
  write_samp_global: true
  vbal_block: [true, true,false, true,false,false]
  vbal_rad: 2000.0e3
  vbal_diag_reg: [true, false,false, false,false,false]
  vbal_pseudo_inv: true
  vbal_pseudo_inv_var_th: 0.1
EOF

# VBAL sbatch
sbatch_name="vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_error_covariance_training.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# VAR ##############################################################
####################################################################

for var in ${vars}; do
   # Create directories
   mkdir -p ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
   mkdir -p ${work_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

   # VAR yaml
   yaml_name="var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
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
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: var_${yyyymmddhh_first}-${yyyymmddhh_last}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
  universe_rad: 3000.0e3
  ens1_nsub: ${yyyymmddhh_size}
  var_filter: true
  var_niter: 1
  var_rhflt:
    ${vars_generic[${var}]}: [3000.0e3]
  ne: $((nmem*yyyymmddhh_size))
  input:
EOF
   for yyyymmddhh in ${yyyymmddhh_list}; do
      yyyy=${yyyymmddhh:0:4}
      mm=${yyyymmddhh:4:2}
      dd=${yyyymmddhh:6:2}
      hh=${yyyymmddhh:8:2}
cat<< EOF >> ${yaml_dir}/${yaml_name}
  - parameter: var
    datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}
    psinfile: true
    filename_core: var_${var}.fv_core.res.nc
    filename_trcr: var_${var}.fv_tracer.res.nc
    filename_cplr: var_${var}.coupler.res
    date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
  - parameter: m4
    datetime: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}
    psinfile: true
    filename_core: m4_${var}.fv_core.res.nc
    filename_trcr: m4_${var}.fv_tracer.res.nc
    filename_cplr: m4_${var}.coupler.res
    date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
EOF
   done
cat<< EOF >> ${yaml_dir}/${yaml_name}
  output:
  - parameter: stddev
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
    prepend files with date: false
    filename_core: stddev_${var}.fv_core.res.nc
    filename_trcr: stddev_${var}.fv_tracer.res.nc
    filename_cplr: stddev_${var}.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

   # VAR sbatch
   sbatch_name="var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
   ntasks=${ntasks_def}
   cpus_per_task=1
   threads=1
   ppn=$((cores_per_node/cpus_per_task))
   nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.err
#SBATCH -o ${work_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.out

cd ${work_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_error_covariance_training.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF
done

####################################################################
# COR ##############################################################
####################################################################

for var in ${vars}; do
   # Create directories
   mkdir -p ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
   mkdir -p ${work_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

   # COR yaml
   yaml_name="cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
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
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
  method: cor
  strategy: specific_univariate
  universe_rad: 4000.0e3
  load_mom: true
  new_hdiag: true
  write_diag: true
  fname_mom:
EOF
   for yyyymmddhh in ${yyyymmddhh_list}; do
      echo "    - var-mom_${yyyymmddhh}/var-mom_${yyyymmddhh}_${var}_mom" >> ${yaml_dir}/${yaml_name}
   done
cat<< EOF >> ${yaml_dir}/${yaml_name}
  fname_samp: var-mom_${yyyymmddhh_last}/var-mom_${yyyymmddhh_last}_${var}_sampling
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
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    prepend files with date: false
    filename_core: cor_rh_${var}.fv_core.res.nc
    filename_trcr: cor_rh_${var}.fv_tracer.res.nc
    filename_cplr: cor_rh_${var}.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - parameter: cor_rv
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    prepend files with date: false
    filename_core: cor_rv_${var}.fv_core.res.nc
    filename_trcr: cor_rv_${var}.fv_tracer.res.nc
    filename_cplr: cor_rv_${var}.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

   # COR sbatch
   sbatch_name="cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
   ntasks=${ntasks_def}
   cpus_per_task=2
   threads=2
   ppn=$((cores_per_node/cpus_per_task))
   nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.err
#SBATCH -o ${work_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.out

cd ${work_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_error_covariance_training.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF
done

####################################################################
# NICAS ############################################################
####################################################################

for var in ${vars}; do
   # Create directories
   mkdir -p ${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
   mkdir -p ${work_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

   # NICAS yaml
   yaml_name="nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
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
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  new_nicas: true
  write_nicas_local: true
  write_nicas_global: true
  resol: 10.0
  nc1max: 50000
  min_lev:
    liq_wat: 76
  universe radius:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rh_${var}.fv_core.res.nc
    filename_trcr: cor_rh_${var}.fv_tracer.res.nc
    filename_cplr: cor_rh_${var}.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  input:
  - parameter: rh
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rh_${var}.fv_core.res.nc
    filename_trcr: cor_rh_${var}.fv_tracer.res.nc
    filename_cplr: cor_rh_${var}.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - parameter: rv
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rv_${var}.fv_core.res.nc
    filename_trcr: cor_rv_${var}.fv_tracer.res.nc
    filename_cplr: cor_rv_${var}.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

   # NICAS sbatch
   sbatch_name="nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
   ntasks=${ntasks_def}
   cpus_per_task=2
   threads=2
   ppn=$((cores_per_node/cpus_per_task))
   nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=02:00:00
#SBATCH -e ${work_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.err
#SBATCH -o ${work_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.out

cd ${work_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_error_covariance_training.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

done
