# QOS: how GPUs are shared, and how to see your limits

The cluster uses Slurm QOS to share GPUs across groups on the single `h100` partition.

- Your **Project QOS** is your default. It caps how many GPUs your group can run at once, at your group's allocation. You never type it; it applies to every job.
- `--qos=general` bursts into a shared pool, up to a per-group limit, when the pool is free.
- `--qos=spot` is uncapped and preemptible: it runs on idle GPUs and can be reclaimed when a Project or general job needs the capacity. You get a 10-minute grace window and the job requeues, so checkpoint your work.

Project and general jobs are never preempted. Caps bound the GPUs you run at once, never how many jobs you can queue.

## See your limits and available QOS

```
# which QOS you can use, and your default
sacctmgr show assoc user=$USER format=Account,QOS,DefaultQOS

# the GPU cap on each QOS you can use (the gres/gpu= value is the GPU limit)
sacctmgr show qos <yourgroup>,general,spot format=Name,GrpTRES,MaxTRESPerAccount

# your jobs; a REASON of QOSGrpGRES means you are at your GPU cap
squeue --me

# your usage
sacct -X --format=JobID,QOS,Elapsed,State
```

## Submit under a QOS

```
sbatch sweep.sh                 # your Project QOS, applied by default
sbatch --qos=general sweep.sh   # burst into the shared pool
sbatch --qos=spot bigscan.sh    # preemptible, uncapped; checkpoint your work
```
