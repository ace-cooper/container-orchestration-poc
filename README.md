# Container Orchestration PoC (WIP)
<img src="https://k3s.io/img/k3s-logo-light.svg" alt="K3s Logo" width="200"/>

## ⚠️ Warning: Educational Project

> **IMPORTANT:** This project is currently labeled as Work In Progress (WIP) and is intended for **educational and study purposes only**. It is not yet recommended for production use.
>
> I am actively learning and improving this setup as I explore Kubernetes orchestration concepts. The WIP label will be removed once I believe the implementation meets production standards and security best practices.
>
> Use at your own risk and always consult official documentation for production deployments.


🚀 **K3s setup for multi-project container hosting**  
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


