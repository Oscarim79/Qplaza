# deploy.ps1 — Toma el ZIP exportado de Claude Design y lo sube a GitHub
# Uso: .\deploy.ps1 -ZipPath "C:\Users\me\Downloads\proyecto.zip"
# Uso: .\deploy.ps1 -ZipPath "C:\Users\me\Downloads\proyecto.zip" -Mensaje "Actualiza diseño de hero"

param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,

    [string]$Mensaje = "Actualiza diseño desde Claude Design"
)

$RepoRoot = $PSScriptRoot

if (-not (Test-Path $ZipPath)) {
    Write-Error "No se encontró el archivo: $ZipPath"
    exit 1
}

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

    Write-Host "Copiando archivos al repo..." -ForegroundColor Cyan

    # 1. Copiar archivos .dc.html (diseños de opciones) desde la raíz del ZIP
    Get-ChildItem "$ExtractRoot\*.dc.html" -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName $RepoRoot -Force
        Write-Host "  $($_.Name)" -ForegroundColor Gray
    }

    # 2. Copiar sitio compilado desde deploy/ (support.js, assets — NO index.html)
    $DeployDir = Join-Path $ExtractRoot "deploy"
    $CopySource = if (Test-Path $DeployDir) { $DeployDir } else { $ExtractRoot }
    Get-ChildItem "$CopySource\*" -Recurse | Where-Object {
        -not $_.PSIsContainer -and $_.Name -ne "index.html" -and $_.Extension -ne ".dc.html"
    } | ForEach-Object {
        $dest = $_.FullName.Replace($CopySource, $RepoRoot)
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory $destDir | Out-Null }
        Copy-Item $_.FullName $dest -Force
    }
    Write-Host "  assets y scripts copiados (index.html preservado)" -ForegroundColor Gray

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
