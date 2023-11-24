#!/bin/bash

#SBATCH --job-name=test_job
#SBATCH --output=results.txt
#SBATCH --ntasks=2

srun bash -c "printf 'Started on %s\n' \$(hostname)"
sleep 60
srun bash -c "printf 'Done on %s\n' \$(hostname)"

