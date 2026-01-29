---
name: opentofu-neon-explorer
description: Explore and manage Neon Postgres serverless database resources using OpenTofu/Terraform
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: database-management
---

## What I do

I guide you through managing Neon serverless Postgres database resources using Neon Terraform provider.

- **Project Management**: Create and manage Neon Postgres projects
- **Database Operations**: Create databases, branches, and endpoints
- **Branching Strategy**: Implement Neon's branch-based database workflow
- **Connection Management**: Configure database connections and credentials

## When to use me

Use when:
- Automating Neon Postgres infrastructure as code
- Creating serverless Postgres databases for applications
- Implementing database branching for development workflows
- Managing database projects, branches, and endpoints programmatically
- Configuring Neon databases for production workloads

**Note**: OpenTofu and Terraform are used interchangeably. OpenTofu is an open-source implementation of Terraform and maintains full compatibility with Terraform providers.

## Prerequisites

- OpenTofu CLI installed: https://opentofu.org/docs/intro/install/
- Neon account with API access
- Neon API key for authentication
- Basic Postgres knowledge (databases, branches, connections)

## Steps

### Step 1: Configure Provider

Create `versions.tf`:

```hcl
terraform {
  required_providers {
    neon = {
      source  = "kislerdm/neon"
      version = "~> 0.13.0"
    }
  }
  required_version = ">= 1.14"
}
```

Create `provider.tf`:

```hcl
provider "neon" {
  # Method 1: API key from environment variable (recommended)
  # Set: export NEON_API_KEY="your-api-key"

  # Method 2: API key in provider configuration
  api_key = var.neon_api_key
}
```

**Important**: Avoid `tofu init -upgrade` in CI pipelines. Use `tofu init` instead.

### Step 2: Create Neon Project

```hcl
resource "neon_project" "main" {
  name = var.project_name

  tags = {
    Environment = var.environment
    ManagedBy  = "Terraform"
  }
}
```

**Project features**:
- Autoscaling storage (automatic)
- Serverless compute (automatic)
- Region selection (automatic)
- High availability (based on plan)

### Step 3: Create Database Branch

```hcl
# Primary branch (default, created with project)
data "neon_branch" "primary" {
  project_id = neon_project.main.id
  name       = "primary"
}

# Development branch
resource "neon_branch" "dev" {
  project_id = neon_project.main.id
  name       = "dev"
  parent_id  = data.neon_branch.primary.id
}

# Feature branch
resource "neon_branch" "feature" {
  project_id = neon_project.main.id
  name       = "feature-auth"
  parent_id  = data.neon_branch.primary.id
}
```

**Branching patterns**:
- Primary: Production database
- Dev: Development/testing
- Feature: Isolated feature development

### Step 4: Create Databases

```hcl
resource "neon_database" "primary" {
  project_id = neon_project.main.id
  branch_id  = data.neon_branch.primary.id
  name       = var.db_name
  collation   = "en_US.UTF-8"
}

resource "neon_database" "dev" {
  project_id = neon_project.main.id
  branch_id  = neon_branch.dev.id
  name       = "appdb"
}
```

### Step 5: Create Endpoints

```hcl
# Primary read-write endpoint
resource "neon_endpoint" "primary" {
  project_id   = neon_project.main.id
  branch_id    = data.neon_branch.primary.id
  name         = "primary"
  endpoint_type = "read_write"
}

# Read-only endpoint (for analytics)
resource "neon_endpoint" "read_only" {
  project_id   = neon_project.main.id
  branch_id    = data.neon_branch.primary.id
  name         = "readonly"
  endpoint_type = "read_only"
}
```

**Endpoint types**:
- `read_write`: Primary endpoint (default)
- `read_only`: Analytics and reporting
- `autoscaling`: Automatic scaling based on workload

### Step 6: Create Roles and Grants

```hcl
resource "neon_role" "app_user" {
  project_id = neon_project.main.id
  name       = "app_user"
}

resource "neon_grant" "app_access" {
  project_id   = neon_project.main.id
  branch_id    = data.neon_branch.primary.id
  database_id  = neon_database.primary.id
  role_name    = neon_role.app_user.name
}
```

**Role patterns**:
- Application role: Database access
- Read-only role: Analytics access
- Admin role: Full access (use carefully)

### Step 7: Define Variables and Apply

Create `variables.tf`:

```hcl
variable "neon_api_key" {
  description = "Neon API key"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Name of Neon project"
  type        = string
}

variable "db_name" {
  description = "Name of primary database"
  type        = string
  default     = "appdb"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

Create `outputs.tf`:

```hcl
output "project_id" {
  description = "Neon project ID"
  value       = neon_project.main.id
}

output "connection_string" {
  description = "Database connection string"
  value       = data.neon_branch.primary.connection_uri
  sensitive   = true
}

output "host" {
  description = "Database host"
  value       = data.neon_branch.primary.host
}

output "port" {
  description = "Database port"
  value       = data.neon_branch.primary.port
}
```

Apply changes:

```bash
export NEON_API_KEY="your-neon-api-key"

tofu init
tofu plan -out=tfplan
tofu apply tfplan

tofu output
```

## Best Practices

### Security

- Use environment variables for API keys (NEON_API_KEY)
- Create separate roles for different use cases
- Use SSL/TLS for all database connections
- Rotate Neon API keys regularly
- Use secret managers for production credentials

### Branching Strategy

- Use branches for development and testing
- Create feature branches for isolated development
- Keep primary branch for production workloads
- Delete feature branches after merging
- Reset development branches from primary regularly

### Cost Optimization

- Suspend endpoints when not in use
- Use read-only endpoints for analytics
- Monitor storage and compute usage in Neon console
- Delete unused branches and databases
- Leverage Neon's autoscaling

### Connection Management

- Use connection pooling for high-traffic applications
- Use read-only endpoints for analytics
- Always use SSL/TLS for production connections
- Configure appropriate connection timeouts
- Implement retry logic for transient failures

## Common Issues

### Provider Authentication Failed

**Symptom**: Error `Error: Error configuring provider: authentication failed`

**Solution**:
```bash
echo $NEON_API_KEY
curl -H "Authorization: Bearer $NEON_API_KEY" \
  https://console.neon.tech/api/v1/projects
```

### Project Already Exists

**Symptom**: Error `Error: Project with name already exists`

**Solution**:
```bash
# Use data source to reference existing project
data "neon_project" "existing" {
  name = "existing-project-name"
}

# Or import existing project
tofu import neon_project.main project-id
```

### Endpoint Connection Failed

**Symptom**: Cannot connect to database endpoint

**Solution**:
```bash
# Check connection string
tofu output connection_string

# Verify endpoint is not suspended
# Check suspend parameter in resource

# Test connection
psql $CONNECTION_STRING
```

### Provider Version Conflict

**Symptom**: Error `Error: Provider version constraint`

**Solution**:
```bash
# Avoid `tofu init -upgrade` in CI pipelines
tofu init

# Run upgrade manually and review plans
tofu init -upgrade
tofu plan -out=tfplan
# Review carefully before applying
```

### State Lock Error

**Symptom**: Error `Error: Error acquiring the state lock`

**Solution**:
```bash
# Check who has the lock
tofu state pull

# Force unlock (caution!)
tofu force-unlock <LOCK_ID>
```

## References

- **Terraform Registry (Neon Provider)**: https://registry.terraform.io/providers/kislerdm/neon/latest/docs
- **Provider GitHub**: https://github.com/kislerdm/terraform-provider-neon
- **Neon Documentation**: https://neon.tech/docs/
- **Neon Terraform Guide**: https://neon.tech/docs/reference/terraform
- **Important Usage Notes**: https://neon.tech/docs/reference/terraform#important-usage-notes
- **OpenTofu Documentation**: https://opentofu.org/docs/
