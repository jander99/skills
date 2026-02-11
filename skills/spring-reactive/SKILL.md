---
name: spring-reactive
description: Build reactive APIs and services with Spring WebFlux, Project Reactor (Mono, Flux), WebClient, and reactive operators. Capabilities include MDC context propagation (ContextRegistry, Hooks.enableAutomaticContextPropagation), WebClient configuration (timeouts, error handling, retry), reactive operator chains (flatMap, switchIfEmpty, zip), and blocking detection. Use when implementing WebFlux endpoints, propagating MDC/trace context across reactive boundaries, configuring WebClient, debugging context loss, handling backpressure, or testing reactive streams with StepVerifier.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: backend-development
---

# Spring Reactive

Build non-blocking, reactive web applications with Spring WebFlux and Project Reactor. This skill focuses on production patterns, especially MDC context propagation which is the #1 pain point in reactive applications.

## When to Use Me

- Implement reactive REST endpoints with WebFlux
- Propagate MDC context (traceId, requestId) across async boundaries
- Configure WebClient with proper timeouts, retries, and error handling
- Debug "context loss" issues where traceId disappears in logs
- Chain reactive operators (Mono/Flux) correctly
- Detect and handle blocking calls in reactive code
- Test reactive streams with StepVerifier

## What I Do

- Guide MDC context propagation setup with ContextRegistry and Hooks
- Provide WebClient configuration patterns (connection pools, timeouts)
- Explain Mono/Flux operator selection and chaining
- Help debug context loss and blocking call issues
- Show StepVerifier testing patterns
- Cover error handling strategies in reactive streams

## MDC Context Propagation

**This is critical.** Without proper setup, MDC context (traceId, spanId, requestId) is lost when crossing reactive boundaries.

### Required Configuration (Spring Boot 3.x / Reactor 3.5+)

```java
@Configuration
public class ReactorContextConfig {
    @PostConstruct
    public void setupContextPropagation() {
        // Enable automatic context propagation (Reactor 3.5+)
        Hooks.enableAutomaticContextPropagation();

        // Register MDC accessor with null-safe handling
        ContextRegistry.getInstance().registerThreadLocalAccessor(
            "mdc",
            () -> Optional.ofNullable(MDC.getCopyOfContextMap()).orElse(Map.of()),
            map -> { if (map != null) MDC.setContextMap(map); },
            MDC::clear
        );
    }
}
```

### Key Points

- Use Micrometer context-propagation integration for production (recommended over DIY)
- Context flows per-subscription within the same reactive chain
- Use `deferContextual` to **read** Reactor Context; don't assume operators "drop" context
- WebFilter captures context: `.contextWrite(ctx -> ctx.put("mdc", contextMap))`

## Reactor Patterns

### Mono/Flux Selection

| Use Case | Type | Why |
| -------- | ---- | --- |
| Single value or empty | `Mono<T>` | 0..1 elements |
| Collection/stream | `Flux<T>` | 0..N elements |
| Void operation | `Mono<Void>` | Side effects only |
| Optional result | `Mono<T>` with `switchIfEmpty` | Handle empty case |

### Common Operators

```java
// Transform
mono.map(x -> transform(x))           // Sync
mono.flatMap(x -> asyncCall(x))       // Async

// Handle empty
mono.switchIfEmpty(Mono.defer(() -> fallback()))
mono.defaultIfEmpty(defaultValue)

// Error handling
mono.onErrorResume(ex -> fallbackMono())
mono.onErrorMap(ex -> new CustomException(ex))

// Combine
Mono.zip(mono1, mono2, (a, b) -> combine(a, b))
Flux.merge(flux1, flux2)  // Interleaved
Flux.concat(flux1, flux2) // Sequential
```

### Anti-Patterns

```java
// BAD: Blocking in reactive chain
mono.map(x -> blockingCall(x))  // Blocks event loop!

// GOOD: Offload to bounded scheduler
mono.flatMap(x -> Mono.fromCallable(() -> blockingCall(x))
    .subscribeOn(Schedulers.boundedElastic()))
```

## WebClient Configuration

Configure `HttpClient` with timeouts, add MDC propagation filter via `Mono.deferContextual()`, handle errors with `.onStatus()`, retry with `Retry.backoff()`.

## Blocking Detection

| Violation | Solution |
| --------- | -------- |
| `Thread.sleep()` | `Mono.delay(Duration)` |
| JDBC calls | Use R2DBC or `subscribeOn(Schedulers.boundedElastic())` |
| `InputStream.read()` | Use `DataBufferUtils` |
| Synchronized blocks | Use `Mono.fromCallable().subscribeOn()` |

Enable BlockHound in dev/test to detect blocking violations automatically.

## Common Errors

| Error | Cause | Solution |
| ----- | ----- | -------- |
| MDC values null in logs | Context not propagated | Enable `Hooks.enableAutomaticContextPropagation()` |
| `block()/blockFirst()` error | Blocking on event loop | Use `subscribeOn(Schedulers.boundedElastic())` |
| Timeout on blocking read | WebClient timeout | Configure timeouts in HttpClient |
| Context is empty | New Mono without context | Use `Mono.deferContextual()` or `contextWrite()` |

## Testing with StepVerifier

```java
@Test
void shouldProcessReactively() {
    StepVerifier.create(service.process("input"))
        .expectNext("expected")
        .verifyComplete();
}

@Test
void shouldPropagateContext() {
    Mono<String> result = service.getTraceId()
        .contextWrite(ctx -> ctx.put("mdc", Map.of("traceId", "test-123")));

    StepVerifier.create(result)
        .expectNext("test-123")
        .verifyComplete();
}
```

## WebTestClient Testing

```java
@WebFluxTest(OrderController.class)
class OrderControllerTest {
    @Autowired
    private WebTestClient webClient;

    @MockBean
    private OrderService orderService;

    @Test
    void shouldReturnOrder() {
        when(orderService.findById(1L)).thenReturn(Mono.just(order));

        webClient.get().uri("/orders/1")
            .exchange()
            .expectStatus().isOk()
            .expectBody(Order.class).isEqualTo(order);
    }
}
```

## Backpressure Basics

| Strategy | Use When |
|----------|----------|
| `onBackpressureBuffer()` | Slow consumer, bounded buffer OK |
| `onBackpressureDrop()` | Latest value matters, can drop old |
| `limitRate(n)` | Control request batch size |

## Context7 Integration

For up-to-date Spring WebFlux documentation:

```
libraryName: "Spring WebFlux" or "Project Reactor"
Queries: "WebClient configuration", "Mono Flux operators", "Context propagation"
```

## Reference Navigation

| Topic | Reference | Load When |
| ----- | --------- | --------- |
| Full MDC WebFilter | [research.md](references/research.md) | Complete implementation |
| WebClient advanced config | [research.md](references/research.md) | Connection pool tuning, DNS resolver |
| Operator deep dive | [research.md](references/research.md) | Complete operator catalog |
| BlockHound setup | [research.md](references/research.md) | Blocking detection configuration |

## Related Skills

| Skill | Use For |
| ----- | ------- |
| spring-boot-core | General Spring Boot patterns |
| spring-testing | Testing strategies including WebTestClient |
| opentelemetry-tracing | Distributed tracing setup |

## Resources

- [Spring WebFlux Reference](https://docs.spring.io/spring-framework/reference/web/webflux.html)
- [Project Reactor Reference](https://projectreactor.io/docs/core/release/reference/)
- [Context Propagation Guide](https://spring.io/blog/2023/03/28/context-propagation-with-project-reactor-1-the-basics)
