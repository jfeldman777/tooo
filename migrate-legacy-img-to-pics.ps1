# One-time: copies legacy root folders img_1, img_2, ... into pics\img_N\ as 1.png .. 8.*
# Class from old name: 4i.png -> 4, i1.png -> 1, 3a.png -> 3. Then removes legacy img_* folders.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$picsRoot = Join-Path $root "pics"
New-Item -ItemType Directory -Force -Path $picsRoot | Out-Null

function Get-ClassFromFilename([string]$name) {
    $m = [regex]::Match($name, '^(\d+)i\.', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m.Success) { return [int]$m.Groups[1].Value }
    $m2 = [regex]::Match($name, '^i(\d+)\.', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m2.Success) { return [int]$m2.Groups[1].Value }
    $m3 = [regex]::Match($name, '^(\d+)a\.', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m3.Success) { return [int]$m3.Groups[1].Value }
    return $null
}

$legacyDirs = @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^img_\d+$' } |
        Sort-Object { [int]($_.Name -replace '^img_', '') })

if ($legacyDirs.Count -eq 0) {
    Write-Host "No img_* folders at project root - nothing to migrate."
    exit 0
}

foreach ($d in $legacyDirs) {
    $destSeries = Join-Path $picsRoot $d.Name
    if (Test-Path -LiteralPath $destSeries) {
        Write-Warning "Already exists: $destSeries - skip copy for $($d.Name)"
        continue
    }
    New-Item -ItemType Directory -Force -Path $destSeries | Out-Null
    $byClass = @{ }
    Get-ChildItem -LiteralPath $d.FullName -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '^\.(png|jpg|jpeg|webp|gif)$' } |
        ForEach-Object {
            $cls = Get-ClassFromFilename $_.Name
            if ($null -eq $cls -or $cls -lt 1 -or $cls -gt 8) { return }
            $byClass["$cls"] = $_
        }
    foreach ($k in $byClass.Keys) {
        $src = $byClass[$k]
        $destFile = Join-Path $destSeries ($k + $src.Extension.ToLowerInvariant())
        Copy-Item -LiteralPath $src.FullName -Destination $destFile -Force
    }
    Write-Host "Copied: $($d.Name) -> pics\$($d.Name)\"
}

foreach ($d in $legacyDirs) {
    $destSeries = Join-Path $picsRoot $d.Name
    if (-not (Test-Path -LiteralPath $destSeries)) { continue }
    Remove-Item -LiteralPath $d.FullName -Recurse -Force
    Write-Host "Removed legacy folder: $($d.Name)"
}

Write-Host "Done. Run build-game-data.ps1"
