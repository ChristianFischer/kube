#!/bin/bash
set -e

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl is not installed or not in PATH"
        exit 1
    fi
}

# Function to check if cluster is accessible
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        echo "Error: Unable to connect to Kubernetes cluster"
        exit 1
    fi
}

# Function to deploy with retry
deploy_with_retry() {
    local manifest=$1
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if kubectl apply -f "$manifest"; then
            return 0
        fi
        echo "Attempt $attempt failed. Retrying in 5 seconds..."
        sleep 5
        attempt=$((attempt + 1))
    done

    echo "Error: Failed to deploy $manifest after $max_attempts attempts"
    return 1
}

echo "Checking prerequisites..."
check_kubectl
check_cluster

echo "Deploying Kubernetes components..."

# Deploy Flannel CNI
echo "Deploying Flannel CNI..."
deploy_with_retry manifests/networking/kube-flannel.yml
echo "Waiting for Flannel to be ready..."
kubectl wait --namespace kube-flannel --for=condition=ready pod --selector=app=flannel --timeout=90s || {
    echo "Error: Flannel pods not ready after 90 seconds"
    exit 1
}

# Deploy Traefik CRDs first
echo "Deploying Traefik CRDs..."
deploy_with_retry manifests/ingress/traefik-crds.yml

# Wait for CRDs to be established
echo "Waiting for Traefik CRDs to be established..."
sleep 5

# Deploy Traefik Ingress Controller
echo "Deploying Traefik Ingress Controller..."
deploy_with_retry manifests/ingress/traefik.yml
echo "Waiting for Traefik to be ready..."
kubectl wait --namespace kube-system --for=condition=ready pod --selector=app=traefik --timeout=90s || {
    echo "Error: Traefik pods not ready after 90 seconds"
    exit 1
}

# Generate secure password for dashboard
echo "Generating secure password for dashboard access..."
DASHBOARD_PASSWORD=$(openssl rand -base64 12)
DASHBOARD_AUTH=$(echo -n "admin:$(openssl passwd -apr1 $DASHBOARD_PASSWORD)" | base64)

# Create auth secret
echo "Creating dashboard auth middleware..."
cat > manifests/ingress/dashboard-auth-middleware.yml << EOF
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: dashboard-auth
  namespace: kubernetes-dashboard
spec:
  basicAuth:
    secret: dashboard-auth-secret
---
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-auth-secret
  namespace: kubernetes-dashboard
type: Opaque
data:
  users: |2
    $DASHBOARD_AUTH
EOF

# Deploy Kubernetes Dashboard and auth middleware
echo "Deploying Kubernetes Dashboard..."
deploy_with_retry manifests/ingress/dashboard-auth-middleware.yml
deploy_with_retry manifests/apps/kubernetes-dashboard.yml
echo "Waiting for Kubernetes Dashboard to be ready..."
kubectl wait --namespace kubernetes-dashboard --for=condition=ready pod --selector=k8s-app=kubernetes-dashboard --timeout=90s

# Create admin user for dashboard
echo "Creating admin user for dashboard..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

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
   https://dashboard.rpcloud:32443

3. Use the token printed above to log in

Note: You might need to accept the self-signed certificate in your browser.

Basic Auth Credentials for Dashboard:
Username: admin
Password: $DASHBOARD_PASSWORD

===========================================
"
