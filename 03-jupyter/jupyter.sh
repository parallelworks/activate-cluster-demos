#!/bin/bash -l
#SBATCH -p h100 --gpus=1 --time=08:00:00 -J jupyter
# `#!/bin/bash -l` gives a login shell so `module` is defined; see 01-pytorch/train.sh.
command -v module >/dev/null 2>&1 || source /etc/profile.d/lmod.sh
module load pytorch
# The token URL is written to slurm-<jobid>.out about 30-50 seconds after start.
jupyter lab --no-browser --ip=0.0.0.0 --port=8888
