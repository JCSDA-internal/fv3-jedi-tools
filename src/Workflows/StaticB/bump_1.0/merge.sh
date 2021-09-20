#!/bin/bash

####################################################################
# VAR-COR ##########################################################
####################################################################

# Create directories
mkdir -p ${work_dir}/merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}

# Merge VAR files
sbatch_name="merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}
module load nco

cd ${work_dir}/merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}

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
   filename_var=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev_ps.fv_core.res.tile\${itile}.nc
   ncrename -d zaxis_1,zaxis_2 \${filename_var}

   # Append files
   filename_core=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.tile\${itile}.nc
   filename_tracer=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.tile\${itile}.nc
   rm -f \${filename_core} \${filename_tracer}
   for var in ${vars}; do
      filename_full=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.\${vars_files[\${var}]}.res.tile\${itile}.nc
      filename_var=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev_\${var}.\${vars_files[\${var}]}.res.tile\${itile}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}"
      ncks -A \${filename_var} \${filename_full}
   done
done

# Coupler file
input_file=${data_dir}/coupler/coupler.res
output_file=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
echo -e "Create coupler file \${output_file}"
sed -e s/"_YYYY_"/${yyyy_last}/g \${input_file} > \${output_file}
if test "${m_last}" -le "9" ; then
   sed -i -e s/"_M_"/" "${m_last}/g \${output_file}
else
   sed -i -e s/"_M_"/${m_last}/g \${output_file}
fi
if test "${d_last}" -le "9" ; then
   sed -i -e s/"_D_"/" "${d_last}/g \${output_file}
else
   sed -i -e s/"_D_"/${d_last}/g \${output_file}
fi
if test "${h_last}" -le "9" ; then
   sed -i -e s/"_H_"/" "${h_last}/g \${output_file}
else
   sed -i -e s/"_H_"/${h_last}/g \${output_file}
fi

# COR

# NetCDF files
for itile in \$(seq 1 6); do
   # Modifiy ps file axis
   filename_var=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_ps.fv_core.res.tile\${itile}.nc
   ncrename -d zaxis_1,zaxis_2 \${filename_var}

   # Append files
   filename_core=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.tile\${itile}.nc
   filename_tracer=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.tile\${itile}.nc
   rm -f \${filename_core} \${filename_tracer}
   for var in ${vars}; do
      filename_full=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.\${vars_files[\${var}]}.res.tile\${itile}.nc
      filename_var=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_\${var}.\${vars_files[\${var}]}.res.tile\${itile}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}"
      ncks -A \${filename_var} \${filename_full}
   done
done

# Coupler file
input_file=${data_dir}/coupler/coupler.res
output_file=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
echo -e "Create coupler file \${output_file}"
sed -e s/"_YYYY_"/${yyyy_last}/g \${input_file} > \${output_file}
if test "${m_last}" -le "9" ; then
   sed -i -e s/"_M_"/" "${m_last}/g \${output_file}
else
   sed -i -e s/"_M_"/${m_last}/g \${output_file}
fi
if test "${d_last}" -le "9" ; then
   sed -i -e s/"_D_"/" "${d_last}/g \${output_file}
else
   sed -i -e s/"_D_"/${d_last}/g \${output_file}
fi
if test "${h_last}" -le "9" ; then
   sed -i -e s/"_H_"/" "${h_last}/g \${output_file}
else
   sed -i -e s/"_H_"/${h_last}/g \${output_file}
fi

exit 0
EOF

####################################################################
# NICAS ############################################################
####################################################################

# Create directories
mkdir -p ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

# Merge NICAS files
sbatch_name="merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=40
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}
module load nco

cd ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

# Number of local files
nlocal=216

# Create scripts for local files
ntotpad=\$(printf "%.6d" "\${nlocal}")
for itot in \$(seq 1 \${nlocal}); do
   itotpad=\$(printf "%.6d" "\${itot}")
   filename_full_3D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas_local_\${ntotpad}-\${itotpad}.nc
   filename_full_2D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas_local_\${ntotpad}-\${itotpad}.nc
   rm -f \${filename_full_3D}
   rm -f \${filename_full_2D}
   echo "#!/bin/bash" > merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
   for var in ${vars}; do
      if test "\${var}" = "ps"; then
         filename_full=\${filename_full_2D}
      else
         filename_full=\${filename_full_3D}
      fi
      filename_var=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas_local_\${ntotpad}-\${itotpad}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}" >> merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
   done
done

# Create scripts for global files
nlocalp1=\$((nlocal+1))
itotpad=\$(printf "%.6d" "\${nlocalp1}")
filename_full_3D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas.nc
filename_full_2D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas.nc
rm -f \${filename_full_3D}
rm -f \${filename_full_2D}
echo "#!/bin/bash" > merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
for var in ${vars}; do
   if test "\${var}" = "ps"; then
      filename_full=\${filename_full_2D}
   else
      filename_full=\${filename_full_3D}
   fi
   filename_var=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas.nc
   echo -e "ncks -A \${filename_var} \${filename_full}" >> merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
done

# Run scripts in parallel
nbatch=\$((nlocalp1/40+1))
itot=0
for ibatch in \$(seq 1 \${nbatch}); do
   for i in \$(seq 1 40); do
      itot=\$((itot+1))
      if test "\${itot}" -le "\${nlocalp1}"; then
         itotpad=\$(printf "%.6d" "\${itot}")
         echo "Batch \${ibatch} - job \${i}: ./merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh"
         chmod 755 merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
         ./merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh &
      fi
   done
   wait
done

exit 0
EOF
