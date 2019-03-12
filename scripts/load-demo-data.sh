#!/usr/bin/env bash

kubectl apply -f - <<EOF
---
apiVersion: batch/v1
kind: Job
metadata:
  labels:
    app: lofocats
    component: load-demo-data
  name: lofocats-load-demo-data
spec:
  template:
    metadata:
      labels:
        app: lofocats
        component: load-demo-data
    spec:
      containers:
      - image: maxbrunet/lofocats_api:latest
        name: lofocats-load-demo-data
        command: ["rake", "db:load_demo_data"]
        env:
        - name: RAILS_ENV
          value: production
        envFrom:
        - secretRef:
            name: lofocats-api-database-url
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 2  # non-root user
      restartPolicy: OnFailure
EOF
