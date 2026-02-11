# Spring Security Research Notes

> Research findings for Spring Security best practices, patterns, and implementation guidance.

## SecurityFilterChain Configuration (Modern Style)

### Key Change from Legacy
- **Deprecated**: `WebSecurityConfigurerAdapter` (removed in Spring Security 6.0)
- **Current**: Component-based `SecurityFilterChain` beans

### Modern Configuration Pattern

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf
                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
                .csrfTokenRequestHandler(new CsrfTokenRequestAttributeHandler()))
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/**").authenticated()
                .anyRequest().denyAll())
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .build();
    }
}
```

### Lambda DSL
- Spring Security 6.x requires lambda DSL
- Each configuration method takes a `Customizer<T>` functional interface
- Use `Customizer.withDefaults()` for default behavior

### Multiple Filter Chains
```java
@Bean
@Order(1)
public SecurityFilterChain apiFilterChain(HttpSecurity http) throws Exception {
    return http
        .securityMatcher("/api/**")
        .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
        .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
        .build();
}

@Bean
@Order(2)
public SecurityFilterChain webFilterChain(HttpSecurity http) throws Exception {
    return http
        .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
        .formLogin(Customizer.withDefaults())
        .build();
}
```

---

## JWT Validation and Generation

### JWT Decoder Configuration

```java
@Bean
public JwtDecoder jwtDecoder() {
    NimbusJwtDecoder decoder = NimbusJwtDecoder
        .withPublicKey(rsaPublicKey)
        .build();
    
    // Add custom validators
    OAuth2TokenValidator<Jwt> audienceValidator = new AudienceValidator("my-api");
    OAuth2TokenValidator<Jwt> withIssuer = JwtValidators.createDefaultWithIssuer(issuerUri);
    OAuth2TokenValidator<Jwt> combined = new DelegatingOAuth2TokenValidator<>(
        withIssuer, audienceValidator);
    
    decoder.setJwtValidator(combined);
    return decoder;
}
```

### Custom Audience Validator

```java
public class AudienceValidator implements OAuth2TokenValidator<Jwt> {
    private final String audience;
    
    public AudienceValidator(String audience) {
        this.audience = audience;
    }
    
    @Override
    public OAuth2TokenValidatorResult validate(Jwt jwt) {
        if (jwt.getAudience().contains(audience)) {
            return OAuth2TokenValidatorResult.success();
        }
        OAuth2Error error = new OAuth2Error("invalid_token", 
            "The required audience is missing", null);
        return OAuth2TokenValidatorResult.failure(error);
    }
}
```

### JWT Generation (for Auth Servers)

```java
@Component
public class JwtTokenProvider {
    private final JWSSigner signer;
    private final Duration tokenValidity = Duration.ofHours(1);
    
    public String generateToken(Authentication auth) {
        Instant now = Instant.now();
        
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
            .subject(auth.getName())
            .issuer("https://myapp.example.com")
            .audience("my-api")
            .issueTime(Date.from(now))
            .expirationTime(Date.from(now.plus(tokenValidity)))
            .claim("roles", extractRoles(auth))
            .jwtID(UUID.randomUUID().toString())
            .build();
        
        SignedJWT signedJWT = new SignedJWT(
            new JWSHeader.Builder(JWSAlgorithm.RS256).build(),
            claims);
        signedJWT.sign(signer);
        
        return signedJWT.serialize();
    }
}
```

### Token Format Best Practices

1. **Always include**:
   - `sub` (subject) - user identifier
   - `iss` (issuer) - token issuer URI
   - `aud` (audience) - intended recipient
   - `exp` (expiration) - token expiry
   - `iat` (issued at) - creation time
   - `jti` (JWT ID) - unique token identifier (for revocation)

2. **Access tokens should be short-lived** (15 min - 1 hour)
3. **Refresh tokens should be long-lived** (days/weeks) and stored securely
4. **Never store sensitive data in JWT payload** (it's only base64 encoded)

---

## OAuth2 Resource Server Setup

### Application Properties

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://auth.example.com
          # OR specify JWK Set URI directly
          jwk-set-uri: https://auth.example.com/.well-known/jwks.json
```

### Extracting Authorities from JWT

```java
@Bean
public JwtAuthenticationConverter jwtAuthenticationConverter() {
    JwtGrantedAuthoritiesConverter grantedAuthoritiesConverter = 
        new JwtGrantedAuthoritiesConverter();
    grantedAuthoritiesConverter.setAuthoritiesClaimName("roles");
    grantedAuthoritiesConverter.setAuthorityPrefix("ROLE_");
    
    JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
    converter.setJwtGrantedAuthoritiesConverter(grantedAuthoritiesConverter);
    return converter;
}

@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
        .oauth2ResourceServer(oauth2 -> oauth2
            .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter())))
        .build();
}
```

### Custom Principal Extraction

```java
@Bean
public JwtAuthenticationConverter jwtAuthenticationConverter() {
    JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
    converter.setPrincipalClaimName("preferred_username"); // Use username instead of sub
    return converter;
}
```

### Opaque Token Support

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
        .oauth2ResourceServer(oauth2 -> oauth2
            .opaqueToken(opaque -> opaque
                .introspectionUri("https://auth.example.com/introspect")
                .introspectionClientCredentials("client-id", "client-secret")))
        .build();
}
```

---

## Method-Level Security

### Enable Method Security

```java
@Configuration
@EnableMethodSecurity  // replaces @EnableGlobalMethodSecurity
public class MethodSecurityConfig {
    // Configuration if needed
}
```

### @PreAuthorize Patterns

```java
@Service
public class OrderService {

    // Simple role check
    @PreAuthorize("hasRole('ADMIN')")
    public void deleteOrder(Long orderId) { }

    // Multiple roles
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public void approveOrder(Long orderId) { }

    // Permission check
    @PreAuthorize("hasAuthority('order:write')")
    public void updateOrder(Order order) { }

    // SpEL with method parameters
    @PreAuthorize("#order.createdBy == authentication.name")
    public void updateOwnOrder(Order order) { }

    // Custom security expression
    @PreAuthorize("@orderSecurityService.canAccess(#orderId, authentication)")
    public Order getOrder(Long orderId) { }

    // Combining expressions
    @PreAuthorize("hasRole('USER') and #userId == authentication.principal.id")
    public UserProfile getProfile(Long userId) { }
}
```

### @PostAuthorize for Return Value Filtering

```java
@PostAuthorize("returnObject.owner == authentication.name")
public Document getDocument(Long documentId) {
    return documentRepository.findById(documentId).orElseThrow();
}

@PostFilter("filterObject.department == authentication.principal.department")
public List<Employee> getAllEmployees() {
    return employeeRepository.findAll();
}
```

### @Secured (Simpler Alternative)

```java
@Secured("ROLE_ADMIN")
public void adminOnlyMethod() { }

@Secured({"ROLE_ADMIN", "ROLE_MANAGER"})
public void managerOrAdmin() { }
```

### Custom Permission Evaluator

```java
@Component
public class CustomPermissionEvaluator implements PermissionEvaluator {

    @Override
    public boolean hasPermission(Authentication auth, Object target, Object permission) {
        if (target instanceof Document doc) {
            return evaluateDocumentPermission(auth, doc, (String) permission);
        }
        return false;
    }

    @Override
    public boolean hasPermission(Authentication auth, Serializable targetId, 
                                  String targetType, Object permission) {
        // Load and check by ID
        return false;
    }
}
```

Usage:
```java
@PreAuthorize("hasPermission(#document, 'write')")
public void updateDocument(Document document) { }
```

---

## CORS Configuration

### Global CORS Configuration

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(List.of("https://frontend.example.com"));
    configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
    configuration.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
    configuration.setExposedHeaders(List.of("X-Total-Count", "X-Page-Number"));
    configuration.setAllowCredentials(true);
    configuration.setMaxAge(3600L);
    
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", configuration);
    return source;
}

@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
        .cors(cors -> cors.configurationSource(corsConfigurationSource()))
        // ... other config
        .build();
}
```

### Pattern-Based CORS

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    
    // Public API - permissive
    CorsConfiguration publicConfig = new CorsConfiguration();
    publicConfig.setAllowedOrigins(List.of("*"));
    publicConfig.setAllowedMethods(List.of("GET"));
    source.registerCorsConfiguration("/api/public/**", publicConfig);
    
    // Protected API - strict
    CorsConfiguration protectedConfig = new CorsConfiguration();
    protectedConfig.setAllowedOrigins(List.of("https://app.example.com"));
    protectedConfig.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    protectedConfig.setAllowCredentials(true);
    source.registerCorsConfiguration("/api/**", protectedConfig);
    
    return source;
}
```

### Controller-Level CORS

```java
@RestController
@CrossOrigin(origins = "https://frontend.example.com", maxAge = 3600)
public class ApiController {

    @CrossOrigin(origins = "*") // Override class-level for this method
    @GetMapping("/public/health")
    public String health() {
        return "OK";
    }
}
```

---

## Security Testing Patterns

### Test Configuration

```java
@TestConfiguration
@EnableWebSecurity
public class TestSecurityConfig {

    @Bean
    public SecurityFilterChain testFilterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
            .build();
    }
}
```

### MockMvc with Security

```java
@WebMvcTest(OrderController.class)
@Import(SecurityConfig.class)
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminCanDeleteOrder() throws Exception {
        mockMvc.perform(delete("/api/orders/1"))
            .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(roles = "USER")
    void userCannotDeleteOrder() throws Exception {
        mockMvc.perform(delete("/api/orders/1"))
            .andExpect(status().isForbidden());
    }

    @Test
    void anonymousCannotAccess() throws Exception {
        mockMvc.perform(get("/api/orders"))
            .andExpect(status().isUnauthorized());
    }
}
```

### JWT Testing

```java
@Test
void testWithJwt() throws Exception {
    mockMvc.perform(get("/api/orders")
            .with(jwt()
                .jwt(jwt -> jwt
                    .claim("sub", "user123")
                    .claim("roles", List.of("ROLE_USER")))
                .authorities(new SimpleGrantedAuthority("ROLE_USER"))))
        .andExpect(status().isOk());
}
```

### Custom Authentication for Tests

```java
@Test
@WithUserDetails(value = "admin@example.com", userDetailsServiceBeanName = "testUserService")
void testWithCustomUser() throws Exception {
    // Test with user loaded from testUserService
}
```

### Security Context Setup

```java
@BeforeEach
void setupSecurityContext() {
    SecurityContext context = SecurityContextHolder.createEmptyContext();
    context.setAuthentication(new UsernamePasswordAuthenticationToken(
        "testuser", "password", 
        List.of(new SimpleGrantedAuthority("ROLE_USER"))));
    SecurityContextHolder.setContext(context);
}

@AfterEach
void clearSecurityContext() {
    SecurityContextHolder.clearContext();
}
```

---

## Common Vulnerabilities and Mitigations

### 1. CSRF Attacks

**Problem**: Cross-Site Request Forgery allows attackers to execute actions on behalf of authenticated users.

**Mitigation**:
```java
// For traditional web apps - enable CSRF
.csrf(csrf -> csrf
    .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
    .csrfTokenRequestHandler(new CsrfTokenRequestAttributeHandler()))

// For stateless APIs with JWT - can disable
.csrf(csrf -> csrf.disable())
```

**Note**: Only disable CSRF for truly stateless APIs using bearer tokens.

### 2. Broken Authentication

**Problem**: Weak session management, token storage, or credential handling.

**Mitigations**:
- Use short-lived access tokens (15 min - 1 hour)
- Implement token refresh with rotation
- Store refresh tokens securely (httpOnly cookies or secure storage)
- Validate all token claims (iss, aud, exp, etc.)

### 3. Insecure Direct Object References (IDOR)

**Problem**: Users accessing resources they shouldn't by manipulating IDs.

**Mitigation**:
```java
@PreAuthorize("@orderService.belongsToUser(#orderId, authentication.name)")
public Order getOrder(Long orderId) { }

// Or in service layer
public Order getOrder(Long orderId, Authentication auth) {
    Order order = orderRepository.findById(orderId).orElseThrow();
    if (!order.getOwner().equals(auth.getName())) {
        throw new AccessDeniedException("Not authorized");
    }
    return order;
}
```

### 4. Mass Assignment

**Problem**: Attackers setting fields they shouldn't (like `role` or `isAdmin`).

**Mitigation**: Use DTOs with explicit field mapping:
```java
public record CreateUserRequest(String username, String email) {
    // No role or admin fields exposed
}
```

### 5. JWT Algorithm Confusion

**Problem**: Accepting "none" algorithm or allowing algorithm switching.

**Mitigation**:
```java
@Bean
public JwtDecoder jwtDecoder() {
    // Explicitly specify algorithm - never trust alg header alone
    return NimbusJwtDecoder.withPublicKey(rsaPublicKey).build();
}
```

### 6. Information Disclosure

**Problem**: Leaking stack traces, internal errors, or user existence.

**Mitigation**:
```java
@ControllerAdvice
public class SecurityExceptionHandler {

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied() {
        return ResponseEntity.status(403)
            .body(new ErrorResponse("Access denied")); // Generic message
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ErrorResponse> handleAuthError() {
        return ResponseEntity.status(401)
            .body(new ErrorResponse("Authentication failed")); // Don't reveal why
    }
}
```

### 7. Missing Rate Limiting

**Problem**: Brute force attacks on authentication endpoints.

**Mitigation**: Add rate limiting (e.g., Bucket4j, Resilience4j):
```java
@Bean
public FilterRegistrationBean<RateLimitFilter> rateLimitFilter() {
    FilterRegistrationBean<RateLimitFilter> registration = new FilterRegistrationBean<>();
    registration.setFilter(new RateLimitFilter());
    registration.addUrlPatterns("/api/auth/*");
    return registration;
}
```

### 8. Insufficient Logging

**Problem**: Can't detect or investigate security incidents.

**Mitigation**:
```java
@EventListener
public void onAuthenticationSuccess(AuthenticationSuccessEvent event) {
    log.info("Successful login: user={}, ip={}", 
        event.getAuthentication().getName(),
        getClientIp());
}

@EventListener
public void onAuthenticationFailure(AuthenticationFailureBadCredentialsEvent event) {
    log.warn("Failed login attempt: user={}, ip={}", 
        event.getAuthentication().getName(),
        getClientIp());
}
```

---

## Role Naming Conventions

### Standard Patterns

1. **ROLE_ Prefix**: Spring Security expects `ROLE_` prefix by default
   - `ROLE_ADMIN`, `ROLE_USER`, `ROLE_MANAGER`
   - `hasRole("ADMIN")` checks for `ROLE_ADMIN`
   - `hasAuthority("ROLE_ADMIN")` checks exactly

2. **Permission-Based (Fine-Grained)**:
   - `user:read`, `user:write`, `user:delete`
   - `order:create`, `order:approve`, `order:cancel`
   - Use with `hasAuthority("user:read")`

3. **Hierarchical Roles**:
```java
@Bean
public RoleHierarchy roleHierarchy() {
    return RoleHierarchyImpl.withDefaultRolePrefix()
        .role("ADMIN").implies("MANAGER")
        .role("MANAGER").implies("USER")
        .role("USER").implies("GUEST")
        .build();
}
```

### JWT Claim Structure for Roles

```json
{
  "sub": "user123",
  "roles": ["ROLE_USER", "ROLE_MANAGER"],
  "permissions": ["order:read", "order:write"],
  "iss": "https://auth.example.com",
  "aud": "my-api",
  "exp": 1735689600,
  "iat": 1735686000
}
```

---

## Additional Best Practices

### Password Encoding

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    // Uses bcrypt by default, supports migration from other encoders
}
```

### Security Headers

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
        .headers(headers -> headers
            .contentSecurityPolicy(csp -> csp
                .policyDirectives("default-src 'self'; script-src 'self'"))
            .frameOptions(frame -> frame.deny())
            .xssProtection(xss -> xss.disable()) // Modern browsers don't need it
            .contentTypeOptions(Customizer.withDefaults()))
        .build();
}
```

### Secure Defaults

1. **Deny by default**: End with `.anyRequest().denyAll()`
2. **Explicit permits**: Only allow what's needed
3. **Stateless for APIs**: Use `SessionCreationPolicy.STATELESS`
4. **Validate all inputs**: Even with authentication

### Environment-Specific Configuration

```java
@Bean
@Profile("!production")
public SecurityFilterChain devFilterChain(HttpSecurity http) throws Exception {
    return http
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/h2-console/**").permitAll()
            .anyRequest().authenticated())
        .headers(headers -> headers.frameOptions(frame -> frame.disable()))
        .csrf(csrf -> csrf.disable())
        .build();
}
```

---

## References

- Spring Security Reference Documentation
- OWASP Authentication Cheat Sheet
- OWASP JWT Security Cheat Sheet
- RFC 7519 (JWT)
- RFC 6749 (OAuth 2.0)
