#!/bin/bash

dates=("$@")
bg_date=${dates[-2]}
bgYYYY=${bg_date:0:4}
bgMM=${bg_date:4:2}
bgDD=${bg_date:6:2}
bgHH=${bg_date:8:2}

cat << EOF > new_ensembleb_nicas_gfs.yaml

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
  state variables: [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,cloud_liquid_ice,ozone_mass_mixing_ratio]
  datapath: ${ensemble_dir}/mem001/
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
        data directory: ${ensembleb_dir}
        files prefix: nicas_gfs
        overriding universe radius file: loc_gfs_universe_radius
      drivers:
        multivariate strategy: duplicated
        read universe radius: true
        compute nicas: true
        write local nicas: true
        write global nicas: true
      nicas:
        resolution: 6
      input model files:
      - parameter: rh
        file:
          set datetime on read: true
          skip coupler file: true
          datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
          filetype: fms restart
          psinfile: true
          datapath: ${ensembleb_dir}
          filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rh.fv_core.res.nc
          filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rh.fv_tracer.res.nc
          filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rh.sfc_data.nc
          filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rh.fv_srf_wnd.res.nc
          filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rh.coupler.res
      - parameter: rv
        file:
          set datetime on read: true
          skip coupler file: true
          datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
          filetype: fms restart
          psinfile: true
          datapath: ${ensembleb_dir}
          filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rv.fv_core.res.nc
          filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rv.fv_tracer.res.nc
          filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rv.sfc_data.nc
          filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rv.fv_srf_wnd.res.nc
          filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.loc_rv.coupler.res
      output model files:
      - parameter: nicas_norm
        file:
          filetype: fms restart
          datapath: ${ensembleb_dir}
          filename_core: nicas_norm.fv_core.res.nc
          filename_trcr: nicas_norm.fv_tracer.res.nc
          filename_sfcd: nicas_norm.sfc_data.nc
          filename_sfcw: nicas_norm.fv_srf_wnd.res.nc
          filename_cplr: nicas_norm.coupler.res
EOF
