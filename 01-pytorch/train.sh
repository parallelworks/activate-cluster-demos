#!/bin/bash
#SBATCH -p h100 --gpus=8 --time=01:00:00 -J train
#SBATCH --output=%x-%j.out
# Works whether you submit from the repo root or from 01-pytorch/.
BASE="${SLURM_SUBMIT_DIR:-$PWD}"
TRAIN="$BASE/train.py"
[ -f "$TRAIN" ] || TRAIN="$BASE/01-pytorch/train.py"
module load pytorch
torchrun --nproc_per_node=8 "$TRAIN"
