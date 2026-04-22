---
name: xlsx-specialist-skill
description: "Use this skill whenever a spreadsheet file is the primary input or output. This means any task where you want to: open, read, edit, or fix an existing .xlsx, .xlsm, .csv, or .tsv file (e.g., adding columns, computing formulas, formatting, charting, cleaning messy data); create a new spreadsheet from scratch or from other data sources; or convert between tabular file formats. Trigger especially when you reference a spreadsheet file by name or path — even casually (like \"the xlsx in my downloads\") — and want something done to it or produced from it. Also trigger for cleaning or restructuring messy tabular data files (malformed rows, misplaced headers, junk data) into proper spreadsheets. The deliverable must be a spreadsheet file. Do NOT trigger when the primary deliverable is a Word document, HTML report, standalone Python script, database pipeline, or Google Sheets API integration, even if tabular data is involved."
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: spreadsheet-generation
---

## What I do

- Create, edit, and manipulate Excel spreadsheets (.xlsx, .xlsm) and other tabular formats (.csv, .tsv)
- Build financial models with industry-standard color coding, number formatting, and formula construction
- Recalculate all formulas using LibreOffice and verify zero Excel errors (#REF!, #DIV/0!, #VALUE!, #N/A, #NAME?)
- Analyze data with pandas and build spreadsheets with openpyxl for complex formatting and formulas
- Convert between tabular file formats while preserving data integrity
- Clean and restructure messy tabular data into properly formatted spreadsheets

## When to use me

Use me when you need to work with spreadsheet files as the primary deliverable:

- **Creating spreadsheets**: Build new Excel files from scratch or convert other data sources (JSON, CSV, databases) to .xlsx
- **Editing spreadsheets**: Modify existing .xlsx files (add columns, compute formulas, apply formatting, create charts, clean data)
- **Financial modeling**: Build professional financial models with proper color coding (blue=hardcoded, black=formulas, green=cross-sheet, red=external, yellow=assumptions)
- **Formula verification**: Recalculate and verify all formulas work correctly with zero errors
- **Data analysis**: Read and analyze Excel data with pandas for statistics, filtering, transformations
- **Data cleaning**: Fix malformed rows, misplaced headers, junk data in tabular files
- **Format conversion**: Convert between .xlsx, .xlsm, .csv, .tsv formats

Do NOT use me when the primary deliverable is:
- Word documents (.docx)
- PDFs
- HTML reports
- Standalone Python scripts
- Database pipelines
- Google Sheets API integration (even if tabular data is involved)

## Prerequisites

### Required Tools

- **LibreOffice** (for formula recalculation)
  - Automatically configured on first run of `scripts/recalc.py`
  - Works in sandboxed environments with Unix socket restrictions

### Python Libraries

- **openpyxl**: For creating, reading, and editing Excel files with formulas and formatting
- **pandas**: For data analysis, bulk operations, and simple data export

Install dependencies:
```bash
pip install openpyxl pandas
```

### LibreOffice Configuration

The `scripts/recalc.py` script automatically:
1. Sets up LibreOffice macro for formula recalculation on first run
2. Handles sandboxed environments with Unix socket restrictions
3. Works on both Linux and macOS

## Steps

### Step 1: Choose the Right Tool

- **Use pandas** for data analysis, bulk operations, and simple data export
- **Use openpyxl** for complex formatting, formulas, and Excel-specific features

### Step 2: Create or Load the Spreadsheet

#### Creating New Files
```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment

wb = Workbook()
sheet = wb.active
```

#### Loading Existing Files
```python
from openpyxl import load_workbook

wb = load_workbook('existing.xlsx')
sheet = wb.active  # or wb['SheetName'] for specific sheet
```

### Step 3: Add Data and Formulas

**CRITICAL: Use Excel Formulas, Not Hardcoded Values**

Always use Excel formulas so the spreadsheet remains dynamic and updateable.

❌ WRONG - Hardcoding Calculated Values
```python
total = df['Sales'].sum()
sheet['B10'] = total  # Hardcodes 5000
```

✅ CORRECT - Using Excel Formulas
```python
sheet['B10'] = '=SUM(B2:B9)'
```

Add formulas:
```python
sheet['B2'] = '=(C4-C2)/C2'      # Growth rate
sheet['C5'] = '=AVERAGE(D2:D19)'   # Average
sheet['D10'] = '=SUM(A1:A10)'      # Sum
```

### Step 4: Apply Formatting

#### Professional Font
Use a consistent, professional font:
```python
from openpyxl.styles import Font

sheet['A1'].font = Font(name='Arial', size=11)
```

#### Financial Model Color Coding

Apply industry-standard color conventions:
```python
from openpyxl.styles import Font, PatternFill

# Blue text (RGB: 0,0,255): Hardcoded inputs
sheet['B5'].font = Font(color='0000FF')

# Black text (RGB: 0,0,0): ALL formulas and calculations
sheet['B6'].font = Font(color='000000')

# Green text (RGB: 0,128,0): Links from other worksheets
sheet['C10'].font = Font(color='008000')

# Red text (RGB: 255,0,0): External links to other files
sheet['D15'].font = Font(color='FF0000')

# Yellow background (RGB: 255,255,0): Key assumptions
sheet['E20'].fill = PatternFill('solid', start_color='FFFF00')
```

#### Number Formatting

**Years**: Format as text strings (e.g., "2024" not "2,024")

**Currency**: Use `$#,##0` format, specify units in headers ("Revenue ($mm)"):
```python
# Apply custom number format
sheet['B10'].number_format = '$#,##0;($#,##0);-'

# For zeros, use number format to display as "-"
sheet['B15'].number_format = '$#,##0;($#,##0);-'
```

**Percentages**: Default to 0.0% format (one decimal):
```python
sheet['C5'].number_format = '0.0%'
```

**Multiples**: Format as 0.0x for valuation multiples (EV/EBITDA, P/E):
```python
sheet['D20'].number_format = '0.0x'
```

**Negative numbers**: Use parentheses `(123)` not minus `-123`:
```python
sheet['E10'].number_format = '#,##0;(#,##0)'
```

### Step 5: Formula Construction Rules

#### Assumptions Placement
Place ALL assumptions (growth rates, margins, multiples, etc.) in separate assumption cells. Use cell references instead of hardcoded values in formulas.

Example:
```python
# WRONG: =B5*1.05
sheet['C5'] = '=B5*1.05'  # Hardcoded growth rate

# CORRECT: =B5*(1+$B$6)  where B6 contains 0.05
sheet['C5'] = '=B5*(1+$B$6)'  # References assumption cell
```

#### Documentation for Hardcodes
Comment or note beside cells with hardcoded values:

Format: "Source: [System/Document], [Date], [Specific Reference], [URL if applicable]"

Examples:
- "Source: Company 10-K, FY2024, Page 45, Revenue Note, [SEC EDGAR URL]"
- "Source: Company 10-Q, Q2 2025, Exhibit 99.1, [SEC EDGAR URL]"
- "Source: Bloomberg Terminal, 8/15/2025, AAPL US Equity"
- "Source: FactSet, 8/20/2025, Consensus Estimates Screen"

### Step 6: Save the Spreadsheet

```python
wb.save('output.xlsx')
```

### Step 7: Recalculate Formulas (MANDATORY IF USING FORMULAS)

Excel files created or modified by openpyxl contain formulas as strings but not calculated values. Use the `scripts/recalc.py` script to recalculate formulas:

```bash
python scripts/xlsx-specialist-skill/scripts/recalc.py output.xlsx 30
```

The script:
- Automatically sets up LibreOffice macro on first run
- Recalculates all formulas in all sheets
- Scans ALL cells for Excel errors (#REF!, #DIV/0!, #VALUE!, #NAME?, #NULL!, #NUM!, #N/A)
- Returns JSON with detailed error locations and counts
- Works on both Linux and macOS

### Step 8: Verify and Fix Any Errors

Interpret the script output:

```json
{
  "status": "success",           // or "errors_found"
  "total_errors": 0,              // Total error count
  "total_formulas": 42,           // Number of formulas in file
  "error_summary": {              // Only present if errors found
    "#REF!": {
      "count": 2,
      "locations": ["Sheet1!B5", "Sheet1!C10"]
    }
  }
}
```

If `status` is `"errors_found"`:
1. Check `error_summary` for specific error types and locations
2. Fix identified errors:
   - `#REF!`: Invalid cell references
   - `#DIV/0!`: Division by zero
   - `#VALUE!`: Wrong data type in formula
   - `#NAME?`: Unrecognized formula name
3. Recalculate again until `status` is `"success"` and `total_errors` is 0

### Step 9: Final Verification

Use the Formula Verification Checklist:

#### Essential Verification
- [ ] **Test 2-3 sample references**: Verify they pull correct values before building full model
- [ ] **Column mapping**: Confirm Excel columns match (e.g., column 64 = BL, not BK)
- [ ] **Row offset**: Remember Excel rows are 1-indexed (DataFrame row 5 = Excel row 6)

#### Common Pitfalls
- [ ] **NaN handling**: Check for null values with `pd.notna()`
- [ ] **Far-right columns**: FY data often in columns 50+
- [ ] **Multiple matches**: Search all occurrences, not just first
- [ ] **Division by zero**: Check denominators before using `/` in formulas (#DIV/0!)
- [ ] **Wrong references**: Verify all cell references point to intended cells (#REF!)
- [ ] **Cross-sheet references**: Use correct format (Sheet1!A1) for linking sheets

#### Formula Testing Strategy
- [ ] **Start small**: Test formulas on 2-3 cells before applying broadly
- [ ] **Verify dependencies**: Check all cells referenced in formulas exist
- [ ] **Test edge cases**: Include zero, negative, and very large values

## Best Practices

### Library Selection

| Task | Recommended Library | Why |
|------|---------------------|-----|
| Data analysis, bulk operations, simple export | **pandas** | Powerful data manipulation, easy to use |
| Complex formatting, formulas, Excel-specific features | **openpyxl** | Preserves formulas, supports styling |

### Working with openpyxl

- Cell indices are 1-based (row=1, column=1 refers to cell A1)
- Use `data_only=True` to read calculated values: `load_workbook('file.xlsx', data_only=True)`
- **Warning**: If opened with `data_only=True` and saved, formulas are replaced with values and permanently lost
- For large files: Use `read_only=True` for reading or `write_only=True` for writing
- Formulas are preserved but not evaluated - use `scripts/recalc.py` to update values

### Working with pandas

- Specify data types to avoid inference issues: `pd.read_excel('file.xlsx', dtype={'id': str})`
- For large files, read specific columns: `pd.read_excel('file.xlsx', usecols=['A', 'C', 'E'])`
- Handle dates properly: `pd.read_excel('file.xlsx', parse_dates=['date_column'])`

### Preserve Existing Templates

When updating templates:
- Study and EXACTLY match existing format, style, and conventions
- Never impose standardized formatting on files with established patterns
- Existing template conventions ALWAYS override these guidelines

## Common Issues

### LibreOffice Not Installed

**Error**: Failed to setup LibreOffice macro

**Solution**: Install LibreOffice:
```bash
# Linux (Ubuntu/Debian)
sudo apt-get install libreoffice

# macOS
brew install --cask libreoffice
```

### Sandbox Environment Issues

**Symptom**: LibreOffice fails to start or macro doesn't work

**Solution**: The script automatically handles sandboxed environments with Unix socket restrictions. Ensure you're using the latest version of the script that includes sandbox detection from `scripts/office/soffice.py`.

### Formula Errors After Recalculation

**Common Errors**:
- `#REF!`: Invalid cell references - check for deleted cells/rows/columns
- `#DIV/0!`: Division by zero - add checks for zero denominators
- `#VALUE!`: Wrong data type - ensure cells referenced in formulas contain correct types
- `#NAME?`: Unrecognized formula name - check for typos in formula names

**Solution**: Use the error locations from `scripts/recalc.py` output to identify and fix specific cells.

### Formulas Not Calculating

**Symptom**: Formulas show as text strings (e.g., "=SUM(A1:A10)") instead of calculated values

**Solution**: Always run `scripts/recalc.py` after saving the file to calculate formula values.

### Performance Issues with Large Files

**Symptom**: Slow processing of large Excel files

**Solution**:
- Use `read_only=True` when reading: `load_workbook('large.xlsx', read_only=True)`
- Use `write_only=True` when writing: `Workbook(write_only=True)`
- For pandas: Read specific columns with `usecols` parameter

## Verification Commands

After completing your spreadsheet work:

```bash
# Recalculate formulas and check for errors
python scripts/xlsx-specialist-skill/scripts/recalc.py output.xlsx

# Verify file exists
ls -lh output.xlsx

# Open in LibreOffice for manual review (if needed)
soffice output.xlsx
```
