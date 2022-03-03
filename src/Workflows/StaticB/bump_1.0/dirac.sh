#!/bin/bash

####################################################################
# DIRAC_COR_LOCAL ##################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COR_LOCAL yaml
yaml_name="dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  state variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: *active_vars
    output variables: *active_vars
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_c384}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
output dirac:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: ["psi","psi","psi","psi","psi","psi","chi","chi","chi","chi","chi","chi","t","t","t","t","t","t","sphum","sphum","sphum","sphum","sphum","sphum","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","o3mr","o3mr","o3mr","o3mr","o3mr","o3mr","ps","ps","ps","ps","ps","ps"]
EOF

# DIRAC_COR_LOCAL sbatch
sbatch_name="dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# DIRAC_COR_GLOBAL #################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COR_GLOBAL yaml
yaml_name="dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  state variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: *active_vars
    output variables: *active_vars
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_c384}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_global: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
output dirac:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: ["psi","psi","psi","psi","psi","psi","chi","chi","chi","chi","chi","chi","t","t","t","t","t","t","sphum","sphum","sphum","sphum","sphum","sphum","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","o3mr","o3mr","o3mr","o3mr","o3mr","o3mr","ps","ps","ps","ps","ps","ps"]
EOF

# DIRAC_COR_GLOBAL sbatch
sbatch_name="dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=2
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# DIRAC_COV_LOCAL ##################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_LOCAL yaml
yaml_name="dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  state variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: *control_vars
    output variables: *control_vars
    active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_c384}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: StdDev
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    file:
      filetype: gfs
      psinfile: true
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: stddev.fv_core.res.nc
      filename_trcr: stddev.fv_tracer.res.nc
      filename_cplr: stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
output dirac:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: ["psi","psi","psi","psi","psi","psi","chi","chi","chi","chi","chi","chi","t","t","t","t","t","t","sphum","sphum","sphum","sphum","sphum","sphum","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","o3mr","o3mr","o3mr","o3mr","o3mr","o3mr","ps","ps","ps","ps","ps","ps"]
EOF

# DIRAC_COV_LOCAL sbatch
sbatch_name="dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# DIRAC_COV_GLOBAL #################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_GLOBAL yaml
yaml_name="dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  state variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: *control_vars
    output variables: *control_vars
    active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_c384}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_global: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: StdDev
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    file:
      filetype: gfs
      psinfile: true
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: stddev.fv_core.res.nc
      filename_trcr: stddev.fv_tracer.res.nc
      filename_cplr: stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
output dirac:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 42
  ixdir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,1,1,1,1,1,1]
  itdir: [1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6,1,2,3,4,5,6]
  ifdir: ["psi","psi","psi","psi","psi","psi","chi","chi","chi","chi","chi","chi","t","t","t","t","t","t","sphum","sphum","sphum","sphum","sphum","sphum","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","liq_wat","o3mr","o3mr","o3mr","o3mr","o3mr","o3mr","ps","ps","ps","ps","ps","ps"]
EOF

# DIRAC_COV_GLOBAL sbatch
sbatch_name="dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=2
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# DIRAC_COV_MULTI_LOCAL ############################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_MULTI_LOCAL yaml
yaml_name="dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  state variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: *control_vars
    output variables: *control_vars
    active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_c384}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: StdDev
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    file:
      filetype: gfs
      psinfile: true
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: stddev.fv_core.res.nc
      filename_trcr: stddev.fv_tracer.res.nc
      filename_cplr: stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: BUMP_VerticalBalance
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
output dirac:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
EOF

# DIRAC_COV_MULTI_LOCAL sbatch
sbatch_name="dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# DIRAC_COV_MULTI_GLOBAL ###########################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COV_MULTI_GLOBAL yaml
yaml_name="dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  state variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: *control_vars
    output variables: *control_vars
    active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_c384}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_global: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: StdDev
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    file:
      filetype: gfs
      psinfile: true
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: stddev.fv_core.res.nc
      filename_trcr: stddev.fv_tracer.res.nc
      filename_cplr: stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: BUMP_VerticalBalance
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_global: true
      vbal_block: [true, true,false, true,false,false]
output dirac:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
EOF

# DIRAC_COV_MULTI_GLOBAL sbatch
sbatch_name="dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=2
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# DIRAC_FULL_C2A_LOCAL #############################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_C2A_LOCAL yaml
yaml_name="dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/${bkg_dir}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  state variables: &state_vars [ua,va,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    output variables: *control_vars
    active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_c384}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: StdDev
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    file:
      filetype: gfs
      psinfile: true
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: stddev.fv_core.res.nc
      filename_trcr: stddev.fv_tracer.res.nc
      filename_cplr: stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: BUMP_VerticalBalance
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  variable changes:
  - variable change: Control2Analysis
    input variables: *control_vars
    output variables: *state_vars
output dirac:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
EOF

# DIRAC_FULL_C2A_LOCAL sbatch
sbatch_name="dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# DIRAC_FULL_PSICHITOUV_LOCAL ######################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_PSICHITOUV_LOCAL yaml
yaml_name="dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/${bkg_dir}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  state variables: &state_vars [ua,va,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    output variables: *control_vars
    active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_c384}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: StdDev
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    file:
      filetype: gfs
      psinfile: true
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: stddev.fv_core.res.nc
      filename_trcr: stddev.fv_tracer.res.nc
      filename_cplr: stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: BUMP_VerticalBalance
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  - saber block name: BUMP_PsiChiToUV
    input variables: *control_vars
    output variables: *state_vars
    active variables: [psi,chi,ua,va]
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_wind_local: true
output dirac:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
EOF

# DIRAC_FULL_PSICHITOUV_LOCAL sbatch
sbatch_name="dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# DIRAC_FULL_GLOBAL ################################################
####################################################################

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_GLOBAL yaml
yaml_name="dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/${bkg_dir}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  state variables: &state_vars [ua,va,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    output variables: *control_vars
    active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_c384}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_global: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: StdDev
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    file:
      filetype: gfs
      psinfile: true
      datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: stddev.fv_core.res.nc
      filename_trcr: stddev.fv_tracer.res.nc
      filename_cplr: stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: BUMP_VerticalBalance
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_global: true
      vbal_block: [true, true,false, true,false,false]
  - saber block name: BUMP_PsiChiToUV
    input variables: *control_vars
    output variables: *state_vars
    active variables: [psi,chi,ua,va]
    bump:
      datadir: ${data_dir_c384}/${bump_dir}
      prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_wind_local: true
output dirac:
  filetype: gfs
  datapath: ${data_dir_c384}/${bump_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
dirac:
  ndir: 6
  ixdir: [192,192,192,192,192,192]
  iydir: [192,192,192,192,192,192]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
EOF

# DIRAC_FULL_GLOBAL sbatch
sbatch_name="dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_def}
cpus_per_task=2
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=01:00:00
#SBATCH -e ${work_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF

####################################################################
# DIRAC_FULL_REGRID_LOCAL ##########################################
####################################################################

# Create directories
mkdir -p ${data_dir_regrid}/${bump_dir}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_FULL_REGRID_LOCAL yaml
yaml_name="dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
initial condition:
  filetype: gfs
  datapath: ${data_dir_regrid}/${bump_dir}/${bkg_dir}
  filename_cplr: coupler.res
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  state variables: &state_vars [ua,va,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
background error:
  covariance model: SABER
  saber blocks:
  - saber block name: BUMP_NICAS
    saber central block: true
    input variables: &control_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    output variables: *control_vars
    active variables: &active_vars [psi,chi,t,ps,sphum,liq_wat,o3mr]
    bump:
      prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
      datadir: ${data_dir_regrid}/${bump_dir}
      verbosity: main
      strategy: specific_univariate
      load_nicas_local: true
      min_lev:
        liq_wat: 76
      grids:
      - variables: [stream_function,velocity_potential,air_temperature,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas
      - variables: [surface_pressure]
        fname_nicas: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas
      universe radius:
        filetype: gfs
        psinfile: true
        datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
        filename_core: cor_rh.fv_core.res.nc
        filename_trcr: cor_rh.fv_tracer.res.nc
        filename_cplr: cor_rh.coupler.res
        date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: StdDev
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    file:
      filetype: gfs
      psinfile: true
      datapath: ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
      filename_core: stddev.fv_core.res.nc
      filename_trcr: stddev.fv_tracer.res.nc
      filename_cplr: stddev.coupler.res
      date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  - saber block name: BUMP_VerticalBalance
    input variables: *control_vars
    output variables: *control_vars
    active variables: *active_vars
    bump:
      datadir: ${data_dir_regrid}/${bump_dir}
      prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_vbal: true
      fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
      load_samp_local: true
      vbal_block: [true, true,false, true,false,false]
  - saber block name: BUMP_PsiChiToUV
    input variables: *control_vars
    output variables: *state_vars
    active variables: [psi,chi,ua,va]
    bump:
      datadir: ${data_dir_regrid}/${bump_dir}
      prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
      verbosity: main
      universe_rad: 2000.0e3
      load_wind_local: true
output dirac:
  filetype: gfs
  datapath: ${data_dir_regrid}/${bump_dir}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  psinfile: true
  filename_core: dirac_%id%.fv_core.res.nc
  filename_trcr: dirac_%id%.fv_tracer.res.nc
  filename_cplr: dirac_%id%.coupler.res
  date: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
dirac:
  ndir: 6
  ixdir: [${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid}]
  iydir: [${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid},${dirac_center_regrid}]
  ildir: [50,50,50,50,50,50]
  itdir: [1,2,3,4,5,6]
  ifdir: ["t","t","t","t","t","t"]
EOF

# DIRAC_FULL_REGRID_LOCAL sbatch
sbatch_name="dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
ntasks=${ntasks_regrid}
cpus_per_task=1
threads=1
ppn=$((cores_per_node/cpus_per_task))
nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.out

cd ${work_dir}/dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}

export OMP_NUM_THREADS=${threads}
source ${env_script}
source ${rankfile_script}

SECONDS=0
mpirun -rf ${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/fv3jedi_dirac.x ${yaml_dir}/${yaml_name}
wait
echo "ELAPSED TIME = ${SECONDS}"

exit 0
EOF
