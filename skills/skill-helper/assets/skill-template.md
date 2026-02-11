<!-- 
⚠️ TEMPLATE FILE - REPLACE ALL PLACEHOLDERS BEFORE USE
- Replace [bracketed placeholders] with actual content
- Ensure description has 5+ action verbs and 10+ keywords
- Remove this warning block after customization
- Run validation: ./scripts/validate-skill.sh path/to/skill
-->
---
name: your-skill-name-here
description: [Action verbs] [task objects] [technologies]. Use when [trigger scenario 1], [trigger scenario 2], or [trigger scenario 3].
license: MIT
metadata:
  version: 1.0.0
  author: your-name
  audience: developers
  workflow: your-workflow-type
---

## Quick Start

**Prerequisites:**
- Prerequisite 1
- Prerequisite 2
- Prerequisite 3

**Tools Used:** Read, Write, Edit, Bash, Grep, Glob

**Basic Usage:**
```
User: "[Example user request]"
Agent: [What skill does]
```

## What I Do

- Capability 1
- Capability 2
- Capability 3
- Capability 4
- Capability 5

## When to Use Me

Use this skill when you:
- [Action verb] [task object] ([trigger phrase])
- [Action verb] [task object] ([trigger phrase])
- [Action verb] [task object] ([trigger phrase])
- [Action verb] [task object] ([trigger phrase])
- [Action verb] [task object] ([trigger phrase])

## Process

### Step 1: [Phase Name]

- Substep description
- Substep description
- Substep description

### Step 2: [Phase Name]

- Substep description
- Substep description
- Substep description

### Step 3: [Phase Name]

- Substep description
- Substep description
- Substep description

## Examples

### Example 1: [Scenario Name]

```
User: "[User request]"
Agent: [Expected behavior and output]
```

**Result:** [What was accomplished]

### Example 2: [Scenario Name]

```bash
# Copy-paste ready command
command --flag value argument
```

**Output:**
```
[Expected output]
```

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Error message here | Why it happens | How to fix it |
| Error message here | Why it happens | How to fix it |

## Quick Reference

| Scenario | Approach | Example |
|----------|----------|---------|
| When X | Do Y | `code example` |
| When A | Do B | `code example` |

## Related Skills

- `skill-name` - Brief description of related skill
- `skill-name` - Brief description of related skill
- `skill-name` - Brief description of related skill

---

## Notes for Skill Authors

This template follows the Agent Skills specification and skill-helper v2.0 best practices.

**Before using this template:**

1. Replace `skill-name` with valid name (lowercase, hyphens only)
2. Write trigger-rich description (5+ verbs, 10+ keywords, "Use when" clause)
3. Fill in all sections marked with brackets []
4. Add concrete, copy-paste ready examples
5. Document prerequisites and tool expectations
6. Validate with: `./scripts/validate-skill.sh path/to/skill`
7. Target Grade A (90-100)

**Token Target:** 1000-2000 tokens (~200-400 lines)

**Description Formula:**
```
[5+ action verbs] [task objects] [10+ technology keywords] (grouped). 
Use when [scenario 1], [scenario 2], or [scenario 3].
```

**Good Example:**
```yaml
description: "Create, write, generate, edit, and format API documentation with OpenAPI (Swagger, v3), JSDoc, TypeScript definitions, and markdown. Use when documenting REST APIs, generating OpenAPI schemas, writing endpoint docs, or creating API reference guides."
```

**Validation Checklist:**
- [ ] Name matches `^[a-z0-9-]+$`
- [ ] Description 50-1024 chars, 5+ verbs, 10+ keywords
- [ ] Quick Start within first 50 lines
- [ ] What I Do and When to Use Me sections present
- [ ] Concrete examples (not pseudocode)
- [ ] Prerequisites documented
- [ ] Tool expectations listed
- [ ] No placeholders (TODO, FIXME, etc.)
- [ ] Token count 1000-2000
- [ ] Slash command created

**Next Steps:**
1. Create skill directory: `mkdir -p .opencode/skill/skill-name/{assets,references,scripts}`
2. Copy this template to: `.opencode/skill/skill-name/SKILL.md`
3. Fill in all sections
4. Create slash command: `.opencode/commands/skill-name.md`
5. Validate: `./scripts/validate-skill.sh .opencode/skill/skill-name`
6. Test auto-activation with real queries
7. Iterate based on validation feedback
