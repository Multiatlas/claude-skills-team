---
name: claude-code-vps-deployment
description: Desplegar Claude Code en un VPS Linux headless (sin GUI) y controlarlo desde Telegram, para tener tu agente corriendo 24/7 sin depender de tu portátil. Resuelve el wizard TUI por SSH con screen (PTY real) + inyección de teclas TIOCSTI, instala el plugin oficial de Telegram (pairing) y deja recuperación tras reinicio. Invocar cuando quieras "Claude Code en un servidor", "agente autónomo en VPS", "manejar Claude por Telegram".
type: reference-skill
---

# Skill: Desplegar Claude Code en un VPS headless con Telegram

> **Aplicable a:** cualquier proyecto que necesite Claude Code autónomo en un servidor (sin pantalla), accesible desde el móvil.

---

## Resumen

Claude Code se puede desplegar en un VPS Linux sin GUI usando:
- `screen` para proveer un PTY real (el wizard de Claude Code es una TUI Ink y necesita terminal de verdad).
- Inyección de teclas TIOCSTI (Python + `ioctl`) para navegar el wizard por SSH.
- Plugin oficial de Telegram para comunicación bidireccional (mandar tareas y recibir respuestas desde el móvil).

## Requisitos previos

- VPS Linux con acceso root y SSH.
- Suscripción Claude Pro/Max activa.
- Bot de Telegram creado vía @BotFather.
- Bun instalado (lo requiere el plugin de Telegram).
- Node.js 20+.

## Instalación

```bash
# 1. Instalar Claude Code
npm install -g @anthropic-ai/claude-code

# 2. Instalar Bun
curl -fsSL https://bun.sh/install | bash

# 3. CRÍTICO: symlinks de Bun en /usr/local/bin/ (si no, el plugin falla con "bun: command not found")
ln -sf ~/.bun/bin/bun /usr/local/bin/bun
ln -sf ~/.bun/bin/bun /usr/local/bin/bunx

# 4. Instalar el plugin de Telegram
claude install plugin:telegram@claude-plugins-official

# 5. Configurar el token del bot
mkdir -p ~/.claude/channels/telegram
echo 'TELEGRAM_BOT_TOKEN=<TU_TOKEN>' > ~/.claude/channels/telegram/.env
chmod 600 ~/.claude/channels/telegram/.env

# 6. Script de inyección de teclas (para confirmar el wizard por SSH)
mkdir -p /opt/scripts
cat > /opt/scripts/inject_key.py << 'EOF'
import fcntl, sys
pty = sys.argv[1] if len(sys.argv) > 1 else '/dev/pts/0'
fd = open(pty, 'wb')
fcntl.ioctl(fd, 0x5412, b'\r')   # TIOCSTI: simula pulsar Enter en ese PTY
fd.close()
print(f"Injected Enter into {pty}")
EOF
```

## Lanzamiento

```bash
# Lanzar en screen (PTY real + log)
mkdir -p /opt/logs
export TELEGRAM_BOT_TOKEN=<TU_TOKEN>
screen -L -Logfile /opt/logs/screen-claude.log -dmS claude-agent \
  claude --channels plugin:telegram@claude-plugins-official

# Esperar al wizard y confirmar el "trust" inyectando Enter
sleep 15
python3 /opt/scripts/inject_key.py /dev/pts/0
```

## Errores comunes

### 1. El plugin de Telegram aparece como "failed"
- **Causa:** `bun: command not found` — Bun no está en el PATH global.
- **Fix:** `ln -sf ~/.bun/bin/bun /usr/local/bin/bun`.

### 2. El bot no responde a los mensajes
- **Causa:** falta el pairing (seguridad del plugin).
- **Fix:** envía un mensaje al bot → copia el código de 6 caracteres → en Claude ejecuta `/telegram:access pair <código>`.

### 3. El wizard OAuth no funciona por SSH
- **Causa:** la TUI Ink necesita un PTY real.
- **Fix:** usar `screen` + inyección TIOCSTI (justo lo de arriba).

## Archivos clave

| Archivo | Función |
|---------|---------|
| `~/.claude/settings.json` | Config de Claude Code |
| `~/.claude/channels/telegram/.env` | Token de Telegram |
| `~/.claude/channels/telegram/access.json` | IDs autorizados (el pairing) |
| `~/.claude/plugins/installed_plugins.json` | Plugins instalados |

## Recuperación tras reinicio del VPS

1. SSH al servidor.
2. `screen -dmS claude-agent claude --channels plugin:telegram@claude-plugins-official`
3. Si pide trust → `python3 /opt/scripts/inject_key.py /dev/pts/0`.
4. El pairing de Telegram NO se pierde (vive en `access.json`).

---

> ⚠️ Seguridad: el VPS tiene tu sesión de Claude con acceso a tu cuenta — protégelo (SSH por clave, firewall, usuario dedicado si puedes) y restringe el bot a tus `chat_id` con el pairing. No publiques el token del bot.
