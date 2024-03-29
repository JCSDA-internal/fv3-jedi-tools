#!/bin/bash

dates=("$@")
for date in "${dates[@]}"; do
YYYY=${date:0:4}
MM=${date:4:2}
DD=${date:6:2}
HH=${date:8:2}

cat << EOF > new_staticb_prep_${date}_gfs.yaml
geometry:
  fms initialization:
    namelist filename: Data/fv3files/fmsmpp.nml
    field table filename: Data/fv3files/field_table_gfdl
  akbk: Data/fv3files/akbk127.nc4
  layout: [1,2]
  npx: 13
  npy: 13
  npz: 127
  field metadata override: Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${YYYY}-${MM}-${DD}T${HH}:00:00Z
  filetype: fms restart
  skip coupler file: true
  state variables: &stateVariables [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${balanced_dir}/mem001/
  filename_core: ${YYYY}${MM}${DD}.${HH}0000.fv_core.res.nc
  filename_trcr: ${YYYY}${MM}${DD}.${HH}0000.fv_tracer.res.nc
  filename_sfcd: ${YYYY}${MM}${DD}.${HH}0000.sfc_data.nc
  filename_sfcw: ${YYYY}${MM}${DD}.${HH}0000.fv_srf_wnd.res.nc
  filename_cplr: ${YYYY}${MM}${DD}.${HH}0000.coupler.res
background error:
  covariance model: SABER
  iterative ensemble loading: true
  ensemble:
    members from template:
      template:
        datetime: ${YYYY}-${MM}-${DD}T${HH}:00:00Z
        filetype: fms restart
        state variables: *stateVariables
        psinfile: true
        datapath: ${balanced_dir}/mem%mem%/
        filename_core: ${YYYY}${MM}${DD}.${HH}0000.fv_core.res.nc
        filename_trcr: ${YYYY}${MM}${DD}.${HH}0000.fv_tracer.res.nc
        filename_sfcd: ${YYYY}${MM}${DD}.${HH}0000.sfc_data.nc
        filename_sfcw: ${YYYY}${MM}${DD}.${HH}0000.fv_srf_wnd.res.nc
        filename_cplr: ${YYYY}${MM}${DD}.${HH}0000.coupler.res
      pattern: '%mem%'
      nmembers: ${num_mems}
      start: 0
      zero padding: 3
  output ensemble:
    first member only: true
    filetype: fms restart
    datapath: ${unbalanced_dir}/mem%{member}%/
    filename_core: fv_core.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_sfcd: sfc_data.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_cplr: coupler.res
  saber central block:
    saber block name: BUMP_NICAS
    calibration:
      general:
        universe length-scale: 5000.0e3
      io:
        data directory: ${Data_dir}/newstaticb
      drivers:
        multivariate strategy: univariate
        write local sampling: true
        compute correlation: true
        compute variance: true
        compute correlation: true
        compute moments: true
        write moments: true
      sampling:
        computation grid size: 500
        distance classes: 10
        distance class width: 500.0e3
        reduced levels: 5
        grid type: octahedral
      grids:
      - model:
          variables:
          - stream_function
          - velocity_potential
          - air_temperature
          - specific_humidity
          - cloud_liquid_water
          - ozone_mass_mixing_ratio
        io:
          files prefix: var-mom_3D_${date}_gfs
      - model:
          variables:
          - surface_pressure
        io:
          files prefix: var-mom_2D_${date}_gfs
      output model files:
      - parameter: var
        file:
          filetype: fms restart
          datapath: ${Data_dir}/newstaticb/
          filename_core: var.fv_core.res.nc
          filename_trcr: var.fv_tracer.res.nc
          filename_sfcd: var.sfc_data.nc
          filename_sfcw: var.fv_srf_wnd.res.nc
          filename_cplr: var.coupler.res
      - parameter: m4
        file:
          filetype: fms restart
          datapath: ${Data_dir}/newstaticb/
          filename_core: m4.fv_core.res.nc
          filename_trcr: m4.fv_tracer.res.nc
          filename_sfcd: m4.sfc_data.nc
          filename_sfcw: m4.fv_srf_wnd.res.nc
          filename_cplr: m4.coupler.res
  saber outer blocks:
  - saber block name: BUMP_VerticalBalance
    active variables: [stream_function,velocity_potential,air_temperature,surface_pressure]
    calibration:
      general:
        universe length-scale: 2500.0e3
      io:
        data directory: ${Data_dir}/newstaticb
        files prefix: vbal_${date}_gfs
      drivers:
        write local sampling: true
        compute vertical covariance: true
        write vertical covariance: true
        compute vertical balance: true
        write vertical balance: true
      sampling:
        computation grid size: 500
        diagnostic grid size: 200
        grid type: octahedral
        averaging length-scale: 2000.0e3
      vertical balance:
        vbal:
        - balanced variable: velocity_potential
          unbalanced variable: stream_function
        - balanced variable: air_temperature
          unbalanced variable: stream_function
        - balanced variable: surface_pressure
          unbalanced variable: stream_function
        pseudo inverse: true
        variance threshold: 0.1
EOF
done
