# NX Workspace Research

Research findings for NX monorepo patterns and best practices.

## Sources

- https://nx.dev/concepts/mental-model
- https://nx.dev/features/run-tasks
- https://nx.dev/features/cache-task-results
- https://nx.dev/features/enforce-module-boundaries
- https://nx.dev/features/generate-code
- https://nx.dev/concepts/decisions/folder-structure

---

## Workspace Structure and Organization

### Core Concepts

NX is built around a metadata-driven architecture with:
- **Project Graph**: Analyzes source code to detect projects and dependencies
- **Task Graph**: Created from project graph to execute tasks in correct order
- **Affected Commands**: Change analysis to run only what's needed
- **Computation Caching**: Hash-based caching to never rebuild twice

### Folder Structure Patterns

Projects are grouped by **scope** - either by application or by section within an application.

**Recommended Structure:**
```
apps/
  booking/
  check-in/
libs/
  booking/           <-- grouping folder (app-specific)
    feature-shell/   <-- project
    data-access/
  check-in/
    feature-shell/
  shared/            <-- grouping folder (cross-app)
    data-access/     <-- shared project
    seatmap/         <-- nested grouping folder
      data-access/
      feature-seatmap/
```

### Project Identification

Projects are identified by:
- Presence of `package.json` file
- Presence of `project.json` file
- Custom plugin configuration

---

## Library Creation and Boundaries

### Library Types

1. **Feature Libraries** - Smart components, routes, lazy-loaded features
2. **UI Libraries** - Presentational/dumb components
3. **Data-Access Libraries** - State management, API clients
4. **Utility Libraries** - Pure functions, helpers

### Naming Conventions

```
libs/<scope>/<type>-<name>
```

Examples:
- `libs/booking/feature-shell`
- `libs/shared/ui-buttons`
- `libs/shared/data-access`

### Creating Libraries

```bash
# React library
nx g @nx/react:lib packages/mylib

# Angular library
nx g @nx/angular:lib packages/mylib

# Generic TypeScript library
nx g @nx/js:lib packages/mylib
```

---

## nx affected Commands for CI Efficiency

### How Affected Works

1. NX looks at files changed in your PR
2. Analyzes the nature of changes
3. Determines which projects can be affected
4. Runs only necessary tasks

### Key Commands

```bash
# Run tests only for affected projects
nx affected -t test

# Build only affected projects
nx affected -t build

# Run multiple targets on affected
nx affected -t build lint test

# View affected projects
nx affected --graph
```

### Base Branch Configuration

In `nx.json`:
```json
{
  "affected": {
    "defaultBase": "main"
  }
}
```

---

## Caching Configuration

### Local Caching

Enable caching per target in `nx.json`:
```json
{
  "targetDefaults": {
    "build": {
      "cache": true
    },
    "test": {
      "cache": true
    }
  }
}
```

### Cache Inputs and Outputs

```json
{
  "targetDefaults": {
    "build": {
      "inputs": [
        "{projectRoot}/**/*",
        "!{projectRoot}/**/*.md"
      ],
      "outputs": [
        "{workspaceRoot}/dist/{projectName}"
      ]
    }
  }
}
```

### Named Inputs

Define reusable input patterns:
```json
{
  "namedInputs": {
    "default": ["{projectRoot}/**/*"],
    "production": [
      "default",
      "!{projectRoot}/**/*.spec.ts",
      "!{projectRoot}/test-setup.ts"
    ]
  }
}
```

### Remote Caching (Nx Cloud)

```bash
# Connect to Nx Cloud
npx nx@latest connect
```

Or self-hosted options:
- S3 Cache: `@nx/s3-cache`
- GCS Cache: `@nx/gcs-cache`
- Azure Cache: `@nx/azure-cache`
- Shared FS: `@nx/shared-fs-cache`

---

## Dependency Graph Management

### Viewing the Graph

```bash
# Open interactive graph
nx graph

# Focus on specific project
nx graph --focus=myapp

# Show affected graph
nx affected --graph
```

### Implicit Dependencies

Define in `project.json`:
```json
{
  "implicitDependencies": ["shared-data-access"]
}
```

### Task Pipeline (dependsOn)

```json
{
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"]  // Run build on dependencies first
    },
    "test": {
      "dependsOn": ["build"]   // Run build on same project first
    }
  }
}
```

---

## Generators and Executors

### Using Generators

```bash
# List available generators
nx list @nx/react

# Run a generator
nx g @nx/react:component my-component --project=mylib

# Dry run
nx g @nx/react:component my-component --project=mylib --dry-run
```

### Common Generators

| Plugin | Generator | Purpose |
|--------|-----------|---------|
| @nx/react | lib | Create React library |
| @nx/react | component | Create React component |
| @nx/angular | lib | Create Angular library |
| @nx/js | lib | Create TypeScript library |
| @nx/workspace | move | Move/rename project |
| @nx/workspace | remove | Delete project |

### Local Generators

Create custom generators in `tools/generators/`:
```typescript
import { Tree, formatFiles, installPackagesTask } from '@nx/devkit';

export default async function (tree: Tree, schema: any) {
  // Implementation
  await formatFiles(tree);
  return () => {
    installPackagesTask(tree);
  };
}
```

---

## Module Boundary Enforcement with Tags

### Defining Tags

In `project.json` or `package.json`:
```json
{
  "tags": ["scope:booking", "type:feature"]
}
```

### ESLint Configuration

```javascript
// eslint.config.mjs
{
  rules: {
    '@nx/enforce-module-boundaries': [
      'error',
      {
        depConstraints: [
          {
            sourceTag: 'scope:booking',
            onlyDependOnLibsWithTags: ['scope:booking', 'scope:shared']
          },
          {
            sourceTag: 'type:feature',
            onlyDependOnLibsWithTags: ['type:ui', 'type:data-access', 'type:util']
          }
        ]
      }
    ]
  }
}
```

### Multi-Dimensional Tags

Use multiple tag dimensions:
- `scope:*` - Application scope
- `type:*` - Library type
- `platform:*` - Platform (web, mobile, etc.)

---

## Migration Strategies

### Adding NX to Existing Project

```bash
npx nx@latest init
```

### Import Existing Project

```bash
nx g @nx/workspace:import-project <path-to-project>
```

### Migrating from Turborepo

NX provides automatic migration:
```bash
npx nx@latest init
```

### Keeping NX Updated

```bash
# Check for updates
nx migrate latest

# Apply migrations
nx migrate --run-migrations
```

---

## project.json vs package.json Configuration

### project.json (Recommended for NX-specific config)

```json
{
  "name": "my-lib",
  "root": "libs/my-lib",
  "sourceRoot": "libs/my-lib/src",
  "projectType": "library",
  "tags": ["scope:shared", "type:util"],
  "targets": {
    "build": {
      "executor": "@nx/js:tsc",
      "options": {
        "outputPath": "dist/libs/my-lib"
      }
    }
  }
}
```

### package.json (For npm/pnpm workspaces)

```json
{
  "name": "@myorg/my-lib",
  "scripts": {
    "build": "tsc",
    "test": "jest"
  },
  "nx": {
    "tags": ["scope:shared"],
    "targets": {
      "build": {
        "outputs": ["{projectRoot}/dist"]
      }
    }
  }
}
```

### Inferred Tasks (Project Crystal)

Plugins auto-detect configuration:
```json
{
  "plugins": [
    {
      "plugin": "@nx/vite/plugin",
      "options": {
        "buildTargetName": "build",
        "testTargetName": "test"
      }
    }
  ]
}
```

---

## Key CLI Commands Reference

### Task Execution

```bash
nx <target> <project>              # Run single task
nx run-many -t build               # Run for all projects
nx run-many -t build -p app1 app2  # Run for specific projects
nx affected -t test                # Run for affected only
```

### Workspace Management

```bash
nx graph                           # View dependency graph
nx list                            # List installed plugins
nx list @nx/react                  # List plugin generators
nx show project myapp              # Show project config
nx show project myapp --web        # Show in browser
```

### Project Operations

```bash
nx g @nx/workspace:move --project=old-name new-path
nx g @nx/workspace:remove old-project
```

### Caching

```bash
nx reset                           # Clear local cache
nx run build --skip-nx-cache       # Skip cache for one run
```

---

## Common Errors and Solutions

### "Cannot find project"
- Ensure `project.json` or `package.json` exists
- Run `nx reset` to refresh project graph

### Cache Misses
- Check inputs configuration
- Verify no untracked files affect build
- Use `nx run build --verbose` to debug

### Circular Dependencies
- Use `nx graph` to visualize
- Refactor to extract shared code
- Add `implicitDependencies` if needed

### Module Boundary Violations
- Check project tags
- Update ESLint `depConstraints`
- Consider moving shared code

---

## Performance Tips

1. **Use Affected Commands** - Only run what changed
2. **Enable Remote Caching** - Share cache across CI/team
3. **Configure Inputs Properly** - Exclude non-essential files
4. **Parallelize Tasks** - Use `--parallel` flag
5. **Use Inferred Tasks** - Let plugins configure automatically
6. **Batch TypeScript Compilation** - Enable TSC batch mode
