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
echo "Target system: rpcloud"
echo

# Target system details
TARGET_HOST="rpcloud"
REMOTE_USER="ubuntu"

# Check if user wants to proceed
read -p "Are you sure you want to proceed? (yes/no) " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# Function to execute remote commands
remote_exec() {
    if ! ssh ${REMOTE_USER}@${TARGET_HOST} "sudo bash -c '$1'"; then
        echo "Error executing command on remote system: $1"
        exit 1
    fi
}

# Check remote access before proceeding
echo "Checking connection to remote system..."
if ! ping -c 1 ${TARGET_HOST} &> /dev/null; then
    echo "Error: Cannot reach ${TARGET_HOST}"
    exit 1
fi

echo "Resetting Kubernetes cluster on remote system..."
ssh ${REMOTE_USER}@${TARGET_HOST} << 'SSH'
    sudo bash << SUDO
        set -ex

        # reset kubeadm
        kubeadm reset -f

        # Stop and disable services
        systemctl stop kubelet
        systemctl disable kubelet

        # Remove Kubernetes packages
        apt-get remove -y kubeadm kubectl kubelet kubernetes-cni helm python3-kubernetes
        apt-get autoremove -y

        # Remove Kubernetes repositories and keys
        rm -f /etc/apt/keyrings/kubernetes-apt-keyring.asc
        rm -f /etc/apt/keyrings/helm.asc
        rm -f /etc/apt/sources.list.d/kubernetes.list
        rm -f /etc/apt/sources.list.d/helm-stable-debian.list

        # Remove CNI configurations
        rm -rf /etc/cni/net.d/

        # Clean Kubernetes directories
        rm -rf /etc/kubernetes/
        rm -rf /var/lib/kubernetes/
        rm -rf /var/lib/etcd/
        rm -rf /var/lib/kubelet/
        rm -rf /home/ubuntu/.kube

        # Reset sysctl parameters
        rm -f /etc/sysctl.d/99-kubernetes-cri.conf
        sysctl --system

        # Remove firewall rules
        iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
SUDO
SSH

# Remove local .kube directory
echo "Cleaning local Kubernetes configuration..."
rm -rf ~/.kube

echo "Kubernetes cluster has been reset successfully!"
echo "You can now reinstall Kubernetes using the setup scripts if needed."
