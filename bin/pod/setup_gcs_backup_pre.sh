#!/bin/bash
# Sets up GCP credentials for backup jobs

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <gcp-service-account-json-file>"
  echo "Example: $0 ~/service-account.json"
  exit 1
fi

SA_FILE=$1

echo "Setting up GCP backup infrastructure..."

# 1. Create Kubernetes secret with GCP credentials
kubectl create secret generic gcloud-config \
  --from-file=gcp-credentials.json=${SA_FILE}

# 2. Create GCS bucket lifecycle policy (example)
echo "Creating lifecycle policy template (save as lifecycle.json and apply manually):"
cat <<EOF
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {
        "age": $RETENTION_DAYS,
        "matchesStorageClass": ["STANDARD"]
      }
    }
  ]
}
EOF

echo "Apply lifecycle policy using:"
echo "gsutil lifecycle set lifecycle.json gs://${GCS_BUCKET}"

# 3. Create IAM binding (example)
echo "Granting permissions to service account:"
SA_EMAIL=$(jq -r '.client_email' ${SA_FILE})
echo "Run these commands in GCP Console:"
echo "1. gsutil iam ch serviceAccount:${SA_EMAIL}:objectAdmin gs://${GCS_BUCKET}"
echo "2. gcloud projects add-iam-policy-binding ${GCP_PROJECT} \\
      --member serviceAccount:${SA_EMAIL} \\
      --role roles/storage.objectAdmin"