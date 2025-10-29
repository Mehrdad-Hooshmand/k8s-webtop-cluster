#!/bin/bash
#
# Create Webtop Instance for User
# Usage: ./create-webtop.sh <username>
#

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    echo "Example: $0 user1"
    exit 1
fi

USERNAME=$1
DOMAIN="haiocloud.com"
NAMESPACE="webtops"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Set kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "========================================"
echo "Creating Webtop for: $USERNAME"
echo "========================================"
echo ""

# Validate username (alphanumeric only)
if ! [[ "$USERNAME" =~ ^[a-z0-9]+$ ]]; then
    echo -e "${RED}Error: Username must be lowercase alphanumeric only${NC}"
    exit 1
fi

# Check if user already exists
if kubectl get deployment -n $NAMESPACE webtop-$USERNAME &> /dev/null; then
    echo -e "${RED}Error: Webtop for user '$USERNAME' already exists!${NC}"
    echo "To delete: kubectl delete deployment,svc,pvc,ingress,secret -n $NAMESPACE -l user=$USERNAME"
    exit 1
fi

echo -e "${YELLOW}[1/5] Creating namespace (if not exists)...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace ready${NC}"
echo ""

echo -e "${YELLOW}[2/5] Generating random password...${NC}"
PASSWORD=$(openssl rand -base64 16)
echo "$PASSWORD" > /root/webtop-${USERNAME}-password.txt
echo -e "${GREEN}✓ Password: $PASSWORD${NC}"
echo -e "${GREEN}✓ Saved to: /root/webtop-${USERNAME}-password.txt${NC}"
echo ""

echo -e "${YELLOW}[3/5] Creating Kubernetes resources...${NC}"

# Create resources from template
cat <<EOF | kubectl apply -f -
---
# Secret for password
apiVersion: v1
kind: Secret
metadata:
  name: webtop-${USERNAME}-secret
  namespace: ${NAMESPACE}
  labels:
    user: ${USERNAME}
type: Opaque
stringData:
  password: "${PASSWORD}"
---
# PersistentVolumeClaim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: webtop-${USERNAME}-pvc
  namespace: ${NAMESPACE}
  labels:
    user: ${USERNAME}
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: local-path
---
# Deployment
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
        image: lscr.io/linuxserver/webtop:ubuntu-xfce
        ports:
        - containerPort: 3000
          name: http
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
      volumes:
      - name: config
        persistentVolumeClaim:
          claimName: webtop-${USERNAME}-pvc
---
# Service
apiVersion: v1
kind: Service
metadata:
  name: webtop-${USERNAME}-svc
  namespace: ${NAMESPACE}
  labels:
    app: webtop
    user: ${USERNAME}
spec:
  type: ClusterIP
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
    name: http
  selector:
    app: webtop
    user: ${USERNAME}
---
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webtop-${USERNAME}-ingress
  namespace: ${NAMESPACE}
  labels:
    user: ${USERNAME}
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt
spec:
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
  tls:
  - hosts:
    - ${USERNAME}.${DOMAIN}
    secretName: webtop-${USERNAME}-tls
EOF

echo -e "${GREEN}✓ Resources created${NC}"
echo ""

echo -e "${YELLOW}[4/5] Waiting for pod to be ready (may take 2-3 minutes)...${NC}"
kubectl wait --for=condition=ready pod \
  -l user=${USERNAME} \
  -n ${NAMESPACE} \
  --timeout=300s || echo "Timeout - check manually"

echo ""

echo -e "${YELLOW}[5/5] Checking deployment status...${NC}"
kubectl get pods -n ${NAMESPACE} -l user=${USERNAME}
echo ""

echo -e "${GREEN}========================================"
echo "Webtop Created Successfully!"
echo "========================================${NC}"
echo ""
echo -e "${YELLOW}Access Information:${NC}"
echo "  URL: https://${USERNAME}.${DOMAIN}"
echo "  Username: admin"
echo "  Password: $PASSWORD"
echo ""
echo -e "${YELLOW}Password saved to:${NC} /root/webtop-${USERNAME}-password.txt"
echo ""
echo -e "${GREEN}SSL certificate will be automatically generated by Let's Encrypt${NC}"
echo -e "${GREEN}It may take 1-2 minutes for SSL to be ready${NC}"
echo ""
echo "To delete this webtop:"
echo "  kubectl delete deployment,svc,pvc,ingress,secret -n ${NAMESPACE} -l user=${USERNAME}"
echo ""
