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
    public const int WM_HOTKEY = 0x0312;
    public const int WM_INPUTLANGCHANGEREQUEST = 0x0050;
    public const int HOTKEY_ID_PAUSE = 1001;
    public const uint KLF_ACTIVATE = 0x00000001;
    public const uint VK_PAUSE = 0x13;

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr processId);

    [DllImport("user32.dll")]
    public static extern IntPtr GetKeyboardLayout(uint idThread);

    [DllImport("user32.dll")]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("user32.dll")]
    public static extern IntPtr LoadKeyboardLayout(string pwszKLID, uint flags);

    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    public static string GetActiveLayoutId() {
        IntPtr hwnd = GetForegroundWindow();
        uint threadId = GetWindowThreadProcessId(hwnd, IntPtr.Zero);
        long hkl = GetKeyboardLayout(threadId).ToInt64() & 0xffffffff;
        return hkl.ToString("X8");
    }

    public static void ToggleRussianLayoutOnly() {
        string current = GetActiveLayoutId();
        string target = null;
        if (current == "00020419") {
            target = "00000419";
        } else if (current == "00000419") {
            target = "00020419";
        }
        if (target == null) {
            return;
        }
        IntPtr targetHkl = LoadKeyboardLayout(target, KLF_ACTIVATE);
        IntPtr hwnd = GetForegroundWindow();
        if (hwnd != IntPtr.Zero && targetHkl != IntPtr.Zero) {
            PostMessage(hwnd, WM_INPUTLANGCHANGEREQUEST, IntPtr.Zero, targetHkl);
        }
    }
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

    protected override void OnHandleCreated(EventArgs e) {
        base.OnHandleCreated(e);
        KeyboardStateNative.RegisterHotKey(this.Handle, KeyboardStateNative.HOTKEY_ID_PAUSE, 0, KeyboardStateNative.VK_PAUSE);
    }

    protected override void OnHandleDestroyed(EventArgs e) {
        KeyboardStateNative.UnregisterHotKey(this.Handle, KeyboardStateNative.HOTKEY_ID_PAUSE);
        base.OnHandleDestroyed(e);
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == KeyboardStateNative.WM_HOTKEY && m.WParam.ToInt32() == KeyboardStateNative.HOTKEY_ID_PAUSE) {
            KeyboardStateNative.ToggleRussianLayoutOnly();
            return;
        }
        base.WndProc(ref m);
    }
}
"@

function Get-ActiveKeyboardLayoutId {
    try {
        return [KeyboardStateNative]::GetActiveLayoutId()
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
$form.Text = "Keyboard state - Pause toggles RU only"
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
