---
name: Protocolo de Cierre MultiAtlas Team
description: Protocolo estándar de cierre de sesión para cualquier chat Claude Code del equipo MultiAtlas. Asegura que no se pierde trabajo, se commitea+pushea correctamente, se actualiza memoria persistente si aplica, y se deja la coordinación clara para el siguiente. Invocar cuando el usuario diga "cierre de sesión", "vamos a cerrar", "protocolo de cierre", "hasta mañana", "fin del día", o variantes.
---

# 🔒 Protocolo de Cierre — Equipo MultiAtlas

> **Cualquier chat Claude Code del equipo MA invoca esta skill al cerrar sesión.**
> Garantiza que el trabajo del día queda persistido en GitHub, la memoria persistente está al día, y el siguiente turno (mañana o el otro miembro del equipo) tiene contexto fresco.

---

## ¿Cuándo invocarme?

- "Vamos a cerrar sesión"
- "Protocolo de cierre"
- "Hasta mañana"
- "Cierro y seguimos mañana"
- "Hago commit y cierro"
- "Fin del día"

## Los 5 pasos (ejecutar SIEMPRE en orden)

### Paso 1 — Verificar git status del repo agente-it-multiatlas

```bash
cd /path/to/agente-it-multiatlas
git status
```

**Si hay cambios sin commitear:**

1. **Revisar QUÉ se va a commitear** (`git diff` para ver el detalle)
2. **Add específico** (NO usar `git add .` para no subir basura tipo `node_modules` o archivos temporales):
   ```bash
   git add ruta/al/archivo1 ruta/al/archivo2
   ```
3. **Commit con mensaje en Conventional Commits** (`tipo: descripción`):
   ```bash
   git commit -m "tipo(ámbito): descripción concisa en imperativo"
   ```
4. **Push a master**:
   ```bash
   git push origin master
   ```
5. **Verificar que push fue OK** (sin errores de auth, conflicto, etc.)

**Si no hay cambios**: skip al paso 2.

### Paso 2 — Verificar git status del repo del miembro (si aplica)

Si el miembro tiene un repo propio que estaba tocando (ej: Desi → `programa-gestion-multiatlas`, otro chat → su repo especializado), repetir el mismo proceso del paso 1 sobre ese repo.

### Paso 3 — Memoria persistente nueva (si hay)

¿Has aprendido algo no obvio que aplique a futuro?
- Regla operativa nueva
- Convención que no estaba documentada
- Lección aprendida de incidente
- Decisión arquitectónica importante

**Si SÍ**:
1. Crear archivo en `~/.claude/projects/<proyecto-id>/memory/<tipo>_<nombre>.md` con frontmatter (name, description, type)
2. Añadir línea pointer en `MEMORY.md` del mismo directorio
3. Commit + push (las memorias persistentes en sí no van al repo del proyecto, solo el doc/PENDIENTES si referencias al hecho de que existe la memoria nueva)

**Tipos de memoria**:
- `feedback_*` — reglas operativas (qué hacer, qué no hacer)
- `project_*` — estado de proyecto en curso (cambia con tiempo)
- `reference_*` — pointers a info externa (URLs, IDs, accesos)
- `user_*` — preferencias del usuario

### Paso 4 — Actualizar `docs/PENDIENTES.md` (solo chat principal)

**Importante**: solo el chat principal de Rubén actualiza `docs/PENDIENTES.md` directamente. Los chats de otros miembros del equipo (Desi, Isaac) **NO tocan PENDIENTES.md** — avisan a Rubén por canal de coordinación (Drive, WhatsApp) si hay algo que añadir.

Si eres el chat principal, al cierre:
1. Mover items completados de "🆕 Sesión actual" a `## ✅ Cerrado en esta sesión`
2. Crear nueva sección `## 🆕 Sesión <fecha siguiente>` para próxima vez
3. Conservar items pendientes con su prioridad

### Paso 5 — Resumen final al usuario

Generar un resumen ejecutivo corto que cubra:

| Sección | Qué incluir |
|---|---|
| **✅ Cerrado** | Lo terminado en la sesión, con commit hash si aplica |
| **🟡 Bloqueantes / pendientes** | Cosas que dependen de input externo (cliente, reunión, otro chat) |
| **📋 Próximos pasos** | Qué retomar al volver, en orden de prioridad |
| **📦 Commits del día** | Lista de hashes y mensaje corto |

Ejemplo:

```markdown
## 🔒 Sesión cerrada

**Cerrado**:
- ✅ Iter 3 catálogo Tecniclima — 5 fichas SEO actualizadas (commit `abc123`)
- ✅ Bitwarden Teams MA activado, Desi invitada

**Bloqueantes**:
- 🟡 Esperando feedback Luis Miguel sobre precios PerFera

**Próxima sesión**:
1. Procesar feedback Luis Miguel cuando llegue
2. Continuar iter 4 (modelos faltantes)
3. Empezar montaje backup nocturno S3 para Desi

**Commits del día**:
- abc123 tecniclimatizacion: iter 3 SEO 5 fichas
- def456 docs: actualizar PENDIENTES con bloqueantes
```

---

## Reglas extra del protocolo

- **No saltarse pasos**: si gitleaks bloquea un commit, NO añadas excepción a la ligera. Lee qué detectó, limpia, recommit.
- **No usar `git add .`**: siempre add específico. Evita subir basura (node_modules, .env, archivos temporales).
- **No usar `--force` push** salvo que sea explícitamente necesario y avisado al equipo.
- **Si hay conflicto al pushear**: hacer pull primero, resolver conflicto manualmente, recommit.
- **Si la sesión fue corta y no hay cambios significativos**: igual hacer un mini-resumen para el usuario, así sabe que se cerró ordenadamente.

---

## Checklist mental antes de salir

- [ ] `git status` limpio en agente-it-multiatlas
- [ ] `git status` limpio en repo propio (si aplica)
- [ ] `git log -3` muestra mis últimos commits
- [ ] Memoria persistente actualizada si toca
- [ ] PENDIENTES.md actualizado (solo chat principal)
- [ ] Resumen al usuario claro

Si algún punto da error o duda → no cerrar, resolver primero.
