# Manual Installation Guide — macOS

This guide walks you through every step that the `VibeCodingStack-Mac.sh` script automates. Follow it if you prefer to understand and execute each step yourself, or if you can't run the script directly.

**Estimated time:** 20–40 minutes (depending on download speeds)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Step-by-Step Installation](#3-step-by-step-installation)
4. [Environment Configuration](#4-environment-configuration)
5. [Claude Code Installation](#5-claude-code-installation)
6. [Optional Packages](#6-optional-packages)
7. [Recommended Extras](#7-recommended-extras)
8. [Verification](#8-verification)
9. [Uninstallation](#9-uninstallation)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Overview

The Vibe Coding Stack installs the following core tools:

| Tool | Purpose |
|------|---------|
| Visual Studio Code | Code editor |
| Git | Version control |
| GitHub CLI (gh) | GitHub operations from the terminal |
| wget | File downloader |
| Python 3.12 | Python programming language |
| Node.js LTS (22) | JavaScript runtime (required for Claude Code) |
| Claude Code | Anthropic's AI coding assistant CLI |

Optional tools:

| Tool | Purpose |
|------|---------|
| fd | Fast file finder (macOS alternative to Everything Search) |
| ImageOptim | Image optimizer |

Recommended extras:

| Tool | Purpose |
|------|---------|
| jq | JSON processor |
| tree | Directory visualization |
| ripgrep | Fast code search (`rg`) |
| fzf | Fuzzy finder |
| httpie | Human-friendly HTTP client |

---

## 2. Prerequisites

- **macOS** (any currently supported version)
- **Terminal access** — use Terminal.app or any terminal emulator
- **Internet connection**

### Apple Silicon vs Intel

Throughout this guide, paths differ based on your Mac's processor:

| | Apple Silicon (M1/M2/M3/M4) | Intel |
|---|---|---|
| Homebrew prefix | `/opt/homebrew` | `/usr/local` |
| Homebrew binary | `/opt/homebrew/bin/brew` | `/usr/local/bin/brew` |

To check which you have:

```bash
uname -m
```

- `arm64` = Apple Silicon
- `x86_64` = Intel

### Fix Git SSH Override for GitHub (if applicable)

If you have Git configured to rewrite HTTPS URLs to SSH, Homebrew's install and update commands will fail with "Permission denied (publickey)." Check and fix this before proceeding:

```bash
# Check for SSH overrides
git config --global --get-all url."git@github.com:".insteadOf
git config --global --get-all url."ssh://git@github.com/".insteadOf
```

If either command returns output (typically `https://github.com/`), remove the overrides:

```bash
git config --global --unset-all url."git@github.com:".insteadOf
git config --global --unset-all url."ssh://git@github.com/".insteadOf
```

---

## 3. Step-by-Step Installation

### 3.1 Install Homebrew

If you don't have Homebrew installed:

```bash
/bin/bash -c "$(curl -fsSL --tlsv1.2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Apple Silicon only** — after installation, add Homebrew to your PATH for the current session:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 3.2 Update Homebrew

```bash
brew update --force
```

This ensures your formula index is up to date. If this fails, see the [Troubleshooting](#10-troubleshooting) section.

### 3.3 Install Visual Studio Code

```bash
brew install --cask visual-studio-code
```

### 3.4 Install Git

```bash
brew install git
```

### 3.5 Install GitHub CLI

```bash
brew install gh
```

### 3.6 Install wget

```bash
brew install wget
```

### 3.7 Install Python 3.12

```bash
brew install python@3.12
```

### 3.8 Install Node.js LTS

```bash
brew install node@22
```

Node.js 22 is a "keg-only" formula, meaning it's not automatically linked into your PATH. You'll configure this in [section 4](#4-environment-configuration), but for now, add it to the current session:

**Apple Silicon:**
```bash
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
```

**Intel:**
```bash
export PATH="/usr/local/opt/node@22/bin:$PATH"
```

---

## 4. Environment Configuration

### 4.1 Determine Your Shell RC File

The configuration file depends on your shell:

| Shell | RC File |
|-------|---------|
| zsh (default on modern macOS) | `~/.zshrc` |
| bash | `~/.bash_profile` |
| other | `~/.profile` |

Check your current shell:

```bash
echo $SHELL
```

Create the file if it doesn't exist:

```bash
touch ~/.zshrc  # or ~/.bash_profile for bash
```

### 4.2 Add Homebrew to PATH (Apple Silicon only)

If you're on Apple Silicon and this line isn't already in your RC file, add it:

```bash
echo '' >> ~/.zshrc
echo '# Homebrew' >> ~/.zshrc
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
```

> **Intel users:** Homebrew installs to `/usr/local`, which is already on the default PATH. No action needed.

### 4.3 Add Python 3.12 to PATH

**Apple Silicon:**
```bash
echo '' >> ~/.zshrc
echo '# Python 3.12' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"' >> ~/.zshrc
```

**Intel:**
```bash
echo '' >> ~/.zshrc
echo '# Python 3.12' >> ~/.zshrc
echo 'export PATH="/usr/local/opt/python@3.12/libexec/bin:$PATH"' >> ~/.zshrc
```

### 4.4 Add Node.js to PATH

**Apple Silicon:**
```bash
echo '' >> ~/.zshrc
echo '# Node.js' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/opt/node@22/bin:$PATH"' >> ~/.zshrc
```

**Intel:**
```bash
echo '' >> ~/.zshrc
echo '# Node.js' >> ~/.zshrc
echo 'export PATH="/usr/local/opt/node@22/bin:$PATH"' >> ~/.zshrc
```

### 4.5 Configure Git

```bash
git config --global init.defaultBranch main
git config --global core.editor "code --wait"
```

### 4.6 Apply Changes

Either restart your terminal or reload the RC file:

```bash
source ~/.zshrc  # or source ~/.bash_profile for bash
```

---

## 5. Claude Code Installation

Claude Code is installed globally via npm (which comes with Node.js):

```bash
npm install -g @anthropic-ai/claude-code
```

After installation, verify it:

```bash
claude --version
```

---

## 6. Optional Packages

These are optional macOS alternatives to the Windows-specific tools in the stack.

### 6.1 fd (fast file finder)

A fast alternative to `find`, serving as a macOS replacement for Everything Search:

```bash
brew install fd
```

### 6.2 ImageOptim

An image optimization tool:

```bash
brew install --cask imageoptim
```

---

## 7. Recommended Extras

These are developer productivity tools that the script offers to install after the core packages. All are installed via Homebrew formulae.

### 7.1 jq — JSON Processor

Parse, filter, and transform JSON from the command line:

```bash
brew install jq
```

### 7.2 tree — Directory Visualization

Display directory structures as tree diagrams:

```bash
brew install tree
```

### 7.3 ripgrep — Fast Code Search

Blazing-fast recursive search (the `rg` command):

```bash
brew install ripgrep
```

### 7.4 fzf — Fuzzy Finder

Interactive fuzzy search for files, history, and more:

```bash
brew install fzf
```

### 7.5 httpie — HTTP Client

A human-friendly HTTP client for the terminal:

```bash
brew install httpie
```

---

## 8. Verification

Restart your terminal (or run `source ~/.zshrc`), then verify all core tools:

```bash
code --version && git --version && gh --version && wget --version && python3 --version && node --version && claude --version
```

All commands should return version numbers without errors.

To verify optional tools:

```bash
fd --version       # if installed
jq --version       # if installed
tree --version     # if installed
rg --version       # if installed (ripgrep)
fzf --version      # if installed
http --version     # if installed (httpie)
```

---

## 9. Uninstallation

To reverse the installation, follow these steps in order.

### 9.1 Uninstall Claude Code (do this first, while npm still exists)

```bash
npm uninstall -g @anthropic-ai/claude-code
```

### 9.2 Uninstall Recommended Extras

```bash
brew uninstall jq
brew uninstall tree
brew uninstall ripgrep
brew uninstall fzf
brew uninstall httpie
```

### 9.3 Uninstall Optional Packages

```bash
brew uninstall --cask imageoptim
brew uninstall fd
```

### 9.4 Uninstall Core Packages

```bash
brew uninstall --cask visual-studio-code
brew uninstall node@22
brew uninstall python@3.12
brew uninstall gh
brew uninstall wget
brew uninstall git
```

### 9.5 Clean Up Shell Configuration

Edit your shell RC file (`~/.zshrc` or `~/.bash_profile`) and remove the following blocks that were added during installation:

```bash
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Python 3.12
export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"

# Node.js
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
```

### 9.6 Remove Git Configuration

```bash
git config --global --unset init.defaultBranch
git config --global --unset core.editor
```

### 9.7 Restart Terminal

Close and reopen all terminal windows to apply changes.

---

## 10. Troubleshooting

### "brew: command not found"

Homebrew is not installed or not in your PATH.

- **Install it:** Follow [section 3.1](#31-install-homebrew)
- **Apple Silicon:** Make sure you've added the Homebrew shellenv line to your RC file ([section 4.2](#42-add-homebrew-to-path-apple-silicon-only))

### "brew update" fails with "Permission denied (publickey)"

Git is configured to rewrite HTTPS URLs to SSH for GitHub. See [section 2: Fix Git SSH Override](#fix-git-ssh-override-for-github-if-applicable).

### Homebrew doesn't recognize your macOS version

If `brew config` shows "unsupported" or "unknown" for your macOS version, Homebrew itself needs to be reinstalled:

```bash
/bin/bash -c "$(curl -fsSL --tlsv1.2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then update:

```bash
brew update --force
```

### Node.js/npm commands not found after installation

Node.js 22 is "keg-only" and not automatically linked. Ensure your PATH includes the Node.js bin directory:

**Apple Silicon:**
```bash
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
```

**Intel:**
```bash
export PATH="/usr/local/opt/node@22/bin:$PATH"
```

Add the appropriate line to your `~/.zshrc` (see [section 4.4](#44-add-nodejs-to-path)).

### Python command not found

Homebrew's Python 3.12 is keg-only. Ensure the `libexec/bin` path is in your PATH (see [section 4.3](#43-add-python-312-to-path)). You can also try:

```bash
python3 --version
```

(Homebrew Python may only be available as `python3` without the PATH configuration.)

### npm install fails for Claude Code

- Ensure Node.js is installed and `npm` is on your PATH: `npm --version`
- Try clearing the npm cache: `npm cache clean --force`
- If you get permission errors, do **not** use `sudo npm install`. Instead, fix npm's directory permissions:
  ```bash
  mkdir -p ~/.npm-global
  npm config set prefix '~/.npm-global'
  echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
  ```

### "code" command not found after installing VS Code

Open VS Code manually, then press `Cmd+Shift+P`, type "shell command", and select **Shell Command: Install 'code' command in PATH**.
