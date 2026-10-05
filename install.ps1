param(
    [string]$DestinationHome
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
$isWindowsPlatform = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
if (-not $isWindowsPlatform) {
    Write-Warning 'This installer targets native Windows. Only configuration copying will run on this platform.'
}
if (-not $DestinationHome) {
    $DestinationHome = [Environment]::GetFolderPath('UserProfile')
}
if (-not $DestinationHome) { throw 'Specify -DestinationHome when the user profile directory is unavailable.' }
$destinationRoot = [IO.Path]::GetFullPath($DestinationHome)
$claudeRoot = Join-Path $destinationRoot '.claude'
$codexRoot = Join-Path $destinationRoot '.codex'
if ($env:CLAUDE_CONFIG_DIR) { $claudeRoot = [IO.Path]::GetFullPath($env:CLAUDE_CONFIG_DIR) }
if ($env:CODEX_HOME) { $codexRoot = [IO.Path]::GetFullPath($env:CODEX_HOME) }

function Get-ExistingItem([string]$Path) {
    Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}

# Record intended content even when an install is a no-op.
$managedFiles = @{}
$preservedFiles = @{}
$linkTargets = @{}

function Get-ItemSignature([string]$Path, [bool]$IncludeTime = $false) {
    $item = Get-ExistingItem $Path
    if (-not $item) { return 'missing' }
    $time = if ($IncludeTime) { ':' + $item.LastWriteTimeUtc.Ticks } else { '' }
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        return 'link:' + ($item.Target -join '|') + $time
    }
    if (-not $item.PSIsContainer) {
        return 'file:' + (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash + $time
    }
    $children = @(Get-ChildItem -LiteralPath $Path -Force | Sort-Object Name | ForEach-Object {
        $_.Name + '=' + (Get-ItemSignature $_.FullName $IncludeTime)
    })
    return 'directory:' + ($children -join "`n") + $time
}

function Preserve-Existing([string]$Path) {
    if (Get-ExistingItem $Path) { $preservedFiles[$Path] = Get-ItemSignature $Path }
}

function Remember-LinkTarget([string]$Path) {
    $item = Get-ExistingItem $Path
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        foreach ($target in @($item.Target)) {
            if (-not $target) { continue }
            if (-not [IO.Path]::IsPathRooted($target)) {
                $target = Join-Path (Split-Path -Parent $Path) $target
            }
            $targetPath = [IO.Path]::GetFullPath($target)
            if (Get-ExistingItem $targetPath) {
                $linkTargets[$targetPath] = Get-ItemSignature $targetPath
            }
        }
    }
}

function Backup-Item([string]$Path) {
    $backup = "$Path.bak"
    $index = 1
    while (Get-ExistingItem $backup) {
        $backup = "$Path.bak.$index"
        $index++
    }
    Remember-LinkTarget $Path
    $signature = Get-ItemSignature $Path $true
    # Rename the entry itself, including junctions/symlinks; never modify its target.
    Move-Item -LiteralPath $Path -Destination $backup
    if ((Get-ItemSignature $backup $true) -cne $signature) {
        throw "Backup verification failed: $backup"
    }
    Write-Host "Backed up: $Path -> $backup"
    return $backup
}

function Ensure-Directory([string]$Path) {
    $item = Get-ExistingItem $Path
    if ($item -and $item.PSIsContainer -and -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return }
    $parent = Split-Path -Parent $Path
    if ($parent -and $parent -ne $Path) { Ensure-Directory $parent }
    if ($item) {
        $backup = Backup-Item $Path
        [IO.Directory]::CreateDirectory($Path) | Out-Null
        if ($item.PSIsContainer) {
            # Keep local/user files when replacing an existing directory link.
            Get-ChildItem -LiteralPath $backup -Force | ForEach-Object {
                Copy-Item -LiteralPath $_.FullName -Destination $Path -Recurse -Force
            }
        }
    } else {
        [IO.Directory]::CreateDirectory($Path) | Out-Null
    }
}

function Install-Bytes([byte[]]$Bytes, [string]$Destination) {
    $managedFiles[$Destination] = [Convert]::ToBase64String($Bytes)
    Ensure-Directory (Split-Path -Parent $Destination)
    $item = Get-ExistingItem $Destination
    if ($item) {
        $isLink = $item.Attributes -band [IO.FileAttributes]::ReparsePoint
        if (-not $item.PSIsContainer -and -not $isLink) {
            $existing = [IO.File]::ReadAllBytes($Destination)
            if ([Convert]::ToBase64String($existing) -ceq [Convert]::ToBase64String($Bytes)) { return }
        }
        $null = Backup-Item $Destination
    }
    [IO.File]::WriteAllBytes($Destination, $Bytes)
    Write-Host "Copied: $Destination"
}

function Install-File([string]$Source, [string]$Destination) {
    Install-Bytes ([IO.File]::ReadAllBytes($Source)) $Destination
}

function Install-Tree([string]$Source, [string]$Destination) {
    $sourceFiles = @(Get-ChildItem -LiteralPath $Source -File -Recurse -Force)
    $managedRelativePaths = @{}
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($Source.Length).TrimStart([char[]]@('/', '\'))
        $managedRelativePaths[$relative] = $true
    }
    # Snapshot only this managed tree, including files visible through a linked root.
    if (Test-Path -LiteralPath $Destination -PathType Container) {
        Get-ChildItem -LiteralPath $Destination -File -Recurse -Force | ForEach-Object {
            $relative = $_.FullName.Substring($Destination.Length).TrimStart([char[]]@('/', '\'))
            if (-not $managedRelativePaths.ContainsKey($relative)) { Preserve-Existing $_.FullName }
        }
    }
    Ensure-Directory $Destination
    $sourceFiles | ForEach-Object {
        $relative = $_.FullName.Substring($Source.Length).TrimStart([char[]]@('/', '\'))
        Install-File $_.FullName (Join-Path $Destination $relative)
    }
}

function Initialize-LocalRules([string]$Root) {
    Ensure-Directory $Root
    $localRules = Join-Path $Root 'AGENTS.local.md'
    if (Get-ExistingItem $localRules) { return }
    $source = Join-Path $repoRoot 'claude/AGENTS.local.md'
    if (Test-Path -LiteralPath $source -PathType Leaf) {
        Install-File $source $localRules
    } else {
        Install-Bytes ([Text.UTF8Encoding]::new($false).GetBytes('# Machine-local rules. This file is not managed by the repository.' + "`n")) $localRules
    }
}

function Find-GitBash {
    if (-not $isWindowsPlatform) { return $null }
    $candidates = @()
    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA)) {
        if ($base) {
            $candidates += Join-Path $base 'Git/bin/bash.exe'
            $candidates += Join-Path $base 'Programs/Git/bin/bash.exe'
        }
    }
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($git) {
        $gitDirectory = Split-Path -Parent $git.Source
        $candidates += Join-Path (Split-Path -Parent $gitDirectory) 'bin/bash.exe'
    }
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        $bashPath = (Resolve-Path -LiteralPath $candidate).Path
        & $bashPath --noprofile --norc -c 'command -v jq >/dev/null 2>&1 && jq --version >/dev/null 2>&1'
        if ($LASTEXITCODE -eq 0) { return $bashPath }
    }
    return $null
}

function ConvertTo-BashQuotedLiteral([string]$Value) {
    # End the single-quoted string, emit one quoted apostrophe, then resume it.
    $escapedQuote = "'" + '"' + "'" + '"' + "'"
    return "'" + $Value.Replace("'", $escapedQuote) + "'"
}

foreach ($path in @(
    (Join-Path $destinationRoot '.gitconfig.local'),
    (Join-Path $claudeRoot 'AGENTS.local.md'),
    (Join-Path $claudeRoot 'settings.local.json'),
    (Join-Path $codexRoot 'AGENTS.local.md'),
    (Join-Path $codexRoot 'config.toml')
)) { Preserve-Existing $path }

Ensure-Directory $destinationRoot
foreach ($name in @('.gitconfig', '.gitignore_global')) {
    Install-File (Join-Path $repoRoot $name) (Join-Path $destinationRoot $name)
}
foreach ($name in @('CLAUDE.md', 'AGENTS.md', 'codex-rescue.md', 'model-delegate.md', 'statusline-command.sh')) {
    Install-File (Join-Path $repoRoot "claude/$name") (Join-Path $claudeRoot $name)
}
Install-Tree (Join-Path $repoRoot 'claude/skills/reload-rules') (Join-Path $claudeRoot 'skills/reload-rules')
Install-Tree (Join-Path $repoRoot 'claude/skills/kuromoka-writing') (Join-Path $claudeRoot 'skills/kuromoka-writing')
Install-File (Join-Path $repoRoot 'claude/AGENTS.md') (Join-Path $codexRoot 'AGENTS.md')
Install-Tree (Join-Path $repoRoot 'claude/skills/kuromoka-writing') (Join-Path $codexRoot 'skills/kuromoka-writing')
Get-ChildItem -LiteralPath (Join-Path $repoRoot 'codex/agents') -Filter '*.toml' -File | ForEach-Object {
    Install-File $_.FullName (Join-Path $codexRoot "agents/$($_.Name)")
}
Initialize-LocalRules $claudeRoot
Initialize-LocalRules $codexRoot

$settings = Get-Content -LiteralPath (Join-Path $repoRoot 'claude/settings.json') -Raw | ConvertFrom-Json
if ($settings.hooks -and $settings.hooks.SessionStart) {
    foreach ($group in $settings.hooks.SessionStart) {
        $group.hooks = @($group.hooks | Where-Object { $_.command -notmatch 'herdr-agent-state\.sh' })
    }
    $settings.hooks.SessionStart = @($settings.hooks.SessionStart | Where-Object { $_.hooks.Count -gt 0 })
    if ($settings.hooks.SessionStart.Count -eq 0) { $settings.hooks.PSObject.Properties.Remove('SessionStart') }
    if (@($settings.hooks.PSObject.Properties).Count -eq 0) { $settings.PSObject.Properties.Remove('hooks') }
}
$bash = Find-GitBash
$statusScript = (Join-Path $claudeRoot 'statusline-command.sh').Replace('\', '/')
# Claude Code executes statusLine commands through Git Bash on Windows.
if ($bash) {
    $settings.statusLine.command = (ConvertTo-BashQuotedLiteral $bash.Replace('\', '/')) + ' ' + (ConvertTo-BashQuotedLiteral $statusScript)
} else {
    $settings.PSObject.Properties.Remove('statusLine')
    Write-Warning 'Claude statusLine is disabled: Git for Windows Bash and jq must be available. Install jq, then rerun this installer to enable it.'
}
$settingsJson = ($settings | ConvertTo-Json -Depth 100) + "`n"
Install-Bytes ([Text.UTF8Encoding]::new($false).GetBytes($settingsJson)) (Join-Path $claudeRoot 'settings.json')

function Verify-Installation {
    foreach ($path in $managedFiles.Keys) {
        $item = Get-ExistingItem $path
        if (-not $item -or $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Managed destination is not an ordinary file: $path"
        }
        if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) -cne $managedFiles[$path]) {
            throw "Installed content differs: $path"
        }
    }
    foreach ($path in $preservedFiles.Keys) {
        if ((Get-ItemSignature $path) -cne $preservedFiles[$path]) {
            throw "Existing local or unmanaged file changed: $path"
        }
    }
    foreach ($path in $linkTargets.Keys) {
        if ((Get-ItemSignature $path) -cne $linkTargets[$path]) {
            throw "Existing link target changed: $path"
        }
    }
    $installedSettings = Get-Content -LiteralPath (Join-Path $claudeRoot 'settings.json') -Raw | ConvertFrom-Json
    if (($installedSettings | ConvertTo-Json -Depth 100) -match 'herdr-agent-state\.sh') {
        throw 'Installed settings still contain a Herdr hook.'
    }
    if ($bash) {
        $expectedCommand = (ConvertTo-BashQuotedLiteral $bash.Replace('\', '/')) + ' ' + (ConvertTo-BashQuotedLiteral $statusScript)
        if (-not (Test-Path -LiteralPath $bash -PathType Leaf) -or $installedSettings.statusLine.command -cne $expectedCommand) {
            throw 'Installed statusLine does not match the available Bash dependency.'
        }
    } elseif ($installedSettings.PSObject.Properties['statusLine']) {
        throw 'Installed statusLine is enabled without the required dependencies.'
    }
}

Verify-Installation
Write-Host 'Installation verification completed.'

Write-Host 'Git for Windows, Claude Code and Codex must be installed separately. No software was installed.'
Write-Host 'natural-japanese is not installed by this Windows installer; install it separately if needed.'
if (-not (Test-Path -LiteralPath (Join-Path $destinationRoot '.gitconfig.local'))) {
    Write-Host 'Create ~/.gitconfig.local yourself to configure Git name/email. Existing identity settings were not edited.'
}
Write-Host 'Done. Rerun this installer after changing repository settings; Windows uses copies.'
