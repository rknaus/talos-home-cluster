# Talos Home Cluster Runtime Configuration

## Overview

This module configures the runtime parts of the talos cluster, which are required for a fully
operational base cluster.

## Requirements

The local kubeconfig needs to have the desired kubernetes cluster as the active context for the
following command to be executed by terraform:

```bash
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true \
  | grep '<none>' \
  | awk '{print "-n "$1" "$2}' \
  | xargs -L 1 -r kubectl delete pod
```

## Applying the Runtime configuration

```bash
terraform init -backend-config=configs/k8s.local.tfbackend -reconfigure -upgrade
terraform plan -var-file=configs/k8s.local.tfvars -out=tfplan
terraform apply "tfplan"
```

## Install Result


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
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >=3.0.0, <4.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.0, <3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.37.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cilium](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.cilium_base_network_policy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.cilium_l2_annoncement_policy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.cilium_lb_pool](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [null_resource.delete_unmanaged_pods](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [terraform_remote_state.infrastructure](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd_chart_version"></a> [argocd\_chart\_version](#input\_argocd\_chart\_version) | Version of the ArgoCD Helm Chart | `string` | `"8.1.2"` | no |
| <a name="input_cilium_chart_version"></a> [cilium\_chart\_version](#input\_cilium\_chart\_version) | Version of the Cilium Helm Chart | `string` | `"1.17.5"` | no |
| <a name="input_cilium_lb_pool"></a> [cilium\_lb\_pool](#input\_cilium\_lb\_pool) | n/a | <pre>list(object({<br/>    cidr = string<br/>  }))</pre> | n/a | yes |
| <a name="input_cilium_policy_enforcement_mode"></a> [cilium\_policy\_enforcement\_mode](#input\_cilium\_policy\_enforcement\_mode) | The Cilium Policy enforcement mode | `string` | `"always"` | no |
| <a name="input_infrastructure_remote_state"></a> [infrastructure\_remote\_state](#input\_infrastructure\_remote\_state) | Path to the remote state file of the infrastructure module. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

[back to main README.md](../README.md)
