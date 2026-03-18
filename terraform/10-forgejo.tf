resource "helm_release" "forgejo" {
  name             = "forgejo"
  namespace        = "forgejo"
  repository       = "oci://code.forgejo.org/forgejo-helm/"
  chart            = "forgejo"
  version          = "16.2.1"
  create_namespace = true

  values = [
    file("${local.path_helm_values}/forgejo-values.yaml")
  ]

  depends_on = [
    helm_release.cert-manager,
    helm_release.longhorn,
  ]
}

data "kubernetes_service_v1" "forgejo-http" {
  metadata {
    name = "forgejo-http"
    namespace = "forgejo"
  }

  depends_on = [helm_release.forgejo]
}

resource "kubernetes_config_map_v1" "coredns-forgejo" {
  metadata {
    name      = "coredns-custom"
    namespace = "kube-system"
  }

  data = {
    "git-local.server" = <<EOF
git.local {
    hosts {
        ${data.kubernetes_service_v1.traefik.spec[0].cluster_ip} git.local
        fallthrough
    }
    whoami
}
EOF
  }
}

resource "kubernetes_manifest" "forgejo-ingress" {
  manifest = yamldecode(file("${local.path_manifests}/ingress/git.local.yml"))
  depends_on = [helm_release.forgejo]
}
