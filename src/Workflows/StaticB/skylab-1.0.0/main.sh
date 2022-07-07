#!/bin/bash

# Source parameters and functions
source ./parameters.sh
source ./functions.sh

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
export yyyy_bkg=${yyyymmddhh_bkg:0:4}
export mm_bkg=${yyyymmddhh_bkg:4:2}
export dd_bkg=${yyyymmddhh_bkg:6:2}
export hh_bkg=${yyyymmddhh_bkg:8:2}
export yyyy_obs=${yyyymmddhh_obs:0:4}
export mm_obs=${yyyymmddhh_obs:4:2}
export dd_obs=${yyyymmddhh_obs:6:2}
export hh_obs=${yyyymmddhh_obs:8:2}
echo `date`": dates are ${yyyymmddhh_list}"
echo `date`": first date is ${yyyymmddhh_first}"
echo `date`": last date is ${yyyymmddhh_last}"
echo `date`": background date is ${yyyymmddhh_bkg}"
echo `date`": observations date is ${yyyymmddhh_obs}"

# Define directories
echo `date`": define directories"
export data_dir_def=${data_dir}/c${cdef}
export data_dir_regrid=${data_dir_regrid_base}/c${cregrid}
export first_member_dir="${yyyymmddhh_last}/mem001"
export bkg_dir="bkg_${yyyymmddhh_bkg}"
export sbatch_dir="${xp_dir}/${bump_dir}/sbatch"
export work_dir="${xp_dir}/${bump_dir}/work"
export yaml_dir="${xp_dir}/${bump_dir}/yaml"
export script_dir="${xp_dir}/${bump_dir}/script"

# Default geometry
export npx_def=$((cdef+1))
export npy_def=$((cdef+1))
export dirac_center_def=$((cdef/2))

# Regridding geometry
export npx_regrid=$((cregrid+1))
export npy_regrid=$((cregrid+1))
export dirac_center_regrid=$((cregrid/2))

####################################################################
# Create work directories ##########################################
####################################################################

# Create work directories
echo `date`": create work directories"
mkdir -p ${yaml_dir}
mkdir -p ${sbatch_dir}
mkdir -p ${work_dir}
mkdir -p ${data_dir}
mkdir -p ${data_dir_def}/${bump_dir}

####################################################################
# Get data #########################################################
####################################################################

if test "${get_data_ensemble}" = "true"; then
   # Go to data directory
   echo `date`": cd ${data_dir_def}/${bump_dir}"
   cd ${data_dir_def}/${bump_dir}

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
      for imem in $(seq 1 1 ${nmem}); do
         imemp=$(printf "%.3d" "${imem}")
         ${script_dir}/coupler.sh ${yyyymmddhh} ${data_dir_def}/${bump_dir}/${yyyymmddhh}/mem${imemp}/bvars.coupler.res
      done
   done
fi

if test "${get_data_background}" = "true"; then
   # Go to data directory
   echo `date`": cd ${data_dir_def}/${bump_dir}"
   cd ${data_dir_def}/${bump_dir}

   # Get background
   echo `date`": aws s3 cp s3://fv3-jedi/StaticBTraining/C384/Background/bkg_${yyyymmddhh_bkg}.tar . --quiet"
   aws s3 cp s3://fv3-jedi/StaticBTraining/C384/Background/bkg_${yyyymmddhh_bkg}.tar . --quiet

   # Untar background
   echo `date`": tar -xvf bkg_${yyyymmddhh_bkg}.tar"
   tar -xvf bkg_${yyyymmddhh_bkg}.tar

   # Remove archive
   echo `date`": rm -f bkg_${yyyymmddhh_bkg}.tar"
   rm -f bkg_${yyyymmddhh_bkg}.tar
fi

if test "${get_data_observations}" = "true"; then
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
echo `date`": run yamls and sbatch scripts generators"

if test "${run_daily_vbal}" = "true" || test "${run_daily_unbal}" = "true" || test "${run_daily_varmom}" = "true"; then
   # Daily runs
   ./daily.sh
fi

if test "${run_final_psichitouv}" = "true" || "${run_final_vbal}" = "true" || "${run_final_var}" = "true" || "${run_final_cor}" = "true" || "${run_final_nicas}" = "true" ; then
   # Final runs
   ./final.sh
fi

if test "${run_merge_states}" = "true" || test "${run_merge_nicas}" = "true"; then
   # Merge runs
   ./merge.sh
fi

if test "${run_regrid_states}" = "true" || "${run_regrid_psichitouv}" = "true" || "${run_regrid_vbal}" = "true" || "${run_regrid_nicas}" = "true" || "${run_regrid_merge_nicas}" = "true" ; then
   # Regrid runs
   ./regrid.sh
fi

if test "${run_dirac_cor_local}" = "true" || "${run_dirac_cor_global}" = "true" || "${run_dirac_cov_local}" = "true" || "${run_dirac_cov_global}" = "true" || test "${run_dirac_cov_multi_local}" = "true" || "${run_dirac_cov_multi_global}" = "true" || "${run_dirac_full_c2a_local}" = "true" || "${run_dirac_full_psichitouv_local}" = "true" || "${run_dirac_full_global}" = "true" || test "${run_dirac_full_regrid_local}" = "true" ; then
   # Dirac runs
   ./dirac.sh
fi

if test "${run_variational_3dvar}" = "true" || "${run_variational_3dvar_specific_obs}" = "true" || "${run_variational_3dvar_regrid}" = "true" ; then
   # Variational runs
   ./variational.sh
fi

####################################################################
# Run sbatch #######################################################
####################################################################

if test "${prepare_scripts_only}" = "true"; then
   exit 0
fi

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

# Run states
if test "${run_merge_states}" = "true"; then
   run_sbatch merge_states_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_var_pids}${final_cor_pids}${final_nicas_pids}
   merge_states_pid=:${pid}
fi

# Run nicas
if test "${run_merge_nicas}" = "true"; then
   run_sbatch merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${final_nicas_pids}
   merge_nicas_pid=:${pid}
fi

# Regrid runs
# -----------

# Run states
if test "${run_regrid_states}" = "true"; then
   run_sbatch regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_states_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_states_pid}
   regrid_states_pid=:${pid}
fi

# Run psichitouv
if test "${run_regrid_psichitouv}" = "true"; then
   run_sbatch regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${regrid_states}${final_psichitouv_pid}
   regrid_psichitouv_pid=:${pid}
fi

# Run vbal
if test "${run_regrid_vbal}" = "true"; then
   run_sbatch regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${regrid_states}${final_vbal_pid}
   regrid_vbal_pid=:${pid}
fi

# Run nicas
if test "${run_regrid_nicas}" = "true"; then
   regrid_nicas_pids=""
   for var in ${vars}; do
      run_sbatch regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh ${regrid_states_pid}${final_nicas_pids}
      regrid_nicas_pids=${regrid_nicas_pids}:${pid}
   done
fi

# Run merge nicas
if test "${run_regrid_merge_nicas}" = "true"; then
   run_sbatch regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${regrid_states}${regrid_nicas_pids}
   regrid_merge_nicas_pid=:${pid}
fi

# Dirac runs
# ----------

# Run dirac_cor_local
if test "${run_dirac_cor_local}" = "true"; then
   run_sbatch dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}
   dirac_cor_local_pid=:${pid}
fi

# Run dirac_cor_global
if test "${run_dirac_cor_global}" = "true"; then
   run_sbatch dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}
   dirac_cor_global_pid=:${pid}
fi

# Run dirac_cov_local
if test "${run_dirac_cov_local}" = "true"; then
   run_sbatch dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}
   dirac_cov_local_pid=:${pid}
fi

# Run dirac_cov_global
if test "${run_dirac_cov_global}" = "true"; then
   run_sbatch dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}
   dirac_cov_global_pid=:${pid}
fi

# Run dirac_cov_multi_local
if test "${run_dirac_cov_multi_local}" = "true"; then
   run_sbatch dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}${final_vbal_pid}
   dirac_cov_multi_local_pid=:${pid}
fi

# Run dirac_cov_multi_global
if test "${run_dirac_cov_multi_global}" = "true"; then
   run_sbatch dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}${final_vbal_pid}
   dirac_cov_multi_global_pid=:${pid}
fi

# Run dirac_full_c2a_local
if test "${run_dirac_full_c2a_local}" = "true"; then
   run_sbatch dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}${final_vbal_pid}
   dirac_full_c2a_local_pid=:${pid}
fi

# Run dirac_full_psichitouv_local
if test "${run_dirac_full_psichitouv_local}" = "true"; then
   run_sbatch dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}${final_vbal_pid}${final_psichitouv_pid}
   dirac_full_psichitouv_local_pid=:${pid}
fi

# Run dirac_full_global
if test "${run_dirac_full_global}" = "true"; then
   run_sbatch dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}${final_vbal_pid}${final_psichitouv_pid}
   dirac_full_global_pid=:${pid}
fi

# Run dirac_full_regrid_local
if test "${run_dirac_full_regrid_local}" = "true"; then
   run_sbatch dirac_full_c${cregrid}_${nlx_regrid}x${nly_regrid}_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${regrid_merge_nicas_pid}${regrid_vbal_pid}${regrid_psichitouv_pid}${regrid_states_pid}
   dirac_full_regrid_local_pid=:${pid}
fi

# Variational runs
# ----------------

# Run 3dvar
if test "${run_variational_3dvar}" = "true"; then
   run_sbatch variational_3dvar_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}${final_vbal_pid}${final_psichitouv_pid}
   variational_3dvar_pid=:${pid}
fi

# Run 3dvar_specific_obs
if test "${run_variational_3dvar_specific_obs}" = "true"; then
   variational_3dvar_specific_obs_pid=''
   for obs in ${obs_xp} ; do
      run_sbatch variational_3dvar_${obs}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${merge_nicas_pid}${merge_states_pid}${final_vbal_pid}${final_psichitouv_pid}
      variational_3dvar_specific_obs_pid=${variational_3dvar_specific_obs_pid}:${pid}
   done
fi

# Run 3dvar_regrid
if test "${run_variational_3dvar_regrid}" = "true"; then
   run_sbatch variational_3dvar_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}.sh ${regrid_merge_nicas_pid}${regrid_vbal_pid}${regrid_psichitouv_pid}${regrid_states_pid}
   variational_3dvar_regrid_pid=:${pid}
fi

exit 0
