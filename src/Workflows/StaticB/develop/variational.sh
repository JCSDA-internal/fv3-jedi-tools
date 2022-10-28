#!/bin/bash

# Source functions
source ./functions.sh

# Create data directories
mkdir -p ${data_dir_def}/${bump_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_regrid}/${bump_dir}/variational_3dvar_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

####################################################################
# 3DVAR ############################################################
####################################################################

# Job name
job=variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# 3DVAR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]

  geometry:
    fms initialization:
      namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
      field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
    akbk: &akbk ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
    layout: &layout [${nlx_def},${nly_def}]
    npx: &npx ${npx_def}
    npy: &npy ${npy_def}
    npz: &npz 127
    field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml

  background:
    datetime: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: *vars

  background error:
    covariance model: SABER
    full inverse: true
    saber blocks:
    - saber block name: BUMP_NICAS
      saber central block: true
      input variables: &control_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      output variables: *control_vars
      active variables: &active_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      bump:
        prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        datadir: ${data_dir_def}/${bump_dir}
        verbosity: main
        strategy: specific_univariate
        load_nicas_local: true
        min_lev:
          cloud_liquid_water: 76
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_nicas
        universe radius:
          datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
          filetype: fms restart
          set datetime on read: true
          psinfile: true
          datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
          filename_core: cor_rh.fv_core.res.nc
          filename_trcr: cor_rh.fv_tracer.res.nc
          filename_cplr: cor_rh.coupler.res
    - saber block name: StdDev
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
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
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
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
      input variables: *control_vars
      output variables: *vars

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: ${data_dir}/obs/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
      obsdataout:
        obsfile: ${data_dir_def}/${bump_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
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
      field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
    diagnostics:
      departures: ombg

final:
  diagnostics:
    departures: oman

output:
  filetype: fms restart
  datapath: ${data_dir_def}/${bump_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
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
# 3DVAR REGRID #####################################################
####################################################################

# Job name
job=variational_3dvar_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# 3DVAR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]

  geometry:
    fms initialization:
      namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
      field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
    akbk: &akbk ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
    layout: &layout [${nlx_regrid},${nly_regrid}]
    npx: &npx ${npx_regrid}
    npy: &npy ${npy_regrid}
    npz: &npz 127
    field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml

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

  background error:
    covariance model: SABER
    full inverse: true
    saber blocks:
    - saber block name: BUMP_NICAS
      saber central block: true
      input variables: &control_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      output variables: *control_vars
      active variables: &active_vars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
      bump:
        prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
        datadir: ${data_dir_regrid}/${bump_dir}
        verbosity: main
        strategy: specific_univariate
        load_nicas_local: true
        min_lev:
          cloud_liquid_water: 76
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_nicas
        universe radius:
          datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
          filetype: fms restart
          set datetime on read: true
          psinfile: true
          datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
          filename_core: cor_rh.fv_core.res.nc
          filename_trcr: cor_rh.fv_tracer.res.nc
          filename_cplr: cor_rh.coupler.res
    - saber block name: StdDev
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
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
      input variables: *control_vars
      output variables: *control_vars
      active variables: *active_vars
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
      input variables: *control_vars
      output variables: *vars

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: ${data_dir}/obs/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
      obsdataout:
        obsfile: ${data_dir_regrid}/${bump_dir}/variational_3dvar_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
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
      field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
    diagnostics:
      departures: ombg

final:
  diagnostics:
    departures: oman

output:
  filetype: fms restart
  datapath: ${data_dir_regrid}/${bump_dir}/variational_3dvar_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
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
