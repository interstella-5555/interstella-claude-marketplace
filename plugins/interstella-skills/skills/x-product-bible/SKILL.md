---
name: x-product-bible
description: Guide writing comprehensive product vision/bible documents that serve as the single source of truth for product decisions. Use when user asks to write a product vision, product bible, PRODUCT.md, product strategy document, product spec, or when rewriting/analyzing an existing product document. Also use when user mentions "product-market fit", "product principles", "what are we building and why", or wants to define/refine product direction. Covers vision statements, product principles, user personas (HXC), JTBD framing, competitive positioning, monetization models, go-to-market strategy, success metrics, anti-goals, and gap analysis vs current implementation.
---

# Writing Product Bible Documents

A product bible is a living document that guides every decision — technical, design, marketing. If a decision can't be justified by something in this document, either the decision is wrong or the document needs updating.

## Workflow

```
1. Gather inputs       → Read existing docs, codebase, stakeholder vision
2. Research context     → Market, competitors, frameworks (see references/)
3. Gap analysis         → What exists vs what's envisioned
4. Draft structure      → Present skeleton, get approval
5. Write sections       → One at a time, validate with user
6. Verify               → Cross-check against codebase reality
7. Ship                 → Commit, update Linear/project tracking
```

## Step 1: Gather Inputs

Before writing anything, collect:

- **Existing product docs** (PRODUCT.md, PRDs, specs, brand strategy docs)
- **Stakeholder vision documents** (founder docs, investor decks, strategy memos)
- **Current codebase capabilities** — what the tech actually supports today
- **User feedback** (if available — interviews, NPS, support tickets)

Read the codebase schema, API routes, and mobile screens to understand what's built vs what's planned.

## Step 2: Research Context

Consult framework references as needed:

| You need... | Read... |
|---|---|
| Product vision structure | `references/vision-frameworks.md` → Cagan, Pichler |
| Product-market fit evaluation | `references/pmf-frameworks.md` → Sean Ellis, Superhuman, a16z |
| User needs framing | `references/pmf-frameworks.md` → Jobs to Be Done |
| Competitive positioning | `references/vision-frameworks.md` → DHM model, positioning |
| Product principles that create trade-offs | `references/vision-frameworks.md` → Intercom principles |
| Location-based app lessons | `references/location-app-lessons.md` |

Also do web research for:
- Current market landscape and competitors
- Recent thinking on product vision (2024+)
- Industry-specific benchmarks

## Step 3: Gap Analysis

Compare stakeholder vision against:
1. **Current PRODUCT.md** (or equivalent) — what does the existing doc say?
2. **Actual codebase** — what's built, what's scaffolded, what's missing?
3. **Stakeholder docs** — what does the founder/team envision?

Output a structured gap analysis:
- **What we do well** — aligned with vision, technically solid
- **What needs to change** — misaligned, missing, or contradicts vision
- **Priority ranking** — impact × feasibility

Present this to the user BEFORE writing the new document. Alignment here prevents rewrites later.

## Step 4: Document Structure

A product bible that people actually read and reference has these sections (adapt order/depth to project):

### Required Sections

1. **Vision Statement** (1-2 sentences)
   - The future you're creating. Inspiring, ambitious, 3-5 year horizon.
   - Describes the change in people's lives, not the product features.

2. **The Problem** (1-2 paragraphs)
   - What's broken about the status quo? Why does this need to exist?
   - Frame around JTBD: what circumstance triggers people to need this?

3. **Why Now** (brief)
   - What changed that makes this possible/necessary today?
   - Market shifts, technology enablers, cultural moments.

4. **Core Pillars / Value Proposition** (3-5 pillars)
   - The fundamental properties that define the product.
   - Every feature must strengthen at least one pillar. If it doesn't — don't build it.

5. **Our User (High-Expectation Customer)**
   - Specific, behavior-based persona (not demographics).
   - Superhuman's HXC: who would be MOST disappointed if the product went away?
   - Include 3-5 concrete scenarios showing the product in their life.

6. **Product Principles** (5-8 opinionated beliefs)
   - MUST create meaningful trade-offs. If no one would disagree, it's not a principle.
   - Format: "[Belief] because [reasoning], even though [the alternative]."
   - Example: "Privacy over convenience — status is hidden before ping, even though this means users ping 'blind', because trust > discovery speed."

7. **What We DON'T Do** (anti-goals)
   - Equally important as what you do. Prevents scope creep.
   - Be specific: "We don't build X because Y."

8. **Core Interaction Model**
   - The fundamental loop users go through. Step by step.
   - What information is visible at each stage? What requires action/consent?

### Recommended Sections

9. **Matching / Discovery Logic**
   - How do users find each other? What signals are used?
   - Multiple levels of matching if applicable.

10. **User Journey** (onboarding → core loop → retention)
    - Onboarding: what data do we collect? How?
    - Core loop: the repeatable action that delivers value.
    - Retention: what brings users back?

11. **Safety & Privacy**
    - Moderation approach, blocking, reporting.
    - Data protection, deletion, compliance.

12. **Monetization**
    - Pricing tiers, what's free vs paid.
    - What we explicitly don't monetize.

13. **Go-to-Market**
    - Launch strategy, target geography, growth tactics.
    - Cold start strategy (critical for network-effect products).

14. **Competitive Positioning**
    - Table: us vs alternatives on key dimensions.
    - What makes us hard to copy? (DHM model)

15. **Success Metrics**
    - PMF indicator (Sean Ellis 40% test)
    - Engagement, retention, growth metrics with targets
    - Use a16z benchmarks for social/consumer apps

16. **Platform & Technology** (brief)
    - What platforms, what's the tech stack capable of today?
    - Not architecture docs — just capabilities relevant to product decisions.

17. **Real-Life Scenarios**
    - 4-6 concrete stories showing the product in action.
    - Different contexts, different user types.

## Step 5: Writing Guidelines

- **Language:** Match the team's working language. If founder docs are in Polish, write in Polish.
- **Tone:** Opinionated, not neutral. A bible takes positions.
- **Length:** 500-1500 lines. Long enough to be comprehensive, short enough to actually read.
- **Tables over prose** for comparisons and feature matrices.
- **Quotes from stakeholder docs** — preserve the founder's voice for vision/philosophy sections.
- **No implementation details** — this is WHAT and WHY, not HOW. Technical architecture goes in separate docs.
- **Unified document, not a changelog.** The product bible is a single source of truth for the current vision — not a history of how the vision evolved. Version history belongs in git commits, not in the document itself.
  - **Small updates:** Rewrite affected sections so the document reads as if it was always written this way. Never add "Updated:", "Changed:", "NEW:" markers or version notes inline.
  - **Major pivots:** If the north star, strategy, or core pillars changed fundamentally, don't try to patch — rewrite the document from scratch. A coherent full rewrite is better than a Frankenstein of old and new thinking. Use the same structure but write every section fresh against the new vision.

### Principles for Principles

Product principles are the hardest section to write well. They must:
- **Create real trade-offs** — the opposite must be a legitimate choice someone could make
- **Be actionable** — a developer should be able to use them to say "no" to a feature request
- **Be memorable** — short enough to internalize, vivid enough to stick
- **Include reasoning** — WHY this trade-off, not just WHAT

Bad: "We believe in quality." (Who doesn't?)
Good: "Ambient over engagement — we prefer a user who opens the app twice after push notifications over one who scrolls 40 minutes, because we optimize for real connections, not screen time."

## Step 6: Verify

After writing, cross-check:
- [ ] Every product principle can be used to reject a real feature request
- [ ] Anti-goals are specific enough to be actionable
- [ ] Success metrics have concrete targets (not "improve retention")
- [ ] Current tech capabilities are accurately represented
- [ ] No contradictions between sections
- [ ] Stakeholder's voice/vision is faithfully represented
- [ ] Document is self-contained — someone new could understand the product from this alone

## Step 7: Ship

- Commit to repo (usually `PRODUCT.md` at root)
- Update Linear/project tracking if a ticket exists
- Suggest updating CLAUDE.md if product understanding affects dev workflow
