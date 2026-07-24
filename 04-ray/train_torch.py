import ray, torch
ray.init()
@ray.remote(num_gpus=1)
def gpu_check():
    return torch.cuda.get_device_name(0), torch.cuda.is_available()
print(ray.get(gpu_check.remote()))
