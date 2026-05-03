#!/bin/bash
#SBATCH --job-name=montecarlo
#SBATCH --partition=gpuA100x4
#SBATCH --account=YOUR_ACCOUNT
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=16g
#SBATCH --time=00:20:00
#SBATCH --output=logs/%j.out

module reset
module load nvhpc-hpcx-cuda12/25.3

nvidia-smi --query-gpu=name --format=csv,noheader

  sweep across 4 sample sizes: 10^4, 10^6, 10^8, 10^9

for N in 10000 1000000 100000000 1000000000; do
    echo "=== N=$N ==="
    ./cpu_baseline $N
    ./gpu_mc       $N
done