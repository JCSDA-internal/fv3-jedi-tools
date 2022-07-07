#!/bin/bash

####################################################################
# Directories ######################################################
####################################################################

# Data directory
export data_dir="/work/noaa/da/menetrie/StaticBTraining"

# Data directory for regridded data
export data_dir_regrid_base="/work/noaa/da/menetrie/regrid"

# FV3-JEDI source directory
export fv3jedi_dir="${HOME}/code/bundle/fv3-jedi"

# JEDI binaries directory
export bin_dir="${HOME}/build/gnu-openmpi/bundle_RelWithDebInfo/bin"
#export bin_dir="${HOME}/build/gnu-openmpi/bundle_debug/bin"
#export bin_dir="${HOME}/build/intel-impi/bundle_RelWithDebInfo/bin"
#export bin_dir="${HOME}/build/intel-impi/bundle_debug/bin"

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
export vars="psi chi t ps sphum liq_wat o3mr"

# Number of ensemble members
export nmem=80

# List of dates for the training (january or july or both)
export yyyymmddhh_list="2020010100 2020010200 2020010300 2020010400 2020010500 2020010600 2020010700 2020010800 2020010900 2020011000 2020011100 2020011200 2020011300 2020011400 2020011500 2020011600 2020011700 2020011800 2020011900 2020012000 2020012100 2020012200 2020012300 2020012400 2020012500 2020012600 2020012700 2020012800 2020012900 2020013000 2020013100"
#export yyyymmddhh_list="2020013100"

# Background date
export yyyymmddhh_bkg="2020121500"

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

# Get data
export get_data_ensemble=false
export get_data_background=false
export get_data_observations=false

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
export run_merge_states=false
export run_merge_nicas=false

# Regrid runs (at resolution ${cregrid} and with a layout [${nlx},${nly}])
export run_regrid_states=false
export run_regrid_psichitouv=false
export run_regrid_vbal=false
export run_regrid_nicas=false
export run_regrid_merge_nicas=false

# Dirac runs
export run_dirac_cor_local=false
export run_dirac_cor_global=false
export run_dirac_cov_local=false
export run_dirac_cov_global=false
export run_dirac_cov_multi_local=false
export run_dirac_cov_multi_global=false
export run_dirac_full_c2a_local=false
export run_dirac_full_psichitouv_local=false
export run_dirac_full_global=false
export run_dirac_full_regrid_local=false

# Variational runs
export run_variational_3dvar=false
export run_variational_3dvar_specific_obs=false
export run_variational_3dvar_regrid=false

# Prepare scripts only (do not run sbatch)
export prepare_scripts_only=false

# Benchmark mode
export benchmark=false
