#!/bin/bash

####################################################################
# 3DVAR ############################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir}/hofx/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir}/analysis/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}

# 3DVAR yaml
yaml_name="variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
cost function:

  cost type: 3D-Var
  window begin: 2021-02-28T21:00:00Z
  window length: PT6H
  analysis variables: &anavars [ua,va,t,ps,sphum,ice_wat,liq_wat,o3mr]

  geometry:
    nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
    trc_file: ${data_dir}/fv3files/field_table
    akbk: ${data_dir}/fv3files/akbk127.nc4
    layout: [6,6]
    io_layout: [1,1]
    npx: 385
    npy: 385
    npz: 127
    ntiles: 6
    fieldsets:
    - fieldset: ${data_dir}/fieldsets/dynamics.yaml

  background:
    filetype: gfs
    state variables: &bkgvars [ua,va,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
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
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_2
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
      output variables: *bkgvars
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

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: ${data_dir}/obs/aircraft_obs_2018041500_m.nc4
      obsdataout:
        obsfile: ${data_dir}/hofx/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/aircraft_hyb-3dvar-1-gfs_2018041500_m.nc4
      simulated variables: [eastward_wind, northward_wind, air_temperature]
    obs operator:
      name: VertInterp
    obs error:
      covariance model: diagonal
    obs filters:
    - filter: PreQC
      maxvalue: 3
    - filter: Background Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      - name: air_temperature
      threshold: 6.0
  - obs space:
      name: Radiosonde
      obsdatain:
        obsfile: ${data_dir}/obs/sondes_obs_2018041500_m.nc4
      obsdataout:
        obsfile: ${data_dir}/hofx/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/sondes_hyb-3dvar-1-gfs_2018041500_m.nc4
      simulated variables: [eastward_wind, northward_wind, air_temperature]
    obs operator:
      name: VertInterp
    obs error:
      covariance model: diagonal
    obs filters:
    - filter: PreQC
      maxvalue: 3
    - filter: Background Check
      filter variables:
      - name: eastward_wind
      - name: northward_wind
      - name: air_temperature
      threshold: 6.0
  - obs space:
      name: GnssroBndNBAM
      obsdatain:
        obsfile: ${data_dir}/obs/gnssro_obs_2018041500_m.nc4
      obsdataout:
        obsfile: ${data_dir}/hofx/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/gnssro_hyb-3dvar-1-gfs_2018041500_m.nc4
      simulated variables: [bending_angle]
    obs operator:
      name: GnssroBndNBAM
      obs options:
        sr_steps: 2
        vertlayer: full
        compress: 1
        super_ref_qc: NBAM
    obs error:
      covariance model: diagonal
    obs filters:
    - filter: Domain Check
      filter variables:
      - name: bending_angle
      where:
      - variable:
          name: impact_height@MetaData
        minvalue: 0
        maxvalue: 50000
    - filter: ROobserror
      filter variables:
      - name: bending_angle
      errmodel: NBAM
    - filter: Background Check RONBAM
      filter variables:
      - name: bending_angle
  - obs space:
      name: AMSUA-NOAA19
      obsdatain:
        obsfile: ${data_dir}/obs/amsua_n19_obs_2018041500_m.nc4
      obsdataout:
        obsfile: ${data_dir}/hofx/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/amsua_n19_hyb-3dvar-1-gfs_2018041500_m.nc4
      simulated variables: [brightness_temperature]
      channels: 1-15
    obs operator:
      name: CRTM
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: amsua_n19
        EndianType: little_endian
        CoefficientPath: Data/crtm/
    obs error:
      covariance model: diagonal
    obs filters:
    - filter: Bounds Check
      filter variables:
      - name: brightness_temperature
        channels: 1-15
      minvalue: 100.0
      maxvalue: 500.0
    - filter: Background Check
      filter variables:
      - name: brightness_temperature
        channels: 1-15
      threshold: 3.0
  - obs space:
      name: SfcObs
      obsdatain:
        obsfile: ${data_dir}/obs/sfc_obs_2018041500_m.nc4
      obsdataout:
        obsfile: ${data_dir}/hofx/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/sfc_hyb-3dvar-1-gfs_2018041500_m.nc4
      simulated variables: [surface_pressure]
    obs operator:
      name: SfcPCorrected
      da_psfc_scheme: UKMO
    linear obs operator:
      name: Identity
    obs error:
      covariance model: diagonal
    obs filters:
    - filter: Background Check
      threshold: 1000

variational:

  minimizer:
    algorithm: DRIPCG

  iterations:
  - ninner: 10
    gradient norm reduction: 1e-10
    test: on
    geometry:
      nml_file_mpp: ${data_dir}/fv3files/fmsmpp.nml
      trc_file: ${data_dir}/fv3files/field_table
      akbk: ${data_dir}/fv3files/akbk127.nc4
      layout: [6,6]
      io_layout: [1,1]
      npx: 385
      npy: 385
      npz: 127
      ntiles: 6
      fieldsets:
      - fieldset: ${data_dir}/fieldsets/dynamics.yaml
    diagnostics:
      departures: ombg

final:
  diagnostics:
    departures: oman

output:
  filetype: gfs
  datapath: ${data_dir}/analysis/3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
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
sbatch_name="variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_var.x ${yaml_dir}/${yaml_name}

exit 0
EOF
