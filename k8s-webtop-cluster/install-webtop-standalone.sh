#!/bin/bash
#
# Webtop Desktop Installation Script - HaioCloud Edition
# Standalone Docker installer for individual servers
# Compatible with HaioCloud K8s cluster architecture
#
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/install-webtop.sh | bash
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Webtop Desktop Installer - HaioCloud       ║${NC}"
echo -e "${BLUE}║           Standalone Docker Edition               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run: sudo bash $0"
    exit 1
fi

# Ask for location selection
echo -e "${YELLOW}Select your server location:${NC}"
echo "1) Iran (uses ArvanCloud Docker mirror)"
echo "2) International (direct Docker Hub access)"
read -p "Enter your choice (1 or 2): " LOCATION_CHOICE
echo ""

# Ask for access method
echo -e "${YELLOW}Select access method:${NC}"
echo "1) IP address (HTTP only - simple and fast)"
echo "2) Domain name (HTTPS with Let's Encrypt SSL)"
read -p "Enter your choice (1 or 2): " ACCESS_CHOICE
echo ""

# If domain is selected, ask for domain name
DOMAIN_NAME=""
if [ "$ACCESS_CHOICE" = "2" ]; then
    read -p "Enter your domain name (e.g., desktop.example.com): " DOMAIN_NAME
    echo ""
    echo -e "${YELLOW}⚠️  Important: DNS must be configured BEFORE continuing!${NC}"
    echo "Add this DNS record:"
    echo -e "  Type: ${GREEN}A${NC}"
    echo -e "  Name: ${GREEN}${DOMAIN_NAME}${NC}"
    echo -e "  Value: ${GREEN}$(curl -s -4 icanhazip.com)${NC}"
    echo ""
    read -p "Is DNS already configured and propagated? (yes/no): " DNS_CONFIRM
    if [ "$DNS_CONFIRM" != "yes" ]; then
        echo -e "${RED}Please configure DNS first, then run this script again.${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Starting installation...${NC}"
echo ""

# Configure ArvanCloud mirror for Iran
if [ "$LOCATION_CHOICE" = "1" ]; then
    echo -e "${YELLOW}[1/9] Configuring ArvanCloud Docker mirror...${NC}"
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOF
    echo -e "${GREEN}✓ Docker mirror configured${NC}"
else
    echo -e "${YELLOW}[1/9] Skipping Docker mirror configuration${NC}"
fi
echo ""

# Update system and install dependencies
echo -e "${YELLOW}[2/9] Updating system packages...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null 2>&1
apt-get install -y curl wget openssl nginx -qq > /dev/null 2>&1

if [ "$ACCESS_CHOICE" = "2" ]; then
    apt-get install -y certbot python3-certbot-nginx -qq > /dev/null 2>&1
fi

echo -e "${GREEN}✓ System packages updated${NC}"
echo ""

# Install Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}[3/9] Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh > /dev/null 2>&1
    rm -f get-docker.sh
    systemctl enable docker > /dev/null 2>&1
    systemctl start docker
    echo -e "${GREEN}✓ Docker installed successfully${NC}"
else
    echo -e "${YELLOW}[3/9] Docker already installed${NC}"
    if [ "$LOCATION_CHOICE" = "1" ]; then
        systemctl restart docker
        echo -e "${GREEN}✓ Docker restarted with ArvanCloud mirror${NC}"
    fi
fi
echo ""

# Generate secure password
echo -e "${YELLOW}[4/9] Generating secure password...${NC}"
WEBTOP_PASSWORD=$(openssl rand -base64 18)
mkdir -p /root/webtop
echo "$WEBTOP_PASSWORD" > /root/webtop/password.txt
chmod 600 /root/webtop/password.txt
echo -e "${GREEN}✓ Password generated and saved${NC}"
echo ""

# Create Docker Compose configuration
echo -e "${YELLOW}[5/9] Creating Docker Compose configuration...${NC}"
cat > /root/webtop/docker-compose.yml <<EOF
version: '3.8'

services:
  webtop:
    image: lscr.io/linuxserver/webtop:alpine-kde
    container_name: webtop-desktop
    hostname: webtop
    security_opt:
      - seccomp:unconfined
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Tehran
      - CUSTOM_USER=admin
      - PASSWORD=${WEBTOP_PASSWORD}
      - CUSTOM_PORT=3000
      - DISABLE_HTTPS=true
      - SUBFOLDER=/
      - TITLE=Webtop Desktop
    volumes:
      - /root/webtop/data:/config
    ports:
      - "127.0.0.1:3000:3000"
    shm_size: "1gb"
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
EOF

echo -e "${GREEN}✓ Docker Compose file created${NC}"
echo ""

# Pull and start container
echo -e "${YELLOW}[6/9] Downloading Webtop image...${NC}"
echo -e "${YELLOW}This may take a few minutes depending on connection speed${NC}"
cd /root/webtop
docker compose pull 2>&1 | grep -v "^#" || true
echo -e "${GREEN}✓ Image downloaded${NC}"
echo ""

echo -e "${YELLOW}[6/9] Starting Webtop container...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Container started${NC}"
echo ""

# Wait for container to initialize
echo -e "${YELLOW}[7/9] Waiting for Webtop to initialize...${NC}"
sleep 8

# Check if container is running
if ! docker ps | grep -q webtop-desktop; then
    echo -e "${RED}✗ Container failed to start${NC}"
    echo "Checking logs:"
    docker logs webtop-desktop
    exit 1
fi
echo -e "${GREEN}✓ Webtop is running${NC}"
echo ""

# Configure Nginx based on access method
echo -e "${YELLOW}[8/9] Configuring Nginx reverse proxy...${NC}"

if [ "$ACCESS_CHOICE" = "2" ]; then
    # Domain with Let's Encrypt SSL
    echo -e "${YELLOW}Obtaining SSL certificate from Let's Encrypt...${NC}"
    systemctl stop nginx > /dev/null 2>&1 || true
    certbot certonly --standalone -d "$DOMAIN_NAME" \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email \
        --preferred-challenges http
    
    cat > /etc/nginx/sites-available/webtop <<EOF
# HTTP - Redirect to HTTPS
server {
    listen 80;
    server_name ${DOMAIN_NAME};
    return 301 https://\$server_name\$request_uri;
}

# HTTPS - Main configuration
server {
    listen 443 ssl http2;
    server_name ${DOMAIN_NAME};

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy configuration
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
        
        # Buffering
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF
    ACCESS_URL="https://${DOMAIN_NAME}"
    
else
    # IP access - HTTP only (simpler, no SSL issues)
    SERVER_IP=$(curl -s -4 icanhazip.com || echo "127.0.0.1")
    
    cat > /etc/nginx/sites-available/webtop <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # Proxy configuration
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        # Timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
        
        # Buffering
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF
    ACCESS_URL="http://${SERVER_IP}"
fi

# Enable Nginx site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/webtop /etc/nginx/sites-enabled/

# Test and start Nginx
if nginx -t > /dev/null 2>&1; then
    systemctl restart nginx
    echo -e "${GREEN}✓ Nginx configured and running${NC}"
else
    echo -e "${RED}✗ Nginx configuration error${NC}"
    nginx -t
    exit 1
fi
echo ""

# Create management scripts
echo -e "${YELLOW}[9/9] Creating management scripts...${NC}"

# Status script
cat > /root/webtop/status.sh <<'EOFSCRIPT'
#!/bin/bash
echo "======================================"
echo "Webtop Status"
echo "======================================"
echo ""
echo "Container Status:"
docker ps -a | grep webtop-desktop || echo "Container not found"
echo ""
echo "Resource Usage:"
docker stats --no-stream webtop-desktop 2>/dev/null || echo "Container not running"
echo ""
echo "Recent Logs (last 20 lines):"
docker logs --tail 20 webtop-desktop
EOFSCRIPT

# Restart script
cat > /root/webtop/restart.sh <<'EOFSCRIPT'
#!/bin/bash
echo "Restarting Webtop..."
cd /root/webtop
docker compose restart
echo "Webtop restarted successfully"
EOFSCRIPT

# Stop script
cat > /root/webtop/stop.sh <<'EOFSCRIPT'
#!/bin/bash
echo "Stopping Webtop..."
cd /root/webtop
docker compose stop
echo "Webtop stopped"
EOFSCRIPT

# Start script
cat > /root/webtop/start.sh <<'EOFSCRIPT'
#!/bin/bash
echo "Starting Webtop..."
cd /root/webtop
docker compose start
echo "Webtop started"
EOFSCRIPT

chmod +x /root/webtop/*.sh
echo -e "${GREEN}✓ Management scripts created${NC}"
echo ""

# Save installation info
cat > /root/webtop/info.txt <<EOF
╔═══════════════════════════════════════════════════╗
║        Webtop Desktop - Access Information        ║
╚═══════════════════════════════════════════════════╝

Installation Date: $(date '+%Y-%m-%d %H:%M:%S %Z')

ACCESS INFORMATION:
  URL:      ${ACCESS_URL}
  Username: admin
  Password: ${WEBTOP_PASSWORD}

SERVER DETAILS:
  IP Address: $(curl -s -4 icanhazip.com)
  $([ "$ACCESS_CHOICE" = "2" ] && echo "Domain: ${DOMAIN_NAME}")
  Location: $([ "$LOCATION_CHOICE" = "1" ] && echo "Iran (ArvanCloud)" || echo "International")
  
TECHNICAL INFO:
  Container: webtop-desktop
  Image: lscr.io/linuxserver/webtop:alpine-kde
  Desktop: KDE Plasma on Alpine Linux
  Data Directory: /root/webtop/data
  Password File: /root/webtop/password.txt
  
MANAGEMENT COMMANDS:
  Status:   bash /root/webtop/status.sh
  Restart:  bash /root/webtop/restart.sh
  Stop:     bash /root/webtop/stop.sh
  Start:    bash /root/webtop/start.sh
  
DOCKER COMMANDS:
  View logs:     docker logs webtop-desktop
  Follow logs:   docker logs -f webtop-desktop
  Shell access:  docker exec -it webtop-desktop bash
  Remove all:    cd /root/webtop && docker compose down -v
  
NGINX COMMANDS:
  Test config:   nginx -t
  Reload:        systemctl reload nginx
  Restart:       systemctl restart nginx
  Error logs:    tail -f /var/log/nginx/error.log

$([ "$ACCESS_CHOICE" = "2" ] && echo "SSL CERTIFICATE:
  Provider: Let's Encrypt
  Location: /etc/letsencrypt/live/${DOMAIN_NAME}/
  Renew: certbot renew
  Auto-renewal: Enabled via systemd timer")

FIREWALL SETUP:
  If using UFW:
    sudo ufw allow $([ "$ACCESS_CHOICE" = "2" ] && echo "80,443" || echo "80")/tcp
    
  If using iptables:
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    $([ "$ACCESS_CHOICE" = "2" ] && echo "sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT")

TROUBLESHOOTING:
  Container not starting:
    - Check logs: docker logs webtop-desktop
    - Check resources: docker stats
    
  Cannot access from browser:
    - Check firewall rules
    - Check nginx status: systemctl status nginx
    - Check DNS (if using domain)
    
  Performance issues:
    - Increase resources in docker-compose.yml
    - Check server load: top or htop

SUPPORT:
  Documentation: https://docs.linuxserver.io/images/docker-webtop
  Issues: Check /root/webtop/info.txt for commands
EOF

# Display installation summary
clear
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Installation Completed Successfully! 🎉     ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Access Your Desktop:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}🌐 URL:${NC}      ${ACCESS_URL}"
echo -e "  ${GREEN}👤 Username:${NC} admin"
echo -e "  ${GREEN}🔑 Password:${NC} ${WEBTOP_PASSWORD}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Important Notes:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  ✓ Desktop environment: KDE Plasma (modern and fast)"
echo "  ✓ All files saved in: /root/webtop/data"
echo "  ✓ Password saved in: /root/webtop/password.txt"
echo "  ✓ Container auto-starts on server reboot"
if [ "$ACCESS_CHOICE" = "1" ]; then
    echo "  ⚠️  Using HTTP (not encrypted) - OK for private networks"
else
    echo "  ✓ SSL certificate auto-renews every 60 days"
fi
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Quick Commands:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Check status:  bash /root/webtop/status.sh"
echo "  Restart:       bash /root/webtop/restart.sh"
echo "  View info:     cat /root/webtop/info.txt"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}🚀 Open your browser and navigate to:${NC}"
echo -e "${GREEN}   ${ACCESS_URL}${NC}"
echo ""
echo -e "${YELLOW}Complete information saved to: /root/webtop/info.txt${NC}"
echo ""
