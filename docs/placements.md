# Placements

## Kubernetes Cluster

In order to create Kubernetes clusters it can be used: k3s, k3d, Kind, k0s, Minikube, Rancher Desktop, Docker for Desktop, etc..

However, some of them do not provide the functionality to deploy a High Available Kubernetes cluster with multiples nodes.

This example shows how to create a HA Custer using `k3d`

```bash
# Create a Kubernetes cluster using k3d
# --servers 1 \ # How many nodes used for the Control Plane
# --agents 3 \ # How many workers available to distribute the Workloads
k3d cluster create k3s-ha \
        --api-port 6550 \
        --servers 1 \
        --agents 3 \
        --port 80:80@loadbalancer \
        --port 443:443@loadbalancer

# Get the contexts (verify is the k3d-*)
kubectl config get-contexts

# Get the cluster information
kubectl cluster-info 

# Get all the nodes
kubectl get nodes -o wide
```

## Types

### Node Selector

> Consider using `Affinity`, since it is more flexible than NodeSelectot

Add a `label` to a node

```bash
# List the nodes in your cluster, along with their labels:
kubectl get nodes --show-labels

# Create a label for specific nodes ('disktype=ssd')
kubectl label nodes k3d-k3s-ha-agent-1 disktype=ssd
```

Add following `nodeSelector` key-value to the deployment.

```yaml
  nodeSelector:
    disktype: ssd
```

Check all pod replicas are scheduled into the same node with the label set (`k3d-k3s-ha-agent-1`).

```bash
# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro

# Sacel the previous deployment to 3
kubectl scale --replicas=3 deployment microservice-notifications -n micro

# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro
```

All pods are scheduled into the same node because `nodeSelector` applied to the deployment

```console
NAME                                          READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
microservice-notifications-76845d6887-4sg6n   1/1     Running   0          45s   10.42.3.14   k3d-k3s-ha-agent-1   <none>           <none>
microservice-notifications-76845d6887-ff5rg   1/1     Running   0          4s    10.42.3.15   k3d-k3s-ha-agent-1   <none>           <none>
microservice-notifications-76845d6887-xkn6g   1/1     Running   0          4s    10.42.3.16   k3d-k3s-ha-agent-1   <none>           <none>
```

### Affinity

The way kubernetes assign Pods to nodes is using `nodeSelector` and `affinity` features. As we tried to demonstrate, `affinity` is a great feature for such use cases as creating **dedicated** nodes, distributing Pods evenly across the cluster (`podAntiAffinity`)  or co-locating Pods on the same machine (`nodeAffinity`).

#### NodeAffinity

Add a `label` to a node

```bash
# List the nodes in your cluster, along with their labels:
kubectl get nodes --show-labels

# Create a label for specific nodes ('disktype=ssd')
kubectl label nodes k3d-k3s-ha-agent-1 disktype=ssd
```

Add following `nodeAffinity` rule to the deployment. Be care about `requiredDuring*` or `preferredDuring*` rules type.

```yaml
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd   
```

Check all pod replicas are scheduled into the same node with the label set (`k3d-k3s-ha-agent-1`).

```bash
# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro

# Sacel the previous deployment to 3
kubectl scale --replicas=3 deployment microservice-notifications -n micro

# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro
```

All pods are scheduled into the same node because `nodeAffinity` rule applied to the deployment

```console
NAME                                          READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
microservice-notifications-76845d6887-4sg6n   1/1     Running   0          45s   10.42.3.14   k3d-k3s-ha-agent-1   <none>           <none>
microservice-notifications-76845d6887-ff5rg   1/1     Running   0          4s    10.42.3.15   k3d-k3s-ha-agent-1   <none>           <none>
microservice-notifications-76845d6887-xkn6g   1/1     Running   0          4s    10.42.3.16   k3d-k3s-ha-agent-1   <none>           <none>
```

#### PodAffinity

#### PodAntiAffinity

Using standard deployment with **no** `PodAntiAffinity` configured

```bash
# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro

# Sacel the previous deployment to 3
kubectl scale --replicas=3 deployment microservice-notifications -n micro

# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro
```

Pods are **not** placed equally over the nodes.

```console
NAME                                          READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
microservice-notifications-599fb6c7c7-7fvhm   1/1     Running   0          11s   10.42.1.8    k3d-k3s-ha-agent-0   <none>           <none>
microservice-notifications-599fb6c7c7-stx4h   1/1     Running   0          11s   10.42.3.12   k3d-k3s-ha-agent-1   <none>           <none>
microservice-notifications-599fb6c7c7-dcmjh   1/1     Running   0          75s   10.42.3.11   k3d-k3s-ha-agent-1   <none>           <none>
```

Setting `podAntiAffinity` into deployment with `preferredDuringSchedulingIgnoredDuringExecution`

```yaml
#...
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - podAffinityTerm:
            labelSelector:
              matchLabels:
                app.kubernetes.io/name: notifications
                app.kubernetes.io/instance: microservice  
            topologyKey: kubernetes.io/hostname
          weight: 100
```

Verify that the pod is running on different nodes each.

> Since it is not **required** (`requiredDuringSchedulingIgnoredDuringExecution`) pods are scheduled over the nodes equally because `weight=100`

```bash
# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro

# Scale the previous deployment to 3
kubectl scale --replicas=3 deployment microservice-notifications -n micro

# Scale the previous deployment to 9
kubectl scale --replicas=9 deployment microservice-notifications -n micro

# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro
```

Pods are distributes over all the Nodes that mathes with `PodAntiAffinity` rules

```console
NAME                                          READY   STATUS    RESTARTS   AGE   IP          NODE                 NOMINATED NODE   READINESS GATES
microservice-notifications-56dcc4f4cb-sqlkz   1/1     Running   0          11m   10.42.3.8   k3d-k3s-ha-agent-1   <none>           <none>
microservice-notifications-56dcc4f4cb-r6nf6   1/1     Running   0          64s   10.42.2.5   k3d-k3s-ha-agent-2   <none>           <none>
microservice-notifications-56dcc4f4cb-r77fr   1/1     Running   0          64s   10.42.1.6   k3d-k3s-ha-agent-0   <none>           <none>
```

By using the `requiredDuringSchedulingIgnoredDuringExecution` for `podAntiAffinity`

```yaml
#...
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/instance: microservice
            app.kubernetes.io/name: notifications
        topologyKey: kubernetes.io/hostname
```

```bash
# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro

# Scale the previous deployment to 3
kubectl scale --replicas=3 deployment microservice-notifications -n micro

# Scale the previous deployment to 6
kubectl scale --replicas=6 deployment microservice-notifications -n micro

# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro
```

Since it is `required` some pods will be in `pending` state until new nodes are created.

```bash
NAME                                          READY   STATUS    RESTARTS   AGE     IP           NODE                  NOMINATED NODE   READINESS GATES
microservice-notifications-7c9d5d7644-7zrll   1/1     Running   0          2m38s   10.42.3.13   k3d-k3s-ha-agent-1    <none>           <none>
microservice-notifications-7c9d5d7644-l2b6m   1/1     Running   0          65s     10.42.1.9    k3d-k3s-ha-agent-0    <none>           <none>
microservice-notifications-7c9d5d7644-rbnzp   1/1     Running   0          65s     10.42.0.9    k3d-k3s-ha-server-0   <none>           <none>
microservice-notifications-7c9d5d7644-g554b   1/1     Running   0          22s     10.42.2.7    k3d-k3s-ha-agent-2    <none>           <none>
microservice-notifications-7c9d5d7644-prn2n   0/1     Pending   0          4s      <none>       <none>                <none>           <none>
microservice-notifications-7c9d5d7644-k5j8h   0/1     Pending   0          4s      <none>       <none>                <none>           <none>
```

### Tolerations

`Taints` are used to **repel** Pods from specific nodes. This is quite similar to the node `anti-affinity`. However, `taints` and `tolerations` take a slightly different approach. Instead of applying the label to a node, we apply a `taint` that tells a scheduler to **repel** Pods from this node if it does not match the taint. Only those Pods that have a **toleration** for the taint can be let into the node with that taint.

Without using `taint` pods can be scheduled into every Node

```bash
# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro

# Scale the previous deployment to 6
kubectl scale --replicas=6 deployment microservice-notifications -n micro

# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro
```

All nodes are used for the scheduling operations for this deployment (see `k3d-k3s-ha-server-0`).

```console
NAME                                         READY   STATUS    RESTARTS   AGE    IP           NODE                  NOMINATED NODE   READINESS GATES
microservice-notifications-85d57db79-5k4nj   1/1     Running   0          105s   10.42.3.21   k3d-k3s-ha-agent-1    <none>           <none>
microservice-notifications-85d57db79-5wh4c   1/1     Running   0          22s    10.42.1.10   k3d-k3s-ha-agent-0    <none>           <none>
microservice-notifications-85d57db79-qwchr   1/1     Running   0          22s    10.42.0.10   k3d-k3s-ha-server-0   <none>           <none>
microservice-notifications-85d57db79-fgcns   1/1     Running   0          22s    10.42.2.9    k3d-k3s-ha-agent-2    <none>           <none>
microservice-notifications-85d57db79-n2l5b   1/1     Running   0          22s    10.42.2.8    k3d-k3s-ha-agent-2    <none>           <none>
microservice-notifications-85d57db79-vw8wx   1/1     Running   0          22s    10.42.3.22   k3d-k3s-ha-agent-1    <none>           <none>
```

In order to use toleratinos. it si needed to add a `taint` to a node using `kubectl taint`.

```bash
# Taint the Node to NoSchedule operation
kubectl taint nodes k3d-k3s-ha-server-0 key1=value1:NoSchedule

# Get node taints
kubectl get nodes -o json | jq '.items[].spec.taints,.items[].spec.providerID' 

# Describe specific node to get taints
kubectl describe nodes  k3d-k3s-ha-server-0 | grep "Taints"

# Taints:             key1=value1:NoSchedule
```

To remove the taint added by the command above, you can run:

```bash
# Remove Taint by using minus symbol "-" at the end
kubectl taint nodes k3d-k3s-ha-server-0 key1=value1:NoSchedule-

# Describe specific node to get taints
kubectl describe nodes  k3d-k3s-ha-server-0 | grep "Taints"

# Taints:             <none>
```

Use the following `tolerations` configuration in the deployment.

```yaml
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule
```

```yaml
tolerations:
- key: "key1"
  operator: "Exists"
  effect: "NoSchedule"
```

Get pods spread over the nodes, since the tolerations also inclue the `tainted` node

```bash
# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro

# Scale the previous deployment to 6
kubectl scale --replicas=6 deployment microservice-notifications -n micro

# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro
```

All nodes are used for the scheduling operations for this deployment (see `k3d-k3s-ha-server-0`).

```console
NAME                                         READY   STATUS    RESTARTS   AGE    IP           NODE                  NOMINATED NODE   READINESS GATES
microservice-notifications-85d57db79-5k4nj   1/1     Running   0          105s   10.42.3.21   k3d-k3s-ha-agent-1    <none>           <none>
microservice-notifications-85d57db79-5wh4c   1/1     Running   0          22s    10.42.1.10   k3d-k3s-ha-agent-0    <none>           <none>
microservice-notifications-85d57db79-qwchr   1/1     Running   0          22s    10.42.0.10   k3d-k3s-ha-server-0   <none>           <none>
microservice-notifications-85d57db79-fgcns   1/1     Running   0          22s    10.42.2.9    k3d-k3s-ha-agent-2    <none>           <none>
microservice-notifications-85d57db79-n2l5b   1/1     Running   0          22s    10.42.2.8    k3d-k3s-ha-agent-2    <none>           <none>
microservice-notifications-85d57db79-vw8wx   1/1     Running   0          22s    10.42.3.22   k3d-k3s-ha-agent-1    <none>           <none>
```

Let's change the toleration to a different one.

```yaml
tolerations:
- key: "key2"
  operator: "Exists"
  effect: "NoSchedule"
```

Perform the same operations

```bash
# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro

# Scale the previous deployment to 6
kubectl scale --replicas=6 deployment microservice-notifications -n micro

# Get the node column where each pods has been placed
kubectl get pods -o wide -n micro
```

All nodes except the **tained** one (`k3d-k3s-ha-server-0`) are used for the scheduling.

```console
NAME                                          READY   STATUS      RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS
microservice-notifications-787599fd9f-4fv5b    1/1     Running    0          23s   10.42.3.27   k3d-k3s-ha-agent-1   <none>           <none>
microservice-notifications-787599fd9f-7cbpm    1/1     Running    0          4s    <none>       k3d-k3s-ha-agent-0   <none>           <none>
microservice-notifications-787599fd9f-vl472    1/1     Running    0          3s    <none>       k3d-k3s-ha-agent-2   <none>           <none>
microservice-notifications-787599fd9f-6xndz    1/1     Running    0          3s    <none>       k3d-k3s-ha-agent-0   <none>           <none>
microservice-notifications-787599fd9f-55nk4    1/1     Running    0          3s    <none>       k3d-k3s-ha-agent-2   <none>           <none>
microservice-notifications-787599fd9f-qwj2j    1/1     Running    0          3s    10.42.3.28   k3d-k3s-ha-agent-1   <none>           <none>
```