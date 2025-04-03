#!/bin/bash
set -e
source $(dirname "$(realpath "$0")")/colors

HELM_INSTALL="helm upgrade --install --debug --atomic --wait"

echo -e "${TEXT_GREEN}Deploying Kubernetes components...${TEXT_RESET}"

# Add Helm repositories
echo -e "${TEXT_GREEN}Adding Helm repositories...${TEXT_RESET}"
helm repo add flannel https://flannel-io.github.io/flannel/
helm repo add jetstack https://charts.jetstack.io
helm repo add traefik https://helm.traefik.io/traefik
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo add longhorn https://charts.longhorn.io
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap/
helm repo update

# Deploy Longhorn
echo -e "${TEXT_GREEN}Deploying Longhorn...${TEXT_RESET}"
$HELM_INSTALL longhorn longhorn/longhorn --namespace longhorn-system --create-namespace -f helm/longhorn-values.yaml

# Deploy Flannel CNI
echo -e "${TEXT_GREEN}Deploying Flannel CNI...${TEXT_RESET}"
$HELM_INSTALL flannel --set podCidr="10.244.0.0/16" --create-namespace --namespace kube-flannel flannel/flannel

# Deploy Cert Manager
echo -e "${TEXT_GREEN}Deploying Cert Manager...${TEXT_RESET}"
$HELM_INSTALL cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace -f helm/cert-manager-values.yaml --version v1.17.0

# Deploy Traefik Ingress Controller
echo -e "${TEXT_GREEN}Deploying Traefik Ingress Controller...${TEXT_RESET}"
$HELM_INSTALL traefik traefik/traefik --namespace kube-system -f helm/traefik-values.yaml

# Deploy Kubernetes Dashboard
echo -e "${TEXT_GREEN}Deploying Kubernetes Dashboard...${TEXT_RESET}"
$HELM_INSTALL kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --namespace kubernetes-dashboard \
  --create-namespace \
  -f helm/kubernetes-dashboard-values.yaml

# Deploy Ingress route for Kubernetes Dashboard
echo -e "${TEXT_GREEN}Deploying Kubernetes Dashboard Ingress Route...${TEXT_RESET}"
kubectl apply -f manifests/ingress/kubernetes-dashboard.yml

# Create admin user for dashboard
echo -e "${TEXT_GREEN}Creating admin user for dashboard...${TEXT_RESET}"
kubectl apply -f manifests/auth/dashboard-admin-user.yml

# Get token for dashboard
echo -e "${TEXT_GREEN}Getting token for dashboard login...${TEXT_RESET}"
kubectl -n kubernetes-dashboard create token admin-user

# Deploy OpenLDAP + phpldapadmin
echo -e "${TEXT_GREEN}Deploying OpenLDAP...${TEXT_RESET}"
$HELM_INSTALL openldap helm-openldap/openldap-stack-ha --namespace openldap --create-namespace -f helm/openldap-values.yml


echo "
===========================================
Setup completed!

To access the Kubernetes Dashboard:

1. Add to your /etc/hosts:
   $(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}') dashboard.rpcloud

2. Access the dashboard at:
   https://rpcloud:30443/dashboard

3. Use the token printed above to log in

Note: You might need to accept the self-signed certificate in your browser.
===========================================
"
