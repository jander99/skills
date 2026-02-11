# Agent Skill Activation Checklist

> Quick validation checklist for ensuring skills activate reliably

---

## Pre-Flight (Must Pass)

These requirements are non-negotiable. Failing any will break the skill.

- [ ] `name` field: lowercase, hyphens only, 1-64 chars, no `--`
- [ ] `description` field: 1-1024 chars, non-empty, no XML tags
- [ ] `SKILL.md` exists in skill root directory (ALL CAPS filename)
- [ ] Directory name matches `name` field exactly

---

## Description (Critical - 90% of Activation)

The description field does most of the work. Optimize it aggressively.

### Action Verb Opening

- [ ] Starts with action verb: Build, Create, Implement, Debug, Analyze, Process, Extract, Generate

**Bad:** "A tool for...", "Helps with...", "The comprehensive..."
**Good:** "Build robust...", "Extract text from...", "Generate clear..."

### "Use when" Triggers

- [ ] Contains explicit "Use when" phrase
- [ ] Lists 3+ specific trigger scenarios
- [ ] Scenarios describe user intent, not tool features

**Bad:** "Use when needed"
**Good:** "Use when designing APIs, implementing authentication, optimizing queries, or building microservices"

### Keyword Density

- [ ] 5+ technology keywords (languages, frameworks, tools, file types)
- [ ] Uses parenthetical enumeration: "databases (PostgreSQL, MongoDB, Redis)"
- [ ] Keywords appear early in description (first 200 chars)

### Framing

- [ ] Task-centric: focuses on user goals and outcomes
- [ ] Avoids vague language: "helps with", "tool for", "assists"
- [ ] 150-400 characters optimal (dense but not bloated)

---

## Structure (Progressive Disclosure)

Keep SKILL.md lean; push details to references.

- [ ] SKILL.md under 100 lines (overview and navigation only)
- [ ] `references/` directory for deep content
- [ ] Quick Start section with prerequisites in first 30 lines
- [ ] Reference Navigation table with "Load when" guidance
- [ ] Decision matrix or quick lookup tables for common choices

---

## Content Quality

Concrete, actionable, error-aware.

- [ ] Copy-paste ready command examples with real flags
- [ ] Prerequisites documented with specific versions, API keys, env vars
- [ ] Error handling section with common errors and solutions
- [ ] No orphaned references (all mentioned files exist)
- [ ] No pseudocode (real commands only)

---

## Integration

How the skill fits with tools and other skills.

- [ ] Tool expectations clear (Bash, Read, Write, etc.)
- [ ] Scripts documented with descriptions of what each does
- [ ] Cross-skill references where appropriate
- [ ] Uses `{baseDir}` for skill-relative paths

---

## Anti-Patterns to Avoid

These patterns actively harm activation:

| Anti-Pattern | Example | Fix |
| ------------ | ------- | --- |
| Vague language | "helps with documents" | "Extract text and tables from PDF files" |
| Missing triggers | No "Use when" clause | Add "Use when [scenario 1], [scenario 2]" |
| Tool-centric | "A PDF library wrapper" | "Extract, merge, and fill PDF documents" |
| Monolithic SKILL.md | 500+ lines in one file | Split to references/, keep SKILL.md <100 lines |
| Pseudocode | `run_extraction()` | `python {baseDir}/scripts/extract.py --input file.pdf` |
| Generic keywords | "data tools" | "sales data from CRM exports and Excel files" |

---

## Quick Validation

Run through this 30-second check before committing:

1. **First word** of description is an action verb?
2. **"Use when"** appears with 3+ scenarios?
3. **5+ technology keywords** are present?
4. **SKILL.md** is under 100 lines?
5. **Name** is lowercase-hyphenated and matches directory?

If any answer is "no", revise before publishing.
