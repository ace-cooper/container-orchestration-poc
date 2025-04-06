#!/bin/bash
# Adds configurable health checks to existing deployments with customizable ports

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <pod-name> <probe-type> [<options>]"
    echo ""
    echo "Probe Types:"
    echo "  http <port> <path> (default: 8080 /health)"
    echo "  tcp <port>"
    echo "  cmd <command>"
    echo ""
    echo "Examples:"
    echo "  HTTP: $0 node-api http 3000 /health"
    echo "  TCP:  $0 redis tcp 6379"
    echo "  CMD:  $0 postgres cmd \"pg_isready -U postgres\""
    exit 1
fi

POD_NAME=$1
PROBE_TYPE=$2
PORT=${3:-8080}
PATH=${4:-"/health"}
COMMAND=${3:-""}

# Validate deployment exists
if ! kubectl get deployment "$POD_NAME" > /dev/null 2>&1; then
    echo "Error: Deployment $POD_NAME not found"
    exit 1
fi

echo "Adding $PROBE_TYPE health checks to $POD_NAME..."

case $PROBE_TYPE in
    http)
        echo "Configuring HTTP probe on port $PORT, path $PATH"
        patch=$(cat <<EOF
[{
    "op": "add",
    "path": "/spec/template/spec/containers/0/livenessProbe",
    "value": {
        "httpGet": {
            "path": "$PATH",
            "port": $PORT,
            "scheme": "HTTP"
        },
        "initialDelaySeconds": 30,
        "periodSeconds": 10,
        "timeoutSeconds": 5
    }
},
{
    "op": "add",
    "path": "/spec/template/spec/containers/0/readinessProbe",
    "value": {
        "httpGet": {
            "path": "$PATH",
            "port": $PORT,
            "scheme": "HTTP"
        },
        "initialDelaySeconds": 5,
        "periodSeconds": 5,
        "timeoutSeconds": 3
    }
}]
EOF
        )
        ;;
        
    tcp)
        echo "Configuring TCP probe on port $PORT"
        patch=$(cat <<EOF
[{
    "op": "add",
    "path": "/spec/template/spec/containers/0/livenessProbe",
    "value": {
        "tcpSocket": {
            "port": $PORT
        },
        "initialDelaySeconds": 30,
        "periodSeconds": 20
    }
},
{
    "op": "add",
    "path": "/spec/template/spec/containers/0/readinessProbe",
    "value": {
        "tcpSocket": {
            "port": $PORT
        },
        "initialDelaySeconds": 5,
        "periodSeconds": 10
    }
}]
EOF
        )
        ;;
        
    cmd)
        echo "Configuring Command probe: $COMMAND"
        patch=$(cat <<EOF
[{
    "op": "add",
    "path": "/spec/template/spec/containers/0/livenessProbe",
    "value": {
        "exec": {
            "command": ["sh", "-c", "$COMMAND"]
        },
        "initialDelaySeconds": 45,
        "periodSeconds": 30
    }
},
{
    "op": "add",
    "path": "/spec/template/spec/containers/0/readinessProbe",
    "value": {
        "exec": {
            "command": ["sh", "-c", "$COMMAND"]
        },
        "initialDelaySeconds": 5,
        "periodSeconds": 10
    }
}]
EOF
        )
        ;;
        
    *)
        echo "Error: Invalid probe type. Use http, tcp, or cmd"
        exit 1
        ;;
esac

# Apply the patch
kubectl patch deployment "$POD_NAME" --type=json -p="$patch"

echo "Health checks added successfully!"
echo "Verification:"
kubectl get deployment "$POD_NAME" -o json | jq '.spec.template.spec.containers[0].livenessProbe'
kubectl get deployment "$POD_NAME" -o json | jq '.spec.template.spec.containers[0].readinessProbe'