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
  analysis variables: &vars [ua,va,t,ps,sphum,liq_wat,o3mr]

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
          filetype: gfs
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
        filetype: gfs
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
#SBATCH --time=00:40:00
#SBATCH -e ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}
export OMP_NUM_THREADS=1

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
  analysis variables: &vars [ua,va,t,ps,sphum,liq_wat,o3mr]

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
          filetype: gfs
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
        filetype: gfs
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
export OMP_NUM_THREADS=1

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
  analysis variables: &vars [ua,va,t,ps,sphum,liq_wat,o3mr]

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
          filetype: gfs
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
        filetype: gfs
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
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}
export OMP_NUM_THREADS=1

cd ${work_dir}/variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_var.x ${yaml_dir}/${yaml_name}

exit 0
EOF
done
