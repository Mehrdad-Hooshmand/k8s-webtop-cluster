#!/bin/bash
#
# List and Manage Webtops
#

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
NAMESPACE="webtops"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "Webtop Management Dashboard"
echo "========================================"
echo ""

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo -e "${YELLOW}No webtops namespace found. No users created yet.${NC}"
    exit 0
fi

echo -e "${BLUE}=== Active Webtops ===${NC}"
kubectl get deployments -n $NAMESPACE -o custom-columns=\
USER:.metadata.labels.user,\
STATUS:.status.conditions[0].status,\
READY:.status.readyReplicas,\
AGE:.metadata.creationTimestamp
echo ""

echo -e "${BLUE}=== Pod Status ===${NC}"
kubectl get pods -n $NAMESPACE -o wide
echo ""

echo -e "${BLUE}=== Ingress URLs ===${NC}"
kubectl get ingress -n $NAMESPACE -o custom-columns=\
USER:.metadata.labels.user,\
URL:.spec.rules[0].host,\
AGE:.metadata.creationTimestamp
echo ""

echo -e "${BLUE}=== Storage Usage ===${NC}"
kubectl get pvc -n $NAMESPACE -o custom-columns=\
NAME:.metadata.name,\
STATUS:.status.phase,\
CAPACITY:.status.capacity.storage,\
STORAGECLASS:.spec.storageClassName
echo ""

echo -e "${BLUE}=== Resource Usage (if metrics available) ===${NC}"
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics not available (install metrics-server)"
echo ""

echo "========================================"
echo -e "${YELLOW}Commands:${NC}"
echo "  Create user: ./create-webtop.sh <username>"
echo "  Delete user: ./delete-webtop.sh <username>"
echo "  Get password: cat /root/webtop-<username>-password.txt"
echo "  View logs: kubectl logs -n webtops -l user=<username>"
echo "========================================"
