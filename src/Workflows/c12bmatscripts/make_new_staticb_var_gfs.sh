#!/bin/bash

dates=("$@")
bg_date=${dates[-2]}
bgYYYY=${bg_date:0:4}
bgMM=${bg_date:4:2}
bgDD=${bg_date:6:2}
bgHH=${bg_date:8:2}

cat << EOF > new_staticb_var_gfs.yaml
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
  datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
  filetype: fms restart
  #skip coupler file: true
  set datetime on read: true
  state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio] 
  psinfile: true
  datapath: ${unbalanced_dir}/mem001
  filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.fv_core.res.nc
  filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.fv_tracer.res.nc
  filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.sfc_data.nc
  filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.fv_srf_wnd.res.nc
  filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: ID
  saber outer blocks:
  - saber block name: BUMP_StdDev
    calibration:
      general:
        universe length-scale: 3000.0e3
      io:
        data directory: ${Data_dir}/newstaticb
      drivers:
        multivariate strategy: univariate
      ensemble sizes:
        sub-ensembles: 3
      diagnostics:
        target ensemble size: 30
      variance:
        objective filtering: true
        filtering iterations: 1
        initial length-scale:
        - variables:
          - stream_function
          - velocity_potential
          value: 3000.0e3
        - variables:
          - air_temperature
          - surface_pressure
          - specific_humidity
          - cloud_liquid_water
          - ozone_mass_mixing_ratio
          value: 300.0e3
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
          files prefix: var_3D_gfs
      - model:
          variables:
          - surface_pressure
        io:
          files prefix: var_2D_gfs
      input model files:
EOF
componentcount=1
for date in "${dates[@]}"; do
YYYY=${date:0:4}
MM=${date:4:2}
DD=${date:6:2}
HH=${date:8:2}
cat << EOF >> new_staticb_var_gfs.yaml
      - parameter: var
        component: $componentcount
        file:
          set datetime on read: true
          datetime: ${YYYY}-${MM}-${DD}T${HH}:00:00Z
          filetype: fms restart
          skip coupler file: true
          datapath: ${Data_dir}/newstaticb
          psinfile: true
          filename_core: ${YYYY}${MM}${DD}.${HH}0000.var.fv_core.res.nc
          filename_trcr: ${YYYY}${MM}${DD}.${HH}0000.var.fv_tracer.res.nc
          filename_sfcd: ${YYYY}${MM}${DD}.${HH}0000.var.sfc_data.nc
          filename_sfcw: ${YYYY}${MM}${DD}.${HH}0000.var.fv_srf_wnd.res.nc
          filename_cplr: ${YYYY}${MM}${DD}.${HH}0000.var.coupler.res
      - parameter: m4
        component: $componentcount
        file:
          set datetime on read: true
          datetime: ${YYYY}-${MM}-${DD}T${HH}:00:00Z
          filetype: fms restart
          skip coupler file: true
          datapath: ${Data_dir}/newstaticb
          psinfile: true
          filename_core: ${YYYY}${MM}${DD}.${HH}0000.m4.fv_core.res.nc
          filename_trcr: ${YYYY}${MM}${DD}.${HH}0000.m4.fv_tracer.res.nc
          filename_sfcd: ${YYYY}${MM}${DD}.${HH}0000.m4.sfc_data.nc
          filename_sfcw: ${YYYY}${MM}${DD}.${HH}0000.m4.fv_srf_wnd.res.nc
          filename_cplr: ${YYYY}${MM}${DD}.${HH}0000.m4.coupler.res
EOF
((componentcount++))
done

cat << EOF >> new_staticb_var_gfs.yaml
      output model files:
      - parameter: stddev
        file:
          filetype: fms restart
          datapath: ${Data_dir}/newstaticb
          filename_core: stddev.fv_core.res.nc
          filename_trcr: stddev.fv_tracer.res.nc
          filename_sfcd: stddev.sfc_data.nc
          filename_sfcw: stddev.fv_srf_wnd.res.nc
          filename_cplr: stddev.coupler.res

EOF


