#!/bin/bash

# Script to apply topology spread constraints to existing deployments
# This will update the deployments without recreating pods

echo "Applying topology spread constraints to existing deployments..."

# Get all deployments in the default namespace
DEPLOYMENTS=$(kubectl get deployments -o jsonpath='{.items[*].metadata.name}')

for DEPLOYMENT in $DEPLOYMENTS; do
  echo "Processing deployment: $DEPLOYMENT"
  
  # Get the opentelemetry.io/name label value
  NAME=$(kubectl get deployment $DEPLOYMENT -o jsonpath='{.spec.template.metadata.labels.opentelemetry\.io/name}')
  
  if [ -z "$NAME" ]; then
    echo "  No opentelemetry.io/name label found, skipping"
    continue
  fi
  
  echo "  Adding topology spread constraints for $NAME"
  
  # Create a patch file
  cat > /tmp/patch.yaml << EOF
spec:
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
  
  echo "  Constraints applied to $DEPLOYMENT"
done

echo "Done applying topology spread constraints"
echo "Note: Existing pods will not be rescheduled automatically."
echo "To force rescheduling, you can perform a rolling restart:"
echo "kubectl rollout restart deployment/<deployment-name>"
