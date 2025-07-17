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
      name  = "devices"
      value = "eno1"
    }
  ]
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

resource "kubernetes_manifest" "argocd_app_of_apps_project" {
  manifest = {
    "apiVersion" : "argoproj.io/v1alpha1",
    "kind" : "AppProject",
    "metadata" : {
      "name" : "app-of-apps",
      "namespace" : "argocd",
    },
    "spec" : {
      "clusterResourceWhitelist" : [
        {
          "group" : "*",
          "kind" : "*"
        }
      ],
      "destinations" : [
        {
          "name" : "in-cluster",
          "namespace" : "*",
          "server" : "https://kubernetes.default.svc"
        }
      ],
      "sourceRepos" : [
        "https://github.com/rknaus/argocd-gitops"
      ]
    }
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "argocd_app_of_apps" {
  manifest = {
    "apiVersion" : "argoproj.io/v1alpha1",
    "kind" : "Application",
    "metadata" : {
      "name" : "app-of-apps",
      "namespace" : "argocd",
    },
    "spec" : {
      "destination" : {
        "name" : "in-cluster",
        "namespace" : "argocd"
      },
      "project" : "app-of-apps",
      "source" : {
        "path" : "argocd-apps",
        "repoURL" : "https://github.com/rknaus/argocd-gitops",
        "targetRevision" : "HEAD"
      },
      "syncPolicy" : {
        "automated" : {
          "prune" : true,
          "selfHeal" : true
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.argocd_app_of_apps_project]
}
