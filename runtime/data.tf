data "terraform_remote_state" "infrastructure" {
  backend = "local"

  config = {
    path = var.infrastructure_remote_state
  }
}
