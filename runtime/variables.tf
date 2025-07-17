variable "infrastructure_remote_state" {
  type        = string
  description = "Path to the remote state file of the infrastructure module."
}

variable "cilium_chart_version" {
  type        = string
  description = "Version of the Cilium Helm Chart"
  default     = "1.17.5"
}

variable "cilium_lb_pool" {
  type = list(object({
    cidr = string
  }))
}

variable "argocd_chart_version" {
  type        = string
  description = "Version of the ArgoCD Helm Chart"
  default     = "8.1.2"
}
