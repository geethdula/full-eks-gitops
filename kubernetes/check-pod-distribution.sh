#!/bin/bash

# Script to check pod distribution across nodes
# This helps verify that topology spread constraints are working

echo "Checking pod distribution across nodes..."

# Get the count of pods per node
echo "Pod count per node:"
kubectl get pods -o wide | grep -v "NAME" | awk '{print $8}' | sort | uniq -c

# Get detailed pod distribution by deployment
echo -e "\nPod distribution by deployment:"
kubectl get pods -o wide | grep -v "NAME" | awk '{print $1, $8}' | sort | awk -F'-' '{print $1"-"$2"-"$3, $NF}' | sort | uniq -c

echo -e "\nNode resource usage:"
kubectl top nodes

echo -e "\nPod resource usage (top 10):"
kubectl top pods | sort -k3 -nr | head -10
