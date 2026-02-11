# Document Types & Conventions

Detailed guidance for each document type handled by the markdown-editor skill.

---

## Research Documents

**Location:** `./docs/research/`
**Frontmatter:** Required

Use when: investigating, analyzing, researching, exploring topics

### Process

1. Create directory: `mkdir -p ./docs/research/`
2. Generate descriptive filename: `api-authentication-analysis.md`
3. Extract author: `git config user.name`
4. Apply frontmatter with `type: research`
5. Write content with research structure

### Filename Examples

- `jwt-authentication-best-practices.md`
- `database-performance-analysis.md`
- `competitor-feature-comparison.md`

---

## Plan Documents

**Location:** `./docs/plans/`
**Frontmatter:** Required

Use when: planning implementations, strategies, migrations, roadmaps

### Process

1. Create directory: `mkdir -p ./docs/plans/`
2. Generate descriptive filename: `oauth-implementation-plan.md`
3. Extract author: `git config user.name`
4. Apply frontmatter with `type: plan`
5. Write content with plan structure (goals, phases, timeline)

### Filename Examples

- `database-migration-strategy.md`
- `api-v2-implementation-plan.md`
- `infrastructure-scaling-roadmap.md`

---

## General Documentation

**Location:** `./docs/`
**Frontmatter:** Required

Use when: writing general docs, guides, notes, tutorials

### Process

1. Create directory: `mkdir -p ./docs/`
2. Generate descriptive filename: `deployment-guide.md`
3. Extract author: `git config user.name`
4. Apply frontmatter with `type: documentation` or `type: rambling`
5. Write content

### Filename Examples

- `api-reference-guide.md`
- `development-setup-notes.md`
- `architecture-overview.md`

---

## README Files

**Location:** Project root or module directory
**Frontmatter:** None (traditional markdown)

Use when: creating project overviews, module documentation

### Standard Sections

```markdown
# Project Name

## Overview
Brief description of the project.

## Installation
How to install dependencies and set up.

## Usage
How to use the project with examples.

## Configuration
Available configuration options.

## Contributing
Guidelines for contributors.

## License
License information.
```

### Location Examples

- `./README.md` - Project root
- `./src/auth/README.md` - Module documentation
- `./packages/core/README.md` - Monorepo package

---

## TODO Files

**Location:** Project root
**Frontmatter:** None

Use when: managing task lists, action items

### Format

```markdown
# TODO

## High Priority
- [ ] Critical task one
- [ ] Critical task two

## Medium Priority
- [ ] Standard task
- [x] Completed task

## Low Priority
- [ ] Nice to have
```

---

## CHANGELOG Files

**Location:** Project root
**Frontmatter:** None

Use when: tracking version changes, releases

### Format (Keep a Changelog)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- New feature description

### Changed
- Modified behavior description

### Fixed
- Bug fix description

## [1.0.0] - 2025-01-15

### Added
- Initial release features
```

---

## Frontmatter Deep Dive

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| title | string | Descriptive document title |
| created | ISO 8601 | Creation timestamp (UTC) |
| last_modified | ISO 8601 | Last edit timestamp (UTC) |
| author | string | From `git config user.name` |
| type | enum | research, plan, documentation, rambling |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| tags | array | Categorization tags |
| status | string | draft, review, final |
| related | array | Links to related documents |

### Timestamp Format

Always use ISO 8601 with UTC timezone:
- Correct: `2025-12-25T14:30:00Z`
- Wrong: `2025-12-25`, `Dec 25, 2025`, `12/25/2025`

---

## Directory Creation Commands

```bash
# Research documents
mkdir -p ./docs/research/

# Plan documents  
mkdir -p ./docs/plans/

# General documentation
mkdir -p ./docs/

# Get author name
git config user.name
```

---

## Editing Existing Documents

When editing an existing document:

1. **Read** the current file
2. **Preserve** `created` and `author` fields
3. **Update** `last_modified` to current UTC time
4. **Modify** content as needed
5. **Write** updated file

Never change the original `created` timestamp or `author` field.
