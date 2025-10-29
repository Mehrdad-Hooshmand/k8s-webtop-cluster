#!/bin/bash
#
# Remote Webtop Creator - Create Webtop on K8s cluster from any client
# Usage: ./remote-create-webtop.sh <username>
#

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
K8S_MASTER="94.182.92.207"
SSH_PORT="2280"
SSH_USER="root"
DOMAIN="haiocloud.com"
NAMESPACE="webtops"

echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Remote Webtop Creator - K8s HaioCloud        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

# Check arguments
if [ $# -ne 1 ]; then
    echo -e "${RED}Usage: $0 <username>${NC}"
    echo "Example: $0 ali"
    echo ""
    echo "This will create a new Ubuntu Desktop (Webtop) instance on the Kubernetes cluster"
    echo "accessible at: https://<username>.${DOMAIN}"
    exit 1
fi

USERNAME=$1

# Validate username (alphanumeric only)
if ! [[ "$USERNAME" =~ ^[a-z0-9]+$ ]]; then
    echo -e "${RED}Error: Username must be lowercase alphanumeric only${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating Webtop instance for: ${GREEN}${USERNAME}${NC}"
echo -e "${YELLOW}Domain: ${GREEN}https://${USERNAME}.${DOMAIN}${NC}"
echo ""

# Test SSH connection
echo -e "${YELLOW}[1/6] Testing connection to K8s master...${NC}"
if ! ssh -p $SSH_PORT -o ConnectTimeout=5 ${SSH_USER}@${K8S_MASTER} "echo OK" &> /dev/null; then
    echo -e "${RED}✗ Cannot connect to K8s master at ${K8S_MASTER}:${SSH_PORT}${NC}"
    echo "Please check your SSH connection and try again"
    exit 1
fi
echo -e "${GREEN}✓ Connected to K8s master${NC}"
echo ""

# Check if user already exists
echo -e "${YELLOW}[2/6] Checking if user already exists...${NC}"
if ssh -p $SSH_PORT ${SSH_USER}@${K8S_MASTER} "kubectl get deployment -n $NAMESPACE webtop-$USERNAME 2>/dev/null" &> /dev/null; then
    echo -e "${RED}✗ Webtop for user '$USERNAME' already exists!${NC}"
    echo ""
    echo "To delete this user, run:"
    echo "  ./remote-delete-webtop.sh $USERNAME"
    exit 1
fi
echo -e "${GREEN}✓ Username is available${NC}"
echo ""

# Generate random password
echo -e "${YELLOW}[3/6] Generating secure password...${NC}"
PASSWORD=$(openssl rand -base64 18 | tr -d '\n')
echo -e "${GREEN}✓ Password generated${NC}"
echo ""

# Create namespace if not exists
echo -e "${YELLOW}[4/6] Creating namespace...${NC}"
ssh -p $SSH_PORT ${SSH_USER}@${K8S_MASTER} "kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1"
echo -e "${GREEN}✓ Namespace ready${NC}"
echo ""

# Create Kubernetes resources
echo -e "${YELLOW}[5/6] Deploying Webtop to Kubernetes cluster...${NC}"

ssh -p $SSH_PORT ${SSH_USER}@${K8S_MASTER} bash <<ENDSSH
set -e

# Create Secret with password
kubectl create secret generic webtop-${USERNAME}-secret \
  -n ${NAMESPACE} \
  --from-literal=password='${PASSWORD}' \
  --dry-run=client -o yaml | kubectl apply -f - > /dev/null

# Create Deployment
cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webtop-${USERNAME}
  namespace: ${NAMESPACE}
  labels:
    app: webtop
    user: ${USERNAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webtop
      user: ${USERNAME}
  template:
    metadata:
      labels:
        app: webtop
        user: ${USERNAME}
    spec:
      containers:
      - name: webtop
        image: lscr.io/linuxserver/webtop:alpine-kde
        ports:
        - containerPort: 3000
          name: http
          protocol: TCP
        env:
        - name: PUID
          value: "1000"
        - name: PGID
          value: "1000"
        - name: TZ
          value: "Asia/Tehran"
        - name: CUSTOM_USER
          value: "admin"
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              name: webtop-${USERNAME}-secret
              key: password
        - name: CUSTOM_PORT
          value: "3000"
        - name: DISABLE_HTTPS
          value: "true"
        - name: SUBFOLDER
          value: "/"
        - name: TITLE
          value: "Webtop"
        volumeMounts:
        - name: config
          mountPath: /config
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        securityContext:
          privileged: false
          capabilities:
            add:
            - NET_ADMIN
      volumes:
      - name: config
        persistentVolumeClaim:
          claimName: webtop-${USERNAME}-pvc
EOF

# Create PVC
cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: webtop-${USERNAME}-pvc
  namespace: ${NAMESPACE}
  labels:
    app: webtop
    user: ${USERNAME}
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: local-path
EOF

# Create Service
cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: v1
kind: Service
metadata:
  name: webtop-${USERNAME}-svc
  namespace: ${NAMESPACE}
  labels:
    app: webtop
    user: ${USERNAME}
spec:
  selector:
    app: webtop
    user: ${USERNAME}
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
    name: http
  type: ClusterIP
EOF

# Create Ingress (HTTP only - no SSL)
cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webtop-${USERNAME}-ingress
  namespace: ${NAMESPACE}
  labels:
    app: webtop
    user: ${USERNAME}
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
  - host: ${USERNAME}.${DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webtop-${USERNAME}-svc
            port:
              number: 3000
EOF

echo "Resources created successfully"
ENDSSH

echo -e "${GREEN}✓ Webtop deployed to cluster${NC}"
echo ""

# Wait for pod to be ready
echo -e "${YELLOW}[6/6] Waiting for Webtop to be ready...${NC}"
echo -e "${YELLOW}This may take 1-2 minutes for first-time image download...${NC}"

for i in {1..60}; do
    STATUS=$(ssh -p $SSH_PORT ${SSH_USER}@${K8S_MASTER} "kubectl get pod -n $NAMESPACE -l user=$USERNAME -o jsonpath='{.items[0].status.phase}' 2>/dev/null" || echo "")
    
    if [ "$STATUS" = "Running" ]; then
        echo -e "\r${GREEN}✓ Webtop is ready!                                     ${NC}"
        break
    fi
    
    echo -ne "\rWaiting... ($i/60) Current status: $STATUS    "
    sleep 2
done
echo ""

# Get final status
POD_NAME=$(ssh -p $SSH_PORT ${SSH_USER}@${K8S_MASTER} "kubectl get pod -n $NAMESPACE -l user=$USERNAME -o jsonpath='{.items[0].metadata.name}' 2>/dev/null" || echo "")
NODE_NAME=$(ssh -p $SSH_PORT ${SSH_USER}@${K8S_MASTER} "kubectl get pod -n $NAMESPACE -l user=$USERNAME -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null" || echo "")

# Display success information
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Webtop Created Successfully!             ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Access Information:${NC}"
echo -e "  URL:      ${GREEN}http://${USERNAME}.${DOMAIN}${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}${PASSWORD}${NC}"
echo ""
echo -e "${BLUE}Kubernetes Details:${NC}"
echo -e "  Namespace: ${NAMESPACE}"
echo -e "  Pod:       ${POD_NAME}"
echo -e "  Node:      ${NODE_NAME}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "  • Access URL is HTTP (not HTTPS) - SSL currently disabled"
echo "  • Password is randomly generated for security"
echo "  • Data is persisted in 5GB storage volume"
echo "  • Desktop environment: KDE Plasma on Alpine Linux"
echo ""
echo -e "${YELLOW}Management Commands:${NC}"
echo "  View status:  ssh -p $SSH_PORT $SSH_USER@$K8S_MASTER 'kubectl get pods -n $NAMESPACE -l user=$USERNAME'"
echo "  View logs:    ssh -p $SSH_PORT $SSH_USER@$K8S_MASTER 'kubectl logs -n $NAMESPACE -l user=$USERNAME'"
echo "  Delete user:  ./remote-delete-webtop.sh $USERNAME"
echo ""

# Save credentials to local file
CRED_FILE="webtop-${USERNAME}-credentials.txt"
cat > "$CRED_FILE" <<EOF
╔═══════════════════════════════════════════════════╗
║        Webtop Access Credentials                  ║
╚═══════════════════════════════════════════════════╝

Username: ${USERNAME}
Created:  $(date)

Access Information:
  URL:      http://${USERNAME}.${DOMAIN}
  Username: admin
  Password: ${PASSWORD}

Kubernetes Details:
  Cluster:   ${K8S_MASTER}
  Namespace: ${NAMESPACE}
  Pod:       ${POD_NAME}
  Node:      ${NODE_NAME}

Management:
  SSH:    ssh -p ${SSH_PORT} ${SSH_USER}@${K8S_MASTER}
  Status: kubectl get pods -n ${NAMESPACE} -l user=${USERNAME}
  Logs:   kubectl logs -n ${NAMESPACE} -l user=${USERNAME}
EOF

echo -e "${GREEN}✓ Credentials saved to: ${CRED_FILE}${NC}"
echo ""
