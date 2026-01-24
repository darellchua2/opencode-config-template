# Plan: Add OpenTofu related skills for infrastructure provisioning

## Overview
Add new skills to the OpenCode framework that provide guidance on using OpenTofu (the open-source fork of Terraform) for infrastructure provisioning. These skills should leverage official OpenTofu and Terraform provider documentation to ensure best practices and proper implementation patterns.

## Issue Reference
- Issue: #38
- URL: https://github.com/darellchua2/opencode-config-template/issues/38
- Labels: enhancement

## Requirements

### Scope

Create one or more skills in the `skills/` directory that provide:

1. **OpenTofu Provider Setup Skills**
   - Guidance on configuring OpenTofu with various cloud providers
   - Best practices for provider authentication and configuration
   - State management strategies

2. **OpenTofu Provisioning Workflows**
   - Infrastructure as Code (IaC) development patterns
   - Resource lifecycle management
   - Configuration and state management workflows

### Documentation Requirements

Each skill MUST include:
- **Reference URL**: Link to the official provider documentation (OpenTofu or Terraform Registry)
- **Best Practices**: Verified implementation patterns from provider documentation
- **Common Examples**: Typical use cases and configurations

#### Example Skill Structure

```
skills/opentofu-provider-setup/SKILL.md
- Provider configuration overview
- Authentication setup
- State backend configuration
- Reference URL: https://opentofu.org/docs/providers/

skills/opentofu-provisioning-workflow/SKILL.md
- Resource provisioning patterns
- Dependency management
- State lifecycle management
- Reference URL: https://registry.terraform.io/providers/
```

## Rationale

OpenTofu is gaining traction as a community-driven fork of Terraform. Adding skills for OpenTofu:
- Provides support for open-source infrastructure provisioning
- Enables users to leverage provider documentation effectively
- Ensures best practices are followed through documented workflows
- Aligns with the open-source nature of the OpenCode framework

## Files to Modify/Create

1. `skills/opentofu-provider-setup/SKILL.md` - New skill for provider setup
2. `skills/opentofu-provisioning-workflow/SKILL.md` - New skill for provisioning workflows
3. `README.md` - Update to document new OpenTofu skills (optional)
4. `setup.sh` - Add OpenTofu dependency checks (if needed)

## Approach

### Phase 1: Research and Planning
1. Review OpenTofu documentation structure and best practices
2. Identify common use cases for OpenTofu provisioning
3. Select representative cloud providers (AWS, Azure, GCP) for examples
4. Document reference URLs for each provider

### Phase 2: Skill Development (using opencode-skill-creation)
1. Use opencode-skill-creation skill to create `opentofu-provider-setup` skill
2. Use opencode-skill-creation skill to create `opentofu-provisioning-workflow` skill
3. Ensure each skill follows SKILL.md format with proper frontmatter

### Phase 3: Testing and Validation
1. Test skill invocation with `opencode` command
2. Verify reference URLs are accessible and accurate
3. Validate skills follow existing SKILL.md format
4. Test setup.sh with OpenTofu dependencies

### Phase 4: Documentation Updates
1. Update README.md to include new OpenTofu skills in the overview
2. Update setup.sh to check for OpenTofu CLI (tofu)
3. Add examples to README showing skill usage

## Success Criteria

- [ ] At least 2-3 skills created for OpenTofu workflows
- [ ] Each skill includes a reference URL to provider documentation
- [ ] Skills follow the existing SKILL.md format (see skills/jira-git-workflow/SKILL.md)
- [ ] Skills are tested and documented in the repository
- [ ] Setup.sh includes any necessary OpenTofu dependencies (if applicable)
- [ ] README.md updated with new skills documentation

## Notes

- OpenTofu maintains API compatibility with Terraform 1.5.x
- Provider documentation can be sourced from both Terraform Registry and OpenTofu docs
- Focus on common providers (AWS, Azure, GCP, etc.) initially
- Ensure skills are vendor-agnostic where possible
- Reference URLs:
  - OpenTofu Documentation: https://opentofu.org/docs/
  - Terraform Registry: https://registry.terraform.io/
