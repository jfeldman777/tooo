# Windows-only keyboard state check. It does not change settings.
$ErrorActionPreference = "Stop"

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

$report = Join-Path $PSScriptRoot "keyboard-check-report.txt"
$lines = New-Object System.Collections.Generic.List[string]
[void]$lines.Add("Windows keyboard check report")
[void]$lines.Add(("Generated: " + (Get-Date).ToString("s")))
[void]$lines.Add("")
[void]$lines.Add("WinUserLanguageList:")
foreach ($language in (Get-WinUserLanguageList)) {
    [void]$lines.Add(("  " + $language.LanguageTag))
    foreach ($tip in $language.InputMethodTips) {
        [void]$lines.Add(("    " + $tip + " (" + (Get-KeyboardLayoutName ($tip.Split(":")[-1])) + ")"))
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
        [void]$lines.Add(("  " + $prop.Name + " = " + $prop.Value + " (" + (Get-KeyboardLayoutName $prop.Value) + ")"))
    }
}
[void]$lines.Add("")
$activeLayout = Get-ActiveKeyboardLayoutId
[void]$lines.Add(("Active foreground layout: " + $activeLayout + " (" + (Get-KeyboardLayoutName $activeLayout) + ")"))

[System.IO.File]::WriteAllLines($report, $lines, [System.Text.UTF8Encoding]::new($false))
Write-Host "Отчёт: $report"
