#!/bin/bash
# Sets up automatic backups for database pods

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <pod-name> <backup-schedule> <retention-days> [<s3-bucket>]"
    echo "Example: $0 postgres-db \"0 2 * * *\" 14 my-backup-bucket"
    exit 1
fi

POD_NAME=$1
SCHEDULE=$2
RETENTION=$3
S3_BUCKET=${4:-"your-s3-bucket"}

echo "Configuring backups for $POD_NAME..."
echo "Schedule: $SCHEDULE | Retention: $RETENTION days | S3 Bucket: $S3_BUCKET"

# Create backup CronJob
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ${POD_NAME}-backup
spec:
  schedule: "$SCHEDULE"
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: amazon/aws-cli
            env:
            - name: BACKUP_FILE
              value: "${POD_NAME}-\$(date +\%Y\%m\%d-\%H\%M\%S).sql"
            command:
              - "/bin/sh"
              - "-c"
              - |
                kubectl exec ${POD_NAME} -- pg_dumpall -U postgres > /tmp/\${BACKUP_FILE} && \
                aws s3 cp /tmp/\${BACKUP_FILE} s3://${S3_BUCKET}/backups/ && \
                echo "Backup \${BACKUP_FILE} completed"
            volumeMounts:
            - name: kubectl
              mountPath: /usr/local/bin/kubectl
          volumes:
          - name: kubectl
            hostPath:
              path: /usr/local/bin/kubectl
          restartPolicy: OnFailure
EOF

echo "Backup configuration complete!"
echo "Manual test: kubectl create job --from=cronjob/${POD_NAME}-backup manual-test"