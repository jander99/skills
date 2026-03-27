# AnyLogic Capability Notes

This reference captures the documented and safe assumptions behind the `anylogic` skill.

## Confirmed Surfaces Used by the Skill

### 1. Model file formats

AnyLogic models are stored in XML-backed formats.

- `.alp` is a single-file model format.
- `.alpx` is a multi-part model format that is generally better for targeted edits and version control.

Skill implication: read the exact model files first, then make the smallest XML-consistent change possible.

### 2. Parameters and expressions

Parameters can be represented in model definitions and used as experiment inputs or expressions.

Skill implication: parameter work should update the exact expression/default node rather than rewrite broad sections of the model.

### 3. Statecharts

Statechart behavior has documented runtime APIs, but model construction still lives in the model definition.

Skill implication: use runtime APIs as context for semantics, but create structural statechart changes by editing the model definition files that already hold states, transitions, triggers, and actions.

### 4. Binary-backed run and export workflows

AnyLogic documentation describes command-line driven run/export surfaces in supported environments. These are edition- and install-dependent.

Skill implication: do not promise a command until either:
- the local install exposes a usable help surface, or
- the user provides a known-good path/command from their environment.

## Safe Operational Rules

1. Discover the local install before claiming capabilities.
2. Prefer model-file inspection over speculation.
3. Keep edits surgical and pattern-matched to existing XML.
4. Treat export/build support as conditional, not universal.
5. Separate confirmed local observations from documented-but-unverified possibilities.

## Suggested Discovery Flow

```bash
bash @skills/anylogic/scripts/discover-anylogic.sh
```

The helper checks common install locations and tries lightweight help probes without running a model. It is strongest on bash-based environments (macOS/Linux). Windows entries in the script are candidate path hints, not proof of Windows-native automation support.

## Command Examples to Treat as Templates, Not Guarantees

These are representative categories only:

```bash
# Probe executable help (only if local install exists)
"/path/to/AnyLogic" --help

# Run an experiment if the local binary and edition support it
"/path/to/AnyLogic" -r "/path/to/model.alp" "Simulation"

# Export if the local binary and edition support it
"/path/to/AnyLogic" -e "/path/to/model.alp:Simulation"
```

Only use a command after local confirmation. If the user is on Windows and needs repeatable execution there, add a dedicated PowerShell helper rather than assuming the bash helper is sufficient.

## Sources Consulted During Skill Authoring

- AnyLogic Help — model format guidance (`.alp`, `.alpx`)
- AnyLogic Help — statechart API guidance
- AnyLogic Help — parameter guidance
- AnyLogic Help — running/exporting models from command-line surfaces

The main skill intentionally summarizes these without overcommitting to undocumented automation behavior.
