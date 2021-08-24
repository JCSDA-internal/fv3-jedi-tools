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
  window begin: ${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z
  window length: PT6H
  analysis variables: &vars [ua,va,t,ps,sphum,ice_wat,liq_wat,o3mr]

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
    datapath: ${data_dir_c384}/${bkg_obs_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: *vars
    psinfile: true
 
  background error:
    covariance model: ID

  observations:
  - obs space:
      name: Aircraft
      obsdatain:
        obsfile: ${data_dir}/obs/ncdiag.oper_3d.ob.PT6H.aircraft.${yyyy_obs}-${mm_obs}-${dd_obs}T${hh_obs}:00:00Z.nc4
      simulated variables: [air_temperature]
    obs operator:
      name: VertInterp
    obs error:
      covariance model: diagonal

variational:

  minimizer:
    algorithm: DRIPCG

  iterations:
  - ninner: 10
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
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${HOME}/gnu-openmpi_env.sh

cd ${work_dir}/variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_var.x ${yaml_dir}/${yaml_name}

exit 0
EOF
