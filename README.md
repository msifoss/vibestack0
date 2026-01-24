================================================================================
                 VIBE CODING STACK (Security Hardened)
                           Version 3.0.0
================================================================================

FIRST TIME SETUP (one-time, as Administrator):
--------------------------------------------------------------------------------

Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
Unblock-File .\VibeCodingStack.ps1

INSTALL:
--------------------------------------------------------------------------------

.\VibeCodingStack.ps1

UNINSTALL:
--------------------------------------------------------------------------------

.\VibeCodingStack.ps1 -Uninstall

PREVIEW (no changes):
--------------------------------------------------------------------------------

.\VibeCodingStack.ps1 -WhatIf
.\VibeCodingStack.ps1 -Uninstall -WhatIf

================================================================================

WHAT GETS INSTALLED
-------------------

  Core:
    - Visual Studio Code     (Microsoft.VisualStudioCode)
    - Git for Windows        (Git.Git)
    - Python 3.12            (Python.Python.3.12)
    - Node.js LTS            (OpenJS.NodeJS.LTS)
    - Claude Code            (@anthropic-ai/claude-code)

  Optional:
    - Everything Search      (voidtools.Everything)
    - Everything CLI         (voidtools.Everything.Cli)
    - IrfanView              (IrfanSkiljan.IrfanView)
    - IrfanView Plugins      (IrfanSkiljan.IrfanView.PlugIns)


COMMAND-LINE OPTIONS
--------------------

  INSTALL OPTIONS:
    -WhatIf          Preview without making changes
    -Force           Skip confirmation prompt
    -SkipOptional    Skip Everything and IrfanView
    -LogPath <dir>   Custom audit log location

  UNINSTALL OPTIONS:
    -Uninstall       Switch to uninstall mode
    -WhatIf          Preview without making changes
    -Force           Skip confirmation (normally requires typing 'YES')
    -SkipOptional    Keep Everything and IrfanView
    -KeepPython      Keep Python installed
    -KeepNodeJS      Keep Node.js and Claude Code installed
    -KeepGit         Keep Git installed
    -LogPath <dir>   Custom audit log location


EXAMPLES
--------

  # Install everything
  .\VibeCodingStack.ps1

  # Install core only, skip prompts
  .\VibeCodingStack.ps1 -SkipOptional -Force

  # Preview uninstall
  .\VibeCodingStack.ps1 -Uninstall -WhatIf

  # Uninstall but keep Git and Python
  .\VibeCodingStack.ps1 -Uninstall -KeepGit -KeepPython


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

  - Windows 10 or Windows 11
  - Administrator privileges
  - Internet connection
  - winget (App Installer from Microsoft Store)


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

  "File cannot be loaded. The file is not digitally signed."
    Run: Unblock-File .\VibeCodingStack.ps1
    Or right-click file -> Properties -> check "Unblock" -> OK

  "winget is not recognized"
    Install "App Installer" from Microsoft Store.

  "Access Denied"
    Right-click PowerShell -> Run as Administrator

  PATH not updated
    Close ALL terminal windows and reopen.

  Claude Code not found
    Add npm to PATH: $env:Path += ";$env:APPDATA\npm"


VERIFYING SCRIPT INTEGRITY
--------------------------

  Get-FileHash .\VibeCodingStack.ps1 -Algorithm SHA256

================================================================================
