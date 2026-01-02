resource "helm_release" "gitea" {
  name             = "gitea"
  repository       = "https://dl.gitea.com/charts/"
  chart            = "gitea"
  namespace        = "gitea"
  create_namespace = true

  values = [
    file("${local.path_helm_values}/gitea-values.yaml")
  ]

  depends_on = [
    helm_release.cert-manager,
    helm_release.longhorn,
  ]
}

resource "kubernetes_manifest" "gitea-ingress" {
  manifest = yamldecode(file("${local.path_manifests}/ingress/gitea.local.yml"))
  depends_on = [helm_release.gitea]
}
