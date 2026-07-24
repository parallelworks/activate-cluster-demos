# Kubernetes (CKS) namespace access and quotas

Groups on the Kubernetes list get a dedicated namespace on CoreWeave CKS with a resource quota. Authenticate with the pw CLI, then use standard `kubectl`, `helm`, and your own operators. Group membership scopes you to your namespace.

## Authenticate and inspect

```
pw kube auth
kubectl get resourcequota -n <your-namespace>
kubectl get pods -n <your-namespace> -o wide
```

The quota shows your namespace allocation (CPU, memory, GPU) and live usage.

## Requests beyond your quota are refused at admission

A pod that asks for more than your namespace allows is rejected before it ever schedules. For example, a CPU request past your quota:

```
kubectl run demo -n <your-namespace> --image=nginx:1.27-alpine --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"c","image":"nginx:1.27-alpine","resources":{"requests":{"cpu":"64"},"limits":{"cpu":"64"}}}]}}'
# Error from server (Forbidden): ... exceeded quota
```

## Run a GPU pod

```
kubectl run gpu-check -n <your-namespace> --restart=Never \
  --image=nvidia/cuda:12.4.1-base-ubuntu22.04 \
  --overrides='{"spec":{"containers":[{"name":"c","image":"nvidia/cuda:12.4.1-base-ubuntu22.04","command":["nvidia-smi","-L"],"resources":{"requests":{"nvidia.com/gpu":"1"},"limits":{"nvidia.com/gpu":"1"}}}]}}'
kubectl logs gpu-check -n <your-namespace>     # ~30s for the image pull on first run
# GPU 0: NVIDIA H100 80GB HBM3

kubectl delete pod gpu-check -n <your-namespace>
```

The GPU allocation is a hard ceiling: once your namespace's GPUs are in use, a further GPU request is refused at admission.
