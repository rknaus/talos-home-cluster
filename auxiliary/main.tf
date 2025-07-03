resource "kubernetes_manifest" "cilium_crds" {
  for_each = var.cilium_crd_config.enabled ? fileset("${path.module}/${var.cilium_crd_config.base_path}/${var.cilium_crd_config.version}/", "*.yaml") : []

  manifest = yamldecode(file("${path.module}/${var.cilium_crd_config.base_path}/${var.cilium_crd_config.version}/${each.value}"))

  field_manager {
    # Force changes agains conflicts. Required that existing CRDs can be imported.
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "argocd_crds" {
  for_each = var.argocd_crd_config.enabled ? fileset("${path.module}/${var.argocd_crd_config.base_path}/${var.argocd_crd_config.version}/", "*.yaml") : []

  manifest = yamldecode(file("${path.module}/${var.argocd_crd_config.base_path}/${var.argocd_crd_config.version}/${each.value}"))

  field_manager {
    # Force changes agains conflicts. Required that existing CRDs can be imported.
    force_conflicts = true
  }
}

