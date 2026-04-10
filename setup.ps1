<#
.SYNOPSIS
    OpenCode Configuration Setup Script for Windows (PowerShell)

.DESCRIPTION
    Automated setup for OpenCode configuration on Windows with proper error
    handling, logging, and user experience enhancements.

.EXAMPLE
    .\setup.ps1                      # Interactive menu (recommended)
    .\setup.ps1 -Quick               # Quick setup (config + skills only)
    .\setup.ps1 -SkillsOnly          # Skills deployment only
    .\setup.ps1 -Update              # Update OpenCode CLI to latest
    .\setup.ps1 -DryRun              # Preview all actions without changes
    .\setup.ps1 -Yes                 # Auto-accept all prompts
    .\setup.ps1 -Help                # Show detailed help

.NOTES
    Requires PowerShell 5.1+ (ships with Windows 10/11)
#>

[CmdletBinding()]
param(
    [switch]$Quick,
    [switch]$SkillsOnly,
    [switch]$Update,
    [switch]$DryRun,
    [switch]$Yes,
    [switch]$Help,

    [ValidateSet("daily", "weekly", "monthly", "manual")]
    [string]$ScheduleUpdate = "manual",

    [switch]$EnableAutoUpdate,
    [switch]$DisableAutoUpdate,
    [switch]$CheckUpdate,

    [int]$KeepBackups = 5
)

$ErrorActionPreference = "Continue"
Set-StrictMode -Version Latest

################################################################################
# GLOBAL VARIABLES
################################################################################

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Get-Location }

$VersionFile = Join-Path $ScriptDir "VERSION"
if (Test-Path $VersionFile) {
    $ScriptVersion = (Get-Content $VersionFile -Raw).Trim()
} else {
    $ScriptVersion = "2.0.0"
}

$ConfigDir = Join-Path $HOME ".config\opencode"
$ConfigFile = Join-Path $ConfigDir "config.json"
$SkillsDir = Join-Path $ConfigDir "skills"
$AgentsSrcDir = Join-Path $ScriptDir "agents"
$AgentsDestDir = Join-Path $ConfigDir "agents"
$BackupDir = Join-Path $HOME ".opencode-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$LogFile = Join-Path $HOME ".opencode-setup.log"
$LastUpdateCheck = Join-Path $ConfigDir ".last-update-check"
$UpdateLog = Join-Path $ConfigDir "update.log"

$ZaiApiKey = $env:ZAI_API_KEY
$JiraClientId = $env:JIRA_CLIENT_ID
$JiraClientSecret = $env:JIRA_CLIENT_SECRET
$JiraAccessToken = $env:JIRA_ACCESS_TOKEN
$JiraRefreshToken = $env:JIRA_REFRESH_TOKEN
$JiraCloudId = $env:JIRA_CLOUD_ID

# JIRA PAT credentials (simpler alternative to OAuth2)
$JiraPat = $env:JIRA_PAT
$JiraSite = $env:JIRA_SITE

$SkipConfigCopy = $false

################################################################################
# LOGGING FUNCTIONS
################################################################################

function Initialize-Logging {
    $logDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    if (-not (Test-Path $LogFile)) {
        New-Item -ItemType File -Path $LogFile -Force | Out-Null
    }
    Write-Log "INFO" "=== OpenCode Setup Started at $(Get-Date) ==="
    Write-Log "INFO" "Script version: $ScriptVersion"
    Write-Log "INFO" "User: $env:USERNAME"
    Write-Log "INFO" "PowerShell version: $($PSVersionTable.PSVersion)"
    Write-Log "INFO" "Working directory: $(Get-Location)"
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Level,
        [Parameter(Mandatory)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"

    try {
        Add-Content -Path $LogFile -Value $logLine -ErrorAction SilentlyContinue
    } catch {}

    switch ($Level) {
        "ERROR"   { Write-Host "[$Level] $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[$Level] $Message" -ForegroundColor Yellow }
        "SUCCESS" { Write-Host "[$Level] $Message" -ForegroundColor Green }
        "DEBUG"   { if ($VerbosePreference -eq "Continue") { Write-Host "[$Level] $Message" -ForegroundColor Gray } }
        default   { Write-Host "[$Level] $Message" }
    }
}

function Write-LogInfo    { param([string]$Msg) Write-Log "INFO"    $Msg }
function Write-LogWarn    { param([string]$Msg) Write-Log "WARNING" $Msg }
function Write-LogError   { param([string]$Msg) Write-Log "ERROR"   $Msg }
function Write-LogSuccess { param([string]$Msg) Write-Log "SUCCESS" $Msg }
function Write-LogDebug   { param([string]$Msg) Write-Log "DEBUG"   $Msg }

################################################################################
# UTILITY FUNCTIONS
################################################################################

function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-WithDryRun {
    param([Parameter(Mandatory)][string]$Command, [string]$Description = $Command)

    Write-LogDebug "Executing: $Command"

    if ($DryRun) {
        Write-Host "[DRY-RUN] Would execute: $Command" -ForegroundColor Cyan
        return $true
    }

    try {
        $result = Invoke-Expression $Command
        return $true
    } catch {
        Write-LogError "Command failed: $Description"
        Write-LogError $_.Exception.Message
        return $false
    }
}

function Read-Prompt {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Default = ""
    )

    if ($Yes -and $Default) {
        Write-LogDebug "Auto-accepting with default: $Default"
        return $Default
    }

    $promptText = if ($Default) { "${Message} [${Default}]: " } else { "${Message}: " }
    $result = Read-Host $promptText
    if ([string]::IsNullOrWhiteSpace($result) -and $Default) {
        return $Default
    }
    return $result
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)][string]$Message,
        [bool]$DefaultYes = $false
    )

    if ($Yes) {
        return $DefaultYes
    }

    $defaultDisplay = if ($DefaultYes) { "Y/n" } else { "y/N" }
    $response = Read-Host "$Message [$defaultDisplay]"
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }
    return $response -match "^[Yy]"
}

function New-FileBackup {
    param([Parameter(Mandatory)][string]$FilePath)

    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        Write-LogInfo "Created backup directory: $BackupDir"
    }

    if (Test-Path $FilePath) {
        $fileName = Split-Path $FilePath -Leaf
        $backupPath = Join-Path $BackupDir $fileName
        Copy-Item $FilePath $backupPath -Force
        Write-LogInfo "Backed up: $FilePath -> $backupPath"
    }
}

function Remove-OldBackups {
    if ($KeepBackups -lt 0) {
        Write-LogDebug "Backup cleanup disabled (KeepBackups=$KeepBackups)"
        return
    }

    $allBackups = @(Get-ChildItem $HOME -Directory -Filter ".opencode-backup-*" -ErrorAction SilentlyContinue)
    $allBackups += @(Get-ChildItem $HOME -Directory -Filter ".opencode-update-backup-*" -ErrorAction SilentlyContinue)

    if ($allBackups.Count -eq 0) {
        Write-LogDebug "No old backups found"
        return
    }

    $allBackups = $allBackups | Sort-Object LastWriteTime -Descending

    if ($allBackups.Count -le $KeepBackups) {
        Write-LogDebug "Found $($allBackups.Count) backup(s) (within retention limit of $KeepBackups)"
        return
    }

    $toDelete = $allBackups | Select-Object -Skip $KeepBackups
    Write-LogInfo "Cleaning up old backups (keeping $KeepBackups of $($allBackups.Count))..."

    foreach ($dir in $toDelete) {
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would remove old backup: $($dir.FullName)" -ForegroundColor Cyan
        } else {
            Remove-Item $dir.FullName -Recurse -Force
            Write-LogInfo "Removed old backup: $($dir.FullName)"
        }
    }

    Write-LogSuccess "Cleaned up $($toDelete.Count) old backup(s)"
}

function Test-ApiKey {
    param(
        [string]$Key,
        [string]$KeyName = "API Key"
    )

    if ([string]::IsNullOrWhiteSpace($Key)) {
        Write-LogWarn "No $KeyName provided"
        return $false
    }
    if ($Key.Length -lt 10) {
        Write-LogWarn "$KeyName seems too short (minimum 10 characters)"
        return $false
    }
    return $true
}

function Get-MaskedValue {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -lt 12) { return "<hidden>" }
    return "$($Value.Substring(0,8))...$($Value.Substring($Value.Length - 4))"
}

################################################################################
# SHOW HELP
################################################################################

function Show-Help {
    @"

=======================================================================
                    OpenCode Configuration Setup v$ScriptVersion
                    (Windows PowerShell Edition)
=======================================================================

USAGE:
    .\setup.ps1 [OPTIONS]

=======================================================================
                            SETUP MODES
=======================================================================

  MODE                    WHAT IT DOES                          WHEN TO USE
  ----------------------------------------------------------------------
  Interactive (default)   Full setup with guided prompts       First-time setup
                           1. GitHub PAT setup (optional)
                           2. Z.AI API key setup
                           3. Node.js check/install
                           4. opencode-ai installation
                           5. config.json deployment
                           6. skills/ deployment
                           7. Environment variable persistence

  -Quick                  Copy config files only                Already have
                           1. config.json -> ~/.config/opencode/  dependencies
                           2. AGENTS.md -> ~/.config/opencode/
                           3. skills/* -> ~/.config/opencode/skills/

  -SkillsOnly             Deploy skills only                    opencode-ai already
                           1. Validates opencode-ai installed    installed
                           2. Copies skills/* to config dir

  -Update                 Update opencode-ai CLI only           Keep CLI current

=======================================================================
                            OPTIONS
=======================================================================

  SETUP OPTIONS:
    -Quick                Quick setup mode (config + skills only)
    -SkillsOnly           Skills-only deployment mode
    -Update               Update OpenCode CLI to latest version

  UPDATE MANAGEMENT:
    -EnableAutoUpdate         Enable automatic opencode-ai updates
    -DisableAutoUpdate        Disable automatic updates
    -ScheduleUpdate <sched>   Set update frequency: daily, weekly, monthly, manual
    -CheckUpdate              Check for updates without installing

  UTILITY OPTIONS:
    -Help                Show this help message
    -DryRun              Preview all actions without making changes
    -Yes                 Auto-accept all prompts (non-interactive)
    -KeepBackups <N>     Keep only N most recent backups (default: 5)
                           0 = delete all old backups, negative = keep all

=======================================================================
                         CONFIGURED FEATURES
=======================================================================

  AGENTS (8):
    build (default)      Full-featured coding agent with all tools
    plan                 Planning agent (read-only, edits need approval)
    explore              Fast codebase exploration and analysis
    image-analyzer       Images/screenshots -> code, OCR, error diagnosis
    diagram-creator      Diagrams (architecture, flowcharts, UML)
    mermaid-diagram-subagent  Mermaid diagrams with PNG conversion
    civil-3d-specialist-subagent  Autodesk Civil 3D model modifications and features
    open3d-specialist    Open3D 3D data processing guidance

    Usage: opencode --agent build 'implement auth feature'
           opencode --agent explore 'find all API routes'

     SKILLS (50):
        Framework (9):        test-generator-framework, linting-workflow,
                              pr-creation-workflow, jira-git-integration,
                              error-resolver-workflow, tdd-workflow, docx-creation,
                              coverage-framework, pptx-specialist

       Language-Specific (4): python-pytest-creator, python-ruff-linter,
                             javascript-eslint-linter, changelog-python-cliff

      Framework-Specific (5): nextjs-pr-workflow, nextjs-unit-test-creator,
                            nextjs-standard-setup, nextjs-image-usage,
                            typescript-dry-principle

      OpenCode Meta (3):    opencode-agent-creation, opencode-skill-creation,
                            opencode-skills-maintainer

     OpenTofu (7):         opentofu-aws-explorer, opentofu-keycloak-explorer,
                           opentofu-kubernetes-explorer, opentofu-neon-explorer,
                           opentofu-provider-setup, opentofu-provisioning-workflow,
                           opentofu-ecr-provision

     Git/Workflow (6):     ascii-diagram-creator, git-pr-creator,
                           git-issue-labeler, git-issue-plan-workflow,
                           git-issue-updater, git-semantic-commits

     Documentation (3):    coverage-readme-workflow, docstring-generator,
                           documentation-sync-workflow

      JIRA (5):             jira-ticket-oauth-workflow, jira-ticket-pat-workflow,
                            jira-ticket-plan-workflow, jira-status-updater,
                            jira-git-integration

     Code Quality (7):     solid-principles, clean-code, clean-architecture,
                           design-patterns, object-design, code-smells,
                           complexity-management

    Run 'opencode --list-skills' for detailed descriptions
    Run 'opencode --skill <name> \"prompt\"' to invoke a skill

=======================================================================
                            REQUIREMENTS
=======================================================================

  Required:
    PowerShell 5.1+       Ships with Windows 10/11
    Node.js v20+          For opencode-ai and MCP servers

  Recommended:
    nvm-windows            Node version manager (https://github.com/coreybutler/nvm-windows/releases)
    git                   For version control
    Mermaid CLI           For diagram generation (npm install -g @mermaid-js/mermaid-cli)

  API Keys (prompted during setup):
    ZAI_API_KEY           Required for web-reader, web-search-prime, zread
                          Get from: https://z.ai

  GitHub Auth:
    GitHub CLI (gh)      Recommended for GitHub MCP features
                         Install: https://cli.github.com/
                         Or use OAuth: opencode mcp auth github

  Local Services:
    LM Studio             Running on http://127.0.0.1:1234/v1

=======================================================================

For more information: https://opencode.ai
Report issues: https://github.com/anomalyco/opencode/issues

"@
}

################################################################################
# DEPENDENCY CHECKS
################################################################################

function Test-Dependencies {
    Write-LogInfo "Checking basic dependencies..."

    $missing = @()

    if (-not (Test-CommandExists "curl.exe")) {
        if (-not (Test-CommandExists "curl")) {
            $missing += "curl"
        }
    }

    if (-not (Test-CommandExists "git")) {
        Write-LogWarn "git is not installed (recommended but not required)"
    }

    if ($missing.Count -gt 0) {
        Write-LogError "Missing required dependencies: $($missing -join ', ')"
        Write-LogInfo "Please install missing dependencies and try again"
        return $false
    }

    Write-LogSuccess "All required dependencies are installed"
    return $true
}

function Test-Network {
    Write-LogInfo "Checking network connectivity..."

    $urls = @("https://api.github.com", "https://registry.npmjs.org")
    $ok = $true

    foreach ($url in $urls) {
        try {
            $null = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -UseBasicParsing
            Write-LogDebug "Connected to: $url"
        } catch {
            Write-LogWarn "Cannot reach: $url"
            $ok = $false
        }
    }

    if (-not $ok) {
        Write-LogError "Network connectivity issues detected"
        return $false
    }

    Write-LogSuccess "Network connectivity OK"
    return $true
}

################################################################################
# SETUP: GitHub CLI
################################################################################

function Set-GitHubCLI {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "              GitHub CLI Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""

    if (Test-CommandExists "gh") {
        $ghAuthResult = $null
        try {
            $ghAuthResult = & gh auth status 2>&1
            if ($LASTEXITCODE -eq 0) {
                $ghUser = (& gh api user --jq '.login' 2>$null)
                if ([string]::IsNullOrWhiteSpace($ghUser)) { $ghUser = "unknown" }
                Write-LogSuccess "GitHub CLI is installed and authenticated as: $ghUser"
                Write-LogInfo "Run 'opencode mcp auth github' to configure GitHub MCP authentication"
                return
            }
        } catch {}

        Write-LogWarn "GitHub CLI is installed but not authenticated."
        Write-Host ""
        Write-Host "  To authenticate, run:" -ForegroundColor Yellow
        Write-Host "    gh auth login" -ForegroundColor White
        Write-Host ""
        Write-Host "  Then re-run this setup or run: opencode mcp auth github"
    } else {
        Write-LogWarn "GitHub CLI (gh) is not installed."
        Write-Host ""
        Write-Host "  Install GitHub CLI:" -ForegroundColor Yellow
        Write-Host "    winget install GitHub.cli"
        Write-Host "    -- or --"
        Write-Host "    choco install gh"
        Write-Host ""
        Write-Host "  After installing, run: gh auth login"
        Write-Host "  Then re-run this setup or run: opencode mcp auth github"
    }
}

################################################################################
# SETUP: Z.AI API Key
################################################################################

function Set-ZaiApiKey {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "                  Z.AI API Key Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "This setup requires a Z.AI API Key for MCP services."
    Write-Host ""

    $keyFromRegistry = $null
    try {
        $keyFromRegistry = (Get-ItemPropertyValue -Path "HKCU:\Environment" -Name "ZAI_API_KEY" -ErrorAction SilentlyContinue)
    } catch {}

    if ($keyFromRegistry -and [string]::IsNullOrWhiteSpace($ZaiApiKey)) {
        $ZaiApiKey = $keyFromRegistry
    }

    if (-not [string]::IsNullOrWhiteSpace($ZaiApiKey)) {
        Write-Host "ZAI_API_KEY is already set in your environment."
        Write-Host "Current key (masked): $(Get-MaskedValue $ZaiApiKey)"
        Write-Host ""

        if (Read-YesNo "Use existing key?" $true) {
            Write-LogInfo "Using existing ZAI_API_KEY"
            return
        }
    }

    Write-Host "Please enter your Z.AI API Key:"
    $secureInput = Read-Host -AsSecureString
    $ZaiApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput)
    )
    Write-Host ""

    if (-not (Test-ApiKey -Key $ZaiApiKey -KeyName "ZAI_API_KEY")) {
        Write-LogError "No valid ZAI_API_KEY provided"

        if (-not (Read-YesNo "Continue without API key? Some MCP services will not work." $false)) {
            Write-LogError "Setup cancelled. Please run this script again with your API key."
            exit 1
        }
    } else {
        Write-LogSuccess "API Key accepted: $(Get-MaskedValue $ZaiApiKey)"
    }
}

################################################################################
# SETUP: JIRA OAuth2
################################################################################

function Set-JiraOAuth {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "              JIRA OAuth2 Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "Prerequisites:"
    Write-Host "  1. Create OAuth2 app at: https://developer.atlassian.com/console/myapps/"
    Write-Host "  2. Add callback URL: http://localhost:8085/callback"
    Write-Host "  3. Enable scopes: read:jira-work, write:jira-work, offline_access"
    Write-Host ""

    if (-not [string]::IsNullOrWhiteSpace($JiraClientId) -and -not [string]::IsNullOrWhiteSpace($JiraAccessToken)) {
        Write-Host "JIRA OAuth2 is already configured."
        Write-Host "  Client ID: $($JiraClientId.Substring(0, [Math]::Min(8, $JiraClientId.Length)))..."
        Write-Host "  Access Token: $(Get-MaskedValue $JiraAccessToken)"
        Write-Host ""

        if (-not (Read-YesNo "Reconfigure?" $false)) {
            Write-LogInfo "Keeping existing configuration"
            return
        }
    }

    Write-Host "Step 1/4: Enter your OAuth2 Client ID"
    $JiraClientId = Read-Prompt "JIRA Client ID" ""
    if ([string]::IsNullOrWhiteSpace($JiraClientId)) {
        Write-LogWarn "No Client ID provided, skipping"
        return
    }

    Write-Host ""
    Write-Host "Step 2/4: Enter your OAuth2 Client Secret"
    $secureSecret = Read-Host "JIRA Client Secret" -AsSecureString
    $JiraClientSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSecret)
    )
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($JiraClientSecret)) {
        Write-LogWarn "No Client Secret provided, skipping"
        return
    }

    Write-Host ""
    Write-Host "Step 3/4: Open this URL in your browser and authorize:"
    Write-Host ""
    $authUrl = "https://auth.atlassian.com/authorize?audience=api.atlassian.com&client_id=$JiraClientId&scope=read%3Ajira-work%20write%3Ajira-work%20offline_access&redirect_uri=http%3A%2F%2Flocalhost%3A8085%2Fcallback&response_type=code&prompt=consent"
    Write-Host "  $authUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "After authorization, browser redirects to localhost:8085/callback?code=XXXXX"
    Write-Host "Copy the 'code' value from the URL."
    Write-Host ""

    Write-Host "Step 4/4: Paste the authorization code"
    $authCode = Read-Prompt "Authorization code" ""

    if ([string]::IsNullOrWhiteSpace($authCode)) {
        Write-LogError "No authorization code provided"
        return
    }

    Write-Host ""
    Write-LogInfo "Exchanging code for tokens..."

    try {
        $body = @{
            grant_type    = "authorization_code"
            client_id     = $JiraClientId
            client_secret = $JiraClientSecret
            code          = $authCode
            redirect_uri  = "http://localhost:8085/callback"
        } | ConvertTo-Json

        $tokenResponse = Invoke-RestMethod -Method Post `
            -Uri "https://auth.atlassian.com/oauth/token" `
            -ContentType "application/json" `
            -Body $body

        $JiraAccessToken = $tokenResponse.access_token
        $JiraRefreshToken = $tokenResponse.refresh_token

        if ([string]::IsNullOrWhiteSpace($JiraAccessToken)) {
            Write-LogError "Failed to obtain tokens"
            Write-Host "Response: $($tokenResponse | ConvertTo-Json -Depth 3)"
            return
        }

        Write-LogSuccess "Tokens obtained"

        Write-LogInfo "Fetching Cloud ID..."
        $resources = Invoke-RestMethod -Method Get `
            -Uri "https://api.atlassian.com/oauth/token/accessible-resources" `
            -Headers @{ "Authorization" = "Bearer $JiraAccessToken" }

        if ($resources -and $resources.Count -gt 0) {
            $JiraCloudId = $resources[0].id
        }

        Write-LogSuccess "JIRA OAuth2 configured"
        Write-Host ""
        Write-Host "Summary:"
        Write-Host "  Client ID: $($JiraClientId.Substring(0, [Math]::Min(8, $JiraClientId.Length)))..."
        Write-Host "  Access Token: $(Get-MaskedValue $JiraAccessToken)"
        Write-Host "  Cloud ID: $(if ($JiraCloudId) { $JiraCloudId } else { '<not set>' })"
        Write-Host ""
    } catch {
        Write-LogError "Token exchange failed: $($_.Exception.Message)"
    }
}

################################################################################
# SETUP: JIRA PAT
################################################################################

function Set-JiraPAT {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "              JIRA PAT Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "Personal Access Tokens (PAT) are simpler than OAuth2:" -ForegroundColor Cyan
    Write-Host "  - No token refresh needed"
    Write-Host "  - No callback server required"
    Write-Host "  - Tokens don't expire"
    Write-Host ""
    Write-Host "To create a PAT:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://id.atlassian.com/manage-profile/security/pat"
    Write-Host "  2. Click 'Create token'"
    Write-Host "  3. Select scopes: read:jira-work, write:jira-work"
    Write-Host "  4. Copy the token"
    Write-Host ""

    if (-not [string]::IsNullOrWhiteSpace($JiraPat)) {
        Write-Host "JIRA PAT is already configured."
        Write-Host "  Site: $(if ($JiraSite) { $JiraSite } else { '<not set>' })"
        Write-Host "  Token: $(Get-MaskedValue $JiraPat)"
        Write-Host ""

        if (-not (Read-YesNo "Reconfigure?" $false)) {
            Write-LogInfo "Keeping existing configuration"
            return
        }
    }

    Write-Host "Step 1/2: Enter your Atlassian site"
    Write-Host "Example: your-company.atlassian.net"
    $JiraSite = Read-Prompt "JIRA Site" ""
    if ([string]::IsNullOrWhiteSpace($JiraSite)) {
        Write-LogWarn "No site provided, skipping"
        return
    }

    Write-Host ""
    Write-Host "Step 2/2: Enter your Personal Access Token"
    $securePat = Read-Host "JIRA PAT" -AsSecureString
    $JiraPat = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePat)
    )
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($JiraPat)) {
        Write-LogWarn "No PAT provided, skipping"
        return
    }

    Write-Host ""
    Write-LogInfo "Verifying token..."

    try {
        $response = Invoke-WebRequest -Method Get `
            -Uri "https://$JiraSite/rest/api/3/myself" `
            -Headers @{ "Authorization" = "Bearer $JiraPat" } `
            -UseBasicParsing -ErrorAction SilentlyContinue

        if ($response.StatusCode -eq 200) {
            Write-LogSuccess "Token verified successfully"
        }
    } catch {
        Write-LogWarn "Could not verify token. Token may still be valid."
    }

    Write-LogSuccess "JIRA PAT configured"
    Write-Host ""
    Write-Host "Summary:"
    Write-Host "  Site: $JiraSite"
    Write-Host "  Token: $(Get-MaskedValue $JiraPat)"
    Write-Host ""
}

################################################################################
# SETUP: PeonPing
################################################################################

function Set-PeonPing {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "              PeonPing Sound Notifications Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "PeonPing plays game character voice lines when your AI agent"
    Write-Host "finishes work or needs permission. Works with Claude Code and OpenCode!"
    Write-Host ""
    Write-Host "Features:"
    Write-Host "  - Voice notifications from Warcraft, StarCraft, Portal, and more"
    Write-Host "  - Desktop notifications when agent needs attention"
    Write-Host "  - 160+ sound packs available"
    Write-Host "  - OpenCode TypeScript plugin for native integration"
    Write-Host ""

    if (-not (Read-YesNo "Install PeonPing?" $true)) {
        Write-LogInfo "Skipping PeonPing installation"
        return
    }

    $peonInstallDir = Join-Path $env:USERPROFILE ".claude\hooks\peon-ping"
    if ((Test-Path (Join-Path $peonInstallDir "peon.ps1")) -or (Test-CommandExists "peon")) {
        Write-LogInfo "PeonPing is already installed"
        if (-not (Read-YesNo "Reinstall/update PeonPing?" $false)) {
            Write-LogInfo "Keeping existing PeonPing installation"
            Write-Host ""
            if (Read-YesNo "Install/update PeonPing OpenCode plugin?" $true) {
                Set-PeonPingPlugin
            }
            return
        }
    }

    Write-LogInfo "Installing PeonPing via native Windows installer..."
    Write-Host ""

    try {
        $installerUrl = "https://raw.githubusercontent.com/PeonPing/peon-ping/main/install.ps1"

        if (-not $DryRun) {
            Write-Host "  Downloading and running Windows installer..." -ForegroundColor Cyan
            Write-Host "  Source: $installerUrl"
            Write-Host ""

            $installerTemp = Join-Path $env:TEMP "peon-ping-install.ps1"
            Invoke-WebRequest -Uri $installerUrl -OutFile $installerTemp -UseBasicParsing
            Unblock-File -Path $installerTemp -ErrorAction SilentlyContinue

            $peonArgs = @("-NoProfile", "-File", $installerTemp)

            $policy = Get-ExecutionPolicy -Scope CurrentUser
            if ($policy -eq "Restricted") {
                Write-Host "  Note: Execution policy is Restricted, using Bypass for installer" -ForegroundColor Yellow
                $peonArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $installerTemp)
            }

            & powershell.exe @peonArgs
            $installExitCode = $LASTEXITCODE

            Remove-Item $installerTemp -Force -ErrorAction SilentlyContinue

            if ($installExitCode -ne 0 -and $installExitCode -ne 0) {
                Write-LogWarn "PeonPing installer exited with code: $installExitCode"
            }
        } else {
            Write-Host "[DRY-RUN] Would download and run: $installerUrl" -ForegroundColor Cyan
            Write-Host "[DRY-RUN] Would then install OpenCode TypeScript plugin" -ForegroundColor Cyan
        }

        if ((Test-Path (Join-Path $peonInstallDir "peon.ps1")) -or (Test-CommandExists "peon")) {
            Write-LogSuccess "PeonPing installed successfully"

            Write-Host ""
            Write-Host "Quick commands:"
            Write-Host "  peon status          - Check if active"
            Write-Host "  peon preview         - Play test sounds"
            Write-Host "  peon packs list      - List installed packs"
            Write-Host "  peon packs install <name>   - Install a pack"
            Write-Host "  peon volume 0.5      - Set volume (0.0-1.0)"
            Write-Host "  peon toggle          - Mute/unmute sounds"
            Write-Host ""

            if (Read-YesNo "Install PeonPing OpenCode plugin?" $true) {
                Set-PeonPingPlugin
            }
        } else {
            Write-LogWarn "PeonPing installation may not have completed correctly"
            Write-Host ""
            Write-Host "Try installing manually:" -ForegroundColor Yellow
            Write-Host "  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/PeonPing/peon-ping/main/install.ps1' -UseBasicParsing | Invoke-Expression" -ForegroundColor Yellow
            Write-Host ""
        }
    } catch {
        Write-LogError "PeonPing installation failed: $($_.Exception.Message)"
        Write-LogInfo "Install manually: https://github.com/PeonPing/peon-ping"
    }
}

function Set-PeonPingPlugin {
    Write-Host ""
    Write-LogInfo "Configuring PeonPing for OpenCode..."

    $pluginsDir = Join-Path $ConfigDir "plugins"
    $peonPlugin = Join-Path $pluginsDir "peon-ping.ts"
    $peonConfigDir = Join-Path $ConfigDir "peon-ping"
    $peonConfigFile = Join-Path $peonConfigDir "config.json"

    # Check if plugin already installed
    if ((Test-Path $peonPlugin) -and (Test-Path $peonConfigFile)) {
        Write-LogInfo "PeonPing plugin already installed at $peonPlugin"
        if (-not (Read-YesNo "Reinstall PeonPing plugin?" $false)) {
            Write-LogInfo "Keeping existing PeonPing plugin"
            return
        }
    }

    $peonAdapter = $null

    # Find the PeonPing adapter script (installer)
    $possiblePaths = @(
        (Join-Path $env:USERPROFILE ".claude\hooks\peon-ping\adapters\opencode.sh"),
        "C:\Program Files\peon-ping\libexec\adapters\opencode.sh",
        (Join-Path ${env:ProgramFiles} "peon-ping\libexec\adapters\opencode.sh"),
        (Join-Path ${env:LOCALAPPDATA} "Programs\peon-ping\libexec\adapters\opencode.sh")
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $peonAdapter = $path
            break
        }
    }

    if ($peonAdapter) {
        Write-LogInfo "Found adapter: $peonAdapter"
        Write-LogInfo "Running PeonPing OpenCode adapter installer..."
        
        if (-not $DryRun) {
            # Run bash adapter in Git Bash if available, otherwise download TS directly
            if (Test-CommandExists "bash") {
                & bash $peonAdapter
            } else {
                Write-LogInfo "Git Bash not found, downloading TypeScript plugin directly..."
                $downloadSuccess = $false
                
                # Try primary URL
                $pluginUrl = "https://raw.githubusercontent.com/PeonPing/peon-ping/main/adapters/opencode/peon-ping.ts"
                try {
                    if (-not (Test-Path $pluginsDir)) {
                        New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
                    }
                    Invoke-WebRequest -Uri $pluginUrl -OutFile $peonPlugin -UseBasicParsing
                    Unblock-File -Path $peonPlugin -ErrorAction SilentlyContinue
                    Write-LogSuccess "Plugin downloaded to: $peonPlugin"
                    $downloadSuccess = $true
                } catch {
                    Write-LogWarn "Primary download failed: $($_.Exception.Message)"
                }
                
                # Fallback URL
                if (-not $downloadSuccess) {
                    $fallbackUrl = "https://raw.githubusercontent.com/PeonPing/peon-ping/main/plugins/opencode/peon-ping.ts"
                    try {
                        Invoke-WebRequest -Uri $fallbackUrl -OutFile $peonPlugin -UseBasicParsing
                        Unblock-File -Path $peonPlugin -ErrorAction SilentlyContinue
                        Write-LogSuccess "Plugin downloaded from fallback URL"
                        $downloadSuccess = $true
                    } catch {
                        Write-LogError "Fallback download also failed"
                    }
                }
                
                if (-not $downloadSuccess) {
                    Write-LogError "Failed to download PeonPing plugin"
                    return
                }
            }
        } else {
            Write-Host "[DRY-RUN] Would run adapter or download plugin" -ForegroundColor Cyan
        }
    } else {
        Write-LogWarn "PeonPing adapter script not found"
        Write-LogInfo "Downloading TypeScript plugin directly..."

        $pluginUrl = "https://raw.githubusercontent.com/PeonPing/peon-ping/main/adapters/opencode/peon-ping.ts"

        if ($DryRun) {
            Write-Host "[DRY-RUN] Would download peon-ping.ts to: $peonPlugin" -ForegroundColor Cyan
            Write-Host "[DRY-RUN] Would create config at: $peonConfigFile" -ForegroundColor Cyan
            return
        }

        try {
            if (-not (Test-Path $pluginsDir)) {
                New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
            }

            Write-LogInfo "Downloading peon-ping.ts OpenCode plugin..."
            Invoke-WebRequest -Uri $pluginUrl -OutFile $peonPlugin -UseBasicParsing
            Unblock-File -Path $peonPlugin -ErrorAction SilentlyContinue
            Write-LogSuccess "Plugin downloaded to: $peonPlugin"
        } catch {
            Write-LogError "PeonPing plugin download failed: $($_.Exception.Message)"
            Write-Host ""
            Write-Host "Try installing manually:" -ForegroundColor Yellow
            Write-Host "  1. Download: https://raw.githubusercontent.com/PeonPing/peon-ping/main/adapters/opencode/peon-ping.ts" -ForegroundColor Yellow
            Write-Host "  2. Save to: $peonPlugin" -ForegroundColor Yellow
            Write-Host ""
            return
        }
    }

    # Create config if it doesn't exist
    if (-not (Test-Path $peonConfigDir)) {
        New-Item -ItemType Directory -Path $peonConfigDir -Force | Out-Null
    }

    if (-not (Test-Path $peonConfigFile)) {
        $peonConfig = @{
            default_pack = "peon"
            volume = 0.5
            enabled = $true
            categories = @{
                "session.start" = $true
                "session.end" = $true
                "task.acknowledge" = $true
                "task.complete" = $true
                "task.error" = $true
                "task.progress" = $true
                "input.required" = $true
                "resource.limit" = $true
                "user.spam" = $true
            }
            spam_threshold = 3
            spam_window_seconds = 10
            pack_rotation = @()
            debounce_ms = 500
        }
        $prevCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
            $peonConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $peonConfigFile -Encoding UTF8
        } finally {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = $prevCulture
        }
        Write-LogSuccess "Config created at: $peonConfigFile"
    } else {
        Write-LogInfo "Config already exists, preserved."
    }

    Write-LogSuccess "PeonPing OpenCode plugin installed successfully"
    Write-Host ""
    Write-Host "Plugin installed to:"
    Write-Host "  - Plugin: $peonPlugin"
    Write-Host "  - Config: $peonConfigFile"
    Write-Host "  - Packs:  $env:USERPROFILE\.openpeon\packs\"
    Write-Host ""
    Write-Host "Restart OpenCode to activate the plugin."
    Write-Host ""
}

################################################################################
# SETUP: Node.js
################################################################################

function Set-NodeJS {
    Write-Host ""
    Write-Host "=== Installing/Updating Node.js ===" -ForegroundColor White

    if (Test-CommandExists "node") {
        $nodeVersion = & node --version 2>$null
        Write-LogInfo "Node.js is already installed ($nodeVersion)"

        if (Read-YesNo "Install a newer version of Node.js?" $false) {
            Install-NodeJS
        }
    } else {
        Write-LogInfo "Node.js is not installed"
        Install-NodeJS
    }
}

function Install-NodeJS {
    Write-Host ""
    Write-Host "Node.js installation options:" -ForegroundColor Yellow
    Write-Host ""

    if (Test-CommandExists "nvm") {
        Write-LogInfo "nvm-windows is installed"
        Write-LogInfo "Installing Node.js v24 via nvm..."
        Invoke-WithDryRun "nvm install 24"
        Invoke-WithDryRun "nvm use 24"

        if (Test-CommandExists "node") {
            $nv = & node --version 2>$null
            Write-LogSuccess "Node.js $nv is now active"
        }
        return
    }

    Write-LogWarn "nvm-windows is not installed"
    Write-Host ""

    if (Test-CommandExists "winget") {
        Write-Host "  1. winget install OpenJS.NodeJS.LTS (recommended)"
    }
    if (Test-CommandExists "choco") {
        Write-Host "  2. choco install nodejs"
    }
    Write-Host "  3. Download from: https://nodejs.org/"
    Write-Host "  4. Install nvm-windows: https://github.com/coreybutler/nvm-windows/releases"
    Write-Host ""

    if (Test-CommandExists "winget") {
        if (Read-YesNo "Install Node.js via winget?" $true) {
            Write-LogInfo "Installing Node.js via winget..."
            Invoke-WithDryRun "winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements"
            Write-LogSuccess "Node.js installed via winget. Open a new terminal to use it."
            return
        }
    }

    if (Test-CommandExists "choco") {
        if (Read-YesNo "Install Node.js via chocolatey?" $true) {
            Write-LogInfo "Installing Node.js via chocolatey..."
            Invoke-WithDryRun "choco install nodejs -y"
            Write-LogSuccess "Node.js installed via chocolatey. Open a new terminal to use it."
            return
        }
    }

    Write-LogInfo "Please install Node.js manually from https://nodejs.org/"
    Write-LogInfo "Or install nvm-windows from https://github.com/coreybutler/nvm-windows/releases"
    Write-LogInfo "After installing, open a new terminal and run this script again"
}

################################################################################
# SETUP: OpenCode CLI
################################################################################

function Set-OpenCode {
    Write-Host ""
    Write-Host "=== Installing/Updating OpenCode ===" -ForegroundColor White

    if (-not (Test-CommandExists "npm")) {
        Write-LogError "npm is not available. Cannot install opencode-ai."
        Write-LogInfo "Please install Node.js first via nvm-windows: https://github.com/coreybutler/nvm-windows/releases"
        return
    }

    if (Test-CommandExists "opencode") {
        $currentVersion = & opencode --version 2>$null
        if ([string]::IsNullOrWhiteSpace($currentVersion)) { $currentVersion = "unknown" }

        Write-LogInfo "opencode-ai is already installed (v$currentVersion)"

        try {
            $latestVersion = (Invoke-Expression "npm view opencode-ai version" 2>$null).Trim()
        } catch {
            $latestVersion = "unknown"
        }

        Write-LogInfo "Latest version: v$latestVersion"

        if ($currentVersion -ne $latestVersion -and $latestVersion -ne "unknown") {
            Write-Host ""
            Write-LogWarn "An update is available for opencode-ai!"

            if (Read-YesNo "Would you like to update to the latest version?" $true) {
                Write-LogInfo "Updating opencode-ai..."
                if (Invoke-WithDryRun "npm install -g opencode-ai@latest") {
                    $newVersion = & opencode --version 2>$null
                    Write-LogSuccess "opencode-ai updated successfully to $newVersion"
                } else {
                    Write-LogError "opencode-ai update failed"
                }
            }
        } else {
            Write-LogSuccess "opencode-ai is already up to date"

            if (Read-YesNo "Reinstall opencode-ai anyway?" $false) {
                Write-LogInfo "Reinstalling opencode-ai..."
                Invoke-WithDryRun "npm install -g opencode-ai"
                Write-LogSuccess "opencode-ai reinstalled successfully"
            }
        }
    } else {
        Write-LogInfo "opencode-ai is not installed"

        if (Read-YesNo "Install opencode-ai now?" $true) {
            Write-LogInfo "Installing opencode-ai..."
            if (Invoke-WithDryRun "npm install -g opencode-ai") {
                Write-LogSuccess "opencode-ai installed successfully"
            } else {
                Write-LogError "opencode-ai installation failed"
            }
        } else {
            Write-LogWarn "Skipping opencode-ai installation"
        }
    }
}

################################################################################
# SETUP: Mermaid CLI
################################################################################

function Set-MermaidCLI {
    Write-Host ""
    Write-Host "=== Checking Mermaid CLI ===" -ForegroundColor White

    if (Test-CommandExists "mmdc") {
        $installedVersion = ((& mmdc --version 2>$null) -split '\n' | Select-Object -First 1) -replace '.*?(\d+\.\d+\.\d+).*', '$1'
        if ([string]::IsNullOrWhiteSpace($installedVersion)) { $installedVersion = "unknown" }
        Write-LogInfo "Mermaid CLI is installed (v$installedVersion)"

        $latestVersion = (Invoke-Expression "npm view @mermaid-js/mermaid-cli version" 2>$null).Trim()
        if (-not [string]::IsNullOrWhiteSpace($latestVersion)) {
            Write-LogInfo "Latest version: v$latestVersion"

            if ($installedVersion -ne $latestVersion) {
                Write-LogWarn "A newer version of Mermaid CLI is available!"
                if (Read-YesNo "Update Mermaid CLI to v$latestVersion?" $true) {
                    Invoke-WithDryRun "npm install -g @mermaid-js/mermaid-cli@latest"
                    Write-LogSuccess "Mermaid CLI updated successfully"
                }
            } else {
                Write-LogSuccess "Mermaid CLI is up to date"
            }
        }
    } else {
        Write-LogInfo "Mermaid CLI is not installed"
        Write-Host ""
        Write-Host "  Mermaid CLI is required for diagram generation skills." -ForegroundColor Yellow
        Write-Host "  Alternatively, use npx for zero-install: npx @mermaid-js/mermaid-cli" -ForegroundColor Yellow
        Write-Host ""

        if (Read-YesNo "Install Mermaid CLI?" $true) {
            Invoke-WithDryRun "npm install -g @mermaid-js/mermaid-cli"

            if (Test-CommandExists "mmdc") {
                Write-LogSuccess "Mermaid CLI installed successfully"
            } else {
                Write-LogError "Mermaid CLI installation failed"
                Write-LogInfo "You can use npx as fallback: npx @mermaid-js/mermaid-cli"
            }
        } else {
            Write-LogInfo "Skipping Mermaid CLI installation (npx fallback available)"
        }
    }
}

################################################################################
# UPDATE: OpenCode CLI only
################################################################################

function Update-OpenCodeCLI {
    Write-Host ""
    Write-Host "=== Updating OpenCode CLI ===" -ForegroundColor White
    Write-Host ""

    if (-not (Test-CommandExists "npm")) {
        Write-LogError "npm is not available. Cannot update opencode-ai."
        return
    }

    if (-not (Test-CommandExists "opencode")) {
        Write-LogWarn "opencode-ai is not installed."

        if (Read-YesNo "Would you like to install opencode-ai now?" $true) {
            Write-LogInfo "Installing opencode-ai..."
            if (Invoke-WithDryRun "npm install -g opencode-ai") {
                Write-LogSuccess "opencode-ai installed successfully"
            }
        }
        return
    }

    $currentVersion = & opencode --version 2>$null
    if ([string]::IsNullOrWhiteSpace($currentVersion)) { $currentVersion = "unknown" }
    Write-LogInfo "Current version: v$currentVersion"

    Write-LogInfo "Checking for updates..."
    try {
        $latestVersion = (Invoke-Expression "npm view opencode-ai version" 2>$null).Trim()
    } catch {
        $latestVersion = "unknown"
    }

    if ($latestVersion -eq "unknown") {
        Write-LogError "Could not fetch latest version from npm registry"
        return
    }

    Write-LogInfo "Latest version: v$latestVersion"

    if ($currentVersion -eq $latestVersion) {
        Write-LogSuccess "opencode-ai is already up to date!"

        if (Read-YesNo "Force reinstall anyway?" $false) {
            Write-LogInfo "Reinstalling opencode-ai..."
            Invoke-WithDryRun "npm install -g opencode-ai@$latestVersion"
            Write-LogSuccess "opencode-ai reinstalled successfully"
        }
        return
    }

    Write-Host ""
    Write-LogInfo "Update available: v$currentVersion -> v$latestVersion"

    if (Read-YesNo "Update opencode-ai to v$latestVersion?" $true) {
        Write-LogInfo "Updating opencode-ai..."
        if (Invoke-WithDryRun "npm install -g opencode-ai@latest") {
            $newVersion = & opencode --version 2>$null
            Write-LogSuccess "opencode-ai updated successfully to v$newVersion"
        } else {
            Write-LogError "Update failed"
        }
    }
}

################################################################################
# SETUP: Configuration Deployment
################################################################################

function Set-Configuration {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "                  Configuration Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""

    if (-not $DryRun) {
        if (-not (Test-Path $ConfigDir)) {
            New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        }
    }
    Write-LogInfo "Config directory: $ConfigDir"

    $agentsSrc = Join-Path $ScriptDir ".AGENTS.md"
    $agentsDest = Join-Path $ConfigDir "AGENTS.md"

    if (Test-Path $agentsSrc) {
        if (Test-Path $agentsDest) {
            Write-LogWarn "AGENTS.md already exists at $agentsDest"
            if (Read-YesNo "Do you want to overwrite it?" $false) {
                New-FileBackup $agentsDest
                if (-not $DryRun) { Copy-Item $agentsSrc $agentsDest -Force }
                Write-LogSuccess "AGENTS.md copied successfully (renamed from .AGENTS.md)"
            }
        } else {
            if (-not $DryRun) { Copy-Item $agentsSrc $agentsDest -Force }
            Write-LogSuccess "AGENTS.md copied successfully (renamed from .AGENTS.md)"
        }
    } else {
        Write-LogWarn ".AGENTS.md not found in $ScriptDir"
    }

    if (Test-Path $ConfigFile) {
        Write-Host ""
        Write-LogWarn "config.json already exists at $ConfigFile"

        if (-not (Read-YesNo "Do you want to overwrite it?" $false)) {
            Write-LogInfo "Skipping config.json copy. Existing configuration preserved."
            $script:SkipConfigCopy = $true
            Deploy-Skills
            return
        }

        New-FileBackup $ConfigFile
    } else {
        $msg = "Copy config.json to $($ConfigDir)?"
        if (-not (Read-YesNo $msg $true)) {
            Write-LogInfo "Skipping config.json copy"
            $script:SkipConfigCopy = $true
            Deploy-Skills
            return
        }
    }

    if (-not $script:SkipConfigCopy) {
        $configSrc = Join-Path $ScriptDir "config.json"
        if (Test-Path $configSrc) {
            if (-not $DryRun) { Copy-Item $configSrc $ConfigFile -Force }
            Write-LogSuccess "config.json copied successfully"

            Write-Host ""
            Write-Host "Configured 5 agents:" -ForegroundColor Green
            Write-Host "    - build (default) - Full-featured coding agent"
            Write-Host "    - plan - Planning agent (read-only)"
            Write-Host "    - explore - Codebase exploration and analysis"
            Write-Host "    - image-analyzer - Image/screenshot analysis"
            Write-Host "    - diagram-creator - Diagram creation"
            Write-Host ""
            Write-Host "Configured 5 MCP servers:" -ForegroundColor Green
            Write-Host "    Local (auto-start): atlassian, zai-mcp-server"
            Write-Host "    Remote (needs key): web-reader, web-search-prime, zread"
            Write-Host ""
        } else {
            Write-LogError "config.json not found in $ScriptDir"
        }
    }

    Deploy-Skills
}

function Deploy-Skills {
    Write-Host ""
    Write-LogInfo "Setting up skills directory..."

    $skillsSrc = Join-Path $ScriptDir "skills"

    if (-not $DryRun) {
        if (-not (Test-Path $SkillsDir)) {
            New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
        }
    }
    Write-LogInfo "Skills directory: $SkillsDir"

    if (Test-Path $skillsSrc) {
        $existingSkills = @(Get-ChildItem $SkillsDir -ErrorAction SilentlyContinue)
        if ($existingSkills.Count -gt 0) {
            Write-LogWarn "Skills directory already contains files"

            if (Read-YesNo "Do you want to overwrite existing skills?" $false) {
                $skillsBackup = Join-Path $BackupDir "skills-backup"
                if (-not $DryRun) {
                    if (-not (Test-Path $BackupDir)) {
                        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
                    }
                    Copy-Item $SkillsDir $skillsBackup -Recurse -Force
                    Write-LogInfo "Backed up existing skills to $skillsBackup"
                }
            } else {
                Write-LogInfo "Skipping skills deployment. Existing skills preserved."
                return
            }
        }

        if (-not $DryRun) {
            # Copy all skills except _archived
            Get-ChildItem -Path $skillsSrc -Directory | Where-Object { $_.Name -ne "_archived" } | ForEach-Object {
                Copy-Item $_.FullName $SkillsDir -Recurse -Force
            }
            Get-ChildItem -Path $skillsSrc -File | ForEach-Object {
                Copy-Item $_.FullName $SkillsDir -Force
            }
        }
        Write-LogSuccess "Skills copied successfully to $SkillsDir"

        $skillCount = @(Get-ChildItem $SkillsDir -Directory -ErrorAction SilentlyContinue).Count
        Write-Host ""
        Write-Host "Deployed $skillCount skills to $SkillsDir" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Skill Categories:" -ForegroundColor Cyan
        Write-Host "    Framework (8):"
        Write-Host "      - test-generator-framework, linting-workflow"
        Write-Host "      - pr-creation-workflow, jira-git-integration"
        Write-Host "      - error-resolver-workflow, tdd-workflow"
        Write-Host "      - docx-creation, coverage-framework"
        Write-Host "    Language-Specific (4):"
        Write-Host "      - python-pytest-creator, python-ruff-linter"
        Write-Host "      - javascript-eslint-linter, changelog-python-cliff"
        Write-Host "    Framework-Specific (5):"
        Write-Host "      - nextjs-pr-workflow, nextjs-unit-test-creator"
        Write-Host "      - nextjs-standard-setup, nextjs-image-usage"
         Write-Host "      - typescript-dry-principle"
         Write-Host "    OpenCode Meta (3):"
         Write-Host "      - opencode-agent-creation, opencode-skill-creation"
         Write-Host "      - opencode-skills-maintainer"
         Write-Host "    OpenTofu (7):"
         Write-Host "      - opentofu-aws-explorer, opentofu-keycloak-explorer"
        Write-Host "      - opentofu-kubernetes-explorer, opentofu-neon-explorer"
        Write-Host "      - opentofu-provider-setup, opentofu-provisioning-workflow"
        Write-Host "      - opentofu-ecr-provision"
        Write-Host "    Git/Workflow (6):"
        Write-Host "      - ascii-diagram-creator, git-pr-creator"
        Write-Host "      - git-issue-labeler, git-issue-plan-workflow"
        Write-Host "      - git-issue-updater, git-semantic-commits"
        Write-Host "    Documentation (2):"
        Write-Host "      - coverage-readme-workflow, docstring-generator"
        Write-Host "    JIRA (5):"
        Write-Host "      - jira-ticket-oauth-workflow, jira-ticket-pat-workflow"
        Write-Host "      - jira-ticket-plan-workflow, jira-status-updater"
        Write-Host "      - jira-git-integration"
        Write-Host "    Code Quality (7):"
        Write-Host "      - solid-principles, clean-code, clean-architecture"
        Write-Host "      - design-patterns, object-design, code-smells"
        Write-Host "      - complexity-management"
        Write-Host ""
        Write-Host "  Run 'opencode --list-skills' for detailed descriptions"
        Write-Host ""
        Write-Host "  Skill Categories:" -ForegroundColor Cyan
        Write-Host "    Framework (8):"
        Write-Host "      - test-generator-framework, linting-workflow"
        Write-Host "      - pr-creation-workflow, jira-git-integration"
        Write-Host "      - error-resolver-workflow, tdd-workflow"
        Write-Host "      - coverage-framework, docx-creation"
        Write-Host "    Language-Specific (4):"
        Write-Host "      - python-pytest-creator, python-ruff-linter"
        Write-Host "      - javascript-eslint-linter, changelog-python-cliff"
        Write-Host "    Framework-Specific (5):"
        Write-Host "      - nextjs-pr-workflow, nextjs-unit-test-creator"
        Write-Host "      - nextjs-standard-setup, nextjs-image-usage"
         Write-Host "      - typescript-dry-principle"
         Write-Host "    OpenCode Meta (3):"
         Write-Host "      - opencode-agent-creation, opencode-skill-creation"
         Write-Host "      - opencode-skills-maintainer"
         Write-Host "    OpenTofu (7):"
         Write-Host "      - opentofu-aws-explorer, opentofu-keycloak-explorer"
        Write-Host "      - opentofu-kubernetes-explorer, opentofu-neon-explorer"
        Write-Host "      - opentofu-provider-setup, opentofu-provisioning-workflow"
        Write-Host "      - opentofu-ecr-provision"
        Write-Host "    Git/Workflow (6):"
        Write-Host "      - ascii-diagram-creator, git-pr-creator"
        Write-Host "      - git-issue-labeler, git-issue-plan-workflow"
        Write-Host "      - git-issue-updater, git-semantic-commits"
        Write-Host "    Documentation (2):"
        Write-Host "      - coverage-readme-workflow, docstring-generator"
        Write-Host "    JIRA (5):"
        Write-Host "      - jira-ticket-oauth-workflow, jira-ticket-pat-workflow"
        Write-Host "      - jira-ticket-plan-workflow, jira-status-updater"
        Write-Host "      - jira-git-integration"
        Write-Host "    Code Quality (7):"
        Write-Host "      - solid-principles, clean-code, clean-architecture"
        Write-Host "      - design-patterns, object-design, code-smells"
        Write-Host "      - complexity-management"
        Write-Host ""
        Write-Host "  Run 'opencode --list-skills' for detailed descriptions"
        Write-Host ""
    } else {
        Write-LogWarn "skills/ folder not found in $ScriptDir"
    }

    Deploy-Agents
}

function Deploy-Agents {
    Write-Host ""
    Write-LogInfo "Setting up agents directory..."

    if (Test-Path $AgentsDestDir) {
        $existingAgents = @(Get-ChildItem $AgentsDestDir -Filter "*.md" -ErrorAction SilentlyContinue)
        if ($existingAgents.Count -gt 0) {
            Write-LogWarn "Agents directory already contains files"

            if (-not (Read-YesNo "Do you want to overwrite existing agents?" $false)) {
                Write-LogInfo "Skipping agents deployment. Existing agents preserved."
                return
            }

            $agentsBackup = Join-Path $BackupDir "agents-backup"
            if (-not $DryRun) {
                if (-not (Test-Path $BackupDir)) {
                    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
                }
                Copy-Item $AgentsDestDir $agentsBackup -Recurse -Force
                Write-LogInfo "Backed up existing agents to $agentsBackup"
            }
        }
    }

    if (-not $DryRun) {
        if (-not (Test-Path $AgentsDestDir)) {
            New-Item -ItemType Directory -Path $AgentsDestDir -Force | Out-Null
        }
    }
    Write-LogInfo "Agents directory: $AgentsDestDir"

    if (Test-Path $AgentsSrcDir) {
        $primaryCount = 0
        $subagentCount = 0

        # Copy primary agents (flat into agents/)
        $primaryDir = Join-Path $AgentsSrcDir "primary"
        if (Test-Path $primaryDir) {
            $primaryFiles = @(Get-ChildItem $primaryDir -Filter "*.md" -ErrorAction SilentlyContinue)
            foreach ($file in $primaryFiles) {
                if (-not $DryRun) {
                    Copy-Item $file.FullName (Join-Path $AgentsDestDir $file.Name) -Force
                }
                $primaryCount++
            }
        }

        # Copy subagents (flat into agents/)
        $subagentsDir = Join-Path $AgentsSrcDir "subagents"
        if (Test-Path $subagentsDir) {
            $subagentFiles = @(Get-ChildItem $subagentsDir -Filter "*.md" -ErrorAction SilentlyContinue)
            foreach ($file in $subagentFiles) {
                if (-not $DryRun) {
                    Copy-Item $file.FullName (Join-Path $AgentsDestDir $file.Name) -Force
                }
                $subagentCount++
            }
        } else {
            Write-LogWarn "agents/subagents/ directory not found in $ScriptDir"
        }

        $totalCount = $primaryCount + $subagentCount
        Write-LogSuccess "Agents copied successfully to $AgentsDestDir"

        Write-Host ""
        Write-Host "Deployed $totalCount agents:" -ForegroundColor Green
        Write-Host "    - $primaryCount primary agents"
        Write-Host "    - $subagentCount subagents"
        Write-Host ""
        Write-Host "  Run 'opencode --list-agents' for details"
        Write-Host ""
    } else {
        Write-LogWarn "agents/ folder not found in $ScriptDir"
    }
}

################################################################################
# SETUP: Environment Variables
################################################################################

function Set-ShellVariables {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "              Environment Variables Setup" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""

    if (-not (Test-Path $PROFILE)) {
        $profileDir = Split-Path $PROFILE -Parent
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        Write-LogInfo "Created PowerShell profile: $PROFILE"
    }

    Write-Host "PowerShell profile: $PROFILE"
    Write-Host ""

    if (-not [string]::IsNullOrWhiteSpace($ZaiApiKey)) {
        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($profileContent -match "ZAI_API_KEY") {
            Write-LogInfo "ZAI_API_KEY already exists in $PROFILE"
        } else {
            if (Read-YesNo "Add ZAI_API_KEY to your PowerShell profile for persistent access?" $true) {
                New-FileBackup $PROFILE
                if (-not $DryRun) {
                    Add-Content -Path $PROFILE -Value "`n# Z.AI API Key (added by opencode setup)"
                    Add-Content -Path $PROFILE -Value "`$env:ZAI_API_KEY = `"$ZaiApiKey`""
                }
                Write-LogSuccess "ZAI_API_KEY added to $PROFILE"
            } else {
                Write-LogInfo "Skipping profile update for ZAI_API_KEY"
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($JiraClientId)) {
        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($profileContent -match "JIRA_CLIENT_ID") {
            Write-LogInfo "JIRA OAuth2 credentials already exist in $PROFILE"

            if (Read-YesNo "Update existing JIRA tokens?" $false) {
                New-FileBackup $PROFILE
                if (-not $DryRun) {
                    $lines = Get-Content $PROFILE | Where-Object { $_ -notmatch "JIRA_" -and $_ -notmatch "JIRA OAuth2" }
                    Set-Content -Path $PROFILE -Value $lines

                    Add-Content -Path $PROFILE -Value "`n# JIRA OAuth2 Configuration (added by opencode setup)"
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_CLIENT_ID = `"$JiraClientId`""
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_CLIENT_SECRET = `"$JiraClientSecret`""
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_ACCESS_TOKEN = `"$JiraAccessToken`""
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_REFRESH_TOKEN = `"$JiraRefreshToken`""
                    if ($JiraCloudId) {
                        Add-Content -Path $PROFILE -Value "`$env:JIRA_CLOUD_ID = `"$JiraCloudId`""
                    }
                }
                Write-LogSuccess "JIRA OAuth2 tokens updated in $PROFILE"
            }
        } else {
            if (Read-YesNo "Add JIRA OAuth2 credentials to your PowerShell profile?" $true) {
                New-FileBackup $PROFILE
                if (-not $DryRun) {
                    Add-Content -Path $PROFILE -Value "`n# JIRA OAuth2 Configuration (added by opencode setup)"
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_CLIENT_ID = `"$JiraClientId`""
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_CLIENT_SECRET = `"$JiraClientSecret`""
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_ACCESS_TOKEN = `"$JiraAccessToken`""
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_REFRESH_TOKEN = `"$JiraRefreshToken`""
                    if ($JiraCloudId) {
                        Add-Content -Path $PROFILE -Value "`$env:JIRA_CLOUD_ID = `"$JiraCloudId`""
                    }
                }
                Write-LogSuccess "JIRA OAuth2 credentials added to $PROFILE"
            } else {
                Write-LogInfo "Skipping profile update for JIRA OAuth2"
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($JiraPat)) {
        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($profileContent -match "JIRA_PAT") {
            Write-LogInfo "JIRA PAT credentials already exist in $PROFILE"

            if (Read-YesNo "Update existing JIRA PAT?" $false) {
                New-FileBackup $PROFILE
                if (-not $DryRun) {
                    $lines = Get-Content $PROFILE | Where-Object { $_ -notmatch "JIRA_PAT" -and $_ -notmatch "JIRA_SITE" -and $_ -notmatch "JIRA PAT" }
                    Set-Content -Path $PROFILE -Value $lines

                    Add-Content -Path $PROFILE -Value "`n# JIRA PAT Configuration (added by opencode setup)"
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_PAT = `"$JiraPat`""
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_SITE = `"$JiraSite`""
                }
                Write-LogSuccess "JIRA PAT credentials updated in $PROFILE"
            }
        } else {
            if (Read-YesNo "Add JIRA PAT credentials to your PowerShell profile?" $true) {
                New-FileBackup $PROFILE
                if (-not $DryRun) {
                    Add-Content -Path $PROFILE -Value "`n# JIRA PAT Configuration (added by opencode setup)"
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_PAT = `"$JiraPat`""
                    Add-Content -Path $PROFILE -Value "`$env:JIRA_SITE = `"$JiraSite`""
                }
                Write-LogSuccess "JIRA PAT credentials added to $PROFILE"
            } else {
                Write-LogInfo "Skipping profile update for JIRA PAT"
            }
        }
    }
}

################################################################################
# AUTO-UPDATE FUNCTIONS
################################################################################

function Update-LastCheckTime {
    $timestamp = [int][double]::Parse((Get-Date -UFormat %s))
    if (-not $DryRun) {
        Set-Content -Path $LastUpdateCheck -Value $timestamp
    }
    Write-LogDebug "Updated last check time"
}

function Test-ShouldCheckForUpdate {
    if (-not (Test-Path $LastUpdateCheck)) {
        return $true
    }

    $lastCheck = [int](Get-Content $LastUpdateCheck -Raw -ErrorAction SilentlyContinue)
    if (-not $lastCheck) { return $true }

    $current = [int][double]::Parse((Get-Date -UFormat %s))
    $diff = $current - $lastCheck

    switch ($ScheduleUpdate) {
        "daily"   { return $diff -ge 86400 }
        "weekly"  { return $diff -ge 604800 }
        "monthly" { return $diff -ge 2592000 }
        "manual"  { return $true }
        default   { return $diff -ge 604800 }
    }
}

function Get-OpenCodeVersion {
    param([switch]$Latest)

    if ($Latest) {
        try {
            return (Invoke-Expression "npm view opencode-ai version" 2>$null).Trim()
        } catch {
            return "unknown"
        }
    }

    if (Test-CommandExists "opencode") {
        $v = & opencode --version 2>$null
        if ($v) { return $v.Trim() }
    }
    return "unknown"
}

function Invoke-AutoUpdate {
    if ($DisableAutoUpdate -and -not $EnableAutoUpdate) {
        Write-LogInfo "Auto-update is disabled"
        return
    }

    if (-not (Test-ShouldCheckForUpdate)) {
        Write-LogInfo "Skipping auto-update (scheduled time not reached)"
        return
    }

    Write-LogInfo "Checking for opencode-ai updates..."

    $current = Get-OpenCodeVersion
    $latest = Get-OpenCodeVersion -Latest

    if ($latest -eq "unknown") {
        Write-LogError "Could not fetch latest version from npm registry"
        return
    }

    Write-LogInfo "Current version: v$current"
    Write-LogInfo "Latest version: v$latest"

    if ($current -eq $latest) {
        Write-LogSuccess "opencode-ai is already up to date!"
        Update-LastCheckTime
        return
    }

    Write-LogInfo "Update available: v$current -> v$latest"

    if ($Yes -or (Read-YesNo "Update opencode-ai to v$latest?" $true)) {
        $backupDir = Join-Path $HOME ".opencode-update-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            if (Test-Path $ConfigFile) { Copy-Item $ConfigFile (Join-Path $backupDir "config.json") }
            $agentsDest = Join-Path $ConfigDir "AGENTS.md"
            if (Test-Path $agentsDest) { Copy-Item $agentsDest (Join-Path $backupDir "AGENTS.md") }
            if (Test-Path $SkillsDir) { Copy-Item $SkillsDir (Join-Path $backupDir "skills") -Recurse }
            Remove-OldBackups
        }

        Write-LogInfo "Auto-updating opencode-ai to v$latest..."
        Invoke-WithDryRun "npm install -g opencode-ai@$latest"

        $newVersion = Get-OpenCodeVersion
        if ($newVersion -eq $latest) {
            Write-LogSuccess "opencode-ai updated successfully to v$newVersion"
            Update-LastCheckTime
        } else {
            Write-LogError "Update failed. Current version: v$newVersion"
        }
    }
}

function Show-CheckUpdate {
    Write-LogInfo "Checking for opencode-ai updates..."

    if (-not (Test-CommandExists "opencode")) {
        Write-LogWarn "opencode-ai is not installed"
        return
    }

    $current = Get-OpenCodeVersion
    $latest = Get-OpenCodeVersion -Latest

    if ($latest -eq "unknown") {
        Write-LogError "Could not fetch latest version from npm registry"
        return
    }

    Write-LogInfo "Current version: v$current"
    Write-LogInfo "Latest version: v$latest"

    if ($current -eq $latest) {
        Write-LogSuccess "opencode-ai is already up to date!"
    } else {
        Write-LogInfo "Update available: v$current -> v$latest"
        Write-LogInfo "Run: .\setup.ps1 -EnableAutoUpdate -ScheduleUpdate daily"
    }

    Update-LastCheckTime
}

################################################################################
# SUMMARY
################################################################################

function Show-Summary {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "                      Setup Summary" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""

    Write-Host "Platform Detection:"
    Write-Host "  [OK] OS: Windows $($env:OS)"
    Write-Host "  [OK] PowerShell: $($PSVersionTable.PSVersion)"
    Write-Host "  [OK] Profile: $PROFILE"
    Write-Host ""

    if (Test-CommandExists "nvm") {
        Write-Host "  [OK] nvm-windows: Installed (nvm)"
    } else {
        Write-Host "  [ ] nvm-windows: Not detected (install from github.com/coreybutler/nvm-windows/releases)"
    }

    if (Test-CommandExists "node") {
        $nv = & node --version 2>$null
        Write-Host "  [OK] Node.js: $nv"
    } else {
        Write-Host "  [X] Node.js: Not installed"
    }

    if (Test-CommandExists "opencode") {
        $ov = & opencode --version 2>$null
        Write-Host "  [OK] opencode-ai: Installed v$ov"
    } else {
        Write-Host "  [X] opencode-ai: Not installed"
    }

    if (Test-Path $ConfigFile) {
        Write-Host "  [OK] config.json: Copied to $ConfigDir\" -ForegroundColor Green
    } else {
        Write-Host "  [X] config.json: Not copied"
    }

    if (Test-Path (Join-Path $ConfigDir "AGENTS.md")) {
        Write-Host "  [OK] AGENTS.md: Copied to $ConfigDir\" -ForegroundColor Green
    } else {
        Write-Host "  [X] AGENTS.md: Not copied"
    }

    $skillCount = @(Get-ChildItem $SkillsDir -Directory -ErrorAction SilentlyContinue).Count
    if ($skillCount -gt 0) {
        Write-Host "  [OK] skills: $skillCount skills deployed to $SkillsDir\" -ForegroundColor Green
    } else {
        Write-Host "  [X] skills: Not deployed"
    }

    Write-Host ""

    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent -match "ZAI_API_KEY") {
        Write-Host "  [OK] ZAI_API_KEY: Added to profile"
    } elseif (-not [string]::IsNullOrWhiteSpace($ZaiApiKey)) {
        Write-Host "  [ ] ZAI_API_KEY: Set in current session only"
    } else {
        Write-Host "  [X] ZAI_API_KEY: Not configured"
    }

    if (Test-CommandExists "gh") {
        $ghSummaryAuth = $null
        try {
            $ghSummaryAuth = & gh auth status 2>&1
        } catch {}
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] GitHub CLI: Installed and authenticated"
        } else {
            Write-Host "  [ ] GitHub CLI: Installed but not authenticated (run: gh auth login)"
        }
    } else {
        Write-Host "  [ ] GitHub CLI: Not installed (https://cli.github.com/)"
    }

    Write-Host ""
}

function Show-NextSteps {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "                      Setup Complete!" -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:"
    Write-Host "  1. Restart terminal or run: . $PROFILE"
    Write-Host "  2. Start LM Studio: http://127.0.0.1:1234/v1"
    Write-Host "  3. Verify installation: opencode --version"
    Write-Host ""
    Write-Host "Agents (5):"
    Write-Host "  - build (default) - Full-featured coding agent"
    Write-Host "  - plan - Planning agent (read-only)"
    Write-Host "  - explore - Fast codebase exploration and analysis"
    Write-Host "  - image-analyzer - Images/screenshots to code, OCR, error diagnosis"
    Write-Host "  - diagram-creator - Diagrams (architecture, flowcharts, UML)"
    Write-Host ""
    Write-Host "  Usage: opencode --agent <name> `"prompt`""
    Write-Host "         opencode `"prompt`" (uses build)"
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor White
     Write-Host "                     50 Skills Available" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host ""
     Write-Host "  Framework (7) • Language-Specific (5) • Framework-Specific (7)"
     Write-Host "  OpenCode Meta (3) • OpenTofu (7) • Git/Workflow (7)"
    Write-Host "  Documentation (2) • JIRA (4) • Code Quality (7)"
    Write-Host ""
    Write-Host "  Run 'opencode --list-skills' for detailed descriptions"
    Write-Host "  Run 'opencode --skill <name> `"prompt`"' to invoke a skill"
    Write-Host ""
     Write-Host "  Framework (9) | Language-Specific (5) | Framework-Specific (7)"
     Write-Host "  OpenCode Meta (3) | OpenTofu (7) | Git/Workflow (8)"
    Write-Host "  Documentation (2) | JIRA (4) | Code Quality (7)"
    Write-Host ""
    Write-Host "  Run 'opencode --list-skills' for detailed descriptions"
    Write-Host "  Run 'opencode --skill <name> `"prompt`"' to invoke a skill"
    Write-Host ""
    Write-Host "MCP Servers (5):"
    Write-Host "  Local (auto-start): atlassian, zai-mcp-server"
    Write-Host "  Remote (needs key): web-reader, web-search-prime, zread"
    Write-Host ""
    Write-Host "  Auth: opencode mcp auth atlassian / opencode mcp auth github"
    Write-Host ""
    Write-Host "Documentation:"
    Write-Host "  - Update CLI: .\setup.ps1 -Update"
    Write-Host "  - Config file: $ConfigFile"
    Write-Host "  - Log file: $LogFile"
    Write-Host "  - Full docs: https://opencode.ai"
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""
}

################################################################################
# MAIN
################################################################################

function Main {
    if ($Help) {
        Show-Help
        return
    }

    if ($Update) {
        Write-Host "=== OpenCode CLI Updater v$ScriptVersion ===" -ForegroundColor White
        Write-Host ""
        Initialize-Logging
        Update-OpenCodeCLI
        Write-Host ""
        Write-Host "Update complete!"
        return
    }

    if ($CheckUpdate) {
        Initialize-Logging
        Show-CheckUpdate
        return
    }

    if ($SkillsOnly) {
        Write-Host "=== OpenCode Skills Deployment v$ScriptVersion ===" -ForegroundColor White
        Write-Host ""
        Initialize-Logging

        if (-not (Test-CommandExists "opencode")) {
            Write-LogError "OpenCode CLI is not installed globally"
            Write-LogInfo "Please install OpenCode first: npm install -g opencode-ai"
            exit 1
        }
        Write-LogSuccess "OpenCode is installed ($(Get-OpenCodeVersion))"

        if (-not (Test-Dependencies)) {
            Write-LogError "Dependency check failed."
            exit 1
        }

        Set-Configuration
        Show-Summary
        Write-Host ""
        Write-Host "Skills deployment complete!"
        return
    }

    Write-Host "=== OpenCode Configuration Setup v$ScriptVersion ===" -ForegroundColor White
    Write-Host ""
    Initialize-Logging

    if (-not $Quick) {
        if (-not (Test-Dependencies)) {
            Write-LogError "Dependency check failed. Please install missing dependencies."
            exit 1
        }

        if (-not (Test-Network)) {
            Write-LogWarn "Network connectivity issues detected. Some features may not work."
            if (-not (Read-YesNo "Continue anyway?" $false)) {
                exit 1
            }
        }

        if ($EnableAutoUpdate) {
            Write-LogInfo "Auto-update is enabled (schedule: $ScheduleUpdate)"
            Invoke-AutoUpdate
        }
    }

    if (-not $Quick -and -not $Yes) {
        Write-Host "=====================================================================" -ForegroundColor White
        Write-Host "                      Setup Mode Selection" -ForegroundColor White
        Write-Host "=====================================================================" -ForegroundColor White
        Write-Host ""
        Write-Host "  1) Quick setup (config + skills only)"
        Write-Host "  2) Skills-only setup"
        Write-Host "  3) Full setup (API keys, Node.js, OpenCode)"
        Write-Host "  4) Update OpenCode CLI only"
        Write-Host "  5) Configure JIRA OAuth2"
        Write-Host "  6) Configure JIRA PAT (simpler, no refresh needed)"
        Write-Host "  7) Install PeonPing (sound notifications)"
        Write-Host ""

        $option = Read-Prompt "Select option" "2"

        switch ($option) {
            "1" {
                Write-Host ""
                Write-LogInfo "Quick Setup: Copy config.json and skills only"
                $script:Quick = $true
            }
            "2" {
                Write-Host ""
                Write-LogInfo "Skills-Only Setup: Copy skills folder only"

                if (-not (Test-CommandExists "opencode")) {
                    Write-LogError "OpenCode CLI is not installed globally"
                    Write-LogInfo "Please install OpenCode first: npm install -g opencode-ai"
                    exit 1
                }

                Set-Configuration
                Show-Summary
                Write-Host ""
                Write-Host "Skills deployment complete!"
                return
            }
            "3" {
                Write-LogInfo "Running full setup..."
            }
            "4" {
                Write-Host ""
                Write-LogInfo "Update OpenCode CLI only"
                Update-OpenCodeCLI
                Write-Host ""
                Write-Host "Update complete!"
                return
            }
            "5" {
                Write-Host ""
                Write-LogInfo "JIRA OAuth2 Configuration"
                Set-JiraOAuth
                Set-ShellVariables
                Show-Summary
                Write-Host ""
                Write-Host "JIRA OAuth2 configuration complete!"
                return
            }
            "6" {
                Write-Host ""
                Write-LogInfo "JIRA PAT Configuration"
                Set-JiraPAT
                Set-ShellVariables
                Show-Summary
                Write-Host ""
                Write-Host "JIRA PAT configuration complete!"
                return
            }
            "7" {
                Write-Host ""
                Write-LogInfo "PeonPing Sound Notifications"
                Set-PeonPing
                Write-Host ""
                Write-Host "PeonPing setup complete!"
                return
            }
            default {
                Write-LogWarn "Invalid option. Running full setup..."
            }
        }
        Write-Host ""
    }

    if (-not $Quick) {
        Set-GitHubCLI
        Set-ZaiApiKey
        Set-NodeJS
        Set-OpenCode
        Set-MermaidCLI
    } else {
        Write-LogInfo "Running quick setup: config.json and skills deployment only"
    }

    Set-Configuration
    Set-ShellVariables

    Remove-OldBackups

    Show-Summary
    Show-NextSteps

    Write-Log "INFO" "=== OpenCode Setup Completed at $(Get-Date) ==="

    if (-not $Yes) {
        Write-Host "Press Enter to exit..."
        Read-Host
    }
}

Main
