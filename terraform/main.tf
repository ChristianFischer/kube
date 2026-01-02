# store the state in the cluster itself,
# so it will still be available when this devcontainer is destroyed
terraform {
  backend "kubernetes" {
    secret_suffix = "state"
    config_path   = "~/.kube/config"
    namespace     = "terraform-state"
  }
}
