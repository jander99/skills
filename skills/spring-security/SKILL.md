---
name: spring-security
description: Configure, implement, secure, validate, and audit Spring Security with SecurityFilterChain, JWT validation, OAuth2 resource server, method security, and CORS. Use when adding authentication, authorization, or protecting REST APIs.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: security
---

# Spring Security Skill

## What I Do

- Configure `SecurityFilterChain` using modern lambda DSL (Spring Security 6.x)
- Implement JWT validation with custom claims and audience checking
- Set up OAuth2 resource server with JWK endpoints
- Apply method-level security with `@PreAuthorize` and `@Secured`
- Configure CORS policies for API and web applications
- Audit security configurations for vulnerabilities
- Write security integration tests with `@WithMockUser` and JWT mocking

## When to Use Me

Use this skill when you:
- Create, configure, or update `SecurityFilterChain` beans
- Implement JWT authentication or OAuth2 resource server
- Add method-level authorization with `@PreAuthorize`
- Configure CORS for cross-origin API access
- Migrate from deprecated `WebSecurityConfigurerAdapter`
- Audit, review, or fix security configurations

## Security Configuration

### Modern SecurityFilterChain Pattern

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable()) // Only for stateless JWT APIs
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/**").authenticated()
                .anyRequest().denyAll()) // Deny by default
            .oauth2ResourceServer(oauth2 -> oauth2
                    .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter())))
            .build();
    }
}
```

## JWT Patterns

### JWT Decoder with Validation

```java
@Bean
public JwtDecoder jwtDecoder(@Value("${jwt.public-key}") RSAPublicKey key) {
    NimbusJwtDecoder decoder = NimbusJwtDecoder.withPublicKey(key).build();
    
    OAuth2TokenValidator<Jwt> audienceValidator = new AudienceValidator("my-api");
    OAuth2TokenValidator<Jwt> withIssuer = JwtValidators
        .createDefaultWithIssuer("https://auth.example.com");
    
    decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
        withIssuer, audienceValidator));
    return decoder;
}
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
```

## OAuth2 Setup

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://auth.example.com
          jwk-set-uri: https://auth.example.com/.well-known/jwks.json
```

> **Note:** Use `issuer-uri` OR `jwk-set-uri`, not both. `issuer-uri` is preferred as it auto-discovers the JWK endpoint from `.well-known/openid-configuration`.

## Method Security

```java
@Configuration
@EnableMethodSecurity  // Replaces @EnableGlobalMethodSecurity
public class MethodSecurityConfig { }

@Service
public class OrderService {
    @PreAuthorize("hasRole('ADMIN')")
    public void deleteOrder(Long id) { }

    @PreAuthorize("#order.createdBy == authentication.name")
    public void updateOwnOrder(Order order) { }

    @PreAuthorize("@securityService.canAccess(#id, authentication)")
    public Order getOrder(Long id) { }
}
```

## CORS Configuration

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("https://frontend.example.com"));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
    config.setAllowCredentials(true);
    
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}
```

## Context7 Integration

For current Spring Security documentation, use Context7 MCP server:

1. `context7_resolve-library-id` with libraryName: "Spring Security"
2. `context7_query-docs` with the resolved ID

Recommended queries: "SecurityFilterChain lambda DSL", "OAuth2 JWT validation", "@PreAuthorize SpEL"

## Common Vulnerabilities

| Vulnerability | Prevention |
|--------------|------------|
| CSRF | Disable only for stateless JWT APIs; use `CookieCsrfTokenRepository` for sessions |
| IDOR | `@PreAuthorize("@service.belongsToUser(#id, authentication)")` |
| JWT Algorithm Confusion | Use `NimbusJwtDecoder.withPublicKey()` - never trust `alg` header |
| Missing Deny Default | Always end with `.anyRequest().denyAll()` |
| Info Disclosure | Return generic error messages for auth failures |

## Security Testing

```java
@WebMvcTest(OrderController.class)
@Import(SecurityConfig.class)
class OrderControllerTest {
    @Test
    @WithMockUser(roles = "ADMIN")
    void adminCanDelete() throws Exception {
        mockMvc.perform(delete("/api/orders/1")).andExpect(status().isOk());
    }

    @Test
    void testWithJwt() throws Exception {
        mockMvc.perform(get("/api/orders")
                .with(jwt().jwt(j -> j.claim("roles", List.of("USER")))))
            .andExpect(status().isOk());
    }
}
```

## Related Skills

| Skill | Use For |
|-------|---------|
| `spring-boot-core` | Application configuration and DI |
| `spring-testing` | Comprehensive test strategies |

## References

See `references/research.md` for complete examples on JWT generation, role hierarchy, password encoding, and security headers.
