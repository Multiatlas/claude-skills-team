---
name: claude-code-vps-deployment
description: Deploy de proyectos Multiatlas al VPS S3 con PM2 + LiteSpeed. Invocar cuando el usuario diga "deploy al VPS" o "subir al servidor".
type: reference-skill
---

# Skill: Desplegar Claude Code en VPS Headless con Telegram

> **Proyecto origen:** agente-it-multiatlas
> **Fecha:** 12 abril 2026
> **Aplicable a:** Cualquier proyecto que necesite Claude Code autónomo en servidor

---

## Resumen

Claude Code se puede desplegar en un VPS Linux sin GUI usando:
- `screen` para proveer un PTY real
- TIOCSTI injection (Python + ioctl) para navegar el wizard TUI
- Plugin oficial de Telegram para comunicación bidireccional

## Requisitos Previos

- VPS Linux con root access y SSH
- Suscripción Claude Pro/Max activa
- Bot de Telegram creado via @BotFather
- Bun instalado (requerido por el plugin Telegram)
- Node.js 20+

## Instalación

```bash
# 1. Instalar Claude Code
npm install -g @anthropic-ai/claude-code

# 2. Instalar Bun
curl -fsSL https://bun.sh/install | bash

# 3. CRÍTICO: Crear symlinks en /usr/local/bin/
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bun /usr/local/bin/bunx

# 4. Instalar plugin de Telegram
claude install plugin:telegram@claude-plugins-official

# 5. Configurar token del bot
mkdir -p ~/.claude/channels/telegram
echo 'TELEGRAM_BOT_TOKEN=<TU_TOKEN>' > ~/.claude/channels/telegram/.env
chmod 600 ~/.claude/channels/telegram/.env

# 6. Script de inyección de teclas
cat > /opt/scripts/inject_key.py << 'EOF'
import fcntl, sys
pty = sys.argv[1] if len(sys.argv) > 1 else '/dev/pts/0'
fd = open(pty, 'wb')
fcntl.ioctl(fd, 0x5412, b'\r')
fd.close()
print(f"Injected Enter into {pty}")
EOF
```

## Lanzamiento

```bash
# Lanzar en screen
export TELEGRAM_BOT_TOKEN=<TU_TOKEN>
screen -L -Logfile /opt/logs/screen-claude.log -dmS claude-agent \
  claude --channels plugin:telegram@claude-plugins-official

# Esperar al wizard y confirmar trust
sleep 15
python3 /opt/scripts/inject_key.py /dev/pts/0
```

## Errores Comunes

### 1. Plugin Telegram aparece como "failed"
- **Causa:** `bun: command not found` — Bun no está en el PATH global
- **Fix:** `ln -sf /root/.bun/bin/bun /usr/local/bin/bun`

### 2. Bot no responde a mensajes
- **Causa:** Falta pairing (seguridad del plugin)
- **Fix:** Enviar mensaje al bot → copiar código de 6 chars → ejecutar en Claude: `/telegram:access pair <código>`

### 3. OAuth wizard no funciona por SSH
- **Causa:** Ink TUI necesita PTY real
- **Fix:** Usar `screen` + TIOCSTI injection

## Archivos Clave

| Archivo | Función |
|---------|---------|
| `~/.claude/settings.json` | Config Claude Code |
| `~/.claude/channels/telegram/.env` | Token Telegram |
| `~/.claude/channels/telegram/access.json` | IDs autorizados |
| `~/.claude/plugins/installed_plugins.json` | Plugins instalados |

## Procedimiento de Recuperación

Si el VPS se reinicia:
1. SSH al servidor
2. `screen -dmS claude-agent claude --channels plugin:telegram@claude-plugins-official`
3. Si pide trust → `python3 inject_key.py /dev/pts/0`
4. El pairing de Telegram NO se pierde (guardado en `access.json`)
