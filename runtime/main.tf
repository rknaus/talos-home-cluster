resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = var.cilium_chart_version

  values = [
    "${file("${path.module}/helm-values/cilium.yaml")}"
  ]

  set = [
    {
      name  = "policyEnforcementMode"
      value = var.cilium_policy_enforcement_mode
    },
    {
      name  = "devices"
      value = "eno1"
    }
  ]
}

resource "kubernetes_manifest" "cilium_base_network_policy" {
  for_each = lower(var.cilium_policy_enforcement_mode) == "always" ? fileset("${path.module}/cilium-base-policies", "*.yaml") : []

  manifest = yamldecode(file("${path.module}/cilium-base-policies/${each.value}"))
}

resource "kubernetes_manifest" "cilium_lb_pool" {
  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumLoadBalancerIPPool"
    metadata = {
      name = "lb-pool-01"
    }
    spec = {
      blocks = var.cilium_lb_pool
    }
  }
}

resource "kubernetes_manifest" "cilium_l2_annoncement_policy" {
  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumL2AnnouncementPolicy"
    metadata = {
      name = "basic-policy"
    }
    spec = {
      interfaces : [
        "eno1"
      ]
      externalIPs     = "true"
      loadBalancerIPs = "true"
    }
  }
}

resource "null_resource" "delete_unmanaged_pods" {
  provisioner "local-exec" {
    command = <<EOT
    kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true \
      | grep '<none>' \
      | awk '{print "-n "$1" "$2}' \
      | xargs -L 1 -r kubectl delete pod
    EOT
  }

  depends_on = [helm_release.cilium]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  create_namespace = true

  values = [
    "${file("${path.module}/helm-values/argocd.yaml")}"
  ]

  set = [
    {
      name  = "server.ingress.hostname"
      value = "argocd.${data.terraform_remote_state.infrastructure.outputs.cluster_name}"
    }
  ]
}
