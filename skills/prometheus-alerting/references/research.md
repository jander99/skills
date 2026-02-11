# Prometheus Alerting Research

> Comprehensive research notes on Prometheus metrics, PromQL, alerting, and observability best practices.

---

## Metric Types

### Counter
- Cumulative metric that only increases (or resets to zero)
- Use for: requests served, tasks completed, errors
- Always use `rate()` or `increase()` - never raw values
- Naming: suffix with `_total`

```promql
# Request rate over 5 minutes
rate(http_requests_total[5m])

# Total increase over 1 hour
increase(http_requests_total[1h])
```

### Gauge
- Value that can go up or down
- Use for: temperature, memory usage, concurrent connections
- Can use raw values, `delta()`, or `deriv()`

```promql
# Current memory usage
node_memory_MemAvailable_bytes

# Memory change rate
deriv(node_memory_MemAvailable_bytes[5m])
```

### Histogram
- Samples observations into configurable buckets
- Exposes: `_bucket{le="X"}`, `_sum`, `_count`
- Aggregatable across instances
- Use `histogram_quantile()` for percentiles

```promql
# 95th percentile latency
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
)

# Average request duration
rate(http_request_duration_seconds_sum[5m])
  / rate(http_request_duration_seconds_count[5m])
```

### Summary
- Pre-calculated quantiles on client side
- Cannot aggregate across instances
- Lower server-side cost
- Use when exact quantiles needed for single instance

```promql
# Pre-calculated median (NOT aggregatable)
http_request_duration_seconds{quantile="0.5"}
```

---

## Metric Naming Conventions

### Structure
```
<namespace>_<subsystem>_<name>_<unit>_<suffix>
```

### Rules
1. Use snake_case
2. Include single unit (seconds, bytes, meters)
3. Use base units (seconds not milliseconds)
4. Suffix with unit in plural: `_seconds`, `_bytes`
5. Counters suffix: `_total` (e.g., `http_requests_total`)
6. Info metrics: `_info` (e.g., `build_info`)
7. Timestamps: `_timestamp_seconds`

### Examples
```
http_request_duration_seconds          # histogram
node_memory_usage_bytes                # gauge
http_requests_total                    # counter
process_cpu_seconds_total              # counter with unit
myapp_build_info                       # info metric
```

---

## Label Design and Cardinality

### Good Labels
- `method` (GET, POST, PUT, DELETE)
- `status_code` or `status` (200, 404, 500)
- `instance`, `job`
- `environment` (prod, staging, dev)
- `service`, `version`

### Cardinality Dangers
Avoid high-cardinality labels:
- User IDs
- Request IDs
- Email addresses
- Timestamps as labels
- Unbounded sets

### Cardinality Formula
```
Total series = metric_count * label1_values * label2_values * ...
```

### Monitoring Cardinality
```promql
# Count unique series per metric
count by (__name__) ({__name__=~".+"})

# High cardinality metrics
topk(10, count by (__name__) ({__name__=~".+"}))

# Series count per job
scrape_samples_scraped
```

---

## PromQL Query Patterns

### Rate and Increase
```promql
# Per-second rate over 5 minutes
rate(http_requests_total[5m])

# Per-second rate, counter-aware (handles resets)
irate(http_requests_total[5m])  # instant rate - more volatile

# Total increase (counter-aware)
increase(http_requests_total[1h])
```

### Aggregations
```promql
# Sum across all instances
sum(rate(http_requests_total[5m]))

# Sum by specific label
sum by (method) (rate(http_requests_total[5m]))

# Average across instances
avg(rate(http_requests_total[5m]))

# Exclude labels (keep others)
sum without (instance) (rate(http_requests_total[5m]))
```

### Comparisons and Filters
```promql
# Threshold filtering
http_requests_total > 1000

# Label matching
http_requests_total{status_code=~"5.."}

# Negative matching
http_requests_total{status_code!="200"}

# Multiple conditions
http_requests_total{method="POST", status_code="500"}
```

### Percentiles from Histograms
```promql
# 50th percentile (median)
histogram_quantile(0.50, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# 99th percentile by service
histogram_quantile(0.99, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))
```

### Time Offsets
```promql
# Compare to 1 week ago
rate(http_requests_total[5m]) 
  / rate(http_requests_total[5m] offset 1w)

# Change from yesterday
increase(http_requests_total[1d]) 
  - increase(http_requests_total[1d] offset 1d)
```

### Subqueries
```promql
# Max rate over last hour, sampled every 5m
max_over_time(rate(http_requests_total[5m])[1h:5m])

# Average of 99th percentile over time
avg_over_time(
  histogram_quantile(0.99, 
    sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
  )[1h:5m]
)
```

---

## Recording Rules

### Purpose
- Pre-compute expensive queries
- Reduce dashboard load time
- Create reusable aggregations
- Improve query performance

### Naming Convention
```
level:metric:operations
```

Examples:
- `job:http_requests:rate5m`
- `instance:node_cpu:avg_rate5m`
- `cluster:http_errors:ratio_rate5m`

### Rule File Structure
```yaml
groups:
  - name: http_rules
    interval: 30s
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))
      
      - record: job:http_request_duration_seconds:p99
        expr: |
          histogram_quantile(0.99,
            sum by (job, le) (rate(http_request_duration_seconds_bucket[5m]))
          )
```

### When to Use Recording Rules
1. Dashboard queries taking > 1 second
2. Same aggregation used in multiple places
3. Complex multi-step calculations
4. SLI/SLO calculations

---

## Alerting Rules

### Structure
```yaml
groups:
  - name: example_alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status_code=~"5.."}[5m])) 
          / sum(rate(http_requests_total[5m])) > 0.05
        for: 5m
        keep_firing_for: 10m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"
          runbook_url: "https://runbooks.example.com/high-error-rate"
```

### Key Fields
- `for`: Pending duration before firing (prevents flapping)
- `keep_firing_for`: Continue firing after condition clears
- `labels`: Add metadata (severity, team, service)
- `annotations`: Human-readable info, templated values

### Template Variables
```yaml
annotations:
  summary: "Instance {{ $labels.instance }} down"
  value: "Current value: {{ $value }}"
  humanized: "Rate: {{ $value | humanizePercentage }}"
```

---

## Alert Fatigue Prevention

### Principles
1. Alert on symptoms, not causes
2. Every alert should be actionable
3. Link alerts to runbooks
4. Use appropriate `for` durations
5. Aggregate similar alerts

### Symptom-Based Alerts

**Bad (cause-based):**
```yaml
- alert: HighCPU
  expr: node_cpu_seconds_total > 0.90
```

**Good (symptom-based):**
```yaml
- alert: HighLatency
  expr: |
    histogram_quantile(0.99, 
      sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
    ) > 0.5
  for: 10m
```

### Severity Levels
| Severity | Response | Examples |
|----------|----------|----------|
| critical | Page immediately | Service down, data loss risk |
| warning | Investigate soon | Degraded performance, capacity |
| info | Review in working hours | Non-urgent anomalies |

### For Duration Guidelines
| Scenario | Suggested `for` |
|----------|-----------------|
| Complete outage | 1-2m |
| High error rate | 5m |
| Resource exhaustion | 10-15m |
| Capacity warnings | 30m-1h |

---

## SLI/SLO Patterns

### Availability SLI
```promql
# Success ratio
sum(rate(http_requests_total{status_code!~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))
```

### Latency SLI
```promql
# Requests under 300ms threshold
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))
```

### Error Budget
```yaml
# Recording rule for error budget
- record: slo:error_budget:remaining
  expr: |
    1 - (
      (1 - slo:availability:ratio_rate30d) 
      / (1 - 0.999)  # 99.9% SLO target
    )
```

### Burn Rate Alert
```yaml
- alert: ErrorBudgetBurn
  expr: |
    (
      slo:error_rate:ratio_rate1h > (14.4 * (1 - 0.999))
      and
      slo:error_rate:ratio_rate5m > (14.4 * (1 - 0.999))
    )
    or
    (
      slo:error_rate:ratio_rate6h > (6 * (1 - 0.999))
      and
      slo:error_rate:ratio_rate30m > (6 * (1 - 0.999))
    )
  for: 2m
  labels:
    severity: critical
```

---

## Common PromQL Mistakes

### 1. Using `rate()` with Wrong Window
```promql
# Bad: window too short (< 4x scrape interval)
rate(http_requests_total[15s])

# Good: at least 4x scrape interval
rate(http_requests_total[1m])  # for 15s scrape
```

### 2. Rate on Gauge
```promql
# Wrong: rate on gauge
rate(node_memory_MemFree_bytes[5m])

# Correct: use delta or deriv
delta(node_memory_MemFree_bytes[5m])
```

### 3. Missing Rate Before Aggregation
```promql
# Wrong: sum before rate
rate(sum(http_requests_total)[5m])

# Correct: rate before sum
sum(rate(http_requests_total[5m]))
```

### 4. Histogram Quantile Without Rate
```promql
# Wrong: no rate
histogram_quantile(0.95, http_request_duration_seconds_bucket)

# Correct: with rate
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

### 5. Aggregating Pre-computed Quantiles
```promql
# Wrong: averaging quantiles is meaningless
avg(http_request_duration_seconds{quantile="0.95"})

# Correct: use histogram_quantile with buckets
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

### 6. Division Without Protection
```promql
# Can produce NaN/Inf
rate(errors_total[5m]) / rate(requests_total[5m])

# Safe version
rate(errors_total[5m]) 
  / (rate(requests_total[5m]) > 0) or vector(0)
```

---

## Essential Alert Examples

### Infrastructure
```yaml
# Instance down
- alert: InstanceDown
  expr: up == 0
  for: 5m
  labels:
    severity: critical

# Disk space
- alert: DiskSpaceLow
  expr: |
    (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.1
    and node_filesystem_readonly == 0
  for: 15m
  labels:
    severity: warning

# Memory pressure
- alert: HighMemoryUsage
  expr: |
    (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) > 0.9
  for: 15m
  labels:
    severity: warning
```

### Application
```yaml
# High error rate
- alert: HighErrorRate
  expr: |
    sum(rate(http_requests_total{status_code=~"5.."}[5m])) by (job)
    / sum(rate(http_requests_total[5m])) by (job) > 0.01
  for: 5m
  labels:
    severity: critical

# High latency (p99)
- alert: HighLatencyP99
  expr: |
    histogram_quantile(0.99,
      sum(rate(http_request_duration_seconds_bucket[5m])) by (le, job)
    ) > 1
  for: 10m
  labels:
    severity: warning

# Saturation (queue depth)
- alert: HighQueueDepth
  expr: |
    avg_over_time(request_queue_length[5m]) > 100
  for: 10m
  labels:
    severity: warning
```

### Database
```yaml
# Slow queries
- alert: SlowQueries
  expr: |
    rate(mysql_global_status_slow_queries[5m]) > 0.1
  for: 5m
  labels:
    severity: warning

# Connection pool exhaustion
- alert: ConnectionPoolNearLimit
  expr: |
    pg_stat_activity_count / pg_settings_max_connections > 0.8
  for: 10m
  labels:
    severity: warning
```

---

## Prometheus Configuration Tips

### Rule File Loading
```yaml
# prometheus.yml
rule_files:
  - /etc/prometheus/rules/*.yml
  - /etc/prometheus/alerts/*.yml
```

### Validation
```bash
# Validate rule files
promtool check rules /path/to/rules.yml

# Test rules with unit tests
promtool test rules /path/to/test.yml
```

### Unit Testing Rules
```yaml
# test.yml
rule_files:
  - rules.yml

evaluation_interval: 1m

tests:
  - interval: 1m
    input_series:
      - series: 'http_requests_total{job="api", status="500"}'
        values: '0+10x5'
      - series: 'http_requests_total{job="api", status="200"}'
        values: '0+100x5'
    alert_rule_test:
      - eval_time: 5m
        alertname: HighErrorRate
        exp_alerts:
          - exp_labels:
              job: api
              severity: critical
```

---

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Awesome Prometheus Alerts](https://github.com/samber/awesome-prometheus-alerts)
- [SLO/SLI with Prometheus](https://sre.google/workbook/implementing-slos/)
- [Rob Ewaschuk's Philosophy on Alerting](https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q/)
