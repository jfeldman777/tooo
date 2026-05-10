# Generates gallery.html in this folder from image files, then opens it.
$ErrorActionPreference = "Stop"
$root = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

function Escape-Html([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return "" }
    $text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;")
}

$leaf = Split-Path -Leaf ($root.TrimEnd('\', '/'))
$extensions = @(".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".svg")
$files = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
    Sort-Object FullName

$htmlHeader = @"
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Галерея — $(Escape-Html $leaf)</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; font-family: system-ui, Segoe UI, sans-serif; background: #111; color: #e8e8e8; padding: 1.25rem; }
    h1 { font-size: 1.1rem; font-weight: 600; margin: 0 0 1rem; color: #fff; }
    .meta { font-size: 0.85rem; color: #888; margin-bottom: 1.25rem; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px; }
    figure {
      margin: 0;
      background: #1c1c1c;
      border-radius: 8px;
      overflow: hidden;
      border: 1px solid #2a2a2a;
    }
    figure img {
      width: 100%;
      height: 180px;
      object-fit: contain;
      display: block;
      background: #0a0a0a;
    }
    figcaption {
      padding: 8px 10px;
      font-size: 12px;
      color: #aaa;
      word-break: break-all;
      line-height: 1.35;
    }
    figcaption span.path { color: #666; }
  </style>
</head>
<body>
  <h1>Изображения</h1>
  <p class="meta">Папка: $(Escape-Html $root) · Файлов: $($files.Count) · Обновите страницу после повторного запуска launch.bat.</p>
  <div class="grid">
"@

$htmlFooter = @"
  </div>
</body>
</html>
"@

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine($htmlHeader)

foreach ($f in $files) {
    $uri = [System.Uri]::new($f.FullName).AbsoluteUri
    $rel = $f.FullName.Substring($root.Length).TrimStart("\", "/") -replace "\\", "/"
    $nameEsc = Escape-Html $f.Name
    $relEsc = Escape-Html $rel
    [void]$sb.AppendLine("    <figure>")
    [void]$sb.AppendLine("      <img loading=`"lazy`" src=`"$uri`" alt=`"$nameEsc`" />")
    [void]$sb.AppendLine("      <figcaption><strong>$nameEsc</strong><br/><span class=`"path`">$relEsc</span></figcaption>")
    [void]$sb.AppendLine("    </figure>")
}

[void]$sb.AppendLine($htmlFooter)

$outPath = Join-Path $root "gallery.html"
[System.IO.File]::WriteAllText($outPath, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))

function Open-HtmlInBrowser([string]$htmlPath) {
    $exePaths = @(
        (Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application\msedge.exe"),
        (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe"),
        (Join-Path $env:LocalAppData "Google\Chrome\Application\chrome.exe")
    )
    foreach ($exe in $exePaths) {
        if ($exe -and (Test-Path -LiteralPath $exe)) {
            Start-Process -FilePath $exe -ArgumentList @((Resolve-Path -LiteralPath $htmlPath).Path)
            return
        }
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $htmlPath
    $psi.UseShellExecute = $true
    [void][System.Diagnostics.Process]::Start($psi)
}

Open-HtmlInBrowser $outPath
