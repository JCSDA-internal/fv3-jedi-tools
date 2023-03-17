#!/bin/bash

# Create data directories
mkdir -p ${data_dir_def}/var_${suffix}
mkdir -p ${data_dir_def}/cor_${suffix}
mkdir -p ${data_dir_def}/nicas_${suffix}

####################################################################
# STATES ###########################################################
####################################################################

# Job
job=merge_states_${suffix}
mkdir -p ${work_dir}/${job}

# Merge states files
ntasks=1
cpus_per_task=1
threads=1
time=00:10:00
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

# Specific file
declare -A vars_files
vars_files["stream_function"]="fv_core"
vars_files["velocity_potential"]="fv_core"
vars_files["air_temperature"]="fv_core"
vars_files["surface_pressure"]="fv_core"
vars_files["specific_humidity"]="fv_tracer"
vars_files["cloud_liquid_water"]="fv_tracer"
vars_files["ozone_mass_mixing_ratio"]="fv_tracer"

# States and corresponding directories
declare -A dirs
dirs["stddev"]="var"
dirs["cor_rh"]="cor"
dirs["cor_rh1"]="cor"
dirs["cor_rh2"]="cor"
dirs["cor_rhc"]="cor"
dirs["cor_rv"]="cor"
dirs["nicas_norm"]="nicas"

# Find existing states
possible_states="stddev
cor_rh
cor_rh1
cor_rh2
cor_rhc
cor_rv
nicas_norm"

states=""
for state in \${possible_states}; do
   # No component suffix
   isfilepresent=true
   for itile in \$(seq 1 6); do
      for var in ${vars}; do
         filename_var=${data_dir_def}/\${dirs[\${state}]}_${suffix}_\${var}/\${state}.\${vars_files[\${var}]}.res.tile\${itile}.nc
         if ! test -f \${filename_var}; then
            isfilepresent=false
         fi
      done
   done
   if test "\${isfilepresent}" = "true"; then
      states=\${states}" "\${state}
      echo -e "State "\${state}" found"
   else
      echo -e "State "\${state}" not found"
   fi

   # With component suffix
   for icomp in \$(seq 1 ${number_of_components}; do
      isfilepresent=true
      for itile in \$(seq 1 6); do
         for var in ${vars}; do
            filename_var=${data_dir_def}/\${dirs[\${state}]}_${suffix}_\${var}/\${state}_\${icomp}.\${vars_files[\${var}]}.res.tile\${itile}.nc
            if ! test -f \${filename_var}; then
               isfilepresent=false
            fi
         done
      done
      if test "\${isfilepresent}" = "true"; then
         states=\${states}" "\${state}_\${icomp}
         echo -e "State "\${state}_\${icomp}" found"
      else
         echo -e "State "\${state}_\${icomp}" not found"
      fi
   done
done
echo -e "Found the following states: "\${states}

for state in \${states}; do
   # NetCDF files
   for itile in \$(seq 1 6); do
      # Rename surface_pressure file axis
      filename_var=${data_dir_def}/\${dirs[\${state}]}_${suffix}_surface_pressure/\${state}.fv_core.res.tile\${itile}.nc
      ncrename -d .zaxis_1,zaxis_2 \${filename_var}

      # Remove existing files
      filename_core=${data_dir_def}/\${dirs[\${state}]}_${suffix}/\${state}.fv_core.res.tile\${itile}.nc
      filename_tracer=${data_dir_def}/\${dirs[\${state}]}_${suffix}/\${state}.fv_tracer.res.tile\${itile}.nc
      rm -f \${filename_core} \${filename_tracer}

      # Append files
      for var in ${vars}; do
         filename_full=${data_dir_def}/\${dirs[\${state}]}_${suffix}/\${state}.\${vars_files[\${var}]}.res.tile\${itile}.nc
         filename_var=${data_dir_def}/\${dirs[\${state}]}_${suffix}_\${var}/\${state}.\${vars_files[\${var}]}.res.tile\${itile}.nc
         echo -e "ncks -A \${filename_var} \${filename_full}"
         ncks -A \${filename_var} \${filename_full}
      done
   done

   # Create coupler file
   ${script_dir}/coupler.sh ${yyyymmddhh_fc_last} ${data_dir_def}/\${dirs[\${state}]}_${suffix}/\${state}.coupler.res
done

# Timer
wait
echo "ELAPSED TIME = \${SECONDS} s"

exit 0
EOF

####################################################################
# NICAS ############################################################
####################################################################

# Job name
job=merge_nicas_${suffix}
mkdir -p ${work_dir}/${job}

# Merge NICAS files
ntasks=1
cpus_per_task=${cores_per_node}
threads=1
time=00:45:00
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
      for icomp in \$(seq 1 ${number_of_components}); do
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
   for icomp in \$(seq 1 ${number_of_components}); do
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

# Timer
wait
echo "ELAPSED TIME = \${SECONDS} s"

exit 0
EOF
