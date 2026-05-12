# claude-skills-team — Repo PÚBLICO de aporte a la comunidad SaaS Factory

> ⚠️ **ESTE REPO ES PÚBLICO EN GITHUB.** Cualquier commit es visible para todo el mundo, incluida la comunidad SaaS Factory de Daniel Carreón y cualquier persona que descubra el repo.

---

## 🎯 Propósito

Selección curada de skills de Claude Code publicadas como **aporte a la comunidad SaaS Factory**. Su función es:

- Captación de clientes / visibilidad técnica.
- Compartir buenas prácticas con la comunidad.
- Construir reputación técnica.

**NO es** el repo de skills/memorias internas del equipo. Esas están en repos privados.

---

## 🚫 PROHIBIDO commitear aquí (verificar siempre antes de push)

| Categoría | Ejemplos |
|---|---|
| **Credenciales / Service Accounts** | Emails de SA (`agente-it-multiatlas@…`), project IDs Google Cloud, paths de keys (`/root/.secrets/`), tokens API |
| **Nombres de clientes reales** | tecniclimatizacion, donsat, electroyclima, moneta, nectaran, miaucan, rayareal, isceco, asistehogar… cualquier dominio cliente |
| **Nombres del equipo interno** | Rubén, Desi, Isaac, Iván, Luis Miguel… nombres propios reales |
| **IPs / Hosts / Servidores** | `5.56.166.55`, `5.56.166.56`, `hosting02.multiatlas.es` |
| **Paths internos** | `/root/.ssh/id_agente_plesk`, `/var/www/vhosts/<dominio>/`, rutas locales personales |
| **Customer IDs / Conversion IDs** | Google Ads, MCC `134-193-1012`, `AW-1XXXXXXXX` reales |
| **Memorias internas equipo** | Cualquier archivo de `.claude/memory/` o `.agent/memory/` privados |
| **Datos operativos** | Pendientes vivos, leads, conversaciones cliente, decisiones internas |

---

## ✅ SÍ va aquí

- Skills **genéricas universalmente reutilizables** (git workflows, MCP security audit, VPS deployment patterns, schemas de cierre de sesión sin nombres concretos…).
- Patrones técnicos abstractos con ejemplos genéricos (`cliente-x`, `dominio.com`, `<email>`).
- Documentación de skills con cita a fuentes públicas.
- Sólo lo que Rubén autorice **explícitamente** publicar.

---

## 🛂 Protocolo antes de cualquier commit

1. **Sanitizar el contenido**: reemplazar nombres reales por genéricos (`<cliente>`, `<dominio>`, `<email>`, `<servidor>`).
2. **Ejecutar grep de auditoría**: `grep -rE "agente-it-multiatlas@|fourth-elixir|/root/\.|5\.56\.166|hosting02|<clientes-reales>" .`
3. **Pedir OK explícito a Rubén**: "voy a pushear estas skills al repo público SaaS Factory, ¿OK?".
4. **Solo entonces**: commit + push.
5. Si dudas, **no pushees**. Más vale tarde que público con datos sensibles.

---

## ⚠️ Si detectas una fuga histórica

1. Sanitizar HEAD con commit limpio.
2. Reportar a Rubén el alcance (qué se filtró, en qué commits).
3. Considerar rotación preventiva de credenciales filtradas.
4. Decidir con Rubén si se reescribe historia (`git filter-repo`) o se asume la fuga.

---

## 📚 Repos relacionados (privados, no clonar desde aquí)

- `Multiatlas/agente-it-multiatlas` (privado) — operativo bot + clientes
- `Multiatlas/multiatlas-setup-saas` (privado) — framework SaaS + skills/memorias equipo

Si trabajas en este repo público, **trabajas únicamente con su contenido**. No mezcles con los privados.
