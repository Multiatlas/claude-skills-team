---
name: Git Workflow MultiAtlas
description: Flujo Git unificado para todos los proyectos MultiAtlas. Branching simple, commits convencionales, tags semver al deploy, runbooks de recovery con comandos exactos, y pre-commit hook gitleaks anti-secret. Optimizado para flujo de 1-2 desarrolladores con repos productivos. Invocar antes de cualquier rotación grande, deploy a producción, o operación destructiva con git.
---

# 🛡️ Git Workflow MultiAtlas

> **Filosofía**: Git como red de seguridad, no como burocracia. El flujo es simple para no estorbar al solo developer, pero rígido en los puntos críticos: secrets, deploys y recovery.
>
> **Stack único**: GitHub (origen) + tags semver + gitleaks pre-commit + runbooks. NADA más.

---

## 🎯 Reglas no negociables

| # | Regla | Por qué |
|---|-------|---------|
| 1 | **`main` siempre verde** (testeable, desplegable) | Si rompes `main` rompes tu propia red de seguridad |
| 2 | **Tag semver al deploy a producción** (`v1.2.0`) | "Volver al pasado" en 1 comando |
| 3 | **Pre-commit gitleaks obligatorio** en todo repo cliente o producción | Un secret subido = trabajo de horas revocando + reescribiendo historia |
| 4 | **Conventional Commits** (`tipo: descripción`) | Hace `git log` legible y permite changelog automático |
| 5 | **Nunca `git push --force` en `main`** sin haberlo dicho en voz alta | Reescribe historia compartida → caos |
| 6 | **Nunca `git reset --hard`** sin haber visto `git status` y `git stash` antes | Borra trabajo no commiteado, irrecuperable |
| 7 | **`git reflog` antes de entrar en pánico** | Tu salvavidas: 30 días de cualquier commit que hayas tocado |

---

## 🌿 Branching simple

> **NO Gitflow. NO branches por entorno. SÍ trunk-based con excepciones puntuales.**

```
main ─────●──●──●──●──●──●──●──── ✅ Siempre verde, siempre desplegable
            \      /
             feat/* ── (1-3 días, merge fast-forward o squash)
                    \
                     hotfix/* ── (urgencia, branch desde tag, PR a main)
```

| Branch | Cuándo | Reglas |
|--------|--------|--------|
| `main` | Default. Todo lo que no requiera branch va aquí. | Push directo OK en repos solo-tú. PR si hay 2+ devs. |
| `feature/<nombre>` | Trabajo > 1 día o experimental que puede romperse | Branch desde `main`, merge cuando esté verde |
| `hotfix/<v-anterior>-<bug>` | Urgencia en producción | Branch desde el TAG (no desde `main`), merge a `main` + nuevo tag |

**Repos internos solo de Rubén** (`agente-it`, `vibe`, `setup-saas`...): push directo a `main` tras commit verificado en producción. No abrir PRs vacíos.

**Repos con cliente o equipo** (`asistehogar-app`, `bolsaapp`...): PR obligatorio con la plantilla.

---

## ✍️ Convenciones de commit

Usar **Conventional Commits** ya documentado en skill `multiatlas-methodology`. Tipos:

```
feat:     nueva funcionalidad
fix:      corrección de bug
docs:     documentación
style:    formato (no afecta lógica)
refactor: refactor sin cambio de comportamiento
test:     tests
chore:    tareas mantenimiento (deps, configs, build)
perf:     mejora de rendimiento
ci:       cambios CI/CD
```

**Formato del mensaje**:
```
<tipo>(<ámbito>): <descripción corta en imperativo>

<cuerpo opcional con el "por qué", no el "qué">
```

Ejemplos del repo `agente-it-multiatlas`:
- `tecniclimatizacion: catalogo climatizacion vivo en /catalogo/`
- `auth: capa 10 (2FA push Telegram auto-destruccion) + ampliar a TODOS los logins MA`
- `business-os: vhost app.multiatlas.es vivo en S3 + SSL Let's Encrypt`

---

## 🏷️ Tags semver al deploy

**Cada vez que subes a producción un cambio significativo de cliente o de producto interno, taguea ANTES de deployar**:

```bash
# 1. Ver versión actual
git tag --list 'v*' | sort -V | tail -5

# 2. Tag nueva versión (semver: MAJOR.MINOR.PATCH)
#    PATCH (v1.2.4): bugfix, sin cambios de comportamiento
#    MINOR (v1.3.0): nueva feature compatible
#    MAJOR (v2.0.0): cambio que rompe compatibilidad
git tag -a v1.3.0 -m "tecniclima: catálogo climatización completo (53 series)"

# 3. Push tag a remoto
git push origin v1.3.0

# 4. Ya puedes deployar. Si algo va mal:
git checkout v1.2.0  # vuelves al estado anterior en 1 comando
```

**Repos con tag vivos hoy en MA**: aplicar este patrón a partir del próximo deploy. No taggear retroactivamente todos los commits.

---

## 🔒 Pre-commit hook: gitleaks

> **El error más caro de Git es subir un secret a un repo público. Costó horas revocar + filter-repo + force push + avisar.** Esta línea de defensa lo evita en el último segundo, antes del commit.

`gitleaks` ya está instalado en tu PATH (Windows winget). Para activarlo en un repo:

```bash
# Una vez por repo, ejecutar desde la raíz:
cat > .git/hooks/pre-commit <<'EOF'
#!/usr/bin/env bash
# Pre-commit: bloquea commit si gitleaks detecta secrets
gitleaks protect --staged --redact -v
EOF
chmod +x .git/hooks/pre-commit
```

Para repos COMPARTIDOS (donde varios devs clonan), poner además un `.gitleaks.toml` versionado en raíz del repo con reglas de exclusión específicas, y usar `husky` o `lefthook` para que el hook se instale automáticamente al clonar.

**Si gitleaks bloquea un commit**:
1. **NO añadas excepciones a la ligera**. Lee qué detectó.
2. Si es un falso positivo (ej: API key de ejemplo en docs): `# gitleaks:allow` en la línea o regla en `.gitleaks.toml`.
3. Si es un secret real: bórralo del archivo, mete la real en `.env` (gitignored), commit de nuevo.

---

## 🆘 Runbooks de recovery

Cinco escenarios reales con comandos exactos. **Cuando entras en pánico, vienes aquí.**

### 1. "Borré algo y no estaba commiteado"

```bash
# Si el archivo se borró pero no se hizo `git rm`:
git checkout HEAD -- ruta/al/archivo

# Si el archivo se commitó-borró-commitó (quitar ese commit):
git log --diff-filter=D -- ruta/al/archivo  # encuentra el commit que lo borró
git checkout <commit-anterior>^ -- ruta/al/archivo  # recupera la versión antes
```

### 2. "Mi último commit estaba mal"

```bash
# OPCIÓN A — Quiero quitar el commit pero mantener los cambios para rehacer:
git reset --soft HEAD~1
# Los archivos siguen modificados y staged. Edita y vuelve a commitear.

# OPCIÓN B — Quiero modificar solo el mensaje:
git commit --amend -m "nuevo mensaje correcto"

# OPCIÓN C — Quiero AÑADIR un archivo olvidado al último commit:
git add archivo-olvidado
git commit --amend --no-edit

# ⚠️ NUNCA: git reset --hard HEAD~1 (borra los cambios sin posibilidad de recovery rápida)

# Si ya hiciste push del commit malo:
git push --force-with-lease   # más seguro que --force, falla si alguien empujó después
```

### 3. "Subí un secret a GitHub" 🚨

```bash
# PASO 1 — REVOCAR el secret en su servicio (Stripe, Anthropic, AC, etc.)
#          ANTES DE NADA. Hasta que no lo revoques, está expuesto en el historial.

# PASO 2 — Borrar del historial. Usar git filter-repo (más seguro que filter-branch):
pip install git-filter-repo  # si no lo tienes
git filter-repo --invert-paths --path archivo-con-secret  # borra el archivo entero
# o si quieres mantener el archivo y solo limpiar el secret:
git filter-repo --replace-text <(echo 'sk_live_xxx==>REDACTED')

# PASO 3 — Force push (avisa al equipo si hay):
git push origin main --force

# PASO 4 — Pedir a GitHub que purgue cachés/refs (si era público):
#          https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

# PASO 5 — Confirmar en GitHub Search que ya no aparece:
#          buscar el secret literal en el repo desde la web
```

**Si el repo es público**, asume que el secret YA fue scrapeado por bots (~5 min después del push). Revocar es lo único que vale.

### 4. "Necesito el código de hace 2 semanas"

```bash
# Ver qué había ese día:
git log --since="2 weeks ago" --until="13 days ago" --oneline

# Crear branch desde ese punto (sin tocar main):
git checkout -b rescate-2-weeks <commit-hash>
# Trabaja desde ahí. Si quieres traer ese código a main como hotfix:
git checkout main
git cherry-pick <commit-hash>

# Si tienes tags semver, mejor:
git checkout v1.1.0   # estado exacto de esa release
```

### 5. "Deploy roto en producción"

```bash
# OPCIÓN A — Si hay tag de la versión anterior estable:
git checkout v1.1.0
# Re-deploy desde aquí (manual: scp, push origin v1.1.0:main, etc.)

# OPCIÓN B — Si NO hay tag, encontrar el último commit estable:
git log --oneline --first-parent main | head -10  # ver últimos 10
git checkout <hash-último-estable>
# Re-deploy

# OPCIÓN C — Revertir el commit malo (sin destruir historial):
git revert <hash-commit-malo>   # crea un commit nuevo que deshace
git push origin main
# Re-deploy. El historial muestra que hubo un fallo y se revirtió, lo cual está bien.
```

---

## 🔓 Salvavidas: `git reflog`

> Si has hecho una operación destructiva (`reset --hard`, `checkout` sobre cambios no guardados, rebase mal hecho), **antes de entrar en pánico, ejecuta `git reflog`**.

```bash
git reflog
# Verás algo como:
# 89abc12 HEAD@{0}: reset: moving to HEAD~3
# 76def34 HEAD@{1}: commit: WIP — el commit que querías recuperar
# 65cd456 HEAD@{2}: commit: anterior

# Para volver al commit perdido:
git checkout 76def34
# o crear un branch desde ese punto:
git branch rescate 76def34
```

`reflog` guarda 30-90 días de cualquier referencia que tu HEAD haya tocado. **Casi nada está realmente perdido en Git.**

---

## 🚫 Comandos prohibidos sin doble check

Estos comandos son irreversibles o reescriben historia compartida. Antes de ejecutarlos, **decirlo en voz alta y asegurarte de que entiendes lo que hacen**:

| Comando | Riesgo | Antes de ejecutar |
|---------|--------|-------------------|
| `git reset --hard` | Borra cambios no commiteados | `git status` + `git stash` |
| `git push --force` | Reescribe remoto, puede pisar trabajo de otros | `git push --force-with-lease` |
| `git clean -fd` | Borra archivos no trackeados | `git clean -nd` (dry-run) primero |
| `git filter-repo` / `filter-branch` | Reescribe historia entera | Backup del repo primero |
| `git rebase -i` en commits ya pushed | Reescribe historia compartida | Solo si trabajas solo en ese branch |
| `git checkout -- .` | Descarta TODOS los cambios sin staging | `git status` primero |

---

## 📋 Checklist antes de deploy a producción

Aplica a cualquier deploy de cliente o producto MA:

- [ ] `git status` limpio (sin cambios sin commitear)
- [ ] `git log --oneline -5` muestra los últimos commits — los entiendo todos
- [ ] Pre-commit gitleaks pasó OK en todos los commits del rango
- [ ] Tag semver creado (`git tag -a vX.Y.Z -m "..."`)
- [ ] Smoke test contra el código actual (curl, browser, lo que aplique)
- [ ] Deploy ejecutado
- [ ] Smoke test contra producción tras deploy
- [ ] Tag pusheado al remoto (`git push origin vX.Y.Z`)
- [ ] Si algo va mal: `git checkout v(anterior)` + redeploy

---

## 🔗 Referencias cruzadas

- **Conventional Commits**: skill `multiatlas-methodology` (sección Auto-Blindaje + commits)
- **Secret scanning**: skill `github-secret-scanning` en `multiatlas-setup-saas` (Push Protection lado server)
- **Deploy a producción con backup**: memoria `feedback_deploys_produccion.md` (md5 baseline + rollback)
- **Push tras commit verificado en repos internos**: memoria `feedback_push_tras_commit_verificado.md` (no acumular ni PRs vacíos)
- **Auditar MCPs antes de instalar/actualizar**: skill `mcp-security-audit` (pin exacto, NUNCA `^x.y.z`)

---

## 🎯 Cuándo invocar esta skill

**Sí, invocarla cuando**:
- Vas a hacer un deploy a producción de cliente
- Vas a tocar `main` con commits importantes
- Has roto algo y no sabes cómo recuperar
- Vas a rotar credenciales o tocar secrets en un repo
- Vas a configurar un repo nuevo (gitleaks hook, branch protections si aplica)
- Has visto a alguien teclear `git push --force` y te pone nervioso

**No hace falta invocarla para**:
- Commits de rutina con cambios pequeños
- Pulls / fetches normales
- Branches efímeros que no van a `main`
