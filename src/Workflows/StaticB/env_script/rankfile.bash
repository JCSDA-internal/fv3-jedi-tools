#!/bin/bash
# Create OpenMPI rankfile:
# - requires --cpus-per-task
# - works only with --nodes
# - assume all nodes allocated to this job are alike

# Get and save information about node running this script
NODE_INFO=$(pwd)/${SLURMD_NODENAME}_${SLURM_JOB_ID}
rm -f ${NODE_INFO}
scontrol show node "${SLURMD_NODENAME}" > ${NODE_INFO}

# Number of cores on node
CORES_PER_NODE=$(grep CPUTot ${NODE_INFO} | sed 's/^.*CPUTot=\([0-9]*\).*$/\1/')

# Number of sockets on node
SOCKETS_PER_NODE=$(grep Sockets ${NODE_INFO} | sed 's/^.*Sockets=\([0-9]*\).*$/\1/')
rm -f ${NODE_INFO}

# Get all SLURM hosts
SLURM_HOSTFILE=$(pwd)/mpi.hosts_${SLURM_JOB_ID}
rm -f ${SLURM_HOSTFILE}
scontrol show hostnames ${SLURM_JOB_NODELIST} | sort > ${SLURM_HOSTFILE}
cat ${SLURM_HOSTFILE}

# Map ranks to slots
OMPI_RANKFILE=$(pwd)/mpi.rankfile_${SLURM_JOB_ID}
rm -f ${OMPI_RANKFILE}
touch ${OMPI_RANKFILE}
CORES_PER_SOCKET=$((CORES_PER_NODE/SOCKETS_PER_NODE))
SLOTS_PER_NODE=$((CORES_PER_NODE/SLURM_CPUS_PER_TASK))
RANK=0
for HOST in $(cat ${SLURM_HOSTFILE}); do
   for SLOT in $(seq 0 $((SLOTS_PER_NODE-1))); do
      CORE_OFFSET=$((SLOT*SLURM_CPUS_PER_TASK))
      SOCKET=$((CORE_OFFSET/CORES_PER_SOCKET))
      CORE=$((CORE_OFFSET%CORES_PER_SOCKET))
      echo "rank ${RANK}=${HOST} slot=${SOCKET}:${CORE}" >> ${OMPI_RANKFILE}
      SLOT=$((SLOT+1))
      RANK=$((RANK+1))
   done
done
