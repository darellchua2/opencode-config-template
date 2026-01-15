# OpenCode Configuration Template

This repository contains a pre-configured OpenCode configuration file with support for local LM Studio, GitHub integration via GitHub MCP server, Jira/Confluence integration via Atlassian MCP, and Z.AI services.

## Prerequisites

- **Node.js v24** and **npm** installed (required for MCP servers)
- **LM Studio** running locally on port 1234 (for local LLM)
- **Z.AI API Key** (required for Z.AI MCP services)
- **GitHub account** (required for GitHub MCP server)

### Install Node.js using nvm

```bash
# Install nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Reload shell configuration
source ~/.bashrc

# Install and use Node.js v24
nvm install 24
nvm use 24

# Verify installation
node --version
npm --version
```

### Install OpenCode

```bash
npm install -g opencode-ai
```

## Setup Instructions

### 1. Create Configuration Directory

```bash
mkdir -p ~/.config/opencode
```

### 2. Copy Configuration File

```bash
cp config.json ~/.config/opencode/
```

### 3. Set ZAI_API_KEY Environment Variable

Add your Z.AI API key to `~/.bashrc` for persistent access:

```bash
echo 'export ZAI_API_KEY="your-actual-api-key-here"' >> ~/.bashrc
```

Then reload your shell configuration:

```bash
source ~/.bashrc
```

### 4. Authenticate with GitHub MCP Server

The GitHub MCP server uses OAuth authentication. Run the following command to authenticate:

```bash
opencode mcp auth github
```

This will open your browser to complete the OAuth flow and connect OpenCode to your GitHub account.

Alternatively, you can use a GitHub Personal Access Token (PAT):

1. Create a GitHub PAT at https://github.com/settings/personal-access-tokens/new
2. Set the `GITHUB_PAT` environment variable:

```bash
echo 'export GITHUB_PAT="your-github-pat-here"' >> ~/.bashrc
source ~/.bashrc
```

Then update `config.json` to use the PAT instead of OAuth:

```json
"github": {
  "type": "remote",
  "url": "https://api.githubcopilot.com/mcp/",
  "oauth": false,
  "headers": {
    "Authorization": "Bearer {env:GITHUB_PAT}"
  }
}
```

### 5. Verify Setup

Confirm the configuration is in place:

```bash
cat ~/.config/opencode/config.json
echo $ZAI_API_KEY
```

## Configuration Overview

### Provider
- **LM Studio (local)** - Running at `http://127.0.0.1:1234/v1`
  - Model: `openai/gpt-oss-20b` (GPT-OSS 20B)

### Agent
- **jira-handler** - Automated Jira ticket management agent
  - Can read, comment, update, and transition Jira tickets
  - Uses Atlassian MCP tools

### MCP Servers
- **github** - GitHub integration for repositories, issues, PRs, Actions, and more
- **atlassian** - Jira and Confluence integration
- **web-reader** - Web content reading via Z.AI
- **web-search-prime** - Web search via Z.AI
- **zai-mcp-server** - Local Z.AI MCP server
- **zread** - Additional reading capabilities via Z.AI

## Important Notes

- Replace `"your-actual-api-key-here"` with your actual Z.AI API key
- LM Studio must be running locally on port 1234 before using OpenCode
- The configuration uses `${ZAI_API_KEY}` environment variable syntax for security
- Do not commit actual API keys to version control

## Troubleshooting

### Z.AI services not working
- Verify `ZAI_API_KEY` is set: `echo $ZAI_API_KEY`
- Ensure you replaced the placeholder with a valid API key

### LM Studio connection failed
- Check that LM Studio is running: `curl http://127.0.0.1:1234/v1/models`
- Verify the server is listening on port 1234

### MCP servers not starting
- Ensure Node.js and npm are installed: `node --version && npm --version`
- Check internet connectivity for remote MCP servers
- Verify GitHub authentication: `opencode mcp auth list`

### Config not loading
- Verify file path: `ls -la ~/.config/opencode/config.json`
- Check JSON syntax: `jq . ~/.config/opencode/config.json` (requires `jq`)
