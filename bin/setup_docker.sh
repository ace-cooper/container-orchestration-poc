#!/bin/bash

# Atualiza o sistema
sudo apt-get update -y
sudo apt-get upgrade -y

# Instala dependências
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Adiciona chave GPG oficial do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Adiciona repositório do Docker
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instala Docker Engine
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Adiciona usuário atual ao grupo docker
sudo usermod -aG docker $USER

# Configura Docker para iniciar com o sistema
sudo systemctl enable docker
sudo systemctl start docker

# Instala Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verifica instalação
echo "Docker version:"
docker --version
echo "Docker Compose version:"
docker-compose --version

echo "Docker installed successfully! Please log out and log back in to apply group changes."