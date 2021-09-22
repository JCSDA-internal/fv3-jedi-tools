#!/bin/bash

# Generic variable names
declare -A vars_generic
vars_generic+=(["psi"]="stream_function")
vars_generic+=(["chi"]="velocity_potential")
vars_generic+=(["tv"]="virtual_temperature")
vars_generic+=(["rh"]="relative_humidity")
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
  layout: [6,6]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,tv,ps,rh]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  datadir: ${data_dir_c384}/${bump_dir}
  prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  new_wind: 1
  write_wind_local: 1
  wind_nlon: 400
  wind_nlat: 200
  wind_nsg: 5
  wind_inflation: 1.1
EOF

# PSICHITOUV sbatch
sbatch_name="psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.out

export OMP_NUM_THREADS=2
source ${env_script}

cd ${work_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

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
  layout: [6,6]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,tv,ps]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  datadir: ${data_dir_c384}/${bump_dir}
  prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal_cov: 1
  new_vbal: 1
  write_vbal: 1
  fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
  fname_vbal_cov:
EOF
for yyyymmddhh in ${yyyymmddhh_list}; do
  echo "  - vbal_${yyyymmddhh}/vbal_${yyyymmddhh}_vbal_cov" >> ${yaml_dir}/${yaml_name}
done
cat<< EOF >> ${yaml_dir}/${yaml_name}
  ens1_nsub: ${yyyymmddhh_size}
  load_samp_local: 1
  write_samp_global: 1
  vbal_block: [1, 1,0, 1,0,0]
  vbal_rad: 2000.0e3
  vbal_diag_reg: [1, 0,0, 0,0,0]
  vbal_pseudo_inv: 1
  vbal_pseudo_inv_var_th: 0.1
EOF

# VBAL sbatch
sbatch_name="vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

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
  layout: [6,6]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [${var}]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  prefix: var_${yyyymmddhh_first}-${yyyymmddhh_last}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
  universe_rad: 3000.0e3
  ens1_nsub: ${yyyymmddhh_size}
  var_filter: 1
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
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}
  psinfile: 1
  filename_core: ${yyyy}${mm}${dd}.${hh}0000.var_${var}.fv_core.res.nc
  filename_trcr: ${yyyy}${mm}${dd}.${hh}0000.var_${var}.fv_tracer.res.nc
  filename_cplr: ${yyyy}${mm}${dd}.${hh}0000.var_${var}.coupler.res
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
- parameter: m4
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}
  psinfile: 1
  filename_core: ${yyyy}${mm}${dd}.${hh}0000.m4_${var}.fv_core.res.nc
  filename_trcr: ${yyyy}${mm}${dd}.${hh}0000.m4_${var}.fv_tracer.res.nc
  filename_cplr: ${yyyy}${mm}${dd}.${hh}0000.m4_${var}.coupler.res
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
EOF
   done
cat<< EOF >> ${yaml_dir}/${yaml_name}
output:
- parameter: stddev
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: stddev_${var}.fv_core.res.nc
  filename_trcr: stddev_${var}.fv_tracer.res.nc
  filename_cplr: stddev_${var}.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
- parameter: stddev
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: stddev_${var}_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

   # VAR sbatch
   sbatch_name="var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.err
#SBATCH -o ${work_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.out

source ${env_script}

cd ${work_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

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
  layout: [6,6]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [${var}]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  prefix: cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
  method: cor
  strategy: specific_univariate
  universe_rad: 4000.0e3
  load_mom: 1
  new_hdiag: 1
  write_diag: 1
  fname_mom:
EOF
   for yyyymmddhh in ${yyyymmddhh_list}; do
      echo "    - var-mom_${yyyymmddhh}/var-mom_${yyyymmddhh}_${var}_mom" >> ${yaml_dir}/${yaml_name}
   done
cat<< EOF >> ${yaml_dir}/${yaml_name}
  fname_samp: var-mom_${yyyymmddhh_last}/var-mom_${yyyymmddhh_last}_${var}_sampling
  ens1_nsub: ${yyyymmddhh_size}
  load_samp_local: 1
  nc1: 5000
  nc2: 1000
  nc3: 50
  dc: 75.0e3
  nl0r: 15
  local_diag: 1
  local_rad: 2000.0e3
  diag_rvflt: 0.1
  ne: $((nmem*yyyymmddhh_size))
output:
- parameter: cor_rh
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: cor_rh_${var}.fv_core.res.nc
  filename_trcr: cor_rh_${var}.fv_tracer.res.nc
  filename_cplr: cor_rh_${var}.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
- parameter: cor_rv
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: cor_rv_${var}.fv_core.res.nc
  filename_trcr: cor_rv_${var}.fv_tracer.res.nc
  filename_cplr: cor_rv_${var}.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
- parameter: cor_rh
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: cor_rh_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
- parameter: cor_rv
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: cor_rv_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

   # COR sbatch
   sbatch_name="cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=2
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.err
#SBATCH -o ${work_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.out

source ${env_script}

cd ${work_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

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
  layout: [6,6]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [${var}]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  new_nicas: 1
  write_nicas_local: 1
  write_nicas_global: 1
  resol: 10.0
  nc1max: 50000
  min_lev:
    liq_wat: 76
universe radius:
  filetype: gfs
  psinfile: 1
  datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_${var}.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_${var}.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_${var}.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
input:
- parameter: cor_rh
  filetype: gfs
  psinfile: 1
  datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_${var}.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_${var}.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_${var}.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
- parameter: cor_rv
  filetype: gfs
  psinfile: 1
  datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rv_${var}.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rv_${var}.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rv_${var}.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

   # NICAS sbatch
   sbatch_name="nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=2
#SBATCH --time=02:00:00
#SBATCH -e ${work_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.err
#SBATCH -o ${work_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.out

export OMP_NUM_THREADS=2
source ${env_script}

cd ${work_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

done
