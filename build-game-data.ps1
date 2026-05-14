# Scans pics/<series_name>/ for files 1.png .. 8.png (also .webp .jpg .jpeg .gif).
# Series title in game = folder name. Writes game-data.js (folder: pics/FolderName).
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$picsRoot = Join-Path $root "pics"

$imageExts = @(".png", ".webp", ".jpg", ".jpeg", ".gif")

function Find-ClassFile([string]$seriesDir, [int]$classNum) {
    foreach ($ext in $imageExts) {
        $name = "$classNum$ext"
        $full = Join-Path $seriesDir $name
        if (Test-Path -LiteralPath $full) {
            return Get-Item -LiteralPath $full
        }
    }
    return $null
}

if (-not (Test-Path -LiteralPath $picsRoot)) {
    Write-Warning "Folder pics not found. Create pics\SeriesName\ with 1.png..8.png or run migrate-legacy-img-to-pics.ps1."
}

$seriesDirs = @()
if (Test-Path -LiteralPath $picsRoot) {
    $seriesDirs = @(Get-ChildItem -LiteralPath $picsRoot -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name)
}

$levels = New-Object System.Collections.Generic.List[object]
foreach ($d in $seriesDirs) {
    $images = New-Object System.Collections.Generic.List[object]
    for ($c = 1; $c -le 8; $c++) {
        $hit = Find-ClassFile $d.FullName $c
        if ($null -eq $hit) {
            Write-Warning "Series $($d.Name): missing file for class $c (expected $c.png etc.) - series skipped."
            $images = $null
            break
        }
        [void]$images.Add([ordered]@{ file = $hit.Name; class = $c })
    }
    if ($null -eq $images) { continue }
    if ($images.Count -ne 8) { continue }

    $folderWeb = "pics/" + $d.Name.Replace("\", "/")
    [void]$levels.Add([ordered]@{
            id     = $d.Name
            folder = $folderWeb
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
}
else {
    $json = ConvertTo-Json -InputObject $arr -Depth 10 -Compress
}
$outPath = Join-Path $root "game-data.js"
$js = "`"use strict`";`r`nwindow.GAME_LEVELS = $json;"
[System.IO.File]::WriteAllText($outPath, $js, [System.Text.UTF8Encoding]::new($false))

# Bust browser/CDN cache for GitHub Pages: same URL otherwise keeps old GAME_LEVELS.
$gameHtmlPath = Join-Path $root "game.html"
if (Test-Path -LiteralPath $gameHtmlPath) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $html = [System.IO.File]::ReadAllText($gameHtmlPath, $utf8)
    $bust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $pat = '<script\s+src="game-data\.js(?:\?[^"]*)?"\s*>\s*</script>'
    $rep = "<script src=`"game-data.js?v=$bust`"></script>"
    $m = [regex]::Match($html, $pat)
    if ($m.Success) {
        $newHtml = $html.Substring(0, $m.Index) + $rep + $html.Substring($m.Index + $m.Length)
        [System.IO.File]::WriteAllText($gameHtmlPath, $newHtml, $utf8)
        Write-Host "OK: game.html -> game-data.js?v=$bust"
    }
    else {
        Write-Warning "game.html: no <script src=`"game-data.js`"> tag found; cache-bust skipped."
    }
}

Write-Host "OK: $($arr.Count) series in pics -> $outPath"
