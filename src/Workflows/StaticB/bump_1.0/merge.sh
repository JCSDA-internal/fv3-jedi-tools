#!/bin/bash

####################################################################
# VAR-COR ##########################################################
####################################################################

# Job name
job=merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}

# Create directories
mkdir -p ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/${job}

# Merge VAR and COR files
ntasks=1
cpus_per_task=1
threads=1
time=00:20:00
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
vars_files["psi"]="fv_core"
vars_files["chi"]="fv_core"
vars_files["t"]="fv_core"
vars_files["ps"]="fv_core"
vars_files["sphum"]="fv_tracer"
vars_files["liq_wat"]="fv_tracer"
vars_files["o3mr"]="fv_tracer"

# VAR

# NetCDF files
for itile in \$(seq 1 6); do
   # Modifiy ps file axis
   filename_var=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_ps/stddev.fv_core.res.tile\${itile}.nc
   ncrename -d zaxis_1,zaxis_2 \${filename_var}

   # Remove existing files
   filename_core=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/stddev.fv_core.res.tile\${itile}.nc
   filename_tracer=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/stddev.fv_tracer.res.tile\${itile}.nc
   rm -f \${filename_core} \${filename_tracer}

   # Append files
   for var in ${vars}; do
      filename_full=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/stddev.\${vars_files[\${var}]}.res.tile\${itile}.nc
      filename_var=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}/stddev.\${vars_files[\${var}]}.res.tile\${itile}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}"
      ncks -A \${filename_var} \${filename_full}
   done
done

# Create coupler file
${script_dir}/coupler.sh ${yyyymmddhh_last} ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/stddev.coupler.res

# COR - RH

# NetCDF files
for itile in \$(seq 1 6); do
   # Modifiy ps file axis
   filename_var=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_ps/cor_rh.fv_core.res.tile\${itile}.nc
   ncrename -d zaxis_1,zaxis_2 \${filename_var}

   # Remove existing files
   filename_core=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_rh.fv_core.res.tile\${itile}.nc
   filename_tracer=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_rh.fv_tracer.res.tile\${itile}.nc
   rm -f \${filename_core} \${filename_tracer}

   # Append files
   for var in ${vars}; do
      filename_full=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_rh.\${vars_files[\${var}]}.res.tile\${itile}.nc
      filename_var=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}/cor_rh.\${vars_files[\${var}]}.res.tile\${itile}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}"
      ncks -A \${filename_var} \${filename_full}
   done
done

# Create coupler file
${script_dir}/coupler.sh ${yyyymmddhh_last} ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_rh.coupler.res

# COR - RV

# NetCDF files
for itile in \$(seq 1 6); do
   # Modifiy ps file axis
   filename_var=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_ps/cor_rv.fv_core.res.tile\${itile}.nc
   ncrename -d zaxis_1,zaxis_2 \${filename_var}

   # Remove existing files
   filename_core=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_rv.fv_core.res.tile\${itile}.nc
   filename_tracer=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_rv.fv_tracer.res.tile\${itile}.nc
   rm -f \${filename_core} \${filename_tracer}

   # Append files
   for var in ${vars}; do
      filename_full=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_rv.\${vars_files[\${var}]}.res.tile\${itile}.nc
      filename_var=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}/cor_rv.\${vars_files[\${var}]}.res.tile\${itile}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}"
      ncks -A \${filename_var} \${filename_full}
   done
done

# Create coupler file
${script_dir}/coupler.sh ${yyyymmddhh_last} ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/cor_rv.coupler.res

# Timer
wait
echo "ELAPSED TIME = \${SECONDS} s"

exit 0
EOF

####################################################################
# NICAS ############################################################
####################################################################

# Job name
job=merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

# Create directories
mkdir -p nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
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
nlocal=${ntasks_def}
ntotpad=\$(printf "%.6d" "\${nlocal}")

for itot in \$(seq 1 \${nlocal}); do
   itotpad=\$(printf "%.6d" "\${itot}")

   # Local full files names
   filename_full_3D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas_local_\${ntotpad}-\${itotpad}.nc
   filename_full_2D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas_local_\${ntotpad}-\${itotpad}.nc

   # Remove existing local full files
   rm -f \${filename_full_3D}
   rm -f \${filename_full_2D}

   # Create scripts to merge local files
   echo "#!/bin/bash" > merge_nicas_\${itotpad}.sh
   for var in ${vars}; do
      if test "\${var}" = "ps"; then
         filename_full=\${filename_full_2D}
      else
         filename_full=\${filename_full_3D}
      fi
      filename_var=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas_local_\${ntotpad}-\${itotpad}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}" >> merge_nicas_\${itotpad}.sh
   done
done

# Global full files names
filename_full_3D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas.nc
filename_full_2D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas.nc

# Remove existing global full files
rm -f \${filename_full_3D}
rm -f \${filename_full_2D}

# Create script to merge global files
nlocalp1=\$((nlocal+1))
itotpad=\$(printf "%.6d" "\${nlocalp1}")
echo "#!/bin/bash" > merge_nicas_\${itotpad}.sh
for var in ${vars}; do
   if test "\${var}" = "ps"; then
      filename_full=\${filename_full_2D}
   else
      filename_full=\${filename_full_3D}
   fi
   filename_var=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas.nc
   echo -e "ncks -A \${filename_var} \${filename_full}" >> merge_nicas_\${itotpad}.sh
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
