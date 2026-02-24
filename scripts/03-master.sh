#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

log_step "Kubernetes Master Setup"
echo "=========================="

check_root

MASTER_IP=${1:-$(get_master_ip)}

log_info "Initializing Kubernetes control plane..."
kubeadm init \
    --pod-network-cidr=${POD_CIDR} \
    --apiserver-advertise-address=${MASTER_IP} \
    2>&1 | tee /tmp/kubeadm-init.log

log_info "Configuring kubectl access..."
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

log_info "Removing control-plane taint to allow workloads..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane- 2>/dev/null || \
    kubectl taint nodes $(hostname) node-role.kubernetes.io/control-plane-:NoSchedule- 2>/dev/null || true

log_info "Generating join command..."
JOIN_CMD=$(kubeadm token create --print-join-command)
echo ""
echo "========================================"
echo "JOIN COMMAND FOR WORKER NODES:"
echo "========================================"
echo "$JOIN_CMD"
echo "========================================"
echo ""
echo "$JOIN_CMD" > /tmp/join-command.txt

log_success "Master node configured successfully"
print_elapsed

echo " copying the new certs "
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $USER:$USER ~/.kube/config