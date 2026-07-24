#!/bin/bash
#SBATCH -p h100 --gpus=8 --time=02:00:00 -J raycluster
source /etc/profile.d/lmod.sh; source /etc/profile.d/zz-nodes-modulepath.sh 2>/dev/null || module use /software/modulefiles
module load pytorch
ray start --head --port=6379 --dashboard-host=0.0.0.0 --dashboard-port=8265 --num-gpus=8 --block
