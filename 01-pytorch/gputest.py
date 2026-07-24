import torch

print("cuda_available:", torch.cuda.is_available())
print("gpu:", torch.cuda.get_device_name(0))
