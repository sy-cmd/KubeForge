#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

log_step "Installing Calico CNI"
echo "========================="

log_info "Installing Calico operator..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml

# Install Calico with custom resources
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml


log_info "Calico installation started in background..."
log_warn "Cluster may take 1-2 minutes to become fully ready"

print_elapsed

echo " check the statuus of the calico pods "
kubectl get pods -n calico-system