#!/bin/bash

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm fetch jetstack/cert-manager --version v1.11.0
curl -L -o cert-manager-crd.yaml https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml
kubectl create namespace cert-manager
kubectl apply -f cert-manager-crd.yaml


helm install cert-manager ./cert-manager-v1.11.0.tgz \
    --namespace cert-manager \
    --set image.repository=<REGISTRY.YOURDOMAIN.COM:PORT>/quay.io/jetstack/cert-manager-controller \
    --set webhook.image.repository=<REGISTRY.YOURDOMAIN.COM:PORT>/quay.io/jetstack/cert-manager-webhook \
    --set cainjector.image.repository=<REGISTRY.YOURDOMAIN.COM:PORT>/quay.io/jetstack/cert-manager-cainjector \
    --set startupapicheck.image.repository=<REGISTRY.YOURDOMAIN.COM:PORT>/quay.io/jetstack/cert-manager-ctl