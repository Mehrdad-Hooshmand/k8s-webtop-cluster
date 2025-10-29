#!/bin/bash
#
# Longhorn Distributed Storage Installation Script
# Runs in background with logging
#

LOGFILE="/root/longhorn-install.log"
exec > >(tee -a "$LOGFILE") 2>&1

set -e

echo "========================================"
echo "Longhorn Installation - $(date)"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Set kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo -e "${YELLOW}[1/5] Installing prerequisite packages...${NC}"
apt-get update -qq
apt-get install -y open-iscsi nfs-common jq curl -qq
systemctl enable iscsid
systemctl start iscsid
echo -e "${GREEN}✓ Prerequisites installed${NC}"
echo ""

echo -e "${YELLOW}[2/5] Adding Longhorn Helm repository...${NC}"
helm repo add longhorn https://charts.longhorn.io
helm repo update
echo -e "${GREEN}✓ Longhorn repo added${NC}"
echo ""

echo -e "${YELLOW}[3/5] Creating longhorn-system namespace...${NC}"
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

echo -e "${YELLOW}[4/5] Installing Longhorn (this may take 5-10 minutes)...${NC}"
echo "Installation started at: $(date)"

helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --set defaultSettings.defaultReplicaCount=2 \
  --set defaultSettings.storageMinimalAvailablePercentage="10" \
  --set persistence.defaultClassReplicaCount=2 \
  --set ingress.enabled=false \
  --wait \
  --timeout 15m

echo -e "${GREEN}✓ Longhorn installed${NC}"
echo "Installation completed at: $(date)"
echo ""

echo -e "${YELLOW}[5/5] Waiting for Longhorn pods to be ready...${NC}"
kubectl wait --for=condition=ready pod \
  --all \
  --namespace=longhorn-system \
  --timeout=300s || true

echo ""
echo -e "${YELLOW}Longhorn pod status:${NC}"
kubectl get pods -n longhorn-system
echo ""

echo -e "${YELLOW}Storage classes:${NC}"
kubectl get storageclass
echo ""

echo -e "${GREEN}========================================"
echo "Longhorn Installation Complete!"
echo "========================================${NC}"
echo ""
echo -e "${YELLOW}Dashboard:${NC} Access via kubectl port-forward"
echo -e "${YELLOW}Default StorageClass:${NC} longhorn"
echo -e "${YELLOW}Replica Count:${NC} 2"
echo ""
echo "To access Longhorn UI:"
echo "  kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
echo ""
echo "Log file: $LOGFILE"
echo ""
