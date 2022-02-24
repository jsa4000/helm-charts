# ArgoCD

Install ArgoCD using Helm Charts. This is needed to deploy ArgoCD CRDs.
After the installation ArgoCD will be managed by itself (lifecycle) since it is configured as custom Application in `argocd/argocd.yaml`

```bash
# Add Helm Repo
helm3 repo add argo https://argoproj.github.io/argo-helm

# Update repo
helm3 repo update

## Install ArgoCD Helm Chart
helm3 install argocd -n argocd --create-namespace argo/argo-cd --version 3.33.5

## [RECOMMENDED] Install ArgoCD with custom values equal to the application (argocd/argocd.yaml)
helm3 install argocd -n argocd --create-namespace argo/argo-cd --version 3.33.5 \
  --set redis-ha.enabled=false \
  --set controller.enableStatefulSet=false \
  --set server.autoscaling.enabled=false \
  --set repoServer.autoscaling.enabled=false

# Take a look different ways to deploy ArgoCD: 
#  - Non HA-Mode
#  - HA-Mode With Autoscaling
#  - HA-Mode Without autoscaling
#  - etc...
```

## Istio in Rancher K3s

Uninstall default `traefik` from K3s

```bash
# Uninstall traefik from K3s
kubectl -n kube-system delete helmcharts.helm.cattle.io traefik
```

## Secrets

### Gitlab

```bash
## Export Gitlab variables
export NAMESPACE="argocd"
export SECRETNAME="gitlab-argocd-secret"
export GITLAB_URL=https://gitlab.com/jsa4000/gitops-argocd.git
export GITLAB_TOKEN_NAME=gitops-argocd
export GITLAB_TOKEN=******

# Create argocd namespace if not installed previously
kubectl create namespace argocd

# Create a secret with the public and private keys
kubectl -n "$NAMESPACE" create secret generic "$SECRETNAME" \
  --from-literal=url="${GITLAB_URL}" \
  --from-literal=username="${GITLAB_TOKEN_NAME}" \
  --from-literal=password="${GITLAB_TOKEN}"

# Add a custom label to notificy the controller the current active secret to use
kubectl -n "$NAMESPACE" label secret "$SECRETNAME" argocd.argoproj.io/secret-type=repository
```

## Sealed Secret Certificates

```bash
##Set your vars
export NAMESPACE="sealed-secrets"
export SECRETNAME="sealed-secrets-keys"
export PRIVATEKEY="sealed-secrets.key"
export PUBLICKEY="sealed-secrets.crt"

# Create namespace if not exists
kubectl create namespace "$NAMESPACE"

# Create a secret with the public and private keys
kubectl -n "$NAMESPACE" create secret tls "$SECRETNAME" --cert="$PUBLICKEY" --key="$PRIVATEKEY"

# Add a custom label to notificy the controller the current active secret to use
kubectl -n "$NAMESPACE" label secret "$SECRETNAME" sealedsecrets.bitnami.com/sealed-secrets-key=active
```

## Dashboard

ArgoCD provides a dashbosrd to visualize the deployments and applications.

```bash
# Get the ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Access ArgoCD as admin user
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Install ArgoCD Root Project

> Be sure to install additional secrets such as Git Credentials, SSH keys, Sealed Secrets Certificates, etc..

```bash
## Wait until argo-cd pods are running

## Apply root project
Kubectl apply -f project.yaml
```

### Apps of Apps

With Argo CD there is a way to automate this by creating an application that implements the app of apps pattern. We can call this the “root” application.

```console
├── argocd
│   ├── booking-microservice.yaml
│   ├── car-microservice.yaml
│   ├── flight-microservice\ copy.yaml
│   ├── hotel-microservice.yaml
│   ├── mongodb.yaml
│   └── prometheus-stack.yaml
└── project.yaml
```

project.yaml

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: booking-project
  namespace: argocd
  # Finalizer that ensures that project is not deleted until it is not referenced by any application
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  # Project description
  description: The app bundle POC project
  # Allow manifests to deploy from any Git repos
  sourceRepos:
  - '*'
  # Only permit applications to deploy to the guestbook namespace in the same cluster
  destinations:
  - namespace: '*'
    server: '*'
  # Deny all cluster-scoped resources from being created, except for Namespace
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: booking
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: booking-project
  destination:
    server: https://kubernetes.default.svc
    namespace: micro
  source:
    path: argocd
    repoURL: https://github.com/jsa4000/helm-charts.git
    targetRevision: deploy
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Deploy the first application to point to the others apps.

```bash
# Apply AppProject and Root Application
kubectl apply -f project.yaml   
```

### Applications

car-microservice.yaml

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: car-microservice
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "10"
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: micro
  project: booking-project
  source:
    path: helm/microservices/car
    repoURL: https://github.com/jsa4000/helm-charts.git
    targetRevision: deploy
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

prometheus-stack.yaml

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  project: booking-project
  source:
    chart: kube-prometheus-stack
    helm:
      values: |
        prometheus-node-exporter:
          hostRootFsMount: false
    repoURL: https://prometheus-community.github.io/helm-charts
    targetRevision: 18.0.6
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

Apply application files to kubernetes cluster (the namespace is not need since it is the manifest)

```bash
# Apply both argocd applicaation files
kubectl apply -n argocd -f car-microservice.yaml
kubectl apply -n argocd -f prometheus-stack.yaml
```

### ApplicationSets

Application set allow to define some rules to the deployments.
There are some generators to use with Application Set

**list**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: booking
spec:
  generators:
  - list:
      elements:
      - cluster: engineering-dev
        url: https://1.2.3.4
      - cluster: engineering-prod
        url: https://2.4.6.8
      - cluster: finance-preprod
        url: https://9.8.7.6
  template:
    metadata:
      name: 'booking-{{cluster}}'
    spec:
      project: booking-project
      source:
        path: argocd
        repoURL: https://github.com/jsa4000/helm-charts.git
        targetRevision: {{cluster}}
      destination:
        server: '{{url}}'
        namespace: micro
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

## Observability

### Metrics

Serve prometheus and Grafana dashboards using port-forward

```bash
## Prometheus dashboard (http://localhost:9090)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090

## Grafana dashboard (http://localhost:3000) (`admin/prom-operator`)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Install following dashboards into Grafana.

> Select the same `Prometheus` source for all of them

- Node Exporter Full: 1860
- Traefik: 4475
- Spring Boot Statistics: 6756
- MongoDB Exporter: 2583

In order to use Spring Boot Statistics, use the following data to show app information:

- **Instance**. the `IP:Port` value from `targets` in Prometheus. i.e. `10.1.0.17:8080`
- **Application**. the name of the application (`spring.application.name`) or pod-name in most cases (without the hash). i.e. `car-microservice`.

Instance and Application can be gathered from the tags also:

```bash
com_example_booking_controller_seconds_max{application="booking-microservice", class="com.example.booking.controller.BookingController", container="booking", endpoint="http", exception="none", instance="10.1.0.17:8080", job="booking-microservice-srv", method="findAllBookings", namespace="micro", pod="booking-microservice-65bc7b4694-fdvhl", service="booking-microservice-srv"}
```

### Logs

There are a lot ways to register logs within kubernetes by using kubernetes native tools like loki, fluentd, etc. or using agents for SaaS providers such as DataDog, Splunk, AWS CloudWatch, etc..

#### Loki

Access Grafana deployed by Prometheus and select Loki source.

Get Logs from microservices:

- Open Grafana-Loki at http://localhost:3000
- Select left Menu Item `Explore` -> `Loki` (ComboBox)
- Click into `Log browser` and select `namespace` -> `micro` -> `Show Logs` button, or using `{namespace="micro"}` directly in the search text.
- Select the time range to search for the logs on the top.
- Press `Run Query` to search all results
- Similar to Kibana with the results filters can be added using + or -, column to view (single), etc... i.e. `{app="hotel",namespace="micro"}`

## License

<!-- Keep full URL links to repo files because this README syncs from main to gh-pages.  -->
[Apache 2.0 License](https://github.com/jsa4000/helm-charts/blob/main/LICENSE).