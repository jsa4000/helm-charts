# Examples

## Add Helm Repositories

```bash
## Install repository
helm3 repo add jsa4000 https://jsa4000.github.io/helm-charts
helm3 repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm3 repo add traefik https://helm.traefik.io/traefik
helm3 repo add bitnami https://charts.bitnami.com/bitnami

# List all chart and current version
helm3 repo update

# Get all charts from a repo
helm3 search repo jsa4000
```

## Install Pre-requisites

```bash
## Install `traefik` Chart into `tools` namespace
helm3 install -n tools --create-namespace traefik traefik/traefik --version 10.3.2

## Install `kube-prometheus-stack` Chart into `monitoring` namespace
helm3 install -n monitoring --create-namespace prometheus prometheus-community/kube-prometheus-stack --version 18.0.6 \
--set 'prometheus-node-exporter.hostRootFsMount=false'

# Install the chart with the custom values and specific version (argocd/sealed-secrets.yaml)
helm3 install sealed-secrets -n sealed-secrets --create-namespace sealed-secrets/sealed-secrets --version 2.1.2
```

Uninstall helm charts

```bash
## Delete `traefik` Chart
helm3 delete traefik -n tools

## Delete `kube-prometheus-stack` Chart 
helm3 delete prometheus -n monitoring 

# Delete MongoDB chart
helm3 delete mongo -n datastore
```

Uninstall traefik from K3s

```bash
# Uninstall traefik from K3s
kubectl -n kube-system delete helmcharts.helm.cattle.io traefik
```

## Install Charts

```bash
# Install microservice chart (default values.yaml file)
helm3 install microservice -n micro --create-namespace --dependency-update microservice 

# Install microservice chart using specific value file (microservice/values-placement.yaml )
helm3 install microservice -n micro --create-namespace --dependency-update microservice -f microservice/values-placement.yaml 

# Install spa chart
helm3 install spa -n spa --create-namespace --dependency-update spa
```

## Debug Charts

```bash
# Get microservice chart Manifest generated
helm3 template microservice -n micro --create-namespace --dependency-update microservice > microservice-template.yaml

# Get spa chart Manifest generated
helm3 template spa -n spa --create-namespace --dependency-update spa  > spa-template.yaml
```

## Verify installation

Verify if microservices are currently running (status)

### Microservice

```bash
# Get all the common resources created from previous chart
kubectl get -n micro pods -w

# Get the logs from the pod u
kubectl logs -n micro microservice-notifications-6c9c8d54f9-cflzg -f

# Test microservice by using Port-forward(http://localhost:8080/swagger-ui.html)
kubectl port-forward --namespace micro svc/microservice-notifications 8080:80

# Test microservice by using Traefik Controller / Ingress (http://localhost/notifications/swagger-ui.html)
```

### SPA

```bash
# Get all the common resources created from previous chart
kubectl get -n spa pods -w

# Get the logs from the pod u
kubectl logs -n spa spa-angular-7b8c86ddb9-c94vv -f

# Test microservice by using Port-forward(http://localhost:8080)
kubectl port-forward --namespace spa svc/spa-angular 8080:80

# Test microservice by using Traefik Controller / Ingress (http://localhost)
```
