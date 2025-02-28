#!/bin/bash

echo "Deploying Kubernetes components..."

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add traefik https://helm.traefik.io/traefik
helm repo add projectcalico https://docs.projectcalico.org/charts
helm repo update

# Deploy Calico CNI (replacing Flannel)
echo "Deploying Calico CNI..."
helm install calico projectcalico/tigera-operator --namespace tigera-operator --create-namespace
echo "Waiting for Calico to be ready..."
kubectl wait --namespace calico-system --for=condition=ready pod --selector=k8s-app=calico-node --timeout=90s

# Deploy Traefik Ingress Controller using Helm
echo "Deploying Traefik Ingress Controller..."
helm install traefik traefik/traefik --namespace kube-system -f helm/traefik-values.yaml
echo "Waiting for Traefik to be ready..."
kubectl wait --namespace kube-system --for=condition=ready pod --selector=app.kubernetes.io/name=traefik --timeout=90s

# Deploy Kubernetes Dashboard using Helm
echo "Adding Kubernetes Dashboard Helm repository..."
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
echo "Deploying Kubernetes Dashboard..."
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --namespace kubernetes-dashboard \
  --create-namespace \
  -f helm/kubernetes-dashboard-values.yaml
echo "Waiting for Kubernetes Dashboard to be ready..."
kubectl wait --namespace kubernetes-dashboard --for=condition=ready pod --selector=k8s-app=kubernetes-dashboard --timeout=90s

# Create admin user for dashboard
echo "Creating admin user for dashboard..."
kubectl apply -f manifests/auth/dashboard-admin-user.yml

# Get token for dashboard
echo "Getting token for dashboard login..."
kubectl -n kubernetes-dashboard create token admin-user

echo "
===========================================
Setup completed!

To access the Kubernetes Dashboard:

1. Add to your /etc/hosts:
   $(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}') dashboard.rpcloud

2. Access the dashboard at:
   https://dashboard.rpcloud:30443

3. Use the token printed above to log in

Note: You might need to accept the self-signed certificate in your browser.
===========================================
"
