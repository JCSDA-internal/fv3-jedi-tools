#!/bin/bash

####################################################################
# Directories ######################################################
####################################################################

# Data directory
export data_dir="/work/noaa/da/menetrie/StaticBTraining"

# Ensemble data
export ensemble_dir="/work/noaa/da/menetrie/ensemble"

# Data directory for regridded data
export data_dir_regrid_base="/work/noaa/da/menetrie/regrid"

# FV3-JEDI source directory
export fv3jedi_dir="${HOME}/code/bundle/fv3-jedi"

# JEDI binaries directory
export bin_dir="${HOME}/build/gnu-openmpi/bundle_RelWithDebInfo/bin"
#export bin_dir="${HOME}/build/gnu-openmpi/bundle_debug/bin"

# Experiments directory
export xp_dir="${HOME}/xp"

####################################################################
# Environment script path ##########################################
# Provided: gnu-openmpi or intel-impi on Orion #####################
####################################################################

export env_script=${xp_dir}/env_script/gnu-openmpi_env.sh
#export env_script=${xp_dir}/env_script/intel-impi_env.sh
export rankfile_script=${xp_dir}/env_script/rankfile.bash
export cores_per_node=40

####################################################################
# Parameters #######################################################
####################################################################

# Variables
export vars="stream_function chi t ps sphum liq_wat o3mr"

# Number of ensemble members
export nmem=80

# List of dates for the training
export yyyymmddhh_list="2021080100"

# Background date
export yyyymmddhh_bkg="2021080100"

# Observation date
export yyyymmddhh_obs="2020121421"

# Default layout
export nlx_def=6
export nly_def=6
export ntasks_def=$((6*nlx_def*nly_def))
export cdef=384

# Regridding layout and resolution
export nlx_regrid=4
export nly_regrid=4
export ntasks_regrid=$((6*nlx_regrid*nly_regrid))
export cregrid=96

# Specific observations experiments
export obs_xp="
sondes
single_ob_a
single_ob_b
single_ob_c
single_ob_d
single_ob_e
single_ob_f"
export obs_xp_full="
sondes
single_ob_a
single_ob_b
single_ob_c
single_ob_d
single_ob_e
single_ob_f"

####################################################################
# What should be run? ##############################################
####################################################################

# Daily runs
export run_daily_state_to_control=true
export run_daily_vbal=true
export run_daily_unbal=true
export run_daily_varmom=true

# Final runs
export run_final_psichitouv=true
export run_final_vbal=true
export run_final_var=true
export run_final_cor=true
export run_final_nicas=true

# Merge runs
export run_merge_states=true
export run_merge_nicas=true

# Regrid runs (at resolution ${cregrid} and with a layout [${nlx},${nly}])
export run_regrid_states=true
export run_regrid_vbal=true
export run_regrid_nicas=true
export run_regrid_merge_nicas=true

# Dirac runs
export run_dirac_cor_local=true
export run_dirac_cor_global=true
export run_dirac_cov_local=true
export run_dirac_cov_global=true
export run_dirac_cov_multi_local=true
export run_dirac_cov_multi_global=true
export run_dirac_full_c2a_local=true
export run_dirac_full_psichitouv_local=true
export run_dirac_full_c2a_global=true
export run_dirac_full_regrid_local=true

# Variational runs
export run_variational_3dvar=false
export run_variational_3dvar_specific_obs=false
export run_variational_3dvar_regrid=false
export run_variational_3dvar_full_regrid=false

# Prepare scripts only (do not run sbatch)
export prepare_scripts_only=false

# Benchmark mode
export benchmark=false
