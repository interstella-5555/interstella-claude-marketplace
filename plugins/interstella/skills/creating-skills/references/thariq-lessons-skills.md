# Lessons from Building Claude Code: How We Use Skills

Source: https://x.com/trq212/status/2033949937936085378 (March 17, 2026)
Author: **Thariq (@trq212)** — Anthropic employee, Claude Code team. Previously YC W20, MIT Media Lab.
Credibility: First-party source from the team that builds Claude Code. Same level of authority as Boris Cherny's insights.

---

## Context

Anthropic has hundreds of skills in active use internally. This article catalogs the patterns they've found work best — what types of skills to build, how to write them well, and how to distribute them.

Key quote: *"A common misconception we hear about skills is that they are 'just markdown files', but the most interesting part of skills is that they're not just text files. They're folders that can include scripts, assets, data, etc. that the agent can discover, explore and manipulate."*

---

## 9 Types of Skills

Use this taxonomy when deciding what skill to build. The best skills fit cleanly into one category; confusing ones straddle several.

### 1. Library & API Reference

Skills explaining how to correctly use a library, CLI, or SDK. Both internal and external libraries that Claude sometimes struggles with. Often include a folder of reference code snippets and a list of gotchas.

Examples:
- `billing-lib` — internal billing library edge cases and footguns
- `internal-platform-cli` — every subcommand with usage examples
- `frontend-design` — improve Claude's output with your design system

### 2. Product Verification

Skills describing how to test/verify that code works. Often paired with external tools (Playwright, tmux). These are extremely valuable for ensuring correct output.

**Key insight:** "It can be worth having an engineer spend a week just making your verification skills excellent."

Techniques: have Claude record video of its output, enforce programmatic assertions at each step, include verification scripts in the skill.

Examples:
- `signup-flow-driver` — headless browser: signup → email verify → onboarding, with assertions at each step
- `checkout-verifier` — drives checkout UI with Stripe test cards, verifies invoice state
- `tmux-cli-driver` — interactive CLI testing requiring a TTY

### 3. Data Fetching & Analysis

Skills connecting to data and monitoring stacks. Include libraries with credentials, dashboard IDs, common query workflows.

Examples:
- `funnel-query` — which events to join for signup → activation → paid, plus the canonical user_id table
- `cohort-compare` — compare retention/conversion between cohorts, flag statistically significant deltas
- `grafana` — datasource UIDs, cluster names, problem → dashboard lookup table

### 4. Business Process & Team Automation

Skills automating repetitive workflows. Usually simple instructions but may depend on other skills/MCPs. Tip: saving previous results in log files helps the model stay consistent across executions.

Examples:
- `standup-post` — aggregates ticket tracker + GitHub + Slack → formatted standup (delta-only)
- `create-<ticket-system>-ticket` — enforces schema (valid enums, required fields) + post-creation workflow
- `weekly-recap` — merged PRs + closed tickets + deploys → formatted recap

### 5. Code Scaffolding & Templates

Skills generating framework boilerplate. Especially useful when scaffolding has natural language requirements that pure code can't cover. Can be combined with composable scripts.

Examples:
- `new-<framework>-workflow` — scaffolds a new service/workflow/handler with your annotations
- `new-migration` — migration file template plus common gotchas
- `create-app` — new internal app with auth, logging, deploy config pre-wired

### 6. Code Quality & Review

Skills enforcing code quality. Can include deterministic scripts/tools. May run automatically via hooks or GitHub Actions.

Examples:
- `adversarial-review` — spawns a fresh-eyes subagent to critique, implements fixes, iterates until findings degrade to nitpicks
- `code-style` — enforces styles that Claude doesn't do well by default
- `testing-practices` — instructions on how to write tests and what to test

### 7. CI/CD & Deployment

Skills for fetching, pushing, and deploying code. May reference other skills to collect data.

Examples:
- `babysit-pr` — monitors PR → retries flaky CI → resolves merge conflicts → enables auto-merge
- `deploy-<service>` — build → smoke test → gradual rollout with error-rate comparison → auto-rollback on regression
- `cherry-pick-prod` — isolated worktree → cherry-pick → conflict resolution → PR with template

### 8. Runbooks

Skills that take a symptom (Slack thread, alert, error signature), walk through multi-tool investigation, produce structured report.

Examples:
- `<service>-debugging` — maps symptoms → tools → query patterns for highest-traffic services
- `oncall-runner` — fetches alert → checks usual suspects → formats finding
- `log-correlator` — given request ID, pulls matching logs from every system that touched it

### 9. Infrastructure Operations

Skills for routine maintenance with guardrails on destructive actions.

Examples:
- `<resource>-orphans` — finds orphaned pods/volumes → posts to Slack → soak period → user confirms → cascading cleanup
- `dependency-management` — your org's dependency approval workflow
- `cost-investigation` — "why did our bill spike" with specific buckets and query patterns

---

## Tips for Making Skills

### Don't State the Obvious

Claude knows a lot about coding and has default opinions. Focus on information that pushes Claude **out of its normal way of thinking**. The `frontend-design` skill was built by iterating on Claude's design taste — avoiding patterns like Inter font and purple gradients.

### Build a Gotchas Section

**"The highest-signal content in any skill is the Gotchas section."** Build these from common failure points Claude hits. Update your skill over time to capture new gotchas.

Skills should grow over time. The article shows a Billing Lib skill evolving:

- **Day 1:** "How to use the internal billing library. See the lib README for full API docs."
- **Week 2:** Added `## Gotchas` with "Proration rounds DOWN, not to nearest cent."
- **Month 3:** Gotchas grew to 4 items: proration rounding, test-mode skips invoice.finalized hook, idempotency keys expire after 24h, refunds need charge ID not invoice ID.

*"Add a line each time Claude trips on something."*

### Use the File System & Progressive Disclosure

A skill is a **folder**, not just a markdown file. Think of the entire file system as context engineering:
- Point to other markdown files for detailed references (`references/api.md`)
- Include template files in `assets/` for Claude to copy
- Have folders of references, scripts, examples

Tell Claude what files are in your skill — it will read them at appropriate times.

The article shows a `queue-debugging` skill as a perfect hub-and-spoke example (~30 lines total):

```
queue-debugging/
├── SKILL.md          ← hub (dispatches by symptom)
├── stuck-jobs.md
├── dead-letters.md
├── retry-storms.md
└── consumer-lag.md
```

SKILL.md contains a symptom → file lookup table:

```markdown
| Symptom                        | Read              |
|-------------------------------|-------------------|
| Jobs sit pending, never run   | stuck-jobs.md     |
| Messages in DLQ, no retries  | dead-letters.md   |
| Same job retried in a loop   | retry-storms.md   |
| Queue depth keeps climbing   | consumer-lag.md   |
```

*"~30 lines total — the hub dispatches, spoke files do the work"*

### Avoid Railroading Claude

Skills are reusable, so be careful about over-specifying. Give Claude the information it needs but the **flexibility to adapt**. Don't be too prescriptive when the situation varies.

The article shows a concrete before/after for cherry-pick:

**Too prescriptive:**
```
Step 1: Run git log to find the commit.
Step 2: Run git cherry-pick <hash>.
Step 3: If there are conflicts, run git status to list them.
Step 4: Open each conflicting file.
Step 5: For each <<< marker, decide which side to keep.
Step 6: Run git add on each resolved file, then...
```

**Better:**
```
Cherry-pick the commit onto a clean branch. Resolve conflicts
preserving intent. If it can't land cleanly, explain why.
```

### Think Through the Setup

Some skills need user context (e.g., which Slack channel to post to). Pattern: store setup information in a `config.json` in the skill directory. If config isn't set, the agent asks the user.

For structured questions, instruct Claude to use the `AskUserQuestion` tool.

The article shows a `standup-post` skill with dynamic config loading:

```markdown
## Your config
!`cat ${CLAUDE_SKILL_DIR}/config.json 2>/dev/null || echo "NOT_CONFIGURED"`

## Instructions
If the config above is NOT_CONFIGURED, ask the user:
- Which Slack channel?
- Paste a sample standup you liked
Then write the answers to ${CLAUDE_SKILL_DIR}/config.json.

Otherwise, post to the saved channel using the saved format.
```

*The `!`...`` line runs as a shell command before Claude reads the prompt.*

### The Description Field Is for the Model

When Claude Code starts a session, it builds a listing of every skill with its description. **This is what Claude scans to decide "is there a skill for this request?"** The description is not a summary — it's a trigger condition.

The article shows a side-by-side comparison:

**Bad:** `description: A comprehensive tool for monitoring pull request status across the development lifecycle.`

**Good:** `description: Monitors a PR until it merges. Trigger on 'babysit', 'watch CI', 'make sure this lands'.`

The bad description summarizes what it does. The good description tells the model WHEN to trigger and includes actual phrases users would say.

### Memory & Storing Data

Skills can include memory by storing data within them:
- Append-only text log files
- JSON files
- SQLite databases

Example: `standup-post` keeps a `standups.log` with every post. Next run, Claude reads its own history and knows what changed since yesterday.

**Important:** Data stored in the skill directory may be deleted on upgrade. Use `${CLAUDE_PLUGIN_DATA}` as a stable per-plugin data folder.

The article shows a `standup-post` memory pattern:

```markdown
## Memory

Append each standup to ${CLAUDE_PLUGIN_DATA}/standups.log
after posting. This folder persists across skill upgrades.

On each run:
- read the log to see what changed since yesterday
- write today's entry after sending to Slack
```

### Store Scripts & Generate Code

**"One of the most powerful tools you can give Claude is code."** Scripts and libraries let Claude spend its turns on **composition** — deciding what to do next — rather than reconstructing boilerplate.

Example: data science skill with helper functions to fetch data from your event source. Claude generates scripts on the fly to compose these.

The article shows a concrete example — a `lib/signups.py` with gotcha-laden docstrings:

```python
# lib/signups.py (provided to Claude in the skill)
def fetch(day):
    """Signups from events.raw for one day.
        - event='signup_completed', NOT 'signup_started'
        - dedupe by anonymous_id — user_id is null until after signup"""

def by_referrer(df):
    """Group by traffic source.
        - '(direct)' and '' and None all mean organic"""

def by_landing_page(df):
    """Group by entry page.
        - '/', '/index', '/home' are all the homepage
        - strips query params so UTM'd links collapse"""
```

Claude then **generates** a script composing these functions:

```python
# investigate.py · generated by Claude
from lib.signups import fetch, by_referrer, by_landing_page

mon, tue = fetch("2024-03-11"), fetch("2024-03-12")
print(by_referrer(tue) - by_referrer(mon))      # organic -60%, paid flat
print(by_landing_page(tue) - by_landing_page(mon))  # homepage specifically
# → something broke on / on Tuesday
```

*Claude composes, doesn't reconstruct. The gotchas live in the library docstrings.*

### On-Demand Hooks

Skills can include hooks activated only when the skill is called, lasting for the session duration. Use for opinionated hooks you don't want always-on.

Examples:
- `/careful` — blocks `rm -rf`, `DROP TABLE`, force-push, `kubectl delete` via PreToolUse matcher. Only enable when touching prod.
- `/freeze` — blocks any Edit/Write outside a specific directory. Useful when debugging ("add logs but don't accidentally fix unrelated code").

---

## Distributing Skills

Two methods:
1. **Check into repo** (under `./.claude/skills`) — works well for smaller teams with few repos
2. **Plugin marketplace** — for scale; lets teams decide which skills to install

Every checked-in skill adds to model context. As you scale, a marketplace lets users curate their own set.

### Managing a Marketplace

No centralized team decides. Find useful skills organically:
1. Upload to a sandbox folder in GitHub
2. Point people to it in Slack
3. Once it has traction, PR to move into the marketplace

**Warning:** "It can be quite easy to create bad or redundant skills, so making sure you have some method of curation before release is important."

### Composing Skills

Skills can depend on each other by name. No native dependency management yet — just reference other skills by name and the model will invoke them if installed.

### Measuring Skills

Use a `PreToolUse` hook to log skill usage. This reveals:
- Skills that are popular
- Skills that are under-triggering compared to expectations

---

## Key Takeaways

1. **Skills are folders, not files** — scripts, assets, data, references are all part of the skill
2. **Gotchas are the highest-signal content** — build and maintain them over time
3. **Don't state the obvious** — focus on what pushes Claude out of its defaults
4. **Progressive disclosure** — use the file system to manage context
5. **Description = trigger condition** — write it for the model, not humans
6. **Memory via files** — log files, JSON, SQLite for cross-session persistence
7. **Scripts > instructions** — give Claude composable code, not verbose explanations
8. **On-demand hooks** — powerful but opt-in (e.g., `/careful` for prod safety)
9. **Verification skills are worth heavy investment** — spend a week making them excellent
10. **Measure and curate** — log usage, remove bad/redundant skills
