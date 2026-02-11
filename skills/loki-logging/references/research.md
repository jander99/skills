# Grafana Loki Logging Research

## Overview

Grafana Loki is a horizontally scalable, highly available, multi-tenant log aggregation system. Unlike traditional log systems that index the content of logs, Loki only indexes metadata (labels), making it more cost-effective and easier to operate.

## LogQL Query Language

LogQL is Loki's query language, inspired by PromQL. Queries follow this structure:

```
{ log stream selector } | log pipeline
```

### Log Stream Selector

The stream selector narrows down logs using labels:

```logql
{service_name="nginx", status="500"}
```

**Operators:**
- `=`: exactly equal
- `!=`: not equal
- `=~`: regex matches
- `!~`: regex does not match

### Log Pipeline Components

#### 1. Line Filter Expressions

Filter log content using:
- `|=`: Log line contains string
- `!=`: Log line does not contain string
- `|~`: Log line matches regex
- `!~`: Log line does not match regex

```logql
{job="mysql"} |= "error" != "timeout"
```

#### 2. Parser Expressions

**JSON Parser:**
```logql
{job="api"} | json
{job="api"} | json status_code="response.status", user="request.user_id"
```

**Logfmt Parser:**
```logql
{job="api"} | logfmt
{job="api"} | logfmt --strict host, method
```

**Pattern Parser:**
```logql
{job="nginx"} | pattern `<ip> - - <_> "<method> <uri> <_>" <status> <size>`
```

**Regex Parser:**
```logql
{job="api"} | regexp `(?P<method>\w+) (?P<path>[\w|/]+) \((?P<status>\d+?)\)`
```

#### 3. Label Filter Expressions

```logql
{job="api"} | json | status >= 400
{job="api"} | logfmt | duration > 10s and method = "GET"
```

#### 4. Format Expressions

**Line Format:**
```logql
{job="api"} | json | line_format "{{.method}} {{.path}} - {{.status}}"
```

**Label Format:**
```logql
{job="api"} | json | label_format duration_ms="{{div .duration 1000}}"
```

## Metric Queries

### Log Range Aggregations

- `rate(log-range)`: entries per second
- `count_over_time(log-range)`: count entries in range
- `bytes_rate(log-range)`: bytes per second
- `bytes_over_time(log-range)`: bytes in range
- `absent_over_time(log-range)`: detect missing logs

```logql
# Error rate per service
sum by (service) (rate({env="production"} |= "error" [5m]))

# Request volume
sum(count_over_time({job="nginx"}[1h]))
```

### Unwrapped Range Aggregations

Extract numeric values from logs:

```logql
# Average request duration
avg_over_time({job="api"} | json | unwrap duration [5m])

# 95th percentile latency
quantile_over_time(0.95, {job="api"} | json | unwrap latency_ms [5m]) by (service)
```

**Supported functions:**
- `rate()`, `sum_over_time()`, `avg_over_time()`
- `max_over_time()`, `min_over_time()`
- `first_over_time()`, `last_over_time()`
- `stdvar_over_time()`, `stddev_over_time()`
- `quantile_over_time()`

### Vector Aggregation Operators

- `sum`, `avg`, `min`, `max`
- `stddev`, `stdvar`, `count`
- `topk`, `bottomk`
- `sort`, `sort_desc`

```logql
topk(10, sum by (path) (rate({job="nginx"} | json [5m])))
```

## Label Design Best Practices

### Good Static Labels
- `environment`: prod, staging, dev
- `cluster`: us-west-1, eu-central-1
- `service_name`: api-gateway, user-service
- `namespace`: production, monitoring
- `team`: platform, backend

### Avoid High-Cardinality Labels
DO NOT use as labels:
- Request IDs
- User IDs
- Trace IDs
- Order IDs
- Session IDs
- IP addresses
- Timestamps

**Instead:** Use structured metadata or filter expressions.

### Recommended Label Count
- Keep to 5-10 static labels per stream
- Avoid more than 100,000 active streams per tenant
- Limit to ~10 unique values per dynamic label

## Structured Metadata

Structured metadata attaches high-cardinality data without creating new streams:

### Use Cases
- Trace IDs for correlation (`traceID`, `spanID`)
- Request IDs
- User IDs
- Pod names in Kubernetes

### Configuration
```yaml
limits_config:
  allow_structured_metadata: true
  max_structured_metadata_size: 64KB
  max_structured_metadata_entries_count: 128
```

### Querying
```logql
{job="api"} | trace_id="abc123"
{job="api"} | pod="myservice-abc1234-56789" | trace_id="0242ac120002"
```

## Structured Logging (JSON)

### Recommended JSON Structure
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "error",
  "service": "user-api",
  "traceId": "abc123xyz",
  "spanId": "span456",
  "message": "Failed to process request",
  "error": "connection timeout",
  "duration_ms": 5234,
  "user_id": "user_789",
  "request": {
    "method": "POST",
    "path": "/api/v1/users",
    "status": 500
  }
}
```

### Required Fields
- `timestamp`: ISO 8601 format
- `level`: debug, info, warn, error, fatal
- `service`: service name
- `message`: human-readable description

### Correlation Fields
- `traceId`: distributed trace identifier
- `spanId`: span within trace
- `correlationId`: request correlation

## Trace Correlation

### Linking Logs to Traces

```logql
# Find logs for specific trace
{service="api"} | json | traceId="abc123"

# Aggregate errors by trace
count by (traceId) (
  {service=~".*"} | json | level="error" [1h]
)
```

### Tempo Integration
Configure derived fields in Grafana to create clickable trace links.

## Log-Based Alerting

### Alerting Rules Example
```yaml
groups:
  - name: application_alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({job="api"} |= "error" [5m])) by (service)
            /
          sum(rate({job="api"}[5m])) by (service)
            > 0.05
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "High error rate in {{ $labels.service }}"
          
      - alert: NoLogsReceived
        expr: |
          absent_over_time({job="api"}[15m])
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "No logs from API service"
```

### Recording Rules Example
```yaml
groups:
  - name: nginx_metrics
    interval: 1m
    rules:
      - record: nginx:requests:rate1m
        expr: |
          sum by (status) (
            rate({job="nginx"} | json [1m])
          )
        labels:
          cluster: "us-central1"
```

## Log Volume Management

### Sampling Strategies
```yaml
# Promtail sampling stage
pipeline_stages:
  - sampling:
      rate: 0.1  # Keep 10% of logs
```

### Drop Unnecessary Logs
```yaml
pipeline_stages:
  - drop:
      expression: ".*healthcheck.*"
```

### Log Level Filtering
```logql
# Production: filter debug logs
{env="production"} | json | level!="debug"
```

## Retention Policies

### Configuration
```yaml
limits_config:
  retention_period: 744h  # 31 days

compactor:
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
```

### Per-Tenant Retention
```yaml
overrides:
  tenant1:
    retention_period: 168h  # 7 days
  tenant2:
    retention_period: 2160h # 90 days
```

## Grafana Alloy Configuration

### Basic Loki Source
```alloy
loki.source.file "logs" {
  targets = [
    {__path__ = "/var/log/*.log", job = "varlogs"},
  ]
  forward_to = [loki.write.default.receiver]
}

loki.write "default" {
  endpoint {
    url = "http://loki:3100/loki/api/v1/push"
  }
}
```

### Kubernetes Pod Logs
```alloy
loki.source.kubernetes "pods" {
  targets = discovery.kubernetes.pods.targets
  forward_to = [loki.process.add_labels.receiver]
}

loki.process "add_labels" {
  stage.json {
    expressions = {
      level = "level",
      msg = "message",
    }
  }
  
  stage.structured_metadata {
    values = {
      trace_id = "traceId",
    }
  }
  
  forward_to = [loki.write.default.receiver]
}
```

## Promtail Configuration

### Scrape Configuration
```yaml
scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  - job_name: containers
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
```

### Pipeline Stages
```yaml
pipeline_stages:
  - json:
      expressions:
        level: level
        message: msg
        trace_id: traceId
  
  - labels:
      level:
  
  - structured_metadata:
      trace_id:
```

## Common Query Patterns

### Error Analysis
```logql
# Error count by service
sum by (service) (count_over_time({env="prod"} |= "error" [1h]))

# Error messages
{env="prod"} |= "error" | json | line_format "{{.service}}: {{.message}}"
```

### Latency Analysis
```logql
# P99 latency by endpoint
quantile_over_time(0.99, 
  {job="api"} | json | unwrap duration_ms [5m]
) by (path)

# Slow requests
{job="api"} | json | duration_ms > 1000
```

### Traffic Analysis
```logql
# Requests per second by status
sum by (status) (rate({job="nginx"} | json [5m]))

# Top endpoints by request volume
topk(10, sum by (path) (rate({job="api"} | json [1h])))
```

### Log Gaps Detection
```logql
# Detect missing logs
absent_over_time({service="critical-api"}[5m])
```

## Common Errors and Solutions

### "maximum of series reached"
**Problem:** Query returns too many series.
**Solution:** Use `keep` or `drop` stages, add label filters, narrow time range.

### "context deadline exceeded"
**Problem:** Query timeout.
**Solution:** Add more specific label selectors, reduce time range, use bloom filters.

### High Cardinality Warning
**Problem:** Too many unique label values.
**Solution:** Move high-cardinality values to structured metadata.

### "rate limited"
**Problem:** Ingestion rate exceeded.
**Solution:** Increase limits or reduce log volume through sampling.

## Performance Tips

1. **Filter early**: Put line filters before parsers
2. **Use specific labels**: Narrow stream selection first
3. **Avoid regex when possible**: Prefer exact string matches
4. **Limit time ranges**: Query shorter periods
5. **Use structured metadata**: For high-cardinality correlation data
6. **Enable caching**: Configure results cache
7. **Use recording rules**: Pre-compute expensive queries

## Documentation References

- LogQL: https://grafana.com/docs/loki/latest/query/
- Labels: https://grafana.com/docs/loki/latest/get-started/labels/
- Alerting: https://grafana.com/docs/loki/latest/alert/
- Storage: https://grafana.com/docs/loki/latest/operations/storage/
- Alloy: https://grafana.com/docs/loki/latest/send-data/alloy/
