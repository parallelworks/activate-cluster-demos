#!/bin/bash
#SBATCH -p h100 --gpus=8 --time=01:00:00 -J train
source /etc/profile.d/lmod.sh; module use /software/modulefiles
module load pytorch
torchrun --nproc_per_node=8 train.py
