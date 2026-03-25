---
name: pptx-specialist
description: "Use this skill whenever the user wants to create, read, edit, or analyze PowerPoint presentations (.pptx files). Triggers include: any mention of 'PowerPoint', '.pptx', 'presentation', 'slides', 'deck', 'html to pptx', 'convert html to powerpoint', 'create presentation', 'edit pptx', or requests to produce visual presentations with charts, tables, or professional design. Also use when extracting content from presentations, analyzing slide layouts, creating thumbnails, or converting slides to images. Do NOT use for Word documents (.docx), PDFs, or general coding tasks unrelated to presentation generation."
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: presentation-generation
---

## What I do

- Create new PowerPoint presentations (.pptx) from scratch using html2pptx workflow
- Read and analyze existing presentations using markitdown or raw XML extraction
- Edit existing presentations by unpacking, modifying XML, and repacking
- Create presentations from templates by duplicating, reordering, and replacing text
- Generate visual thumbnail grids for presentation analysis
- Convert slides to images for review and documentation
- Apply professional design principles with color palettes and typography
- Add charts, tables, images, and formatted content to slides

## When to use me

Use this skill when:
- User mentions "PowerPoint", ".pptx", "presentation", "slides", or "deck"
- Creating presentations with charts, tables, or professional formatting
- Extracting or reorganizing content from .pptx files
- Analyzing slide layouts and design patterns
- Converting HTML to PowerPoint presentations
- Creating thumbnail grids for visual review
- Working with templates to create branded presentations
- Converting slides to images

Do NOT use for:
- Word documents (.docx) - use docx-creation skill
- PDFs - use PDF-specific tools
- Spreadsheets - use Excel tools
- General coding tasks unrelated to presentations

## Prerequisites

- **markitdown**: Text extraction from .pptx files - `pip install "markitdown[pptx]"`
- **pptxgenjs**: PowerPoint generation - `npm install -g pptxgenjs`
- **playwright**: HTML rendering - `npm install -g playwright`
- **sharp**: Image processing - `npm install -g sharp`
- **LibreOffice**: PDF conversion - `sudo apt-get install libreoffice`
- **Poppler**: PDF to image conversion - `sudo apt-get install poppler-utils`
- **defusedxml**: XML security - `pip install defusedxml`

## Quick Reference

| Task | Approach |
|------|----------|
| Read/analyze content | `markitdown` for text, unpack for raw XML |
| Create new presentation | Use html2pptx workflow - see Creating Presentations Without Template |
| Edit existing presentation | Unpack -> edit XML -> pack - see Editing Existing Presentations |
| Use template | Duplicate, reorder, replace - see Creating Presentations With Template |
| Visual analysis | Generate thumbnail grids with `thumbnail.py` |

### Converting .ppt to .pptx

Legacy `.ppt` files must be converted before editing:

```bash
soffice --headless --convert-to pptx presentation.ppt
```

### Reading Content

```bash
# Text extraction
python -m markitdown presentation.pptx

# Raw XML access
python scripts/pptx/unpack.py presentation.pptx unpacked/
```

### Converting to Images

```bash
# Convert to PDF first
soffice --headless --convert-to pdf presentation.pptx

# Then convert PDF pages to images
pdftoppm -jpeg -r 150 presentation.pdf slide
```

---

## Creating Presentations Without Template

When creating a new PowerPoint presentation from scratch, use the **html2pptx** workflow to convert HTML slides to PowerPoint with accurate positioning.

### Design Principles

**CRITICAL**: Before creating any presentation, analyze the content and choose appropriate design elements:

1. **Consider the subject matter**: What is this presentation about? What tone, industry, or mood does it suggest?
2. **Check for branding**: If the user mentions a company/organization, consider their brand colors and identity
3. **Match palette to content**: Select colors that reflect the subject
4. **State your approach**: Explain your design choices before writing code

### Design Philosophy — "Swiss Style" over "Bootstrap"

- Treat each slide as a single, cohesive canvas with unity
- Use **negative space / whitespace** as the primary active element to separate content
- Establish hierarchy through font size/weight, not boxes/containers
- Prioritize **asymmetrical layouts, floating elements, and overlapping layers** over rigid, symmetrical grid systems
- Minimize the use of grid systems or nested frames; instead use parallel text directly listed in a clean format

### Requirements

- State your content-informed design approach BEFORE writing code
- Use web-safe fonts only: Arial, Helvetica, Times New Roman, Georgia, Courier New, Verdana, Tahoma, Trebuchet MS, Impact
- Create clear visual hierarchy through size, weight, and color
- Ensure readability: strong contrast, appropriately sized text, clean alignment
- Be consistent: use the same color palette and font style throughout the entire presentation
- Use keywords, not long sentences — keep each slide concise (avoid more than 100 words per slide)
- Limit emphasis to only the most important elements (no more than 2-3 instances per slide)

### Color Palette Selection

**Color System — Background / Primary / Accent**

Each presentation uses exactly ONE color group with three roles:

- **Background**: Fixed, used only for the slide background
- **Primary**: Used for all main elements — titles, headers, frames, and content blocks (≥80% of non-background color)
- **Accent**: Used rarely (≤5%) for highlights only, never for decoration

**Color Rules**:
- Same type = same color. All titles share one color; all content blocks share one color
- Keep one dominant color (Primary). Accent appears only where emphasis is needed
- Use the same color (mostly Primary) for parallel elements on the same slide
- Global consistency > ratio balance > color variety
- Visual ratio (strictly follow): **Primary ≥ 80% | Accent ≤ 5% | Background fixed**
- Minimize the use of color gradients
- **Background vs text contrast**: Background color and text/Primary color must have strong contrast
- **Shape fill vs slide background**: Decorative shapes must be clearly distinguishable from the slide background

**Available Color Groups** (select ONE group and use ONLY that group for all slides):

| Style | Background | Primary | Accent |
|---|---|---|---|
| Warm Modern (Light) | #F4F1E9 | #15857A | #FF6A3B |
| Warm Modern (Dark) | #111111 | #15857A | #FF6A3B |
| Warm Modern (Mauve) | #111111 | #7C3D5E | #FF7E5E |
| Cool Modern (Green) | #FEFEFE | #44B54B | #1399FF |
| Cool Modern (Navy) | #09325E | #FFFFFF | #7DE545 |
| Cool Modern (Blue) | #FEFEFE | #1284BA | #FF862F |
| Cool Modern (Bold) | #FEFEFE | #133EFF | #00CD82 |
| Deep Mineral (Blue) | #162235 | #FFFFFF | #37DCF2 |
| Deep Mineral (Green) | #193328 | #FFFFFF | #E7E950 |
| Soft Neutral (Yellow) | #F7F3E6 | #E7F177 | #106188 |
| Soft Neutral (Lavender) | #EBDCEF | #73593C | #B13DC6 |
| Soft Neutral (Olive) | #8B9558 | #262626 | #E1DE2D |
| Minimalism (Warm) | #F3F1ED | #000000 | #D6C096 |
| Minimalism (Clean) | #FFFFFF | #000000 | #A6C40D |
| Minimalism (Gray) | #F3F1ED | #393939 | #FFFFFF |
| Warm Retro (Red) | #F4EEEA | #882F1C | #FEE79B |
| Warm Retro (Forest) | #F4F1E9 | #2A4A3A | #C89F62 |
| Warm Retro (Brown) | #554737 | #FFFFFF | #66D4FF |

You may create your own color group only when the user requests specific colors or the provided groups are not suitable — but still follow the Background/Primary/Accent structure and ratio rules strictly.

### Visual & Layout Style

**Layout Approach**:
- **Vertical balance**: When a slide has limited content, vertically center the content using flexbox (`justify-content: center`)
- Create compact layouts: reduce overall vertical height, decrease internal padding/margins
- Use creative, asymmetric arrangements — prioritize visual interest over rigid grids
- Asymmetric column widths (30/70, 40/60, 25/75) are preferred over equal splits
- Floating text boxes and overlapping layers add depth
- Use negative space as a deliberate design element
- Avoid adding too much content per slide — if content exceeds allowed space, remove or summarize lowest-priority items

**Typography**:
- Establish hierarchy through size contrast (large titles vs smaller body text)
- All-caps headers with wide letter spacing for emphasis
- Numbered sections in oversized display type
- Monospace (Courier New) for data/stats/technical content
- Keep emphasized text size smaller than headings/titles
- Do not decrease font size below readable minimums just to fit more content
- Do not apply text-shadows or luminescence effects

**Cover Slide (First Slide)**:
- Title should be prominently sized and either centered or left-aligned with vertical centering
- **CRITICAL**: To vertically center content, the body MUST use `display: flex; flex-direction: column; justify-content: center;`
- If left-aligned, keywords or data highlights can be placed on the right side
- Subtitle should be noticeably smaller than the title
- Background image (if used): only one image with an opaque/semi-transparent mask

**Content Slides**:
- Maintain consistent design using the same color/font palette across all slides
- Content slide backgrounds should be consistent across all slides
- Headers should have consistent layout/style and similar color design across slides

**Charts & Data**:
- Monochrome charts with single accent color for key data
- Data labels directly on elements (no legends when possible)
- Oversized numbers for key metrics
- Minimal gridlines or none at all
- Horizontal bar charts instead of vertical when appropriate

**Background Treatments**:
- Solid color blocks occupying 40-60% of slide
- Split backgrounds (two colors, diagonal or vertical)
- Edge-to-edge color bands
- Minimize gradient fills

### Layout Tips for Charts and Tables

- **Two-column layout (PREFERRED)**: Header spanning full width, then two columns — text/bullets in one and featured content in the other. Use asymmetric column widths (e.g., 40%/60%)
- **Full-slide layout**: Let the featured content take up the entire slide for maximum impact
- **NEVER vertically stack**: Do not place charts/tables below text in a single column

### Workflow

1. **MANDATORY - READ ENTIRE FILE**: Read `html2pptx.md` completely from start to finish. **NEVER set any range limits when reading this file.** Read the full file content for detailed syntax, critical formatting rules, and best practices before proceeding.

2. **Create an HTML file for each slide** with proper dimensions (e.g., 720pt × 405pt for 16:9)
   - Use `<p>`, `<h1>`-`<h6>`, `<ul>`, `<ol>` for all text content
   - Use `class="placeholder"` for areas where charts/tables will be added
   - **CRITICAL**: Rasterize gradients and icons as PNG images FIRST using Sharp, then reference in HTML

3. **Create and run a JavaScript file** using the `html2pptx.js` library to convert HTML slides to PowerPoint
   - Use the `html2pptx()` function to process each HTML file
   - Add charts and tables to placeholder areas using PptxGenJS API
   - Save the presentation using `pptx.writeFile()`

4. **Visual validation**: Generate thumbnails and inspect for layout issues
   ```bash
   python scripts/thumbnail.py output.pptx workspace/thumbnails --cols 4
   ```
   - Read and examine the thumbnail image for text cutoff, overlap, positioning, and contrast issues
   - If issues found, adjust HTML margins/spacing/colors and regenerate

---

## Editing Existing Presentations

When editing slides in an existing PowerPoint presentation, work with the raw Office Open XML (OOXML) format.

### Workflow

1. **MANDATORY - READ ENTIRE FILE**: Read `ooxml.md` (~500 lines) completely from start to finish. **NEVER set any range limits when reading this file.** Read the full file content for detailed guidance on OOXML structure and editing workflows.

2. **Unpack the presentation**:
   ```bash
   python scripts/pptx/unpack.py presentation.pptx output_dir
   ```

3. **Edit the XML files** (primarily `ppt/slides/slide{N}.xml` and related files)

4. **CRITICAL - Validate immediately** after each edit:
   ```bash
   python scripts/pptx/validate.py output_dir --original presentation.pptx
   ```

5. **Pack the final presentation**:
   ```bash
   python scripts/pptx/pack.py output_dir new_presentation.pptx
   ```

### Key File Structures

| File | Description |
|------|-------------|
| `ppt/presentation.xml` | Main presentation metadata and slide references |
| `ppt/slides/slide{N}.xml` | Individual slide contents (slide1.xml, slide2.xml, etc.) |
| `ppt/notesSlides/notesSlide{N}.xml` | Speaker notes for each slide |
| `ppt/comments/modernComment_*.xml` | Comments for specific slides |
| `ppt/slideLayouts/` | Layout templates for slides |
| `ppt/slideMasters/` | Master slide templates |
| `ppt/theme/` | Theme and styling information |
| `ppt/media/` | Images and other media files |

### Typography and Color Extraction

**When given an example design to emulate**: Always analyze the presentation's typography and colors first:

1. **Read theme file**: Check `ppt/theme/theme1.xml` for colors (`<a:clrScheme>`) and fonts (`<a:fontScheme>`)
2. **Sample slide content**: Examine `ppt/slides/slide1.xml` for actual font usage (`<a:rPr>`) and colors
3. **Search for patterns**: Use grep to find color (`<a:solidFill>`, `<a:srgbClr>`) and font references across all XML files

---

## Creating Presentations With Template

When you need to create a presentation that follows an existing template's design, duplicate and re-arrange template slides before replacing placeholder content.

### Workflow

1. **Extract template text AND create visual thumbnail grid**:
   ```bash
   # Extract text
   python -m markitdown template.pptx > template-content.md
   
   # Create thumbnail grids
   python scripts/thumbnail.py template.pptx
   ```
   - Read the entire `template-content.md` file to understand the contents
   - See Creating Thumbnail Grids section for more details

2. **Analyze template and save inventory to a file**:
   - Review thumbnail grid(s) to understand slide layouts, design patterns, and visual structure
   - Create and save a template inventory file at `template-inventory.md`:
   
   ```markdown
   # Template Inventory Analysis
   **Total Slides: [count]**
   **IMPORTANT: Slides are 0-indexed (first slide = 0, last slide = count-1)**
   
   ## [Category Name]
   - Slide 0: [Layout code if available] - Description/purpose
   - Slide 1: [Layout code] - Description/purpose
   ...
   ```

3. **Create presentation outline based on template inventory**:
   - Review available templates from step 2
   - Choose an intro or title template for the first slide
   - Choose safe, text-based layouts for other slides
   - **CRITICAL: Match layout structure to actual content**:
     - Single-column layouts: Use for unified narrative or single topic
     - Two-column layouts: Use ONLY when you have exactly 2 distinct items/concepts
     - Three-column layouts: Use ONLY when you have exactly 3 distinct items/concepts
     - Image + text layouts: Use ONLY when you have actual images to insert
     - Quote layouts: Use ONLY for actual quotes from people (with attribution)
     - Never use layouts with more placeholders than you have content
   - Save `outline.md` with content AND template mapping:
   
   ```
   # Template slides to use (0-based indexing)
   # WARNING: Verify indices are within range! Template with 73 slides has indices 0-72
   template_mapping = [
       0,   # Use slide 0 (Title/Cover)
       34,  # Use slide 34 (B1: Title and body)
       34,  # Use slide 34 again (duplicate for second B1)
       50,  # Use slide 50 (E1: Quote)
       54,  # Use slide 54 (F2: Closing + Text)
   ]
   ```

4. **Duplicate, reorder, and delete slides using `rearrange.py`**:
   ```bash
   python scripts/rearrange.py template.pptx working.pptx 0,34,34,50,52
   ```
   - Slide indices are 0-based (first slide is 0, second is 1, etc.)
   - The same slide index can appear multiple times to duplicate that slide

5. **Extract ALL text using the `inventory.py` script**:
   ```bash
   python scripts/inventory.py working.pptx text-inventory.json
   ```
   - Read the entire text-inventory.json file to understand all shapes and their properties
   
   **Inventory JSON structure**:
   ```json
   {
     "slide-0": {
       "shape-0": {
         "placeholder_type": "TITLE",
         "left": 1.5,
         "top": 2.0,
         "width": 7.5,
         "height": 1.2,
         "paragraphs": [
           {
             "text": "Paragraph text",
             "bullet": true,
             "level": 0,
             "alignment": "CENTER",
             "font_name": "Arial",
             "font_size": 14.0,
             "bold": true,
             "color": "FF0000"
           }
         ]
       }
     }
   }
   ```
   
   **Key features**:
   - **Slides**: Named as "slide-0", "slide-1", etc.
   - **Shapes**: Ordered by visual position (top-to-bottom, left-to-right)
   - **Placeholder types**: TITLE, CENTER_TITLE, SUBTITLE, BODY, OBJECT, or null
   - **Slide numbers are filtered**: Shapes with SLIDE_NUMBER placeholder type are excluded
   - **Bullets**: When `bullet: true`, `level` is always included (even if 0)

6. **Generate replacement text and save to JSON file**:
   - **CRITICAL**: First verify which shapes exist in the inventory
   - **VALIDATION**: The replace.py script will validate shapes in replacement JSON exist
   - **AUTOMATIC CLEARING**: ALL text shapes from inventory will be cleared unless you provide "paragraphs"
   - Add a "paragraphs" field to shapes that need content
   - **IMPORTANT**: When bullet: true, do NOT include bullet symbols (•, -, *) in text - they're added automatically
   - **ESSENTIAL FORMATTING RULES**:
     - Headers/titles should typically have `"bold": true`
     - List items should have `"bullet": true, "level": 0`
     - Preserve any alignment properties (e.g., `"alignment": "CENTER"`)
     - Include font properties when different from default
     - Colors: Use `"color": "FF0000"` for RGB or `"theme_color": "DARK_1"` for theme colors
   
   **Example replacement JSON**:
   ```json
   {
     "slide-0": {
       "shape-0": {
         "paragraphs": [
           { "text": "New presentation title", "alignment": "CENTER", "bold": true },
           { "text": "Section Header", "bold": true },
           { "text": "First bullet point", "bullet": true, "level": 0 },
           { "text": "Red colored text", "color": "FF0000" }
         ]
       }
     }
   }
   ```

7. **Apply replacements using the `replace.py` script**:
   ```bash
   python scripts/replace.py working.pptx replacement-text.json output.pptx
   ```
   
   The script will:
   - Extract the inventory of ALL text shapes
   - Validate shapes in replacement JSON exist in inventory
   - Clear text from ALL shapes identified in inventory
   - Apply new text only to shapes with "paragraphs" defined
   - Preserve formatting by applying paragraph properties from JSON

---

## Creating Thumbnail Grids

To create visual thumbnail grids of PowerPoint slides for quick analysis:

```bash
python scripts/thumbnail.py presentation.pptx [output_prefix]
```

**Features**:
- Creates: `thumbnails.jpg` (or `thumbnails-1.jpg`, `thumbnails-2.jpg`, etc. for large decks)
- Default: 5 columns, max 30 slides per grid (5×6)
- Custom prefix: `python scripts/thumbnail.py presentation.pptx my-grid`
- Adjust columns: `--cols 4` (range: 3-6, affects slides per grid)
- Grid limits: 3 cols = 12 slides/grid, 4 cols = 20, 5 cols = 30, 6 cols = 42
- Slides are zero-indexed (Slide 0, Slide 1, etc.)

**Use cases**:
- Template analysis: Quickly understand slide layouts and design patterns
- Content review: Visual overview of entire presentation
- Navigation reference: Find specific slides by their visual appearance
- Quality check: Verify all slides are properly formatted

**Examples**:
```bash
# Basic usage
python scripts/thumbnail.py presentation.pptx

# Custom name with 4 columns
python scripts/thumbnail.py template.pptx analysis --cols 4
```

---

## Converting Slides to Images

To visually analyze PowerPoint slides, convert them to images:

1. **Convert PPTX to PDF**:
   ```bash
   soffice --headless --convert-to pdf presentation.pptx
   ```

2. **Convert PDF pages to JPEG images**:
   ```bash
   pdftoppm -jpeg -r 150 presentation.pdf slide
   ```
   Creates files like `slide-1.jpg`, `slide-2.jpg`, etc.

**Options**:
- `-r 150`: Sets resolution to 150 DPI (adjust for quality/size balance)
- `-jpeg`: Output JPEG format (use `-png` for PNG)
- `-f N`: First page to convert
- `-l N`: Last page to convert
- `slide`: Prefix for output files

**Example for specific range**:
```bash
pdftoppm -jpeg -r 150 -f 2 -l 5 presentation.pdf slide  # Converts only pages 2-5
```

---

## Code Style Guidelines

**IMPORTANT**: When generating code for PPTX operations:
- Write concise code
- Avoid verbose variable names and redundant operations
- Avoid unnecessary print statements

---

## Dependencies

| Dependency | Installation |
|------------|--------------|
| markitdown | `pip install "markitdown[pptx]"` |
| pptxgenjs | `npm install -g pptxgenjs` |
| playwright | `npm install -g playwright` |
| react-icons | `npm install -g react-icons react react-dom` |
| sharp | `npm install -g sharp` |
| LibreOffice | `sudo apt-get install libreoffice` |
| Poppler | `sudo apt-get install poppler-utils` |
| defusedxml | `pip install defusedxml` |

---

## Key Scripts Reference

| Script | Purpose |
|--------|---------|
| `html2pptx.js` | Convert HTML slides to PowerPoint |
| `thumbnail.py` | Generate visual thumbnail grids |
| `inventory.py` | Extract all text shapes from PPTX |
| `replace.py` | Replace text in presentations |
| `rearrange.py` | Duplicate/reorder/delete slides |
| `unpack.py` | Unpack PPTX to XML files |
| `pack.py` | Pack XML files back to PPTX |
| `validate.py` | Validate XML structure |

**Script Locations**:
- Scripts are located at `scripts/pptx/` or `skills/pptx/scripts/` relative to project root
- If scripts don't exist at expected paths, use `find . -name "scriptname.py"` to locate

---

## Best Practices

### Presentation Creation
- Always read html2pptx.md completely before creating new presentations
- Choose color palette based on content subject matter
- Maintain visual hierarchy through size, weight, and color contrast
- Keep slides concise - avoid more than 100 words per slide
- Use asymmetric layouts for visual interest

### Template Workflow
- Always create and save template inventory before using templates
- Match layout structure to actual content (don't force content into wrong layouts)
- Verify slide indices are within range before applying template mapping
- Preserve original formatting properties when replacing text

### Editing Workflow
- Always read ooxml.md completely before editing XML
- Unpack before editing and validate after each edit
- Analyze theme and typography from example presentations

## Common Issues

### HTML to PPTX Conversion Issues
**Issue**: Slides don't render correctly

**Solution**:
- Ensure HTML dimensions match target aspect ratio (e.g., 720pt × 405pt for 16:9)
- Rasterize gradients and icons as PNG images before referencing in HTML
- Check that all web-safe fonts are used
- Generate thumbnail grid to visually inspect for layout issues

### Template Replacement Issues
**Issue**: Text not appearing or wrong formatting

**Solution**:
- Verify shape names in replacement JSON match inventory exactly
- Include all required paragraph properties (bold, alignment, color)
- Remember bullet symbols are added automatically - don't include in text
- Shapes without "paragraphs" will be cleared automatically

### Validation Errors After Edit
**Issue**: PPTX won't open after XML editing

**Solution**:
- Run validate.py immediately after each edit
- Check XML element order and structure
- Ensure all required attributes are present
- Compare with original file structure

## Verification Commands

```bash
# Extract text to verify content
python -m markitdown presentation.pptx

# Generate thumbnails for visual review
python scripts/thumbnail.py presentation.pptx

# Unpack to inspect XML structure
python scripts/pptx/unpack.py presentation.pptx unpacked/
ls unpacked/ppt/slides/

# Validate after XML edits
python scripts/pptx/validate.py unpacked/ --original presentation.pptx
```

**Verification Checklist**:
- [ ] Presentation opens in PowerPoint/LibreOffice without errors
- [ ] All slides render correctly with proper layout
- [ ] Text is readable with sufficient contrast
- [ ] Charts and tables display properly
- [ ] Images appear in correct positions
- [ ] Color palette is consistent across all slides
- [ ] Font styles are consistent throughout
