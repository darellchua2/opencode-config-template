---
name: opentofu-ecr-provision
description: Provision AWS Elastic Container Registry (ECR) repositories with GitHub OIDC integration following BETEKK standards
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: infrastructure-as-code
---

## What I do
- Create ECR repositories with proper configuration and lifecycle policies
- Setup IAM roles for GitHub Actions to push/pull images
- Configure S3 backend for Terraform state management
- Implement standardized IAM roles with OIDC trust relationships
- Apply BETEKK naming conventions and modular structure

## When to use me
Use when:
- Provisioning new ECR repository for Docker container images
- Setting up GitHub Actions CI/CD for ECR integration
- Creating standardized AWS infrastructure following BETEKK patterns
- Implementing OIDC authentication for GitHub Actions

## Prerequisites
- OpenTofu CLI installed: https://opentofu.org/docs/intro/install/
- Valid AWS account with appropriate permissions
- GitHub OIDC provider configured (can be created during workflow)
- Basic OpenTofu/Terraform knowledge

## References
- AWS ECR Documentation: https://docs.aws.amazon.com/AmazonECR/
- AWS Provider (ECR): https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
- GitHub OIDC: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

## BETEKK Standards

### Variable Naming Convention
```hcl
variable "environment" { description = "Environment (dev, prod, uat)", type = string }
variable "project_prefix" { description = "Project Prefix", type = string, default = "betekk" }
variable "repo_name" { description = "ECR Repository Name", type = string, default = "betekk-<service-name>" }
variable "aws_region" { description = "AWS region", type = string, default = "ap-southeast-1" }
variable "state_management_bucket_name" { description = "State Bucket", type = string, default = "betekk-state-management-bucket" }
variable "github_organization_old" { description = "Old GitHub Org", type = string, default = "nus-cee" }
variable "github_organization_new" { description = "New GitHub Org", type = string, default = "betekk" }
```

### Folder Structure
```
<service-name>/
├── modules/
│   ├── ecr/ (main.tf, variables.tf)
│   └── iam-role-assume/ (main.tf, variables.tf)
├── data.tf
├── iam_policies.tf
├── iam_policy_attachments.tf
├── iam_roles.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── terraform.tf
└── variables.tf
```

## Steps

### Step 1: Initialize Project
```bash
mkdir -p <service-name>/modules/ecr && mkdir -p <service-name>/modules/iam-role-assume
cd <service-name> && tofu init
```

### Step 2: Configure Terraform and Provider
**terraform.tf**:
```hcl
terraform {
  required_version = "~> 1.8"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = var.state_management_bucket_name
    key    = "ecr/<service-name>/terraform.tfstate"
    region = var.aws_region
  }
}
```

**providers.tf**:
```hcl
provider "aws" { region = var.aws_region }
```

### Step 3: Define Variables
**variables.tf** (use BETEKK naming convention from above).

### Step 4: Create ECR Module
**modules/ecr/main.tf**:
```hcl
resource "aws_ecr_repository" "repository" {
  name         = var.repository_name
  force_delete = false
}

output "repository_url" { description = "ECR repository URL", value = aws_ecr_repository.repository.repository_url }
output "repository_arn" { description = "ECR repository ARN", value = aws_ecr_repository.repository.arn }
```

**modules/ecr/variables.tf**:
```hcl
variable "repository_name" { type = string, description = "ECR repository name" }
```

### Step 5: Create IAM Assume Role Module
**modules/iam-role-assume/main.tf**:
```hcl
resource "aws_iam_policy" "assume_role_policy" {
  name        = "${var.project_prefix}_AssumeRolePolicy"
  description = "Policy allowing assume role access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Resource = var.assume_role_arn }]
  })
}

resource "aws_iam_policy_attachment" "assume_role_policy_attachment" {
  name       = "${var.project_prefix}-AssumeRoleAttachment"
  policy_arn = aws_iam_policy.assume_role_policy.arn
  users      = [var.user_arn]
}
```

### Step 6: Create IAM Roles
**iam_roles.tf**:
```hcl
# GitHub ECR Upload Role
resource "aws_iam_role" "ecr_betekk_probe_engine_github_workflows_upload_role" {
  name = "${upper(var.project_prefix)}-GithubWorkflowsUploadRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { "Federated" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com" }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:aud"  = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub"  = ["repo:${var.github_organization_old}/<repo-name>:*", "repo:${var.github_organization_new}/<repo-name>:*"]
        }
      }
    }]
  })
}

# Lambda Deploy Role
resource "aws_iam_role" "betekk_lambda_github_workflows_deploy_role" {
  name = "${upper(var.project_prefix)}-GithubWorkflowsLambdaDeployRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { "Federated" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com" }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:aud"  = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub"  = ["repo:${var.github_organization_old}/<repo-name>:*", "repo:${var.github_organization_new}/<repo-name>:*"]
        }
      }
    }]
  })
}
```

### Step 7: Create IAM Policies
**iam_policies.tf**:
```hcl
# ECR Upload Policy
resource "aws_iam_policy" "ecr_upload_policy" {
  name        = "${var.project_prefix}-ECRUploadPolicy"
  description = "Policy allowing ECR operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload", "ecr:DescribeRepositories", "ecr:GetRepositoryPolicy",
        "ecr:ListImages", "ecr:DeleteRepository", "ecr:BatchDeleteImage",
        "ecr:SetRepositoryPolicy", "ecr:DeleteRepositoryPolicy"
      ]
      Resource = "*"
    }]
  })
}

# Lambda Deploy Policy
resource "aws_iam_policy" "lambda_deploy_policy" {
  name        = "${var.project_prefix}-LambdaDeployPolicy"
  description = "Policy allowing Lambda operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["lambda:CreateFunction", "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration", "lambda:GetFunction", "lambda:DeleteFunction"]
      Resource = "*"
    }]
  })
}
```

### Step 8: Attach Policies
**iam_policy_attachments.tf**:
```hcl
resource "aws_iam_role_policy_attachment" "ecr_upload_attachment" {
  role       = aws_iam_role.ecr_betekk_probe_engine_github_workflows_upload_role.name
  policy_arn = aws_iam_policy.ecr_upload_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_deploy_attachment" {
  role       = aws_iam_role.betekk_lambda_github_workflows_deploy_role.name
  policy_arn = aws_iam_policy.lambda_deploy_policy.arn
}
```

### Step 9: Create Root Module and Outputs
**main.tf**:
```hcl
data "aws_caller_identity" "current" {}

module "ecr_betekk_<service-name>" {
  source          = "./modules/ecr"
  repository_name = var.repo_name
}
```

**outputs.tf**:
```hcl
output "ecr_repository_url" { description = "ECR repository URL", value = module.ecr_betekk_<service-name>.repository_url }
output "ecr_repository_arn" { description = "ECR repository ARN", value = module.ecr_betekk_<service-name>.repository_arn }
output "ecr_upload_role_arn" { description = "ECR upload role ARN", value = aws_iam_role.ecr_betekk_probe_engine_github_workflows_upload_role.arn }
output "lambda_deploy_role_arn" { description = "Lambda deploy role ARN", value = aws_iam_role.betekk_lambda_github_workflows_deploy_role.arn }
```

### Step 10: Initialize and Apply
```bash
tofu init
tofu plan -out=tfplan
tofu apply tfplan
tofu output
```

## Best Practices

### Security
- Grant minimal permissions in IAM roles and policies
- Use GitHub OIDC instead of long-lived credentials
- Enable ECR image scanning for security vulnerabilities
- Use consistent tags for all resources

### High Availability
- Deploy repositories to multiple regions if needed
- Consider ECR replication for disaster recovery

### Cost Optimization
- Implement ECR lifecycle policies to clean up old images
- Use consistent image tagging for easy cleanup
- Monitor repository size and image count

### State Management
- Use S3 backend for state management
- Enable state encryption and versioning on state bucket

## Common Issues

### Repository Already Exists
**Solution**: Import existing repository with `tofu import aws_ecr_repository.repository <repository-name>`.

### OIDC Provider Not Found
**Solution**: Create OIDC provider:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com
```

### Authentication Failed
**Solution**: Verify credentials with `aws sts get-caller-identity`, check environment variables.

### State Lock Error
**Solution**: Check lock with `tofu state pull`, force unlock if necessary: `tofu force-unlock <LOCK_ID>` (caution!).
