#!/bin/bash

# OpenCode Configuration Setup Script

set -e

echo "=== OpenCode Configuration Setup ==="
echo ""

# Interactive ZAI_API_KEY setup
echo "=== Z.AI API Key Setup ==="
echo "This setup requires a Z.AI API Key for MCP services."
echo ""

if [ -n "$ZAI_API_KEY" ]; then
    echo "ZAI_API_KEY is already set in your environment."
    echo "Current key (masked): ${ZAI_API_KEY:0:8}...${ZAI_API_KEY: -4}"
    echo ""
    read -p "Do you want to use the existing key? (y/n): " use_existing
    if [[ "$use_existing" != "y" && "$use_existing" != "Y" ]]; then
        echo "Please enter your Z.AI API Key:"
        read -s ZAI_API_KEY
        echo ""
    fi
else
    echo "Please enter your Z.AI API Key:"
    read -s ZAI_API_KEY
    echo ""
fi

if [ -z "$ZAI_API_KEY" ]; then
    echo "Warning: No ZAI_API_KEY provided. Some MCP services will not work."
    read -p "Continue without API key? (y/n): " continue_nokey
    if [[ "$continue_nokey" != "y" && "$continue_nokey" != "Y" ]]; then
        echo "Setup cancelled. Please run this script again with your API key."
        exit 1
    fi
else
    echo "API Key accepted: ${ZAI_API_KEY:0:8}...${ZAI_API_KEY: -4}"
    echo ""
fi

# Check and install/update nvm
echo "=== Checking nvm (Node Version Manager) ==="

# Check if nvm is installed
if command -v nvm &> /dev/null; then
    INSTALLED_NVM_VERSION=$(nvm --version 2>/dev/null)
    LATEST_NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//')

    echo "nvm is already installed."
    echo "Installed version: $INSTALLED_NVM_VERSION"
    echo "Latest version: $LATEST_NVM_VERSION"

    # Compare versions (simple string comparison for now)
    if [ "$INSTALLED_NVM_VERSION" != "$LATEST_NVM_VERSION" ]; then
        echo ""
        echo "⚠️  A newer version of nvm is available!"
        read -p "Would you like to update nvm to v$LATEST_NVM_VERSION? (y/n): " update_nvm
        if [[ "$update_nvm" == "y" || "$update_nvm" == "Y" ]]; then
        echo "Updating nvm..."
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${LATEST_NVM_VERSION}/install.sh" | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        echo "nvm updated successfully to $(nvm --version)."
        else
            echo "Skipping nvm update."
        fi
    else
        echo ""
        echo "✓ nvm is already up to date."
    fi
else
    echo "nvm is not installed."
    read -p "Install nvm? (y/n): " install_nvm
    if [[ "$install_nvm" == "y" || "$install_nvm" == "Y" ]]; then
        LATEST_NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//')
        echo "Installing nvm v$LATEST_NVM_VERSION..."
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${LATEST_NVM_VERSION}/install.sh" | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        echo "nvm installed successfully."
    else
        echo "Skipping nvm installation."
        echo "Note: nvm is required for Node.js management. Continuing may fail."
    fi
fi

# Install and use Node.js v24
echo ""
echo "=== Installing Node.js v24 ==="
read -p "Install/switch to Node.js v24? (y/n): " install_node
if [[ "$install_node" == "y" || "$install_node" == "Y" ]]; then
    nvm install 24
    nvm use 24
    echo "Node.js $(node --version) installed and active."
else
    echo "Skipping Node.js v24 installation."
fi

# Install/Update opencode-ai globally
echo ""
echo "=== Installing/Updating OpenCode ==="

# Check if opencode-ai is already installed
if command -v opencode &> /dev/null; then
    CURRENT_VERSION=$(opencode --version 2>/dev/null || echo "unknown")
    LATEST_VERSION=$(npm view opencode-ai version 2>/dev/null || echo "unknown")

    echo "opencode-ai is already installed."
    echo "Current version: $CURRENT_VERSION"
    echo "Latest version: $LATEST_VERSION"

    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo ""
        echo "⚠️  An update is available for opencode-ai!"
        read -p "Would you like to update to the latest version? (y/n): " update_opencode
        if [[ "$update_opencode" == "y" || "$update_opencode" == "Y" ]]; then
            echo "Updating opencode-ai..."
            npm install -g opencode-ai@latest
            echo "opencode-ai updated successfully to $(opencode --version)."
        else
            echo "Skipping opencode-ai update."
        fi
    else
        echo ""
        echo "✓ opencode-ai is already up to date."
        read -p "Reinstall opencode-ai anyway? (y/n): " reinstall_opencode
        if [[ "$reinstall_opencode" == "y" || "$reinstall_opencode" == "Y" ]]; then
            echo "Reinstalling opencode-ai..."
            npm install -g opencode-ai
            echo "opencode-ai reinstalled successfully."
        fi
    fi
else
    read -p "opencode-ai is not installed. Install it now? (y/n): " install_opencode
    if [[ "$install_opencode" == "y" || "$install_opencode" == "Y" ]]; then
        echo "Installing opencode-ai..."
        npm install -g opencode-ai
        echo "opencode-ai installed successfully."
    else
        echo "Skipping opencode-ai installation."
    fi
fi

# Create config directory
echo ""
echo "=== Configuration Setup ==="
CONFIG_DIR="$HOME/.config/opencode"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"
echo "Created $CONFIG_DIR directory."

# Check if config.json already exists
if [ -f "$CONFIG_FILE" ]; then
    echo ""
    echo "⚠️  config.json already exists at $CONFIG_FILE"
    read -p "Do you want to overwrite it? (y/n): " overwrite_config
    if [[ "$overwrite_config" != "y" && "$overwrite_config" != "Y" ]]; then
        echo "Skipping config.json copy. Existing configuration preserved."
        skip_config_copy=true
    fi
fi

# Copy config.json
if [ "$skip_config_copy" != true ]; then
    echo ""
    read -p "Copy config.json to $CONFIG_DIR/? (y/n): " copy_config
    if [[ "$copy_config" == "y" || "$copy_config" == "Y" ]]; then
        if [ -f "config.json" ]; then
            cp config.json "$CONFIG_DIR/"
            echo "config.json copied successfully."
        else
            echo "Warning: config.json not found in current directory."
        fi
    else
        echo "Skipping config.json copy."
    fi
fi

# Add ZAI_API_KEY to ~/.bashrc if not already present
if [ -n "$ZAI_API_KEY" ]; then
    echo ""
    read -p "Add ZAI_API_KEY to ~/.bashrc for persistent access? (y/n): " add_bashrc
    if [[ "$add_bashrc" == "y" || "$add_bashrc" == "Y" ]]; then
    BASHRC_FILE="$HOME/.bashrc"
    if ! grep -q "ZAI_API_KEY" "$BASHRC_FILE"; then
        echo "Adding ZAI_API_KEY to $BASHRC_FILE..."
        echo "export ZAI_API_KEY=\"$ZAI_API_KEY\"" >> "$BASHRC_FILE"
        echo "ZAI_API_KEY added to $BASHRC_FILE."
    else
        echo "ZAI_API_KEY already exists in $BASHRC_FILE."
    fi
    else
        echo "Skipping ~/.bashrc update."
    fi
fi

echo ""
echo "=== Setup Summary ==="
echo ""

# Check what was installed
if command -v nvm &> /dev/null; then
    NVM_VERSION=$(nvm --version 2>/dev/null)
    echo "✓ nvm: Installed (v$NVM_VERSION)"
else
    echo "✗ nvm: Not installed"
fi

if command -v node &> /dev/null; then
    echo "✓ Node.js: $(node --version)"
else
    echo "✗ Node.js: Not installed"
fi

if command -v opencode &> /dev/null; then
    OC_VERSION=$(opencode --version 2>/dev/null || echo "unknown")
    echo "✓ opencode-ai: Installed (v$OC_VERSION)"
else
    echo "✗ opencode-ai: Not installed"
fi

CONFIG_DIR="$HOME/.config/opencode"
CONFIG_FILE="$CONFIG_DIR/config.json"
BASHRC_FILE="$HOME/.bashrc"

if [ -f "$CONFIG_FILE" ]; then
    echo "✓ config.json: Copied to $CONFIG_DIR/"
else
    echo "✗ config.json: Not copied"
fi

if grep -q "ZAI_API_KEY" "$BASHRC_FILE"; then
    echo "✓ ZAI_API_KEY: Added to $BASHRC_FILE"
else
    echo "✗ ZAI_API_KEY: Not added to $BASHRC_FILE"
fi

echo ""
echo "=== Next Steps ==="
echo ""
echo "To finish setup:"
echo "1. Restart your terminal or run: source $BASHRC_FILE"
echo "2. Ensure LM Studio is running on http://127.0.0.1:1234/v1"
echo "3. Verify installation: opencode --version"
echo "4. Test configuration: opencode --help"
echo ""
echo "Configuration file located at: $CONFIG_FILE"
echo ""
read -p "Press Enter to exit..."
