# deploy.ps1 — Toma el ZIP exportado de Claude Design y lo sube a GitHub
# Uso: .\deploy.ps1 -ZipPath "C:\Users\me\Downloads\proyecto.zip"
# Uso: .\deploy.ps1 -ZipPath "C:\Users\me\Downloads\proyecto.zip" -Mensaje "Actualiza diseño de hero"

param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,

    [string]$Mensaje = "Actualiza diseño desde Claude Design"
)

$RepoRoot = $PSScriptRoot

# Validar que el ZIP existe
if (-not (Test-Path $ZipPath)) {
    Write-Error "No se encontró el archivo: $ZipPath"
    exit 1
}

# Carpeta temporal para extraer
$TempDir = Join-Path $env:TEMP "plaza-deploy-$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
    Write-Host "Extrayendo $ZipPath..." -ForegroundColor Cyan
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

    # Si el ZIP tiene una subcarpeta raíz, entrar en ella
    $items = Get-ChildItem $TempDir
    $SourceDir = $TempDir
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
        $SourceDir = $items[0].FullName
        Write-Host "Subcarpeta detectada: $($items[0].Name)" -ForegroundColor Gray
    }

    # Copiar archivos al repo (sobreescribe los existentes)
    Write-Host "Copiando archivos al repo..." -ForegroundColor Cyan
    Copy-Item -Path "$SourceDir\*" -Destination $RepoRoot -Recurse -Force -Exclude "deploy.ps1", "CLAUDE.md", ".git"

    # Git add + commit + push
    Write-Host "Haciendo push a GitHub..." -ForegroundColor Cyan
    Set-Location $RepoRoot
    git add -A
    git commit -m $Mensaje
    git push origin main

    Write-Host "Listo. Cambios publicados en GitHub." -ForegroundColor Green

} finally {
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
}
