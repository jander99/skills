---
name: opentelemetry-tracing
description: Instrument, configure, debug, and optimize OpenTelemetry distributed tracing for Java and TypeScript microservices. Create spans, propagate context, configure exporters, implement sampling. Use when adding tracing, debugging broken traces, or connecting services with W3C Trace Context.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: observability
---

# OpenTelemetry Distributed Tracing

Instrument, configure, and debug distributed tracing across microservices using OpenTelemetry.

## What I Do

- Initialize OpenTelemetry SDK for Java Spring Boot and Node.js/TypeScript applications
- Create spans with proper hierarchy, attributes, events, and error handling
- Configure context propagation using W3C Trace Context headers
- Set up OTLP exporters to send traces to Tempo, Jaeger, or other backends
- Implement head and tail sampling strategies
- Apply semantic conventions for consistent span naming and attributes
- Debug broken traces, missing spans, and context propagation issues

## When to Use Me

Use this skill when you:
- Add distributed tracing to a new or existing service
- Create custom spans for business operations
- Debug why traces are broken or spans are missing
- Configure trace exporters (OTLP to Tempo/Jaeger)
- Implement context propagation between services
- Set up sampling to reduce trace volume
- Troubleshoot context loss in async operations or thread pools

## SDK Initialization

**Java:** Create `@Bean OpenTelemetry` with `SdkTracerProvider`, `OtlpGrpcSpanExporter`, and `Resource` attributes.

**TypeScript:** Use `NodeSDK` with `OTLPTraceExporter` and run with `--import` flag.

## Creating Spans

### Java Pattern

```java
public Order processOrder(OrderRequest req) {
    Span span = tracer.spanBuilder("processOrder")
        .setAttribute("order.id", req.getOrderId())
        .startSpan();
    
    try (Scope scope = span.makeCurrent()) {
        return saveOrder(req);
    } catch (Exception e) {
        span.recordException(e);
        span.setStatus(StatusCode.ERROR);
        throw e;
    } finally {
        span.end();
    }
}
```

### TypeScript Pattern

```typescript
return tracer.startActiveSpan('processOrder', async (span) => {
  try {
    span.setAttribute('order.id', req.orderId);
    return await saveOrder(req);
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: SpanStatusCode.ERROR });
    throw error;
  } finally {
    span.end();
  }
});
```

## Context Propagation

### W3C Trace Context Format

```
traceparent: 00-{trace-id}-{span-id}-{flags}
tracestate: vendor1=value1,vendor2=value2
```

Auto-instrumentation handles this for HTTP. For manual propagation:

**Java:** Use `openTelemetry.getPropagators().getTextMapPropagator()`  
**TypeScript:** Use `propagation.extract()` and `propagation.inject()`

## Environment Variables

```bash
OTEL_SERVICE_NAME=order-service
OTEL_EXPORTER_OTLP_ENDPOINT=http://tempo:4317
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1  # 10% sampling
```

## Instrumentation Approaches

| Approach | Setup | Coverage | Control |
|----------|-------|----------|---------|
| Auto-instrumentation (Agent) | Java agent JAR | Automatic | Low |
| SDK with auto libs | Add dependencies | Semi-auto | Medium |
| Manual SDK | Code spans yourself | Custom only | Full |

### Java Auto-Instrumentation
```bash
java -javaagent:opentelemetry-javaagent.jar \
  -Dotel.service.name=my-service \
  -Dotel.exporter.otlp.endpoint=http://collector:4317 \
  -jar app.jar
```

### TypeScript Auto-Instrumentation
```typescript
// tracing.ts - import BEFORE anything else
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

const sdk = new NodeSDK({
  serviceName: 'my-service',
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
```

## Baggage and Propagators

```java
// Add baggage (propagates to downstream services)
Baggage.current().toBuilder()
    .put("user.id", userId)
    .build()
    .makeCurrent();

// Configure propagators
OpenTelemetrySdk.builder()
    .setPropagators(ContextPropagators.create(
        TextMapPropagator.composite(
            W3CTraceContextPropagator.getInstance(),
            W3CBaggagePropagator.getInstance()
        )
    ))
```

## Sampling

| Type | When | Configuration |
|------|------|---------------|
| Head (SDK) | Simple, fast | `Sampler.traceIdRatioBased(0.1)` |
| Tail (Collector) | Keep errors/slow | Collector tail_sampling processor |

**Head sampling example:**
```java
SdkTracerProvider.builder()
    .setSampler(Sampler.parentBased(Sampler.traceIdRatioBased(0.1)))
    .build();
```

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| No traces appearing | SDK not initialized | Initialize before first span |
| Broken traces | Context not propagated | Extract context from headers |
| Async context loss | Wrong context in callbacks | Use `Context.current()` + `makeCurrent()` |
| High cardinality | Dynamic span names | Use parameterized names: `/users/{id}` |
| Spans not ended | Missing finally block | Always call `span.end()` in finally |

### Fix Async Context Loss

```java
Context ctx = Context.current();
executor.submit(() -> {
    try (Scope scope = ctx.makeCurrent()) {
        // context available here
    }
});
```

## Context7 Integration

For the latest OpenTelemetry documentation:

```
Query: "OpenTelemetry Java SDK span creation"
Library: /open-telemetry/opentelemetry-java
```

> See `references/research.md` for detailed examples and advanced patterns.

## Related Skills

- **spring-reactive**: WebFlux context propagation with Reactor
- **loki-logging**: Correlate logs with trace IDs
- **prometheus-alerting**: Create alerts on trace metrics

## Resources

- [OpenTelemetry Docs](https://opentelemetry.io/docs/) - Official documentation
- [Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/) - Standard attributes
