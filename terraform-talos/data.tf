locals {
  talos_api_endpoint = coalesce(var.talos_api_endpoint, "https://api.${var.talos_cluster_name}:6443")
}

data "talos_client_configuration" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  cluster_name         = var.talos_cluster_name
  endpoints = concat([var.talos_cluster_vip], [
    for i in var.talos_master_nodes : split("/", i.address)[0]
  ])
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.talos_cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = local.talos_api_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.talos_cluster_name
  machine_type     = "worker"
  cluster_endpoint = local.talos_api_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}
