#!/bin/bash -l
#SBATCH -p h100 --gpus=8 --time=02:00:00 -J raycluster
# `#!/bin/bash -l` gives a login shell so `module` is defined; see 01-pytorch/train.sh.
command -v module >/dev/null 2>&1 || source /etc/profile.d/lmod.sh
module load pytorch
ray start --head --port=6379 --dashboard-host=0.0.0.0 --dashboard-port=8265 --num-gpus=8 --block
