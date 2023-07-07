#!/bin/bash

dates=("$@")
bg_date=${dates[-2]}
bgYYYY=${bg_date:0:4}
bgMM=${bg_date:4:2}
bgDD=${bg_date:6:2}
bgHH=${bg_date:8:2}

cat << EOF > new_ensembleb_loc_gfs.yaml
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
      general:
        universe length-scale: 5000.0e3
      io:
        data directory: ${ensembleb_dir}
        files prefix: loc_gfs
        overriding sampling file: mom_${dates[0]}_gfs_sampling
        overriding moments file:
EOF
for date in "${dates[@]}"; do
cat << EOF >> new_ensembleb_loc_gfs.yaml
        - mom_${date}_gfs_mom_000001_1
EOF
done
cat << EOF >> new_ensembleb_loc_gfs.yaml
      drivers:
        compute covariance: true
        compute correlation: true
        compute localization: true
        multivariate strategy: duplicated
        read local sampling: true
        read moments: true
        write diagnostics: true
        write universe radius: true
      ensemble sizes:
        total ensemble size: 30
        sub-ensembles: 3
      sampling:
        distance classes: 10
        distance class width: 500.0e3
        reduced levels: 5
      diagnostics:
        target ensemble size: 10
      fit:
        vertical filtering length-scale: 0.1
        vertical stride: 127
      output model files:
      - parameter: loc_rh
        file:
          filetype: fms restart
          datapath: ${ensembleb_dir}
          filename_core: loc_rh.fv_core.res.nc
          filename_trcr: loc_rh.fv_tracer.res.nc
          filename_sfcd: loc_rh.sfc_data.nc
          filename_sfcw: loc_rh.fv_srf_wnd.res.nc
          filename_cplr: loc_rh.coupler.res
      - parameter: loc_rv
        file:
          filetype: fms restart
          datapath: ${ensembleb_dir}
          filename_core: loc_rv.fv_core.res.nc
          filename_trcr: loc_rv.fv_tracer.res.nc
          filename_sfcd: loc_rv.sfc_data.nc
          filename_sfcw: loc_rv.fv_srf_wnd.res.nc
          filename_cplr: loc_rv.coupler.res
EOF
