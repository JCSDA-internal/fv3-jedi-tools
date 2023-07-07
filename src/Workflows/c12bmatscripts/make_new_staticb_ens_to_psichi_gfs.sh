#!/bin/bash

dates=("$@")
for date in "${dates[@]}"; do
YYYY=${date:0:4}
MM=${date:4:2}
DD=${date:6:2}
HH=${date:8:2}
cat << EOF > new_staticb_ens_to_psichi_${date}_gfs.yaml
input geometry:
  fms initialization:
    namelist filename: Data/fv3files/fmsmpp.nml
    field table filename: Data/fv3files/field_table_gfdl
  akbk: Data/fv3files/akbk127.nc4
  layout: [1,2]
  npx: 13
  npy: 13
  npz: 127
  field metadata override: Data/fieldmetadata/gfs-restart.yaml
output geometry:
  akbk: Data/fv3files/akbk127.nc4
  layout: [1,2]
  npx: 13
  npy: 13
  npz: 127
  field metadata override: Data/fieldmetadata/gfs-restart.yaml

variable change:
  variable change name: Control2Analysis
  output variables: [psi,chi,t,ps,sphum,liq_wat,ice_wat,o3mr]
  do inverse: true
  femps_iterations: 60
  femps_ngrids: 2
  femps_path2fv3gridfiles: Data/femps/
  femps_checkconvergence: false
states:
EOF
for i in $( seq 0 $(( num_mems - 1 )) ); do
member=mem$(printf "%03d\t" "$i")
cat << EOF >> new_staticb_ens_to_psichi_${date}_gfs.yaml
- input:
    datetime: ${YYYY}-${MM}-${DD}T${HH}:00:00Z
    filetype: fms restart
    skip coupler file: true
    state variables: &readvars [ua,va,t,delp,sphum,liq_wat,ice_wat,o3mr]
    datapath: ${ensemble_dir}/${member}
    filename_core: ${YYYY}${MM}${DD}.${HH}0000.fv_core.res.nc
    filename_trcr: ${YYYY}${MM}${DD}.${HH}0000.fv_tracer.res.nc
    filename_sfcd: ${YYYY}${MM}${DD}.${HH}0000.sfc_data.nc
    filename_sfcw: ${YYYY}${MM}${DD}.${HH}0000.fv_srf_wnd.res.nc
    filename_cplr: ${YYYY}${MM}${DD}.${HH}0000.coupler.res
  output:
    filetype: fms restart
    datapath: ${balanced_dir}/${member}
    filename_core: fv_core.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_sfcd: sfc_data.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_cplr: coupler.res
EOF
done
done
