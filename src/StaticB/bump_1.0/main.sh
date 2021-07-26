#!/bin/bash

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
export dates="2020010100 2020010200 2020010300 2020010400 2020010500 2020010600 2020010700 2020010800 2020010900 2020011000"
#export dates="2020070100 2020070200 2020070300 2020070400 2020070500 2020070600 2020070700 2020070800 2020070900 2020071000"

# Directories
export data_dir="/work/noaa/da/menetrie/StaticBTraining"
export xp_dir="${HOME}/xp"
export bin_dir="${HOME}/build/gnu-openmpi/bundle_RelWithDebInfo/bin"

# What should be run?

# Create directories
export create_directories=false

# Get data
export get_data=false

# Convert data to C192 TODO
export convert_to_c192=false

# Daily
export run_daily_vbal=false
export run_daily_unbal=true
export run_daily_varmom=true

# Final
export run_final_vbal=true
export run_final_var=true
export run_final_cor=true
export run_final_nicas=true
export run_final_psichitouv=true

# Merge
export run_merge_var=false
export run_merge_cor=false
export run_merge_nicas=false

# Regridding
export run_regridding=false

# Split
export run_split_vbal_c192=false
export run_split_vbal_7x7=false
export run_split_nicas_c192=false
export run_split_nicas_7x7=false
export run_split_psichitouv_c192=false
export run_split_psichitouv_7x7=false

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

####################################################################
# No edition needed beyond this line ###############################
####################################################################

# Dates
set -- ${dates}
export ndates=${#dates[@]}
export yyyymmddhh_first=${1}
export yyyymmddhh_last=${@: -1}
export yyyy_last=${yyyymmddhh_last:0:4}
export mm_last=${yyyymmddhh_last:4:2}
export dd_last=${yyyymmddhh_last:6:2}
export hh_last=${yyyymmddhh_last:8:2}
export m_last=${mm_last##0}
export d_last=${dd_last##0}
export h_last=${hh_last##0}
echo `date`": dates are ${dates}"
echo `date`": first date is ${yyyymmddhh_first}"
echo `date`": last date is ${yyyymmddhh_last}"

# Define directories
echo `date`": define directories"
export data_dir_c384=${data_dir}/c384
export data_dir_c192=${data_dir}/c192
export first_member_dir="${yyyymmddhh_last}/mem001"
export bkg_dir="bkg_${yyyymmddhh_last}"
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
   for yyyymmddhh in ${dates}; do
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

   for yyyymmddhh in ${dates}; do
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

# Daily runs
./daily.sh

# Final runs
./final.sh

# Split runs
./split.sh

# Merge runs
./merge.sh

# Regridding run
./regridding.sh

# Dirac run
./dirac.sh

# Go to sbatch directory
echo `date`": cd ${sbatch_dir}"
cd ${sbatch_dir}

# Daily runs

# Run vbal step
if test "${run_daily_vbal}" = "true"; then
   vbal_daily_pids=""
   for yyyymmddhh in ${dates}; do
      echo `date`": sbatch vbal_${yyyymmddhh}.sh"
      vbal_daily_pid=$(sbatch vbal_${yyyymmddhh}.sh)
      vbal_daily_pid=${vbal_daily_pid##* }
      vbal_daily_pids=${vbal_daily_pids}:${vbal_daily_pid}
   done
fi

# Run unbal step
if test "${run_daily_unbal}" = "true"; then
   unbal_daily_pids=""
   for yyyymmddhh in ${dates}; do
      echo `date`": sbatch unbal_${yyyymmddhh}.sh"
      if test "${run_daily_vbal}" = "true"; then
         unbal_daily_pid=$(sbatch --dependency=afterok:${vbal_daily_pid} unbal_${yyyymmddhh}.sh)
      else
         unbal_daily_pid=$(sbatch unbal_${yyyymmddhh}.sh)
      fi
      unbal_daily_pid=${unbal_daily_pid##* }
      unbal_daily_pids=${unbal_daily_pids}:${unbal_daily_pid}
   done
fi

# Run var-mom step
if test "${run_daily_varmom}" = "true"; then
   declare -A varmom_daily_pids
   for var in ${vars}; do
      varmom_daily_pids+=(["${var}"]="")
      for yyyymmddhh in ${dates}; do
         echo `date`": sbatch var-mom_${yyyymmddhh}_${var}.sh"
         if test "${run_daily_unbal}" = "true"; then
            varmom_daily_pid=$(sbatch --dependency=afterok:${unbal_daily_pid} var-mom_${yyyymmddhh}_${var}.sh)
         else
            varmom_daily_pid=$(sbatch var-mom_${yyyymmddhh}_${var}.sh)
         fi
         varmom_daily_pid=${varmom_daily_pid##* }
         varmom_daily_pids[${var}]="${varmom_daily_pids[${var}]}:${varmom_daily_pid}"
      done
   done
fi

# Final runs

# Run vbal step
if test "${run_final_vbal}" = "true"; then
   echo `date`": sbatch vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   if test "${run_daily_vbal}" = "true"; then
      vbal_final_pid=$(sbatch --dependency=afterok${vbal_daily_pids} vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh)
   else
      vbal_final_pid=$(sbatch vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh)
   fi
   vbal_final_pid=${vbal_final_pid##* }
fi

# Run var step
if test "${run_final_var}" = "true"; then
   declare -A var_final_pids
   for var in ${vars}; do
      var_final_pids+=(["${var}"]="")
      echo `date`": sbatch var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
      if test "${run_daily_varmom}" = "true"; then
         var_final_pid=$(sbatch --dependency=afterok${varmom_daily_pids[${var}]} var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh)
      else
         var_final_pid=$(sbatch var_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh)
      fi
      var_final_pid=${var_final_pid##* }
      var_final_pids[${var}]="${var_final_pids[${var}]}:${var_final_pid}"
   done
fi

# Run cor step
if test "${run_final_cor}" = "true"; then
   declare -A cor_final_pids
   for var in ${vars}; do
      cor_final_pids+=(["${var}"]="")
      echo `date`": sbatch cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
      if test "${run_daily_varmom}" = "true"; then
         cor_final_pid=$(sbatch --dependency=afterok${varmom_daily_pids[${var}]} cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh)
      else
         cor_final_pid=$(sbatch cor_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh)
      fi
      cor_final_pid=${cor_final_pid##* }
      cor_final_pids[${var}]="${cor_final_pids[${var}]}:${cor_final_pid}"
   done
fi

# Run nicas step
if test "${run_final_nicas}" = "true"; then
   declare -A nicas_final_pids
   for var in ${vars}; do
      nicas_final_pids+=(["${var}"]="")
      echo `date`": sbatch nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
      if test "${run_final_cor}" = "true"; then
         nicas_final_pid=$(sbatch --dependency=afterok${cor_final_pids[${var}]} nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh)
      else
         nicas_final_pid=$(sbatch nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh)
      fi
      nicas_final_pid=${nicas_final_pid##* }
      nicas_final_pids[${var}]="${nicas_final_pids[${var}]}:${nicas_final_pid}"
   done
fi

# Run psichitouv step
if test "${run_final_psichitouv}" = "true"; then
   echo `date`": sbatch psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   psichitouv_final_pid=$(sbatch psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh)
   psichitouv_final_pid=${psichitouv_final_pid##* }
fi

# Merge runs
# TODO: dependencies

# Run var step
if test "${run_merge_var}" = "true"; then
   echo `date`": sbatch merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run cor step
if test "${run_merge_cor}" = "true"; then
   echo `date`": sbatch merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run nicas step
if test "${run_merge_nicas}" = "true"; then
   for itot in $(seq 1 216); do
      itotpad=$(printf "%.6d" "${itot}")
      echo `date`": sbatch merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${itotpad}.sh"
      sbatch merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${itotpad}.sh
   done
   echo `date`": sbatch merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Regrid run
# TODO: dependencies
if test "${run_regridding}" = "true"; then
   echo `date`": sbatch regridding_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch regridding_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Split runs
# TODO: dependencies

# Run vbal_c192 step
if test "${run_split_vbal_c192}" = "true"; then
   echo `date`": sbatch split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch split_vbal_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run vbal_7x7 step
if test "${run_split_vbal_7x7}" = "true"; then
   echo `date`": sbatch split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch split_vbal_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run nicas_c192 step
if test "${run_split_nicas_c192}" = "true"; then
   echo `date`": sbatch split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch split_nicas_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run nicas_7x7 step
if test "${run_split_nicas_7x7}" = "true"; then
   echo `date`": sbatch split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch split_nicas_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run psichitouv_c192 step
if test "${run_split_psichitouv_c192}" = "true"; then
   echo `date`": sbatch split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch split_psichitouv_c192_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run psichitouv_7x7 step
if test "${run_split_psichitouv_7x7}" = "true"; then
   echo `date`": sbatch split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch split_psichitouv_7x7_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Dirac runs
# TODO: dependencies

# Run dirac_cor_local step
if test "${run_dirac_cor_local}" = "true"; then
   echo `date`": sbatch dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_cor_global step
if test "${run_dirac_cor_global}" = "true"; then
   echo `date`": sbatch dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_cor_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_cov_local step
if test "${run_dirac_cov_local}" = "true"; then
   echo `date`": sbatch dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_cov_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_cov_global step
if test "${run_dirac_cov_global}" = "true"; then
   echo `date`": sbatch dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_cov_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_cov_multi_local step
if test "${run_dirac_cov_multi_local}" = "true"; then
   echo `date`": sbatch dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_cov_multi_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_cov_multi_global step
if test "${run_dirac_cov_multi_global}" = "true"; then
   echo `date`": sbatch dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_cov_multi_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_full_c2a_local step
if test "${run_dirac_full_c2a_local}" = "true"; then
   echo `date`": sbatch dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_full_c2a_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_full_psichitouv_local step
if test "${run_dirac_full_psichitouv_local}" = "true"; then
   echo `date`": sbatch dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_full_psichitouv_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_full_global step
if test "${run_dirac_full_global}" = "true"; then
   echo `date`": sbatch dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_full_global_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_full_c192_local step
if test "${run_dirac_full_c192_local}" = "true"; then
   echo `date`": sbatch dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_full_c192_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

# Run dirac_full_7x7_local step
if test "${run_dirac_full_7x7_local}" = "true"; then
   echo `date`": sbatch dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
   sbatch dirac_full_7x7_local_${yyyymmddhh_first}-${yyyymmddhh_last}.sh
fi

exit 0
