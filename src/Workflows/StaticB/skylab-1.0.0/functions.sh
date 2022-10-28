#!/bin/bash

####################################################################
# Function: prepare sbatch script
####################################################################
prepare_sbatch () {
   # Parameters
   job=$1
   ntasks=$2
   cpus_per_task=$3
   threads=$4
   time=$5
   exe=$6

   # Create work directory
   mkdir -p ${work_dir}/${job}
   # Common directives
cat<< EOF > ${sbatch_dir}/${job}.sh
#!/bin/bash
#SBATCH --job-name=${job}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --time=${time}
#SBATCH -e ${work_dir}/${job}/${job}.err
#SBATCH -o ${work_dir}/${job}/${job}.out
EOF

   if test "${benchmark}" = "true"; then
      # Benckmark directives
      ppn=$((cores_per_node/cpus_per_task))
      nodes=$(((ntasks+ppn-1)/ppn))
cat<< EOF >> ${sbatch_dir}/${job}.sh
#SBATCH --nodes=${nodes}-${nodes}
#SBATCH --exclusive
#SBATCH --wait-all-nodes=1
EOF
   else
      # Normal experiment directives
cat<< EOF >> ${sbatch_dir}/${job}.sh
#SBATCH --ntasks=${ntasks}
EOF
   fi

   # Common commands
cat<< EOF >> ${sbatch_dir}/${job}.sh
cd ${work_dir}/${job}
export OMP_NUM_THREADS=${threads}
source ${env_script}
SECONDS=0
EOF

   if test "${benchmark}" = "true"; then
      # Benckmark command
cat<< EOF >> ${sbatch_dir}/${job}.sh
source ${rankfile_script}
mpirun -rf \${OMPI_RANKFILE} --report-bindings -np ${ntasks} ${bin_dir}/${exe} ${yaml_dir}/${job}.yaml
EOF
   else
      # Normal experiment directives
cat<< EOF >> ${sbatch_dir}/${job}.sh
mpirun -np ${ntasks} ${bin_dir}/${exe} ${yaml_dir}/${job}.yaml
EOF
   fi

   # Final commands  
cat<< EOF >> ${sbatch_dir}/${job}.sh
wait
echo "ELAPSED TIME = \${SECONDS} s"
exit 0
EOF

}

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
