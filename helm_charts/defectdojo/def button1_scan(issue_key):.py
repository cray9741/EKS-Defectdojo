def button1_scan(issue_key):
    dread_job = f"""
            apiVersion: batch/v1
            kind: Job
            metadata:
            name: dread-job
            spec:
            ttlSecondsAfterFinished: 30
            template:
                spec:
                containers:
                - name: dread
                    image: tray3rd/dread:latest
                    env:
                    - name: ISSUE_KEY
                    value: {issue_key}  # This will be populated by the Django application when the job is created.
                    - name: S3_BUCKET
                    value: "tools-bucket-cloudranger-30293812"
                    - name: AWS_DEFAULT_REGION
                    value: "us-east-1"
                    - name: AWS_ACCESS_KEY_ID
                    valueFrom:
                        secretKeyRef:
                        name: aws-credentials
                        key: AWS_ACCESS_KEY_ID
                    - name: AWS_SECRET_ACCESS_KEY
                    valueFrom:
                        secretKeyRef:
                        name: aws-credentials
                        key: AWS_SECRET_ACCESS_KEY
                    resources:
                    requests:
                        memory: "2Gi"
                        cpu: "1"
                    limits:
                        memory: "4Gi"
                        cpu: "2"
                restartPolicy: Never
            backoffLimit: 4
        """
    return create_job_from_yaml(dread_job)