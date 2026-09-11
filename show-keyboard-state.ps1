# Windows-only live keyboard layout indicator.
# It shows the active foreground-window layout without typing test letters.
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies @("System.Windows.Forms", "System.Drawing") -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class KeyboardStateNative {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr processId);

    [DllImport("user32.dll")]
    public static extern IntPtr GetKeyboardLayout(uint idThread);
}

public class NoActivateKeyboardForm : Form {
    protected override bool ShowWithoutActivation {
        get { return true; }
    }

    protected override CreateParams CreateParams {
        get {
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= 0x08000000; // WS_EX_NOACTIVATE
            return cp;
        }
    }
}
"@

function Get-ActiveKeyboardLayoutId {
    try {
        $hwnd = [KeyboardStateNative]::GetForegroundWindow()
        $threadId = [KeyboardStateNative]::GetWindowThreadProcessId($hwnd, [IntPtr]::Zero)
        $hkl = [KeyboardStateNative]::GetKeyboardLayout($threadId).ToInt64() -band 0xffffffff
        return ("{0:x8}" -f $hkl).ToUpperInvariant()
    } catch {
        return "UNKNOWN"
    }
}

function Get-LayoutInfo([string]$layoutId) {
    switch ($layoutId.ToUpperInvariant()) {
        "00000409" {
            return [pscustomobject]@{
                Title = "EN"
                Detail = "US"
                Back = [System.Drawing.Color]::FromArgb(35, 92, 170)
                Fore = [System.Drawing.Color]::White
            }
        }
        "00020419" {
            return [pscustomobject]@{
                Title = "RU"
                Detail = "KLAVIA"
                Back = [System.Drawing.Color]::FromArgb(20, 135, 72)
                Fore = [System.Drawing.Color]::White
            }
        }
        "00000419" {
            return [pscustomobject]@{
                Title = "RU"
                Detail = "STANDARD"
                Back = [System.Drawing.Color]::FromArgb(180, 122, 20)
                Fore = [System.Drawing.Color]::White
            }
        }
        "0002040D" {
            return [pscustomobject]@{
                Title = "HE"
                Detail = "STANDARD"
                Back = [System.Drawing.Color]::FromArgb(99, 73, 168)
                Fore = [System.Drawing.Color]::White
            }
        }
        "0000040D" {
            return [pscustomobject]@{
                Title = "HE"
                Detail = "LEGACY"
                Back = [System.Drawing.Color]::FromArgb(180, 40, 40)
                Fore = [System.Drawing.Color]::White
            }
        }
        "0003040D" {
            return [pscustomobject]@{
                Title = "HE"
                Detail = "2018"
                Back = [System.Drawing.Color]::FromArgb(180, 40, 40)
                Fore = [System.Drawing.Color]::White
            }
        }
        default {
            return [pscustomobject]@{
                Title = "??"
                Detail = $layoutId
                Back = [System.Drawing.Color]::FromArgb(55, 55, 55)
                Fore = [System.Drawing.Color]::White
            }
        }
    }
}

$form = [NoActivateKeyboardForm]::new()
$form.Text = "Keyboard state"
$form.TopMost = $true
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedToolWindow
$form.ShowInTaskbar = $true
$form.Width = 190
$form.Height = 92
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = [System.Drawing.Point]::new($screen.Right - $form.Width - 18, $screen.Bottom - $form.Height - 18)

$label = [System.Windows.Forms.Label]::new()
$label.Dock = [System.Windows.Forms.DockStyle]::Fill
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$label.Font = [System.Drawing.Font]::new("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)

function Update-KeyboardBadge {
    $layoutId = Get-ActiveKeyboardLayoutId
    $info = Get-LayoutInfo $layoutId
    $form.BackColor = $info.Back
    $label.BackColor = $info.Back
    $label.ForeColor = $info.Fore
    $label.Text = $info.Title + "`r`n" + $info.Detail
    $form.Text = "Keyboard state - " + $layoutId
}

$timer = [System.Windows.Forms.Timer]::new()
$timer.Interval = 250
$timer.Add_Tick({ Update-KeyboardBadge })

Update-KeyboardBadge
$timer.Start()
[System.Windows.Forms.Application]::Run($form)
