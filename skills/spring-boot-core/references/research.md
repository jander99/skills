# Spring Boot Core Best Practices Research

Research findings on Spring Boot microservice development patterns, gathered from official Spring Boot documentation and industry best practices.

## Constructor Injection Pattern

### Why Constructor Injection Over Field Injection

Spring officially recommends constructor injection for dependency injection. From the Spring Boot documentation:

> "We generally recommend using constructor injection to wire up dependencies."

**Benefits:**

1. **Immutability**: Dependencies declared as `final` fields cannot be changed after construction
2. **Required Dependencies**: Missing dependencies cause compile-time or startup errors (fail-fast)
3. **Testability**: Easy to pass mock objects directly through constructor in unit tests
4. **No Reflection**: Constructor injection doesn't require reflection, improving performance
5. **Explicit Dependencies**: All dependencies visible in constructor signature

**Field Injection Problems:**

```java
// ANTI-PATTERN: Field injection
@Service
public class OrderService {
    @Autowired
    private OrderRepository repository;  // Hidden dependency!
    
    @Autowired
    private PaymentClient client;  // Can't see dependencies at glance
}
```

Issues:
- Dependencies hidden from callers
- Requires reflection to inject
- Cannot make fields final
- Harder to test (need reflection or Spring context)
- NPE risk if bean used before injection complete

**Correct Pattern:**

```java
@Service
public class OrderService {

    private final OrderRepository repository;
    private final PaymentClient client;

    // @Autowired optional with single constructor (Spring 4.3+)
    public OrderService(OrderRepository repository, PaymentClient client) {
        this.repository = repository;
        this.client = client;
    }
}
```

### Multiple Constructors

When a class has multiple constructors, annotate the preferred one with `@Autowired`:

```java
@Service
public class FlexibleService {

    private final RequiredDependency required;
    private final OptionalDependency optional;

    @Autowired  // Tell Spring to use this constructor
    public FlexibleService(RequiredDependency required) {
        this(required, null);
    }

    public FlexibleService(RequiredDependency required, OptionalDependency optional) {
        this.required = required;
        this.optional = optional;
    }
}
```

### Optional Dependencies

For truly optional dependencies, use `Optional<T>` or `@Autowired(required = false)`:

```java
@Service
public class ServiceWithOptionalDeps {

    private final RequiredService required;
    private final Optional<CacheService> cache;

    public ServiceWithOptionalDeps(
            RequiredService required,
            Optional<CacheService> cache) {
        this.required = required;
        this.cache = cache;
    }

    public Data getData(String id) {
        return cache
            .map(c -> c.get(id))
            .orElseGet(() -> required.fetch(id));
    }
}
```

---

## @ConfigurationProperties with Validation

### Type-Safe Configuration Binding

Spring Boot's `@ConfigurationProperties` provides type-safe binding of external configuration to Java objects.

**Key Features:**
- Relaxed binding (kebab-case in YAML maps to camelCase in Java)
- Type conversion (strings to Duration, DataSize, etc.)
- Validation support via JSR-303 annotations
- Nested object binding
- Collection binding (lists, maps)

### Basic Pattern

```java
@ConfigurationProperties("app.payment")
@Validated
public class PaymentProperties {

    /**
     * Base URL for payment gateway
     */
    @NotBlank
    private String gatewayUrl;

    /**
     * Connection timeout for payment requests
     */
    @NotNull
    private Duration timeout = Duration.ofSeconds(30);

    /**
     * Maximum retry attempts
     */
    @Min(0)
    @Max(10)
    private int maxRetries = 3;

    // Getters and setters required for JavaBean binding
    public String getGatewayUrl() { return gatewayUrl; }
    public void setGatewayUrl(String gatewayUrl) { this.gatewayUrl = gatewayUrl; }
    
    public Duration getTimeout() { return timeout; }
    public void setTimeout(Duration timeout) { this.timeout = timeout; }
    
    public int getMaxRetries() { return maxRetries; }
    public void setMaxRetries(int maxRetries) { this.maxRetries = maxRetries; }
}
```

Corresponding YAML:

```yaml
app:
  payment:
    gateway-url: https://api.payments.example.com
    timeout: 30s
    max-retries: 3
```

### Constructor Binding (Immutable)

For immutable configuration objects (recommended for thread safety):

```java
@ConfigurationProperties("app.api")
public class ApiProperties {

    private final String baseUrl;
    private final Duration timeout;
    private final Security security;

    public ApiProperties(
            String baseUrl,
            @DefaultValue("30s") Duration timeout,
            Security security) {
        this.baseUrl = baseUrl;
        this.timeout = timeout;
        this.security = security;
    }

    // Only getters, no setters
    public String getBaseUrl() { return baseUrl; }
    public Duration getTimeout() { return timeout; }
    public Security getSecurity() { return security; }

    public record Security(String apiKey, List<String> allowedOrigins) {
        public Security {
            if (allowedOrigins == null) {
                allowedOrigins = List.of();
            }
        }
    }
}
```

### Enabling Configuration Properties

Two approaches:

**1. Component Scanning (recommended for application code):**

```java
@SpringBootApplication
@ConfigurationPropertiesScan  // Scans for @ConfigurationProperties in app packages
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

**2. Explicit Registration (for libraries/auto-configuration):**

```java
@Configuration
@EnableConfigurationProperties(PaymentProperties.class)
public class PaymentConfiguration {
    // ...
}
```

### Validation with Nested Objects

Use `@Valid` to cascade validation to nested objects:

```java
@ConfigurationProperties("app.service")
@Validated
public class ServiceProperties {

    @Valid  // Cascade validation
    @NotNull
    private final DatabaseProperties database;

    @Valid
    private final CacheProperties cache;

    // Constructor binding
    public ServiceProperties(
            DatabaseProperties database,
            @DefaultValue CacheProperties cache) {
        this.database = database;
        this.cache = cache;
    }

    public record DatabaseProperties(
            @NotBlank String url,
            @NotBlank String username,
            @NotNull Duration connectionTimeout) {}

    public record CacheProperties(
            boolean enabled,
            @DurationMin(seconds = 1) Duration ttl) {
        public CacheProperties {
            if (ttl == null) ttl = Duration.ofMinutes(5);
        }
    }
}
```

### Relaxed Binding Rules

Spring Boot uses relaxed binding, mapping various formats to Java properties:

| Property Source | Format |
|-----------------|--------|
| application.yml | `my.property-name` (kebab-case recommended) |
| application.properties | `my.propertyName` or `my.property-name` |
| Environment variable | `MY_PROPERTYNAME` |
| System property | `my.propertyName` |

All map to Java field: `myPropertyName`

---

## Profile-Based Configuration

### Profile Activation

Profiles enable environment-specific configuration.

**Activation methods:**

```bash
# Command line
java -jar app.jar --spring.profiles.active=prod

# Environment variable
SPRING_PROFILES_ACTIVE=prod java -jar app.jar

# In application.properties (for default/fallback)
spring.profiles.active=dev
```

### File Organization

```
src/main/resources/
  application.yml             # Always loaded (defaults)
  application-dev.yml         # Loaded when 'dev' profile active
  application-staging.yml     # Loaded when 'staging' profile active
  application-prod.yml        # Loaded when 'prod' profile active
  application-local.yml       # Local development overrides
```

**Loading order (later overrides earlier):**
1. `application.yml` (base)
2. `application-{profile}.yml` (profile-specific)
3. External config locations (outside jar)
4. Environment variables
5. Command-line arguments

### Multi-Document YAML

Combine multiple profiles in single file using `---` separator:

```yaml
# Default configuration
spring:
  application:
    name: order-service

logging:
  level:
    root: INFO

---
# Development profile
spring:
  config:
    activate:
      on-profile: dev

logging:
  level:
    root: DEBUG
    com.example: TRACE

---
# Production profile
spring:
  config:
    activate:
      on-profile: prod

logging:
  level:
    root: WARN
```

### Profile Groups

Combine related profiles:

```yaml
spring:
  profiles:
    group:
      production:
        - prod
        - prod-db
        - prod-security
      development:
        - dev
        - dev-tools
```

Activate with: `--spring.profiles.active=production`

### Environment Variables in Config

Reference environment variables for secrets:

```yaml
app:
  database:
    url: ${DATABASE_URL:jdbc:postgresql://localhost:5432/mydb}
    username: ${DATABASE_USER:localuser}
    password: ${DATABASE_PASSWORD}  # Required - no default
  
  api:
    key: ${API_KEY}
```

---

## Actuator Setup and Health Checks

### Enabling Actuator

Add dependency:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

### Endpoint Configuration

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus,env,configprops
      base-path: /actuator  # Default
  
  endpoint:
    health:
      show-details: when-authorized  # never, when-authorized, always
      show-components: when-authorized
      probes:
        enabled: true  # Enable /actuator/health/liveness and /readiness
    
    env:
      show-values: when-authorized  # Hide sensitive values by default
  
  server:
    port: 8081  # Separate management port (optional)
```

### Available Endpoints

| Endpoint | Description |
|----------|-------------|
| `/health` | Application health status |
| `/health/liveness` | Kubernetes liveness probe |
| `/health/readiness` | Kubernetes readiness probe |
| `/info` | Application information |
| `/metrics` | Application metrics |
| `/prometheus` | Prometheus-format metrics |
| `/env` | Environment properties |
| `/configprops` | Configuration properties |
| `/beans` | All Spring beans |
| `/mappings` | Request mappings |

### Auto-Configured Health Indicators

Spring Boot auto-configures health indicators for:

| Key | Description |
|-----|-------------|
| `db` | Database connectivity |
| `diskspace` | Available disk space |
| `mongo` | MongoDB connectivity |
| `redis` | Redis connectivity |
| `rabbit` | RabbitMQ connectivity |
| `kafka` | Kafka connectivity |
| `mail` | Mail server connectivity |

### Custom Health Indicator

```java
@Component
public class ExternalServiceHealthIndicator implements HealthIndicator {

    private final ExternalServiceClient client;
    private final Duration timeout;

    public ExternalServiceHealthIndicator(
            ExternalServiceClient client,
            @Value("${health.external.timeout:5s}") Duration timeout) {
        this.client = client;
        this.timeout = timeout;
    }

    @Override
    public Health health() {
        long start = System.currentTimeMillis();
        try {
            boolean reachable = client.ping(timeout);
            long latency = System.currentTimeMillis() - start;
            
            if (reachable) {
                return Health.up()
                    .withDetail("latency_ms", latency)
                    .withDetail("service", "external-api")
                    .build();
            } else {
                return Health.down()
                    .withDetail("reason", "ping failed")
                    .build();
            }
        } catch (TimeoutException e) {
            return Health.down()
                .withDetail("reason", "timeout")
                .withDetail("timeout_ms", timeout.toMillis())
                .build();
        } catch (Exception e) {
            return Health.down()
                .withException(e)
                .build();
        }
    }
}
```

### Reactive Health Indicator

For reactive applications (WebFlux):

```java
@Component
public class ReactiveExternalHealthIndicator implements ReactiveHealthIndicator {

    private final WebClient webClient;

    public ReactiveExternalHealthIndicator(WebClient.Builder builder) {
        this.webClient = builder.baseUrl("https://api.example.com").build();
    }

    @Override
    public Mono<Health> health() {
        return webClient.get()
            .uri("/health")
            .retrieve()
            .toBodilessEntity()
            .map(response -> Health.up().build())
            .onErrorResume(ex -> 
                Mono.just(Health.down(ex).build()))
            .timeout(Duration.ofSeconds(5));
    }
}
```

### Health Groups

Create custom health groups for different purposes:

```yaml
management:
  endpoint:
    health:
      group:
        liveness:
          include: ping
        readiness:
          include: db,redis,externalService
        full:
          include: "*"
          show-details: always
```

Access at:
- `/actuator/health/liveness`
- `/actuator/health/readiness`
- `/actuator/health/full`

---

## Service Directory Structure Conventions

### Recommended Package Layout

```
com.example.orderservice/
│
├── OrderServiceApplication.java          # Main class with @SpringBootApplication
│
├── config/                                # Spring configuration classes
│   ├── SecurityConfig.java               # Security configuration
│   ├── WebConfig.java                    # Web MVC configuration
│   ├── AsyncConfig.java                  # Async execution configuration
│   └── CacheConfig.java                  # Caching configuration
│
├── controller/                            # REST API layer
│   ├── OrderController.java              # Order endpoints
│   ├── OrderAdminController.java         # Admin endpoints
│   └── advice/
│       └── GlobalExceptionHandler.java   # @ControllerAdvice
│
├── service/                               # Business logic layer
│   ├── OrderService.java                 # Interface (optional)
│   ├── OrderServiceImpl.java             # Implementation
│   ├── PaymentService.java
│   └── NotificationService.java
│
├── repository/                            # Data access layer
│   ├── OrderRepository.java              # Spring Data repository
│   ├── OrderCustomRepository.java        # Custom query interface
│   └── OrderCustomRepositoryImpl.java    # Custom query implementation
│
├── model/                                 # Domain entities
│   ├── Order.java                        # JPA entity
│   ├── OrderItem.java
│   ├── OrderStatus.java                  # Enum
│   └── event/
│       ├── OrderCreatedEvent.java        # Domain events
│       └── OrderCompletedEvent.java
│
├── dto/                                   # Data transfer objects
│   ├── request/
│   │   ├── CreateOrderRequest.java
│   │   └── UpdateOrderRequest.java
│   └── response/
│       ├── OrderResponse.java
│       └── OrderSummaryResponse.java
│
├── mapper/                                # DTO mappers
│   └── OrderMapper.java                  # MapStruct or manual mapping
│
├── client/                                # External service clients
│   ├── PaymentClient.java                # Payment gateway client
│   ├── InventoryClient.java              # Inventory service client
│   └── config/
│       └── ClientConfig.java             # RestClient/WebClient config
│
├── exception/                             # Custom exceptions
│   ├── OrderNotFoundException.java
│   ├── PaymentFailedException.java
│   └── BusinessException.java            # Base exception
│
├── validation/                            # Custom validators
│   ├── ValidOrderStatus.java             # Custom annotation
│   └── OrderStatusValidator.java         # Validator implementation
│
└── util/                                  # Utility classes
    └── OrderNumberGenerator.java
```

### Package Placement Rules

| Component | Package | Stereotype |
|-----------|---------|------------|
| Main application class | Root package | `@SpringBootApplication` |
| REST controllers | `.controller` | `@RestController` |
| Business services | `.service` | `@Service` |
| Data repositories | `.repository` | `@Repository` |
| JPA entities | `.model` or `.entity` | `@Entity` |
| DTOs | `.dto` | Plain POJOs or records |
| Configuration | `.config` | `@Configuration` |
| Exception handlers | `.controller.advice` | `@ControllerAdvice` |

### Main Application Class Placement

The `@SpringBootApplication` class must be in the root package to enable component scanning of all sub-packages:

```java
package com.example.orderservice;  // ROOT package

@SpringBootApplication
public class OrderServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(OrderServiceApplication.class, args);
    }
}
```

**Why root package?**
- `@SpringBootApplication` includes `@ComponentScan`
- Component scan starts from the package of the annotated class
- All beans in sub-packages are automatically discovered

---

## Common Anti-Patterns to Avoid

### 1. Field Injection
See Constructor Injection section above.

### 2. God Services
**Problem:** Single service with too many responsibilities

```java
// ANTI-PATTERN
@Service
public class OrderService {
    // Handles orders, payments, notifications, inventory, reporting...
    // 50+ methods, 2000+ lines
}
```

**Solution:** Split by responsibility

```java
@Service
public class OrderService { /* Order lifecycle */ }

@Service
public class PaymentService { /* Payment processing */ }

@Service
public class OrderNotificationService { /* Notifications */ }
```

### 3. Hardcoded Configuration

```java
// ANTI-PATTERN
private static final String API_URL = "https://api.prod.example.com";
private static final int TIMEOUT = 30000;
```

**Solution:** Externalize configuration

```java
@ConfigurationProperties("external.api")
public class ApiProperties {
    private String url;
    private Duration timeout = Duration.ofSeconds(30);
    // getters, setters
}
```

### 4. Catching Generic Exceptions

```java
// ANTI-PATTERN
try {
    return client.call();
} catch (Exception e) {
    log.error("Failed", e);
    return null;  // Silent failure!
}
```

**Solution:** Handle specific exceptions, fail appropriately

```java
try {
    return client.call();
} catch (TimeoutException e) {
    throw new ServiceUnavailableException("External service timeout", e);
} catch (ClientException e) {
    throw new BadRequestException("Invalid request to external service", e);
}
```

### 5. Ignoring Bean Scopes

```java
// ANTI-PATTERN - mutable state in singleton
@Service
public class CounterService {
    private int count = 0;  // Shared across all threads!
    
    public void increment() {
        count++;  // Race condition!
    }
}
```

**Solution:** Use thread-safe constructs or appropriate scope

```java
@Service
public class CounterService {
    private final AtomicInteger count = new AtomicInteger(0);
    
    public void increment() {
        count.incrementAndGet();
    }
}
```

### 6. Circular Dependencies

```java
// ANTI-PATTERN
@Service
public class ServiceA {
    @Autowired private ServiceB serviceB;
}

@Service
public class ServiceB {
    @Autowired private ServiceA serviceA;  // Circular!
}
```

**Solutions:**
1. Refactor to eliminate cycle (extract common logic)
2. Use `@Lazy` on one dependency (temporary fix)
3. Use setter injection with `@Lazy`

```java
@Service
public class ServiceA {
    private final ServiceB serviceB;
    
    public ServiceA(@Lazy ServiceB serviceB) {
        this.serviceB = serviceB;
    }
}
```

---

## Testing Considerations

### Testing @ConfigurationProperties

```java
@SpringBootTest
@TestPropertySource(properties = {
    "app.service.timeout=5s",
    "app.service.max-retries=2"
})
class ServicePropertiesTest {

    @Autowired
    private ServiceProperties properties;

    @Test
    void shouldBindProperties() {
        assertThat(properties.getTimeout()).isEqualTo(Duration.ofSeconds(5));
        assertThat(properties.getMaxRetries()).isEqualTo(2);
    }
}
```

### Testing Health Indicators

```java
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class HealthEndpointTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void healthEndpointShouldReturnUp() {
        ResponseEntity<String> response = restTemplate
            .getForEntity("/actuator/health", String.class);
        
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).contains("\"status\":\"UP\"");
    }
}
```

---

## Summary of Key Recommendations

1. **Always use constructor injection** for mandatory dependencies
2. **Validate configuration** with `@ConfigurationProperties` + `@Validated`
3. **Externalize all configuration** - no hardcoded values
4. **Use profiles** for environment-specific settings
5. **Expose health endpoints** appropriately for your deployment
6. **Structure packages** following Spring conventions
7. **Place main class in root package** for proper component scanning
8. **Use Context7 MCP** to query latest Spring Boot documentation when implementing
