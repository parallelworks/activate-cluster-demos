#!/bin/bash
#SBATCH -p h100 --gpus=8 --time=02:00:00 -J raycluster
#SBATCH --output=%x-%j.out
module load pytorch
ray start --head --port=6379 --dashboard-host=0.0.0.0 --dashboard-port=8265 --num-gpus=8 --block
