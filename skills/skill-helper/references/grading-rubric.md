# Agent Skill Grading Rubric

> Scoring system for evaluating Agent Skill quality and activation potential
> 
> **Note:** This rubric is integrated into the validation script (`scripts/validate-skill.sh`). Grades are calculated automatically during validation and used as input for additional validation checks.

---

## Grade Scale

| Grade | Score | Description |
|-------|-------|-------------|
| **A** | 90-100 | Excellent - High activation, comprehensive, well-structured |
| **B** | 80-89 | Good - Solid activation, minor improvements possible |
| **C** | 70-79 | Adequate - Will activate but inconsistently |
| **D** | 60-69 | Poor - Low activation, significant issues |
| **F** | 0-59 | Failing - Will rarely activate or is malformed |

---

## Scoring Categories

| Category | Weight | Max Points |
|----------|--------|------------|
| Description Quality | 35% | 35 |
| Structure & Organization | 25% | 25 |
| Content Quality | 20% | 20 |
| Technical Implementation | 15% | 15 |
| Specification Compliance | 5% | 5 |
| **Total** | 100% | 100 |

---

## 1. Description Quality (35 points)

The description is the PRIMARY activation mechanism. This is the most critical element.

### 1.1 Action Verb Opening (5 points)

| Points | Criteria |
|--------|----------|
| 5 | Starts with strong action verb (Build, Create, Implement, Process, Debug, Analyze) |
| 3 | Starts with weaker verb (Help, Assist, Provide, Enable) |
| 1 | Starts with noun or passive construction |
| 0 | Missing or starts with article (A, The) |

### 1.2 "Use when" Trigger Phrase (10 points)

| Points | Criteria |
|--------|----------|
| 10 | Explicit "Use when" followed by 3+ specific scenarios |
| 7 | "Use when" present with 1-2 scenarios |
| 4 | Implicit triggers without "Use when" phrase |
| 0 | No trigger scenarios at all |

### 1.3 Technology/Keyword Density (10 points)

| Points | Criteria |
|--------|----------|
| 10 | 10+ relevant technology keywords |
| 7 | 5-9 technology keywords |
| 4 | 2-4 technology keywords |
| 1 | 1 technology keyword |
| 0 | No specific technologies mentioned |

**Keywords include:** Languages, frameworks, tools, concepts, file types

### 1.4 Parenthetical Enumeration (5 points)

| Points | Criteria |
|--------|----------|
| 5 | Uses parentheticals to group sub-features: "databases (PostgreSQL, MongoDB, Redis)" |
| 3 | Some grouping but inconsistent |
| 0 | No grouping, just flat lists or prose |

### 1.5 Task-Centric Framing (5 points)

| Points | Criteria |
|--------|----------|
| 5 | Focuses on user goals and outcomes |
| 3 | Mix of tool-centric and task-centric |
| 0 | Entirely tool-centric (describes what tool does, not what user achieves) |

---

## 2. Structure & Organization (25 points)

### 2.1 Progressive Disclosure (10 points)

*Note: Token estimation uses ~4 chars/token. Line count varies (2-6 tokens/line) based on content density.*

| Points | Criteria |
|--------|----------|
| 10 | SKILL.md 1000-2000 tokens (~200-400 lines), deep content in references/, clear navigation |
| 7 | SKILL.md 500-1000 tokens or 2000-3500 tokens, some references |
| 4 | SKILL.md <500 tokens (too small) or 3500-5000 tokens (too large), minimal references |
| 0 | SKILL.md <200 tokens or >5000 tokens (spec violation) |

### 2.2 Reference Navigation (5 points)

| Points | Criteria |
|--------|----------|
| 5 | Clear navigation table/section with "Load when" guidance |
| 3 | References mentioned but no navigation section |
| 0 | No reference navigation or orphaned references |

### 2.3 Quick Start Section (5 points)

| Points | Criteria |
|--------|----------|
| 5 | Prerequisites + concrete usage example within first 30 lines |
| 3 | Quick start present but missing prerequisites or examples |
| 0 | No quick start section |

### 2.4 Decision Matrix/Quick Reference (5 points)

| Points | Criteria |
|--------|----------|
| 5 | Decision matrix or quick reference table present |
| 3 | Partial decision guidance in prose form |
| 0 | No decision guidance |

---

## 3. Content Quality (20 points)

### 3.1 Concrete Examples (8 points)

| Points | Criteria |
|--------|----------|
| 8 | Copy-paste ready commands with real flags and parameters |
| 5 | Examples present but incomplete (missing flags, placeholders) |
| 2 | Pseudocode only |
| 0 | No examples |

### 3.2 Error Handling Documentation (6 points)

| Points | Criteria |
|--------|----------|
| 6 | Error table with codes, causes, and solutions |
| 4 | Some error handling mentioned |
| 0 | No error handling documentation |

### 3.3 Prerequisites Documentation (6 points)

| Points | Criteria |
|--------|----------|
| 6 | Specific versions, API keys, environment variables documented |
| 3 | General prerequisites without specifics |
| 0 | No prerequisites documented |

---

## 4. Technical Implementation (15 points)

### 4.1 Script Quality (5 points)

| Points | Criteria |
|--------|----------|
| 5 | Scripts documented, self-contained, with error handling |
| 3 | Scripts present but poorly documented |
| 0 | Scripts missing when needed, or broken |
| N/A | No scripts needed for this skill type |

### 4.2 Cross-Skill Integration (5 points)

| Points | Criteria |
|--------|----------|
| 5 | Appropriate cross-references to related skills |
| 3 | Some integration mentioned |
| 0 | No integration when it would be beneficial |
| N/A | Standalone skill, integration not applicable |

### 4.3 Tool Expectations (5 points)

| Points | Criteria |
|--------|----------|
| 5 | Clear indication of what tools skill expects (Bash, Read, Write, etc.) |
| 3 | Implicit tool usage |
| 0 | No clarity on tool requirements |

---

## 5. Specification Compliance (5 points)

### 5.1 Name Field (2 points)

| Points | Criteria |
|--------|----------|
| 2 | Valid: lowercase, hyphens only, 1-64 chars, no consecutive hyphens |
| 0 | Invalid name format |

### 5.2 Description Field (2 points)

| Points | Criteria |
|--------|----------|
| 2 | Valid: 1-1024 characters, non-empty |
| 0 | Invalid (empty, >1024 chars, or missing) |

### 5.3 Directory Structure (1 point)

| Points | Criteria |
|--------|----------|
| 1 | Follows spec: SKILL.md present, proper subdirectories |
| 0 | Non-compliant structure |

---

## Grading Worksheet

```
Skill Name: ___________________
Date Graded: __________________

DESCRIPTION QUALITY (35 pts max)
├── Action Verb Opening:      ___ / 5
├── "Use when" Triggers:      ___ / 10
├── Keyword Density:          ___ / 10
├── Parenthetical Enum:       ___ / 5
└── Task-Centric Framing:     ___ / 5
    Subtotal:                 ___ / 35

STRUCTURE & ORGANIZATION (25 pts max)
├── Progressive Disclosure:   ___ / 10
├── Reference Navigation:     ___ / 5
├── Quick Start Section:      ___ / 5
└── Decision Matrix:          ___ / 5
    Subtotal:                 ___ / 25

CONTENT QUALITY (20 pts max)
├── Concrete Examples:        ___ / 8
├── Error Handling:           ___ / 6
└── Prerequisites:            ___ / 6
    Subtotal:                 ___ / 20

TECHNICAL IMPLEMENTATION (15 pts max)
├── Script Quality:           ___ / 5  (or N/A)
├── Cross-Skill Integration:  ___ / 5  (or N/A)
└── Tool Expectations:        ___ / 5
    Subtotal:                 ___ / 15

SPECIFICATION COMPLIANCE (5 pts max)
├── Name Field Valid:         ___ / 2
├── Description Valid:        ___ / 2
└── Directory Structure:      ___ / 1
    Subtotal:                 ___ / 5

═══════════════════════════════════════
TOTAL SCORE:                  ___ / 100

GRADE: _____ (A/B/C/D/F)

NOTES:
_________________________________
```

---

## Common Deductions

| Issue                                  | Typical Deduction |
| -------------------------------------- | ----------------- |
| Missing "Use when" phrase              | -10               |
| Vague description                      | -15 to -25        |
| Too small (<500 tokens)                | -4                |
| Too small (500-1000 tokens)            | -3                |
| Too large (2000-3500 tokens)           | -3                |
| Too large (>3500 tokens)               | -6                |
| No concrete examples                   | -8                |
| Pseudocode instead of real code        | -6                |
| Missing prerequisites                  | -6                |
| Invalid name format                    | -2                |
| No error handling docs                 | -6                |
| Tool-centric framing                   | -5                |
| Orphaned references                    | -3                |

---

## Examples by Grade

### Grade A (95 points)

```yaml
description: Build robust backend systems with modern technologies (Node.js, Python, Go, Rust), frameworks (NestJS, FastAPI, Django), databases (PostgreSQL, MongoDB, Redis), APIs (REST, GraphQL, gRPC), authentication (OAuth 2.1, JWT). Use when designing APIs, implementing authentication, optimizing database queries, setting up CI/CD pipelines, or building microservices.
```

**Strengths:** Action verb, 30+ keywords, 5+ triggers, parenthetical grouping, task-centric

### Grade C (72 points)

```yaml
description: A tool for working with databases. Supports PostgreSQL and MongoDB. Can help with queries and schema design.
```

**Issues:** Weak opening ("A tool"), only 2 keywords, no "Use when", tool-centric framing

### Grade F (45 points)

```yaml
name: DB_Tool
description: helps with stuff
```

**Issues:** Invalid name (uppercase, underscore), no action verb, no keywords, vague

---

## See Also

- [validation-guide.md](validation-guide.md) - Complete list of 34 validation checks
- [optimization-patterns.md](optimization-patterns.md) - How to write trigger-rich descriptions
- [creation-workflow.md](creation-workflow.md) - Step-by-step skill creation process
