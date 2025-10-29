#!/bin/bash
#
# Webtop Client Installer - Docker Standalone
# این اسکریپت را روی سرور خودتان اجرا کنید
# نیازی به دسترسی به کلاستر ندارد
#
# Usage: sudo bash client-install-webtop.sh
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
MANAGEMENT_SERVER="94.182.92.207"
MANAGEMENT_PORT="8080"

clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Webtop Ubuntu Desktop - Client Installer     ║${NC}"
echo -e "${BLUE}║              HaioCloud Platform                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Please run as root (use sudo)${NC}"
    exit 1
fi

# Get server information
SERVER_IP=$(curl -s -4 icanhazip.com 2>/dev/null || echo "unknown")
echo -e "${GREEN}Your server IP: ${SERVER_IP}${NC}"
echo ""

# Ask for location
echo -e "${YELLOW}Select your server location:${NC}"
echo "1) Iran (uses ArvanCloud Docker mirror)"
echo "2) International (direct Docker Hub)"
read -p "Enter choice (1 or 2): " LOCATION_CHOICE
echo ""

# Ask for username
read -p "Enter your desired username (lowercase letters/numbers only): " USERNAME

# Validate username
if ! [[ "$USERNAME" =~ ^[a-z0-9]+$ ]]; then
    echo -e "${RED}Error: Username must contain only lowercase letters and numbers${NC}"
    exit 1
fi

# Ask for access method
echo ""
echo -e "${YELLOW}Select access method:${NC}"
echo "1) IP Address (http://${SERVER_IP})"
echo "2) Domain Name (requires DNS configuration)"
read -p "Enter choice (1 or 2): " ACCESS_METHOD
echo ""

DOMAIN_NAME=""
if [ "$ACCESS_METHOD" = "2" ]; then
    read -p "Enter your domain name (e.g., desktop.example.com): " DOMAIN_NAME
    echo ""
    echo -e "${YELLOW}⚠️  Important: Configure your DNS before continuing!${NC}"
    echo "Add an A record:"
    echo "  ${DOMAIN_NAME} → ${SERVER_IP}"
    echo ""
    read -p "DNS is configured? (yes/no): " DNS_CONFIRM
    if [ "$DNS_CONFIRM" != "yes" ]; then
        echo -e "${RED}Please configure DNS first, then run this script again${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}Installation Summary:${NC}"
echo "  Username: ${USERNAME}"
echo "  Server IP: ${SERVER_IP}"
echo "  Location: $([ "$LOCATION_CHOICE" = "1" ] && echo "Iran (ArvanCloud)" || echo "International")"
echo "  Access: $([ "$ACCESS_METHOD" = "1" ] && echo "IP (http://${SERVER_IP})" || echo "Domain (https://${DOMAIN_NAME})")"
echo ""
read -p "Continue with installation? (yes/no): " INSTALL_CONFIRM
if [ "$INSTALL_CONFIRM" != "yes" ]; then
    echo "Installation cancelled"
    exit 0
fi

echo ""
echo -e "${GREEN}Starting installation...${NC}"
echo ""

# Step 1: Configure Docker mirror for Iran
if [ "$LOCATION_CHOICE" = "1" ]; then
    echo -e "${YELLOW}[1/8] Configuring ArvanCloud Docker mirror...${NC}"
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOF
    echo -e "${GREEN}✓ Docker mirror configured${NC}"
else
    echo -e "${YELLOW}[1/8] Skipping Docker mirror configuration...${NC}"
fi

# Step 2: Update system
echo -e "${YELLOW}[2/8] Updating system packages...${NC}"
apt-get update -qq > /dev/null 2>&1
apt-get install -y curl wget openssl nginx certbot python3-certbot-nginx -qq > /dev/null 2>&1
echo -e "${GREEN}✓ System updated${NC}"

# Step 3: Install Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}[3/8] Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh > /dev/null 2>&1
    rm get-docker.sh
    systemctl enable docker > /dev/null 2>&1
    systemctl start docker
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${YELLOW}[3/8] Docker already installed${NC}"
    if [ "$LOCATION_CHOICE" = "1" ]; then
        systemctl restart docker
        echo -e "${GREEN}✓ Docker restarted with new mirror${NC}"
    fi
fi

# Step 4: Generate password
echo -e "${YELLOW}[4/8] Generating secure password...${NC}"
PASSWORD=$(openssl rand -base64 18)
mkdir -p /root/webtop
echo "$PASSWORD" > /root/webtop/password.txt
echo -e "${GREEN}✓ Password generated${NC}"

# Step 5: Create Docker Compose file
echo -e "${YELLOW}[5/8] Creating Docker configuration...${NC}"
cat > /root/webtop/docker-compose.yml <<EOF
version: '3'
services:
  webtop:
    image: lscr.io/linuxserver/webtop:alpine-kde
    container_name: webtop-${USERNAME}
    security_opt:
      - seccomp:unconfined
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Tehran
      - CUSTOM_USER=admin
      - PASSWORD=${PASSWORD}
      - CUSTOM_PORT=3000
      - DISABLE_HTTPS=true
      - SUBFOLDER=/
      - TITLE=Webtop - ${USERNAME}
    volumes:
      - /root/webtop/data:/config
    ports:
      - "127.0.0.1:3000:3000"
    shm_size: "1gb"
    restart: unless-stopped
EOF
echo -e "${GREEN}✓ Docker Compose created${NC}"

# Step 6: Pull and start container
echo -e "${YELLOW}[6/8] Downloading Webtop image (this may take a few minutes)...${NC}"
cd /root/webtop
docker compose pull > /dev/null 2>&1
echo -e "${GREEN}✓ Image downloaded${NC}"

echo -e "${YELLOW}[6/8] Starting Webtop container...${NC}"
docker compose up -d
sleep 5
echo -e "${GREEN}✓ Container started${NC}"

# Step 7: Configure Nginx
echo -e "${YELLOW}[7/8] Configuring Nginx reverse proxy...${NC}"

if [ "$ACCESS_METHOD" = "2" ]; then
    # Domain with Let's Encrypt SSL
    systemctl stop nginx > /dev/null 2>&1
    certbot certonly --standalone -d "$DOMAIN_NAME" --non-interactive --agree-tos --register-unsafely-without-email
    
    cat > /etc/nginx/sites-available/webtop <<EOF
server {
    listen 80;
    server_name ${DOMAIN_NAME};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN_NAME};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffering off;
        proxy_read_timeout 86400;
    }
}
EOF
    ACCESS_URL="https://${DOMAIN_NAME}"
else
    # IP with HTTP
    cat > /etc/nginx/sites-available/webtop <<EOF
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_buffering off;
        proxy_read_timeout 86400;
    }
}
EOF
    ACCESS_URL="http://${SERVER_IP}"
fi

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/webtop /etc/nginx/sites-enabled/
nginx -t > /dev/null 2>&1
systemctl restart nginx
echo -e "${GREEN}✓ Nginx configured${NC}"

# Step 8: Save installation info
echo -e "${YELLOW}[8/8] Saving installation information...${NC}"
cat > /root/webtop/info.txt <<EOF
╔═══════════════════════════════════════════════════╗
║        Webtop Ubuntu Desktop - Access Info        ║
╚═══════════════════════════════════════════════════╝

Installation Date: $(date)

Access Information:
  URL:      ${ACCESS_URL}
  Username: admin
  Password: ${PASSWORD}

User Information:
  Username: ${USERNAME}
  Server IP: ${SERVER_IP}
  $([ "$ACCESS_METHOD" = "2" ] && echo "Domain: ${DOMAIN_NAME}")

Technical Details:
  Container: webtop-${USERNAME}
  Data Dir: /root/webtop/data
  Password File: /root/webtop/password.txt
  Compose File: /root/webtop/docker-compose.yml

Management Commands:
  Status:   docker ps
  Logs:     docker logs webtop-${USERNAME}
  Restart:  cd /root/webtop && docker compose restart
  Stop:     cd /root/webtop && docker compose stop
  Start:    cd /root/webtop && docker compose start
  Remove:   cd /root/webtop && docker compose down -v

Nginx Commands:
  Status:   systemctl status nginx
  Restart:  systemctl restart nginx
  Logs:     tail -f /var/log/nginx/error.log

$([ "$ACCESS_METHOD" = "2" ] && echo "SSL Certificate:
  Renew:    certbot renew
  Location: /etc/letsencrypt/live/${DOMAIN_NAME}/")
EOF

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""

# Display final information
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Installation Completed Successfully!     ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
cat /root/webtop/info.txt
echo ""
echo -e "${YELLOW}Open your browser and go to:${NC}"
echo -e "${GREEN}${ACCESS_URL}${NC}"
echo ""
echo -e "${YELLOW}Login with:${NC}"
echo -e "Username: ${GREEN}admin${NC}"
echo -e "Password: ${GREEN}${PASSWORD}${NC}"
echo ""
echo -e "${BLUE}Installation info saved to: /root/webtop/info.txt${NC}"
echo ""
