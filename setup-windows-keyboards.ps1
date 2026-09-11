# Windows-only one-click setup for the project's input languages.
# It configures one global input layout state for all app windows.
$ErrorActionPreference = "Stop"

$EnUsTip = "0409:00000409"
$RuStandardTip = "0419:00000419"
$RuMnemonicTip = "0419:00020419"
$DefaultInputTip = $RuMnemonicTip
$HebrewStandardTip = "040D:0002040D"
$LegacyHebrewLayoutIds = @("0000040D", "0003040D")

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

function Set-DefaultUserPreloadRegistry([string[]]$layoutIds) {
    $preloadPath = "Registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Preload"
    if (-not (Test-Path -LiteralPath $preloadPath)) {
        return
    }
    try {
        $props = Get-ItemProperty -Path $preloadPath
        foreach ($prop in $props.PSObject.Properties) {
            if ($prop.Name -match '^\d+$') {
                Remove-ItemProperty -Path $preloadPath -Name $prop.Name -ErrorAction SilentlyContinue
            }
        }
        for ($i = 0; $i -lt $layoutIds.Count; $i++) {
            New-ItemProperty -Path $preloadPath -Name ([string]($i + 1)) -Value $layoutIds[$i] -PropertyType String -Force | Out-Null
        }
    } catch {
        Write-Warning "Не удалось обновить .DEFAULT preload без прав администратора: $($_.Exception.Message)"
    }
}

function Remove-LegacyHebrewRegistryLayouts {
    $paths = @(
        "HKCU:\Keyboard Layout\Preload",
        "HKCU:\Keyboard Layout\Substitutes"
    )
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }
        $props = Get-ItemProperty -Path $path
        foreach ($prop in $props.PSObject.Properties) {
            $value = [string]$prop.Value
            if ($LegacyHebrewLayoutIds -contains $prop.Name -or $LegacyHebrewLayoutIds -contains $value) {
                Remove-ItemProperty -Path $path -Name $prop.Name -ErrorAction SilentlyContinue
            }
        }
    }
}

function Disable-PerWindowInputMethod {
    $desktopPath = "HKCU:\Control Panel\Desktop"
    try {
        $prefMask = (Get-ItemProperty -Path $desktopPath -Name "UserPreferencesMask" -ErrorAction Stop).UserPreferencesMask
        if ($prefMask -and $prefMask.Length -gt 4) {
            # Bit 0x80 in byte 4 enables "different input method for each app window".
            $prefMask[4] = $prefMask[4] -band 0x7F
            New-ItemProperty -Path $desktopPath -Name "UserPreferencesMask" -Value $prefMask -PropertyType Binary -Force | Out-Null
        }
    } catch {
        Write-Warning "Не удалось выключить раскладки по окнам через UserPreferencesMask: $($_.Exception.Message)"
    }
}

function New-ExactLanguageList {
    $languageList = New-WinUserLanguageList "en-US"
    [void]$languageList.Add("ru-RU")
    [void]$languageList.Add("he-IL")

    Set-InputMethods (Get-Language $languageList "en-US") @($EnUsTip)
    Set-InputMethods (Get-Language $languageList "ru-RU") @($RuMnemonicTip, $RuStandardTip)
    Set-InputMethods (Get-Language $languageList "he-IL") @($HebrewStandardTip)

    return $languageList
}

function Restart-InputSwitcher {
    foreach ($name in @("TextInputHost", "ctfmon")) {
        Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    $ctfmon = Join-Path $env:WINDIR "System32\ctfmon.exe"
    if (Test-Path -LiteralPath $ctfmon) {
        Start-Process -FilePath $ctfmon | Out-Null
    }
}

function Get-ActiveKeyboardLayoutId {
    try {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class KeyboardLayoutState {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr processId);

    [DllImport("user32.dll")]
    public static extern IntPtr GetKeyboardLayout(uint idThread);
}
"@
        $hwnd = [KeyboardLayoutState]::GetForegroundWindow()
        $threadId = [KeyboardLayoutState]::GetWindowThreadProcessId($hwnd, [IntPtr]::Zero)
        $hkl = [KeyboardLayoutState]::GetKeyboardLayout($threadId).ToInt64() -band 0xffffffff
        return ("{0:x8}" -f $hkl).ToUpperInvariant()
    } catch {
        return "unknown"
    }
}

function Get-KeyboardLayoutName([string]$layoutId) {
    switch ($layoutId.ToUpperInvariant()) {
        "00000409" { return "EN US" }
        "00000419" { return "RU Russian" }
        "00020419" { return "RU Russian - Mnemonic" }
        "0002040D" { return "HE Hebrew (Standard)" }
        "0000040D" { return "HE Hebrew legacy (should be removed)" }
        "0003040D" { return "HE Hebrew Standard 2018 (should be removed)" }
        default { return "unknown" }
    }
}

function Write-KeyboardReport {
    $report = Join-Path $PSScriptRoot "keyboard-setup-report.txt"
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add("Windows keyboard setup report")
    [void]$lines.Add(("Generated: " + (Get-Date).ToString("s")))
    [void]$lines.Add("")
    [void]$lines.Add("WinUserLanguageList:")
    foreach ($language in (Get-WinUserLanguageList)) {
        [void]$lines.Add(("  " + $language.LanguageTag))
        foreach ($tip in $language.InputMethodTips) {
            [void]$lines.Add(("    " + $tip))
        }
    }
    [void]$lines.Add("")
    [void]$lines.Add("HKCU Keyboard Layout Preload:")
    $preloadPath = "HKCU:\Keyboard Layout\Preload"
    if (Test-Path -LiteralPath $preloadPath) {
        $props = Get-ItemProperty -Path $preloadPath
        $numericProps = $props.PSObject.Properties |
            Where-Object { $_.Name -match '^\d+$' } |
            Sort-Object { [int]$_.Name }
        foreach ($prop in $numericProps) {
            [void]$lines.Add(("  " + $prop.Name + " = " + $prop.Value))
        }
    }
    [void]$lines.Add("")
    $activeLayout = Get-ActiveKeyboardLayoutId
    [void]$lines.Add(("Active foreground layout: " + $activeLayout + " (" + (Get-KeyboardLayoutName $activeLayout) + ")"))
    [System.IO.File]::WriteAllLines($report, $lines, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Отчёт: $report"
}

Write-Host "Настройка клавиатур Windows для текущего пользователя..."

$list = New-ExactLanguageList
Set-WinUserLanguageList $list -Force
Start-Sleep -Milliseconds 500

# Re-apply after Windows materializes language defaults; this removes auto-added Hebrew legacy layouts.
$list = New-ExactLanguageList
Set-WinUserLanguageList $list -Force

# Keep the legacy Windows layout preload list exact too: one EN, RU mnemonic, RU standard, one Hebrew Standard.
Set-KeyboardPreloadRegistry @("00000409", "00020419", "00000419", "0002040D")
Set-DefaultUserPreloadRegistry @("00000409", "00020419", "00000419", "0002040D")
Remove-LegacyHebrewRegistryLayouts

# RU mnemonic ("клавиа") is the default input after setup; Ctrl+Shift switches RU mnemonic <-> RU standard.
Set-WinDefaultInputMethodOverride -InputTip $DefaultInputTip

# Make input layout global instead of separate per app window.
try {
    Set-WinLanguageBarOption
} catch {
    Write-Warning "Не удалось вызвать Set-WinLanguageBarOption: $($_.Exception.Message)"
}
Disable-PerWindowInputMethod

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

Restart-InputSwitcher
Start-Sleep -Milliseconds 500
Write-KeyboardReport

Write-Host ""
Write-Host "Готово."
Write-Host "Языки: EN US, RU, HE."
Write-Host "RU-клавиатуры: Russian - Mnemonic и Russian."
Write-Host "Hebrew: один пункт, только Hebrew (Standard)."
Write-Host "По умолчанию: RU Russian - Mnemonic."
Write-Host ""
Write-Host "Переключение языка: Win+Space или Alt+Shift."
Write-Host "Когда выбран RU, переключение Russian - Mnemonic <-> Russian: Ctrl+Shift."
Write-Host "Если список не обновился сразу, выйдите из Windows и войдите снова."
