---
name: opentofu-provider-setup
description: Configure OpenTofu with cloud providers, manage authentication, and setup state backends
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: infrastructure-provisioning
---

## What I do
- Configure OpenTofu providers with required and optional parameters
- Set up authentication methods (access keys, service principals, etc.)
- Configure remote state backends (S3, Azure Storage, GCS)
- Follow provider-specific configuration patterns from official docs

## When to use me
Use when:
- Initializing new OpenTofu project with provider configuration
- Configuring authentication for cloud providers (AWS, Azure, GCP, etc.)
- Setting up remote state backends for team collaboration
- Troubleshooting provider connection or authentication issues

## Prerequisites
- OpenTofu CLI installed: https://opentofu.org/docs/intro/install/
- Valid credentials for target cloud provider
- Basic Terraform knowledge (HCL syntax, configuration structure)
- Reference to provider's official documentation

## References
- OpenTofu Documentation: https://opentofu.org/docs/
- Terraform Registry: https://registry.terraform.io/
- AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- GCP Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- State Backends: https://www.terraform.io/docs/language/settings/backends/index.html

## Steps

### Step 1: Install and Initialize
```bash
tofu version
mkdir my-opentofu-project && cd my-opentofu-project
tofu init
```

### Step 2: Configure Provider
Create `versions.tf`:
```hcl
terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
    google  = { source = "hashicorp/google", version = "~> 5.0" }
  }
  backend "s3" { bucket = "my-opentofu-state", key = "prod/terraform.tfstate", region = "us-east-1" }
}
```

### Step 3: Configure Provider Authentication

**AWS**:
```hcl
provider "aws" {
  region = "us-east-1"
  # Method 1: Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  # Method 2: Shared credentials file (~/.aws/credentials)
  # Method 3: Assume role: assume_role { role_arn = "arn:aws:iam::123456789012:role/TerraformRole" }
}
```

**Azure**:
```hcl
provider "azurerm" {
  features {}
  # Method 1: Environment variables (ARM_CLIENT_ID, ARM_CLIENT_SECRET, etc.)
  # Method 2: Managed Identity
  # Method 3: Service Principal with Certificate
}
```

**GCP**:
```hcl
provider "google" {
  project = "my-project-id"
  region  = "us-central1"
  # Method 1: Application Default Credentials
  # Method 2: Service Account Key (GOOGLE_CREDENTIALS env var)
  # Method 3: Workload Identity
}
```

### Step 4: Configure State Backend

**AWS S3**:
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**Azure Storage**:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-storage-rg"
    storage_account_name = "terraformstate123"
    container_name       = "terraform-state"
    key                  = "prod.terraform.tfstate"
  }
}
```

**GCS**:
```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "prod"
  }
}
```

### Step 5: Initialize and Verify
```bash
tofu init
tofu init -upgrade
tofu plan -out=tfplan
```

## Best Practices

### Configuration
- Pin provider versions to avoid breaking changes
- Store state securely in encrypted remote backends
- Use environment variables, never hardcode credentials
- Enable state locking with DynamoDB or equivalent
- Separate state per environment (dev/staging/prod)

### Security
```bash
# Use AWS Vault for credential management
aws-vault exec my-profile -- tofu plan

# Use environment variables in production
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### Organization
- Organize providers in separate files (providers/aws.tf, providers/azure.tf)
- Use workspace management for multiple environments

## Common Issues

### Provider Not Found
**Solution**: `tofu init -upgrade` and verify provider source/version in versions.tf.

### Authentication Failed
**Solution**: Verify credentials with `aws sts get-caller-identity` and check environment variables. Reference provider authentication docs.

### State Backend Access Denied
**Solution**: Verify IAM/permissions for state bucket. Check S3 bucket policy, Storage Account access, or GCS IAM permissions. Force unlock if necessary: `tofu force-unlock <LOCK_ID>` (caution!).

### Provider Version Conflict
**Solution**: Remove lock file and reinitialize: `rm -rf .terraform/ && rm .terraform.lock.hcl && tofu init -upgrade`.
