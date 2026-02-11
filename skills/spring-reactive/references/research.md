# Spring WebFlux & Project Reactor Research

> Comprehensive research findings for reactive programming best practices

---

## MDC Context Propagation (Critical)

### The Problem

In traditional servlet-based applications, MDC (Mapped Diagnostic Context) uses ThreadLocal storage. Each request runs on a dedicated thread, so MDC values persist throughout the request lifecycle.

In reactive applications, a single request may execute across multiple threads. ThreadLocal values are lost when execution hops between threads, causing:
- Missing traceId/spanId in logs
- Broken distributed tracing
- Inability to correlate log statements

### The Solution Stack

**Required components (Spring Boot 3.x / Reactor 3.5+):**

1. **Hooks.enableAutomaticContextPropagation()** - Enables Reactor's context propagation
2. **ContextRegistry** - Maps Reactor Context to ThreadLocal accessors
3. **WebFilter** - Captures initial context at request entry
4. **contextWrite()** - Attaches context to reactive chains

### Complete Setup

```java
@Configuration
public class ReactorContextConfiguration {

    private static final Logger log = LoggerFactory.getLogger(ReactorContextConfiguration.class);

    @PostConstruct
    public void setupReactorContext() {
        // Step 1: Enable automatic context propagation
        // This tells Reactor to automatically restore ThreadLocal values
        // when operators execute on different threads
        Hooks.enableAutomaticContextPropagation();
        
        // Step 2: Register MDC with the ContextRegistry
        // This creates a bridge between Reactor Context and MDC ThreadLocal
        ContextRegistry.getInstance().registerThreadLocalAccessor(
            "mdc",                          // Key name in Reactor Context
            MDC::getCopyOfContextMap,       // How to capture current value
            map -> {                        // How to restore value
                if (map != null) {
                    MDC.setContextMap(map);
                }
            },
            MDC::clear                      // How to clear value
        );
        
        log.info("Reactor context propagation configured");
    }
}
```

### MdcContextWebFilter Implementation

```java
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class MdcContextWebFilter implements WebFilter {

    private static final String TRACE_ID_HEADER = "X-Trace-Id";
    private static final String REQUEST_ID_HEADER = "X-Request-Id";
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        // Extract or generate trace context
        String traceId = Optional.ofNullable(
                exchange.getRequest().getHeaders().getFirst(TRACE_ID_HEADER))
            .filter(s -> !s.isBlank())
            .orElseGet(() -> UUID.randomUUID().toString().replace("-", ""));
        
        String requestId = UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        
        // Create MDC map
        Map<String, String> contextMap = new HashMap<>();
        contextMap.put("traceId", traceId);
        contextMap.put("requestId", requestId);
        contextMap.put("path", exchange.getRequest().getPath().value());
        contextMap.put("method", exchange.getRequest().getMethod().name());
        
        // Attach to Reactor Context - this propagates to all downstream operators
        return chain.filter(exchange)
            .contextWrite(ctx -> ctx.put("mdc", contextMap));
    }
}
```

### Accessing Context in Business Logic

```java
@Service
public class OrderService {

    public Mono<Order> createOrder(OrderRequest request) {
        return Mono.deferContextual(ctx -> {
            // Access MDC from Reactor Context
            Map<String, String> mdc = ctx.getOrDefault("mdc", Collections.emptyMap());
            String traceId = mdc.get("traceId");
            
            log.info("Creating order, traceId={}", traceId);
            
            return orderRepository.save(toOrder(request));
        });
    }
}
```

### OpenTelemetry Integration

When using OpenTelemetry with WebFlux, context propagation requires additional setup:

```java
@Configuration
public class OtelReactorConfig {

    @PostConstruct
    public void configureOtelContextPropagation() {
        // Reactor hooks for automatic propagation
        Hooks.enableAutomaticContextPropagation();
        
        // Register OpenTelemetry Context with ContextRegistry
        ContextRegistry.getInstance().registerThreadLocalAccessor(
            "otel-context",
            io.opentelemetry.context.Context::current,
            context -> context.makeCurrent(),
            () -> {} // No-op clear
        );
    }
}
```

---

## Mono/Flux Operators Reference

### Creation Operators

| Operator | Use Case | Example |
| -------- | -------- | ------- |
| `Mono.just(T)` | Wrap existing value | `Mono.just("hello")` |
| `Mono.empty()` | No value | `Mono.empty()` |
| `Mono.error(Throwable)` | Signal error | `Mono.error(new RuntimeException())` |
| `Mono.defer(Supplier)` | Lazy evaluation | `Mono.defer(() -> compute())` |
| `Mono.fromCallable()` | Wrap blocking call | `Mono.fromCallable(() -> blockingOp())` |
| `Mono.fromFuture()` | Wrap CompletableFuture | `Mono.fromFuture(future)` |
| `Flux.fromIterable()` | Wrap collection | `Flux.fromIterable(list)` |
| `Flux.range(start, count)` | Numeric sequence | `Flux.range(1, 10)` |
| `Flux.interval(Duration)` | Periodic emission | `Flux.interval(Duration.ofSeconds(1))` |

### Transformation Operators

```java
// map - synchronous transformation
mono.map(user -> user.getName())

// flatMap - asynchronous transformation (returns Publisher)
mono.flatMap(userId -> userRepository.findById(userId))

// flatMapMany - Mono to Flux transformation
mono.flatMapMany(user -> Flux.fromIterable(user.getOrders()))

// flatMapSequential - preserve order with parallel execution
flux.flatMapSequential(item -> processAsync(item), 4)

// concatMap - sequential flatMap (one at a time)
flux.concatMap(item -> processAsync(item))

// switchMap - cancel previous on new emission
flux.switchMap(search -> searchService.query(search))

// transform - reusable operator chain
mono.transform(this::addLogging)

private <T> Mono<T> addLogging(Mono<T> mono) {
    return mono
        .doOnSubscribe(s -> log.debug("Subscribed"))
        .doOnSuccess(v -> log.debug("Completed"));
}
```

### Filtering Operators

```java
// filter - keep matching elements
flux.filter(user -> user.isActive())

// filterWhen - async predicate
flux.filterWhen(user -> checkPermission(user))

// distinct - remove duplicates
flux.distinct()
flux.distinctUntilChanged()

// take/skip
flux.take(10)           // First 10
flux.takeLast(5)        // Last 5
flux.skip(10)           // Skip first 10
flux.takeUntil(pred)    // Until predicate matches
flux.takeWhile(pred)    // While predicate matches

// next - first element as Mono
flux.next()

// single - exactly one element (error if 0 or >1)
flux.single()

// elementAt - specific index
flux.elementAt(5)
```

### Combining Operators

```java
// zip - combine element-wise
Mono.zip(userMono, ordersMono, (user, orders) -> new UserOrders(user, orders))

// zipWith - combine with another publisher
userMono.zipWith(ordersMono)

// merge - interleaved combination
Flux.merge(flux1, flux2)

// concat - sequential combination
Flux.concat(flux1, flux2)

// combineLatest - latest from each
Flux.combineLatest(flux1, flux2, (a, b) -> a + b)

// firstWithValue - race condition
Mono.firstWithValue(primary, fallback)

// mergeWith - merge into existing flux
flux1.mergeWith(flux2)

// startWith - prepend elements
flux.startWith(header)
```

### Error Handling Operators

```java
// onErrorReturn - fallback value
mono.onErrorReturn(defaultValue)
mono.onErrorReturn(IOException.class, defaultValue)

// onErrorResume - fallback publisher
mono.onErrorResume(ex -> fallbackMono())
mono.onErrorResume(IOException.class, ex -> fallbackMono())

// onErrorMap - transform error
mono.onErrorMap(ex -> new CustomException(ex))
mono.onErrorMap(IOException.class, ex -> new ServiceException(ex))

// onErrorComplete - swallow error
mono.onErrorComplete()

// retry - simple retry
mono.retry(3)

// retryWhen - advanced retry with backoff
mono.retryWhen(Retry.backoff(3, Duration.ofMillis(100))
    .maxBackoff(Duration.ofSeconds(2))
    .jitter(0.5)
    .filter(ex -> ex instanceof RetryableException)
    .doBeforeRetry(signal -> log.warn("Retrying: {}", signal.failure().getMessage()))
    .onRetryExhaustedThrow((spec, signal) -> signal.failure()))

// timeout
mono.timeout(Duration.ofSeconds(5))
mono.timeout(Duration.ofSeconds(5), fallbackMono)
```

### Side Effect Operators

```java
// doOnNext - each element
flux.doOnNext(item -> log.debug("Processing: {}", item))

// doOnSuccess - single completion (Mono)
mono.doOnSuccess(result -> metrics.recordSuccess())

// doOnComplete - completion signal (Flux)
flux.doOnComplete(() -> log.info("Stream completed"))

// doOnError - error signal
mono.doOnError(ex -> log.error("Failed", ex))
mono.doOnError(IOException.class, ex -> alerting.notify(ex))

// doOnSubscribe - subscription
mono.doOnSubscribe(sub -> log.debug("Subscribed"))

// doOnCancel - cancellation
mono.doOnCancel(() -> log.debug("Cancelled"))

// doOnTerminate - complete or error
mono.doOnTerminate(() -> cleanup())

// doFinally - always (complete, error, or cancel)
mono.doFinally(signal -> {
    switch (signal) {
        case ON_COMPLETE -> metrics.recordComplete();
        case ON_ERROR -> metrics.recordError();
        case CANCEL -> metrics.recordCancel();
    }
})

// doOnEach - all signals
mono.doOnEach(signal -> {
    if (signal.isOnNext()) log.debug("Next: {}", signal.get());
    if (signal.isOnError()) log.error("Error", signal.getThrowable());
})
```

### Empty Handling

```java
// switchIfEmpty - alternative when empty
mono.switchIfEmpty(Mono.defer(() -> computeAlternative()))

// defaultIfEmpty - default value when empty
mono.defaultIfEmpty(defaultValue)

// hasElement - check if has value
mono.hasElement()  // Mono<Boolean>

// switchIfEmpty with error
mono.switchIfEmpty(Mono.error(new NotFoundException()))
```

---

## WebClient Configuration

### Connection Pool Tuning

```java
@Configuration
public class WebClientConfiguration {

    @Bean
    public WebClient webClient(WebClientProperties properties) {
        // Connection provider with pool configuration
        ConnectionProvider provider = ConnectionProvider.builder("custom")
            .maxConnections(100)                    // Max total connections
            .maxIdleTime(Duration.ofSeconds(30))   // Idle connection timeout
            .maxLifeTime(Duration.ofMinutes(5))    // Max connection lifetime
            .pendingAcquireTimeout(Duration.ofSeconds(45)) // Wait for connection
            .pendingAcquireMaxCount(500)           // Max waiting requests
            .evictInBackground(Duration.ofSeconds(30)) // Background cleanup
            .metrics(true)                         // Enable metrics
            .build();

        HttpClient httpClient = HttpClient.create(provider)
            .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 5000)
            .option(ChannelOption.SO_KEEPALIVE, true)
            .responseTimeout(Duration.ofSeconds(30))
            .compress(true)
            .wiretap(false);  // Enable for debugging only

        return WebClient.builder()
            .clientConnector(new ReactorClientHttpConnector(httpClient))
            .codecs(configurer -> configurer
                .defaultCodecs()
                .maxInMemorySize(16 * 1024 * 1024))  // 16MB buffer
            .build();
    }
}
```

### DNS Resolution Issues

Reactor Netty's default DNS resolver can hang or be slow. Configure explicit timeouts:

```java
HttpClient httpClient = HttpClient.create()
    .resolver(spec -> spec
        .queryTimeout(Duration.ofSeconds(5))
        .maxQueriesPerResolve(3)
        .trace("DNS", LogLevel.DEBUG)  // Debug logging
        .cacheMaxTimeToLive(Duration.ofMinutes(5))
        .cacheMinTimeToLive(Duration.ofSeconds(30))
        .cacheNegativeTimeToLive(Duration.ofSeconds(10)));
```

For environments with DNS issues, consider using IP addresses or a custom resolver.

### Request/Response Logging

```java
@Bean
public WebClient webClient() {
    return WebClient.builder()
        .filter(logRequest())
        .filter(logResponse())
        .build();
}

private ExchangeFilterFunction logRequest() {
    return ExchangeFilterFunction.ofRequestProcessor(request -> {
        log.debug("Request: {} {}", request.method(), request.url());
        request.headers().forEach((name, values) -> 
            log.trace("Header: {}={}", name, values));
        return Mono.just(request);
    });
}

private ExchangeFilterFunction logResponse() {
    return ExchangeFilterFunction.ofResponseProcessor(response -> {
        log.debug("Response: {}", response.statusCode());
        return Mono.just(response);
    });
}
```

### Error Handling Strategies

```java
public Mono<Response> callWithErrorHandling(Request request) {
    return webClient.post()
        .uri("/api/endpoint")
        .bodyValue(request)
        .retrieve()
        // Handle 4xx errors
        .onStatus(HttpStatusCode::is4xxClientError, response -> 
            response.bodyToMono(ApiError.class)
                .flatMap(error -> {
                    if (response.statusCode() == HttpStatus.NOT_FOUND) {
                        return Mono.error(new NotFoundException(error.getMessage()));
                    }
                    if (response.statusCode() == HttpStatus.BAD_REQUEST) {
                        return Mono.error(new ValidationException(error.getDetails()));
                    }
                    return Mono.error(new ClientException(error.getMessage()));
                }))
        // Handle 5xx errors
        .onStatus(HttpStatusCode::is5xxServerError, response ->
            Mono.error(new UpstreamServiceException(
                "Service returned " + response.statusCode())))
        .bodyToMono(Response.class)
        // Retry only on specific errors
        .retryWhen(Retry.backoff(3, Duration.ofMillis(500))
            .maxBackoff(Duration.ofSeconds(5))
            .filter(this::isRetryable)
            .doBeforeRetry(signal -> log.warn("Retry #{}: {}", 
                signal.totalRetries() + 1, signal.failure().getMessage())))
        // Circuit breaker integration
        .transformDeferred(CircuitBreakerOperator.of(circuitBreaker))
        // Timeout
        .timeout(Duration.ofSeconds(30))
        .onErrorResume(TimeoutException.class, ex -> 
            Mono.error(new ServiceTimeoutException("Call timed out")));
}

private boolean isRetryable(Throwable ex) {
    return ex instanceof UpstreamServiceException ||
           ex instanceof ConnectException ||
           ex instanceof TimeoutException;
}
```

---

## Blocking Call Detection and Handling

### BlockHound Setup

```xml
<dependency>
    <groupId>io.projectreactor.tools</groupId>
    <artifactId>blockhound</artifactId>
    <scope>test</scope>
</dependency>
```

```java
@TestConfiguration
public class BlockHoundConfiguration {

    @PostConstruct
    public void installBlockHound() {
        BlockHound.builder()
            // Allow known blocking calls
            .allowBlockingCallsInside("org.slf4j.LoggerFactory", "getLogger")
            .allowBlockingCallsInside("ch.qos.logback.classic.Logger", "callAppenders")
            .allowBlockingCallsInside("io.micrometer.core.instrument.MeterRegistry", "counter")
            // Custom integrations
            .with(new ReactorBlockHoundIntegration())
            .install();
    }
}
```

### Offloading Blocking Calls

```java
// Pattern 1: subscribeOn for single blocking call
public Mono<Data> fetchFromLegacySystem(String id) {
    return Mono.fromCallable(() -> legacyClient.fetch(id))  // Blocking call
        .subscribeOn(Schedulers.boundedElastic());          // Offload to elastic pool
}

// Pattern 2: Multiple blocking calls
public Flux<Result> processAll(List<String> ids) {
    return Flux.fromIterable(ids)
        .flatMap(id -> Mono.fromCallable(() -> blockingProcess(id))
            .subscribeOn(Schedulers.boundedElastic()), 
            4);  // Concurrency limit
}

// Pattern 3: Mixed reactive and blocking
public Mono<CompleteResult> processWithLegacy(Request request) {
    return reactiveRepository.findById(request.getId())
        .flatMap(entity -> Mono.fromCallable(() -> legacyEnrich(entity))
            .subscribeOn(Schedulers.boundedElastic()))
        .flatMap(enriched -> reactiveRepository.save(enriched));
}
```

### Common Blocking Violations

| Violation | Reactive Alternative |
| --------- | -------------------- |
| `Thread.sleep(ms)` | `Mono.delay(Duration.ofMillis(ms))` |
| `future.get()` | `Mono.fromFuture(future)` |
| `inputStream.read()` | `DataBufferUtils.read()` |
| JDBC operations | R2DBC or `subscribeOn(boundedElastic)` |
| `synchronized` block | `Mono.fromCallable().subscribeOn()` |
| `ReentrantLock.lock()` | `Mono.fromCallable().subscribeOn()` |
| `CountDownLatch.await()` | `Mono.zip()` or `Flux.merge()` |

---

## Testing Reactive Code

### StepVerifier Basics

```java
@Test
void shouldEmitValues() {
    Flux<Integer> flux = Flux.range(1, 3);
    
    StepVerifier.create(flux)
        .expectNext(1)
        .expectNext(2)
        .expectNext(3)
        .verifyComplete();
}

@Test
void shouldEmitValuesWithAssertion() {
    Flux<String> flux = service.getNames();
    
    StepVerifier.create(flux)
        .expectNextMatches(name -> name.startsWith("A"))
        .expectNextCount(5)
        .assertNext(name -> assertThat(name).hasSize(10))
        .thenConsumeWhile(name -> name.length() > 0)
        .verifyComplete();
}
```

### Testing Errors

```java
@Test
void shouldHandleError() {
    Mono<String> mono = service.failingOperation();
    
    StepVerifier.create(mono)
        .expectErrorMatches(ex -> 
            ex instanceof ServiceException &&
            ex.getMessage().contains("expected failure"))
        .verify();
}

@Test
void shouldRecoverFromError() {
    Mono<String> mono = service.operationWithFallback();
    
    StepVerifier.create(mono)
        .expectNext("fallback-value")
        .verifyComplete();
}
```

### Testing with Virtual Time

```java
@Test
void shouldRespectDelay() {
    StepVerifier.withVirtualTime(() -> 
            Mono.delay(Duration.ofHours(1)).thenReturn("delayed"))
        .expectSubscription()
        .expectNoEvent(Duration.ofMinutes(59))
        .thenAwait(Duration.ofMinutes(1))
        .expectNext("delayed")
        .verifyComplete();
}

@Test
void shouldRetryWithBackoff() {
    AtomicInteger attempts = new AtomicInteger(0);
    
    Mono<String> mono = Mono.defer(() -> {
        if (attempts.incrementAndGet() < 3) {
            return Mono.error(new RuntimeException("Retry"));
        }
        return Mono.just("success");
    }).retryWhen(Retry.backoff(3, Duration.ofSeconds(1)));
    
    StepVerifier.withVirtualTime(() -> mono)
        .expectSubscription()
        .thenAwait(Duration.ofSeconds(3))
        .expectNext("success")
        .verifyComplete();
    
    assertThat(attempts.get()).isEqualTo(3);
}
```

### Testing Context Propagation

```java
@Test
void shouldPropagateContext() {
    String traceId = "test-trace-123";
    Map<String, String> mdc = Map.of("traceId", traceId);
    
    Mono<String> mono = service.getTraceId()
        .contextWrite(ctx -> ctx.put("mdc", mdc));
    
    StepVerifier.create(mono)
        .expectNext(traceId)
        .verifyComplete();
}

@Test
void shouldAccessContextInOperator() {
    Mono<String> mono = Mono.deferContextual(ctx -> {
        Map<String, String> mdc = ctx.getOrDefault("mdc", Map.of());
        return Mono.just(mdc.getOrDefault("userId", "anonymous"));
    }).contextWrite(ctx -> ctx.put("mdc", Map.of("userId", "user-456")));
    
    StepVerifier.create(mono)
        .expectNext("user-456")
        .verifyComplete();
}
```

### WebTestClient

```java
@WebFluxTest(UserController.class)
class UserControllerTest {

    @Autowired
    private WebTestClient webClient;
    
    @MockBean
    private UserService userService;
    
    @Test
    void shouldGetUser() {
        when(userService.findById("123"))
            .thenReturn(Mono.just(new User("123", "John")));
        
        webClient.get()
            .uri("/users/123")
            .exchange()
            .expectStatus().isOk()
            .expectBody(User.class)
            .value(user -> {
                assertThat(user.getId()).isEqualTo("123");
                assertThat(user.getName()).isEqualTo("John");
            });
    }
    
    @Test
    void shouldStreamUsers() {
        when(userService.findAll())
            .thenReturn(Flux.just(new User("1", "A"), new User("2", "B")));
        
        webClient.get()
            .uri("/users/stream")
            .accept(MediaType.TEXT_EVENT_STREAM)
            .exchange()
            .expectStatus().isOk()
            .expectBodyList(User.class)
            .hasSize(2);
    }
}
```

---

## Common Mistakes and Anti-Patterns

### 1. Creating New Publishers Without Context

```java
// BAD: Context is lost
public Mono<Result> process(Request request) {
    Result result = computeResult(request);
    return Mono.just(result);  // No context!
}

// GOOD: Preserve context
public Mono<Result> process(Request request) {
    return Mono.deferContextual(ctx -> {
        Result result = computeResult(request);
        return Mono.just(result);
    });
}
```

### 2. Blocking in Operators

```java
// BAD: Blocks event loop
public Mono<Data> getData(String id) {
    return Mono.just(id)
        .map(i -> jdbcTemplate.queryForObject(...));  // BLOCKING!
}

// GOOD: Offload to elastic scheduler
public Mono<Data> getData(String id) {
    return Mono.fromCallable(() -> jdbcTemplate.queryForObject(...))
        .subscribeOn(Schedulers.boundedElastic());
}
```

### 3. Not Subscribing

```java
// BAD: Nothing happens - no subscription!
public void sendNotification(User user) {
    notificationService.send(user);  // Returns Mono, never subscribed
}

// GOOD: Subscribe or return to caller
public Mono<Void> sendNotification(User user) {
    return notificationService.send(user);  // Caller subscribes
}

// Or if fire-and-forget is needed:
public void sendNotification(User user) {
    notificationService.send(user)
        .subscribe(
            null,
            ex -> log.error("Notification failed", ex)
        );
}
```

### 4. Using .block() in Reactive Code

```java
// BAD: Defeats purpose of reactive
public Mono<FullData> getFullData(String id) {
    User user = userService.findById(id).block();  // NEVER!
    Orders orders = orderService.findByUser(user).block();
    return Mono.just(new FullData(user, orders));
}

// GOOD: Chain reactively
public Mono<FullData> getFullData(String id) {
    return userService.findById(id)
        .flatMap(user -> orderService.findByUser(user)
            .collectList()
            .map(orders -> new FullData(user, orders)));
}
```

### 5. Ignoring Empty Cases

```java
// BAD: NullPointerException risk
public Mono<String> getName(String id) {
    return userRepository.findById(id)
        .map(user -> user.getName());  // What if empty?
}

// GOOD: Handle empty explicitly
public Mono<String> getName(String id) {
    return userRepository.findById(id)
        .map(User::getName)
        .switchIfEmpty(Mono.error(new UserNotFoundException(id)));
}
```

### 6. Sharing Mutable State

```java
// BAD: Race conditions
List<Result> results = new ArrayList<>();
flux.doOnNext(item -> results.add(process(item)))  // Not thread-safe!
    .subscribe();

// GOOD: Collect immutably
flux.map(this::process)
    .collectList()
    .subscribe(results -> handleResults(results));
```

---

## Performance Considerations

### Scheduler Selection

| Scheduler | Use Case | Thread Pool |
| --------- | -------- | ----------- |
| `parallel()` | CPU-bound work | Fixed (CPU cores) |
| `boundedElastic()` | Blocking I/O | Elastic (grows/shrinks) |
| `single()` | Sequential work | 1 thread |
| `immediate()` | Same thread | Current |

### Backpressure Strategies

```java
// limitRate - request in batches
flux.limitRate(100)  // Request 100 at a time

// onBackpressureBuffer - buffer with limit
flux.onBackpressureBuffer(1000, 
    dropped -> log.warn("Dropped: {}", dropped))

// onBackpressureDrop - drop excess
flux.onBackpressureDrop(dropped -> metrics.recordDrop())

// onBackpressureLatest - keep only latest
flux.onBackpressureLatest()
```

### Memory Optimization

```java
// Avoid collecting large datasets
// BAD: 
flux.collectList()  // Holds everything in memory

// GOOD: Process in chunks
flux.window(100)
    .flatMap(window -> window.collectList().flatMap(this::processBatch))
```

---

## Dependencies

```xml
<!-- Spring Boot WebFlux -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>

<!-- Project Reactor (included with WebFlux) -->
<dependency>
    <groupId>io.projectreactor</groupId>
    <artifactId>reactor-core</artifactId>
</dependency>

<!-- Context Propagation (Spring Boot 3.x) -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>context-propagation</artifactId>
</dependency>

<!-- Testing -->
<dependency>
    <groupId>io.projectreactor</groupId>
    <artifactId>reactor-test</artifactId>
    <scope>test</scope>
</dependency>

<!-- BlockHound (testing only) -->
<dependency>
    <groupId>io.projectreactor.tools</groupId>
    <artifactId>blockhound</artifactId>
    <scope>test</scope>
</dependency>
```

---

## Resources

- [Spring WebFlux Reference](https://docs.spring.io/spring-framework/reference/web/webflux.html)
- [Project Reactor Reference](https://projectreactor.io/docs/core/release/reference/)
- [Reactor Operators Reference](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html)
- [Context Propagation Blog Series](https://spring.io/blog/2023/03/28/context-propagation-with-project-reactor-1-the-basics)
- [BlockHound](https://github.com/reactor/BlockHound)
- [R2DBC](https://r2dbc.io/)
