# Сборка данных, запуск локального сервера и открытие игры в браузере.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
& "$root\build-game-data.ps1"
if (Test-Path -LiteralPath (Join-Path $root "build-book-manifest.ps1")) {
    & "$root\build-book-manifest.ps1"
}
$entryPage = "index.html"
$preferredPort = 5500

function Assert-FiveGameSeries {
    $dataPath = Join-Path $root "game-data.js"
    if (-not (Test-Path -LiteralPath $dataPath)) {
        throw "Не найден game-data.js. Запустите build-game-data.ps1."
    }
    $js = [System.IO.File]::ReadAllText($dataPath, [System.Text.UTF8Encoding]::new($false))
    $m = [regex]::Match($js, 'window\.GAME_LEVELS\s*=\s*(\[.*\]);?\s*$', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $m.Success) {
        throw "Не удалось прочитать список раскладок из game-data.js."
    }
    $levels = $m.Groups[1].Value | ConvertFrom-Json
    $count = 0
    if ($null -ne $levels) {
        $count = @($levels).Count
    }
    if ($count -lt 5) {
        throw "Нужно 5 раскладок, сейчас найдено $count. Проверьте, что в pics есть пять папок, и в каждой 1.png .. 8.png."
    }
    Write-Host "OK: найдено $count раскладок."
}

Assert-FiveGameSeries

function Get-PythonCommand {
    $cmds = @(
        @{ File = "python"; Args = @() },
        @{ File = "python3"; Args = @() },
        @{ File = "py"; Args = @("-3") }
    )
    foreach ($cmd in $cmds) {
        if (-not (Get-Command $cmd.File -ErrorAction SilentlyContinue)) {
            continue
        }
        try {
            $versionArgs = @($cmd.Args) + @("--version")
            $p = Start-Process -FilePath $cmd.File -ArgumentList $versionArgs -NoNewWindow -Wait -PassThru
            if ($p.ExitCode -eq 0 -or $null -eq $p.ExitCode) {
                return $cmd
            }
        } catch {
        }
    }
    throw "Python не найден. Установите Python для Windows и повторите запуск."
}

function Test-PortFree([int]$port) {
    $listener = $null
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse("127.0.0.1"), $port)
        $listener.Start()
        return $true
    } catch {
        return $false
    } finally {
        if ($listener) {
            $listener.Stop()
        }
    }
}

function Get-FreePort([int]$startPort) {
    for ($port = $startPort; $port -lt ($startPort + 50); $port++) {
        if (Test-PortFree $port) {
            return $port
        }
    }
    throw "Не найден свободный порт начиная с $startPort."
}

function Wait-Server([string]$url) {
    for ($i = 0; $i -lt 40; $i++) {
        try {
            $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 1
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) {
                return
            }
        } catch {
            Start-Sleep -Milliseconds 250
        }
    }
    throw "Сервер запущен, но не ответил: $url"
}

function Start-ProjectServer([int]$port) {
    $python = Get-PythonCommand
    $args = @($python.Args) + @("-m", "http.server", [string]$port, "--bind", "127.0.0.1")
    Start-Process -FilePath $python.File -ArgumentList $args -WorkingDirectory $root | Out-Null
}

function Open-UrlInBrowser([string]$url) {
    $exePaths = @(
        (Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application\msedge.exe"),
        (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe"),
        (Join-Path $env:LocalAppData "Google\Chrome\Application\chrome.exe")
    )
    foreach ($exe in $exePaths) {
        if ($exe -and (Test-Path -LiteralPath $exe)) {
            Start-Process -FilePath $exe -ArgumentList @($url)
            return
        }
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $url
    $psi.UseShellExecute = $true
    [void][System.Diagnostics.Process]::Start($psi)
}

$port = Get-FreePort $preferredPort
$url = "http://127.0.0.1:$port/$entryPage"
Start-ProjectServer $port
Wait-Server $url
Write-Host "OK: local server -> $url"
Open-UrlInBrowser $url
