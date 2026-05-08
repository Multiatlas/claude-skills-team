# =============================================================================
# Invoke-GitPullWithOneDriveRetry — Wrapper git pull con reintento solo para OneDrive locks
# =============================================================================
#
# CONTEXTO
# --------
# En PCs con repos git dentro de OneDrive (estructura canónica MA:
# ~\OneDrive\Documentos\DEVELOPER\<repo>), ocasionalmente `git pull` falla con:
#
#   error: cannot open '.git/FETCH_HEAD': Permission denied
#
# Esto ocurre porque OneDrive bloquea el archivo durante un microsegundo mientras
# lo sincroniza al cloud. El error es totalmente transient — un retry pasa.
#
# REGLAS DEL WRAPPER (3)
# ----------------------
# 1. Reintenta SOLO si el output coincide con "Permission denied" AND ruta
#    dentro de ".git/". Cualquier otro error (network, conflicto, autenticación)
#    se propaga inmediatamente sin reintento — esos son problemas reales.
#
# 2. Máximo 3 reintentos con Start-Sleep 2 entre cada uno. Tras 3 intentos
#    fallidos, devuelve fallo y deja que el flujo padre muestre el aviso amarillo.
#
# 3. Cada reintento se loguea visible en cyan oscuro:
#       [reintento N/3] OneDrive lock detectado en .git/, esperando 2s...
#    Si un día empieza a reintentar siempre 2-3 veces, el equipo se entera
#    (puede indicar que OneDrive se ha vuelto más agresivo).
#
# ORIGEN
# ------
# Diseñado por el agente IT de Desi tras detectar el problema el 2026-05-07
# en su PC. Validado en producción ese mismo día y propuesto al equipo MA por
# Desi el 2026-05-08. Aplicable a cualquier miembro del equipo con repos git
# dentro de OneDrive.
#
# CÓMO USARLO
# -----------
# Hacer dot-source en tu script personal de morning:
#
#   . "$HOME\OneDrive\Documentos\DEVELOPER\claude-skills-team\skills\setup-vscode-multiatlas-team\git-pull-onedrive-retry.ps1"
#
# Y luego en el bucle de tu script:
#
#   foreach ($r in $repos) {
#       Write-Host "--- $($r.Name) ---" -ForegroundColor Yellow
#       $ok = Invoke-GitPullWithOneDriveRetry -RepoPath $r.Path -Branch $r.Branch
#       if (-not $ok) {
#           Write-Host "  ERROR: git pull falló en $($r.Name)" -ForegroundColor Red
#           $failed += $r.Name
#       }
#   }
#
# =============================================================================

function Invoke-GitPullWithOneDriveRetry {
    param(
        [Parameter(Mandatory)] [string]$RepoPath,
        [Parameter(Mandatory)] [string]$Branch,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2
    )

    Set-Location $RepoPath
    $attempt = 0
    while ($true) {
        $attempt++
        $output = git pull origin $Branch 2>&1
        $exitCode = $LASTEXITCODE

        # Imprimir output siempre (sea OK o error)
        $output | ForEach-Object { Write-Host "  $_" }

        if ($exitCode -eq 0) { return $true }

        # ¿Es el patrón de OneDrive lock? "Permission denied" + ruta dentro de .git/
        $joined = ($output | Out-String)
        $isOneDriveLock = ($joined -match 'Permission denied') -and ($joined -match '\.git[\\/]')

        if (-not $isOneDriveLock) {
            # Error real (network, conflicto, auth, etc.) — no reintentar, dejar caer
            return $false
        }

        if ($attempt -ge $MaxRetries) {
            Write-Host "  [reintento $attempt/$MaxRetries fallido] OneDrive lock persiste tras $MaxRetries intentos" -ForegroundColor Red
            return $false
        }

        Write-Host "  [reintento $attempt/$MaxRetries] OneDrive lock detectado en .git/, esperando ${DelaySeconds}s..." -ForegroundColor DarkCyan
        Start-Sleep -Seconds $DelaySeconds
    }
}
