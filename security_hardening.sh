#!/bin/bash

# Script de Hardening de Segurança para AWS EC2 + Crafty
# Execute assim: sudo bash security_hardening.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}===============================================${NC}"
echo -e "${YELLOW}AWS EC2 - Security Hardening${NC}"
echo -e "${YELLOW}===============================================${NC}"
echo ""

# Verificar se é root
if [ "$EUID" -ne 0 ]; then 
   echo -e "${RED}Execute com sudo!${NC}"
   exit 1
fi

# 1. Atualizar sistema
echo -e "${YELLOW}1. Atualizando sistema...${NC}"
apt update && apt upgrade -y && apt autoremove -y
echo -e "${GREEN}✓ Sistema atualizado${NC}\n"

# 2. Instalar UFW (firewall)
echo -e "${YELLOW}2. Configurando firewall (UFW)...${NC}"
apt install ufw -y

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 25565/tcp # Minecraft
ufw --force enable

echo -e "${GREEN}✓ Firewall configurado${NC}"
echo "  Portas abertas: 22, 80, 443, 25565"
echo ""

# 3. Hardening SSH
echo -e "${YELLOW}3. Configurando SSH...${NC}"

# Backup do arquivo original
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Desabilitar root login
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

# Desabilitar password auth (apenas chaves)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

# Habilitar pubkey auth
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

# Mudar porta SSH (opcional - comentado)
# sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config

systemctl restart sshd

echo -e "${GREEN}✓ SSH hardened${NC}"
echo "  - Root login desabilidado"
echo "  - Apenas chaves permitidas"
echo ""

# 4. Instalar Fail2ban
echo -e "${YELLOW}4. Instalando Fail2ban (proteção brute force)...${NC}"
apt install fail2ban -y

# Criar configuração local
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

systemctl enable fail2ban
systemctl restart fail2ban

echo -e "${GREEN}✓ Fail2ban instalado${NC}"
echo "  Proteção contra brute force: 3 tentativas em 10min = 1h bloqueado"
echo ""

# 5. Atualização automática
echo -e "${YELLOW}5. Configurando atualizações automáticas...${NC}"
apt install unattended-upgrades apt-listchanges -y

# Habilitar atualizações automáticas
dpkg-reconfigure -plow unattended-upgrades

echo -e "${GREEN}✓ Atualizações automáticas ativadas${NC}\n"

# 6. Audit logging
echo -e "${YELLOW}6. Configurando auditoria...${NC}"
apt install auditd -y
systemctl enable auditd
systemctl start auditd

echo -e "${GREEN}✓ Auditoria ativada${NC}\n"

# 7. Instalar ferramentas de segurança
echo -e "${YELLOW}7. Instalando ferramentas de segurança...${NC}"
apt install curl wget git htop iotop net-tools -y

echo -e "${GREEN}✓ Ferramentas instaladas${NC}\n"

# 8. Informações úteis
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}✓ Hardening Completo!${NC}"
echo -e "${GREEN}===============================================${NC}"
echo ""
echo "Próximas ações:"
echo "  1. Verificar firewall:"
echo "     sudo ufw status verbose"
echo ""
echo "  2. Verificar Fail2ban:"
echo "     sudo fail2ban-client status sshd"
echo ""
echo "  3. Ver logs de segurança:"
echo "     sudo tail -f /var/log/auth.log"
echo ""
echo "  4. Agora instalar Crafty:"
echo "     sudo ./setup_deploy.sh"
echo ""
