#!/bin/bash

# Script to update all deployments to have 2 replicas and redeploy them
# This script will also ensure topology spread constraints are applied

echo "Updating and redeploying all deployments with 2 replicas..."

# Get all deployments in the default namespace
DEPLOYMENTS=$(kubectl get deployments -o jsonpath='{.items[*].metadata.name}')

for DEPLOYMENT in $DEPLOYMENTS; do
  echo "Processing deployment: $DEPLOYMENT"
  
  # Get the opentelemetry.io/name label value
  NAME=$(kubectl get deployment $DEPLOYMENT -o jsonpath='{.spec.template.metadata.labels.opentelemetry\.io/name}')
  
  if [ -z "$NAME" ]; then
    echo "  No opentelemetry.io/name label found, using deployment name"
    NAME=$DEPLOYMENT
  fi
  
  echo "  Updating $DEPLOYMENT to 2 replicas with topology spread constraints"
  
  # Create a patch file with both replicas and topology spread constraints
  cat > /tmp/patch.yaml << EOF
spec:
  replicas: 2
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            opentelemetry.io/name: $NAME
EOF
  
  # Apply the patch
  kubectl patch deployment $DEPLOYMENT --patch "$(cat /tmp/patch.yaml)"
  
  echo "  Restarting deployment: $DEPLOYMENT"
  kubectl rollout restart deployment/$DEPLOYMENT
  
  echo "  Deployment $DEPLOYMENT updated and restarted"
done

echo "Done updating and redeploying all deployments"
echo "Waiting for rollouts to complete..."

# Wait for all deployments to be ready
for DEPLOYMENT in $DEPLOYMENTS; do
  echo "Waiting for deployment $DEPLOYMENT to be ready..."
  kubectl rollout status deployment/$DEPLOYMENT --timeout=300s
  if [ $? -eq 0 ]; then
    echo "  Deployment $DEPLOYMENT is ready"
  else
    echo "  WARNING: Deployment $DEPLOYMENT may not be fully ready"
  fi
done

echo "All deployments have been updated and redeployed"
echo "Checking pod distribution across nodes:"
kubectl get pods -o wide | grep -v "NAME" | awk '{print $8}' | sort | uniq -c
