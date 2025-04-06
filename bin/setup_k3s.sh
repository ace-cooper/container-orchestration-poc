#!/bin/bash

# Installs k3s
curl -sfL https://get.k3s.io | sh -s - --docker

# Configures access to kubectl
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $USER:$USER $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# Installs Metrics Server for HPA
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Adjusts Metrics Server configuration to work on k3s
kubectl patch deployment metrics-server -n kube-system --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
kubectl patch deployment metrics-server -n kube-system --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-preferred-address-types=InternalIP"}]'

# Verifies installation
echo "Verifying installation:"
kubectl get nodes
kubectl get pods -n kube-system
echo "Waiting for Metrics Server to be ready..."
while [[ $(kubectl get pods -n kube-system | grep metrics-server | awk '{print $2}') != "1/1" ]]; do
    sleep 5
done
# sleep 30
kubectl top nodes

echo "k3s and Metrics Server successfully installed!"