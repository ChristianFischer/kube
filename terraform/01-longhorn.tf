resource "helm_release" "longhorn" {
  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  namespace        = "longhorn-system"
  create_namespace = true

  values = [
    file("${local.path_helm_values}/longhorn-values.yaml")
  ]

  wait          = true
  wait_for_jobs = true
}
