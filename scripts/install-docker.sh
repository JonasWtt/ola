#!/bin/bash

# One-shot Docker Installation Script
# Installs Docker Engine + Docker Compose from official apt repository
# Does NOT run any test containers
# Tested on Ubuntu/Debian

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Docker Installation Script${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Detect OS
OS_RELEASE="/etc/os-release"
if [ ! -f "$OS_RELEASE" ]; then
    echo -e "${RED}ERROR: Cannot detect Linux distribution${NC}"
    exit 1
fi

. /etc/os-release
DISTRO="${ID:-unknown}"
VERSION="${VERSION_ID:-unknown}"

echo -e "${BLUE}Detected OS: ${DISTRO} ${VERSION}${NC}"
echo ""

# Check if already installed
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Docker and Docker Compose appear to be already installed.${NC}"
    echo -e "${YELLOW}Docker version: $(docker --version 2>/dev/null || echo 'unknown')${NC}"
    echo -e "${YELLOW}Docker Compose version: $(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null || echo 'unknown')${NC}"
    read -p "Do you want to reinstall? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Skipping installation.${NC}"
        exit 0
    fi
fi

# Step 1: Install prerequisites
echo -e "${BLUE}[1/4] Installing prerequisites...${NC}"
apt-get update -qq
apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo -e "${GREEN}✓ Prerequisites installed${NC}"
echo ""

# Step 2: Add Docker's official GPG key
echo -e "${BLUE}[2/4] Adding Docker GPG key...${NC}"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/${DISTRO}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo -e "${GREEN}✓ Docker GPG key added${NC}"
echo ""

# Step 3: Add Docker apt repository
echo -e "${BLUE}[3/4] Adding Docker apt repository...${NC}"
ARCH=$(dpkg --print-architecture)
CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME:-$UBUNTU_CODENAME}")

# Create the repository source file
cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO} ${CODENAME} stable
EOF

# Update package index
apt-get update -qq

echo -e "${GREEN}✓ Docker repository added${NC}"
echo ""

# Step 4: Install Docker Engine + Docker Compose
echo -e "${BLUE}[4/4] Installing Docker Engine and Docker Compose...${NC}"

# Install Docker packages
apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo -e "${GREEN}✓ Docker packages installed${NC}"
echo ""

# Step 5: Start Docker service
echo -e "${BLUE}Starting Docker service...${NC}"
systemctl enable docker
systemctl start docker

echo -e "${GREEN}✓ Docker service started${NC}"
echo ""

# Verify installation
echo -e "${BLUE}Verifying installation...${NC}"

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker installed: $(docker --version)${NC}"
else
    echo -e "${RED}✗ Docker installation failed${NC}"
    exit 1
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose installed: $(docker compose version)${NC}"
else
    echo -e "${RED}✗ Docker Compose installation failed${NC}"
    exit 1
fi

# Check Docker service
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓ Docker service is running${NC}"
else
    echo -e "${RED}✗ Docker service is not running${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Docker Installation Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${BLUE}To use Docker without sudo:${NC}"
echo "  sudo usermod -aG docker \$USER"
echo "  Then log out and log back in"
echo ""
echo -e "${BLUE}Commands available:${NC}"
echo "  docker --version"
echo "  docker compose version"
echo "  docker run hello-world  (if you want to test)"
echo ""
