#!/bin/sh
NAMESPACE=$1
PODS=$(kubectl get pods -n $NAMESPACE -o name)

for POD in $PODS; do
	echo "Logs for $POD"
	kubectl logs $POD -n $NAMESPACE
done
