#!/bin/bash

# Script de Setup Automático para Crafty Server
# Este script automatiza o deploy do servidor Crafty como serviço systemd

set -e

echo "==============================================="
echo "Crafty Server - Setup Automático"
echo "==============================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detectar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
   echo -e "${RED}Este script precisa ser executado como root (use sudo)${NC}"
   exit 1
fi

# Detectar diretório de instalação
INSTALL_DIR="/workspaces/server"
if [ ! -d "$INSTALL_DIR/minecraft" ]; then
    echo -e "${RED}Erro: Diretório $INSTALL_DIR não encontrado${NC}"
    exit 1
fi

echo -e "${YELLOW}Configuração encontrada em: $INSTALL_DIR${NC}"
echo ""

# Menu de opções
echo "Escolha o tipo de deploy:"
echo "1) Serviço Systemd (recomendado)"
echo "2) Docker"
echo "3) Sair"
echo ""
read -p "Opção (1-3): " OPTION

case $OPTION in
    1)
        echo -e "${YELLOW}Configurando como Serviço Systemd...${NC}"
        
        # Criar usuário crafty se não existir
        if ! id "crafty" &>/dev/null; then
            echo "Criando usuário crafty..."
            useradd -r -s /bin/bash -d /workspaces/server crafty
        fi
        
        # Dar permissões
        echo "Configurando permissões..."
        chown -R crafty:crafty "$INSTALL_DIR"
        
        # Copiar arquivo de serviço
        echo "Instalando serviço systemd..."
        cp "$INSTALL_DIR/minecraft/crafty.service" /etc/systemd/system/crafty.service
        
        # Atualizar caminhos no arquivo de serviço
        sed -i "s|/workspaces/server|$INSTALL_DIR|g" /etc/systemd/system/crafty.service
        
        # Recarregar systemd
        systemctl daemon-reload
        
        # Habilitar serviço
        systemctl enable crafty
        
        echo -e "${GREEN}✓ Serviço instalado com sucesso!${NC}"
        echo ""
        echo "Iniciando serviço..."
        systemctl start crafty
        
        # Esperar um pouco e verificar status
        sleep 2
        if systemctl is-active --quiet crafty; then
            echo -e "${GREEN}✓ Serviço iniciado com sucesso!${NC}"
        else
            echo -e "${RED}✗ Erro ao iniciar serviço${NC}"
            echo "Verifique com: sudo systemctl status crafty"
            exit 1
        fi
        
        echo ""
        echo "Próximas ações:"
        echo "  Ver status: sudo systemctl status crafty"
        echo "  Ver logs: sudo journalctl -u crafty -f"
        echo "  Parar: sudo systemctl stop crafty"
        echo "  Reiniciar: sudo systemctl restart crafty"
        ;;
        
    2)
        echo -e "${YELLOW}Configurando Docker...${NC}"
        
        # Verificar se Docker está instalado
        if ! command -v docker &> /dev/null; then
            echo -e "${RED}Docker não está instalado${NC}"
            read -p "Deseja instalar Docker? (s/n): " INSTALL_DOCKER
            if [ "$INSTALL_DOCKER" = "s" ]; then
                echo "Instalando Docker..."
                curl -fsSL https://get.docker.com -o get-docker.sh
                sh get-docker.sh
                rm get-docker.sh
            else
                exit 1
            fi
        fi
        
        # Construir imagem
        echo "Construindo imagem Docker..."
        cd "$INSTALL_DIR/minecraft/crafty-4"
        docker build -t crafty-server:latest .
        
        # Parar container anterior se existir
        if docker ps -a --format '{{.Names}}' | grep -q crafty; then
            echo "Removendo container anterior..."
            docker stop crafty 2>/dev/null || true
            docker rm crafty 2>/dev/null || true
        fi
        
        # Rodar container
        echo "Iniciando container..."
        docker run -d \
            --name crafty \
            -p 8443:8443 \
            -p 25565:25565 \
            -v "$INSTALL_DIR/minecraft/crafty-4/config":/opt/crafty/config \
            -v "$INSTALL_DIR/minecraft/crafty-4/servers":/opt/crafty/servers \
            -v "$INSTALL_DIR/minecraft/crafty-4/backups":/opt/crafty/backups \
            --restart always \
            crafty-server:latest
        
        echo -e "${GREEN}✓ Container iniciado com sucesso!${NC}"
        echo ""
        echo "Próximas ações:"
        echo "  Ver logs: docker logs -f crafty"
        echo "  Ver status: docker ps | grep crafty"
        echo "  Parar: docker stop crafty"
        echo "  Reiniciar: docker restart crafty"
        ;;
        
    3)
        echo "Abortado."
        exit 0
        ;;
        
    *)
        echo -e "${RED}Opção inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}Setup concluído com sucesso!${NC}"
echo -e "${GREEN}===============================================${NC}"
