To make yamls and scripts for training 
bash c12bmatworkflow.sh
(Make sure to check which options are set to true int the #tasks to do section of the script)
#tasks to do
export make_dirs=1
export get_data=0
export make_yamls=1
export make_sbatch=1

Once all yamls and sbatch scripts are made the order of execution is:

For staticb:

1. bash submit_new_staticb_ens_to_psichi.sh  (submits batch jobs for each date)
2. bash submit_new_staticb_prep.sh (submits batch jobs for each date)
3. sbatch sbatch_new_staticb_vbal_gfs.sh
4. sbatch sbatch_new_staticb_var_gfs.sh
5. sbatch sbatch_new_staticb_cor_gfs.sh
6. sbatch sbatch_new_staticb_nicas_gfs.sh
7. (optional) sbatch make_new_staticb_split_vbal_gfs.sh (note change -n"12" to -n"6" in sbatch script)
8. (optional) sbatch make_new_staticb_split_nicas_gfs.sh (note change -n"12" to -n"6" in sbatch script)

For ensembleb:

1. bash submit_new_ensembleb_prep_gfs.sh (submits batch jobs for each date)
2. sbatch sbatch_new_ensembleb_loc_gfs.sh
3  sbatch sbatch_new_ensembleb_nicas_gfs.sh
4. (optional) sbatch_new_ensembleb_split_nicas_gfs.sh (note chante -n "12" to -n "6" in sbatch script)

