================================================================================
                 VIBE CODING STACK (Security Hardened)
                        Version 3.2.0-secure
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
    - Python 3.12
    - Node.js LTS
    - Claude Code (@anthropic-ai/claude-code)

  Core - macOS only:
    - wget                   (PowerShell has Invoke-WebRequest on Windows)

  Optional - Windows:
    - Everything Search      (voidtools.Everything)
    - Everything CLI         (voidtools.Everything.Cli)

  Optional - macOS (alternatives):
    - fd                     (fast file finder - Everything alternative)
    - ImageOptim             (image optimizer)

  Recommended Extras - macOS (prompted after core install):
    - jq                     (JSON processor)
    - tree                   (directory visualization)
    - ripgrep                (fast code search)
    - fzf                    (fuzzy finder)
    - httpie                 (human-friendly HTTP client)

  Windows-only (no Mac equivalent):
    - Everything (Void Tools) - use Spotlight, fd, or Alfred on Mac


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

  Added in 3.2.0-secure:

  macOS:
  [+] TLS 1.2 Enforcement   All curl calls require --tlsv1.2 minimum
  [+] Log File Permissions   Audit logs created with chmod 600 (owner-only)
  [+] Log Path Validation    Rejects path traversal sequences (../, //, /../)
  [+] Version Pin Support    CLAUDE_CODE_VERSION variable for reproducible builds
  [+] Unused Code Removed    Dead array declarations stripped from script

  Windows:
  [+] Direct Winget          Invokes winget directly (removed cmd.exe intermediary)
  [+] Resolved Path          Resolves winget.exe full path via Get-Command at startup
  [+] No Interactivity       --disable-interactivity prevents hidden prompts/stalls
  [+] IrfanView Removed      Dropped from optional packages and allowlist


AUDIT LOGS
----------

Every run creates a log file:

  Install:    VibeCodingStack_Install_YYYY-MM-DD_HHMMSS.log
  Uninstall:  VibeCodingStack_Uninstall_YYYY-MM-DD_HHMMSS.log

Location: Script directory, or %TEMP% if not writable.
macOS: Log files are created with 600 permissions (owner read/write only).


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
     gh --version
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
    /bin/bash -c "$(curl -fsSL --tlsv1.2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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
                        CLAUDE CODE SECURITY AUDIT
                            2026-02-18
================================================================================

An independent security audit was performed by Claude Code (Opus 4.6) against
the full source of both VibeCodingStack-Mac.sh and VibeCodingStack-Windows.ps1.

WHAT IS SAFE
------------

  [SAFE] No embedded secrets, API keys, or credentials in either script
  [SAFE] No data exfiltration - scripts do not phone home or transmit data
  [SAFE] No obfuscated or encoded code - all logic is readable and auditable
  [SAFE] No backdoors, reverse shells, or hidden functionality
  [SAFE] No file deletion outside of controlled uninstall operations
  [SAFE] No user data collection or telemetry

  [SAFE] Windows: Package allowlist blocks unapproved package IDs
  [SAFE] Windows: --exact flag prevents winget substitution/typosquatting attacks
  [SAFE] Windows: --source winget restricts to official Microsoft source only
  [SAFE] Windows: Set-StrictMode -Version Latest catches common coding errors
  [SAFE] Windows: #Requires -RunAsAdministrator enforced (no silent elevation)
  [SAFE] Windows: SupportsShouldProcess enables native -WhatIf preview
  [SAFE] Windows: winget invoked directly via resolved full path (v3.2.0)
  [SAFE] Windows: --disable-interactivity prevents hidden prompts (v3.2.0)

  [SAFE] macOS: Packages installed only from Homebrew official formulae/casks
  [SAFE] macOS: set -uo pipefail catches unset variables and pipe failures
  [SAFE] macOS: Claude Code installed from official @anthropic-ai npm scope
  [SAFE] macOS: User confirmation required before install and uninstall
  [SAFE] macOS: Uninstall requires typing "YES" (not just Y) for safety
  [SAFE] macOS: All curl calls enforce TLS 1.2+ via --tlsv1.2 (v3.2.0)
  [SAFE] macOS: Audit log files created with 600 permissions (v3.2.0)
  [SAFE] macOS: Log file path validated against traversal attacks (v3.2.0)
  [SAFE] macOS: Claude Code version pinning supported for reproducibility (v3.2.0)

  [SAFE] Both: Full audit logging with timestamps for every operation
  [SAFE] Both: WhatIf/--whatif preview mode makes zero changes
  [SAFE] Both: Git configured with safe defaults (init.defaultBranch main)
  [SAFE] Both: All packages are well-known, widely-used open-source tools

CONCERNS AND RISKS TO BE AWARE OF
----------------------------------

  [MEDIUM] Remote code execution via Homebrew bootstrap (macOS)
    The Mac script downloads and executes the Homebrew installer:
      /bin/bash -c "$(curl -fsSL --tlsv1.2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    This is the standard, officially recommended Homebrew installation method.
    Risk: If GitHub or the Homebrew repo were compromised, arbitrary code
    could execute. This is an accepted industry-standard risk shared by
    millions of macOS developers.
    Mitigation: HTTPS-only with TLS 1.2+ enforced, official Homebrew source,
    no custom modifications.

  [MEDIUM] Shell RC file modification (macOS)
    The Mac script appends PATH entries to ~/.zshrc, ~/.bash_profile, or
    ~/.profile. These changes persist after uninstall.
    Risk: Accumulates PATH entries on repeated runs; modifies user shell
    startup environment permanently.
    Mitigation: Script checks for existing entries before adding (grep guard).

  [MEDIUM] System PATH modification (Windows)
    The Windows script modifies the system-wide PATH environment variable
    using [Environment]::SetEnvironmentVariable("Path", ..., "Machine").
    Risk: Affects all users on multi-user systems. Incorrect cleanup
    during uninstall could break other applications.
    Mitigation: Uses wildcard-pattern-based cleanup; reversible via uninstall.

  [MEDIUM] Git global/system config changes (both platforms)
    Both scripts set git configuration:
      macOS:   git config --global init.defaultBranch main
               git config --global core.editor "code --wait"
      Windows: git config --system core.autocrlf true
               git config --system init.defaultBranch main
    Risk: Overrides existing user/system git preferences without backup.
    Mitigation: Uninstall mode reverses system-level settings (Windows).
    Note: macOS global config changes are NOT reversed on uninstall.

  [MEDIUM] npm global package install (both platforms)
    Claude Code is installed via: npm install -g @anthropic-ai/claude-code
    Risk: npm packages can run arbitrary install scripts. A compromised
    npm registry or package could execute malicious code.
    Mitigation: Uses the official @anthropic-ai npm scope (verified publisher).
    macOS v3.2.0 adds CLAUDE_CODE_VERSION pinning for reproducible builds.

  [LOW] Git SSH override removal (macOS)
    If git is configured to rewrite GitHub HTTPS URLs to SSH, the Mac script
    removes this override to allow Homebrew to function.
    Risk: May break workflows that depend on SSH-based git access to GitHub.
    Mitigation: Only removes the specific insteadOf override; warns before
    acting; SSH keys and config remain intact.

  [LOW] Homebrew self-repair reinstall (macOS)
    If Homebrew does not recognize the macOS version, the script reinstalls
    Homebrew from scratch by re-running the official installer.
    Risk: Additional remote code execution on a potentially unexpected
    code path.
    Mitigation: Same official Homebrew installer; only triggered when
    Homebrew reports macOS as "unsupported" or "unknown".

  [LOW] pip auto-upgrade (Windows)
    The Windows script runs: python -m pip install --upgrade pip --quiet
    Risk: Downloads pip from PyPI; could be affected by a PyPI compromise.
    Mitigation: Uses official PyPI; pip is a first-party Python tool.

  [NONE] No credential harvesting or exfiltration
  [NONE] No network listeners or open ports
  [NONE] No modification of system security settings (firewall, antivirus)
  [NONE] No scheduled tasks or persistent background processes created
  [NONE] No browser extensions or certificates installed

AUDIT METHODOLOGY
-----------------

  This audit was performed by Claude Code (Anthropic Opus 4.6) on 2026-02-18.
  Both scripts were read in their entirety (980 lines macOS, 755 lines Windows)
  and analyzed for:
    - Embedded secrets or credentials
    - Remote code execution vectors
    - Data exfiltration or telemetry
    - Obfuscated or encoded payloads
    - Unauthorized file system changes
    - Privilege escalation beyond stated requirements
    - Supply chain risks (package sources and registries)
    - Environment persistence and reversibility

  Conclusion: Both scripts do exactly what they claim to do - install a
  curated set of developer tools using official package managers. The security
  hardening measures (allowlist, exact matching, audit logging, confirmation
  prompts) are genuine and effective. The identified concerns are standard
  risks inherent to using package managers and are not unique to this project.

================================================================================