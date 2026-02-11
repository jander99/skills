# Markdown Editor Examples

## Creating a Research Document

### User Input
"Research JWT authentication best practices and document findings"

### Agent Action
Create ./docs/research/jwt-authentication-best-practices.md

### Output File
```markdown
---
title: JWT Authentication Best Practices
created: 2025-12-25T14:30:00Z
last_modified: 2025-12-25T14:30:00Z
author: Jane Developer
type: research
tags: [authentication, jwt, security]
---

# JWT Authentication Best Practices

## Overview
[Research content here...]
```

## Creating a Plan Document

### User Input
"Create an implementation plan for migrating to PostgreSQL"

### Agent Action
Create ./docs/plans/postgresql-migration-implementation.md

### Output File
```markdown
---
title: PostgreSQL Migration Implementation Plan
created: 2025-12-25T15:00:00Z
last_modified: 2025-12-25T15:00:00Z
author: Jane Developer
type: plan
tags: [database, migration, postgresql]
---

# PostgreSQL Migration Implementation Plan

## Goals
[Plan content here...]
```

## Creating a README (No Frontmatter)

### User Input
"Write a README for the authentication module"

### Agent Action
Create ./src/auth/README.md (or appropriate module location)

### Output File
```markdown
# Authentication Module

## Overview
This module handles user authentication using JWT tokens.

## Installation
[Installation instructions...]

## Usage
[Usage examples...]
```

## Editing an Existing Document

### User Input
"Update the PostgreSQL migration plan with new timeline"

### Agent Action
1. Read ./docs/plans/postgresql-migration-implementation.md
2. Preserve frontmatter except update last_modified
3. Update content

### Updated Frontmatter
```markdown
---
title: PostgreSQL Migration Implementation Plan
created: 2025-12-25T15:00:00Z
last_modified: 2025-12-25T16:45:00Z  # Updated!
author: Jane Developer  # Preserved!
type: plan
tags: [database, migration, postgresql]
---
```

## Handling Filename Collision

### Scenario
File `./docs/plans/implementation-plan.md` already exists

### Action
Create more descriptive name: `./docs/plans/oauth-implementation-plan.md`
Instead of: `./docs/plans/implementation-plan-2.md` ❌
