#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

log_step "5-Minute Kubernetes Installation"
echo "===================================="
echo ""
echo "Starting at: $(date)"
echo ""

MASTER_IP=${1:-$(get_master_ip)}

log_info "Using Master IP: $MASTER_IP"
log_info "Pod CIDR: $POD_CIDR"
log_info "Kubernetes Version: $K8S_VERSION"
echo ""

echo -e "${YELLOW}=== Step 1: Prerequisites ===${NC}"
bash "$SCRIPT_DIR/01-prerequisites.sh"

echo -e "${YELLOW}=== Step 2: Pre-pull Images ===${NC}"
bash "$SCRIPT_DIR/02-pull-images.sh"

echo -e "${YELLOW}=== Step 3: Initialize Master ===${NC}"
bash "$SCRIPT_DIR/03-master.sh" "$MASTER_IP"

echo -e "${YELLOW}=== Step 4: Install Calico ===${NC}"
bash "$SCRIPT_DIR/05-calico.sh"

echo ""
log_success "=============================================="
log_success "Kubernetes cluster is ready!"
log_success "=============================================="
echo ""
echo "To verify cluster status, run:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo ""
print_elapsed
