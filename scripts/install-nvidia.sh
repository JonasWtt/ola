#!/bin/bash

# One-shot NVIDIA Installation Script
# Installs NVIDIA drivers + NVIDIA Container Toolkit
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
echo -e "${BLUE}  NVIDIA Drivers + Container Toolkit Install${NC}"
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

# Check for NVIDIA GPU
if ! lspci | grep -i nvidia &> /dev/null; then
    echo -e "${RED}ERROR: No NVIDIA GPU detected!${NC}"
    echo -e "${RED}This script requires an NVIDIA GPU.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ NVIDIA GPU detected${NC}"
echo ""

# ============================================
# Part 1: Install NVIDIA Drivers
# ============================================

# Check if drivers are already installed
if nvidia-smi &> /dev/null; then
    echo -e "${YELLOW}NVIDIA drivers appear to be already installed.${NC}"
    echo -e "${YELLOW}Driver version: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo 'unknown')${NC}"
    read -p "Do you want to reinstall drivers? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        DRIVER_INSTALLED=true
    else
        DRIVER_INSTALLED=false
    fi
else
    DRIVER_INSTALLED=false
fi

if [ "$DRIVER_INSTALLED" = false ]; then
    echo -e "${BLUE}[1/3] Installing NVIDIA drivers...${NC}"
    
    # Add NVIDIA apt repository
    if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
        # Add the official NVIDIA driver PPA
        if [ "$DISTRO" = "ubuntu" ]; then
            add-apt-repository -y ppa:graphics-drivers/ppa
        fi
        
        # Update package list
        apt-get update -qq
        
        # Install NVIDIA drivers
        # For Ubuntu 22.04/24.04 and Debian, use the recommended driver
        if [ "$DISTRO" = "ubuntu" ] && [[ "$VERSION" =~ ^2[24]\.04 ]]; then
            # Use the recommended driver package
            apt-get install -y -qq ubuntu-drivers-common
            
            # Auto-detect and install recommended driver
            if command -v ubuntu-drivers &> /dev/null; then
                echo -e "${BLUE}Detecting recommended NVIDIA driver...${NC}"
                RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep recommended | head -1 | awk '{print $3}')
                if [ -n "$RECOMMENDED_DRIVER" ]; then
                    echo -e "${BLUE}Installing recommended driver: $RECOMMENDED_DRIVER${NC}"
                    apt-get install -y -qq "$RECOMMENDED_DRIVER"
                else
                    # Fallback to nvidia-driver-535
                    echo -e "${BLUE}Installing fallback driver: nvidia-driver-535${NC}"
                    apt-get install -y -qq nvidia-driver-535
                fi
            else
                # Fallback
                apt-get install -y -qq nvidia-driver-535
            fi
        else
            # Generic fallback
            apt-get install -y -qq nvidia-driver-535
        fi
        
        echo -e "${GREEN}✓ NVIDIA drivers installed${NC}"
    else
        echo -e "${RED}ERROR: Unsupported distribution for automatic driver installation: $DISTRO${NC}"
        echo -e "${YELLOW}Please install NVIDIA drivers manually from:${NC}"
        echo -e "${YELLOW}  https://www.nvidia.com/Download/index.aspx${NC}"
        exit 1
    fi
    
    echo ""
else
    echo -e "${BLUE}Skipping NVIDIA driver installation.${NC}"
    echo ""
fi

# ============================================
# Part 2: Install NVIDIA Container Toolkit
# ============================================

echo -e "${BLUE}[2/3] Installing NVIDIA Container Toolkit...${NC}"

# Install prerequisites
apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg2

# Add NVIDIA Container Toolkit repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Get the distribution codename
CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME:-$UBUNTU_CODENAME}")
ARCH=$(dpkg --print-architecture)

# Add the repository
cat > /etc/apt/sources.list.d/nvidia-container-toolkit.list <<EOF
Types: deb
URIs: https://nvidia.github.io/libnvidia-container/stable/deb/${DISTRO}
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
EOF

# Update package list
apt-get update -qq

# Install NVIDIA Container Toolkit
apt-get install -y -qq \
    nvidia-container-toolkit \
    nvidia-container-toolkit-base \
    libnvidia-container-tools \
    libnvidia-container1

# Configure Docker to use NVIDIA Container Runtime
nvidia-ctk runtime configure --runtime=docker

# Restart Docker to pick up changes
if systemctl is-active --quiet docker; then
    echo -e "${BLUE}Restarting Docker to enable NVIDIA support...${NC}"
    systemctl restart docker
fi

echo -e "${GREEN}✓ NVIDIA Container Toolkit installed${NC}"
echo ""

# ============================================
# Part 3: Verify Installation
# ============================================

echo -e "${BLUE}[3/3] Verifying installation...${NC}"

# Check NVIDIA drivers
if nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA drivers working: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || nvidia-smi | head -1 | awk '{print $6}')${NC}"
else
    echo -e "${RED}✗ NVIDIA drivers not working${NC}"
    echo -e "${YELLOW}You may need to reboot your system.${NC}"
    DRIVER_OK=false
fi

# Check NVIDIA Container Toolkit
if command -v nvidia-container-cli &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA Container Toolkit: $(nvidia-container-cli --version 2>/dev/null | head -1)${NC}"
else
    echo -e "${RED}✗ NVIDIA Container Toolkit not found${NC}"
    TOOLKIT_OK=false
fi

# Check Docker NVIDIA support
if command -v docker &> /dev/null; then
    # Test if Docker can see NVIDIA runtime
    if docker info | grep -q "nvidia"; then
        echo -e "${GREEN}✓ Docker NVIDIA runtime configured${NC}"
    else
        echo -e "${YELLOW}⚠ Docker NVIDIA runtime may need Docker restart${NC}"
        echo -e "${YELLOW}Try: sudo systemctl restart docker${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Docker not installed - NVIDIA Container Toolkit ready for when Docker is installed${NC}"
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  NVIDIA Installation Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# Show GPU info
if command -v nvidia-smi &> /dev/null; then
    echo -e "${BLUE}GPU Information:${NC}"
    nvidia-smi
    echo ""
fi

echo -e "${BLUE}If you see GPU information above, everything is working!${NC}"
echo ""

if [ "$DRIVER_INSTALLED" = false ] && [ "$DRIVER_OK" != false ]; then
    echo -e "${BLUE}You may need to reboot for driver changes to take effect.${NC}"
    echo ""
fi

echo -e "${BLUE}To test NVIDIA in Docker (optional):${NC}"
echo "  docker run --rm --gpus all nvidia/cuda:12.9.0-base-ubuntu22.04 nvidia-smi"
echo ""
