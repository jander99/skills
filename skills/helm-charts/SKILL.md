---
name: helm-charts
description: Create, write, build, develop, debug, test, package, and deploy Helm charts with templates, values, helpers, dependencies, and tests. Use when authoring Kubernetes charts, writing values.yaml, creating _helpers.tpl, managing chart dependencies, or troubleshooting template errors.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: infrastructure
---

# Helm Charts Skill

## What I Do

- Create Helm charts with proper structure (Chart.yaml, values.yaml, templates/)
- Write Go templates for Kubernetes manifests
- Design values.yaml with --set compatible patterns
- Build named templates in _helpers.tpl
- Manage chart dependencies and environment overrides
- Write chart tests and debug template errors
- Package charts for repository distribution

## When to Use Me

Use this skill when you:
- Create, scaffold, or generate a new Helm chart
- Write, edit, or debug template files (.yaml, .tpl)
- Design or restructure values.yaml configuration
- Add or configure chart dependencies
- Create named templates (_helpers.tpl)
- Write or run helm tests
- Debug template rendering or YAML errors

## Chart Structure

```
mychart/
  Chart.yaml          # Required: name, version, apiVersion
  values.yaml         # Default configuration
  charts/             # Dependencies
  templates/
    _helpers.tpl      # Named templates
    deployment.yaml
    service.yaml
    NOTES.txt         # Post-install message
    tests/test-connection.yaml
```

## Template Patterns

```yaml
# Defaults and requirements
image: {{ .Values.image | default "nginx" }}
name: {{ required "name required" .Values.name }}

# Indentation (use nindent)
labels:
  {{- include "myapp.labels" . | nindent 4 }}

# Conditionals
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
{{- end }}

# Loops
{{- range .Values.ports }}
- port: {{ .port }}
{{- end }}

# With block (scoped context)
{{- with .Values.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}

# Built-in objects
{{ .Release.Name }}      # Release name
{{ .Release.Namespace }} # Target namespace
{{ .Chart.Version }}     # Chart version
```

## Values Management

```yaml
# Use camelCase (avoid hyphens - breaks --set)
replicaCount: 3          # Good
replica-count: 3         # Bad

# Document values
# serverPort is the HTTP listener port
serverPort: 8080

# Prefer flat for --set compatibility
serverHost: example.com

# Use nested for logical groups
image:
  repository: nginx
  tag: "1.21"
```

Environment overrides:
```bash
helm install myapp ./chart -f values.yaml -f values-prod.yaml
```

## Named Templates (_helpers.tpl)

```yaml
{{- define "myapp.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "myapp.labels" -}}
app.kubernetes.io/name: {{ include "myapp.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myapp.fullname" . }}
{{- end }}
```

Usage (prefer `include` over `template`):
```yaml
metadata:
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
```

## Dependencies

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "11.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency update ./mychart
```

Global values (shared with subcharts):
```yaml
global:
  imageRegistry: registry.example.com
```

## Testing

```bash
helm lint ./mychart                    # Validate chart
helm template myrelease ./mychart      # Render locally
helm install test ./mychart --dry-run  # Client-side dry run
helm test myrelease                    # Run test pods
```

Test pod template:
```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "myapp.fullname" . }}-test"
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: test
      image: busybox
      command: ['wget', '{{ include "myapp.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

## Modern Helm Workflows

### Upgrade with Install (CI Default)
```bash
helm upgrade --install myrelease ./mychart \
  --namespace production \
  --create-namespace \
  --wait \
  --timeout 5m
```

### Values Schema Validation
```json
// values.schema.json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["replicaCount"],
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1
    }
  }
}
```

### Dry Run with Server Validation
```bash
helm template myrelease ./mychart | kubectl apply --dry-run=server -f -
```

### Helm Diff Plugin (PR Previews)
```bash
helm plugin install https://github.com/databus23/helm-diff
helm diff upgrade myrelease ./mychart -f values-prod.yaml
```

## Context7 Integration

Use Context7 MCP server for up-to-date Helm documentation:
- Template function reference
- Best practices for current Helm version
- New features and deprecations

## Common Errors

| Error | Fix |
|-------|-----|
| `nil pointer evaluating` | Use `with` or `{{ if .Values.x }}` |
| `template "X" not defined` | Check _helpers.tpl, prefix with chart name |
| `cannot unmarshal` | Run `helm lint`, check YAML indentation |
| Whitespace issues | Use `{{-` and `-}}` to trim |

Debug workflow:
```bash
helm lint ./mychart
helm template test ./mychart --debug
helm install test ./mychart --dry-run=server
helm get manifest test  # After install
```

## Related Skills

| Skill | Use For |
|-------|---------|
| [gke-deployment](../gke-deployment/) | GKE deployment patterns |
| [kubernetes-debugging](../kubernetes-debugging/) | Debugging deployed resources |
| [github-actions](../github-actions/) | CI/CD for chart releases |

## References

| Resource | URL |
|----------|-----|
| Chart Development | https://helm.sh/docs/topics/charts/ |
| Template Guide | https://helm.sh/docs/chart_template_guide/ |
| Best Practices | https://helm.sh/docs/chart_best_practices/ |
