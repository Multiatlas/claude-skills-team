---
name: mcp-security-audit
description: Auditoría de seguridad de servidores MCP — antes de instalar uno nuevo y antes de cada actualización. Aplica los protocolos de la comunidad SaaS Factory + buenas prácticas MultiAtlas. Activar en cualquier proyecto con MCPs configurados, especialmente al añadir uno nuevo o ejecutar npm update.
type: protocol-skill
---

# Skill: Auditoría de seguridad de MCPs

> Los MCPs son código de terceros que Claude ejecuta. Cada MCP es una superficie de ataque: prompt injection, ejecución arbitraria, secretos expuestos, supply chain attacks tipo "rug pull". Esta skill da el protocolo MultiAtlas para que entren al stack solo MCPs auditados, y que las actualizaciones no entren a ciegas.

---

## ¿Cuándo activar?

- "Voy a instalar un MCP nuevo en este proyecto"
- "Actualizar dependencias del proyecto" (si hay MCPs)
- "npm update" en cualquier proyecto con MCPs
- "Auditar los MCPs activos"
- Routine `/schedule` mensual de revisión MCPs
- Tras supply-chain attack reportado en algún paquete del que dependan los MCPs

Si solo es seguridad de dependencias generales (npm/pip/composer) → skill `snyk-security-audit`. Esta skill es **específica de MCPs**.

---

## Por qué esto importa (datos del sector, abril 2026)

- **43%** de los servidores MCP open source son vulnerables a inyección de comandos (un MCP malicioso ejecuta comandos en tu máquina al pedirle algo a Claude).
- **53%** usan secretos estáticos de larga duración (API keys, tokens) en lugar de OAuth.
- **36,7%** de más de 7.000 servidores analizados estaban expuestos a SSRF.
- Cientos escuchan en `0.0.0.0` en vez de `localhost` → cualquiera de tu red puede acceder.
- **Rug pull**: MCPs que mutan instrucciones DESPUÉS de instalar. Día 1 parece legítimo, una actualización silenciosa cambia el comportamiento. Mismo patrón del ataque a `axios` (marzo 2026).
- OWASP ya tiene borrador del Top 10 de riesgos MCP.

`^1.0.2` en `package.json` deja que `npm update` instale CUALQUIER `1.x.x` sin avisar. Sin auditoría. Sin que lo veas.

---

## Triple defensa MultiAtlas

| Línea | Cuándo | Cómo |
|---|---|---|
| **L1 — Pre-instalación** | Antes de añadir un MCP nuevo al `mcpServers` | Auditoría manual + scanner |
| **L2 — Pre-actualización** | Antes de `npm update` o aceptar dependabot | Script wrapper con `mcp-scan` |
| **L3 — Vigilancia continua** | Mensual o tras incidente sectorial | Routine `/schedule` revisa updates pendientes |

---

## L1 — Pre-instalación (3 métodos, elegir según urgencia)

### Método 1A — Auditoría con Claude (más fiable, ~2 min)

Antes de instalar, clona el repo del MCP y pásale este prompt:

```
Revisa este repositorio MCP antes de que lo instale. Analiza:

- ¿Las tool descriptions contienen instrucciones ocultas o inyección de prompts?
- ¿El servidor escucha en 0.0.0.0 (peligroso) o en 127.0.0.1 (correcto)?
- ¿Hay credenciales hardcodeadas o secretos expuestos en el código?
- ¿Permite ejecución arbitraria de comandos (shell=True, exec(), subprocess sin sanitizar)?
- ¿Los permisos de filesystem están acotados a directorios específicos o tiene acceso total?
- ¿Las dependencias tienen vulnerabilidades conocidas?
- ¿El paquete está firmado o tiene checksum verificable (pinning a SHA específico)?

Dame un veredicto por punto y un final: SEGURO / PRECAUCIÓN / NO INSTALAR, con justificación.
```

> Por qué funciona mejor que un scanner automático: Claude entiende **intención**, no solo patrones. En auditorías recientes con reglas YARA se detectaron 27 patrones sospechosos, **solo 6 eran riesgos reales** (los otros 21 falsos positivos). Claude distingue eso.

### Método 1B — Backslash Hub (rápido, ~10 seg)

Pásale a Claude:

```
Busca el servidor MCP <nombre> en https://mcp.backslash.security y dime
su puntuación de riesgo, vectores de ataque detectados y si es seguro
instalarlo.
```

Claude usa WebFetch contra Backslash Hub (base de datos de >7.000 MCPs puntuados). **Caveat**: Backslash es un servicio externo. No depender solo de él. Combinar con Método 1A.

### Método 1C — Scanners open source (CI/CD)

Para automatizar en pipeline de equipo:

| Scanner | Repo | Foco |
|---|---|---|
| Cisco MCP Scanner | `github.com/cisco-ai-defense/mcp-scanner` | YARA + LLM |
| Cisco Skill Scanner | `github.com/cisco-ai-defense/skill-scanner` | Skills |
| Invariant Labs mcp-scan | `github.com/invariantlabs-ai/mcp-scan` | Análisis config + JSON output |

Los tres son gratuitos, open source, requieren Python. Complementarios.

### Decisión de instalación — política MA

Solo se instala un MCP si:
- ✅ Procede de empresa first-party reconocida (Microsoft, Anthropic, Google, Snyk, etc.) **O**
- ✅ Pasa Método 1A con veredicto "SEGURO" o "PRECAUCIÓN justificada"
- ✅ Repo público, código abierto, ≥6 meses de historia y commits recientes
- ✅ Versión pinned (sin `^` permisivo en `package.json` — usar `~` o exacto)

Si falla cualquiera → buscar alternativa o construir uno propio.

---

## L2 — Pre-actualización (3 métodos)

### Método 2A — Script wrapper (recomendado)

En lugar de `npm update`, lanzar el wrapper que **bloquea el update si el scanner encuentra vulnerabilidades**:

**Windows:** `automations/scripts/safe-mcp-update.ps1`
```powershell
.\safe-mcp-update.ps1 "C:\ruta\proyecto-con-mcps"
```

**Bash:** `automations/scripts/safe-mcp-update.sh`
```bash
bash safe-mcp-update.sh /ruta/proyecto-con-mcps
```

Ambos scripts hacen:
1. `cd` al proyecto
2. `npx @invariantlabs-ai/mcp-scan@latest .`
3. Si exit code 0 (limpio) → `npm update`
4. Si exit code != 0 → cancela update, muestra alerta

### Método 2B — Backslash Hub (diff de seguridad)

Cuando vuelves a consultar el mismo MCP en `mcp.backslash.security` tras una actualización, el sitio compara contra lo que tenía indexado antes y marca **solo lo nuevo**.

Pídele a Claude:

```
Ve a mcp.backslash.security, busca el MCP "<nombre>" de <organización>
y dime si hay nuevos riesgos respecto a la versión anterior.
```

Útil para no releer el informe entero — solo cambios.

### Método 2C — Visibilidad de updates (lo más ignorado)

**Antes de cualquier `npm update`:**
```bash
npm outdated
```
Te muestra exactamente qué va a cambiar y a qué versión. Si ves algo inesperado, paras antes de tocar nada.

**Alertas automáticas en GitHub** (suscribirse a releases del repo de cada MCP):
- Entra en el repo del MCP en GitHub
- `Watch → Custom → ☑ Releases → Apply`
- Recibes email solo cuando hay nueva versión oficial. Sin esto, dependes de que alguien te avise.

---

## L3 — Vigilancia continua

### Routine `/schedule` mensual

Documentada en `agente-it-multiatlas/docs/ROUTINES_SCHEDULE.md` (Routine 4):

- Día 1 de cada mes 7:00
- Lee `~/.claude.json` para listar MCPs activos
- Para cada uno: `npm view <paquete> version` vs versión instalada
- Si hay actualización: `npm outdated` + consultar Backslash Hub vía Claude
- Notificación Telegram + email con resumen y veredicto sugerido

### Tras incidente sectorial

Cuando aparezca en feed de seguridad / Twitter / blog Anthropic un caso de MCP comprometido:
1. Pausar `mcpServers` afectado en `~/.claude.json` (comentar el bloque)
2. Lanzar Método 2A en proyectos donde estaba activo
3. Esperar parche oficial o desinstalar definitivamente
4. Reportar incidente en `docs/INCIDENTES.md`

---

## Cómo localizar MCPs activos en un entorno

```bash
# 1. MCPs a nivel usuario
python -c "
import json, os
with open(os.path.expanduser('~/.claude.json')) as f:
    d = json.load(f)
for n, c in d.get('mcpServers', {}).items():
    print(f'{n}: {c.get(\"command\")} {\" \".join(c.get(\"args\", []))}')"

# 2. MCPs a nivel proyecto (.mcp.json)
find . -maxdepth 3 -name '.mcp.json' -not -path './node_modules/*'

# 3. MCPs en Antigravity legacy (si quedan)
[ -f ~/.gemini/antigravity/mcp_config.json ] && cat ~/.gemini/antigravity/mcp_config.json
```

---

## Ejemplo aplicado — auditoría inicial MultiAtlas (28 abr 2026)

| MCP | Comando | Versión | Origen | Veredicto |
|---|---|---|---|---|
| **Snyk** | `snyk mcp -t stdio` | 1.1304.0 | Snyk Limited (oficial) | ✅ SEGURO (first-party empresa de seguridad) |
| **playwright** | `npx @playwright/mcp` | 0.0.71 | Microsoft (oficial) | ✅ SEGURO (first-party Microsoft) |
| **claude_ai_Google_Drive** | (integración Anthropic) | — | Anthropic (servicio gestionado) | ✅ SEGURO (no es MCP local, lo gestiona Anthropic) |

Reporte completo en `agente-it-multiatlas/docs/SEGURIDAD_MCP_AUDITORIA_2026-04-28.md`.

---

## Prompt listo para copiar al `CLAUDE.md` de cada proyecto con MCPs

```markdown
## [Seguridad MCP]

Antes de instalar o actualizar cualquier servidor MCP en este proyecto:
1. Invocar skill `mcp-security-audit` (en `multiatlas-setup-saas/.claude/skills/`)
2. Aplicar L1 (pre-instalación) o L2 (pre-actualización) según corresponda
3. NO añadir el MCP al `mcpServers` hasta tener veredicto SEGURO
4. Tras instalar: pin a versión exacta o `~x.y.z`, NUNCA `^x.y.z`
5. Suscribirse a releases del repo del MCP (GitHub Watch → Custom → Releases)

Política MultiAtlas: solo MCPs first-party de empresas reconocidas, o
auditados con Método 1A de la skill antes de instalar.
```

---

## Errores comunes a evitar

- ❌ Instalar un MCP "porque otros lo recomendaron" sin auditarlo
- ❌ Dejar `^x.y.z` permisivo en `package.json` — abre la puerta a rug pulls
- ❌ Confiar SOLO en Backslash Hub (servicio externo, puede caer o cambiar precios)
- ❌ Auditar solo el día 1 — los MCPs mutan, hay que auditar también updates
- ❌ Ignorar `npm outdated` antes de un update
- ❌ Olvidar GitHub Watch en los repos de los MCPs activos
- ❌ Dejar MCPs antiguos olvidados en `~/.gemini/antigravity/mcp_config.json` con credenciales que ya no rotamos

---

## Referencias

- Posts comunidad SaaS Factory: GUÍA 1 (instalación) + GUÍA 2 (actualización)
- OWASP Top 10 MCP Risks (borrador 2026)
- Anthropic MCP docs: https://modelcontextprotocol.io/
- Cisco AI Defense: https://github.com/cisco-ai-defense/
- Invariant Labs: https://github.com/invariantlabs-ai/mcp-scan
- Backslash Hub: https://mcp.backslash.security
