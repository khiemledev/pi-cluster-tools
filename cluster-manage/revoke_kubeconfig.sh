#!/bin/bash

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <NAMESPACE> <USER>"
  exit 1
fi

NAMESPACE="$1"
USERNAME="$2"

CLUSTER_ROLE="view"

kubectl delete rolebinding $USERNAME-$CLUSTER_ROLE-binding
kubectl delete secret $USERNAME-token
kubectl delete sa $USERNAME