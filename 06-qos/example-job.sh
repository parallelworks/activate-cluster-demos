#!/bin/bash
#SBATCH -p h100 --gpus=1 --time=00:05:00 -J qos-example
#SBATCH --output=%x-%j.out
# A tiny GPU job you can submit under any QOS, to see the tiers behave:
#   sbatch 06-qos/example-job.sh                  # your Project QOS (default)
#   sbatch --qos=general 06-qos/example-job.sh    # shared burst pool
#   sbatch --qos=spot    06-qos/example-job.sh    # preemptible
echo "job    : $SLURM_JOB_ID"
echo "node   : $(hostname)"
echo "qos    : $(squeue -h -j "$SLURM_JOB_ID" -o %q)"
echo "account: $(squeue -h -j "$SLURM_JOB_ID" -o %a)"
module load pytorch
python -c "import torch; print('gpu    :', torch.cuda.get_device_name(0))"
