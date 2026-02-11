# GitHub Actions Research

## Overview

GitHub Actions is a CI/CD platform that automates build, test, and deployment pipelines. Workflows are defined in YAML files stored in `.github/workflows/`.

## Core Components

### Workflows
- YAML files in `.github/workflows/` directory
- Triggered by events, schedules, or manual dispatch
- Contain one or more jobs that run in parallel by default
- Can reference other workflows (reusable workflows)

### Events (Triggers)

#### Push and Pull Request Events
```yaml
on:
  push:
    branches: [main, develop]
    paths:
      - 'src/**'
      - '!src/**/*.test.ts'
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
```

#### Scheduled Events (Cron)
```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
```

#### Manual Dispatch with Inputs
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
```

#### Workflow Call (Reusable Workflows)
```yaml
on:
  workflow_call:
    inputs:
      config-path:
        required: true
        type: string
    secrets:
      token:
        required: true
```

### Jobs

Jobs run on runners (GitHub-hosted or self-hosted). By default, jobs run in parallel.

#### Job Dependencies
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build
      
  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: npm test
      
  deploy:
    needs: [build, test]
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

#### Conditional Execution
```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
```

### Matrix Builds

Run jobs across multiple configurations:

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [18, 20, 22]
        exclude:
          - os: macos-latest
            node: 18
        include:
          - os: ubuntu-latest
            node: 22
            experimental: true
      fail-fast: false
      max-parallel: 4
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
```

## Caching Strategies

### Direct Cache Action
```yaml
- name: Cache node modules
  id: cache-npm
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

### Setup Actions with Built-in Caching
Most setup-* actions support caching:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'

- uses: actions/setup-python@v5
  with:
    python-version: '3.12'
    cache: 'pip'

- uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: '21'
    cache: 'gradle'

- uses: actions/setup-go@v5
  with:
    go-version: '1.22'
    cache: true
```

### Cache Key Strategies
- Use `hashFiles()` for lock files
- Include OS in key for platform-specific dependencies
- Use restore-keys for fallback matching
- Cache key max length: 512 characters
- Cache storage limit: 10 GB per repository (default)
- Caches not accessed in 7 days are evicted

### Cache Scope
- Caches are scoped to branches
- Feature branches can access caches from default branch
- Pull requests can access caches from base branch

## Secrets Management

### Repository/Organization Secrets
```yaml
steps:
  - name: Deploy
    env:
      API_KEY: ${{ secrets.API_KEY }}
    run: ./deploy.sh
```

### Environment Secrets
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: echo "Deploying with ${{ secrets.PROD_API_KEY }}"
```

### GITHUB_TOKEN
Automatically provided, scoped to repository:
```yaml
steps:
  - uses: actions/checkout@v4
  - name: Create PR
    run: gh pr create --title "Update"
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### OpenID Connect (OIDC)
Passwordless authentication to cloud providers:
```yaml
jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/deploy
          aws-region: us-east-1
```

## Reusable Workflows

### Creating Reusable Workflow
```yaml
# .github/workflows/reusable-build.yml
name: Reusable Build

on:
  workflow_call:
    inputs:
      node-version:
        required: false
        type: string
        default: '20'
    outputs:
      artifact-name:
        description: "Name of uploaded artifact"
        value: ${{ jobs.build.outputs.artifact }}
    secrets:
      npm-token:
        required: false

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      artifact: ${{ steps.upload.outputs.name }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci && npm run build
```

### Calling Reusable Workflow
```yaml
jobs:
  build:
    uses: org/repo/.github/workflows/reusable-build.yml@main
    with:
      node-version: '20'
    secrets:
      npm-token: ${{ secrets.NPM_TOKEN }}
    # Or inherit all secrets:
    # secrets: inherit
```

### Nesting Limits
- Maximum 10 levels of nested workflows
- No circular references allowed

## Composite Actions

For sharing steps (not full workflows):
```yaml
# .github/actions/setup-project/action.yml
name: 'Setup Project'
description: 'Setup Node.js and install dependencies'
inputs:
  node-version:
    description: 'Node.js version'
    default: '20'
runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
    - run: npm ci
      shell: bash
```

## Artifact Management

### Upload Artifacts
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 5
```

### Download Artifacts
```yaml
- uses: actions/download-artifact@v4
  with:
    name: build-output
    path: ./dist
```

### Share Between Jobs
```yaml
jobs:
  build:
    outputs:
      artifact-id: ${{ steps.upload.outputs.artifact-id }}
    steps:
      - id: upload
        uses: actions/upload-artifact@v4
        
  deploy:
    needs: build
    steps:
      - uses: actions/download-artifact@v4
```

## Workflow Optimization

### Concurrency Control
Prevent duplicate runs:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### Path Filtering
Only run on relevant changes:
```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package*.json'
      - '.github/workflows/ci.yml'
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

### Job Outputs for Conditional Steps
```yaml
jobs:
  changes:
    outputs:
      frontend: ${{ steps.filter.outputs.frontend }}
    steps:
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            frontend:
              - 'frontend/**'
              
  build-frontend:
    needs: changes
    if: needs.changes.outputs.frontend == 'true'
```

### Timeouts
```yaml
jobs:
  test:
    timeout-minutes: 30
    steps:
      - run: npm test
        timeout-minutes: 10
```

## Self-Hosted Runners

### Considerations
- Security: runs code from PRs on your infrastructure
- Maintenance: you manage updates and scaling
- Cost: avoid GitHub-hosted runner costs for high-volume
- Performance: can have persistent caches and specialized hardware

### Labels
```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, x64, gpu]
```

### Actions Runner Controller (ARC)
For Kubernetes-based autoscaling runners.

## GitHub-Hosted Runner Specs

| Runner | vCPUs | RAM | Storage |
|--------|-------|-----|---------|
| ubuntu-latest | 4 | 16 GB | 14 GB SSD |
| windows-latest | 4 | 16 GB | 14 GB SSD |
| macos-latest | 3 | 14 GB | 14 GB SSD |

## Usage Limits

- Workflow run: 6 hours max (35 days for self-hosted)
- Job execution: 6 hours max
- Concurrent jobs: varies by plan (20-180)
- Matrix: 256 jobs per workflow
- Nested reusable workflows: 10 levels
- API requests: 1,000 per hour per repo
- Cache storage: 10 GB default per repo

## Common Patterns

### CI for Pull Requests
```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
```

### Release Workflow
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build
      - uses: softprops/action-gh-release@v2
        with:
          files: dist/*
          generate_release_notes: true
```

### Deploy to Multiple Environments
```yaml
jobs:
  deploy-staging:
    environment: staging
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh staging

  deploy-production:
    needs: deploy-staging
    environment: production
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh production
```

## Common Errors and Solutions

### "Resource not accessible by integration"
- Check GITHUB_TOKEN permissions
- Add explicit permissions block

### Cache miss despite same lockfile
- Check if OS is part of cache key
- Verify paths are correct
- Check cache storage limits

### "Workflow not found"
- Ensure workflow file is in default branch for scheduled runs
- Check file is in `.github/workflows/`
- Verify YAML syntax

### "Context access might be invalid"
- Some contexts unavailable in certain trigger types
- Check context availability per event type

### Timeout Issues
- Add explicit timeout-minutes
- Split long jobs into parallel steps
- Use caching to speed up dependency installation

## Best Practices Summary

1. **Use caching aggressively** - setup-* actions with cache, actions/cache
2. **Implement concurrency controls** - prevent duplicate runs
3. **Filter by paths** - only run when relevant files change
4. **Parallelize jobs** - use matrix builds and independent jobs
5. **Use reusable workflows** - reduce duplication across repos
6. **Pin action versions** - use SHA for production, tags for development
7. **Minimize secrets exposure** - use OIDC over long-lived credentials
8. **Set timeouts** - prevent runaway jobs from consuming resources
9. **Use artifacts sparingly** - they consume storage and transfer time
10. **Monitor workflow metrics** - track duration trends

## References

- https://docs.github.com/en/actions
- https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions
- https://docs.github.com/en/actions/reference/events-that-trigger-workflows
- https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows
- https://docs.github.com/en/actions/using-workflows/reusing-workflows
