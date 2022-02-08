# Sealed Secret

https://github.com/bitnami-labs/sealed-secrets

**Problem**: "I can manage all my K8s config in Git, except Secrets." (GitOps)

**Solution**: Encrypt your Secret into a SealedSecret, which is safe to store - even to a public repository. The SealedSecret can be decrypted only by the controller running in the target cluster and nobody else (not even the original author) is able to obtain the original Secret from the SealedSecret.

## Scopes

These are the possible scopes:

* **strict** (default): the secret must be sealed with exactly the same name and namespace. These attributes become part of the encrypted data and thus changing name and/or namespace would lead to "decryption error".
* **namespace-wide**: you can freely rename the sealed secret within a given namespace.
* **cluster-wide**: the secret can be unsealed in any namespace and can be given any name.

## Installation (Without ArgoCD)

> It would be needed to create public and private certificates to encrypt first secrets.

```bash
# Add the sealed secret repo
helm3 repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets

# Install the chart with the default values and specific version
helm3 install sealed-secrets -n sealed-secrets --create-namespace sealed-secrets/sealed-secrets --version 2.1.2

# [RECOMMENDED] Install the chart with the custom values and specific version (argocd/sealed-secrets.yaml)
helm3 install sealed-secrets -n sealed-secrets --create-namespace sealed-secrets/sealed-secrets --version 2.1.2 --set keyrenewperiod=720h0m0s
```

## Kubeseal CLI

[kubeseal releases](https://github.com/bitnami-labs/sealed-secrets/releases)

```bash
# Download kubeseal desired version
export KUBESEAL_VERSION=0.17.3
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v$KUBESEAL_VERSION/kubeseal-$KUBESEAL_VERSION-darwin-amd64.tar.gz

# Unpack it 
tar -zxvf kubeseal-$KUBESEAL_VERSION-darwin-amd64.tar.gz

# Move to user binaries
sudo mv kubeseal /usr/local/bin/kubeseal

# Remove temporary files
rm LICENSE README.md
rm kubeseal-$KUBESEAL_VERSION-darwin-amd64.tar.gz

# Test kubeseal 
kubeseal --version \
  --controller-namespace sealed-secrets \
  --controller-name sealed-secrets
```

## Create Custom Certificates

In order to create your own set of certificates (Managed) use the following procedure

https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md

```bash
##Set your vars
export PRIVATEKEY="sealed-secrets.key"
export PUBLICKEY="sealed-secrets.crt"
export NAMESPACE="sealed-secrets"
export SECRETNAME="sealed-secrets-keys"
```

Generate a new RSA key pair (certificates)

```bash
# Create the asymetric certificates
openssl req -x509 -nodes -newkey rsa:4096 -keyout "$PRIVATEKEY" -out "$PUBLICKEY" -subj "/CN=sealed-secret/O=sealed-secret"
```

Create a tls k8s secret, using your recently created RSA key pair

```bash
# Create namespace if not exists
kubectl create namespace "$NAMESPACE"

# Create a secret with the public and private keys
kubectl -n "$NAMESPACE" create secret tls "$SECRETNAME" --cert="$PUBLICKEY" --key="$PRIVATEKEY"

# Add a custom label to notificy the controller the current active secret to use
kubectl -n "$NAMESPACE" label secret "$SECRETNAME" sealedsecrets.bitnami.com/sealed-secrets-key=active
```

Delete the controller Pod is needed to pick they new keys (automatically)

> If you have not installed `sealed-secrets` yet, these certificates will be used by the controller.

```bash
# Delete the pod so sealed secret refresh the aactive keys
kubectl -n  "$NAMESPACE" delete pod -l name=sealed-secrets-controller

Use your own certificate (key) by using the `--cert` flag:

# Use the public key (offline) to encrypt the secret
kubeseal --cert "./${PUBLICKEY}" --scope cluster-wide < mysecret.yaml | kubectl apply -f-
```

## Script

Script to encrypt al the files with the `.unseal` extension with the secrets as text/plain

```console
├── folderA
│   ├── folderAA
│   │   ├── database.password.unseal
│   │   ├── database.username.unseal
│   │   ├── folderAAA
│   │   │   ├── database.password.unseal
│   │   │   ├── database.username.unseal
│   │   │   └── jwt.publicKey.unseal
│   │   └── jwt.publicKey.unseal
│   └── folderAB
│       ├── database.password.unseal
│       ├── database.username.unseal
│       └── jwt.publicKey.unseal
```

Use following commands

```bash
# Check all the files to be encrypted
./seal-secrets.sh plan './certs/sealed-secrets.crt'

# Apply the kubeseal encryption with the public key provided
./seal-secrets.sh apply './certs/sealed-secrets.crt'
```

## Usage

### Get the public key to encrypt the file

```bash
kubeseal \
    --controller-name=sealed-secrets \
    --controller-namespace=sealed-secrets\
    --fetch-cert > sealed-secrets.crt
```

### Create a normal secret using the conten of the file

```bash
# Create a secret using the specified key (mysecret) and file (mysecret.unseal)
kubectl create secret generic mysecret --dry-run=client --from-file=mysecret=mysecret.unseal -o yaml > mysecret.yaml

# Create the secret using the key as the filename (mysecret.unseal)
kubectl create secret generic mysecret --dry-run=client --from-file=mysecret.unseal -o yaml > mysecret.yaml
```

### Create the sealed secret using the previous secret created and cert

```bash
# Create the secret using a file an key
kubectl create secret generic mysecret --dry-run=client --from-file=mysecret=mysecret.unseal -o yaml > mysecret.yaml

# Creaete the sealed-secret cluster-wide to be used with templating (helm chaart)
kubeseal --cert sealed-secrets.crt --scope cluster-wide -o yaml < mysecret.yaml > mysecret-sealed.yaml
```

### Apply the sealed secret and verify it is created in every namespace

```bash
# Create within the Current namespace
kubectl apply -f mysecret-sealed.yaml

# Create a new namespace
kubectl create namespace example
kubectl apply -n example -f mysecret-sealed.yaml

# Get the name of the sealed-secret creaated
kubectl get secret,sealedsecret --all-namespaces | grep my

# Sealed secrets and Secrets (by sealed-secret-controller) must be created in both namespaces
# NAMESPACE         NAME                                                        TYPE                                  DATA   AGE
# default           secret/mysecret                                             Opaque                                1      19s
# example           secret/mysecret                                             Opaque                                1      19s
# default     sealedsecret.bitnami.com/mysecret   19s
# example     sealedsecret.bitnami.com/mysecret   19s

# Describe the status of the sealed-secrets
kubectl describe sealedsecret mysecret
kubectl describe sealedsecret -n example mysecret

# Remove sealec-secrets
kubectl delete sealedsecret mysecret
kubectl delete sealedsecret -n example mysecret

# Since secrets are managed by sealed-secrets everything must be deleted
kubectl get secret,sealedsecret --all-namespaces | grep my

```

### Create Sealed Secrets Manifest Manually

Create following sealed-secret file tamplate called `secret-sealed-template.yaml`

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  annotations:
    sealedsecrets.bitnami.com/cluster-wide: "true"
  name: ${SECRERT_SEALED_NAME}
spec:
  encryptedData:
    ${MYSECRERT_KEY}: ${MYSECRERT_SEALED}
```

```bash
# Create a raw encrypt from a text file
kubeseal --cert sealed-secrets.crt --raw --scope cluster-wide --from-file=mysecret.unseal

# Create the env variables to use with the template
export SECRERT_SEALED_NAME=mysecret-sealed
export MYSECRERT_KEY=mysecret
export MYSECRERT_SEALED=$(Kubeseal --cert sealed-secrets.crt --raw --scope cluster-wide --from-file=mysecret.unseal)

# Create a file using the variales and the template
envsubst < secret-sealed-template.yaml > mysecret-sealed.yaml

# Apply into the same namespace
kubectl apply -f mysecret-sealed.yaml
# Describe the creaatee secret
kubectl describe sealedsecret mysecret

# This must return the secret 
kubectl get secret mysecret-sealed -o jsonpath='{.data.mysecret}' | base64 -d
```
