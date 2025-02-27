# Kubernetes Cluster Setup with Flannel and Traefik

This repository contains configuration files for setting up a Kubernetes cluster with Flannel CNI and Traefik Ingress Controller, along with the Kubernetes Dashboard.

## Components

- **Flannel**: Network overlay for pod networking
- **Traefik**: Ingress Controller running on master node
- **Kubernetes Dashboard**: Web UI for cluster management

## Prerequisites

- Kubernetes cluster with 1-2 nodes
- Master node named 'rpcloud'
- kubectl configured with admin access

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
- Deploy Flannel CNI
- Deploy Traefik Ingress Controller
- Deploy Kubernetes Dashboard
- Create an admin user for the dashboard
- Display access instructions and login token

## Network Configuration

- Flannel Network CIDR: 10.244.0.0/16
- Traefik Ports:
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
├── manifests/
│   ├── networking/     # Flannel CNI configuration
│   ├── ingress/       # Traefik configuration
│   └── apps/          # Application manifests (Dashboard)
└── scripts/
    └── deploy.sh      # Deployment script
```

## Notes

- All services are configured to run on the master node (rpcloud)
- Traefik is configured with NodePort services for external access
- Dashboard uses HTTPS with self-signed certificates
