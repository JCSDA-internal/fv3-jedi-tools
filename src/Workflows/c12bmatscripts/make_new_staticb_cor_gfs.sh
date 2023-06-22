dates=("$@")
bg_date=${dates[-2]}
bgYYYY=${bg_date:0:4}
bgMM=${bg_date:4:2}
bgDD=${bg_date:6:2}
bgHH=${bg_date:8:2}

cat << EOF > new_staticb_cor_gfs.yaml
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
  datapath: ${balanced_dir}/mem001/
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
        data directory: ${Data_dir}/newstaticb
      drivers:
        compute covariance: true
        compute correlation: true
        multivariate strategy: univariate
        read local sampling: true
        read moments: true
        write diagnostics: true
        write diagnostics detail: true
        write universe radius: true
      ensemble sizes:
        total ensemble size: 30
        sub-ensembles: 3
      sampling:
        distance classes: 10
        distance class width: 500.0e3
        reduced levels: 5
      diagnostics:
        target ensemble size: 30
      fit:
        vertical filtering length-scale: 0.1
        number of components: 2
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
          files prefix: cor_3D_gfs
          overriding sampling file: var-mom_3D_${dates[0]}_gfs_sampling
          overriding moments file:
EOF

for date in "${dates[@]}"; do
cat << EOF >> new_staticb_cor_gfs.yaml
          - var-mom_3D_${date}_gfs_mom_000001_1
EOF
done

cat << EOF >> new_staticb_cor_gfs.yaml
      - model:
          variables:
          - surface_pressure
        io:
          files prefix: cor_2D_gfs
          overriding sampling file: var-mom_2D_${dates[0]}_gfs_sampling
          overriding moments file:
EOF

for date in "${dates[@]}"; do
cat << EOF >> new_staticb_cor_gfs.yaml
          - var-mom_2D_${date}_gfs_mom_000001_1
EOF
done

cat << EOF >> new_staticb_cor_gfs.yaml
      output model files:
      - parameter: cor_a
        component: 1
        file:
          filetype: fms restart
          datapath: ${Data_dir}/newstaticb
          filename_core: cor_a_1.fv_core.res.nc
          filename_trcr: cor_a_1.fv_tracer.res.nc
          filename_sfcd: cor_a_1.sfc_data.nc
          filename_sfcw: cor_a_1.fv_srf_wnd.res.nc
          filename_cplr: cor_a_1.coupler.res
      - parameter: cor_a
        component: 2
        file:
          filetype: fms restart
          datapath: ${Data_dir}/newstaticb
          filename_core: cor_a_2.fv_core.res.nc
          filename_trcr: cor_a_2.fv_tracer.res.nc
          filename_sfcd: cor_a_2.sfc_data.nc
          filename_sfcw: cor_a_2.fv_srf_wnd.res.nc
          filename_cplr: cor_a_2.coupler.res
      - parameter: cor_rh
        component: 1
        file:
          filetype: fms restart
          datapath: ${Data_dir}/newstaticb
          filename_core: cor_rh_1.fv_core.res.nc
          filename_trcr: cor_rh_1.fv_tracer.res.nc
          filename_sfcd: cor_rh_1.sfc_data.nc
          filename_sfcw: cor_rh_1.fv_srf_wnd.res.nc
          filename_cplr: cor_rh_1.coupler.res
      - parameter: cor_rh
        component: 2
        file:
          filetype: fms restart
          datapath: ${Data_dir}/newstaticb
          filename_core: cor_rh_2.fv_core.res.nc
          filename_trcr: cor_rh_2.fv_tracer.res.nc
          filename_sfcd: cor_rh_2.sfc_data.nc
          filename_sfcw: cor_rh_2.fv_srf_wnd.res.nc
          filename_cplr: cor_rh_2.coupler.res
      - parameter: cor_rv
        component: 1
        file:
          filetype: fms restart
          datapath: ${Data_dir}/newstaticb
          filename_core: cor_rv_1.fv_core.res.nc
          filename_trcr: cor_rv_1.fv_tracer.res.nc
          filename_sfcd: cor_rv_1.sfc_data.nc
          filename_sfcw: cor_rv_1.fv_srf_wnd.res.nc
          filename_cplr: cor_rv_1.coupler.res
      - parameter: cor_rv
        component: 2
        file:
          filetype: fms restart
          datapath: ${Data_dir}/newstaticb
          filename_core: cor_rv_2.fv_core.res.nc
          filename_trcr: cor_rv_2.fv_tracer.res.nc
          filename_sfcd: cor_rv_2.sfc_data.nc
          filename_sfcw: cor_rv_2.fv_srf_wnd.res.nc
          filename_cplr: cor_rv_2.coupler.res
EOF
