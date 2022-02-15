# Kubernetes Security

## Kubescape

[Kubescape](https://github.com/armosec/kubescape) is a K8s open-source tool providing a multi-cloud K8s single pane of glass, including risk analysis, security compliance, RBAC visualizer and image vulnerabilities scanning. Kubescape scans K8s clusters, YAML files, and HELM charts, detecting misconfigurations according to multiple frameworks (such as the NSA-CISA , MITRE ATT&CK®), software vulnerabilities, and RBAC (role-based-access-control) violations at early stages of the CI/CD pipeline, calculates risk score instantly and shows risk trends over time. It became one of the fastest-growing Kubernetes tools among developers due to its easy-to-use CLI interface, flexible output formats, and automated scanning capabilities, saving Kubernetes users and admins’ precious time, effort, and resources. Kubescape integrates natively with other DevOps tools, including Jenkins, CircleCI, Github workflows, Prometheus, and Slack, and supports multi-cloud K8s deployments like EKS, GKE, and AKS.

Kubescape based on OPA engine: https://github.com/open-policy-agent/opa and ARMO's posture controls.

The tools retrieves Kubernetes objects from the API server and runs a set of regos snippets developed by ARMO.

### Installation

`Kubescape` can be downloaded from the Gihub page

```bash
# Install specific version from Git
VERSION=v2.0.147 && ORIG_FILE=kubescape-macos-latest DEST_FILE=kubescape && \
DOWNLOAD_URL=https://github.com/armosec/kubescape/releases/download/$VERSION/$ORIG_FILE && \
wget $DOWNLOAD_URL && chmod +x $ORIG_FILE &&  sudo mv $ORIG_FILE /usr/local/bin/$DEST_FILE

# Verify Version
kubescape version 
```

### Usage

In other to test into a Kubernetes cluster, following examples can be used

```bash
# Scan a running Kubernetes cluster with nsa framework. Use '--submit' to submit results to the Kubescape SaaS version
kubescape scan framework nsa

# Scan a running Kubernetes cluster with MITRE ATT&CK® framework
kubescape scan framework mitre

# Scan a running Kubernetes cluster with a specific control using the control name or control ID. See List of controls
kubescape scan control "Privileged container"

#Scan specific namespaces
kubescape scan --include-namespaces development,staging,production

# Scan enabling host scan
kubescape scan --enable-host-scan --include-namespaces micro

# Scan cluster and exclude some namespaces
kubescape scan --exclude-namespaces kube-system,kube-public

# Output in json, junit, prometheus format
kubescape scan --format json --output results.json
kubescape scan --format junit --output results.xml
kubescape scan --format prometheus

# Display all scanned resources (including the resources who passed)
kubescape scan --verbose
```

Files, Manifest, Helm charts can be scanned

```bash
# Scan local yaml/json files before deploying. Take a look at the demonstration
kubescape scan *.yaml

# Scan kubernetes manifest files from a public github repository
kubescape scan https://github.com/armosec/kubescape

# Scan Helm charts - Render the helm chart using helm template and pass to stdout
helm template [NAME] [CHART] [flags] --dry-run | kubescape scan -

# Helm3 example
helm3 template car -n micro --create-namespace --dependency-update helm/components/car --dry-run | kubescape scan -
```

Offline/Air-gaped Environment Support

```bash
# Download All

# 1. Download and save in local directory, if path not specified, will save all in ~/.kubescape
kubescape download artifacts --output path/to/local/dir

# 2. Scan using the downloaded artifacts
kubescape scan --use-artifacts-from path/to/local/dir

# Download specific files

# 1. Download and save in file, if file name not specified, will save in ~/.kubescape/<framework name>.json
kubescape download framework nsa --output /path/nsa.json

# 2. Scan using the downloaded framework
kubescape scan framework nsa --use-from /path/nsa.json
```

## Falco

### Installation

Install Chart

```bash
# Adding falcosecurity repository
helm3 repo add falcosecurity https://falcosecurity.github.io/charts
helm3 repo update

# Installing the Chart
helm3 install -n falco --create-namespace falco falcosecurity/falco --version 1.17.1

# Installing the Chart with some settings (--set ebpf.enabled=true)
helm3 install -n falco --create-namespace falco falcosecurity/falco --version 1.17.1 --set falcosidekick.enabled=true 
```

Uninstall Chart

```bash
# To uninstall the falco deployment:
helm3 delete -n falco falco
```

## Popeye - A Kubernetes Cluster Sanitizer

> **UPDATE**: The latest release for Popeye of from Nov 2021

[Popeye](https://github.com/derailed/popeye) is a utility that scans live Kubernetes cluster and reports potential issues with deployed resources and configurations. It **sanitizes** your cluster based on what's deployed and not what's sitting on disk. By scanning your cluster, it detects misconfigurations and helps you to ensure that best practices are in place, thus preventing future headaches. It aims at reducing the cognitive overload one faces when operating a Kubernetes cluster in the wild. Furthermore, if your cluster employs a metric-server, it reports potential resources over/under allocations and attempts to warn you should your cluster run out of capacity. Popeye is a **readonly** tool, it does not alter any of your Kubernetes resources.

### Installation

`Popeye` is integrated into `k9s` tools

```bash
# Install specific version from Git
VERSION=v0.25.18 && ORIG_FILE=k9s_Darwin_x86_64.tar.gz DEST_FILE=k9s && \
DOWNLOAD_URL=https://github.com/derailed/k9s/releases/download/$VERSION/$ORIG_FILE && \
wget $DOWNLOAD_URL && tar -zxvf $ORIG_FILE $DEST_FILE && chmod +x $DEST_FILE && \
sudo mv $DEST_FILE /usr/local/bin/$DEST_FILE && rm $ORIG_FILE

# Verify Version
k9s version

# Remove ~/.k9s from user folder if already exists.
```

### Usage

Using `k9s` with Popeye integration

```bash
# Open k9s
k9s

# Popeye -> :popeye
# Pulse -> :pulse
# Namespaces -> :ns
# Pods -> :pods
# Quit -> :quit

# Filter / cored
# Label  /-l ssd

# X-ray -> :xray pod default
```

Using docker

```bash
# Run popeye within default context and namespace
docker run --rm -it --network="host" -v ~/.kube:/root/.kube derailed/popeye

# Run popeye specifying context and namespace
docker run --rm -it --network="host" \
    -v ~/.kube:/root/.kube derailed/popeye \
    --context rancher-desktop -n kube-system
```

## Kube-Hunter

[kube-hunter](https://github.com/aquasecurity/kube-hunter) hunts for security **weaknesses** in Kubernetes clusters. The tool was developed to increase awareness and visibility for security issues in Kubernetes environments. You should **NOT** run kube-hunter on a Kubernetes cluster that you don't own!

Kube-hunter is available as a container (`aquasec/kube-hunter`), and we also offer a web site at kube-hunter.aquasec.com where you can register online to receive a token allowing you to see and share the results online. You can also run the Python code yourself as described below.

The kube-hunter knowledge base includes articles about discoverable vulnerabilities and issues. When kube-hunter reports an issue, it will show its VID (Vulnerability ID) so you can look it up in the KB at https://aquasecurity.github.io/kube-hunter/

## Kube-Bench

[kube-bench](https://github.com/aquasecurity/kube-bench) is a tool that checks whether Kubernetes is deployed securely by running the checks documented in the CIS Kubernetes Benchmark. **Center for Internet Security** (CIS) provides a number of guidelines to make sure your system is following the security best practices.

### Installation

> Only available for `Linux` Systems

```bash
# Install specific version from Git
VERSION=0.6.6 && ORIG_FILE=kube-bench_${VERSION}_linux_amd64.tar.gz DEST_FILE=kube-bench && \
DOWNLOAD_URL=https://github.com/aquasecurity/kube-bench/releases/download/v$VERSION/$ORIG_FILE && \
wget $DOWNLOAD_URL && tar -zxvf $ORIG_FILE && chmod +x $DEST_FILE && \
sudo mv $DEST_FILE /usr/local/bin/$DEST_FILE && rm $ORIG_FILE

# Verify Version
kube-bench version
```

```bash
# You can run kube-bench inside a pod, but it will need access to the host's PID namespace in order to check the running processes
kubectl create -f https://github.com/aquasecurity/kube-bench/blob/main/job.yaml

# Get the name of the po createdd
kubectl get pods

# Get the  output from the logs
kubectl logs kube-bench-ndqsm
```