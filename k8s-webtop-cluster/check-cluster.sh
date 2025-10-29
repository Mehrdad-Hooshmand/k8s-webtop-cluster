#!/bin/bash
#
# Check K3s cluster status
#

echo "========================================
"
echo "K3s Cluster Status - haiocloud.com"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if K3s is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ K3s is not installed${NC}"
    exit 1
fi

# Set kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo -e "${YELLOW}=== System Info ===${NC}"
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo ""

echo -e "${YELLOW}=== K3s Service Status ===${NC}"
if systemctl is-active --quiet k3s; then
    echo -e "${GREEN}✓ K3s service is running${NC}"
elif systemctl is-active --quiet k3s-agent; then
    echo -e "${GREEN}✓ K3s agent is running${NC}"
else
    echo -e "${RED}✗ K3s service is not running${NC}"
fi
echo ""

echo -e "${YELLOW}=== Cluster Nodes ===${NC}"
kubectl get nodes -o wide
echo ""

echo -e "${YELLOW}=== Cluster Info ===${NC}"
kubectl cluster-info
echo ""

echo -e "${YELLOW}=== System Pods ===${NC}"
kubectl get pods -A
echo ""

echo -e "${YELLOW}=== Namespaces ===${NC}"
kubectl get namespaces
echo ""

# If this is master, show token
if [ -f "/var/lib/rancher/k3s/server/node-token" ]; then
    echo -e "${YELLOW}=== Worker Join Token ===${NC}"
    echo -e "${GREEN}$(cat /var/lib/rancher/k3s/server/node-token)${NC}"
    echo ""
    echo -e "${YELLOW}Join command for workers:${NC}"
    MASTER_IP=$(hostname -I | awk '{print $1}')
    echo "curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=<TOKEN> sh -"
    echo ""
fi

echo "========================================"
