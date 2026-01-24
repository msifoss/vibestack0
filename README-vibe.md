# Vibe Coding Stack Installer

A PowerShell script that installs and configures a complete development environment for all users on a Windows system.

## What Gets Installed

### Core Stack
| Software | Purpose |
|----------|---------|
| **Visual Studio Code** | Code editor with context menu integration |
| **Git for Windows** | Version control + Git Bash terminal |
| **Python 3.12** | Python runtime with pip |
| **Node.js LTS** | JavaScript runtime (required for Claude Code) |
| **Claude Code** | AI-powered coding assistant CLI |

### Optional Tools
| Software | Purpose |
|----------|---------|
| **Everything** (Void Tools) | Instant file search + CLI |
| **IrfanView** | Fast image viewer with plugins |

## Requirements

- Windows 10 or Windows 11
- Administrator privileges
- Internet connection
- Windows Package Manager (winget) - script will attempt to install if missing

## Usage

### Basic Installation

1. **Open PowerShell as Administrator**
   - Press `Win + X`
   - Select "Terminal (Admin)" or "PowerShell (Admin)"

2. **Set execution policy** (if needed)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run the installer**
   ```powershell
   .\Install-VibeCodingStack.ps1
   ```

### Command-Line Options

```powershell
# Install everything (default)
.\Install-VibeCodingStack.ps1

# Skip optional tools (Everything, IrfanView)
.\Install-VibeCodingStack.ps1 -SkipOptional

# Force reinstall of all packages
.\Install-VibeCodingStack.ps1 -Force

# Combine options
.\Install-VibeCodingStack.ps1 -SkipOptional -Force
```

## Environment Variables Configured

The script automatically sets up these environment variables:

| Variable | Value | Purpose |
|----------|-------|---------|
| `PATH` | Updated with all tool paths | Command-line access |
| `EDITOR` | VS Code | Default editor for CLI tools |
| `VISUAL` | VS Code | Visual editor for git, etc. |
| `PYTHONHOME` | Python install directory | Python configuration |
| `PYTHONUTF8` | `1` | Force UTF-8 encoding in Python |
| `FORCE_COLOR` | `1` | Enable ANSI colors in terminals |

## Post-Installation

After installation completes:

1. **Close and reopen** any terminal windows to load the new PATH

2. **Verify installations:**
   ```powershell
   code --version     # Visual Studio Code
   git --version      # Git
   python --version   # Python
   node --version     # Node.js
   npm --version      # npm
   claude --version   # Claude Code
   es -h              # Everything CLI (if installed)
   ```

3. **Authenticate Claude Code:**
   ```powershell
   claude
   ```
   Follow the prompts to connect your Anthropic API key.

## Git Configuration

The script configures these Git defaults system-wide:

- `core.autocrlf = true` - Handles line endings on Windows
- `init.defaultBranch = main` - Uses 'main' as default branch
- `core.editor = code --wait` - Uses VS Code as Git editor

## Troubleshooting

### "winget is not recognized"
The script will attempt to install winget automatically. If it fails:
1. Open Microsoft Store
2. Search for "App Installer"
3. Install/Update the app
4. Re-run the script

### "Access Denied" errors
Ensure you're running PowerShell as Administrator (right-click → Run as Administrator)

### Package installation fails
Try running with the `-Force` flag:
```powershell
.\Install-VibeCodingStack.ps1 -Force
```

### PATH not updated
Close all terminal windows and open a new one. If issues persist:
```powershell
# Manually refresh environment
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
```

### Claude Code not found after install
The npm global path may need to be added manually:
```powershell
$env:Path += ";$env:ProgramData\npm"
```

## Customization

To modify installed packages, edit the script and update the `Install-*` functions. Each uses winget package IDs which can be found at:
- https://winget.run
- Run `winget search <package-name>`

## Uninstallation

To remove installed packages:
```powershell
winget uninstall Microsoft.VisualStudioCode
winget uninstall Git.Git
winget uninstall Python.Python.3.12
winget uninstall OpenJS.NodeJS.LTS
winget uninstall voidtools.Everything
winget uninstall IrfanSkiljan.IrfanView

npm uninstall -g @anthropic-ai/claude-code
```

## License

MIT - Feel free to modify and distribute.
