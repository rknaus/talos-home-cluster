output "cluster_name" {
  description = "Cluster name"
  value       = var.talos_cluster_name
}

output "path_to_kubeconfig_file" {
  description = "Path to the kubeconfig of the Talos Linux cluster"
  value       = local.path_to_kubeconfig_file
}

output "path_to_talosconfig_file" {
  description = "Path to the talosconfig of the Talos Linux cluster"
  value       = local.path_to_talosconfig_file
}
