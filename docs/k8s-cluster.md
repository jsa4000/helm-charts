# Cluster

## k3s

### Installation

The install.sh script provides a convenient way to download K3s and add a service to systemd or openrc.

To install k3s as a service, run:

```bash
# Install using edge version from Github
curl -sfL https://get.k3s.io | sh -

# Install using specified version and set kubeconfig permissions (/etc/rancher/k3s/k3s.yaml)
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_VERSION=v1.22.5+k3s1 sh - 

# Uninstall k3s
/usr/local/bin/k3s-killall.sh
```

A `kubeconfig` file is written to `/etc/rancher/k3s/k3s.yaml` and the service is automatically started or restarted. The install script will install K3s and additional utilities, such as `kubectl`, `crictl`, `k3s-killall.sh`, and `k3s-uninstall.sh`.

`K3S_TOKEN` is created at `/var/lib/rancher/k3s/server/node-token` on your server. To install on worker nodes, pass `K3S_URL` along with `K3S_TOKEN` or `K3S_CLUSTER_SECRET` environment variables, for example:

```bash
# Join workers to the cluster
curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=XXX sh -
```

### Verify

```bash
# Get current context status
kubectl cluster-info

# Get Node Status
kubectl get nodes

# Get Node current capacity
kubectl top nodes

# Get all Pods status (Including control plane)
kubectl get pods --all-namespaces
```

### Kubeconfig

Copy or get the content from the created kubeconfig file at `/etc/rancher/k3s/k3s.yaml`

```bash
# Copy the content into a local file ~/.kube/k3s
cat /etc/rancher/k3s/k3s.yaml
# Replace the loopback address with IP Address of the host machine (use 'sed' or 'gsed')
sed -i 's/127.0.0.1/192.168.56.10/g' ~/.kube/k3s

# export current kubeconfig (or combine context)
export KUBECONFIG=$KUBECONFIG:~/.kube/k3s

# Verify Connection
kubectl cluster-info
kubectl version
kubectl get nodes

# Verify LoadBalanacer created by traefic (EXTERNAL-IP is local)
kubectl -n kube-system get svc
telnet 192.168.56.10 443
```

## K3d

Create a cluster using k3d

```bash
# Create a cluster 1 Master node and 3 Workers nodes
k3d cluster create k3s-ha \
    --api-port 6550 \
    --servers 1 \
    --agents 3 \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer

# Get the contexts
kubectl config get-contexts 

 # Get the cluster information
kubectl cluster-info   

# Get the nodes created
kubectl get nodes -o wide
```

```bash
# Delete created cluster
k3d cluster delete k3s-ha
```

## Kubeadm

### Vagrant

Create a `Vagrantfile` with the following content

```ruby
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.hostname = "ubuntu-focal"
  config.vm.network :private_network, ip: "192.168.56.10"
  config.vm.synced_folder "files/", "/vagrant"

  # Virtual Box
  config.vm.provider :virtualbox do |vb|
    vb.memory = 2046
  end

  # KVM: vagrant up --provider=libvirt
  #config.vm.provider :libvirt do |libvirt|
  #  libvirt.memory = 2048
  #  libvirt.cpus = 2
  #end

  config.vm.provision :shell, path: "provision/ubuntu_update.sh"
  config.vm.provision :shell, path: "provision/addons_install.sh"
end

```

```bash
# Start the Virtual Machine
vagrant up

# login in to the machine
vagrant ssh

# Destroy the Virtual Machine
vagrant destroy

# Current VMs managed by vagrant
vagrant global-status
```

### Installation

https://computingforgeeks.com/deploy-kubernetes-cluster-on-ubuntu-with-kubeadm/ 

Install dependencies and `kubeadm`

```bash
# Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Download the Google Cloud public signing key:
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# Add the Kubernetes apt repository:
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Check the installation
kubectl version --client && kubeadm version
```

Disable Swap

```bash
# Turn off swap.
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
```

Enable kernel modules and configure sysctl.

```bash
# Enable kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Add some settings to sysctl
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload sysctl
sudo sysctl --system
```

Install Container runtime

```bash
# Configure persistent loading of modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

# Install required packages
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Add Docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install containerd
sudo apt update
sudo apt install -y containerd

# Configure containerd and start service
sudo su -
mkdir -p /etc/containerd
containerd config default>/etc/containerd/config.toml

# restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
systemctl status  containerd
```

Verification

```bash
# Make sure that the br_netfilter module is loaded
lsmod | grep br_netfilter

# Enable kubelet service.
sudo systemctl enable kubelet

# Pull container images:
sudo kubeadm config images pull

# f you have multiple CRI sockets, please use --cri-socket to select one:
sudo kubeadm config images pull --cri-socket /run/containerd/containerd.sock

# Bootstrap without shared endpoint, for Containerd
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --cri-socket /run/containerd/containerd.sock \
  --upload-certs \
  --control-plane-endpoint=192.168.56.10

#Configure kubectl using commands in the output:
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Check cluster status:
kubectl cluster-info

# Set simpler alias for kubectl
alias k=kubectl

# join other nodes
kubeadm join 192.168.56.10:6443 --token bm9gfw.jeuz7l61ep9jeowl \
	--discovery-token-ca-cert-hash sha256:1b6a784255c0332a3d6c52a37131947a03e9f7142c717c68652b3f49375bff12
```

Install Kubernetes Network Plugin CNI

```bash
# Install Calino Network
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml 
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml

# Confirm that all of the pods are running
kubectl get pods --all-namespaces

# Confirm master node is ready
kubectl get nodes -o wide
```

Scheduling Pods on Kubernetes Control plane (Master) Nodes

```bash
# Remove taint to master nodes
kubectl taint nodes --all node-role.kubernetes.io/master-
```

Copy the kubeconfig into `~/.kube/vm-config`

```bash
# Copy the kubeconfig into the shared folder
cp ~/.kube/config /vagrant/vm-config

# Export the KUBECONFIG using the vm-config path
export KUBECONFIG=$KUBECONFIG:~/.kube/vm-config 

# Deploy the Metrics Server with the following command:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Get the current status of the cluster
kubectl top nodes
```