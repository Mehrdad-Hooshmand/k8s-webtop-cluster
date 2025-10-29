#!/bin/bash
#
# K3s Worker Installation Script for haiocloud.com cluster
# Usage: ./02-install-k3s-worker.sh <WORKER_NAME> <MASTER_IP> <K3S_TOKEN>
#

set -e

# Check arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <WORKER_NAME> <MASTER_IP> <K3S_TOKEN>"
    echo "Example: $0 k8s-worker1 94.182.92.207 K10abc123..."
    exit 1
fi

WORKER_NAME=$1
MASTER_IP=$2
K3S_TOKEN=$3

echo "========================================"
echo "K3s Worker Installation - $WORKER_NAME"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Update system
echo -e "${YELLOW}[1/5] Updating system packages...${NC}"
apt update -qq
apt install -y curl wget git -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

# Install Docker with ArvanCloud mirror
echo -e "${YELLOW}[2/5] Installing Docker with ArvanCloud mirror...${NC}"
if ! command -v docker &> /dev/null; then
    # Configure ArvanCloud mirror
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://docker.arvancloud.ir"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh > /dev/null 2>&1
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}✓ Docker installed with ArvanCloud mirror${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi
echo ""

# Disable swap
echo -e "${YELLOW}[3/5] Disabling swap...${NC}"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
echo -e "${GREEN}✓ Swap disabled${NC}"
echo ""

# Configure system for K3s
echo -e "${YELLOW}[4/5] Configuring system for K3s...${NC}"
modprobe overlay
modprobe br_netfilter

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system > /dev/null 2>&1
echo -e "${GREEN}✓ System configured${NC}"
echo ""

# Install K3s Agent (Worker)
echo -e "${YELLOW}[5/5] Installing K3s Agent and joining cluster...${NC}"
echo "Master IP: $MASTER_IP"
echo "Worker Name: $WORKER_NAME"
echo ""

curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 \
  K3S_TOKEN=$K3S_TOKEN \
  INSTALL_K3S_EXEC="agent --node-name $WORKER_NAME" sh -

# Wait for agent to start
echo -e "${YELLOW}Waiting for K3s agent to start...${NC}"
sleep 10

# Check if K3s agent is running
if systemctl is-active --quiet k3s-agent; then
    echo -e "${GREEN}✓ K3s Agent installed successfully${NC}"
else
    echo -e "${RED}✗ K3s agent installation failed${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}========================================"
echo "K3s Worker Installation Complete!"
echo "========================================${NC}"
echo ""
echo -e "${YELLOW}Worker node '$WORKER_NAME' joined the cluster!${NC}"
echo ""
echo "Check from master node:"
echo "  kubectl get nodes"
echo ""
