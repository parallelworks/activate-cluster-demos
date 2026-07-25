"""Minimal training step, single GPU or multi-GPU via torchrun.

Runs a few steps on synthetic data so the job does real GPU work without
needing a dataset. Replace the model and data with your own.
"""
import os

import torch
import torch.distributed as dist
import torch.nn as nn
import torch.nn.functional as F

world_size = int(os.environ.get("WORLD_SIZE", 1))
distributed = world_size > 1

if distributed:
    dist.init_process_group("nccl")
    rank = dist.get_rank()
    local_rank = int(os.environ["LOCAL_RANK"])
else:
    rank, local_rank = 0, 0

torch.cuda.set_device(local_rank)
device = torch.device("cuda", local_rank)

model = nn.Sequential(nn.Linear(1024, 4096), nn.ReLU(), nn.Linear(4096, 10)).to(device)
if distributed:
    model = nn.parallel.DistributedDataParallel(model, device_ids=[local_rank])
optimizer = torch.optim.SGD(model.parameters(), lr=0.01)

for step in range(50):
    inputs = torch.randn(256, 1024, device=device)
    targets = torch.randint(0, 10, (256,), device=device)
    loss = F.cross_entropy(model(inputs), targets)
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()
    if rank == 0 and step % 10 == 0:
        print(f"step {step:3d}  loss {loss.item():.4f}", flush=True)

if rank == 0:
    print(f"done on {world_size} rank(s), {torch.cuda.get_device_name(local_rank)}", flush=True)

if distributed:
    dist.destroy_process_group()
