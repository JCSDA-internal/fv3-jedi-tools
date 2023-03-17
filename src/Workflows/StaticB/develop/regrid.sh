#!/bin/bash

# Source functions
source ${script_dir}/functions.sh

# Create data directories
mkdir -p ${data_dir_regrid}/${yyyymmddhh_last}${rr}/mem001
mkdir -p ${data_dir_regrid}/var_${suffix}
mkdir -p ${data_dir_regrid}/cor_${suffix}
mkdir -p ${data_dir_regrid}/nicas_${suffix}
mkdir -p ${data_dir_regrid}/vbal_${yyyymmddhh_last}${rr}
mkdir -p ${data_dir_regrid}/vbal_${suffix}
for var in ${vars}; do
   for icomp in $(seq 1 ${number_of_components}); do
      mkdir -p ${data_dir_regrid}/nicas_${suffix}_${var}_${icomp}
   done
done

####################################################################
# STATES ###########################################################
####################################################################

# Job name
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_states_${suffix}

# STATES yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
input geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  logp: true
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
  logp: true
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
states:
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: &stateVars [eastward_wind,northward_wind,stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
    filename_core: balanced.fv_core.res.nc
    filename_trcr: balanced.fv_tracer.res.nc
    filename_cplr: balanced.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${yyyymmddhh_last}${rr}/mem001
    prepend files with date: false
    filename_core: balanced.fv_core.res.nc
    filename_trcr: balanced.fv_tracer.res.nc
    filename_cplr: balanced.coupler.res
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
    filename_core: unbal.fv_core.res.nc
    filename_trcr: unbal.fv_tracer.res.nc
    filename_cplr: unbal.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${yyyymmddhh_last}${rr}/mem001
    prepend files with date: false
    filename_core: unbal.fv_core.res.nc
    filename_trcr: unbal.fv_tracer.res.nc
    filename_cplr: unbal.coupler.res
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/var_${suffix}
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/var_${suffix}
    prepend files with date: false
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
EOF
for icomp in $(seq 1 ${number_of_components}); do
   cat<< EOF >> ${yaml_dir}/${job}.yaml
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/cor_${suffix}
    filename_core: cor_a_${icomp}.fv_core.res.nc
    filename_trcr: cor_a_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_a_${icomp}.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/cor_${suffix}
    prepend files with date: false
    filename_core: cor_a_${icomp}.fv_core.res.nc
    filename_trcr: cor_a_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_a_${icomp}.coupler.res
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/cor_${suffix}
    filename_core: cor_rh_${icomp}.fv_core.res.nc
    filename_trcr: cor_rh_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_rh_${icomp}.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/cor_${suffix}
    prepend files with date: false
    filename_core: cor_rh_${icomp}.fv_core.res.nc
    filename_trcr: cor_rh_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_rh_${icomp}.coupler.res
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/cor_${suffix}
    filename_core: cor_rv_${icomp}.fv_core.res.nc
    filename_trcr: cor_rv_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_rv_${icomp}.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/cor_${suffix}
    prepend files with date: false
    filename_core: cor_rv_${icomp}.fv_core.res.nc
    filename_trcr: cor_rv_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_rv_${icomp}.coupler.res
- input:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
    psinfile: true
    datapath: ${data_dir_def}/nicas_${suffix}
    filename_core: nicas_norm_${icomp}.fv_core.res.nc
    filename_trcr: nicas_norm_${icomp}.fv_tracer.res.nc
    filename_cplr: nicas_norm_${icomp}.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/nicas_${suffix}
    prepend files with date: false
    filename_core: nicas_norm_${icomp}.fv_core.res.nc
    filename_trcr: nicas_norm_${icomp}.fv_tracer.res.nc
    filename_cplr: nicas_norm_${icomp}.coupler.res
EOF
done

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
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_vbal_${suffix}

# Link input file
ln -sf ${data_dir_def}/vbal_${yyyymmddhh_last}${rr}/vbal_${yyyymmddhh_last}${rr}_sampling.nc ${data_dir_regrid}/vbal_${yyyymmddhh_last}${rr}/vbal_${yyyymmddhh_last}${rr}_sampling.nc
ln -sf ${data_dir_def}/vbal_${suffix}/vbal_${suffix}_vbal.nc ${data_dir_regrid}/vbal_${suffix}/vbal_${suffix}_vbal.nc

# VBAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  logp: true
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
  datapath: ${data_dir_regrid}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [stream_function,velocity_potential,air_temperature,surface_pressure]
bump:
  general:
    universe length-scale: 2000.0e3
  io:
    data directory: ${data_dir_regrid}
    files prefix: vbal_${suffix}/vbal_${suffix}
    overriding sampling file: vbal_${yyyymmddhh_last}${rr}/vbal_${yyyymmddhh_last}${rr}_sampling
  drivers:
    read global sampling: true
    write local sampling: true
    read vertical balance: true
    write vertical balance: true
  ensemble sizes:
    sub-ensembles: ${yyyymmddhh_size}
  vertical balance:
    vbal:
    - balanced variable: velocity_potential
      unbalanced variable: stream_function
    - balanced variable: air_temperature
      unbalanced variable: stream_function
    - balanced variable: surface_pressure
      unbalanced variable: stream_function
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
   for icomp in $(seq 1 ${number_of_components}); do
      # Job name
      job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_nicas_${suffix}_${var}_${icomp}

      # Link input files
      ln -sf ${data_dir_def}/nicas_${suffix}/nicas_${suffix}_nicas.nc ${data_dir_regrid}/nicas_${suffix}_${var}_${icomp}/nicas_${suffix}_${var}_${icomp}_nicas.nc

      # NICAS yaml
      cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  logp: true
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
  datapath: ${data_dir_regrid}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  io:
    data directory: ${data_dir_regrid}
    files prefix: nicas_${suffix}_${var}/nicas_${suffix}_${var}
  drivers:
    multivariate strategy: univariate
    read global nicas: true
    write local nicas: true
  nicas:
    interpolation type:
    - groups: [stream_function,velocity_potential,air_temperature,surface_pressure]
      type: si
    overriding component in file: ${icomp}
input fields:
- parameter: universe radius
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_regrid}/cor_${suffix}
    filename_core: cor_rh_${icomp}.fv_core.res.nc
    filename_trcr: cor_rh_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_rh_${icomp}.coupler.res
    date: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
- parameter: a
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_regrid}/cor_${suffix}
    filename_core: cor_a_${icomp}.fv_core.res.nc
    filename_trcr: cor_a_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_a_${icomp}.coupler.res
    date: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
- parameter: rh
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_regrid}/cor_${suffix}
    filename_core: cor_rh_${icomp}.fv_core.res.nc
    filename_trcr: cor_rh_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_rh_${icomp}.coupler.res
    date: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
- parameter: rv
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_regrid}/cor_${suffix}
    filename_core: cor_rv_${icomp}.fv_core.res.nc
    filename_trcr: cor_rv_${icomp}.fv_tracer.res.nc
    filename_cplr: cor_rv_${icomp}.coupler.res
    date: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
- parameter: nicas_norm
  file:
    datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/nicas_${suffix}
    filename_core: nicas_norm_${icomp}.fv_core.res.nc
    filename_trcr: nicas_norm_${icomp}.fv_tracer.res.nc
    filename_cplr: nicas_norm_${icomp}.coupler.res
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
done

####################################################################
# MERGE NICAS ######################################################
####################################################################

# Job name
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_merge_nicas_${suffix}
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
   filename_full=${data_dir_regrid}/nicas_${suffix}/nicas_${suffix}_nicas_local_\${ntotpad}-\${itotpad}.nc

   # Remove existing local full files
   rm -f \${filename_full}

   # Create scripts to merge local files
   echo "#!/bin/bash" > merge_nicas_\${itotpad}.sh
   for var in ${vars}; do
      for icomp in \${number_of_components}; do
         filename_var_comp=${data_dir_regrid}/nicas_${suffix}_\${var}_\${icomp}/nicas_${suffix}_\${var}_\${icomp}_nicas_local_\${ntotpad}-\${itotpad}.nc
         echo -e "ncks -A \${filename_var}_\${icomp} \${filename_full}" >> merge_nicas_\${itotpad}.sh
      done
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
