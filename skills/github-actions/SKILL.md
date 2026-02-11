---
name: github-actions
description: Create, configure, optimize, and debug GitHub Actions CI/CD workflows, jobs, triggers, caching, matrix builds, reusable workflows, and secrets. Use when writing .github/workflows YAML, fixing pipeline failures, or improving CI speed.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: ci-cd
---

# GitHub Actions

## What I Do

- Create and configure CI/CD workflow YAML files in `.github/workflows/`
- Set up workflow triggers (push, pull_request, schedule, workflow_dispatch)
- Design job dependencies with `needs` for sequential/parallel execution
- Configure matrix builds for multi-environment testing
- Implement caching strategies to reduce CI time
- Create reusable workflows and composite actions
- Manage secrets and OIDC authentication securely
- Debug failing workflows and fix common errors

## When to Use Me

Use this skill when you:
- Create, write, or generate a new GitHub Actions workflow
- Configure CI/CD pipelines for build, test, and deploy
- Set up matrix builds for multiple OS/Node/language versions
- Implement or fix dependency caching (npm, pip, gradle)
- Create reusable workflows to share across repositories
- Debug workflow failures or "resource not accessible" errors
- Optimize slow CI pipelines to improve build times
- Configure secrets, environment variables, or OIDC

## Workflow Structure

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci && npm run build && npm test
```

### Job Dependencies
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps: [...]
  test:
    runs-on: ubuntu-latest
    steps: [...]
  deploy:
    needs: [lint, test]  # Waits for both
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
```

### Matrix Builds
```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
        node: [18, 20, 22]
      fail-fast: false
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
```

## Caching Strategies

### Setup Actions (Recommended)
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'  # Built-in caching

- uses: actions/setup-python@v5
  with:
    python-version: '3.12'
    cache: 'pip'
```

### Custom Cache
```yaml
- uses: actions/cache@v4
  with:
    path: node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
    restore-keys: ${{ runner.os }}-node-
```

## Secrets Management

```yaml
# Repository secrets
env:
  API_KEY: ${{ secrets.API_KEY }}

# Environment-specific
jobs:
  deploy:
    environment: production
    steps:
      - run: echo "${{ secrets.PROD_KEY }}"

# OIDC (no long-lived secrets)
jobs:
  deploy:
    permissions:
      id-token: write
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123:role/deploy
```

## Security Best Practices

### Fork PR Security
```yaml
# pull_request is safe - secrets not exposed to forks
on:
  pull_request:  # Runs in fork context, no secrets

# pull_request_target is DANGEROUS - runs with repo secrets
on:
  pull_request_target:  # Only use if you audit the PR code first!
```

### Minimal Permissions
```yaml
permissions:
  contents: read  # Minimum needed for checkout

jobs:
  build:
    permissions:
      contents: read
      packages: write  # Only if publishing
```

### Artifacts for Cross-Job Data
```yaml
jobs:
  build:
    steps:
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  deploy:
    needs: build
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
          path: dist/
```

## Reusable Workflows

```yaml
# .github/workflows/reusable-ci.yml
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '20'
    secrets:
      npm-token:
        required: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
```

```yaml
# Calling workflow
jobs:
  ci:
    uses: ./.github/workflows/reusable-ci.yml
    with:
      node-version: '20'
    secrets: inherit
```

## Context7 Integration

For current GitHub Actions docs, use Context7 MCP server:
1. `context7_resolve-library-id` with "github actions"
2. `context7_query-docs` for topics like "caching", "matrix strategy", "reusable workflows"

## Common Errors

| Error | Solution |
|-------|----------|
| "Resource not accessible" | Add `permissions:` block with required scopes |
| Cache miss | Include `runner.os` in key; check 10GB limit |
| "Workflow not found" | Must exist in default branch for scheduled runs |
| Slow builds | Enable caching; use `concurrency`; add `paths` filter |

## Performance Optimization

```yaml
# Cancel redundant runs
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Path filtering
on:
  push:
    paths: ['src/**', 'package*.json']
    paths-ignore: ['**/*.md', 'docs/**']

# Timeouts
jobs:
  build:
    timeout-minutes: 15
```

## Related Skills

| Skill | Use When |
|-------|----------|
| [nx-workspace](../nx-workspace/SKILL.md) | CI for Nx monorepos with affected commands |

## References

| Reference | Description |
|-----------|-------------|
| [research.md](references/research.md) | Detailed research on all topics |
| [GitHub Docs](https://docs.github.com/en/actions) | Official documentation |
