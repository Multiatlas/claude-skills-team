# 🛠️ Claude Skills — Aporte MultiAtlas a la comunidad SaaS Factory

> **Skills de Claude Code publicadas por [MultiAtlas](https://multiatlas.net) como aporte oficial a la comunidad SaaS Factory de Daniel Carreón.**
>
> Skills que usamos en nuestro día a día — auditorías de seguridad MCP, deploy a VPS, auth 2FA por Telegram, workflow Git con anti-secret, memoria conversacional cross-superficie, backup defensivo antes de tocar webs de cliente — sanitizadas y preparadas para que cualquier agencia, freelance o equipo SaaS pueda reutilizarlas con su Claude Code.

---

## 🎯 Filosofía

- **Skills genéricas reutilizables**: cada una resuelve un problema concreto sin asumir un cliente, equipo o stack específico.
- **Versionadas**: cada cambio queda en `git log`. Si una skill rompe algo, `git revert`.
- **Sanitización por diseño**: todo dato sensible (emails de service accounts, IPs, nombres de clientes, paths internos) está reemplazado por placeholders genéricos (`<email>`, `<servidor>`, `<cliente>`, `<tu-clave-ssh>`).
- **Aporte público al ecosistema SaaS Factory** (Daniel Carreón). Si la comunidad propone una skill nueva, la prepararemos sanitizada y la añadimos aquí.

---

## 📦 Skills incluidas

| Skill | Para qué sirve |
|---|---|
| `2fa-telegram-push-pattern` | Patrón de segundo factor de autenticación con push de Telegram (custom, sin SaaS de terceros). Incluye TTL y auto-destrucción del mensaje. |
| `claude-code-vps-deployment` | Deploy de un agente Claude Code a un VPS propio, con PM2, healthcheck y logging. |
| `cross-surface-chat-memory` | Memoria conversacional entre superficies (Telegram ↔ Web ↔ CLI) para que el agente recuerde sesiones previas. |
| `git-workflow-multiatlas` | Flujo Git unificado: branching simple, commits convencionales, tags semver, runbooks de recovery, pre-commit gitleaks anti-secret. |
| `mcp-security-audit` | Auditoría de seguridad de servidores MCP antes de instalar o actualizar. Pinning, scope mínimo, checklist de la propia comunidad SaaS Factory. |
| `protocolo-blindado-anti-desastre` | Backup defensivo antes de operaciones destructivas o rotaciones críticas en webs de cliente. Si algo puede romperse, esto te frena y te obliga a tener red de seguridad. |
| `supabase-rls-escrituras-admin-service-role` | **El bug fantasma de Supabase**: tu panel admin dice "guardado ✅" y no guarda nada. Escrituras admin con la clave ANON + RLS → 0 filas, sin error, `success:true`. Regla service_role tras verifyAdmin + guard anti-silencio + grep para CI. |
| `handoff-continuidad-sesion` | **Caja negra para tu agente**: que un fallo de API o una compactación de contexto no te borre horas de trabajo. HANDOFF vivo en git, actualizado cada hora; si la sesión muere, un chat nuevo lo lee y retoma en 30 segundos. |

---

## 🧭 Cómo actuar con este repo

Este repo tiene **tres tipos de audiencia**. Cada una tiene su modo de uso.

### 👤 Si eres de la comunidad SaaS Factory (o llegas desde fuera)

Eres bienvenido. Usa las skills como quieras: clona, copia la que te interese, adapta a tu workflow.

**Opción 1 — Clonar e instalar localmente** (recomendado si vas a usar varias):

```powershell
# Windows
cd $HOME\Developer
git clone https://github.com/Multiatlas/claude-skills-team.git
cd claude-skills-team
.\install.ps1
```

```bash
# Mac / Linux
cd ~/Developer
git clone https://github.com/Multiatlas/claude-skills-team.git
cd claude-skills-team
./install.sh
```

Reinicia Claude Code (VS Code, terminal, lo que uses) tras instalar.

**Opción 2 — Copiar solo la skill que te interese**:

Cada skill es autocontenida en `skills/<nombre>/SKILL.md`. Cópiala a tu propio repo o directamente a `~/.claude/skills/`.

**Opción 3 — Inspirarte y reescribir**:

Las skills son referencias. Adáptalas a tu equipo, tu stack, tu workflow. Eso es lo bonito de los patrones — replicables, no copy/paste a ciegas.

### 🤖 Si eres un agente Claude que ha abierto este repo

Léete primero `CLAUDE.md` — explica qué puedes y qué NO puedes commitear aquí (es un repo PÚBLICO, las reglas son estrictas con datos sensibles).

Si te han pedido contribuir aquí:

1. Lee `CLAUDE.md` completo.
2. Sanitiza tu contenido: reemplaza nombres reales por placeholders genéricos (`<cliente>`, `<dominio>`, `<email>`, `<servidor>`, `<tu-clave-ssh>`).
3. Ejecuta el grep de auditoría que está en `CLAUDE.md`.
4. NUNCA hagas commit sin OK explícito del owner del repo.

### 🧑‍💻 Si trabajas en MultiAtlas

Este repo es la **vitrina pública** del equipo MA en la comunidad SaaS Factory. Las skills/memorias internas viven en **repos privados separados**, no aquí.

Cuando una skill interna madure y pueda compartirse con la comunidad: la sanitizas, la auditas con grep, y la mueves aquí **con OK explícito del owner**.

---

## 🔄 Actualizar (cuando publiquemos nuevas skills)

```powershell
# Windows
cd $HOME\Developer\claude-skills-team
.\update.ps1
```

```bash
# Mac / Linux
cd ~/Developer/claude-skills-team
./update.sh
```

Estos scripts hacen `git pull` y vuelven a copiar las skills a `~/.claude/skills/`.

---

## ✏️ Convenciones de las skills

Si quieres entender cómo están construidas o adaptar alguna a tu stack:

- Nombre de carpeta: `kebab-case` y descriptivo (`protocolo-blindado-anti-desastre`, no `pbad`)
- Frontmatter obligatorio en `SKILL.md`:

```markdown
---
name: Nombre Legible
description: Una línea — para qué sirve y cuándo invocarla. Verbos en imperativo.
---
```

---

## 🚫 Qué NO incluimos en este repo

- **Skills con secretos** (API keys, tokens, paths privados) — los hemos limpiado todos.
- **Skills muy específicas de nuestro stack interno** que no aportarían valor genérico a la comunidad — se quedan en nuestros repos privados.
- **Skills experimentales no probadas** en producción — terminamos en local primero.

Lo que comparte este repo son skills que **están en uso real** en nuestro día a día con clientes.

---

## 🤝 Comunidad SaaS Factory

Este repo es nuestro aporte a la comunidad **SaaS Factory de Daniel Carreón**. Iremos publicando más skills curadas según las necesidades que vaya planteando la comunidad — las próximas las elegís vosotros.

Si echas en falta una skill o tienes feedback:

- Abre un **issue** en este repo.
- Coméntalo en el grupo de la comunidad SF V4.

PRs bienvenidos (sanitizados, sin datos sensibles, con frontmatter correcto).

---

## ⚖️ Licencia

Uso libre con atribución. Si publicas algo derivado de estas skills, menciona a [MultiAtlas](https://multiatlas.net) como fuente original.

---

## 🔗 MultiAtlas

- **Web**: https://multiatlas.net
- **Comunidad SaaS Factory**: [enlace al grupo / canal de Daniel Carreón]
