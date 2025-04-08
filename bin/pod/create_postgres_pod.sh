#!/bin/bash
# Creates PostgreSQL pod with self-signed SSL

# Check if certificates exist
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CERT_DIR="$SCRIPT_DIR/postgres_ssl"
if [ ! -f "$CERT_DIR/server.crt" ] || [ ! -f "$CERT_DIR/server.key" ]; then
    echo "ERROR: SSL certificates not found in $CERT_DIR/"
    echo "First run ./generate_ssl_certs.sh"
    exit 1
fi

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

# Create secret with certificates
kubectl create secret generic ${POD_NAME}-ssl-certs \
  --from-file="$CERT_DIR/server.crt" \
  --from-file="$CERT_DIR/server.key" \
  --dry-run=client -o yaml | kubectl apply -f -

# Persistent Volume configuration (external)
VOLUME_PATH="/mnt/data/${POD_NAME}"
sudo mkdir -p "$VOLUME_PATH"
sudo chown -R 999:999 "$VOLUME_PATH"  # 999 = postgres user UID

# Check if PV already exists and delete it if it does
if kubectl get pv ${PV_NAME} &>/dev/null; then
  echo "PV ${PV_NAME} already exists. Deleting it to recreate..."
  kubectl delete pvc ${PVC_NAME} --ignore-not-found=true
  kubectl delete pv ${PV_NAME} --ignore-not-found=true
fi

# Create PV
cat <<EOF | kubectl apply -f -
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
    path: "$VOLUME_PATH"
    type: DirectoryOrCreate
EOF

# Create PVC
cat <<EOF | kubectl apply -f -
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

# PostgreSQL Deployment with SSL
cat <<EOF | kubectl apply -f -
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
        image: postgres:15-alpine
        resources:
          requests:
            memory: ${RAM_REQUEST:-2Gi}
            cpu: ${CPU_REQUEST:-500m}
          limits:
            memory: ${RAM_LIMIT:-4Gi}
            cpu: ${CPU_LIMIT:-1}
        env:
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          value: "$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9')"
        - name: PGDATA
          value: "/var/lib/postgresql/data/pgdata"
        - name: PGSSLMODE
          value: "verify-full"
        - name: PGSSLKEY
          value: "/etc/postgresql/ssl/server.key"
        - name: PGSSLCERT
          value: "/etc/postgresql/ssl/server.crt"
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: ssl-certs
          mountPath: /etc/postgresql/ssl
          readOnly: true
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: ${POD_NAME}-pvc
      - name: ssl-certs
        secret:
          secretName: ${POD_NAME}-ssl-certs
EOF

# Service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${POD_NAME}-svc
spec:
  selector:
    app: ${POD_NAME}
  ports:
  - port: 5432
    targetPort: 5432
EOF

echo "PostgreSQL with SSL configured!"
echo "Certificates in: $CERT_DIR/"
echo "Connect via:"
echo "  kubectl port-forward svc/${POD_NAME}-svc 5432:5432"
echo "  psql 'host=localhost port=5432 user=postgres sslmode=verify-full sslrootcert=$CERT_DIR/server.crt'"