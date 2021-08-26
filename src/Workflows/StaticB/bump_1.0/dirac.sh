#!/bin/bash

####################################################################
# DIRAC_COR_LOCAL ##################################################
####################################################################

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
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
  state variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
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
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
  ifdir: ["psi","psi","psi","psi","psi","psi","chi","chi","chi","chi","chi","chi","t","t","t","t","t","t","sphum","sphum","sphum","sphum","sphum","sphum","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","o3mr","o3mr","o3mr","o3mr","o3mr","o3mr","ps","ps","ps","ps","ps","ps"]
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

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
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
  state variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
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
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
  ifdir: ["psi","psi","psi","psi","psi","psi","chi","chi","chi","chi","chi","chi","t","t","t","t","t","t","sphum","sphum","sphum","sphum","sphum","sphum","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","o3mr","o3mr","o3mr","o3mr","o3mr","o3mr","ps","ps","ps","ps","ps","ps"]
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

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
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
  state variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
  psinfile: 1
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
    input variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
  ifdir: ["psi","psi","psi","psi","psi","psi","chi","chi","chi","chi","chi","chi","t","t","t","t","t","t","sphum","sphum","sphum","sphum","sphum","sphum","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","o3mr","o3mr","o3mr","o3mr","o3mr","o3mr","ps","ps","ps","ps","ps","ps"]
EOF

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

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
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
  state variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
  psinfile: 1
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  bump:
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_global: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
    input variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
  ifdir: ["psi","psi","psi","psi","psi","psi","chi","chi","chi","chi","chi","chi","t","t","t","t","t","t","sphum","sphum","sphum","sphum","sphum","sphum","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","o3mr","o3mr","o3mr","o3mr","o3mr","o3mr","ps","ps","ps","ps","ps","ps"]
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

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
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
  state variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
    input variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
  ifdir: ["t","t","t","t","t","t"]
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

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
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
  state variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_global: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
    input variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
  ifdir: ["t","t","t","t","t","t"]
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

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
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
  state variables: &state_vars [ua,va,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
  datapath: ${data_dir_c384}/${bkg_dir}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
    input variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
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

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
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
  state variables: &state_vars [ua,va,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
  datapath: ${data_dir_c384}/${bkg_dir}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
    input variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
      wind_streamfunction: stream_function
      wind_velocity_potential: velocity_potential
      wind_zonal: eastward_wind
      wind_meridional: northward_wind
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
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

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
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
  state variables: &state_vars [ua,va,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
  datapath: ${data_dir_c384}/${bkg_dir}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_global: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
    input variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
      wind_streamfunction: stream_function
      wind_velocity_potential: velocity_potential
      wind_zonal: eastward_wind
      wind_meridional: northward_wind
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
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
# DIRAC_FULL_C192_LOCAL ############################################
####################################################################

# Create specific BUMP and work directories
mkdir -p ${data_dir_c192}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_C192_LOCAL yaml
yaml_name="dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [6,6]
  npx: 193
  npy: 193
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  state variables: &state_vars [ua,va,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
  datapath: ${data_dir_c192}/${bkg_dir}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c192}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    universe_rad: 12000.0e3
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
    - variables: [surface_pressure]
      fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
  variable changes:
  - variable change: StdDev
    input variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      - variables: [surface_pressure]
    input:
    - parameter: stddev
      filetype: gfs
      psinfile: 1
      datapath: ${data_dir_c192}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
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
      datadir: ${data_dir_c192}/${bump_dir}
      prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_wind_local: 1
      wind_streamfunction: stream_function
      wind_velocity_potential: velocity_potential
      wind_zonal: eastward_wind
      wind_meridional: northward_wind
output B:
  filetype: geos
  datapath: ${data_dir_c192}/${bump_dir}/geos
  filename_bkgd: dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 6
  ixdir: [64,64,64,64,64,64]
  iydir: [64,64,64,64,64,64]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
EOF

# DIRAC_FULL_C192_LOCAL sbatch
sbatch_name="dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# DIRAC_FULL_7x7_LOCAL #############################################
####################################################################

# Create specific BUMP and work directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_7x7_LOCAL yaml
yaml_name="dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [7,7]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  state variables: &state_vars [ua,va,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
  datapath: ${data_dir_c384}/${bkg_dir}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res
background error:
  covariance model: BUMP
  active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  bump:
    prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    datadir: ${data_dir_c384}/${bump_dir}
    verbosity: main
    strategy: specific_univariate
    load_nicas_local: 1
    min_lev:
      liq_wat: 76
    grids:
    - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
    input variables: &control_vars [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    output variables: *control_vars
    active variables: *active_vars
    bump:
      verbosity: main
      universe_rad: 100.0e3
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
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
      wind_streamfunction: stream_function
      wind_velocity_potential: velocity_potential
      wind_zonal: eastward_wind
      wind_meridional: northward_wind
output B:
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
EOF

# DIRAC_FULL_7x7_LOCAL sbatch
sbatch_name="dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=294
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 294 ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}

exit 0
EOF
