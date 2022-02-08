#!/bin/bash

## HOW TO USE THE SCRIPT
#
# Run using the certificate provided by Sealed Secret Controller installed into the cluster
# ./seal-secrets.sh 
# Run using the provided certificate by args
# ./seal-secrets.sh apply 'sealed-secret-public.pem'
#

# Set variables
VERBOSE=1
RUN_MODE=${1:-"plan"}
UNSEAL_FILE_EXTENSION="unseal"
PUBLIC_CERT_FILE=$2
KUBESEAL_SCOPE="cluster-wide"
KUBESEAL_BINARY="kubeseal"

# Check if kubeseal is installed
KUBESEAL_VERSION=$($KUBESEAL_BINARY --version)
if [ $? -eq 0 ]; then
    echo "kubeseal has been detected"
else
    echo "ERROR: kubeseal has not been detected"
    exit 1
fi

# Show the run mode
echo "Run mode $RUN_MODE is enabled"

# Echo the parameters
if [ -z "$PUBLIC_CERT_FILE" ]; then
    ##echo "Using the certificate provided by Sealed Secret Controller installed into the cluster."
    echo "ERROR: Currently not supported. It is needed to provide a valid certificate to encrypt the files"
    exit 1
else
    echo "Using the provided certificate by args $PUBLIC_CERT_FILE."
fi

# Find all files with extension recursively (whitespaces in folders not supported)
array=($(find . -name "*.$UNSEAL_FILE_EXTENSION"))

# Seal secrets and change the name of the file without extensioon
for i in ${array[@]};do 
    if [ $VERBOSE -eq 1 ]; then
        echo "File $i has been detected."; 
    fi
    if [ $RUN_MODE == "apply" ]; then
        if [ -z "$PUBLIC_CERT_FILE" ]; then
        SECRERT_SEALED=$(kubeseal --raw --scope $KUBESEAL_SCOPE --from-file=$i)
        else
        SECRERT_SEALED=$(kubeseal --cert $PUBLIC_CERT_FILE --raw --scope $KUBESEAL_SCOPE --from-file=$i)
        fi
        #echo $SECRERT_SEALED
        # Create new file encrypted
        SECRERT_SEALED_FILE="$(dirname $i)/$(basename $i .unseal )"
        echo "$SECRERT_SEALED" > $SECRERT_SEALED_FILE
        # Remove original file
        rm $i
        # Print the result
        if [ $VERBOSE -eq 1 ]; then
            echo "- Succesfully Sealed"; 
        fi
    fi
done

