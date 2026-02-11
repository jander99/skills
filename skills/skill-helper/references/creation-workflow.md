# Skill Creation Workflow

Complete 8-step process for creating well-structured Agent Skills.

---

## What is a Skill?

A skill is a directory containing:
- **`SKILL.md`** - Instructions with YAML frontmatter (required)
- **`assets/`** - Templates, data files (optional)
- **`references/`** - Additional documentation (optional)
- **`scripts/`** - Executable code (optional)

Skills extend AI agent capabilities with domain-specific knowledge and workflows.

---

## 8-Step Creation Workflow

### Step 1: Gather Requirements

Ask yourself or the user:
1. **What should the skill do?** (capability)
2. **When should it activate?** (trigger conditions)
3. **What resources does it need?** (templates, scripts, references)
4. **Where should it live?** (project or global)
5. **What tools will it use?** (Read, Write, Edit, Bash, etc.)

### Step 2: Choose Skill Location

```
# Project skill (shared with team via git)
.opencode/skill/{skill-name}/SKILL.md
.claude/skills/{skill-name}/SKILL.md

# Global skill (only for you)
~/.config/opencode/skills/{skill-name}/SKILL.md
~/.claude/skills/{skill-name}/SKILL.md

# agent-kit content (for distribution)
content/skills/{skill-name}/SKILL.md
```

**Decision Matrix:**

| If... | Use... |
|-------|--------|
| Skill is project-specific | Project location (.opencode/skill/) |
| Skill is personal/reusable | Global location (~/.config/opencode/skills/) |
| Skill is for distribution | agent-kit content/ |

### Step 3: Create Directory Structure

```bash
mkdir -p {location}/{skill-name}/{assets,references,scripts}
```

**Example:**
```bash
mkdir -p .opencode/skill/api-validator/{assets,references,scripts}
```

### Step 4: Write SKILL.md

Use the template from [assets/skill-template.md](../assets/skill-template.md).

**Key sections:**
1. **Frontmatter** - name, description (trigger-rich!), metadata
2. **Quick Start** - Prerequisites, tools used, basic usage
3. **What I Do** - Bullet list of capabilities
4. **When to Use Me** - Trigger phrases with action verbs
5. **Process** (optional) - Step-by-step workflow
6. **Examples** - Concrete usage examples
7. **Related Skills** (optional) - Links to other skills

**Frontmatter Requirements:**

```yaml
---
name: skill-name              # Required: ^[a-z0-9-]+$ (max 64)
description: What and when    # Required: 50-1024 chars, 5+ verbs, 10+ keywords
license: MIT                  # Optional: license type
metadata:                     # Optional: additional info
  version: "1.0.0"
  author: your-name
---
```

**Description Best Practices:**
- Start with strong action verbs (Create, Build, Implement, Process, Debug)
- Include 5+ action verbs total
- Include 10+ technology keywords
- Use parenthetical grouping: `technologies (TypeScript, JavaScript, Python)`
- Add explicit "Use when" triggers
- Focus on user goals (task-centric), not tool features

❌ **Bad:** `Helps with documentation`

✅ **Good:** `Generate API documentation from code with OpenAPI specs, JSDoc, TypeScript types. Use when creating docs, README files, or API specifications for libraries.`

**Token Target: 1000-2000 tokens (~200-400 lines)**

### Step 5: Add Bundled Resources (if needed)

**assets/** - Templates and Data

Use for:
- Document templates
- Configuration examples
- Data schemas

```markdown
# In SKILL.md
See [assets/template.md](assets/template.md) for the format.
```

**references/** - Extended Documentation

Use for:
- Detailed examples
- Troubleshooting guides
- API references
- Advanced topics

```markdown
# In SKILL.md
For advanced usage, see [references/advanced.md](references/advanced.md).
```

**scripts/** - Executable Code

Use for:
- Validation utilities
- Code generation
- Data processing

```markdown
# In SKILL.md
Run the validation script:
\`\`\`bash
./scripts/validate.sh
\`\`\`
```

Scripts execute without loading into context - only output is captured.

### Step 6: Create Slash Command

Every skill should have a corresponding slash command for easy invocation.

**Command location:**
```
# Project command (matches skill location)
.opencode/commands/{skill-name}.md
.claude/commands/{skill-name}.md

# agent-kit content (MUST use ak- prefix!)
content/commands/ak-{skill-name}.md
```

**Naming Rules:**
1. **agent-kit commands MUST use `ak-` prefix** to avoid conflicts
2. **No command/skill name conflicts** in the same scope

**Command template:**

See [assets/command-template.md](../assets/command-template.md) for complete template.

```markdown
---
description: {One-line description of what command does}
arguments:
  - name: arg-name
    description: What the argument is for
    required: false
---

Use the {skill-name} skill to help the user {accomplish task}.

Follow the {skill-name} skill instructions in @skills/{skill-name}/SKILL.md exactly.

Key steps:
1. {Step from skill}
2. {Step from skill}
```

### Step 7: Validate & Grade

Before finalizing, run automated validation:

```bash
./scripts/validate-skill.sh path/to/skill
```

The validator checks:
- **34 validation rules** (9 errors, 17 warnings, 8 suggestions)
- **100-point grading rubric** (A/B/C/D/F scale)
- Frontmatter requirements
- SKILL.md structure and token limits
- All referenced files exist
- Slash command exists and is properly configured
- agent-kit commands use `ak-` prefix
- No command/skill name conflicts

**Target: Grade B+ (85+) minimum, Grade A (90-100) ideal**

See [validation-guide.md](validation-guide.md) for complete validation rules.

**Only proceed if validation passes with no errors.**

### Step 8: Test Auto-Activation

Test that your skill activates correctly:

1. **Restart the agent** to reload skills
2. **Test trigger phrases** - Ask questions that should activate the skill
3. **Verify activation** - Confirm the skill loads
4. **Check output quality** - Ensure skill provides useful guidance
5. **Iterate** - Refine description and instructions based on results

**Testing Framework:**
See [optimization-patterns.md](optimization-patterns.md) for the 3-question auto-activation testing methodology.

---

## Skill Patterns

### Pattern 1: Workflow Skills

For multi-step processes (planning, deployment, migration):

```markdown
## Workflow

1. **Phase 1: Discovery**
   - Gather requirements
   - Identify constraints
   
2. **Phase 2: Design**
   - Create architecture
   - Choose technologies
   
3. **Phase 3: Implementation**
   - Generate code
   - Configure systems
   
4. **Phase 4: Validation**
   - Run tests
   - Verify deployment
```

**Examples:** create-plan, deploy-service, migrate-database

### Pattern 2: Reference Skills

For domain knowledge (testing, security, language features):

```markdown
## Quick Reference

| Pattern | When to Use | Example |
|---------|-------------|---------|
| Pattern A | Scenario 1 | Code... |
| Pattern B | Scenario 2 | Code... |

## Detailed Guidance

See [references/full-guide.md](references/full-guide.md) for:
- Complex scenarios
- Performance optimization
- Troubleshooting guide
```

**Examples:** angular-testing, spring-security, typescript-advanced

### Pattern 3: Tool Skills

For specific operations (file generation, validation, formatting):

```markdown
## What I Do

- [Specific operation 1]
- [Specific operation 2]
- [Specific operation 3]

## Usage

**Input:** [description]
**Output:** [result]
**Tools:** Read, Write, Edit, Bash

## Process

1. Read input files
2. Process content
3. Generate output
```

**Examples:** markdown-editor, skill-helper, doc-contents

---

## Progressive Loading Strategy

Skills use a 3-level loading system:

| Level | Loads | When | Token Budget |
|-------|-------|------|--------------|
| **L1: Frontmatter** | name + description | Agent startup | ~100 tokens |
| **L2: SKILL.md body** | Main instructions | Skill activates | 1000-2000 tokens |
| **L3: Bundled files** | references/, assets/, scripts/ | As referenced | Unlimited |

**Best Practice:** Keep SKILL.md under 2000 tokens. Move detailed content, examples, and advanced topics to references/.

---

## Output Checklist

After creation, verify you have:

- [ ] Valid skill name (lowercase, hyphens, no reserved words)
- [ ] Trigger-rich description (5+ verbs, 10+ keywords)
- [ ] SKILL.md with required sections (What I Do, When to Use Me, Quick Start)
- [ ] Token count in sweet spot (1000-2000 tokens)
- [ ] Bundled resources (if needed): assets/, references/, scripts/
- [ ] Slash command created and properly named
- [ ] Validation passes with no errors (`./scripts/validate-skill.sh`)
- [ ] Grade B+ (85+) or higher
- [ ] Auto-activation tested with real queries
- [ ] All links resolve correctly

---

## Examples

### Example 1: Creating a Code Review Skill

```
User: "Create a skill for reviewing React components"
Agent: [Asks clarifying questions]
- What aspects to review? (performance, accessibility, patterns)
- Any specific rules or style guide?
- Should it suggest fixes or just identify issues?

[Creates skill structure]
.opencode/skill/react-review/
├── SKILL.md
├── assets/
│   └── checklist.md
└── references/
    └── patterns.md
```

**Key decisions:**
- Name: `react-review` (specific, focused)
- Description: "Review, audit, and analyze React components for performance, accessibility, hooks usage, state management, and best practices. Use when reviewing code, analyzing components, or providing feedback on React implementations."
- Pattern: Reference skill (provides checklists and patterns)
- Resources: Checklist in assets/, detailed patterns in references/

### Example 2: Creating a Documentation Skill

```
User: "Create a skill for writing JSDoc comments"

Agent: [Creates skill with template]
.opencode/skill/jsdoc-writer/
├── SKILL.md
└── assets/
    └── jsdoc-template.md
```

**Key decisions:**
- Name: `jsdoc-writer` (clear, descriptive)
- Description: "Generate, write, and format JSDoc comments for JavaScript and TypeScript functions, classes, and modules. Use when documenting code, creating API documentation, or adding type annotations."
- Pattern: Tool skill (performs specific operation)
- Resources: Template in assets/ for consistent JSDoc format

---

## Common Pitfalls

### ❌ Avoid These Mistakes

1. **Vague descriptions**
   - Bad: "Helps with testing"
   - Good: "Write, generate, and debug Jest unit tests for React components with Testing Library. Use when testing components, mocking dependencies, or fixing failing tests."

2. **Missing "Use when" triggers**
   - Bad: "A skill for database optimization"
   - Good: "Optimize database queries, indexes, and schemas. Use when debugging slow queries, analyzing performance, or designing database architecture."

3. **Tool-centric framing**
   - Bad: "This tool processes PDFs using PyPDF2"
   - Good: "Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDFs or document processing."

4. **Monolithic SKILL.md**
   - Move detailed examples to references/
   - Keep SKILL.md under 2000 tokens
   - Use progressive loading

5. **No concrete examples**
   - Provide copy-paste ready code
   - Avoid pseudocode
   - Show real command syntax

6. **Missing slash command**
   - Every skill needs a corresponding command
   - Use proper naming (ak- prefix for agent-kit)
   - Reference the skill in command

7. **Scope too broad or too narrow**
   - Bad (too broad): One skill for git, releases, CI/CD, deployment, docs
   - Bad (too narrow): Separate skills for "create markdown" vs "edit markdown"
   - Good: One skill for all markdown operations; separate skill for git releases

---

## Related Resources

- [validation-guide.md](validation-guide.md) - 34 validation checks
- [optimization-patterns.md](optimization-patterns.md) - Trigger-rich descriptions
- [grading-rubric.md](grading-rubric.md) - 100-point scoring system
- [assets/skill-template.md](../assets/skill-template.md) - Starter template
- [assets/command-template.md](../assets/command-template.md) - Command template
