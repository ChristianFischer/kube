#!/bin/bash

echo "Deploying Kubernetes components..."

# Deploy Flannel CNI
echo "Deploying Flannel CNI..."
kubectl apply -f manifests/networking/kube-flannel.yml
echo "Waiting for Flannel to be ready..."
kubectl wait --namespace kube-flannel --for=condition=ready pod --selector=app=flannel --timeout=90s

# Deploy Traefik Ingress Controller
echo "Deploying Traefik Ingress Controller..."
kubectl apply -f manifests/ingress/traefik.yml
echo "Waiting for Traefik to be ready..."
kubectl wait --namespace kube-system --for=condition=ready pod --selector=app=traefik --timeout=90s

# Deploy Kubernetes Dashboard
echo "Deploying Kubernetes Dashboard..."
kubectl apply -f manifests/apps/kubernetes-dashboard.yml
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
