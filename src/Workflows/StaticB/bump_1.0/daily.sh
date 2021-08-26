#!/bin/bash

for yyyymmddhh in ${yyyymmddhh_list}; do
   # Date
   yyyy=${yyyymmddhh:0:4}
   mm=${yyyymmddhh:4:2}
   dd=${yyyymmddhh:6:2}
   hh=${yyyymmddhh:8:2}

   ####################################################################
   # VBAL #############################################################
   ####################################################################

   # Create specific BUMP and work directories
   mkdir -p ${data_dir_c384}/${bump_dir}/vbal_${yyyymmddhh}
   mkdir -p ${work_dir}/vbal_${yyyymmddhh}

   # VBAL yaml
   yaml_name="vbal_${yyyymmddhh}.yaml"
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
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${yyyymmddhh}/mem001
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps]
date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
bump:
  datadir: ${data_dir_c384}/${bump_dir}
  prefix: vbal_${yyyymmddhh}/vbal_${yyyymmddhh}
  verbosity: main
  universe_rad: 2000.0e3
  update_vbal_cov: 1
  write_vbal_cov: 1
  new_vbal: 1
  write_vbal: 1
  write_samp_local: 1
  nc1: 5000
  nc2: 3500
  vbal_block: [1,1,0,1]
  vbal_rad: 2000.0e3
  vbal_pseudo_inv: 1
  vbal_pseudo_inv_var_th: 0.1
  ensemble:
    members:
EOF
   for imem in $(seq 1 1 ${nmem}); do
      imemp=$(printf "%.3d" "${imem}")
cat<< EOF >> ${yaml_dir}/${yaml_name}
    - filetype: gfs
      state variables: *stateVars
      psinfile: 1
      datapath: ${data_dir_c384}/${yyyymmddhh}/mem${imemp}
      filename_core: bvars.fv_core.res.nc
      filename_trcr: bvars.fv_tracer.res.nc
      filename_cplr: bvars.coupler.res
      date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
EOF
   done

   # VBAL sbatch
   sbatch_name="vbal_${yyyymmddhh}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=vbal_${yyyymmddhh}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/vbal_${yyyymmddhh}/vbal_${yyyymmddhh}.err
#SBATCH -o ${work_dir}/vbal_${yyyymmddhh}/vbal_${yyyymmddhh}.out

source ${env_script}

cd ${work_dir}/vbal_${yyyymmddhh}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

   ####################################################################
   # Unbal ############################################################
   ####################################################################

   # Create specific BUMP and work directories
   mkdir -p ${data_dir_c384}/${bump_dir}/unbal_${yyyymmddhh}
   mkdir -p ${work_dir}/unbal_${yyyymmddhh}

   # Unbal yaml
   yaml_name="unbal_${yyyymmddhh}.yaml"
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
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${yyyymmddhh}/mem001
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: *stateVars
date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
bump:
  datadir: ${data_dir_c384}/${bump_dir}
  prefix: unbal_${yyyymmddhh}/unbal_${yyyymmddhh}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal: 1
  fname_samp: vbal_${yyyymmddhh}/vbal_${yyyymmddhh}_sampling
  fname_vbal: vbal_${yyyymmddhh}/vbal_${yyyymmddhh}_vbal
  load_samp_local: 1
  vbal_block: [1,1,0,1]
operators application:
EOF
   for imem in $(seq 1 1 ${nmem}); do
      imemp=$(printf "%.3d" "${imem}")
cat<< EOF >> ${yaml_dir}/${yaml_name}
- input:
    filetype: gfs
    state variables: *stateVars
    psinfile: 1
    datapath: ${data_dir_c384}/${yyyymmddhh}/mem${imemp}
    filename_core: bvars.fv_core.res.nc
    filename_trcr: bvars.fv_tracer.res.nc
    filename_cplr: bvars.coupler.res
  bump operators: [multiplyVbalInv]
  output:
    filetype: gfs
    datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem${imemp}
    filename_core: unbal.fv_core.res.nc
    filename_trcr: unbal.fv_tracer.res.nc
    filename_cplr: unbal.coupler.res
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
EOF
   done

   # Unbal sbatch
   sbatch_name="unbal_${yyyymmddhh}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=unbal_${yyyymmddhh}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/unbal_${yyyymmddhh}/unbal_${yyyymmddhh}.err
#SBATCH -o ${work_dir}/unbal_${yyyymmddhh}/unbal_${yyyymmddhh}.out

source ${env_script}

cd ${work_dir}/unbal_${yyyymmddhh}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF


   ####################################################################
   # VAR-MOM ##########################################################
   ####################################################################

   for var in ${vars}; do
      # Create specific BUMP and work directories
      mkdir -p ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}
      mkdir -p ${work_dir}/var-mom_${yyyymmddhh}_${var}

      # VAR-MOM yaml
      yaml_name="var-mom_${yyyymmddhh}_${var}.yaml"
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
  state variables: &stateVars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem001
  filename_core: ${yyyy}${mm}${dd}.${hh}0000.unbal.fv_core.res.nc
  filename_trcr: ${yyyy}${mm}${dd}.${hh}0000.unbal.fv_tracer.res.nc
  filename_cplr: ${yyyy}${mm}${dd}.${hh}0000.unbal.coupler.res
input variables: [${var}]
date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
bump:
  prefix: var-mom_${yyyymmddhh}/var-mom_${yyyymmddhh}_${var}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
  universe_rad: 4000.0e3
  method: cor
  strategy: specific_univariate
  update_var: 1
  update_mom: 1
  write_mom: 1
  new_hdiag: 1
  write_hdiag: 1
  write_samp_local: 1
  nc1: 5000
  nc2: 1000
  nc3: 50
  dc: 75.0e3
  nl0r: 15
  local_diag: 1
  local_rad: 2000.0e3
  diag_rvflt: 0.1
  ensemble:
    members:
EOF
      for imem in $(seq 1 1 ${nmem}); do
         imemp=$(printf "%.3d" "${imem}")
cat<< EOF >> ${yaml_dir}/${yaml_name}
    - filetype: gfs
      state variables: *stateVars
      psinfile: 1
      datapath: ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem${imemp}
      filename_core: ${yyyy}${mm}${dd}.${hh}0000.unbal.fv_core.res.nc
      filename_trcr: ${yyyy}${mm}${dd}.${hh}0000.unbal.fv_tracer.res.nc
      filename_cplr: ${yyyy}${mm}${dd}.${hh}0000.unbal.coupler.res
      date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
EOF
      done
cat<< EOF >> ${yaml_dir}/${yaml_name}
output:
- parameter: var
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}
  filename_core: var_${var}.fv_core.res.nc
  filename_trcr: var_${var}.fv_tracer.res.nc
  filename_cplr: var_${var}.coupler.res
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
- parameter: m4
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}
  filename_core: m4_${var}.fv_core.res.nc
  filename_trcr: m4_${var}.fv_tracer.res.nc
  filename_cplr: m4_${var}.coupler.res
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
- parameter: cor_rh
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}
  filename_core: cor_rh_${var}.fv_core.res.nc
  filename_trcr: cor_rh_${var}.fv_tracer.res.nc
  filename_cplr: cor_rh_${var}.coupler.res
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
- parameter: cor_rv
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/var-mom_${yyyymmddhh}
  filename_core: cor_rv_${var}.fv_core.res.nc
  filename_trcr: cor_rv_${var}.fv_tracer.res.nc
  filename_cplr: cor_rv_${var}.coupler.res
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
- parameter: var
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: var_${yyyymmddhh}_${var}.nc4
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
- parameter: m4
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: m4_${yyyymmddhh}_${var}.nc4
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
- parameter: cor_rh
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: cor_rh_${yyyymmddhh}_${var}.nc4
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
- parameter: cor_rv
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: cor_rv_${yyyymmddhh}_${var}.nc4
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
EOF

      # VAR-MOM sbatch
      sbatch_name="var-mom_${yyyymmddhh}_${var}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=var-mom_${yyyymmddhh}_${var}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/var-mom_${yyyymmddhh}_${var}/var-mom_${yyyymmddhh}_${var}.err
#SBATCH -o ${work_dir}/var-mom_${yyyymmddhh}_${var}/var-mom_${yyyymmddhh}_${var}.out

source ${env_script}

cd ${work_dir}/var-mom_${yyyymmddhh}_${var}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF
   done
done
