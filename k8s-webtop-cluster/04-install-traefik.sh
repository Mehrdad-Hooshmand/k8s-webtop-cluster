#!/bin/bash
#
# Traefik Ingress Controller Installation Script
# With Let's Encrypt SSL automation
#

set -e

echo "========================================"
echo "Traefik Ingress Controller Installation"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Set kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Variables
DOMAIN="apps.haiocloud.com"
EMAIL="admin@haiocloud.com"  # Change this to your email

echo -e "${YELLOW}[1/6] Installing Helm (if not installed)...${NC}"
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo -e "${GREEN}✓ Helm installed${NC}"
else
    echo -e "${GREEN}✓ Helm already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[2/6] Adding Traefik Helm repository...${NC}"
helm repo add traefik https://traefik.github.io/charts
helm repo update
echo -e "${GREEN}✓ Traefik repo added${NC}"
echo ""

echo -e "${YELLOW}[3/6] Creating traefik namespace...${NC}"
kubectl create namespace traefik --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

echo -e "${YELLOW}[4/6] Creating Traefik values configuration...${NC}"
cat > /root/traefik-values.yaml <<EOF
# Traefik Configuration for haiocloud.com
globalArguments:
  - "--global.checknewversion=false"
  - "--global.sendanonymoususage=false"

# Enable dashboard
ingressRoute:
  dashboard:
    enabled: true
    matchRule: Host(\`traefik.${DOMAIN}\`)
    entryPoints: ["websecure"]

# Ports configuration
ports:
  web:
    port: 8000
    exposedPort: 80
  websecure:
    port: 8443
    exposedPort: 443
    tls:
      enabled: true

# Service type - LoadBalancer (uses MetalLB)
service:
  enabled: true
  type: LoadBalancer
  annotations: {}

# Let's Encrypt configuration
additionalArguments:
  - "--certificatesresolvers.letsencrypt.acme.email=${EMAIL}"
  - "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
  - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"

# Persistence for Let's Encrypt certificates
persistence:
  enabled: true
  storageClass: "local-path"
  size: 128Mi

# Resource limits (adjust based on your needs)
resources:
  requests:
    cpu: "100m"
    memory: "50Mi"
  limits:
    cpu: "300m"
    memory: "150Mi"

# Enable access logs
logs:
  general:
    level: INFO
  access:
    enabled: true
EOF

echo -e "${GREEN}✓ Configuration file created${NC}"
echo ""

echo -e "${YELLOW}[5/6] Installing Traefik...${NC}"
echo "This may take a few minutes..."
helm install traefik traefik/traefik \
  --namespace traefik \
  --values /root/traefik-values.yaml \
  --wait \
  --timeout 5m

echo -e "${GREEN}✓ Traefik installed${NC}"
echo ""

echo -e "${YELLOW}[6/6] Waiting for LoadBalancer IP assignment...${NC}"
sleep 10
kubectl get svc -n traefik
echo ""

echo -e "${GREEN}========================================"
echo "Traefik Installation Complete!"
echo "========================================${NC}"
echo ""
echo -e "${YELLOW}Dashboard URL:${NC} https://traefik.${DOMAIN}"
echo -e "${YELLOW}Wildcard Domain:${NC} *.${DOMAIN}"
echo ""
echo -e "${GREEN}✓ Traefik is ready to handle ingress traffic${NC}"
echo -e "${GREEN}✓ SSL certificates will be automatically generated${NC}"
echo ""
echo "To access the dashboard, create DNS record:"
echo "  traefik.${DOMAIN} → 94.182.92.207"
echo ""
