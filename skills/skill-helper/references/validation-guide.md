# Skill Validation Guide

Complete validation rules and automated grading system for Agent Skills.

---

## When to Validate

Run validation:
- **Before committing** a new or modified skill
- **After editing** existing skills
- **During code review** of skill PRs
- **Before publishing** to ensure quality
- **Audit scenarios** for quality assessment

---

## Validation + Grading Integration

The validation system consists of two integrated components:

1. **Validation** (Pass/Fail): 34 automated checks across 3 tiers
2. **Grading** (A-F): 100-point rubric across 5 categories

**Critical:** Grade is calculated **first** and used as input for additional validation checks. Skills graded D or F trigger additional warnings about quality issues.

**Run both:** `./scripts/validate-skill.sh path/to/skill`

---

## 34 Validation Checks

### 🔴 Errors (9 checks - Must Fix)

These block publishing and indicate spec violations:

#### 1. `name` exists
**Rule:** Frontmatter must contain `name` field  
**Why:** Required by Agent Skills specification  
**Fix:** Add `name: skill-name` to frontmatter

#### 2. `name` format
**Rule:** Must match `^[a-z0-9]+(-[a-z0-9]+)*$` (lowercase, hyphens, max 64 chars)  
**Why:** Ensures cross-platform compatibility  
**Fix:** Use only lowercase letters, numbers, and hyphens. No spaces, underscores, or special characters.

**Valid:** `spring-boot-core`, `api-validator`, `markdown-editor`  
**Invalid:** `Spring-Boot`, `api_validator`, `--markdown`, `api--editor`

#### 3. `name` no reserved words
**Rule:** Cannot contain "anthropic" or "claude"  
**Why:** Reserved for official use  
**Fix:** Choose a different name

#### 4. `description` exists
**Rule:** Frontmatter must contain `description` field  
**Why:** Primary activation signal for semantic matching  
**Fix:** Add description with action verbs and triggers

#### 5. `description` length
**Rule:** Must be 50-1024 characters  
**Why:** Too short lacks triggers; too long exceeds spec limit  
**Fix:** Aim for 100-300 characters with dense keyword packing

#### 6. No XML in frontmatter
**Rule:** `name` and `description` cannot contain `<` or `>` characters  
**Why:** XML tags interfere with skill loading  
**Fix:** Remove or escape XML characters

#### 7. SKILL.md exists
**Rule:** Directory must contain SKILL.md file  
**Why:** Required entry point for skill  
**Fix:** Create SKILL.md with proper structure

#### 8. Context7 format validation
**Rule:** If Context7 integration is present, validate correct function format  
**Why:** Incorrect format causes runtime errors  
**Fix:** Use proper function signatures:
```markdown
## Context7 Integration

\`\`\`
context7_resolve-library-id("library-name", "your query")
context7_query-docs("/org/project", "your question")
\`\`\`
```

#### 9. No placeholder content
**Rule:** Cannot contain TODO:, FIXME:, XXX:, TBD:, [PLACEHOLDER]  
**Why:** Indicates incomplete skill  
**Fix:** Replace placeholders with actual content or remove them

---

### 🟡 Warnings (17 checks - Should Fix)

These reduce effectiveness but don't block publishing:

#### 10. Description has "Use when"
**Rule:** Description should include "Use when" or similar trigger phrase  
**Why:** Gives LLM clear activation criteria  
**Fix:** Add explicit triggers: "Use when [scenario1], [scenario2], or [scenario3]"

#### 11. Description 5+ action verbs
**Rule:** Description should contain 5 or more action verbs  
**Why:** Increases semantic matching accuracy  
**Fix:** Pack with verbs: create, write, edit, validate, optimize, generate, build, etc.

**Example:** "Create, validate, audit, review, refactor, improve, and optimize Agent Skills..."

#### 12. Keyword density 10+
**Rule:** Description should contain 10+ technology keywords  
**Why:** Improves discoverability across different tech stacks  
**Fix:** Add languages, frameworks, tools, concepts

**Example:** "...with TypeScript, JavaScript, Python, React, Angular, Jest, Vitest, unit tests, integration tests..."

#### 13. Has examples
**Rule:** SKILL.md should have concrete usage examples  
**Why:** Examples demonstrate activation and usage patterns  
**Fix:** Add "## Examples" section with real scenarios

#### 14. Token limit
**Rule:** SKILL.md body should be in optimal range  
**Why:** Token efficiency for context windows  

**Token Targets:**
- 🔴 **Too Small:** <500 tokens - Insufficient content
- ⚠️ **Small:** 500-1000 tokens - Consider expanding
- 🎯 **Sweet Spot:** 1000-2000 tokens - Ideal for Grade A
- ⚠️ **Large:** 2000-3500 tokens - Consider refactoring
- 🔴 **Too Large:** >3500 tokens - Move content to references/

**Fix:** Refactor to target range, use progressive loading

#### 15. Referenced files exist
**Rule:** All markdown links `[text](path)` must resolve to actual files  
**Why:** Broken links cause errors when loading bundled resources  
**Fix:** Verify all links or remove broken references

#### 16. Has purpose section
**Rule:** Should have "What I Do", "Purpose", or "Overview" section  
**Why:** Clarifies capability for users and agents  
**Fix:** Add clear capability list in "What I Do" section

#### 17. Slash command exists
**Rule:** Corresponding slash command file should exist  
**Why:** Enables direct invocation via commands  
**Fix:** Create `.opencode/commands/{skill-name}.md` or `content/commands/ak-{skill-name}.md`

#### 18. Command references skill
**Rule:** Command file should reference `@skills/{skill-name}/SKILL.md`  
**Why:** Links command to skill for proper activation  
**Fix:** Add reference in command markdown

#### 19. agent-kit command prefix
**Rule:** Commands in `content/commands/` must use `ak-` prefix  
**Why:** Avoids conflicts with user-created commands  
**Fix:** Rename command file from `command.md` to `ak-command.md`

#### 20. No name conflicts
**Rule:** Command name cannot conflict with existing skill names  
**Status:** ⚠️ NOT CURRENTLY IMPLEMENTED - Manual check required  
**Why:** Prevents ambiguous activation  
**Fix:** Manually verify skill name is unique across installed skills  
**Future:** Will scan ~/.opencode/skill/* or .opencode/skill/* for conflicts

#### 21. Quick Start section
**Rule:** Should have Quick Start section within first 50 lines  
**Why:** Provides immediate value for users  
**Fix:** Add Quick Start with prerequisites, tools, and basic usage example

#### 22. Tool expectations documented
**Rule:** Should indicate required tools (Read, Write, Edit, Bash, etc.)  
**Why:** Sets expectations for what skill can do  
**Fix:** Add "Tools Used: Read, Write, Edit" to Quick Start

#### 23. Parenthetical grouping
**Rule:** Use parentheses for related items in description  
**Why:** Improves keyword density and readability  
**Fix:** Group related tech: `databases (PostgreSQL, MongoDB, Redis)`

**Example:** "...frameworks (NestJS, FastAPI, Django), databases (PostgreSQL, MongoDB), APIs (REST, GraphQL, gRPC)..."

#### 24. Reference navigation
**Rule:** If references/ directory exists, should have navigation section  
**Why:** Helps users find detailed content  
**Fix:** Add navigation table pointing to reference files

```markdown
## References

| Reference | Use When |
|-----------|----------|
| [advanced.md](references/advanced.md) | Complex scenarios |
| [troubleshooting.md](references/troubleshooting.md) | Debugging issues |
```

#### 25. Error handling docs
**Rule:** Complex skills should document common errors  
**Why:** Helps users troubleshoot issues  
**Fix:** Add error table with causes and solutions

```markdown
## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| ... | ... | ... |
```

#### 26. Prerequisites section
**Rule:** Skills requiring setup should list prerequisites  
**Why:** Sets expectations and prevents failures  
**Fix:** Add prerequisites to Quick Start

```markdown
**Prerequisites:**
- Node.js 18+
- Git configured
- Write access to directory
```

---

### 🟢 Suggestions (8 checks - Nice to Have)

Polish and completeness improvements:

#### 27. Has related skills
**Rule:** Should link to complementary skills  
**Why:** Helps users discover related capabilities  
**Fix:** Add "## Related Skills" section

```markdown
## Related Skills

- `spring-data` - Database access patterns
- `spring-security` - Authentication and authorization
- `spring-testing` - Testing strategies
```

#### 28. Consistent formatting
**Rule:** Headers, code blocks, and lists should be properly formatted  
**Why:** Improves readability  
**Fix:** Follow markdown best practices

#### 29. Version in metadata
**Rule:** Should include `version` field in metadata  
**Why:** Tracks changes over time  
**Fix:** Add `version: "1.0.0"` to metadata

#### 30. License specified
**Rule:** Should include `license` field  
**Why:** Clear usage terms  
**Fix:** Add `license: MIT` (or appropriate license)

#### 31. Decision matrix
**Rule:** Should include table for quick decision guidance  
**Why:** Speeds up common decisions  
**Fix:** Add decision matrix or quick reference table

```markdown
## Quick Reference

| Scenario | Approach | Example |
|----------|----------|---------|
| ... | ... | ... |
```

#### 32. Cross-skill integration
**Rule:** Should reference related skills where appropriate  
**Why:** Enables skill composition  
**Fix:** Mention related skills in process steps

#### 33. Concrete examples
**Rule:** Examples should be copy-paste ready, not pseudocode  
**Why:** Provides immediate value  
**Fix:** Use real commands with actual flags and parameters

❌ **Bad:** `command [options] [args]`  
✅ **Good:** `jest --coverage --watchAll=false tests/`

#### 34. Task-centric framing
**Rule:** Description should focus on user goals, not tool features  
**Why:** Improves semantic matching to user intent  
**Fix:** Frame around outcomes, not mechanics

❌ **Tool-centric:** "This tool uses PyPDF2 to process PDFs"  
✅ **Task-centric:** "Extract text and tables from PDF files, fill forms, merge documents"

---

## Grading Integration

After running validation checks, the script calculates a grade using the 100-point rubric.

**Grade Components:**

| Category | Weight | Max Points | Based On |
|----------|--------|------------|----------|
| Description Quality | 35% | 35 | Checks 10-12, 23, 34 |
| Structure & Organization | 25% | 25 | Checks 14, 21, 24, 31 |
| Content Quality | 20% | 20 | Checks 13, 25, 26, 33 |
| Technical Implementation | 15% | 15 | Checks 17-20, 22, 32 |
| Specification Compliance | 5% | 5 | Checks 1-9 |

**Grade as Validation Input:**

If grade is **D (60-69) or F (0-59)**, validation adds warning:
```
⚠️  Low grade detected (D/F) - Skill needs significant improvements before publishing
```

See [grading-rubric.md](grading-rubric.md) for complete scoring details.

---

## Automated Validation

### Using the Validation Script

```bash
./scripts/validate-skill.sh path/to/skill
```

**Exit Codes:**
- `0` - Passed (no errors)
- `1` - Failed (has errors)

**Output Format:**

```
╭─────────────────────────────────────────╮
│  Skill Validation: skill-name           │
╰─────────────────────────────────────────╯

🔴 Errors:      0
🟡 Warnings:    2
🟢 Suggestions: 1

🟡 Warnings:
   • SKILL.md is ~2,100 tokens (recommend 1000-2000)
   • No decision matrix found

🟢 Suggestions:
   • Consider adding version to metadata

═══════════════════════════════════════════
GRADE BREAKDOWN:

Description Quality        33/35  (94%)
Structure & Organization  22/25  (88%)
Content Quality           20/20  (100%)
Technical Implementation  15/15  (100%)
Specification Compliance   5/5   (100%)

═══════════════════════════════════════════
TOTAL SCORE: 95/100
Grade: A (Excellent)

Status: ✅ PASSED
```

### CI/CD Integration

Add to GitHub Actions workflow:

```yaml
- name: Validate Skills
  run: |
    for skill in .opencode/skill/*/; do
      ./scripts/validate-skill.sh "$skill" || exit 1
    done
```

---

## Manual Validation Checklist

For human review, use this quick checklist:

**Frontmatter:**
- [ ] `name` is valid format (lowercase, hyphens)
- [ ] `description` is 50-1024 chars
- [ ] `description` has 5+ action verbs
- [ ] `description` has 10+ keywords
- [ ] `description` has "Use when" triggers
- [ ] No placeholders (TODO, FIXME, etc.)

**Structure:**
- [ ] SKILL.md exists
- [ ] Token count 1000-2000 (sweet spot)
- [ ] Has Quick Start within first 50 lines
- [ ] Has "What I Do" section
- [ ] Has "When to Use Me" section
- [ ] Has concrete examples

**Resources:**
- [ ] All markdown links resolve
- [ ] Slash command exists
- [ ] Command references skill
- [ ] If agent-kit: command uses ak- prefix

**Quality:**
- [ ] Examples are copy-paste ready
- [ ] Prerequisites documented (if needed)
- [ ] Tool expectations listed
- [ ] Error handling documented (for complex skills)
- [ ] Task-centric framing (not tool-centric)

**Grade:** ___/100 (Target: 90+ for A)

---

## Common Issues & Fixes

### Issue 1: Description Too Vague

**Problem:** `description: "Helps with testing"`

**Fix:** Add action verbs, keywords, triggers:
```yaml
description: "Write, generate, debug, and fix Jest unit tests for React components with Testing Library, mocks, and spies. Use when testing components, services, hooks, or debugging failing tests."
```

### Issue 2: SKILL.md Too Large

**Problem:** SKILL.md is 500 lines (>3500 tokens)

**Fix:** Move content to references/:
- Detailed examples → `references/examples.md`
- Advanced topics → `references/advanced.md`
- Troubleshooting → `references/troubleshooting.md`

Keep only essential content in SKILL.md, link to references.

### Issue 3: No Slash Command

**Problem:** Skill exists but no corresponding command

**Fix:** Create command file:
```bash
# For project skills
touch .opencode/commands/skill-name.md

# For agent-kit distribution
touch content/commands/ak-skill-name.md
```

Use template from [assets/command-template.md](../assets/command-template.md)

### Issue 4: Broken Links

**Problem:** `[reference](references/guide.md)` but file doesn't exist

**Fix:** Either create the referenced file or remove the link

### Issue 5: Missing Prerequisites

**Problem:** Skill requires specific setup but doesn't document it

**Fix:** Add to Quick Start:
```markdown
**Prerequisites:**
- Docker installed and running
- AWS CLI configured
- kubectl access to cluster
```

### Issue 6: Tool-Centric Description

**Problem:** `description: "This skill uses the ESLint API to lint code"`

**Fix:** Focus on user goals:
```yaml
description: "Lint, format, and fix JavaScript/TypeScript code with ESLint rules. Use when checking code quality, fixing style issues, or enforcing coding standards."
```

### Issue 7: Placeholder Content

**Problem:** Skill contains `TODO: Add examples`

**Fix:** Complete all placeholder sections or remove them before publishing

### Issue 8: Invalid Name Format

**Problem:** `name: API_Validator` (uppercase + underscore)

**Fix:** Use valid format: `name: api-validator`

### Issue 9: Context7 Format Error

**Problem:** Incorrect function call format

**Fix:** Use correct syntax:
```markdown
\`\`\`
context7_resolve-library-id("React", "testing with Jest")
context7_query-docs("/facebook/react", "useEffect cleanup")
\`\`\`
```

### Issue 10: No Examples

**Problem:** Skill has no concrete usage examples

**Fix:** Add examples section:
```markdown
## Examples

### Example 1: Basic Usage

\`\`\`bash
npm test -- --coverage
\`\`\`

### Example 2: Watch Mode

\`\`\`bash
npm test -- --watch
\`\`\`
```

---

## Related Resources

- [grading-rubric.md](grading-rubric.md) - 100-point scoring system
- [optimization-patterns.md](optimization-patterns.md) - Writing trigger-rich descriptions
- [creation-workflow.md](creation-workflow.md) - Step-by-step skill creation
- [../assets/skill-template.md](../assets/skill-template.md) - Starter template
