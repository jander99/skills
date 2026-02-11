# Agent Skill Template

> Canonical template for creating high-activation Agent Skills

---

## Directory Structure

```
skill-name/
├── SKILL.md              # Required - Main skill file
├── references/           # Optional - Deep documentation
│   ├── getting-started.md
│   ├── api-reference.md
│   └── troubleshooting.md
├── scripts/              # Optional - Executable code
│   └── helper.py
└── assets/               # Optional - Static resources
    └── template.html
```

---

## SKILL.md Template

### Frontmatter

```yaml
---
name: skill-name
description: [ACTION VERB] [domain/capability] with [technologies/tools]. Capabilities include [feature-1] ([sub-features]), [feature-2] ([sub-features]). Use when [trigger-1], [trigger-2], [trigger-3], or [trigger-N]. Supports [additional-context].
license: MIT
compatibility: opencode
metadata:
  version: 1.0.0
  audience: developers
  workflow: your-workflow
---
```

### Body Structure

```markdown
# Skill Name

[1-2 sentence overview of what this skill does and its primary value proposition.]

## When to Use

- [Specific scenario 1 - complete user intent]
- [Specific scenario 2 - complete user intent]
- [Specific scenario 3 - complete user intent]
- [Edge case scenario]

## Quick Start

### Prerequisites

- [Dependency 1 with version]
- [Environment variable: `VAR_NAME`]
- [Required tool/package]

### Basic Usage

```bash
# Actual command with real flags
command --flag value --option
```

## Core Workflow

### Step 1: [Action]

[Brief instruction]

```code
# Concrete example
```

### Step 2: [Action]

[Brief instruction]

## Reference Navigation

| Topic     | Reference             | Load When           |
| --------- | --------------------- | ------------------- |
| [Topic 1] | `references/file1.md` | [Trigger condition] |
| [Topic 2] | `references/file2.md` | [Trigger condition] |

## Quick Decision Matrix

| Need     | Solution     |
| -------- | ------------ |
| [Need 1] | [Solution 1] |
| [Need 2] | [Solution 2] |

## Error Handling

| Error                | Cause        | Solution    |
| -------------------- | ------------ | ----------- |
| [Error code/message] | [Root cause] | [Fix steps] |

## Resources

- [Official docs link]
- [API reference link]
```

---

## Description Formula

The high-activation description follows this structure:

```
[ACTION VERB] [domain] with [technologies].
Capabilities include [feature-1] ([sub-features]), [feature-2] ([sub-features]).
Use when [trigger-1], [trigger-2], [trigger-3], or [trigger-N].
[Optional: Supports/Includes additional-context.]
```

### Components

1. **Action Verb** (required): Build, Create, Implement, Process, Debug, Analyze, Extract, Generate
2. **Domain** (required): The problem space (backend systems, PDF documents, authentication)
3. **Technologies** (required): Specific tools, frameworks, languages in parenthetical groups
4. **"Use when" triggers** (required): 3+ specific scenarios starting with "Use when"
5. **Additional context** (optional): Supported features, limitations, integrations

### Length Guidance

| Length | Recommendation |
| ------ | -------------- |
| <100 chars | Too short - insufficient trigger density |
| 100-200 chars | Minimum viable |
| 200-400 chars | Optimal range |
| 400-1024 chars | Acceptable for complex skills |
| >1024 chars | Invalid (spec limit) |

---

## Example: Grade A Skill

```yaml
---
name: backend-development
description: Build robust backend systems with modern technologies (Node.js, Python, Go, Rust), frameworks (NestJS, FastAPI, Django), databases (PostgreSQL, MongoDB, Redis), APIs (REST, GraphQL, gRPC), authentication (OAuth 2.1, JWT), testing strategies, security best practices (OWASP Top 10), performance optimization, scalability patterns (microservices, caching, sharding), DevOps practices (Docker, Kubernetes, CI/CD), and monitoring. Use when designing APIs, implementing authentication, optimizing database queries, setting up CI/CD pipelines, handling security vulnerabilities, building microservices, or developing production-ready backend systems.
license: MIT
---
```

**Why it scores A:**
- Action verb opening ("Build")
- 30+ technology keywords
- 7 explicit "Use when" scenarios
- Excellent parenthetical grouping
- Task-centric framing
