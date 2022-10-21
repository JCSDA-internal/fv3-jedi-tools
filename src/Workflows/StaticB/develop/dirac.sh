#!/bin/bash

# Source functions
source ./functions.sh

# Create data directories
mkdir -p ${data_dir_def}/${bump_dir}/dirac_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_def}/${bump_dir}/dirac_c0_global_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_regrid}/${bump_dir}/dirac_regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

####################################################################
# DIRAC_C0 #########################################################
####################################################################

# Job name
job=dirac_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# DIRAC_C0 yaml
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
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      fname_nicas: nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_nicas      
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      - variables: [surface_pressure]
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *stateVars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_C0 sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_C1 #########################################################
####################################################################

# Job name
job=dirac_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# DIRAC_C1 yaml
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
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      fname_nicas: nicas_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_nicas
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      - variables: [surface_pressure]
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *stateVars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_c1_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_C1 sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_SI #########################################################
####################################################################

# Job name
job=dirac_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# DIRAC_SI yaml
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
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      fname_nicas: nicas_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_nicas
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      - variables: [surface_pressure]
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *stateVars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_si_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_SI sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_PSICHITOUV #################################################
####################################################################

# Job name
job=dirac_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# DIRAC_PSICHITOUV yaml
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
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      fname_nicas: nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_nicas
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      - variables: [surface_pressure]
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      variables: [stream_function,velocity_potential,air_temperature,surface_pressure]  # TODO(Benjamin): remove this line when vbal_block is refactored
      fname_samp: vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  - saber block name: BUMP_PsiChiToUV
    active variables: [eastward_wind,northward_wind,stream_function,velocity_potential]
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      verbosity: main
      universe_rad: 2000.0e3
      load_wind_local: true
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_PSICHITOUV sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_C0_GLOBAL ##################################################
####################################################################

# Job name
job=dirac_c0_global_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# DIRAC_C0_GLOBAL yaml
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
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      datadir: ${data_dir_def}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_global: true
      min_lev:
        cloud_liquid_water: 76
      fname_nicas: nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_nicas
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      - variables: [surface_pressure]
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
    - parameter: nicas_norm
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: nicas_norm.fv_core.res.nc
        filename_trcr: nicas_norm.fv_tracer.res.nc
        filename_cplr: nicas_norm.coupler.res
  saber outer blocks:  
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_def}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling
      load_samp_global: true
      vbal_block: [true, true,false, true,false,false]
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *stateVars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/dirac_c0_global_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_C0_GLOBAL sbatch
ntasks=${ntasks_def}
cpus_per_task=2
threads=1
time=01:00:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# DIRAC_REGRID #####################################################
####################################################################

# Job name
job=dirac_regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# DIRAC_REGRID yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
initial condition:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_regrid}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: balanced.fv_core.res.nc
  filename_trcr: balanced.fv_tracer.res.nc
  filename_cplr: balanced.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    bump:
      prefix: nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      datadir: ${data_dir_regrid}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        cloud_liquid_water: 76
      fname_nicas: nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_c0_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_nicas
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      - variables: [surface_pressure]
    input fields:
    - parameter: universe radius
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
  saber outer blocks:
  - saber block name: StdDev
    input fields:
    - parameter: StdDev
      file:
        datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
        filetype: fms restart
        set datetime on read: true
        psinfile: true
        datapath: ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
  - saber block name: BUMP_VerticalBalance
    bump:
      datadir: ${data_dir_regrid}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  linear variable change:
    linear variable change name: Control2Analysis
    input variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    output variables: *stateVars
output dirac:
  filetype: fms restart
  datapath: ${data_dir_regrid}/${bump_dir}/dirac_regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
dirac:
  ndir: 6
  ixdir: [${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid}]
  iydir: [${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid}]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: [air_temperature,air_temperature,air_temperature,air_temperature,air_temperature,air_temperature]
EOF

# DIRAC_REGRID sbatch
ntasks=${ntasks_regrid}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
