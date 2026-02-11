# OpenTelemetry Distributed Tracing Research

## Overview

OpenTelemetry (OTel) is a vendor-neutral observability framework providing APIs, SDKs, and tools for generating, collecting, and exporting telemetry data (traces, metrics, logs). Distributed tracing connects the dots across microservices, enabling end-to-end request flow visibility.

## Core Concepts

### Traces and Spans

A **trace** represents the full path of a request through a distributed system. It consists of multiple **spans**, each representing a unit of work:

```json
{
  "name": "processOrder",
  "context": {
    "trace_id": "5b8aa5a2d2c872e8321cf37308d69df2",
    "span_id": "051581bf3cb55c13"
  },
  "parent_id": null,
  "start_time": "2024-01-15T10:30:00.000Z",
  "end_time": "2024-01-15T10:30:00.150Z",
  "attributes": {
    "http.method": "POST",
    "http.route": "/api/orders"
  },
  "status": { "code": 0 }
}
```

### Span Components

- **Span Context**: Immutable object containing trace_id, span_id, trace_flags, trace_state
- **Attributes**: Key-value pairs with metadata about the operation
- **Events**: Timestamped annotations (like structured logs)
- **Links**: References to causally-related spans in other traces
- **Status**: Unset, Error, or Ok

### Span Kinds

| Kind | Description |
|------|-------------|
| CLIENT | Outgoing synchronous call (HTTP client, DB call) |
| SERVER | Incoming synchronous call (HTTP server) |
| INTERNAL | Operations within a process boundary |
| PRODUCER | Async job creation (message queue producer) |
| CONSUMER | Async job processing (message queue consumer) |

---

## Java SDK Setup

### Dependencies (Maven)

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>io.opentelemetry</groupId>
      <artifactId>opentelemetry-bom</artifactId>
      <version>1.40.0</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>

<dependencies>
  <!-- API -->
  <dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-api</artifactId>
  </dependency>
  <!-- SDK -->
  <dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-sdk</artifactId>
  </dependency>
  <!-- OTLP Exporter -->
  <dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
  </dependency>
  <!-- Semantic Conventions -->
  <dependency>
    <groupId>io.opentelemetry.semconv</groupId>
    <artifactId>opentelemetry-semconv</artifactId>
  </dependency>
</dependencies>
```

### SDK Initialization

```java
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.semconv.ResourceAttributes;

public class TracingConfig {
    public static OpenTelemetry initOpenTelemetry() {
        Resource resource = Resource.getDefault()
            .merge(Resource.create(Attributes.of(
                ResourceAttributes.SERVICE_NAME, "order-service",
                ResourceAttributes.SERVICE_VERSION, "1.0.0",
                ResourceAttributes.DEPLOYMENT_ENVIRONMENT, "production"
            )));

        OtlpGrpcSpanExporter spanExporter = OtlpGrpcSpanExporter.builder()
            .setEndpoint("http://tempo:4317")
            .build();

        SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
            .setResource(resource)
            .addSpanProcessor(BatchSpanProcessor.builder(spanExporter).build())
            .build();

        return OpenTelemetrySdk.builder()
            .setTracerProvider(tracerProvider)
            .buildAndRegisterGlobal();
    }
}
```

### Creating Spans in Java

```java
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;

public class OrderService {
    private final Tracer tracer;

    public OrderService(OpenTelemetry openTelemetry) {
        this.tracer = openTelemetry.getTracer("order-service", "1.0.0");
    }

    public Order processOrder(OrderRequest request) {
        Span span = tracer.spanBuilder("processOrder")
            .setSpanKind(SpanKind.INTERNAL)
            .setAttribute("order.id", request.getOrderId())
            .setAttribute("order.items.count", request.getItems().size())
            .startSpan();

        try (Scope scope = span.makeCurrent()) {
            // Business logic here
            validateOrder(request);
            Order order = saveOrder(request);
            
            span.setAttribute("order.total", order.getTotal());
            return order;
        } catch (Exception e) {
            span.recordException(e);
            span.setStatus(StatusCode.ERROR, e.getMessage());
            throw e;
        } finally {
            span.end();
        }
    }

    private void validateOrder(OrderRequest request) {
        Span span = tracer.spanBuilder("validateOrder")
            .startSpan();
        try (Scope scope = span.makeCurrent()) {
            // Validation logic - this span is automatically a child
        } finally {
            span.end();
        }
    }
}
```

### Spring Boot Auto-Configuration

```yaml
# application.yaml
spring:
  application:
    name: order-service

otel:
  exporter:
    otlp:
      endpoint: http://tempo:4317
  resource:
    attributes:
      service.name: order-service
      deployment.environment: production
```

---

## TypeScript/Node.js SDK Setup

### Dependencies

```bash
npm install @opentelemetry/api \
  @opentelemetry/sdk-node \
  @opentelemetry/sdk-trace-node \
  @opentelemetry/exporter-trace-otlp-grpc \
  @opentelemetry/resources \
  @opentelemetry/semantic-conventions
```

### SDK Initialization

```typescript
// instrumentation.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-grpc';
import { resourceFromAttributes } from '@opentelemetry/resources';
import {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
  ATTR_DEPLOYMENT_ENVIRONMENT
} from '@opentelemetry/semantic-conventions';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';

const resource = resourceFromAttributes({
  [ATTR_SERVICE_NAME]: 'order-service',
  [ATTR_SERVICE_VERSION]: '1.0.0',
  [ATTR_DEPLOYMENT_ENVIRONMENT]: 'production'
});

const traceExporter = new OTLPTraceExporter({
  url: 'http://tempo:4317'
});

const sdk = new NodeSDK({
  resource,
  spanProcessors: [new BatchSpanProcessor(traceExporter)]
});

sdk.start();

// Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('SDK shut down'))
    .catch((err) => console.error('Error shutting down SDK', err))
    .finally(() => process.exit(0));
});
```

### Creating Spans in TypeScript

```typescript
import { trace, SpanKind, SpanStatusCode, context } from '@opentelemetry/api';

const tracer = trace.getTracer('order-service', '1.0.0');

async function processOrder(request: OrderRequest): Promise<Order> {
  return tracer.startActiveSpan(
    'processOrder',
    { kind: SpanKind.INTERNAL },
    async (span) => {
      try {
        span.setAttribute('order.id', request.orderId);
        span.setAttribute('order.items.count', request.items.length);

        await validateOrder(request);
        const order = await saveOrder(request);

        span.setAttribute('order.total', order.total);
        return order;
      } catch (error) {
        span.recordException(error as Error);
        span.setStatus({ code: SpanStatusCode.ERROR, message: (error as Error).message });
        throw error;
      } finally {
        span.end();
      }
    }
  );
}

async function validateOrder(request: OrderRequest): Promise<void> {
  return tracer.startActiveSpan('validateOrder', async (span) => {
    try {
      // Validation logic - automatically a child span
    } finally {
      span.end();
    }
  });
}
```

---

## Context Propagation

### W3C Trace Context

The W3C Trace Context standard defines HTTP headers for propagating trace context:

```
traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
             |   |                                  |                |
           version  trace-id (32 hex)         parent-id (16 hex)  flags
```

### Propagation Headers

| Header | Purpose |
|--------|---------|
| `traceparent` | Primary context (trace-id, span-id, flags) |
| `tracestate` | Vendor-specific trace information |
| `baggage` | Cross-cutting key-value pairs |

### Java Context Propagation

```java
import io.opentelemetry.context.propagation.TextMapGetter;
import io.opentelemetry.context.propagation.TextMapSetter;
import io.opentelemetry.context.Context;

// Extract context from incoming request
TextMapGetter<HttpServletRequest> getter = new TextMapGetter<>() {
    @Override
    public Iterable<String> keys(HttpServletRequest carrier) {
        return Collections.list(carrier.getHeaderNames());
    }
    @Override
    public String get(HttpServletRequest carrier, String key) {
        return carrier.getHeader(key);
    }
};

Context extractedContext = openTelemetry.getPropagators()
    .getTextMapPropagator()
    .extract(Context.current(), request, getter);

// Inject context into outgoing request
TextMapSetter<HttpRequest> setter = (carrier, key, value) -> 
    carrier.addHeader(key, value);

openTelemetry.getPropagators()
    .getTextMapPropagator()
    .inject(Context.current(), outgoingRequest, setter);
```

### TypeScript Context Propagation

```typescript
import { propagation, context, trace } from '@opentelemetry/api';

// Extract from incoming HTTP headers
const incomingContext = propagation.extract(
  context.active(),
  req.headers,
  {
    get: (carrier, key) => carrier[key.toLowerCase()],
    keys: (carrier) => Object.keys(carrier)
  }
);

// Create span with extracted context as parent
const span = tracer.startSpan('handleRequest', {}, incomingContext);

// Inject into outgoing HTTP headers
const headers: Record<string, string> = {};
propagation.inject(context.active(), headers, {
  set: (carrier, key, value) => { carrier[key] = value; }
});
```

---

## Baggage (Cross-Cutting Concerns)

Baggage propagates key-value pairs across service boundaries:

```typescript
import { propagation, context } from '@opentelemetry/api';

// Set baggage
const baggage = propagation.createBaggage({
  'user.id': { value: 'user-123' },
  'tenant.id': { value: 'tenant-abc' },
  'request.priority': { value: 'high' }
});

const ctxWithBaggage = propagation.setBaggage(context.active(), baggage);

// Read baggage in downstream service
const currentBaggage = propagation.getBaggage(context.active());
const userId = currentBaggage?.getEntry('user.id')?.value;
```

---

## Exporter Configuration

### OTLP to Tempo/Jaeger

Environment variables for configuration:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://tempo:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Bearer token123
OTEL_EXPORTER_OTLP_TIMEOUT=10000
OTEL_EXPORTER_OTLP_COMPRESSION=gzip
```

### Collector Configuration

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 2000

exporters:
  otlp/tempo:
    endpoint: tempo:4317
    tls:
      insecure: true
  
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp/tempo]
```

---

## Sampling Strategies

### Head Sampling (SDK-level)

Decision made at span creation:

```java
// Java - TraceIdRatioBased sampler
SdkTracerProvider.builder()
    .setSampler(Sampler.traceIdRatioBased(0.1)) // 10% sampling
    .build();

// Parent-based with ratio
SdkTracerProvider.builder()
    .setSampler(Sampler.parentBased(
        Sampler.traceIdRatioBased(0.1)
    ))
    .build();
```

```typescript
// TypeScript
import { TraceIdRatioBasedSampler, ParentBasedSampler } from '@opentelemetry/sdk-trace-base';

const sampler = new ParentBasedSampler({
  root: new TraceIdRatioBasedSampler(0.1) // 10% of root spans
});
```

### Tail Sampling (Collector-level)

Decision made after span completion:

```yaml
# Collector tail sampling processor
processors:
  tail_sampling:
    decision_wait: 10s
    num_traces: 100000
    policies:
      - name: errors
        type: status_code
        status_code: { status_codes: [ERROR] }
      - name: slow-traces
        type: latency
        latency: { threshold_ms: 1000 }
      - name: percentage
        type: probabilistic
        probabilistic: { sampling_percentage: 10 }
```

---

## Auto-Instrumentation

### Java Agent

```bash
java -javaagent:opentelemetry-javaagent.jar \
  -Dotel.service.name=order-service \
  -Dotel.exporter.otlp.endpoint=http://tempo:4317 \
  -jar myapp.jar
```

Supported libraries include: Spring, HTTP clients, JDBC, Kafka, gRPC, Redis, MongoDB, and 100+ more.

### Node.js Auto-Instrumentation

```typescript
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

const sdk = new NodeSDK({
  instrumentations: [getNodeAutoInstrumentations()]
});
```

---

## Span Naming Conventions

Follow semantic conventions for consistent naming:

| Operation | Span Name Pattern |
|-----------|------------------|
| HTTP Server | `{http.method} {http.route}` e.g., `GET /api/orders/{id}` |
| HTTP Client | `{http.method}` e.g., `POST` |
| Database | `{db.operation} {db.name}.{table}` e.g., `SELECT orders` |
| Messaging | `{destination} {operation}` e.g., `orders.queue send` |
| RPC/gRPC | `{service}/{method}` e.g., `OrderService/CreateOrder` |

---

## Common Attributes (Semantic Conventions)

### HTTP

```
http.method: GET
http.url: https://api.example.com/orders/123
http.route: /orders/{id}
http.status_code: 200
http.request_content_length: 256
http.response_content_length: 1024
```

### Database

```
db.system: postgresql
db.name: orders_db
db.operation: SELECT
db.statement: SELECT * FROM orders WHERE id = $1
db.user: app_user
```

### Messaging

```
messaging.system: kafka
messaging.destination: orders.topic
messaging.destination_kind: topic
messaging.operation: publish
messaging.message_id: msg-123
```

---

## Error Recording

```java
try {
    // operation
} catch (Exception e) {
    span.recordException(e);
    span.setStatus(StatusCode.ERROR, "Operation failed: " + e.getMessage());
    span.setAttribute("error.type", e.getClass().getName());
}
```

This creates an event with attributes:
- `exception.type`: The exception class name
- `exception.message`: The exception message
- `exception.stacktrace`: Full stack trace

---

## Best Practices

1. **Use semantic conventions** - Consistent attribute names improve cross-service analysis
2. **Set service.name resource** - Required for service identification in backends
3. **Prefer BatchSpanProcessor** - SimpleSpanProcessor blocks; use only for debugging
4. **Propagate context** - Always extract/inject context at service boundaries
5. **Record exceptions** - Use `recordException()` and set status to ERROR
6. **Keep span names low-cardinality** - Avoid dynamic values in span names
7. **Use span events for milestones** - Track significant points within a span
8. **Configure sampling appropriately** - Balance visibility with cost
9. **Graceful shutdown** - Flush pending spans before process exit
10. **Instrument at boundaries** - Focus on HTTP, DB, queue, and cache operations

---

## Troubleshooting

### No Traces Appearing

1. Check exporter endpoint connectivity
2. Verify SDK initialization before first span
3. Confirm spans are being ended (`span.end()`)
4. Check sampling configuration (not dropping all traces)
5. Verify collector is receiving data (check collector logs)

### Broken Traces (Missing Spans)

1. Ensure context propagation at all boundaries
2. Verify async operations maintain context
3. Check for context loss in thread pools

### High Cardinality Issues

1. Avoid dynamic values in span names
2. Use parameterized routes (`/users/{id}` not `/users/123`)
3. Limit unique attribute values
