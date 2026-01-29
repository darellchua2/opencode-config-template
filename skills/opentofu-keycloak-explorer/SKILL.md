---
name: opentofu-keycloak-explorer
description: Explore and manage Keycloak identity and access management resources using OpenTofu/Terraform
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: identity-management
---

## What I do
- Create and configure Keycloak realms
- Setup OAuth2/OpenID Connect clients
- Manage users, groups, and roles
- Configure authentication flows and mappers
- Follow Keycloak provider documentation patterns

## When to use me
Use when:
- Automating Keycloak infrastructure as code
- Managing identity providers (GitHub, Google, Azure AD, etc.)
- Setting up authentication and authorization flows
- Managing users, groups, and roles programmatically
- Configuring client applications with OAuth2/OpenID Connect

## Prerequisites
- OpenTofu CLI installed: https://opentofu.org/docs/intro/install/
- Running Keycloak instance (managed or self-hosted)
- Keycloak admin credentials with privileges
- Basic IAM knowledge (OAuth2, OpenID Connect, SAML)

## References
- Terraform Registry: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs
- Latest Provider Version: keycloak/keycloak ~> 5.0.0
- Provider Source: https://github.com/mrparkers/terraform-provider-keycloak
- Keycloak Documentation: https://www.keycloak.org/documentation.html
- OAuth2 Best Practices: https://datatracker.ietf.org/doc/html/rfc6749

## Steps

### Step 1: Install and Initialize
```bash
tofu version
mkdir keycloak-terraform && cd keycloak-terraform
tofu init
```

### Step 2: Configure Provider
Create `versions.tf` and `provider.tf`:
```hcl
terraform {
  required_providers {
    keycloak = { source = "keycloak/keycloak", version = "~> 5.0.0" }
  }
  backend "s3" { bucket = "keycloak-state", key = "terraform.tfstate", region = "us-east-1" }
}

provider "keycloak" {
  # Method 1: Direct URL (local development)
  url       = "http://localhost:8080"
  client_id = "admin-cli"
  username  = "admin"
  password  = "admin"

  # Method 2: Managed Keycloak (e.g., Red Hat SSO)
  # url       = "https://sso.example.com/auth"
  # client_id = "terraform"

  # Method 3: Client Credentials (recommended for production)
  # url       = "https://keycloak.example.com"
  # client_id = "terraform"
  # Read from environment variable: KEYCLOAK_CLIENT_SECRET
}
```

### Step 3: Configure Environment Variables
```bash
export KEYCLOAK_CLIENT_SECRET="your-client-secret"
cat > terraform.tfvars <<EOF
keycloak_admin_username = "admin"
keycloak_admin_password = "secure-password"
EOF
```

### Step 4: Create Keycloak Realm
**Key pattern**:
```hcl
resource "keycloak_realm" "example" {
  realm        = "example"
  enabled      = true
  display_name = "Example Realm"
  ssl_required = "external"

  registration_allowed        = true
  reset_password_allowed      = true
  edit_username_allowed      = true
  brute_force_protected     = true

  internationalization_enabled = true
  supported_locales         = ["en", "es", "fr"]
  default_locale            = "en"

  smtp_server {
    host      = "smtp.gmail.com"
    port      = 587
    from      = "noreply@example.com"
    starttls  = true
    auth { username = var.smtp_username, password = var.smtp_password }
  }
}
```

### Step 5: Create Identity Providers
**Key pattern**:
```hcl
# GitHub OAuth2
resource "keycloak_identity_provider" "github" {
  realm   = keycloak_realm.example.realm
  alias   = "github"
  provider_id = "github"
  enabled = true

  config {
    client_id     = var.github_client_id
    client_secret = var.github_client_secret
    use_jwks_url  = true
  }
}

# Google OAuth2
resource "keycloak_identity_provider" "google" {
  realm   = keycloak_realm.example.realm
  alias   = "google"
  provider_id = "google"
  enabled = true

  config {
    client_id     = var.google_client_id
    client_secret = var.google_client_secret
    hosted_domain = "example.com"
    use_jwks_url  = true
  }
}

# Azure AD
resource "keycloak_identity_provider" "azure" {
  realm   = keycloak_realm.example.realm
  alias   = "azure"
  provider_id = "azure"
  enabled = true

  config {
    client_id = var.azure_client_id
    client_secret = var.azure_client_secret
    tenant_id = var.azure_tenant_id
  }
}
```

### Step 6: Create Authentication Flows
**Key pattern**:
```hcl
resource "keycloak_authentication_flow" "browser" {
  realm_id    = keycloak_realm.example.id
  alias       = "browser"
  description = "Browser based authentication"
  provider_id = "basic-flow"
  top_level   = true
}

resource "keycloak_authentication_flow" "github" {
  realm_id    = keycloak_realm.example.id
  alias       = "github"
  description = "GitHub authentication"
  provider_id = "basic-flow"
  top_level   = true
}
```

### Step 7: Create Users and Groups
**Key pattern**:
```hcl
resource "keycloak_group" "developers" {
  realm_id = keycloak_realm.example.id
  name     = "developers"
  attributes = { department = "engineering", team = "platform" }
}

resource "keycloak_role" "developer" {
  realm_id    = keycloak_realm.example.id
  name        = "developer"
  description = "Developer role with API access"
}

resource "keycloak_user" "admin_user" {
  realm_id = keycloak_realm.example.id
  username = "johndoe"
  enabled  = true
  email    = "john.doe@example.com"

  initial_password { value = var.user_password, temporary = false }
  groups = [keycloak_group.developers.id]
  realm_roles = [keycloak_role.developer.name]
}
```

### Step 8: Create Client Applications
**Key pattern**:
```hcl
# Web application (confidential client)
resource "keycloak_openid_client" "web_app" {
  realm_id               = keycloak_realm.example.id
  client_id             = "my-web-app"
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  service_accounts_enabled = true

  valid_redirect_uris = ["https://app.example.com/callback"]
  web_origins        = ["https://app.example.com"]

  protocol_mappers {
    name                 = "username"
    protocol             = "openid-connect"
    protocol_mapper      = "user-attribute-mapper"
    user_attribute       = "username"
    claim_name           = "preferred_username"
    add_to_id_token     = true
    add_to_access_token = true
  }
}

# SPA application (public client)
resource "keycloak_openid_client" "spa_app" {
  realm_id               = keycloak_realm.example.id
  client_id             = "my-spa-app"
  access_type           = "PUBLIC"
  standard_flow_enabled = true

  valid_redirect_uris = ["https://spa.example.com/callback"]
  pkce_code_challenge_method = "S256"
}
```

### Step 9: Define Variables
**Key pattern**:
```hcl
variable "keycloak_admin_username" { description = "Keycloak admin username", type = string, sensitive = true }
variable "keycloak_admin_password" { description = "Keycloak admin password", type = string, sensitive = true }
variable "github_client_id" { description = "GitHub OAuth2 client ID", type = string, sensitive = true }
variable "github_client_secret" { description = "GitHub OAuth2 client secret", type = string, sensitive = true }
variable "google_client_id" { description = "Google OAuth2 client ID", type = string, sensitive = true }
variable "google_client_secret" { description = "Google OAuth2 client secret", type = string, sensitive = true }
```

### Step 10: Initialize and Apply
```bash
tofu init
tofu plan -out=tfplan
tofu apply tfplan
```

## Best Practices

### Security
- Use service accounts for production instead of admin credentials
- Grant minimal permissions to service accounts
- Store sensitive data in environment variables or secret managers
- Always use HTTPS in production environments
- Set appropriate session timeouts

### Organization
- Split resources into logical files (realm.tf, clients.tf, users.tf)
- Use modules for reusable patterns
- Use remote backend with encryption and locking
- Use workspaces for dev/staging/prod

### Authentication Flows
- Customize flows based on requirements
- Enable MFA for sensitive applications
- Configure identity providers (GitHub, Google, Azure AD)
- Set strong password policies

### Client Configuration
- Use PKCE for SPAs (recommended security practice)
- Only request necessary scopes
- Only allow trusted redirect URIs
- Implement proper logout flows (frontchannel and backchannel)

## Common Issues

### Provider Connection Failed
**Solution**: Verify Keycloak is running (`curl http://localhost:8080/health/ready`), check provider configuration (ensure URL includes /auth/ for Keycloak < 18, omit for >= 18), and test credentials manually.

### Authentication Flow Not Found
**Solution**: Ensure authentication flow is created before assigning. Check flow existence: `tofu state list | grep authentication_flow`, verify flow alias matches exactly.

### Client Registration Fails
**Solution**: Check if client already exists and import with `tofu import keycloak_openid_client.web_app my-realm/my-web-app`, or use import block in configuration.

### Identity Provider Configuration
**Solution**: Verify OAuth2 credentials from provider console, check client ID and secret, ensure redirect URI matches in Keycloak. Reference provider documentation (GitHub, Google, Azure).

### User Creation with Password
**Solution**: Ensure initial_password block is correctly configured with value and temporary fields.

### Protocol Mapper Not Working
**Solution**: Check mapper configuration, verify claim_name and user_attribute match, ensure add_to_id_token or add_to_access_token is true.
