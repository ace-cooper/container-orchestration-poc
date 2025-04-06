# container-orchestration-poc

🚀 **Production-ready K3s setup for multi-project container hosting**  
✅ Automatic scaling (HPA) | 📊 Monitoring stack | 🐳 Docker-ready  

## Purpose  
A ready-to-deploy infrastructure PoC featuring:  
- Single-node K3s cluster with metrics server  
- Pre-configured autoscaling (HPA)  
- Monitoring stack (Prometheus + Grafana)  
- Optimized for AI workloads (Ollama/Gemma)  
- Multi-database support (PostgreSQL + Redis)  

## Ideal For  
- Developers needing quick container hosting  
- AI project deployments  
- Multi-project environments  
- Learning Kubernetes orchestration  

## Quick Start  
```bash
# 1. Docker setup
./setup_docker.sh

# 2. K3s + Metrics Server
./setup_k3s.sh

# 3. Monitoring (Optional)
./setup_monitoring.sh

## Features

| Component         | Description                                                                 |
|-------------------|-----------------------------------------------------------------------------|
| 🔄 Auto-scaling   | Horizontal Pod Autoscaler (HPA) pre-configured for CPU/memory metrics       |
| 📈 Monitoring     | Prometheus + Grafana stack with preloaded Kubernetes dashboards             |
| 🗃️ Databases      | PostgreSQL (multi-db support) + Redis instances                             |
| 🤖 AI Ready       | Resource profiles for Ollama (Gemma 7B - 9GB reserved)                      |
| 🔒 Isolation      | Namespace-based project separation                                          |
| 🛡️ Security       | Basic RBAC and network policies                                             |
| 🔌 Load Balancing | Traefik ingress controller pre-installed                                    |
| 📦 Storage        | Local volume provisioning                                                   |

## Roadmap

| Status | Feature                          | Priority  |
|--------|----------------------------------|-----------|
| ✅     | Single-node k3s setup            | Released  |
| 🚧     | Multi-node cluster guide         | High      |
| 🔜     | Blue/Green deployment samples    | Medium    |
| 🔜     | Custom HPA metrics               | High      |
| 🔜     | SSL/TLS automation               | Medium    |
| 🔜     | GPU support documentation        | Low       |
| 🔜     | Backup solutions                 | Medium    |