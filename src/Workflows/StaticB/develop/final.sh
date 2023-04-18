#!/bin/bash

# Source functions
source ${script_dir}/functions.sh

# Create data directories
mkdir -p ${data_dir_def}/vbal_${suffix}
mkdir -p ${data_dir_def}/var_${suffix}
mkdir -p ${data_dir_def}/cor_${suffix}
for var in ${vars}; do 
  for icomp in $(seq 1 ${number_of_components}); do
    mkdir -p ${data_dir_def}/nicas_${suffix}_${var}_${icomp}
  done
done
mkdir -p ${data_dir_def}/nicas_${suffix}

####################################################################
# VBAL #############################################################
####################################################################

# Job name
job=vbal_${suffix}

# VBAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  logp: true
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: ID
  saber outer blocks:
  - saber block name: BUMP_VerticalBalance
    active variables: [stream_function,velocity_potential,air_temperature,surface_pressure]
    calibration:
      general:
        universe length-scale: 2000.0e3
      io:
        data directory: ${data_dir_def}
        files prefix: vbal_${suffix}/vbal_${suffix}
EOF
if test "${from_gsi}" = "true"; then
  # GSI-based
  cat<< EOF >> ${yaml_dir}/${job}.yaml
        gsi data file: gsi-coeffs-gmao-global-l72x72y46
        gsi namelist: dirac_gsi_geos_global.nml
      drivers:
        write local sampling: true
        write global sampling: true
        compute vertical balance: true
        write vertical balance: true
        interpolate from gsi data: true
      sampling:
        diagnostic grid size: 89
      vertical balance:
        vbal:
        - balanced variable: velocity_potential
          unbalanced variable: stream_function
        - balanced variable: air_temperature
          unbalanced variable: stream_function
        - balanced variable: surface_pressure
          unbalanced variable: stream_function
EOF
else
  # Ensemble-based
  cat<< EOF >> ${yaml_dir}/${job}.yaml
        overriding sampling file: vbal_${yyyymmddhh_last}${rr}/vbal_${yyyymmddhh_last}${rr}_sampling
        overriding vertical covariance file:
EOF
  for yyyymmddhh in ${yyyymmddhh_list}; do
    cat<< EOF >> ${yaml_dir}/${job}.yaml
        - vbal_${yyyymmddhh}${rr}/vbal_${yyyymmddhh}${rr}_vbal_cov
EOF
  done
  cat<< EOF >> ${yaml_dir}/${job}.yaml
      drivers:
        read local sampling: true
        write global sampling: true
        read vertical covariance: true
        compute vertical balance: true
        write vertical balance: true
      ensemble sizes:
        sub-ensembles: ${yyyymmddhh_size}
      sampling:
        averaging length-scale: 2000.0e3 
      vertical balance:
        vbal:
        - balanced variable: velocity_potential
          unbalanced variable: stream_function
          diagonal autocovariance: true
          diagonal regression: true
        - balanced variable: air_temperature
          unbalanced variable: stream_function
          diagonal autocovariance: true
          diagonal regression: true
        - balanced variable: surface_pressure
          unbalanced variable: stream_function
          diagonal autocovariance: true
          diagonal regression: true
EOF
fi

# VBAL sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:30:00
exe=fv3jedi_error_covariance_training.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# VAR ##############################################################
####################################################################

# Job name
job=var_${suffix}

# VAR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  logp: true
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: ID
  saber outer blocks:
  - saber block name: BUMP_StdDev
    calibration:
      general:
        universe length-scale: 3000.0e3
      io:
        data directory: ${data_dir_def}
        files prefix: var_${suffix}/var_${suffix}
EOF
if test "${from_gsi}" = "true"; then
  # GSI-based
  cat<< EOF >> ${yaml_dir}/${job}.yaml
        gsi data file: gsi-coeffs-gmao-global-l72x72y46
        gsi namelist: dirac_gsi_geos_global.nml
      drivers:
        compute variance: true
        interpolate from gsi data: true
EOF
else
  # Ensemble-based
  cat<< EOF >> ${yaml_dir}/${job}.yaml
      ensemble sizes:
        sub-ensembles: ${yyyymmddhh_size}
      variance:
        objective filtering: true
        filtering iterations: 1
        initial length-scale:
        - variables: *stateVars
          value: 3000.0e3
      diagnostics:
        target ensemble size: $((nmem*yyyymmddhh_size))
      input model files:
EOF
  icomp=1
  for yyyymmddhh in ${yyyymmddhh_list}; do
    yyyy=${yyyymmddhh:0:4}
    mm=${yyyymmddhh:4:2}
    dd=${yyyymmddhh:6:2}
    hh=${yyyymmddhh:8:2}
    yyyymmddhh_fc=`date -d "${yyyy}${mm}${dd} +${hh} hours ${rr} hours" '+%Y%m%d%H'`
    yyyy_fc=${yyyymmddhh_fc:0:4}
    mm_fc=${yyyymmddhh_fc:4:2}
    dd_fc=${yyyymmddhh_fc:6:2}
    hh_fc=${yyyymmddhh_fc:8:2}
    cat<< EOF >> ${yaml_dir}/${job}.yaml
      - parameter: var
        component: ${icomp}
        file:
          datetime: ${yyyy_fc}-${mm_fc}-${dd_fc}T${hh_fc}:00:00Z
          filetype: fms restart
          datapath: ${data_dir_def}/var-mom_${yyyymmddhh}${rr}
          set datetime on read: true
          psinfile: true
          filename_core: var.fv_core.res.nc
          filename_trcr: var.fv_tracer.res.nc
          filename_cplr: var.coupler.res
      - parameter: m4
        component: ${icomp}
        file:
          datetime: ${yyyy_fc}-${mm_fc}-${dd_fc}T${hh_fc}:00:00Z
          filetype: fms restart
          datapath: ${data_dir_def}/var-mom_${yyyymmddhh}${rr}
          set datetime on read: true
          psinfile: true
          filename_core: m4.fv_core.res.nc
          filename_trcr: m4.fv_tracer.res.nc
          filename_cplr: m4.coupler.res
EOF
    icomp=$((icomp+1))
  done
fi
cat<< EOF >> ${yaml_dir}/${job}.yaml
      output model files:
      - parameter: stddev
        file:
          filetype: fms restart
          datapath: ${data_dir_def}/var_${suffix}
          prepend files with date: false
          filename_core: stddev.fv_core.res.nc
          filename_trcr: stddev.fv_tracer.res.nc
          filename_cplr: stddev.coupler.res
EOF

# VAR sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=01:00:00
exe=fv3jedi_error_covariance_training.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# COR ##############################################################
####################################################################

# Job name
job=cor_${suffix}

# COR yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  logp: true
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    calibration:
      general:
        universe length-scale: 4000.0e3
      io:
        data directory: ${data_dir_def}
        files prefix: cor_${suffix}/cor_${suffix}
EOF
if test "${from_gsi}" = "true"; then
  # GSI-based
  cat<< EOF >> ${yaml_dir}/${job}.yaml
        gsi data file: gsi-coeffs-gmao-global-l72x72y46
        gsi namelist: dirac_gsi_geos_global.nml
      drivers:
        multivariate strategy: specific_univariate
        compute correlation: true
        write universe radius: true
        interpolate from gsi data: true
      sampling:
        diagnostic grid size: 89
      fit:
        number of components: ${number_of_components}
EOF
else
  # Ensemble-based
  cat<< EOF >> ${yaml_dir}/${job}.yaml
        overriding moments file:
EOF
  for yyyymmddhh in ${yyyymmddhh_list}; do
    cat<< EOF >> ${yaml_dir}/${job}.yaml
        - var-mom_${yyyymmddhh}${rr}/var-mom_${yyyymmddhh}${rr}_mom_000001_1
EOF
  done
  cat<< EOF >> ${yaml_dir}/${job}.yaml
        overriding sampling file: var-mom_${yyyymmddhh_last}${rr}/var-mom_${yyyymmddhh_last}${rr}_sampling
      drivers:
        compute correlation: true
        multivariate strategy: univariate
        read local sampling: true
        read moments: true
        write universe radius: true
        write diagnostics: true
      ensemble sizes:
        total ensemble size: $((nmem*yyyymmddhh_size))
        sub-ensembles: ${yyyymmddhh_size}
      sampling:
        angular sectors: ${angular_sectors}
        computation grid size: 5000
        diagnostic grid size: 1000
        distance classes: 50
        distance class width: 75.0e3
        reduced levels: 15
        local diagnostic: true
        averaging length-scale: 2000.0e3
      diagnostics:
        target ensemble size: $((nmem*yyyymmddhh_size))
        diagnosed lengths scaling: 4.0
      fit:
        vertical filtering length-scale: 0.1
        horizontal filtering length-scale: 2000.0e3
        number of components: ${number_of_components}
EOF
fi
cat<< EOF >> ${yaml_dir}/${job}.yaml
      output model files:
EOF
for icomp in $(seq 1 ${number_of_components}); do
  cat<< EOF >> ${yaml_dir}/${job}.yaml
      - parameter: cor_a
        component: ${icomp}
        file:
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          prepend files with date: false
          filename_core: cor_a_${icomp}.fv_core.res.nc
          filename_trcr: cor_a_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_a_${icomp}.coupler.res
      - parameter: cor_rh
        component: ${icomp}
        file:
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          prepend files with date: false
          filename_core: cor_rh_${icomp}.fv_core.res.nc
          filename_trcr: cor_rh_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rh_${icomp}.coupler.res
EOF
  if [ ${angular_sectors} -gt 1 ]; then
    cat<< EOF >> ${yaml_dir}/${job}.yaml
      - parameter: cor_rh1
        component: ${icomp}
        file:
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          prepend files with date: false
          filename_core: cor_rh1_${icomp}.fv_core.res.nc
          filename_trcr: cor_rh1_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rh1_${icomp}.coupler.res
      - parameter: cor_rh2
        component: ${icomp}
        file:
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          prepend files with date: false
          filename_core: cor_rh2_${icomp}.fv_core.res.nc
          filename_trcr: cor_rh2_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rh2_${icomp}.coupler.res
      - parameter: cor_rhc
        component: ${icomp}
        file:
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          prepend files with date: false
          filename_core: cor_rhc_${icomp}.fv_core.res.nc
          filename_trcr: cor_rhc_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rhc_${icomp}.coupler.res
EOF
  fi
  cat<< EOF >> ${yaml_dir}/${job}.yaml
      - parameter: cor_rv
        component: ${icomp}
        file:
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          prepend files with date: false
          filename_core: cor_rv_${icomp}.fv_core.res.nc
          filename_trcr: cor_rv_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rv_${icomp}.coupler.res
EOF
done

# COR sbatch
ntasks=${ntasks_def}
cpus_per_task=2
threads=2
time=00:30:00
exe=fv3jedi_error_covariance_training.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# NICAS ############################################################
####################################################################

for var in ${vars}; do
  for icomp in $(seq 1 ${number_of_components}); do
    # Job name
    job=nicas_${suffix}_${var}_${icomp}

    # NICAS yaml
    cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  logp: true
  layout: [${nlx_def},${nly_def}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: 127
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
  filetype: fms restart
  state variables: &stateVars [stream_function,velocity_potential,air_temperature,surface_pressure,specific_humidity,cloud_liquid_water,ozone_mass_mixing_ratio]
  psinfile: true
  datapath: ${data_dir_def}/${yyyymmddhh_last}${rr}/mem001
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: BUMP_NICAS
    active variables: [${var}]
    calibration:
      general:
        universe length-scale: 5000.0e3
      io:
        data directory: ${data_dir_def}
        files prefix: nicas_${suffix}_${var}_${icomp}/nicas_${suffix}_${var}_${icomp}
        overriding universe radius file: cor_${suffix}/cor_${suffix}_universe_radius
      drivers:
        multivariate strategy: univariate
        read universe radius: true
        compute nicas: true
        write local nicas: true
        write global nicas: true
      nicas:
        resolution: 10.0
        max horizontal grid size: 50000
        grid type: octahedral
        interpolation type:
        - groups: [stream_function,velocity_potential,air_temperature,surface_pressure]
          type: si
        overriding component in file: ${icomp}
        minimum level:
        - groups: [cloud_liquid_water]
          value: 76
      input model file:
      - parameter: a
        file:
          datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          set datetime on read: true
          psinfile: true
          filename_core: cor_a_${icomp}.fv_core.res.nc
          filename_trcr: cor_a_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_a_${icomp}.coupler.res
EOF
    if [ ${angular_sectors} -eq 1 ]; then
      cat<< EOF >> ${yaml_dir}/${job}.yaml
      - parameter: rh
        file:
          datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          set datetime on read: true
          psinfile: true
          filename_core: cor_rh_${icomp}.fv_core.res.nc
          filename_trcr: cor_rh_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rh_${icomp}.coupler.res
EOF
    else
      cat<< EOF >> ${yaml_dir}/${job}.yaml
      - parameter: rh1
        file:
          datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          set datetime on read: true
          psinfile: true
          filename_core: cor_rh1_${icomp}.fv_core.res.nc
          filename_trcr: cor_rh1_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rh1_${icomp}.coupler.res
      - parameter: rh2
        file:
          datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          set datetime on read: true
          psinfile: true
          filename_core: cor_rh2_${icomp}.fv_core.res.nc
          filename_trcr: cor_rh2_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rh2_${icomp}.coupler.res
      - parameter: rhc
        file:
          datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          set datetime on read: true
          psinfile: true
          filename_core: cor_rhc_${icomp}.fv_core.res.nc
          filename_trcr: cor_rhc_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rhc_${icomp}.coupler.res
EOF
    fi
    cat<< EOF >> ${yaml_dir}/${job}.yaml 
      - parameter: rv
        file:
          datetime: ${yyyy_fc_last}-${mm_fc_last}-${dd_fc_last}T${hh_fc_last}:00:00Z
          filetype: fms restart
          datapath: ${data_dir_def}/cor_${suffix}
          set datetime on read: true
          psinfile: true
          filename_core: cor_rv_${icomp}.fv_core.res.nc
          filename_trcr: cor_rv_${icomp}.fv_tracer.res.nc
          filename_cplr: cor_rv_${icomp}.coupler.res
      output model file:
      - parameter: nicas_norm
        file:
          filetype: fms restart
          datapath: ${data_dir_def}/nicas_${suffix}_${var}_${icomp}
          prepend files with date: false
          filename_core: nicas_norm.fv_core.res.nc
          filename_trcr: nicas_norm.fv_tracer.res.nc
          filename_cplr: nicas_norm.coupler.res
EOF

    # NICAS sbatch
    ntasks=${ntasks_def}
    cpus_per_task=2
    threads=2
    time=03:00:00
    exe=fv3jedi_error_covariance_training.x
    prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
  done
done

####################################################################
# MERGE NICAS ######################################################
####################################################################

# Job
job=merge_nicas_${suffix}
mkdir -p ${work_dir}/${job}

# Merge nicas norm files
ntasks=1
cpus_per_task=${cores_per_node}
threads=1
time=01:00:00
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
nlocal=${ntasks_def}
ntotpad=\$(printf "%.6d" "\${nlocal}")

for itot in \$(seq 1 \${nlocal}); do
  itotpad=\$(printf "%.6d" "\${itot}")

  # Local full files names
  filename_full=${data_dir_def}/nicas_${suffix}/nicas_${suffix}_nicas_local_\${ntotpad}-\${itotpad}.nc

  # Remove existing local full files
  rm -f \${filename_full}

  # Create scripts to merge local files
  echo "#!/bin/bash" > merge_nicas_\${itotpad}.sh
  for var in ${vars}; do
    for icomp in \$(seq 1 \${number_of_components}); do
      filename_var_comp=${data_dir_def}/nicas_${suffix}_\${var}_\${icomp}/nicas_${suffix}_\${var}_\${icomp}_nicas_local_\${ntotpad}-\${itotpad}.nc
      echo -e "ncks -A \${filename_var_comp} \${filename_full}" >> merge_nicas_\${itotpad}.sh
    done
  done
done

# Global full files names
filename_full=${data_dir_def}/nicas_${suffix}/nicas_${suffix}_nicas.nc

# Remove existing global full files
rm -f \${filename_full}

# Create script to merge global files
nlocalp1=\$((nlocal+1))
itotpad=\$(printf "%.6d" "\${nlocalp1}")
echo "#!/bin/bash" > merge_nicas_\${itotpad}.sh
for var in ${vars}; do
  for icomp in \$(seq 1 \${number_of_components}); do
    filename_var_comp=${data_dir_def}/nicas_${suffix}_\${var}_\${icomp}/nicas_${suffix}_\${var}_\${icomp}_nicas.nc
    echo -e "ncks -A \${filename_var_comp} \${filename_full}" >> merge_nicas_\${itotpad}.sh
  done
done

# Run scripts in parallel
nbatch=\$((nlocalp1/${cores_per_node}+1))
itot=0
for ibatch in \$(seq 1 \${nbatch}); do
  for i in \$(seq 1 ${cores_per_node}); do
    itot=\$((itot+1))
    if test "\${itot}" -le "\${nlocalp1}"; then
      itotpad=\$(printf "%.6d" "\${itot}")
      echo "Batch \${ibatch} - job \${i}: ./merge_nicas_\${itotpad}.sh"
      chmod 755 merge_nicas_\${itotpad}.sh
      ./merge_nicas_\${itotpad}.sh &
    fi
  done
  wait
done

# Wait
wait

# Specific file
declare -A file_type
file_type["stream_function"]="fv_core"
file_type["velocity_potential"]="fv_core"
file_type["air_temperature"]="fv_core"
file_type["surface_pressure"]="fv_core"
file_type["specific_humidity"]="fv_tracer"
file_type["cloud_liquid_water"]="fv_tracer"
file_type["ozone_mass_mixing_ratio"]="fv_tracer"

# NetCDF files
for itile in \$(seq 1 6); do
  # Remove existing files
  filename_core=${data_dir_def}/nicas_${suffix}/nicas_norm.fv_core.res.tile\${itile}.nc
  filename_tracer=${data_dir_def}/nicas_${suffix}/nicas_norm.fv_tracer.res.tile\${itile}.nc
  rm -f \${filename_core} \${filename_tracer}

  for icomp in \${number_of_components}; do
    # Rename surface_pressure file axis
    filename_var=${data_dir_def}/nicas_${suffix}_surface_pressure_\${icomp}/nicas_norm.fv_core.res.tile\${itile}.nc
    ncrename -d .zaxis_1,zaxis_2 \${filename_var}

    # Append files
    for var in ${vars}; do
      filename_full=${data_dir_def}/nicas_${suffix}/nicas_norm.\${file_type[\${var}]}.res.tile\${itile}.nc
      filename_var=${data_dir_def}/nicas_${suffix}_\${var}\${icomp}/nicas_norm.\${file_type[\${var}]}.res.tile\${itile}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}"
      ncks -A \${filename_var} \${filename_full}
    done
  done
done

# Create coupler file
${script_dir}/coupler.sh ${yyyymmddhh_fc_last} ${data_dir_def}/nicas_${suffix}/nicas_norm.coupler.res

# Timer
wait
echo "ELAPSED TIME = \${SECONDS} s"

exit 0
EOF
