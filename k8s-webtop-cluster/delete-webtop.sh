#!/bin/bash
#
# Delete Webtop Instance
# Usage: ./delete-webtop.sh <username>
#

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    echo "Example: $0 user1"
    exit 1
fi

USERNAME=$1
NAMESPACE="webtops"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "========================================"
echo "Deleting Webtop for: $USERNAME"
echo "========================================"
echo ""

# Check if exists
if ! kubectl get deployment -n $NAMESPACE webtop-$USERNAME &> /dev/null; then
    echo -e "${RED}Error: Webtop for user '$USERNAME' not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}WARNING: This will delete all data for user: $USERNAME${NC}"
echo -e "${YELLOW}Are you sure? (yes/no)${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Deleting resources...${NC}"

kubectl delete deployment,svc,pvc,ingress,secret -n $NAMESPACE -l user=$USERNAME

echo ""
echo -e "${GREEN}✓ Webtop for user '$USERNAME' deleted successfully${NC}"

# Delete password file
if [ -f "/root/webtop-${USERNAME}-password.txt" ]; then
    rm /root/webtop-${USERNAME}-password.txt
    echo -e "${GREEN}✓ Password file deleted${NC}"
fi

echo ""
