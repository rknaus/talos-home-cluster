# Talos Home Cluster

The following guide shows the steps to install talos k8s on my home lab. The setup described below
contains 3 master nodes and 4 worker nodes based on HP EliteDesk 800 G4 SFF PCs.

As a CNI I decided to use cilium. After the initial configuration I use ArgoCD to manage the
configuration on the cluster. The ArgoCD repository is located separately on GitHub.

It is customized for my home environment and needs to get adjusted slightly when used in another
environment.

The guide assumes you run the installation on a mac.

If not, certain commands will not work (cilium cli installation and olm installation). Alternatives
can be found on the internet.

## Cluster Diagram

The following diagram gives a brief overview about the set up home lab cluster.

<img src="./cluster-diagram/kubernetes-environment.svg"/>

## Infrastructure installation

Talos base installation with Terraforn

```bash
cd infrastructure
```

and follow the instructions in the [README.md](infrastructure/README.md) of the infrastructure subfolder

## Auxiliary installation

CRD installation required for runtime components

```bash
cd auxiliary
```

and follow the instructions in the [README.md](auxiliary/README.md) of the auxiliary subfolder

## Runtime installation

Cilium installation and GitOps bootstrapping

```bash
cd runtime
```

and follow the instructions in the [README.md](runtime/README.md) of the runtime subfolder

# Day two ops tasks

## Talos Linux Upgrade

```bash
export CLUSTER_NAME=k8s.local
export API_ENDPOINT=https://api.${CLUSTER_NAME}:6443
export TALOS_VERSION=v1.9.0   # changeme
```

Upgrade node by node:

```bash
talosctl upgrade --nodes master0.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME} --image ghcr.io/siderolabs/installer:$TALOS_VERSION

talosctl upgrade --nodes master1.${CLUSTER_NAME} --endpoints master1.${CLUSTER_NAME} --image ghcr.io/siderolabs/installer:$TALOS_VERSION

talosctl upgrade --nodes master2.${CLUSTER_NAME} --endpoints master2.${CLUSTER_NAME} --image ghcr.io/siderolabs/installer:$TALOS_VERSION

kubectl drain worker0 --ignore-daemonsets
talosctl upgrade --nodes worker0.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME} --image ghcr.io/siderolabs/installer:$TALOS_VERSION
kubectl uncordon worker0

kubectl drain worker1 --ignore-daemonsets
talosctl upgrade --nodes worker1.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME} --image ghcr.io/siderolabs/installer:$TALOS_VERSION
kubectl uncordon worker1

kubectl drain worker2 --ignore-daemonsets
talosctl upgrade --nodes worker2.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME} --image ghcr.io/siderolabs/installer:$TALOS_VERSION
kubectl uncordon worker2

kubectl drain worker3 --ignore-daemonsets
talosctl upgrade --nodes worker3.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME} --image ghcr.io/siderolabs/installer:$TALOS_VERSION
kubectl uncordon worker3

brew upgrade talosctl
```

## Kubernetes Upgrade

```bash
talosctl upgrade-k8s --nodes master0.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME}
```

# Get the kubeconfig

## via talosctl

Define general variables:

```bash
export CLUSTER_NAME=k8s.local
export API_ENDPOINT=https://api.${CLUSTER_NAME}:6443
```

Retreive the kubeconfig

```bash
talosctl kubeconfig \
  --nodes master0.${CLUSTER_NAME} \
  --endpoints master0.${CLUSTER_NAME} \
  --talosconfig=./talosconfig
```

## via Terraform generated files

Terraform in the infrastructure folder generates a talosconfig and kubeconfig file in the `configs/${CLUSTER_NAME}/` folder.

# Talos Command Examples

## Shutdown the cluster to save energy

.. in reverse order to keep master0 until the end.

```bash
export CLUSTER_NAME=k8s.local
export NODE_TYPE=worker
for i in {3..0}
do
  talosctl shutdown --force --nodes ${NODE_TYPE}${i}.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME}
done
```

```bash
export NODE_TYPE=master
for i in {2..0}
do
  talosctl shutdown --force --nodes ${NODE_TYPE}${i}.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME}
done
```

## Update the Node Configuration (example the DNS configuration)

To update the DNS server configuration on tge existing Talos cluster, you'll need to modify the machine configuration for each node:

```bash
export CLUSTER_NAME=k8s.local
export NODE_TYPE=master
for i in {0..2}
do
  talosctl patch machineconfig -p '[{"op": "replace", "path": "/machine/network/nameservers/0", "value": "192.168.0.253"}]' --nodes ${NODE_TYPE}${i}.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME}
done
```

Apply the worker node configuration to the master nodes:

```bash
export NODE_TYPE=worker
for i in {0..3}
do
  talosctl patch machineconfig -p '[{"op": "replace", "path": "/machine/network/nameservers/0", "value": "192.168.0.253"}]' --nodes ${NODE_TYPE}${i}.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME}
done
```

Validate the configuration:

```bash
export NODE_TYPE=master
for i in {0..2}
do
  talosctl get resolvers --nodes ${NODE_TYPE}${i}.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME}
done
```

Apply the worker node configuration to the master nodes:

```bash
export NODE_TYPE=worker
for i in {0..3}
do
  talosctl get resolvers --nodes ${NODE_TYPE}${i}.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME}
done
```

### Alternative to edit the machineconfig

```bash
talosctl edit machineconfig --nodes master0.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME}
```
