param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)][string]$Link
)

$resolved = Resolve-Path $Target -ErrorAction SilentlyContinue
if (-not $resolved) {
    Write-Error "Origem nao encontrada: $Target"
    exit 1
}

if (Test-Path $Link) {
    Write-Error "Ja existe algo em: $Link"
    exit 1
}

$linkDir = Split-Path $Link -Parent
if ($linkDir -and -not (Test-Path $linkDir)) {
    New-Item -ItemType Directory -Force $linkDir | Out-Null
}

$type = if ((Get-Item $resolved).PSIsContainer) { "Junction" } else { "SymbolicLink" }
New-Item -ItemType $type -Path $Link -Target $resolved | Out-Null

Write-Host "Link criado: $Link -> $resolved"
