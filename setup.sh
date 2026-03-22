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
# SETUP MODES:
#   ./setup.sh                    Interactive menu (recommended for first-time setup)
#   ./setup.sh --quick            Quick setup (config + skills only, no dependencies)
#   ./setup.sh --skills-only      Skills deployment only (requires opencode-ai installed)
#   ./setup.sh --update           Update OpenCode CLI to latest version
#
# OPTIONS:
#   -h, --help          Show detailed help with all options and examples
#   -q, --quick         Quick setup: copy config.json + AGENTS.md + skills/ folder
#   -s, --skills-only   Skills-only: deploy skills/ folder (validates opencode-ai installed)
#   -d, --dry-run       Preview all actions without making changes
#   -y, --yes           Auto-accept all prompts (non-interactive mode)
#   -v, --verbose       Enable detailed debug output
#   -u, --update        Update OpenCode CLI only (skip config/skills)
#   -A, --enable-auto-update    Enable automatic opencode-ai updates
#   -D, --disable-auto-update   Disable automatic updates
#   -S, --schedule-update <schedule>  Set update schedule: daily|weekly|monthly|manual
#   -C, --check-update  Check for available updates without installing
#
# REQUIREMENTS (for full setup):
#   - curl (for downloading)
#   - Node.js v20+ and npm (for opencode-ai and MCP servers)
#   - nvm recommended (for Node.js version management on macOS/Linux)
#   - ZAI_API_KEY (required for web-reader, web-search-prime, zread MCP servers)
#   - LM Studio running on http://127.0.0.1:1234/v1 (local LLM inference)
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
AGENTS_SRC_DIR="${SCRIPT_DIR}/agents"
AGENTS_DEST_DIR="${CONFIG_DIR}/agents"
BACKUP_DIR="${HOME}/.opencode-backup-$(date +%Y%m%d_%H%M%S)"
LAST_UPDATE_CHECK="${CONFIG_DIR}/.last-update-check"
UPDATE_LOG="${CONFIG_DIR}/update.log"

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
            # Check if running under WSL
            if grep -q Microsoft /proc/version 2>/dev/null; then
                echo "Windows-WSL"
            else
                echo "Linux"
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows"
            ;;
        MINGW64_NT-*)
            # Git Bash on Windows
            echo "Windows-GitBash"
            ;;
        *)
            # Check for Windows environment variables
            if [ -n "$OS" ] && [[ "$OS" == "Windows_NT" ]]; then
                echo "Windows"
            else
                echo "Unknown"
            fi
            ;;
    esac
}

DETECTED_OS=$(detect_platform)
OS_VERSION=$(sw_vers 2>/dev/null || uname -r)

# Check if a command exists (defined early, used by detect_package_manager)
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect package manager and distribution based on platform
detect_package_manager() {
    local platform="$1"

    case "$platform" in
        macOS)
            # Check for Homebrew
            if command_exists brew; then
                echo "brew"
            else
                echo "none"
            fi
            ;;
        Linux*)
            # Detect distribution and package manager
            if [ -f /etc/debian_version ]; then
                # Debian-based: Ubuntu, Debian, Linux Mint, etc.
                local distro_id
                distro_id=$(grep "^ID=" /etc/os-release 2>/dev/null | cut -d= -f2 | cut -d\" -f1)
                echo "apt:${distro_id}"
            elif [ -f /etc/redhat-release ]; then
                # RHEL-based: Fedora, RHEL, CentOS, Rocky, etc.
                local distro_id
                distro_id=$(grep "^ID=" /etc/os-release 2>/dev/null | cut -d= -f2 | cut -d\" -f1)
                echo "dnf:${distro_id}"
            elif [ -f /etc/arch-release ]; then
                # Arch-based: Arch, Manjaro, EndeavourOS, etc.
                local distro_id
                distro_id=$(grep "^ID=" /etc/os-release 2>/dev/null | cut -d= -f2 | cut -d\" -f1)
                echo "pacman:${distro_id}"
            elif [ -f /etc/SUSE-brand ] || [ -f /etc/SUSE-release ]; then
                # SUSE-based: openSUSE, SUSE Linux
                echo "zypper:opensuse"
            elif command_exists zypper; then
                # Check for zypper as fallback
                echo "zypper:unknown"
            elif [ -f /etc/alpine-release ]; then
                # Alpine Linux
                echo "apk:alpine"
            elif command_exists pacman; then
                # Fallback to pacman
                echo "pacman:unknown"
            elif command_exists apk; then
                # Fallback to apk
                echo "apk:unknown"
            elif command_exists dnf; then
                # Fallback to dnf
                echo "dnf:unknown"
            elif command_exists apt-get; then
                # Fallback to apt
                echo "apt:unknown"
            else
                echo "none"
            fi
            ;;
        Windows*|Windows-GitBash)
            # Check for winget
            if command_exists winget; then
                echo "winget"
            # Check for chocolatey
            elif command_exists choco; then
                echo "chocolatey"
            else
                echo "none"
            fi
            ;;
        *)
            echo "none"
            ;;
    esac
}

PACKAGE_MANAGER=$(detect_package_manager "$DETECTED_OS")

# Extract distribution name from package manager
get_distribution_name() {
    local pkg_manager="$1"
    case "$pkg_manager" in
        apt:*|apt:*)
            echo "${pkg_manager#*:}"
            ;;
        dnf:*|dnf:*)
            echo "${pkg_manager#*:}"
            ;;
        pacman:*|pacman:*)
            echo "${pkg_manager#*:}"
            ;;
        zypper:*)
            echo "opensuse"
            ;;
        apk:*)
            echo "alpine"
            ;;
        brew|winget|chocolatey)
            echo "$pkg_manager"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

DISTRIBUTION_NAME=$(get_distribution_name "$PACKAGE_MANAGER")

# Detect shell (bash, zsh, or powershell)
detect_shell() {
    if [ -n "${ZSH_VERSION:-}" ]; then
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
ENABLE_AUTO_UPDATE=false
UPDATE_SCHEDULE="manual"
CHECK_UPDATE_ONLY=false

# API Keys (initialize to empty to avoid unbound variable errors)
# Capture from environment if they exist
GITHUB_PAT=""
ZAI_API_KEY="${ZAI_API_KEY:-}"

# JIRA OAuth2 credentials
JIRA_CLIENT_ID="${JIRA_CLIENT_ID:-}"
JIRA_CLIENT_SECRET="${JIRA_CLIENT_SECRET:-}"
JIRA_ACCESS_TOKEN="${JIRA_ACCESS_TOKEN:-}"
JIRA_REFRESH_TOKEN="${JIRA_REFRESH_TOKEN:-}"
JIRA_CLOUD_ID="${JIRA_CLOUD_ID:-}"

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
    log "INFO" "User: ${USER:-${LOGNAME:-unknown}}"
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
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    OpenCode Configuration Setup v${SCRIPT_VERSION}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

USAGE:
    ./setup.sh [OPTIONS]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            SETUP MODES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  MODE                    WHAT IT DOES                          WHEN TO USE
  ─────────────────────────────────────────────────────────────────────────────
  Interactive (default)   Full setup with guided prompts       First-time setup
                           1. GitHub CLI check
                           2. Z.AI API key setup
                          3. nvm installation/update
                          4. Node.js v24 installation
                          5. opencode-ai installation
                          6. config.json deployment
                          7. skills/ deployment
                          8. Environment variable persistence

  --quick                 Copy config files only                Already have
                          1. config.json → ~/.config/opencode/  dependencies installed
                          2. AGENTS.md → ~/.config/opencode/
                          3. skills/* → ~/.config/opencode/skills/
                          (Skips all dependency checks)

  --skills-only           Deploy skills only                    opencode-ai already
                          1. Validates opencode-ai installed    installed, just need
                          2. Copies skills/* to config dir      updated skills

  --update                Update opencode-ai CLI only           Keep CLI current
                          (No config changes)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            OPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  SETUP OPTIONS:
    -q, --quick           Quick setup mode (config + skills only, no dependencies)
    -s, --skills-only     Skills-only deployment mode
    -u, --update          Update OpenCode CLI to latest version

  UPDATE MANAGEMENT:
    -A, --enable-auto-update      Enable automatic opencode-ai updates
    -D, --disable-auto-update     Disable automatic updates
    -S, --schedule-update <schedule>  Set update check frequency:
                                      daily, weekly, monthly, manual (default)
    -C, --check-update    Check for updates without installing

  UTILITY OPTIONS:
    -h, --help            Show this detailed help message
    -d, --dry-run         Preview all actions without making changes
    -y, --yes             Auto-accept all prompts (non-interactive)
    -v, --verbose         Enable detailed debug logging

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            EXAMPLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  First-time setup:
    ./setup.sh                      # Interactive full setup with menu
    ./setup.sh -y                   # Full setup, auto-accept all prompts

  Quick deployment:
    ./setup.sh --quick              # Copy config and skills (no deps)
    ./setup.sh --skills-only        # Deploy skills only
    ./setup.sh -y -q                # Quick setup, non-interactive

  Preview and update:
    ./setup.sh --dry-run            # Preview what would be done
    ./setup.sh --update             # Update opencode-ai CLI
    ./setup.sh -C                   # Check for available updates

  Auto-update management:
    ./setup.sh -A                   # Enable auto-updates (manual schedule)
    ./setup.sh -A -S daily          # Enable with daily checks
    ./setup.sh -A -S weekly         # Enable with weekly checks
    ./setup.sh -D                   # Disable auto-updates

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                         CONFIGURED FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  AGENTS (5):
    build (default)      Full-featured coding agent with all tools
    plan                 Planning agent (read-only, edits need approval)
    explore              Fast codebase exploration and analysis
    image-analyzer       Images/screenshots → code, OCR, error diagnosis
    diagram-creator      Diagrams (architecture, flowcharts, UML)

    Usage: opencode --agent build "implement auth feature"
           opencode --agent explore "find all API routes"

  MCP SERVERS (6):
    Auto-start (npx):
      atlassian          JIRA and Confluence integration
      zai-mcp-server     Image analysis and video processing

    Remote (requires ZAI_API_KEY):
      web-reader         Web page content extraction
      web-search-prime   Web search capabilities
      zread              GitHub repository search and file reading

   SKILLS (49):
     Framework (7):        test-generator-framework, linting-workflow,
                           pr-creation-workflow, jira-git-integration,
                           error-resolver-workflow, tdd-workflow, docx-creation

     Language-Specific (4): python-pytest-creator, python-ruff-linter,
                           python-docstring-generator, javascript-eslint-linter

     Framework-Specific (7): nextjs-pr-workflow, nextjs-unit-test-creator,
                           nextjs-standard-setup, nextjs-complete-setup,
                           nextjs-image-usage, nextjs-tsdoc-documentor,
                           typescript-dry-principle

     OpenCode Meta (4):    opencode-agent-creation, opencode-skill-creation,
                           opencode-skill-auditor, opencode-skills-maintainer

     OpenTofu (7):         opentofu-aws-explorer, opentofu-keycloak-explorer,
                           opentofu-kubernetes-explorer, opentofu-neon-explorer,
                           opentofu-provider-setup, opentofu-provisioning-workflow,
                           opentofu-ecr-provision

     Git/Workflow (7):     ascii-diagram-creator, git-issue-creator,
                           git-pr-creator, git-issue-labeler,
                           git-issue-plan-workflow, git-issue-updater,
                           git-semantic-commits

     Documentation (2):    coverage-readme-workflow, docstring-generator

     JIRA (4):             jira-ticket-oauth-workflow, jira-ticket-plan-workflow,
                           jira-status-updater, jira-ticket-workflow

     Code Quality (7):     solid-principles, clean-code, clean-architecture,
                           design-patterns, object-design, code-smells,
                           complexity-management

    Run 'opencode --list-skills' for detailed descriptions
    Run 'opencode --skill <name> "prompt"' to invoke a skill

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                           REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Required (for full setup):
    curl                  For downloading files
    Node.js v20+          For opencode-ai and MCP servers
    npm                   Comes with Node.js

  Recommended:
    nvm                   Node Version Manager (macOS/Linux)
    git                   For version control integration

  API Keys (prompted during setup):
     ZAI_API_KEY           Required for: web-reader, web-search-prime, zread
                           Get from: https://z.ai

   GitHub Auth:
     GitHub CLI (gh)      Recommended for GitHub MCP features
                           Install: https://cli.github.com/
                           Or use OAuth: opencode mcp auth github

  Local Services:
    LM Studio             Running on http://127.0.0.1:1234/v1
                           Local LLM inference server

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            FILE LOCATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Configuration:        ~/.config/opencode/config.json
  Agents config:        ~/.config/opencode/AGENTS.md
  Skills directory:     ~/.config/opencode/skills/
  Setup log:            ~/.opencode-setup.log
  Update log:           ~/.config/opencode/update.log
  Backups:              ~/.opencode-backup-YYYYMMDD_HHMMSS/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For more information: https://opencode.ai
Report issues: https://github.com/anomalyco/opencode/issues

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
            -A|--enable-auto-update)
                ENABLE_AUTO_UPDATE=true
                shift
                ;;
            -D|--disable-auto-update)
                ENABLE_AUTO_UPDATE=false
                shift
                ;;
            -S|--schedule-update)
                if [ -n "$2" ]; then
                    UPDATE_SCHEDULE="$2"
                else
                    log_error "--schedule-update requires an argument (daily, weekly, monthly)"
                    exit 1
                fi
                shift 2
                ;;
            -C|--check-update)
                CHECK_UPDATE_ONLY=true
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

# Check GitHub CLI
setup_github_cli() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "              🔑 GitHub CLI Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if command_exists gh; then
        if gh auth status >/dev/null 2>&1; then
            local gh_user
            gh_user=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
            log_success "GitHub CLI is installed and authenticated as: ${gh_user}"
            log_info "Run 'opencode mcp auth github' to configure GitHub MCP authentication"
        else
            log_warn "GitHub CLI is installed but not authenticated."
            echo ""
            echo "  To authenticate, run:"
            echo "    gh auth login"
            echo ""
            echo "  Then re-run this setup or run: opencode mcp auth github"
        fi
    else
        log_warn "GitHub CLI (gh) is not installed."
        echo ""
        echo "  Install GitHub CLI:"
        case "$DETECTED_OS" in
            macOS*)
                echo "    brew install gh"
                ;;
            Windows*|Windows-GitBash)
                echo "    winget install GitHub.cli"
                echo "    -- or --"
                echo "    choco install gh"
                ;;
            Linux*)
                echo "    See: https://cli.github.com/"
                ;;
            *)
                echo "    See: https://cli.github.com/"
                ;;
        esac
        echo ""
        echo "  After installing, run: gh auth login"
        echo "  Then re-run this setup or run: opencode mcp auth github"
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
    # On Windows, also check the registry for setx-persisted values
    if is_windows && [ -z "$ZAI_API_KEY" ]; then
        local _reg_key
        _reg_key=$(reg query "HKCU\\Environment" /v ZAI_API_KEY 2>/dev/null | grep -oP 'REG_SZ\s+\K.*' || true)
        if [ -n "$_reg_key" ]; then
            ZAI_API_KEY="$_reg_key"
        fi
    fi

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

# Setup PeonPing (AI agent sound notifications)
setup_peonping() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "              🔊 PeonPing Sound Notifications Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "PeonPing plays game character voice lines when your AI agent"
    echo "finishes work or needs permission. Works with OpenCode!"
    echo ""
    echo "Features:"
    echo "  - Voice notifications from Warcraft, StarCraft, Portal, and more"
    echo "  - Desktop notifications when agent needs attention"
    echo "  - 160+ sound packs available"
    echo ""

    if ! prompt_yes_no "Install PeonPing?" "y"; then
        log_info "Skipping PeonPing installation"
        return 0
    fi

    # Check if peon command exists
    if command_exists peon; then
        log_info "PeonPing is already installed"
        if prompt_yes_no "Reinstall/update PeonPing?" "n"; then
            log_info "Updating PeonPing..."
        else
            log_info "Keeping existing PeonPing installation"
            return 0
        fi
    fi

    # Install based on platform
    case "$DETECTED_OS" in
        macOS|Linux*|Windows-WSL)
            log_info "Installing PeonPing via Homebrew or curl..."
            
            if command_exists brew; then
                log_info "Using Homebrew..."
                run_cmd "brew install PeonPing/tap/peon-ping"
            else
                log_info "Using curl installer..."
                run_cmd "curl -fsSL https://peonping.com/install | bash"
            fi
            ;;
        Windows*|Windows-GitBash)
            log_info "Installing PeonPing via PowerShell..."
            log_info "Run this in PowerShell as Administrator:"
            echo "  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/PeonPing/peon-ping/main/install.ps1' -UseBasicParsing | Invoke-Expression"
            echo ""
            if prompt_yes_no "Have you completed the PowerShell installation?" "y"; then
                log_success "PeonPing installation completed"
            else
                log_warn "Please complete PeonPing installation manually"
                return 0
            fi
            ;;
        *)
            log_warn "Unsupported platform for automatic PeonPing installation"
            log_info "Install manually: https://github.com/PeonPing/peon-ping"
            return 0
            ;;
    esac

    # Verify installation
    if command_exists peon; then
        log_success "PeonPing installed successfully"
        
        # Run setup
        log_info "Running PeonPing setup..."
        run_cmd "peon-ping-setup 2>/dev/null || peon packs install peon 2>/dev/null || true"
        
        echo ""
        echo "✓ PeonPing installed successfully!"
        echo ""
        echo "Quick commands:"
        echo "  peon status          - Check if active"
        echo "  peon preview         - Play test sounds"
        echo "  peon packs list      - List installed packs"
        echo "  peon packs list --registry  - Browse 160+ packs"
        echo "  peon packs install <name>   - Install a pack"
        echo "  peon volume 0.5      - Set volume (0.0-1.0)"
        echo "  peon toggle          - Mute/unmute sounds"
        echo ""
        
        # Ask about configuring OpenCode plugin
        if prompt_yes_no "Install PeonPing TypeScript plugin for OpenCode?" "y"; then
            setup_peonping_hooks
        fi
    else
        log_warn "PeonPing installation may not have completed correctly"
        log_info "Try: brew install PeonPing/tap/peon-ping"
    fi
}

# Setup PeonPing plugin for OpenCode
# Note: OpenCode uses a TypeScript plugin system, NOT shell hooks.
# The opencode.sh adapter is an installer script that downloads the TS plugin.
setup_peonping_hooks() {
    echo ""
    log_info "Configuring PeonPing for OpenCode..."
    
    local OPENCODE_PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins"
    local PEON_PLUGIN="${OPENCODE_PLUGINS_DIR}/peon-ping.ts"
    
    # Check if plugin already installed
    if [ -f "$PEON_PLUGIN" ]; then
        log_info "PeonPing plugin already installed at ${PEON_PLUGIN}"
        if prompt_yes_no "Reinstall PeonPing plugin?" "n"; then
            log_info "Reinstalling..."
        else
            log_info "Keeping existing PeonPing plugin"
            return 0
        fi
    fi
    
    local peon_adapter=""
    
    # Find the PeonPing adapter script (installer)
    if [ -f "${HOME}/.claude/hooks/peon-ping/adapters/opencode.sh" ]; then
        peon_adapter="${HOME}/.claude/hooks/peon-ping/adapters/opencode.sh"
    elif [ -f "/opt/homebrew/opt/peon-ping/libexec/adapters/opencode.sh" ]; then
        peon_adapter="/opt/homebrew/opt/peon-ping/libexec/adapters/opencode.sh"
    elif [ -f "/usr/local/opt/peon-ping/libexec/adapters/opencode.sh" ]; then
        peon_adapter="/usr/local/opt/peon-ping/libexec/adapters/opencode.sh"
    else
        log_warn "PeonPing adapter script not found"
        log_info "Downloading adapter directly..."
        
        # Download and run the adapter directly from GitHub
        mkdir -p "${OPENCODE_PLUGINS_DIR}"
        local ADAPTER_URL="https://raw.githubusercontent.com/PeonPing/peon-ping/main/adapters/opencode.sh"
        
        if command_exists curl; then
            log_info "Running PeonPing OpenCode adapter installer..."
            curl -fsSL "$ADAPTER_URL" | bash
            
            if [ -f "$PEON_PLUGIN" ]; then
                log_success "PeonPing plugin installed successfully"
            else
                log_error "Failed to install PeonPing plugin"
                return 1
            fi
        else
            log_error "curl is required to download the adapter"
            return 1
        fi
        return 0
    fi
    
    log_info "Found adapter: ${peon_adapter}"
    
    # Run the adapter installer
    # This downloads peon-ping.ts to ~/.config/opencode/plugins/
    # And creates config at ~/.config/opencode/peon-ping/config.json
    log_info "Running PeonPing OpenCode adapter installer..."
    run_cmd "bash ${peon_adapter}"
    
    if [ -f "$PEON_PLUGIN" ]; then
        log_success "PeonPing plugin installed successfully"
        echo ""
        echo "Plugin installed to:"
        echo "  - Plugin: ${OPENCODE_PLUGINS_DIR}/peon-ping.ts"
        echo "  - Config: ${XDG_CONFIG_HOME:-$HOME/.config}/opencode/peon-ping/config.json"
        echo "  - Packs:  ~/.openpeon/packs/"
        echo ""
        echo "Restart OpenCode to activate the plugin."
        echo ""
    else
        log_error "PeonPing plugin installation failed"
        return 1
    fi
}

# Setup JIRA OAuth2 credentials
setup_jira_oauth() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "              🔑 JIRA OAuth2 Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Prerequisites:"
    echo "  1. Create OAuth2 app at: https://developer.atlassian.com/console/myapps/"
    echo "  2. Add callback URL: http://localhost:8085/callback"
    echo "  3. Enable scopes: read:jira-work, write:jira-work, offline_access"
    echo ""

    # Check if already configured
    if [ -n "$JIRA_CLIENT_ID" ] && [ -n "$JIRA_ACCESS_TOKEN" ]; then
        echo "JIRA OAuth2 is already configured."
        echo "  Client ID: ${JIRA_CLIENT_ID:0:8}..."
        echo "  Access Token: ${JIRA_ACCESS_TOKEN:0:8}...${JIRA_ACCESS_TOKEN: -4}"
        echo ""
        if prompt_yes_no "Reconfigure?" "n"; then
            log_info "Reconfiguring..."
        else
            log_info "Keeping existing configuration"
            return 0
        fi
    fi

    # Step 1: Client ID
    echo "Step 1/4: Enter your OAuth2 Client ID"
    read -p "JIRA Client ID: " JIRA_CLIENT_ID
    
    if [ -z "$JIRA_CLIENT_ID" ]; then
        log_warn "No Client ID provided, skipping"
        return 1
    fi

    # Step 2: Client Secret
    echo ""
    echo "Step 2/4: Enter your OAuth2 Client Secret"
    read -s -p "JIRA Client Secret: " JIRA_CLIENT_SECRET
    echo ""

    if [ -z "$JIRA_CLIENT_SECRET" ]; then
        log_warn "No Client Secret provided, skipping"
        return 1
    fi

    # Step 3: Authorize
    echo ""
    echo "Step 3/4: Open this URL in your browser and authorize:"
    echo ""
    echo "  https://auth.atlassian.com/authorize?audience=api.atlassian.com&client_id=${JIRA_CLIENT_ID}&scope=read%3Ajira-work%20write%3Ajira-work%20offline_access&redirect_uri=http%3A%2F%2Flocalhost%3A8085%2Fcallback&response_type=code&prompt=consent"
    echo ""
    echo "After authorization, browser redirects to localhost:8085/callback?code=XXXXX"
    echo "Copy the 'code' value from the URL."
    echo ""

    # Step 4: Enter code
    echo "Step 4/4: Paste the authorization code"
    read -p "Authorization code: " auth_code

    if [ -z "$auth_code" ]; then
        log_error "No authorization code provided"
        return 1
    fi

    # Exchange code for tokens
    echo ""
    log_info "Exchanging code for tokens..."
    
    local token_response
    token_response=$(curl -s -X POST "https://auth.atlassian.com/oauth/token" \
        -H "Content-Type: application/json" \
        -d "{
            \"grant_type\": \"authorization_code\",
            \"client_id\": \"${JIRA_CLIENT_ID}\",
            \"client_secret\": \"${JIRA_CLIENT_SECRET}\",
            \"code\": \"${auth_code}\",
            \"redirect_uri\": \"http://localhost:8085/callback\"
        }")
    
    JIRA_ACCESS_TOKEN=$(echo "$token_response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    JIRA_REFRESH_TOKEN=$(echo "$token_response" | grep -o '"refresh_token":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$JIRA_ACCESS_TOKEN" ] || [ "$JIRA_ACCESS_TOKEN" = "null" ]; then
        log_error "Failed to obtain tokens"
        echo "Response: $token_response"
        return 1
    fi

    log_success "Tokens obtained"
    
    # Get cloud ID
    log_info "Fetching Cloud ID..."
    JIRA_CLOUD_ID=$(curl -s -H "Authorization: Bearer ${JIRA_ACCESS_TOKEN}" \
        "https://api.atlassian.com/oauth/token/accessible-resources" | \
        grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    log_success "JIRA OAuth2 configured"
    echo ""
    echo "Summary:"
    echo "  Client ID: ${JIRA_CLIENT_ID:0:8}..."
    echo "  Access Token: ${JIRA_ACCESS_TOKEN:0:8}...${JIRA_ACCESS_TOKEN: -4}"
    echo "  Cloud ID: ${JIRA_CLOUD_ID:-<not set>}"
    echo ""
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

    # Check platform and install accordingly
    case "$DETECTED_OS" in
        Windows*|Windows-GitBash)
            # Windows: Check if Node.js is already installed
            if command_exists node; then
                log_info "Node.js is already installed ($(node --version))"

                if prompt_yes_no "Install a newer version of Node.js?" "n"; then
                    log_info "To install/update Node.js on Windows:"
                    echo "  1. Download from https://nodejs.org/"
                    echo "  2. Use winget: winget install OpenJS.NodeJS.LTS"
                    echo "  3. Use chocolatey: choco install nodejs"
                    echo "  4. Follow the installer prompts"
                fi
            else
                log_info "Node.js is not installed on Windows"
                echo ""
                echo "To install Node.js on Windows:"
                echo "  Option 1: Download from https://nodejs.org/"
                echo "  Option 2: Use winget (Windows 10+):"
                echo "           winget install OpenJS.NodeJS.LTS"
                echo "  Option 3: Use chocolatey:"
                echo "           choco install nodejs"
                echo ""

                if prompt_yes_no "Would you like to install Node.js now?" "y"; then
                    if command_exists winget; then
                        log_info "Installing Node.js via winget..."
                        run_cmd "winget install OpenJS.NodeJS.LTS"
                    elif command_exists choco; then
                        log_info "Installing Node.js via chocolatey..."
                        run_cmd "choco install nodejs"
                    else
                        log_error "No package manager found (winget or chocolatey)"
                        log_info "Please install Node.js manually from https://nodejs.org/"
                    fi
                fi
            fi
            ;;

        macOS|Linux*)
            # Unix-like systems: Use nvm
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
        else
            log_error "Node.js installation failed"
            return 1
        fi
        else
            log_info "Skipping Node.js v24 installation"
        fi
        ;;
    esac

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

    # Copy AGENTS.md from project to global config
    if [ -f "${SCRIPT_DIR}/.AGENTS.md" ]; then
        if [ -f "${CONFIG_DIR}/AGENTS.md" ]; then
            log_warn "AGENTS.md already exists at ${CONFIG_DIR}/AGENTS.md"
            if prompt_yes_no "Do you want to overwrite it?" "n"; then
                create_backup "${CONFIG_DIR}/AGENTS.md"
                run_cmd "cp ${SCRIPT_DIR}/.AGENTS.md ${CONFIG_DIR}/AGENTS.md"
                log_success "AGENTS.md copied successfully (renamed from .AGENTS.md)"
            fi
        else
            run_cmd "cp ${SCRIPT_DIR}/.AGENTS.md ${CONFIG_DIR}/AGENTS.md"
            log_success "AGENTS.md copied successfully (renamed from .AGENTS.md)"
        fi
    else
        log_warn ".AGENTS.md not found in ${SCRIPT_DIR}"
    fi

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
            echo "✓ Configured 5 agents:"
            echo "    - build (default) - Full-featured coding agent"
            echo "    - plan - Planning agent (read-only)"
            echo "    - explore - Codebase exploration and analysis"
            echo "    - image-analyzer - Image/screenshot analysis"
            echo "    - diagram-creator - Diagram creation"
            echo ""
            echo "✓ Configured 5 MCP servers:"
            echo "    Local (auto-start): atlassian, zai-mcp-server"
            echo "    Remote (needs key): web-reader, web-search-prime, zread"
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
        echo "✓ Deployed 51 skills:"
        echo "    - Framework (9):"
        echo "      - test-generator-framework"
        echo "      - linting-workflow"
        echo "      - pr-creation-workflow"
        echo "      - jira-git-integration"
        echo "      - ticket-branch-workflow"
        echo "      - error-resolver-workflow"
        echo "      - tdd-workflow"
        echo "      - coverage-framework"
        echo "      - docx-creation"
        echo "    - Language-Specific (4):"
        echo "      - python-pytest-creator"
        echo "      - python-ruff-linter"
        echo "      - python-docstring-generator"
        echo "      - javascript-eslint-linter"
        echo "    - Framework-Specific (7):"
        echo "      - nextjs-pr-workflow"
        echo "      - nextjs-unit-test-creator"
        echo "      - nextjs-standard-setup"
        echo "      - nextjs-complete-setup"
        echo "      - nextjs-image-usage"
        echo "      - nextjs-tsdoc-documentor"
        echo "      - typescript-dry-principle"
        echo "    - OpenCode Meta (4):"
        echo "      - opencode-agent-creation"
        echo "      - opencode-skill-creation"
        echo "      - opencode-skill-auditor"
        echo "      - opencode-skills-maintainer"
        echo "    - OpenTofu (7):"
        echo "      - opentofu-aws-explorer"
        echo "      - opentofu-keycloak-explorer"
        echo "      - opentofu-kubernetes-explorer"
        echo "      - opentofu-neon-explorer"
        echo "      - opentofu-provider-setup"
        echo "      - opentofu-provisioning-workflow"
        echo "      - opentofu-ecr-provision"
        echo "    - Git/Workflow (8):"
        echo "      - ascii-diagram-creator"
        echo "      - git-issue-creator"
        echo "      - git-pr-creator"
        echo "      - git-issue-labeler"
        echo "      - git-issue-plan-workflow"
        echo "      - git-issue-updater"
        echo "      - git-semantic-commits"
        echo "      - jira-git-workflow"
        echo "    - Documentation (2):"
        echo "      - coverage-readme-workflow"
        echo "      - docstring-generator"
        echo "    - JIRA (4):"
        echo "      - jira-ticket-oauth-workflow"
        echo "      - jira-ticket-plan-workflow"
        echo "      - jira-status-updater"
        echo "      - jira-ticket-workflow"
        echo "    - Code Quality (7):"
        echo "      - solid-principles"
        echo "      - clean-code"
        echo "      - clean-architecture"
        echo "      - design-patterns"
        echo "      - object-design"
        echo "      - code-smells"
        echo "      - complexity-management"
        echo ""
        echo "  Run 'opencode --list-skills' for detailed descriptions"
        echo ""
    else
        log_warn "skills/ folder not found in ${SCRIPT_DIR}"
    fi

    return 0
}

deploy_agents() {
    echo ""
    log_info "Setting up agents directory..."

    if [ -d "${AGENTS_DEST_DIR}" ]; then
        if [ "$(ls -A ${AGENTS_DEST_DIR} 2>/dev/null)" ]; then
            log_warn "Agents directory already contains files"

            if ! prompt_yes_no "Do you want to overwrite existing agents?" "n"; then
                log_info "Skipping agents deployment. Existing agents preserved."
                return 0
            fi

            if [ ! -d "${BACKUP_DIR}" ]; then
                mkdir -p "${BACKUP_DIR}"
            fi
            run_cmd "cp -r ${AGENTS_DEST_DIR} ${BACKUP_DIR}/agents-backup"
            log_info "Backed up existing agents to ${BACKUP_DIR}/agents-backup"
        fi
    fi

    run_cmd "mkdir -p ${AGENTS_DEST_DIR}"
    log_info "Created ${AGENTS_DEST_DIR} directory"

    if [ -d "${AGENTS_SRC_DIR}" ]; then
        local primary_count=0
        local subagent_count=0

        # Copy primary agents (flat into agents/)
        if [ -d "${AGENTS_SRC_DIR}/primary" ]; then
            for agent_file in "${AGENTS_SRC_DIR}"/primary/*.md; do
                if [ -f "$agent_file" ]; then
                    local filename=$(basename "$agent_file")
                    run_cmd "cp ${agent_file} ${AGENTS_DEST_DIR}/${filename}"
                    primary_count=$((primary_count + 1))
                fi
            done
        fi

        # Copy subagents (flat into agents/)
        if [ -d "${AGENTS_SRC_DIR}/subagents" ]; then
            for agent_file in "${AGENTS_SRC_DIR}"/subagents/*.md; do
                if [ -f "$agent_file" ]; then
                    local filename=$(basename "$agent_file")
                    run_cmd "cp ${agent_file} ${AGENTS_DEST_DIR}/${filename}"
                    subagent_count=$((subagent_count + 1))
                fi
            done
        else
            log_warn "agents/subagents/ directory not found in ${SCRIPT_DIR}"
        fi

        local total_count=$((primary_count + subagent_count))
        log_success "Agents copied successfully to ${AGENTS_DEST_DIR}"

        echo ""
        echo "✓ Deployed ${total_count} agent files:"
        echo "    - ${primary_count} primary agents"
        echo "    - ${subagent_count} subagents"
        echo ""
        echo "  Run 'opencode --list-agents' for details"
        echo ""
    else
        log_warn "agents/ folder not found in ${SCRIPT_DIR}"
    fi
}

# Check if running on Windows (native or Git Bash)
is_windows() {
    case "$DETECTED_OS" in
        Windows*|Windows-GitBash) return 0 ;;
        *) return 1 ;;
    esac
}

# Set a user-level environment variable on Windows using setx
# Falls back gracefully if setx is not available
setx_env() {
    local key="$1"
    local value="$2"

    if ! command_exists setx; then
        log_warn "setx not found - skipping system env var for ${key}"
        return 1
    fi

    log_debug "Setting Windows env var: ${key} via setx"
    setx "$key" "$value" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_success "${key} set via setx (available in new terminals)"
    else
        log_warn "setx failed for ${key}"
        return 1
    fi
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
    if is_windows; then
        echo "Platform: Windows (using setx for system-wide env vars)"
    fi
    echo ""

    # On Windows, use setx for system-wide access (all shells + opencode)
    # On non-Windows, use shell config file (bashrc/zshrc)
    if is_windows; then
        log_info "Windows detected: setting env vars via setx (available in all terminals)"
    fi

    # Add ZAI_API_KEY
    if [ -n "$ZAI_API_KEY" ]; then
        if is_windows; then
            setx_env "ZAI_API_KEY" "${ZAI_API_KEY}"
            export ZAI_API_KEY="${ZAI_API_KEY}"
        else
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
    fi

    # Add JIRA OAuth2 credentials
    if [ -n "$JIRA_CLIENT_ID" ]; then
        if is_windows; then
            setx_env "JIRA_CLIENT_ID" "${JIRA_CLIENT_ID}"
            setx_env "JIRA_CLIENT_SECRET" "${JIRA_CLIENT_SECRET}"
            setx_env "JIRA_ACCESS_TOKEN" "${JIRA_ACCESS_TOKEN}"
            setx_env "JIRA_REFRESH_TOKEN" "${JIRA_REFRESH_TOKEN}"
            if [ -n "$JIRA_CLOUD_ID" ]; then
                setx_env "JIRA_CLOUD_ID" "${JIRA_CLOUD_ID}"
            fi
            export JIRA_CLIENT_ID="${JIRA_CLIENT_ID}"
            export JIRA_CLIENT_SECRET="${JIRA_CLIENT_SECRET}"
            export JIRA_ACCESS_TOKEN="${JIRA_ACCESS_TOKEN}"
            export JIRA_REFRESH_TOKEN="${JIRA_REFRESH_TOKEN}"
            export JIRA_CLOUD_ID="${JIRA_CLOUD_ID:-}"
        else
            local jira_vars_missing=false
            
            if ! grep -q "JIRA_CLIENT_ID" "$SHELL_CONFIG_FILE" 2>/dev/null; then
                jira_vars_missing=true
            fi
            
            if [ "$jira_vars_missing" = true ]; then
                if prompt_yes_no "Add JIRA OAuth2 credentials to $(basename ${SHELL_CONFIG_FILE})?" "y"; then
                    create_backup "$SHELL_CONFIG_FILE"
                    
                    run_cmd "echo '' >> ${SHELL_CONFIG_FILE}"
                    run_cmd "echo '# JIRA OAuth2 Configuration' >> ${SHELL_CONFIG_FILE}"
                    run_cmd "echo 'export JIRA_CLIENT_ID=\"${JIRA_CLIENT_ID}\"' >> ${SHELL_CONFIG_FILE}"
                    run_cmd "echo 'export JIRA_CLIENT_SECRET=\"${JIRA_CLIENT_SECRET}\"' >> ${SHELL_CONFIG_FILE}"
                    run_cmd "echo 'export JIRA_ACCESS_TOKEN=\"${JIRA_ACCESS_TOKEN}\"' >> ${SHELL_CONFIG_FILE}"
                    run_cmd "echo 'export JIRA_REFRESH_TOKEN=\"${JIRA_REFRESH_TOKEN}\"' >> ${SHELL_CONFIG_FILE}"
                    
                    if [ -n "$JIRA_CLOUD_ID" ]; then
                        run_cmd "echo 'export JIRA_CLOUD_ID=\"${JIRA_CLOUD_ID}\"' >> ${SHELL_CONFIG_FILE}"
                    fi
                    
                    log_success "JIRA OAuth2 credentials added to ${SHELL_CONFIG_FILE}"
                else
                    log_info "Skipping shell config update for JIRA OAuth2"
                fi
            else
                log_info "JIRA OAuth2 credentials already exist in ${SHELL_CONFIG_FILE}"
                
                if prompt_yes_no "Update existing JIRA tokens?" "n"; then
                    create_backup "$SHELL_CONFIG_FILE"
                    
                    local temp_file="${SHELL_CONFIG_FILE}.tmp"
                    grep -v "^export JIRA_" "$SHELL_CONFIG_FILE" > "$temp_file" 2>/dev/null || true
                    
                    echo '' >> "$temp_file"
                    echo '# JIRA OAuth2 Configuration' >> "$temp_file"
                    echo "export JIRA_CLIENT_ID=\"${JIRA_CLIENT_ID}\"" >> "$temp_file"
                    echo "export JIRA_CLIENT_SECRET=\"${JIRA_CLIENT_SECRET}\"" >> "$temp_file"
                    echo "export JIRA_ACCESS_TOKEN=\"${JIRA_ACCESS_TOKEN}\"" >> "$temp_file"
                    echo "export JIRA_REFRESH_TOKEN=\"${JIRA_REFRESH_TOKEN}\"" >> "$temp_file"
                    
                    if [ -n "$JIRA_CLOUD_ID" ]; then
                        echo "export JIRA_CLOUD_ID=\"${JIRA_CLOUD_ID}\"" >> "$temp_file"
                    fi
                    
                    mv "$temp_file" "$SHELL_CONFIG_FILE"
                    log_success "JIRA OAuth2 tokens updated in ${SHELL_CONFIG_FILE}"
                fi
            fi
        fi
    fi

    return 0
}

################################################################################
# AUTO-UPDATE FUNCTIONS
################################################################################

# Update last check time
update_last_check_time() {
    local timestamp=$(date +%s)
    echo "$timestamp" > "$LAST_UPDATE_CHECK"
    log_debug "Updated last check time: $(date -d @$timestamp)"
}

# Check if enough time has passed since last check
should_check_for_updates() {
    if [ ! -f "$LAST_UPDATE_CHECK" ]; then
        log_debug "No last check file found, should check for updates"
        return 0
    fi

    local last_check=$(cat "$LAST_UPDATE_CHECK" 2>/dev/null || echo "0")
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_check))

    # Time intervals in seconds
    local daily=86400        # 24 * 60 * 60
    local weekly=604800      # 7 * 24 * 60 * 60
    local monthly=2592000    # 30 * 24 * 60 * 60

    case "$UPDATE_SCHEDULE" in
        daily)
            return $((time_diff >= daily))
            ;;
        weekly)
            return $((time_diff >= weekly))
            ;;
        monthly)
            return $((time_diff >= monthly))
            ;;
        manual)
            return 0
            ;;
        *)
            # Default to weekly
            return $((time_diff >= weekly))
            ;;
    esac
}

# Create backup before update
create_backup_before_update() {
    log_info "Creating backup before update..."

    local backup_dir="${HOME}/.opencode-update-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir" 2>/dev/null

    # Backup config
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "${backup_dir}/config.json"
        log_info "Backed up: ${CONFIG_FILE}"
    fi

    # Backup AGENTS.md if it exists
    if [ -f "${CONFIG_DIR}/AGENTS.md" ]; then
        cp "${CONFIG_DIR}/AGENTS.md" "${backup_dir}/AGENTS.md"
        log_info "Backed up: ${CONFIG_DIR}/AGENTS.md"
    fi

    # Backup skills directory if it exists
    if [ -d "$SKILLS_DIR" ]; then
        cp -r "$SKILLS_DIR" "${backup_dir}/skills"
        log_info "Backed up: ${SKILLS_DIR}"
    fi

    log_success "Backup created at: ${backup_dir}"
    echo "" >> "$UPDATE_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup created: ${backup_dir}" >> "$UPDATE_LOG"
}

# Check for updates only (don't install)
check_for_updates_only() {
    log_info "Checking for opencode-ai updates..."

    # Check if enough time has passed
    if ! should_check_for_updates; then
        log_info "Skipping update check (scheduled time not reached)"
        return 0
    fi

    # Get current version
    local current_version
    if ! command_exists opencode; then
        log_warn "opencode-ai is not installed"
        return 1
    fi
    current_version=$(opencode --version 2>/dev/null || echo "unknown")

    # Get latest version
    local latest_version
    latest_version=$(npm view opencode-ai version 2>/dev/null || echo "unknown")

    if [ "$latest_version" = "unknown" ]; then
        log_error "Could not fetch latest version from npm registry"
        return 1
    fi

    log_info "Current version: v${current_version}"
    log_info "Latest version: v${latest_version}"

    # Compare versions
    if [ "$current_version" = "$latest_version" ]; then
        log_success "opencode-ai is already up to date!"
    else
        log_info "Update available: v${current_version} → v${latest_version}"
        log_info "Run: ./setup.sh -A -S <daily|weekly|monthly> to enable auto-updates"
    fi

    update_last_check_time
    echo "" >> "$UPDATE_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Update check: v${current_version} (latest: v${latest_version})" >> "$UPDATE_LOG"
}

# Perform auto-update
auto_update_opencode() {
    # Check if auto-update is enabled
    if [ "$ENABLE_AUTO_UPDATE" = false ]; then
        log_info "Auto-update is disabled"
        return 0
    fi

    # Check if enough time has passed
    if ! should_check_for_updates; then
        log_info "Skipping auto-update (scheduled time not reached)"
        return 0
    fi

    log_info "Checking for opencode-ai updates..."

    # Get current version
    local current_version
    if ! command_exists opencode; then
        log_warn "opencode-ai is not installed"
        return 1
    fi
    current_version=$(opencode --version 2>/dev/null || echo "unknown")

    # Get latest version
    local latest_version
    latest_version=$(npm view opencode-ai version 2>/dev/null || echo "unknown")

    if [ "$latest_version" = "unknown" ]; then
        log_error "Could not fetch latest version from npm registry"
        log_info "Check your internet connection and try again"
        return 1
    fi

    log_info "Current version: v${current_version}"
    log_info "Latest version: v${latest_version}"

    # Check if update is needed
    if [ "$current_version" = "$latest_version" ]; then
        log_success "opencode-ai is already up to date!"
        update_last_check_time
        return 0
    fi

    log_info "Update available: v${current_version} → v${latest_version}"

    # Create backup before update
    create_backup_before_update

    # Perform update
    log_info "Auto-updating opencode-ai to v${latest_version}..."
    run_cmd "npm install -g opencode-ai@${latest_version}"

    # Verify update
    local new_version
    new_version=$(opencode --version 2>/dev/null || echo "unknown")

    if [ "$new_version" = "$latest_version" ]; then
        log_success "opencode-ai updated successfully to v${new_version}"
        update_last_check_time
    else
        log_error "Update failed. Current version: v${new_version}"
        return 1
    fi

    echo "" >> "$UPDATE_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto-update: v${current_version} → v${new_version}" >> "$UPDATE_LOG"
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

    # nvm status (Unix-like systems only)
    if command_exists nvm; then
        nvm_version=$(nvm --version 2>/dev/null)
        echo "✓ nvm: Installed v${nvm_version}"
    else
        case "$DETECTED_OS" in
            Windows*|Windows-GitBash)
                # On Windows, nvm is not used
                ;;
            *)
                echo "✗ nvm: Not installed"
                ;;
        esac
    fi

    # Package manager status
    if [ "$PACKAGE_MANAGER" != "none" ]; then
        echo "✓ Package Manager: ${PACKAGE_MANAGER}"
        # Show distribution for Linux
        case "$DETECTED_OS" in
            Linux*)
                if [ -n "$DISTRIBUTION_NAME" ] && [ "$DISTRIBUTION_NAME" != "unknown" ]; then
                    echo "  Distribution: ${DISTRIBUTION_NAME}"
                fi
                ;;
        esac
    else
        case "$DETECTED_OS" in
            Windows*|Windows-GitBash)
                echo "○ Package Manager: Not detected (use winget or chocolatey)"
                ;;
            *)
                echo "✗ Package Manager: Not detected"
                ;;
        esac
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
        echo "    - Default agent: build"
    else
        echo "✗ config.json: Not copied"
    fi

    # Agents configured
    if [ -f "$CONFIG_FILE" ]; then
        echo "✓ Configured 5 agents:"
        echo "    - build (default) - Full-featured coding agent"
        echo "    - plan - Planning agent (read-only)"
        echo "    - explore - Codebase exploration and analysis"
        echo "    - image-analyzer - Image/screenshot analysis"
        echo "    - diagram-creator - Diagram creation"
    fi

    # MCP servers configured
    if [ -f "$CONFIG_FILE" ]; then
        echo "✓ Configured 5 MCP servers:"
        echo "    - atlassian - JIRA and Confluence integration (auto-start)"
        echo "    - web-reader - Web page reading (needs ZAI_API_KEY)"
        echo "    - web-search-prime - Web search (needs ZAI_API_KEY)"
        echo "    - zai-mcp-server - Image analysis (auto-start)"
        echo "    - zread - GitHub repo search (needs ZAI_API_KEY)"
    fi

    # skills directory status
    if [ -d "$SKILLS_DIR" ] && [ "$(ls -A ${SKILLS_DIR} 2>/dev/null)" ]; then
        local skill_count=$(find ${SKILLS_DIR} -name "SKILL.md" 2>/dev/null | wc -l)
        echo "✓ skills: ${skill_count} skills deployed to ${SKILLS_DIR}/"
        echo "    - Framework (9):"
        echo "      - test-generator-framework"
        echo "      - linting-workflow"
        echo "      - pr-creation-workflow"
        echo "      - jira-git-integration"
        echo "      - ticket-branch-workflow"
        echo "      - error-resolver-workflow"
        echo "      - tdd-workflow"
        echo "      - coverage-framework"
        echo "      - docx-creation"
        echo "    - Language-Specific (4):"
        echo "      - python-pytest-creator"
        echo "      - python-ruff-linter"
        echo "      - python-docstring-generator"
        echo "      - javascript-eslint-linter"
        echo "    - Framework-Specific (7):"
        echo "      - nextjs-pr-workflow"
        echo "      - nextjs-unit-test-creator"
        echo "      - nextjs-standard-setup"
        echo "      - nextjs-complete-setup"
        echo "      - nextjs-image-usage"
        echo "      - nextjs-tsdoc-documentor"
        echo "      - typescript-dry-principle"
        echo "    - OpenCode Meta (4):"
        echo "      - opencode-agent-creation"
        echo "      - opencode-skill-creation"
        echo "      - opencode-skill-auditor"
        echo "      - opencode-skills-maintainer"
        echo "    - OpenTofu (7):"
        echo "      - opentofu-aws-explorer"
        echo "      - opentofu-keycloak-explorer"
        echo "      - opentofu-kubernetes-explorer"
        echo "      - opentofu-neon-explorer"
        echo "      - opentofu-provider-setup"
        echo "      - opentofu-provisioning-workflow"
        echo "      - opentofu-ecr-provision"
        echo "    - Git/Workflow (8):"
        echo "      - ascii-diagram-creator"
        echo "      - git-issue-creator"
        echo "      - git-pr-creator"
        echo "      - git-issue-labeler"
        echo "      - git-issue-plan-workflow"
        echo "      - git-issue-updater"
        echo "      - git-semantic-commits"
        echo "      - jira-git-workflow"
        echo "    - Documentation (2):"
        echo "      - coverage-readme-workflow"
        echo "      - docstring-generator"
        echo "    - JIRA (4):"
        echo "      - jira-ticket-oauth-workflow"
        echo "      - jira-ticket-plan-workflow"
        echo "      - jira-status-updater"
        echo "      - jira-ticket-workflow"
        echo "    - Code Quality (7):"
        echo "      - solid-principles"
        echo "      - clean-code"
        echo "      - clean-architecture"
        echo "      - design-patterns"
        echo "      - object-design"
        echo "      - code-smells"
        echo "      - complexity-management"
    else
        echo "✗ skills: Not deployed"
    fi

    # ZAI_API_KEY status
    if is_windows && command_exists setx; then
        if [ -n "$ZAI_API_KEY" ]; then
            echo "✓ ZAI_API_KEY: Set via setx (system-wide)"
        else
            echo "✗ ZAI_API_KEY: Not configured"
        fi
    elif grep -q "ZAI_API_KEY" "$SHELL_CONFIG_FILE" 2>/dev/null; then
        echo "✓ ZAI_API_KEY: Added to ${SHELL_CONFIG_FILE}"
    elif [ -n "$ZAI_API_KEY" ]; then
        echo "○ ZAI_API_KEY: Set in current session only"
    else
        echo "✗ ZAI_API_KEY: Not configured"
    fi

    # GitHub CLI status
    if command_exists gh; then
        if gh auth status >/dev/null 2>&1; then
            echo "✓ GitHub CLI: Installed and authenticated"
        else
            echo "○ GitHub CLI: Installed but not authenticated (run: gh auth login)"
        fi
    else
        echo "○ GitHub CLI: Not installed (https://cli.github.com/)"
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
    if is_windows; then
        echo "     (Environment variables were set via setx - open a NEW terminal to use them)"
    fi
    echo "  2. Start LM Studio: http://127.0.0.1:1234/v1"
    echo "  3. Verify installation: opencode --version"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                        🚀 Quick Start"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🤖 Agents (5):"
    echo "  - build (default) - Full-featured coding agent"
    echo "  - plan - Planning agent (read-only)"
    echo "  - explore - Fast codebase exploration and analysis"
    echo "  - image-analyzer - Images/screenshots to code, OCR, error diagnosis"
    echo "  - diagram-creator - Diagrams (architecture, flowcharts, UML)"
    echo ""
    echo "  Usage: opencode --agent <name> \"prompt\""
    echo "         opencode \"prompt\" (uses build)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                     📦 49 Skills Available"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Framework (7) • Language-Specific (4) • Framework-Specific (7)"
    echo "  OpenCode Meta (4) • OpenTofu (7) • Git/Workflow (7)"
    echo "  Documentation (2) • JIRA (4) • Code Quality (7)"
    echo ""
    echo "  Run 'opencode --list-skills' for detailed descriptions"
    echo "  Run 'opencode --skill <name> \"prompt\"' to use a skill"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                     🔌 MCP Servers (5)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Local (auto-start): atlassian, zai-mcp-server"
    echo "  Remote (needs key): web-reader, web-search-prime, zread"
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

    # Check for update command
    if [ "$CHECK_UPDATE_ONLY" = true ]; then
        check_for_updates_only
        exit 0
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

    # Auto-update check (run before main menu)
    if [ "$AUTO_ACCEPT" = true ] || [ "$CHECK_UPDATE_ONLY" = false ]; then
        if [ "$ENABLE_AUTO_UPDATE" = true ]; then
            log_info "Auto-update is enabled (schedule: ${UPDATE_SCHEDULE})"
            auto_update_opencode
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
        echo "  5) Configure JIRA OAuth2"
        echo "  6) Install PeonPing (sound notifications)"
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
            5)
                echo ""
                log_info "JIRA OAuth2 Configuration"
                setup_jira_oauth || true
                setup_shell_vars || true
                print_summary
                echo ""
                echo "JIRA OAuth2 configuration complete!"
                exit 0
                ;;
            6)
                echo ""
                log_info "PeonPing Sound Notifications"
                setup_peonping || true
                echo ""
                echo "PeonPing setup complete!"
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
        setup_github_cli || true
        setup_zai_api_key || true
        setup_nvm || true
        setup_nodejs || true
        setup_opencode || true
    else
        if [ "$QUICK_SETUP" = true ]; then
            log_info "Running quick setup: config.json and skills deployment only"
        fi
    fi

    setup_config || true
    deploy_agents || true
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

# Update standard agents if they exist in config
for agent in ['build', 'plan']:
    if agent in config.get('agent', {}):
        old_prompt = config['agent'][agent].get('prompt', '')
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

