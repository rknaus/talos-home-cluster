# contains declarations of variables used in main.tf

variable "talos_version" {
  type        = string
  description = "Talos Version to use"
}

variable "talos_cluster_name" {
  type        = string
  description = <<EOF
    Talos Cluster name
    It is recommended to use a name like cluster.domain
  EOF
}

variable "talos_api_endpoint" {
  type        = string
  description = <<EOF
    Talos API Endpoint
    leave empty to use https://api.$\{talos_cluster_name\}:6443"
  EOF
  default     = ""
}

variable "talos_cluster_vip" {
  type        = string
  description = "VIP of the Talos control plane"
}

variable "gateway" {
  type        = string
  description = "IPv4 Gateway for the talos cluster"
}

variable "nameservers" {
  type        = list(string)
  description = "List of Nameservers for the talos cluster"
}

variable "talos_master_nodes" {
  type = list(
    object({
      hostname              = string,
      interface             = string,
      address               = string,
      install_disk_selector = string,
    })
  )
  description = "Talos nodes variable object"
}

variable "talos_worker_nodes" {
  type = list(
    object({
      hostname              = string,
      interface             = string,
      address               = string,
      install_disk_selector = string,
    })
  )
  description = "Talos nodes variable object"
}
