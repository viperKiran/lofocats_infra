#!/usr/bin/env bash

kubectl exec "$(
  kubectl get pod -l app=lofocats,component=api \
          -o jsonpath='{.items[0].metadata.name}'
)" -c lofocats-api -- rake db:load_demo_data
