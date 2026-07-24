#!/bin/bash -l
#SBATCH -p h100 --gpus=8 --time=01:00:00 -J train
# The -l above matters: batch scripts run in a NON-login shell by default, where
# `module` is not defined. Starting with `#!/bin/bash -l` sources the profile so
# Lmod is available. The guard below is a fallback if the profile is bypassed.
command -v module >/dev/null 2>&1 || source /etc/profile.d/lmod.sh
module load pytorch
torchrun --nproc_per_node=8 train.py
