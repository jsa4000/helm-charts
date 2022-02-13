# RBAC

## Introduction

Role-based access control (RBAC) is a method of regulating access to computer or network resources based on the roles of individual users within your organization.

RBAC authorization uses the rbac.authorization.k8s.io API group to drive authorization decisions, allowing you to dynamically configure policies through the Kubernetes API.

To enable RBAC, start the API server with the --authorization-mode flag set to a comma-separated list that includes RBAC; for example:

### Role and ClusterRole

An RBAC Role or ClusterRole contains rules that represent a set of permissions. Permissions are purely additive (there are no "deny" rules).

A Role always sets permissions within a particular namespace; when you create a Role, you have to specify the namespace it belongs in.

ClusterRole, by contrast, is a non-namespaced resource. The resources have different names (Role and ClusterRole) because a Kubernetes object always has to be either namespaced or not namespaced; it can't be both.

ClusterRoles have several uses. You can use a ClusterRole to:

* define permissions on namespaced resources and be granted within individual namespace(s)
* define permissions on namespaced resources and be granted across all namespaces
* define permissions on cluster-scoped resources

If you want to define a role within a namespace, use a Role; if you want to define a role cluster-wide, use a ClusterRole.
Role example

## Example

### Default `ServiceAccount`

By default kubernetes creates a default `ServiceAccount` that it is mounted **automatically** if other is not specified

```bash
# Get all ServiceAccounts in default namespace (created initially)
kubectl get ServiceAccount

# NAME      SECRETS   AGE
# default   1         44h

# Describe the ServiceAccount to get its content
kubectl describe ServiceAccount default    

# Name:                default
# Namespace:           default
# Labels:              <none>
# Annotations:         <none>
# Image pull secrets:  <none>
# Mountable secrets:   default-token-d5pjk
# Tokens:              default-token-d5pjk
# Events:              <none> 

# For each ServiceAccount Kubernetes creates a secrets with the token, ca.crt and namepace.
# This information will be used by the container to interact with the Kubernetes API
kubectl describe secrets default-token-d5pjk

# Name:         default-token-d5pjk
# Namespace:    default
# Labels:       <none>
# Annotations:  kubernetes.io/service-account.name: default
#               kubernetes.io/service-account.uid: a6cc16a0-5a58-4ad6-8d0e-21ba957001de
# 
# Type:  kubernetes.io/service-account-token
# 
# Data
# ====
# token:      XXX bytes
# ca.crt:     570 bytes
# namespace:  7 bytes
```

Kubernetes also creates a default `service` to be used internally (i.e. `containers`) to interact with **Kubernetes API**

```bash
# Get all Services created initially
kubectl get svc

# NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP   45h
```

A `Secret` manifest is created by each `ServiceAccount`. This is automatically mounted to the container that use it.

> Depending the `ServiceAccountName` is specified, a default one is automatically injected with the default.

```bash
# Run container from a terminal using run or create a deployment
kubectl run -it --rm nginx --image=nginx:latest -- sh

# In other terminal describe the pod to get the secret and the MountPath used
kubectl describe pod nginx
```

```console
Name:         nginx
Namespace:    default
Priority:     0
Node:         lima-rancher-desktop/192.168.1.150
Start Time:   Sun, 13 Feb 2022 19:46:33 +0100
Labels:       run=nginx
Annotations:  <none>
Status:       Running
...
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-v5shl (ro)
...
Volumes:
  kube-api-access-v5shl:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
```

Secrets from ServiceAccounts are mounted in the following folder within each container.

`/var/run/secrets/kubernetes.io/serviceaccount`

```bash
# Run following commands within the container
cd /var/run/secrets/kubernetes.io/serviceaccount
ls

# ca.crt    namespace    token
```

Decoding the `JWT token` following information can be extracted with the credentials.

```json
{
  "iss": "kubernetes/serviceaccount",
  "kubernetes.io/serviceaccount/namespace": "default",
  "kubernetes.io/serviceaccount/secret.name": "default-token-d5pjk",
  "kubernetes.io/serviceaccount/service-account.name": "default",
  "kubernetes.io/serviceaccount/service-account.uid": "a6cc16a0-5a58-4ad6-8d0e-21ba957001de",
  "sub": "system:serviceaccount:default:default"
}
```

Invoke `Kubernetes API` from a Container

```bash
# Point to the internal API server hostname
APISERVER=https://kubernetes.default.svc

# Path to ServiceAccount token
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# Read this Pod's namespace
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

# Read the ServiceAccount bearer token
TOKEN=$(cat ${SERVICEACCOUNT}/token)

# Reference the internal certificate authority (CA)
CACERT=${SERVICEACCOUNT}/ca.crt

# Explore the API with TOKEN
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api
```

The output will be similar to this one.

```json
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "192.168.1.150:6443"
    }
  ]
}
```

However, since it is the `default` ServiceAccount there is no permissions created by default.

```bash
# Install pre-requisites
apt update
apt install jq

# Get all the pods in the default namespace
curl -X GET $APISERVER/api/v1/namespaces/default/pods/ \
--cacert ${CACERT} \
--header "Authorization: Bearer ${TOKEN}" \
| jq -rM '.items[].metadata.name'

# To get the logs of a pod, insert the desired pod name into the request path.
curl -X GET $APISERVER/api/v1/namespaces/default/pods/nginx/log \
--cacert ${CACERT} \
--header "Authorization: Bearer ${TOKEN}" \
| tail -n 10
```

Default ServiceAccount cannot perform almost any operation over the Kubernetes API.

```json
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "pods is forbidden: User \"system:serviceaccount:default:default\" cannot list resource \"pods\" in API group \"\" in the namespace \"default\"",
  "reason": "Forbidden",
  "details": {
    "kind": "pods"
  },
  "code": 403
}
```

### Create `ServiceAccount`

Create a `ServiceAccount`

```bash
# Create a Service Account to fetch pods and logs
kubectl create serviceaccount api-explorer

# Get the manifest used (dry run)
kubectl create serviceaccount api-explorer --dry-run=client -o yaml
```

`api-explorer-sa.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-explorer
```

With the `ServiceAccount` is not enough to define permissionsl so it is needed `Role` and `RoleBinding` to complete it.

> There are `cluster-wide` roles that can be used if the pod need to use resources from other namespaces such as `ClusterRole` and `ClusterRoleBinding`.

Create the `Role` to define the **actions** and **resources** allowed.

```bash
# Create the role
kubectl create role log-reader --verb=get,watch,list --resource=pods,pods/log

# Get the manifest
kubectl create role log-reader --verb=get,watch,list --resource=pods,pods/log --dry-run=client -o yaml
```

`log-reader-role.yaml`

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: log-reader
  namespace: default
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods", "pods/log"]
  verbs: ["get", "watch", "list"]
```

Create the Role Binding, to bind the `ServiceAccount` (`User` or `Group`) with the **Roles**

```bash
# Create the RoleBinding
kubectl create rolebinding logger-pods --role log-reader --serviceaccount default:api-explorer --dry-run=client -o yaml
```

`logger-pods-rb.yaml`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: null
  name: logger-pods
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: log-reader
subjects:
- kind: ServiceAccount
  name: api-explorer
  namespace: default
```

Get all resources created

```bash
# Get ServiceAccount, Role, RoleBinding and Secrets created in default namespace
kubectl get ServiceAccount,Role,RoleBinding,Secrets 

# serviceaccount/default        1         45h
# serviceaccount/api-explorer   1         7m49s
# 
# NAME                                        CREATED AT
# role.rbac.authorization.k8s.io/log-reader   2022-02-13T19:46:19Z
# 
# NAME                                                ROLE              AGE
# rolebinding.rbac.authorization.k8s.io/logger-pods   Role/log-reader   3m28s
# 
# NAME                              TYPE                                  DATA   AGE
# secret/default-token-d5pjk        kubernetes.io/service-account-token   3      45h
# secret/api-explorer-token-rh2zn   kubernetes.io/service-account-token   3      7m49s
```

Create a Pod attached with the `ServiceAccountName` created

```bash
# Clean previous pod if already exists
kubectl delete pods nginx    
```

Since `--serviceaccount` is being deprecated, the serviceaccount must be inclued into a deployment file

`nginx-deployment-sa.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      # Service Account is sepecified at Pod level
      serviceAccountName: api-explorer 
      containers:
      - name: nginx
        image: nginx:1.21.6
        ports:
        - containerPort: 80
```

```bash
# Apply previous manifed using previous file
kubectl apply -f 

# Apply previous manifed directly using echo 
echo '
apiVersion: apps/v1
kind: Deployment
metadata:
...
' | kubectl apply -f -

# Verify the pods is running
kubectl get pods 
```

Check wether the secret hasa been mounted into the pod using the proper ServiceAccount

```bash
# Describe the deployment that has been created
# NOTE:  Mounted volumnes from ServiceAAccount are not visdbile within the deployments
kubectl describe deployment nginx

# Describe the pod that has been created
kubectl describe pod nginx-59cbd6d697-r9hg2

#    Mounts:
#     /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-pbwhq (ro)
```

Test the new credentials using the Kubernetes PI

```bash
# Shell into the container
kubectl exec -it nginx-578bcbcfcf-bkc8b -- sh 

# Install pre-requisites
apt update
apt install jq

# Set the APISERVER, CACERT, TOKEN environment variables from top
APISERVER=https://kubernetes.default.svc
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
TOKEN=$(cat ${SERVICEACCOUNT}/token)
CACERT=${SERVICEACCOUNT}/ca.crt

# Get all the pods in the default namespace
curl -X GET $APISERVER/api/v1/namespaces/default/pods/ \
--cacert ${CACERT} \
--header "Authorization: Bearer ${TOKEN}" \
| jq -rM '.items[].metadata.name'

# To get the logs of a pod, insert the desired pod name into the request path.
curl -X GET $APISERVER/api/v1/namespaces/default/pods/nginx-578bcbcfcf-bkc8b/log \
--cacert ${CACERT} \
--header "Authorization: Bearer ${TOKEN}" \
| tail -n 10
```

## References

* [Accessing the Kubernetes API from a Pod](https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/)
* [cURLing the Kubernetes API server](https://nieldw.medium.com/curling-the-kubernetes-api-server-d7675cfc398c)
* [Getting started with Kubernetes service accounts](https://www.youtube.com/watch?v=keoYFZhtg0U)
* [Kubernetes RBAC full tutorial with examples](https://www.youtube.com/watch?v=PSDVanXZ0a4)