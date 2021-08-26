#!/bin/bash

####################################################################
# PSICHITOUV #######################################################
####################################################################

# Create specific work directory
mkdir -p ${data_dir_c192}/${bump_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}

# PSICHITOUV yaml
yaml_name="regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [6,6]
  npx: 193
  npy: 193
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c192}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  datadir: ${data_dir_c192}/${bump_dir}
  prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  new_wind: 1
  write_wind_local: 1
  wind_nlon: 400
  wind_nlat: 200
  wind_nsg: 5
  wind_inflation: 1.1
EOF

# PSICHITOUV sbatch
sbatch_name="regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.out

export OMP_NUM_THREADS=2
source ${env_script}

cd ${work_dir}/regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# VAR-COR ##########################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}

# Create output directory
mkdir -p ${data_dir_c192}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_c192}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}

# VAR-COR yaml
yaml_name="regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
input geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [6,6]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
output geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [6,6]
  npx: 193
  npy: 193
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
states:
- input:
    filetype: gfs
    state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  output:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c192}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
- input:
    filetype: gfs
    state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
    psinfile: 1
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  output:
    filetype: gfs
    psinfile: 1
    datapath: ${data_dir_c192}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

# VAR-COR sbatch
sbatch_name="regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}/regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}/regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_convertstate.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# NICAS ############################################################
####################################################################

for var in ${vars}; do
   # Create specific BUMP and work directories
   mkdir -p ${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
   mkdir -p ${work_dir}/regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

   # Link input files
   ln -sf ${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}_nicas.nc ${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}_nicas.nc
   ln -sf ${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}_nicas.nc ${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}_nicas.nc

   # NICAS yaml
   yaml_name="regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [6,6]
  npx: 193
  npy: 193
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: 1
  datapath: ${data_dir_c192}/${first_member_dir}
  filename_core: bvars.fv_core.res.nc
  filename_trcr: bvars.fv_tracer.res.nc
  filename_cplr: bvars.coupler.res
input variables: [${var}]
date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_c192}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  load_nicas_global: 1
  write_nicas_local: 1
  min_lev:
    liq_wat: 76
universe radius:
  filetype: gfs
  psinfile: 1
  datapath: ${data_dir_c192}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
  date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

   # NICAS sbatch
   sbatch_name="regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=2
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.err
#SBATCH -o ${work_dir}/regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.out

export OMP_NUM_THREADS=2
source ${env_script}

cd ${work_dir}/regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
mpirun -n 216 ${bin_dir}/fv3jedi_parameters.x ${yaml_dir}/${yaml_name}

exit 0
EOF
done

####################################################################
# MERGE NICAS ######################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

# Merge local NICAS files
sbatch_name="regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=40
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}
module load nco

cd ${work_dir}/regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

# Number of local files
nlocal=216

# Create scripts for local files
ntotpad=\$(printf "%.6d" "\${nlocal}")
for itot in \$(seq 1 \${nlocal}); do
   itotpad=\$(printf "%.6d" "\${itot}")
   filename_full_3D=${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas_local_\${ntotpad}-\${itotpad}.nc
   filename_full_2D=${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas_local_\${ntotpad}-\${itotpad}.nc
   rm -f \${filename_full_3D}
   rm -f \${filename_full_2D}
   echo "#!/bin/bash" > regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
   for var in ${vars}; do
      if test "\${var}" = "ps"; then
         filename_full=\${filename_full_2D}
      else
         filename_full=\${filename_full_3D}
      fi
      filename_var=${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas_local_\${ntotpad}-\${itotpad}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}" >> regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
   done
done

# Create scripts for global files
nlocalp1=\$((nlocal+1))
itotpad=\$(printf "%.6d" "\${nlocalp1}")
filename_full_3D=${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas.nc
filename_full_2D=${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas.nc
rm -f \${filename_full_3D}
rm -f \${filename_full_2D}
echo "#!/bin/bash" > regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
for var in ${vars}; do
   if test "\${var}" = "ps"; then
      filename_full=\${filename_full_2D}
   else
      filename_full=\${filename_full_3D}
   fi
   filename_var=${data_dir_c192}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas.nc
   echo -e "ncks -A \${filename_var} \${filename_full}" >> regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
done

# Run scripts in parallel
nbatch=\$((nlocalp1/40+1))
itot=0
for ibatch in \$(seq 1 \${nbatch}); do
   for i in \$(seq 1 40); do
      itot=\$((itot+1))
      if test "\${itot}" -le "\${nlocalp1}"; then
         itotpad=\$(printf "%.6d" "\${itot}")
         echo "Batch \${ibatch} - job \${i}: ./regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh"
         chmod 755 regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
         ./regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh &
      fi
   done
   wait
done

exit 0
EOF
