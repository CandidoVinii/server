# Guia de Deploy Permanente - Crafty Server

Este guia mostra como fazer deploy do seu servidor Crafty para rodar permanentemente sem precisar de playit toda hora.

## Opções de Deploy

### Opção 1: Serviço Systemd (Recomendado para Linux)

Essa é a forma mais simples e mantém o servidor rodando automaticamente mesmo após reboots.

#### Passo 1: Criar usuário dedicado (opcional mas recomendado)
```bash
sudo useradd -r -s /bin/bash -d /workspaces/server crafty
sudo chown -R crafty:crafty /workspaces/server
```

#### Passo 2: Instalar o serviço
```bash
sudo cp /workspaces/server/minecraft/crafty.service /etc/systemd/system/crafty.service
sudo systemctl daemon-reload
```

#### Passo 3: Ativar e iniciar o serviço
```bash
# Ativar para iniciar automaticamente no boot
sudo systemctl enable crafty

# Iniciar o serviço
sudo systemctl start crafty

# Verificar status
sudo systemctl status crafty

# Ver logs
sudo journalctl -u crafty -f
```

#### Passo 4: Verificar se está rodando
```bash
sudo systemctl is-active crafty
# Deve retornar: active
```

### Opção 2: Docker (Melhor para portabilidade)

#### Passo 1: Construir a imagem Docker
```bash
cd /workspaces/server/minecraft/crafty-4
docker build -t crafty-server:latest .
```

#### Passo 2: Rodar o container
```bash
docker run -d \
  --name crafty \
  -p 8443:8443 \
  -p 25565:25565 \
  -v /workspaces/server/minecraft/crafty-4/config:/opt/crafty/config \
  -v /workspaces/server/minecraft/crafty-4/servers:/opt/crafty/servers \
  --restart always \
  crafty-server:latest
```

#### Passo 3: Usar Docker Compose (mais fácil)
Veja o arquivo `docker-compose.yml` no repositório.

### Opção 3: Configurar Reverse Proxy com Nginx/Apache

Se você tem um domínio ou IP fixo:

#### Exemplo com Nginx:
```nginx
server {
    listen 80;
    server_name seu-dominio.com;

    location / {
        proxy_pass https://localhost:8443;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Para WebSocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Opção 4: Alternativas a Playit (mais permanentes)

Se você não tem IP fixo, considere estas alternativas:

1. **Ngrok** - Tunnel com IP fixo (pago)
2. **Cloudflare Tunnel** - Gratuito e confiável
3. **Localtunnel** - Simples e gratuito
4. **Serveo** - Tunnel gratuito

#### Exemplo com Cloudflare Tunnel:
```bash
# Instalar cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb

# Configurar
cloudflared login
cloudflared tunnel create crafty-server

# Criar arquivo de config (~/.cloudflared/config.yml)
tunnel: crafty-server
credentials-file: /home/user/.cloudflared/<UUID>.json

ingress:
  - hostname: crafty.seu-dominio.com
    service: https://localhost:8443
  - hostname: minecraft.seu-dominio.com
    service: tcp://localhost:25565
  - service: http_status:404
```

## Próximos Passos

1. **Escolha uma opção** baseada na sua infraestrutura
2. **Configure firewall** para abrir portas necessárias (8443 para painel, 25565 para Minecraft)
3. **Configure domínio** se estiver usando DNS
4. **Teste conexão** do seu cliente Minecraft

## Comandos Úteis

```bash
# Ver status do serviço
sudo systemctl status crafty

# Parar o serviço
sudo systemctl stop crafty

# Reiniciar o serviço
sudo systemctl restart crafty

# Ver logs
sudo journalctl -u crafty -f

# Desabilitar de auto-iniciar
sudo systemctl disable crafty
```

## Qual opção escolher?

- **Serviço Systemd**: Se já está em um servidor Linux dedicado
- **Docker**: Se quer portabilidade e isolamento
- **Reverse Proxy**: Se já tem um servidor web rodando
- **Cloudflare Tunnel**: Se não tem IP fixo mas quer algo mais permanente que playit
