# Checklist de Deploy - Crafty Server

## Opção 1: Setup Rápido com Script Automático ⚡

```bash
# 1. Dar permissão de execução
chmod +x /workspaces/server/setup_deploy.sh

# 2. Executar script (escolha: systemd ou docker)
sudo /workspaces/server/setup_deploy.sh
```

---

## Opção 2: Setup Manual - Systemd

### Pré-requisitos
- [ ] Linux (Ubuntu, Debian, Fedora, etc)
- [ ] Python 3.10+
- [ ] Virtual environment configurado
- [ ] Código do Crafty em `/workspaces/server/minecraft/crafty-4`

### Etapas

#### 1. Criar usuário (opcional)
```bash
sudo useradd -r -s /bin/bash -d /workspaces/server crafty
sudo chown -R crafty:crafty /workspaces/server
```
- [ ] Usuário criado

#### 2. Instalar serviço
```bash
sudo cp /workspaces/server/minecraft/crafty.service /etc/systemd/system/crafty.service
sudo systemctl daemon-reload
```
- [ ] Arquivo copiado para `/etc/systemd/system/`
- [ ] Systemd recarregado

#### 3. Ativar e iniciar
```bash
sudo systemctl enable crafty      # Auto-iniciar no boot
sudo systemctl start crafty       # Iniciar agora
```
- [ ] Serviço habilitado
- [ ] Serviço iniciado

#### 4. Verificar
```bash
sudo systemctl status crafty
```
- [ ] Status = `active (running)`

### Verificação Pós-Setup
```bash
# Verificar se está rodando
ps aux | grep "python3 main.py"

# Ver logs
sudo journalctl -u crafty -f

# Testar acesso ao painel
curl -k https://localhost:8443/
```
- [ ] Processo em execução
- [ ] Logs sem erros
- [ ] Painel acessível

---

## Opção 3: Setup com Docker

### Pré-requisitos
- [ ] Docker instalado
- [ ] Docker Compose (opcional)
- [ ] Pelo menos 2GB de RAM livre

### Etapas

#### 1. Com Docker Compose (Recomendado)
```bash
cd /workspaces/server
docker-compose up -d
```
- [ ] Imagem construída
- [ ] Container iniciado

#### 2. Com Docker CLI
```bash
cd /workspaces/server/minecraft/crafty-4
docker build -t crafty-server:latest .

docker run -d \
  --name crafty \
  -p 8443:8443 \
  -p 25565:25565 \
  -v /workspaces/server/minecraft/crafty-4/config:/opt/crafty/config \
  -v /workspaces/server/minecraft/crafty-4/servers:/opt/crafty/servers \
  --restart always \
  crafty-server:latest
```
- [ ] Imagem construída
- [ ] Container em execução

### Verificação Pós-Setup
```bash
# Ver logs
docker logs -f crafty

# Verificar container
docker ps | grep crafty

# Testar acesso
curl -k https://localhost:8443/
```
- [ ] Logs mostram sucesso
- [ ] Container rodando
- [ ] Painel acessível

---

## Pós-Setup: Configuração de Rede

### Opção A: Domínio Próprio + Reverse Proxy
```bash
# 1. Instalar nginx
sudo apt install nginx

# 2. Criar config (veja exemplo em DEPLOY_GUIDE.md)
# 3. Habilitar HTTPS (certbot + Let's Encrypt)
sudo apt install certbot python3-certbot-nginx
sudo certbot certonly --nginx -d seu-dominio.com
```
- [ ] Nginx instalado
- [ ] Configuração criada
- [ ] HTTPS funcionando

### Opção B: Cloudflare Tunnel (Sem IP Fixo)
```bash
# 1. Instalar cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb

# 2. Configurar
cloudflared login
cloudflared tunnel create crafty-minecraft
```
- [ ] Cloudflared instalado
- [ ] Tunnel criado
- [ ] Domínio apontando para tunnel

---

## Comandos Importantes

### Systemd
```bash
sudo systemctl status crafty           # Ver status
sudo systemctl start crafty            # Iniciar
sudo systemctl stop crafty             # Parar
sudo systemctl restart crafty          # Reiniciar
sudo journalctl -u crafty -f           # Ver logs em tempo real
sudo systemctl enable crafty           # Auto-iniciar no boot
sudo systemctl disable crafty          # Desabilitar auto-iniciar
```

### Docker
```bash
docker-compose up -d                   # Iniciar (com compose)
docker-compose down                    # Parar (com compose)
docker-compose restart                 # Reiniciar (com compose)
docker logs -f crafty                  # Ver logs em tempo real
docker exec -it crafty bash            # Entrar no container
docker stats crafty                    # Ver consumo de recursos
```

---

## Troubleshooting

### Serviço não inicia
```bash
# Ver logs detalhados
sudo journalctl -u crafty -f

# Verificar permissões
ls -la /workspaces/server/minecraft/

# Verificar se porta está em uso
sudo netstat -tlnp | grep 8443
sudo netstat -tlnp | grep 25565
```

### Pasta .venv não ativa
Certifique-se que em `run_crafty_service.sh`:
```bash
source /workspaces/server/minecraft/.venv/bin/activate
```
Está usando o caminho absoluto correto.

### Container Docker não sobe
```bash
docker logs crafty          # Ver erro
docker inspect crafty       # Ver detalhes
docker ps -a                # Ver se está morto
```

---

## Checklist Final

- [ ] Serviço/Container rodando
- [ ] Painel acessível em https://localhost:8443/
- [ ] Servidor Minecraft rodando (porta 25565)
- [ ] Logs sem erros
- [ ] Auto-restart configurado
- [ ] Backups funcionando
- [ ] Firewall liberando portas (se necessário)
- [ ] Domínio/Tunnel configurado (se usando acesso remoto)

---

## Próximos Passos

1. **Logar no painel**: https://localhost:8443/
2. **Criar servidor Minecraft**: Adicionar novo servidor via painel
3. **Configurar backups**: Agendar backups automáticos
4. **Configurar acesso remoto**: Domínio ou Cloudflare Tunnel
5. **Dividir com amigos**: Compartilhar endereço do servidor
