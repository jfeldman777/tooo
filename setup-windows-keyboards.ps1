# Windows-only one-click setup for the project's input languages.
# It configures one global input layout state for all app windows.
$ErrorActionPreference = "Stop"

function Set-InputMethods($language, [string[]]$tips) {
    $language.InputMethodTips.Clear()
    foreach ($tip in $tips) {
        [void]$language.InputMethodTips.Add($tip)
    }
}

function Get-Language($list, [string]$tag) {
    foreach ($language in $list) {
        if ($language.LanguageTag -eq $tag) {
            return $language
        }
    }
    return $null
}

function Set-KeyboardPreloadRegistry([string[]]$layoutIds) {
    $preloadPath = "HKCU:\Keyboard Layout\Preload"
    if (-not (Test-Path -LiteralPath $preloadPath)) {
        New-Item -Path $preloadPath -Force | Out-Null
    }

    $props = Get-ItemProperty -Path $preloadPath
    foreach ($prop in $props.PSObject.Properties) {
        if ($prop.Name -match '^\d+$') {
            Remove-ItemProperty -Path $preloadPath -Name $prop.Name -ErrorAction SilentlyContinue
        }
    }

    for ($i = 0; $i -lt $layoutIds.Count; $i++) {
        New-ItemProperty -Path $preloadPath -Name ([string]($i + 1)) -Value $layoutIds[$i] -PropertyType String -Force | Out-Null
    }
}

Write-Host "Настройка клавиатур Windows для текущего пользователя..."

$list = New-WinUserLanguageList "en-US"
[void]$list.Add("ru-RU")
[void]$list.Add("he-IL")

Set-InputMethods (Get-Language $list "en-US") @("0409:00000409")             # English - US
Set-InputMethods (Get-Language $list "ru-RU") @("0419:00000419", "0419:00020419") # Russian + Russian - Mnemonic
Set-InputMethods (Get-Language $list "he-IL") @("040D:0002040D")             # Hebrew (Standard)

Set-WinUserLanguageList $list -Force

# Keep the legacy Windows layout preload list exact too: one EN, two RU, one Hebrew Standard.
Set-KeyboardPreloadRegistry @("00000409", "00000419", "00020419", "0002040D")

# RU standard is the default input after setup; Ctrl+Shift switches RU standard <-> RU mnemonic.
Set-WinDefaultInputMethodOverride -InputTip "0419:00000419"

# Make input layout global instead of separate per app window.
try {
    Set-WinLanguageBarOption
} catch {
    Write-Warning "Не удалось вызвать Set-WinLanguageBarOption: $($_.Exception.Message)"
}

try {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class InputSettings {
    [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo(uint action, uint param, IntPtr value, uint flags);
}
"@
    [void][InputSettings]::SystemParametersInfo(0x104F, 0, [IntPtr]::Zero, 0x03)
} catch {
    Write-Warning "Не удалось закрепить общий ввод через Windows API: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "Готово."
Write-Host "Языки: EN US, RU, HE."
Write-Host "RU-клавиатуры: Russian и Russian - Mnemonic."
Write-Host "Hebrew: один пункт, только Hebrew (Standard)."
Write-Host ""
Write-Host "Переключение языка: Win+Space или Alt+Shift."
Write-Host "Когда выбран RU, переключение Russian <-> Russian - Mnemonic: Ctrl+Shift."
Write-Host "Если список не обновился сразу, выйдите из Windows и войдите снова."
