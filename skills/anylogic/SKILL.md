---
name: anylogic
description: Create, build, edit, validate, run, and export AnyLogic models with local-binary workflows and documented model structures (statecharts, parameter expressions, experiments, CLI, XML, Java, ALP, ALPX). Use when building or revising AnyLogic statecharts, changing parameter expressions, probing a local installation, running experiments, exporting standalone applications, or checking which documented binary surfaces are actually available.
license: MIT
metadata:
  version: 1.0.0
  author: JDA0041
  audience: developers, modelers, agents
  workflow: anylogic-local-binary
---

## Quick Start

**Prerequisites:**
- A local AnyLogic installation or exported AnyLogic model artifacts
- Read/write access to the target model directory
- Bash access for install discovery and local binary probing
- A backup or VCS checkpoint before changing `.alp`, `.alpx`, or related XML files

**Tools Used:** Read, Write, Edit, Bash, Grep, Glob

**Basic Usage:**
```text
User: "Add a statechart transition to this AnyLogic agent"
Agent:
1. Detects model format and local install surface
2. Reads the relevant model files before editing
3. Updates statechart or parameter-expression XML surgically
4. Verifies references, expressions, and runnable command surface
```

## What I Do

- Discover local AnyLogic installations and likely executable paths with `scripts/discover-anylogic.sh` on bash-based environments
- Inspect model layouts and distinguish `.alp` single-file models from `.alpx` multi-file models
- Edit parameter defaults and parameter expressions in model files with minimal, targeted changes
- Build or revise statechart structures by updating the model definition files rather than inventing unsupported GUI automation
- Prepare and run documented local-binary workflows for experiment execution and standalone export when the installed edition supports them
- Summarize what the local binary appears to expose versus what still requires manual IDE interaction
- Keep scope explicit when the requested action is not documented or cannot be confirmed from the local installation

## When to Use Me

Use this skill when you:
- Create or revise AnyLogic statecharts in existing model files
- Change parameter expressions, defaults, formulas, or experiment inputs
- Probe a local AnyLogic installation to see what binary surfaces are available
- Run or export AnyLogic experiments from the command line
- Inspect `.alp` or `.alpx` model structure before making edits
- Need a safe workflow for XML-backed AnyLogic model changes
- Want the agent to avoid overpromising GUI automation that the local install cannot prove

## Workflow

### Step 1: Discover the local surface first

Run the install-discovery helper before making capability claims. The helper is bash-first, so treat macOS/Linux discovery as primary and Windows path matches as hints unless the user provides a Windows-native command surface.

```bash
bash @skills/anylogic/scripts/discover-anylogic.sh
```

Use the output to answer three questions:
1. Is AnyLogic installed locally?
2. Which executable or app bundle is present?
3. Is there evidence for runnable run/export/help surfaces?

If discovery finds no installation, continue only with file-level model analysis and clearly state that binary-backed actions are unverified.

### Step 2: Identify the model format and edit surface

Look for these patterns before editing:
- `.alp` → single XML model file
- `.alpx` or split XML files → multi-file model representation that is safer for targeted edits
- experiment-specific files or generated Java/export artifacts

Read the model cluster first. Do not edit blind. Prefer the smallest possible change set that preserves XML structure and existing naming.

### Step 3: Handle parameters and expressions surgically

For parameter work:
- Locate the exact parameter node or file section first
- Change only the intended default, expression, or experiment input binding
- Preserve expression syntax, units, and referenced names
- Re-read surrounding XML after edits

### Step 4: Handle statecharts as model-definition edits

For statecharts:
- Find the existing statechart container, states, events, and transitions
- Match the surrounding XML/structure pattern already used by the model
- Add or update only the necessary state, transition, trigger, or action block
- Preserve IDs, names, and symbol references consistently

Treat runtime statechart APIs as execution-time helpers, not as a substitute for editing the model definition.

### Step 5: Run only documented or locally-proven binary actions

After discovery, use only surfaces that are documented or locally observable. Common safe categories are:
- probe/help output
- experiment run commands
- export/build commands

Do **not** claim full IDE GUI automation unless the local installation or user-provided tooling proves it.

## Capability Boundaries

This skill is intentionally conservative.

**In scope:**
- installation discovery
- model-file inspection
- statechart and parameter-expression edits in `.alp` / `.alpx` structures
- documented run/export flows
- capability summaries tied to the local install
- bash-based install discovery with explicit limits on cross-platform certainty

**Out of scope unless proven locally:**
- arbitrary GUI automation inside the IDE
- undocumented binary flags
- schema-free bulk rewrites of model XML
- claiming edition-specific features without evidence

## Quick Reference

| Goal | Primary approach | Notes |
|---|---|---|
| Find installed AnyLogic | `bash @skills/anylogic/scripts/discover-anylogic.sh` | Probes common paths and lightweight help surfaces |
| Update parameter expression | Read model XML, then edit targeted node | Preserve names, units, and references |
| Add statechart transition | Read current statechart structure, then patch smallest matching block | Keep IDs and symbol references consistent |
| Run experiment | Use documented/local-proven binary command | Edition and install path may constrain availability |
| Export standalone app | Use documented export surface only if available | Often edition-gated |

## Examples

### Example 1: Discover local capability before acting

```text
User: "What can my installed AnyLogic binary do?"
Agent: Runs the discovery script, reports candidate executable paths, notes any observed help output, and separates confirmed capabilities from assumptions.
```

**Result:** The user gets a grounded summary of installation paths, likely edition clues, and command-line surfaces without pretending the IDE is scriptable in ways that were not observed.

### Example 2: Update a parameter expression

```text
User: "Change the arrival-rate parameter expression to use `baseRate * seasonalMultiplier`"
Agent: Reads the relevant model files, finds the exact parameter definition, edits only the expression-bearing node, and re-reads the surrounding XML.
```

**Result:** The expression changes without unrelated XML churn.

### Example 3: Extend a statechart

```text
User: "Add a transition from Idle to Busy when queueSize > 0"
Agent: Reads the agent/statechart definition, finds the existing Idle and Busy nodes, inserts the smallest matching transition block, and reports unresolved symbol or ID requirements.
```

**Result:** The statechart change is expressed as a model-definition update instead of an invented GUI macro.

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| No AnyLogic installation found | App/binary is not installed in common paths | Ask the user for the install path or continue with file-only model edits |
| XML edit would be too broad | Requested change spans multiple unrelated nodes | Narrow the change and edit the exact statechart/parameter block only |
| Binary action is unclear | Local install did not expose usable help or documented flags | Report the uncertainty and limit the task to confirmed capabilities |
| Export fails or is unavailable | Edition or install does not support documented export flow | Treat export as unavailable and avoid claiming it is supported |
| Model references break after edit | Expression or transition references renamed/mismatched symbols | Re-read adjacent XML and repair symbol consistency before stopping |

## References

| Reference | Use when | Content |
|-----------|----------|---------|
| [references/capabilities.md](references/capabilities.md) | Need capability boundaries and command examples | Documented AnyLogic surfaces, safety limits, and local-binary guidance |

## Related Skills

- `skill-helper` - Validate and improve this skill
- `markdown-editor` - Edit markdown-based skill documentation
- `python-core` - Build deeper XML or automation helpers if a future version needs them
