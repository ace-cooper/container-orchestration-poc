#!/bin/bash

# Set error handling
set -e

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 Starting container orchestration setup...${NC}"

# Update and upgrade system packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Run Docker setup
echo -e "${YELLOW}🐳 Setting up Docker...${NC}"
./setup_docker.sh
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker setup completed successfully.${NC}"
    
    # Run K3s setup
    echo -e "${YELLOW}☸️  Setting up K3s...${NC}"
    ./setup_k3s.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ K3s setup completed successfully.${NC}"
        
        # Run monitoring setup
        echo -e "${YELLOW}📊 Setting up monitoring...${NC}"
        ./setup_monitoring.sh
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Monitoring setup completed successfully.${NC}"
            echo -e "${BLUE}🎉 All components have been set up successfully!${NC}"
        else
            echo -e "${RED}❌ Error: Monitoring setup failed.${NC}"
            exit 3
        fi
    else
        echo -e "${RED}❌ Error: K3s setup failed.${NC}"
        exit 2
    fi
else
    echo -e "${RED}❌ Error: Docker setup failed.${NC}"
    exit 1
fi