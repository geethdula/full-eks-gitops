#!/bin/bash

# Script to apply all Kubernetes manifests in the service directories
# This will apply the updated manifests with topology spread constraints

echo "Applying all Kubernetes manifests..."

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

# Apply service account first
if [ -f "serviceaccount.yaml" ]; then
  echo "Applying service account..."
  kubectl apply -f serviceaccount.yaml
fi

# Process each directory
for dir in "${DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "Processing $dir directory..."
    
    # Apply all YAML files in the directory
    for file in "$dir"/*.yaml; do
      if [ -f "$file" ]; then
        echo "  Applying $file"
        kubectl apply -f "$file"
      fi
    done
  else
    echo "Directory $dir not found, skipping"
  fi
done

echo "All manifests have been applied"
echo "Checking pod distribution across nodes:"
sleep 10  # Give some time for pods to start scheduling
kubectl get pods -o wide | grep -v "NAME" | awk '{print $8}' | sort | uniq -c
