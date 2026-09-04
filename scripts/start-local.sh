#!/bin/bash

# Local Startup Script for Odysseus + vLLM
# This script provides a comfortable local development experience
# Usage: ./start-local.sh [model-file]
# Example: ./start-local.sh docker-compose.vllm.llama3-8b.yml

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default model
DEFAULT_VLLM_FILE="docker-compose.vllm.llama3-8b.yml"
ODYSSEUS_FILE="docker-compose.odysseus.local.yml"

# Function to check if a container is running
container_running() {
    docker compose -f "$1" ps | grep -q "Up"
}

# Function to get admin password
default_admin_password() {
    # Try to extract password from logs
    local password
    password=$(docker compose -f "$ODYSSEUS_FILE" logs odysseus 2>/dev/null | grep -i "password" | tail -1 | sed -n 's/.*Password: \([^ ]*\).*/\1/p' || true)
    
    if [ -n "$password" ]; then
        echo "$password"
    else
        echo "Not found in logs - check docker compose logs odysseus"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}ERROR: Docker is not installed. Please install Docker first.${NC}"
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        echo -e "${RED}ERROR: Docker Compose is not available. Please install Docker Compose v2+.${NC}"
        exit 1
    fi
    
    # Check NVIDIA Container Toolkit
    if ! nvidia-smi &> /dev/null; then
        echo -e "${YELLOW}WARNING: NVIDIA drivers may not be installed. vLLM requires GPU support.${NC}"
    fi
    
    if ! nvidia-container-cli --version &> /dev/null; then
        echo -e "${YELLOW}WARNING: NVIDIA Container Toolkit may not be installed. vLLM requires this for GPU access.${NC}"
    fi
    
    echo -e "${GREEN}✓ All prerequisites checked${NC}"
}

# Function to create data directories
create_directories() {
    echo -e "${BLUE}Creating data directories...${NC}"
    
    mkdir -p data
    mkdir -p logs
    mkdir -p config/searxng
    mkdir -p data/ssh
    mkdir -p data/huggingface
    mkdir -p data/local
    mkdir -p data/fastembed
    
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Function to copy example config if not exists
copy_example_config() {
    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        echo -e "${BLUE}Copying .env.example to .env...${NC}"
        cp .env.example .env
        echo -e "${YELLOW}Please edit .env to set your ODYSSEUS_ADMIN_PASSWORD before first run!${NC}"
    fi
}

# Function to start vLLM server
start_vllm() {
    local vllm_file="$1"
    
    echo -e "${BLUE}Starting vLLM server with $vllm_file...${NC}"
    
    if container_running "$vllm_file"; then
        echo -e "${YELLOW}vLLM server is already running. Restarting...${NC}"
        docker compose -f "$vllm_file" down
        sleep 2
    fi
    
    docker compose -f "$vllm_file" pull
    docker compose -f "$vllm_file" up -d
    
    # Wait for vLLM to start
    echo -e "${BLUE}Waiting for vLLM server to initialize...${NC}"
    local max_attempts=30
    local attempt=0
    local ready=false
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:8000/v1/models &> /dev/null; then
            ready=true
            break
        fi
        attempt=$((attempt + 1))
        sleep 10
        echo -e "${BLUE}Waiting for vLLM (attempt $attempt/$max_attempts)...${NC}"
    done
    
    if [ "$ready" = true ]; then
        echo -e "${GREEN}✓ vLLM server is ready!${NC}"
        curl -s http://localhost:8000/v1/models | head -20
    else
        echo -e "${RED}ERROR: vLLM server did not start within the expected time.${NC}"
        echo -e "${YELLOW}Check logs with: docker compose -f $vllm_file logs${NC}"
        exit 1
    fi
}

# Function to start Odysseus
start_odysseus() {
    echo -e "${BLUE}Starting Odysseus AI...${NC}"
    
    if container_running "$ODYSSEUS_FILE"; then
        echo -e "${YELLOW}Odysseus is already running. Restarting...${NC}"
        docker compose -f "$ODYSSEUS_FILE" down
        sleep 2
    fi
    
    docker compose -f "$ODYSSEUS_FILE" pull
    docker compose -f "$ODYSSEUS_FILE" up -d
    
    # Wait for Odysseus to start
    echo -e "${BLUE}Waiting for Odysseus to initialize...${NC}"
    local max_attempts=30
    local attempt=0
    local ready=false
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:7000/health &> /dev/null; then
            ready=true
            break
        fi
        attempt=$((attempt + 1))
        sleep 10
        echo -e "${BLUE}Waiting for Odysseus (attempt $attempt/$max_attempts)...${NC}"
    done
    
    if [ "$ready" = true ]; then
        echo -e "${GREEN}✓ Odysseus is ready!${NC}"
    else
        echo -e "${RED}ERROR: Odysseus did not start within the expected time.${NC}"
        echo -e "${YELLOW}Check logs with: docker compose -f $ODYSSEUS_FILE logs odysseus${NC}"
        exit 1
    fi
}

# Function to display access information
show_access_info() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}       LOCAL AI SETUP READY!        ${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    echo -e "${BLUE}Access URLs:${NC}"
    echo -e "  Odysseus AI:    http://localhost:7000"
    echo -e "  vLLM API:      http://localhost:8000/v1"
    echo -e "  SearXNG:       http://localhost:8080"
    echo -e "  ChromaDB:      http://localhost:8100"
    echo -e "  ntfy:          http://localhost:8091\n"
    
    echo -e "${BLUE}Default Credentials:${NC}"
    echo -e "  Username: admin"
    
    local password
    password=$(default_admin_password)
    echo -e "  Password: $password\n"
    
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "  View Odysseus logs:    docker compose -f $ODYSSEUS_FILE logs -f odysseus"
    echo -e "  View vLLM logs:        docker compose -f $VLLM_FILE logs -f"
    echo -e "  Stop all services:     docker compose -f $ODYSSEUS_FILE down && docker compose -f $VLLM_FILE down"
    echo -e "  Check GPU usage:       nvidia-smi"
    echo -e "  Check service status:  docker ps\n"
    
    echo -e "${GREEN}========================================${NC}\n"
}

# Main script
main() {
    # Check prerequisites
    check_prerequisites
    
    # Create directories
    create_directories
    
    # Copy example config
    copy_example_config
    
    # Determine vLLM file
    VLLM_FILE=${1:-$DEFAULT_VLLM_FILE}
    
    if [ ! -f "$VLLM_FILE" ]; then
        echo -e "${RED}ERROR: vLLM compose file '$VLLM_FILE' not found.${NC}"
        echo -e "${YELLOW}Available files:${NC}"
        ls -1 docker-compose.vllm*.yml 2>/dev/null || echo "No vLLM compose files found"
        exit 1
    fi
    
    echo -e "${BLUE}Starting Local AI Setup${NC}"
    echo -e "  vLLM config: $VLLM_FILE"
    echo -e "  Odysseus config: $ODYSSEUS_FILE"
    echo ""
    
    # Start services
    start_vllm "$VLLM_FILE"
    start_odysseus
    
    # Show access information
    show_access_info
    
    echo -e "${GREEN}Setup complete! Open http://localhost:7000 in your browser.${NC}"
}

# Run main
main "$@"
