#!/bin/bash

# Source functions
source ./functions.sh

# Create data directories
mkdir -p ${data_dir_regrid}/${bump_dir}/${bkg_dir}
mkdir -p ${data_dir_regrid}/${bump_dir}/${first_member_dir}
mkdir -p ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
for var in ${vars}; do
   mkdir -p ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
done

# Date Offset
yyyymmddhh_o=$(date +%Y%m%d%H -d "$yyyy_last$mm_last$dd_last $hh_last - $offset hour")

yyyy_o=${yyyymmddhh_o:0:4}
mm_o=${yyyymmddhh_o:4:2}
dd_o=${yyyymmddhh_o:6:2}
hh_o=${yyyymmddhh_o:8:2}

####################################################################
# STATES ###########################################################
####################################################################

# Job name
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_states_${yyyymmddhh_first}-${yyyymmddhh_last}

# BACKGROUND yaml

cat<< EOF > ${yaml_dir}/${job}.yaml
input geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-aerosol.yaml
output geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-aerosol.yaml
states:
- input:
    datetime: ${yyyy_bkg}-${mm_bkg}-${dd_bkg}T${hh_bkg}:00:00Z
    filetype: fms restart
    datapath: ${data_dir_def}/${bump_dir}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
    state variables: [${varlist}]
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/${bkg_dir}
    prepend files with date: false
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_sfcw: fv_srf_wnd.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_phys: phy_data.nc
    filename_sfcd: sfc_data.nc
- input:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    state variables: [${varlist}]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
    filename_core: unbal.fv_core.res.nc
    filename_trcr: unbal.fv_tracer.res.nc
    filename_cplr: unbal.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/${first_member_dir}
    prepend files with date: false
    filename_core: unbal.fv_core.res.nc
    filename_trcr: unbal.fv_tracer.res.nc
    filename_cplr: unbal.coupler.res
- input:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    state variables: [${varlist}]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
    prepend files with date: false
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
- input:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    state variables: [${varlist}]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    prepend files with date: false
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
- input:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    state variables: [${varlist}]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    prepend files with date: false
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
- input:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    state variables: [${varlist}]
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
  output:
    filetype: fms restart
    datapath: ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
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
# PSICHITOUV #######################################################
####################################################################

# Job name
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}

# PSICHITOUV yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-aerosol.yaml
background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: [${varlist}]
  psinfile: true
  datapath: ${data_dir_regrid}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${varlist}]
bump:
  datadir: ${data_dir_regrid}/${bump_dir}
  prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  new_wind: true
  write_wind_local: true
  wind_nlon: 400
  wind_nlat: 200
  wind_nsg: 5
  wind_inflation: 1.1
EOF

# PSICHITOUV sbatch
ntasks=${ntasks_regrid}
cpus_per_task=1
threads=1
time=00:20:00
exe=fv3jedi_error_covariance_training.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}

####################################################################
# VBAL #############################################################
####################################################################

# Job name
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}

# Link input file
ln -sf ${data_dir_def}/${bump_dir}/vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling.nc ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling.nc
ln -sf ${data_dir_def}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}_vbal.nc ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}_vbal.nc

# VBAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-aerosol.yaml
background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: [${varlist}]
  psinfile: true
  datapath: ${data_dir_regrid}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${varlist}]
bump:
  datadir: ${data_dir_regrid}/${bump_dir}
  prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal: true
  write_vbal: true
  fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
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
   job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

   # Link input files
   if test "${var}" = "ps"; then
      ln -sf ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas.nc ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}_nicas.nc
   else
      ln -sf ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas.nc ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}_nicas.nc
   fi

   # NICAS yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  layout: [${nlx_regrid},${nly_regrid}]
  npx: ${npx_regrid}
  npy: ${npy_regrid}
  npz: ${npz_def}
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/gfs-aerosol.yaml
background:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: fms restart
  state variables: [${varlist}]
  psinfile: true
  datapath: ${data_input_dir}/enkfgdas.${yyyy_o}${mm_o}${dd_o}/${hh_o}/mem001/RESTART
  filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.ges.nc
  filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.ges.nc
  filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res.ges
input variables: [${var}]
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_regrid}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  load_nicas_global: true
  write_nicas_local: true
  min_lev:
    liq_wat: 76
#  universe radius:
#    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
#    filetype: fms restart
#    psinfile: true
#    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
#    filename_core: cor_rh.fv_core.res.nc
#    filename_trcr: cor_rh.fv_tracer.res.nc
#    filename_cplr: cor_rh.coupler.res
#    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
input fields:
- parameter: nicas_norm
  file:
    datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
    filetype: fms restart
    psinfile: true
    datapath: ${data_dir_def}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
    filename_core: nicas_norm.fv_core.res.nc
    filename_trcr: nicas_norm.fv_tracer.res.nc
    filename_cplr: nicas_norm.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
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
job=regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/${job}

# Merge NICAS files
ntasks=1
cpus_per_task=1 #${cores_per_node}
threads=1
time=00:30:00
cat<< EOF > ${sbatch_dir}/${job}.sh
#!/bin/bash
#SBATCH --job-name=${job}
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
   filename_full_3D=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas_local_\${ntotpad}-\${itotpad}.nc
   filename_full_2D=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas_local_\${ntotpad}-\${itotpad}.nc

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
      filename_var=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas_local_\${ntotpad}-\${itotpad}.nc
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
