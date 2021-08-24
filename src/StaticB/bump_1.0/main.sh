#!/bin/bash

run_sbatch () {
  script=$1
  pids=$2
  if [[ -z ${pids} ]] ; then
     dependency=""
   else
     dependency="--dependency=afterok${pids}"
  fi
  cmd="sbatch ${dependency} ${script}"
  pid=$(eval ${cmd})
  pid=${pid##* }
  echo `date`": ${cmd} > "${pid}
}

# Variables
export vars="psi chi t ps sphum liq_wat o3mr"
declare -A vars_long
vars_long+=(["psi"]="stream_function")
vars_long+=(["chi"]="velocity_potential")
vars_long+=(["t"]="air_temperature")
vars_long+=(["sphum"]="specific_humidity")
vars_long+=(["liq_wat"]="cloud_liquid_water")
vars_long+=(["o3mr"]="ozone_mass_mixing_ratio")
vars_long+=(["ps"]="surface_pressure")
export vars_long

# Parameters
export nmem=80
export bump_dir="bump_1.0"
export yyyymmddhh_list="2020010100 2020010200 2020010300 2020010400 2020010500 2020010600 2020010700 2020010800 2020010900 2020011000"
#export yyyymmddhh_list="2020070100 2020070200 2020070300 2020070400 2020070500 2020070600 2020070700 2020070800 2020070900 2020071000"
export yyyymmddhh_obs="2020121421"

# Directories
export data_dir="/work/noaa/da/menetrie/StaticBTraining"
export fv3jedi_dir="${HOME}/code/bundle/fv3-jedi"
export bin_dir="${HOME}/build/gnu-openmpi/bundle_RelWithDebInfo/bin"
export xp_dir="${HOME}/xp"

# What should be run?

# Create directories
export create_directories=false

# Get data
export get_data=false

# Convert backgrounds to C192
export convert_to_c192=false

# Daily
export run_daily_vbal=false
export run_daily_unbal=false
export run_daily_varmom=false

# Final
export run_final_vbal=false
export run_final_var=false
export run_final_cor=false
export run_final_nicas=false
export run_final_psichitouv=false

# Merge
export run_merge_varcor=false
export run_merge_nicas=false

# Split (for 7x7 procs on each tile)
export nsplit=7
export run_split_vbal=false
export run_split_nicas=false
export run_split_psichitouv=false

# Regridding (at C192)
export run_regridding_varcor=false
export run_regridding_nicas=false
export run_regridding_merge_nicas=false
export run_regridding_psichitouv=false

# Dirac
export run_dirac_cor_local=false
export run_dirac_cor_global=false
export run_dirac_cov_local=false
export run_dirac_cov_global=false
export run_dirac_cov_multi_local=false
export run_dirac_cov_multi_global=false
export run_dirac_full_c2a_local=false
export run_dirac_full_psichitouv_local=false
export run_dirac_full_c192_local=false
export run_dirac_full_7x7_local=false
export run_dirac_full_global=false

# Variational
export run_variational_3dvar=true

####################################################################
# No edition needed beyond this line ###############################
####################################################################

# Dates
set -- ${yyyymmddhh_list}
export yyyymmddhh_size=${#yyyymmddhh_list[@]}
export yyyymmddhh_first=${1}
export yyyymmddhh_last=${@: -1}
export yyyy_last=${yyyymmddhh_last:0:4}
export mm_last=${yyyymmddhh_last:4:2}
export dd_last=${yyyymmddhh_last:6:2}
export hh_last=${yyyymmddhh_last:8:2}
export m_last=${mm_last##0}
export d_last=${dd_last##0}
export h_last=${hh_last##0}
export yyyy_obs=${yyyymmddhh_obs:0:4}
export mm_obs=${yyyymmddhh_obs:4:2}
export dd_obs=${yyyymmddhh_obs:6:2}
export hh_obs=${yyyymmddhh_obs:8:2}
echo `date`": dates are ${yyyymmddhh_list}"
echo `date`": first date is ${yyyymmddhh_first}"
echo `date`": last date is ${yyyymmddhh_last}"
echo `date`": observations date is ${yyyymmddhh_obs}"

# Define directories
echo `date`": define directories"
export data_dir_c384=${data_dir}/c384
export data_dir_c192=${data_dir}/c192
export first_member_dir="${yyyymmddhh_last}/mem001"
export bkg_dir="bkg_${yyyymmddhh_last}"
export bkg_obs_dir="bkg_${yyyymmddhh_obs}"
export sbatch_dir="${xp_dir}/${bump_dir}/sbatch"
export work_dir="${xp_dir}/${bump_dir}/work"
export yaml_dir="${xp_dir}/${bump_dir}/yaml"

if test "${create_directories}" = "true"; then
   # Create directories
   echo `date`": create directories"
   mkdir -p ${data_dir_c384}
   mkdir -p ${data_dir_c192}
   mkdir -p ${data_dir_c384}/${bump_dir}
   mkdir -p ${data_dir_c192}/${bump_dir}
   mkdir -p ${data_dir_c384}/${bump_dir}/geos
   mkdir -p ${data_dir_c192}/${bump_dir}/geos
   for yyyymmddhh in ${yyyymmddhh_list}; do
      mkdir -p ${data_dir_c384}/${bump_dir}/${yyyymmddhh}
      for imem in $(seq 1 1 ${nmem}); do
         imemp=$(printf "%.3d" "${imem}")
         mkdir -p ${data_dir_c384}/${bump_dir}/${yyyymmddhh}/mem${imemp}
      done
   done
   mkdir -p ${yaml_dir}
   mkdir -p ${sbatch_dir}
   mkdir -p ${work_dir}
fi

if test "${get_data}" = "true"; then
   # Go to data directory
   echo `date`": cd ${data_dir}/c384"
   cd ${data_dir}/c384

   for yyyymmddhh in ${yyyymmddhh_list}; do
      # Download ensemble from S3
      echo `date`": aws s3 cp s3://fv3-jedi/StaticBTraining/C384/EnsembleForRegression/bvars_ens_${yyyymmddhh}.tar . --quiet"
      aws s3 cp s3://fv3-jedi/StaticBTraining/C384/EnsembleForRegression/bvars_ens_${yyyymmddhh}.tar . --quiet
   
      # Untar ensemble
      echo `date`": tar -xvf bvars_ens_${yyyymmddhh}.tar"
      tar -xvf bvars_ens_${yyyymmddhh}.tar

      # Remove archive
      echo `date`": rm -f bvars_ens_${yyyymmddhh}.tar"
      rm -f bvars_ens_${yyyymmddhh}.tar

      # Create coupler files
      ./coupler.sh ${yyyymmddhh}
   done
fi

# Run generators
echo `date`": run generators"

if test "${run_daily_vbal}" = "true" || test "${run_daily_unbal}" = "true" || test "${run_daily_varmom}" = "true"; then
   # Daily runs
   ./daily.sh
fi

if test "${run_final_vbal}" = "true" || "${run_final_var}" = "true" || "${run_final_cor}" = "true" || "${run_final_nicas}" = "true" || "${run_final_psichitouv}" = "true"; then
   # Final runs
   ./final.sh
fi

if test "${run_merge_varcor}" = "true" || test "${run_merge_nicas}" = "true"; then
   # Merge runs
   ./merge.sh
fi

if test "${run_split_vbal}" = "true" || "${run_split_nicas}" = "true" || "${run_split_psichitouv}" = "true"; then
   # Split runs
   ./split.sh
fi

if test "${run_regridding_varcor}" = "true" || "${run_regridding_nicas}" = "true" || "${run_regridding_merge_nicas}" = "true" || "${run_regridding_psichitouv}" = "true"; then
   # Regridding runs
   ./regridding.sh
fi

if test "${run_dirac_cor_local}" = "true" || "${run_dirac_cor_global}" = "true" || "${run_dirac_cov_local}" = "true" || "${run_dirac_cov_global}" = "true" || test "${run_dirac_cov_multi_local}" = "true" || "${run_dirac_cov_multi_global}" = "true" || "${run_dirac_full_c2a_local}" = "true" || "${run_dirac_full_psichitouv_local}" = "true" || test "${run_dirac_full_c192_local}" = "true" || "${run_dirac_full_7x7_local}" = "true" || "${run_dirac_full_global}" = "true"; then
   # Dirac runs
   ./dirac.sh
fi

if test "${run_variational_3dvar}" = "true" ; then
   # Variational runs
   ./variational.sh
fi

# Go to sbatch directory
echo `date`": cd ${sbatch_dir}"
cd ${sbatch_dir}

# Daily runs

# Run vbal h
if test "${run_daily_vbal}" = "true"; then
   daily_vbal_pids=""
   for yyyymmddhh in ${yyyymmddhh_list}; do
      run_sbatch vbal_${yyyymmddhh}.sh ""
      daily_vbal_pids=${daily_vbal_pids}:${pid}
   done
fi

# Run unbal 
if test "${run_daily_unbal}" = "true"; then
   daily_unbal_pids=""
   for yyyymmddhh in ${yyyymmddhh_list}; do
      run_sbatch unbal_${yyyymmddhh}.sh ${daily_vbal_pids}
      daily_unbal_pids=${daily_unbal_pids}:${pid}
   done
fi

# Run var-mom 
if test "${run_daily_varmom}" = "true"; then
   declare -A daily_varmom_pids
   for var in ${vars}; do
      daily_varmom_pids+=(["${var}"]="")
      for yyyymmddhh in ${yyyymmddhh_list}; do
         run_sbatch var-mom_${yyyymmddhh}_${var}.sh ${daily_unbal_pids}
         daily_varmom_pids[${var}]=${daily_varmom_pids[${var}]}:${pid}
      done
   done
fi

# Final runs

# Run vbal 
if test "${run_final_vbal}" = "true"; then
   echo `date`": sbatch vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   run_sbatch vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${daily_vbal_pids}
   final_vbal_pid=:${pid}
fi

# Run var 
if test "${run_final_var}" = "true"; then
   final_var_pids=""
   for var in ${vars}; do
      run_sbatch var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh ${daily_varmom_pids[${var}]}
      final_var_pids=${final_var_pids}:${pid}
   done
fi

# Run cor 
if test "${run_final_cor}" = "true"; then
   final_cor_pids=""
   for var in ${vars}; do
      run_sbatch cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh ${daily_varmom_pids[${var}]}
      final_cor_pids=${final_cor_pids}:${pid}
   done
fi

# Run nicas 
if test "${run_final_nicas}" = "true"; then
   final_nicas_pids=""
   for var in ${vars}; do
      run_sbatch nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh ${final_cor_pids}
      final_nicas_pids=${final_nicas_pids}:${pid}
   done
fi

# Run psichitouv 
if test "${run_final_psichitouv}" = "true"; then
   run_sbatch psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ""
   final_psichitouv_pid=:${pid}
fi

# Merge runs

# Run var-cor 
if test "${run_merge_varcor}" = "true"; then
   run_sbatch merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_var_pids}${final_cor_pids}
   merge_varcor_pid=:${pid}
fi

# Run nicas 
if test "${run_merge_nicas}" = "true"; then
   merge_nicas_pids=""
   for itot in $(seq 1 216); do
      itotpad=$(printf "%.6d" "${itot}")
      run_sbatch merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${itotpad}.sh ${final_nicas_pids}
      merge_nicas_pids=${merge_nicas_pids}:${pid}
   done
   run_sbatch merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_nicas_pids}
   merge_nicas_pids=${merge_nicas_pids}:${pid}
fi

# Split runs

# Run vbal 
if test "${run_split_vbal}" = "true"; then
   run_sbatch split_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_vbal_pid}
   split_vbal_pid=:${pid}
fi

# Run nicas 
if test "${run_split_nicas}" = "true"; then
   run_sbatch split_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_global_pid}
   split_nicas_pid=:${pid}
fi

# Run psichitouv 
if test "${run_split_psichitouv}" = "true"; then
   run_sbatch split_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_psichitouv_pid}
   split_psichitouv_pid=:${pid}
fi

# Regridding runs

# Run var-cor 
if test "${run_regridding_varcor}" = "true"; then
   run_sbatch regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_varcor_pid}
   regridding_varcor_pid=:${pid}
fi

# Run nicas 
if test "${run_regridding_nicas}" = "true"; then
   regridding_nicas_pids=""
   for var in ${vars}; do
      run_sbatch regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh
      regridding_nicas_pids=${regridding_nicas_pids}:${pid}
   done
fi

# Run merge nicas 
if test "${run_regridding_merge_nicas}" = "true"; then
   regridding_merge_nicas_pids=""
   for itot in $(seq 1 216); do
      itotpad=$(printf "%.6d" "${itot}")
      run_sbatch regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${itotpad}.sh ${regridding_nicas_pids}
      regridding_merge_nicas_pids=${regridding_merge_nicas_pids}:${pid}
   done
fi

# Run psichitouv 
if test "${run_regridding_psichitouv}" = "true"; then
   run_sbatch regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_psichitouv_pid}
   regridding_psichitouv_pid=:${pid}
fi

# Dirac runs

# Run dirac_cor_local 
if test "${run_dirac_cor_local}" = "true"; then
   run_sbatch dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_cor_local_pid=:${pid}
fi

# Run dirac_cor_global 
if test "${run_dirac_cor_global}" = "true"; then
   run_sbatch dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_cor_global_pid=:${pid}
fi

# Run dirac_cov_local 
if test "${run_dirac_cov_local}" = "true"; then
   run_sbatch dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_cov_local_pid=:${pid}
fi

# Run dirac_cov_global 
if test "${run_dirac_cov_global}" = "true"; then
   run_sbatch dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_cov_global_pid=:${pid}
fi

# Run dirac_cov_multi_local 
if test "${run_dirac_cov_multi_local}" = "true"; then
   run_sbatch dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_cov_multi_local_pid=:${pid}
fi

# Run dirac_cov_multi_global 
if test "${run_dirac_cov_multi_global}" = "true"; then
   run_sbatch dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_cov_multi_global_pid=:${pid}
fi

# Run dirac_full_c2a_local 
if test "${run_dirac_full_c2a_local}" = "true"; then
   run_sbatch dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_full_c2a_local_pid=:${pid}
fi

# Run dirac_full_psichitouv_local 
if test "${run_dirac_full_psichitouv_local}" = "true"; then
   run_sbatch dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_full_psichitouv_local_pid=:${pid}
fi

# Run dirac_full_global 
if test "${run_dirac_full_global}" = "true"; then
   run_sbatch dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_full_global_pid=:${pid}
fi

# Run dirac_full_c192_local 
if test "${run_dirac_full_c192_local}" = "true"; then
   run_sbatch dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_full_c192_local_pid=:${pid}
fi

# Run dirac_full_7x7_local 
if test "${run_dirac_full_7x7_local}" = "true"; then
   run_sbatch dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   dirac_full_7x7_local_pid=:${pid}
fi

# Variational runs

# Run 3dvar 
if test "${run_variational_3dvar}" = "true"; then
   run_sbatch variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.sh # TODO
   variational_3dvar_pid=:${pid}
fi

exit 0
