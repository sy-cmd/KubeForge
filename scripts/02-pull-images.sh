#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

log_step "Pre-pull Kubernetes Images"
echo "=============================="

check_root

log_info "Pulling Kubernetes control plane images..."
kubeadm config images pull --kubernetes-version ${K8S_VERSION} 2>/dev/null || \
    kubeadm config images list --kubernetes-version ${K8S_VERSION} | xargs -I{} crictl pull {}

log_info "Pulling Calico images..."
crictl pull docker.io/calico/node:${CALICO_VERSION} 2>/dev/null || true
crictl pull docker.io/calico/kube-controllers:${CALICO_VERSION} 2>/dev/null || true
crictl pull docker.io/calico/cni:${CALICO_VERSION} 2>/dev/null || true

log_success "Images pre-pulled successfully"
print_elapsed
