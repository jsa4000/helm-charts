#!/bin/bash

# Remove traefik from cluster (Rancher Desktop)
kubectl -n kube-system delete helmcharts.helm.cattle.io traefik

# Install certificates for sealed-secrets
cd certs;./create_secrets.sh;cd ..

# Install ArgoCD using helm chart
echo Installing ArgoCD from chart
helm install argocd -n argocd --create-namespace argo/argo-cd --version 3.33.5 \
  --set redis-ha.enabled=false \
  --set controller.enableStatefulSet=false \
  --set server.autoscaling.enabled=false \
  --set repoServer.autoscaling.enabled=false \
  --wait

# Create ArgoCD project and Root App (App of Apps)
kubectl apply -f project.yaml 