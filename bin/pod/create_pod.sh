#!/bin/bash

# Check if all required arguments were provided
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <pod-name> <cpu-request> <ram-request> <cpu-limit> <ram-limit> <storage-size> [<image>] [<ports>]"
    echo "Example: $0 my-postgres 500m 2Gi 1 4Gi 10Gi postgres:15 '5432:5432'"
    exit 1
fi

# Parameters
POD_NAME=$1
CPU_REQUEST=$2
RAM_REQUEST=$3
CPU_LIMIT=$4
RAM_LIMIT=$5
STORAGE_SIZE=$6
IMAGE=${7:-"busybox"}  # Default to busybox if not specified
PORTS=${8:-""}

# Create Persistent Volume (if necessary)
PV_NAME="${POD_NAME}-pv"
PVC_NAME="${POD_NAME}-pvc"

# Create data directory if it doesn't exist
sudo mkdir -p "/mnt/data/${POD_NAME}"
sudo chmod -R 777 "/mnt/data/${POD_NAME}"

# Create PersistentVolume
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV_NAME}
spec:
  storageClassName: manual
  capacity:
    storage: ${STORAGE_SIZE}
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data/${POD_NAME}"
EOF

# Create PersistentVolumeClaim
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC_NAME}
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${STORAGE_SIZE}
EOF

# Prepare port mapping
PORT_MAPPING=""
if [ ! -z "$PORTS" ]; then
    IFS=':' read -ra PORTS <<< "$PORTS"
    PORT_MAPPING=$(cat <<EOF
        ports:
        - containerPort: ${PORTS[1]}
          hostPort: ${PORTS[0]}
EOF
    )
fi

# Create Deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${POD_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${POD_NAME}
  template:
    metadata:
      labels:
        app: ${POD_NAME}
    spec:
      containers:
      - name: ${POD_NAME}
        image: ${IMAGE}
        resources:
          requests:
            cpu: "${CPU_REQUEST}"
            memory: "${RAM_REQUEST}"
          limits:
            cpu: "${CPU_LIMIT}"
            memory: "${RAM_LIMIT}"
        volumeMounts:
        - name: ${POD_NAME}-storage
          mountPath: /data
${PORT_MAPPING}
      volumes:
      - name: ${POD_NAME}-storage
        persistentVolumeClaim:
          claimName: ${PVC_NAME}
EOF

# Create Service (if ports were specified)
if [ ! -z "$PORTS" ]; then
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ${POD_NAME}-svc
spec:
  selector:
    app: ${POD_NAME}
  ports:
  - protocol: TCP
    port: ${PORTS[1]}
    targetPort: ${PORTS[1]}
  type: NodePort
EOF
fi

echo "Pod ${POD_NAME} successfully created!"
echo "Resources: CPU ${CPU_REQUEST}/${CPU_LIMIT}, RAM ${RAM_REQUEST}/${RAM_LIMIT}"
echo "Storage: ${STORAGE_SIZE} in /mnt/data/${POD_NAME}"
if [ ! -z "$PORTS" ]; then
    NODE_PORT=$(kubectl get svc ${POD_NAME}-svc -o jsonpath='{.spec.ports[0].nodePort}')
    echo "Accessible on port: ${NODE_PORT}"
fi