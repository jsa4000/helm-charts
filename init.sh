#!/bin/bash

# Remove traefik from cluster (Rancher Desktop)
kubectl -n kube-system delete helmcharts.helm.cattle.io traefik

# Install certificates for sealed-secrets
cd certs;./create_secrets.sh;cd ..

# Install ArgoCD using helm chart
echo Installing ArgoCD from Helm Chart using 'argocd-values.yaml'
helm install argocd -n argocd --create-namespace argo/argo-cd --version 3.33.5 -f argocd-values.yaml --wait

# Create ArgoCD project and Root App (App of Apps)
kubectl apply -f project.yaml 
