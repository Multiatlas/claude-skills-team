---
name: Setup VS Code MultiAtlas Team
description: Onboarding técnico para nuevos miembros del equipo MultiAtlas (Desi, Isaac, futuros). Configura VS Code + Claude Code + extensiones + skills + repos clave igual que el PC principal. Invocar cuando un nuevo agente Claude Code arranque y diga "soy nuevo en MultiAtlas-IT", "necesito configurar mi PC", "instala extensiones del equipo", o variantes.
---

# 🧭 Setup VS Code para Equipo MultiAtlas-IT

> **Esta skill se invoca cuando un nuevo miembro del equipo MA arranca su Claude Code.**
> Le guía paso a paso para tener su PC configurado igual que el PC principal de Rubén.

---

## ¿Cuándo invocarme?

- "Soy Desi, voy a configurar mi PC"
- "Soy nuevo en MultiAtlas-IT, ¿qué tengo que instalar?"
- "Instala las extensiones VS Code del equipo MultiAtlas"
- "Configura mi entorno como el de Rubén"
- "Onboarding técnico"

## Inventario del PC principal (a replicar)

### Extensiones VS Code (26)

```
anthropic.claude-code               ⭐ esencial — extensión principal
devsense.composer-php-vscode
devsense.intelli-php-vscode
devsense.phptools-vscode
devsense.profiler-php-vscode
esbenp.prettier-vscode
golang.go
llvm-vs-code-extensions.vscode-clangd
meta.pyrefly
ms-azuretools.vscode-containers
ms-azuretools.vscode-docker
ms-python.debugpy
ms-python.python
ms-python.vscode-pylance
ms-python.vscode-python-envs
ms-vscode-remote.remote-containers
ms-vscode.powershell
redhat.java
shopify.ruby-lsp
tomoki1207.pdf
vscjava.vscode-gradle
vscjava.vscode-java-debug
vscjava.vscode-java-dependency
vscjava.vscode-java-pack
vscjava.vscode-java-test
vscjava.vscode-maven
```

### Configuración Claude Code (`~/.claude/`)

| Archivo | Origen | Notas |
|---|---|---|
| `~/.claude/CLAUDE.md` | Copiar desde Drive `setup-vscode-desi/CLAUDE.md` | Reglas globales: idioma español, economía tokens (navegador último recurso), regla Snyk |
| `~/.claude/settings.json` | Copiar desde Drive `setup-vscode-desi/settings.json` | Permisos allow/ask por defecto, evita popups |
| `~/.claude/.credentials.json` | NO copiar — cada uno tiene el suyo tras login propio | |
| `~/.claude/skills/` | Clonar carpeta desde el PC principal o el repo `multiatlas-setup-saas/.claude/skills/` | 26 skills globales (incluyendo esta + git-workflow-multiatlas + protocolo-cierre-multiatlas-team) |

### Repositorios clave (clonar)

| Repo | Para qué |
|---|---|
| `Multiatlas/agente-it-multiatlas` | **Memoria global del ecosistema MA** — clientes, docs, PRD, PENDIENTES. Pull diario obligatorio |
| `Multiatlas/programa-gestion-multiatlas` | Repo de Desi (ERP/CRM interno). Otros miembros: solo lectura salvo coordinación |
| `Multiatlas/multiatlas-setup-saas` | Template SaaS + skills compartidas. Útil de tener clonado para referencia |

### MCPs configurados (los que de verdad usa el equipo)

- **Playwright** — navegador (uso restringido por economía de tokens, ver CLAUDE.md)
- **Snyk** — security scan
- **Google Drive** — gestión de docs en `H:\Mi unidad\SAAS FACTORY\SYNC-ANTIGRAVITY\` (canal de comunicación equipo)

Cada miembro del equipo configura los MCPs con su propia auth (OAuth flow propio, no compartir credenciales).

---

## Procedimiento paso a paso

### Paso 1 — Verificar prerequisitos

```bash
# Versión Node.js (debe ser >= 22)
node --version

# Git instalado
git --version

# VS Code instalado (si no, descargar de https://code.visualstudio.com/)
code --version
```

### Paso 2 — Instalar extensión Claude Code

```powershell
# Desde terminal VS Code (Windows PowerShell)
code --install-extension anthropic.claude-code
```

O manual: VS Code → Extensions (Ctrl+Shift+X) → buscar "Claude Code" → publisher Anthropic → Install

### Paso 3 — Login Claude Code

```
Ctrl+Shift+P → "Claude Code: Sign In" → abre navegador → login con cuenta Anthropic propia (NO la de Rubén)
```

### Paso 4 — Instalar las 26 extensiones del equipo (PowerShell)

```powershell
$extensions = @(
    "anthropic.claude-code",
    "devsense.composer-php-vscode",
    "devsense.intelli-php-vscode",
    "devsense.phptools-vscode",
    "devsense.profiler-php-vscode",
    "esbenp.prettier-vscode",
    "golang.go",
    "llvm-vs-code-extensions.vscode-clangd",
    "meta.pyrefly",
    "ms-azuretools.vscode-containers",
    "ms-azuretools.vscode-docker",
    "ms-python.debugpy",
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-python.vscode-python-envs",
    "ms-vscode-remote.remote-containers",
    "ms-vscode.powershell",
    "redhat.java",
    "shopify.ruby-lsp",
    "tomoki1207.pdf",
    "vscjava.vscode-gradle",
    "vscjava.vscode-java-debug",
    "vscjava.vscode-java-dependency",
    "vscjava.vscode-java-pack",
    "vscjava.vscode-java-test",
    "vscjava.vscode-maven"
)

foreach ($ext in $extensions) {
    code --install-extension $ext
}
```

### Paso 5 — Copiar config Claude Code

Descargar de Drive (carpeta `SAAS FACTORY/SYNC-ANTIGRAVITY/setup-vscode-desi/`):
- `CLAUDE.md` → copiar a `C:\Users\<tu-usuario>\.claude\CLAUDE.md`
- `settings.json` → copiar a `C:\Users\<tu-usuario>\.claude\settings.json`

### Paso 6 — Clonar repositorios

```bash
cd C:\Users\<tu-usuario>\OneDrive\Documentos\DEVELOPER

git clone https://github.com/Multiatlas/agente-it-multiatlas.git
git clone https://github.com/Multiatlas/programa-gestion-multiatlas.git
git clone https://github.com/Multiatlas/multiatlas-setup-saas.git  # opcional, referencia
```

### Paso 7 — Hook gitleaks pre-commit (anti-secrets)

```bash
cd agente-it-multiatlas

# Crear hook
cat > .git/hooks/pre-commit << 'EOF'
#!/usr/bin/env bash
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "⚠️ gitleaks no encontrado en PATH. Skip."
  exit 0
fi
echo "🔍 gitleaks pre-commit: escaneando secrets..."
gitleaks protect --staged --redact -v
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "🚨 SECRETS detectados. Limpia antes de commitear."
  exit 1
fi
echo "✅ gitleaks: sin secrets detectados."
EOF

chmod +x .git/hooks/pre-commit
```

Si gitleaks no está en PATH, instalar:
```powershell
winget install Gitleaks.Gitleaks
```

### Paso 8 — Verificación final

Abrir VS Code en `agente-it-multiatlas` (`code .`) y pedir a Claude Code:

```
Hola. Soy [nombre]. Lista los clientes activos del repo y muéstrame el contenido de docs/ONBOARDING-CHAT-NUEVO.md
```

Si responde con la lista correcta de clientes (Tecniclima, Surdeplant, Asistehogar, BolsaApp, etc.) y lee el doc onboarding, **el setup está OK**.

---

## Tokens / credenciales que cada miembro tiene que tener (no se comparten)

| Token | Cómo obtenerlo |
|---|---|
| Cuenta Anthropic | Cada uno tiene su propia. Si no tienes, alta en https://console.anthropic.com |
| GitHub PAT (Personal Access Token) | Cada uno crea el suyo en `github.com/settings/tokens`. Scopes mínimos: `repo`, `workflow` |
| Acceso a la organización Multiatlas en GitHub | Rubén invita al miembro como collaborator |
| Bitwarden Teams MA | Pendiente — Rubén crea cuenta team y invita |
| MCPs con OAuth (Drive, etc.) | Flow propio cuando el MCP lo solicite |

---

## Después del setup — siguientes pasos

1. Leer `agente-it-multiatlas/docs/ONBOARDING-CHAT-NUEVO.md` (5 min, te orienta)
2. Leer `agente-it-multiatlas/docs/PENDIENTES.md` sección "🆕 Sesión más reciente"
3. Leer las 3 fichas de cliente más activas en `agente-it-multiatlas/clientes/`
4. Skill `protocolo-cierre-multiatlas-team` también está en el sistema — invocarla al cerrar cada sesión

---

## Si algo falla

- Pide a Rubén ayuda directa por WhatsApp/Telegram
- Si es problema de Claude Code, comparte la traza con él
- Si es problema de extensión VS Code, búscala en el marketplace y revisa requisitos
- **No avances con la siguiente fase si una anterior falla** — algo lo necesitará después

---

## 🌅 Helper para script morning personal: wrapper git pull con reintento OneDrive

Si te haces un script morning personal (tipo `multiatlas-morning.ps1` en el Escritorio) que haga `git pull` en tus repos cada mañana, **añade este wrapper** para evitar el "OneDrive lock" intermitente.

### El problema

En PCs con repos git dentro de OneDrive (estructura canónica MA: `~\OneDrive\Documentos\DEVELOPER\<repo>`), `git pull` ocasionalmente falla con:

```
error: cannot open '.git/FETCH_HEAD': Permission denied
```

Esto pasa porque OneDrive bloquea el archivo durante un microsegundo mientras lo sincroniza al cloud. El error es transient — un retry pasa.

### La solución

Hay un helper PowerShell incluido en esta skill: [`git-pull-onedrive-retry.ps1`](git-pull-onedrive-retry.ps1).

**3 reglas del wrapper**:
1. Reintenta SOLO si es "Permission denied" + ruta `.git/`. Cualquier otro error (network, conflicto, auth) se propaga sin retry → no oculta problemas reales.
2. Máximo 3 reintentos con `Start-Sleep 2`. Tras eso, falla normalmente.
3. Cada reintento se loguea en cyan oscuro. Si empieza a reintentar siempre, el equipo se entera (OneDrive se ha vuelto más agresivo).

### Cómo usarlo

En tu script morning personal:

```powershell
# Cargar el wrapper (dot-source)
. "$HOME\OneDrive\Documentos\DEVELOPER\claude-skills-team\skills\setup-vscode-multiatlas-team\git-pull-onedrive-retry.ps1"

# Lista de tus repos
$repos = @(
    @{ Name = "agente-it-multiatlas"; Path = "$HOME\OneDrive\Documentos\DEVELOPER\agente-it-multiatlas"; Branch = "master" },
    @{ Name = "multiatlas-setup-saas"; Path = "$HOME\OneDrive\Documentos\DEVELOPER\multiatlas-setup-saas"; Branch = "main" },
    @{ Name = "claude-skills-team"; Path = "$HOME\OneDrive\Documentos\DEVELOPER\claude-skills-team"; Branch = "main" }
    # añadir los tuyos...
)

$failed = @()
foreach ($r in $repos) {
    Write-Host "--- $($r.Name) ---" -ForegroundColor Yellow
    if (-not (Test-Path $r.Path)) {
        Write-Host "  AVISO: ruta no encontrada" -ForegroundColor DarkYellow
        $failed += $r.Name
        continue
    }
    $ok = Invoke-GitPullWithOneDriveRetry -RepoPath $r.Path -Branch $r.Branch
    if (-not $ok) {
        Write-Host "  ERROR: git pull falló en $($r.Name)" -ForegroundColor Red
        $failed += $r.Name
    }
}

if ($failed.Count -eq 0) {
    Write-Host "`n✅ Todo sincronizado." -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Falló: $($failed -join ', ')" -ForegroundColor DarkYellow
}
```

### Origen y validación

Diseñado por el agente IT de Desi tras detectar el problema en su PC el 2026-05-07. Validado en producción el mismo día (resolvió `programa-gestion-multiatlas` en primer reintento). Propuesto al equipo MA por Desi el 2026-05-08 e incorporado al estándar.

---

## ⚙️ Tooling adicional

Cuando el equipo decida formalizar un script morning oficial unificado para todos, irá en este mismo directorio. Hasta entonces, el helper `git-pull-onedrive-retry.ps1` queda disponible para integrarlo a scripts personales.
