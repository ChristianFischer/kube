resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    file("${local.path_helm_values}/cert-manager-values.yaml")
  ]
}

resource "kubernetes_manifest" "self-signed-cert" {
  for_each = {
    for m in provider::kubernetes::manifest_decode_multi(
      file("${local.path_manifests}/clusterissuer/rpcloud-selfsigned.yml")
    ) : m.metadata.name => m
  }
  manifest = each.value
  depends_on = [helm_release.cert-manager]
}

