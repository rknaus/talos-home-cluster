# Talos Home Cluster Auxiliary Configuration

## Overview

This module is required to install the used CRDs in the Runtime Module. Terraform otherwise can't
create the plan for non existing CRDs.

## Requirements

The CRDs for the desired Cilium Version are present in the crds/cilium/<version>/ folder.

To update the CRDs, run the following Script:

```bash
CILIUM_VERSION=<CHANGEME> # example: CILIUM_VERSION=1.17.5

mkdir -p crds/cilium/${CILIUM_VERSION}
cd crds/cilium/${CILIUM_VERSION}
curl https://raw.githubusercontent.com/cilium/cilium/refs/tags/v${CILIUM_VERSION}/pkg/k8s/apis/cilium.io/client/crds/v2/ciliumnetworkpolicies.yaml -o ciliumnetworkpolicies.yaml
curl https://raw.githubusercontent.com/cilium/cilium/refs/tags/v${CILIUM_VERSION}/pkg/k8s/apis/cilium.io/client/crds/v2/ciliumclusterwidenetworkpolicies.yaml -o ciliumclusterwidenetworkpolicies.yaml
curl https://raw.githubusercontent.com/cilium/cilium/refs/tags/v${CILIUM_VERSION}/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumloadbalancerippools.yaml -o ciliumloadbalancerippools.yaml
curl https://raw.githubusercontent.com/cilium/cilium/refs/tags/v${CILIUM_VERSION}/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliuml2announcementpolicies.yaml -o ciliuml2announcementpolicies.yaml

cd ../../../
```

The CRDs for the desired ArgoCD Version are present in the crds/argocd/<version>/ folder. Take the
app version and not the helm chart version.

To update the CRDs, run the following Script:

```bash
ARGOCD_VERSION=<CHANGEME> # example: ARGOCD_VERSION=3.0.6

mkdir -p crds/argocd/${ARGOCD_VERSION}
cd crds/argocd/${ARGOCD_VERSION}
curl https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v${ARGOCD_VERSION}/manifests/crds/application-crd.yaml -o application-crd.yaml
curl https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v${ARGOCD_VERSION}/manifests/crds/applicationset-crd.yaml -o applicationset-crd.yaml
curl https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v${ARGOCD_VERSION}/manifests/crds/appproject-crd.yaml -o appproject-crd.yaml

cd ../../../
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
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.37.1 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_manifest.argocd_crds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.cilium_crds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [terraform_remote_state.infrastructure](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd_crd_config"></a> [argocd\_crd\_config](#input\_argocd\_crd\_config) | Enable argocd CRDs (Required for ArgoCD CustomResources in Runtime Module) | <pre>object({<br/>    enabled   = bool<br/>    version   = optional(string, "3.0.6")<br/>    base_path = optional(string, "crds/argocd/")<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_cilium_crd_config"></a> [cilium\_crd\_config](#input\_cilium\_crd\_config) | Enable Cilium CRDs (Required for Cilium Network Policies in Runtime Module) | <pre>object({<br/>    enabled   = bool<br/>    version   = optional(string, "1.17.5")<br/>    base_path = optional(string, "crds/cilium/")<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_infrastructure_remote_state"></a> [infrastructure\_remote\_state](#input\_infrastructure\_remote\_state) | Path to the remote state file of the infrastructure module. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

[back to main README.md](../README.md)
