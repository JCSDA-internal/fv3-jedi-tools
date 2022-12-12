#!/bin/bash

# Source parameters and functions
export script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${script_dir}/parameters.sh
source ${script_dir}/functions.sh

####################################################################
# Set other variables ##############################################
####################################################################

# Forecast range
if test ${r} -ge 0; then
   export rr="+"$(printf "%.2d" "${r}")
   export rr_fc=${rr}
   echo `date`": forecast range is ${r}h"
else
   export rr=""
   export rr_fc="+00"
   echo `date`": no forecast range specified"
fi

# Dates
set -- ${yyyymmddhh_list}
export yyyymmddhh_size=${#yyyymmddhh_list[@]}
export yyyymmddhh_first=${1}
export yyyymmddhh_last=${@: -1}
export yyyy_last=${yyyymmddhh_last:0:4}
export mm_last=${yyyymmddhh_last:4:2}
export dd_last=${yyyymmddhh_last:6:2}
export hh_last=${yyyymmddhh_last:8:2}
export yyyymmddhh_fc_last=`date -d "${yyyy_last}${mm_last}${dd_last} +${hh_last} hours ${rr_fc} hours" '+%Y%m%d%H'`
export yyyy_fc_last=${yyyymmddhh_fc_last:0:4}
export mm_fc_last=${yyyymmddhh_fc_last:4:2}
export dd_fc_last=${yyyymmddhh_fc_last:6:2}
export hh_fc_last=${yyyymmddhh_fc_last:8:2}
echo `date`": dates are ${yyyymmddhh_list}"
echo `date`": first date is ${yyyymmddhh_first}"
echo `date`": last date is ${yyyymmddhh_last}"

# Define directories
echo `date`": define directories"
export data_dir_def=${data_dir}/c${cdef}/${bump_dir}
export data_dir_regrid=${data_dir_regrid_base}/c${cregrid}/${bump_dir}
export sbatch_dir="${xp_dir}/${bump_dir}/sbatch"
export work_dir="${xp_dir}/${bump_dir}/work"
export yaml_dir="${xp_dir}/${bump_dir}/yaml"

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
mkdir -p ${data_dir_def}

####################################################################
# Run generators ###################################################
####################################################################

# Run generators
echo `date`": run yamls and sbatch scripts generators"

if test "${run_daily_state_to_control}" = "true" || "${run_daily_vbal}" = "true" || "${run_daily_unbal}" = "true" || "${run_daily_varmom}" = "true"; then
   # Daily runs
   ${script_dir}/daily.sh
fi

if test "${run_final_vbal}" = "true" || "${run_final_var}" = "true" || "${run_final_cor}" = "true" || "${run_final_nicas}" = "true" ; then
   # Final runs
   ${script_dir}/final.sh
fi

if test "${run_merge_states}" = "true" || "${run_merge_nicas}" = "true"; then
   # Merge runs
   ${script_dir}/merge.sh
fi

if test "${run_regrid_states}" = "true" || "${run_regrid_vbal}" = "true" || "${run_regrid_nicas}" = "true" || "${run_regrid_merge_nicas}" = "true" ; then
   # Regrid runs
   ${script_dir}/regrid.sh
fi

if test "${run_dirac}" = "true" || "${run_dirac_regrid}" = "true" ; then
   # Dirac runs
   ${script_dir}/dirac.sh
fi

####################################################################
# Run sbatch #######################################################
####################################################################

if test "${prepare_scripts_only}" = "true"; then
   exit 0
fi

# Daily runs
# ----------

# Run state_to_control
if test "${run_daily_state_to_control}" = "true"; then
   daily_state_to_control_pids=""
   for yyyymmddhh in ${yyyymmddhh_list}; do
      run_sbatch ${sbatch_dir}/state_to_control_${yyyymmddhh}${rr}.sh ""
      daily_state_to_control_pids=${daily_state_to_control_pids}:${pid}
   done
fi

# Run vbal
if test "${run_daily_vbal}" = "true"; then
   daily_vbal_pids=""
   for yyyymmddhh in ${yyyymmddhh_list}; do
      run_sbatch ${sbatch_dir}/vbal_${yyyymmddhh}${rr}.sh ${daily_state_to_control_pids}
      daily_vbal_pids=${daily_vbal_pids}:${pid}
   done
fi

# Run unbal
if test "${run_daily_unbal}" = "true"; then
   daily_unbal_pids=""
   for yyyymmddhh in ${yyyymmddhh_list}; do
      run_sbatch ${sbatch_dir}/unbal_${yyyymmddhh}${rr}.sh ${daily_vbal_pids}
      daily_unbal_pids=${daily_unbal_pids}:${pid}
   done
fi

# Run var-mom
if test "${run_daily_varmom}" = "true"; then
   declare -A daily_varmom_pids
   for var in ${vars}; do
      daily_varmom_pids+=(["${var}"]="")
      for yyyymmddhh in ${yyyymmddhh_list}; do
         run_sbatch ${sbatch_dir}/var-mom_${yyyymmddhh}${rr}_${var}.sh ${daily_unbal_pids}
         daily_varmom_pids[${var}]=${daily_varmom_pids[${var}]}:${pid}
      done
   done
fi

# Final runs
# ----------

# Run vbal
if test "${run_final_vbal}" = "true"; then
   run_sbatch ${sbatch_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}.sh ${daily_vbal_pids}
   final_vbal_pid=:${pid}
fi

# Run var
if test "${run_final_var}" = "true"; then
   final_var_pids=""
   for var in ${vars}; do
      run_sbatch ${sbatch_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}.sh ${daily_varmom_pids[${var}]}
      final_var_pids=${final_var_pids}:${pid}
   done
fi

# Run cor
if test "${run_final_cor}" = "true"; then
   final_cor_pids=""
   for var in ${vars}; do
      run_sbatch ${sbatch_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}.sh ${daily_varmom_pids[${var}]}
      final_cor_pids=${final_cor_pids}:${pid}
   done
fi

# Run nicas
if test "${run_final_nicas}" = "true"; then
   final_nicas_pids=""
   for var in ${vars}; do
      run_sbatch ${sbatch_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}.sh ${final_cor_pids}
      final_nicas_pids=${final_nicas_pids}:${pid}
   done
fi

# Merge runs
# ----------

# Run states
if test "${run_merge_states}" = "true"; then
   run_sbatch ${sbatch_dir}/merge_states_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}.sh ${final_var_pids}${final_cor_pids}${final_nicas_pids}
   merge_states_pid=:${pid}
fi

# Run nicas
if test "${run_merge_nicas}" = "true"; then
   run_sbatch ${sbatch_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}.sh ${final_nicas_pids}
   merge_nicas_pid=:${pid}
fi

# Regrid runs
# -----------

# Run states
if test "${run_regrid_states}" = "true"; then
   run_sbatch ${sbatch_dir}/regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_states_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}.sh ${merge_states_pid}
   regrid_states_pid=:${pid}
fi

# Run vbal
if test "${run_regrid_vbal}" = "true"; then
   run_sbatch ${sbatch_dir}/regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}.sh ${regrid_states}${final_vbal_pid}
   regrid_vbal_pid=:${pid}
fi

# Run nicas
if test "${run_regrid_nicas}" = "true"; then
   regrid_nicas_pids=""
   for var in ${vars}; do
      run_sbatch ${sbatch_dir}/regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_${var}.sh ${regrid_states_pid}${final_nicas_pids}
      regrid_nicas_pids=${regrid_nicas_pids}:${pid}
   done
fi

# Run merge nicas
if test "${run_regrid_merge_nicas}" = "true"; then
   run_sbatch ${sbatch_dir}/regrid_c${cregrid}_${nlx_regrid}x${nly_regrid}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}.sh ${regrid_states}${regrid_nicas_pids}
   regrid_merge_nicas_pid=:${pid}
fi

# Dirac runs
# ----------

# Run dirac
if test "${run_dirac}" = "true"; then
   run_sbatch ${sbatch_dir}/dirac_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}.sh ${merge_nicas_pid}${merge_states_pid}${final_vbal_pid}
   dirac_pid=:${pid}
fi

# Run dirac_regrid
if test "${run_dirac_regrid}" = "true"; then
   run_sbatch ${sbatch_dir}/dirac_c${cregrid}_${nlx_regrid}x${nly_regrid}_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}.sh ${regrid_merge_nicas_pid}${regrid_vbal_pid}${regrid_states_pid}
   dirac_regrid_pid=:${pid}
fi

exit 0
