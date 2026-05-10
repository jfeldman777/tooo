# Сканирует папки img_1, img_2, ... и пишет game-data.js (класс из имени: 4i.png -> 4, i1.png -> 1).
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

function Get-ClassFromFilename([string]$name) {
    $m = [regex]::Match($name, '^(\d+)i\.', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m.Success) { return [int]$m.Groups[1].Value }
    $m2 = [regex]::Match($name, '^i(\d+)\.', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m2.Success) { return [int]$m2.Groups[1].Value }
    $m3 = [regex]::Match($name, '^(\d+)a\.', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m3.Success) { return [int]$m3.Groups[1].Value }
    return $null
}

$dirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^img_(\d+)$' } |
    Sort-Object { [int]($_.Name -replace '^img_', '') }

if (-not $dirs) {
    Write-Warning "No folders img_1, img_2, ... found."
}

$levels = New-Object System.Collections.Generic.List[object]
foreach ($d in $dirs) {
    $pics = @(Get-ChildItem -LiteralPath $d.FullName -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '^\.(png|jpg|jpeg|webp|gif)$' } |
        Sort-Object @{ Expression = { switch ($_.Extension.ToLowerInvariant()) {
                    '.png' { 0 } '.webp' { 1 } '.gif' { 2 } '.jpg' { 3 } '.jpeg' { 4 } Default { 9 }
                } } }, Name)
    $images = New-Object System.Collections.Generic.List[object]
    $seenClass = @{}
    foreach ($p in $pics) {
        $cls = Get-ClassFromFilename $p.Name
        if ($null -eq $cls) {
            Write-Warning ("Skip (unknown filename pattern): $($d.Name)\$($p.Name)")
            continue
        }
        if ($cls -lt 1 -or $cls -gt 8) {
            Write-Warning ("Skip (class not 1..8): $($p.Name) -> $cls")
            continue
        }
        if ($seenClass.ContainsKey($cls)) {
            continue
        }
        [void]$seenClass.Add($cls, $true)
        [void]$images.Add([ordered]@{ file = $p.Name; class = $cls })
    }
    if ($images.Count -eq 0) { continue }

    [void]$levels.Add([ordered]@{
            id = $d.Name
            folder = $d.Name
            images = $images.ToArray()
        })
}

$levelObjs = foreach ($lvl in $levels) {
    $imgObjs = foreach ($img in $lvl.images) {
        [PSCustomObject]@{ file = [string]$img.file; class = [int]$img.class }
    }
    [PSCustomObject]@{ id = [string]$lvl.id; folder = [string]$lvl.folder; images = @( $imgObjs ) }
}

$arr = @($levelObjs)
if ($arr.Count -eq 0) {
    $json = "[]"
} else {
    $json = ConvertTo-Json -InputObject $arr -Depth 10 -Compress
}
$outPath = Join-Path $root "game-data.js"
$js = "`"use strict`";`r`nwindow.GAME_LEVELS = $json;"
[System.IO.File]::WriteAllText($outPath, $js, [System.Text.UTF8Encoding]::new($false))

Write-Host "OK: $($arr.Count) sets -> $outPath"
