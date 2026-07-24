# ACTIVATE GPU Cluster: Quick Start and Demos

Runnable examples and a command reference for the NVIDIA H100 GPU cluster operated by Parallel Works on dedicated CoreWeave infrastructure and managed through the ACTIVATE control plane. Everything here has been run on the live cluster. Questions go to support@parallelworks.com.

Clone this repo onto the cluster and run the examples from your home directory:

```
git clone https://github.com/parallelworks/activate-cluster-demos.git
cd activate-cluster-demos
```

| Folder | What it shows |
|---|---|
| `01-pytorch` | Modules and a single- to multi-GPU PyTorch job |
| `02-containers` | Containers through Slurm with pyxis and enroot |
| `03-jupyter` | A Jupyter notebook on a GPU node over an SSH tunnel |
| `04-ray` | A Ray cluster on Slurm, with jobs submitted from your laptop |
| `05-k8s` | Kubernetes (CKS) namespace access and quotas |
| `06-qos` | How GPUs are shared, plus `mylimits` to see your own caps and usage |

## Getting on the cluster

Your account is provisioned in ACTIVATE at activate.parallel.works; set your password from the email invitation. From a terminal, install the pw CLI and connect with `pw ssh nodescluster`. VS Code and remote desktop sessions are also available through ACTIVATE.

## How the scheduler shares GPUs

The cluster runs Slurm. There is a single GPU partition, `h100`, and it is the default, so you do not have to name it; including `-p h100` is fine and harmless.

Every group has a group QOS, called your Project QOS, and it is your default. It caps the number of GPUs your group can run at once at the number your team was allocated; you never type it. On top of that, `--qos=general` bursts into a shared pool up to a per-group limit, and `--qos=spot` is uncapped and preemptible: spot jobs run on idle GPUs and can be reclaimed with a 10-minute grace window, then requeue, so checkpoint your work. Project and general jobs are never preempted. To see your own QOS, cap, and current usage, run `mylimits` (in `06-qos`, or already on your PATH if support has installed it cluster-wide). `06-qos/README.md` documents the underlying `sacctmgr` commands.

## Run a PyTorch job

```
module load pytorch
srun -p h100 --gpus=1 python 01-pytorch/gputest.py
```

Returns `cuda_available: True` and `NVIDIA H100 80GB HBM3`. The batch skeleton `01-pytorch/train.sh` shows the 8-GPU `torchrun` form; multi-node adds `--nodes=2 --gpus-per-node=8`, with NCCL over InfiniBand already tuned. The same pattern runs NAMD, OpenMM, and JAX: load the module, then srun or sbatch.

Start every batch script with `#!/bin/bash -l`. See Troubleshooting below for why.

## Containers with pyxis and enroot

```
bash 02-containers/pyxis_hello.sh      # two verified one-liners
bash 02-containers/enroot_build.sh     # imports, builds, and runs on a GPU node
```

Use glibc images such as ubuntu:22.04 or the NGC catalog, not ubuntu:latest or alpine. `enroot import` runs on a compute node, and `create`/`start` must run on the same node. Large images pull once and then cache on the node.

## Jupyter on a GPU node

```
sbatch 03-jupyter/jupyter.sh
squeue --me                            # note the node
grep -o "http://.*token=.*" slurm-<jobid>.out | head -1
```

On your laptop, open a tunnel and browse to the notebook:

```
pw ssh nodescluster -L 8888:<gpu-node>:8888
# open http://localhost:8888 and paste the token
```

## Ray, submitting from your laptop

```
sbatch 04-ray/raycluster.sh
squeue --me                            # note the head node
```

On your laptop (with `pip install ray` and the pw CLI):

```
pw ssh nodescluster -L 8265:<head-node>:8265
export RAY_ADDRESS=http://localhost:8265
ray job submit --working-dir 04-ray -- python train_torch.py
# -> ('NVIDIA H100 80GB HBM3', True)  SUCCEEDED
```

## Where your data lives

Your home `/home/<username>` (small quota) holds code and environments; your group's `/project/<group>` (large, shared, on every node) holds datasets and results; `/software` is the Lmod module tree. Each GPU server also has fast node-local NVMe scratch that is ephemeral, so copy results back to your project directory.

## Troubleshooting

**`module: command not found`, or `python`/`ray`/`jupyter` not found in a job.** This is the most common problem, and it is almost always a login-shell issue. `module` is defined by the shell profile, which only runs in a login shell. An interactive SSH session is a login shell, so `module load pytorch` works when you type it. A batch script is not, so the same line inside a plain `#!/bin/bash` script fails, and every command the module was supposed to provide fails after it.

Start batch scripts with a login shell:

```
#!/bin/bash -l
#SBATCH -p h100 --gpus=1
module load pytorch
python train.py
```

The same applies to any non-interactive command, for example over SSH: use `pw ssh nodescluster "bash -lc 'module load pytorch; python train.py'"`. If you need a fallback inside a script, `command -v module >/dev/null || source /etc/profile.d/lmod.sh` restores it. The example scripts in this repo all do this.

Watch out for pipes too: `module load pytorch | tee log` runs the load in a subshell, so the module is not loaded in your script. Load first, then run.

**`srun` says `execve(): python: No such file or directory`.** The module was not loaded in the environment `srun` inherited. Run `module load pytorch` in the same shell first, then `srun`, and confirm with `command -v python`; it should be under `/software`.

**A job sits in `PENDING` with reason `QOSGrpGRES`.** That is your GPU cap, not an error. The job starts as your running jobs finish. See `06-qos` for how to view your limits.

**`Module ERROR: Magic cookie '#%Module' missing`.** Cosmetic Lmod noise from a stray file in the module tree; it does not affect your job. Report it to support and we will clear it.

## Getting help

support@parallelworks.com is staffed 24/7. There is a standing weekly office-hours session, and we run additional training on request. User Guide and CLI Reference: docs.parallel.works.
