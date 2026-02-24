#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

log_step "Kubernetes Worker Setup"
echo "=========================="

check_root

if [[ -z "$1" ]]; then
    if [[ -f /tmp/join-command.txt ]]; then
        JOIN_CMD=$(cat /tmp/join-command.txt)
        log_info "Using cached join command from master"
    else
        log_error "Join command required. Usage: $0 <join-command>"
        log_info "Run on master: kubeadm token create --print-join-command"
        exit 1
    fi
else
    JOIN_CMD="$1"
fi

log_info "Joining cluster as worker node..."
eval $JOIN_CMD 2>&1

log_success "Worker node joined successfully"
print_elapsed
