#!/bin/bash
#
# MetalLB Installation Script for K3s
# Provides LoadBalancer functionality for bare-metal clusters
#

set -e

echo "========================================"
echo "MetalLB Installation"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Set kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo -e "${YELLOW}[1/4] Installing MetalLB using manifest...${NC}"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml

echo -e "${GREEN}✓ MetalLB manifests applied${NC}"
echo ""

echo -e "${YELLOW}[2/4] Waiting for MetalLB pods to be ready...${NC}"
kubectl wait --namespace metallb-system \
    --for=condition=ready pod \
    --selector=app=metallb \
    --timeout=120s

echo -e "${GREEN}✓ MetalLB pods are ready${NC}"
echo ""

echo -e "${YELLOW}[3/4] Configuring IP Address Pool...${NC}"
# We'll use the same public IPs of our nodes for LoadBalancer services
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: haiocloud-pool
  namespace: metallb-system
spec:
  addresses:
  - 94.182.92.207/32
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: haiocloud-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - haiocloud-pool
EOF

echo -e "${GREEN}✓ IP Address Pool configured${NC}"
echo ""

echo -e "${YELLOW}[4/4] Verifying MetalLB installation...${NC}"
kubectl get pods -n metallb-system
echo ""
kubectl get ipaddresspool -n metallb-system
echo ""

echo -e "${GREEN}========================================"
echo "MetalLB Installation Complete!"
echo "========================================${NC}"
echo ""
echo -e "${YELLOW}IP Pool:${NC} 94.182.92.207"
echo -e "${YELLOW}Mode:${NC} Layer 2 (L2)"
echo ""
echo -e "${GREEN}✓ LoadBalancer services will now get external IPs${NC}"
echo ""
