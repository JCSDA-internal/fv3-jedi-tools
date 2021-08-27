#!/bin/bash

####################################################################
# Function: run sbatch script, dealing with optional dependencies ##
####################################################################
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

####################################################################
# Directories ######################################################
####################################################################

# Data directory
export data_dir="/work/noaa/da/menetrie/StaticBTraining"

# FV3-JEDI source directory
export fv3jedi_dir="${HOME}/code/bundle/fv3-jedi"

# JEDI binaries directory
export bin_dir="${HOME}/build/gnu-openmpi/bundle_RelWithDebInfo/bin"

# Experiments directory
export xp_dir="${HOME}/xp"

# BUMP subdirectory name
export bump_dir="bump_1.0"

####################################################################
# Environment script (gnu-openmpi or intel-impi) ###################
####################################################################

export env_script=${xp_dir}/env_script/gnu-openmpi_env.sh
#export env_script=${xp_dir}/env_script/intel-impi_env.sh

####################################################################
# Parameters #######################################################
####################################################################
# Variables
export vars="psi chi t ps sphum liq_wat o3mr"

# Number of ensemble members
export nmem=80

# List of cycles for training (january or july)
export yyyymmddhh_list="2020010100 2020010200 2020010300 2020010400 2020010500 2020010600 2020010700 2020010800 2020010900 2020011000"
#export yyyymmddhh_list="2020070100 2020070200 2020070300 2020070400 2020070500 2020070600 2020070700 2020070800 2020070900 2020071000"

# Observation cycle
export yyyymmddhh_obs="2020121421"

####################################################################
# What should be run? ##############################################
####################################################################

# Create directories
export create_directories=false

# Get data
export get_data=false

# Daily runs
export run_daily_vbal=false
export run_daily_unbal=false
export run_daily_varmom=false

# Final runs
export run_final_psichitouv=false
export run_final_vbal=false
export run_final_var=false
export run_final_cor=false
export run_final_nicas=false

# Merge runs
export run_merge_varcor=false
export run_merge_nicas=false

# Split runs (for 7x7 procs on each tile)
export run_split_psichitouv=false
export nsplit=7
export run_split_vbal=false
export run_split_nicas=false

# Regridding runs (at C192)
export run_regridding_background=false
export run_regridding_first_member=false
export run_regridding_psichitouv=false
export run_regridding_varcor=false
export run_regridding_nicas=false
export run_regridding_merge_nicas=false

# Dirac runs
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

# Variational runs
export run_variational_3dvar=false

####################################################################
####################################################################
################ No edition needed beyond this line ################
####################################################################
####################################################################

####################################################################
# Set other variables ##############################################
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

# Local scripts directory
export script_dir=`pwd`

####################################################################
# Create directories ###############################################
####################################################################

if test "${create_directories}" = "true"; then
   # Create directories
   echo `date`": create directories"
   mkdir -p ${data_dir_c384}
   mkdir -p ${data_dir_c192}
   mkdir -p ${data_dir_c192}/${bkg_dir}
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
   mkdir -p ${data_dir_c192}/${first_member_dir}
   mkdir -p ${yaml_dir}
   mkdir -p ${sbatch_dir}
   mkdir -p ${work_dir}
fi

####################################################################
# Get data #########################################################
####################################################################

if test "${get_data}" = "true"; then
   # Go to data directory
   echo `date`": cd ${data_dir_c384}"
   cd ${data_dir_c384}

   # Get ensemble for regression
   for yyyymmddhh in ${yyyymmddhh_list}; do
      # Download ensemble member from S3
      echo `date`": aws s3 cp s3://fv3-jedi/StaticBTraining/C384/EnsembleForRegression/bvars_ens_${yyyymmddhh}.tar . --quiet"
      aws s3 cp s3://fv3-jedi/StaticBTraining/C384/EnsembleForRegression/bvars_ens_${yyyymmddhh}.tar . --quiet

      # Untar ensemble member
      echo `date`": tar -xvf bvars_ens_${yyyymmddhh}.tar"
      tar -xvf bvars_ens_${yyyymmddhh}.tar

      # Remove archive
      echo `date`": rm -f bvars_ens_${yyyymmddhh}.tar"
      rm -f bvars_ens_${yyyymmddhh}.tar

      # Create coupler files
      ./coupler.sh ${yyyymmddhh}
   done

   # Get background
   echo `date`": aws s3 cp s3://fv3-jedi/StaticBTraining/C384/Background/bkg_2020121421.tar . --quiet"
   aws s3 cp s3://fv3-jedi/StaticBTraining/C384/Background/bkg_2020121421.tar . --quiet

   # Untar background
   echo `date`": tar -xvf bkg_2020121421.tar"
   tar -xvf bkg_2020121421.tar

   # Remove archive
   echo `date`": rm -f bkg_2020121421.tar"
   rm -f bkg_2020121421.tar

   # Go to data directory
   echo `date`": cd ${data_dir}"
   cd ${data_dir}

   # Get observations
   echo `date`": aws s3 cp s3://fv3-jedi/StaticBTraining/Observations/obs.tar . --quiet"
   aws s3 cp s3://fv3-jedi/StaticBTraining/Observations/obs.tar . --quiet

   # Untar background
   echo `date`": tar -xvf obs.tar"
   tar -xvf obs.tar

   # Remove archive
   echo `date`": rm -f obs.tar"
   rm -f obs.tar
fi

####################################################################
# Run generators ###################################################
####################################################################

# Go to script directory
echo `date`": cd ${script_dir}"
cd ${script_dir}

# Run generators
echo `date`": run generators"

if test "${run_daily_vbal}" = "true" || test "${run_daily_unbal}" = "true" || test "${run_daily_varmom}" = "true"; then
   # Daily runs
   ./daily.sh
fi

if test "${run_final_psichitouv}" = "true" || "${run_final_vbal}" = "true" || "${run_final_var}" = "true" || "${run_final_cor}" = "true" || "${run_final_nicas}" = "true" ; then
   # Final runs
   ./final.sh
fi

if test "${run_merge_varcor}" = "true" || test "${run_merge_nicas}" = "true"; then
   # Merge runs
   ./merge.sh
fi

if test "${run_split_psichitouv}" = "true" || "${run_split_vbal}" = "true" || "${run_split_nicas}" = "true" ; then
   # Split runs
   ./split.sh
fi

if test "${run_regridding_background}" = "true" || "${run_regridding_first_member}" = "true" || "${run_regridding_psichitouv}" = "true" || "${run_regridding_varcor}" = "true" || "${run_regridding_nicas}" = "true" || "${run_regridding_merge_nicas}" = "true" ; then
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

####################################################################
# Run sbatch #######################################################
####################################################################

# Go to sbatch directory
echo `date`": cd ${sbatch_dir}"
cd ${sbatch_dir}

# Daily runs
# ----------

# Run vbal
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
# ----------

# Run vbal
if test "${run_final_vbal}" = "true"; then
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
# ----------

# Run var-cor
if test "${run_merge_varcor}" = "true"; then
   run_sbatch merge_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_var_pids}${final_cor_pids}
   merge_varcor_pid=:${pid}
fi

# Run nicas
if test "${run_merge_nicas}" = "true"; then
   run_sbatch merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_nicas_pids}
   merge_nicas_pid=:${pid}
fi

# Split runs
# ----------

# Run vbal
if test "${run_split_vbal}" = "true"; then
   run_sbatch split_vbal_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_vbal_pid}
   split_vbal_pid=:${pid}
fi

# Run nicas
if test "${run_split_nicas}" = "true"; then
   run_sbatch split_nicas_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_global_pid}
   split_nicas_pid=:${pid}
fi

# Run psichitouv
if test "${run_split_psichitouv}" = "true"; then
   run_sbatch split_psichitouv_${nsplit}x${nsplit}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_psichitouv_pid}
   split_psichitouv_pid=:${pid}
fi

# Regridding runs
# ---------------

# Run background
if test "${run_regridding_background}" = "true"; then
   run_sbatch regridding_background.sh
   regridding_background_pid=:${pid}
fi

# Run first member
if test "${run_regridding_first_member}" = "true"; then
   run_sbatch regridding_first_member_${yyyymmddhh_last}.sh
   regridding_first_member_pid=:${pid}
fi

# Run psichitouv
if test "${run_regridding_psichitouv}" = "true"; then
   run_sbatch regridding_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_psichitouv_pid}${regridding_first_member_pid}
   regridding_psichitouv_pid=:${pid}
fi

# Run var-cor
if test "${run_regridding_varcor}" = "true"; then
   run_sbatch regridding_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_varcor_pid}
   regridding_varcor_pid=:${pid}
fi

# Run nicas
if test "${run_regridding_nicas}" = "true"; then
   regridding_nicas_pids=""
   for var in ${vars}; do
      run_sbatch regridding_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh ${final_nicas_pids}${regridding_first_member_pid}
      regridding_nicas_pids=${regridding_nicas_pids}:${pid}
   done
fi

# Run merge nicas
if test "${run_regridding_merge_nicas}" = "true"; then
   run_sbatch regridding_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${regridding_nicas_pids}
   regridding_merge_nicas_pid=:${pid}
fi

# Dirac runs
# ----------

# Run dirac_cor_local
if test "${run_dirac_cor_local}" = "true"; then
   run_sbatch dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}
   dirac_cor_local_pid=:${pid}
fi

# Run dirac_cor_global
if test "${run_dirac_cor_global}" = "true"; then
   run_sbatch dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}
   dirac_cor_global_pid=:${pid}
fi

# Run dirac_cov_local
if test "${run_dirac_cov_local}" = "true"; then
   run_sbatch dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_varcor_pid}
   dirac_cov_local_pid=:${pid}
fi

# Run dirac_cov_global
if test "${run_dirac_cov_global}" = "true"; then
   run_sbatch dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_varcor_pid}
   dirac_cov_global_pid=:${pid}
fi

# Run dirac_cov_multi_local
if test "${run_dirac_cov_multi_local}" = "true"; then
   run_sbatch dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_varcor_pid}${final_vbal_pid}
   dirac_cov_multi_local_pid=:${pid}
fi

# Run dirac_cov_multi_global
if test "${run_dirac_cov_multi_global}" = "true"; then
   run_sbatch dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_varcor_pid}${final_vbal_pid}
   dirac_cov_multi_global_pid=:${pid}
fi

# Run dirac_full_c2a_local
if test "${run_dirac_full_c2a_local}" = "true"; then
   run_sbatch dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_varcor_pid}${final_vbal_pid}
   dirac_full_c2a_local_pid=:${pid}
fi

# Run dirac_full_psichitouv_local
if test "${run_dirac_full_psichitouv_local}" = "true"; then
   run_sbatch dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_varcor_pid}${final_vbal_pid}${final_psichitouv_pid}
   dirac_full_psichitouv_local_pid=:${pid}
fi

# Run dirac_full_global
if test "${run_dirac_full_global}" = "true"; then
   run_sbatch dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_varcor_pid}${final_vbal_pid}${final_psichitouv_pid}
   dirac_full_global_pid=:${pid}
fi

# Run dirac_full_c192_local
if test "${run_dirac_full_c192_local}" = "true"; then
   run_sbatch dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${regridding_merge_nicas_pid}${regridding_varcor_pid}${final_vbal_pid}${regridding_psichitouv_pid}${regridding_background_pid}
   dirac_full_c192_local_pid=:${pid}
fi

# Run dirac_full_7x7_local
if test "${run_dirac_full_7x7_local}" = "true"; then
   run_sbatch dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${split_nicas_pid}${merge_varcor_pid}${run_split_vbal}${run_split_psichitouv}
   dirac_full_7x7_local_pid=:${pid}
fi

# Variational runs
# ----------------

# Run 3dvar
if test "${run_variational_3dvar}" = "true"; then
   run_sbatch variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_varcor_pid}${final_vbal_pid}${final_psichitouv_pid}
   variational_3dvar_pid=:${pid}
fi

exit 0
