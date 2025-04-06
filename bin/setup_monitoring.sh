#!/bin/bash

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace for monitoring
kubectl create namespace monitoring

# Install Prometheus Stack (includes Grafana)
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false

# Configure port-forward for Grafana access
echo "To access Grafana, run in another terminal:"
echo "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "Access http://localhost:3000 with user 'admin' and password:"
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Additional configuration to monitor host resources
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: node-exporter
  endpoints:
  - port: http
EOF

# Persistent Volume for Prometheus and Grafana
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: monitoring-pv
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data/monitoring"
EOF

# Updateing prometheus and grafana to use persistent volumes
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName="manual" \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]="ReadWriteOnce" \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage="5Gi" \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName="manual" \
  --set grafana.persistence.accessModes[0]="ReadWriteOnce" \
  --set grafana.persistence.size="2Gi"

echo "Monitoring installed successfully!"