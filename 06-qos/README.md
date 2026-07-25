# QOS: how GPUs are shared, and how to see your own limits

The cluster runs a single GPU partition, `h100`, and it is the default, so you do not have to name it. GPUs are shared across groups with Slurm QOS.

- Your **Project QOS** is your default. It caps how many GPUs your group can run at once, at your group's allocation. You never type it; it applies to every job automatically.
- **`--qos=general`** bursts into a shared pool, up to a per-group limit, when the pool is free.
- **`--qos=spot`** is uncapped and preemptible. It runs on otherwise idle GPUs and can be reclaimed when a Project or general job needs the capacity; you get a 10-minute grace window and the job requeues. Checkpoint your work.

Project and general jobs are never preempted. Caps bound the GPUs you can run at once, never how many jobs you can queue: submit as much as you like, and work starts as capacity frees up. Time limits differ by tier: your Project QOS has none, `general` allows up to 3 days, and `spot` up to 1 day.

## See your limits

### The short way: `mylimits` (also available as `myquota`)

`mylimits` is installed on the cluster and answers this in one shot. `myquota` is the same command under a second name, so either works:

```
mylimits
```

```
Slurm access for jsmith

  PROJECT (ACCOUNT)                  QOS YOU MAY USE
  my-group                           my-group,general,spot (default)

Tier limits
  QOS            GPU LIMIT                    MAX WALLTIME   NOTES
  spot           unlimited                    1-00:00:00     interruptible - can be requeued
  general        5 per project (pool 40)      3-00:00:00     shared burst pool
  my-group       11 GPUs                      none

Your jobs right now
  running: 0   pending: 0   GPUs in use: 0

Storage
  PATH                       USED       SIZE
  /home/jsmith (home)        3.1G       1.0T
  /project/my-group          412G       50T
```

Reading it: the `PROJECT (ACCOUNT)` block is which QOS you may submit under and which one applies by default. `GPU LIMIT` is the cap, and on `general` the shared pool total is shown alongside the per-project share of it. `MAX WALLTIME` is worth noting: your Project QOS has no time limit, but `general` jobs are capped at 3 days and `spot` jobs at 1 day.

It only reads the accounting database and the filesystem, so it is safe to run any time. You see your own group's limits; the shared `general` pool and `spot` are visible to everyone.

Ready-made job scripts live in `/software/templates/` on the cluster (single-GPU, multi-GPU, multi-node, container, spot, burst). Copy one and edit it rather than starting from scratch.

The rest of this page is what `mylimits` runs underneath, useful when you want a specific field or are scripting against it.

### Which QOS can I use, and what is my default?

```
sacctmgr show assoc user=$USER format=Account,QOS,DefaultQOS
```

```
   Account                     QOS             DefaultQOS
---------- ----------------------- ----------------------
 my-group     my-group,general,spot               my-group
```

Read it as: your account is `my-group`, you may submit under `my-group` (your Project QOS), `general`, or `spot`, and if you do not pass `--qos` you get `my-group`.

### What is my GPU cap?

```
sacctmgr show qos $(sacctmgr -n show assoc user=$USER format=DefaultQOS%20 | head -1 | tr -d ' '),general,spot \
  format=Name,GrpTRES%28,MaxTRESPerAccount%22,Priority
```

Or simply name them, substituting your group:

```
sacctmgr show qos my-group,general,spot format=Name,GrpTRES%28,MaxTRESPerAccount%22,Priority
```

```
      Name                      GrpTRES              MaxTRESPA  Priority
---------- ---------------------------- ---------------------- ---------
  my-group    cpu=176,gres/gpu=11,mem=+                              3000
   general    cpu=640,gres/gpu=40,mem=+   cpu=80,gres/gpu=5,mem+      2000
      spot                                                           1000
```

The number after **`gres/gpu=`** is the GPU limit. `GrpTRES` is the ceiling for the whole QOS; on `general`, `MaxTRESPerAccount` is the most any one group may take from that shared pool at a time. `spot` has no cap. Higher `Priority` wins when jobs compete, which is why Project jobs outrank general, and general outranks spot.

Add `%NN` after a column name to widen it, as above; without it Slurm truncates the value with a `+`.

### What am I running, and why is something waiting?

```
squeue --me
```

A `REASON` of **`QOSGrpGRES`** means your group is at its GPU cap and the job starts automatically as your own jobs finish. `Priority` or `Resources` means the cluster is simply busy. To see the QOS a job is using:

```
squeue --me -O JobID,Name,QOS,State,Reason
scontrol show job <jobid> | grep -E "QOS|Reason|TRES"
```

### What have I used?

```
sacct -X --format=JobID,JobName%16,QOS,AllocTRES%28,Elapsed,State
sacct -X --starttime now-7days --format=JobID,QOS,Elapsed,State
```

## Submit under a QOS

`example-job.sh` in this folder is a small GPU job that prints the QOS it ran under, so you can watch the tiers behave:

```
sbatch 06-qos/example-job.sh                 # your Project QOS, applied by default
sbatch --qos=general 06-qos/example-job.sh   # burst into the shared pool
sbatch --qos=spot    06-qos/example-job.sh   # preemptible; checkpoint real work
```

```
job    : 132
node   : slurm-h100-196-227
qos    : general
account: my-group
gpu    : NVIDIA H100 80GB HBM3
```

Swap in your own script the same way; the `--qos` flag is all that changes.

Interactive work takes the same flags:

```
srun --gpus=1 --pty bash -i
srun --qos=general --gpus=2 --pty bash -i
```

## Making spot jobs safe to preempt

A preempted spot job is requeued, so it will run again from the start unless it can resume. Write checkpoints to your project directory and look for one on startup:

```
#!/bin/bash
#SBATCH --qos=spot --gpus=1 --requeue
module load pytorch
# your own script, with whatever checkpoint flags it takes
python my_train.py --checkpoint-dir /project/<group>/ckpt --resume-if-exists
```

Spot is the right choice for large sweeps, scans, and anything that checkpoints cheaply. Keep deadline work on your Project QOS.
