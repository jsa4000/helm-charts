# ArgoCD

Project to create ArgoCD project for GitOps

## Connect to the kubernetes cluster

```bash
## Set the kubernetes config file for the context to use
export KUBECONFIG=$KUBECONFIG:~/.kube/myconfig
```

## Install Argocd

```bash
### Create devops namespaace
kubectl create namespace argocd

### Install argocd 
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for the installation to complete

```bash
# Wait until argccd finish to install and all pods are runnning
kubectl get pods -n argocd -w
```

```console
NAMESPACE NAME                                 READY STATUS  RESTARTS  AGE
argocd    argocd-redis-5b6967fdfc-9bjzm        1/1   Running     0     7m3s
argocd    argocd-dex-server-66f865ffb4-mq7f2   1/1   Running     0     7m3s
argocd    argocd-repo-server-656c76778f-mzwpg  1/1   Running     0     7m3s
argocd    argocd-application-controller-0      1/1   Running     0     7m3s
argocd    argocd-server-cd68f46f8-7vpsv        1/1   Running     0     7m3s
```

## Create Gitlab Credentials

```bash
## Export Gitlab variables
export GITLAB_TOKEN_NAME=gitops-argocd
export GITLAB_TOKEN=******

## Apply secret with previous information (brew install gettext)
envsubst < gitlab-argocd-secret.yaml | kubectl apply -f -
```

```bash
## Check secret is correctly configured with local environment variables
kubectl -n argocd get secret gitlab-argocd-secret -o jsonpath="{.data.password}" | base64 -d; echo 
kubectl -n argocd get secret gitlab-argocd-secret -o jsonpath="{.data.username}" | base64 -d; echo 
```

## Install ArgoCD Root Project

```bash
## Apply root project
Kubectl apply -f project.yaml
```

## Verify the installation

Check the sync status for the deployment using ArgoCD dashboard

```bash
## Get the ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

## Access ArgoCD as admin user
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
