resource "helm_release" "kubernetes-dashboard" {
  name             = "kubernetes-dashboard"
  repository       = "https://kubernetes.github.io/dashboard/"
  chart            = "kubernetes-dashboard"
  namespace        = "kubernetes-dashboard"
  create_namespace = true

  values = [
    file("${local.path_helm_values}/kubernetes-dashboard-values.yaml")
  ]

  # disable metrics server for k3s
  set {
    name  = "metrics-server.enabled"
    value = "false"
  }
}


resource "kubernetes_manifest" "kubernetes-dashboard-admin-user" {
  manifest = yamldecode(file("${local.path_manifests}/auth/dashboard-admin-user.yml"))
  depends_on = [helm_release.kubernetes-dashboard]
}


resource "kubernetes_manifest" "kubernetes-dashboard-admin-user-role-binding" {
  manifest = yamldecode(file("${local.path_manifests}/auth/dashboard-admin-user-role-binding.yml"))
  depends_on = [kubernetes_manifest.kubernetes-dashboard-admin-user]
}


resource "kubernetes_manifest" "kubernetes-dashboard-ingress-route" {
  manifest = yamldecode(file("${local.path_manifests}/ingress/kubernetes-dashboard.local.yml"))
  depends_on = [helm_release.kubernetes-dashboard]
}


resource "kubernetes_secret_v1" "kubernetes-dashboard-admin-token" {
  metadata {
    name      = "admin-user"
    namespace = "kubernetes-dashboard"
    annotations = {
      "kubernetes.io/service-account.name" = "admin-user"
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_manifest.kubernetes-dashboard-admin-user]
}


output "kubernetes-dashboard-admin-token" {
  value = kubernetes_secret_v1.kubernetes-dashboard-admin-token.data["token"]
  sensitive = true
}

