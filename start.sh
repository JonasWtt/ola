#!/bin/bash

# Super Simple Start Script
# Run this to start everything with one command

set -euo pipefail

echo "=========================================="
echo "  Starting Local AI Setup"
echo "=========================================="
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not found. Please install Docker first."
    exit 1
fi

# Create data directories
mkdir -p data logs config/searxng data/ssh data/huggingface data/local data/fastembed

# Start Odysseus + dependencies
echo "Starting Odysseus (with search, memory, notifications)..."
docker compose -f docker-compose.simple.yml up -d

# Start Llama 3 8B model (best default)
echo "Starting Llama 3 8B model server..."
docker compose -f docker-compose.vllm.llama3-8b.yml up -d

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Access Odysseus AI at:"
echo "  http://localhost:7000"
echo "  http://$(hostname -I | awk '{print $1}'):7000"
echo ""
echo "Default login:"
echo "  Username: admin"
echo "  Password: $(docker compose -f docker-compose.simple.yml logs odysseus 2>/dev/null | grep -i "Password:" | tail -1 | sed 's/.*Password: //' | tr -d '"' || echo 'Check logs with: docker compose -f docker-compose.simple.yml logs odysseus | grep -i password')"
echo ""
echo "To stop everything:"
echo "  docker compose -f docker-compose.simple.yml down"
echo "  docker compose -f docker-compose.vllm.llama3-8b.yml down"
echo ""
