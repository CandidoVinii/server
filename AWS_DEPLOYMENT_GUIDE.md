# Guia Completo: Deploy na AWS (Passo a Passo)

## ✅ Checklist Pré-Requisitos

- [ ] Conta AWS ativa
- [ ] Seu código em GitHub (com push feito)
- [ ] Arquivo .pem da chave salvo no computador

---

## 📋 PARTE 1: Criar Instância EC2

### Passo 1: Acessar AWS Console
1. Ir para https://console.aws.amazon.com
2. Procurar por **EC2** (ou ir direto em Services → EC2)
3. Clicar em **Launch instances** (ou "Executar instâncias")

### Passo 2: Escolher Imagem (AMI)
1. Procurar por **Ubuntu 22.04 LTS**
2. Certificar que está marcado **Free tier eligible**
3. Clicar **Select**

### Passo 3: Selecionar Tipo de Instância
```
Instance Type: t2.micro
✓ Free tier eligible
```

Clicar **Next: Configure Instance Details**

### Passo 4: Configurar Instância
```
Network: Default VPC
Subnet: Default subnet
Auto-assign Public IP: Enable (IMPORTANTE!)
IAM role: None
```

Clicar **Next: Add Storage**

### Passo 5: Storage
```
Volume size: 30 GB (máximo free tier)
Volume type: gp2
Delete on Termination: ✓ Checked
```

Clicar **Next: Add Tags**

### Passo 6: Tags (Opcional)
```
Name: crafty-minecraft
Environment: production
```

Clicar **Next: Configure Security Group**

### Passo 7: Security Group (IMPORTANTE!)

**Nome:** crafty-security-group

**Adicionar regras:**

| Type | Protocol | Port | Source |
|------|----------|------|--------|
| SSH | TCP | 22 | **My IP** ⚠️ |
| HTTP | TCP | 80 | 0.0.0.0/0 |
| HTTPS | TCP | 443 | 0.0.0.0/0 |
| Custom TCP | TCP | 25565 | 0.0.0.0/0 |
| Custom TCP | TCP | 8443 | 0.0.0.0/0 |

⚠️ **IMPORTANTE:** SSH deve ser seu IP, não 0.0.0.0!

### Passo 8: Review e Launch
1. Revisar configurações
2. Clicar **Launch**
3. Escolher chave SSH:
   - **Create a new key pair**
   - Nome: `crafty-key`
   - **Download Key Pair** (salvar em lugar seguro!)
4. Clicar **Launch Instances**

### Passo 9: Aguardar
Esperar status ficar em:
```
Instance State: running
Status Checks: 2/2 checks passed
```

---

## 📋 PARTE 2: Conectar via SSH

### No Windows PowerShell / Mac Terminal / Linux:

```bash
# 1. Ir para pasta onde salvou a chave
cd ~/Downloads  # ou onde salvou

# 2. Dar permissão à chave (importante!)
chmod 600 crafty-key.pem

# 3. Pegar IP da instância
# Ir em AWS Console → EC2 → Instances → copiar "Public IPv4"
# Exemplo: 54.123.456.789

# 4. Conectar via SSH
ssh -i crafty-key.pem ubuntu@54.123.456.789

# Responder "yes" quando perguntar
```

**Se conectou:** Parabéns! 🎉

---

## 📋 PARTE 3: Preparar a VM

### Passo 1: Atualizar Sistema
```bash
sudo apt update && sudo apt upgrade -y
```

### Passo 2: Instalar Dependências
```bash
sudo apt install -y \
  python3 \
  python3-venv \
  python3-pip \
  git \
  curl \
  wget \
  ufw \
  nginx \
  certbot \
  python3-certbot-nginx
```

### Passo 3: Clonar seu Repositório
```bash
# Ir para home
cd /home/ubuntu

# Clonar seu repo (troque URL pela sua)
git clone https://github.com/seu-usuario/server.git
cd server
```

### Passo 4: Rodar Security Hardening (Recomendado)
```bash
chmod +x security_hardening.sh
sudo bash security_hardening.sh
```

Responder:
```
Do you want to allow automatic updates? → Yes
```

---

## 📋 PARTE 4: Instalar Crafty com Systemd

### Passo 1: Preparar Virtual Environment
```bash
cd /home/ubuntu/server/minecraft
python3 -m venv .venv
source .venv/bin/activate
cd crafty-4
pip install -r requirements.txt
cd ..
```

### Passo 2: Rodar Setup
```bash
chmod +x ../setup_deploy.sh
sudo ../setup_deploy.sh
```

**Quando perguntar, escolher opção: 1 (Systemd)**

### Passo 3: Verificar Status
```bash
sudo systemctl status crafty
```

Deve mostrar:
```
● crafty.service - Crafty 4
   Loaded: loaded (/etc/systemd/system/crafty.service; enabled; ...)
   Active: active (running) since ...
```

---

## 📋 PARTE 5: Configurar Acesso Remoto

### Opção A: IP Direto (Simples)

1. Ir ao AWS Console → EC2 → Instances
2. Copiar **Public IPv4 Address**
3. Acessar: `https://seu-ip:8443`
4. Ignorar aviso de certificado

### Opção B: Com Domínio (Recomendado)

#### Subpasso 1: Ter um domínio
- Comprar em Namecheap, GoDaddy, etc
- Apontar DNS para IP da AWS

#### Subpasso 2: Configurar Nginx com SSL
```bash
# Na VM:
sudo nano /etc/nginx/sites-available/default
```

Substituir conteúdo por:
```nginx
# HTTP → HTTPS redirect
server {
    listen 80;
    server_name seu-dominio.com www.seu-dominio.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name seu-dominio.com www.seu-dominio.com;
    
    ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;
    
    location / {
        proxy_pass https://localhost:8443;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### Subpasso 3: Gerar Certificado SSL
```bash
sudo certbot certonly --standalone -d seu-dominio.com

# Se perguntar email, informar seu email
# Aceitar termos (Yes)
```

#### Subpasso 4: Ativar Nginx
```bash
sudo nginx -t  # Testar config
sudo systemctl enable nginx
sudo systemctl start nginx
```

---

## ✅ Verificações Finais

### Testar Acesso

```bash
# Via SSH na VM:
curl -k https://localhost:8443/
# Deve retornar HTML do Crafty

# Via navegador local:
# Opção A (IP): https://seu-ip:8443
# Opção B (Domínio): https://seu-dominio.com
```

### Ver Logs
```bash
# Logs do Crafty
sudo journalctl -u crafty -f

# Logs do Nginx
sudo tail -f /var/log/nginx/access.log
```

### Verificar Minecraft Server

```bash
# Cria um servidor Minecraft no painel Crafty
# URL: https://seu-ip:8443 (ou domínio)
# Username/Password: (padrão é admin/admin)
```

---

## 🔒 Segurança - Checklist Final

- [ ] SSH apenas do seu IP
- [ ] Security Hardening executado
- [ ] Firewall (UFW) ativado
- [ ] Fail2ban rodando
- [ ] HTTPS configurado (Let's Encrypt ou auto-signed)
- [ ] Atualizações automáticas ativadas
- [ ] IP Elástico alocado (opcional)

---

## 💰 Evitar Custos (Importante!)

1. **Alertas de Cobrança:**
   - AWS Console → Billing → Alerts
   - Ativar quando passar de $0.50

2. **Parar Instância quando não usar:**
   ```bash
   # No AWS Console:
   # EC2 → Instances → Selecionar → Instance State → Stop
   # (Não delete! Apenas Stop)
   ```

3. **Monitorar Free Tier:**
   ```bash
   # Na VM:
   free -h  # RAM
   df -h    # Disco
   ```

---

## 🆘 Troubleshooting

### Erro: Permission denied (publickey)
```bash
# Verificar permissões da chave
chmod 600 ~/Downloads/crafty-key.pem

# Verificar IP correto
# AWS Console → EC2 → Instances → copiar Public IPv4
```

### Erro: Connection timeout
```bash
# Verificar Security Group:
# AWS Console → EC2 → Security Groups → crafty-security-group
# SSH deve estar aberto para seu IP

# Esperar 2 minutos após launch
# Instância pode levar tempo para iniciar
```

### Erro: Crafty não inicia
```bash
# Na VM:
sudo systemctl status crafty
sudo journalctl -u crafty -f  # Ver erro específico
```

### Erro: Nginx não redireciona
```bash
# Testar config
sudo nginx -t

# Verificar logs
sudo tail -f /var/log/nginx/error.log
```

---

## 📞 Próximas Ações

1. ✅ Instância rodando
2. ✅ Crafty rodando
3. ✅ Acesso remoto configurado
4. ✅ Segurança ativada
5. → Criar servidor Minecraft no painel
6. → Compartilhar IP/domínio com amigos
7. → Jogar! 🎮

---

## 🔗 Links Úteis

- AWS Free Tier: https://aws.amazon.com/free
- Crafty Docs: https://crafty.forgecdn.com/
- Let's Encrypt: https://letsencrypt.org/
- Certbot: https://certbot.eff.org/

