# Pod Distribution Balancing with Topology Spread Constraints

This directory contains Kubernetes manifests for the OpenTelemetry demo application with added topology spread constraints to ensure even pod distribution across nodes.

## What are Topology Spread Constraints?

Topology Spread Constraints are a Kubernetes feature that allows you to control how pods are spread across your cluster among failure-domains such as regions, zones, nodes, and other user-defined topology domains.

## How it Works

The topology spread constraints have been added to deployment manifests with the following configuration:

```yaml
topologySpreadConstraints:
- maxSkew: 1              # Maximum difference in number of pods between nodes
  topologyKey: kubernetes.io/hostname  # Spread across nodes
  whenUnsatisfiable: ScheduleAnyway   # Still schedule if constraint can't be met perfectly
  labelSelector:
    matchLabels:
      opentelemetry.io/name: <service-name>  # Match pods with this label
```

This configuration ensures:
- Pods are distributed evenly across nodes (maxSkew: 1)
- If perfect distribution isn't possible, pods will still be scheduled (whenUnsatisfiable: ScheduleAnyway)
- The constraint applies to pods with the same opentelemetry.io/name label

## Updating Existing Deployments

To add topology spread constraints to all deployments, run:

```bash
./update-deployments.sh
```

This script will automatically add the appropriate constraints to all deployment files in the service directories.

## Applying the Changes

After updating the deployment files, apply them to your cluster:

```bash
kubectl apply -f <service-directory>/deploy.yaml
```

Or to apply all changes at once:

```bash
kubectl apply -f complete-deploy.yaml
```

## Verifying Pod Distribution

To check if pods are evenly distributed across nodes:

```bash
kubectl get pods -o wide | grep -v "NAME" | awk '{print $8}' | sort | uniq -c
```

This command will show the count of pods on each node.

## Benefits

- Prevents pod scheduling imbalance
- Improves resource utilization across nodes
- Enhances application resilience
- Reduces the risk of node overload
