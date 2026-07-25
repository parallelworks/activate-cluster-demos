#!/bin/bash
#SBATCH -p h100 --gpus=8 --time=01:00:00 -J train
#SBATCH --output=%x-%j.out
module load pytorch
torchrun --nproc_per_node=8 train.py
