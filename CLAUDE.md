# claude-skills-team — Aporte público MultiAtlas a la comunidad SaaS Factory

> ⚠️ **ESTE REPO ES PÚBLICO EN GITHUB.** Cualquier commit es visible para todo el mundo, incluyendo:
>
> - La comunidad **SaaS Factory** de Daniel Carreón.
> - Cualquier desarrollador que descubra el repo por búsqueda, links o forks futuros.
> - Crawlers de GitHub, GitHub Search, Code Search de Anthropic, etc.

---

## 🎯 Qué es este repo

Es la **vitrina pública de MultiAtlas** en la comunidad SaaS Factory de Daniel Carreón. Sirve para:

- **Aportar valor a la comunidad** publicando skills sanitizadas que usamos en producción.
- **Captación / visibilidad técnica** para MultiAtlas como agencia.
- **Construir reputación** demostrando madurez operativa con ejemplos reales (pero genéricos).

**NO es** el repo de skills/memorias internas del equipo. Esas viven en repos privados.

---

## 🧭 Cómo decidir qué hacer cuando trabajas en este repo

### Audiencias y reglas

| ¿Quién eres? | ¿Qué puedes hacer? |
|---|---|
| Agente Claude trabajando para Rubén | Solo commitear con OK explícito de Rubén. Aplicar protocolo sanitización + grep audit antes |
| Miembro del equipo MultiAtlas (Desi, Isaac, futuros) | Igual: nunca commit sin OK Rubén. Si encuentras una skill interna que merece compartirse, sanitízala primero y propón |
| Comunidad SaaS Factory (fork / clon externo) | Bienvenido. Usa, modifica, redistribuye. PRs aceptados con sanitización correcta |

### Antes de cualquier commit/push, AUDITA

Ejecuta este grep antes de cada commit. Si devuelve resultados, **STOP — no commitees**:

```bash
grep -rE "agente-it-multiatlas@|fourth-elixir|/root/\.|5\.56\.166|hosting02|rubentoledano|ivantamajon|info@tecniclimatizacion|miaucan|nectaran|rayareal|piscinasibiza|liquidacioncomp|donsat|tecniclima|topmanitas|electroyclima|moneta|isceco|asistehogar|cinefuture|surdeplant|Bitwarden Teams MA|programa-gestion-multiatlas|id_agente_plesk" . | grep -v "^./\.git/"
```

Las únicas excepciones permitidas son las menciones dentro de este `CLAUDE.md` (el listado de qué NO hacer es documentación, no fuga).

---

## 🚫 PROHIBIDO commitear aquí

| Categoría | Ejemplos prohibidos |
|---|---|
| **Credenciales / Service Accounts** | Emails de SA reales (`<algo>@<proyecto>.iam.gserviceaccount.com` cuando proyecto es real), project IDs Google Cloud, paths de keys (`/root/.secrets/`, `~/.secrets/<nombre-real>`), tokens API |
| **Nombres de clientes reales** | Cualquier dominio de cliente de MA (lista no exhaustiva): tecniclimatizacion, donsat, electroyclima, moneta, nectaran, miaucan, rayareal, isceco, asistehogar, surdeplant, cinefuture, topmanitas, tecnicalderas, piscinasibiza, liquidacioncomplementaria |
| **Nombres del equipo interno** | Rubén, Desi, Isaac, Iván, Luis Miguel, Diego, Andreu, Arnau… nombres propios reales |
| **IPs / Hosts / Servidores** | `5.56.166.55` (S2), `5.56.166.56` (S3), `hosting02.multiatlas.es`, cualquier IP del equipo |
| **Paths internos** | `/root/.ssh/id_agente_plesk`, `/var/www/vhosts/<dominio>/`, `~/.bun/`, rutas absolutas de PCs concretos |
| **Customer IDs / Conversion IDs** | Google Ads, MCC `134-193-1012`, `AW-1XXXXXXXX` reales |
| **Memorias internas del equipo** | Cualquier archivo de `.claude/memory/` o `.agent/memory/` de los repos privados |
| **Datos operativos** | Pendientes vivos, leads, conversaciones cliente, decisiones internas, PENDIENTES.md |

---

## ✅ SÍ va aquí

- **Skills genéricas universalmente reutilizables** que cualquier agencia/freelance puede aplicar (git workflows, MCP security audit, VPS deployment patterns, schemas de cierre de sesión sin nombres concretos…).
- **Patrones técnicos abstractos** con ejemplos genéricos (`cliente-x`, `dominio.com`, `<email>`, `<servidor>`).
- **Documentación de skills** con cita a fuentes públicas (artículos, repos open-source).
- Solo lo que Rubén autorice **explícitamente** publicar.

---

## 🛂 Protocolo antes de cualquier commit (no negociable)

1. **Sanitizar el contenido**: reemplazar nombres reales por placeholders genéricos:
   - `tecniclimatizacion.es` → `cliente.com` o `<dominio>`
   - `Rubén / Desi / Iván` → `el owner / el desarrollador / el trafficker`
   - `agente-it-multiatlas@…` → `<service-account-email>`
   - `5.56.166.55` → `<servidor>` o `<vps-ip>`
   - `/root/.ssh/id_agente_plesk` → `~/.ssh/<tu-clave-ssh>`

2. **Ejecutar grep de auditoría** (comando en la sección "Antes de cualquier commit/push" arriba). Si hay matches, sanitizar más.

3. **Pedir OK explícito a Rubén**: "Voy a pushear estas skills al repo público SaaS Factory, ¿OK?".

4. **Solo entonces**: commit + push.

5. Si dudas, **no pushees**. Más vale tarde que público con datos sensibles.

---

## ⚠️ Si detectas una fuga histórica

1. **Sanitizar HEAD** con un commit limpio inmediato.
2. **Reportar a Rubén** el alcance: qué se filtró, en qué commits, desde cuándo.
3. **Considerar rotación preventiva** de credenciales que aparezcan filtradas (SA, tokens, keys).
4. **Decidir con Rubén** si se reescribe historia (`git filter-repo`) o se asume la fuga histórica.

> 📌 **Antecedente**: hubo fuga 2026-05-12 en commits `b841364` y `421b81c` (SA email + 7 clientes en `seo-protocolo-multiatlas/SKILL.md`). HEAD sanitizado el mismo día. Decisión: asumir histórico, rotar SA preventivamente en sesión aparte. Lección: **el grep de auditoría existe por esto. Ejecutarlo SIEMPRE.**

---

## 📚 Alcance de este repo

Este repo es **público** y contiene únicamente skills sanitizadas para la comunidad. Los repos internos del equipo MA (operativo + framework) viven aparte como **privados** y no se mencionan aquí por nombre.

Si trabajas en este repo público, **trabajas únicamente con su contenido**. Si necesitas tocar algo interno, ábrelo en otro VS Code o workspace distinto.

---

## 🤝 Filosofía hacia la comunidad SaaS Factory

- Las skills aquí son **patrones probados en producción real**, no tutoriales.
- Cada skill resuelve un problema concreto del día a día de una agencia/freelance.
- Si recibes feedback de la comunidad, escúchalo — son ellos quienes usarán esto en sus stacks.
- PRs externos son bienvenidos si están sanitizados y siguen las convenciones del repo (kebab-case + frontmatter `SKILL.md`).

---

## 🔄 Versionado

Cada skill puede tener su propio versionado en su `SKILL.md`. El repo entero se versiona con tags semver cuando hacemos una "release" significativa.

```bash
git tag --list 'v*' | sort -V | tail -5
```
