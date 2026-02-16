#!/bin/bash
#
# VibeCodingStack.sh - Install/Uninstall Vibe Coding Stack for macOS
# Version: 3.0.0
#
# Usage:
#   ./VibeCodingStack.sh              # Install
#   ./VibeCodingStack.sh --uninstall  # Uninstall
#   ./VibeCodingStack.sh --whatif     # Preview (no changes)
#   ./VibeCodingStack.sh --help       # Show help
#

set -uo pipefail
# Note: Not using 'set -e' to allow graceful error handling

# =============================================================================
# Configuration
# =============================================================================

VERSION="3.0.0"
SCRIPT_NAME="VibeCodingStack"

# Core packages (Homebrew)
declare -a CORE_FORMULAE=("git" "gh" "wget" "python@3.12" "node@22")
declare -a CORE_CASKS=("visual-studio-code")

# Optional packages (Mac alternatives to Windows tools)
declare -a OPTIONAL_FORMULAE=("fd")  # Fast file finder (Everything alternative)
declare -a OPTIONAL_CASKS=("imageoptim")  # Image optimizer (IrfanView alternative)

# Claude Code npm package
CLAUDE_CODE_PACKAGE="@anthropic-ai/claude-code"

# Flags
UNINSTALL=false
WHATIF=false
FORCE=false
SKIP_OPTIONAL=false
KEEP_PYTHON=false
KEEP_NODE=false
KEEP_GIT=false
LOG_FILE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Results tracking
declare -a SUCCESSFUL=()
declare -a FAILED=()
declare -a SKIPPED=()
declare -a NOT_FOUND=()

# =============================================================================
# Logging
# =============================================================================

start_audit_log() {
    local timestamp=$(date +"%Y-%m-%d_%H%M%S")
    local mode="Install"
    [[ "$UNINSTALL" == true ]] && mode="Uninstall"
    
    LOG_FILE="${SCRIPT_NAME}_${mode}_${timestamp}.log"
    
    exec > >(tee -a "$LOG_FILE") 2>&1
    
    local color="$CYAN"
    local mode_text="INSTALLER"
    if [[ "$UNINSTALL" == true ]]; then
        color="$BLUE"
        mode_text="UNINSTALLER"
    fi
    
    echo ""
    echo -e "${color}======================================================================${NC}"
    echo -e "${color}  VIBE CODING STACK ${mode_text} (macOS)${NC}"
    echo -e "${color}  Version: ${VERSION}${NC}"
    echo -e "${color}======================================================================${NC}"
    echo ""
    
    log_event "START" "${mode} initiated by $(whoami) on $(hostname)"
}

log_event() {
    local event_type="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${GRAY}[${timestamp}] [${event_type}] ${message}${NC}"
}

# =============================================================================
# Output Functions
# =============================================================================

write_header() {
    local message="$1"
    local color="$MAGENTA"
    [[ "$UNINSTALL" == true ]] && color="$BLUE"
    
    echo ""
    echo -e "${color}============================================================${NC}"
    echo -e "${color}  ${message}${NC}"
    echo -e "${color}============================================================${NC}"
    echo ""
}

write_step() {
    echo -e "${CYAN}[*] $1${NC}"
    log_event "STEP" "$1"
}

write_success() {
    echo -e "${GREEN}[+] $1${NC}"
    log_event "SUCCESS" "$1"
}

write_warn() {
    echo -e "${YELLOW}[!] $1${NC}"
    log_event "WARNING" "$1"
}

write_err() {
    echo -e "${RED}[-] $1${NC}"
    log_event "ERROR" "$1"
}

# =============================================================================
# Helper Functions
# =============================================================================

command_exists() {
    command -v "$1" &> /dev/null
}

brew_formula_installed() {
    brew list --formula "$1" &> /dev/null
}

brew_cask_installed() {
    brew list --cask "$1" &> /dev/null
}

npm_package_installed() {
    npm list -g "$1" &> /dev/null 2>&1
}

# =============================================================================
# Prerequisites
# =============================================================================

check_prerequisites() {
    write_header "Checking Prerequisites"

    # Check macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        write_err "This script requires macOS"
        return 1
    fi
    write_success "macOS $(sw_vers -productVersion)"

    # Fix git SSH override for GitHub
    # If git is configured to rewrite HTTPS URLs to SSH, Homebrew install
    # and brew update will fail with "Permission denied (publickey)" because
    # they expect anonymous HTTPS access to github.com.
    if command_exists git; then
        local ssh_override
        ssh_override=$(git config --global --get-all url."git@github.com:".insteadOf 2>/dev/null || true)
        local ssh_override2
        ssh_override2=$(git config --global --get-all url."ssh://git@github.com/".insteadOf 2>/dev/null || true)

        if [[ -n "$ssh_override" || -n "$ssh_override2" ]]; then
            write_warn "Git is configured to force SSH for GitHub (blocks Homebrew)"
            if [[ "$WHATIF" == true ]]; then
                write_warn "WHATIF: Would remove git SSH-over-HTTPS overrides"
            else
                git config --global --unset-all url."git@github.com:".insteadOf 2>/dev/null || true
                git config --global --unset-all url."ssh://git@github.com/".insteadOf 2>/dev/null || true
                write_success "Removed git SSH-over-HTTPS overrides for GitHub"
            fi
        fi
    fi

    # Check/Install Homebrew
    if ! command_exists brew; then
        write_warn "Homebrew not found. Installing..."
        
        if [[ "$WHATIF" == true ]]; then
            write_warn "WHATIF: Would install Homebrew"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
                write_err "Failed to install Homebrew"
                return 1
            }
            
            # Add to PATH for Apple Silicon
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi
    fi
    write_success "Homebrew available"
    
    # Self-healing Homebrew upgrade
    # An outdated Homebrew won't recognize newer macOS versions (e.g. Sequoia)
    # or modern formula syntax (e.g. no_autobump!). We must upgrade the
    # Homebrew binary itself, not just the formula index.
    write_step "Checking Homebrew version..."
    if [[ "$WHATIF" == false ]]; then
        local brew_ok=false

        # Step 1: Update formula index (output streamed live so user sees progress)
        write_step "Updating Homebrew formula index (this may take a minute)..."
        if brew update --force 2>&1; then
            write_success "Homebrew formula index updated"
        else
            write_warn "brew update failed (exit $?), will attempt deeper fix..."
        fi

        # Step 2: Upgrade only Homebrew's own infrastructure
        # 'brew update' fetches the latest formula/cask definitions.
        # We do NOT run 'brew upgrade' here — that upgrades every installed
        # package on the system which can take a very long time.
        # Instead, check if Homebrew recognizes the current macOS.
        write_step "Verifying Homebrew compatibility..."
        local config_output
        config_output=$(brew config 2>&1 || true)
        local homebrew_ver
        homebrew_ver=$(echo "$config_output" | grep "Homebrew/homebrew-core" || echo "unknown")
        write_step "Homebrew core: ${homebrew_ver}"

        local macos_check
        macos_check=$(echo "$config_output" | grep -i "macOS:" || true)
        if echo "$macos_check" | grep -qi "unsupported\|unknown"; then
            # macOS not recognized — need a full Homebrew reinstall
            write_warn "Homebrew does not recognize this macOS version: $macos_check"
            write_step "Reinstalling Homebrew from scratch (output streamed live)..."
            if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1; then
                # Re-add to PATH for Apple Silicon
                if [[ -f "/opt/homebrew/bin/brew" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
                write_step "Running post-reinstall update..."
                brew update --force 2>&1 || true
                brew_ok=true
                write_success "Homebrew reinstalled"
            else
                write_err "Homebrew reinstall failed"
            fi
        else
            brew_ok=true
            write_success "Homebrew recognizes macOS: $macos_check"
        fi

        if [[ "$brew_ok" == true ]]; then
            write_success "Homebrew ready"
        else
            write_warn "Homebrew may not work correctly. Continuing anyway..."
            write_warn "Try manually: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        fi
    else
        write_warn "WHATIF: Would update and upgrade Homebrew"
    fi

    return 0
}

# =============================================================================
# Install Functions
# =============================================================================

install_formula() {
    local formula="$1"
    local display_name="$2"
    
    write_step "Installing ${display_name}..."
    
    if brew_formula_installed "$formula"; then
        write_success "${display_name} already installed"
        SKIPPED+=("$display_name")
        return 0
    fi
    
    if [[ "$WHATIF" == true ]]; then
        write_warn "WHATIF: Would install ${display_name}"
        SKIPPED+=("$display_name")
        return 0
    fi
    
    log_event "COMMAND" "brew install ${formula}"
    
    # Capture output, suppress noise
    local output
    if output=$(brew install "$formula" 2>&1); then
        write_success "${display_name} installed"
        SUCCESSFUL+=("$display_name")
        return 0
    else
        write_err "${display_name} failed: ${output}"
        FAILED+=("$display_name")
        return 1
    fi
}

install_cask() {
    local cask="$1"
    local display_name="$2"
    
    write_step "Installing ${display_name}..."
    
    if brew_cask_installed "$cask"; then
        write_success "${display_name} already installed"
        SKIPPED+=("$display_name")
        return 0
    fi
    
    if [[ "$WHATIF" == true ]]; then
        write_warn "WHATIF: Would install ${display_name}"
        SKIPPED+=("$display_name")
        return 0
    fi
    
    log_event "COMMAND" "brew install --cask ${cask}"
    
    # Capture output, suppress noise
    local output
    if output=$(brew install --cask "$cask" 2>&1); then
        write_success "${display_name} installed"
        SUCCESSFUL+=("$display_name")
        return 0
    else
        write_err "${display_name} failed: ${output}"
        FAILED+=("$display_name")
        return 1
    fi
}

install_claude_code() {
    write_header "Installing Claude Code CLI"
    
    if ! command_exists npm; then
        write_err "npm not available. Install Node.js first."
        FAILED+=("Claude Code")
        return 1
    fi
    
    if [[ "$WHATIF" == true ]]; then
        write_warn "WHATIF: Would install Claude Code"
        SKIPPED+=("Claude Code")
        return 0
    fi
    
    write_step "Installing Claude Code via npm..."
    log_event "COMMAND" "npm install -g ${CLAUDE_CODE_PACKAGE}"
    
    local output
    if output=$(npm install -g "$CLAUDE_CODE_PACKAGE" 2>&1); then
        write_success "Claude Code installed"
        SUCCESSFUL+=("Claude Code")
        return 0
    else
        write_err "Claude Code failed: ${output}"
        FAILED+=("Claude Code")
        return 1
    fi
}

# =============================================================================
# Uninstall Functions
# =============================================================================

uninstall_formula() {
    local formula="$1"
    local display_name="$2"
    
    write_step "Checking ${display_name}..."
    
    if ! brew_formula_installed "$formula"; then
        write_warn "${display_name} not installed"
        NOT_FOUND+=("$display_name")
        return 0
    fi
    
    write_step "Uninstalling ${display_name}..."
    
    if [[ "$WHATIF" == true ]]; then
        write_warn "WHATIF: Would uninstall ${display_name}"
        SKIPPED+=("$display_name")
        return 0
    fi
    
    log_event "COMMAND" "brew uninstall ${formula}"
    
    local output
    if output=$(brew uninstall "$formula" 2>&1); then
        write_success "${display_name} uninstalled"
        SUCCESSFUL+=("$display_name")
        return 0
    else
        write_err "${display_name} failed: ${output}"
        FAILED+=("$display_name")
        return 1
    fi
}

uninstall_cask() {
    local cask="$1"
    local display_name="$2"
    
    write_step "Checking ${display_name}..."
    
    if ! brew_cask_installed "$cask"; then
        write_warn "${display_name} not installed"
        NOT_FOUND+=("$display_name")
        return 0
    fi
    
    write_step "Uninstalling ${display_name}..."
    
    if [[ "$WHATIF" == true ]]; then
        write_warn "WHATIF: Would uninstall ${display_name}"
        SKIPPED+=("$display_name")
        return 0
    fi
    
    log_event "COMMAND" "brew uninstall --cask ${cask}"
    
    local output
    if output=$(brew uninstall --cask "$cask" 2>&1); then
        write_success "${display_name} uninstalled"
        SUCCESSFUL+=("$display_name")
        return 0
    else
        write_err "${display_name} failed: ${output}"
        FAILED+=("$display_name")
        return 1
    fi
}

uninstall_claude_code() {
    write_header "Uninstalling Claude Code CLI"
    
    if ! command_exists npm; then
        write_warn "npm not available - skipping Claude Code"
        SKIPPED+=("Claude Code")
        return 0
    fi
    
    if ! npm_package_installed "$CLAUDE_CODE_PACKAGE"; then
        write_warn "Claude Code not installed"
        NOT_FOUND+=("Claude Code")
        return 0
    fi
    
    if [[ "$WHATIF" == true ]]; then
        write_warn "WHATIF: Would uninstall Claude Code"
        SKIPPED+=("Claude Code")
        return 0
    fi
    
    write_step "Uninstalling Claude Code..."
    log_event "COMMAND" "npm uninstall -g ${CLAUDE_CODE_PACKAGE}"
    
    if npm uninstall -g "$CLAUDE_CODE_PACKAGE" 2>&1; then
        write_success "Claude Code uninstalled"
        SUCCESSFUL+=("Claude Code")
        return 0
    else
        write_warn "Claude Code removal had issues"
        FAILED+=("Claude Code")
        return 1
    fi
}

# =============================================================================
# Post-Install Configuration
# =============================================================================

configure_environment() {
    write_header "Configuring Environment"
    
    if [[ "$WHATIF" == true ]]; then
        write_warn "WHATIF: Would configure shell environment"
        return 0
    fi
    
    # Detect shell
    local shell_rc=""
    case "$SHELL" in
        */zsh)  shell_rc="$HOME/.zshrc" ;;
        */bash) shell_rc="$HOME/.bash_profile" ;;
        *)      shell_rc="$HOME/.profile" ;;
    esac
    
    write_step "Configuring ${shell_rc}..."
    
    # Create file if it doesn't exist
    touch "$shell_rc" 2>/dev/null || true
    
    # Ensure Homebrew is in PATH (Apple Silicon)
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$shell_rc" 2>/dev/null; then
            echo '' >> "$shell_rc"
            echo '# Homebrew' >> "$shell_rc"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$shell_rc"
            write_success "Added Homebrew to PATH"
        fi
    fi
    
    # Add Python 3.12 to PATH
    local python_path="/opt/homebrew/opt/python@3.12/libexec/bin"
    [[ ! -d "$python_path" ]] && python_path="/usr/local/opt/python@3.12/libexec/bin"
    
    if [[ -d "$python_path" ]] && ! grep -q "$python_path" "$shell_rc" 2>/dev/null; then
        echo '' >> "$shell_rc"
        echo '# Python 3.12' >> "$shell_rc"
        echo "export PATH=\"${python_path}:\$PATH\"" >> "$shell_rc"
        write_success "Added Python 3.12 to PATH"
    fi
    
    # Add Node to PATH
    local node_path="/opt/homebrew/opt/node@22/bin"
    [[ ! -d "$node_path" ]] && node_path="/usr/local/opt/node@22/bin"
    
    if [[ -d "$node_path" ]] && ! grep -q "$node_path" "$shell_rc" 2>/dev/null; then
        echo '' >> "$shell_rc"
        echo '# Node.js' >> "$shell_rc"
        echo "export PATH=\"${node_path}:\$PATH\"" >> "$shell_rc"
        write_success "Added Node.js to PATH"
    fi
    
    # Configure Git defaults
    if command_exists git; then
        write_step "Configuring Git..."
        git config --global init.defaultBranch main 2>/dev/null || true
        git config --global core.editor "code --wait" 2>/dev/null || true
        write_success "Git configured"
    fi
    
    write_success "Environment configured"
    write_warn "Run 'source ${shell_rc}' or restart terminal to apply changes"
}

# =============================================================================
# Summary & Confirmation
# =============================================================================

show_plan() {
    local action="INSTALLED"
    local color="$CYAN"
    
    if [[ "$UNINSTALL" == true ]]; then
        action="REMOVED"
        color="$BLUE"
    fi
    
    write_header "$(if [[ "$UNINSTALL" == true ]]; then echo 'Uninstallation'; else echo 'Installation'; fi) Plan"
    
    echo -e "${color}The following will be ${action}:${NC}"
    echo ""
    
    echo -e "${YELLOW}  Core:${NC}"
    
    if [[ "$UNINSTALL" == true && "$KEEP_GIT" == true ]]; then
        echo -e "${GRAY}    - Git [KEEPING]${NC}"
    else
        echo "    - Git"
    fi

    echo "    - GitHub CLI (gh)"
    echo "    - wget"

    if [[ "$UNINSTALL" == true && "$KEEP_PYTHON" == true ]]; then
        echo -e "${GRAY}    - Python 3.12 [KEEPING]${NC}"
    else
        echo "    - Python 3.12"
    fi
    
    if [[ "$UNINSTALL" == true && "$KEEP_NODE" == true ]]; then
        echo -e "${GRAY}    - Node.js [KEEPING]${NC}"
    else
        echo "    - Node.js"
    fi
    
    echo "    - Visual Studio Code"
    echo "    - Claude Code (npm)"
    
    if [[ "$SKIP_OPTIONAL" == false ]]; then
        echo ""
        echo -e "${YELLOW}  Optional (Mac alternatives):${NC}"
        echo "    - fd (fast file finder - Everything alternative)"
        echo "    - ImageOptim (image optimizer - IrfanView alternative)"
    fi
    
    echo ""
    echo -e "${YELLOW}  Note: Windows-only tools not available:${NC}"
    echo -e "${GRAY}    - Everything (Void Tools) - use 'fd' or Spotlight instead${NC}"
    echo -e "${GRAY}    - IrfanView - use Preview or ImageOptim instead${NC}"
    echo ""
    
    if [[ "$WHATIF" == true ]]; then
        write_warn "WHATIF MODE - No changes will be made"
        return 0
    fi
    
    if [[ "$FORCE" == false ]]; then
        if [[ "$UNINSTALL" == true ]]; then
            echo -n "Type 'YES' to confirm uninstall: "
            read -r response
            if [[ "$response" != "YES" ]]; then
                write_warn "Cancelled by user"
                return 1
            fi
        else
            echo -n "Proceed? (Y/N): "
            read -r response
            if [[ ! "$response" =~ ^[Yy] ]]; then
                write_warn "Cancelled by user"
                return 1
            fi
        fi
    fi
    
    return 0
}

show_summary() {
    write_header "Summary"
    
    if [[ ${#SUCCESSFUL[@]} -gt 0 ]]; then
        echo -e "${GREEN}Successful:${NC}"
        for item in "${SUCCESSFUL[@]}"; do
            echo -e "${GREEN}  + ${item}${NC}"
        done
    fi
    
    if [[ ${#SKIPPED[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Skipped:${NC}"
        for item in "${SKIPPED[@]}"; do
            echo -e "${YELLOW}  - ${item}${NC}"
        done
    fi
    
    if [[ ${#NOT_FOUND[@]} -gt 0 ]]; then
        echo -e "${GRAY}Not Found:${NC}"
        for item in "${NOT_FOUND[@]}"; do
            echo -e "${GRAY}  . ${item}${NC}"
        done
    fi
    
    if [[ ${#FAILED[@]} -gt 0 ]]; then
        echo -e "${RED}Failed:${NC}"
        for item in "${FAILED[@]}"; do
            echo -e "${RED}  x ${item}${NC}"
        done
    fi
    
    echo ""
    
    if [[ "$WHATIF" == false && ${#SUCCESSFUL[@]} -gt 0 ]]; then
        echo -e "${CYAN}NEXT: Restart terminal or run 'source ~/.zshrc'${NC}"
        
        if [[ "$UNINSTALL" == false ]]; then
            echo ""
            echo -e "${CYAN}Verify:${NC}"
            echo "  code --version && git --version && gh --version && wget --version && python3 --version && node --version && claude --version"
        fi
    fi
    
    echo ""
    echo -e "${GRAY}Audit log: ${LOG_FILE}${NC}"
}

# =============================================================================
# Main Operations
# =============================================================================

do_install() {
    write_header "Installing Core Packages"
    
    # Casks
    install_cask "visual-studio-code" "Visual Studio Code" || true
    
    # Formulae
    install_formula "git" "Git" || true
    install_formula "gh" "GitHub CLI" || true
    install_formula "wget" "wget" || true
    install_formula "python@3.12" "Python 3.12" || true
    install_formula "node@22" "Node.js LTS" || true
    
    # Optional
    if [[ "$SKIP_OPTIONAL" == false ]]; then
        write_header "Installing Optional Packages"
        install_formula "fd" "fd (file finder)" || true
        install_cask "imageoptim" "ImageOptim" || true
    else
        write_warn "Skipping optional packages"
    fi
    
    # Claude Code
    install_claude_code || true
    
    # Configure
    configure_environment || true
}

do_uninstall() {
    # Uninstall Claude Code first while npm exists
    if [[ "$KEEP_NODE" == false ]]; then
        uninstall_claude_code || true
    else
        write_warn "Keeping Claude Code (--keep-node)"
        SKIPPED+=("Claude Code")
    fi
    
    # Optional
    if [[ "$SKIP_OPTIONAL" == false ]]; then
        write_header "Uninstalling Optional Packages"
        uninstall_cask "imageoptim" "ImageOptim" || true
        uninstall_formula "fd" "fd (file finder)" || true
    fi
    
    # Core
    write_header "Uninstalling Core Packages"
    
    uninstall_cask "visual-studio-code" "Visual Studio Code" || true
    
    if [[ "$KEEP_NODE" == true ]]; then
        write_warn "Keeping Node.js"
        SKIPPED+=("Node.js LTS")
    else
        uninstall_formula "node@22" "Node.js LTS" || true
    fi
    
    if [[ "$KEEP_PYTHON" == true ]]; then
        write_warn "Keeping Python"
        SKIPPED+=("Python 3.12")
    else
        uninstall_formula "python@3.12" "Python 3.12" || true
    fi
    
    uninstall_formula "gh" "GitHub CLI" || true
    uninstall_formula "wget" "wget" || true

    if [[ "$KEEP_GIT" == true ]]; then
        write_warn "Keeping Git"
        SKIPPED+=("Git")
    else
        uninstall_formula "git" "Git" || true
    fi
}

# =============================================================================
# Help
# =============================================================================

show_help() {
    cat << EOF
VibeCodingStack.sh - Install/Uninstall Vibe Coding Stack for macOS
Version: ${VERSION}

USAGE:
    ./VibeCodingStack.sh [OPTIONS]

OPTIONS:
    --uninstall      Uninstall mode (default is install)
    --whatif         Preview changes without executing
    --force          Skip confirmation prompts
    --skip-optional  Skip optional packages (fd, ImageOptim)
    --keep-git       (Uninstall) Keep Git installed
    --keep-python    (Uninstall) Keep Python installed
    --keep-node      (Uninstall) Keep Node.js and Claude Code installed
    --help           Show this help message

EXAMPLES:
    ./VibeCodingStack.sh                           # Install all
    ./VibeCodingStack.sh --skip-optional           # Install core only
    ./VibeCodingStack.sh --whatif                  # Preview install
    ./VibeCodingStack.sh --uninstall               # Uninstall all
    ./VibeCodingStack.sh --uninstall --keep-git    # Uninstall but keep Git

PACKAGES:
    Core:
      - Visual Studio Code
      - Git
      - GitHub CLI (gh)
      - wget
      - Python 3.12
      - Node.js LTS
      - Claude Code

    Optional (Mac alternatives):
      - fd (fast file finder - replaces Everything)
      - ImageOptim (image optimizer - replaces IrfanView)

EOF
    exit 0
}

# =============================================================================
# Argument Parsing
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --whatif)
                WHATIF=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --skip-optional)
                SKIP_OPTIONAL=true
                shift
                ;;
            --keep-git)
                KEEP_GIT=true
                shift
                ;;
            --keep-python)
                KEEP_PYTHON=true
                shift
                ;;
            --keep-node)
                KEEP_NODE=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                write_err "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Main
# =============================================================================

main() {
    parse_args "$@"
    
    start_audit_log
    
    if ! check_prerequisites; then
        write_err "Prerequisites check failed"
        exit 1
    fi
    
    if ! show_plan; then
        exit 0
    fi
    
    if [[ "$UNINSTALL" == true ]]; then
        do_uninstall
    else
        do_install
    fi
    
    show_summary
    
    if [[ ${#FAILED[@]} -gt 0 ]]; then
        exit 1
    fi
    
    exit 0
}

main "$@"