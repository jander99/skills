# Helm Chart Development Research

This document captures research findings for Helm chart development best practices, patterns, and techniques.

## Chart Structure and Organization

### Standard Directory Layout

```
mychart/
  Chart.yaml          # Required: Chart metadata
  LICENSE             # Optional: License file
  README.md           # Optional: Human-readable documentation
  values.yaml         # Default configuration values
  values.schema.json  # Optional: JSON Schema for values validation
  charts/             # Dependency charts (managed or manual)
  crds/               # Custom Resource Definitions (not templated)
  templates/          # Template files
  templates/NOTES.txt # Post-install usage notes
  templates/tests/    # Test definitions
  templates/_helpers.tpl  # Named template partials
```

### Chart.yaml Required Fields

```yaml
apiVersion: v2         # v2 for Helm 3+
name: mychart          # Chart name
version: 1.0.0         # Chart version (SemVer)
```

### Chart.yaml Optional Fields

```yaml
kubeVersion: ">= 1.19.0"  # Kubernetes version constraint
description: "A Helm chart for deploying MyApp"
type: application         # or 'library'
appVersion: "2.1.0"       # Application version (informational)
deprecated: false
keywords:
  - web
  - backend
home: https://example.com
sources:
  - https://github.com/org/repo
maintainers:
  - name: John Doe
    email: john@example.com
icon: https://example.com/icon.png
annotations:
  category: web
```

## Values File Patterns and Layering

### Naming Conventions

- Use camelCase for variable names
- Avoid hyphens in names (breaks --set)
- Prefer flat over deeply nested structures

```yaml
# Good
serverName: nginx
serverPort: 80
replicaCount: 3

# Avoid deep nesting when possible
# server:
#   config:
#     nested:
#       value: true
```

### Flat vs Nested Decision

Use flat for simple config (easier --set overrides):
```yaml
serverHost: example.com
serverPort: 9191
```

Use nested when related values form logical groups:
```yaml
image:
  repository: nginx
  tag: latest
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
```

### Value Documentation Pattern

```yaml
# replicaCount is the number of pod replicas to deploy
replicaCount: 3

# image.repository is the container image registry/name
# image.tag is the container image tag
# image.pullPolicy controls when kubelet pulls the image
image:
  repository: nginx
  tag: "1.21"
  pullPolicy: IfNotPresent
```

### Type Safety

```yaml
# Quote strings explicitly
name: "myapp"
port: "8080"  # Store as string, convert with {{ int .Values.port }}

# Boolean values
enabled: true
debug: false

# Integers - be careful with large numbers
maxConnections: 100
```

## Template Functions and Pipelines

### Essential Template Functions

```yaml
# Default values
{{ default "nginx" .Values.image }}
{{ .Values.name | default "myapp" }}

# Required values (fail if not set)
{{ required "image.repository is required" .Values.image.repository }}

# Quoting
{{ .Values.name | quote }}      # "value"
{{ .Values.name | squote }}     # 'value'

# Indentation
{{ include "mychart.labels" . | indent 4 }}
{{ include "mychart.labels" . | nindent 4 }}

# Trimming whitespace
{{- .Values.name -}}   # Trim both sides
{{- .Values.name }}    # Trim left only
{{ .Values.name -}}    # Trim right only

# Conditionals
{{ if .Values.enabled }}
{{ else if .Values.alternative }}
{{ else }}
{{ end }}

# Loops
{{- range .Values.servers }}
  - {{ .name }}: {{ .port }}
{{- end }}

{{- range $key, $val := .Values.labels }}
  {{ $key }}: {{ $val | quote }}
{{- end }}
```

### String Manipulation

```yaml
# Truncation
{{ .Release.Name | trunc 63 | trimSuffix "-" }}

# Case conversion
{{ .Values.name | upper }}
{{ .Values.name | lower }}
{{ .Values.name | title }}

# Contains/hasPrefix/hasSuffix
{{ if contains "prod" .Release.Namespace }}
{{ if hasPrefix "test-" .Values.name }}
{{ if hasSuffix "-dev" .Release.Name }}

# Replace
{{ .Values.name | replace "-" "_" }}
```

### Type Conversion

```yaml
# To string
{{ .Values.port | toString }}

# To integer
{{ .Values.port | int }}
{{ .Values.port | int64 }}

# To list
{{ .Values.items | toStrings }}

# To YAML/JSON
{{ .Values.config | toYaml | indent 2 }}
{{ .Values.config | toJson }}
{{ .Values.config | toPrettyJson }}
```

### Lookup Function

```yaml
# Query existing cluster resources
{{ $secret := lookup "v1" "Secret" .Release.Namespace "mysecret" }}
{{ if $secret }}
  # Secret exists
{{ end }}
```

## Named Templates and Helpers (_helpers.tpl)

### Defining Named Templates

```yaml
{{/* _helpers.tpl */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ include "mychart.chart" . }}
{{ include "mychart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mychart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### Using Named Templates

```yaml
# Use 'include' (preferred) - allows piping
metadata:
  labels:
    {{- include "mychart.labels" . | nindent 4 }}

# Use 'template' action - direct insertion (no piping)
metadata:
  labels:
    {{ template "mychart.labels" . }}
```

### Template Naming Convention

Always prefix with chart name to avoid conflicts:
```yaml
{{- define "mychart.labels" -}}      # Good
{{- define "labels" -}}              # Bad - global collision risk
```

## Dependency Management

### Chart.yaml Dependencies

```yaml
dependencies:
  - name: postgresql
    version: "11.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
    tags:
      - database
    
  - name: redis
    version: "17.x.x"
    repository: "@bitnami"  # Using alias after helm repo add
    condition: redis.enabled
    alias: cache           # Access as .Values.cache
    
  - name: common
    version: "1.x.x"
    repository: "oci://registry.example.com/charts"
```

### Managing Dependencies

```bash
# Add repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Download dependencies
helm dependency update ./mychart
helm dep up ./mychart

# List dependencies
helm dependency list ./mychart

# Build (rebuild charts/ directory)
helm dependency build ./mychart
```

### Conditional Dependencies

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    condition: postgresql.enabled
    tags:
      - database

# values.yaml
postgresql:
  enabled: true

tags:
  database: true
```

### Importing Values from Subcharts

```yaml
# Parent Chart.yaml
dependencies:
  - name: subchart
    import-values:
      - data                    # Export format
      - child: config.database  # Child-parent format
        parent: db
```

### Global Values

```yaml
# values.yaml
global:
  imageRegistry: registry.example.com
  storageClass: fast

# Accessible in all charts as .Values.global.imageRegistry
```

## Environment-Specific Overrides

### Values File Hierarchy

```bash
# Base values (in chart)
values.yaml

# Environment overrides
helm install myapp ./mychart \
  -f values.yaml \
  -f values-production.yaml \
  --set image.tag=v2.0.0
```

### Environment Values Pattern

```yaml
# values-development.yaml
replicaCount: 1
resources:
  limits:
    memory: 256Mi
debug: true

# values-production.yaml
replicaCount: 3
resources:
  limits:
    memory: 1Gi
debug: false
```

### Namespace-Aware Templates

```yaml
{{- if eq .Release.Namespace "production" }}
replicas: 3
{{- else }}
replicas: 1
{{- end }}
```

## Chart Testing

### Helm Lint

```bash
# Basic linting
helm lint ./mychart

# Strict mode
helm lint --strict ./mychart

# With values
helm lint ./mychart -f values-test.yaml
```

### Helm Template (Local Rendering)

```bash
# Render templates locally
helm template myrelease ./mychart

# With debug info
helm template myrelease ./mychart --debug

# Output to file
helm template myrelease ./mychart > rendered.yaml

# With specific values
helm template myrelease ./mychart -f custom-values.yaml --set key=value
```

### Helm Test

Tests are Pods with `helm.sh/hook: test` annotation:

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "mychart.fullname" . }}-test-connection"
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "mychart.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

```bash
# Run tests
helm test myrelease

# With timeout
helm test myrelease --timeout 5m

# Show logs
helm test myrelease --logs
```

### Dry Run Installation

```bash
# Client-side dry run
helm install myrelease ./mychart --dry-run

# Server-side dry run (validates against cluster)
helm install myrelease ./mychart --dry-run=server

# With debug output
helm install myrelease ./mychart --dry-run --debug
```

## Upgrade Strategies and Rollbacks

### Safe Upgrades

```bash
# Preview changes
helm diff upgrade myrelease ./mychart  # requires helm-diff plugin

# Upgrade with atomic (rollback on failure)
helm upgrade myrelease ./mychart --atomic

# Wait for resources
helm upgrade myrelease ./mychart --wait --timeout 5m

# Recreate pods
helm upgrade myrelease ./mychart --recreate-pods  # deprecated
helm upgrade myrelease ./mychart --force           # use carefully
```

### Rollback

```bash
# View history
helm history myrelease

# Rollback to previous
helm rollback myrelease

# Rollback to specific revision
helm rollback myrelease 2

# With timeout
helm rollback myrelease 2 --timeout 5m
```

### Upgrade Hooks

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ .Release.Name }}-db-migrate"
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": hook-succeeded
```

## Chart Versioning and Repository Management

### Versioning Strategy

- Chart version: Use SemVer (1.2.3)
- appVersion: Application version (can be any format)
- Bump chart version on any chart changes
- Bump appVersion when underlying app changes

```yaml
version: 1.2.3          # Chart version
appVersion: "2.0.0"     # App version (quote recommended)
```

### Packaging Charts

```bash
# Package chart
helm package ./mychart

# Package with specific version
helm package ./mychart --version 1.2.3

# Package to specific directory
helm package ./mychart -d ./releases
```

### Chart Repository

```bash
# Create repository index
helm repo index ./charts --url https://charts.example.com

# Update index with new charts
helm repo index ./charts --merge index.yaml

# Add repository
helm repo add myrepo https://charts.example.com

# Update repository cache
helm repo update

# Search charts
helm search repo myrepo/
```

### OCI Registry

```bash
# Login to registry
helm registry login registry.example.com

# Push chart
helm push mychart-1.0.0.tgz oci://registry.example.com/charts

# Pull chart
helm pull oci://registry.example.com/charts/mychart --version 1.0.0

# Install from OCI
helm install myrelease oci://registry.example.com/charts/mychart
```

## Built-in Objects Reference

### Release Object
- `.Release.Name` - Release name
- `.Release.Namespace` - Target namespace
- `.Release.IsInstall` - True if install operation
- `.Release.IsUpgrade` - True if upgrade operation
- `.Release.Revision` - Revision number
- `.Release.Service` - Rendering engine (always "Helm")

### Chart Object
- `.Chart.Name` - Chart name
- `.Chart.Version` - Chart version
- `.Chart.AppVersion` - App version
- `.Chart.Maintainers` - Maintainer list

### Values Object
- `.Values` - Values from values.yaml and overrides

### Capabilities Object
- `.Capabilities.KubeVersion` - Kubernetes version
- `.Capabilities.APIVersions` - Available API versions
- `.Capabilities.APIVersions.Has "apps/v1"` - Check API availability

### Files Object
- `.Files.Get "config.ini"` - Get file contents
- `.Files.GetBytes "binary"` - Get as bytes
- `.Files.Glob "*.yaml"` - Match files

## Common Patterns

### Conditional Resource Creation

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
...
{{- end }}
```

### Resource Limits Pattern

```yaml
{{- with .Values.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
```

### ConfigMap from Files

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "mychart.fullname" . }}-config
data:
  {{- (.Files.Glob "config/*").AsConfig | nindent 2 }}
```

### Secret from Template

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "mychart.fullname" . }}-secret
type: Opaque
data:
  password: {{ .Values.password | b64enc | quote }}
```

## Debugging Techniques

### Debug Commands

```bash
# Lint for issues
helm lint ./mychart

# Render and inspect
helm template myrelease ./mychart --debug

# Dry run against cluster
helm install myrelease ./mychart --dry-run=server --debug

# Get rendered manifests from deployed release
helm get manifest myrelease

# Get computed values
helm get values myrelease

# Get all release info
helm get all myrelease
```

### Template Debugging

```yaml
# Print debug info in template
{{- /* Debug: {{ .Values | toYaml }} */ -}}

# Comment out problematic sections
# apiVersion: v1
# problematic: {{ .Values.missing }}
```

## Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `nil pointer` | Missing nested value | Use `with` or check existence |
| `cannot unmarshal` | YAML syntax error | Validate YAML structure |
| `template not defined` | Missing helper | Check _helpers.tpl exists |
| `named template already defined` | Duplicate name | Prefix with chart name |
| `release already exists` | Previous failed install | Use `helm uninstall` first |
| `lookup not available` | Template-only render | Use `--dry-run=server` |

## References

- [Helm Documentation](https://helm.sh/docs/)
- [Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Sprig Functions](https://masterminds.github.io/sprig/)
- [Artifact Hub](https://artifacthub.io/)
