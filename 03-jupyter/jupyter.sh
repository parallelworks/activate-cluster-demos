#!/bin/bash
#SBATCH -p h100 --gpus=1 --time=08:00:00 -J jupyter
#SBATCH --output=%x-%j.out
module load pytorch
# The token URL appears in the job output 30-50 seconds after the job starts.
jupyter lab --no-browser --ip=0.0.0.0 --port=8888
