# Changelog

All notable changes to the Vibe Coding Stack are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).
Most recent changes appear first.

---

## [3.2.0-secure] - 2026-02-18

**TLDR:** Security hardening pass on both scripts — macOS gets TLS 1.2
enforcement, locked-down audit logs, and version pinning. Windows removes the
`cmd.exe` intermediary so winget is invoked directly. Dead code removed from both.

### Security
- (macOS) Enforce TLS 1.2 minimum on all `curl` calls via `--tlsv1.2` (3 locations)
- (macOS) Create audit log files with `chmod 600` (owner read/write only)
- (macOS) Validate log file paths against directory traversal sequences (`../`, `//`, `/../`)
- (macOS) Add `CLAUDE_CODE_VERSION` variable for pinning Claude Code to a specific version
- (macOS) Warn at runtime when Claude Code version is unpinned (latest)
- (Windows) Invoke winget directly instead of shelling through `cmd.exe /c` — eliminates unnecessary intermediary process
- (Windows) Resolve winget full path via `Get-Command` at startup to handle AppX alias resolution reliably with `Start-Process`
- (Windows) Add `--disable-interactivity` to all winget install and uninstall calls to prevent hidden prompts from stalling the script

### Removed
- Unused `declare -a` array variables (`CORE_FORMULAE`, `CORE_CASKS`, `OPTIONAL_FORMULAE`, `OPTIONAL_CASKS`, `PHASE2_FORMULAE`) that were never referenced

### Changed
- Bump version to `3.2.0-secure` in script header and `VERSION` variable
- Strip trailing whitespace from entire Mac script
- Update README security features section with 3.2.0-secure additions
- Update README security audit with new `[SAFE]` items and revised mitigations

---

## [3.1.0] - 2026-02-16

**TLDR:** Added GitHub CLI, wget, and a "recommended extras" prompt (jq, tree,
ripgrep, fzf, httpie) to the macOS installer. Claude Code security audit
added to README. Fixed npm-not-found bug during Claude Code install.

### Added
- GitHub CLI (`gh`) to macOS core install
- `wget` to macOS core install
- Phase 2 "Recommended Extras" interactive prompt after core install: jq, tree, ripgrep, fzf, httpie
- `--skip-extras` flag to bypass the extras prompt
- Independent Claude Code security audit appended to README
- README documentation for recommended extras and all core tools

### Fixed
- npm not found when installing Claude Code — Node.js keg-only PATH not exported before `npm install -g` runs

### Changed
- Set Mac install script as executable (`chmod +x`)
- Bump version to 3.1.0

---

## [3.0.0] - 2026-01-26

**TLDR:** Major reliability overhaul of the macOS script — self-healing Homebrew
that survives Sequoia upgrades, automatic SSH override removal, live-streamed
output, and comprehensive error handling. Cross-platform support finalized.

### Added
- Cross-platform support: separate scripts per OS (`VibeCodingStack-Mac.sh` and `VibeCodingStack-Windows.ps1`)
- Self-healing Homebrew upgrade that detects and reinstalls when macOS version is unrecognized (e.g. Sequoia)
- Automatic detection and removal of git SSH-over-HTTPS overrides that block Homebrew
- Live-streamed output for long-running Homebrew operations (no more silent hangs)
- Comprehensive error handling with `set -uo pipefail` and graceful fallbacks
- Result tracking arrays (`SUCCESSFUL`, `FAILED`, `SKIPPED`, `NOT_FOUND`) with color-coded summary
- `--whatif` preview mode for macOS
- `--force`, `--skip-optional`, `--keep-git`, `--keep-python`, `--keep-node` flags
- Audit logging with timestamped log files
- Apple Silicon (`/opt/homebrew`) PATH detection and configuration
- Post-install environment configuration (shell RC files, Git defaults)

### Fixed
- Mac script filename typo (`VibCodingStack` -> `VibeCodingStack`)
- Stale Homebrew causing formula install failures
- Homebrew hanging during update (switched from captured output to live streaming)
- Various Mac script edge cases around PATH detection and missing dependencies

### Changed
- Rewrote Mac script from scratch with structured install/uninstall functions
- README updated with cross-platform usage, options comparison table, and troubleshooting

---

## [2.0.0] - 2026-01-24

**TLDR:** The PowerShell script gained uninstall support, confirmation prompts,
WhatIf preview mode, and structured audit logging. Single-script
install-and-uninstall workflow.

### Added
- Uninstall mode (`-Uninstall` flag) for Windows PowerShell script
- WhatIf preview mode (`-WhatIf` flag)
- Confirmation prompts before install and uninstall
- Structured audit logging with timestamped log files
- Package allowlist with `--exact` matching and `--source winget` enforcement

### Changed
- Renamed script from `Install-VibeCodingStack.ps1` to `VibeCodingStack.ps1`
- Expanded README with full usage documentation

---

## [1.0.0] - 2026-01-24

**TLDR:** Initial release — Windows-only PowerShell installer for the core vibe
coding stack (VS Code, Git, Python, Node.js, Claude Code) plus optional
tools (Everything, IrfanView).

### Added
- Windows PowerShell install script (`Install-VibeCodingStack.ps1`)
- Core package installation via winget: Visual Studio Code, Git, Python 3.12, Node.js LTS, Claude Code
- Optional package installation: Everything Search, Everything CLI, IrfanView, IrfanView Plugins
- Basic README with usage instructions
