# update.ps1 — Actualiza las skills del equipo MultiAtlas
# Uso: .\update.ps1
#
# 1. git pull desde GitHub
# 2. Llama a install.ps1 para copiar las skills actualizadas a ~/.claude/skills/

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "===== Actualizador skills MultiAtlas =====" -ForegroundColor Cyan
Write-Host ""

# 1. Pull
Write-Host "[1/2] git pull..." -ForegroundColor Cyan
Push-Location $PSScriptRoot
try {
    git pull origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: git pull fallo. Revisa conflictos o conexion." -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

Write-Host ""

# 2. Reinstalar
Write-Host "[2/2] Reinstalando skills..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "install.ps1")
