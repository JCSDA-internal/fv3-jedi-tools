cat << EOF > "sbatch_${yaml/.yaml/}.sh"
#!/bin/bash
#SBATCH --job-name=${yaml/.yaml/}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --cpus-per-task=1
#SBATCH --time=03:00:00
#SBATCH -e ${log_dir}/${yaml/.yaml/}.err
#SBATCH -o ${log_dir}/${yaml/.yaml/}.out
#SBATCH --ntasks=12
cd ${run_dir}
export OMP_NUM_THREADS=1
source ${environment_dir}/${environment}
SECONDS=0
#mpirun -np 12 ${executable_dir}/fv3jedi_error_covariance_training.x ${yaml_dir}/vbal_2021080306+03.yaml
srun -n 12 ${executable_dir}/${executable} ${yaml_dir}/${yaml}
wait
echo "ELAPSED TIME = ${SECONDS} s"
sleep 30
EOF

