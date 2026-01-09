resource "helm_release" "nextcloud" {
  name             = "nextcloud"
  repository       = "https://nextcloud.github.io/helm/"
  chart            = "nextcloud"
  namespace        = "nextcloud"
  create_namespace = true

  values = [
    file("${local.path_helm_values}/nextcloud-values.yaml")
  ]

  depends_on = [
    helm_release.cert-manager,
    helm_release.longhorn,
  ]
}

resource "kubernetes_manifest" "nextcloud-ingress" {
  manifest = yamldecode(file("${local.path_manifests}/ingress/nextcloud.local.yml"))
  depends_on = [helm_release.nextcloud]
}
