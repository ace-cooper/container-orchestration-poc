#!/bin/bash
# Blue-green deployment for non-database pods

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <app-name> <new-image> [<port>]"
    echo "Example: $0 node-api your-registry/node-api:v2 3000"
    exit 1
fi

APP_NAME=$1
NEW_IMAGE=$2
PORT=${3:-80}

echo "Starting blue-green deployment for $APP_NAME..."
echo "New image: $NEW_IMAGE"

# Create green deployment
kubectl get deployment ${APP_NAME} -o yaml | \
  sed "s/${APP_NAME}/${APP_NAME}-green/g" | \
  sed "s/image: .*/image: ${NEW_IMAGE}/g" | \
  kubectl apply -f -

echo "Waiting for green deployment to stabilize..."
kubectl rollout status deployment/${APP_NAME}-green --timeout=120s

# Switch service to green
kubectl patch service ${APP_NAME}-svc -p "{\"spec\":{\"selector\":{\"app\":\"${APP_NAME}-green\"}}}"

echo "Traffic switched to green deployment"

# Scale down blue
kubectl scale deployment ${APP_NAME} --replicas=0

# Cleanup (optional)
read -p "Delete old blue deployment? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete deployment ${APP_NAME}
    kubectl rename deployment ${APP_NAME}-green ${APP_NAME}
fi

echo "Deployment complete! New version is live."