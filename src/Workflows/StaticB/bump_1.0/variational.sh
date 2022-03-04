#!/bin/bash

# Source functions
source ./functions.sh

# Observations file
declare -A obs_file
obs_file+=(["sondes"]="ncdiag.oper_3d.ob.PT6H.sondes.2020-12-14T21:00:00Z")
obs_file+=(["single_ob_a"]="single_ob_a")
obs_file+=(["single_ob_b"]="single_ob_b")
obs_file+=(["single_ob_c"]="single_ob_c")
obs_file+=(["single_ob_d"]="single_ob_d")
obs_file+=(["single_ob_e"]="single_ob_e")
obs_file+=(["single_ob_f"]="single_ob_f")

# Observations name
declare -A obs_name
obs_name+=(["sondes"]="Radiosonde")
obs_name+=(["single_ob_a"]="Radiosonde")
obs_name+=(["single_ob_b"]="Radiosonde")
obs_name+=(["single_ob_c"]="Radiosonde")
obs_name+=(["single_ob_d"]="Radiosonde")
obs_name+=(["single_ob_e"]="Radiosonde")
obs_name+=(["single_ob_f"]="Radiosonde")

# Observations simulated variables
declare -A obs_vars
obs_vars+=(["sondes"]="air_temperature,eastward_wind,northward_wind")
obs_vars+=(["single_ob_a"]="air_temperature")
obs_vars+=(["single_ob_b"]="air_temperature")
obs_vars+=(["single_ob_c"]="air_temperature")
obs_vars+=(["single_ob_d"]="air_temperature")
obs_vars+=(["single_ob_e"]="air_temperature")
obs_vars+=(["single_ob_f"]="air_temperature")

####################################################################
# 3DVAR ############################################################
####################################################################

# Job name
job=variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}

# Create directories
mkdir -p ${work_dir}/${job}
mkdir -p ${data_dir_c384}/${bump_dir}/${job}

# 3DVAR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,t,ps,sphum,liq_wat,o3mr]

  geometry:
    fms initialization:
      namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
      field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
    akbk: &akbk ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
    layout: &layout [${nlx_def},${nly_def}]
    npx: &npx ${npx_def}
    npy: &npy ${npy_def}
    npz: &npz 127
    fieldsets:
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml

  background:
    datetime: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: *vars
    psinfile: true

  background error:
    covariance model: SABER
    full inverse: true
    saber blocks:
    - saber block name: BUMP_NICAS
      saber central block: true
      input variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
      output variables: *control_vars
      active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
      bump:
        prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
        datadir: ${data_dir_c384}/${bump_dir}
        verbosity: main
        strategy: specific_univariate
        load_nicas_local: true
        min_lev:
          liq_wat: 76
        grids:
        - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
          fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
        - variables: [surface_pressure]
          fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
        universe radius:
          datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
          filetype: fms restart
          psinfile: true
          datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
          filename_core: cor_rh.fv_core.res.nc
          filename_trcr: cor_rh.fv_tracer.res.nc
          filename_cplr: cor_rh.coupler.res
          date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - saber block name: StdDev
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - saber block name: BUMP_VerticalBalance
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
      bump:
        datadir: ${data_dir_c384}/${bump_dir}
        prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_vbal: true
        fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
        load_samp_local: true
        vbal_block: [true, true,false, true,false,false]
    - saber block name: BUMP_PsiChiToUV
      input variables: *control_vars
      output variables: *vars
      active variables: [psi,chi,ua,va]
      bump:
        datadir: ${data_dir_c384}/${bump_dir}
        prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_wind_local: true

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: ${data_dir}/obs/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
      obsdataout:
        obsfile: ${data_dir_c384}/${bump_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
      simulated variables: [air_temperature]
    obs operator:
      name: VertInterp
    obs error:
      covariance model: diagonal

variational:

  minimizer:
    algorithm: DRIPCG

  iterations:
  - ninner: 30
    gradient norm reduction: 1e-10
    test: on
    geometry:
      fms initialization:
        namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
        field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
      akbk: *akbk
      layout: *layout
      npx: *npx
      npy: *npy
      npz: *npz
      fieldsets:
      - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
      - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml
    diagnostics:
      departures: ombg

final:
  diagnostics:
    departures: oman

output:
  filetype: fms restart
  datapath: ${data_dir_c384}/${bump_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_sfcw: fv_srf_wnd.res.nc
  filename_trcr: fv_tracer.res.nc
  filename_phys: phy_data.nc
  filename_sfcd: sfc_data.nc
  first: PT0H
  frequency: PT1H
EOF

# 3DVAR sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:40:00
exe=fv3jedi_var.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# 3DVAR with specific observations #################################
####################################################################

for obs in ${obs_xp} ; do
   # Job name
   job=variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}

   # Create directories
   mkdir -p ${work_dir}/${job}
   mkdir -p ${data_dir_c384}/${bump_dir}/${job}
   
   # 3DVAR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,t,ps,sphum,liq_wat,o3mr]

  geometry:
    fms initialization:
      namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
      field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
    akbk: &akbk ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
    layout: &layout [${nlx_def},${nly_def}]
    npx: &npx ${npx_def}
    npy: &npy ${npy_def}
    npz: &npz 127
    fieldsets:
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml

  background:
    datetime: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_c384}/${bump_dir}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: *vars
    psinfile: true

  background error:
    covariance model: SABER
    full inverse: true
    saber blocks:
    - saber block name: BUMP_NICAS
      saber central block: true
      input variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
      output variables: *control_vars
      active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
      bump:
        prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
        datadir: ${data_dir_c384}/${bump_dir}
        verbosity: main
        strategy: specific_univariate
        load_nicas_local: true
        min_lev:
          liq_wat: 76
        grids:
        - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
          fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
        - variables: [surface_pressure]
          fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
        universe radius:
          datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
          filetype: fms restart
          psinfile: true
          datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
          filename_core: cor_rh.fv_core.res.nc
          filename_trcr: cor_rh.fv_tracer.res.nc
          filename_cplr: cor_rh.coupler.res
          date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - saber block name: StdDev
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - saber block name: BUMP_VerticalBalance
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
      bump:
        datadir: ${data_dir_c384}/${bump_dir}
        prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_vbal: true
        fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
        load_samp_local: true
        vbal_block: [true, true,false, true,false,false]
    - saber block name: BUMP_PsiChiToUV
      input variables: *control_vars
      output variables: *vars
      active variables: [psi,chi,ua,va]
      bump:
        datadir: ${data_dir_c384}/${bump_dir}
        prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_wind_local: true

  observations:
  - obs space:
      name: ${obs_name[${obs}]}
      obsdatain:
        obsfile: /work/noaa/da/dholdawa/JediWork/Benchmarks/3dvar/Data/obs/${obs_file[${obs}]}.nc4
      obsdataout:
        obsfile: ${data_dir_c384}/${bump_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}/${obs_file[${obs}]}.nc4
      simulated variables: [${obs_vars[${obs}]}]
    obs operator:
      name: VertInterp
    obs error:
      covariance model: diagonal

variational:

  minimizer:
    algorithm: DRIPCG

  iterations:
  - ninner: 30
    gradient norm reduction: 1e-10
    test: on
    geometry:
      fms initialization:
        namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
        field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
      akbk: *akbk
      layout: *layout
      npx: *npx
      npy: *npy
      npz: *npz
      fieldsets:
      - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
      - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml
    diagnostics:
      departures: ombg

final:
  diagnostics:
    departures: oman

output:
  filetype: fms restart
  datapath: ${data_dir_c384}/${bump_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_sfcw: fv_srf_wnd.res.nc
  filename_trcr: fv_tracer.res.nc
  filename_phys: phy_data.nc
  filename_sfcd: sfc_data.nc
  first: PT0H
  frequency: PT1H
EOF

   # 3DVAR sbatch
   ntasks=${ntasks_def}
   cpus_per_task=1
   threads=1
   time=00:20:00
   exe=fv3jedi_var.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
done

####################################################################
# 3DVAR REGRID #####################################################
####################################################################

# Job name
job=variational_3dvar_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}

# Create directories
mkdir -p ${work_dir}/${job}
mkdir -p ${data_dir_regrid}/${bump_dir}/${job}

# 3DVAR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,t,ps,sphum,liq_wat,o3mr]

  geometry:
    fms initialization:
      namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
      field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
    akbk: &akbk ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
    layout: &layout [${nlx_regrid},${nly_regrid}]
    npx: &npx ${npx_regrid}
    npy: &npy ${npy_regrid}
    npz: &npz 127
    fieldsets:
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml

  background:
    datetime: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: *vars
    psinfile: true

  background error:
    covariance model: SABER
    full inverse: true
    saber blocks:
    - saber block name: BUMP_NICAS
      saber central block: true
      input variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
      output variables: *control_vars
      active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
      bump:
        prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
        datadir: ${data_dir_regrid}/${bump_dir}
        verbosity: main
        strategy: specific_univariate
        load_nicas_local: true
        min_lev:
          liq_wat: 76
        grids:
        - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
          fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
        - variables: [surface_pressure]
          fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
        universe radius:
          datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
          filetype: fms restart
          psinfile: true
          datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
          filename_core: cor_rh.fv_core.res.nc
          filename_trcr: cor_rh.fv_tracer.res.nc
          filename_cplr: cor_rh.coupler.res
          date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - saber block name: StdDev
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        psinfile: true
        datapath: ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - saber block name: BUMP_VerticalBalance
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
      bump:
        datadir: ${data_dir_regrid}/${bump_dir}
        prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_vbal: true
        fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
        load_samp_local: true
        vbal_block: [true, true,false, true,false,false]
    - saber block name: BUMP_PsiChiToUV
      input variables: *control_vars
      output variables: *vars
      active variables: [psi,chi,ua,va]
      bump:
        datadir: ${data_dir_regrid}/${bump_dir}
        prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_wind_local: true

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: ${data_dir}/obs/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
      obsdataout:
        obsfile: ${data_dir_regrid}/${bump_dir}/variational_3dvar_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
      simulated variables: [air_temperature]
    obs operator:
      name: VertInterp
    obs error:
      covariance model: diagonal

variational:

  minimizer:
    algorithm: DRIPCG

  iterations:
  - ninner: 30
    gradient norm reduction: 1e-10
    test: on
    geometry:
      fms initialization:
        namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
        field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
      akbk: *akbk
      layout: *layout
      npx: *npx
      npy: *npy
      npz: *npz
      fieldsets:
      - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
      - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml
    diagnostics:
      departures: ombg

final:
  diagnostics:
    departures: oman

output:
  filetype: fms restart
  datapath: ${data_dir_regrid}/${bump_dir}/variational_3dvar_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_sfcw: fv_srf_wnd.res.nc
  filename_trcr: fv_tracer.res.nc
  filename_phys: phy_data.nc
  filename_sfcd: sfc_data.nc
  first: PT0H
  frequency: PT1H
EOF

# 3DVAR REGRID sbatch
ntasks=${ntasks_regrid}
cpus_per_task=2
threads=1
time=00:40:00
exe=fv3jedi_var.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# 3DVAR FULL REGRID ################################################
####################################################################

# Job name
job=variational_3dvar_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}

# Create directories
mkdir -p ${work_dir}/${job}
mkdir -p ${data_dir_regrid}/${bump_dir}/${job}

# 3DVAR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,t,ps,sphum,liq_wat,o3mr]

  geometry:
    fms initialization:
      namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
      field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
    akbk: &akbk ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
    layout: &layout [${nlx_regrid},${nly_regrid}]
    npx: &npx ${npx_regrid}
    npy: &npy ${npy_regrid}
    npz: &npz 127
    fieldsets:
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml

  background:
    datetime: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: [ua,va,t,ps,delp,sphum,ice_wat,liq_wat,o3mr,phis,
                      slmsk,sheleg,tsea,vtype,stype,vfrac,stc,smc,snwdph,
                      u_srf,v_srf,f10m] 

  background error:
    covariance model: SABER
    full inverse: true
    saber blocks:
    - saber block name: BUMP_NICAS
      saber central block: true
      input variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
      output variables: *control_vars
      active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
      bump:
        prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
        datadir: ${data_dir_regrid}/${bump_dir}
        verbosity: main
        strategy: specific_univariate
        load_nicas_local: true
        min_lev:
          liq_wat: 76
        grids:
        - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
          fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
        - variables: [surface_pressure]
          fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
        universe radius:
          datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
          filetype: fms restart
          psinfile: true
          datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
          filename_core: cor_rh.fv_core.res.nc
          filename_trcr: cor_rh.fv_tracer.res.nc
          filename_cplr: cor_rh.coupler.res
          date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - saber block name: StdDev
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
      file:
        datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
        filetype: fms restart
        psinfile: true
        datapath: ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - saber block name: BUMP_VerticalBalance
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
      bump:
        datadir: ${data_dir_regrid}/${bump_dir}
        prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_vbal: true
        fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
        load_samp_local: true
        vbal_block: [true, true,false, true,false,false]
    - saber block name: BUMP_PsiChiToUV
      input variables: *control_vars
      output variables: *vars
      active variables: [psi,chi,ua,va]
      bump:
        datadir: ${data_dir_regrid}/${bump_dir}
        prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_wind_local: true

#-------------------------------------------------------------------------------------------
# OBSERVATIONS #
#-------------------------------------------------------------------------------------------
  observations:
#  #-------------------------------------------------------------------------------------------
#  # AIRCRAFT #
#  #-------------------------------------------------------------------------------------------
#  - obs operator:
#      name: VertInterp
#    obs error:
#      covariance model: diagonal
#      random amplitude: 0.1
#    obs space:
#      name: Aircraft
#      obsdatain:
#        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.aircraft.2020-12-14T21:00:00Z.nc4
#        obsgrouping:
#          group variables: ["station_id"]
#          sort variable: "air_pressure"
#          sort order: "descending"
#      # obsdataout:
#        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.aircraft.2020-12-14T21:00:00Z.nc4
#      simulated variables: [eastward_wind, northward_wind, air_temperature, specific_humidity]
#      obs perturbations seed: 1
#    obs filters:
#    #--------------------------------------------------------------------------------------------------------------------
#    # WINDS
#    #--------------------------------------------------------------------------------------------------------------------
#    #
#    # Begin by assigning all ObsError to a constant value. These will get overwritten (as needed) for specific types.
#    - filter: BlackList
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      action:
#        name: assign error
#        error parameter: 2.0             # 2.0 m/s
#    #
#    # Assign initial ObsError specific to AIREP/ACARS
#    - filter: BlackList
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      action:
#        name: assign error
#        error parameter: 3.6             # 3.6 m/s
#      where:
#      - variable:
#          name: eastward_wind@ObsType
#        is_in: 230
#    #
#    # Assign intial ObsError specific to AMDAR
#    - filter: BlackList
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      action:
#        name: assign error
#        error parameter: 3.0             # 3.0 m/s
#      where:
#      - variable:
#          name: eastward_wind@ObsType
#        is_in: 231
#    #
#    # Assign intial ObsError specific to MDCRS
#    - filter: BlackList
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      action:
#        name: assign error
#        error parameter: 2.5             # 2.5 m/s
#      where:
#      - variable:
#          name: eastward_wind@ObsType
#        is_in: 233
#    #
#    # Assign the initial ObsError, based on height/pressure for RECON aircraft
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      minvalue: -135
#      maxvalue: 135
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: air_pressure@MetaData
#            xvals: [70000, 65000, 60000, 55000, 50000, 45000, 40000, 35000, 30000, 25000, 20000, 15000, 10000, 7500, 5000]
#            errors: [2.4, 2.5, 2.6, 2.7, 2.8, 2.95, 3.1, 3.25, 3.4, 3.175, 2.95, 2.725, 2.5, 2.6, 2.7]
#      where:
#      - variable:
#          name: eastward_wind@ObsType
#        is_in: 232
#    #
#    # Reject all obs with PreQC mark already set above 3
#    - filter: PreQC
#      maxvalue: 3
#      action:
#        name: reject
#    #
#    # Observation Range Sanity Check: either wind component or velocity exceeds 135 m/s
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      minvalue: -135
#      maxvalue: 135
#      action:
#        name: reject
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      test variables:
#      - name: Velocity@ObsFunction
#      maxvalue: 135.0
#      action:
#        name: reject
#    #
#    # Reject when pressure is less than 126 mb.
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      test variables:
#      - name: air_pressure@MetaData
#      minvalue: 12600
#      action:
#        name: reject
#    #
#    # Reject when difference of wind direction is more than 50 degrees.
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      test variables:
#      - name: WindDirAngleDiff@ObsFunction
#      maxvalue: 50.0
#      action:
#        name: reject
#    #
#    # When multiple obs exist within a single vertical model level, inflate ObsError
#    - filter: BlackList
#      filter variables:
#      - name: eastward_wind
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#            test QCflag: PreQC
#            inflate variables: [eastward_wind]
#      defer to post: true
#    #
#    - filter: BlackList
#      filter variables:
#      - name: northward_wind
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#            test QCflag: PreQC
#            inflate variables: [northward_wind]
#      defer to post: true
#    #
#    # If background check is largely different than obs, inflate ObsError
#    - filter: Background Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      absolute threshold: 7.5
#      action:
#        name: inflate error
#        inflation factor: 3.0
#      defer to post: true
#    #
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      action:
#        name: reject
#      maxvalue: 7.0
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: eastward_wind@ObsErrorData   # After inflation step
#          denominator:
#            name: eastward_wind@ObsError
#      defer to post: true
#    #
#    # If ObsError inflation factor is larger than threshold, reject obs
#    - filter: Bounds Check
#      filter variables:
#      - name: northward_wind
#      action:
#        name: reject
#      maxvalue: 7.0
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: northward_wind@ObsErrorData   # After inflation step
#          denominator:
#            name: northward_wind@ObsError
#      defer to post: true
#    #--------------------------------------------------------------------------------------------------------------------
#    # TEMPERATURE
#    #--------------------------------------------------------------------------------------------------------------------
#    #
#    # Begin by assigning all ObsError to a constant value. These will get overwritten for specific types.
#    - filter: BlackList
#      filter variables:
#      - name: air_temperature
#      action:
#        name: assign error
#        error parameter: 2.0             # 2.0 K
#    #
#    # Assign the initial observation error, based on pressure (for AIREP/ACARS; itype=130)
#    - filter: Bounds Check
#      filter variables:
#      - name: air_temperature
#      minvalue: 195
#      maxvalue: 327
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: air_pressure@MetaData
#            xvals: [100000, 95000, 90000, 85000, 80000]
#            errors: [2.5, 2.3, 2.1, 1.9, 1.7]
#      where:
#      - variable:
#          name: air_temperature@ObsType
#        is_in: 130
#    #
#    # Assign the initial observation error, based on pressure (for AMDAR and MDCRS; itype=131,133)
#    - filter: Bounds Check
#      filter variables:
#      - name: air_temperature
#      minvalue: 195
#      maxvalue: 327
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: air_pressure@MetaData
#            xvals: [100000, 95000, 90000, 85000, 80000]
#            errors: [1.4706, 1.3529, 1.2353, 1.1176, 1.0]
#      where:
#      - variable:
#          name: air_temperature@ObsType
#        is_in: 131,133
#    #
#    # Assign the initial observation error, based on pressure (for RECON aircraft; itype=132)
#    - filter: Bounds Check
#      filter variables:
#      - name: air_temperature
#      minvalue: 195
#      maxvalue: 327
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: air_pressure@MetaData
#            xvals: [100000, 95000, 90000, 85000, 35000, 30000, 25000, 20000, 15000, 10000, 7500, 5000, 4000, 3200, 2000, 1000]
#            errors: [1.2, 1.1, 0.9, 0.8, 0.8, 0.9, 1.2, 1.2, 1.0, 0.8, 0.8, 0.9, 0.95, 1.0, 1.25, 1.5]
#      where:
#      - variable:
#          name: air_temperature@ObsType
#        is_in: 132
#    #
#    # Observation Range Sanity Check
#    - filter: Bounds Check
#      filter variables:
#      - name: air_temperature
#      minvalue: 195
#      maxvalue: 327
#      action:
#        name: reject
#    #
#    # Reject all obs with PreQC mark already set above 3
#    - filter: PreQC
#      maxvalue: 3
#      action:
#        name: reject
#    #
#    # When multiple obs exist within a single vertical model level, inflate ObsError
#    - filter: BlackList
#      filter variables:
#      - name: air_temperature
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#    #       test QCflag: PreQC
#            inflate variables: [air_temperature]
#      defer to post: true
#    #
#    # If background check is largely different than obs, inflate ObsError
#    - filter: Background Check
#      filter variables:
#      - name: air_temperature
#      absolute threshold: 4.0
#      action:
#        name: inflate error
#        inflation factor: 3.0
#      defer to post: true
#    #
#    # If ObsError inflation factor is larger than threshold, reject obs
#    - filter: Bounds Check
#      filter variables:
#      - name: air_temperature
#      action:
#        name: reject
#      maxvalue: 7.0
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: air_temperature@ObsErrorData   # After inflation step
#          denominator:
#            name: air_temperature@ObsError
#      defer to post: true
#    #--------------------------------------------------------------------------------------------------------------------
#    # MOISTURE
#    #--------------------------------------------------------------------------------------------------------------------
#    #
#    # Assign the initial observation error, based on height/pressure Only_regrid MDCRS
#    - filter: Bounds Check
#      filter variables:
#      - name: specific_humidity
#      minvalue: 1.0E-7
#      maxvalue: 0.34999999
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: air_pressure@MetaData
#            xvals: [110000, 105000, 100000, 95000, 90000, 85000, 80000, 75000, 70000, 65000, 60000, 55000,
#                     50000, 45000, 40000, 35000, 30000, 25000, 20000, 15000, 10000, 7500, 5000, 4000, 3000]
#            errors: [.19455, .19062, .18488, .17877, .17342, .16976, .16777, .16696, .16605, .16522, .16637, .17086,
#                     .17791, .18492, .18996, .19294, .19447, .19597, .19748, .19866, .19941, .19979, .19994, .19999, .2]
#            scale_factor_var: specific_humidity@ObsValue
#      where:
#      - variable:
#          name: specific_humidity@ObsType
#        is_in: 133
#    #
#    # Observation Range Sanity Check
#    - filter: Bounds Check
#      filter variables:
#      - name: specific_humidity
#      minvalue: 1.0E-7
#      maxvalue: 0.34999999
#      action:
#        name: reject
#    #
#    # Reject all obs with PreQC mark already set above 3
#    - filter: PreQC
#      maxvalue: 3
#      action:
#        name: reject
#    #
#    # When multiple obs exist within a single vertical model level, inflate ObsError
#    - filter: BlackList
#      filter variables:
#      - name: specific_humidity
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#            test QCflag: PreQC
#            inflate variables: [specific_humidity]
#      defer to post: true
#    #
#    # If ObsError inflation factor is larger than threshold, reject obs
#    - filter: Bounds Check
#      filter variables:
#      - name: specific_humidity
#      action:
#        name: reject
#      maxvalue: 8.0
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: specific_humidity@ObsErrorData   # After inflation step
#          denominator:
#            name: specific_humidity@ObsError
#      defer to post: true
#
  #-------------------------------------------------------------------------------------------
  # AMSUA METOP-A #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: amsua_metop-a
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.amsua_metop-a.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.amsua_metop-a.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      channels: &amsua_metop-a_channels 1-15
      obs perturbations seed: 1
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      Clouds: [Water, Ice]
      Cloud_Fraction: 1.0
      obs options:
        Sensor_ID: amsua_metop-a
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &amsua_metop-a_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.amsua_metop-a.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *amsua_metop-a_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &amsua_metop-a_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.amsua_metop-a.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *amsua_metop-a_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle
    obs filters:
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-a_channels
      action:
        name: assign error
        error function:
          name: ObsErrorModelRamp@ObsFunction
          channels: *amsua_metop-a_channels
          options:
            channels: *amsua_metop-a_channels
            xvar:
              name: CLWRetSymmetricMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [ObsValue, HofX]
            x0:    [ 0.050,  0.030,  0.030,  0.020,  0.000,
                     0.100,  0.000,  0.000,  0.000,  0.000,
                     0.000,  0.000,  0.000,  0.000,  0.030]
            x1:    [ 0.600,  0.450,  0.400,  0.450,  1.000,
                     1.500,  0.000,  0.000,  0.000,  0.000,
                     0.000,  0.000,  0.000,  0.000,  0.200]
            err0:  [ 2.500,  2.200,  2.000,  0.550,  0.300,
                     0.230,  0.230,  0.250,  0.250,  0.350,
                     0.400,  0.550,  0.800,  3.000,  3.500]
            err1:  [20.000, 18.000, 12.000,  3.000,  0.500,
                     0.300,  0.230,  0.250,  0.250,  0.350,
                     0.400,  0.550,  0.800,  3.000, 18.000]
    #  CLW Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: 1-6, 15
      test variables:
      - name: CLWRetMW@ObsFunction
        options:
          clwret_ch238: 1
          clwret_ch314: 2
          clwret_types: [ObsValue]
      maxvalue: 999.0
      action:
        name: reject
    #  CLW Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: 1-6, 15
      test variables:
      - name: CLWRetMW@ObsFunction
        options:
          clwret_ch238: 1
          clwret_ch314: 2
          clwret_types: [HofX]
      maxvalue: 999.0
      action:
        name: reject
    #  Hydrometeor Check (cloud/precipitation affected chanels)
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-a_channels
      test variables:
      - name: HydrometeorCheckAMSUA@ObsFunction
        channels: *amsua_metop-a_channels
        options:
          channels: *amsua_metop-a_channels
          obserr_clearsky: [ 2.500, 2.200, 2.000, 0.550, 0.300,
                             0.230, 0.230, 0.250, 0.250, 0.350,
                             0.400, 0.550, 0.800, 3.000, 3.500]
          clwret_function:
            name: CLWRetMW@ObsFunction
            options:
              clwret_ch238: 1
              clwret_ch314: 2
              clwret_types: [ObsValue]
          obserr_function:
            name: ObsErrorModelRamp@ObsFunction
            channels: *amsua_metop-a_channels
            options:
              channels: *amsua_metop-a_channels
              xvar:
                name: CLWRetSymmetricMW@ObsFunction
                options:
                  clwret_ch238: 1
                  clwret_ch314: 2
                  clwret_types: [ObsValue, HofX]
              x0:    [ 0.050,  0.030,  0.030,  0.020,  0.000,
                       0.100,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.030]
              x1:    [ 0.600,  0.450,  0.400,  0.450,  1.000,
                       1.500,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.200]
              err0:  [ 2.500,  2.200,  2.000,  0.550,  0.300,
                       0.230,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000,  3.500]
              err1:  [20.000, 18.000, 12.000,  3.000,  0.500,
                       0.300,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000, 18.000]
      maxvalue: 0.0
      action:
        name: reject
    #  Topography check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-a_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTopoRad@ObsFunction
          channels: *amsua_metop-a_channels
          options:
            sensor: amsua_metop-a
            channels: *amsua_metop-a_channels
    #  Transmittnace Top Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-a_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTransmitTopRad@ObsFunction
          channels: *amsua_metop-a_channels
          options:
            channels: *amsua_metop-a_channels
    #  Surface Jacobian check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-a_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSurfJacobianRad@ObsFunction
          channels: *amsua_metop-a_channels
          options:
            channels: *amsua_metop-a_channels
            obserr_demisf: [0.010, 0.020, 0.015, 0.020, 0.200]
            obserr_dtempf: [0.500, 2.000, 1.000, 2.000, 4.500]
    #  Situation dependent Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-a_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSituDependMW@ObsFunction
          channels: *amsua_metop-a_channels
          options:
            sensor: amsua_metop-a
            channels: *amsua_metop-a_channels
            clwobs_function:
              name: CLWRetMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [ObsValue]
            clwbkg_function:
              name: CLWRetMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [HofX]
                bias_application: HofX
            scatobs_function:
              name: SCATRetMW@ObsFunction
              options:
                scatret_ch238: 1
                scatret_ch314: 2
                scatret_ch890: 15
                scatret_types: [ObsValue]
                bias_application: HofX
            clwmatchidx_function:
              name: CLWMatchIndexMW@ObsFunction
              channels: *amsua_metop-a_channels
              options:
                channels: *amsua_metop-a_channels
                clwobs_function:
                  name: CLWRetMW@ObsFunction
                  options:
                    clwret_ch238: 1
                    clwret_ch314: 2
                    clwret_types: [ObsValue]
                clwbkg_function:
                  name: CLWRetMW@ObsFunction
                  options:
                    clwret_ch238: 1
                    clwret_ch314: 2
                    clwret_types: [HofX]
                    bias_application: HofX
                clwret_clearsky: [0.050, 0.030, 0.030, 0.020, 0.000,
                                  0.100, 0.000, 0.000, 0.000, 0.000,
                                  0.000, 0.000, 0.000, 0.000, 0.030]
            obserr_clearsky: [2.500, 2.200, 2.000, 0.550, 0.300,
                              0.230, 0.230, 0.250, 0.250, 0.350,
                              0.400, 0.550, 0.800, 3.000, 3.500]
    #  Gross check
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-a_channels
      function absolute threshold:
      - name: ObsErrorBoundMW@ObsFunction
        channels: *amsua_metop-a_channels
        options:
          sensor: amsua_metop-a
          channels: *amsua_metop-a_channels
          obserr_bound_latitude:
            name: ObsErrorFactorLatRad@ObsFunction
            options:
              latitude_parameters: [25.0, 0.25, 0.04, 3.0]
          obserr_bound_transmittop:
            name: ObsErrorFactorTransmitTopRad@ObsFunction
            channels: *amsua_metop-a_channels
            options:
              channels: *amsua_metop-a_channels
          obserr_bound_topo:
            name: ObsErrorFactorTopoRad@ObsFunction
            channels: *amsua_metop-a_channels
            options:
              channels: *amsua_metop-a_channels
              sensor: amsua_metop-a
          obserr_function:
            name: ObsErrorModelRamp@ObsFunction
            channels: *amsua_metop-a_channels
            options:
              channels: *amsua_metop-a_channels
              xvar:
                name: CLWRetSymmetricMW@ObsFunction
                options:
                  clwret_ch238: 1
                  clwret_ch314: 2
                  clwret_types: [ObsValue, HofX]
                  bias_application: HofX
              x0:    [ 0.050,  0.030,  0.030,  0.020,  0.000,
                       0.100,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.030]
              x1:    [ 0.600,  0.450,  0.400,  0.450,  1.000,
                       1.500,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.200]
              err0:  [ 2.500,  2.200,  2.000,  0.550,  0.300,
                       0.230,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000,  3.500]
              err1:  [20.000, 18.000, 12.000,  3.000,  0.500,
                       0.300,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000, 18.000]
          obserr_bound_max: [4.5, 4.5, 4.5, 2.5, 2.0,
                             2.0, 2.0, 2.0, 2.0, 2.0,
                             2.5, 3.5, 4.5, 4.5, 4.5]
      action:
        name: reject
    #  Inter-channel check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-a_channels
      test variables:
      - name: InterChannelConsistencyCheck@ObsFunction
        channels: *amsua_metop-a_channels
        options:
          channels: *amsua_metop-a_channels
          sensor: amsua_metop-a
          use_flag: [ 1,  1,  1,  1,  1,
                      1, -1, -1,  1,  1,
                      1,  1,  1, -1,  1 ]
      maxvalue: 1.0e-12
      action:
        name: reject
    #  Useflag check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-a_channels
      test variables:
      - name: ChannelUseflagCheckRad@ObsFunction
        channels: *amsua_metop-a_channels
        options:
          channels: *amsua_metop-a_channels
          use_flag: [ 1,  1,  1,  1,  1,
                      1, -1, -1,  1,  1,
                      1,  1,  1, -1,  1 ]
      minvalue: 1.0e-12
      action:
        name: reject

  #-------------------------------------------------------------------------------------------
  # AMSUA METOP-B #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: amsua_metop-b
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.amsua_metop-b.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.amsua_metop-b.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      channels: &amsua_metop-b_channels 1-15
      obs perturbations seed: 1
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      Clouds: [Water, Ice]
      Cloud_Fraction: 1.0
      obs options:
        Sensor_ID: amsua_metop-b
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &amsua_metop-b_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.amsua_metop-b.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *amsua_metop-b_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &amsua_metop-b_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.amsua_metop-b.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *amsua_metop-b_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle
    obs filters:
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-b_channels
      action:
        name: assign error
        error function:
          name: ObsErrorModelRamp@ObsFunction
          channels: *amsua_metop-b_channels
          options:
            channels: *amsua_metop-b_channels
            xvar:
              name: CLWRetSymmetricMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [ObsValue, HofX]
            x0:    [ 0.050,  0.030,  0.030,  0.020,  0.000,
                     0.100,  0.000,  0.000,  0.000,  0.000,
                     0.000,  0.000,  0.000,  0.000,  0.030]
            x1:    [ 0.600,  0.450,  0.400,  0.450,  1.000,
                     1.500,  0.000,  0.000,  0.000,  0.000,
                     0.000,  0.000,  0.000,  0.000,  0.200]
            err0:  [ 2.500,  2.200,  2.000,  0.550,  0.300,
                     0.230,  0.230,  0.250,  0.250,  0.350,
                     0.400,  0.550,  0.800,  3.000,  3.500]
            err1:  [20.000, 18.000, 12.000,  3.000,  0.500,
                     0.300,  0.230,  0.250,  0.250,  0.350,
                     0.400,  0.550,  0.800,  3.000, 18.000]
    #  CLW Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: 1-6, 15
      test variables:
      - name: CLWRetMW@ObsFunction
        options:
          clwret_ch238: 1
          clwret_ch314: 2
          clwret_types: [ObsValue]
      maxvalue: 999.0
      action:
        name: reject
    #  CLW Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: 1-6, 15
      test variables:
      - name: CLWRetMW@ObsFunction
        options:
          clwret_ch238: 1
          clwret_ch314: 2
          clwret_types: [HofX]
      maxvalue: 999.0
      action:
        name: reject
    #  Hydrometeor Check (cloud/precipitation affected chanels)
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-b_channels
      test variables:
      - name: HydrometeorCheckAMSUA@ObsFunction
        channels: *amsua_metop-b_channels
        options:
          channels: *amsua_metop-b_channels
          obserr_clearsky: [ 2.500, 2.200, 2.000, 0.550, 0.300,
                             0.230, 0.230, 0.250, 0.250, 0.350,
                             0.400, 0.550, 0.800, 3.000, 3.500]
          clwret_function:
            name: CLWRetMW@ObsFunction
            options:
              clwret_ch238: 1
              clwret_ch314: 2
              clwret_types: [ObsValue]
          obserr_function:
            name: ObsErrorModelRamp@ObsFunction
            channels: *amsua_metop-b_channels
            options:
              channels: *amsua_metop-b_channels
              xvar:
                name: CLWRetSymmetricMW@ObsFunction
                options:
                  clwret_ch238: 1
                  clwret_ch314: 2
                  clwret_types: [ObsValue, HofX]
              x0:    [ 0.050,  0.030,  0.030,  0.020,  0.000,
                       0.100,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.030]
              x1:    [ 0.600,  0.450,  0.400,  0.450,  1.000,
                       1.500,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.200]
              err0:  [ 2.500,  2.200,  2.000,  0.550,  0.300,
                       0.230,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000,  3.500]
              err1:  [20.000, 18.000, 12.000,  3.000,  0.500,
                       0.300,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000, 18.000]
      maxvalue: 0.0
      action:
        name: reject
    #  Topography check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-b_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTopoRad@ObsFunction
          channels: *amsua_metop-b_channels
          options:
            sensor: amsua_metop-b
            channels: *amsua_metop-b_channels
    #  Transmittnace Top Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-b_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTransmitTopRad@ObsFunction
          channels: *amsua_metop-b_channels
          options:
            channels: *amsua_metop-b_channels
    #  Surface Jacobian check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-b_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSurfJacobianRad@ObsFunction
          channels: *amsua_metop-b_channels
          options:
            channels: *amsua_metop-b_channels
            obserr_demisf: [0.010, 0.020, 0.015, 0.020, 0.200]
            obserr_dtempf: [0.500, 2.000, 1.000, 2.000, 4.500]
    #  Situation dependent Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-b_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSituDependMW@ObsFunction
          channels: *amsua_metop-b_channels
          options:
            sensor: amsua_metop-b
            channels: *amsua_metop-b_channels
            clwobs_function:
              name: CLWRetMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [ObsValue]
            clwbkg_function:
              name: CLWRetMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [HofX]
                bias_application: HofX
            scatobs_function:
              name: SCATRetMW@ObsFunction
              options:
                scatret_ch238: 1
                scatret_ch314: 2
                scatret_ch890: 15
                scatret_types: [ObsValue]
                bias_application: HofX
            clwmatchidx_function:
              name: CLWMatchIndexMW@ObsFunction
              channels: *amsua_metop-b_channels
              options:
                channels: *amsua_metop-b_channels
                clwobs_function:
                  name: CLWRetMW@ObsFunction
                  options:
                    clwret_ch238: 1
                    clwret_ch314: 2
                    clwret_types: [ObsValue]
                clwbkg_function:
                  name: CLWRetMW@ObsFunction
                  options:
                    clwret_ch238: 1
                    clwret_ch314: 2
                    clwret_types: [HofX]
                    bias_application: HofX
                clwret_clearsky: [0.050, 0.030, 0.030, 0.020, 0.000,
                                  0.100, 0.000, 0.000, 0.000, 0.000,
                                  0.000, 0.000, 0.000, 0.000, 0.030]
            obserr_clearsky: [2.500, 2.200, 2.000, 0.550, 0.300,
                              0.230, 0.230, 0.250, 0.250, 0.350,
                              0.400, 0.550, 0.800, 3.000, 3.500]
    #  Gross check
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-b_channels
      function absolute threshold:
      - name: ObsErrorBoundMW@ObsFunction
        channels: *amsua_metop-b_channels
        options:
          sensor: amsua_metop-b
          channels: *amsua_metop-b_channels
          obserr_bound_latitude:
            name: ObsErrorFactorLatRad@ObsFunction
            options:
              latitude_parameters: [25.0, 0.25, 0.04, 3.0]
          obserr_bound_transmittop:
            name: ObsErrorFactorTransmitTopRad@ObsFunction
            channels: *amsua_metop-b_channels
            options:
              channels: *amsua_metop-b_channels
          obserr_bound_topo:
            name: ObsErrorFactorTopoRad@ObsFunction
            channels: *amsua_metop-b_channels
            options:
              channels: *amsua_metop-b_channels
              sensor: amsua_metop-b
          obserr_function:
            name: ObsErrorModelRamp@ObsFunction
            channels: *amsua_metop-b_channels
            options:
              channels: *amsua_metop-b_channels
              xvar:
                name: CLWRetSymmetricMW@ObsFunction
                options:
                  clwret_ch238: 1
                  clwret_ch314: 2
                  clwret_types: [ObsValue, HofX]
                  bias_application: HofX
              x0:    [ 0.050,  0.030,  0.030,  0.020,  0.000,
                       0.100,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.030]
              x1:    [ 0.600,  0.450,  0.400,  0.450,  1.000,
                       1.500,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.200]
              err0:  [ 2.500,  2.200,  2.000,  0.550,  0.300,
                       0.230,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000,  3.500]
              err1:  [20.000, 18.000, 12.000,  3.000,  0.500,
                       0.300,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000, 18.000]
          obserr_bound_max: [4.5, 4.5, 4.5, 2.5, 2.0,
                             2.0, 2.0, 2.0, 2.0, 2.0,
                             2.5, 3.5, 4.5, 4.5, 4.5]
      action:
        name: reject
    #  Inter-channel check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-b_channels
      test variables:
      - name: InterChannelConsistencyCheck@ObsFunction
        channels: *amsua_metop-b_channels
        options:
          channels: *amsua_metop-b_channels
          sensor: amsua_metop-b
          use_flag: [-1, -1, -1, -1, -1,
                     -1, -1,  1,  1,  1,
                      1,  1,  1, -1, -1]
      maxvalue: 1.0e-12
      action:
        name: reject
    #  Useflag check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-b_channels
      test variables:
      - name: ChannelUseflagCheckRad@ObsFunction
        channels: *amsua_metop-b_channels
        options:
          channels: *amsua_metop-b_channels
          use_flag: [-1, -1, -1, -1, -1,
                     -1, -1,  1,  1,  1,
                      1,  1,  1, -1, -1]
      minvalue: 1.0e-12
      action:
        name: reject

  #-------------------------------------------------------------------------------------------
  # AMSUA METOP-C #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: amsua_metop-c
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.amsua_metop-c.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.amsua_metop-c.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      channels: &amsua_metop-c_channels 1-15
      obs perturbations seed: 1
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      Clouds: [Water, Ice]
      Cloud_Fraction: 1.0
      obs options:
        Sensor_ID: amsua_metop-c
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &amsua_metop-c_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.amsua_metop-c.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *amsua_metop-c_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &amsua_metop-c_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.amsua_metop-c.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *amsua_metop-c_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle
    obs filters:
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-c_channels
      action:
        name: assign error
        error function:
          name: ObsErrorModelRamp@ObsFunction
          channels: *amsua_metop-c_channels
          options:
            channels: *amsua_metop-c_channels
            xvar:
              name: CLWRetSymmetricMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [ObsValue, HofX]
            x0:    [ 0.050,  0.030,  0.030,  0.020,  0.000,
                     0.100,  0.000,  0.000,  0.000,  0.000,
                     0.000,  0.000,  0.000,  0.000,  0.030]
            x1:    [ 0.600,  0.450,  0.400,  0.450,  1.000,
                     1.500,  0.000,  0.000,  0.000,  0.000,
                     0.000,  0.000,  0.000,  0.000,  0.200]
            err0:  [ 2.500,  2.200,  2.000,  0.550,  0.300,
                     0.230,  0.230,  0.250,  0.250,  0.350,
                     0.400,  0.550,  0.800,  3.000,  3.500]
            err1:  [20.000, 18.000, 12.000,  3.000,  0.500,
                     0.300,  0.230,  0.250,  0.250,  0.350,
                     0.400,  0.550,  0.800,  3.000, 18.000]
    #  CLW Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: 1-6, 15
      test variables:
      - name: CLWRetMW@ObsFunction
        options:
          clwret_ch238: 1
          clwret_ch314: 2
          clwret_types: [ObsValue]
      maxvalue: 999.0
      action:
        name: reject
    #  CLW Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: 1-6, 15
      test variables:
      - name: CLWRetMW@ObsFunction
        options:
          clwret_ch238: 1
          clwret_ch314: 2
          clwret_types: [HofX]
      maxvalue: 999.0
      action:
        name: reject
    #  Hydrometeor Check (cloud/precipitation affected chanels)
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-c_channels
      test variables:
      - name: HydrometeorCheckAMSUA@ObsFunction
        channels: *amsua_metop-c_channels
        options:
          channels: *amsua_metop-c_channels
          obserr_clearsky: [ 2.500, 2.200, 2.000, 0.550, 0.300,
                             0.230, 0.230, 0.250, 0.250, 0.350,
                             0.400, 0.550, 0.800, 3.000, 3.500]
          clwret_function:
            name: CLWRetMW@ObsFunction
            options:
              clwret_ch238: 1
              clwret_ch314: 2
              clwret_types: [ObsValue]
          obserr_function:
            name: ObsErrorModelRamp@ObsFunction
            channels: *amsua_metop-c_channels
            options:
              channels: *amsua_metop-c_channels
              xvar:
                name: CLWRetSymmetricMW@ObsFunction
                options:
                  clwret_ch238: 1
                  clwret_ch314: 2
                  clwret_types: [ObsValue, HofX]
              x0:    [ 0.050,  0.030,  0.030,  0.020,  0.000,
                       0.100,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.030]
              x1:    [ 0.600,  0.450,  0.400,  0.450,  1.000,
                       1.500,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.200]
              err0:  [ 2.500,  2.200,  2.000,  0.550,  0.300,
                       0.230,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000,  3.500]
              err1:  [20.000, 18.000, 12.000,  3.000,  0.500,
                       0.300,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000, 18.000]
      maxvalue: 0.0
      action:
        name: reject
    #  Topography check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-c_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTopoRad@ObsFunction
          channels: *amsua_metop-c_channels
          options:
            sensor: amsua_metop-c
            channels: *amsua_metop-c_channels
    #  Transmittnace Top Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-c_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTransmitTopRad@ObsFunction
          channels: *amsua_metop-c_channels
          options:
            channels: *amsua_metop-c_channels
    #  Surface Jacobian check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-c_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSurfJacobianRad@ObsFunction
          channels: *amsua_metop-c_channels
          options:
            channels: *amsua_metop-c_channels
            obserr_demisf: [0.010, 0.020, 0.015, 0.020, 0.200]
            obserr_dtempf: [0.500, 2.000, 1.000, 2.000, 4.500]
    #  Situation dependent Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-c_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSituDependMW@ObsFunction
          channels: *amsua_metop-c_channels
          options:
            sensor: amsua_metop-c
            channels: *amsua_metop-c_channels
            clwobs_function:
              name: CLWRetMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [ObsValue]
            clwbkg_function:
              name: CLWRetMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [HofX]
                bias_application: HofX
            scatobs_function:
              name: SCATRetMW@ObsFunction
              options:
                scatret_ch238: 1
                scatret_ch314: 2
                scatret_ch890: 15
                scatret_types: [ObsValue]
                bias_application: HofX
            clwmatchidx_function:
              name: CLWMatchIndexMW@ObsFunction
              channels: *amsua_metop-c_channels
              options:
                channels: *amsua_metop-c_channels
                clwobs_function:
                  name: CLWRetMW@ObsFunction
                  options:
                    clwret_ch238: 1
                    clwret_ch314: 2
                    clwret_types: [ObsValue]
                clwbkg_function:
                  name: CLWRetMW@ObsFunction
                  options:
                    clwret_ch238: 1
                    clwret_ch314: 2
                    clwret_types: [HofX]
                    bias_application: HofX
                clwret_clearsky: [0.050, 0.030, 0.030, 0.020, 0.000,
                                  0.100, 0.000, 0.000, 0.000, 0.000,
                                  0.000, 0.000, 0.000, 0.000, 0.030]
            obserr_clearsky: [2.500, 2.200, 2.000, 0.550, 0.300,
                              0.230, 0.230, 0.250, 0.250, 0.350,
                              0.400, 0.550, 0.800, 3.000, 3.500]
    #  Gross check
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-c_channels
      function absolute threshold:
      - name: ObsErrorBoundMW@ObsFunction
        channels: *amsua_metop-c_channels
        options:
          sensor: amsua_metop-c
          channels: *amsua_metop-c_channels
          obserr_bound_latitude:
            name: ObsErrorFactorLatRad@ObsFunction
            options:
              latitude_parameters: [25.0, 0.25, 0.04, 3.0]
          obserr_bound_transmittop:
            name: ObsErrorFactorTransmitTopRad@ObsFunction
            channels: *amsua_metop-c_channels
            options:
              channels: *amsua_metop-c_channels
          obserr_bound_topo:
            name: ObsErrorFactorTopoRad@ObsFunction
            channels: *amsua_metop-c_channels
            options:
              channels: *amsua_metop-c_channels
              sensor: amsua_metop-c
          obserr_function:
            name: ObsErrorModelRamp@ObsFunction
            channels: *amsua_metop-c_channels
            options:
              channels: *amsua_metop-c_channels
              xvar:
                name: CLWRetSymmetricMW@ObsFunction
                options:
                  clwret_ch238: 1
                  clwret_ch314: 2
                  clwret_types: [ObsValue, HofX]
                  bias_application: HofX
              x0:    [ 0.050,  0.030,  0.030,  0.020,  0.000,
                       0.100,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.030]
              x1:    [ 0.600,  0.450,  0.400,  0.450,  1.000,
                       1.500,  0.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.200]
              err0:  [ 2.500,  2.200,  2.000,  0.550,  0.300,
                       0.230,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000,  3.500]
              err1:  [20.000, 18.000, 12.000,  3.000,  0.500,
                       0.300,  0.230,  0.250,  0.250,  0.350,
                       0.400,  0.550,  0.800,  3.000, 18.000]
          obserr_bound_max: [4.5, 4.5, 4.5, 2.5, 2.0,
                             2.0, 2.0, 2.0, 2.0, 2.0,
                             2.5, 3.5, 4.5, 4.5, 4.5]
      action:
        name: reject
    #  Inter-channel check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-c_channels
      test variables:
      - name: InterChannelConsistencyCheck@ObsFunction
        channels: *amsua_metop-c_channels
        options:
          channels: *amsua_metop-c_channels
          sensor: amsua_metop-c
          use_flag: [-1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1]
      maxvalue: 1.0e-12
      action:
        name: reject
    #  Useflag check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *amsua_metop-c_channels
      test variables:
      - name: ChannelUseflagCheckRad@ObsFunction
        channels: *amsua_metop-c_channels
        options:
          channels: *amsua_metop-c_channels
          use_flag: [-1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1]
      minvalue: 1.0e-12
      action:
        name: reject

  #-------------------------------------------------------------------------------------------
  # ATMS N20 #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: atms_n20
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.atms_n20.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.atms_n20.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      channels: &atms_n20_channels 1-22
      obs perturbations seed: 1
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      Clouds: [Water, Ice]
      Cloud_Fraction: 1.0
      obs options:
        Sensor_ID: atms_n20
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &atms_n20_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.atms_n20.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *atms_n20_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &atms_n20_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.atms_n20.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *atms_n20_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle
    obs filters:
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *atms_n20_channels
      action:
        name: assign error
        error function:
          name: ObsErrorModelRamp@ObsFunction
          channels: *atms_n20_channels
          options:
            channels: *atms_n20_channels
            xvar:
              name: CLWRetSymmetricMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [ObsValue, HofX]
            x0:    [ 0.030,  0.030,  0.030,  0.020,  0.030,
                     0.080,  0.150,  0.000,  0.000,  0.000,
                     0.000,  0.000,  0.000,  0.000,  0.000,
                     0.020,  0.030,  0.030,  0.030,  0.030,
                     0.050,  0.100]
            x1:    [ 0.350,  0.380,  0.400,  0.450,  0.500,
                     1.000,  1.000,  0.000,  0.000,  0.000,
                     0.000,  0.000,  0.000,  0.000,  0.000,
                     0.350,  0.500,  0.500,  0.500,  0.500,
                     0.500,  0.500]
            err0:  [ 4.500,  4.500,  4.500,  2.500,  0.550,
                     0.300,  0.300,  0.400,  0.400,  0.400,
                     0.450,  0.450,  0.550,  0.800,  3.000,
                     4.000,  4.000,  3.500,  3.000,  3.000,
                     3.000,  3.000]
            err1:  [20.000, 25.000, 12.000,  7.000,  3.500,
                     3.000,  0.800,  0.400,  0.400,  0.400,
                     0.450,  0.450,  0.550,  0.800,  3.000,
                    19.000, 30.000, 25.000, 16.500, 12.000,
                     9.000,  6.500]
    #  CLW Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: 1-7, 16-22
      test variables:
      - name: CLWRetMW@ObsFunction
        options:
          clwret_ch238: 1
          clwret_ch314: 2
          clwret_types: [ObsValue]
      maxvalue: 999.0
      action:
        name: reject
    #  CLW Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: 1-7, 16-22
      test variables:
      - name: CLWRetMW@ObsFunction
        options:
          clwret_ch238: 1
          clwret_ch314: 2
          clwret_types: [HofX]
      maxvalue: 999.0
      action:
        name: reject
    #  Hydrometeor Check (cloud/precipitation affected chanels)
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *atms_n20_channels
      test variables:
      - name: HydrometeorCheckATMS@ObsFunction
        channels: *atms_n20_channels
        options:
          channels: *atms_n20_channels
          obserr_clearsky:  [ 4.500,  4.500,  4.500,  2.500,  0.550,
                              0.300,  0.300,  0.400,  0.400,  0.400,
                              0.450,  0.450,  0.550,  0.800,  3.000,
                              4.000,  4.000,  3.500,  3.000,  3.000,
                              3.000,  3.000]
          clwret_function:
            name: CLWRetMW@ObsFunction
            options:
              clwret_ch238: 1
              clwret_ch314: 2
              clwret_types: [ObsValue]
          obserr_function:
            name: ObsErrorModelRamp@ObsFunction
            channels: *atms_n20_channels
            options:
              channels: *atms_n20_channels
              xvar:
                name: CLWRetSymmetricMW@ObsFunction
                options:
                  clwret_ch238: 1
                  clwret_ch314: 2
                  clwret_types: [ObsValue, HofX]
              x0:    [ 0.030,  0.030,  0.030,  0.020,  0.030,
                       0.080,  0.150,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.000,
                       0.020,  0.030,  0.030,  0.030,  0.030,
                       0.050,  0.100]
              x1:    [ 0.350,  0.380,  0.400,  0.450,  0.500,
                       1.000,  1.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.000,
                       0.350,  0.500,  0.500,  0.500,  0.500,
                       0.500,  0.500]
              err0:  [ 4.500,  4.500,  4.500,  2.500,  0.550,
                       0.300,  0.300,  0.400,  0.400,  0.400,
                       0.450,  0.450,  0.550,  0.800,  3.000,
                       4.000,  4.000,  3.500,  3.000,  3.000,
                       3.000,  3.000]
              err1:  [20.000, 25.000, 12.000,  7.000,  3.500,
                      3.000,  0.800,  0.400,  0.400,  0.400,
                      0.450,  0.450,  0.550,  0.800,  3.000,
                     19.000, 30.000, 25.000, 16.500, 12.000,
                      9.000,  6.500]
      maxvalue: 0.0
      action:
        name: reject
    #  Topography check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *atms_n20_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTopoRad@ObsFunction
          channels: *atms_n20_channels
          options:
            sensor: atms_n20
            channels: *atms_n20_channels
    #  Transmittnace Top Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *atms_n20_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTransmitTopRad@ObsFunction
          channels: *atms_n20_channels
          options:
            channels: *atms_n20_channels
    #  Surface Jacobian check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *atms_n20_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSurfJacobianRad@ObsFunction
          channels: *atms_n20_channels
          options:
            channels: *atms_n20_channels
            obserr_demisf: [0.010, 0.020, 0.015, 0.020, 0.200]
            obserr_dtempf: [0.500, 2.000, 1.000, 2.000, 4.500]
    #  Situation dependent Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *atms_n20_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSituDependMW@ObsFunction
          channels: *atms_n20_channels
          options:
            sensor: atms_n20
            channels: *atms_n20_channels
            clwobs_function:
              name: CLWRetMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [ObsValue]
            clwbkg_function:
              name: CLWRetMW@ObsFunction
              options:
                clwret_ch238: 1
                clwret_ch314: 2
                clwret_types: [HofX]
            scatobs_function:
              name: SCATRetMW@ObsFunction
              options:
                scatret_ch238: 1
                scatret_ch314: 2
                scatret_ch890: 16
                scatret_types: [ObsValue]
            clwmatchidx_function:
              name: CLWMatchIndexMW@ObsFunction
              channels: *atms_n20_channels
              options:
                channels: *atms_n20_channels
                clwobs_function:
                  name: CLWRetMW@ObsFunction
                  options:
                    clwret_ch238: 1
                    clwret_ch314: 2
                    clwret_types: [ObsValue]
                clwbkg_function:
                  name: CLWRetMW@ObsFunction
                  options:
                    clwret_ch238: 1
                    clwret_ch314: 2
                    clwret_types: [HofX]
                clwret_clearsky: [ 0.030,  0.030,  0.030,  0.020,  0.030,
                                   0.080,  0.150,  0.000,  0.000,  0.000,
                                   0.000,  0.000,  0.000,  0.000,  0.000,
                                   0.020,  0.030,  0.030,  0.030,  0.030,
                                   0.050,  0.100]
            obserr_clearsky:  [ 4.500,  4.500,  4.500,  2.500,  0.550,
                                0.300,  0.300,  0.400,  0.400,  0.400,
                                0.450,  0.450,  0.550,  0.800,  3.000,
                                4.000,  4.000,  3.500,  3.000,  3.000,
                                3.000,  3.000]
    #  Gross check
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: *atms_n20_channels
      function absolute threshold:
      - name: ObsErrorBoundMW@ObsFunction
        channels: *atms_n20_channels
        options:
          sensor: atms_n20
          channels: *atms_n20_channels
          obserr_bound_latitude:
            name: ObsErrorFactorLatRad@ObsFunction
            options:
              latitude_parameters: [25.0, 0.25, 0.04, 3.0]
          obserr_bound_transmittop:
            name: ObsErrorFactorTransmitTopRad@ObsFunction
            channels: *atms_n20_channels
            options:
              channels: *atms_n20_channels
          obserr_bound_topo:
            name: ObsErrorFactorTopoRad@ObsFunction
            channels: *atms_n20_channels
            options:
              channels: *atms_n20_channels
              sensor: atms_n20
          obserr_function:
            name: ObsErrorModelRamp@ObsFunction
            channels: *atms_n20_channels
            options:
              channels: *atms_n20_channels
              xvar:
                name: CLWRetSymmetricMW@ObsFunction
                options:
                  clwret_ch238: 1
                  clwret_ch314: 2
                  clwret_types: [ObsValue, HofX]
              x0:    [ 0.030,  0.030,  0.030,  0.020,  0.030,
                       0.080,  0.150,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.000,
                       0.020,  0.030,  0.030,  0.030,  0.030,
                       0.050,  0.100]
              x1:    [ 0.350,  0.380,  0.400,  0.450,  0.500,
                       1.000,  1.000,  0.000,  0.000,  0.000,
                       0.000,  0.000,  0.000,  0.000,  0.000,
                       0.350,  0.500,  0.500,  0.500,  0.500,
                       0.500,  0.500]
              err0:  [ 4.500,  4.500,  4.500,  2.500,  0.550,
                       0.300,  0.300,  0.400,  0.400,  0.400,
                       0.450,  0.450,  0.550,  0.800,  3.000,
                       4.000,  4.000,  3.500,  3.000,  3.000,
                       3.000,  3.000]
              err1:  [20.000, 25.000, 12.000,  7.000,  3.500,
                       3.000,  0.800,  0.400,  0.400,  0.400,
                       0.450,  0.450,  0.550,  0.800,  3.000,
                      19.000, 30.000, 25.000, 16.500, 12.000,
                       9.000,  6.500]
          obserr_bound_max: [4.5, 4.5, 3.0, 3.0, 1.0,
                             1.0, 1.0, 1.0, 1.0, 1.0,
                             1.0, 1.0, 1.0, 2.0, 4.5,
                             4.5, 2.0, 2.0, 2.0, 2.0,
                             2.0, 2.0]
      action:
        name: reject
    #  Inter-channel check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *atms_n20_channels
      test variables:
      - name: InterChannelConsistencyCheck@ObsFunction
        channels: *atms_n20_channels
        options:
          channels: *atms_n20_channels
          sensor: atms_n20
          use_flag: [ 1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1,
                      1,  1,  1,  1, -1,
                      1,  1,  1,  1,  1,
                      1,  1]
      maxvalue: 1.0e-12
      action:
        name: reject
    #  Useflag check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *atms_n20_channels
      test variables:
      - name: ChannelUseflagCheckRad@ObsFunction
        channels: *atms_n20_channels
        options:
          channels: *atms_n20_channels
          use_flag: [ 1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1,
                      1,  1,  1,  1, -1,
                      1,  1,  1,  1,  1,
                      1,  1]
      minvalue: 1.0e-12
      action:
        name: reject

  #-------------------------------------------------------------------------------------------
  # CRIS FSR N20 #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: cris-fsr_n20
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.cris-fsr_n20.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.cris-fsr_n20.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      obs perturbations seed: 1
      channels: &cris-fsr_n20_channels 19, 24, 26, 27, 28, 31, 32, 33, 37, 39, 42, 44, 47, 49, 50,
                                       51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68,
                                       69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86,
                                       87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103,
                                       104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117,
                                       118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131,
                                       132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145,
                                       146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
                                       160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173,
                                       174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187,
                                       188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 208,
                                       211, 216, 224, 234, 236, 238, 239, 242, 246, 248, 255, 264, 266, 268,
                                       275, 279, 283, 285, 291, 295, 301, 305, 311, 332, 342, 389, 400, 402,
                                       404, 406, 410, 427, 439, 440, 441, 445, 449, 455, 458, 461, 464, 467,
                                       470, 473, 475, 482, 486, 487, 490, 493, 496, 499, 501, 503, 505, 511,
                                       513, 514, 518, 519, 520, 522, 529, 534, 563, 568, 575, 592, 594, 596,
                                       598, 600, 602, 604, 611, 614, 616, 618, 620, 622, 626, 631, 638, 646,
                                       648, 652, 659, 673, 675, 678, 684, 688, 694, 700, 707, 710, 713, 714,
                                       718, 720, 722, 725, 728, 735, 742, 748, 753, 762, 780, 784, 798, 849,
                                       860, 862, 866, 874, 882, 890, 898, 906, 907, 908, 914, 937, 972, 973,
                                       978, 980, 981, 988, 995, 998, 1000, 1003, 1008, 1009, 1010, 1014, 1017,
                                       1018, 1020, 1022, 1024, 1026, 1029, 1030, 1032, 1034, 1037, 1038, 1041,
                                       1042, 1044, 1046, 1049, 1050, 1053, 1054, 1058, 1060, 1062, 1064, 1066,
                                       1069, 1076, 1077, 1080, 1086, 1091, 1095, 1101, 1109, 1112, 1121, 1128,
                                       1133, 1163, 1172, 1187, 1189, 1205, 1211, 1219, 1231, 1245, 1271, 1289,
                                       1300, 1313, 1316, 1325, 1329, 1346, 1347, 1473, 1474, 1491, 1499, 1553,
                                       1570, 1596, 1602, 1619, 1624, 1635, 1939, 1940, 1941, 1942, 1943, 1944,
                                       1945, 1946, 1947, 1948, 1949, 1950, 1951, 1952, 1953, 1954, 1955, 1956,
                                       1957, 1958, 1959, 1960, 1961, 1962, 1963, 1964, 1965, 1966, 1967, 1968,
                                       1969, 1970, 1971, 1972, 1973, 1974, 1975, 1976, 1977, 1978, 1979, 1980,
                                       1981, 1982, 1983, 1984, 1985, 1986, 1987, 2119, 2140, 2143, 2147, 2153,
                                       2158, 2161, 2168, 2171, 2175, 2182
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: cris-fsr_n20
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &cris-fsr_n20_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.cris-fsr_n20.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *cris-fsr_n20_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse:  &cris-fsr_n20_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.cris-fsr_n20.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *cris-fsr_n20_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle
    obs filters:
    #  Wavenumber Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: 1972, 1973, 1974, 1975, 1976, 1977, 1978, 1979, 1980, 1981,
                  1982, 1983, 1984, 1985, 1986, 1987, 2119, 2140, 2143, 2147,
                  2153, 2158, 2161, 2168, 2171, 2175, 2182
      where:
      - variable:
          name: solar_zenith_angle@MetaData
        maxvalue: 88.9999
      - variable:
          name: water_area_fraction@GeoVaLs
        minvalue: 1.0e-12
      action:
        name: reject
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorWavenumIR@ObsFunction
          channels: *cris-fsr_n20_channels
          options:
            channels: *cris-fsr_n20_channels
    #  Observation Range Sanity Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      minvalue: 50.00001
      maxvalue: 449.99999
      action:
        name: reject
    #  Topography Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTopoRad@ObsFunction
          channels: *cris-fsr_n20_channels
          options:
            channels: *cris-fsr_n20_channels
            sensor: cris-fsr_n20
    #  Transmittance Top Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTransmitTopRad@ObsFunction
          channels: *cris-fsr_n20_channels
          options:
            channels: *cris-fsr_n20_channels
    #  Cloud Detection Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      test variables:
      - name: CloudDetectMinResidualIR@ObsFunction
        channels: *cris-fsr_n20_channels
        options:
          channels: *cris-fsr_n20_channels
          use_flag: [ -1,  1,  1, -1,  1, -1,  1, -1,  1,  1,
                       1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1, -1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1, -1, -1,  1, -1, -1,
                      -1,  1, -1, -1, -1,  1, -1, -1, -1,  1,
                      -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                      -1,  1, -1, -1,  1, -1, -1, -1,  1, -1,
                      -1,  1, -1, -1,  1, -1,  1, -1,  1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                       1,  1, -1, -1,  1, -1, -1, -1,  1,  1,
                       1,  1, -1, -1, -1, -1,  1,  1, -1, -1,
                      -1, -1, -1, -1, -1, -1,  1, -1, -1, -1,
                      -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1,  1,  1, -1, -1, -1, -1, -1, -1, -1,
                       1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1,  1,  1, -1, -1, -1, -1, -1,  1,
                      -1, -1, -1, -1, -1, -1,  1, -1, -1, -1,
                       1, -1, -1, -1, -1, -1, -1,  1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1,  1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1]
          use_flag_clddet: [ -1,  1, -1, -1, -1, -1,  1, -1,  1, -1,
                              1, -1,  1, -1, -1,  1, -1, -1, -1,  1,
                             -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                             -1,  1, -1, -1, -1,  1, -1, -1, -1,  1,
                             -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                             -1,  1, -1, -1, -1,  1, -1, -1, -1,  1,
                             -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                             -1,  1, -1, -1, -1,  1, -1, -1, -1,  1,
                             -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                             -1,  1, -1, -1, -1,  1, -1, -1, -1,  1,
                             -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                             -1,  1, -1, -1, -1,  1, -1, -1, -1,  1,
                             -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                             -1,  1, -1, -1, -1,  1, -1, -1, -1,  1,
                             -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                             -1,  1, -1, -1,  1, -1, -1, -1,  1, -1,
                             -1,  1, -1, -1,  1, -1,  1, -1,  1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                              1,  1, -1, -1, -1, -1,  1,  1, -1, -1,
                             -1, -1, -1, -1, -1, -1,  1, -1, -1, -1,
                             -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1,  1,  1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                             -1]
          obserr_dtempf: [0.50,2.00,4.00,2.00,4.00]
      maxvalue: 1.0e-12
      action:
        name: reject
    # Surface Temperature Jacobian Check over Land
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      where:
      - variable:
          name: water_area_fraction@GeoVaLs
        maxvalue: 0.99
      test variables:
      - name: brightness_temperature_jacobian_surface_temperature@ObsDiag
        channels: *cris-fsr_n20_channels
      maxvalue: 0.2
    #  NSST Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      test variables:
      - name: NearSSTRetCheckIR@ObsFunction
        channels: *cris-fsr_n20_channels
        options:
          channels: *cris-fsr_n20_channels
          use_flag: [ -1,  1,  1, -1,  1, -1,  1, -1,  1,  1,
                       1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1, -1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1, -1, -1,  1, -1, -1,
                      -1,  1, -1, -1, -1,  1, -1, -1, -1,  1,
                      -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                      -1,  1, -1, -1,  1, -1, -1, -1,  1, -1,
                      -1,  1, -1, -1,  1, -1,  1, -1,  1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                       1,  1, -1, -1,  1, -1, -1, -1,  1,  1,
                       1,  1, -1, -1, -1, -1,  1,  1, -1, -1,
                      -1, -1, -1, -1, -1, -1,  1, -1, -1, -1,
                      -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1,  1,  1, -1, -1, -1, -1, -1, -1, -1,
                       1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1,  1,  1, -1, -1, -1, -1, -1,  1,
                      -1, -1, -1, -1, -1, -1,  1, -1, -1, -1,
                       1, -1, -1, -1, -1, -1, -1,  1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1,  1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1 ]
          obserr_demisf: [0.01,0.02,0.03,0.02,0.03]
          obserr_dtempf: [0.50,2.00,4.00,2.00,4.00]
      maxvalue: 1.0e-12
      action:
        name: reject
    #  Surface Jacobians Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSurfJacobianRad@ObsFunction
          channels: *cris-fsr_n20_channels
          options:
            channels: *cris-fsr_n20_channels
            obserr_demisf: [0.01, 0.02, 0.03, 0.02, 0.03]
            obserr_dtempf: [0.50, 2.00, 4.00, 2.00, 4.00]
    #  Gross check
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      function absolute threshold:
      - name: ObsErrorBoundIR@ObsFunction
        channels: *cris-fsr_n20_channels
        options:
          channels: *cris-fsr_n20_channels
          obserr_bound_latitude:
            name: ObsErrorFactorLatRad@ObsFunction
            options:
              latitude_parameters: [25.0, 0.5, 0.04, 1.0]
          obserr_bound_transmittop:
            name: ObsErrorFactorTransmitTopRad@ObsFunction
            channels: *cris-fsr_n20_channels
            options:
              channels: *cris-fsr_n20_channels
          obserr_bound_max: [ 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0 ]
      action:
        name: reject
    #  Useflag Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *cris-fsr_n20_channels
      test variables:
      - name: ChannelUseflagCheckRad@ObsFunction
        channels: *cris-fsr_n20_channels
        options:
          channels: *cris-fsr_n20_channels
          use_flag: [ -1,  1,  1, -1,  1, -1,  1, -1,  1,  1,
                       1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1, -1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1,  1, -1,  1, -1,  1,
                      -1,  1, -1,  1, -1, -1, -1,  1, -1, -1,
                      -1,  1, -1, -1, -1,  1, -1, -1, -1,  1,
                      -1, -1, -1,  1, -1, -1, -1,  1, -1, -1,
                      -1,  1, -1, -1,  1, -1, -1, -1,  1, -1,
                      -1,  1, -1, -1,  1, -1,  1, -1,  1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                       1,  1, -1, -1,  1, -1, -1, -1,  1,  1,
                       1,  1, -1, -1, -1, -1,  1,  1, -1, -1,
                      -1, -1, -1, -1, -1, -1,  1, -1, -1, -1,
                      -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1,  1,  1, -1, -1, -1, -1, -1, -1, -1,
                       1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1,  1,  1, -1, -1, -1, -1, -1,  1,
                      -1, -1, -1, -1, -1, -1,  1, -1, -1, -1,
                       1, -1, -1, -1, -1, -1, -1,  1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1,  1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                      -1 ]
      minvalue: 1.0e-12
      action:
        name: reject

  #-------------------------------------------------------------------------------------------
  # IASI METOP-A #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: iasi_metop-a
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.iasi_metop-a.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.iasi_metop-a.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      obs perturbations seed: 1
      channels: &iasi_metop-a_channels 16, 29, 32, 35, 38, 41, 44, 47, 49, 50, 51, 53,
                                       55, 56, 57, 59, 61, 62, 63, 66, 68, 70, 72, 74, 76, 78, 79, 81, 82, 83,
                                       84, 85, 86, 87, 89, 92, 93, 95, 97, 99, 101, 103, 104, 106, 109, 110,
                                       111, 113, 116, 119, 122, 125, 128, 131, 133, 135, 138, 141, 144, 146,
                                       148, 150, 151, 154, 157, 159, 160, 161, 163, 167, 170, 173, 176, 179,
                                       180, 185, 187, 191, 193, 197, 199, 200, 202, 203, 205, 207, 210, 212,
                                       213, 214, 217, 218, 219, 222, 224, 225, 226, 228, 230, 231, 232, 236,
                                       237, 239, 243, 246, 249, 252, 254, 259, 260, 262, 265, 267, 269, 275,
                                       279, 282, 285, 294, 296, 299, 300, 303, 306, 309, 313, 320, 323, 326,
                                       327, 329, 332, 335, 345, 347, 350, 354, 356, 360, 363, 366, 371, 372,
                                       373, 375, 377, 379, 381, 383, 386, 389, 398, 401, 404, 405, 407, 408,
                                       410, 411, 414, 416, 418, 423, 426, 428, 432, 433, 434, 439, 442, 445,
                                       450, 457, 459, 472, 477, 483, 509, 515, 546, 552, 559, 566, 571, 573,
                                       578, 584, 594, 625, 646, 662, 668, 705, 739, 756, 797, 867, 906, 921,
                                       1027, 1046, 1090, 1098, 1121, 1133, 1173, 1191, 1194, 1222, 1271, 1283,
                                       1338, 1409, 1414, 1420, 1424, 1427, 1430, 1434, 1440, 1442, 1445, 1450,
                                       1454, 1460, 1463, 1469, 1474, 1479, 1483, 1487, 1494, 1496, 1502, 1505,
                                       1509, 1510, 1513, 1518, 1521, 1526, 1529, 1532, 1536, 1537, 1541, 1545,
                                       1548, 1553, 1560, 1568, 1574, 1579, 1583, 1585, 1587, 1606, 1626, 1639,
                                       1643, 1652, 1658, 1659, 1666, 1671, 1675, 1681, 1694, 1697, 1710, 1786,
                                       1791, 1805, 1839, 1884, 1913, 1946, 1947, 1991, 2019, 2094, 2119, 2213,
                                       2239, 2271, 2289, 2321, 2333, 2346, 2349, 2352, 2359, 2367, 2374, 2398,
                                       2426, 2562, 2701, 2741, 2745, 2760, 2819, 2889, 2907, 2910, 2919, 2921,
                                       2939, 2944, 2945, 2948, 2951, 2958, 2971, 2977, 2985, 2988, 2990, 2991,
                                       2993, 3002, 3008, 3014, 3027, 3029, 3030, 3036, 3047, 3049, 3052, 3053,
                                       3055, 3058, 3064, 3069, 3087, 3093, 3098, 3105, 3107, 3110, 3116, 3127,
                                       3129, 3136, 3146, 3151, 3160, 3165, 3168, 3175, 3178, 3189, 3207, 3228,
                                       3244, 3248, 3252, 3256, 3263, 3281, 3295, 3303, 3309, 3312, 3322, 3326,
                                       3354, 3366, 3375, 3378, 3411, 3416, 3432, 3438, 3440, 3442, 3444, 3446,
                                       3448, 3450, 3452, 3454, 3458, 3467, 3476, 3484, 3491, 3497, 3499, 3504,
                                       3506, 3509, 3518, 3527, 3555, 3575, 3577, 3580, 3582, 3586, 3589, 3599,
                                       3610, 3626, 3638, 3646, 3653, 3658, 3661, 3673, 3689, 3700, 3710, 3726,
                                       3763, 3814, 3841, 3888, 4032, 4059, 4068, 4082, 4095, 4160, 4234, 4257,
                                       4411, 4498, 4520, 4552, 4567, 4608, 4646, 4698, 4808, 4849, 4920, 4939,
                                       4947, 4967, 4991, 4996, 5015, 5028, 5056, 5128, 5130, 5144, 5170, 5178,
                                       5183, 5188, 5191, 5368, 5371, 5379, 5381, 5383, 5397, 5399, 5401, 5403,
                                       5405, 5446, 5455, 5472, 5480, 5483, 5485, 5492, 5497, 5502, 5507, 5509,
                                       5517, 5528, 5558, 5697, 5714, 5749, 5766, 5785, 5798, 5799, 5801, 5817,
                                       5833, 5834, 5836, 5849, 5851, 5852, 5865, 5869, 5881, 5884, 5897, 5900,
                                       5916, 5932, 5948, 5963, 5968, 5978, 5988, 5992, 5994, 5997, 6003, 6008,
                                       6023, 6026, 6039, 6053, 6056, 6067, 6071, 6082, 6085, 6098, 6112, 6126,
                                       6135, 6140, 6149, 6154, 6158, 6161, 6168, 6174, 6182, 6187, 6205, 6209,
                                       6213, 6317, 6339, 6342, 6366, 6381, 6391, 6489, 6962, 6966, 6970, 6975,
                                       6977, 6982, 6985, 6987, 6989, 6991, 6993, 6995, 6997, 6999, 7000, 7004,
                                       7008, 7013, 7016, 7021, 7024, 7027, 7029, 7032, 7038, 7043, 7046, 7049,
                                       7069, 7072, 7076, 7081, 7084, 7089, 7099, 7209, 7222, 7231, 7235, 7247,
                                       7267, 7269, 7284, 7389, 7419, 7423, 7424, 7426, 7428, 7431, 7436, 7444,
                                       7475, 7549, 7584, 7665, 7666, 7831, 7836, 7853, 7865, 7885, 7888, 7912,
                                       7950, 7972, 7980, 7995, 8007, 8015, 8055, 8078
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: iasi_metop-a
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &iasi_metop-a_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.iasi_metop-a.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *iasi_metop-a_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0

      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &iasi_metop-a_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.iasi_metop-a.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *iasi_metop-a_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle
    obs filters:
    #  Wavenumber Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: 7024, 7027, 7029, 7032, 7038, 7043, 7046, 7049, 7069, 7072,
                  7076, 7081, 7084, 7089, 7099, 7209, 7222, 7231, 7235, 7247,
                  7267, 7269, 7284, 7389, 7419, 7423, 7424, 7426, 7428, 7431,
                  7436, 7444, 7475, 7549, 7584, 7665, 7666, 7831, 7836, 7853,
                  7865, 7885, 7888, 7912, 7950, 7972, 7980, 7995, 8007, 8015,
                  8055, 8078
      where:
      - variable:
          name: solar_zenith_angle@MetaData
        maxvalue: 88.9999
      - variable:
          name: water_area_fraction@GeoVaLs
        minvalue: 1.0e-12
      action:
        name: reject
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-a_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorWavenumIR@ObsFunction
          channels: *iasi_metop-a_channels
          options:
            channels: *iasi_metop-a_channels
    #  Observation Range Sanity Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-a_channels
      minvalue: 50.00001
      maxvalue: 449.99999
      action:
        name: reject
    #  Topography Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-a_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTopoRad@ObsFunction
          channels: *iasi_metop-a_channels
          options:
            channels: *iasi_metop-a_channels
            sensor: iasi_metop-a
    #  Transmittance Top Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-a_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTransmitTopRad@ObsFunction
          channels: *iasi_metop-a_channels
          options:
            channels: *iasi_metop-a_channels
    #  Cloud Detection Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-a_channels
      test variables:
      - name: CloudDetectMinResidualIR@ObsFunction
        channels: *iasi_metop-a_channels
        options:
          channels: *iasi_metop-a_channels
          use_flag: [ 1, -1, -1, -1,  1, -1, -1, -1,  1, -1,
                      1, -1,  1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1,  1,  1, -1, -1,  1,  1, -1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1,  1, -1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
                      1, -1,  1,  1,  1,  1, -1,  1,  1,  1,
                      1,  1,  1, -1,  1,  1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1,  1,  1,  1, -1,  1,
                      1, -1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1, -1,
                      1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                      1,  1, -1,  1,  1, -1, -1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1,  1,
                     -1,  1,  1, -1,  1,  1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1, -1, -1, -1,
                      1,  1,  1, -1, -1,  1, -1,  1,  1,  1,
                      1,  1, -1, -1,  1,  1, -1,  1,  1, -1,
                      1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1, -1,  1,  1, -1,  1,  1,
                      1,  1,  1, -1, -1,  1, -1, -1, -1, -1,
                     -1,  1, -1,  1, -1,  1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1,  1, -1, -1,
                     -1, -1, -1, -1, -1,  1, -1, -1,  1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                      1,  1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1,  1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1]
          use_flag_clddet: [ 1, -1, -1, -1,  1, -1, -1, -1,  1, -1,
                             1, -1,  1, -1,  1,  1,  1, -1,  1,  1,
                            -1,  1,  1,  1, -1, -1,  1,  1, -1,  1,
                            -1,  1, -1,  1, -1, -1, -1, -1, -1, -1,
                            -1, -1,  1,  1,  1, -1,  1,  1,  1,  1,
                             1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
                             1, -1,  1,  1,  1,  1, -1,  1,  1,  1,
                             1,  1,  1, -1,  1,  1,  1, -1,  1, -1,
                             1, -1, -1, -1,  1,  1,  1,  1, -1,  1,
                             1, -1,  1,  1,  1, -1,  1, -1,  1, -1,
                             1,  1, -1,  1,  1,  1,  1,  1,  1, -1,
                             1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                             1,  1, -1,  1,  1, -1, -1, -1,  1, -1,
                             1,  1, -1,  1,  1,  1,  1,  1,  1,  1,
                            -1,  1,  1, -1,  1,  1,  1,  1,  1,  1,
                             1,  1,  1,  1,  1, -1,  1, -1,  1, -1,
                             1,  1, -1, -1,  1,  1,  1, -1,  1,  1,
                            -1,  1, -1,  1, -1, -1, -1, -1, -1,  1,
                             1,  1,  1,  1,  1,  1, -1, -1, -1, -1,
                             1,  1,  1, -1, -1,  1, -1,  1,  1,  1,
                             1,  1, -1, -1,  1,  1, -1,  1,  1, -1,
                             1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1,  1, -1,  1, -1,  1, -1, -1, -1,  1,
                             1,  1,  1,  1,  1,  1, -1,  1, -1, -1,
                            -1, -1, -1, -1, -1,  1, -1, -1,  1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1]
          obserr_dtempf: [0.50,2.00,4.00,2.00,4.00]
      maxvalue: 1.0e-12
      action:
        name: reject
    #  NSST Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-a_channels
      test variables:
      - name: NearSSTRetCheckIR@ObsFunction
        channels: *iasi_metop-a_channels
        options:
          channels: *iasi_metop-a_channels
          use_flag: [ 1, -1, -1, -1,  1, -1, -1, -1,  1, -1,
                      1, -1,  1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1,  1,  1, -1, -1,  1,  1, -1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1,  1, -1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
                      1, -1,  1,  1,  1,  1, -1,  1,  1,  1,
                      1,  1,  1, -1,  1,  1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1,  1,  1,  1, -1,  1,
                      1, -1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1, -1,
                      1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                      1,  1, -1,  1,  1, -1, -1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1,  1,
                     -1,  1,  1, -1,  1,  1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1, -1, -1, -1,
                      1,  1,  1, -1, -1,  1, -1,  1,  1,  1,
                      1,  1, -1, -1,  1,  1, -1,  1,  1, -1,
                      1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1, -1,  1,  1, -1,  1,  1,
                      1,  1,  1, -1, -1,  1, -1, -1, -1, -1,
                     -1,  1, -1,  1, -1,  1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1,  1, -1, -1,
                     -1, -1, -1, -1, -1,  1, -1, -1,  1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                      1,  1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1,  1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1]
          obserr_demisf: [0.01,0.02,0.03,0.02,0.03]
          obserr_dtempf: [0.50,2.00,4.00,2.00,4.00]
      maxvalue: 1.0e-12
      action:
        name: reject
    #  Surface Jacobians Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-a_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSurfJacobianRad@ObsFunction
          channels: *iasi_metop-a_channels
          options:
            channels: *iasi_metop-a_channels
            obserr_demisf: [0.01, 0.02, 0.03, 0.02, 0.03]
            obserr_dtempf: [0.50, 2.00, 4.00, 2.00, 4.00]
    #  Gross check
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-a_channels
      function absolute threshold:
      - name: ObsErrorBoundIR@ObsFunction
        channels: *iasi_metop-a_channels
        options:
          channels: *iasi_metop-a_channels
          obserr_bound_latitude:
            name: ObsErrorFactorLatRad@ObsFunction
            options:
              latitude_parameters: [25.0, 0.5, 0.04, 1.0]
          obserr_bound_transmittop:
            name: ObsErrorFactorTransmitTopRad@ObsFunction
            channels: *iasi_metop-a_channels
            options:
              channels: *iasi_metop-a_channels
          obserr_bound_max: [ 3.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 4.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0, 4.0,
                              3.5, 2.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              3.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 3.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.5, 2.0, 2.5, 2.5, 3.0, 2.5,
                              2.5, 2.5, 2.5, 3.5, 2.5, 2.5, 3.0, 3.5, 3.0, 4.0,
                              4.0, 4.0, 4.0, 4.0, 4.0, 4.5, 4.5, 4.5, 4.5, 4.5,
                              4.0, 4.5, 4.0, 4.0, 4.5, 2.5, 3.0, 2.5, 3.0, 2.5,
                              3.0, 2.0, 2.5, 2.5, 3.0, 3.0, 2.5, 3.0, 3.0, 3.0,
                              2.5, 2.5, 4.0, 4.5, 4.5, 5.0, 4.0, 4.0, 5.0, 5.0,
                              5.0, 5.0, 5.5, 5.5, 4.0, 5.0, 4.0, 4.5, 5.5, 5.5,
                              6.0, 4.5, 4.5, 4.0, 5.0, 5.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 5.5, 4.5, 6.0,
                              5.0, 5.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 5.0, 6.0,
                              6.0, 6.0, 4.0, 6.0, 6.0, 6.0, 6.0, 4.5, 6.0, 6.0,
                              4.5, 6.0, 6.0, 6.0, 6.0, 6.0, 5.0, 6.0, 6.0, 6.0,
                              5.0, 6.0, 6.0, 5.0, 6.0, 5.0, 6.0, 6.0, 6.0, 5.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0]
      action:
        name: reject
    #  Useflag Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-a_channels
      test variables:
      - name: ChannelUseflagCheckRad@ObsFunction
        channels: *iasi_metop-a_channels
        options:
          channels: *iasi_metop-a_channels
          use_flag: [ 1, -1, -1, -1,  1, -1, -1, -1,  1, -1,
                      1, -1,  1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1,  1,  1, -1, -1,  1,  1, -1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1,  1, -1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
                      1, -1,  1,  1,  1,  1, -1,  1,  1,  1,
                      1,  1,  1, -1,  1,  1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1,  1,  1,  1, -1,  1,
                      1, -1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1, -1,
                      1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                      1,  1, -1,  1,  1, -1, -1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1,  1,
                     -1,  1,  1, -1,  1,  1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1, -1, -1, -1,
                      1,  1,  1, -1, -1,  1, -1,  1,  1,  1,
                      1,  1, -1, -1,  1,  1, -1,  1,  1, -1,
                      1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1, -1,  1,  1, -1,  1,  1,
                      1,  1,  1, -1, -1,  1, -1, -1, -1, -1,
                     -1,  1, -1,  1, -1,  1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1,  1, -1, -1,
                     -1, -1, -1, -1, -1,  1, -1, -1,  1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                      1,  1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1,  1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1]
      minvalue: 1.0e-12
      action:
        name: reject

  #-------------------------------------------------------------------------------------------
  # IASI METOP-B #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: iasi_metop-b
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.iasi_metop-b.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.iasi_metop-b.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      obs perturbations seed: 1
      channels: &iasi_metop-b_channels 16, 29, 32, 35, 38, 41, 44, 47, 49, 50, 51, 53,
                                       55, 56, 57, 59, 61, 62, 63, 66, 68, 70, 72, 74, 76, 78, 79, 81, 82, 83,
                                       84, 85, 86, 87, 89, 92, 93, 95, 97, 99, 101, 103, 104, 106, 109, 110,
                                       111, 113, 116, 119, 122, 125, 128, 131, 133, 135, 138, 141, 144, 146,
                                       148, 150, 151, 154, 157, 159, 160, 161, 163, 167, 170, 173, 176, 179,
                                       180, 185, 187, 191, 193, 197, 199, 200, 202, 203, 205, 207, 210, 212,
                                       213, 214, 217, 218, 219, 222, 224, 225, 226, 228, 230, 231, 232, 236,
                                       237, 239, 243, 246, 249, 252, 254, 259, 260, 262, 265, 267, 269, 275,
                                       279, 282, 285, 294, 296, 299, 300, 303, 306, 309, 313, 320, 323, 326,
                                       327, 329, 332, 335, 345, 347, 350, 354, 356, 360, 363, 366, 371, 372,
                                       373, 375, 377, 379, 381, 383, 386, 389, 398, 401, 404, 405, 407, 408,
                                       410, 411, 414, 416, 418, 423, 426, 428, 432, 433, 434, 439, 442, 445,
                                       450, 457, 459, 472, 477, 483, 509, 515, 546, 552, 559, 566, 571, 573,
                                       578, 584, 594, 625, 646, 662, 668, 705, 739, 756, 797, 867, 906, 921,
                                       1027, 1046, 1090, 1098, 1121, 1133, 1173, 1191, 1194, 1222, 1271, 1283,
                                       1338, 1409, 1414, 1420, 1424, 1427, 1430, 1434, 1440, 1442, 1445, 1450,
                                       1454, 1460, 1463, 1469, 1474, 1479, 1483, 1487, 1494, 1496, 1502, 1505,
                                       1509, 1510, 1513, 1518, 1521, 1526, 1529, 1532, 1536, 1537, 1541, 1545,
                                       1548, 1553, 1560, 1568, 1574, 1579, 1583, 1585, 1587, 1606, 1626, 1639,
                                       1643, 1652, 1658, 1659, 1666, 1671, 1675, 1681, 1694, 1697, 1710, 1786,
                                       1791, 1805, 1839, 1884, 1913, 1946, 1947, 1991, 2019, 2094, 2119, 2213,
                                       2239, 2271, 2289, 2321, 2333, 2346, 2349, 2352, 2359, 2367, 2374, 2398,
                                       2426, 2562, 2701, 2741, 2745, 2760, 2819, 2889, 2907, 2910, 2919, 2921,
                                       2939, 2944, 2945, 2948, 2951, 2958, 2971, 2977, 2985, 2988, 2990, 2991,
                                       2993, 3002, 3008, 3014, 3027, 3029, 3030, 3036, 3047, 3049, 3052, 3053,
                                       3055, 3058, 3064, 3069, 3087, 3093, 3098, 3105, 3107, 3110, 3116, 3127,
                                       3129, 3136, 3146, 3151, 3160, 3165, 3168, 3175, 3178, 3189, 3207, 3228,
                                       3244, 3248, 3252, 3256, 3263, 3281, 3295, 3303, 3309, 3312, 3322, 3326,
                                       3354, 3366, 3375, 3378, 3411, 3416, 3432, 3438, 3440, 3442, 3444, 3446,
                                       3448, 3450, 3452, 3454, 3458, 3467, 3476, 3484, 3491, 3497, 3499, 3504,
                                       3506, 3509, 3518, 3527, 3555, 3575, 3577, 3580, 3582, 3586, 3589, 3599,
                                       3610, 3626, 3638, 3646, 3653, 3658, 3661, 3673, 3689, 3700, 3710, 3726,
                                       3763, 3814, 3841, 3888, 4032, 4059, 4068, 4082, 4095, 4160, 4234, 4257,
                                       4411, 4498, 4520, 4552, 4567, 4608, 4646, 4698, 4808, 4849, 4920, 4939,
                                       4947, 4967, 4991, 4996, 5015, 5028, 5056, 5128, 5130, 5144, 5170, 5178,
                                       5183, 5188, 5191, 5368, 5371, 5379, 5381, 5383, 5397, 5399, 5401, 5403,
                                       5405, 5446, 5455, 5472, 5480, 5483, 5485, 5492, 5497, 5502, 5507, 5509,
                                       5517, 5528, 5558, 5697, 5714, 5749, 5766, 5785, 5798, 5799, 5801, 5817,
                                       5833, 5834, 5836, 5849, 5851, 5852, 5865, 5869, 5881, 5884, 5897, 5900,
                                       5916, 5932, 5948, 5963, 5968, 5978, 5988, 5992, 5994, 5997, 6003, 6008,
                                       6023, 6026, 6039, 6053, 6056, 6067, 6071, 6082, 6085, 6098, 6112, 6126,
                                       6135, 6140, 6149, 6154, 6158, 6161, 6168, 6174, 6182, 6187, 6205, 6209,
                                       6213, 6317, 6339, 6342, 6366, 6381, 6391, 6489, 6962, 6966, 6970, 6975,
                                       6977, 6982, 6985, 6987, 6989, 6991, 6993, 6995, 6997, 6999, 7000, 7004,
                                       7008, 7013, 7016, 7021, 7024, 7027, 7029, 7032, 7038, 7043, 7046, 7049,
                                       7069, 7072, 7076, 7081, 7084, 7089, 7099, 7209, 7222, 7231, 7235, 7247,
                                       7267, 7269, 7284, 7389, 7419, 7423, 7424, 7426, 7428, 7431, 7436, 7444,
                                       7475, 7549, 7584, 7665, 7666, 7831, 7836, 7853, 7865, 7885, 7888, 7912,
                                       7950, 7972, 7980, 7995, 8007, 8015, 8055, 8078
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: iasi_metop-b
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &iasi_metop-b_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.iasi_metop-b.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *iasi_metop-b_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &iasi_metop-b_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.iasi_metop-b.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *iasi_metop-b_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle
    obs filters:
    #  Wavenumber Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: 7024, 7027, 7029, 7032, 7038, 7043, 7046, 7049, 7069, 7072,
                  7076, 7081, 7084, 7089, 7099, 7209, 7222, 7231, 7235, 7247,
                  7267, 7269, 7284, 7389, 7419, 7423, 7424, 7426, 7428, 7431,
                  7436, 7444, 7475, 7549, 7584, 7665, 7666, 7831, 7836, 7853,
                  7865, 7885, 7888, 7912, 7950, 7972, 7980, 7995, 8007, 8015,
                  8055, 8078
      where:
      - variable:
          name: solar_zenith_angle@MetaData
        maxvalue: 88.9999
      - variable:
          name: water_area_fraction@GeoVaLs
        minvalue: 1.0e-12
      action:
        name: reject
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-b_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorWavenumIR@ObsFunction
          channels: *iasi_metop-b_channels
          options:
            channels: *iasi_metop-b_channels
    #  Observation Range Sanity Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-b_channels
      minvalue: 50.00001
      maxvalue: 449.99999
      action:
        name: reject
    #  Topography Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-b_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTopoRad@ObsFunction
          channels: *iasi_metop-b_channels
          options:
            channels: *iasi_metop-b_channels
            sensor: iasi_metop-b
    #  Transmittance Top Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-b_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorTransmitTopRad@ObsFunction
          channels: *iasi_metop-b_channels
          options:
            channels: *iasi_metop-b_channels
    #  Cloud Detection Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-b_channels
      test variables:
      - name: CloudDetectMinResidualIR@ObsFunction
        channels: *iasi_metop-b_channels
        options:
          channels: *iasi_metop-b_channels
          use_flag: [ 1, -1, -1, -1,  1, -1, -1, -1,  1, -1,
                      1, -1,  1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1,  1,  1, -1, -1,  1,  1, -1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1,  1, -1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
                      1, -1,  1,  1,  1,  1, -1,  1,  1,  1,
                      1,  1,  1, -1,  1,  1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1,  1,  1,  1, -1,  1,
                      1, -1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1, -1,
                      1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                      1,  1, -1,  1,  1, -1, -1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1,  1,
                     -1,  1,  1, -1,  1,  1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1, -1, -1, -1,
                      1,  1,  1, -1, -1,  1, -1,  1,  1,  1,
                      1,  1, -1, -1,  1,  1, -1,  1,  1, -1,
                      1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1, -1,  1,  1, -1,  1,  1,
                      1,  1,  1, -1, -1,  1, -1, -1, -1, -1,
                     -1,  1, -1,  1, -1,  1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1,  1, -1, -1,
                     -1, -1, -1, -1, -1,  1, -1, -1,  1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                      1,  1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1,  1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1]
          use_flag_clddet: [ 1, -1, -1, -1,  1, -1, -1, -1,  1, -1,
                             1, -1,  1, -1,  1,  1,  1, -1,  1,  1,
                            -1,  1,  1,  1, -1, -1,  1,  1, -1,  1,
                            -1,  1, -1,  1, -1, -1, -1, -1, -1, -1,
                            -1, -1,  1,  1,  1, -1,  1,  1,  1,  1,
                             1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
                             1, -1,  1,  1,  1,  1, -1,  1,  1,  1,
                             1,  1,  1, -1,  1,  1,  1, -1,  1, -1,
                             1, -1, -1, -1,  1,  1,  1,  1, -1,  1,
                             1, -1,  1,  1,  1, -1,  1, -1,  1, -1,
                             1,  1, -1,  1,  1,  1,  1,  1,  1, -1,
                             1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                             1,  1, -1,  1,  1, -1, -1, -1,  1, -1,
                             1,  1, -1,  1,  1,  1,  1,  1,  1,  1,
                            -1,  1,  1, -1,  1,  1,  1,  1,  1,  1,
                             1,  1,  1,  1,  1, -1,  1, -1,  1, -1,
                             1,  1, -1, -1,  1,  1,  1, -1,  1,  1,
                            -1,  1, -1,  1, -1, -1, -1, -1, -1,  1,
                             1,  1,  1,  1,  1,  1, -1, -1, -1, -1,
                             1,  1,  1, -1, -1,  1, -1,  1,  1,  1,
                             1,  1, -1, -1,  1,  1, -1,  1,  1, -1,
                             1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1,  1, -1,  1, -1,  1, -1, -1, -1,  1,
                             1,  1,  1,  1,  1,  1, -1,  1, -1, -1,
                            -1, -1, -1, -1, -1,  1, -1, -1,  1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                            -1, -1, -1, -1, -1, -1]
          obserr_dtempf: [0.50,2.00,4.00,2.00,4.00]
      maxvalue: 1.0e-12
      action:
        name: reject
    #  NSST Retrieval Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-b_channels
      test variables:
      - name: NearSSTRetCheckIR@ObsFunction
        channels: *iasi_metop-b_channels
        options:
          channels: *iasi_metop-b_channels
          use_flag: [ 1, -1, -1, -1,  1, -1, -1, -1,  1, -1,
                      1, -1,  1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1,  1,  1, -1, -1,  1,  1, -1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1,  1, -1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
                      1, -1,  1,  1,  1,  1, -1,  1,  1,  1,
                      1,  1,  1, -1,  1,  1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1,  1,  1,  1, -1,  1,
                      1, -1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1, -1,
                      1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                      1,  1, -1,  1,  1, -1, -1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1,  1,
                     -1,  1,  1, -1,  1,  1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1, -1, -1, -1,
                      1,  1,  1, -1, -1,  1, -1,  1,  1,  1,
                      1,  1, -1, -1,  1,  1, -1,  1,  1, -1,
                      1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1, -1,  1,  1, -1,  1,  1,
                      1,  1,  1, -1, -1,  1, -1, -1, -1, -1,
                     -1,  1, -1,  1, -1,  1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1,  1, -1, -1,
                     -1, -1, -1, -1, -1,  1, -1, -1,  1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                      1,  1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1,  1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1]
          obserr_demisf: [0.01,0.02,0.03,0.02,0.03]
          obserr_dtempf: [0.50,2.00,4.00,2.00,4.00]
      maxvalue: 1.0e-12
      action:
        name: reject
    #  Surface Jacobians Check
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-b_channels
      action:
        name: inflate error
        inflation variable:
          name: ObsErrorFactorSurfJacobianRad@ObsFunction
          channels: *iasi_metop-b_channels
          options:
            channels: *iasi_metop-b_channels
            obserr_demisf: [0.01, 0.02, 0.03, 0.02, 0.03]
            obserr_dtempf: [0.50, 2.00, 4.00, 2.00, 4.00]
    #  Gross check
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-b_channels
      function absolute threshold:
      - name: ObsErrorBoundIR@ObsFunction
        channels: *iasi_metop-b_channels
        options:
          channels: *iasi_metop-b_channels
          obserr_bound_latitude:
            name: ObsErrorFactorLatRad@ObsFunction
            options:
              latitude_parameters: [25.0, 0.5, 0.04, 1.0]
          obserr_bound_transmittop:
            name: ObsErrorFactorTransmitTopRad@ObsFunction
            channels: *iasi_metop-b_channels
            options:
              channels: *iasi_metop-b_channels
          obserr_bound_max: [ 3.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 4.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0, 4.0,
                              3.5, 2.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              3.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 3.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
                              2.0, 2.0, 2.0, 2.0, 2.5, 2.0, 2.5, 2.5, 3.0, 2.5,
                              2.5, 2.5, 2.5, 3.5, 2.5, 2.5, 3.0, 3.5, 3.0, 4.0,
                              4.0, 4.0, 4.0, 4.0, 4.0, 4.5, 4.5, 4.5, 4.5, 4.5,
                              4.0, 4.5, 4.0, 4.0, 4.5, 2.5, 3.0, 2.5, 3.0, 2.5,
                              3.0, 2.0, 2.5, 2.5, 3.0, 3.0, 2.5, 3.0, 3.0, 3.0,
                              2.5, 2.5, 4.0, 4.5, 4.5, 5.0, 4.0, 4.0, 5.0, 5.0,
                              5.0, 5.0, 5.5, 5.5, 4.0, 5.0, 4.0, 4.5, 5.5, 5.5,
                              6.0, 4.5, 4.5, 4.0, 5.0, 5.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 5.5, 4.5, 6.0,
                              5.0, 5.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 5.0, 6.0,
                              6.0, 6.0, 4.0, 6.0, 6.0, 6.0, 6.0, 4.5, 6.0, 6.0,
                              4.5, 6.0, 6.0, 6.0, 6.0, 6.0, 5.0, 6.0, 6.0, 6.0,
                              5.0, 6.0, 6.0, 5.0, 6.0, 5.0, 6.0, 6.0, 6.0, 5.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0,
                              6.0, 6.0, 6.0, 6.0, 6.0, 6.0]
      action:
        name: reject
    #  Useflag Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *iasi_metop-b_channels
      test variables:
      - name: ChannelUseflagCheckRad@ObsFunction
        channels: *iasi_metop-b_channels
        options:
          channels: *iasi_metop-b_channels
          use_flag: [ 1, -1, -1, -1,  1, -1, -1, -1,  1, -1,
                      1, -1,  1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1,  1,  1, -1, -1,  1,  1, -1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1,  1, -1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
                      1, -1,  1,  1,  1,  1, -1,  1,  1,  1,
                      1,  1,  1, -1,  1,  1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1,  1,  1,  1, -1,  1,
                      1, -1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1, -1,
                      1,  1,  1,  1, -1,  1, -1,  1, -1,  1,
                      1,  1, -1,  1,  1, -1, -1, -1,  1, -1,
                      1,  1, -1,  1,  1,  1,  1,  1,  1,  1,
                     -1,  1,  1, -1,  1,  1,  1,  1,  1,  1,
                      1,  1,  1,  1,  1, -1,  1, -1,  1, -1,
                      1,  1, -1, -1,  1,  1,  1, -1,  1,  1,
                     -1,  1, -1,  1, -1, -1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1, -1, -1, -1,
                      1,  1,  1, -1, -1,  1, -1,  1,  1,  1,
                      1,  1, -1, -1,  1,  1, -1,  1,  1, -1,
                      1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1,  1, -1,  1, -1,
                      1, -1, -1, -1,  1, -1, -1, -1, -1, -1,
                     -1, -1,  1,  1, -1,  1,  1, -1,  1,  1,
                      1,  1,  1, -1, -1,  1, -1, -1, -1, -1,
                     -1,  1, -1,  1, -1,  1, -1, -1, -1,  1,
                      1,  1,  1,  1,  1,  1, -1,  1, -1, -1,
                     -1, -1, -1, -1, -1,  1, -1, -1,  1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1,  1, -1, -1, -1, -1, -1, -1,
                      1,  1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,
                     -1,  1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1,  1, -1, -1, -1, -1, -1, -1,  1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1]
      minvalue: 1.0e-12
      action:
        name: reject

  #-------------------------------------------------------------------------------------------
  # MHS METOP-B #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: mhs_metop-b
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.mhs_metop-b.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.mhs_metop-b.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      obs perturbations seed: 1
      channels: 1-5
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: mhs_metop-b
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &mhs_metop-b_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.mhs_metop-b.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *mhs_metop-b_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &mhs_metop-b_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.mhs_metop-b.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *mhs_metop-b_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle

  #-------------------------------------------------------------------------------------------
  # MHS METOP-C #
  #-------------------------------------------------------------------------------------------

  - obs space:
      name: mhs_metop-c
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.mhs_metop-c.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.mhs_metop-c.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      channels: 1-5
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: mhs_metop-c
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &mhs_metop-c_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.mhs_metop-c.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *mhs_metop-c_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &mhs_metop-c_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.mhs_metop-c.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *mhs_metop-c_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle

  #-------------------------------------------------------------------------------------------
  # MHS N19 #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: mhs_n19
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.mhs_n19.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.mhs_n19.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      obs perturbations seed: 1
      channels: 1-5
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: mhs_n19
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &mhs_n19_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.mhs_n19.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *mhs_n19_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &mhs_n19_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.mhs_n19.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *mhs_n19_tlapse
        - name: emissivity
        - name: scan_angle
          order: 4
        - name: scan_angle
          order: 3
        - name: scan_angle
          order: 2
        - name: scan_angle

  #-------------------------------------------------------------------------------------------
  # OMI AURA #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: omi_aura
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.omi_aura.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.omi_aura.2020-12-14T21:00:00Z.nc4
      simulated variables: [integrated_layer_ozone_in_air]
      obs perturbations seed: 1
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: AtmVertInterpLay
      geovals: [mole_fraction_of_ozone_in_air]
      coefficients: [0.007886131] # convert from ppmv to DU
      nlevels: [1]

  #-------------------------------------------------------------------------------------------
  # SATWIND #
  #-------------------------------------------------------------------------------------------
  - obs operator:
      name: VertInterp
    obs space:
      name: satwind
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.satwind.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.satwind.2020-12-14T21:00:00Z.nc4
      simulated variables: [eastward_wind, northward_wind]
      obs perturbations seed: 1
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs filters:
    # Reject all obs with PreQC mark already set above 3
    - filter: PreQC
      maxvalue: 3
      action:
        name: reject
    #
    # Assign the initial observation error, based on height/pressure
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      minvalue: -135
      maxvalue: 135
      action:
        name: assign error
        error function:
          name: ObsErrorModelStepwiseLinear@ObsFunction
          options:
            xvar:
              name: air_pressure@MetaData
            xvals: [100000, 95000, 80000, 65000, 60000, 55000, 50000, 45000, 40000, 35000, 30000, 25000, 20000, 15000, 10000]   #Pressure (Pa)
            errors: [1.4, 1.5, 1.6, 1.8, 1.9, 2.0, 2.1, 2.3, 2.6, 2.8, 3.0, 3.2, 2.7, 2.4, 2.1]
    #
    # Observation Range Sanity Check: either wind component or velocity exceeds 135 m/s
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      minvalue: -135
      maxvalue: 135
      action:
        name: reject
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: Velocity@ObsFunction
      maxvalue: 135.0
      action:
        name: reject
    #
    # All satellite platforms, reject when pressure greater than 950 mb.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: air_pressure@MetaData
      maxvalue: 95000
      action:
        name: reject
    #
    # Difference check surface_pressure and air_pressure@ObsValue, if less than 100 hPa, reject.
    # Starting with 730029 values, 338418 missing (half?), 50883 rejected by difference check, leaving 340728
    - filter: Difference Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      reference: surface_pressure@GeoVaLs
      value: air_pressure@MetaData
      maxvalue: -10000
    #
    # Multiple satellite platforms, reject when pressure is more than 50 mb above tropopause.
    - filter: Difference Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      reference: TropopauseEstimate@ObsFunction
      value: air_pressure@MetaData
      minvalue: -5000                    # 50 hPa above tropopause level, negative p-diff
      action:
        name: reject
    #
    # GOES WV (non-cloudy; itype=247) reject when difference of wind direction is more than 50 degrees.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: WindDirAngleDiff@ObsFunction
      maxvalue: 50.0
      action:
        name: reject
    #
    # GOES IR (245), EUMET IR (253), JMA IR (252) reject when pressure between 400 and 800 mb.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: air_pressure@MetaData
      minvalue: 40000
      maxvalue: 80000
      where:
      - variable:
          name: eastward_wind@ObsType
        is_in: 245, 252, 253
      action:
        name: reject
    #
    # GOES WV (246, 250, 254), reject when pressure greater than 400 mb.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: air_pressure@MetaData
      maxvalue: 40000
      where:
      - variable:
          name: eastward_wind@ObsType
        is_in: 246, 250, 254
      action:
        name: reject
    #
    # EUMET (242) and JMA (243) vis, reject when pressure less than 700 mb.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: air_pressure@MetaData
      minvalue: 70000
      where:
      - variable:
          name: eastward_wind@ObsType
        is_in: 242, 243
      action:
        name: reject
    #
    # MODIS-Aqua/Terra (257) and (259), reject when pressure less than 250 mb.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: air_pressure@MetaData
      minvalue: 25000
      where:
      - variable:
          name: eastward_wind@ObsType
        is_in: 257-259
      action:
        name: reject
    #
    # MODIS-Aqua/Terra (258) and (259), reject when pressure greater than 600 mb.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: air_pressure@MetaData
      maxvalue: 60000
      where:
      - variable:
          name: eastward_wind@ObsType
        is_in: 258, 259
      action:
        name: reject
    #
    # AVHRR (244), MODIS (257,258,259), VIIRS (260), GOES (247) use a LNVD check.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: SatWindsLNVDCheck@ObsFunction
      maxvalue: 3
      where:
      - variable:
          name: eastward_wind@ObsType
        is_in: 244, 247, 257-260
      action:
        name: reject
    #
    # AVHRR and MODIS (ObsType=244,257,258,259) use a SPDB check.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: SatWindsSPDBCheck@ObsFunction
        options:
          error_min: 1.4
          error_max: 20.0
      maxvalue: 1.75
      where:
        - variable:
            name: eastward_wind@ObsType
          is_in: 244, 257, 258, 259
      action:
        name: reject
    #
    # GOES (ObsType=245,246,253,254) use a SPDB check only_regrid between 300-400 mb.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      test variables:
      - name: SatWindsSPDBCheck@ObsFunction
        options:
          error_min: 1.4
          error_max: 20.0
      maxvalue: 1.75
      where:
        - variable:
            name: eastward_wind@ObsType
          is_in: 244, 257, 258, 259
        - variable:
            name: air_pressure@MetaData
          minvalue: 30000
          maxvalue: 40000
      action:
        name: reject
    #
    - filter: Background Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      absolute threshold: 7.5
      action:
        name: inflate error
        inflation factor: 3.0
      defer to post: true
    #
    # If the total inflation factor is too big, reject.
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      action:
        name: reject
      maxvalue: 2.5
      test variables:
      - name: ObsErrorFactorQuotient@ObsFunction
        options:
          numerator:
            name: eastward_wind@ObsErrorData   # After inflation step
          denominator:
            name: eastward_wind@ObsError
      where:
        - variable:
            name: eastward_wind@ObsType
          is_in: 240, 241, 242, 244, 247, 248, 249, 250, 252, 255-260
      defer to post: true
    #
    - filter: Bounds Check
      filter variables:
      - name: northward_wind
      action:
        name: reject
      maxvalue: 2.5
      test variables:
      - name: ObsErrorFactorQuotient@ObsFunction
        options:
          numerator:
            name: northward_wind@ObsErrorData   # After inflation step
          denominator:
            name: northward_wind@ObsError
      where:
        - variable:
            name: northward_wind@ObsType
          is_in: 240, 241, 242, 244, 247, 248, 249, 250, 252, 255-260
      defer to post: true
    #
    # Some satellite platforms have a lower threshold of inflation factor of 1.5
    - filter: Bounds Check
      filter variables:
      - name: eastward_wind
      action:
        name: reject
      maxvalue: 1.5
      test variables:
      - name: ObsErrorFactorQuotient@ObsFunction
        options:
          numerator:
            name: eastward_wind@ObsErrorData   # After inflation step
          denominator:
            name: eastward_wind@ObsError
      where:
        - variable:
            name: eastward_wind@ObsType
          is_in: 243, 245, 246, 251, 253, 254
      defer to post: true
    #
    - filter: Bounds Check
      filter variables:
      - name: northward_wind
      action:
        name: reject
      maxvalue: 1.5
      test variables:
      - name: ObsErrorFactorQuotient@ObsFunction
        options:
          numerator:
            name: northward_wind@ObsErrorData   # After inflation step
          denominator:
            name: northward_wind@ObsError
      where:
        - variable:
            name: eastward_wind@ObsType
          is_in: 243, 245, 246, 251, 253, 254
      defer to post: true

#-------------------------------------------------------------------------------------------
# SONDES #
#-------------------------------------------------------------------------------------------
#  - obs space:
#      name: sondes
#      obsdatain:
#        obsfile:  /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.radiosonde.2020-12-14T21:00:00Z.nc4
#        obsgrouping:
#          group variables: ["station_id", "LaunchTime"]
#          sort variable: "air_pressure"
#          sort order: "descending"
#      # obsdataout:
#        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.radiosonde.2020-12-14T21:00:00Z.nc4
#      simulated variables: [air_temperature, specific_humidity, eastward_wind, northward_wind, surface_pressure]
#    obs error:
#      covariance model: diagonal
#      random amplitude: 0.1
#    obs operator:
#      name: Composite
#      components:
#       - name: VertInterp
#         variables:
#         - name: air_temperature
#         - name: specific_humidity
#         - name: eastward_wind
#         - name: northward_wind
#       - name: SfcPCorrected
#         variables:
#         - name: surface_pressure
#         da_psfc_scheme: UKMO
#    #    geovar_geomz: geopotential_height
#    #    geovar_sfc_geomz: surface_geopotential_height
#    obs filters:
#    # Reject all obs with PreQC mark already set above 3
#    - filter: PreQC
#      maxvalue: 3
#      action:
#        name: reject
#    #
#    # Observation Range Sanity Check: temperature, surface_pressure, moisture, winds
#    - filter: Bounds Check
#      filter variables:
#      - name: air_temperature
#      minvalue: 185
#      maxvalue: 327
#      action:
#        name: reject
#    #
#    - filter: Bounds Check
#      filter variables:
#      - name: surface_pressure
#      minvalue: 37499
#      maxvalue: 106999
#      action:
#        name: reject
#    #
#    - filter: Bounds Check
#      filter variables:
#      - name: specific_humidity
#      minvalue: 1.0E-8
#      maxvalue: 0.034999999
#      action:
#        name: reject
#    #
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      minvalue: -135
#      maxvalue: 135
#      action:
#        name: reject
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      test variables:
#      - name: Velocity@ObsFunction
#      maxvalue: 135.0
#      action:
#        name: reject
#    #
#    # Reject when difference of wind direction is more than 50 degrees.
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      test variables:
#      - name: WindDirAngleDiff@ObsFunction
#      maxvalue: 50.0
#      action:
#        name: reject
#    #
#    # Assign the initial observation error, based on height/pressure
#    - filter: Perform Action
#      filter variables:
#      - name: air_temperature
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: air_pressure@MetaData
#            xvals: [100000, 95000, 90000, 85000, 35000, 30000, 25000, 20000, 15000, 10000, 7500, 5000, 4000, 3000, 2000, 1000]
#            errors: [1.2, 1.1, 0.9, 0.8, 0.8, 0.9, 1.2, 1.2, 1.0, 0.8, 0.8, 0.9, 0.95, 1.0, 1.25, 1.5]
#    #
#    - filter: Perform Action
#      filter variables:
#      - name: surface_pressure
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: surface_pressure@ObsValue
#            xvals: [80000, 75000]
#            errors: [110, 120]        # 1.1 mb below 800 mb and 1.2 mb agove 750 mb
#    #
#    - filter: Perform Action
#      filter variables:
#      - name: surface_pressure
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorSfcPressure@ObsFunction
#          options:
#            error_min: 100         # 1 mb
#            error_max: 300         # 3 mb
#            geovar_sfc_geomz: surface_geopotential_height
#    #
#    - filter: Perform Action
#      filter variables:
#      - name: specific_humidity
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: air_pressure@MetaData
#            xvals: [25000, 20000, 10]
#            errors: [0.2, 0.4, 0.8]        # 20% RH up to 250 mb, then increased rapidly above
#            scale_factor_var: specific_humidity@ObsValue
#    #
#    - filter: Perform Action
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: air_pressure@MetaData
#            xvals: [100000, 95000, 80000, 65000, 60000, 55000, 50000, 45000, 40000, 35000, 30000, 25000, 20000, 15000, 10000]   #Pressure (Pa)
#            errors: [1.4, 1.5, 1.6, 1.8, 1.9, 2.0, 2.1, 2.3, 2.6, 2.8, 3.0, 3.2, 2.7, 2.4, 2.1]
#    #
#    # Inflate obserror when multiple obs exist inside vertical model layers.
#    - filter: Perform Action
#      filter variables:
#      - name: specific_humidity
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#            test QCflag: PreQC
#            inflate variables: [specific_humidity]
#      defer to post: true
#    - filter: Perform Action
#      filter variables:
#      - name: air_temperature
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#            test QCflag: PreQC
#            inflate variables: [air_temperature]
#      defer to post: true
#    - filter: Perform Action
#      filter variables:
#      - name: eastward_wind
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#            test QCflag: PreQC
#            inflate variables: [eastward_wind]
#      defer to post: true
#    #
#    - filter: Perform Action
#      filter variables:
#      - name: northward_wind
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#            test QCflag: PreQC
#            inflate variables: [northward_wind]
#      defer to post: true
#    #
#    - filter: Background Check
#      filter variables:
#      - name: air_temperature
#      absolute threshold: 4.0
#      action:
#        name: inflate error
#        inflation factor: 3.0
#      defer to post: true
#    #
#    - filter: Background Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      absolute threshold: 7.5
#      action:
#        name: inflate error
#        inflation factor: 3.0
#      defer to post: true
#    #
#    # If the total inflation factor is too big, reject.
#    - filter: Bounds Check
#      filter variables:
#      - name: air_temperature
#      action:
#        name: reject
#      maxvalue: 8.0
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: air_temperature@ObsErrorData   # After inflation step
#          denominator:
#            name: air_temperature@ObsError
#      defer to post: true
#    #
#    - filter: Bounds Check
#      filter variables:
#      - name: specific_humidity
#      action:
#        name: reject
#      maxvalue: 8.0
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: specific_humidity@ObsErrorData   # After inflation step
#          denominator:
#            name: specific_humidity@ObsError
#      defer to post: true
#    #
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      action:
#        name: reject
#      maxvalue: 8.0
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: eastward_wind@ObsErrorData   # After inflation step
#          denominator:
#            name: eastward_wind@ObsError
#      defer to post: true
#    #
#    - filter: Bounds Check
#      filter variables:
#      - name: northward_wind
#      action:
#        name: reject
#      maxvalue: 8.0
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: northward_wind@ObsErrorData   # After inflation step
#          denominator:
#            name: northward_wind@ObsError
#      defer to post: true
#    #
#    - filter: Bounds Check
#      filter variables:
#      - name: surface_pressure
#      action:
#        name: reject
#      maxvalue: 4.0
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: surface_pressure@ObsErrorData   # After inflation step
#          denominator:
#            name: surface_pressure@ObsError
#      defer to post: true
#
  #-------------------------------------------------------------------------------------------
  # SSMIS F17 #
  #-------------------------------------------------------------------------------------------
  - obs space:
      name: ssmis_f17
      obsdatain:
        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.ssmis_f17.2020-12-14T21:00:00Z.nc4
      # obsdataout:
        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.ssmis_f17.2020-12-14T21:00:00Z.nc4
      simulated variables: [brightness_temperature]
      channels: &ssmis_f17_channels 1-24
      obs perturbations seed: 1
    obs error:
      covariance model: diagonal
      random amplitude: 0.1
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: ssmis_f17
        EndianType: little_endian
        CoefficientPath: /work/noaa/da/cgas/fv3-bundle/build/ufo/test/Data/
    obs bias:
      input file: &ssmis_f17_satbias /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.ssmis_f17.2020-12-14T18:00:00Z.satbias
      covariance:
        minimal required obs number: 20
        variance range: [1.0e-6, 10.0]
        step size: 1.0e-4
        largest analysis variance: 10000.0
        prior:
          input file: *ssmis_f17_satbias
          inflation:
            ratio: 1.1
            ratio for small dataset: 2.0
      variational bc:
        predictors:
        - name: constant
        - name: cloud_liquid_water
          satellite: SSMIS
          ch19h: 12
          ch19v: 13
          ch22v: 14
          ch37h: 15
          ch37v: 16
          ch91v: 17
          ch91h: 18
        - name: cosine_of_latitude_times_orbit_node
        - name: sine_of_latitude
        # - name: lapse_rate
        #   order: 2
        #   tlapse: &ssmis_f17_tlapse /work/noaa/da/cgas/data_clem/bias/20201214/gsi.oper_3d.bc.ssmis_f17.2020-12-14T18:00:00Z.tlapse
        # - name: lapse_rate
        #   tlapse: *ssmis_f17_tlapse
        - name: emissivity
        - name: scan_angle
          var_name: scan_position
          order: 4
        - name: scan_angle
          var_name: scan_position
          order: 3
        - name: scan_angle
          var_name: scan_position
          order: 2
        - name: scan_angle
          var_name: scan_position
    obs filters:
    #step1: Gross check (setuprad)
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: *ssmis_f17_channels
      threshold: 1.5
      action:
        name: reject
    #step1: Gross check(qcmod)
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: *ssmis_f17_channels
      absolute threshold: 3.5
      remove bias correction: true
      action:
        name: reject
    # #step2: clw check
    # Keep the CLW check in yaml for further improvement.
    # The test case using 2020110112 global SSMIS data shows that CLW check is not activated in GSI.
    #- filter: Bounds Check
    #  filter variables:
    #  - name: brightness_temperature
    #    channels: 1
    #  test variables:
    #  - name: CLWRetMW_SSMIS@ObsFunction
    #    options:
    #      satellite: SSMIS
    #      ch19h: 12
    #      ch19v: 13
    #      ch22v: 14
    #      ch37h: 15
    #      ch37v: 16
    #      ch91v: 17
    #      ch91h: 18
    #      varGroup: ObsValue
    #  minvalue: 0.0
    #  maxvalue: 0.1
    #  where:
    #  - variable:
    #      name: water_area_fraction@GeoVaLs
    #    minvalue: 0.99
    #  action:
    #    name: reject
    #step3:
    - filter: Difference Check
      filter variables:
      - name: brightness_temperature
        channels: 1-2,12-16
      reference: brightness_temperature_2@ObsValue
      value: brightness_temperature_2@HofX
      minvalue: -1.5
      maxvalue: 1.5
      where:
      - variable:
          name: water_area_fraction@GeoVaLs
        maxvalue: 0.99
    #QC_terrain: If ssmis and terrain height > 2km. do not use
    - filter: Domain Check
      filter variables:
      - name: brightness_temperature
        channels: *ssmis_f17_channels
      where:
      - variable:
          name: height_above_mean_sea_level@MetaData
        maxvalue: 2000.0
    #Do not use over mixed surface
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: 1-3,8-18
      where:
      - variable:
          name: land_area_fraction@GeoVaLs
        maxvalue: 0.99
      - variable:
          name: water_area_fraction@GeoVaLs
        maxvalue: 0.99
      - variable:
          name: ice_area_fraction@GeoVaLs
        maxvalue: 0.99
      - variable:
          name: surface_snow_area_fraction@GeoVaLs
        maxvalue: 0.99
    #step4: Generate q.c. bounds and modified variances
    - filter: BlackList
      filter variables:
      - name: brightness_temperature
        channels: *ssmis_f17_channels
      action:
        name: inflate error
        inflation variable:
    #Surface Jacobian check
          name: ObsErrorFactorSurfJacobianRad@ObsFunction
          channels: *ssmis_f17_channels
          options:
            channels: *ssmis_f17_channels
            obserr_demisf: [0.010, 0.010, 0.010, 0.010, 0.010]
            obserr_dtempf: [0.500, 0.500, 0.500, 0.500, 0.500]
    #Useflag Check
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: *ssmis_f17_channels
      test variables:
      - name: ChannelUseflagCheckRad@ObsFunction
        channels: *ssmis_f17_channels
        options:
          channels: *ssmis_f17_channels
          use_flag: [ 1, -1, -1, -1,  1 , 1,  1, -1, -1, -1,
                     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                     -1, -1, -1, 1]
      minvalue: 1.0e-12
      action:
        name: reject

#  #-------------------------------------------------------------------------------------------
#  # VADWIND #
#  #-------------------------------------------------------------------------------------------
#  - obs operator:
#      name: VertInterp
#    obs space:
#      name: vadwind
#      obsdatain:
#        obsfile: /work/noaa/da/cgas/data_clem/obs/20201215/ncdiag.oper_3d.ob.PT6H.vadwind.2020-12-14T21:00:00Z.nc4
#        obsgrouping:
#          group variables: ["station_id", "datetime"]
#          sort variable: "air_pressure"
#          sort order: "descending"
#      # obsdataout:
#        # obsfile: /work/noaa/da/cgas/data_clem/lanczos_exp/20201215_00/hofx/mem001/hofx.vadwind.2020-12-14T21:00:00Z.nc4
#      simulated variables: [eastward_wind, northward_wind]
#      obs perturbations seed: 1
#    #--------------------------------------------------------------------------------------------------------------------
#    obs error:
#      covariance model: diagonal
#      random amplitude: 0.1
#    obs filters:
#    # Begin by assigning all ObsError to a constant value. These might get overwritten later.
#    - filter: BlackList
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      action:
#        name: assign error
#        error parameter: 2.0             # 2.0 m/s
#    #
#    # Assign the initial ObsError, based on height/pressure
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      minvalue: -135
#      maxvalue: 135
#      action:
#        name: assign error
#        error function:
#          name: ObsErrorModelStepwiseLinear@ObsFunction
#          options:
#            xvar:
#              name: air_pressure@MetaData
#            xvals: [100000, 95000, 85000, 80000, 70000, 65000, 60000, 55000, 50000, 45000, 40000, 35000, 30000, 25000, 20000, 15000, 10000]
#            errors: [1.4, 1.5, 1.5, 1.6, 1.6, 1.8, 1.9, 2.0, 2.1, 2.3, 2.6, 2.8, 3.0, 3.2, 2.7, 2.4, 2.1]
#    #
#    # Reject all obs with PreQC mark already set above 3
#    - filter: PreQC
#      maxvalue: 3
#      action:
#        name: reject
#    #
#    # Reject when pressure is less than 226 mb.
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      test variables:
#      - name: air_pressure@MetaData
#      minvalue: 22600
#      action:
#        name: reject
#    #
#    # Observation Range Sanity Check: either wind component or velocity exceeds 135 m/s
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      minvalue: -135
#      maxvalue: 135
#      action:
#        name: reject
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      test variables:
#      - name: Velocity@ObsFunction
#      maxvalue: 135.0
#      action:
#        name: reject
#    #
#    # Reject when difference of wind direction is more than 50 degrees.
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      test variables:
#      - name: WindDirAngleDiff@ObsFunction
#      maxvalue: 50.0
#      action:
#        name: reject
#      defer to post: true
#    #
#    # Inflate obserror when multiple obs exist inside vertical model layers.
#    - filter: BlackList
#      filter variables:
#      - name: eastward_wind
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#            test QCflag: PreQC
#            inflate variables: [eastward_wind]
#      defer to post: true
#    #
#    - filter: BlackList
#      filter variables:
#      - name: northward_wind
#      action:
#        name: inflate error
#        inflation variable:
#          name: ObsErrorFactorConventional@ObsFunction
#          options:
#            test QCflag: PreQC
#            inflate variables: [northward_wind]
#      defer to post: true
#    #
#    - filter: Background Check
#      filter variables:
#      - name: eastward_wind
#      - name: northward_wind
#      absolute threshold: 7.5
#      action:
#        name: inflate error
#        inflation factor: 2.5
#      defer to post: true
#    #
#    # If the total inflation factor is too big, reject.
#    - filter: Bounds Check
#      filter variables:
#      - name: eastward_wind
#      action:
#        name: reject
#      maxvalue: 6.5
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: eastward_wind@ObsErrorData   # After inflation step
#          denominator:
#            name: eastward_wind@ObsError
#      defer to post: true
#    #
#    - filter: Bounds Check
#      filter variables:
#      - name: northward_wind
#      action:
#        name: reject
#      maxvalue: 6.5
#      test variables:
#      - name: ObsErrorFactorQuotient@ObsFunction
#        options:
#          numerator:
#            name: northward_wind@ObsErrorData   # After inflation step
#          denominator:
#            name: northward_wind@ObsError
#      defer to post: true
#
#-------------------------------------------------------------------------------------------
# END OF OBSERVATIONS #
#-------------------------------------------------------------------------------------------

variational:

  minimizer:
    algorithm: DRIPCG

  iterations:
  - ninner: 30
    gradient norm reduction: 1e-10
    test: on
    geometry:
      fms initialization:
        namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
        field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
      akbk: *akbk
      layout: *layout
      npx: *npx
      npy: *npy
      npz: *npz
      fieldsets:
      - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
      - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml
    diagnostics:
      departures: ombg

final:
  diagnostics:
    departures: oman

output:
  filetype: fms restart
  datapath: ${data_dir_regrid}/${bump_dir}/variational_3dvar_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_sfcw: fv_srf_wnd.res.nc
  filename_trcr: fv_tracer.res.nc
  filename_phys: phy_data.nc
  filename_sfcd: sfc_data.nc
  first: PT0H
  frequency: PT1H
EOF

# 3DVAR FULL REGRID sbatch
ntasks=${ntasks_regrid}
cpus_per_task=2
threads=1
time=01:30:00
exe=fv3jedi_var.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
