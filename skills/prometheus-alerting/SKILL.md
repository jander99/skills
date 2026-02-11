---
name: prometheus-alerting
description: Write, create, debug, and optimize Prometheus alerting rules, PromQL queries, recording rules, and metric configurations. Covers metric types (counter, gauge, histogram, summary), cardinality management, SLI/SLO patterns, and alert fatigue prevention. Use when writing PromQL, creating alerts, debugging metrics, or implementing observability.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: observability
---

# Prometheus Alerting

Write effective Prometheus alerts, PromQL queries, and recording rules with production best practices.

## What I Do

- Write and debug PromQL queries for metrics analysis
- Create alerting rules with proper severity and annotations
- Design recording rules for dashboard performance
- Implement SLI/SLO monitoring with burn-rate alerts
- Troubleshoot cardinality issues and alert fatigue

## When to Use Me

- Write, create, or debug PromQL queries
- Create, update, or fix alerting rules
- Design recording rules for performance
- Manage metric cardinality issues
- Implement SLI/SLO monitoring
- Troubleshoot alert fatigue

## Metric Types

| Type | Use Case | PromQL Pattern |
|------|----------|----------------|
| Counter | Requests, errors | `rate(metric_total[5m])` |
| Gauge | Memory, temperature | `metric` or `delta()` |
| Histogram | Latency distributions | `histogram_quantile(0.95, sum(rate(bucket[5m])) by (le))` |
| Summary | Pre-computed quantiles | `metric{quantile="0.95"}` (not aggregatable) |

## Essential PromQL Patterns

```promql
# Request rate
sum(rate(http_requests_total[5m])) by (job)

# Error ratio
sum(rate(http_requests_total{status=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))

# P99 latency from histogram
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, job))

# Average duration
rate(http_request_duration_seconds_sum[5m])
  / rate(http_request_duration_seconds_count[5m])
```

## Alerting Rule Template

```yaml
groups:
  - name: application_alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (job)
          / sum(rate(http_requests_total[5m])) by (job) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.job }}"
          description: "Error rate: {{ $value | humanizePercentage }}"
          runbook_url: "https://runbooks.example.com/high-error-rate"
```

## Recording Rules

```yaml
groups:
  - name: http_rules
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))
```

Naming: `level:metric:operations` (e.g., `job:http_requests:rate5m`)

## Alert Fatigue Prevention

1. **Alert on symptoms** - High latency, not high CPU
2. **Every alert actionable** - Include runbook URL
3. **Use appropriate `for`** - 5m+ for most alerts
4. **Severity guidelines**: critical (1-5m), warning (10-30m), info (1h+)

## Cardinality Management

```promql
# Find high-cardinality metrics
topk(10, count by (__name__) ({__name__=~".+"}))
```

Avoid: user IDs, request IDs, unbounded strings as labels.

## SLI/SLO Patterns

```promql
# Availability SLI
sum(rate(http_requests_total{status!~"5.."}[30d]))
  / sum(rate(http_requests_total[30d]))

# Latency SLI (requests under 300ms)
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))
```

## Multi-Window Burn-Rate SLO Alert

```yaml
# Fast burn (2% error budget in 1 hour)
- alert: SLOBurnRateFast
  expr: |
    (
      sum(rate(http_requests_total{status=~"5.."}[5m])) by (job)
      / sum(rate(http_requests_total[5m])) by (job)
    ) > (14.4 * 0.001)  # 14.4x burn rate
    and
    (
      sum(rate(http_requests_total{status=~"5.."}[1h])) by (job)
      / sum(rate(http_requests_total[1h])) by (job)
    ) > (14.4 * 0.001)
  for: 2m
  labels:
    severity: critical

# Slow burn (10% error budget in 3 days)
- alert: SLOBurnRateSlow
  expr: |
    (
      sum(rate(http_requests_total{status=~"5.."}[6h])) by (job)
      / sum(rate(http_requests_total[6h])) by (job)
    ) > (1 * 0.001)
  for: 1h
  labels:
    severity: warning
```

## Alert Label Conventions

```yaml
labels:
  severity: critical|warning|info
  team: platform|backend|frontend
  service: "{{ $labels.job }}"
  component: api|database|cache
annotations:
  summary: "Brief description"
  description: "Details with {{ $value }}"
  runbook_url: "https://runbooks.example.com/{{ $labels.alertname }}"
  dashboard_url: "https://grafana.example.com/d/xxx"
```

## Common Errors

| Error | Fix |
|-------|-----|
| Rate returns nothing | Use `[5m]` minimum (4x scrape interval) |
| NaN in division | Add `> 0` guard or `or vector(0)` |
| Histogram quantile wrong | Include `by (le)` in aggregation |
| Alert flapping | Increase `for` duration |

## Context7 Integration

Query up-to-date Prometheus docs:
```
libraryId: /prometheus/docs
query: "alerting rules PromQL functions"
```

## Validation

```bash
promtool check rules /path/to/rules.yml
promtool test rules /path/to/tests.yml
```

> See `references/research.md` for detailed examples and advanced patterns.

## Related Skills

- `loki-logging` - Log correlation with metrics
- `opentelemetry-tracing` - Distributed tracing
