---
name: nx-workspace
description: Create, configure, manage, and optimize NX monorepo workspaces. Generate libraries, run affected commands, configure caching, enforce module boundaries with tags, visualize dependency graphs, and set up CI pipelines. Use when building, structuring, or scaling TypeScript/JavaScript monorepos.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: monorepo
---

# NX Workspace

## What I Do

- Create and structure NX monorepo workspaces with apps and libs
- Generate libraries using NX generators (`nx g @nx/react:lib`, `nx g @nx/angular:lib`)
- Configure and optimize task caching (local and remote)
- Run affected commands for efficient CI (`nx affected -t build test`)
- Enforce module boundaries using project tags and ESLint rules
- Visualize and analyze the dependency graph (`nx graph`)
- Set up task pipelines with `dependsOn` configuration
- Move, rename, and remove projects safely
- Version and publish releases with `nx release`

## When to Use Me

Use this skill when you:
- Create, initialize, or set up an NX monorepo workspace
- Generate, scaffold, or add new libraries or applications
- Configure, enable, or troubleshoot task caching
- Run only affected projects in CI pipelines
- Enforce, define, or fix module boundary rules with tags
- Visualize, analyze, or debug the dependency graph
- Move, rename, or restructure projects
- Optimize build times and CI performance

## Workspace Structure

```
apps/
  web-app/
  admin-app/
libs/
  web-app/                 # App-specific grouping folder
    feature-shell/
  shared/                  # Cross-app grouping folder
    ui/                    # Shared UI components
    data-access/           # Shared API clients
    util/                  # Shared utilities
```

**Library Types:** feature (routes), ui (components), data-access (state/API), util (helpers)

## Library Patterns

```bash
# Generate libraries
nx g @nx/react:lib libs/shared/ui-buttons
nx g @nx/angular:lib libs/booking/feature-shell
nx g @nx/js:lib libs/shared/util-helpers

# With tags
nx g @nx/react:lib my-lib --directory=libs/shared --tags="scope:shared,type:ui"

# Move/remove projects
nx g @nx/workspace:move --project=old-name new-path
nx g @nx/workspace:remove old-project
```

**Naming:** `libs/<scope>/<type>-<name>` (e.g., `libs/booking/feature-shell`)

## Affected Commands

```bash
nx affected -t test                    # Test affected only
nx affected -t build lint              # Multiple targets
nx affected --graph                    # View affected graph
nx affected -t test --base=main        # Specific base branch
```

Configure in `nx.json`: `{ "affected": { "defaultBase": "main" } }`

## Caching Configuration

```json
// nx.json
{
  "namedInputs": {
    "default": ["{projectRoot}/**/*"],
    "production": ["default", "!{projectRoot}/**/*.spec.ts"]
  },
  "targetDefaults": {
    "build": {
      "cache": true,
      "inputs": ["production", "^production"],
      "outputs": ["{projectRoot}/dist"],
      "dependsOn": ["^build"]
    },
    "test": { "cache": true },
    "lint": { "cache": true }
  }
}
```

**Remote Caching:**
```bash
npx nx@latest connect          # Nx Cloud
nx add @nx/s3-cache            # Self-hosted S3
```

## Module Boundary Enforcement

Define tags in `project.json`:
```json
{ "tags": ["scope:booking", "type:feature"] }
```

Configure ESLint:
```javascript
'@nx/enforce-module-boundaries': ['error', {
  depConstraints: [
    { sourceTag: 'scope:booking', onlyDependOnLibsWithTags: ['scope:booking', 'scope:shared'] },
    { sourceTag: 'type:feature', onlyDependOnLibsWithTags: ['type:ui', 'type:data-access', 'type:util'] },
    { sourceTag: 'type:ui', onlyDependOnLibsWithTags: ['type:ui', 'type:util'] }
  ]
}]
```

**Tag Dimensions:** `scope:*` (app), `type:*` (library type), `platform:*` (web/mobile)

## Context7 Integration

For up-to-date NX documentation, use Context7 MCP server:
```
Query: "nx affected command usage"
Library: /nrwl/nx
```

## Common Errors

| Error | Solution |
|-------|----------|
| "Cannot find project" | `nx reset` to refresh project graph |
| Cache misses | `nx run build --verbose` to debug inputs |
| Circular dependencies | `nx graph --focus=lib` to visualize, then refactor |
| Boundary violations | Check tags in `project.json`, update ESLint config |

## Essential Commands

```bash
# Workspace
nx graph                              # Dependency graph
nx show project myapp                 # Show project config (JSON)
nx graph --focus=myapp                # Visual graph focused on project
nx list @nx/react                     # Available generators

# Execution
nx run myapp:build                    # Single task
nx run-many -t build test             # All projects
nx affected -t test                   # Affected only

# Maintenance
nx migrate latest                     # Check updates
nx reset                              # Clear cache
```

## Migration Workflow

```bash
# Check for updates
nx migrate latest

# Review migrations
cat migrations.json

# Run migrations
nx migrate --run-migrations

# Clean up
rm migrations.json
```

## Release with `nx release`

`nx release` is the built-in versioning, changelog, and publishing subcommand. It reads `nx.json` + each project's `package.json`, derives the next version (semver or independent), updates versions across the workspace, generates a changelog, creates git tags + GitHub releases, and (optionally) publishes to npm.

### One-shot dry run

```bash
# Preview what would change without writing anything
nx release --dry-run
```

### Version and publish to npm

```bash
# Bump versions, update lockfiles, tag, push, publish
nx release version minor          # bump across workspace (e.g. 1.2.0 -> 1.3.0)
nx release publish                # publish all publishable projects to npm
```

Or combine into a single command:

```bash
nx release --skip-publish=false   # version + publish in one step
```

### Independent versioning per project

In `nx.json`, set the release config to version each project independently (common for libraries shipped separately):

```json
{
  "release": {
    "projectsRelationship": "independent",
    "version": {
      "generatorOptions": {
        "packageRoot": "dist/{projectRoot}"
      }
    }
  }
}
```

### Configure groups and changelog

`nx release` supports release groups — projects that version together. Define them in `nx.json`:

```json
{
  "release": {
    "groups": {
      "shared": {
        "projects": ["shared-ui", "shared-utils"],
        "version": { "generatorOptions": { "currentVersionResolver": "git-tag" } }
      }
    },
    "changelog": {
      "workspaceChangelog": { "file": "CHANGELOG.md" },
      "projectChangelogs": true
    }
  }
}
```

### Common errors

| Error | Solution |
|-------|----------|
| `ENOPKG: No matching package.json` | Run from workspace root or set `release.version.generatorOptions.packageRoot` |
| Drift between lockfile and versions | Run `nx release version patch --skip-lockfile-update=false` (default true in 20+) |
| Tag already exists | Use `--specifier=patch` or `nx release version --git-tag-match-pattern` |
| Want to skip publish | `nx release --skip-publish=true` for version-only releases |

> `nx release` replaces older hand-rolled release scripts (Changesets, Lerna-style flows). For new workspaces, prefer `nx release`; for older workspaces, the [Nx migration guide](https://nx.dev/recipes/nx-release/automate-git-releases) covers importing an existing changeset history.

## CI Base/Head Calculation

```yaml
# GitHub Actions
- name: Set base and head
  uses: nrwl/nx-set-shas@v4

- name: Run affected
  run: npx nx affected -t build test --base=$NX_BASE --head=$NX_HEAD
```

## References

| Reference | Use When |
|-----------|----------|
| [research.md](references/research.md) | Deep dive into NX patterns and configuration |

## Related Skills

- **angular-components** - Building Angular component libraries
- **angular-testing** - Testing Angular applications in NX
