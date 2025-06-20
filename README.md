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

## Talos base installation with Terraforn

```bash
cd terraform-talos
```
and follow the instructions in the README of the subfolder

## Cilium installation

Before the cilium installation the cluster is not ready to be used. So let's go through the setup.

Get the latest stable cilium CLI version and download/install it:

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "arm64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-darwin-${CLI_ARCH}.tar.gz{,.sha256sum}
shasum -a 256 -c cilium-darwin-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-darwin-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-darwin-${CLI_ARCH}.tar.gz{,.sha256sum}
```

Install cilium Helm chart on the cluster:

```bash
helm repo add cilium https://helm.cilium.io/

CILIUM_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium/main/stable.txt)
helm upgrade -i cilium cilium/cilium --version ${CILIUM_VERSION} \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set=kubeProxyReplacement=true \
  --set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set=cgroup.autoMount.enabled=false \
  --set=cgroup.hostRoot=/sys/fs/cgroup \
  --set=k8sServiceHost=localhost \
  --set=k8sServicePort=7445 \
  --set ingressController.enabled=true \
  --set ingressController.default=true \
  --set l2announcements.enabled=true \
  --set externalIPs.enabled=true \
  --set devices=eno1 \
  --set k8sClientRateLimit.qps=32 \
  --set k8sClientRateLimit.burst=48 \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true
```

Validate the installation:

```bash
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod

cilium status --wait
```

### Cilium LoadBalancer IP Pool

```bash
cat <<EOF | kubectl apply -f -
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: lb-pool-01
spec:
  blocks:
  - cidr: 192.168.0.208/28
EOF

# Validation

kubectl get ciliumloadbalancerippool.cilium.io

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: service-red
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - port: 1234
EOF

kubectl delete svc service-red

```

### Cilium L2 Announcement Policy

```bash
cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: basic-policy
spec:
  interfaces:
  - eno1
  externalIPs: true
  loadBalancerIPs: true
EOF

# Validation

kubectl get ciliuml2announcementPolicy.cilium.io

```

### Cilium Doc how to set a single IP for the default-ingress

https://mkz.me/weblog/posts/cilium-enable-ingress-controller/


## OLM Installation

```bash
brew install operator-sdk
operator-sdk olm install

# Validation
kubectl get ns
kubectl get pods -n olm
```

## ArgoCD installation

```bash
kubectl create namespace argocd

git clone https://github.com/argoproj-labs/argocd-operator.git
cd argocd-operator

# Install Operator Catalog
kubectl create -n olm -f deploy/catalog_source.yaml

# Validation
kubectl get catalogsources -n olm
kubectl get pods -n olm -l olm.catalogSource=argocd-catalog

# Install Operator Group
kubectl create -n argocd -f deploy/operator_group.yaml

# Validation
kubectl get operatorgroups -n argocd

# Install Subscription
kubectl create -n argocd -f deploy/subscription.yaml

# Validation
kubectl get subscriptions -n argocd
kubectl get installplans -n argocd
kubectl get pods -n argocd

cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1beta1
kind: ArgoCD
metadata:
  name: argocd
  namespace: argocd
spec:
  server:
    host: argocd.k8s.local
    service:
      type: LoadBalancer
EOF

kubectl -n argocd get secret argocd-cluster -o jsonpath="{.data.admin\.password}" | base64 -d

```

# Talos Linux Upgrade

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

# Kubernetes Upgrade

```bash
talosctl upgrade-k8s --nodes master0.${CLUSTER_NAME} --endpoints master0.${CLUSTER_NAME}
```

# Cilium Upgrade

```bash
helm repo update cilium

CILIUM_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium/main/stable.txt)
helm upgrade cilium cilium/cilium --version ${CILIUM_VERSION} \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set=kubeProxyReplacement=true \
  --set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set=cgroup.autoMount.enabled=false \
  --set=cgroup.hostRoot=/sys/fs/cgroup \
  --set=k8sServiceHost=localhost \
  --set=k8sServicePort=7445 \
  --set ingressController.enabled=true \
  --set ingressController.default=true \
  --set l2announcements.enabled=true \
  --set externalIPs.enabled=true \
  --set devices=eno1 \
  --set k8sClientRateLimit.qps=32 \
  --set k8sClientRateLimit.burst=48 \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

cilium status --wait
```

# Get the kubeconfig via talosctl

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

[back to main README.md](../README.md)

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
