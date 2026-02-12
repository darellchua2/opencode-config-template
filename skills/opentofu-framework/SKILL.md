---
name: opentofu-framework
description: Framework for OpenTofu/Terraform infrastructure management workflows
license: Apache-2.0
compatibility: opencode
metadata:
  audience: devops, platform engineers
  workflow: infrastructure
  type: framework
---

## What I do

Framework for infrastructure-as-code workflows using OpenTofu/Terraform. Extended by platform-specific skills.

## Extensions

| Skill | Platform | Purpose |
|-------|----------|---------|
| `opentofu-provider-setup` | All | Configure providers, auth, state backends |
| `opentofu-provisioning-workflow` | All | Resource lifecycle management |
| `opentofu-kubernetes-explorer` | Kubernetes | K8s clusters and resources |
| `opentofu-neon-explorer` | Neon | Serverless Postgres databases |
| `opentofu-aws-explorer` | AWS | EC2, S3, EKS, IAM resources |
| `opentofu-keycloak-explorer` | Keycloak | Identity and access management |
| `opentofu-ecr-provision` | AWS ECR | Container registry with OIDC |

## Workflow Steps

### 1. Setup & Configuration
- Initialize: `tofu init`
- Configure provider credentials
- Setup state backend (local, S3, Terraform Cloud)
- Use `opentofu-provider-setup` for auth

### 2. Plan & Preview
- Plan changes: `tofu plan -out=tfplan`
- Review planned resource changes
- Validate configuration: `tofu validate`
- Check formatting: `tofu fmt -check`

### 3. Apply Changes
- Apply plan: `tofu apply tfplan`
- Monitor resource creation/updates
- Handle errors and rollbacks
- Use `opentofu-provisioning-workflow` for patterns

### 4. Explore Resources (Platform-Specific)
- Use platform explorer skills for resource management
- Import existing resources: `tofu import`
- Query state: `tofu state list`, `tofu show`
- Use `*-explorer` skills for platform operations

### 5. State Management
- Backup state before changes
- Use remote state for teams
- Lock state during operations
- Migrate state if needed: `tofu state mv`

## Common Commands

```bash
tofu init          # Initialize
tofu plan          # Preview changes
tofu apply         # Apply changes
tofu destroy       # Remove resources
tofu state list    # List resources
tofu import        # Import existing
tofu fmt           # Format code
tofu validate      # Validate config
```

## Best Practices

1. Always run `tofu plan` before `tofu apply`
2. Use remote state with locking
3. Store `.tfvars` in secure location
4. Use modules for reusable components
5. Tag all resources for tracking
6. Review plans in PR workflow

## Related Skills

- `opentofu-provider-setup` - Provider configuration
- `opentofu-provisioning-workflow` - Provisioning patterns
- Platform explorers - AWS, K8s, Neon, Keycloak
