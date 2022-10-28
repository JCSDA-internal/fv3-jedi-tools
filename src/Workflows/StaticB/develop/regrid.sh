#!/bin/bash

# Source functions
source ./functions.sh

# Create data directories
mkdir -p ${ensemble_dir}/c${cregrid}
mkdir -p ${data_dir_regrid}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
mkdir -p ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_last}+${rr}
mkdir -p ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
for var in ${vars}; do
   mkdir -p ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
done

####################################################################
# STATES ###########################################################
####################################################################

# Job name
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_states_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# STATES yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
input geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
output geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
states:
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [ua,va,air_temperature,delp,specific_humidity,cloud_liquid_water,ice_wat,ozone_mass_mixing_ratio]
    datapath: ${ensemble_dir}/c${cdef}/${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filename_core: gfs.oper.fc_ens.PT${r}H.${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.c${cdef}.fv_core.1.res.nc
    filename_trcr: gfs.oper.fc_ens.PT${r}H.${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.c${cdef}.fv_tracer.1.res.nc
    filename_sfcd: gfs.oper.fc_ens.PT${r}H.${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.c${cdef}.sfc_data.1.nc
    filename_sfcw: gfs.oper.fc_ens.PT${r}H.${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.c${cdef}.fv_srf_wnd.1.res.nc
    filename_cplr: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.PT${r}H.coupler.res.1
  output:
    filetype: fms restart
    datapath: ${ensemble_dir}/c${cregrid}/${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    prepend files with date: false
    filename_core: gfs.oper.fc_ens.PT${r}H.${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.c${cregrid}.fv_core.1.res.nc
    filename_trcr: gfs.oper.fc_ens.PT${r}H.${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.c${cregrid}.fv_tracer.1.res.nc
    filename_sfcd: gfs.oper.fc_ens.PT${r}H.${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.c${cregrid}.sfc_data.1.nc
    filename_sfcw: gfs.oper.fc_ens.PT${r}H.${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.c${cregrid}.fv_srf_wnd.1.res.nc
    filename_cplr: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z.PT${r}H.coupler.res.1
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
    filename_core: unbal.fv_core.res.nc
    filename_trcr: unbal.fv_tracer.res.nc
    filename_cplr: unbal.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
    prepend files with date: false
    filename_core: unbal.fv_core.res.nc
    filename_trcr: unbal.fv_tracer.res.nc
    filename_cplr: unbal.coupler.res
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
    prepend files with date: false
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
    prepend files with date: false
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
    prepend files with date: false
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
    prepend files with date: false
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
EOF

# BACKGROUND sbatch
ntasks=${ntasks_regrid}
cpus_per_task=1
threads=1
time=00:05:00
exe=fv3jedi_convertstate.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}


####################################################################
# VBAL #############################################################
####################################################################

# Job name
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}

# Link input file
ln -sf ${data_dir_def}/${bump_dir}/vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling.nc ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling.nc
ln -sf ${data_dir_def}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_vbal.nc ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_vbal.nc

# VBAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_regrid}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [stream_function,velocity_potential,air_temperature,surface_pressure]
bump:
  datadir: ${data_dir_regrid}/${bump_dir}
  prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal: true
  write_vbal: true
  fname_samp: vbal_${yyyymmddhh_last}+${rr}/vbal_${yyyymmddhh_last}+${rr}_sampling
  ens1_nsub: ${yyyymmddhh_size}
  load_samp_global: true
  write_samp_local: true
  vbal_block: [true, true,false, true,false,false]
EOF

# VBAL sbatch
ntasks=${ntasks_regrid}
cpus_per_task=1
threads=1
time=00:30:00
exe=fv3jedi_error_covariance_training.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# NICAS ############################################################
####################################################################

for var in ${vars}; do
   # Job name
   job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}

   # Link input files
   ln -sf ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}_nicas.nc ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}_nicas.nc

   # NICAS yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_regrid}/${bump_dir}/${yyyymmddhh_last}+${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
  datadir: ${data_dir_regrid}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  load_nicas_global: true
  write_nicas_local: true
  min_lev:
    cloud_liquid_water: 76
input fields:
- parameter: universe radius
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
    date: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
- parameter: nicas_norm
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_${var}
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
    date: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
EOF

   # NICAS sbatch
   ntasks=${ntasks_regrid}
   cpus_per_task=2
   threads=2
   time=00:20:00
   exe=fv3jedi_error_covariance_training.x
   prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
done

####################################################################
# MERGE NICAS ######################################################
####################################################################

# Job name
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}
mkdir -p ${work_dir}/${job}

# Merge NICAS files
ntasks=1
cpus_per_task=${cores_per_node}
threads=1
time=00:30:00
cat<< EOF > ${sbatch_dir}/${job}.sh
#!/bin/bash
#SBATCH --job-name=${job}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=${ntasks}
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --time=${time}
#SBATCH -e ${work_dir}/${job}/${job}.err
#SBATCH -o ${work_dir}/${job}/${job}.out

cd ${work_dir}/${job}

export OMP_NUM_THREADS=${threads}
source ${env_script}
module load nco

# Timer
SECONDS=0

# Number of local files
nlocal=${ntasks_regrid}
ntotpad=\$(printf "%.6d" "\${nlocal}")

for itot in \$(seq 1 \${nlocal}); do
   itotpad=\$(printf "%.6d" "\${itot}")

   # Local full files names
   filename_full=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_nicas_local_\${ntotpad}-\${itotpad}.nc

   # Remove existing local full files
   rm -f \${filename_full}

   # Create scripts to merge local files
   echo "#!/bin/bash" > merge_nicas_\${itotpad}.sh
   for var in ${vars}; do
      filename_var=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_\${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}+${rr}_\${var}_nicas_local_\${ntotpad}-\${itotpad}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}" >> merge_nicas_\${itotpad}.sh
   done
done

# Run scripts in parallel
nbatch=\$((nlocal/${cores_per_node}+1))
itot=0
for ibatch in \$(seq 1 \${nbatch}); do
   for i in \$(seq 1 ${cores_per_node}); do
      itot=\$((itot+1))
      if test "\${itot}" -le "\${nlocal}"; then
         itotpad=\$(printf "%.6d" "\${itot}")
         echo "Batch \${ibatch} - job \${i}: ./merge_nicas_\${itotpad}.sh"
         chmod 755 merge_nicas_\${itotpad}.sh
         ./merge_nicas_\${itotpad}.sh &
      fi
   done
   wait
done

# Timer
wait
echo "ELAPSED TIME = \${SECONDS} s"

exit 0
EOF
