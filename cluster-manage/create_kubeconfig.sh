#!/bin/bash
set -e

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <NAMESPACE> <USER>"
  exit 1
fi

NAMESPACE="$1"
USERNAME="$2"

# clusterrole could be view or admin or custom role
CLUSTER_ROLE="view"
CLUSTER_NAME="pi-cluster"

CLUSTER_SERVER=$(hostname -I | awk '{print $1}')

echo "Create serviceaccount"
kubectl create serviceaccount $USERNAME -n $NAMESPACE

echo "Create rolebinding"
kubectl create rolebinding "$USERNAME-$CLUSTER_ROLE-binding" \
  --clusterrole=$CLUSTER_ROLE \
  --serviceaccount=$NAMESPACE:$USERNAME \
  --namespace=$NAMESPACE

echo "Create secret for $USERNAME"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $USERNAME-token
  annotations:
    kubernetes.io/service-account.name: $USERNAME
type: kubernetes.io/service-account-token
EOF

SECRET_NAME="$USERNAME-token"
SA_TOKEN=$(kubectl get secret $SECRET_NAME -n default -o jsonpath='{.data.token}' | base64 -d)
CA_CRT=$(kubectl get secret $SECRET_NAME -n default -o jsonpath='{.data.ca\.crt}')

echo "Generating kubeconfig"
cat <<EOF > kubeconfig-$USERNAME.yaml
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    server: ${CLUSTER_SERVER}
    certificate-authority-data: ${CA_CRT}
contexts:
- name: khiemle-context
  context:
    cluster: ${CLUSTER_NAME}
    namespace: default
    user: khiemle
current-context: khiemle-context
users:
- name: khiemle
  user:
    token: ${SA_TOKEN}
EOF
