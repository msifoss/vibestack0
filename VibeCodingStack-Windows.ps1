#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Installs or uninstalls the Vibe Coding Stack.

.DESCRIPTION
    This script manages:
    - Visual Studio Code
    - Git for Windows (Git Bash)
    - GitHub CLI (gh)
    - Python
    - Node.js (required for Claude Code)
    - Claude Code CLI
    - Everything (Void Tools)

.PARAMETER Uninstall
    Switch to uninstall mode. Without this flag, the script installs.

.PARAMETER SkipOptional
    Skip optional tools (Everything)

.PARAMETER WhatIf
    Preview mode - shows what would happen without making changes

.PARAMETER Force
    Skip confirmation prompts

.PARAMETER KeepPython
    (Uninstall only) Keep Python installed

.PARAMETER KeepNodeJS
    (Uninstall only) Keep Node.js and Claude Code installed

.PARAMETER KeepGit
    (Uninstall only) Keep Git installed

.PARAMETER LogPath
    Custom path for the audit log (default: script directory)

.EXAMPLE
    .\VibeCodingStack.ps1
    Installs the full stack with confirmation prompt.

.EXAMPLE
    .\VibeCodingStack.ps1 -Uninstall
    Uninstalls the full stack with confirmation prompt.

.EXAMPLE
    .\VibeCodingStack.ps1 -WhatIf
    Preview installation without making changes.

.EXAMPLE
    .\VibeCodingStack.ps1 -Uninstall -KeepGit -KeepPython
    Uninstall but keep Git and Python.

.NOTES
    Security Hardened Version
    - Uses only official winget source
    - Exact package matching to prevent substitution attacks
    - Full audit logging
    - Confirmation required before changes
    
    Requires: Administrator privileges, Windows 10/11
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Uninstall,
    [switch]$SkipOptional,
    [switch]$Force,
    [switch]$KeepPython,
    [switch]$KeepNodeJS,
    [switch]$KeepGit,
    [string]$LogPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ScriptVersion = "3.0.0-secure"
$ScriptDate = "2025-01-24"

#region Package Configuration

$AllowedPackages = @{
    "Microsoft.VisualStudioCode" = "Visual Studio Code"
    "Git.Git" = "Git for Windows"
    "GitHub.cli" = "GitHub CLI"
    "Python.Python.3.12" = "Python 3.12"
    "OpenJS.NodeJS.LTS" = "Node.js LTS"
    "voidtools.Everything" = "Everything Search"
    "voidtools.Everything.Cli" = "Everything CLI"
}

$CorePackages = @(
    @{ Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code"; KeepFlag = $false }
    @{ Id = "Git.Git"; Name = "Git for Windows"; KeepFlag = $KeepGit }
    @{ Id = "GitHub.cli"; Name = "GitHub CLI"; KeepFlag = $false }
    @{ Id = "Python.Python.3.12"; Name = "Python 3.12"; KeepFlag = $KeepPython }
    @{ Id = "OpenJS.NodeJS.LTS"; Name = "Node.js LTS"; KeepFlag = $KeepNodeJS }
)

$OptionalPackages = @(
    @{ Id = "voidtools.Everything"; Name = "Everything Search" }
    @{ Id = "voidtools.Everything.Cli"; Name = "Everything CLI" }
)

$ClaudeCodePackage = "@anthropic-ai/claude-code"

$EnvVarsToSet = @{
    "PYTHONUTF8" = "1"
}

$PathPatternsToClean = @(
    "*\Microsoft VS Code\*"
    "*\Git\*"
    "*\Python312*"
    "*\nodejs*"
    "*\npm*"
)

#endregion

#region Logging

function Start-AuditLog {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $mode = if ($Uninstall) { "Uninstall" } else { "Install" }
    
    if ($LogPath -eq "") { $LogPath = $PSScriptRoot }
    if (-not (Test-Path $LogPath)) { $LogPath = $env:TEMP }
    
    $script:LogFile = Join-Path $LogPath "VibeCodingStack_${mode}_${timestamp}.log"
    
    Start-Transcript -Path $script:LogFile -Append
    
    $color = if ($Uninstall) { "Blue" } else { "Cyan" }
    $modeText = if ($Uninstall) { "UNINSTALLER" } else { "INSTALLER" }
    
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor $color
    Write-Host "  VIBE CODING STACK $modeText (Security Hardened)" -ForegroundColor $color
    Write-Host "  Version: $ScriptVersion" -ForegroundColor $color
    Write-Host ("=" * 70) -ForegroundColor $color
    Write-Host ""
    
    Write-AuditEvent "START" "$mode initiated by $env:USERNAME on $env:COMPUTERNAME"
}

function Stop-AuditLog {
    Write-AuditEvent "END" "Operation completed"
    Stop-Transcript
    Write-Host ""
    Write-Host "Audit log: $script:LogFile" -ForegroundColor Gray
}

function Write-AuditEvent {
    param([string]$EventType, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$EventType] $Message" -ForegroundColor Gray
}

#endregion

#region Output Functions

function Write-Header {
    param([string]$Message)
    $color = if ($Uninstall) { "Blue" } else { "Magenta" }
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor $color
    Write-Host "  $Message" -ForegroundColor $color
    Write-Host ("=" * 60) -ForegroundColor $color
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
    Write-AuditEvent "STEP" $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
    Write-AuditEvent "SUCCESS" $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
    Write-AuditEvent "WARNING" $Message
}

function Write-Err {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
    Write-AuditEvent "ERROR" $Message
}

#endregion

#region Results Tracking

$Script:Results = @{
    Successful = @()
    Failed     = @()
    Skipped    = @()
    NotFound   = @()
}

#endregion

#region Helper Functions

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-PackageInstalled {
    param([string]$PackageId)
    $null = winget list --exact --id $PackageId --source winget 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Add-ToSystemPath {
    param([string]$PathToAdd)
    
    if (-not (Test-Path $PathToAdd)) { return $false }
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $pathArray = $currentPath -split ";" | Where-Object { $_ -ne "" }
    
    if ($pathArray -contains $PathToAdd) {
        Write-Step "Already in PATH: $PathToAdd"
        return $true
    }
    
    if ($PSCmdlet.ShouldProcess("System PATH", "Add $PathToAdd")) {
        $newPath = $currentPath + ";" + $PathToAdd
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        $env:Path = $PathToAdd + ";" + $env:Path
        Write-Success "Added to PATH: $PathToAdd"
        Write-AuditEvent "PATH_ADD" $PathToAdd
    }
    return $true
}

function Remove-FromSystemPath {
    param([string]$Pattern)
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $pathArray = @($currentPath -split ";" | Where-Object { $_ -ne "" })
    $matched = @($pathArray | Where-Object { $_ -like $Pattern })
    
    if ($matched.Count -eq 0) { return }
    
    foreach ($m in $matched) {
        if ($PSCmdlet.ShouldProcess("System PATH", "Remove $m")) {
            $pathArray = @($pathArray | Where-Object { $_ -ne $m })
            Write-Success "Removed from PATH: $m"
            Write-AuditEvent "PATH_REMOVE" $m
        }
    }
    
    if (-not $WhatIfPreference) {
        [Environment]::SetEnvironmentVariable("Path", ($pathArray -join ";"), "Machine")
    }
}

function Set-SystemEnvVar {
    param([string]$Name, [string]$Value)
    
    if ($PSCmdlet.ShouldProcess("$Name", "Set to $Value")) {
        [Environment]::SetEnvironmentVariable($Name, $Value, "Machine")
        Set-Item -Path "Env:$Name" -Value $Value
        Write-Success "Set $Name = $Value"
        Write-AuditEvent "ENV_SET" "$Name = $Value"
    }
}

function Remove-SystemEnvVar {
    param([string]$Name)
    
    $current = [Environment]::GetEnvironmentVariable($Name, "Machine")
    if ($null -eq $current) { return }
    
    if ($PSCmdlet.ShouldProcess("$Name", "Remove")) {
        [Environment]::SetEnvironmentVariable($Name, $null, "Machine")
        Remove-Item -Path "Env:$Name" -ErrorAction SilentlyContinue
        Write-Success "Removed $Name"
        Write-AuditEvent "ENV_REMOVE" $Name
    }
}

function Refresh-Env {
    Write-Step "Refreshing environment..."
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = $machine + ";" + $user
    
    foreach ($level in @("Machine", "User")) {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            if ($_.Key -ne "Path") {
                Set-Item -Path "Env:$($_.Key)" -Value $_.Value -ErrorAction SilentlyContinue
            }
        }
    }
}

#endregion

#region Winget Operations

function Invoke-WingetInstall {
    param([string]$PackageId, [string]$DisplayName)
    
    if (-not $AllowedPackages.ContainsKey($PackageId)) {
        Write-Err "BLOCKED: $PackageId not in allowlist"
        return $false
    }
    
    Write-Step "Installing $DisplayName..."
    
    if (-not $PSCmdlet.ShouldProcess($DisplayName, "Install")) {
        $Script:Results.Skipped += $DisplayName
        return $true
    }
    
    $wingetArgs = @("install", "--exact", "--id", $PackageId, "--source", "winget", "--scope", "machine", "--accept-source-agreements", "--accept-package-agreements", "--silent", "--disable-interactivity")
    Write-AuditEvent "COMMAND" "winget $($wingetArgs -join ' ')"

    $result = Start-Process -FilePath $script:WingetPath -ArgumentList $wingetArgs -Wait -PassThru -NoNewWindow
    
    if ($result.ExitCode -eq 0) {
        Write-Success "$DisplayName installed"
        $Script:Results.Successful += $DisplayName
        return $true
    }
    elseif ($result.ExitCode -eq -1978335189) {
        Write-Success "$DisplayName already installed"
        $Script:Results.Skipped += $DisplayName
        return $true
    }
    else {
        Write-Err "$DisplayName failed (exit: $($result.ExitCode))"
        $Script:Results.Failed += $DisplayName
        return $false
    }
}

function Invoke-WingetUninstall {
    param([string]$PackageId, [string]$DisplayName)
    
    if (-not (Test-PackageInstalled $PackageId)) {
        Write-Warn "$DisplayName not installed"
        $Script:Results.NotFound += $DisplayName
        return $true
    }
    
    Write-Step "Uninstalling $DisplayName..."
    
    if (-not $PSCmdlet.ShouldProcess($DisplayName, "Uninstall")) {
        $Script:Results.Skipped += $DisplayName
        return $true
    }
    
    $wingetArgs = @("uninstall", "--exact", "--id", $PackageId, "--source", "winget", "--silent", "--accept-source-agreements", "--disable-interactivity")
    Write-AuditEvent "COMMAND" "winget $($wingetArgs -join ' ')"

    $result = Start-Process -FilePath $script:WingetPath -ArgumentList $wingetArgs -Wait -PassThru -NoNewWindow
    
    if ($result.ExitCode -eq 0) {
        Write-Success "$DisplayName uninstalled"
        $Script:Results.Successful += $DisplayName
        return $true
    }
    else {
        Write-Err "$DisplayName failed (exit: $($result.ExitCode))"
        $Script:Results.Failed += $DisplayName
        return $false
    }
}

#endregion

#region Claude Code Operations

function Install-ClaudeCode {
    Write-Header "Installing Claude Code CLI"
    
    Refresh-Env
    
    if (-not (Test-CommandExists "npm")) {
        Write-Err "npm not available. Install Node.js first."
        $Script:Results.Failed += "Claude Code"
        return
    }
    
    if (-not $PSCmdlet.ShouldProcess("Claude Code", "Install via npm")) {
        $Script:Results.Skipped += "Claude Code"
        return
    }
    
    Write-Step "Installing Claude Code via npm..."
    Write-AuditEvent "COMMAND" "npm install -g $ClaudeCodePackage"
    
    try {
        $ErrorActionPreference = "Continue"
        $output = npm install -g $ClaudeCodePackage 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Claude Code installed"
            $Script:Results.Successful += "Claude Code"
        }
        else {
            Write-Err "Claude Code failed: $output"
            $Script:Results.Failed += "Claude Code"
        }
    }
    catch {
        Write-Err "Claude Code install error: $_"
        $Script:Results.Failed += "Claude Code"
    }
    finally {
        $ErrorActionPreference = "Stop"
    }
}

function Uninstall-ClaudeCode {
    Write-Header "Uninstalling Claude Code CLI"
    
    if (-not (Test-CommandExists "npm")) {
        Write-Warn "npm not available - skipping Claude Code"
        $Script:Results.Skipped += "Claude Code"
        return
    }
    
    try {
        $ErrorActionPreference = "Continue"
        $installed = npm list -g $ClaudeCodePackage 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Claude Code not installed"
            $Script:Results.NotFound += "Claude Code"
            return
        }
        
        if (-not $PSCmdlet.ShouldProcess("Claude Code", "Uninstall via npm")) {
            $Script:Results.Skipped += "Claude Code"
            return
        }
        
        Write-Step "Uninstalling Claude Code..."
        $output = npm uninstall -g $ClaudeCodePackage 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Claude Code uninstalled"
            $Script:Results.Successful += "Claude Code"
        }
        else {
            Write-Warn "Claude Code removal had issues: $output"
            $Script:Results.Failed += "Claude Code"
        }
    }
    catch {
        Write-Warn "Claude Code removal failed: $_ - continuing anyway"
        $Script:Results.Failed += "Claude Code"
    }
    finally {
        $ErrorActionPreference = "Stop"
    }
}

#endregion

#region Post-Install Configuration

function Set-PostInstallConfig {
    Write-Header "Configuring Environment"
    
    # VS Code PATH
    $vscodePaths = @("$env:ProgramFiles\Microsoft VS Code\bin", "${env:ProgramFiles(x86)}\Microsoft VS Code\bin")
    foreach ($p in $vscodePaths) { if (Test-Path $p) { Add-ToSystemPath $p; break } }
    
    # Git PATH
    $gitPaths = @("$env:ProgramFiles\Git\cmd", "${env:ProgramFiles(x86)}\Git\cmd")
    foreach ($p in $gitPaths) { if (Test-Path $p) { Add-ToSystemPath $p; break } }
    
    # Python PATH
    $pythonPaths = @("$env:ProgramFiles\Python312", "$env:ProgramFiles\Python312\Scripts")
    foreach ($p in $pythonPaths) { if (Test-Path $p) { Add-ToSystemPath $p } }
    
    # Node PATH
    if (Test-Path "$env:ProgramFiles\nodejs") { Add-ToSystemPath "$env:ProgramFiles\nodejs" }
    
    # Environment variables
    foreach ($kv in $EnvVarsToSet.GetEnumerator()) {
        Set-SystemEnvVar -Name $kv.Key -Value $kv.Value
    }
    
    Refresh-Env
    
    # Git config
    if (Test-CommandExists "git") {
        if ($PSCmdlet.ShouldProcess("Git", "Configure defaults")) {
            git config --system core.autocrlf true 2>$null
            git config --system init.defaultBranch main 2>$null
            Write-Success "Git configured"
        }
    }
    
    # Upgrade pip
    if (Test-CommandExists "python") {
        if ($PSCmdlet.ShouldProcess("pip", "Upgrade")) {
            python -m pip install --upgrade pip --quiet 2>$null
            Write-Success "pip upgraded"
        }
    }
}

function Remove-PostInstallConfig {
    Write-Header "Cleaning Environment"
    
    # Remove PATH entries
    foreach ($pattern in $PathPatternsToClean) {
        Remove-FromSystemPath $pattern
    }
    
    # Remove environment variables
    foreach ($varName in $EnvVarsToSet.Keys) {
        Remove-SystemEnvVar $varName
    }
    
    # Remove Git config
    if (Test-CommandExists "git") {
        if ($PSCmdlet.ShouldProcess("Git config", "Remove")) {
            git config --system --unset core.autocrlf 2>$null
            git config --system --unset init.defaultBranch 2>$null
            Write-Success "Git config cleaned"
        }
    }
}

#endregion

#region Prerequisites

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    if ([Environment]::OSVersion.Version.Major -lt 10) {
        throw "Requires Windows 10 or later"
    }
    Write-Success "Windows $([Environment]::OSVersion.Version)"
    
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Requires Administrator privileges"
    }
    Write-Success "Administrator privileges confirmed"
    
    if (-not (Test-CommandExists "winget")) {
        throw "winget required. Install App Installer from Microsoft Store."
    }
    $script:WingetPath = (Get-Command winget -ErrorAction Stop).Source
    Write-Success "winget available ($script:WingetPath)"
    
    Write-Step "Updating winget sources..."
    winget source update --disable-interactivity 2>$null | Out-Null
}

#endregion

#region Summary & Confirmation

function Show-Plan {
    $action = if ($Uninstall) { "REMOVED" } else { "INSTALLED" }
    $color = if ($Uninstall) { "Blue" } else { "Cyan" }
    
    Write-Header "$(if ($Uninstall) { 'Uninstallation' } else { 'Installation' }) Plan"
    
    Write-Host "The following will be ${action}:" -ForegroundColor $color
    Write-Host ""
    
    Write-Host "  Core:" -ForegroundColor Yellow
    foreach ($pkg in $CorePackages) {
        if ($Uninstall -and $pkg.KeepFlag) {
            Write-Host "    - $($pkg.Name) [KEEPING]" -ForegroundColor Gray
        }
        else {
            Write-Host "    - $($pkg.Name)" -ForegroundColor White
        }
    }
    Write-Host "    - Claude Code (npm)" -ForegroundColor White
    
    if (-not $SkipOptional) {
        Write-Host ""
        Write-Host "  Optional:" -ForegroundColor Yellow
        foreach ($pkg in $OptionalPackages) {
            Write-Host "    - $($pkg.Name)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    
    if ($WhatIfPreference) {
        Write-Warn "WHATIF MODE - No changes will be made"
        return $true
    }
    
    if (-not $Force) {
        $prompt = if ($Uninstall) { "Type 'YES' to confirm uninstall" } else { "Proceed? (Y/N)" }
        $response = Read-Host $prompt
        
        if ($Uninstall) {
            if ($response -ne "YES") {
                Write-Warn "Cancelled by user"
                return $false
            }
        }
        else {
            if ($response -notmatch "^[Yy]") {
                Write-Warn "Cancelled by user"
                return $false
            }
        }
    }
    
    return $true
}

function Show-Summary {
    Write-Header "Summary"
    
    if ($Script:Results.Successful.Count -gt 0) {
        Write-Host "Successful:" -ForegroundColor Green
        $Script:Results.Successful | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
    }
    
    if ($Script:Results.Skipped.Count -gt 0) {
        Write-Host "Skipped:" -ForegroundColor Yellow
        $Script:Results.Skipped | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    if ($Script:Results.NotFound.Count -gt 0) {
        Write-Host "Not Found:" -ForegroundColor Gray
        $Script:Results.NotFound | ForEach-Object { Write-Host "  . $_" -ForegroundColor Gray }
    }
    
    if ($Script:Results.Failed.Count -gt 0) {
        Write-Host "Failed:" -ForegroundColor Red
        $Script:Results.Failed | ForEach-Object { Write-Host "  x $_" -ForegroundColor Red }
    }
    
    Write-Host ""
    
    if (-not $WhatIfPreference -and $Script:Results.Successful.Count -gt 0) {
        Write-Host "NEXT: Close and reopen all terminals" -ForegroundColor Cyan
        
        if (-not $Uninstall) {
            Write-Host ""
            Write-Host "Verify:" -ForegroundColor Cyan
            Write-Host "  code --version && git --version && python --version && node --version && claude --version"
        }
    }
}

#endregion

#region Main

function Invoke-Install {
    foreach ($pkg in $CorePackages) {
        Invoke-WingetInstall -PackageId $pkg.Id -DisplayName $pkg.Name
    }
    
    if (-not $SkipOptional) {
        Write-Header "Installing Optional Tools"
        foreach ($pkg in $OptionalPackages) {
            Invoke-WingetInstall -PackageId $pkg.Id -DisplayName $pkg.Name
        }
    }
    
    Set-PostInstallConfig
    Install-ClaudeCode
}

function Invoke-Uninstall {
    # Uninstall Claude Code first while npm exists
    if (-not $KeepNodeJS) {
        Uninstall-ClaudeCode
    }
    else {
        Write-Warn "Keeping Claude Code (-KeepNodeJS)"
        $Script:Results.Skipped += "Claude Code"
    }
    
    if (-not $SkipOptional) {
        Write-Header "Uninstalling Optional Tools"
        foreach ($pkg in $OptionalPackages) {
            Invoke-WingetUninstall -PackageId $pkg.Id -DisplayName $pkg.Name
        }
    }
    
    Write-Header "Uninstalling Core Packages"
    foreach ($pkg in $CorePackages) {
        if ($pkg.KeepFlag) {
            Write-Warn "Keeping $($pkg.Name)"
            $Script:Results.Skipped += $pkg.Name
        }
        else {
            Invoke-WingetUninstall -PackageId $pkg.Id -DisplayName $pkg.Name
        }
    }
    
    Remove-PostInstallConfig
}

function Main {
    try {
        Start-AuditLog
        Test-Prerequisites
        
        if (-not (Show-Plan)) {
            Stop-AuditLog
            exit 0
        }
        
        if ($Uninstall) {
            Invoke-Uninstall
        }
        else {
            Invoke-Install
        }
        
        Refresh-Env
        Show-Summary
        Stop-AuditLog
        
        if ($Script:Results.Failed.Count -gt 0) { exit 1 }
    }
    catch {
        Write-Err "Fatal: $_"
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        Stop-AuditLog
        exit 1
    }
}

Main

#endregion
