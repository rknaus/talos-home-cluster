variable "infrastructure_remote_state" {
  type        = string
  description = "Path to the remote state file of the infrastructure module."
}

variable "cilium_crd_config" {
  type = object({
    enabled   = bool
    version   = optional(string, "1.17.5")
    base_path = optional(string, "crds/cilium/")
  })
  default = {
    enabled = true
  }
  description = "Enable Cilium CRDs (Required for Cilium Network Policies in Runtime Module)"
}

variable "argocd_crd_config" {
  type = object({
    enabled   = bool
    version   = optional(string, "3.0.6")
    base_path = optional(string, "crds/argocd/")
  })
  default = {
    enabled = true
  }
  description = "Enable argocd CRDs (Required for ArgoCD CustomResources in Runtime Module)"
}
