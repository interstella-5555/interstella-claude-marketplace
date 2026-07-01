# The Complete Guide to Building Skills for Claude

Source: Anthropic official PDF guide (33 pages). Converted to markdown for reference.

---

## Introduction

A skill is a set of instructions — packaged as a simple folder — that teaches Claude how to handle specific tasks or workflows. Skills are one of the most powerful ways to customize Claude for your specific needs. Instead of re-explaining your preferences, processes, and domain expertise in every conversation, skills let you teach Claude once and benefit every time.

Skills are powerful when you have repeatable workflows: generating frontend designs from specs, conducting research with consistent methodology, creating documents that follow your team's style guide, or orchestrating multi-step processes.

**Two Paths Through This Guide:**
- Building standalone skills? Focus on Fundamentals, Planning and Design, and category 1-2.
- Enhancing an MCP integration? The "Skills + MCP" section and category 3 are for you.

**What you'll learn:**
- Technical requirements and best practices for skill structure
- Patterns for standalone skills and MCP-enhanced workflows
- Patterns we've seen work well across different use cases
- How to test, iterate, and distribute your skills

**Who this is for:**
- Developers who want Claude to follow specific workflows consistently
- Power users who want Claude to follow specific workflows
- Teams looking to standardize how Claude works across their organization

---

## Chapter 1: Fundamentals

### What is a skill?

A skill is a folder containing:
- **SKILL.md** (required): Instructions in Markdown with YAML frontmatter
- **scripts/** (optional): Executable code (Python, Bash, etc.)
- **references/** (optional): Documentation loaded as needed
- **assets/** (optional): Templates, fonts, icons used in output

### Core Design Principles

#### Progressive Disclosure

Skills use a three-level system:
- **First level (YAML frontmatter):** Always loaded in Claude's system prompt. Provides just enough information for Claude to know when each skill should be used without loading all of it into context.
- **Second level (SKILL.md body):** Loaded when Claude thinks the skill is relevant to the current task. Contains the full instructions and guidance.
- **Third level (Linked files):** Additional files bundled within the skill directory that Claude can choose to navigate and discover only as needed.

This progressive disclosure minimizes token usage while maintaining specialized expertise.

#### Composability

Claude can load multiple skills simultaneously. Your skill should work well alongside others, not assume it's the only capability available.

#### Portability

Skills work identically across Claude.ai, Claude Code, and API. Create a skill once and it works across all surfaces without modification, provided the environment supports any dependencies the skill requires.

### For MCP Builders: Skills + Connectors

If you already have a working MCP server, you've done the hard part. Skills are the knowledge layer on top — capturing the workflows and best practices you already know, so Claude can apply them consistently.

**The kitchen analogy:**
- **MCP provides the professional kitchen:** access to tools, ingredients, and equipment.
- **Skills provide the recipes:** step-by-step instructions on how to create something valuable.

Together, they enable users to accomplish complex tasks without needing to figure out every step themselves.

| MCP (Connectivity) | Skills (Knowledge) |
|---|---|
| Connects Claude to your service (Notion, Asana, Linear, etc.) | Teaches Claude how to use your service effectively |
| Provides real-time data access and tool invocation | Captures workflows and best practices |
| What Claude can do | How Claude should do it |

### Why this matters for your MCP users

**Without skills:**
- Users connect your MCP but don't know what to do next
- Support tickets asking "how do I do X with your integration"
- Each conversation starts from scratch
- Inconsistent results because users prompt differently each time
- Users blame your connector when the real issue is workflow guidance

**With skills:**
- Pre-built workflows activate automatically when needed
- Consistent, reliable tool usage
- Best practices embedded in every interaction
- Lower learning curve for your integration

---

## Chapter 2: Planning and Design

### Start with use cases

Before writing any code, identify 2-3 concrete use cases your skill should enable.

**Good use case definition:**
```
Use Case: Project Sprint Planning
Trigger: User says "help me plan this sprint" or "create sprint tasks"
Steps:
1. Fetch current project status from Linear (via MCP)
2. Analyze team velocity and capacity
3. Suggest task prioritization
4. Create tasks in Linear with proper labels and estimates
Result: Fully planned sprint with tasks created
```

**Ask yourself:**
- What does a user want to accomplish?
- What multi-step workflows does this require?
- Which tools are needed (built-in or MCP?)
- What domain knowledge or best practices should be embedded?

### Common skill use case categories

#### Category 1: Document & Asset Creation
Used for: Creating consistent, high-quality output including documents, presentations, apps, designs, code, etc.

Key techniques:
- Embedded style guides and brand standards
- Template structures for consistent output
- Quality checklists before finalizing
- No external tools required — uses Claude's built-in capabilities

#### Category 2: Workflow Automation
Used for: Multi-step processes that benefit from consistent methodology, including coordination across multiple MCP servers.

Key techniques:
- Step-by-step workflow with validation gates
- Templates for common structures
- Built-in review and improvement suggestions
- Iterative refinement loops

#### Category 3: MCP Enhancement
Used for: Workflow guidance to enhance the tool access an MCP server provides.

Key techniques:
- Coordinates multiple MCP calls in sequence
- Embeds domain expertise
- Provides context users would otherwise need to specify
- Error handling for common MCP issues

### Define success criteria

**Quantitative metrics:**
- Skill triggers on 90% of relevant queries
- Completes workflow in X tool calls
- 0 failed API calls per workflow

**Qualitative metrics:**
- Users don't need to prompt Claude about next steps
- Workflows complete without user correction
- Consistent results across sessions

### Technical requirements

#### File structure

```
your-skill-name/
├── SKILL.md                    # Required — main skill file
├── scripts/                    # Optional — executable code
│   ├── process_data.py
│   └── validate.sh
├── references/                 # Optional — documentation
│   ├── api-guide.md
│   └── examples/
└── assets/                     # Optional — templates, etc.
    └── report-template.md
```

#### Critical rules

**SKILL.md naming:** Must be exactly `SKILL.md` (case-sensitive). No variations accepted (SKILL.MD, skill.md, etc.)

**Skill folder naming:** Use kebab-case only.
- ✅ `notion-project-setup`
- ❌ `Notion Project Setup` (spaces)
- ❌ `notion_project_setup` (underscores)
- ❌ `NotionProjectSetup` (capitals)

**No README.md:** Don't include README.md inside your skill folder. All documentation goes in SKILL.md or references/. Note: when distributing via GitHub, you'll still want a repo-level README for human users.

#### YAML frontmatter: The most important part

The YAML frontmatter is how Claude decides whether to load your skill. Get this right.

**Minimal required format:**
```yaml
---
name: your-skill-name
description: What it does. Use when user asks to [specific phrases].
---
```

**name (required):**
- kebab-case only
- No spaces or capitals
- Should match folder name

**description (required):**
- MUST include BOTH: what the skill does AND when to use it (trigger conditions)
- Under 1024 characters
- No XML tags (< or >)
- Include specific tasks users might say
- Mention file types if relevant

**Structure:** `[What it does] + [When to use it] + [Key capabilities]`

**Optional fields:**

**license:** MIT, Apache-2.0, etc.

**compatibility:** Indicates environment requirements (1-500 characters).

**metadata:** Any custom key-value pairs. Suggested: author, version, mcp-server.

**Security restrictions:**
- XML angle brackets (< >) — security restriction
- Code execution in YAML (uses safe YAML parsing)
- Skills named with "claude" or "anthropic" prefix (reserved)

### Writing effective skills

#### The description field

Structure: `[What it does] + [When to use it] + [Key capabilities]`

Good examples:
```yaml
# Good — specific and actionable
description: Analyzes Figma design files and generates developer handoff documentation. Use when user uploads .fig files, asks for "design specs", "component documentation", or "design-to-code handoff".

# Good — includes trigger phrases
description: Manages Linear project workflows including sprint planning, task creation, and status tracking. Use when user mentions "sprint", "Linear tasks", "project planning", or asks to "create tickets".

# Good — clear value proposition
description: End-to-end customer onboarding workflow for PayFlow. Handles account creation, payment setup, and subscription management. Use when user says "onboard new customer", "set up subscription", or "create PayFlow account".
```

Bad examples:
```yaml
# Too vague
description: Helps with projects.

# Missing triggers
description: Creates sophisticated multi-page documentation systems.

# Too technical, no user triggers
description: Implements the Project entity model with hierarchical relationships.
```

#### Writing the main instructions

Recommended structure (adapt to your skill):
```yaml
---
name: your-skill
description: [...]
---

# Your Skill Name

## Instructions

### Step 1: [First Major Step]
Clear explanation of what happens.

Example:
```bash
python scripts/fetch_data.py --project-id PROJECT_ID
Expected output: [describe what success looks like]
```

### Step 2: [Next Step]
...
```

#### Best Practices for Instructions

**Be Specific and Actionable:**
```
✅ Good:
Run `python scripts/validate.py --input {filename}` to check data format.
If validation fails, common issues include:
- Missing required fields (add them to the CSV)
- Invalid date formats (use YYYY-MM-DD)

❌ Bad:
Validate the data before proceeding.
```

**Include error handling:**
```markdown
## Common Issues

### MCP Connection Failed
If you see "Connection refused":
1. Verify MCP server is running: Check Settings > Extensions
2. Confirm API key is valid
3. Try reconnecting: Settings > Extensions > [Your Service] > Reconnect
```

**Reference bundled resources clearly:**
```
Before writing queries, consult `references/api-patterns.md` for:
- Rate limiting guidance
- Pagination patterns
- Error codes and handling
```

**Use progressive disclosure:** Keep SKILL.md focused on core instructions. Move detailed documentation to `references/` and link to it.

---

## Chapter 3: Testing and Iteration

Skills can be tested at varying levels of rigor:

- **Manual testing in Claude.ai** — Run queries directly and observe behavior. Fast iteration, no setup required.
- **Scripted testing in Claude Code** — Automate test cases for repeatable validation across changes.
- **Programmatic testing via skills API** — Build evaluation suites that run systematically against defined test sets.

**Pro Tip:** Iterate on a single task before expanding. The most effective skill creators iterate on a single challenging task until Claude succeeds, then extract the winning approach into a skill.

### Recommended Testing Approach

#### 1. Triggering tests
**Goal:** Ensure your skill loads at the right times.

Test cases:
- ✅ Triggers on obvious tasks
- ✅ Triggers on paraphrased requests
- ❌ Doesn't trigger on unrelated topics

#### 2. Functional tests
**Goal:** Verify the skill produces correct outputs.

Test cases:
- Valid outputs generated
- API calls succeed
- Error handling works
- Edge cases covered

#### 3. Performance comparison
**Goal:** Prove the skill improves results vs. baseline.

Compare with and without skill:
- Number of messages needed
- Tool call count
- Token consumption
- Failed API calls

### Using the skill-creator skill

The `skill-creator` skill — available in Claude.ai via plugin directory or download for Claude Code — can help you build and iterate on skills.

**Creating skills:** Generate from natural language descriptions, produce properly formatted SKILL.md with frontmatter, suggest trigger phrases and structure.

**Reviewing skills:** Flag common issues (vague descriptions, missing triggers, structural problems), identify potential over/under-triggering risks, suggest test cases.

**Iterative improvement:** After using your skill and encountering edge cases or failures, bring those examples back to skill-creator. Example: "Use the issues & solution identified in this chat to improve how the skill handles [specific edge case]"

### Iteration based on feedback

Skills are living documents. Plan to iterate based on:

**Undertriggering signals:**
- Skill doesn't load when it should
- Users manually enabling it
- Support questions about when to use it
- **Solution:** Add more detail and nuance to the description — this may include keywords particularly for technical terms

**Overtriggering signals:**
- Skill loads for irrelevant queries
- Users disabling it
- Confusion about purpose
- **Solution:** Add negative triggers, be more specific

**Execution issues:**
- Inconsistent results
- API call failures
- User corrections needed
- **Solution:** Improve instructions, add error handling

---

## Chapter 4: Distribution and Sharing

Skills make your MCP integration more complete. As users compare connectors, those with skills offer a faster path to value, giving you an edge over MCP-only alternatives.

### Current distribution model (January 2026)

**How individual users get skills:**
1. Download the skill folder
2. Zip the folder (if needed)
3. Upload to Claude.ai via Settings > Capabilities > Skills
4. Or place in Claude Code skills directory

**Organization-level skills:**
- Admins can deploy skills workspace-wide (shipped December 18, 2025)
- Automatic updates
- Centralized management

### An open standard

Agent Skills is published as an open standard. Like MCP, skills should be portable across tools and platforms — the same skill should work whether you're using Claude or other AI platforms. Authors can note platform-specific capabilities in the `compatibility` field.

### Using skills via API

For programmatic use cases — such as building applications, agents, or automated workflows that leverage skills — the API provides direct control over skill management and execution.

Key capabilities:
- `/v1/skills` endpoint for listing and managing skills
- Add skills to Messages API requests via the `container.skills` parameter
- Version control and management through the Claude Console
- Works with the Claude Agent SDK for building custom agents

| Use Case | Best Surface |
|---|---|
| End users interacting with skills directly | Claude.ai / Claude Code |
| Manual testing and iteration during development | Claude.ai / Claude Code |
| Individual, ad-hoc workflows | Claude.ai / Claude Code |
| Applications using skills programmatically | API |
| Production deployments at scale | API |
| Automated pipelines and agent systems | API |

### Positioning your skill

Focus on outcomes, not features:
```
✅ Good:
"The ProjectHub skill enables teams to set up complete project workspaces in seconds — including pages, databases, and templates — instead of spending 30 minutes on manual setup."

❌ Bad:
"The ProjectHub skill is a folder containing YAML frontmatter and Markdown instructions that calls our MCP server tools."
```

Highlight the MCP + skills story:
```
"Our MCP server gives Claude access to your Linear projects. Our skills teach Claude your team's sprint planning workflow. Together, they enable AI-powered project management."
```

---

## Chapter 5: Patterns and Troubleshooting

These patterns emerged from skills created by early adopters and internal teams. They represent common approaches we've seen work well, not prescriptive templates.

### Choosing your approach: Problem-first vs. tool-first

- **Problem-first:** "I need to set up a project workspace" → Your skill orchestrates the right MCP calls in the right sequence. Users describe outcomes; the skill handles the tools.
- **Tool-first:** "I have Notion MCP connected" → Your skill teaches Claude the optimal workflows and best practices. Users have access; the skill provides expertise.

### Pattern 1: Sequential workflow orchestration
**Use when:** Your users need multi-step processes in a specific order.

Key techniques: Explicit step ordering, dependencies between steps, validation at each stage, rollback instructions for failures.

### Pattern 2: Multi-MCP coordination
**Use when:** Workflows span multiple services.

Example: Design-to-development handoff across Figma → Drive → Linear → Slack MCPs.

Key techniques: Clear phase separation, data passing between MCPs, validation before moving to next phase, centralized error handling.

### Pattern 3: Iterative refinement
**Use when:** Output quality improves with iteration.

Key techniques: Explicit quality criteria, iterative improvement, validation scripts, know when to stop iterating.

### Pattern 4: Context-aware tool selection
**Use when:** Same outcome, different tools depending on context.

Key techniques: Clear decision criteria, fallback options, transparency about choices.

### Pattern 5: Domain-specific intelligence
**Use when:** Your skill adds specialized knowledge beyond tool access.

Key techniques: Domain expertise embedded in logic, compliance before action, comprehensive documentation, clear governance.

### Troubleshooting

#### Skill won't upload
- **"Could not find SKILL.md":** Rename to exactly SKILL.md (case-sensitive)
- **"Invalid frontmatter":** Check YAML formatting — use `---` delimiters, no unclosed quotes
- **"Invalid skill name":** Name has spaces or capitals — use kebab-case

#### Skill doesn't trigger
- Revise description field — is it too generic? Include trigger phrases users would actually say.
- Debugging: Ask Claude "When would you use the [skill name] skill?" and adjust based on what's missing.

#### Skill triggers too often
1. Add negative triggers in description
2. Be more specific about scope
3. Clarify scope with explicit boundaries

#### Instructions not followed
1. **Instructions too verbose** — keep concise, use bullet points
2. **Instructions buried** — put critical instructions at the top, use ## Important headers
3. **Ambiguous language** — be specific and actionable
4. **Model "laziness"** — add explicit encouragement: "Take your time", "Quality is more important than speed"

#### MCP connection issues
1. Verify MCP server is connected
2. Check authentication (API keys, OAuth tokens)
3. Test MCP independently (without skill)
4. Verify tool names are correct (case-sensitive, fully qualified)

#### Large context issues
**Causes:** Skill content too large, too many skills enabled simultaneously, all content loaded instead of progressive disclosure.

**Solutions:**
1. Optimize SKILL.md size — move docs to references/, keep under 5,000 words
2. Reduce enabled skills — evaluate if 20-50 skills are all needed simultaneously

---

## Reference A: Quick checklist

### Before you start
- [ ] Identified 2-3 concrete use cases
- [ ] Tools identified (built-in or MCP)
- [ ] Reviewed this guide and example skills
- [ ] Planned folder structure

### During development
- [ ] Folder named in kebab-case
- [ ] SKILL.md file exists (exact spelling)
- [ ] YAML frontmatter has `---` delimiters
- [ ] name field: kebab-case, no spaces, no capitals
- [ ] description includes WHAT and WHEN
- [ ] No XML tags (< >) anywhere
- [ ] Instructions are clear and actionable
- [ ] Error handling included
- [ ] Examples provided
- [ ] References clearly linked

### Before upload
- [ ] Tested triggering on obvious tasks
- [ ] Tested triggering on paraphrased requests
- [ ] Verified doesn't trigger on unrelated topics
- [ ] Functional tests pass
- [ ] Tool integration works (if applicable)
- [ ] Compressed as .zip file

### After upload
- [ ] Test in real conversations
- [ ] Monitor for under/over-triggering
- [ ] Collect user feedback
- [ ] Iterate on description and instructions
- [ ] Update version in metadata

---

## Reference B: YAML frontmatter

### Required fields
```yaml
---
name: skill-name-in-kebab-case
description: What it does and when to use it. Include specific trigger phrases.
---
```

### All optional fields
```yaml
name: skill-name
description: [required description]
license: MIT # Optional: License for open-source
allowed-tools: "Bash(python:*) Bash(npm:*) WebFetch" # Optional: Restrict tool access
metadata: # Optional: Custom fields
  author: Company Name
  version: 1.0.0
  mcp-server: server-name
  category: productivity
  tags: [project-management, automation]
  documentation: https://example.com/docs
  support: support@example.com
```

### Security notes
**Allowed:** Any standard YAML types, custom metadata fields, long descriptions (up to 1024 chars).
**Forbidden:** XML angle brackets (< >), code execution in YAML, skills named with "claude" or "anthropic" prefix (reserved).

---

## Reference C: Complete skill examples

- Document Skills — PDF, DOCX, PPTX, XLSX creation
- Example Skills — Various workflow patterns
- Partner Skills Directory — Asana, Atlassian, Canva, Figma, Sentry, Zapier, and more

These repositories stay up-to-date and include additional examples beyond what's covered here. Clone them, modify them for your use case, and use them as templates.
