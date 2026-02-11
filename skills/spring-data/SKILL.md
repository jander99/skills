---
name: spring-data
description: Create, design, build, optimize, and debug Spring Data JPA entities, repositories, queries, projections, and transactions. Detect and fix N+1 queries, configure auditing, write JPQL and native SQL. Use when implementing data access layers, fixing performance issues, or building repository patterns.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: backend-development
---

# Spring Data JPA Skill

## What I Do

- Design JPA entities with proper ID strategies, relationships, and mapping
- Create repositories with derived query methods and @Query annotations
- Detect and fix N+1 query problems using JOIN FETCH and @EntityGraph
- Implement projections (interface-based, DTO) for performance
- Configure @Transactional and entity auditing

## When to Use Me

Use this skill when you:
- Create JPA entities with @Entity, @Id, @GeneratedValue
- Build Spring Data repository interfaces
- Write or debug @Query methods (JPQL or native SQL)
- Fix N+1 query performance problems
- Configure @Transactional or auditing

## Entity Design

```java
@Entity
@Table(name = "orders")
public class Order extends AuditableEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    // LAZY for @ManyToOne (default is EAGER!)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private Customer customer;
    
    // LAZY is default for collections
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL)
    private List<OrderItem> items = new ArrayList<>();
}

// Auditable base class
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class AuditableEntity {
    @CreatedDate @Column(updatable = false)
    private Instant createdAt;
    @LastModifiedDate
    private Instant updatedAt;
}
```

## Repository Patterns

```java
public interface UserRepository extends JpaRepository<User, Long> {
    // Derived queries
    Optional<User> findByEmail(String email);
    List<User> findByLastnameAndActiveTrue(String lastname);
    boolean existsByEmail(String email);
    
    // @Query for complex cases
    @Query("SELECT u FROM User u WHERE u.role = :role AND u.active = true")
    List<User> findActiveByRole(@Param("role") Role role);
    
    // Modifying queries
    @Modifying @Transactional
    @Query("UPDATE User u SET u.active = false WHERE u.lastLogin < :date")
    int deactivateOldUsers(@Param("date") LocalDateTime date);
}
```

## N+1 Query Detection and Prevention

**The #1 performance killer in JPA.** Occurs when accessing lazy collections triggers N additional queries.

```java
// PROBLEM: N+1 queries
List<Order> orders = orderRepository.findAll();
orders.forEach(o -> o.getCustomer().getName()); // N extra queries!

// SOLUTION 1: JOIN FETCH
@Query("SELECT o FROM Order o JOIN FETCH o.customer WHERE o.status = :status")
List<Order> findWithCustomer(@Param("status") OrderStatus status);

// SOLUTION 2: @EntityGraph
@EntityGraph(attributePaths = {"customer", "items"})
List<Order> findByStatus(OrderStatus status);

// SOLUTION 3: Batch fetching (application.properties)
spring.jpa.properties.hibernate.default_batch_fetch_size=25
```

## Projections for Performance

```java
// Interface projection - loads only selected columns
public interface UserSummary {
    String getFirstname();
    String getLastname();
}

List<UserSummary> findByActiveTrue();  // Efficient!

// DTO projection
public record UserDto(String firstname, String lastname) {}

@Query("SELECT new com.example.UserDto(u.firstname, u.lastname) FROM User u")
List<UserDto> findAllDtos();
```

## Transaction Management

```java
@Service
public class OrderService {
    @Transactional(readOnly = true)  // Optimized for queries
    public List<Order> findOrders() { ... }
    
    @Transactional  // Default for writes
    public Order createOrder(CreateOrderRequest req) { ... }
    
    @Transactional(rollbackFor = BusinessException.class)
    public void processOrder(Long id) { ... }
}
```

## Context7 Integration

For up-to-date Spring Data JPA documentation:
```
1. context7_resolve-library-id("Spring Data JPA")
2. context7_query-docs(libraryId, "EntityGraph best practices")
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| LazyInitializationException | Accessing lazy collection outside session | Use JOIN FETCH, @EntityGraph, or DTO |
| MultipleBagFetchException | Fetching multiple Lists | Use Set instead of List |
| N+1 queries | Lazy loading in loop | JOIN FETCH or @EntityGraph |
| Slow queries | Missing indexes, full entity loads | Add indexes, use projections |

## High-Impact Gotchas

### JOIN FETCH with Pagination
```java
// BAD: Silently loads all data in memory
@Query("SELECT o FROM Order o JOIN FETCH o.items")
Page<Order> findAllWithItems(Pageable pageable);  // Warning in logs!

// GOOD: Use DTO projection for paged reads
@Query("SELECT new OrderSummaryDto(o.id, o.status, SIZE(o.items)) FROM Order o")
Page<OrderSummaryDto> findAllSummaries(Pageable pageable);
```

### Optimistic Locking
```java
@Entity
public class Order {
    @Version
    private Long version;  // Automatic optimistic locking
}
// Throws OptimisticLockingFailureException on concurrent modification
```

### Entity equals/hashCode
```java
// BAD: Using @Data or including lazy relations
@Data  // Generates equals/hashCode using all fields including lazy collections!

// GOOD: Use business key or ID-based with null safety
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Order other)) return false;
    return id != null && id.equals(other.getId());
}

@Override
public int hashCode() {
    return getClass().hashCode();  // Consistent for new/persisted entities
}
```

### ID Strategy for PostgreSQL
```java
// Prefer SEQUENCE for batch insert performance
@Id
@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "order_seq")
@SequenceGenerator(name = "order_seq", sequenceName = "order_id_seq", allocationSize = 50)
private Long id;
```

## Quick Reference

| Task | Pattern |
|------|---------|
| Find by property | `findByName(value)` |
| Multiple conditions | `findByNameAndActive(name, true)` |
| Exists check | `existsByEmail(email)` |
| Top N results | `findTop10ByOrderByCreatedAtDesc()` |
| Eager fetch | `@EntityGraph(attributePaths = {"rel"})` |
| Pagination | `Page<T> findBy...(Pageable pageable)` |

## Related Skills

| Skill | Use When |
|-------|----------|
| [spring-boot-core](../spring-boot-core/SKILL.md) | Application configuration |
| [spring-testing](../spring-testing/SKILL.md) | Testing with @DataJpaTest |

## References

| Reference | Content |
|-----------|---------|
| [research.md](references/research.md) | Comprehensive patterns and examples |
