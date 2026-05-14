# Scans book/ for N.txt | N.png | … (N = leading digits). Writes book/book-manifest.json.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$bookDir = Join-Path $root "book"
$outPath = Join-Path $bookDir "book-manifest.json"

if (-not (Test-Path -LiteralPath $bookDir)) {
    Write-Warning "Folder book not found."
    exit 1
}

$rows = New-Object System.Collections.Generic.List[object]
Get-ChildItem -LiteralPath $bookDir -File -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Name -eq "book-manifest.json") { return }
    if ($_.Name -match '^(\d+)\.(txt|png|webp|jpg|jpeg|gif)$') {
        $n = [int]$Matches[1]
        $ext = $Matches[2].ToLowerInvariant()
        $kind = if ($ext -eq "txt") { "text" } else { "image" }
        [void]$rows.Add([ordered]@{ n = $n; file = $_.Name; kind = $kind })
    }
}

$sorted = $rows | Sort-Object { $_.n }
$pageObjs = foreach ($r in $sorted) {
    [PSCustomObject]@{ file = [string]$r.file; kind = [string]$r.kind }
}
$wrap = [PSCustomObject]@{ pages = @($pageObjs) }
$json = ConvertTo-Json -InputObject $wrap -Depth 5 -Compress
[System.IO.File]::WriteAllText($outPath, $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "OK: $($pageObjs.Count) pages -> $outPath"

# book-titles.json: { "byFile": { "1.txt": "Заголовок", ... } } — заголовки для оглавления
$titlesPath = Join-Path $bookDir "book-titles.json"
$byFile = @{}
if (Test-Path -LiteralPath $titlesPath) {
    try {
        $tRaw = Get-Content -LiteralPath $titlesPath -Raw -Encoding UTF8
        $tParsed = $tRaw | ConvertFrom-Json
        if ($null -ne $tParsed.byFile) {
            $tParsed.byFile.PSObject.Properties | ForEach-Object {
                $byFile[$_.Name] = [string]$_.Value
            }
        }
    }
    catch {
        Write-Warning "Could not read book-titles.json, starting titles from scratch."
    }
}
$byFileExport = @{}
foreach ($r in $sorted) {
    $fn = [string]$r.file
    if ($byFile.ContainsKey($fn)) {
        $byFileExport[$fn] = $byFile[$fn]
    }
    else {
        $byFileExport[$fn] = ""
    }
}
$titlesWrap = @{ byFile = $byFileExport }
$titlesJson = $titlesWrap | ConvertTo-Json -Depth 10 -Compress
[System.IO.File]::WriteAllText($titlesPath, $titlesJson, [System.Text.UTF8Encoding]::new($false))
Write-Host "OK: titles -> $titlesPath"
