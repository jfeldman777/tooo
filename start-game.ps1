# Сборка данных и открытие игры в браузере.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
& "$root\build-game-data.ps1"
if (Test-Path -LiteralPath (Join-Path $root "build-book-manifest.ps1")) {
    & "$root\build-book-manifest.ps1"
}
$entryPage = Join-Path $root "index.html"

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

Open-HtmlInBrowser $entryPage
