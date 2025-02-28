# Kubernetes Cluster Setup with Calico and Traefik

This repository contains Helm charts and configuration files for setting up a Kubernetes cluster with Calico CNI and Traefik Ingress Controller, along with the Kubernetes Dashboard.

## Components

- **Calico**: Container Network Interface (CNI) for pod networking
- **Traefik**: Ingress Controller running on master node (deployed via Helm)
- **Kubernetes Dashboard**: Web UI for cluster management

## Prerequisites

- Kubernetes cluster with 1-2 nodes
- Master node named 'rpcloud'
- kubectl configured with admin access
- Helm v3 installed

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd <repository-name>
   ```

2. Run the deployment script:
   ```bash
   ./scripts/deploy.sh
   ```

The script will:
- Add required Helm repositories
- Deploy Calico CNI using Helm
- Deploy Traefik Ingress Controller using Helm
- Deploy Kubernetes Dashboard
- Create an admin user for the dashboard
- Display access instructions and login token

## Network Configuration

- Calico is configured with default IPAM settings
- Traefik Ports (configured via helm/traefik-values.yaml):
  - HTTP: 30080
  - HTTPS: 30443
  - Admin: 30808

## Accessing Services

### Kubernetes Dashboard
1. Add the following entry to your `/etc/hosts`:
   ```
   <master-node-ip> dashboard.rpcloud
   ```

2. Access the dashboard at:
   ```
   https://dashboard.rpcloud:30443
   ```

3. Use the token displayed during installation to log in

## Directory Structure

```
.
├── helm/
│   └── traefik-values.yaml    # Traefik Helm values
├── manifests/
│   ├── apps/                  # Application manifests (Dashboard)
│   └── auth/                  # Authentication configurations
└── scripts/
    └── deploy.sh             # Deployment script
```

## Notes

- All services are configured to run on the master node (rpcloud)
- Traefik is configured with NodePort services for external access
- Dashboard uses HTTPS with self-signed certificates
