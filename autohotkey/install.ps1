param(
    [string]$AutoHotkeyPath
)

$ErrorActionPreference = 'Stop'

$scriptPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'realforce-ime.ahk')).Path

if ($AutoHotkeyPath) {
    if (-not (Test-Path -LiteralPath $AutoHotkeyPath -PathType Leaf)) {
        throw "AutoHotkey executable was not found: $AutoHotkeyPath"
    }
    $ahkPath = (Resolve-Path -LiteralPath $AutoHotkeyPath).Path
} else {
    $candidatePaths = @(
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey.exe')
    )
    $ahkPath = $candidatePaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $ahkPath) {
        throw 'AutoHotkey v2 was not found. Install it or rerun with -AutoHotkeyPath <path-to-AutoHotkey.exe>.'
    }
    $ahkPath = (Resolve-Path -LiteralPath $ahkPath).Path
}

$startupDirectory = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startupDirectory 'REALFORCE IME.lnk'
$shell = New-Object -ComObject WScript.Shell

if (Test-Path -LiteralPath $shortcutPath) {
    $existingShortcut = $shell.CreateShortcut($shortcutPath)
    $isThisShortcut = $existingShortcut.TargetPath -eq $ahkPath -and $existingShortcut.Arguments -eq ('"' + $scriptPath + '"')
    if (-not $isThisShortcut) {
        $backupPath = Join-Path $startupDirectory ('REALFORCE IME.backup-{0:yyyyMMddHHmmss}.lnk.bak' -f (Get-Date))
        Move-Item -LiteralPath $shortcutPath -Destination $backupPath
        Write-Host "Backed up existing shortcut: $backupPath"
    }
}

$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $ahkPath
$shortcut.Arguments = '"' + $scriptPath + '"'
$shortcut.WorkingDirectory = Split-Path -Parent $scriptPath
$shortcut.Save()

Write-Host "Created startup shortcut: $shortcutPath"
