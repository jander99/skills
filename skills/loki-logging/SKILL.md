---
name: loki-logging
description: Write, debug, optimize LogQL queries, design log labels, configure structured logging, create log-based metrics and alerts, correlate logs with traces using traceID. Use when querying Loki, troubleshooting log pipelines, building observability dashboards, or investigating incidents.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: observability
---

# Loki Logging Skill

## What I Do

- Write and optimize LogQL queries (log queries and metric queries)
- Design effective log label strategies with low cardinality
- Configure structured JSON logging with correlation fields
- Create log-based metrics and alerting rules
- Correlate logs with distributed traces using traceID
- Troubleshoot common Loki query errors and performance issues

## When to Use Me

Use this skill when you:
- Write, build, or debug LogQL queries for Loki
- Query logs during incident investigation
- Design or refactor log label strategies
- Create dashboards with log-based metrics
- Set up alerts based on log patterns or volumes
- Correlate logs with traces for distributed tracing
- Troubleshoot "maximum series reached" or timeout errors

## LogQL Patterns

### Log Queries

```logql
# Stream selector with filters
{service_name="api", env="prod"} |= "error" != "timeout"

# JSON parsing and filtering
{job="api"} | json | status >= 500 and method = "POST"

# Logfmt parsing
{job="api"} | logfmt | duration > 10s

# Pattern matching (fast, no regex overhead)
{job="nginx"} | pattern `<ip> - - <_> "<method> <uri> <_>" <status> <size>`

# Regex parsing (flexible)
{job="api"} | regexp `(?P<method>\w+) (?P<path>[\w/]+) \((?P<status>\d+)\)`

# Custom output format
{job="api"} | json | line_format "{{.method}} {{.path}} [{{.status}}]"

# Filter by structured metadata (traceID) - requires structured_metadata configured
{job="api"} | json | traceId="abc123" | level="error"

# If traceId is a label (not recommended due to cardinality):
{job="api", traceId="abc123"} | level="error"
```

### Metric Queries

```logql
# Error rate per service
sum by (service) (rate({env="prod"} |= "error" [5m]))

# P95 latency from logs
quantile_over_time(0.95, {job="api"} | json | unwrap latency_ms [5m]) by (service)

# Top endpoints by traffic
topk(10, sum by (path) (rate({job="api"} | json [1h])))

# Detect missing logs
absent_over_time({service="critical-api"}[15m])
```

## Label Design

### Good Static Labels
- `service_name`, `env`, `cluster`, `namespace`, `team`
- Keep 5-10 labels per stream, < 100k active streams

### Avoid as Labels (Use Structured Metadata)
- Request IDs, trace IDs, user IDs, IP addresses
- Any unbounded/high-cardinality values

## Structured Logging

### Required JSON Fields
```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "error",
  "service": "user-api",
  "message": "Request failed",
  "traceId": "abc123xyz",
  "spanId": "span456",
  "duration_ms": 1234
}
```

### Log Levels
Use consistent levels: `debug`, `info`, `warn`, `error`, `fatal`

### Structured Metadata Config (Promtail)
```yaml
pipeline_stages:
  - json:
      expressions:
        trace_id: traceId
  - structured_metadata:
      trace_id:
```

## Context7 Integration

For up-to-date Loki documentation:
```
context7_resolve-library-id: grafana loki
context7_query-docs: libraryId=/grafana/loki, query="LogQL metric queries"
```

## Alerting Examples

```yaml
# Error rate alert
- alert: HighErrorRate
  expr: |
    sum(rate({env="prod"} |= "error" [5m])) by (service)
      / sum(rate({env="prod"}[5m])) by (service) > 0.05
  for: 10m
  labels:
    severity: critical
  annotations:
    summary: "{{ $labels.service }} error rate exceeds 5%"

# Missing logs alert
- alert: NoLogsReceived
  expr: absent_over_time({service="critical-api"}[15m])
  for: 15m
  labels:
    severity: warning
    
# Recording rule for metrics
- record: service:request_rate:1m
  expr: sum by (service) (rate({env="prod"} | json [1m]))
```

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "maximum of series reached" | Too many time series | Add label filters, use `keep` stage |
| "context deadline exceeded" | Query timeout | Filter early, narrow time range |
| High cardinality warning | Label has too many values | Move to structured metadata |
| Parse errors | Format mismatch | Check format, filter `__error__=""` |

## Query Debugging

```logql
# Find parsing errors
{job="api"} | json | __error__ != ""

# Show only successful parses
{job="api"} | json | __error__ = ""

# Debug which lines fail parsing
{job="api"} | json | line_format "error={{.__error__}} line={{__line__}}"
```

### Labels vs Parsed Fields vs Structured Metadata

| Type | Syntax | Cardinality | Use For |
|------|--------|-------------|---------|
| Labels | `{label="value"}` | Low (<100 values) | service, env, namespace |
| Parsed fields | `| json | field="value"` | Any | Request data, user IDs |
| Structured metadata | Configured in pipeline | Medium | traceId, requestId |

## Performance Tips

1. **Filter early**: Line filters (`|=`) before parsers
2. **Specific selectors**: Narrow streams with labels first
3. **Avoid regex**: Prefer exact string matches
4. **Use structured metadata**: For trace/request IDs
5. **Recording rules**: Pre-compute expensive metrics

## Related Skills

| Skill | Relationship |
|-------|-------------|
| grafana-dashboards | Visualize Loki data |
| prometheus-alerting | Alert on log-derived metrics |
| opentelemetry-tracing | Correlate logs with traces |

## References

| Document | Use When |
|----------|----------|
| [research.md](references/research.md) | Deep dive into LogQL patterns and configuration |
