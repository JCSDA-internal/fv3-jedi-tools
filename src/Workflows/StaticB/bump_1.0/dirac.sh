#!/bin/bash

####################################################################
# DIRAC_COR_LOCAL ##################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COR_LOCAL yaml
yaml_name="dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
initial condition:
  filetype: gfs
  state variables: &active_vars [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: *active_vars
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: [psi,psi,psi,psi,psi,psi,chi,chi,chi,chi,chi,chi,tv,tv,tv,tv,tv,tv,rh,rh,rh,rh,rh,rh,ps,ps,ps,ps,ps,ps]
EOF

# DIRAC_COR_LOCAL sbatch
sbatch_name="dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_COR_GLOBAL #################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COR_GLOBAL yaml
yaml_name="dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
initial condition:
  filetype: gfs
  state variables: &active_vars [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: *active_vars
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_global: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: [psi,psi,psi,psi,psi,psi,chi,chi,chi,chi,chi,chi,tv,tv,tv,tv,tv,tv,rh,rh,rh,rh,rh,rh,ps,ps,ps,ps,ps,ps]
EOF

# DIRAC_COR_GLOBAL sbatch
sbatch_name="dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_COV_LOCAL ##################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_LOCAL yaml
yaml_name="dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
initial condition:
  filetype: gfs
  state variables: &control_vars [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,tv,ps,rh]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  variable changes:
  - variable change: StdDev
    input variables: &control_vars [psi,chi,tv,ps,rh]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      - variables: [surface_pressure]
    input:
    - parameter: stddev
      filetype: gfs
      psinfile: 1
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
      filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
      filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: [psi,psi,psi,psi,psi,psi,chi,chi,chi,chi,chi,chi,tv,tv,tv,tv,tv,tv,rh,rh,rh,rh,rh,rh,ps,ps,ps,ps,ps,ps]EOF

# DIRAC_COV_LOCAL sbatch
sbatch_name="dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_COV_GLOBAL #################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_GLOBAL yaml
yaml_name="dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
initial condition:
  filetype: gfs
  state variables: &control_vars [psi,chi,tv,ps,rh]
  psinfile: 1
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,tv,ps,rh]
  bump:
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_global: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  variable changes:
  - variable change: StdDev
    input variables: &control_vars [psi,chi,tv,ps,rh]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      - variables: [surface_pressure]
    input:
    - parameter: stddev
      filetype: gfs
      psinfile: 1
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
      filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
      filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: [psi,psi,psi,psi,psi,psi,chi,chi,chi,chi,chi,chi,tv,tv,tv,tv,tv,tv,rh,rh,rh,rh,rh,rh,ps,ps,ps,ps,ps,ps]
EOF

# DIRAC_COV_GLOBAL sbatch
sbatch_name="dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_COV_MULTI_LOCAL ############################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_MULTI_LOCAL yaml
yaml_name="dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
initial condition:
  filetype: gfs
  state variables: &control_vars [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,tv,ps,rh]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  variable changes:
  - variable change: StdDev
    input variables: &control_vars [psi,chi,tv,ps,rh]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      - variables: [surface_pressure]
    input:
    - parameter: stddev
      filetype: gfs
      psinfile: 1
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
      filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
      filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - variable change: StatsVariableChange
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: 1
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: 1
      vbal_block: [1,1,0,1]
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [tv,tv,tv,tv,tv,tv]
EOF

# DIRAC_COV_MULTI_LOCAL sbatch
sbatch_name="dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_COV_MULTI_GLOBAL ###########################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_MULTI_GLOBAL yaml
yaml_name="dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
initial condition:
  filetype: gfs
  state variables: &control_vars [psi,chi,tv,ps,rh]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,tv,ps,rh]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_global: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  variable changes:
  - variable change: StdDev
    input variables: &control_vars [psi,chi,tv,ps,rh]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      - variables: [surface_pressure]
    input:
    - parameter: stddev
      filetype: gfs
      psinfile: 1
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
      filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
      filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - variable change: StatsVariableChange
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: 1
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_global: 1
      vbal_block: [1,1,0,1]
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [tv,tv,tv,tv,tv,tv]
EOF

# DIRAC_COV_MULTI_GLOBAL sbatch
sbatch_name="dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_FULL_C2A_LOCAL #############################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_C2A_LOCAL yaml
yaml_name="dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
initial condition:
  filetype: gfs
  datapath: ${data_dir_c384}/${bkg_dir}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  state variables: &state_vars [ua,va,tv,ps,rh]
  psinfile: true
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,tv,ps,rh]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  variable changes:
  - variable change: StdDev
    input variables: &control_vars [psi,chi,tv,ps,rh]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      - variables: [surface_pressure]
    input:
    - parameter: stddev
      filetype: gfs
      psinfile: 1
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
      filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
      filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - variable change: StatsVariableChange
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: 1
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: 1
      vbal_block: [1,1,0,1]
  - variable change: Control2Analysis
    input variables: *control_vars
    output variables: *state_vars
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [tv,tv,tv,tv,tv,tv]
EOF

# DIRAC_FULL_C2A_LOCAL sbatch
sbatch_name="dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_FULL_PSICHITOUV_LOCAL ######################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_PSICHITOUV_LOCAL yaml
yaml_name="dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
initial condition:
  filetype: gfs
  datapath: ${data_dir_c384}/${bkg_dir}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  state variables: &state_vars [ua,va,tv,ps,rh]
  psinfile: true
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,tv,ps,rh]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  variable changes:
  - variable change: StdDev
    input variables: &control_vars [psi,chi,tv,ps,rh]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      - variables: [surface_pressure]
    input:
    - parameter: stddev
      filetype: gfs
      psinfile: 1
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
      filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
      filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - variable change: StatsVariableChange
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: 1
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: 1
      vbal_block: [1,1,0,1]
  - variable change: PsiChiToUV
    input variables: *control_vars
    output variables: *state_vars
    active variables: [psi,chi]
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_wind_local: 1
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [tv,tv,tv,tv,tv,tv]
EOF

# DIRAC_FULL_PSICHITOUV_LOCAL sbatch
sbatch_name="dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_FULL_GLOBAL ################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_GLOBAL yaml
yaml_name="dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
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
initial condition:
  filetype: gfs
  datapath: ${data_dir_c384}/${bkg_dir}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  state variables: &state_vars [ua,va,tv,ps,rh]
  psinfile: true
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,tv,ps,rh]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_global: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  variable changes:
  - variable change: StdDev
    input variables: &control_vars [psi,chi,tv,ps,rh]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      - variables: [surface_pressure]
    input:
    - parameter: stddev
      filetype: gfs
      psinfile: 1
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
      filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
      filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - variable change: StatsVariableChange
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: 1
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_global: 1
      vbal_block: [1,1,0,1]
  - variable change: PsiChiToUV
    input variables: *control_vars
    output variables: *state_vars
    active variables: [psi,chi]
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_wind_local: 1
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [tv,tv,tv,tv,tv,tv]
EOF

# DIRAC_FULL_GLOBAL sbatch
sbatch_name="dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_FULL_REGRID_LOCAL ##########################################
####################################################################

# Create directories
mkdir -p ${data_dir_regrid}/${bump_dir}/geos
mkdir -p ${work_dir}/dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_REGRID_LOCAL yaml
yaml_name="dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: ${npx}
  npy: ${npy}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  datapath: ${data_dir_regrid}/${bkg_dir}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  state variables: &state_vars [ua,va,tv,ps,rh]
  psinfile: true
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,tv,ps,rh]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_regrid}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  universe radius:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  variable changes:
  - variable change: StdDev
    input variables: &control_vars [psi,chi,tv,ps,rh]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,virtual_temperature,relative_humidity]
      - variables: [surface_pressure]
    input:
    - parameter: stddev
      filetype: gfs
      psinfile: 1
      datapath: ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
      filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
      filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - variable change: StatsVariableChange
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_regrid}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: 1
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: 1
      vbal_block: [1,1,0,1]
  - variable change: PsiChiToUV
    input variables: *control_vars
    output variables: *state_vars
    active variables: [psi,chi]
    bump:
      datadir: ${data_dir_regrid}/${bump_dir}
      prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_wind_local: 1
output B:
  filetype: geos
  datapath: ${data_dir_regrid}/${bump_dir}/geos
  filename_bkgd: dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
dirac:
  ndir: 6
  ixdir: [${dirac_center},${dirac_center},${dirac_center},${dirac_center},${dirac_center},${dirac_center}]
  iydir: [${dirac_center},${dirac_center},${dirac_center},${dirac_center},${dirac_center},${dirac_center}]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [tv,tv,tv,tv,tv,tv]
EOF

# DIRAC_FULL_REGRID_LOCAL sbatch
sbatch_name="dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nlx*nly))
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_full_c${cregrid}_${nlx}x${nly}_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n $((6*nlx*nly)) ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF
