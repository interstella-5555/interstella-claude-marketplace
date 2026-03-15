# Skill Authoring Best Practices

Source: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
Converted to markdown for local reference.

---

## Core Principles

### Concise is Key

The context window is a public good. Your Skill shares it with the system prompt, conversation history, other Skills' metadata, and user requests.

**Default assumption:** Claude is already very smart. Only add context Claude doesn't already have. Challenge each piece of information:
- "Does Claude really need this explanation?"
- "Can I assume Claude knows this?"
- "Does this paragraph justify its token cost?"

**Good example (~50 tokens):**
```markdown
## Extract PDF text
Use pdfplumber for text extraction:
```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

**Bad example (~150 tokens):** Explaining what PDFs are and how libraries work before showing the code.

### Set Appropriate Degrees of Freedom

Match the level of specificity to the task's fragility and variability.

**High freedom** (text-based instructions): Use when multiple approaches are valid, decisions depend on context, heuristics guide the approach. Example: code review process.

**Medium freedom** (pseudocode/scripts with parameters): Use when a preferred pattern exists, some variation is acceptable, configuration affects behavior.

**Low freedom** (specific scripts, few or no parameters): Use when operations are fragile and error-prone, consistency is critical, a specific sequence must be followed. Example: database migrations.

**Analogy:** Think of Claude as a robot on a path:
- **Narrow bridge with cliffs:** One safe way forward → exact instructions (low freedom)
- **Open field:** Many paths to success → general direction (high freedom)

### Test with All Models You Plan to Use

- **Claude Haiku** (fast, economical): Does the Skill provide enough guidance?
- **Claude Sonnet** (balanced): Is the Skill clear and efficient?
- **Claude Opus** (powerful reasoning): Does the Skill avoid over-explaining?

What works for Opus might need more detail for Haiku.

---

## Skill Structure

### YAML Frontmatter

**name:** Max 64 characters, lowercase letters/numbers/hyphens only, no XML tags, no reserved words ("anthropic", "claude").

**description:** Non-empty, max 1024 characters, no XML tags. Should describe what the Skill does and when to use it.

### Naming Conventions

Use **gerund form** (verb + -ing) for Skill names:
- ✅ `processing-pdfs`, `analyzing-spreadsheets`, `managing-databases`
- Also acceptable: `pdf-processing`, `process-pdfs`
- ❌ Avoid: `helper`, `utils`, `tools`, `documents`, `data`

### Writing Effective Descriptions

**Always write in third person.** Description is injected into system prompt.
- ✅ "Processes Excel files and generates reports"
- ❌ "I can help you process Excel files"
- ❌ "You can use this to process Excel files"

**Be specific and include key terms.** Include both what the Skill does and specific triggers/contexts for when to use it.

**Good examples:**
```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.

description: Generate descriptive commit messages by analyzing git diffs. Use when the user asks for help writing commit messages or reviewing staged changes.
```

**Avoid:**
```yaml
description: Helps with documents
description: Processes data
```

### Progressive Disclosure Patterns

SKILL.md serves as an overview that points Claude to detailed materials as needed. Keep SKILL.md body under 500 lines.

#### Pattern 1: High-level guide with references

```markdown
# PDF Processing

## Quick start
[inline code example]

## Advanced features
**Form filling**: See [FORMS.md](FORMS.md) for complete guide
**API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
```

Claude loads FORMS.md or REFERENCE.md only when needed.

#### Pattern 2: Domain-specific organization

```
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md (revenue, billing metrics)
    ├── sales.md (opportunities, pipeline)
    ├── product.md (API usage, features)
    └── marketing.md (campaigns, attribution)
```

When user asks about revenue, Claude reads only `reference/finance.md`.

#### Pattern 3: Conditional details

```markdown
## Creating documents
Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).

## Editing documents
For simple edits, modify the XML directly.
**For tracked changes**: See [REDLINING.md](REDLINING.md)
```

### Avoid Deeply Nested References

**Keep references one level deep from SKILL.md.** Claude may partially read files referenced from other referenced files.

```markdown
# ❌ Bad: SKILL.md → advanced.md → details.md (too deep)
# ✅ Good: SKILL.md → advanced.md, SKILL.md → reference.md (one level)
```

### Structure Longer Files with Table of Contents

For reference files longer than 100 lines, include a table of contents at the top so Claude can see the full scope even when previewing.

---

## Workflows and Feedback Loops

### Use Workflows for Complex Tasks

Break complex operations into clear, sequential steps. For complex workflows, provide a checklist Claude can copy and track:

```markdown
Task Progress:
- [ ] Step 1: Analyze the form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate mapping (run validate_fields.py)
- [ ] Step 4: Fill the form (run fill_form.py)
- [ ] Step 5: Verify output (run verify_output.py)
```

### Implement Feedback Loops

**Common pattern:** Run validator → fix errors → repeat

```markdown
1. Make your edits
2. **Validate immediately**: `python scripts/validate.py`
3. If validation fails: fix issues, run validation again
4. **Only proceed when validation passes**
5. Rebuild and test
```

---

## Content Guidelines

### Avoid Time-Sensitive Information

Use "old patterns" section instead of dates:
```markdown
## Current method
Use the v2 API endpoint

## Old patterns
<details>
<summary>Legacy v1 API (deprecated 2025-08)</summary>
The v1 API used: `api.example.com/v1/messages`
</details>
```

### Use Consistent Terminology

Choose one term and use it throughout:
- ✅ Always "API endpoint" (not mix of "URL", "API route", "path")
- ✅ Always "field" (not mix of "box", "element", "control")
- ✅ Always "extract" (not mix of "pull", "get", "retrieve")

---

## Common Patterns

### Template Pattern

For strict requirements (API responses, data formats) → use exact template with "ALWAYS use this exact structure."

For flexible guidance → use template with "sensible default, adapt as needed."

### Examples Pattern

Provide input/output pairs (like few-shot prompting):
```markdown
Input: Added user authentication with JWT tokens
Output:
feat(auth): implement JWT-based authentication
Add login endpoint and token validation middleware
```

### Conditional Workflow Pattern

Guide through decision points:
```markdown
1. Determine modification type:
   **Creating new content?** → Follow "Creation workflow"
   **Editing existing content?** → Follow "Editing workflow"
```

---

## Evaluation and Iteration

### Build Evaluations First

Create evaluations BEFORE writing extensive documentation:
1. **Identify gaps:** Run Claude on tasks without a Skill. Document failures.
2. **Create evaluations:** Build three scenarios testing these gaps.
3. **Establish baseline:** Measure performance without Skill.
4. **Write minimal instructions:** Just enough to address gaps and pass evaluations.
5. **Iterate:** Execute evaluations, compare against baseline, refine.

### Develop Skills Iteratively with Claude

Work with one Claude instance ("Claude A") to create a Skill used by others ("Claude B"):

1. Complete a task without a Skill — notice what context you repeatedly provide
2. Identify the reusable pattern
3. Ask Claude A to create a Skill capturing that pattern
4. Review for conciseness — remove unnecessary explanations
5. Improve information architecture — organize with separate reference files
6. Test with Claude B on similar tasks
7. Iterate based on observation — bring specific issues back to Claude A

**Why this works:** Claude A understands agent needs, you provide domain expertise, Claude B reveals gaps through real usage.

### Observe How Claude Navigates Skills

Watch for:
- **Unexpected exploration paths** → structure isn't intuitive
- **Missed connections** → links need to be more explicit
- **Overreliance on certain sections** → move that content to main SKILL.md
- **Ignored content** → unnecessary or poorly signaled

---

## Anti-Patterns to Avoid

### Avoid Windows-Style Paths
✅ `scripts/helper.py`
❌ `scripts\helper.py`

### Avoid Offering Too Many Options
```markdown
# ❌ Bad: "You can use pypdf, or pdfplumber, or PyMuPDF, or..."
# ✅ Good: "Use pdfplumber for text extraction.
#          For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."
```

---

## Advanced: Skills with Executable Code

### Solve, Don't Punt

Handle error conditions in scripts rather than leaving Claude to figure it out:
```python
def process_file(path):
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        print(f"File {path} not found, creating default")
        with open(path, "w") as f:
            f.write("")
        return ""
```

Document magic numbers:
```python
# ✅ Good: HTTP requests typically complete within 30 seconds
REQUEST_TIMEOUT = 30
# ❌ Bad: TIMEOUT = 47  # Why 47?
```

### Provide Utility Scripts

Pre-made scripts are more reliable than generated code, save tokens and time, and ensure consistency. Make clear whether Claude should **execute** or **read** the script.

### Use Visual Analysis

When inputs can be rendered as images, have Claude analyze them visually (PDFs → images → visual field detection).

### Create Verifiable Intermediate Outputs

**Plan-validate-execute pattern:** analyze → create plan file → validate plan → execute → verify. Catches errors before changes are applied.

### MCP Tool References

Always use fully qualified tool names: `ServerName:tool_name`
```markdown
Use the BigQuery:bigquery_schema tool to retrieve table schemas.
```

### Package Dependencies

- **claude.ai:** Can install packages from npm and PyPI
- **Claude API:** No network access, no runtime installation

List required packages in SKILL.md.

---

## Checklist for Effective Skills

### Core quality
- [ ] Description is specific and includes key terms
- [ ] Description includes both what and when
- [ ] SKILL.md body under 500 lines
- [ ] Additional details in separate files (if needed)
- [ ] No time-sensitive information
- [ ] Consistent terminology
- [ ] Concrete examples
- [ ] File references one level deep
- [ ] Progressive disclosure used appropriately
- [ ] Workflows have clear steps

### Code and scripts
- [ ] Scripts solve problems rather than punt to Claude
- [ ] Error handling is explicit and helpful
- [ ] No magic numbers (all values justified)
- [ ] Required packages listed and verified
- [ ] No Windows-style paths
- [ ] Validation/verification steps for critical operations
- [ ] Feedback loops for quality-critical tasks

### Testing
- [ ] At least three evaluations created
- [ ] Tested with Haiku, Sonnet, and Opus
- [ ] Tested with real usage scenarios
- [ ] Team feedback incorporated (if applicable)
