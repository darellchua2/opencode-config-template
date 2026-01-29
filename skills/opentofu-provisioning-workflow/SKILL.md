---
name: opentofu-provisioning-workflow
description: Infrastructure as Code development patterns, resource lifecycle management, and state management workflows with OpenTofu
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: infrastructure-provisioning
---

## What I do
- Guide through complete IaC development workflows using OpenTofu
- Handle resource creation, modification, and deletion
- Manage OpenTofu state and troubleshoot state issues
- Apply IaC best practices and handle resource dependencies

## When to use me
Use when:
- Creating or updating infrastructure resources
- Planning and previewing infrastructure changes
- Troubleshooting state issues or drift
- Implementing infrastructure best practices

## Prerequisites
- OpenTofu CLI installed: https://opentofu.org/docs/intro/install/
- Provider configured via `opentofu-provider-setup`
- Valid provider credentials
- Basic understanding of HCL (HashiCorp Configuration Language)
- Remote state backend configured (S3, Azure Storage, GCS)

## Steps

### Step 1: Define Resources
Create `main.tf` with infrastructure resources.
**Key pattern**:
```hcl
resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  tags = { Name = "WebServer", Environment = var.environment }
}
```

### Step 2: Define Variables
Create `variables.tf` for reusability.
**Key pattern**:
```hcl
variable "ami_id" {
  description = "ID of AMI to use for EC2 instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}
```

### Step 3: Define Outputs
Create `outputs.tf` to expose values.
**Key pattern**:
```hcl
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}
```

### Step 4: Initialize and Format
```bash
tofu init      # Download providers
tofu fmt       # Format code
tofu validate  # Validate configuration
```

### Step 5: Plan Changes
```bash
tofu plan              # Show execution plan
tofu plan -out=tfplan  # Save plan for review
tofu show tfplan       # Review plan details
```

### Step 6: Apply Changes
```bash
tofu apply         # Apply interactively
tofu apply tfplan   # Apply saved plan
tofu apply -auto-approve  # Auto-approve (use caution)
```

### Step 7: Inspect State
```bash
tofu state list                    # List resources
tofu state show aws_instance.web   # Show specific resource
tofu show -json                    # Show state as JSON
```

### Step 8: Update Resources
```bash
tofu plan -out=tfplan  # Modify and plan
tofu apply tfplan       # Review and apply
```

### Step 9: Destroy Resources
```bash
tofu plan -destroy                              # Plan destruction
tofu destroy                                    # Destroy all resources
tofu destroy -target=aws_instance.web_server    # Destroy specific resource
```

## Best Practices

### Resource Management
- Use descriptive, self-documenting resource names
- Apply consistent tagging for cost tracking
- Use variables instead of hardcoding values
- Separate environments with workspaces or state files
- Keep configurations focused and modular

### State Management
- Use remote state backends for team collaboration
- Enable encryption and versioning on state
- Use state locking to prevent conflicts
- Regular backups of state files

### Dependency Management
```hcl
# Implicit dependencies (reference attributes)
resource "aws_instance" "web" {
  vpc_security_group_ids = [aws_security_group.web.id]
}

# Explicit dependencies
resource "aws_instance" "db" {
  depends_on = [aws_instance.web]
}

# Multiple resources with count/for_each
resource "aws_instance" "servers" {
  count = 3
  ami   = var.ami_id
  tags  = { Name = "Server-${count.index + 1}" }
}
```

### Modularization
```hcl
# Reusable module structure
module "vpc" {
  source    = "./modules/vpc"
  cidr_block = var.vpc_cidr
  name      = var.project_name
  tags      = var.common_tags
}
```

### Lifecycle Management
```hcl
resource "aws_instance" "web" {
  lifecycle {
    create_before_destroy = true
    ignore_changes       = [tags, user_data]
  }
}
```

## Common Issues

### State File Lock
**Symptom**: `Error acquiring the state lock`
**Solution**:
```bash
tofu force-unlock <LOCK_ID>  # Use caution!
```

### Resource Already Exists
**Symptom**: Error creating resource that already exists
**Solution**:
```bash
tofu import aws_instance.web i-0123456789abcdef0
```

### State Drift
**Symptom**: Actual infrastructure differs from state
**Solution**:
```bash
tofu apply -refresh-only  # Sync state without changes
tofu import <resource>.<name> <id>  # Import manual changes
```

### Dependency Cycle
**Symptom**: `Cycle` error
**Solution**: Use explicit dependencies or refactor configuration. Visualize with `tofu graph | dot -Tpng > graph.png`.

## References
- OpenTofu Documentation: https://opentofu.org/docs/
- Terraform Language: https://www.terraform.io/docs/language/
- Terraform State: https://www.terraform.io/docs/language/state/
- Resource Lifecycle: https://www.terraform.io/docs/language/meta-arguments/lifecycle.html
