# Talos Home Cluster Bootstrapping and Config

## Overview

This module bootstraps a talos cluster on baremetal.

## Requirements

The following prerequisites must be met before starting.

1. Install the following binaries:

    - terraform
    - terraform-docs

1. Make sure the defined variables under `configs/<CLUSTER>/<CLUSTER>.tfbackend` and
`configs/<CLUSTER>/<CLUSTER>.tfvars` are correct. Also check the talos-patches folder.

1. Reserve DNS entry for each node and for the api. In my case the dns entries are as following:
    - api.k8s.local => 192.168.0.200
    - master0.k8s.local => 192.168.0.201
    - master1.k8s.local => 192.168.0.202
    - master2.k8s.local => 192.168.0.203
    - worker0.k8s.local => 192.168.0.204
    - worker1.k8s.local => 192.168.0.205
    - worker2.k8s.local => 192.168.0.206
    - worker3.k8s.local => 192.168.0.207

1. For easier management during initial boot, make a dhcp reservation for each node with the IP
address and its MAC address.

1. Download Talos from the releases GitHub page
([github.com/siderolabs/talos/releases](https://github.com/siderolabs/talos/releases/)) and flash
the iso to a memory stick with a tool like balenaEtcher.

1. Boot all nodes from the memory stick.

## Talos base installation

Deploy the talos cluster using the specified or a custom backend and variables:

```bash
terraform init -backend-config=configs/k8s.local.tfbackend -reconfigure -upgrade
terraform plan -var-file=configs/k8s.local.tfvars -out=tfplan
terraform apply "tfplan"
```

## Setting the config files

To save the kubeconfig and the talos config file in your local home directory, execute the
following:

```bash
export KUBECONFIG=~/.kube/config:configs/k8s.local/kubeconfig
kubectl config view --flatten > ~/.kube/config
cp configs/k8s.local/talosconfig ~/.talos/config
```

## Install Result

The nodes should be visible now, but in `NotReady` state:

```bash
% kubectl get nodes
NAME      STATUS     ROLES           AGE     VERSION
master0   NotReady   control-plane   3m41s   v1.32.3
master1   NotReady   control-plane   3m13s   v1.32.3
master2   NotReady   control-plane   3m42s   v1.32.3
worker0   NotReady   <none>          3m54s   v1.32.3
worker1   NotReady   <none>          3m54s   v1.32.3
worker2   NotReady   <none>          3m53s   v1.32.3
worker3   NotReady   <none>          3m53s   v1.32.3
```

## Terraform Docs

```bash
# Use terraform-docs to update this README.md
terraform-docs markdown table --output-file README.md --output-mode inject .
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | >=0.8.0, <0.99.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.3 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.8.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_sensitive_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [local_sensitive_file.talosconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_secrets) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/client_configuration) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gateway"></a> [gateway](#input\_gateway) | IPv4 Gateway for the talos cluster | `string` | n/a | yes |
| <a name="input_nameservers"></a> [nameservers](#input\_nameservers) | List of Nameservers for the talos cluster | `list(string)` | n/a | yes |
| <a name="input_talos_api_endpoint"></a> [talos\_api\_endpoint](#input\_talos\_api\_endpoint) | Talos API Endpoint<br/>    leave empty to use https://api.${talos_cluster_name}:6443" | `string` | `""` | no |
| <a name="input_talos_cluster_name"></a> [talos\_cluster\_name](#input\_talos\_cluster\_name) | Talos Cluster name<br/>    It is recommended to use a name like cluster.domain | `string` | n/a | yes |
| <a name="input_talos_cluster_vip"></a> [talos\_cluster\_vip](#input\_talos\_cluster\_vip) | VIP of the Talos control plane | `string` | n/a | yes |
| <a name="input_talos_master_nodes"></a> [talos\_master\_nodes](#input\_talos\_master\_nodes) | Talos nodes variable object | <pre>list(<br/>    object({<br/>      hostname              = string,<br/>      interface             = string,<br/>      address               = string,<br/>      install_disk_selector = string,<br/>    })<br/>  )</pre> | n/a | yes |
| <a name="input_talos_version"></a> [talos\_version](#input\_talos\_version) | Talos Version to use | `string` | n/a | yes |
| <a name="input_talos_worker_nodes"></a> [talos\_worker\_nodes](#input\_talos\_worker\_nodes) | Talos nodes variable object | <pre>list(<br/>    object({<br/>      hostname              = string,<br/>      interface             = string,<br/>      address               = string,<br/>      install_disk_selector = string,<br/>    })<br/>  )</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cluster name |
| <a name="output_path_to_kubeconfig_file"></a> [path\_to\_kubeconfig\_file](#output\_path\_to\_kubeconfig\_file) | Path to the kubeconfig of the Talos Linux cluster |
| <a name="output_path_to_talosconfig_file"></a> [path\_to\_talosconfig\_file](#output\_path\_to\_talosconfig\_file) | Path to the talosconfig of the Talos Linux cluster |
<!-- END_TF_DOCS -->

[back to main README.md](../README.md)
