# Optimization Patterns for Agent Skills

Guide to writing trigger-rich descriptions and maximizing auto-activation.

---

## The Auto-Activation Pattern

**Key Insight:** Skills should trigger automatically when agents encounter matching tasks. This requires **trigger-rich descriptions** packed with action verbs and task keywords.

Agent Skills use **pure LLM-based semantic matching** for activation. There's no algorithmic routing, keyword matching, or intent classification. The `description` field is presented to the AI model in its system prompt, and the model decides when to invoke skills based solely on textual understanding.

This means activation success depends entirely on how well your description communicates relevance to the language model.

---

## Writing Trigger-Rich Descriptions

### Formula

**[Action verbs describing capability] + [Explicit triggers] + [Key technology terms]**

**Requirements:**
- **5+ action verbs** minimum
- **10+ technology keywords** minimum
- **Explicit "Use when" triggers**
- **Parenthetical grouping** for related items
- **Task-centric framing** (user goals, not tool features)
- **50-1024 characters** (aim for 100-300)

### Action Verbs to Pack

**Creation:**
- create, generate, build, write, scaffold, initialize, setup

**Modification:**
- edit, update, refactor, improve, optimize, enhance, modify, transform

**Analysis:**
- validate, audit, review, check, analyze, inspect, evaluate, assess

**Organization:**
- structure, organize, format, arrange, clean, normalize

**Problem Solving:**
- debug, fix, troubleshoot, resolve, diagnose, repair

**Documentation:**
- document, explain, describe, annotate, comment

### Technology Keywords

Include specific:
- **Languages:** TypeScript, JavaScript, Python, Java, Go, Rust
- **Frameworks:** React, Angular, Spring Boot, NestJS, FastAPI
- **Tools:** Jest, Vitest, ESLint, Prettier, Docker, Kubernetes
- **Concepts:** unit tests, integration tests, APIs, microservices, authentication
- **File types:** markdown, JSON, YAML, TypeScript, configuration files

### Parenthetical Grouping

Group related technologies in parentheses to maximize keyword density while maintaining readability:

```yaml
# Good
description: "Test frameworks (Jest, Vitest, Jasmine), libraries (Testing Library, Enzyme), and patterns (mocks, spies, fixtures)"

# Bad  
description: "Test with Jest or Vitest or Jasmine using Testing Library or Enzyme with mocks or spies or fixtures"
```

**Pattern:** `category (item1, item2, item3)`

**Examples:**
- `languages (TypeScript, JavaScript, Python)`
- `databases (PostgreSQL, MongoDB, Redis)`
- `frameworks (React, Angular, Vue)`
- `tools (Docker, Kubernetes, Helm)`

---

## Examples: Good vs Bad

### ❌ Weak (Generic, Few Triggers)

```yaml
description: "Helps with releases"
```

**Problems:**
- Weak verb ("helps")
- No specific actions
- No technology keywords
- No "Use when" triggers
- 3 words, ~18 characters

### ✅ Strong (Trigger-Rich, Auto-Activating)

```yaml
description: "Create, generate, build, publish, and manage git releases, version tags, changelogs, release notes from merged PRs and git history. Use when creating releases, tagging versions, generating changelogs, or publishing packages."
```

**Strengths:**
- 5 action verbs (create, generate, build, publish, manage)
- 8+ keywords (git, releases, tags, changelogs, PRs, versions, packages)
- Explicit "Use when" triggers
- Task-centric (what user accomplishes)
- 257 characters

---

### ❌ Weak

```yaml
description: "Documentation tool"
```

**Problems:**
- No verbs
- Vague ("tool")
- No specific actions
- No triggers
- 2 words

### ✅ Strong

```yaml
description: "Write, edit, update, format, structure, and organize markdown documentation (README, CHANGELOG, guides, tutorials, API docs). Use when creating docs, writing README files, documenting code, or generating project documentation."
```

**Strengths:**
- 6 action verbs
- Specific file types (README, CHANGELOG)
- Parenthetical grouping
- Clear triggers
- 244 characters

---

### ❌ Weak (Tool-Centric)

```yaml
description: "Uses PyPDF2 library to work with PDF files"
```

**Problems:**
- Tool-centric (focuses on implementation)
- Weak verb ("uses")
- No user goals
- No triggers

### ✅ Strong (Task-Centric)

```yaml
description: "Extract text and tables from PDF files, fill PDF forms, merge documents, split pages. Use when processing PDFs, extracting data, working with forms, or manipulating PDF documents."
```

**Strengths:**
- Task-centric (what user wants to do)
- Multiple action verbs
- Specific capabilities
- Clear triggers

---

## Action Verb Library

Organize by category for easy reference:

### Creation & Generation
create, generate, build, write, scaffold, initialize, setup, construct, compose, produce, develop, implement, design

### Modification & Enhancement
edit, update, refactor, improve, optimize, enhance, modify, transform, adjust, revise, polish, tune, upgrade

### Analysis & Validation
validate, audit, review, check, analyze, inspect, evaluate, assess, verify, test, debug, profile, measure

### Organization & Structure
structure, organize, format, arrange, clean, normalize, sort, categorize, group, order, standardize

### Problem Solving & Maintenance
debug, fix, troubleshoot, resolve, diagnose, repair, correct, patch, solve, address, handle

### Documentation & Communication
document, explain, describe, annotate, comment, clarify, detail, outline, summarize

### Deployment & Operations
deploy, publish, release, install, configure, setup, manage, monitor, operate, maintain

---

## Auto-Activation Testing

After creating a skill, test if it would auto-activate using this 3-question framework:

### Question 1: Would an Agent's Task Match This Description?

**Test:** Present realistic user queries and check if description contains matching keywords.

**Example:**
- **User says:** "Write a markdown file about API endpoints"
- **Skill description contains:** write, markdown, file, API, documentation
- **Result:** ✅ Yes → Good auto-activation potential

**Example:**
- **User says:** "Test my React component"
- **Skill description contains:** React, component (but NOT "test")
- **Result:** ❌ No → Will not activate

**Fix:** Add "test" verb and related keywords to description.

### Question 2: Are Trigger Verbs Comprehensive?

**Test:** Check if description covers all major verbs users might employ.

**Example skill: markdown-editor**
- create ✅
- write ✅
- edit ✅
- update ✅
- generate ✅
- build ✅
- format ✅

**Missing verbs = missed auto-activation opportunities**

If users might say "fix my markdown" but description doesn't contain "fix", the skill won't activate for that query.

### Question 3: Are Task Objects Specific Enough?

**Test:** Compare generic vs specific terms in description.

**Generic:** "files"
**Specific:** "markdown files, README, CHANGELOG, documentation"

**Generic:** "code"
**Specific:** "React components, TypeScript files, JSX"

**Generic:** "tests"
**Specific:** "unit tests, integration tests, Jest tests, component tests"

**Rule:** Specific triggers better than generic.

---

## Testing Scenarios

### Scenario 1: Testing Framework Skill

**Description:**
```yaml
description: "Write, generate, debug, and fix unit tests, integration tests, e2e tests with Jest, Vitest, Testing Library, mocks, spies, fixtures. Use when testing code, writing tests, debugging failures, or mocking dependencies."
```

**Test Queries:**

| Query | Match? | Why |
|-------|--------|-----|
| "Write unit tests for this component" | ✅ Yes | Contains "write", "unit tests", "component" |
| "Debug my failing Jest test" | ✅ Yes | Contains "debug", "failing", "Jest", "test" |
| "Mock this API call" | ✅ Yes | Contains "mock", "API" |
| "Create integration tests" | ✅ Yes | Contains "create" (generate), "integration tests" |
| "Set up test coverage" | ⚠️ Maybe | Contains "test" but not "coverage" or "setup" |

**Fix for last query:** Add "coverage" to description or use more general "configure" verb.

### Scenario 2: API Documentation Skill

**Description:**
```yaml
description: "Generate, create, write, and maintain API documentation with OpenAPI specs, Swagger, JSDoc, TypeScript definitions. Use when documenting APIs, creating OpenAPI schemas, writing endpoint docs, or generating API references."
```

**Test Queries:**

| Query | Match? | Why |
|-------|--------|-----|
| "Generate OpenAPI spec from code" | ✅ Yes | Contains "generate", "OpenAPI", "spec", "code" |
| "Document this REST API" | ✅ Yes | Contains "document", "API" |
| "Create Swagger documentation" | ✅ Yes | Contains "create", "Swagger", "documentation" |
| "Update API docs for new endpoint" | ✅ Yes | Contains "update", "API", "docs", "endpoint" |
| "Validate my OpenAPI schema" | ❌ No | Contains "OpenAPI" but not "validate" |

**Fix for last query:** Add "validate" verb to description.

---

## Scope Guidance

### Good Skill Scope

**One skill for markdown editing:**
- All markdown file operations (create, edit, format, organize)
- Cohesive capability set
- Single domain (markdown)

**Separate skill for git releases:**
- Focused on release workflow
- Different domain from markdown
- Complementary but not overlapping

**One skill for test generation:**
- All test-related creation (unit, integration, e2e)
- Cohesive around "testing"

### Bad Skill Scope

**❌ Mega-skill handling too much:**
- One skill for: git operations + releases + changelogs + CI/CD + deployment + documentation
- Too broad, dilutes activation signals
- Hard to maintain
- Conflicting triggers

**❌ Too narrow:**
- Separate skills for "creating markdown" vs "editing markdown"
- Unnecessary split
- User doesn't think in these terms
- Fragmented experience

### When to Split

Split a skill into multiple skills if:
- ✅ Different domains (Spring Data vs Spring Security)
- ✅ Different user goals (testing vs deployment)
- ✅ Token limit exceeded even after refactoring
- ✅ Activation conflicts (too many competing signals)

Keep as one skill if:
- ✅ Same domain (all markdown operations)
- ✅ Related capabilities (create/edit/format are related)
- ✅ User thinks of it as one task
- ✅ Within token limits

### When to Combine

Combine multiple skills into one if:
- ✅ Always used together
- ✅ Significant overlap in descriptions
- ✅ Same technology stack
- ✅ Natural workflow sequence

---

## Token Optimization

### Progressive Loading Strategy

Keep SKILL.md lean, move details to bundled resources:

**SKILL.md (1000-2000 tokens):**
- Frontmatter (required)
- Quick Start
- What I Do
- When to Use Me
- Core instructions
- Links to references

**references/ (unlimited):**
- Detailed examples
- Advanced topics
- Troubleshooting guides
- API references
- Research findings

**assets/ (unlimited):**
- Templates
- Configuration examples
- Data schemas

**scripts/ (unlimited):**
- Automation tools
- Validation scripts

### When to Use Progressive Loading

Use progressive loading when:
- ✅ Skill has extensive examples
- ✅ Multiple advanced use cases
- ✅ Detailed troubleshooting needed
- ✅ SKILL.md exceeds 2000 tokens

Example structure:
```
my-skill/
├── SKILL.md (1500 tokens - core instructions)
├── references/
│   ├── examples.md (detailed examples)
│   ├── advanced.md (advanced patterns)
│   └── troubleshooting.md (common issues)
└── assets/
    └── template.md (starter template)
```

---

## Task-Centric vs Tool-Centric Framing

### Tool-Centric (❌ Avoid)

Focuses on implementation details, not user goals:

- "This skill uses the ESLint API to lint code"
- "Utilizes PyPDF2 library for PDF manipulation"
- "Wraps the Docker CLI for container management"

**Problems:**
- Doesn't match how users think
- Misses user intent keywords
- Focuses on mechanism, not outcome

### Task-Centric (✅ Prefer)

Focuses on what user wants to accomplish:

- "Lint, format, and fix JavaScript/TypeScript code for quality and consistency"
- "Extract text and tables from PDFs, fill forms, merge documents"
- "Build, run, and manage Docker containers for development and deployment"

**Benefits:**
- Matches user mental model
- Contains goal-oriented keywords
- Focuses on outcomes

### Conversion Pattern

**Convert from tool-centric to task-centric:**

1. **Identify the tool/technology:** ESLint
2. **Ask: What does the user want?** → Fix code quality issues
3. **List user actions:** lint, format, fix, check
4. **Frame around goals:** "Lint, format, and fix code..."

---

## Related Resources

- [validation-guide.md](validation-guide.md) - How descriptions are validated
- [grading-rubric.md](grading-rubric.md) - Description scoring (35% of grade)
- [creation-workflow.md](creation-workflow.md) - When to write descriptions
