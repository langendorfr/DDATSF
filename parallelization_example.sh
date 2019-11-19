#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=00:30:00
#SBATCH --qos=testing
#SBATCH --partition=shas-testing
#SBATCH --ntasks=24
#SBATCH --job-name=lab_meeting
#SBATCH --output=lab_meeting.%j.out

module purge
module load R/3.5.0

echo "hello"
sleep 2
echo "goodbye"

Rscript parallelization_example.R

echo "Done!"
