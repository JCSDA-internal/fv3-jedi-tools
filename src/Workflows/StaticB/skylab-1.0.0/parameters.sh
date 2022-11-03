#!/bin/bash

####################################################################
# Directories ######################################################
####################################################################

# Input Data directory (need to be more generic)
export r2d2_dir="/data/users/jbarre/gfs_aero_ensemble"

export WORK_DIR="/data/users/jbarre"

# Ouput Data directory
export data_dir="${WORK_DIR}/StaticBTraining"

# Data directory for regridded data
export data_dir_regrid_base="${WORK_DIR}/regrid"

# FV3-JEDI source directory
export fv3jedi_dir="${WORK_DIR}/jedi-bundle/fv3-jedi"

export fv3jeditools_dir="${WORK_DIR}/fv3-jedi-tools"

# JEDI binaries directory
export bin_dir="${WORK_DIR}/jedi-bundle/build/bin"
#export bin_dir="${HOME}/build/gnu-openmpi/bundle_debug/bin"
#export bin_dir="${HOME}/build/intel-impi/bundle_RelWithDebInfo/bin"
#export bin_dir="${HOME}/build/intel-impi/bundle_debug/bin"

# Experiments directory
export xp_dir="${WORK_DIR}/xp"

# BUMP directory
export bump_dir="skylab-1.0.0"

####################################################################
# Environment script path ##########################################
# Provided: gnu-openmpi or intel-impi on Orion #####################
####################################################################

#export env_script=${xp_dir}/env_script/gnu-openmpi_env.sh
export env_script=${xp_dir}/env_script/intel-impi_env.sh
export rankfile_script=${xp_dir}/env_script/rankfile.bash
export cores_per_node=40

####################################################################
# Parameters #######################################################
####################################################################

# Variables
#export vars="psi chi t ps sphum liq_wat o3mr"
#export vars="mass_fraction_of_sulfate_in_air mass_fraction_of_dust001_in_air"

export vars="mass_fraction_of_sulfate_in_air mass_fraction_of_hydrophobic_black_carbon_in_air mass_fraction_of_hydrophilic_black_carbon_in_air mass_fraction_of_hydrophobic_organic_carbon_in_air mass_fraction_of_hydrophilic_organic_carbon_in_air mass_fraction_of_dust001_in_air mass_fraction_of_dust002_in_air mass_fraction_of_dust003_in_air mass_fraction_of_dust004_in_air mass_fraction_of_dust005_in_air mass_fraction_of_sea_salt001_in_air mass_fraction_of_sea_salt002_in_air mass_fraction_of_sea_salt003_in_air mass_fraction_of_sea_salt004_in_air"

#export vars="mass_fraction_of_sulfate_in_air" # bc1 bc2 oc1 oc2 dust1 dust2 dust3 dust4 dust5 seas1 seas2 seas3 seas4 seas5"
varlist=""
for var in ${vars}; do
    varlist=${varlist}","${var}
done
varlist=${varlist:1}
export varlist
# Number of ensemble members
export nmem=20

#offset in hours to get forecast at analysis time
export offset=6

# List of dates for the training (january or july or both)
#make a for loop for this...
start_date="2021080106"
end_date="2021080500"
d=$start_date
until [[ $d > ${end_date} ]]; do
    yyyymmdd=${d:0:8}
    hh=${d:8:2}
    yyyymmddhh_list=$yyyymmddhh_list$d" "
    d=$(date +%Y%m%d%H -d "$yyyymmdd $hh + $offset hour")
done
echo $yyyymmddhh_list
export yyyymmddhh_list

# Background date
export yyyymmddhh_bkg="2021080200"

# Observation date
export yyyymmddhh_obs="2021080121"

# Default layout
export nlx_def=6
export nly_def=6
export ntasks_def=$((6*nlx_def*nly_def))
export cdef=96

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
export run_merge_states=true
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
