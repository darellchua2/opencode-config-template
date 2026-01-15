#!/bin/bash

################################################################################
# OpenCode Configuration Setup Script
#
# Description: Automated setup for OpenCode configuration with proper error
#              handling, logging, and user experience enhancements.
#
# Usage: ./setup.sh [OPTIONS]
#
# Options:
#   -h, --help          Show this help message
#   -q, --quick         Quick setup (copy config.json only)
#   -d, --dry-run       Show what would be done without making changes
#   -y, --yes           Auto-accept all prompts (use with caution)
#   -v, --verbose       Enable verbose output
#
################################################################################

# Strict error handling
set -o pipefail  # Catch errors in pipes
set -o nounset   # Error on undefined variables
# Note: We don't use 'set -e' because we want custom error handling

################################################################################
# GLOBAL VARIABLES
################################################################################

SCRIPT_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOME}/.opencode-setup.log"
CONFIG_DIR="${HOME}/.config/opencode"
CONFIG_FILE="${CONFIG_DIR}/config.json"
BASHRC_FILE="${HOME}/.bashrc"
BACKUP_DIR="${HOME}/.opencode-backup-$(date +%Y%m%d_%H%M%S)"

# Flags
QUICK_SETUP=false
DRY_RUN=false
AUTO_ACCEPT=false
VERBOSE=false
SKIP_CONFIG_COPY=false

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
    -q, --quick         Quick setup (copy config.json only)
    -d, --dry-run       Show what would be done without making changes
    -y, --yes           Auto-accept all prompts (use with caution)
    -v, --verbose       Enable verbose output

EXAMPLES:
    ./setup.sh              # Interactive full setup
    ./setup.sh --quick      # Quick setup (config only)
    ./setup.sh --dry-run    # Preview changes
    ./setup.sh -y -q        # Quick setup with auto-accept

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
    echo "=== GitHub Personal Access Token Setup ==="
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
    echo "=== Z.AI API Key Setup ==="
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
        else
            log_error "Node.js installation failed"
            return 1
        fi
    else
        log_info "Skipping Node.js v24 installation"
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

# Setup configuration file
setup_config() {
    echo ""
    echo "=== Configuration Setup ==="

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
        else
            log_error "config.json not found in ${SCRIPT_DIR}"
            return 1
        fi
    fi

    return 0
}

# Setup environment variables in bashrc
setup_bashrc_vars() {
    echo ""
    echo "=== Environment Variables Setup ==="

    # Add ZAI_API_KEY to ~/.bashrc
    if [ -n "$ZAI_API_KEY" ]; then
        if grep -q "ZAI_API_KEY" "$BASHRC_FILE" 2>/dev/null; then
            log_info "ZAI_API_KEY already exists in ${BASHRC_FILE}"
        else
            if prompt_yes_no "Add ZAI_API_KEY to ~/.bashrc for persistent access?" "y"; then
                create_backup "$BASHRC_FILE"
                run_cmd "echo 'export ZAI_API_KEY=\"${ZAI_API_KEY}\"' >> ${BASHRC_FILE}"
                log_success "ZAI_API_KEY added to ${BASHRC_FILE}"
            else
                log_info "Skipping ~/.bashrc update for ZAI_API_KEY"
            fi
        fi
    fi

    # Add GITHUB_PAT to ~/.bashrc
    if [ -n "$GITHUB_PAT" ]; then
        if grep -q "GITHUB_PAT" "$BASHRC_FILE" 2>/dev/null; then
            log_info "GITHUB_PAT already exists in ${BASHRC_FILE}"
        else
            if prompt_yes_no "Add GITHUB_PAT to ~/.bashrc for persistent access?" "y"; then
                create_backup "$BASHRC_FILE"
                run_cmd "echo 'export GITHUB_PAT=\"${GITHUB_PAT}\"' >> ${BASHRC_FILE}"
                log_success "GITHUB_PAT added to ${BASHRC_FILE}"
            else
                log_info "Skipping ~/.bashrc update for GITHUB_PAT"
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
    echo ""
    echo "=== Setup Summary ==="
    echo ""

    # nvm status
    if command_exists nvm; then
        echo "✓ nvm: Installed (v$(nvm --version 2>/dev/null))"
    else
        echo "✗ nvm: Not installed"
    fi

    # Node.js status
    if command_exists node; then
        echo "✓ Node.js: $(node --version)"
    else
        echo "✗ Node.js: Not installed"
    fi

    # opencode-ai status
    if command_exists opencode; then
        echo "✓ opencode-ai: Installed (v$(opencode --version 2>/dev/null || echo "unknown"))"
    else
        echo "✗ opencode-ai: Not installed"
    fi

    # config.json status
    if [ -f "$CONFIG_FILE" ]; then
        echo "✓ config.json: Copied to ${CONFIG_DIR}/"
    else
        echo "✗ config.json: Not copied"
    fi

    # ZAI_API_KEY status
    if grep -q "ZAI_API_KEY" "$BASHRC_FILE" 2>/dev/null; then
        echo "✓ ZAI_API_KEY: Added to ${BASHRC_FILE}"
    elif [ -n "$ZAI_API_KEY" ]; then
        echo "○ ZAI_API_KEY: Set in current session only"
    else
        echo "✗ ZAI_API_KEY: Not configured"
    fi

    # GITHUB_PAT status
    if grep -q "GITHUB_PAT" "$BASHRC_FILE" 2>/dev/null; then
        echo "✓ GITHUB_PAT: Added to ${BASHRC_FILE}"
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
    echo "=== Next Steps ==="
    echo ""
    echo "To finish setup:"
    echo "1. Restart your terminal or run: source ${BASHRC_FILE}"
    echo "2. Ensure LM Studio is running on http://127.0.0.1:1234/v1"
    echo "3. Verify installation: opencode --version"
    echo "4. Test configuration: opencode --help"
    echo ""
    echo "GitHub Authentication:"
    echo "  - If you set a GITHUB_PAT, update config.json to use it (see README.md)"
    echo "  - Or use OAuth: opencode mcp auth github"
    echo ""
    echo "Configuration file: ${CONFIG_FILE}"
    echo "Log file: ${LOG_FILE}"
    echo "Backup directory: ${BACKUP_DIR}"
    echo ""
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Display header
    echo "=== OpenCode Configuration Setup v${SCRIPT_VERSION} ==="
    echo ""

    # Initialize logging
    init_logging

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

    # Main menu (if not quick setup)
    if [ "$QUICK_SETUP" = false ] && [ "$AUTO_ACCEPT" = false ]; then
        echo "Select an option:"
        echo "1) Copy config.json only (quick setup)"
        echo "2) Run full setup (API keys, Node.js, OpenCode, config)"
        echo ""

        local setup_option
        setup_option=$(prompt_user "Enter option" "2")

        case "$setup_option" in
            1)
                echo ""
                log_info "Quick Setup: Copy config.json only"
                QUICK_SETUP=true
                ;;
            2)
                log_info "Running full setup..."
                ;;
            *)
                log_warn "Invalid option. Running full setup..."
                ;;
        esac
        echo ""
    fi

    # Execute setup steps
    if [ "$QUICK_SETUP" = false ]; then
        setup_github_pat || true
        setup_zai_api_key || true
        setup_nvm || true
        setup_nodejs || true
        setup_opencode || true
    fi

    setup_config || true
    setup_bashrc_vars || true

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
