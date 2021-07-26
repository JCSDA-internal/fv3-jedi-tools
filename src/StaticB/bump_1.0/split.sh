#!/bin/bash

####################################################################
# VBAL_C192 ########################################################
####################################################################


# Create specific BUMP and work directories
mkdir -p ${data_dir_c192}/${bump_dir}/vbal_${yyyymmddhh_last}
mkdir -p ${data_dir_c192}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}

# Link input files
ln -sf ${data_dir_c384}/${bump_dir}/vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling.nc ${data_dir_c192}/${bump_dir}/vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling.nc
ln -sf ${data_dir_c384}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}_vbal.nc ${data_dir_c192}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}_vbal.nc

# VBAL_C192 yaml
yaml_name="split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
  trc_file: ${data_dir}/fv3files/field_table
  akbk: ${data_dir}/fv3files/akbk127.nc4
  layout: [6,6]
  io_layout: [1,1]
  npx: 193
  npy: 193
  npz: 127
  ntiles: 6
  fieldsets:
    - fieldset: ${data_dir}/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c192}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  datadir: ${data_dir_c192}/${bump_dir}
  prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal: 1
  write_vbal: 1
  fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
  ens1_nsub: ${ndates}
  load_samp_global: 1
  write_samp_local: 1
  vbal_block: [1,1,0,1]
EOF

# VBAL_C192 sbatch
sbatch_name="split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}/split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}/split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# VBAL_7x7 #########################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}

# VBAL_7x7 yaml
yaml_name="split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
  trc_file: ${data_dir}/fv3files/field_table
  akbk: ${data_dir}/fv3files/akbk127.nc4
  layout: [7,7]
  io_layout: [1,1]
  npx: 385
  npy: 385
  npz: 127
  ntiles: 6
  fieldsets:
    - fieldset: ${data_dir}/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  datadir: ${data_dir_c384}/${bump_dir}
  prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal: 1
  write_vbal: 1
  fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
  ens1_nsub: ${ndates}
  load_samp_global: 1
  write_samp_local: 1
  vbal_block: [1,1,0,1]
EOF

# VBAL_7x7 sbatch
sbatch_name="split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=294
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}/split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}/split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 294 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# NICAS_C192 #######################################################
####################################################################

# Create specific BUMP directory
mkdir -p ${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

# Create specific work directory
mkdir -p ${work_dir}/split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}

# Link input files
ln -sf ${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_3D.nc ${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_3D.nc
ln -sf ${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_2D.nc ${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_2D.nc

# NICAS_C192 yaml
yaml_name="split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
  trc_file: ${data_dir}/fv3files/field_table
  akbk: ${data_dir}/fv3files/akbk127.nc4
  layout: [6,6]
  io_layout: [1,1]
  npx: 193
  npy: 193
  npz: 127
  ntiles: 6
  fieldsets:
    - fieldset: ${data_dir}/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c192}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
  datadir: ${data_dir_c192}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  load_nicas_global: 1
  write_nicas_local: 1
  min_lev:
    liq_wat: 76
  grids:
  - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_3D
  - variables: [surface_pressure]
    fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_2D
universe radius:
  filetype: gfs
  psinfile: 1
  datapath: ${data_dir_c192}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
EOF

# NICAS_C192 sbatch
sbatch_name="split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=2
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}/split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}/split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.out

export OMP_NUM_THREADS=2
source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# NICAS_7x7 ########################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}

# NICAS_7x7 yaml
yaml_name="split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
  trc_file: ${data_dir}/fv3files/field_table
  akbk: ${data_dir}/fv3files/akbk127.nc4
  layout: [7,7]
  io_layout: [1,1]
  npx: 385
  npy: 385
  npz: 127
  ntiles: 6
  fieldsets:
    - fieldset: ${data_dir}/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
  datadir: ${data_dir_c384}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  load_nicas_global: 1
  write_nicas_local: 1
  min_lev:
    liq_wat: 76
  grids:
  - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_3D
  - variables: [surface_pressure]
    fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_2D
universe radius:
  filetype: gfs
  psinfile: 1
  datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
  date: ${yyyy}-${mm}-${dd}T${hh}:00:00Z
EOF

# NICAS_7x7 sbatch
sbatch_name="split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=294
#SBATCH --cpus-per-task=2
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}/split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}/split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.out

export OMP_NUM_THREADS=2
source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 294 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# PSICHITOUV_C192 ##################################################
####################################################################

# Create specific work directory
mkdir -p ${data_dir_c192}/${bump_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}

# PSICHITOUV_C192 yaml
yaml_name="split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
  trc_file: ${data_dir}/fv3files/field_table
  akbk: ${data_dir}/fv3files/akbk127.nc4
  layout: [6,6]
  io_layout: [1,1]
  npx: 193
  npy: 193
  npz: 127
  ntiles: 6
  fieldsets:
    - fieldset: ${data_dir}/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c192}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  datadir: ${data_dir_c192}/${bump_dir}
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

# PSICHITOUV_C192 sbatch
sbatch_name="split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}/split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}/split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.out

export OMP_NUM_THREADS=2
source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# PSICHITOUV_7x7 ###################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}

# PSICHITOUV_7x7 yaml
yaml_name="split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
  trc_file: ${data_dir}/fv3files/field_table
  akbk: ${data_dir}/fv3files/akbk127.nc4
  layout: [7,7]
  io_layout: [1,1]
  npx: 385
  npy: 385
  npz: 127
  ntiles: 6
  fieldsets:
    - fieldset: ${data_dir}/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c384}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
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

# PSICHITOUV_7x7 sbatch
sbatch_name="split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=294
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}/split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}/split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.out

export OMP_NUM_THREADS=2
source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 294 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF
