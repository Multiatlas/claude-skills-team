# install.ps1 — Instala las skills del equipo MultiAtlas en ~/.claude/skills/
# Uso: .\install.ps1
#
# Copia cada subcarpeta de skills/ a $env:USERPROFILE\.claude\skills\
# Si la skill ya existe en destino, la sobreescribe (este repo es la fuente de verdad).

$ErrorActionPreference = "Stop"

$repoSkillsDir = Join-Path $PSScriptRoot "skills"
$targetSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"

Write-Host ""
Write-Host "===== Instalador skills MultiAtlas =====" -ForegroundColor Cyan
Write-Host ""
Write-Host "Origen : $repoSkillsDir"
Write-Host "Destino: $targetSkillsDir"
Write-Host ""

# Crear destino si no existe
if (-not (Test-Path $targetSkillsDir)) {
    Write-Host "Carpeta destino no existe. Creandola..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $targetSkillsDir -Force | Out-Null
}

# Verificar origen
if (-not (Test-Path $repoSkillsDir)) {
    Write-Host "ERROR: no encuentro la carpeta skills/ en el repo." -ForegroundColor Red
    Write-Host "Asegurate de ejecutar este script desde la raiz del repo claude-skills-team." -ForegroundColor Red
    exit 1
}

# Copiar cada skill
$installed = 0
Get-ChildItem -Path $repoSkillsDir -Directory | ForEach-Object {
    $skillName = $_.Name
    $sourcePath = $_.FullName
    $destPath = Join-Path $targetSkillsDir $skillName

    Write-Host "Instalando: $skillName" -ForegroundColor Green

    if (Test-Path $destPath) {
        Remove-Item -Path $destPath -Recurse -Force
    }

    Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
    $installed++
}

Write-Host ""
Write-Host "OK: $installed skills instaladas en $targetSkillsDir" -ForegroundColor Green
Write-Host ""
Write-Host "Reinicia VS Code para que Claude Code detecte las skills nuevas." -ForegroundColor Yellow
Write-Host ""
