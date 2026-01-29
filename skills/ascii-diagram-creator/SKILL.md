---
name: ascii-diagram-creator
description: Create ASCII diagrams from workflow definitions and save them as image files (PNG, SVG, etc.)
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: diagram-generation
---

## What I do
- Parse workflow definition to understand diagram structure
- Generate clean, well-formatted ASCII representation of workflow
- Convert ASCII to image file (PNG, SVG, or other formats)
- Save image file to specified location (default: `./diagrams/`)

**Supported diagram types**:
- Flowcharts
- Process flows
- Sequence diagrams
- State machines
- System architecture diagrams
- Decision trees

## When to use me

Use when:
- Visualizing a workflow, process, or system architecture
- Need a quick, text-based diagram that can be saved as an image
- Including diagrams in documentation or presentations
- Documenting code logic or system flows
- Communicating complex processes in a visual format

## Prerequisites

- ImageMagick or similar tool for ASCII to image conversion
- Write permissions to output directory
- Valid workflow definition from user input

## Steps

### Step 1: Analyze Workflow Request

**Key elements to extract**:
- Start/end points
- Processes/actions
- Decision points
- Connections/flows
- Labels and annotations

### Step 2: Design ASCII Diagram

**Standard ASCII diagramming conventions**:
```
┌─────────────┐
│   Start     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Process   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    End      │
└─────────────┘
```

**Best practices**:
- Use consistent spacing and alignment
- Ensure diagram is readable and properly aligned
- Follow standard conventions for box-drawing characters

### Step 3: Create Output Directory

```bash
mkdir -p diagrams
```

### Step 4: Save ASCII to Text File

```bash
cat > /tmp/workflow.txt << 'EOF'
[ASCII diagram content]
EOF
```

### Step 5: Convert ASCII to Image

**Using ImageMagick**:
```bash
convert -font Courier -pointsize 12 -background white -fill black \
  -border 20 -bordercolor white /tmp/workflow.txt diagrams/workflow.png
```

**Supported formats**:
- PNG (default)
- SVG (for scalable graphics)
- PDF (for documentation)

### Step 6: Verify and Report

```bash
ls -lh diagrams/workflow.png
echo "Image saved: diagrams/workflow.png"
```

## Examples

**Example 1: Simple Flowchart**

**Input**: "Create a flowchart showing a login process: start, check credentials, if valid show dashboard, else show error, end"

**Output**:
```
┌─────────────┐
│   Start     │
└──────┬──────┘
       │
       ▼
┌───────────────┐
│Check Credentials│
└──────┬────────┘
       │
       ├────── Valid ────┐
       │                 │
       │                 ▼
       │      ┌───────────────┐
       │      │  Show Dashboard│
       │      └───────────────┘
       │
       │
       ▼
┌──────────────┐
│   Show Error  │
└──────┬───────┘
       │
       ▼
┌─────────────┐
│    End      │
└─────────────┘
```

## Best Practices

- Use standard box-drawing characters (─│┌┐└┘┬┼┼┤)
- Maintain consistent alignment and spacing
- Keep diagrams simple and readable
- Use meaningful labels
- Test diagram in different terminals
- Save in multiple formats for flexibility

## Common Issues

### Image Conversion Fails
**Solution**: Install ImageMagick: `sudo apt install imagemagick` (Ubuntu) or `brew install imagemagick` (macOS).

### Diagram Alignment Issues
**Solution**: Use monospace fonts, ensure consistent character widths.

### Output Directory Not Writable
**Solution**: Check permissions with `ls -ld diagrams`, change owner with `sudo chown`.

## References

- ImageMagick Documentation: https://imagemagick.org/script/command-line-options.php
- ASCII Art Tools: https://www.asciiflow.com/
