#!/usr/bin/env bash
set -e

# Script to reset Kubernetes cluster
echo "WARNING: This script will completely reset the Kubernetes cluster!"
echo "This will:"
echo "  - Reset the Kubernetes cluster on the remote system"
echo "  - Remove all Kubernetes packages and configurations"
echo "  - Clear all firewall rules"
echo "  - Remove local Kubernetes configurations"
echo
echo "Target system: rpcloud (192.168.115.127)"
echo

# Target system details
TARGET_HOST="rpcloud"
TARGET_IP="192.168.115.127"
REMOTE_USER="ubuntu"

# Check if user wants to proceed
read -p "Are you sure you want to proceed? (yes/no) " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]
then
    echo "Operation cancelled."
    exit 1
fi

# Function to check if remote host is accessible
check_remote_access() {
    if ! ping -c 1 ${TARGET_IP} &> /dev/null; then
        echo "Error: Cannot reach ${TARGET_HOST} (${TARGET_IP})"
        exit 1
    fi
}

# Function to execute remote commands
remote_exec() {
    if ! ssh ${REMOTE_USER}@${TARGET_IP} "sudo bash -c '$1'"; then
        echo "Error executing command on remote system: $1"
        exit 1
    fi
}

# Check remote access before proceeding
echo "Checking connection to remote system..."
check_remote_access

echo "Resetting Kubernetes cluster on remote system..."

# Reset kubeadm
remote_exec "kubeadm reset -f"

# Stop and disable services
remote_exec "systemctl stop kubelet"
remote_exec "systemctl disable kubelet"

# Remove Kubernetes packages
remote_exec "apt-get remove -y kubeadm kubectl kubelet kubernetes-cni helm python3-kubernetes"
remote_exec "apt-get autoremove -y"

# Remove Kubernetes repositories and keys
remote_exec "rm -f /etc/apt/keyrings/kubernetes-apt-keyring.asc"
remote_exec "rm -f /etc/apt/keyrings/helm.asc"
remote_exec "rm -f /etc/apt/sources.list.d/kubernetes.list"
remote_exec "rm -f /etc/apt/sources.list.d/helm-stable-debian.list"

# Remove CNI configurations
remote_exec "rm -rf /etc/cni/net.d/"

# Clean Kubernetes directories
remote_exec "rm -rf /etc/kubernetes/"
remote_exec "rm -rf /var/lib/kubernetes/"
remote_exec "rm -rf /var/lib/etcd/"
remote_exec "rm -rf /var/lib/kubelet/"
remote_exec "rm -rf /home/ubuntu/.kube"

# Reset sysctl parameters
remote_exec "rm -f /etc/sysctl.d/99-kubernetes-cri.conf"
remote_exec "sysctl --system"

# Remove firewall rules
remote_exec "iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X"

echo "Cleaning local Kubernetes configuration..."
# Remove local .kube directory
rm -rf ~/.kube

# Verify cleanup
echo "Verifying cleanup..."

# Check if local .kube directory is removed
if [ -d ~/.kube ]; then
    echo "Warning: Local .kube directory still exists"
    exit 1
fi

# Verify remote cleanup
if ssh ${REMOTE_USER}@${TARGET_IP} "[ -d /etc/kubernetes ]"; then
    echo "Warning: Remote kubernetes directory still exists"
    exit 1
fi

echo "Kubernetes cluster has been reset successfully!"
echo "You can now reinstall Kubernetes using the setup scripts if needed."
