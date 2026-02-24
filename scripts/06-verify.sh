#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

log_step "Cluster Verification"
echo "======================="

log_info "Checking node status..."
kubectl get nodes -o wide

echo ""
log_info "Checking system pods..."
kubectl get pods -n kube-system

echo ""
log_info "Checking Calico pods..."
kubectl get pods -n calico-system 2>/dev/null || echo "Calico pods not yet ready"

echo ""
log_info "Cluster info:"
kubectl cluster-info

echo ""
log_success "Verification complete"
print_elapsed
