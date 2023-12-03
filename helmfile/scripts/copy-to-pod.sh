#!/bin/sh

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <local-file-path> <namespace:pod/directory>"
	exit 1
fi

LOCAL_FILE_PATH="$1"
NAMESPACE_POD_DIR="$2"

# Extract the namespace, pod name, and directory from the second argument
NAMESPACE=$(echo $NAMESPACE_POD_DIR | cut -d ':' -f 1)
POD_DIR=$(echo $NAMESPACE_POD_DIR | cut -d ':' -f 2)
POD=$(echo $POD_DIR | cut -d '/' -f 1)
DIRECTORY=$(echo $POD_DIR | cut -d '/' -f 2-)

POD_NAME=$(kubectl get pods -n $NAMESPACE -o jsonpath="{.items[*].metadata.name}" | tr ' ' '\n' | grep "$POD")

if [ -z "$POD_NAME" ]; then
	echo "Pod $POD not found in namespace $NAMESPACE"
	exit 1
fi

kubectl cp $LOCAL_FILE_PATH $NAMESPACE/$POD_NAME:$DIRECTORY
