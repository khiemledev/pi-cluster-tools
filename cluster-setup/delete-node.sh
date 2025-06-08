#!/bin/bash

set -e

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <NODE_NAME_TO_DELETE>"
  exit 1
fi

NODE_NAME = $1

kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data

kubectl delete node $NODE_NAME

echo "Run this command on your worker node to reset it:"
echo "sudo kudeadm reset"