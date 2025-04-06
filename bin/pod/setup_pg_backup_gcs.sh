#!/bin/bash
# Automated backups to GCP Cloud Storage for Kubernetes pods

# Validate parameters
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <pod-name> <backup-schedule> <retention-days> <gcs-bucket> [<gcp-project>] [<service-account>]"
  echo "Example: $0 postgres-db \"0 2 * * *\" 14 my-backups gcp-project-123 service-account@project.iam.gserviceaccount.com"
  exit 1
fi

POD_NAME=$1
SCHEDULE=$2
RETENTION=$3
GCS_BUCKET=$4
GCP_PROJECT=${5:-$(gcloud config get-value project)}
SERVICE_ACCOUNT=${6:-"default"}

echo "Configuring GCP backups for $POD_NAME..."
echo "Schedule: $SCHEDULE | Retention: $RETENTION days | GCS Bucket: gs://$GCS_BUCKET"

# Create backup CronJob
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ${POD_NAME}-gcp-backup
  labels:
    app: ${POD_NAME}
    backup-type: gcs
spec:
  schedule: "$SCHEDULE"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: ${SERVICE_ACCOUNT}
          containers:
          - name: backup
            image: google/cloud-sdk:slim
            env:
            - name: BACKUP_FILE
              value: "${POD_NAME}-\$(date +\%Y\%m\%d-\%H\%M\%S).sql"
            - name: GCS_BUCKET
              value: "${GCS_BUCKET}"
            - name: RETENTION_DAYS
              value: "${RETENTION}"
            command:
              - "/bin/bash"
              - "-c"
              - |
                # Create backup
                kubectl exec ${POD_NAME} -- pg_dumpall -U postgres > /tmp/\${BACKUP_FILE}
                
                # Upload to GCS
                gsutil cp /tmp/\${BACKUP_FILE} gs://\${GCS_BUCKET}/backups/
                
                # Apply retention policy
                gsutil ls -l gs://\${GCS_BUCKET}/backups/${POD_NAME}* | \\
                  awk '\$1 < "'\$(date -d "-\${RETENTION_DAYS} days" +%Y-%m-%d)'" {print \$2}' | \\
                  xargs -r gsutil rm
                
                echo "Backup \${BACKUP_FILE} completed and old backups pruned"
            volumeMounts:
            - name: gcloud-config
              mountPath: /root/.config/gcloud
            - name: kubectl
              mountPath: /usr/local/bin/kubectl
          volumes:
          - name: gcloud-config
            secret:
              secretName: gcloud-config
          - name: kubectl
            hostPath:
              path: /usr/local/bin/kubectl
          restartPolicy: OnFailure
EOF

echo "GCP backup configuration complete!"
echo "Manual test: kubectl create job --from=cronjob/${POD_NAME}-gcp-backup manual-test"
echo "Backups will be stored in: gs://$GCS_BUCKET/backups/"