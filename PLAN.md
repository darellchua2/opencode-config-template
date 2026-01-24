# Plan: Fix poetry pytest workflow to properly detect and activate virtual environments

## Overview
Implement virtual environment detection and activation logic in `pr-creation-workflow` to ensure `poetry run pytest` runs in isolated Python environment, preventing system library pollution.

## Issue Reference
- Issue: #28
- URL: https://github.com/darellchua2/opencode-config-template/issues/28
- Labels: bug, enhancement

## Files to Modify
1. `skills/pr-creation-workflow/SKILL.md` - Add virtual environment detection logic to Step 2: Run Quality Checks

## Approach

### Phase 1: Analysis
- [x] Analyze current implementation in pr-creation-workflow/SKILL.md
- [x] Identify problem at lines 108-115 (test check section)
- [x] Determine required virtual environment detection patterns

### Phase 2: Implementation
1. **Add Virtual Environment Detection Section**:
   - Add detection logic for common virtual environment directories (.venv, venv, myvenv, env, virtualenv)
   - Check in priority order (Poetry default first)
   - Implement shell detection (bash/zsh/fish/PowerShell)

2. **Update Step 2: Run Quality Checks**:
   - Insert virtual environment detection before running `poetry run pytest`
   - Add activation logic based on shell type
   - Handle case when no virtual environment exists (create or prompt)
   - Add logging to show which environment is being used

3. **Add Code Examples**:
   - Show bash script for detection and activation
   - Include error handling for missing venv
   - Provide Poetry-specific creation command

4. **Update Documentation**:
   - Add new subsection "Virtual Environment Detection for Python"
   - Document supported patterns and shells
   - Update best practices section
   - Add troubleshooting for venv issues

### Phase 3: Testing
- [ ] Test with existing .venv directory (Poetry project)
- [ ] Test with existing venv directory (pip project)
- [ ] Test without virtual environment (should create one)
- [ ] Test with custom virtual environment name (myvenv)
- [ ] Verify logging shows correct environment
- [ ] Ensure system Python is not used

## Implementation Details

### Virtual Environment Detection Logic:
```bash
# Function to detect virtual environment
detect_and_activate_venv() {
  local venv_dirs=(".venv" "venv" "myvenv" "env" "virtualenv")

  for venv_dir in "${venv_dirs[@]}"; do
    if [ -d "$venv_dir" ]; then
      # Check for activation script
      if [ -f "$venv_dir/bin/activate" ]; then
        # bash/zsh
        source "$venv_dir/bin/activate"
        echo "✅ Activated virtual environment: $venv_dir"
        return 0
      elif [ -f "$venv_dir/bin/activate.fish" ]; then
        # fish
        source "$venv_dir/bin/activate.fish"
        echo "✅ Activated virtual environment: $venv_dir (fish)"
        return 0
      elif [ -f "$venv_dir/Scripts/Activate.ps1" ]; then
        # PowerShell
        . "$venv_dir/Scripts/Activate.ps1"
        echo "✅ Activated virtual environment: $venv_dir (PowerShell)"
        return 0
      fi
    fi
  done

  # No venv found
  return 1
}

# Usage in test check section
if [ "$RUN_TESTS" = "true" ]; then
  echo "Running tests..."
  if command -v npm &>/dev/null; then
    npm run test
  elif command -v poetry &>/dev/null; then
    # Detect and activate virtual environment
    if ! detect_and_activate_venv; then
      echo "⚠️  No virtual environment found"
      read -p "Create virtual environment with 'poetry install'? (y/n): " CREATE_VENV
      if [ "$CREATE_VENV" = "y" ]; then
        poetry install
        poetry shell
      else
        echo "⚠️  Running tests without virtual environment may affect system Python"
      fi
    fi
    poetry run pytest
  fi
fi
```

### Sections to Add to SKILL.md:

#### After line 107 (before "Test check (if enabled)"):
```bash
#### Virtual Environment Detection for Python

**Purpose**: Ensure Python tests run in isolated virtual environment to prevent system library pollution

**Detection Patterns** (checked in priority order):
- `.venv` - Poetry default
- `venv` - Python standard
- `myvenv` - Custom
- `env` - Alternative
- `virtualenv` - Legacy

**Shell Detection and Activation**:
```bash
# Detect virtual environment
if [ -d ".venv" ]; then
  # bash/zsh
  source .venv/bin/activate
  echo "✅ Using virtual environment: .venv"
elif [ -d "venv" ]; then
  source venv/bin/activate
  echo "✅ Using virtual environment: venv"
elif [ -d "myvenv" ]; then
  source myvenv/bin/activate
  echo "✅ Using virtual environment: myvenv"
else
  # No venv found - create if Poetry
  if command -v poetry &>/dev/null && [ -f pyproject.toml ]; then
    echo "⚠️  No virtual environment found"
    read -p "Create with 'poetry install'? (y/n): " CREATE_VENV
    if [ "$CREATE_VENV" = "y" ]; then
      poetry install
      source .venv/bin/activate
      echo "✅ Created and activated virtual environment"
    else
      echo "⚠️  Warning: Tests may affect system Python libraries"
    fi
  fi
fi
```

**PowerShell Activation** (for Windows):
```powershell
if (Test-Path ".venv") {
  .\.venv\Scripts\Activate.ps1
  Write-Host "✅ Using virtual environment: .venv"
}
```
```

## Success Criteria
- [x] pr-creation-workflow/SKILL.md updated with virtual environment detection
- [x] Detection logic covers all common venv patterns (.venv, venv, myvenv, env, virtualenv)
- [x] Shell-specific activation commands documented (bash/zsh/fish/PowerShell)
- [x] Logging shows which environment is being used
- [x] Handles missing venv gracefully (creates or warns)
- [x] Code examples are clear and copy-pasteable
- [x] Documentation follows existing SKILL.md format
- [x] No build errors in syntax validation
- [ ] PR can be created successfully

## Implementation Status

### ✅ Phase 1: Analysis
- [x] Analyzed current implementation in pr-creation-workflow/SKILL.md
- [x] Identified problem at lines 108-115 (test check section)
- [x] Determined required virtual environment detection patterns

### ✅ Phase 2: Implementation
- [x] Added Virtual Environment Detection Section (line 107)
  - Added detection logic for common virtual environment directories
  - Check in priority order (Poetry default first)
  - Implement shell detection (bash/zsh/fish/PowerShell)
- [x] Updated Step 2: Run Quality Checks
  - Inserted virtual environment detection before running `poetry run pytest`
  - Added activation logic based on shell type
  - Handle case when no virtual environment exists (create or prompt)
  - Added logging to show which environment is being used
- [x] Added Code Examples
  - Bash script for detection and activation function
  - Error handling for missing venv
  - Poetry-specific creation command
  - PowerShell activation examples
- [x] Updated Documentation
  - Added new subsection "Virtual Environment Detection for Python"
  - Documented supported patterns and shells
  - Updated best practices section (line 581)
  - Added 4 new troubleshooting sections:
    - Virtual Environment Not Detected (line 658)
    - Virtual Environment Activation Fails (line 683)
    - Poetry Install Fails (line 709)
    - Tests Run in System Python (line 743)
  - Updated Troubleshooting Checklist with venv checks (line 779)
  - Added Virtual Environment Commands section (line 827)

### ⏳ Phase 3: Testing
- [ ] Test with existing .venv directory (Poetry project)
- [ ] Test with existing venv directory (pip project)
- [ ] Test without virtual environment (should create one)
- [ ] Test with custom virtual environment name (myvenv)
- [ ] Verify logging shows correct environment
- [ ] Ensure system Python is not used

## Notes
- Poetry is preferred for Python projects (detected via `pyproject.toml`)
- Fallback to pip-based venv if Poetry not available
- Always warn user before running tests without venv (prevents accidental system pollution)
- Shell detection via `$SHELL` environment variable
- Cross-platform support (Linux/Mac/Windows)

## Dependencies
- None (modifies existing skill documentation only)

## Risks
- Risk: User may not have `poetry` or `venv` tools installed
  - Mitigation: Check tool availability and provide clear error messages with installation instructions
- Risk: Virtual environment activation may fail silently
  - Mitigation: Always log activation status with clear visual indicators (✅/⚠️)
- Risk: PowerShell activation requires execution policy changes
  - Mitigation: Document PowerShell requirement and provide alternative (cmd)

## Testing Plan
1. **Create test Poetry project**:
   ```bash
   mkdir test-poetry-project
   cd test-poetry-project
   poetry init -n
   poetry add pytest
   poetry install  # Creates .venv
   ```

2. **Test detection**:
   - Run detection logic
   - Verify .venv is detected and activated
   - Check logging output

3. **Test without venv**:
   - Remove .venv directory
   - Run detection logic
   - Verify prompt appears to create venv

4. **Test custom venv name**:
   - Create `myvenv` directory
   - Run detection logic
   - Verify myvenv is detected

5. **Test with pip project**:
   - Create requirements.txt
   - Create venv with `python -m venv venv`
   - Run detection logic
   - Verify venv is detected

## Next Steps
1. Implement changes to pr-creation-workflow/SKILL.md
2. Create test project to verify implementation
3. Run validation: `jq . config.json` (not needed, but good practice)
4. Commit changes
5. Push branch
6. Create PR with updated issue reference
