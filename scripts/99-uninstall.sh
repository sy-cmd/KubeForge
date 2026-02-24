#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

log_step "Complete Kubernetes Uninstall"
echo "==============================="

check_root

log_warn "This will completely remove Kubernetes and all its components!"
read -p "Are you sure? Type 'yes' to confirm: " confirm
if [[ "$confirm" != "yes" ]]; then
    log_info "Uninstall cancelled"
    exit 0
fi

echo ""

log_step "Step 1: Killing processes using Kubernetes ports..."
KUBE_PORTS=(6443 10250 10259 10257 2379 2380 30000 30001 30002)
for port in "${KUBE_PORTS[@]}"; do
    fuser -k $port/tcp 2>/dev/null || true
done
log_info "Port processes killed"

log_step "Step 2: Stopping and disabling services..."
systemctl stop kubelet 2>/dev/null || true
systemctl stop containerd 2>/dev/null || true
systemctl stop etcd 2>/dev/null || true
systemctl disable kubelet 2>/dev/null || true
systemctl disable containerd 2>/dev/null || true
log_info "Services stopped"

log_step "Step 3: Killing Kubernetes and container processes..."
pkill -9 kubelet 2>/dev/null || true
pkill -9 etcd 2>/dev/null || true
pkill -9 kube-apiserver 2>/dev/null || true
pkill -9 kube-controller-manager 2>/dev/null || true
pkill -9 kube-scheduler 2>/dev/null || true
pkill -9 kube-proxy 2>/dev/null || true
pkill -9 containerd 2>/dev/null || true
pkill -9 containerd-shim 2>/dev/null || true
pkill -9 containerd-shim-runc-v2 2>/dev/null || true
pkill -9 crictl 2>/dev/null || true
log_info "Processes killed"

log_step "Step 4: Running kubeadm reset..."
kubeadm reset --force 2>/dev/null || true

log_step "Step 5: Purging Kubernetes packages..."
apt-get purge -y kubelet kubeadm kubectl 2>/dev/null || true
apt-get purge -y kube-* 2>/dev/null || true

log_step "Step 6: Purging containerd and Docker..."
apt-get purge -y containerd 2>/dev/null || true
apt-get purge -y docker.io docker-ce docker-ce-cli 2>/dev/null || true
apt-get autoremove -y --purge 2>/dev/null || true
apt-mark unhold kubelet kubeadm kubectl 2>/dev/null || true
log_info "Packages purged"

log_step "Step 7: Removing binary files..."
rm -f /usr/bin/kube* 2>/dev/null || true
rm -f /usr/bin/kubeadm 2>/dev/null || true
rm -f /usr/bin/kubectl 2>/dev/null || true
rm -f /usr/bin/kubelet 2>/dev/null || true
rm -f /usr/bin/crictl 2>/dev/null || true
rm -f /usr/local/bin/kube* 2>/dev/null || true
rm -f /usr/local/bin/kubeadm 2>/dev/null || true
rm -f /usr/local/bin/kubectl 2>/dev/null || true
log_info "Binary files removed"

log_step "Step 8: Cleaning up directories..."
rm -rf /etc/kubernetes 2>/dev/null || true
rm -rf /var/lib/etcd 2>/dev/null || true
rm -rf /var/lib/containerd 2>/dev/null || true
rm -rf /var/lib/kubelet 2>/dev/null || true
rm -rf /var/lib/crictl 2>/dev/null || true
rm -rf /var/lib/docker 2>/dev/null || true
rm -rf $HOME/.kube 2>/dev/null || true
rm -rf /etc/cni/net.d 2>/dev/null || true
log_info "Directories cleaned"

log_step "Step 9: Cleaning up network rules..."
iptables -F 2>/dev/null || true
iptables -t nat -F 2>/dev/null || true
iptables -t mangle -F 2>/dev/null || true
iptables -X 2>/dev/null || true
ipvsadm --clear 2>/dev/null || true
log_info "Network rules flushed"

log_step "Step 10: Removing configuration files..."
rm -f /etc/apt/sources.list.d/kubernetes.list 2>/dev/null || true
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null || true
rm -f /etc/modules-load.d/k8s.conf 2>/dev/null || true
rm -f /etc/sysctl.d/k8s.conf 2>/dev/null || true
rm -f /etc/containerd/config.toml 2>/dev/null || true
rm -rf /etc/containerd 2>/dev/null || true
rm -f /etc/crictl.yaml 2>/dev/null || true
rm -f /etc/crictl.yaml.d 2>/dev/null || true
systemctl daemon-reload 2>/dev/null || true
log_info "Configuration files removed"

log_step "Step 11: Re-enabling swap..."
swapon -a 2>/dev/null || true
sed -i '/ swap / s/^#//' /etc/fstab 2>/dev/null || true

echo ""
log_success "=============================================="
log_success "Kubernetes completely uninstalled!"
log_success "=============================================="
echo ""
log_info "All packages removed, binaries deleted, processes killed"
log_info "System is now clean. You can reinstall with:"
echo "  sudo bash 10-all-in-one.sh"
echo ""
