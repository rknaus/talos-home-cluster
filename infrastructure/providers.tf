terraform {
  required_version = ">= 1.0"
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.8.0, <0.99.0"
    }
  }
}

provider "talos" {
  # Configuration options
}
