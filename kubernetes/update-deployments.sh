#!/bin/bash

# Script to add topology spread constraints to all deployments
# This ensures pods are evenly distributed across nodes

# Define directories to process
DIRS=(
  "accounting"
  "ad"
  "cart"
  "checkout"
  "currency"
  "email"
  "flagd"
  "frauddetection"
  "frontend"
  "frontendproxy"
  "imageprovider"
  "kafka"
  "loadgenerator"
  "payment"
  "productcatalog"
  "quote"
  "recommendation"
  "shipping"
  "valkey"
)

# Process each directory
for dir in "${DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "Processing $dir directory..."
    
    # Find deployment files
    for file in "$dir"/*.yaml; do
      if grep -q "kind: Deployment" "$file"; then
        echo "  Adding topology spread constraints to $file"
        
        # Get the component name from the file
        COMPONENT=$(grep -A5 "app.kubernetes.io/component:" "$file" | grep -v "app.kubernetes.io/component:" | head -1 | awk '{print $2}')
        
        # Get the opentelemetry.io/name from the file
        NAME=$(grep -A2 "opentelemetry.io/name:" "$file" | grep -v "opentelemetry.io/name:" | head -1 | awk '{print $2}')
        
        if [ -z "$NAME" ]; then
          echo "    Could not find opentelemetry.io/name in $file, skipping"
          continue
        fi
        
        # Add topology spread constraints after the spec: line
        sed -i '/spec:/,/serviceAccountName:/ {
          /serviceAccountName:/i\
      # Add topology spread constraints for even pod distribution across nodes\
      topologySpreadConstraints:\
      - maxSkew: 1              # Maximum difference in number of pods between nodes\
        topologyKey: kubernetes.io/hostname  # Spread across nodes\
        whenUnsatisfiable: ScheduleAnyway   # Still schedule if constraint can not be met perfectly\
        labelSelector:\
          matchLabels:\
            opentelemetry.io/name: '"$NAME"'
          ; :
        }' "$file"
        
        echo "    Added constraints for component: $COMPONENT with name: $NAME"
      fi
    done
  else
    echo "Directory $dir not found, skipping"
  fi
done

echo "Done adding topology spread constraints to all deployments"
