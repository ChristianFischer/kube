resource "null_resource" "forgejo-create-runner-init-config" {
  depends_on = [
    helm_release.forgejo,
    data.kubernetes_service_v1.forgejo-http,
  ]

  triggers = {
    secret_name = "forgejo-runner-init-config"
    namespace   = "forgejo"
  }

  provisioner "local-exec" {
    command = <<SCRIPT
      set -e

      if kubectl get secret forgejo-runner-init-config -n forgejo >/dev/null 2>&1; then
        echo "Secret forgejo-runner-init-config already exists, checking token..."
        EXISTING_TOKEN=$(kubectl get secret forgejo-runner-init-config -n forgejo -o jsonpath='{.data.CONFIG_TOKEN}' | base64 -d)
        if [ -n "$EXISTING_TOKEN" ]; then
          echo "Valid token found, skipping."
          exit 0
        fi
        echo "Token is empty, recreating secret..."
        kubectl delete secret forgejo-runner-init-config -n forgejo
      fi

      RUNNER_TOKEN="$(kubectl exec -n forgejo deployments/forgejo -- \
        sh -c 'gitea forgejo-cli actions generate-runner-token')"

      if [ -z "$RUNNER_TOKEN" ]; then
        echo "Failed to generate RUNNER_TOKEN"
        exit 1
      fi

      cat <<ADD_SECRET | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: forgejo-runner-init-config
  namespace: forgejo
type: Opaque
stringData:
  # todo: change into https://git.local as soon as we have a valid certificate
  CONFIG_INSTANCE: "http://${data.kubernetes_service_v1.forgejo-http.spec[0].cluster_ip}:3000"
  CONFIG_NAME: Homelab Forgejo Runner
  CONFIG_TOKEN: "$${RUNNER_TOKEN}"
ADD_SECRET
SCRIPT
  }
}

resource "helm_release" "forgejo-runner" {
  name             = "forgejo-runner"
  namespace        = "forgejo"
  repository       = "oci://codeberg.org/wrenix/helm-charts/"
  chart            = "forgejo-runner"
  version          = "0.7.4"
  create_namespace = true

  values = [
    file("${local.path_helm_values}/forgejo-runner-values.yaml")
  ]

  depends_on = [
    helm_release.cert-manager,
    helm_release.longhorn,
    helm_release.forgejo,
    kubernetes_config_map_v1.coredns-forgejo,
    null_resource.forgejo-create-runner-init-config,
  ]
}
