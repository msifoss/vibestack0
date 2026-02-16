================================================================================
                 VIBE CODING STACK (Security Hardened)
                           Version 3.1.0
================================================================================

WINDOWS - PowerShell (as Administrator):
--------------------------------------------------------------------------------

First time setup:
  Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
  Unblock-File .\VibeCodingStack.ps1

Install:     .\VibeCodingStack.ps1
Uninstall:   .\VibeCodingStack.ps1 -Uninstall
Preview:     .\VibeCodingStack.ps1 -WhatIf

macOS - Terminal:
--------------------------------------------------------------------------------

First time setup:
  chmod +x ./VibeCodingStack.sh

Install:     ./VibeCodingStack.sh
Uninstall:   ./VibeCodingStack.sh --uninstall
Preview:     ./VibeCodingStack.sh --whatif

================================================================================

WHAT GETS INSTALLED
-------------------

  Core (both platforms):
    - Visual Studio Code
    - Git
    - GitHub CLI (gh)
    - wget
    - Python 3.12
    - Node.js LTS
    - Claude Code (@anthropic-ai/claude-code)

  Optional - Windows:
    - Everything Search      (voidtools.Everything)
    - Everything CLI         (voidtools.Everything.Cli)
    - IrfanView              (IrfanSkiljan.IrfanView)
    - IrfanView Plugins      (IrfanSkiljan.IrfanView.PlugIns)

  Optional - macOS (alternatives):
    - fd                     (fast file finder - Everything alternative)
    - ImageOptim             (image optimizer - IrfanView alternative)

  Recommended Extras - macOS (prompted after core install):
    - jq                     (JSON processor)
    - tree                   (directory visualization)
    - ripgrep                (fast code search)
    - fzf                    (fuzzy finder)
    - httpie                 (human-friendly HTTP client)

  Windows-only (no Mac equivalent):
    - Everything (Void Tools) - use Spotlight, fd, or Alfred on Mac
    - IrfanView - use Preview, ImageOptim, or Pixelmator on Mac


COMMAND-LINE OPTIONS
--------------------

  WINDOWS (PowerShell):                 macOS (bash):
  ----------------------                -------------
  -WhatIf                               --whatif
  -Force                                --force
  -SkipOptional                         --skip-optional
  (n/a)                                 --skip-extras
  -Uninstall                            --uninstall
  -KeepPython                           --keep-python
  -KeepNodeJS                           --keep-node
  -KeepGit                              --keep-git
  -LogPath <dir>                        (auto in current dir)


EXAMPLES
--------

  Windows:
    .\VibeCodingStack.ps1                              # Install all
    .\VibeCodingStack.ps1 -SkipOptional -Force         # Core only, no prompts
    .\VibeCodingStack.ps1 -Uninstall -WhatIf           # Preview uninstall
    .\VibeCodingStack.ps1 -Uninstall -KeepGit          # Uninstall, keep Git

  macOS:
    ./VibeCodingStack.sh                               # Install all
    ./VibeCodingStack.sh --skip-optional --force       # Core only, no prompts
    ./VibeCodingStack.sh --skip-extras                 # Install without extras prompt
    ./VibeCodingStack.sh --uninstall --whatif          # Preview uninstall
    ./VibeCodingStack.sh --uninstall --keep-git        # Uninstall, keep Git


SECURITY FEATURES
-----------------

  [+] Package Allowlist      Only approved packages can install
  [+] Exact Matching         Uses --exact to prevent substitution attacks
  [+] Official Source Only   Uses --source winget exclusively
  [+] Audit Logging          Full transcript saved to timestamped log file
  [+] Confirmation Required  Shows plan before making changes
  [+] WhatIf Mode            Preview all changes safely
  [+] Strict Mode            PowerShell strict mode enabled


AUDIT LOGS
----------

Every run creates a log file:

  Install:    VibeCodingStack_Install_YYYY-MM-DD_HHMMSS.log
  Uninstall:  VibeCodingStack_Uninstall_YYYY-MM-DD_HHMMSS.log

Location: Script directory, or %TEMP% if not writable.


REQUIREMENTS
------------

  Windows:
    - Windows 10 or Windows 11
    - Administrator privileges
    - Internet connection
    - winget (App Installer from Microsoft Store)

  macOS:
    - macOS 10.15+ (Catalina or later)
    - Internet connection
    - Homebrew (will be installed if missing)


POST-INSTALLATION
-----------------

  1. Close and reopen all terminal windows

  2. Verify:
     code --version
     git --version
     python --version
     node --version
     claude --version

  3. Authenticate Claude Code:
     claude


TROUBLESHOOTING
---------------

  Windows - "File cannot be loaded. The file is not digitally signed."
    Run: Unblock-File .\VibeCodingStack.ps1
    Or right-click file -> Properties -> check "Unblock" -> OK

  Windows - "winget is not recognized"
    Install "App Installer" from Microsoft Store.

  Windows - "Access Denied"
    Right-click PowerShell -> Run as Administrator

  macOS - "permission denied"
    Run: chmod +x ./VibeCodingStack.sh

  macOS - "command not found: brew"
    Script will auto-install Homebrew, or manually run:
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  Both - PATH not updated
    Close ALL terminal windows and reopen.
    macOS: run 'source ~/.zshrc'

  Both - Claude Code not found
    Windows: $env:Path += ";$env:APPDATA\npm"
    macOS: export PATH="$HOME/.npm-global/bin:$PATH"


VERIFYING SCRIPT INTEGRITY
--------------------------

  Windows:
    Get-FileHash .\VibeCodingStack.ps1 -Algorithm SHA256

  macOS:
    shasum -a 256 ./VibeCodingStack.sh

================================================================================