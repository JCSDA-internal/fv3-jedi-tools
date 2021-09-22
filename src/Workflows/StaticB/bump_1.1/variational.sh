#!/bin/bash

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

# Create directories
mkdir -p ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_c384}/${bump_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}

# 3DVAR yaml
yaml_name="variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &stateVars [ua,va,T,ps,sphum,ice_wat,liq_wat,o3mr]

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
    state variables: *stateVars
    psinfile: 1
    datapath: ${data_dir_c384}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc

  background error:
    covariance model: BUMP
    full inverse: 1
    active variables: &controlVars [psi,chi,tv,ps,rh]
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
      filename_core: cor_rh.fv_core.res.nc
      filename_trcr: cor_rh.fv_tracer.res.nc
      filename_cplr: cor_rh.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    variable changes:
    - variable change: StdDev
      input variables: *controlVars
      output variables: *controlVars
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
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - variable change: StatsVariableChange
      input variables: *controlVars
      output variables: *controlVars
      active variables: [psi,chi,tv,ps]
      bump:
        datadir: ${data_dir_c384}/${bump_dir}
        prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_vbal: 1
        fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
        load_samp_local: 1
        vbal_block: [1,1,0,1]
    - variable change: StatsVariableChange
      input variables: *controlVars
      output variables: *controlVars
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
      input variables: *controlVars
      output variables: *stateVars

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
#  filetype: gfs
#  datapath: ${data_dir_c384}/${bump_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
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
# 3DVAR REGRID #####################################################
####################################################################

# Create directories
mkdir -p ${work_dir}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}

# 3DVAR yaml
yaml_name="variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &stateVars [ua,va,T,ps,sphum,ice_wat,liq_wat,o3mr]

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
    state variables: *stateVars
    psinfile: 1
    datapath: ${data_dir_regrid}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc

  background error:
    covariance model: BUMP
    full inverse: 1
    active variables: &controlVars [psi,chi,tv,ps,rh]
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
      filename_core: cor_rh.fv_core.res.nc
      filename_trcr: cor_rh.fv_tracer.res.nc
      filename_cplr: cor_rh.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    variable changes:
    - variable change: StdDev
      input variables: *controlVars
      output variables: *controlVars
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
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - variable change: StatsVariableChange
      input variables: *controlVars
      output variables: *controlVars
      active variables: [psi,chi,tv,ps]
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
      input variables: *controlVars
      output variables: &stateVarsWithTvRh [ua,va,tv,ps,rh]
      active variables: [psi,chi]
      bump:
        datadir: ${data_dir_regrid}/${bump_dir}
        prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_wind_local: 1
    - variable change: Control2Analysis
      input variables: *stateVarsWithTvRh
      output variables: *stateVars

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: ${data_dir}/obs/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
      obsdataout:
        obsfile: ${data_dir_regrid}/${bump_dir}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
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
#  datapath: ${data_dir_regrid}/${bump_dir}/variational_3dvar_c${cregrid}_${nlx}x${nly}_${yyyymmddhh_first}-${yyyymmddhh_last}
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

####################################################################
# 3DVAR with specific observations #################################
####################################################################

for obs in ${obs_xp} ; do
   # Create directories
   mkdir -p ${work_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}
   mkdir -p ${data_dir_c384}/${bump_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}
   
   # 3DVAR yaml
   yaml_name="variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
cost function:

  cost type: 3D-Var
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &stateVars [ua,va,T,ps,sphum,ice_wat,liq_wat,o3mr]

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
    state variables: *stateVars
    psinfile: 1
    datapath: ${data_dir_c384}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc

  background error:
    covariance model: BUMP
    full inverse: 1
    active variables: &controlVars [psi,chi,tv,ps,rh]
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
      filename_core: cor_rh.fv_core.res.nc
      filename_trcr: cor_rh.fv_tracer.res.nc
      filename_cplr: cor_rh.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    variable changes:
    - variable change: StdDev
      input variables: *controlVars
      output variables: *controlVars
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
        filename_core: stddev.fv_core.res.nc
        filename_trcr: stddev.fv_tracer.res.nc
        filename_cplr: stddev.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    - variable change: StatsVariableChange
      input variables: *controlVars
      output variables: *controlVars
      active variables: [psi,chi,tv,ps]
      bump:
        datadir: ${data_dir_c384}/${bump_dir}
        prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
        verbosity: main
        universe_rad: 2000.0e3
        load_vbal: 1
        fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
        load_samp_local: 1
        vbal_block: [1,1,0,1]
    - variable change: StatsVariableChange
      input variables: *controlVars
      output variables: *controlVars
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
      input variables: *controlVars
      output variables: *stateVars

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
#  filetype: gfs
#  datapath: ${data_dir_c384}/${bump_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}
#  filename_cplr: coupler.res
#  filename_core: fv_core.res.nc
#  filename_sfcw: fv_srf_wnd.res.nc
#  filename_trcr: fv_tracer.res.nc
#  filename_phys: phy_data.nc
#  filename_sfcd: sfc_data.nc
  filetype: geos
  datapath: ${data_dir_c384}/${bump_dir}/geos
  filename_bkgd: 3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}.nc4
  first: PT0H
  frequency: PT1H
EOF

   # 3DVAR sbatch
   sbatch_name="variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_var.x ${yaml_dir}/${yaml_name}

exit 0
EOF
done
