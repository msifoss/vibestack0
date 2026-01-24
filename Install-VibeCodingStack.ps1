#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs the Vibe Coding Stack for all users.

.DESCRIPTION
    This script installs and configures:
    - Visual Studio Code
    - Git for Windows (Git Bash)
    - Python
    - Node.js (required for Claude Code)
    - Claude Code CLI
    - Everything (Void Tools)
    - IrfanView

.NOTES
    Requires: Administrator privileges, Windows 10/11
    Run: Right-click PowerShell -> Run as Administrator
#>

[CmdletBinding()]
param(
    [switch]$SkipOptional,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Script:InstallResults = @{
    Successful = @()
    Failed     = @()
    Skipped    = @()
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Magenta
    Write-Host "  $Message" -ForegroundColor Magenta
    Write-Host ("=" * 60) -ForegroundColor Magenta
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Add-ToSystemPath {
    param(
        [string]$PathToAdd,
        [switch]$Prepend
    )
    
    if (-not (Test-Path $PathToAdd)) {
        Write-Warn "Path does not exist: $PathToAdd"
        return $false
    }
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $pathArray = $currentPath -split ";" | Where-Object { $_ -ne "" }
    
    if ($pathArray -contains $PathToAdd) {
        Write-Step "Path already in system PATH: $PathToAdd"
        return $true
    }
    
    if ($Prepend) {
        $newPath = $PathToAdd + ";" + $currentPath
    } else {
        $newPath = $currentPath + ";" + $PathToAdd
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    $env:Path = $PathToAdd + ";" + $env:Path
    
    Write-Success "Added to system PATH: $PathToAdd"
    return $true
}

function Set-SystemEnvVar {
    param(
        [string]$Name,
        [string]$Value
    )
    
    [Environment]::SetEnvironmentVariable($Name, $Value, "Machine")
    Set-Item -Path "Env:$Name" -Value $Value
    Write-Success "Set environment variable: $Name = $Value"
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$DisplayName,
        [string]$Scope = "machine",
        [string]$OverrideArgs = ""
    )
    
    Write-Step "Installing $DisplayName..."
    
    try {
        # Build command as a single string to avoid argument parsing issues
        $cmd = "winget install --id $PackageId --source winget --scope $Scope --accept-source-agreements --accept-package-agreements --silent"
        
        if ($Force) {
            $cmd += " --force"
        }
        
        if ($OverrideArgs -ne "") {
            $cmd += " --override `"$OverrideArgs`""
        }
        
        Write-Step "Running: $cmd"
        
        # Use cmd /c to properly handle the command string
        $result = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -Wait -PassThru -NoNewWindow
        
        if ($result.ExitCode -eq 0) {
            Write-Success "$DisplayName installed successfully"
            $Script:InstallResults.Successful += $DisplayName
            return $true
        }
        elseif ($result.ExitCode -eq -1978335189) {
            Write-Success "$DisplayName is already installed"
            $Script:InstallResults.Skipped += $DisplayName
            return $true
        }
        else {
            Write-Err "Failed to install $DisplayName (Exit code: $($result.ExitCode))"
            $Script:InstallResults.Failed += $DisplayName
            return $false
        }
    }
    catch {
        Write-Err "Error installing ${DisplayName}: $_"
        $Script:InstallResults.Failed += $DisplayName
        return $false
    }
}

function Refresh-Env {
    Write-Step "Refreshing environment variables..."
    
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = $machinePath + ";" + $userPath
    
    foreach ($level in @("Machine", "User")) {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            if ($_.Key -ne "Path") {
                Set-Item -Path "Env:$($_.Key)" -Value $_.Value -ErrorAction SilentlyContinue
            }
        }
    }
    
    Write-Success "Environment variables refreshed"
}

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $osVersion = [Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        throw "This script requires Windows 10 or later"
    }
    Write-Success "Windows version: $($osVersion.ToString())"
    
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run as Administrator"
    }
    Write-Success "Running with Administrator privileges"
    
    if (-not (Test-CommandExists "winget")) {
        Write-Warn "winget not found. Attempting to install..."
        
        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
            Start-Sleep -Seconds 5
        }
        catch {
            throw "winget is required. Please install App Installer from the Microsoft Store."
        }
        
        if (-not (Test-CommandExists "winget")) {
            throw "Failed to install winget. Please install it manually from the Microsoft Store."
        }
    }
    Write-Success "winget is available"
    
    Write-Step "Updating winget sources..."
    winget source update --disable-interactivity | Out-Null
    Write-Success "winget sources updated"
}

function Install-VisualStudioCode {
    Write-Header "Installing Visual Studio Code"
    
    $overrideArgs = "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
    $installed = Install-WingetPackage -PackageId "Microsoft.VisualStudioCode" -DisplayName "Visual Studio Code" -OverrideArgs $overrideArgs
    
    if ($installed) {
        $vscodePaths = @(
            "$env:ProgramFiles\Microsoft VS Code\bin",
            "${env:ProgramFiles(x86)}\Microsoft VS Code\bin"
        )
        
        foreach ($p in $vscodePaths) {
            if (Test-Path $p) {
                Add-ToSystemPath -PathToAdd $p
                break
            }
        }
    }
}

function Install-GitForWindows {
    Write-Header "Installing Git for Windows (Git Bash)"
    
    $overrideArgs = "/VERYSILENT /NORESTART /COMPONENTS=icons,assoc,assoc_sh,gitlfs,windowsterminal"
    $installed = Install-WingetPackage -PackageId "Git.Git" -DisplayName "Git for Windows" -OverrideArgs $overrideArgs
    
    if ($installed) {
        $gitPaths = @(
            "$env:ProgramFiles\Git\cmd",
            "$env:ProgramFiles\Git\bin",
            "${env:ProgramFiles(x86)}\Git\cmd",
            "${env:ProgramFiles(x86)}\Git\bin"
        )
        
        foreach ($p in $gitPaths) {
            if (Test-Path $p) {
                Add-ToSystemPath -PathToAdd $p
            }
        }
        
        Refresh-Env
        
        if (Test-CommandExists "git") {
            Write-Step "Configuring Git defaults..."
            git config --system core.autocrlf true
            git config --system init.defaultBranch main
            git config --system core.editor "code --wait"
            Write-Success "Git configured with sensible defaults"
        }
    }
}

function Install-Python {
    Write-Header "Installing Python"
    
    $overrideArgs = "InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=1 Include_pip=1"
    $installed = Install-WingetPackage -PackageId "Python.Python.3.12" -DisplayName "Python 3.12" -OverrideArgs $overrideArgs
    
    if ($installed) {
        $pythonPaths = @(
            "$env:ProgramFiles\Python312",
            "$env:ProgramFiles\Python312\Scripts",
            "${env:ProgramFiles(x86)}\Python312",
            "${env:ProgramFiles(x86)}\Python312\Scripts"
        )
        
        foreach ($p in $pythonPaths) {
            if (Test-Path $p) {
                Add-ToSystemPath -PathToAdd $p
            }
        }
        
        $pythonHome = $pythonPaths | Where-Object { (Test-Path $_) -and (-not $_.EndsWith("Scripts")) } | Select-Object -First 1
        if ($pythonHome) {
            Set-SystemEnvVar -Name "PYTHONHOME" -Value $pythonHome
        }
        
        Refresh-Env
        
        if (Test-CommandExists "python") {
            Write-Step "Upgrading pip..."
            python -m pip install --upgrade pip --quiet
            Write-Success "pip upgraded"
        }
    }
}

function Install-NodeJS {
    Write-Header "Installing Node.js (Required for Claude Code)"
    
    $installed = Install-WingetPackage -PackageId "OpenJS.NodeJS.LTS" -DisplayName "Node.js LTS"
    
    if ($installed) {
        $nodePaths = @(
            "$env:ProgramFiles\nodejs",
            "${env:ProgramFiles(x86)}\nodejs"
        )
        
        foreach ($p in $nodePaths) {
            if (Test-Path $p) {
                Add-ToSystemPath -PathToAdd $p
            }
        }
        
        $npmGlobalPath = "$env:ProgramData\npm"
        if (-not (Test-Path $npmGlobalPath)) {
            New-Item -ItemType Directory -Path $npmGlobalPath -Force | Out-Null
        }
        Add-ToSystemPath -PathToAdd $npmGlobalPath
        
        Refresh-Env
        
        if (Test-CommandExists "npm") {
            Write-Step "Configuring npm for system-wide packages..."
            npm config set prefix $npmGlobalPath --global
            Write-Success "npm configured"
        }
    }
}

function Install-ClaudeCode {
    Write-Header "Installing Claude Code CLI"
    
    Refresh-Env
    
    if (-not (Test-CommandExists "npm")) {
        Write-Err "npm is not available. Please ensure Node.js is installed correctly."
        $Script:InstallResults.Failed += "Claude Code"
        return
    }
    
    Write-Step "Installing Claude Code via npm..."
    
    try {
        $output = npm install -g @anthropic-ai/claude-code 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Claude Code installed successfully"
            $Script:InstallResults.Successful += "Claude Code"
            
            Refresh-Env
            if (Test-CommandExists "claude") {
                Write-Success "Claude Code CLI is available. Run 'claude' to start."
            }
        }
        else {
            Write-Err "Failed to install Claude Code: $output"
            $Script:InstallResults.Failed += "Claude Code"
        }
    }
    catch {
        Write-Err "Error installing Claude Code: $_"
        $Script:InstallResults.Failed += "Claude Code"
    }
}

function Install-Everything {
    Write-Header "Installing Everything (Void Tools)"
    
    Install-WingetPackage -PackageId "voidtools.Everything" -DisplayName "Everything Search"
    Install-WingetPackage -PackageId "voidtools.Everything.Cli" -DisplayName "Everything CLI"
}

function Install-IrfanView {
    Write-Header "Installing IrfanView"
    
    Install-WingetPackage -PackageId "IrfanSkiljan.IrfanView" -DisplayName "IrfanView"
    
    Write-Step "Installing IrfanView Plugins..."
    Install-WingetPackage -PackageId "IrfanSkiljan.IrfanView.PlugIns" -DisplayName "IrfanView Plugins"
}

function Set-AdditionalEnvVars {
    Write-Header "Configuring Additional Environment Variables"
    
    $codeCmd = Get-Command "code" -ErrorAction SilentlyContinue
    if ($codeCmd) {
        $codePath = $codeCmd.Source
        Set-SystemEnvVar -Name "EDITOR" -Value "$codePath --wait"
        Set-SystemEnvVar -Name "VISUAL" -Value "$codePath --wait"
    }
    
    Set-SystemEnvVar -Name "FORCE_COLOR" -Value "1"
    Set-SystemEnvVar -Name "PYTHONUTF8" -Value "1"
    
    Write-Success "Additional environment variables configured"
}

function Show-Summary {
    Write-Header "Installation Summary"
    
    if ($Script:InstallResults.Successful.Count -gt 0) {
        Write-Host ""
        Write-Host "Successfully Installed:" -ForegroundColor Green
        $Script:InstallResults.Successful | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
    }
    
    if ($Script:InstallResults.Skipped.Count -gt 0) {
        Write-Host ""
        Write-Host "Already Installed (Skipped):" -ForegroundColor Yellow
        $Script:InstallResults.Skipped | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    if ($Script:InstallResults.Failed.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed to Install:" -ForegroundColor Red
        $Script:InstallResults.Failed | ForEach-Object { Write-Host "  x $_" -ForegroundColor Red }
    }
    
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Magenta
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "  1. Close and reopen any terminal windows"
    Write-Host "  2. Run 'claude' to authenticate Claude Code"
    Write-Host "  3. Open VS Code and install recommended extensions"
    Write-Host ""
    Write-Host "VERIFY INSTALLATION:" -ForegroundColor Cyan
    Write-Host "  code --version"
    Write-Host "  git --version"
    Write-Host "  python --version"
    Write-Host "  node --version"
    Write-Host "  claude --version"
    Write-Host ""
    
    if ($Script:InstallResults.Failed.Count -gt 0) {
        Write-Host "Some installations failed. You may need to install them manually." -ForegroundColor Yellow
        exit 1
    }
}

function Main {
    Clear-Host
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "          VIBE CODING STACK INSTALLER                    " -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Installing: VS Code, Git Bash, Python, Claude Code" -ForegroundColor White
    Write-Host "  Optional:   Everything, IrfanView" -ForegroundColor White
    Write-Host ""

    try {
        Test-Prerequisites
        
        Install-VisualStudioCode
        Install-GitForWindows
        Install-Python
        Install-NodeJS
        Install-ClaudeCode
        
        if (-not $SkipOptional) {
            Write-Header "Installing Optional Tools"
            Install-Everything
            Install-IrfanView
        }
        else {
            Write-Warn "Skipping optional tools (Everything, IrfanView)"
        }
        
        Set-AdditionalEnvVars
        Refresh-Env
        
        Show-Summary
    }
    catch {
        Write-Err "Installation failed: $_"
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        exit 1
    }
}

Main
