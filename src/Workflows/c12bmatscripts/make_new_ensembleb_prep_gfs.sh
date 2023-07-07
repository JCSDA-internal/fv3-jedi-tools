#!/bin/bash

dates=("$@")
for date in "${dates[@]}"; do
YYYY=${date:0:4}
MM=${date:4:2}
DD=${date:6:2}
HH=${date:8:2}

cat << EOF > new_ensembleb_prep_${date}_gfs.yaml
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
  state variables: &stateVariables [eastward_wind,northward_wind,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,cloud_liquid_ice,ozone_mass_mixing_ratio]
  datapath: ${ensemble_dir}/mem001/
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
        skip coupler file: true
        state variables: *stateVariables
        datapath: ${ensemble_dir}/mem%mem%/
        filename_core: ${YYYY}${MM}${DD}.${HH}0000.fv_core.res.nc
        filename_trcr: ${YYYY}${MM}${DD}.${HH}0000.fv_tracer.res.nc
        filename_sfcd: ${YYYY}${MM}${DD}.${HH}0000.sfc_data.nc
        filename_sfcw: ${YYYY}${MM}${DD}.${HH}0000.fv_srf_wnd.res.nc
        filename_cplr: ${YYYY}${MM}${DD}.${HH}0000.coupler.res
      pattern: '%mem%'
      nmembers: ${num_mems}
      start: 0
      zero padding: 3
  saber central block:
    saber block name: BUMP_NICAS
    calibration:
      general:
        universe length-scale: 5000.0e3
      io:
        data directory: ${ensembleb_dir}
        files prefix: mom_${date}_gfs
      drivers:
        multivariate strategy: duplicated
        write local sampling: true
        compute moments: true
        write moments: true
      sampling:
        computation grid size: 500
        distance classes: 10
        distance class width: 500.0e3
        reduced levels: 5
        grid type: octahedral
EOF
done
