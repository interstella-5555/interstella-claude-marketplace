# Boris Cherny — Skill & Claude Code Insights

Unique operational insights from Boris Cherny, Head of Claude Code at Anthropic. These complement the official docs with practical philosophy and patterns derived from building and using Claude Code daily.

**Sources:** Boris's X threads (@bcherny), Lenny's Newsletter interview, Pragmatic Engineer interview, community documentation at howborisusesclaudecode.com.

## Core Philosophy

### Verification is the #1 Force Multiplier

> "Give Claude a way to verify its work... it will 2-3x the quality of the final result."
> "You don't trust; you instrument."

Verification approaches by complexity:
- **Simple tasks:** bash commands to check output
- **Moderate tasks:** test suites
- **Complex UI:** browser testing where Claude navigates, validates, and iterates

**For skills:** Always include validation steps. Bundle validator scripts when possible. Make validation output verbose with specific error messages to help Claude fix issues.

### Plan Mode is Non-Negotiable

> "Pour your energy into the plan so Claude can 1-shot the implementation."

- Start complex sessions in Plan Mode
- Iterate on the plan until solid
- Then switch to auto-accept mode for execution
- Some team members have a second Claude review the plan as a staff engineer before execution

**For skills:** Use workflow patterns with explicit steps and checklists. The "plan-validate-execute" pattern catches errors early.

### Compounding Engineering via CLAUDE.md

- When Claude makes a mistake → add a rule to CLAUDE.md
- During code review → tag `@.claude` on PRs to update CLAUDE.md as part of the PR
- Each correction becomes permanent institutional knowledge

> "Anytime we see Claude do something incorrectly we add it to the CLAUDE.md, so Claude knows not to do it next time."

**For skills:** Same principle applies — when a skill doesn't work as expected, update it. Skills are living documents. Iterate based on observed behavior, not assumptions.

## When to Use What (Skills vs Other Features)

| Feature | Purpose | Use when... |
|---|---|---|
| **CLAUDE.md** | Project-specific rules | Rules that apply to ALL tasks in a project (gotchas, commands, style) |
| **Skills** | Reusable workflows | Repeatable processes across projects (skill-writing, code review, deployments) |
| **Hooks** | Auto-triggered actions | Mechanical enforcement (auto-format on save, lint on commit) |
| **Subagents** | Isolated specialists | Modular roles needing separate context (code-reviewer, build-validator) |
| **Slash commands** | Quick shortcuts | Repetitive sequences you run daily (`/commit-push-pr`, `/test-and-fix`) |

**Key insight:** Don't put workflow instructions in CLAUDE.md — use skills. Don't put project rules in skills — use CLAUDE.md. Each tool has a specific purpose.

## Subagents as Modular Specialists

Boris treats subagents not as "one big agent" but as modular roles. Reliability comes from specialization + constraint.

Known production subagents:
- **code-simplifier** — Reviews recently modified code, reduces complexity (now open-sourced as plugin)
- **verify-app** — End-to-end testing instructions
- **code-architect** — Architecture review
- **build-validator** — Build verification
- **staff-reviewer** — Code review from staff-engineer perspective

**For skills:** When a skill orchestrates complex workflows, consider delegating specific phases to subagents rather than doing everything in one context window.

## Skill Design Principles (Derived from Boris's Practices)

### 1. Solve, Don't Punt
Scripts should handle errors explicitly rather than failing and leaving Claude to figure it out. If a file doesn't exist, create it with defaults. If validation fails, provide specific error messages.

### 2. Pre-compute Context
Use inline bash to gather information (git status, file structure, etc.) so Claude doesn't waste turns exploring. Boris's slash commands embed `git diff`, `git status` etc. directly.

### 3. Parallel Execution
When possible, design skills that can dispatch independent tasks to parallel subagents. Boris runs 5+ terminal sessions + browser sessions simultaneously, each in its own git worktree.

### 4. Token Awareness
Boris uses Opus with thinking for everything — but that makes token efficiency critical. Skills should minimize context consumption through progressive disclosure.

### 5. Permission Strategy
Instead of `--dangerously-skip-permissions`, pre-allow safe commands via `/permissions` in `.claude/settings.json`. Share team-wide for consistency.

## PostToolUse Hooks Pattern

Auto-format code after every Write/Edit:
```json
"PostToolUse": [{
  "matcher": "Write|Edit",
  "hooks": [{
    "type": "command",
    "command": "npm run format 2>/dev/null || npx prettier --write \"$CLAUDE_FILE_PATH\" 2>/dev/null || true"
  }]
}]
```

**For skills:** If your skill generates code, consider recommending hooks for auto-formatting rather than embedding formatting instructions in the skill itself.
