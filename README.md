# 🛠️ Claude Skills — Aporte MultiAtlas a la comunidad

> **Selección curada de skills de Claude Code, publicadas por [MultiAtlas](https://multiatlas.net) como aporte a la comunidad SaaS Factory.**

Estas son skills que usamos en nuestro día a día (auditorías de seguridad MCP, deploy a VPS, auth 2FA por Telegram, workflow git con anti-secret, memoria conversacional cross-surface, onboarding nuevo equipo, etc) y que hemos preparado para que cualquiera pueda usarlas con su Claude Code.

---

## 📦 Skills incluidas

| Skill | Para qué sirve |
|---|---|
| **`2fa-telegram-push-pattern`** | Patrón de segundo factor de autenticación con push de Telegram (custom, sin SaaS de terceros). Incluye TTL y auto-destrucción. |
| **`claude-code-vps-deployment`** | Deploy de un agente Claude Code a un VPS propio, con PM2, healthcheck y logging. |
| **`cross-surface-chat-memory`** | Memoria conversacional entre superficies (Telegram ↔ Web ↔ CLI) para que el agente recuerde sesiones previas. |
| **`git-workflow-multiatlas`** | Flujo Git unificado: branching simple, commits convencionales, tags semver, runbooks de recovery, pre-commit gitleaks anti-secret. |
| **`mcp-security-audit`** | Auditoría de seguridad de servidores MCP antes de instalar o actualizar. Pinning, scope mínimo, checklist comunidad. |
| **`protocolo-blindado-anti-desastre`** | Checklist anti-desastre antes de operaciones destructivas o rotaciones críticas. Si algo puede romperse, esto te frena. |
| **`protocolo-cierre-multiatlas-team`** | Protocolo de cierre de sesión: git status, commit + push, memoria persistente, resumen ejecutivo al usuario. |
| **`setup-vscode-multiatlas-team`** | Onboarding técnico para un nuevo miembro: extensiones VS Code, hooks gitleaks pre-commit, config Claude Code. |

---

## 🚀 Instalación

### Windows (PowerShell)

```powershell
git clone https://github.com/Multiatlas/claude-skills-team.git
cd claude-skills-team
.\install.ps1
```

### Mac/Linux

```bash
git clone https://github.com/Multiatlas/claude-skills-team.git
cd claude-skills-team
./install.sh
```

Reinicia Claude Code (VS Code, terminal, lo que uses) tras instalar.

Verifica con:

```
Lista las skills que tienes instaladas
```

---

## 🔄 Actualizar cuando publiquemos nuevas skills

```powershell
# Windows
cd claude-skills-team
.\update.ps1
```

```bash
# Mac/Linux
cd claude-skills-team && ./update.sh
```

Estos scripts hacen `git pull` y vuelven a copiar las skills a `~/.claude/skills/`.

---

## ✏️ Convenciones de las skills

Si quieres entender cómo están construidas o adaptar alguna a tu stack:

- Nombre carpeta: `kebab-case` y descriptivo
- Frontmatter obligatorio en `SKILL.md`:
  ```markdown
  ---
  name: Nombre Legible
  description: Una línea — para qué sirve y cuándo invocarla. Verbos en imperativo.
  ---
  ```

---

## 🚫 Qué NO incluimos en este repo

- **Skills con secretos** (API keys, tokens, paths privados) — los hemos limpiado todos
- **Skills muy específicas de nuestro stack interno** que no aportarían valor genérico a la comunidad
- **Skills experimentales no probadas** en producción

Lo que comparte este repo son skills que **están en uso real** en nuestro día a día.

---

## 🤝 Comunidad

Este repo es nuestro aporte a la comunidad **SaaS Factory de Daniel Carreón**. Iremos publicando más skills curadas según las necesidades que vaya planteando la comunidad — las próximas las elegís vosotros.

Si echas en falta una skill o tienes feedback:

- Abre un issue en el repo
- O coméntalo en el grupo de la comunidad SF V4

---

## ⚖️ Licencia

Uso libre con atribución. Si publicas algo derivado de estas skills, menciona a MultiAtlas como fuente original.

---

## 🔗 MultiAtlas

- Web: https://multiatlas.net
- Producto interno Webs IA en 48h: https://vibe.multiatlas.net
