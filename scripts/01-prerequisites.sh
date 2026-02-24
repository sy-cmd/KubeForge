#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

log_step "Prerequisites Installation (All Nodes)"
echo "========================================"

check_root

log_info "Updating package lists..."
apt-get update -qq

log_info "Installing required packages..."
apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release netcat-openbsd conntrack > /dev/null 2>&1

log_info "Disabling swap..."
swapoff -a 2>/dev/null || true
sed -i '/ swap / s/^/#/' /etc/fstab 2>/dev/null || true

log_info "Loading kernel modules..."
cat <<K8SCONF | tee /etc/modules-load.d/k8s.conf > /dev/null
overlay
br_netfilter
K8SCONF

modprobe overlay 2>/dev/null || true
modprobe br_netfilter 2>/dev/null || true

log_info "Configuring kernel networking..."
cat <<SYSCTLCONF | tee /etc/sysctl.d/k8s.conf > /dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTLCONF

sysctl --system > /dev/null 2>&1

log_info "Installing and configuring containerd..."
apt-get install -y -qq containerd > /dev/null 2>&1

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml 2>/dev/null || true
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml 2>/dev/null || true

systemctl enable --now containerd 2>/dev/null || true
systemctl restart containerd 2>/dev/null || true

log_info "Installing Kubernetes components (kubeadm, kubelet, kubectl)..."

KUBERNETES_VERSION="v1.29"

log_info "Using Kubernetes version: ${KUBERNETES_VERSION}"

log_info "Adding Kubernetes GPG key..."
mkdir -p -m 755 /etc/apt/keyrings
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
rm -f /etc/apt/sources.list.d/kubernetes.list

curl -fsSL "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null || {
    log_error "Failed to add GPG key"
    exit 1
}

log_info "Adding Kubernetes repository..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

log_info "Updating package lists..."
apt-get update -qq

log_info "Installing kubeadm, kubelet, kubectl..."
apt-get install -y -qq kubeadm kubelet kubectl

apt-mark hold kubelet kubeadm kubectl

systemctl enable --now kubelet

log_success "Prerequisites installed successfully"
print_elapsed
