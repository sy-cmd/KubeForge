#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/config.env" ]]; then
    source "$SCRIPT_DIR/config.env"
fi

K8S_VERSION="${K8S_VERSION:-latest}"
POD_CIDR="${POD_CIDR:-192.168.0.0/16}"
SERVICE_CIDR="${SERVICE_CIDR:-10.96.0.0/12}"
CALICO_VERSION="${CALICO_VERSION:-latest}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

START_TIME=$(date +%s)

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} ${BOLD}$1${NC}"
}

print_elapsed() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - START_TIME))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))
    echo -e "${GREEN}[TIME] Elapsed: ${minutes}m ${seconds}s${NC}"
}

resolve_latest_version() {
    if [[ "${K8S_VERSION}" == "latest" ]]; then
        local latest
        latest=$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || echo "")
        
        if [[ -z "$latest" || ! "$latest" =~ ^v1\.[0-3][0-9]\.[0-9]+$ ]]; then
            latest="v1.32.0"
        fi
        
        K8S_VERSION="${latest}"
        log_info "Resolved K8S_VERSION to: $K8S_VERSION"
    fi

    if [[ "${CALICO_VERSION}" == "latest" ]]; then
        local calico_latest
        calico_latest=$(curl -fsSL https://api.github.com/repos/projectcalico/calico/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 || echo "v3.29")
        CALICO_VERSION="${calico_latest}"
        log_info "Resolved CALICO_VERSION to: $CALICO_VERSION"
    fi
}

resolve_latest_version

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

get_master_ip() {
    hostname -I | awk '{print $1}'
}

is_master() {
    [[ -f /etc/kubernetes/admin.conf ]]
}
