#!/bin/bash
# Updates NetworkPolicy to allow new API proxies access to databases

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <database-pod-name> <api-proxy-name>"
    echo "Example: $0 postgres-db api-gateway"
    exit 1
fi

DB_POD=$1
API_PROXY=$2

echo "Adding $API_PROXY to allowed connections for $DB_POD..."

kubectl patch NetworkPolicy ${DB_POD}-netpol --type=json -p="[{'op': 'add', 'path': '/spec/ingress/0/from/-', 'value': {'podSelector': {'matchLabels': {'app': '${API_PROXY}'}}}}]"

echo "Updated NetworkPolicy:"
kubectl get NetworkPolicy ${DB_POD}-netpol -o yaml