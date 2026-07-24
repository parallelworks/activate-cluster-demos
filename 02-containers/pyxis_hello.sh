#!/bin/bash
# one-liners; run from the login node
srun -p h100 --container-image=docker://ubuntu:22.04 grep PRETTY_NAME /etc/os-release
srun -p h100 --gpus=1 --container-image=docker://ubuntu:22.04 nvidia-smi -L
