#!/bin/bash
#
# K3s Master Installation Script for haiocloud.com cluster
# Optimized for Iran with ArvanCloud mirror
# Server: 94.182.92.207
#

set -e

echo "========================================"
echo "K3s Master Installation - haiocloud.com"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Update system
echo -e "${YELLOW}[1/6] Updating system packages...${NC}"
apt update -qq
apt install -y curl wget git openssl jq -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

# Install Docker with ArvanCloud mirror
echo -e "${YELLOW}[2/6] Installing Docker with ArvanCloud mirror...${NC}"
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

# Disable swap (required for K8s)
echo -e "${YELLOW}[3/6] Disabling swap...${NC}"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
echo -e "${GREEN}✓ Swap disabled${NC}"
echo ""

# Configure system for K3s
echo -e "${YELLOW}[4/6] Configuring system for K3s...${NC}"
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

# Install K3s Master
echo -e "${YELLOW}[5/6] Installing K3s Master...${NC}"
echo "This may take a few minutes..."

# K3s installation with custom settings
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --disable traefik \
  --disable servicelb \
  --write-kubeconfig-mode 644 \
  --node-name k8s-master \
  --cluster-cidr 10.42.0.0/16 \
  --service-cidr 10.43.0.0/16 \
  --tls-san 94.182.92.207 \
  --tls-san k8s.apps.haiocloud.com" sh -

# Wait for K3s to be ready
echo -e "${YELLOW}Waiting for K3s to be ready...${NC}"
sleep 10

# Check if K3s is running
if systemctl is-active --quiet k3s; then
    echo -e "${GREEN}✓ K3s Master installed successfully${NC}"
else
    echo -e "${RED}✗ K3s installation failed${NC}"
    exit 1
fi
echo ""

# Configure kubectl
echo -e "${YELLOW}[6/6] Configuring kubectl...${NC}"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc

# Install kubectl completion
kubectl completion bash > /etc/bash_completion.d/kubectl
echo -e "${GREEN}✓ kubectl configured${NC}"
echo ""

# Get node token for workers
K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
echo -e "${GREEN}========================================"
echo "K3s Master Installation Complete!"
echo "========================================${NC}"
echo ""
echo -e "${YELLOW}Master Node Info:${NC}"
kubectl get nodes
echo ""
echo -e "${YELLOW}Cluster Info:${NC}"
kubectl cluster-info
echo ""
echo -e "${GREEN}Node Token for Workers:${NC}"
echo "$K3S_TOKEN"
echo ""
echo -e "${YELLOW}Save this token! You'll need it for worker nodes.${NC}"
echo "Token saved to: /var/lib/rancher/k3s/server/node-token"
echo ""

# Save token to file for easy access
echo "$K3S_TOKEN" > /root/k3s-token.txt
chmod 600 /root/k3s-token.txt

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Join worker nodes using the token above"
echo "2. Install MetalLB for LoadBalancer"
echo "3. Install Traefik for Ingress"
