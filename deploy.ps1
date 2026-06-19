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
    $ExtractRoot = $TempDir
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
        $ExtractRoot = $items[0].FullName
    }

    # Claude Design pone el sitio real en la subcarpeta "deploy/"
    $DeployDir = Join-Path $ExtractRoot "deploy"
    if (Test-Path $DeployDir) {
        $SourceDir = $DeployDir
        Write-Host "Usando carpeta deploy/ del ZIP" -ForegroundColor Gray
    } else {
        $SourceDir = $ExtractRoot
        Write-Host "No se encontró deploy/, copiando raíz del ZIP" -ForegroundColor Yellow
    }

    # Copiar solo los archivos del sitio al repo
    Write-Host "Copiando archivos al repo..." -ForegroundColor Cyan
    Copy-Item -Path "$SourceDir\*" -Destination $RepoRoot -Recurse -Force

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
