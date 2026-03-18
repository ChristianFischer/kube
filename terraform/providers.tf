terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }

  required_version = ">= 1.14.0"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

data "kubernetes_service_v1" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "kube-system"
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
