terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=3.0.0, <4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0, <3.0.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "${path.module}/../infrastructure/configs/${data.terraform_remote_state.infrastructure.outputs.cluster_name}/kubeconfig"
}

provider "helm" {
  kubernetes = {
    config_path = "${path.module}/../infrastructure/configs/${data.terraform_remote_state.infrastructure.outputs.cluster_name}/kubeconfig"
  }
}
