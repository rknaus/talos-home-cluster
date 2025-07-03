infrastructure_remote_state    = "../.terraform/state/k8s.local/infrastructure.tfstate"
cilium_chart_version           = "1.17.5"
cilium_policy_enforcement_mode = "default"
cilium_lb_pool = [{
  cidr = "192.168.0.208/28"
}]
argocd_chart_version = "8.1.2" # App Version 3.0.6
