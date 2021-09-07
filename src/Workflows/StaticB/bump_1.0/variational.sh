#!/bin/bash

####################################################################
# 3DVAR ############################################################
####################################################################

# Create directories
mkdir -p ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_c384}/${bump_dir}/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}

# 3DVAR yaml
yaml_name="variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,t,ps,sphum,ice_wat,liq_wat,o3mr]

  geometry:
    fms initialization:
      namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
      field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
    akbk: &akbk ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
    layout: &layout [6,6]
    npx: &npx 385
    npy: &npy 385
    npz: &npz 127
    fieldsets:
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml

  background:
    filetype: gfs
    datapath: ${data_dir_c384}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: *vars
    psinfile: true

  background error:
    covariance model: BUMP
    full inverse: 1
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
      input variables: &control_vars [psi,chi,t,ps,sphum,ice_wat,liq_wat,o3mr]
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
      output variables: *vars
      active variables: [psi,chi]
      bump:
        datadir: ${data_dir_c384}/${bump_dir}
        prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_wind_local: 1

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: ${data_dir}/obs/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
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
#  filetype: gfs
#  datapath: ${data_dir_c384}/${bump_dir}/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
#  filename_cplr: coupler.res
#  filename_core: fv_core.res.nc
#  filename_sfcw: fv_srf_wnd.res.nc
#  filename_trcr: fv_tracer.res.nc
#  filename_phys: phy_data.nc
#  filename_sfcd: sfc_data.nc
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: 3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  first: PT0H
  frequency: PT1H
EOF

# 3DVAR sbatch
sbatch_name="variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_var.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# 3DVAR_SINGLE-OBS #################################################
####################################################################

# Create directories
mkdir -p ${work_dir}/variational_3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_c384}/${bump_dir}/3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}

# 3DVAR SINGLE-OBS yaml
yaml_name="variational_3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,t,ps,sphum,ice_wat,liq_wat,o3mr]

  geometry:
    fms initialization:
      namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
      field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
    akbk: &akbk ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
    layout: &layout [6,6]
    npx: &npx 385
    npy: &npy 385
    npz: &npz 127
    fieldsets:
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml

  background:
    filetype: gfs
    datapath: ${data_dir_c384}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: *vars
    psinfile: true

  background error:
    covariance model: BUMP
    full inverse: 1
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
      input variables: &control_vars [psi,chi,t,ps,sphum,ice_wat,liq_wat,o3mr]
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
      output variables: *vars
      active variables: [psi,chi]
      bump:
        datadir: ${data_dir_c384}/${bump_dir}
        prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_wind_local: 1

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: /work/noaa/da/dholdawa/JediWork/Benchmarks/3dvar/Data/obs/single_ob_a.nc4
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
#  filetype: gfs
#  datapath: ${data_dir_c384}/${bump_dir}/3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}
#  filename_cplr: coupler.res
#  filename_core: fv_core.res.nc
#  filename_sfcw: fv_srf_wnd.res.nc
#  filename_trcr: fv_tracer.res.nc
#  filename_phys: phy_data.nc
#  filename_sfcd: sfc_data.nc
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: 3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  first: PT0H
  frequency: PT1H
EOF

# 3DVAR SINGLE-OBS sbatch
sbatch_name="variational_3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=variational_3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/variational_3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/variational_3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/variational_3dvar_single-obs_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_var.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# 3DVAR REGRID #####################################################
####################################################################

# Create directories
mkdir -p ${work_dir}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}

# 3DVAR yaml
yaml_name="variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,t,ps,sphum,ice_wat,liq_wat,o3mr]

  geometry:
    fms initialization:
      namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
      field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
    akbk: &akbk ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
    layout: &layout [${nlx},${nly}]
    npx: &npx ${npx}
    npy: &npy ${npy}
    npz: &npz 127
    fieldsets:
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
    - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/ufo.yaml

  background:
    filetype: gfs
    datapath: ${data_dir_regrid}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: *vars
    psinfile: true

  background error:
    covariance model: BUMP
    full inverse: 1
    active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_regrid}/${bump_dir}
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
      datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
      filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
      filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    variable changes:
    - variable change: StdDev
      input variables: &control_vars [psi,chi,t,ps,sphum,ice_wat,liq_wat,o3mr]
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
      output variables: *vars
      active variables: [psi,chi]
      bump:
        datadir: ${data_dir_regrid}/${bump_dir}
        prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_wind_local: 1

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: ${data_dir}/obs/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
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
#  filetype: gfs
#  datapath: ${data_dir_regrid}/${bump_dir}/3dvar_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}
#  filename_cplr: coupler.res
#  filename_core: fv_core.res.nc
#  filename_sfcw: fv_srf_wnd.res.nc
#  filename_trcr: fv_tracer.res.nc
#  filename_phys: phy_data.nc
#  filename_sfcd: sfc_data.nc
  filetype: geos
  datapath: ${data_dir_regrid}/${bump_dir}/geos
  filename_bkgd: 3dvar_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  first: PT0H
  frequency: PT1H
EOF

# 3DVAR sbatch
sbatch_name="variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nlx*nly))
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n $((6*nlx*nly)) ${bin_dir}/fv3jedi_var.x ${yaml_dir}/${yaml_name}

exit 0
EOF
