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
#   ./setup.sh --rollback [TARGET]  Restore ~/.config/opencode/ from a previous backup
#                                   TARGET: TIMESTAMP | VERSION | latest | list
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
#   --rollback [TARGET] Restore from previous backup (see SETUP MODES above)
#   --no-zip-backup     Skip zip archive creation after flat-file backup
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

# Resolve directories (setup.sh lives in deploy/, repo root is one level up)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read version from VERSION file
VERSION_FILE="${REPO_DIR}/VERSION"
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
AGENTS_SRC_DIR="${REPO_DIR}/opencode_app/.opencode/agents"
AGENTS_DEST_DIR="${CONFIG_DIR}/agents"
BACKUP_DIR="${HOME}/.opencode-backup-$(date +%Y%m%d_%H%M%S)"
LAST_UPDATE_CHECK="${CONFIG_DIR}/.last-update-check"
UPDATE_LOG="${CONFIG_DIR}/update.log"

# v2.0 model resolution (tier-based, provider-agnostic)
DEPLOY_DIR="${REPO_DIR}/deploy"
RESOLVER_SCRIPT="${DEPLOY_DIR}/resolve-models.mjs"
TUI_SCRIPT="${DEPLOY_DIR}/tui.mjs"
AGENT_TIERS="${DEPLOY_DIR}/agent-tiers.json"
MODELS_DEFAULT_MAP="${DEPLOY_DIR}/models.default.json"
PROVIDER_PRESETS="${DEPLOY_DIR}/provider-presets.json"
# Global user overrides (~/.config/opencode/)
USER_MODELS_MAP="${CONFIG_DIR}/models.json"
USER_OVERRIDES="${CONFIG_DIR}/agent-overrides.json"
# Project-local overrides (repo root .opencode/)
PROJECT_MODELS_MAP="${REPO_DIR}/.opencode/models.json"
PROJECT_OVERRIDES="${REPO_DIR}/.opencode/agent-overrides.json"
# Resolver state + migration marker
RESOLVED_SIDECAR="${CONFIG_DIR}/.resolved-models.json"
CONFIG_VERSION_FILE="${CONFIG_DIR}/.config-version"
SCHEMA_VERSION="2.0"
SOURCE_CONFIG="${REPO_DIR}/opencode_app/opencode.json"
# Where dry-run stages complete resolved files (mirrors what would land in ~/.config)
DRY_RUN_PREVIEW_DIR="${CONFIG_DIR}/.dry-run-preview"

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
            # ${OS:-} guards against nounset abort when $OS is not exported
            if [ -n "${OS:-}" ] && [[ "$OS" == "Windows_NT" ]]; then
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
        apt:*|dnf:*|pacman:*)
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
KEEP_BACKUPS=5

# Rollback mode (set by --rollback)
ROLLBACK_MODE=false
ROLLBACK_TARGET=""
# Zip backup toggle (default on; --no-zip-backup disables)
ZIP_BACKUP=true
# v2.0 model-resolution flags
PROVIDER=""              # --provider <preset>
MODELS_ONLY=false        # --models-only (provider + resolve only)
FORCE_RESOLVE=false      # --force (ignore preserve-edits)
MIGRATE_ONLY=false       # --migrate (migration + resolve only)
MIX_MODE=false           # --mix (per-category provider/model editor)

# API Keys (initialize to empty to avoid unbound variable errors)
# Capture from environment if they exist
GITHUB_PAT=""
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

    # Print the call stack so the user can see WHERE the failure happened.
    # FUNCNAME / BASH_LINENO / BASH_SOURCE are parallel arrays — same length,
    # indexed from the innermost (current) function outward.
    if [ "${#FUNCNAME[@]}" -gt 1 ]; then
        log_error "Call stack:"
        local i
        for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
            log_error "  ${BASH_SOURCE[$i]:-setup.sh}:${BASH_LINENO[$((i-1))]:-?}  ${FUNCNAME[$i]}"
        done
    fi

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

# Trap errors — capture the actual failing line via BASH_LINENO, not the trap
# definition site. Without this, every error reports the trap's own line number.
trap 'error_handler "${BASH_LINENO[0]}" "$?"' ERR

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

  --rollback [TARGET]     Restore from a previous backup         Undo a bad deploy
                          TARGET:
                            (omitted)   Interactive picker
                            TIMESTAMP   e.g. 20260719_070926
                            VERSION     e.g. 1.76.0 (closest backup <= tag)
                            latest      Most recent backup
                            list        List available backups and exit
                          Safety: creates a pre-rollback backup first
                          Combine with --yes to skip confirmation prompt

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            OPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  SETUP OPTIONS:
    -q, --quick           Quick setup mode (config + skills only, no dependencies)
    -s, --skills-only     Skills-only deployment mode
    -u, --update          Update OpenCode CLI to latest version
    --rollback [TARGET]   Restore from previous backup (see SETUP MODES above)

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
    -k, --keep-backups <N>  Keep only N most recent backups (default: 5)
                            0 = delete all old backups, negative = keep all
    --no-zip-backup       Skip zip archive creation (zip is created by default
                            alongside the flat-file backup for portability)

  MODEL RESOLUTION (v2.0):
    --provider <name>     Non-interactive provider preset: zai|anthropic|openai|
                          openrouter|lmstudio (writes ~/.config/opencode/models.json)
    --models-only         Provider selection + model resolution only (no other setup)
    --migrate             Run v1.x -> v2.0 migration + model resolution only
    --force               Re-resolve all agents (ignore preserved hand-edits)
    --mix                 Per-category provider/model editor (mix providers across
                          primary/reasoning/fast/docs/vision, e.g. vision on OpenAI)

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

  Backup and rollback:
    ./setup.sh --rollback list      # List available backups (timestamp + size + zip)
    ./setup.sh --rollback latest    # Restore from most recent backup
    ./setup.sh --rollback 20260719_070926  # Restore from specific timestamp
    ./setup.sh --rollback 1.76.0    # Restore from backup closest to version 1.76.0
    ./setup.sh --rollback           # Interactive picker
    ./setup.sh --rollback latest -y # Restore without confirmation prompt
    ./setup.sh --rollback latest -d # Dry-run: preview restore, change nothing
    ./setup.sh --no-zip-backup      # Deploy without creating zip archive

  Note: Every deploy creates BOTH a flat-file backup (~/.opencode-backup-TIMESTAMP/)
        AND a zip archive (~/.opencode-backup-TIMESTAMP.zip) for portability.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                         CONFIGURED FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   AGENTS (39):
    build (default)      Full-featured coding agent with all tools
    plan                 Planning agent (read-only, edits need approval)
    explore              Fast codebase exploration and analysis
    general              General-purpose multi-step research
    scout                External docs and dependency research
    explorer             Codebase exploration and analysis (subagent)
    code-review          Code review with SOLID/clean-code analysis
    python-reviewer      Python code review (PEP 8, type hints, async)
    typescript-reviewer  TypeScript/JS code review (type safety, React/Next)
    go-reviewer          Go code review (idioms, concurrency, errors)
    rust-reviewer        Rust code review (ownership, unsafe, Result/Option)
    java-reviewer        Java code review (Effective Java, concurrency, Spring)
    testing              Test generation with framework detection
    pr-workflow          PR creation with quality gates and JIRA integration
    linting              Code linting with auto-fix for Python/JS/TS
    repo-ops-specialist  Git repository operations (release, branch protection, labels)
    architecture-review  Architecture review with clean architecture principles
    tdd                  Test Driven Development workflow guidance
    coverage             Test coverage reporting and badges
    documentation        Docstring generation (PEP 257, JSDoc, Javadoc)
    loop-operator        Autonomous loop execution with self-correction
    pptx-specialist      PowerPoint orchestration (routes to generate-slide/template-modifier)
    docx-creation        Word document creation and manipulation
    xlsx-specialist      Spreadsheet creation and analysis
    image-analyzer       Images/screenshots to code, OCR, error diagnosis
    error-resolver       Error diagnosis with stack trace analysis
    opencode-tooling     OpenCode config creation and maintenance
    ticket-creation      GitHub issues and JIRA ticket management
    startup-founder      Startup founder business operations agent
    startup-ceo          Investor-ready pitch decks and board updates
    office-document      Office document specialist: Word, PowerPoint, Excel
    google-mcp           Google Cloud MCP (BigQuery, Maps, GCE, GKE)
    microsoft-m365       Microsoft 365 MCP (Teams, Mail, Calendar, SharePoint, etc.)
     nextjs-specialist  Next.js scaffolding + runtime MCP diagnosis
    opentofu-explorer    OpenTofu/Terraform infrastructure management
    cad-specialist       CAD, robotics, hardware design orchestration
    discovery-specialist Customer-facing discovery: Vision docs + wireframes
    requirements-specialist  BRD + SRS drafting (BABOK/IIBA + IEEE 830)
    technical-design-specialist  Technical design + ADRs (engineering 'how' stage)

    Usage: opencode --agent build "implement auth feature"
           opencode --agent explore "find all API routes"

  MCP SERVERS (26):
    Auto-start (local npx servers):
      codegraph           Pre-indexed code knowledge graph (100% local)
      atlassian          JIRA and Confluence integration
      zai-vision-mcp-server     Image analysis and video processing
      mermaid            Mermaid diagram rendering (SVG/PNG)

    Available but disabled (opt-in — set enabled: true in config.json):
      filesystem         Local filesystem read/write (redundant with built-in file tools)
      next-devtools      Next.js DevTools integration

    Remote (requires ZAI_API_KEY):
      web-reader         Web page content extraction
      web-search-prime   Web search capabilities
      zread              GitHub repository search and file reading

    Microsoft 365 (requires M365 Copilot license):
      microsoft-teams    Teams chats, channels, messages
      microsoft-mail     Outlook email operations
      microsoft-calendar Calendar event management
      microsoft-sharepoint SharePoint files and lists
      microsoft-onedrive Personal file management
      microsoft-word     Word document operations
      microsoft-user     User profile and org info
      microsoft-copilot  M365 Copilot conversations
      microsoft-dataverse Business data (Dynamics 365)

    Autodesk (requires Autodesk access token):
      autodesk-revit     Revit model data and APIs
      autodesk-fusion    Fusion 360 integration
      autodesk-model-data  Autodesk Model Data API
      autodesk-help      Autodesk Help knowledge base

    Google Cloud (requires Google auth):
      google-bigquery    BigQuery analytics queries
      google-maps        Google Maps geocoding/routes
      google-gce         Google Compute Engine management
      google-gke         Google Kubernetes Engine management

    SKILLS (123):
              Framework (19):       test-generator-framework, linting-workflow,
                                      pr-creation-workflow, pr-merge-workflow,
                                      error-resolver-workflow, tdd-workflow,
                                      docx-creation,
                                      xlsx-specialist, pdf-specialist, frontend-design,
                                      uiux-review-skill,
                                      api-design-skill, openapi-contract-adherence-skill,
                                      performance-optimization-skill, srs-creation-skill,
                                      brd-creation-skill, technical-design-creation-skill,
                                      vision-creation-skill, interactive-document-rendering-skill

            Presentation (3):       pptx-generate-slide-skill, pptx-generate-template-skill,
                                      pptx-template-modifier-skill

            Office Utilities (2):   ooxml-editing-skill, office-thumbnail-skill

            Language-Specific (8): python-pytest-creator, python-ruff-linter,
                                  javascript-eslint-linter, changelog-python-cliff,
                                  python-backend-skill, python-packaging-skill,
                                  csharp-linter-skill, java-linter-skill

          Framework-Specific (10): nextjs-pr-workflow, nextjs-unit-test-creator,
                                 nextjs-standard-setup, nextjs-image-usage,
                                 nextjs-devtools-mcp, amplify-nextjs-deployment,
                                  typescript-dry-principle, accessibility-a11y-skill,
                                  react-nextjs-antipatterns-skill,
                                  threejs-nextjs-skill

           OpenCode Meta (4):    opencode-agent-creation, opencode-skill-creation,
                                 opencode-skills-maintainer,
                                 documentation-consistency-skill

           OpenTofu (7):         opentofu-aws-explorer, opentofu-keycloak-explorer,
                                 opentofu-kubernetes-explorer, opentofu-neon-explorer,
                                 opentofu-provider-setup, opentofu-provisioning-workflow,
                                 opentofu-ecr-provision

           Git/Workflow (12):   ascii-diagram-creator, mermaid-diagram-creator,
                                  ticket-plan-workflow-skill, plan-execution-skill,
                                  git-issue-labeler, git-issue-updater,
                                  git-semantic-commits, semantic-release-convention,
                                  git-compact-commits, plan-updater, version-bump-standard,
                                  git-branch-workflow-setup-skill

          Documentation (3):    coverage-readme-workflow, docstring-generator,
                                 documentation-sync-workflow

          JIRA (3):             jira-status-updater, jira-git-integration, jira-ticket-labeler

         Code Quality (8):     solid-principles-skill, clean-code-skill, clean-architecture-skill,
                               design-patterns-skill, object-design-skill, code-smells-skill,
                               complexity-management-skill, deprecated-code-cleanup-skill

       Agent Optimization (7):  continuous-learning-skill, eval-harness-skill,
                                strategic-compact-skill, verification-loop-skill,
                                search-first-skill, context-budget-skill,
                                agent-introspection-debugging-skill

            Autoresearch (4):  autoresearch-core-skill, autoresearch-ml-skill,
                                autoresearch-code-skill, autoresearch-research-skill

            Startup/Business (3): startup-pitch-deck-skill, startup-business-docs-skill,
                                  construction-bd-skill

            Configuration (2):    microsoft-m365-config-skill, codegraph-setup-skill

              Security (2):     security-audit-skill, authentication-authorization-skill

                 DevOps (4):     docker-containerization-skill, monorepo-management-skill,
                                 database-migration-skill, logging-observability-skill

       Planning & Alignment (4): grilling-skill, domain-modeling-skill,
                                 grill-with-docs-skill, grill-me-skill

 Responsive & Visual Testing (2): wireframer-skill,
                                   playwright-responsive-audit-skill

    CAD & Hardware Design (14): cad-generation, cad-viewer, cad-step-parts,
                                 cad-dxf, cad-urdf, cad-srdf, cad-sdf,
                                 cad-sendcutsend, cad-gcode, cad-bambu-labs,
                                 cad-implicit, autodesk-aps-skill,
                                 civil-3d-skill, open3d-skill

  Academic & Research Writing (2): horseshoe-paper-writing-skill,
                                    research-paper-generation-skill

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
  Learnings directory:  ~/.config/opencode/learnings/
  Setup log:            ~/.opencode-setup.log
  Update log:           ~/.config/opencode/update.log
  Backups:              ~/.opencode-backup-YYYYMMDD_HHMMSS/        (flat-file)
                        ~/.opencode-backup-YYYYMMDD_HHMMSS.zip     (zip archive)
                         Retention: 5 most recent (configurable with --keep-backups)
                         Rollback:  ./setup.sh --rollback list

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
                if [ -z "$2" ]; then
                    log_error "--schedule-update requires an argument (daily, weekly, monthly, manual)"
                    exit 1
                fi
                case "$2" in
                    daily|weekly|monthly|manual)
                        UPDATE_SCHEDULE="$2"
                        ;;
                    *)
                        log_error "Invalid --schedule-update value: '$2' (allowed: daily, weekly, monthly, manual)"
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            -C|--check-update)
                CHECK_UPDATE_ONLY=true
                shift
                ;;
            -k|--keep-backups)
                if [ -n "$2" ] && [[ "$2" =~ ^-?[0-9]+$ ]]; then
                    KEEP_BACKUPS="$2"
                else
                    log_error "--keep-backups requires a numeric argument"
                    exit 1
                fi
                shift 2
                ;;
            --rollback)
                ROLLBACK_MODE=true
                # Optional positional: TIMESTAMP | VERSION | latest | list
                if [ -n "${2:-}" ] && [[ "$2" != --* ]]; then
                    ROLLBACK_TARGET="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --no-zip-backup)
                ZIP_BACKUP=false
                shift
                ;;
            --provider)
                if [ -n "$2" ]; then
                    PROVIDER="$2"
                else
                    log_error "--provider requires an argument (zai|anthropic|openai|openrouter|lmstudio)"
                    exit 1
                fi
                shift 2
                ;;
            --models-only)
                MODELS_ONLY=true
                shift
                ;;
            --force)
                FORCE_RESOLVE=true
                shift
                ;;
            --migrate)
                MIGRATE_ONLY=true
                shift
                ;;
            --mix)
                MIX_MODE=true
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

# Safe execution with dry-run support.
# Supports two calling conventions:
#   - Multi-arg (preferred):  run_cmd cp "$src" "$dest"      # preserves spaces
#   - Single-string (legacy): run_cmd "cp $src $dest"        # eval'd for back-comat
# Prefer the multi-arg form in new code — it survives paths with spaces, quotes,
# and glob chars without an eval injection risk.
run_cmd() {
    log_debug "Executing: $*"

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would execute: $*"
        return 0
    fi

    if [ $# -gt 1 ]; then
        # Multi-arg: execute directly so each arg is its own word.
        "$@"
    else
        # Single-string legacy form: requires eval for word-splitting.
        eval "$1"
    fi
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
        while true; do
            read -p "${prompt_message} [${default_value}]: " result
            result="${result:-$default_value}"
            if [[ "$result" =~ ^[YyNn]$ ]]; then
                break
            fi
            echo "Invalid input. Please enter y or n."
        done
    fi

    [[ "$result" =~ ^[Yy]$ ]]
}

# Create backup of existing files
create_backup() {
    local file_to_backup="$1"
    local backup_path="${BACKUP_DIR}/$(basename "$file_to_backup")"

    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: ${BACKUP_DIR}"
    fi

    if [ -f "$file_to_backup" ]; then
        run_cmd cp "$file_to_backup" "$backup_path"
        log_info "Backed up: ${file_to_backup} -> ${backup_path}"
    fi
}

cleanup_old_backups() {
    local keep_count="${KEEP_BACKUPS}"

    if [ "$keep_count" -lt 0 ]; then
        log_debug "Backup cleanup disabled (KEEP_BACKUPS=$keep_count)"
        return 0
    fi

    local all_backups
    # Use find -type d to avoid matching sibling .zip files (which the glob
    # would otherwise count as separate backups, inflating the keep total).
    all_backups=$(find "${HOME}" -maxdepth 1 -type d \( -name ".opencode-backup-*" -o -name ".opencode-update-backup-*" \) 2>/dev/null | sort -r)

    if [ -z "$all_backups" ]; then
        log_debug "No old backups found"
        return 0
    fi

    local total_count
    total_count=$(echo "$all_backups" | grep -c . 2>/dev/null || echo 0)

    if [ "$total_count" -le "$keep_count" ]; then
        log_debug "Found $total_count backup(s) (within retention limit of $keep_count)"
        return 0
    fi

    local to_delete
    to_delete=$(echo "$all_backups" | tail -n +"$((keep_count + 1))")
    local delete_count
    delete_count=$(echo "$to_delete" | grep -c . 2>/dev/null || echo 0)

    log_info "Cleaning up old backups (keeping $keep_count of $total_count)..."

    echo "$to_delete" | while read -r dir; do
        if [ -n "$dir" ] && [ -d "$dir" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY-RUN] Would remove old backup: ${dir}"
                [ -f "${dir}.zip" ] && echo "[DRY-RUN] Would remove old backup zip: ${dir}.zip"
            else
                rm -rf "${dir}"
                log_info "Removed old backup: ${dir}"
                # Also remove associated zip archive (sibling file)
                if [ -f "${dir}.zip" ]; then
                    rm -f "${dir}.zip"
                    log_info "Removed old backup zip: ${dir}.zip"
                fi
            fi
        fi
    done

    log_success "Cleaned up $delete_count old backup(s)"
}

################################################################################
# ZIP BACKUP AND ROLLBACK FUNCTIONS
################################################################################

# Create a zip archive of the backup directory for portability.
# Zip path: ${BACKUP_DIR}.zip (sibling of flat-file dir, same timestamp).
# Uses `zip -r` if available; falls back to `tar -czf` (.tar.gz) if not.
# Respects DRY_RUN and ZIP_BACKUP toggle.
create_zip_backup() {
    # Respect toggle (--no-zip-backup disables)
    if [ "$ZIP_BACKUP" != true ]; then
        log_debug "Zip backup disabled (ZIP_BACKUP=$ZIP_BACKUP)"
        return 0
    fi

    # No backup dir → nothing to zip
    if [ ! -d "$BACKUP_DIR" ]; then
        log_debug "Skipping zip: BACKUP_DIR does not exist ($BACKUP_DIR)"
        return 0
    fi

    # Empty backup dir → nothing to zip
    if [ ! "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        log_debug "Skipping zip: BACKUP_DIR is empty ($BACKUP_DIR)"
        return 0
    fi

    local zip_path="${BACKUP_DIR}.zip"
    local archive_name
    archive_name=$(basename "$BACKUP_DIR")

    if [ "$DRY_RUN" = true ]; then
        if command_exists zip; then
            echo "[DRY-RUN] Would execute: zip -rj ${zip_path} ${BACKUP_DIR}/"
        else
            echo "[DRY-RUN] Would execute: tar -czf ${zip_path}.tar.gz -C ${HOME} ${archive_name}"
        fi
        return 0
    fi

    if command_exists zip; then
        log_info "Creating zip archive: ${zip_path}"
        # -j: junk paths (store filenames only); -q: quiet
        if zip -qrj "$zip_path" "$BACKUP_DIR"/; then
            log_success "Zip archive created: ${zip_path}"
            return 0
        else
            log_warn "zip command failed; archive not created"
            return 1
        fi
    else
        # Fallback: tar.gz (named .tar.gz so consumers can detect format)
        local tar_path="${zip_path}.tar.gz"
        log_info "'zip' not available; creating tar.gz archive: ${tar_path}"
        if tar -czf "$tar_path" -C "$HOME" "$archive_name"; then
            log_success "Tar.gz archive created: ${tar_path}"
            return 0
        else
            log_warn "tar command failed; archive not created"
            return 1
        fi
    fi
}

# List available backups (newest-first) with timestamp, size, and zip availability.
# Output format (tabular, human-readable):
#   TIMESTAMP        TYPE       SIZE       ZIP     PATH
list_backups() {
    # Combine all backup-prefix directories, newest first.
    # Use find (not ls) so non-matching globs don't fail with pipefail.
    local all_dirs
    all_dirs=$(find "${HOME}" -maxdepth 1 -type d \( \
        -name ".opencode-backup-*" -o \
        -name ".opencode-update-backup-*" -o \
        -name ".opencode-pre-rollback-backup-*" \
        \) 2>/dev/null | sort -r)

    if [ -z "$all_dirs" ]; then
        echo "No backups found in ${HOME}/"
        echo ""
        echo "Backups are created automatically by:"
        echo "  - ./setup.sh (full deploy)"
        echo "  - ./setup.sh --rollback (pre-rollback safety)"
        return 0
    fi

    printf "%-17s %-22s %-10s %-5s %s\n" "TIMESTAMP" "TYPE" "SIZE" "ZIP" "PATH"
    printf -- "--------------------------------------------------------------------------------------------\n"

    local dir
    while IFS= read -r dir; do
        [ -z "$dir" ] && continue
        local name
        name=$(basename "$dir")
        local ts=""
        local btype="backup"

        # Classify and extract timestamp
        case "$name" in
            .opencode-backup-*)
                ts="${name#.opencode-backup-}"
                btype="backup"
                ;;
            .opencode-update-backup-*)
                ts="${name#.opencode-update-backup-}"
                btype="update"
                ;;
            .opencode-pre-rollback-backup-*)
                ts="${name#.opencode-pre-rollback-backup-}"
                btype="pre-rollback"
                ;;
            *)
                ts="?"
                ;;
        esac

        # Compute human-readable size of the dir
        local size_str="?"
        if command_exists du; then
            size_str=$(du -sh "$dir" 2>/dev/null | cut -f1)
        fi

        # Check for sibling .zip or .tar.gz
        local zip_str="-"
        if [ -f "${dir}.zip" ]; then
            zip_str="zip"
        elif [ -f "${dir}.zip.tar.gz" ]; then
            zip_str="tgz"
        fi

        printf "%-17s %-22s %-10s %-5s %s\n" "$ts" "$btype" "$size_str" "$zip_str" "$dir"
    done <<< "$all_dirs"

    # Also list orphan zip files (where the flat dir no longer exists).
    # Use find (not ls) to avoid pipefail on non-matching globs.
    local orphan_zips
    orphan_zips=$(find "${HOME}" -maxdepth 1 -type f \( \
        -name ".opencode-backup-*.zip" -o \
        -name ".opencode-backup-*.zip.tar.gz" -o \
        -name ".opencode-update-backup-*.zip" -o \
        -name ".opencode-pre-rollback-backup-*.zip" \
        \) 2>/dev/null | sort -r)
    if [ -n "$orphan_zips" ]; then
        echo ""
        echo "Orphan archives (no matching flat dir):"
        while IFS= read -r zpath; do
            [ -z "$zpath" ] && continue
            local zname
            zname=$(basename "$zpath")
            local zsize="?"
            if command_exists du; then
                zsize=$(du -sh "$zpath" 2>/dev/null | cut -f1)
            fi
            printf "  %-40s %-10s %s\n" "$zname" "$zsize" "$zpath"
        done <<< "$orphan_zips"
    fi
}

# Get the most recent backup directory (flat-file only, any prefix).
# Echoes the absolute path; returns 1 if none found.
get_latest_backup() {
    local latest
    latest=$(find "${HOME}" -maxdepth 1 -type d \( \
        -name ".opencode-backup-*" -o \
        -name ".opencode-update-backup-*" -o \
        -name ".opencode-pre-rollback-backup-*" \
        \) 2>/dev/null | sort -r | head -n1)
    if [ -z "$latest" ]; then
        return 1
    fi
    echo "$latest"
}

# Resolve a user-provided rollback target to a concrete backup directory.
# Accepts:
#   - TIMESTAMP (YYYYMMDD_HHMMSS)
#   - VERSION  (vX.Y.Z or X.Y.Z) — resolves via VERSION file git history
# Echoes the absolute path; returns 1 if not found.
resolve_backup_target() {
    local target="$1"

    # TIMESTAMP pattern: 8 digits, underscore, 6 digits
    if [[ "$target" =~ ^[0-9]{8}_[0-9]{6}$ ]]; then
        for prefix in ".opencode-backup-" ".opencode-update-backup-" ".opencode-pre-rollback-backup-"; do
            local candidate="${HOME}/${prefix}${target}"
            if [ -d "$candidate" ]; then
                echo "$candidate"
                return 0
            fi
        done
        # Also accept zip-only backup
        for prefix in ".opencode-backup-" ".opencode-update-backup-" ".opencode-pre-rollback-backup-"; do
            if [ -f "${HOME}/${prefix}${target}.zip" ]; then
                echo "${HOME}/${prefix}${target}.zip"
                return 0
            fi
        done
        return 1
    fi

    # VERSION pattern: vX.Y.Z or X.Y.Z
    if [[ "$target" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        local clean_ver="${target#v}"
        log_info "Resolving version ${clean_ver} via VERSION file git history..."

        # Get the commit date when VERSION was set to this value
        local version_commit_date=""
        if command_exists git && [ -d "${REPO_DIR}/.git" ]; then
            # Find the commit where VERSION content matched this value
            version_commit_date=$(cd "$REPO_DIR" && git log -1 --format=%ci -- VERSION 2>/dev/null | head -1)
            # Also try by tag
            if [ -z "$version_commit_date" ]; then
                version_commit_date=$(cd "$REPO_DIR" && git log -1 --format=%ai "v${clean_ver}" 2>/dev/null | head -1)
            fi
            # Try by content of VERSION file at commits
            if [ -z "$version_commit_date" ]; then
                local matching_commit
                matching_commit=$(cd "$REPO_DIR" && git log --format=%H -- VERSION 2>/dev/null | while read -r commit; do
                    local content
                    content=$(cd "$REPO_DIR" && git show "${commit}:VERSION" 2>/dev/null | tr -d '[:space:]')
                    if [ "$content" = "$clean_ver" ]; then
                        echo "$commit"
                        break
                    fi
                done | head -1)
                if [ -n "$matching_commit" ]; then
                    version_commit_date=$(cd "$REPO_DIR" && git log -1 --format=%ci "${matching_commit}" 2>/dev/null | head -1)
                fi
            fi
        fi

        if [ -z "$version_commit_date" ]; then
            log_warn "Could not resolve version ${clean_ver} to a git commit date"
            return 1
        fi

        # Convert git date (e.g. "2026-07-19 12:34:56 -0500") to comparable numeric form YYYYMMDDHHMMSS
        local git_ts_numeric
        git_ts_numeric=$(echo "$version_commit_date" | awk '{
            # Parse "YYYY-MM-DD HH:MM:SS ±ZZZZ"
            gsub(/-/, "", $1)
            gsub(/:/, "", $2)
            print $1 $2
        }')

        if [ -z "$git_ts_numeric" ]; then
            return 1
        fi

        log_info "Version ${clean_ver} corresponds to commit timestamp ${git_ts_numeric}"

        # Find the latest backup whose timestamp is <= git_ts_numeric
        local best_dir=""
        local best_ts=""
        local prefixes=(".opencode-backup-" ".opencode-update-backup-" ".opencode-pre-rollback-backup-")
        for prefix in "${prefixes[@]}"; do
            while IFS= read -r dir; do
                [ -z "$dir" ] && continue
                local name
                name=$(basename "$dir")
                local ts="${name#${prefix}}"
                # Only compare against valid timestamp suffixes
                [[ "$ts" =~ ^[0-9]{8}_[0-9]{6}$ ]] || continue
                # Strip underscore for numeric comparison
                local ts_numeric="${ts%_*}${ts#*_}"
                if [ "$ts_numeric" -le "$git_ts_numeric" ]; then
                    if [ -z "$best_ts" ] || [ "$ts_numeric" -gt "$best_ts" ]; then
                        best_ts="$ts_numeric"
                        best_dir="$dir"
                    fi
                fi
            done < <(find "${HOME}" -maxdepth 1 -type d -name "${prefix}*" 2>/dev/null)
        done

        if [ -n "$best_dir" ]; then
            echo "$best_dir"
            return 0
        fi
        return 1
    fi

    # Unknown format
    return 1
}

# Extract a zip/tar backup to a temporary directory.
# Echoes the temp dir path; caller MUST clean up.
# Returns 1 on failure.
extract_backup_archive() {
    local archive="$1"
    local tmp_dir
    tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/opencode-rollback-XXXXXX")
    if [ $? -ne 0 ]; then
        log_error "Could not create temp dir for extraction"
        return 1
    fi

    case "$archive" in
        *.zip.tar.gz)
            if ! tar -xzf "$archive" -C "$tmp_dir"; then
                log_error "Failed to extract tar.gz: $archive"
                rm -rf "$tmp_dir"
                return 1
            fi
            ;;
        *.zip)
            if command_exists unzip; then
                if ! unzip -q "$archive" -d "$tmp_dir"; then
                    log_error "Failed to extract zip: $archive"
                    rm -rf "$tmp_dir"
                    return 1
                fi
            else
                # Fallback: python's zipfile
                if command_exists python3; then
                    python3 -c "import zipfile; zipfile.ZipFile('$archive').extractall('$tmp_dir')" 2>/dev/null
                    if [ $? -ne 0 ]; then
                        log_error "Failed to extract zip (no unzip, python fallback failed): $archive"
                        rm -rf "$tmp_dir"
                        return 1
                    fi
                else
                    log_error "Cannot extract $archive: neither unzip nor python3 available"
                    rm -rf "$tmp_dir"
                    return 1
                fi
            fi
            ;;
        *)
            log_error "Unknown archive format: $archive"
            rm -rf "$tmp_dir"
            return 1
            ;;
    esac

    # If the extracted content has a single top-level dir that matches the
    # backup name pattern, descend into it so callers see flat content.
    local first_child
    first_child=$(ls -1 "$tmp_dir" 2>/dev/null | head -n1)
    if [ $(ls -1 "$tmp_dir" 2>/dev/null | wc -l) -eq 1 ] && [ -d "${tmp_dir}/${first_child}" ]; then
        echo "${tmp_dir}/${first_child}"
    else
        echo "$tmp_dir"
    fi
}

# Restore files from a backup directory into $CONFIG_DIR.
# Handles both backup layouts:
#   - flat files (config.json, AGENTS.md) + subdirs (skills/, skills-backup/, agents-backup/)
#   - update backups (config.json, AGENTS.md, skills/, agents/)
restore_from_dir() {
    local src_dir="$1"

    # Restore config.json
    if [ -f "${src_dir}/config.json" ]; then
        mkdir -p "$CONFIG_DIR"
        cp -f "${src_dir}/config.json" "${CONFIG_DIR}/config.json"
        log_info "Restored: config.json"
    fi

    # Restore AGENTS.md
    if [ -f "${src_dir}/AGENTS.md" ]; then
        mkdir -p "$CONFIG_DIR"
        cp -f "${src_dir}/AGENTS.md" "${CONFIG_DIR}/AGENTS.md"
        log_info "Restored: AGENTS.md"
    fi

    # Restore skills — prefer "skills" over "skills-backup"
    if [ -d "${src_dir}/skills" ]; then
        rm -rf "$SKILLS_DIR"
        cp -r "${src_dir}/skills" "$SKILLS_DIR"
        log_info "Restored: skills/"
    elif [ -d "${src_dir}/skills-backup" ]; then
        rm -rf "$SKILLS_DIR"
        cp -r "${src_dir}/skills-backup" "$SKILLS_DIR"
        log_info "Restored: skills/ (from skills-backup/)"
    fi

    # Restore agents
    if [ -d "${src_dir}/agents" ]; then
        rm -rf "$AGENTS_DEST_DIR"
        cp -r "${src_dir}/agents" "$AGENTS_DEST_DIR"
        log_info "Restored: agents/"
    elif [ -d "${src_dir}/agents-backup" ]; then
        rm -rf "$AGENTS_DEST_DIR"
        cp -r "${src_dir}/agents-backup" "$AGENTS_DEST_DIR"
        log_info "Restored: agents/ (from agents-backup/)"
    fi

    # Restore any other top-level files (*.json, *.md) that aren't config.json/AGENTS.md
    for f in "${src_dir}"/*; do
        [ -e "$f" ] || continue
        local fname
        fname=$(basename "$f")
        # Skip already-handled and known subdirs
        case "$fname" in
            config.json|AGENTS.md|skills|skills-backup|agents|agents-backup) continue ;;
        esac
        # Only restore regular files (skip shell configs etc. — those go to $HOME)
        if [ -f "$f" ]; then
            case "$fname" in
                *.json|*.md)
                    cp -f "$f" "${CONFIG_DIR}/${fname}"
                    log_info "Restored: ${fname}"
                    ;;
            esac
        fi
    done
}

# Create a safety backup before rollback (so rollback is reversible).
# Stored in ~/.opencode-pre-rollback-backup-TIMESTAMP/
create_pre_rollback_backup() {
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local pre_dir="${HOME}/.opencode-pre-rollback-backup-${ts}"
    mkdir -p "$pre_dir"

    log_info "Creating pre-rollback safety backup..."

    if [ -f "$CONFIG_FILE" ]; then
        cp -f "$CONFIG_FILE" "${pre_dir}/config.json"
    fi
    if [ -f "${CONFIG_DIR}/AGENTS.md" ]; then
        cp -f "${CONFIG_DIR}/AGENTS.md" "${pre_dir}/AGENTS.md"
    fi
    if [ -d "$SKILLS_DIR" ]; then
        cp -r "$SKILLS_DIR" "${pre_dir}/skills"
    fi
    if [ -d "$AGENTS_DEST_DIR" ]; then
        cp -r "$AGENTS_DEST_DIR" "${pre_dir}/agents"
    fi

    log_success "Pre-rollback backup created: ${pre_dir}"
    echo "$pre_dir"
}

# Rollback: restore ~/.config/opencode/ from a previous backup.
# Uses ROLLBACK_TARGET (set by parse_arguments) to select the backup.
rollback() {
    local target="${ROLLBACK_TARGET:-}"

    # Sub-mode: list
    if [ "$target" = "list" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "                📦 Available Backups"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        list_backups
        return 0
    fi

    # Resolve target → backup path (dir, or zip file)
    local backup_path=""

    if [ -z "$target" ]; then
        # Interactive: list and pick
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "                📦 Select Backup to Restore"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        list_backups
        echo ""
        if [ "$AUTO_ACCEPT" != true ]; then
            local pick
            read -p "Enter TIMESTAMP to restore (or 'q' to cancel): " pick
            if [ "$pick" = "q" ] || [ -z "$pick" ]; then
                log_info "Rollback cancelled"
                return 0
            fi
            target="$pick"
        else
            log_error "Interactive rollback requires a TARGET (cannot prompt with --yes)"
            log_info "Use: ./setup.sh --rollback TIMESTAMP"
            log_info "Or:  ./setup.sh --rollback latest"
            return 1
        fi
    fi

    if [ "$target" = "latest" ]; then
        backup_path=$(get_latest_backup)
        if [ -z "$backup_path" ]; then
            log_error "No backups available to restore from"
            return 1
        fi
    else
        backup_path=$(resolve_backup_target "$target")
        if [ -z "$backup_path" ]; then
            log_error "No backup found for target: '${target}'"
            log_info "Available backups:"
            list_backups
            return 1
        fi
    fi

    log_info "Resolved backup: ${backup_path}"

    # DRY-RUN: print what would happen, change nothing
    if [ "$DRY_RUN" = true ]; then
        echo ""
        echo "[DRY-RUN] Rollback plan:"
        echo "  Source: ${backup_path}"
        echo "  Target: ${CONFIG_DIR}/"
        echo "  Steps:"
        echo "    1. Create pre-rollback backup of current state"
        echo "    2. Confirm (or skip with --yes)"
        if [[ "$backup_path" == *.zip ]]; then
            echo "    3. Extract archive to temp location"
            echo "    4. Copy files to ${CONFIG_DIR}/"
        else
            echo "    3. Copy files to ${CONFIG_DIR}/"
        fi
        echo ""
        return 0
    fi

    # Confirmation prompt (unless --yes)
    if [ "$AUTO_ACCEPT" != true ]; then
        echo ""
        echo "⚠️  This will replace files in ${CONFIG_DIR}/ with content from:"
        echo "    ${backup_path}"
        echo ""
        if ! prompt_yes_no "Continue with rollback?" "n"; then
            log_info "Rollback cancelled by user"
            return 0
        fi
    fi

    # STEP 1: Safety backup (always — even with --yes)
    local pre_dir
    pre_dir=$(create_pre_rollback_backup)

    # STEP 2: Resolve src_dir (extract zip if needed)
    local src_dir="$backup_path"
    local extracted_tmp=""
    if [[ "$backup_path" == *.zip ]]; then
        log_info "Extracting zip archive..."
        extracted_tmp=$(extract_backup_archive "$backup_path")
        if [ $? -ne 0 ] || [ -z "$extracted_tmp" ]; then
            log_error "Failed to extract backup archive"
            log_info "Your current state is unchanged"
            return 1
        fi
        src_dir="$extracted_tmp"
    elif [ ! -d "$backup_path" ]; then
        log_error "Backup path is neither a directory nor a zip: ${backup_path}"
        return 1
    fi

    # STEP 3: Restore
    log_info "Restoring files to ${CONFIG_DIR}/..."
    mkdir -p "$CONFIG_DIR"
    restore_from_dir "$src_dir"

    # Cleanup temp dir
    if [ -n "$extracted_tmp" ]; then
        # Extracted tmp may be a subdir of mktemp base — remove the base
        local tmp_base
        tmp_base=$(echo "$extracted_tmp" | sed -E 's|^(.*)/opencode-rollback-[A-Za-z0-9]+.*$|\1/opencode-rollback-XXXXXX|' 2>/dev/null)
        # Safer: just remove the parent that mktemp created
        local tmp_parent
        tmp_parent="$extracted_tmp"
        # Walk up until we hit a path containing opencode-rollback-
        while [ "$tmp_parent" != "/" ] && [[ "$(basename "$tmp_parent")" != opencode-rollback-* ]]; do
            tmp_parent=$(dirname "$tmp_parent")
        done
        if [[ "$(basename "$tmp_parent")" == opencode-rollback-* ]]; then
            rm -rf "$tmp_parent"
        fi
    fi

    echo ""
    log_success "Rollback complete!"
    log_info "Restored from: ${backup_path}"
    log_info "Pre-rollback backup saved to: ${pre_dir}"
    log_info "If rollback was wrong, run: ./setup.sh --rollback $(basename "$pre_dir" | sed 's/^\.opencode-pre-rollback-backup-//')"
    return 0
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
    run_cmd mkdir -p "$CONFIG_DIR"
    log_info "Created ${CONFIG_DIR} directory"

    # Copy AGENTS.md from project to global config
    if [ -f "${SCRIPT_DIR}/.AGENTS.md" ]; then
        if [ -f "${CONFIG_DIR}/AGENTS.md" ]; then
            log_warn "AGENTS.md already exists at ${CONFIG_DIR}/AGENTS.md"
            if prompt_yes_no "Do you want to overwrite it?" "n"; then
                create_backup "${CONFIG_DIR}/AGENTS.md"
                run_cmd cp "${SCRIPT_DIR}/.AGENTS.md" "${CONFIG_DIR}/AGENTS.md"
                log_success "AGENTS.md copied successfully (renamed from .AGENTS.md)"
            fi
        else
            run_cmd cp "${SCRIPT_DIR}/.AGENTS.md" "${CONFIG_DIR}/AGENTS.md"
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

    # Copy config.json from the single source of truth (opencode_app/opencode.json).
    # Historically this copied deploy/config.json, but maintaining a duplicate
    # caused drift (see PLAN-BT-74 Phase 12.2). The resolver (run later in
    # deploy_agents) patches this file in-place for primary/explore/general models.
    if [ "$SKIP_CONFIG_COPY" != true ]; then
        if [ -f "$SOURCE_CONFIG" ]; then
            run_cmd cp "$SOURCE_CONFIG" "$CONFIG_FILE"
            log_success "config.json copied successfully (from ${SOURCE_CONFIG})"

            echo ""
        echo "✓ Configured 39 agents:"
        echo "    - build (default) - Full-featured coding agent"
        echo "    - plan - Planning agent (read-only)"
        echo "    - explore - Codebase exploration and analysis"
        echo "    - image-analyzer-subagent - Image/screenshot analysis"
        echo "    - discovery-specialist-subagent - Customer-facing discovery: Vision docs + wireframes"
        echo "    - ... and 34 more agents"
            echo ""
             echo "✓ Configured MCP servers:"
             echo "    Local (auto-start): atlassian, zai-vision-mcp-server, codegraph, mermaid"
             echo "    Remote (needs key): web-reader, web-search-prime, zread"
            echo ""
        else
            log_error "config.json source not found: ${SOURCE_CONFIG}"
            return 1
        fi
    fi

    # Setup skills directory
    echo ""
    log_info "Setting up skills directory..."

    # Create skills directory
    run_cmd mkdir -p "$SKILLS_DIR"
    log_info "Created ${SKILLS_DIR} directory"

    # Check if skills folder exists in script directory
    if [ -d "${REPO_DIR}/opencode_app/.opencode/skills" ]; then
        # Check if skills directory already has content
        if [ -d "${SKILLS_DIR}" ] && [ "$(ls -A "${SKILLS_DIR}" 2>/dev/null)" ]; then
            log_warn "Skills directory already contains files"

            if prompt_yes_no "Do you want to overwrite existing skills?" "n"; then
                # Backup existing skills
                if [ -d "${BACKUP_DIR}" ]; then
                    run_cmd cp -r "$SKILLS_DIR" "${BACKUP_DIR}/skills-backup"
                    log_info "Backed up existing skills to ${BACKUP_DIR}/skills-backup"
                fi
            else
                log_info "Skipping skills deployment. Existing skills preserved."
                return 0
            fi
        fi

        # Copy skills folder (excluding _archived)
        if command -v rsync &> /dev/null; then
            run_cmd rsync -av --exclude='_archived' "${REPO_DIR}/opencode_app/.opencode/skills/" "${SKILLS_DIR}/"
        else
            # Fallback: copy all except _archived
            mkdir -p "${SKILLS_DIR}"
            for item in "${REPO_DIR}/opencode_app/.opencode/skills"/*; do
                item_name=$(basename "$item")
                if [[ "$item_name" != "_archived" ]]; then
                    cp -r "$item" "${SKILLS_DIR}/"
                fi
            done
        fi
        log_success "Skills copied successfully to ${SKILLS_DIR}"
    else
        log_warn "skills/ folder not found in ${REPO_DIR}/opencode_app/.opencode/skills"
    fi

    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# v2.0 MODEL RESOLUTION HELPERS
# ─────────────────────────────────────────────────────────────────────────────

# Run the model resolver: injects concrete models into deployed agent .md files
# and patches config.json (primary + explore + general). Honors global/project
# overrides + provider preset. Preserve-edits via sidecar unless --force.
run_resolver() {
    if [ ! -f "$RESOLVER_SCRIPT" ]; then
        log_error "Resolver not found: $RESOLVER_SCRIPT"
        return 1
    fi

    local extra_args=""
    if [ "$FORCE_RESOLVE" = true ]; then
        extra_args="$extra_args --force"
    fi
    if [ -n "$PROVIDER" ]; then
        extra_args="$extra_args --provider ${PROVIDER} --presets ${PROVIDER_PRESETS}"
    fi

    local project_map_arg=""
    [ -f "$PROJECT_MODELS_MAP" ] && project_map_arg="--project-map ${PROJECT_MODELS_MAP}"
    local project_overrides_arg=""
    [ -f "$PROJECT_OVERRIDES" ] && project_overrides_arg="--project-overrides ${PROJECT_OVERRIDES}"

    local dry_arg=""
    if [ "$DRY_RUN" = true ]; then
        rm -rf "$DRY_RUN_PREVIEW_DIR"
        dry_arg="--dry-run --preview-dir ${DRY_RUN_PREVIEW_DIR}"
    fi

    node "$RESOLVER_SCRIPT" \
        --agents-src "$AGENTS_SRC_DIR" \
        --agents-dest "$AGENTS_DEST_DIR" \
        --tiers "$AGENT_TIERS" \
        --default-map "$MODELS_DEFAULT_MAP" \
        --user-map "$USER_MODELS_MAP" \
        $project_map_arg \
        --overrides "$USER_OVERRIDES" \
        $project_overrides_arg \
        --config-src "$SOURCE_CONFIG" \
        --config-dest "$CONFIG_FILE" \
        --state "$RESOLVED_SIDECAR" \
        $dry_arg \
        $extra_args
}

# Choose a model provider (interactive TUI or --provider flag) and write the
# global ~/.config/opencode/models.json tier map. Skipped silently in
# non-interactive mode unless --provider is set (defaults apply).
setup_model_provider() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                  🧠 Model Provider (v2.0)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ -n "$PROVIDER" ] && [ "$MIX_MODE" = false ]; then
        log_info "Provider preset: ${PROVIDER} (writing ${USER_MODELS_MAP})"
        node "$TUI_SCRIPT" provider-picker \
            --presets "$PROVIDER_PRESETS" --provider "$PROVIDER" \
            --out "$USER_MODELS_MAP"
        return $?
    fi

    # --mix: per-category provider/model editor (interactive). Base = $PROVIDER or zai.
    if [ "$MIX_MODE" = true ]; then
        local base="${PROVIDER:-zai}"
        log_info "Mix mode: choose a provider/model per category (base: ${base})"
        node "$TUI_SCRIPT" tier-editor \
            --presets "$PROVIDER_PRESETS" --provider "$base" \
            --out "$USER_MODELS_MAP" \
            || log_warn "Mix editor cancelled (using default models)"
        return $?
    fi

    if [ -t 0 ] && [ "$AUTO_ACCEPT" = false ]; then
        echo "  1) Single provider (recommended)"
        echo "  2) Mix providers per category (e.g. vision on OpenAI, rest on Z.AI)"
        local provider_choice
        provider_choice=$(prompt_user "Select option [1]" "1")
        case "$provider_choice" in
            2)
                node "$TUI_SCRIPT" tier-editor \
                    --presets "$PROVIDER_PRESETS" --provider "${PROVIDER:-zai}" \
                    --out "$USER_MODELS_MAP" \
                    || log_warn "Mix editor cancelled (using default models)"
                ;;
            *)
                if prompt_yes_no "Choose a model provider? (default: Z.AI)" "n"; then
                    node "$TUI_SCRIPT" provider-picker \
                        --presets "$PROVIDER_PRESETS" \
                        --out "$USER_MODELS_MAP" \
                        || log_warn "Provider selection skipped (using default models)"
                else
                    log_info "Using default Z.AI models"
                fi
                ;;
        esac
    else
        log_info "Non-interactive: using default models (use --provider <name> or --mix to choose)"
    fi
}

# Lift unknown (non-z.ai-default) model customizations from an existing deployed
# agent set into ~/.config/opencode/agent-overrides.json so they survive the
# re-resolve as first-class managed overrides rather than being clobbered.
lift_customizations() {
    [ -d "$AGENTS_DEST_DIR" ] || return 0
    local dry_arg=""
    [ "$DRY_RUN" = true ] && dry_arg="--dry-run"
    node "$RESOLVER_SCRIPT" --lift-only \
        --agents-dest "$AGENTS_DEST_DIR" \
        --default-map "$MODELS_DEFAULT_MAP" \
        --overrides "$USER_OVERRIDES" \
        $dry_arg
}

# Detect a pre-v2 install and run the one-time migration: backup, lift
# customizations, mark the config version. Idempotent (no-op once at v2.0).
run_migration() {
    local current_version="0"
    [ -f "$CONFIG_VERSION_FILE" ] && current_version=$(tr -d '[:space:]' < "$CONFIG_VERSION_FILE")

    # current_version >= SCHEMA_VERSION  ->  skip (input is ascending iff SCHEMA <= current)
    if printf '%s\n%s\n' "$SCHEMA_VERSION" "$current_version" | sort -V -C 2>/dev/null; then
        log_debug "Config already at v${SCHEMA_VERSION}, no migration needed"
        return 0
    fi

    echo ""
    log_warn "v2.0 major upgrade detected (current config: v${current_version:-unknown})"
    log_warn "Agent models are now resolved from tiers (see MIGRATION.md). Existing"
    log_warn "agents will be backed up and re-resolved. Custom models are preserved."

    if [ "$AUTO_ACCEPT" = false ]; then
        if ! prompt_yes_no "Run migration now?" "y"; then
            log_warn "Migration skipped. Agents re-resolved from tiers (custom models NOT lifted)."
            return 0
        fi
    fi

    # Backup existing agents + config (skip actual copy in dry-run)
    if [ "$DRY_RUN" = true ]; then
        if [ -d "$AGENTS_DEST_DIR" ] && [ "$(ls -A "$AGENTS_DEST_DIR" 2>/dev/null)" ]; then
            log_info "[DRY-RUN] Would back up agents -> ${BACKUP_DIR}/agents-backup"
        fi
        [ -f "$CONFIG_FILE" ] && log_info "[DRY-RUN] Would back up config.json"
    else
        if [ -d "$AGENTS_DEST_DIR" ] && [ "$(ls -A "$AGENTS_DEST_DIR" 2>/dev/null)" ]; then
            mkdir -p "$BACKUP_DIR"
            if [ ! -d "$BACKUP_DIR/agents-backup" ]; then
                cp -r "$AGENTS_DEST_DIR" "$BACKUP_DIR/agents-backup"
                log_info "Backed up agents to ${BACKUP_DIR}/agents-backup"
            fi
        fi
        [ -f "$CONFIG_FILE" ] && create_backup "$CONFIG_FILE"
    fi

    # Lift customizations into agent-overrides.json BEFORE re-resolve
    lift_customizations

    # Mark migrated (skip write in dry-run)
    if [ "$DRY_RUN" = true ]; then
        log_success "[DRY-RUN] Would mark config as v${SCHEMA_VERSION}"
    else
        echo "$SCHEMA_VERSION" > "$CONFIG_VERSION_FILE"
        log_success "Migration to v${SCHEMA_VERSION} complete"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# AGENT DEPLOYMENT (v2.0 — resolver-driven)
# ─────────────────────────────────────────────────────────────────────────────
deploy_agents() {
    echo ""
    log_info "Setting up agents (v2.0 model resolution)..."

    # Node is required for the resolver (opencode-ai needs it anyway)
    if ! command_exists node; then
        log_error "Node.js is required to resolve agent models."
        log_error "Install Node.js first, then re-run this setup."
        log_warn "Skipping agent deployment."
        return 1
    fi

    if [ ! -d "$AGENTS_SRC_DIR" ]; then
        log_warn "agents/ source folder not found: ${AGENTS_SRC_DIR}"
        return 1
    fi

    run_cmd "mkdir -p ${AGENTS_DEST_DIR}"

    # Migration (detect pre-v2, backup, lift customizations) before resolve
    run_migration

    # Resolve + inject concrete models from tiers/overrides/presets
    log_info "Resolving agent models..."
    run_resolver
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        log_error "Model resolution failed (exit ${rc})"
        return 1
    fi

    # Count deployed agents by mode
    local agent_count=0 primary_count=0 subagent_count=0
    for agent_file in "${AGENTS_DEST_DIR}"/*.md; do
        [ -f "$agent_file" ] || continue
        agent_count=$((agent_count + 1))
        if grep -q "^mode: primary" "$agent_file" 2>/dev/null; then
            primary_count=$((primary_count + 1))
        elif grep -q "^mode: subagent" "$agent_file" 2>/dev/null; then
            subagent_count=$((subagent_count + 1))
        fi
    done

    log_success "Deployed ${agent_count} agents (${subagent_count} subagents) to ${AGENTS_DEST_DIR}"
    echo "  Models resolved via tier registry."
    echo "  Change provider: ./setup.sh --provider <zai|anthropic|openai|openrouter|lmstudio>"
    echo "  Pin per-agent:   ~/.config/opencode/agent-overrides.json"
    return 0
}

setup_learnings_dir() {
    log_info "Setting up user-level learnings directory..."

    local LEARNINGS_DIR="${CONFIG_DIR}/learnings"
    local learnings_categories=("patterns" "decisions" "anti-patterns" "solutions" "conventions")

    if [ ! -d "${LEARNINGS_DIR}" ]; then
        run_cmd mkdir -p "$LEARNINGS_DIR"
        log_info "Created ${LEARNINGS_DIR}"
    fi

    for category in "${learnings_categories[@]}"; do
        local category_dir="${LEARNINGS_DIR}/${category}"
        if [ ! -d "${category_dir}" ]; then
            run_cmd mkdir -p "$category_dir"
            run_cmd touch "${category_dir}/.gitkeep"
        fi
    done

    if [ ! -f "${LEARNINGS_DIR}/_index.md" ]; then
        cat > "${LEARNINGS_DIR}/_index.md" << 'LEARNINGS_INDEX'
# LEARNINGS Index (User-Level)

<!-- AUTO-GENERATED — manual edits to the listing below will be overwritten on next learning write -->

## Folder Structure

| Folder | Purpose |
|--------|---------|
| `patterns/` | Reusable code/architecture patterns (cross-project) |
| `decisions/` | Personal architectural decisions |
| `anti-patterns/` | Things to avoid |
| `solutions/` | Non-obvious fixes worth remembering |
| `conventions/` | Personal coding standards |

## Entries

<!-- Entries are appended here automatically when new learnings are saved -->

<!-- No entries yet -->
LEARNINGS_INDEX
        log_info "Created _index.md template"
    fi

    log_success "User-level learnings directory ready at ${LEARNINGS_DIR}"
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
                if prompt_yes_no "Add ZAI_API_KEY to $(basename "${SHELL_CONFIG_FILE}") for persistent access?" "y"; then
                    create_backup "$SHELL_CONFIG_FILE"
                    run_cmd "printf '%s\\n' 'export ZAI_API_KEY=\"${ZAI_API_KEY}\"' >> \"${SHELL_CONFIG_FILE}\""
                    log_success "ZAI_API_KEY added to ${SHELL_CONFIG_FILE}"
                else
                    log_info "Skipping shell config update for ZAI_API_KEY"
                fi
            fi
        fi
    fi

    # Offer to install autoresearch protocol helpers (ar-enable / ar-disable)
    # into existing bashrc / zshrc. Prompted — never silent.
    if ! is_windows; then
        local rc_files=()
        [ -f "$HOME/.bashrc" ] && rc_files+=("$HOME/.bashrc")
        [ -f "$HOME/.zshrc" ] && rc_files+=("$HOME/.zshrc")
        if [ ${#rc_files[@]} -gt 0 ]; then
            local already_present=true
            for rc in "${rc_files[@]}"; do
                grep -q 'ar-enable()' "$rc" 2>/dev/null || already_present=false
            done
            if [ "$already_present" = false ]; then
                if prompt_yes_no "Install 'ar-enable' / 'ar-disable' helpers in your shell rc?" "n"; then
                    for rc in "${rc_files[@]}"; do
                        if ! grep -q 'ar-enable()' "$rc" 2>/dev/null; then
                            create_backup "$rc"
                            {
                                echo ''
                                echo '# autoresearch protocol helpers (added by opencode setup)'
                                echo 'ar-enable()  { export AUTORESEARCH_PROTOCOL=1; echo "autoresearch protocol: ON"; }'
                                echo 'ar-disable() { unset AUTORESEARCH_PROTOCOL;   echo "autoresearch protocol: OFF"; }'
                            } >> "$rc"
                            log_info "Added ar-enable/ar-disable to ${rc}"
                        fi
                    done
                    log_success "autoresearch protocol helpers installed"
                else
                    log_info "Skipping autoresearch protocol helpers"
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
    # date -d @<ts> is GNU-only (Linux). BSD date (macOS) uses -r <ts>.
    if [ "$DETECTED_OS" = "macOS" ]; then
        log_debug "Updated last check time: $(date -r "$timestamp" 2>/dev/null || echo "$timestamp")"
    else
        log_debug "Updated last check time: $(date -d "@$timestamp" 2>/dev/null || echo "$timestamp")"
    fi
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

    cleanup_old_backups
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
        echo "✓ Configured 39 agents:"
        echo "    - build (default) - Full-featured coding agent"
        echo "    - plan - Planning agent (read-only)"
        echo "    - explore - Codebase exploration and analysis"
        echo "    - image-analyzer-subagent - Image/screenshot analysis"
        echo "    - ... and 35 more agents"
    fi

    # MCP servers configured
    if [ -f "$CONFIG_FILE" ]; then
         echo "✓ Configured MCP servers:"
         echo "    - atlassian - JIRA and Confluence integration (auto-start)"
         echo "    - web-reader - Web page reading (needs ZAI_API_KEY)"
         echo "    - web-search-prime - Web search (needs ZAI_API_KEY)"
         echo "    - zai-vision-mcp-server - Image analysis (auto-start)"
         echo "    - zread - GitHub repo search (needs ZAI_API_KEY)"
         echo "    - codegraph - Code knowledge graph (auto-start)"
         echo "    - mermaid - Diagram rendering SVG/PNG (auto-start)"
    fi

    # skills directory status
    if [ -d "$SKILLS_DIR" ] && [ "$(ls -A "${SKILLS_DIR}" 2>/dev/null)" ]; then
        local skill_count=$(find "${SKILLS_DIR}" -type f -name "SKILL.md" 2>/dev/null | wc -l)
        echo "✓ skills: ${skill_count} skills deployed to ${SKILLS_DIR}/"
        echo "    - Framework (19):"
        echo "      - test-generator-framework"
        echo "      - linting-workflow"
        echo "      - pr-creation-workflow"
        echo "      - pr-merge-workflow"
        echo "      - error-resolver-workflow"
        echo "      - tdd-workflow"
        echo "      - docx-creation"
        echo "      - xlsx-specialist"
        echo "      - pdf-specialist"
        echo "      - frontend-design"
        echo "      - uiux-review-skill"
        echo "      - api-design-skill"
        echo "      - openapi-contract-adherence-skill"
        echo "      - performance-optimization-skill"
        echo "      - srs-creation-skill"
        echo "      - brd-creation-skill"
        echo "      - technical-design-creation-skill"
        echo "      - vision-creation-skill"
        echo "      - interactive-document-rendering-skill"
        echo "    - Language-Specific (8):"
        echo "      - python-pytest-creator"
        echo "      - python-ruff-linter"
        echo "      - javascript-eslint-linter"
        echo "      - changelog-python-cliff"
        echo "      - python-backend-skill"
        echo "      - python-packaging-skill"
        echo "      - csharp-linter-skill"
        echo "      - java-linter-skill"
        echo "    - Presentation (3):"
        echo "      - pptx-generate-slide-skill, pptx-generate-template-skill"
        echo "      - pptx-template-modifier-skill"
        echo "    - Office Utilities (2):"
        echo "      - ooxml-editing-skill, office-thumbnail-skill"
        echo "    - Framework-Specific (10):"
        echo "      - nextjs-pr-workflow"
        echo "      - nextjs-unit-test-creator"
        echo "      - nextjs-standard-setup"
        echo "      - nextjs-image-usage"
        echo "      - nextjs-devtools-mcp"
        echo "      - amplify-nextjs-deployment"
        echo "      - typescript-dry-principle"
        echo "      - accessibility-a11y-skill"
        echo "      - react-nextjs-antipatterns-skill"
        echo "      - threejs-nextjs-skill"
        echo "    - OpenCode Meta (4):"
        echo "      - opencode-agent-creation"
        echo "      - opencode-skill-creation"
        echo "      - opencode-skills-maintainer"
        echo "      - documentation-consistency-skill"
        echo "    - OpenTofu (7):"
        echo "      - opentofu-aws-explorer"
        echo "      - opentofu-keycloak-explorer"
        echo "      - opentofu-kubernetes-explorer"
        echo "      - opentofu-neon-explorer"
        echo "      - opentofu-provider-setup"
        echo "      - opentofu-provisioning-workflow"
        echo "      - opentofu-ecr-provision"
        echo "    - Git/Workflow (12):"
        echo "      - ascii-diagram-creator"
        echo "      - mermaid-diagram-creator"
        echo "      - ticket-plan-workflow-skill"
        echo "      - plan-execution-skill"
        echo "      - git-issue-labeler"
        echo "      - git-issue-updater"
        echo "      - git-semantic-commits"
        echo "      - semantic-release-convention"
        echo "      - git-compact-commits"
        echo "      - plan-updater"
        echo "      - version-bump-standard"
        echo "      - git-branch-workflow-setup-skill"
        echo "    - Documentation (3):"
        echo "      - coverage-readme-workflow"
        echo "      - docstring-generator"
        echo "      - documentation-sync-workflow"
         echo "    - Academic & Research Writing (2):"
         echo "      - horseshoe-paper-writing-skill"
         echo "      - research-paper-generation-skill"
         echo "    - JIRA (3):"
         echo "      - jira-status-updater"
         echo "      - jira-git-integration"
         echo "      - jira-ticket-labeler"
        echo "    - Code Quality (8):"
        echo "      - solid-principles"
        echo "      - clean-code"
        echo "      - clean-architecture"
        echo "      - design-patterns"
        echo "      - object-design"
        echo "      - code-smells"
        echo "      - complexity-management"
        echo "      - deprecated-code-cleanup-skill"
         echo "    - Planning & Alignment (4):"
         echo "      - grilling-skill"
         echo "      - domain-modeling-skill"
         echo "      - grill-with-docs-skill"
         echo "      - grill-me-skill"
        echo "    - Responsive & Visual Testing (2):"
        echo "      - wireframer-skill"
        echo "      - playwright-responsive-audit-skill"
        echo "    - CAD & Hardware Design (14):"
        echo "      - cad-generation-skill"
        echo "      - cad-viewer-skill"
        echo "      - cad-step-parts-skill"
        echo "      - cad-dxf-skill"
        echo "      - cad-urdf-skill"
        echo "      - cad-srdf-skill"
        echo "      - cad-sdf-skill"
        echo "      - cad-sendcutsend-skill"
        echo "      - cad-gcode-skill"
        echo "      - cad-bambu-labs-skill"
        echo "      - cad-implicit-skill"
        echo "      - autodesk-aps-skill"
        echo "      - civil-3d-skill"
        echo "      - open3d-skill"

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
    echo "🤖 Agents (39):"
    echo "  - build (default) - Full-featured coding agent"
    echo "  - plan - Planning agent (read-only)"
    echo "  - explore - Fast codebase exploration and analysis"
    echo "  - image-analyzer-subagent - Images/screenshots to code, OCR, error diagnosis"
    echo "  - discovery-specialist-subagent - Customer-facing discovery: Vision docs + wireframes"
    echo "  - ... and 34 more agents"
    echo ""
    echo "  Usage: opencode --agent <name> \"prompt\""
    echo "         opencode \"prompt\" (uses build)"
     echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "                     📦 123 Skills Available"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
     echo "  Framework (19) • Language-Specific (8) • Presentation (3)"
     echo "  Office Utilities (2) • Framework-Specific (10) • OpenCode Meta (4)"
     echo "  OpenTofu (7) • Git/Workflow (12) • Documentation (3) • JIRA (3) • Code Quality (8)"
    echo "  Agent Optimization (7) • Planning & Alignment (4) • Academic & Research Writing (2)"
    echo "  Responsive & Visual Testing (2)"
    echo "  CAD & Hardware Design (14)"
    echo ""
    echo "  Run 'opencode --list-skills' for detailed descriptions"
    echo "  Run 'opencode --skill <name> \"prompt\"' to use a skill"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo "                     🔌 MCP Servers (6)"
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo ""
     echo "  Local (auto-start): atlassian, zai-vision-mcp-server, codegraph"
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

    # Handle rollback mode (mutually exclusive with normal setup flow)
    if [ "$ROLLBACK_MODE" = true ]; then
        rollback
        exit $?
    fi

    # Handle update-only mode
    if [ "$UPDATE_ONLY" = true ]; then
        update_opencode_cli
        echo ""
        echo "Update complete!"
        exit 0
    fi

    # Handle models-only mode (v2.0): provider selection + model resolution only
    if [ "$MODELS_ONLY" = true ]; then
        log_info "Models-only mode (v2.0)"
        if ! command_exists node; then
            log_error "Node.js is required for model resolution."
            exit 1
        fi
        setup_model_provider || true
        run_resolver
        echo ""
        echo "Model resolution complete!"
        exit 0
    fi

    # Handle migrate-only mode (v2.0): v1.x -> v2.0 migration + resolution only
    if [ "$MIGRATE_ONLY" = true ]; then
        log_info "Migrate mode (v2.0)"
        if ! command_exists node; then
            log_error "Node.js is required for model resolution."
            exit 1
        fi
        run_cmd "mkdir -p ${AGENTS_DEST_DIR}"
        run_migration
        run_resolver
        echo ""
        echo "Migration + model resolution complete!"
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
        deploy_agents || true
        setup_learnings_dir || true
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

    # Auto-update check (run before main menu).
    # Note: $CHECK_UPDATE_ONLY is guaranteed false here — we exit at the block
    # above when it's true. The previous `|| [ "$CHECK_UPDATE_ONLY" = false ]`
    # was always-true and therefore a no-op.
    if [ "$ENABLE_AUTO_UPDATE" = true ]; then
        log_info "Auto-update is enabled (schedule: ${UPDATE_SCHEDULE})"
        auto_update_opencode
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
        echo "  5) Install PeonPing (sound notifications)"
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
                deploy_agents || true
                setup_learnings_dir || true
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
    setup_model_provider || true
    deploy_agents || true
    setup_learnings_dir || true
    setup_shell_vars || true

    # Zip backup (after all flat-file backups have been written, before cleanup)
    create_zip_backup || true

    cleanup_old_backups

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

# Run main function with all arguments (guard allows sourcing for testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

