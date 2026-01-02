resource "helm_release" "flannel" {
  name             = "flannel"
  repository       = "https://flannel-io.github.io/flannel"
  chart            = "flannel"
  namespace        = "flannel"
  create_namespace = true

  values = [
    file("${var.path_helm_values}/flannel-values.yaml")
  ]
}
