locals {
  path_to_workspace_dir    = "${abspath(path.root)}/configs/${var.talos_cluster_name}"
  path_to_kubeconfig_file  = "${local.path_to_workspace_dir}/kubeconfig"
  path_to_talosconfig_file = "${local.path_to_workspace_dir}/talosconfig"
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

resource "talos_machine_configuration_apply" "controlplane" {
  count = length(var.talos_master_nodes)

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = "${var.talos_master_nodes[count.index].hostname}.${var.talos_cluster_name}"
  config_patches = [
    templatefile("${path.module}/talos-patches/network.tpl", {
      hostname    = "${var.talos_master_nodes[count.index].hostname}.${var.talos_cluster_name}",
      interface   = var.talos_master_nodes[count.index].interface,
      address     = var.talos_master_nodes[count.index].address,
      gateway     = var.gateway,
      nameservers = indent(6, yamlencode(var.nameservers)),
    }),
    templatefile("${path.module}/talos-patches/cluster-name.tpl", {
      talos_cluster_name = var.talos_cluster_name,
    }),
    templatefile("${path.module}/talos-patches/cni.tpl", {}),
    templatefile("${path.module}/talos-patches/install-params.tpl", {
      talos_version               = var.talos_version
      talos_install_disk_selector = var.talos_master_nodes[count.index].install_disk_selector,
    }),
    templatefile("${path.module}/talos-patches/vip.tpl", {
      interface         = var.talos_master_nodes[count.index].interface,
      talos_cluster_vip = var.talos_cluster_vip,
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  count = length(var.talos_worker_nodes)

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = "${var.talos_worker_nodes[count.index].hostname}.${var.talos_cluster_name}"
  config_patches = [
    templatefile("${path.module}/talos-patches/network.tpl", {
      hostname    = "${var.talos_worker_nodes[count.index].hostname}.${var.talos_cluster_name}",
      interface   = var.talos_worker_nodes[count.index].interface,
      address     = var.talos_worker_nodes[count.index].address,
      gateway     = var.gateway,
      nameservers = indent(6, yamlencode(var.nameservers)),
    }),
    templatefile("${path.module}/talos-patches/cluster-name.tpl", {
      talos_cluster_name = var.talos_cluster_name,
    }),
    templatefile("${path.module}/talos-patches/cni.tpl", {}),
    templatefile("${path.module}/talos-patches/install-params.tpl", {
      talos_version               = var.talos_version
      talos_install_disk_selector = var.talos_worker_nodes[count.index].install_disk_selector,
    }),
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]

  node                 = "${var.talos_master_nodes[0].hostname}.${var.talos_cluster_name}"
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "local_sensitive_file" "talosconfig" {
  content         = nonsensitive(data.talos_client_configuration.this.talos_config)
  filename        = local.path_to_talosconfig_file
  file_permission = "0600"
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  node                 = "${var.talos_master_nodes[0].hostname}.${var.talos_cluster_name}"
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "local_sensitive_file" "kubeconfig" {
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename        = local.path_to_kubeconfig_file
  file_permission = "0600"
  lifecycle {
    ignore_changes = [content]
  }
}

