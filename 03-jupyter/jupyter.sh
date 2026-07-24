#!/bin/bash
#SBATCH -p h100 --gpus=1 --time=08:00:00 -J jupyter
source /etc/profile.d/lmod.sh; module use /software/modulefiles
module load pytorch
jupyter lab --no-browser --ip=0.0.0.0 --port=8888
