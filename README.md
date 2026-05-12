# 🛠️ Claude Skills — Multiatlas Pack (aporte público)

> **Selección curada de skills de Claude Code publicadas como aporte a la comunidad SaaS Factory.**
>
> ⚠️ **Repo PÚBLICO** — léase `CLAUDE.md` antes de cualquier commit. Las skills aquí son **genéricas, sin datos sensibles, sin nombres internos**. Pensadas para que cualquier agencia, freelance o equipo SaaS pueda reutilizarlas.

---

## 🎯 Filosofía

- **Skills genéricas reutilizables**: cada una resuelve un problema concreto sin asumir un cliente, equipo o stack específico.
- **Versionadas**: cada cambio queda en `git log`. Si una skill rompe algo, `git revert`.
- **Sanitización por diseño**: todo dato sensible (emails de service accounts, IPs, nombres de clientes, paths internos) está reemplazado por placeholders genéricos (`<email>`, `<servidor>`, `<cliente>`, `<tu-clave-ssh>`).

## 📦 Skills incluidas

| Skill | Para qué |
|---|---|
| `git-workflow-multiatlas` | Flujo Git unificado: branching, commits convencionales, tags semver, runbooks de recovery, gitleaks pre-commit |
| `mcp-security-audit` | Auditoría de seguridad de servidores MCP antes de instalar/actualizar |
| `protocolo-blindado-anti-desastre` | Backup defensivo antes de tocar webs WP de cliente (BD + temas + plugins a GitHub) |
| `claude-code-vps-deployment` | Patrón de deploy en VPS con Bun + PM2 + LiteSpeed |
| `2fa-telegram-push-pattern` | 2FA push notificación con auto-destrucción del mensaje (alternativa a TOTP) |
| `cross-surface-chat-memory` | Memoria conversacional cross-superficie via tabla `chat_messages` |

---

## 🚀 Cómo usar estas skills

### Opción 1 — Clonar e instalar localmente

```powershell
# Windows
cd ~\Developer
git clone https://github.com/Multiatlas/claude-skills-team.git
cd claude-skills-team
.\install.ps1   # copia las skills a ~/.claude/skills/
```

```bash
# Mac/Linux
cd ~/Developer
git clone https://github.com/Multiatlas/claude-skills-team.git
cd claude-skills-team
./install.sh
```

### Opción 2 — Copiar la skill que te interese

Cada skill es autocontenida en `skills/<nombre>/SKILL.md`. Cópiala a tu propio repo o a `~/.claude/skills/` directamente.

### Opción 3 — Inspirarte y reescribir

Las skills son referencias. Adáptalas a tu equipo, tu stack, tu workflow. Eso es lo bonito de los patrones — replicables, no copy/paste a ciegas.

---

## 🔄 Actualizar

```powershell
# Windows
cd ~\Developer\claude-skills-team
.\update.ps1
```

```bash
# Mac/Linux
cd ~/Developer/claude-skills-team
./update.sh
```

---

## ✏️ Contribuir (si trabajas en Multiatlas)

Este repo es para aporte público. **Nunca commitees** aquí:

- Service Account emails / project IDs
- IPs / hosts / paths internos
- Nombres de clientes reales
- Nombres del equipo interno
- Credenciales / tokens / customer IDs

Si necesitas commitear una skill que tiene referencias internas, **sanitízala primero**: reemplaza con genéricos (`<email>`, `<cliente>`, `<servidor>`). Léase `CLAUDE.md` para el protocolo completo.

---

## 🤝 Comunidad SaaS Factory

Este repo es aporte a la comunidad **SaaS Factory** (Daniel Carreón). Si encuentras estas skills útiles:

- Adáptalas a tu workflow.
- Comparte mejoras (PRs bienvenidos).
- Cita la fuente si republicas.

---

## 📞 Licencia

MIT — usa, modifica, redistribuye. Sin garantías.
