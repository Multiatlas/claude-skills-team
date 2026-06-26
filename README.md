# 🛠️ Claude Skills — Aporte MultiAtlas a la comunidad SaaS Factory

> **Skills de Claude Code publicadas por [MultiAtlas](https://multiatlas.net) como aporte oficial a la comunidad SaaS Factory de Daniel Carreón.**
>
> Skills de Claude Code que usamos en producción, **curadas y sanitizadas una a una** para que cualquier agencia, freelance o equipo SaaS pueda reutilizarlas. Publicamos **por lotes**: cada semana añadimos la(s) que de verdad aportan valor genérico, sin datos sensibles. Empezamos limpio — esto es lo que hay hoy y va creciendo con cuidado.

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
| `handoff-continuidad-sesion` | **Caja negra para tu agente**: que un fallo de API o una compactación de contexto no te borre horas de trabajo. Mantiene un HANDOFF vivo en git (actualizado cada hora y tras cada hito); si la sesión muere, abres un chat nuevo, lo lee y retomas donde estabas en 30 segundos. |
| `mcp-security-audit` | **Auditoría de un servidor MCP ANTES de instalarlo o actualizarlo**: permisos, código y supply-chain. Para que no metas un MCP malicioso (o una versión envenenada) dentro de tu agente. Pin exacto de versiones, nunca `^`. |
| `protocolo-blindado-anti-desastre` | **Backup obligatorio a git ANTES de que un agente toque la web o infra de un cliente.** Nació de un marrón real: un agente rompió una web sin backup previo. Si algo peta, `git revert` y vuelves a producción en segundos. |
| `deploy-quirurgico-next-vps` | **Deploy sin Vercel.** Sube cambios a tu Next.js self-hosted (PM2 + VPS) subiendo **solo el artefacto que cambió** (KB, no los ~90 MB del build): `md5` de invariantes + `scp` quirúrgico + swap atómico + rollback en segundos. Coste fijo, control total, cero lock-in. |
| `meta-capi-server-side` | **Meta Ads sin perder leads.** Conversions API server-side con deduplicación por `event_id`: recupera el **30-50% de conversiones** que el píxel pierde por iOS/ATT y ad-blockers → mejor atribución → **CPL 15-25% más bajo**. Helper completo, dedup cliente↔server, GDPR, y cómo generar el token (con sus 2 trampas que dejan el botón en gris). |
| `2fa-telegram-push-pattern` | **2FA gratis sin SMS ni Twilio.** Aprobación de login por push de Telegram con botones ✅/❌. El mensaje es genérico (sin email/IP/dominio) y **se auto-destruye en 30s** → si te roban el móvil desbloqueado, el chat no revela nada. Incluye el esquema Supabase, el endpoint Next.js, el handler del bot, el comando `/quiet`, los tests de aceptación y la trampa del **límite de 64 bytes en `callback_data`** que rompe el botón en silencio. |
| `claude-code-vps-deployment` | **Tu Claude Code corriendo 24/7 en un VPS, manejado desde Telegram.** Sin depender del portátil. Resuelve el problema real: el wizard TUI de Claude Code no funciona por SSH → se arregla con `screen` (PTY real) + inyección de teclas **TIOCSTI**. Trae el plugin oficial de Telegram (pairing), recuperación tras reinicio y los 3 errores típicos (Bun fuera del PATH, pairing, OAuth por SSH). |
| `ga4-gdpr-compliant` | **GA4 + Google Ads + Meta Pixel LEGALES en la UE.** Consent Mode v2 default-denied + banner: los tags NO disparan hasta que el usuario acepta, y el Pixel de Meta (sin consent mode nativo) se **gatea**. Sin esto pierdes señales de campañas y te expones a sanción RGPD. Patrón vanilla (WordPress) y patrón canónico **Next.js (App Router)** completo + eventos de engagement + las trampas (orden `beforeInteractive`, cookie-wall, verificación real en navegador). |

> 🆕 Publicamos **más skills cada semana**, curadas y sanitizadas una a una. Las próximas las elegís vosotros (votad en la comunidad).

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

- Nombre de carpeta: `kebab-case` y descriptivo (`handoff-continuidad-sesion`, no `hcs`)
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
