#!/bin/bash

dates=("$@")
bg_date=${dates[-2]}
bgYYYY=${bg_date:0:4}
bgMM=${bg_date:4:2}
bgDD=${bg_date:6:2}
bgHH=${bg_date:8:2}

cat << EOF > new_staticb_nicas_gfs.yaml
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
  skip coupler file: true
  state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${unbalanced_dir}/mem001/
  filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.fv_core.res.nc
  filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.fv_tracer.res.nc
  filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.sfc_data.nc
  filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.fv_srf_wnd.res.nc
  filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    calibration:
      io:
        data directory: ${Data_dir}/newstaticb
        files prefix: nicas_gfs
      drivers:
        multivariate strategy: univariate
        read universe radius: true
        compute nicas: true
        write local nicas: true
        write global nicas: true
      nicas:
        resolution: 6
        interpolation type:
        - groups:
          - stream_function
          - velocity_potential
          - air_temperature
          - surface_pressure
          type: si
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
          overriding universe radius file: cor_3D_gfs_universe_radius
      - model:
          variables:
          - surface_pressure
        io:
          overriding universe radius file: cor_2D_gfs_universe_radius
      input model files:
      - parameter: a
        component: 1
        file:
          set datetime on read: true
          datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
          filetype: fms restart
          skip coupler file: true
          psinfile: true
          datapath: ${Data_dir}/newstaticb/
          filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_1.fv_core.res.nc
          filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_1.fv_tracer.res.nc
          filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_1.sfc_data.nc
          filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_1.fv_srf_wnd.res.nc
          filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_1.coupler.res
      - parameter: a
        component: 2
        file:
          set datetime on read: true
          datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
          filetype: fms restart
          skip coupler file: true
          psinfile: true
          datapath: ${Data_dir}/newstaticb/
          filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_2.fv_core.res.nc
          filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_2.fv_tracer.res.nc
          filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_2.sfc_data.nc
          filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_2.fv_srf_wnd.res.nc
          filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_a_2.coupler.res
      - parameter: rh
        component: 1
        file:
          set datetime on read: true
          datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
          filetype: fms restart
          skip coupler file: true
          psinfile: true
          datapath: ${Data_dir}/newstaticb/
          filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_1.fv_core.res.nc
          filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_1.fv_tracer.res.nc
          filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_1.sfc_data.nc
          filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_1.fv_srf_wnd.res.nc
          filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_1.coupler.res
      - parameter: rh
        component: 2
        file:
          set datetime on read: true
          datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
          filetype: fms restart
          skip coupler file: true
          psinfile: true
          datapath: ${Data_dir}/newstaticb/
          filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_2.fv_core.res.nc
          filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_2.fv_tracer.res.nc
          filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_2.sfc_data.nc
          filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_2.fv_srf_wnd.res.nc
          filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rh_2.coupler.res
      - parameter: rv
        component: 1
        file:
          set datetime on read: true
          datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
          filetype: fms restart
          psinfile: true
          datapath: ${Data_dir}/newstaticb/
          filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_1.fv_core.res.nc
          filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_1.fv_tracer.res.nc
          filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_1.sfc_data.nc
          filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_1.fv_srf_wnd.res.nc
          filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_1.coupler.res
      - parameter: rv
        component: 2
        file:
          set datetime on read: true
          datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
          filetype: fms restart
          psinfile: true
          datapath: ${Data_dir}/newstaticb/
          filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_2.fv_core.res.nc
          filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_2.fv_tracer.res.nc
          filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_2.sfc_data.nc
          filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_2.fv_srf_wnd.res.nc
          filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.cor_rv_2.coupler.res
      output model files:
      - parameter: nicas_norm
        component: 1
        file:
          filetype: fms restart
          skip coupler file: true
          datapath: ${Data_dir}/newstaticb/
          filename_core: nicas_norm_1.fv_core.res.nc
          filename_trcr: nicas_norm_1.fv_tracer.res.nc
          filename_sfcd: nicas_norm_1.sfc_data.nc
          filename_sfcw: nicas_norm_1.fv_srf_wnd.res.nc
          filename_cplr: nicas_norm_1.coupler.res
      - parameter: nicas_norm
        component: 2
        file:
          filetype: fms restart
          skip coupler file: true
          datapath: ${Data_dir}/newstaticb/
          filename_core: nicas_norm_2.fv_core.res.nc
          filename_trcr: nicas_norm_2.fv_tracer.res.nc
          filename_sfcd: nicas_norm_2.sfc_data.nc
          filename_sfcw: nicas_norm_2.fv_srf_wnd.res.nc
          filename_cplr: nicas_norm_2.coupler.res
EOF
