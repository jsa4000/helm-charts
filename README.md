# ArgoCD

Install ArgoCD using Helm Charts

```bash
# Add Helm Repo
helm3 repo add argo https://argoproj.github.io/argo-helm

# Update repo
helm3 repo update

## Install ArgoCD Helm Chart
helm3 install argocd -n argocd --create-namespace argo/argo-cd --version 3.33.5

## Install ArgoCD with custom values equal to the application (argocd/argocd.yaml)
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

### Dashboard

ArgoCD provides a dashbosrd to visualize the deployments and applications.

```bash
# Get the ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Access ArgoCD as admin user
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Install ArgoCD Root Project

> Be sure to install additional secrets such as Git Credentials, Certificates, etc..

```bash
## Wait until argo-cd pods are running

## Apply root project
Kubectl apply -f project.yaml
```

### Example

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

## License

<!-- Keep full URL links to repo files because this README syncs from main to gh-pages.  -->
[Apache 2.0 License](https://github.com/jsa4000/helm-charts/blob/main/LICENSE).