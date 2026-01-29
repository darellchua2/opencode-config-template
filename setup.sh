#!/bin/bash

################################################################################
# OpenCode Configuration Setup Script
#
# Copyright 2026 OpenCode Configuration Template Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################
#
# Description: Automated setup for OpenCode configuration with proper error
#              handling, logging, and user experience enhancements.
#
# Usage: ./setup.sh [OPTIONS]
#
# Options:
#   -h, --help          Show this help message
#   -q, --quick         Quick setup (copy config.json and skills only)
#   -s, --skills-only    Skills-only setup (copy skills folder only, validate OpenCode installed)
#   -d, --dry-run       Show what would be done without making changes
#   -y, --yes           Auto-accept all prompts (use with caution)
#   -v, --verbose       Enable verbose output
#   -u, --update        Update OpenCode CLI only
#
################################################################################

# Strict error handling
set -o pipefail  # Catch errors in pipes
set -o nounset   # Error on undefined variables
# Note: We don't use 'set -e' because we want custom error handling

################################################################################
# GLOBAL VARIABLES
################################################################################

# Read version from VERSION file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${SCRIPT_DIR}/VERSION"
if [ -f "$VERSION_FILE" ]; then
    SCRIPT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    SCRIPT_VERSION="2.0.0"
    log_warn "VERSION file not found, using default: ${SCRIPT_VERSION}"
fi

# This is a configuration template repository (no package.json required)
LOG_FILE="${HOME}/.opencode-setup.log"
CONFIG_DIR="${HOME}/.config/opencode"
CONFIG_FILE="${CONFIG_DIR}/config.json"
SKILLS_DIR="${CONFIG_DIR}/skills"
BACKUP_DIR="${HOME}/.opencode-backup-$(date +%Y%m%d_%H%M%S)"

################################################################################
# PLATFORM AND SHELL DETECTION
################################################################################

# Detect operating system
detect_platform() {
    case "$(uname -s)" in
        Darwin)
            echo "macOS"
            ;;
        Linux*)
            echo "Linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

DETECTED_OS=$(detect_platform)
OS_VERSION=$(sw_vers 2>/dev/null || uname -r)

# Detect shell (bash, zsh, or powershell)
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$PSVersionTable" ]; then
        echo "powershell"
    else
        # Fallback: check $0
        case "$0" in
            *zsh*)
                echo "zsh"
                ;;
            *bash*)
                echo "bash"
                ;;
            *)
                echo "bash"
                ;;
        esac
    fi
}

DETECTED_SHELL=$(detect_shell)

# Determine shell config file based on OS and shell
determine_shell_config() {
    local shell="$1"
    local os="$2"

    case "${os}:${shell}" in
        macOS:zsh)
            echo "${HOME}/.zshrc"
            ;;
        macOS:bash)
            if [ -f "${HOME}/.bash_profile" ]; then
                echo "${HOME}/.bash_profile"
            else
                echo "${HOME}/.bashrc"
            fi
            ;;
        Linux:bash|Linux:*)
            echo "${HOME}/.bashrc"
            ;;
        Windows:powershell)
            echo "${PROFILE}"
            ;;
        *)
            # Default to bashrc
            echo "${HOME}/.bashrc"
            ;;
    esac
}

SHELL_CONFIG_FILE=$(determine_shell_config "$DETECTED_SHELL" "$DETECTED_OS")

# Flags
QUICK_SETUP=false
SKILLS_ONLY=false
DRY_RUN=false
AUTO_ACCEPT=false
VERBOSE=false
SKIP_CONFIG_COPY=false
UPDATE_ONLY=false

# API Keys (initialize to empty to avoid unbound variable errors)
# Capture from environment if they exist
GITHUB_PAT="${GITHUB_PAT:-}"
ZAI_API_KEY="${ZAI_API_KEY:-}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

################################################################################
# LOGGING FUNCTIONS
################################################################################

# Initialize logging
init_logging() {
    local log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir" 2>/dev/null || true

    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE" 2>/dev/null || true
    fi

    log "INFO" "=== OpenCode Setup Started at $(date) ==="
    log "INFO" "Script version: ${SCRIPT_VERSION}"
    log "INFO" "User: ${USER}"
    log "INFO" "Working directory: ${PWD}"
}

# Log message with level
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log to file
    if [ -w "$LOG_FILE" ] 2>/dev/null; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    fi

    # Print to stderr for errors, stdout for everything else
    if [ "$level" = "ERROR" ]; then
        echo -e "${RED}[${level}]${NC} ${message}" >&2
    elif [ "$level" = "WARNING" ]; then
        echo -e "${YELLOW}[${level}]${NC} ${message}"
    elif [ "$level" = "SUCCESS" ]; then
        echo -e "${GREEN}[${level}]${NC} ${message}"
    elif [ "$VERBOSE" = true ] || [ "$level" != "DEBUG" ]; then
        echo "[${level}] ${message}"
    fi
}

log_debug() { log "DEBUG" "$@"; }
log_info() { log "INFO" "$@"; }
log_warn() { log "WARNING" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

################################################################################
# ERROR HANDLING
################################################################################

# Global error handler
error_handler() {
    local line_number=$1
    local error_code=$2
    log_error "Script failed at line ${line_number} with exit code ${error_code}"
    log_error "Check ${LOG_FILE} for details"

    # Suggest recovery actions
    echo ""
    echo "=== Recovery Suggestions ==="
    echo "1. Check the log file: ${LOG_FILE}"
    echo "2. Restore from backup: ${BACKUP_DIR}"
    echo "3. Try running with --verbose flag for more details"
    echo "4. Check network connectivity and try again"
    echo ""

    cleanup_on_error
    exit 1
}

# Cleanup on error
cleanup_on_error() {
    log_warn "Performing cleanup..."

    # Remove partial installations
    if [ -d "${BACKUP_DIR}" ]; then
        log_info "Backup preserved at: ${BACKUP_DIR}"
    fi
}

# Trap errors
trap 'error_handler ${LINENO} $?' ERR

# Trap interruption
trap 'echo ""; log_warn "Setup interrupted by user"; exit 130' INT

################################################################################
# UTILITY FUNCTIONS
################################################################################

# Show usage information
show_help() {
    cat << EOF
OpenCode Configuration Setup Script v${SCRIPT_VERSION}

USAGE:
    ./setup.sh [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -q, --quick         Quick setup (copy config.json and skills only)
    -s, --skills-only    Skills-only setup (copy skills folder only, validate OpenCode installed)
    -d, --dry-run       Show what would be done without making changes
    -y, --yes           Auto-accept all prompts (use with caution)
    -v, --verbose       Enable verbose output
    -u, --update        Update OpenCode CLI only

EXAMPLES:
    ./setup.sh              # Interactive full setup
    ./setup.sh --quick      # Quick setup (config and skills only)
    ./setup.sh --skills-only # Skills-only setup (copy skills only)
    ./setup.sh --dry-run    # Preview changes
    ./setup.sh -y -q        # Quick setup with auto-accept
    ./setup.sh --update     # Update OpenCode CLI only

 PLATFORM SUPPORT:
   macOS:
     - Shells: zsh (default), bash
     - Config: ~/.zshrc (zsh), ~/.bash_profile (bash)
     - Package Manager: Homebrew
     - Tested: Intel and Apple Silicon

   Linux:
     - Shells: bash, zsh
     - Config: ~/.bashrc
     - Package Managers: apt (Ubuntu/Debian), dnf (Fedora), pacman (Arch)
     - Tested: Ubuntu, Debian, Fedora, Arch

   Windows:
     - Shells: PowerShell, Git Bash, WSL2
     - Config: $PROFILE (PowerShell), ~/.bashrc (Git Bash/WSL2)
     - Package Managers: winget, chocolatey
     - Tested: PowerShell, Git Bash, WSL2

 CONFIGURED FEATURES:
  Agents (4):
    - build-with-skills (default): Skill-aware coding agent that identifies and uses appropriate skills
      Automatically ensures best practices: testing, linting, PR workflows, JIRA integration
    - explore: Codebase exploration and analysis
    - image-analyzer: Image/screenshot analysis (UI to code, OCR, error diagnosis)
    - diagram-creator: Draw.io diagram creation (architecture, flowcharts, UML)

  MCP Servers (6):
    - atlassian: JIRA and Confluence integration (auto-start with npx)
    - drawio: Draw.io MCP server (requires local instance on port 41033)
    - web-reader: Web page reading (requires ZAI_API_KEY)
    - web-search-prime: Web search (requires ZAI_API_KEY)
    - zai-mcp-server: Image analysis and video processing (auto-start with npx)
    - zread: GitHub repo search and file reading (requires ZAI_API_KEY)

   Skills (27):
    Framework (5): test-generator-framework, jira-git-integration, pr-creation-workflow, ticket-branch-workflow, linting-workflow
    Language-Specific (3): python-pytest-creator, python-ruff-linter, javascript-eslint-linter
    Framework-Specific (4): nextjs-pr-workflow, nextjs-unit-test-creator, nextjs-standard-setup, typescript-dry-principle
    OpenCode Meta (3): opencode-agent-creation, opencode-skill-creation, opencode-skill-auditor
    OpenTofu (6): opentofu-aws-explorer, opentofu-keycloak-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-provider-setup, opentofu-provisioning-workflow
    Git/Workflow (3): ascii-diagram-creator, git-issue-creator, git-pr-creator
    Documentation (2): coverage-readme-workflow, docstring-generator
    JIRA (1): jira-git-workflow

   Run 'opencode --list-skills' for detailed descriptions

REQUIREMENTS:
  - Node.js v20+ (required for Draw.io MCP server)
  - LM Studio running on http://127.0.0.1:1234/v1
  - ZAI_API_KEY (for web-reader, web-search-prime, zread MCP servers)
  - Draw.io MCP server instance on http://localhost:41033/mcp (optional)

For more information, visit: https://opencode.ai

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -q|--quick)
                QUICK_SETUP=true
                shift
                ;;
            -s|--skills-only)
                SKILLS_ONLY=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                log_warn "Dry-run mode enabled - no changes will be made"
                shift
                ;;
            -y|--yes)
                AUTO_ACCEPT=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -u|--update)
                UPDATE_ONLY=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Safe execution with dry-run support
run_cmd() {
    local cmd="$*"
    log_debug "Executing: ${cmd}"

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would execute: ${cmd}"
        return 0
    fi

    eval "$cmd"
}

# Prompt user with default
prompt_user() {
    local prompt_message="$1"
    local default_value="${2:-}"
    local result

    if [ "$AUTO_ACCEPT" = true ] && [ -n "$default_value" ]; then
        log_debug "Auto-accepting with default: ${default_value}"
        echo "$default_value"
        return 0
    fi

    if [ -n "$default_value" ]; then
        read -p "${prompt_message} [${default_value}]: " result
        echo "${result:-$default_value}"
    else
        read -p "${prompt_message}: " result
        echo "$result"
    fi
}

# Prompt yes/no with default
prompt_yes_no() {
    local prompt_message="$1"
    local default_value="${2:-n}"
    local result

    if [ "$AUTO_ACCEPT" = true ]; then
        result="$default_value"
    else
        read -p "${prompt_message} [${default_value}]: " result
        result="${result:-$default_value}"
    fi

    [[ "$result" =~ ^[Yy]$ ]]
}

# Create backup of existing files
create_backup() {
    local file_to_backup="$1"
    local backup_path="${BACKUP_DIR}/$(basename ${file_to_backup})"

    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: ${BACKUP_DIR}"
    fi

    if [ -f "$file_to_backup" ]; then
        run_cmd "cp ${file_to_backup} ${backup_path}"
        log_info "Backed up: ${file_to_backup} -> ${backup_path}"
    fi
}

################################################################################
# VALIDATION FUNCTIONS
################################################################################

# Validate API key format
validate_api_key() {
    local key="$1"
    local key_name="$2"

    if [ -z "$key" ]; then
        log_warn "No ${key_name} provided"
        return 1
    fi

    # Basic validation - adjust regex as needed
    if [ ${#key} -lt 10 ]; then
        log_warn "${key_name} seems too short (minimum 10 characters)"
        return 1
    fi

    return 0
}

# Validate network connectivity
check_network() {
    log_info "Checking network connectivity..."

    local test_urls=("https://api.github.com" "https://registry.npmjs.org")
    local connectivity_ok=true

    for url in "${test_urls[@]}"; do
        if curl -s --head --connect-timeout 5 "$url" > /dev/null 2>&1; then
            log_debug "Connected to: ${url}"
        else
            log_warn "Cannot reach: ${url}"
            connectivity_ok=false
        fi
    done

    if [ "$connectivity_ok" = false ]; then
        log_error "Network connectivity issues detected"
        return 1
    fi

    log_success "Network connectivity OK"
    return 0
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    log_info "Checking basic dependencies..."

    local missing_deps=()

    # Check for curl
    if ! command_exists curl; then
        missing_deps+=("curl")
    fi

    # Check for git (optional but recommended)
    if ! command_exists git; then
        log_warn "git is not installed (recommended but not required)"
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install missing dependencies and try again"
        return 1
    fi

    log_success "All required dependencies are installed"
    return 0
}

# Safe file download with retry
download_file() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if curl -fsSL --connect-timeout 10 --max-time 30 "$url" -o "$output" 2>/dev/null; then
            return 0
        fi

        retry_count=$((retry_count + 1))
        log_warn "Download failed (attempt ${retry_count}/${max_retries}): ${url}"

        if [ $retry_count -lt $max_retries ]; then
            local wait_time=$((retry_count * 2))
            log_info "Waiting ${wait_time}s before retry..."
            sleep $wait_time
        fi
    done

    log_error "Failed to download after ${max_retries} attempts: ${url}"
    return 1
}

################################################################################
# PROGRESS INDICATORS
################################################################################

# Show spinning progress
show_progress() {
    local message="$1"
    local pid=$2
    local delay=0.1
    local spinstr='|/-\'

    echo -n "${message} "

    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done

    printf "    \b\b\b\b"
}

################################################################################
# SETUP FUNCTIONS
################################################################################

# Setup GitHub PAT
setup_github_pat() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "              🔑 GitHub Personal Access Token Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This setup can use a GitHub Personal Access Token (optional)."
    echo "If you prefer OAuth authentication, you can skip this."
    echo ""

    if ! prompt_yes_no "Do you want to use a GitHub PAT?" "n"; then
        log_info "Skipping GitHub PAT setup. You can authenticate later with: opencode mcp auth github"
        return 0
    fi

    # Check if already set
    if [ -n "$GITHUB_PAT" ]; then
        echo ""
        echo "GITHUB_PAT is already set in your environment."
        echo "Current token (masked): ${GITHUB_PAT:0:8}...${GITHUB_PAT: -4}"
        echo ""

        if prompt_yes_no "Do you want to use the existing token?" "y"; then
            log_info "Using existing GITHUB_PAT"
            return 0
        fi
    fi

    echo ""
    echo "Please enter your GitHub Personal Access Token:"
    read -s GITHUB_PAT
    echo ""

    if validate_api_key "$GITHUB_PAT" "GITHUB_PAT"; then
        log_success "GitHub PAT accepted: ${GITHUB_PAT:0:8}...${GITHUB_PAT: -4}"
    else
        log_warn "Invalid or empty GITHUB_PAT provided"
        GITHUB_PAT=""
    fi
}

# Setup Z.AI API Key
setup_zai_api_key() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                  🔑 Z.AI API Key Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This setup requires a Z.AI API Key for MCP services."
    echo ""

    # Check if already set
    if [ -n "$ZAI_API_KEY" ]; then
        echo "ZAI_API_KEY is already set in your environment."
        echo "Current key (masked): ${ZAI_API_KEY:0:8}...${ZAI_API_KEY: -4}"
        echo ""

        if prompt_yes_no "Use existing key?" "y"; then
            log_info "Using existing ZAI_API_KEY"
            return 0
        fi
    fi

    echo "Please enter your Z.AI API Key:"
    read -s ZAI_API_KEY
    echo ""

    if ! validate_api_key "$ZAI_API_KEY" "ZAI_API_KEY"; then
        log_error "No valid ZAI_API_KEY provided"

        if ! prompt_yes_no "Continue without API key? Some MCP services will not work." "n"; then
            log_error "Setup cancelled. Please run this script again with your API key."
            exit 1
        fi
    else
        log_success "API Key accepted: ${ZAI_API_KEY:0:8}...${ZAI_API_KEY: -4}"
    fi
}

# Setup nvm
setup_nvm() {
    echo ""
    echo "=== Checking nvm (Node Version Manager) ==="

    # Check if nvm is installed
    if [ -d "$HOME/.nvm" ] || command_exists nvm; then
        local installed_version
        installed_version=$(nvm --version 2>/dev/null || echo "unknown")
        log_info "nvm is already installed (v${installed_version})"

        # Try to get latest version
        local latest_version
        if latest_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//'); then
            log_info "Latest version: v${latest_version}"

            if [ "$installed_version" != "$latest_version" ]; then
                echo ""
                log_warn "A newer version of nvm is available!"

                if prompt_yes_no "Would you like to update nvm to v${latest_version}?" "n"; then
                    log_info "Updating nvm..."
                    run_cmd "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${latest_version}/install.sh | bash"

                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

                    log_success "nvm updated successfully"
                else
                    log_info "Skipping nvm update"
                fi
            else
                log_success "nvm is already up to date"
            fi
        fi
    else
        log_info "nvm is not installed"

        if prompt_yes_no "Install nvm?" "y"; then
            local latest_version
            latest_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//' || echo "latest")

            log_info "Installing nvm v${latest_version}..."
            run_cmd "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${latest_version}/install.sh | bash"

            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

            if command_exists nvm; then
                log_success "nvm installed successfully (v$(nvm --version))"
            else
                log_error "nvm installation failed"
                return 1
            fi
        else
            log_warn "Skipping nvm installation"
            log_warn "Note: nvm is required for Node.js management. Continuing may fail."
        fi
    fi

    return 0
}

# Setup Node.js
setup_nodejs() {
    echo ""
    echo "=== Installing Node.js v24 ==="

    # Ensure nvm is available
    if ! command_exists nvm; then
        log_error "nvm is not available. Cannot install Node.js."
        return 1
    fi

    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if prompt_yes_no "Install/switch to Node.js v24?" "y"; then
        log_info "Installing Node.js v24..."
        run_cmd "nvm install 24"
        run_cmd "nvm use 24"

        if command_exists node; then
            log_success "Node.js $(node --version) installed and active"
            log_info "Node.js v20+ is required for Draw.io MCP server integration"
            echo ""
            echo "=== Draw.io MCP Server Setup ==="
            echo "To use the diagram-creator agent with Draw.io MCP server:"
            echo "1. Clone and build Draw.io MCP server:"
            echo "   git clone https://github.com/scholtzm/mcp-drawio.git"
            echo "   cd mcp-drawio"
            echo "   npm install"
            echo "   npm run build"
            echo ""
            echo "2. Start the server:"
            echo "   npm start"
            echo ""
            echo "3. Ensure it's running on: http://localhost:41033/mcp"
            echo ""
            log_info "Diagram-creator agent requires Draw.io MCP server for diagram creation"
        else
            log_error "Node.js installation failed"
            return 1
        fi
    else
        log_info "Skipping Node.js v24 installation"
        log_warn "Node.js v20+ is recommended for Draw.io MCP server integration"
    fi

    return 0
}

# Setup OpenCode
setup_opencode() {
    echo ""
    echo "=== Installing/Updating OpenCode ==="

    # Ensure npm/node is available
    if ! command_exists npm; then
        log_error "npm is not available. Cannot install opencode-ai."
        return 1
    fi

    # Check if already installed
    if command_exists opencode; then
        local current_version
        current_version=$(opencode --version 2>/dev/null || echo "unknown")
        local latest_version
        latest_version=$(npm view opencode-ai version 2>/dev/null || echo "unknown")

        log_info "opencode-ai is already installed (v${current_version})"
        log_info "Latest version: v${latest_version}"

        if [ "$current_version" != "$latest_version" ]; then
            echo ""
            log_warn "An update is available for opencode-ai!"

            if prompt_yes_no "Would you like to update to the latest version?" "y"; then
                log_info "Updating opencode-ai..."
                run_cmd "npm install -g opencode-ai@latest"

                if command_exists opencode; then
                    log_success "opencode-ai updated successfully to $(opencode --version)"
                else
                    log_error "opencode-ai update failed"
                    return 1
                fi
            else
                log_info "Skipping opencode-ai update"
            fi
        else
            log_success "opencode-ai is already up to date"

            if prompt_yes_no "Reinstall opencode-ai anyway?" "n"; then
                log_info "Reinstalling opencode-ai..."
                run_cmd "npm install -g opencode-ai"
                log_success "opencode-ai reinstalled successfully"
            fi
        fi
    else
        log_info "opencode-ai is not installed"

        if prompt_yes_no "Install opencode-ai now?" "y"; then
            log_info "Installing opencode-ai..."
            run_cmd "npm install -g opencode-ai"

            if command_exists opencode; then
                log_success "opencode-ai installed successfully"
            else
                log_error "opencode-ai installation failed"
                return 1
            fi
        else
            log_warn "Skipping opencode-ai installation"
        fi
    fi

    return 0
}

# Update OpenCode CLI only
update_opencode_cli() {
    echo ""
    echo "=== Updating OpenCode CLI ==="
    echo ""

    # Ensure npm/node is available
    if ! command_exists npm; then
        log_error "npm is not available. Cannot update opencode-ai."
        log_info "Please install Node.js first: https://nodejs.org/"
        return 1
    fi

    # Check if opencode is installed
    if ! command_exists opencode; then
        log_warn "opencode-ai is not installed."
        if prompt_yes_no "Would you like to install opencode-ai now?" "y"; then
            log_info "Installing opencode-ai..."
            run_cmd "npm install -g opencode-ai"
            
            if command_exists opencode; then
                log_success "opencode-ai installed successfully (v$(opencode --version 2>/dev/null))"
                return 0
            else
                log_error "opencode-ai installation failed"
                return 1
            fi
        else
            log_info "Skipping opencode-ai installation"
            return 0
        fi
    fi

    # Get current version
    local current_version
    current_version=$(opencode --version 2>/dev/null || echo "unknown")
    log_info "Current version: v${current_version}"

    # Get latest version
    local latest_version
    log_info "Checking for updates..."
    latest_version=$(npm view opencode-ai version 2>/dev/null || echo "unknown")
    
    if [ "$latest_version" = "unknown" ]; then
        log_error "Could not fetch latest version from npm registry"
        log_info "Check your internet connection and try again"
        return 1
    fi

    log_info "Latest version: v${latest_version}"

    # Compare versions
    if [ "$current_version" = "$latest_version" ]; then
        log_success "opencode-ai is already up to date!"
        echo ""
        
        if prompt_yes_no "Force reinstall anyway?" "n"; then
            log_info "Reinstalling opencode-ai..."
            run_cmd "npm install -g opencode-ai@${latest_version}"
            log_success "opencode-ai reinstalled successfully"
        fi
        
        return 0
    fi

    echo ""
    log_info "Update available: v${current_version} → v${latest_version}"
    
    # Check if auto-update is enabled
    if [ "$AUTO_ACCEPT" = true ]; then
        log_info "Auto-updating to latest version..."
        run_cmd "npm install -g opencode-ai@latest"
        
        local new_version
        new_version=$(opencode --version 2>/dev/null || echo "unknown")
        
        if [ "$new_version" = "$latest_version" ]; then
            log_success "opencode-ai updated successfully to v${new_version}"
        else
            log_error "Update failed. Current version: v${new_version}"
            return 1
        fi
    else
        if prompt_yes_no "Update opencode-ai to v${latest_version}?" "y"; then
            log_info "Updating opencode-ai..."
            run_cmd "npm install -g opencode-ai@latest"
            
            local new_version
            new_version=$(opencode --version 2>/dev/null || echo "unknown")
            
            if [ "$new_version" = "$latest_version" ]; then
                log_success "opencode-ai updated successfully to v${new_version}"
            else
                log_error "Update failed. Current version: v${new_version}"
                return 1
            fi
        else
            log_info "Update cancelled by user"
        fi
    fi

    return 0
}

# Setup configuration file
setup_config() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                  📁 Configuration Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Create config directory
    run_cmd "mkdir -p ${CONFIG_DIR}"
    log_info "Created ${CONFIG_DIR} directory"

    # Check if config.json already exists
    if [ -f "$CONFIG_FILE" ]; then
        echo ""
        log_warn "config.json already exists at ${CONFIG_FILE}"

        if ! prompt_yes_no "Do you want to overwrite it?" "n"; then
            log_info "Skipping config.json copy. Existing configuration preserved."
            SKIP_CONFIG_COPY=true
            return 0
        fi

        # Create backup
        create_backup "$CONFIG_FILE"
    else
        # Config doesn't exist, prompt to copy
        if ! prompt_yes_no "Copy config.json to ${CONFIG_DIR}/?" "y"; then
            log_info "Skipping config.json copy"
            SKIP_CONFIG_COPY=true
            return 0
        fi
    fi

    # Copy config.json
    if [ "$SKIP_CONFIG_COPY" != true ]; then
        if [ -f "${SCRIPT_DIR}/config.json" ]; then
            run_cmd "cp ${SCRIPT_DIR}/config.json ${CONFIG_FILE}"
            log_success "config.json copied successfully"

            echo ""
            echo "✓ Configured 4 agents:"
            echo "    - build-with-skills (default) - Skill-aware coding agent"
            echo "    - explore - Codebase exploration and analysis"
            echo "    - image-analyzer - Image/screenshot analysis"
            echo "    - diagram-creator - Draw.io diagram creation"
            echo ""
            echo "✓ Configured 6 MCP servers:"
            echo "    Local (auto-start): atlassian, zai-mcp-server"
            echo "    Remote (needs key): web-reader, web-search-prime, zread, drawio"
            echo ""
        else
            log_error "config.json not found in ${SCRIPT_DIR}"
            return 1
        fi
    fi

    # Setup skills directory
    echo ""
    log_info "Setting up skills directory..."

    # Create skills directory
    run_cmd "mkdir -p ${SKILLS_DIR}"
    log_info "Created ${SKILLS_DIR} directory"

    # Check if skills folder exists in script directory
    if [ -d "${SCRIPT_DIR}/skills" ]; then
        # Check if skills directory already has content
        if [ -d "${SKILLS_DIR}" ] && [ "$(ls -A ${SKILLS_DIR} 2>/dev/null)" ]; then
            log_warn "Skills directory already contains files"

            if prompt_yes_no "Do you want to overwrite existing skills?" "n"; then
                # Backup existing skills
                if [ -d "${BACKUP_DIR}" ]; then
                    run_cmd "cp -r ${SKILLS_DIR} ${BACKUP_DIR}/skills-backup"
                    log_info "Backed up existing skills to ${BACKUP_DIR}/skills-backup"
                fi
            else
                log_info "Skipping skills deployment. Existing skills preserved."
                return 0
            fi
        fi

        # Copy skills folder
        run_cmd "cp -r ${SCRIPT_DIR}/skills/* ${SKILLS_DIR}/"
        log_success "Skills copied successfully to ${SKILLS_DIR}"

        echo ""
        echo "✓ Deployed 27 skills:"
        echo "    - Framework (5):"
        echo "      - test-generator-framework"
        echo "      - jira-git-integration"
        echo "      - pr-creation-workflow"
        echo "      - ticket-branch-workflow"
        echo "      - linting-workflow"
        echo "    - Language-Specific (3):"
        echo "      - python-pytest-creator"
        echo "      - python-ruff-linter"
        echo "      - javascript-eslint-linter"
        echo "    - Framework-Specific (4):"
        echo "      - nextjs-pr-workflow"
        echo "      - nextjs-unit-test-creator"
        echo "      - nextjs-standard-setup"
        echo "      - typescript-dry-principle"
        echo "    - OpenCode Meta (3):"
        echo "      - opencode-agent-creation"
        echo "      - opencode-skill-creation"
        echo "      - opencode-skill-auditor"
        echo "    - OpenTofu (6):"
        echo "      - opentofu-aws-explorer"
        echo "      - opentofu-keycloak-explorer"
        echo "      - opentofu-kubernetes-explorer"
        echo "      - opentofu-neon-explorer"
        echo "      - opentofu-provider-setup"
        echo "      - opentofu-provisioning-workflow"
        echo "    - Git/Workflow (3):"
        echo "      - ascii-diagram-creator"
        echo "      - git-issue-creator"
        echo "      - git-pr-creator"
        echo "    - Documentation (2):"
        echo "      - coverage-readme-workflow"
        echo "      - docstring-generator"
        echo "    - JIRA (1):"
        echo "      - jira-git-workflow"
        echo ""
        echo "  Run 'opencode --list-skills' for detailed descriptions"
        echo ""
    else
        log_warn "skills/ folder not found in ${SCRIPT_DIR}"
    fi

    return 0
}

# Setup environment variables in shell config (bashrc, zshrc, etc.)
setup_shell_vars() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "              🔐 Environment Variables Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Detected shell: ${DETECTED_SHELL}"
    echo "Config file: ${SHELL_CONFIG_FILE}"
    echo ""

    # Add ZAI_API_KEY to shell config
    if [ -n "$ZAI_API_KEY" ]; then
        if grep -q "ZAI_API_KEY" "$SHELL_CONFIG_FILE" 2>/dev/null; then
            log_info "ZAI_API_KEY already exists in ${SHELL_CONFIG_FILE}"
        else
            if prompt_yes_no "Add ZAI_API_KEY to $(basename ${SHELL_CONFIG_FILE}) for persistent access?" "y"; then
                create_backup "$SHELL_CONFIG_FILE"
                run_cmd "echo 'export ZAI_API_KEY=\"${ZAI_API_KEY}\"' >> ${SHELL_CONFIG_FILE}"
                log_success "ZAI_API_KEY added to ${SHELL_CONFIG_FILE}"
            else
                log_info "Skipping shell config update for ZAI_API_KEY"
            fi
        fi
    fi

    # Add GITHUB_PAT to shell config
    if [ -n "$GITHUB_PAT" ]; then
        if grep -q "GITHUB_PAT" "$SHELL_CONFIG_FILE" 2>/dev/null; then
            log_info "GITHUB_PAT already exists in ${SHELL_CONFIG_FILE}"
        else
            if prompt_yes_no "Add GITHUB_PAT to $(basename ${SHELL_CONFIG_FILE}) for persistent access?" "y"; then
                create_backup "$SHELL_CONFIG_FILE"
                run_cmd "echo 'export GITHUB_PAT=\"${GITHUB_PAT}\"' >> ${SHELL_CONFIG_FILE}"
                log_success "GITHUB_PAT added to ${SHELL_CONFIG_FILE}"
            else
                log_info "Skipping shell config update for GITHUB_PAT"
            fi
        fi
    fi

    return 0
}

################################################################################
# SUMMARY AND REPORTING
################################################################################

# Print setup summary
print_summary() {
    local nvm_version
    local opencode_version
    local node_version
    local skill_count

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                      📊 Setup Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Platform detection status
    echo "Platform Detection:"
    echo "✓ Detected OS: ${DETECTED_OS} ${OS_VERSION:+(${OS_VERSION})}"
    echo "✓ Detected Shell: ${DETECTED_SHELL}"
    echo "✓ Shell Config: ${SHELL_CONFIG_FILE}"
    echo ""

    # nvm status
    if command_exists nvm; then
        nvm_version=$(nvm --version 2>/dev/null)
        echo "✓ nvm: Installed v${nvm_version}"
    else
        echo "✗ nvm: Not installed"
    fi

    # Node.js status
    if command_exists node; then
        node_version=$(node --version)
        echo "✓ Node.js: ${node_version}"
    else
        echo "✗ Node.js: Not installed"
    fi

    # opencode-ai status
    if command_exists opencode; then
        opencode_version=$(opencode --version 2>/dev/null || echo "unknown")
        echo "✓ opencode-ai: Installed v${opencode_version}"
    else
        echo "✗ opencode-ai: Not installed"
    fi

    # config.json status
    if [ -f "$CONFIG_FILE" ]; then
        echo "✓ config.json: Copied to ${CONFIG_DIR}/"
        echo "    - Model: zai-coding-plan/glm-4.7"
        echo "    - Default agent: build-with-skills"
    else
        echo "✗ config.json: Not copied"
    fi

    # Agents configured
    if [ -f "$CONFIG_FILE" ]; then
        echo "✓ Configured 4 agents:"
        echo "    - build-with-skills (default) - Skill-aware coding agent"
        echo "    - explore - Codebase exploration and analysis"
        echo "    - image-analyzer - Image/screenshot analysis"
        echo "    - diagram-creator - Draw.io diagram creation"
    fi

    # MCP servers configured
    if [ -f "$CONFIG_FILE" ]; then
        echo "✓ Configured 6 MCP servers:"
        echo "    - atlassian - JIRA and Confluence integration (auto-start)"
        echo "    - drawio - Draw.io diagram server (needs local instance)"
        echo "    - web-reader - Web page reading (needs ZAI_API_KEY)"
        echo "    - web-search-prime - Web search (needs ZAI_API_KEY)"
        echo "    - zai-mcp-server - Image analysis (auto-start)"
        echo "    - zread - GitHub repo search (needs ZAI_API_KEY)"
    fi

    # skills directory status
    if [ -d "$SKILLS_DIR" ] && [ "$(ls -A ${SKILLS_DIR} 2>/dev/null)" ]; then
        local skill_count=$(find ${SKILLS_DIR} -name "SKILL.md" 2>/dev/null | wc -l)
        echo "✓ skills: ${skill_count} skills deployed to ${SKILLS_DIR}/"
        echo "    - Framework (5):"
        echo "      - test-generator-framework"
        echo "      - jira-git-integration"
        echo "      - pr-creation-workflow"
        echo "      - ticket-branch-workflow"
        echo "      - linting-workflow"
        echo "    - Language-Specific (3):"
        echo "      - python-pytest-creator"
        echo "      - python-ruff-linter"
        echo "      - javascript-eslint-linter"
        echo "    - Framework-Specific (4):"
        echo "      - nextjs-pr-workflow"
        echo "      - nextjs-unit-test-creator"
        echo "      - nextjs-standard-setup"
        echo "      - typescript-dry-principle"
        echo "    - OpenCode Meta (3):"
        echo "      - opencode-agent-creation"
        echo "      - opencode-skill-creation"
        echo "      - opencode-skill-auditor"
        echo "    - OpenTofu (6):"
        echo "      - opentofu-aws-explorer"
        echo "      - opentofu-keycloak-explorer"
        echo "      - opentofu-kubernetes-explorer"
        echo "      - opentofu-neon-explorer"
        echo "      - opentofu-provider-setup"
        echo "      - opentofu-provisioning-workflow"
        echo "    - Git/Workflow (3):"
        echo "      - ascii-diagram-creator"
        echo "      - git-issue-creator"
        echo "      - git-pr-creator"
        echo "    - Documentation (2):"
        echo "      - coverage-readme-workflow"
        echo "      - docstring-generator"
        echo "    - JIRA (1):"
        echo "      - jira-git-workflow"
    else
        echo "✗ skills: Not deployed"
    fi

    # ZAI_API_KEY status
    if grep -q "ZAI_API_KEY" "$SHELL_CONFIG_FILE" 2>/dev/null; then
        echo "✓ ZAI_API_KEY: Added to ${SHELL_CONFIG_FILE}"
    elif [ -n "$ZAI_API_KEY" ]; then
        echo "○ ZAI_API_KEY: Set in current session only"
    else
        echo "✗ ZAI_API_KEY: Not configured"
    fi

    # GITHUB_PAT status
    if grep -q "GITHUB_PAT" "$SHELL_CONFIG_FILE" 2>/dev/null; then
        echo "✓ GITHUB_PAT: Added to ${SHELL_CONFIG_FILE}"
    elif [ -n "$GITHUB_PAT" ]; then
        echo "○ GITHUB_PAT: Set in current session only"
    else
        echo "○ GITHUB_PAT: Not configured (use OAuth with: opencode mcp auth github)"
    fi

    echo ""
}

# Print next steps
print_next_steps() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                        🎉 Setup Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Restart terminal or run: source ${SHELL_CONFIG_FILE}"
    echo "  2. Start LM Studio: http://127.0.0.1:1234/v1"
    echo "  3. Verify installation: opencode --version"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                        🚀 Quick Start"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🤖 Agents (4):"
    echo "  - build-with-skills (default) - Auto-detects and uses best practices"
    echo "  - explore - Fast codebase exploration and analysis"
    echo "  - image-analyzer - Images/screenshots to code, OCR, error diagnosis"
    echo "  - diagram-creator - Draw.io diagrams (architecture, flowcharts, UML)"
    echo ""
    echo "  Usage: opencode --agent <name> \"prompt\""
    echo "         opencode \"prompt\" (uses build-with-skills)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                     📦 27 Skills Available"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Framework (5) • Language-Specific (3) • Framework-Specific (4)"
    echo "  OpenCode Meta (3) • OpenTofu (6) • Git/Workflow (3)"
    echo "  Documentation (2) • JIRA (1)"
    echo ""
    echo "  Run 'opencode --list-skills' for detailed descriptions"
    echo "  Run 'opencode --skill <name> \"prompt\"' to use a skill"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                     🔌 MCP Servers (6)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Local (auto-start): atlassian, zai-mcp-server"
    echo "  Remote (needs key): web-reader, web-search-prime, zread, drawio"
    echo ""
    echo "  Auth: opencode mcp auth atlassian / opencode mcp auth github"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                     📚 Documentation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  - Update CLI: ./setup.sh --update"
    echo "  - Config file: ${CONFIG_FILE}"
    echo "  - Log file: ${LOG_FILE}"
    echo "  - Backup dir: ${BACKUP_DIR}"
    echo "  - Full docs: https://opencode.ai"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Display header
    if [ "$UPDATE_ONLY" = false ] && [ "$SKILLS_ONLY" = false ]; then
        echo "=== OpenCode Configuration Setup v${SCRIPT_VERSION} ==="
        echo ""
    elif [ "$SKILLS_ONLY" = true ]; then
        echo "=== OpenCode Skills Deployment v${SCRIPT_VERSION} ==="
        echo ""
    else
        echo "=== OpenCode CLI Updater v${SCRIPT_VERSION} ==="
        echo ""
    fi

    # Initialize logging
    init_logging

    # Handle update-only mode
    if [ "$UPDATE_ONLY" = true ]; then
        update_opencode_cli
        echo ""
        echo "Update complete!"
        exit 0
    fi

    # Handle skills-only mode
    if [ "$SKILLS_ONLY" = true ]; then
        log_info "Validating OpenCode installation..."
        if command_exists opencode; then
            log_success "OpenCode is installed ($(opencode --version 2>/dev/null))"
        else
            log_error "OpenCode CLI is not installed globally"
            log_info "Please install OpenCode first: npm install -g opencode-ai"
            exit 1
        fi

        if ! check_dependencies; then
            log_error "Dependency check failed. Please install missing dependencies."
            exit 1
        fi

    # Generate and inject skills section before config copy
    generate_and_inject_skills

        setup_config || true
        print_summary
        echo ""
        echo "Skills deployment complete!"
        exit 0
    fi

    # Check dependencies
    if ! check_dependencies; then
        log_error "Dependency check failed. Please install missing dependencies."
        exit 1
    fi

    # Check network connectivity (skip in quick setup)
    if [ "$QUICK_SETUP" = false ]; then
        if ! check_network; then
            log_warn "Network connectivity issues detected. Some features may not work."
            if ! prompt_yes_no "Continue anyway?" "n"; then
                exit 1
            fi
        fi
    fi

    # Main menu (if not quick setup or skills-only)
    if [ "$QUICK_SETUP" = false ] && [ "$SKILLS_ONLY" = false ] && [ "$AUTO_ACCEPT" = false ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "                      Setup Mode Selection"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  1) Quick setup (config + skills only)"
        echo "  2) Skills-only setup"
        echo "  3) Full setup (API keys, Node.js, OpenCode)"
        echo "  4) Update OpenCode CLI only"
        echo ""

        local setup_option
        setup_option=$(prompt_user "Select option [default: 2]" "2")

        case "$setup_option" in
            1)
                echo ""
                log_info "Quick Setup: Copy config.json and skills only"
                QUICK_SETUP=true
                ;;
            2)
                echo ""
                log_info "Skills-Only Setup: Copy skills folder only"
                
                # Validate OpenCode installation
                if command_exists opencode; then
                    log_success "OpenCode is installed ($(opencode --version 2>/dev/null))"
                else
                    log_error "OpenCode CLI is not installed globally"
                    log_info "Please install OpenCode first: npm install -g opencode-ai"
    generate_and_inject_skills

                    exit 1
                fi
                
                setup_config || true
                print_summary
                echo ""
                echo "Skills deployment complete!"
                exit 0
                ;;
            3)
                log_info "Running full setup..."
                ;;
            4)
                echo ""
                log_info "Update OpenCode CLI only"
                update_opencode_cli
                echo ""
                echo "Update complete!"
                exit 0
                ;;
            *)
                log_warn "Invalid option. Running full setup..."
                ;;
        esac
        echo ""
    fi

    # Execute setup steps
    if [ "$QUICK_SETUP" = false ] && [ "$SKILLS_ONLY" = false ]; then
        setup_github_pat || true
        setup_zai_api_key || true
        setup_nvm || true
        setup_nodejs || true
        setup_opencode || true
    else
        if [ "$QUICK_SETUP" = true ]; then
    generate_and_inject_skills

            log_info "Running quick setup: config.json and skills deployment only"
        fi
    fi

    setup_config || true
    setup_shell_vars || true

    # Print summary and next steps
    print_summary
    print_next_steps

    # Log completion
    log "INFO" "=== OpenCode Setup Completed at $(date) ==="

    # Prompt to exit
    if [ "$AUTO_ACCEPT" = false ]; then
        read -p "Press Enter to exit..."
    fi

    exit 0
}

# Run main function with all arguments
main "$@"

################################################################################
# DYNAMIC SKILLS GENERATION
################################################################################

# Generate skills section from skills folder
generate_and_inject_skills() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                  📋 Generating Skills Section"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local config_file="${SCRIPT_DIR}/config.json"
    local temp_config="${SCRIPT_DIR}/config.json.tmp"
    
    # Check if Python script exists
    local gen_script="${SCRIPT_DIR}/scripts/generate-skills.py"
    if [ ! -f "$gen_script" ]; then
        log_warn "Skills generator script not found: ${gen_script}"
        log_info "Skipping skills section generation"
        return 0
    fi
    
    # Generate skills markdown
    log_info "Generating skills section from skills/ folder..."
    local skills_md=$("$gen_script" 2>&1)
    
    if [ $? -ne 0 ]; then
        log_warn "Skills generation failed"
        return 1
    fi
    
    # Read config.json
    if ! command_exists python3; then
        log_error "Python 3 is required for skills generation"
        return 1
    fi
    
    # Inject skills section into config.json
    log_info "Injecting skills section into config.json..."
    
    # Use Python to replace placeholder with skills
    python3 << EOF
import json
import sys

# Read config
try:
    with open('${config_file}', 'r') as f:
        config = json.load(f)
except:
    print(f"Error: Cannot read {config_file}", file=sys.stderr)
    sys.exit(1)

# Skills markdown (passed as argument)
skills_md = """${skills_md}"""

# Update both agents
for agent in ['build-with-skills', 'plan-with-skills']:
    if agent in config.get('agent', {}):
        old_prompt = config['agent'][agent]['prompt']
        placeholder = '{{SKILLS_SECTION_PLACEHOLDER}}'
        
        if placeholder in old_prompt:
            new_prompt = old_prompt.replace(placeholder, skills_md)
            config['agent'][agent]['prompt'] = new_prompt
            print(f"Updated {agent}")

# Write back
try:
    with open('${temp_config}', 'w') as f:
        json.dump(config, f, indent=2)
    print("Temporary config written")
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF
    
    if [ $? -eq 0 ] && [ -f "$temp_config" ]; then
        # Replace original with temp
        run_cmd "mv ${temp_config} ${config_file}"
        log_success "Skills section generated and injected"
        
        # Show summary
        echo ""
        local skill_count=$(echo "$skills_md" | grep -c "^- \*\*")
        echo "✓ Generated skills section with ${skill_count} skills"
        echo "✓ Skills will be auto-discovered at runtime"
    else
        log_warn "Skills injection failed, using original config"
    fi
}

