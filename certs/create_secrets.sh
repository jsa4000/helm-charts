#!/bin/bash

# Unzip file
CERT_FILE="sealed-secrets-certs"
unzip $CERT_FILE.zip -d $CERT_FILE

##Set your vars
NAMESPACE="sealed-secrets"
SECRETNAME="sealed-secrets-keys"
PRIVATEKEY="$CERT_FILE/sealed-secrets.key"
PUBLICKEY="$CERT_FILE/sealed-secrets.crt"

# Create namespace if not exists
kubectl create namespace "$NAMESPACE"

# Create a secret with the public and private keys
kubectl -n "$NAMESPACE" create secret tls "$SECRETNAME" --cert="$PUBLICKEY" --key="$PRIVATEKEY"

# Add a custom label to notificy the controller the current active secret to use
kubectl -n "$NAMESPACE" label secret "$SECRETNAME" sealedsecrets.bitnami.com/sealed-secrets-key=active

# Remove folder
rm -rf $CERT_FILE