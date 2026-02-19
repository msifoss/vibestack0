# Manual Installation Guide — Windows

This guide walks you through every step that the `VibeCodingStack-Windows.ps1` script automates. Follow it if you prefer to understand and execute each step yourself, or if you can't run the script directly.

**Estimated time:** 20–40 minutes (depending on download speeds)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Step-by-Step Installation](#3-step-by-step-installation)
4. [Environment Configuration](#4-environment-configuration)
5. [Claude Code Installation](#5-claude-code-installation)
6. [Optional Packages](#6-optional-packages)
7. [Verification](#7-verification)
8. [Uninstallation](#8-uninstallation)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Overview

The Vibe Coding Stack installs the following core tools:

| Tool | Purpose |
|------|---------|
| Visual Studio Code | Code editor |
| Git for Windows | Version control (includes Git Bash) |
| GitHub CLI (gh) | GitHub operations from the terminal |
| Python 3.12 | Python programming language |
| Node.js LTS | JavaScript runtime (required for Claude Code) |
| Claude Code | Anthropic's AI coding assistant CLI |

Optional tools:

| Tool | Purpose |
|------|---------|
| Everything Search | Instant file search by name |
| Everything CLI | Command-line interface for Everything Search |

---

## 2. Prerequisites

- **Windows 10 or later** (Windows 11 recommended)
- **Administrator privileges** — you must run PowerShell as Administrator for most steps
- **winget** (Windows Package Manager) — comes pre-installed on Windows 11. On Windows 10, install [App Installer](https://apps.microsoft.com/detail/9nblggh4nns1) from the Microsoft Store if `winget` is not available.

### Verify winget is available

Open PowerShell as Administrator and run:

```powershell
winget --version
```

If this returns a version number, you're ready to proceed.

### Update winget sources

```powershell
winget source update --disable-interactivity
```

---

## 3. Step-by-Step Installation

Open **PowerShell as Administrator** for all of the following commands.

> **Important:** Each `winget install` command uses `--exact --id` to ensure you get the correct package, `--source winget` to use the official repository, and `--scope machine` to install system-wide.

### 3.1 Install Visual Studio Code

```powershell
winget install --exact --id Microsoft.VisualStudioCode --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
```

### 3.2 Install Git for Windows

```powershell
winget install --exact --id Git.Git --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
```

### 3.3 Install GitHub CLI

```powershell
winget install --exact --id GitHub.cli --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
```

### 3.4 Install Python 3.12

```powershell
winget install --exact --id Python.Python.3.12 --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
```

### 3.5 Install Node.js LTS

```powershell
winget install --exact --id OpenJS.NodeJS.LTS --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
```

---

## 4. Environment Configuration

After installing the packages above, you need to configure the system PATH, environment variables, and Git.

> **Important:** Close and reopen PowerShell (as Administrator) after making PATH changes so they take effect. Alternatively, you can refresh the current session's PATH using the commands in section 4.3.

### 4.1 Add to System PATH

The installers usually add themselves to PATH, but verify and add these if missing:

```powershell
# VS Code — add whichever path exists on your system
# 64-bit:
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\Microsoft VS Code\bin", "Machine")

# Git
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\Git\cmd", "Machine")

# Python 3.12 (both the interpreter and Scripts directory)
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\Python312;C:\Program Files\Python312\Scripts", "Machine")

# Node.js
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\nodejs", "Machine")
```

> **Tip:** Before adding a path, check if it already exists to avoid duplicates:
> ```powershell
> [Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Select-String "VS Code"
> ```

### 4.2 Set Environment Variables

Set `PYTHONUTF8=1` so Python defaults to UTF-8 encoding:

```powershell
[Environment]::SetEnvironmentVariable("PYTHONUTF8", "1", "Machine")
```

### 4.3 Refresh Current Session

To pick up the new PATH and environment variables without restarting PowerShell:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
$env:PYTHONUTF8 = "1"
```

### 4.4 Configure Git

```powershell
git config --system core.autocrlf true
git config --system init.defaultBranch main
```

These are set at the **system** level (applies to all users). The script uses `--system` because it runs as Administrator.

### 4.5 Upgrade pip

```powershell
python -m pip install --upgrade pip --quiet
```

---

## 5. Claude Code Installation

Claude Code is installed globally via npm (which comes with Node.js):

```powershell
npm install -g @anthropic-ai/claude-code
```

After installation, verify it:

```powershell
claude --version
```

---

## 6. Optional Packages

These are optional but recommended for enhanced file search capabilities.

### 6.1 Everything Search

A fast file search tool by Void Tools:

```powershell
winget install --exact --id voidtools.Everything --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
```

### 6.2 Everything CLI

Command-line access to Everything Search:

```powershell
winget install --exact --id voidtools.Everything.Cli --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
```

---

## 7. Verification

Close and reopen all terminal windows, then run:

```powershell
code --version
git --version
python --version
node --version
claude --version
```

All commands should return version numbers without errors.

---

## 8. Uninstallation

To reverse the installation, follow these steps in order.

### 8.1 Uninstall Claude Code (do this first, while npm still exists)

```powershell
npm uninstall -g @anthropic-ai/claude-code
```

### 8.2 Uninstall Optional Packages

```powershell
winget uninstall --exact --id voidtools.Everything.Cli --source winget --silent --accept-source-agreements --disable-interactivity
winget uninstall --exact --id voidtools.Everything --source winget --silent --accept-source-agreements --disable-interactivity
```

### 8.3 Uninstall Core Packages

```powershell
winget uninstall --exact --id Microsoft.VisualStudioCode --source winget --silent --accept-source-agreements --disable-interactivity
winget uninstall --exact --id Git.Git --source winget --silent --accept-source-agreements --disable-interactivity
winget uninstall --exact --id GitHub.cli --source winget --silent --accept-source-agreements --disable-interactivity
winget uninstall --exact --id Python.Python.3.12 --source winget --silent --accept-source-agreements --disable-interactivity
winget uninstall --exact --id OpenJS.NodeJS.LTS --source winget --silent --accept-source-agreements --disable-interactivity
```

### 8.4 Clean Up PATH

Remove the PATH entries that were added. Open PowerShell as Administrator:

```powershell
# Get current system PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

# Remove entries matching the installed tools
$patterns = @("*\Microsoft VS Code\*", "*\Git\*", "*\Python312*", "*\nodejs*", "*\npm*")
$pathArray = $currentPath -split ";" | Where-Object { $_ -ne "" }

foreach ($pattern in $patterns) {
    $pathArray = @($pathArray | Where-Object { $_ -notlike $pattern })
}

# Set the cleaned PATH
[Environment]::SetEnvironmentVariable("Path", ($pathArray -join ";"), "Machine")
```

### 8.5 Remove Environment Variables

```powershell
[Environment]::SetEnvironmentVariable("PYTHONUTF8", $null, "Machine")
```

### 8.6 Remove Git System Config

```powershell
git config --system --unset core.autocrlf
git config --system --unset init.defaultBranch
```

### 8.7 Restart

Close and reopen all terminal windows to apply changes.

---

## 9. Troubleshooting

### "winget is not recognized"

- On Windows 10, install [App Installer](https://apps.microsoft.com/detail/9nblggh4nns1) from the Microsoft Store.
- On Windows 11, it should be pre-installed. Try running `winget` from a new PowerShell window.

### "Access denied" or "requires Administrator"

- Right-click PowerShell and select **Run as Administrator**.
- The system-level PATH changes and `git config --system` require Administrator privileges.

### Package "already installed" messages

- This is normal. winget skips packages that are already present. Exit code `-1978335189` means "already installed."

### Commands not found after installation

- Close **all** terminal windows and open a new one. PATH changes only apply to new sessions.
- To refresh the current session without restarting, run the commands in [section 4.3](#43-refresh-current-session).

### npm install fails for Claude Code

- Ensure Node.js is installed and `npm` is on your PATH: `npm --version`
- If you get permission errors, make sure you're running PowerShell as Administrator.
- Try clearing the npm cache: `npm cache clean --force`

### Python encoding issues

- Verify `PYTHONUTF8` is set: `[Environment]::GetEnvironmentVariable("PYTHONUTF8", "Machine")`
- If it returns `1`, the setting is correct. Restart your terminal if Python still defaults to a different encoding.

### Git line ending issues

- Verify the setting: `git config --system core.autocrlf`
- Should return `true`. This ensures consistent line endings on Windows.
