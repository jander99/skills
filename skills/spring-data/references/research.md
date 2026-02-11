# Spring Data JPA Best Practices Research

Research findings for building Spring Data JPA repositories, entities, and queries.
Data layer mistakes cause production incidents - performance is critical.

## Entity Design and Mapping

### ID Strategy Patterns

```java
// Recommended: Use @GeneratedValue with IDENTITY or SEQUENCE
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
}

// For UUID-based IDs
@Entity
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
}

// SEQUENCE for high-volume inserts (better batch performance)
@Entity
public class Transaction {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "txn_seq")
    @SequenceGenerator(name = "txn_seq", sequenceName = "transaction_seq", allocationSize = 50)
    private Long id;
}
```

### Entity Naming Conventions

```java
// Entity class: PascalCase, singular noun
@Entity
@Table(name = "users")  // Table: snake_case, plural
public class User {
    
    @Column(name = "first_name")  // Column: snake_case
    private String firstName;    // Field: camelCase
    
    @Column(name = "email_address", nullable = false, unique = true)
    private String emailAddress;
}
```

### Relationship Mapping Best Practices

```java
@Entity
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    // LAZY is the default and recommended for @OneToMany and @ManyToMany
    @OneToMany(mappedBy = "order", fetch = FetchType.LAZY)
    private List<OrderItem> items = new ArrayList<>();
    
    // EAGER only for small, always-needed associations
    @ManyToOne(fetch = FetchType.LAZY)  // Override EAGER default!
    @JoinColumn(name = "customer_id")
    private Customer customer;
}
```

### Equals and HashCode

```java
@Entity
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    // Use business key or ID for equals/hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Product)) return false;
        Product product = (Product) o;
        return id != null && id.equals(product.id);
    }
    
    @Override
    public int hashCode() {
        return getClass().hashCode();  // Constant hashCode for JPA entities
    }
}
```

## Repository Method Naming Conventions

### Query Derivation Keywords

| Keyword | Sample | JPQL Equivalent |
|---------|--------|-----------------|
| `And` | `findByLastnameAndFirstname` | `where x.lastname = ?1 and x.firstname = ?2` |
| `Or` | `findByLastnameOrFirstname` | `where x.lastname = ?1 or x.firstname = ?2` |
| `Is`, `Equals` | `findByFirstname`, `findByFirstnameIs` | `where x.firstname = ?1` |
| `Between` | `findByStartDateBetween` | `where x.startDate between ?1 and ?2` |
| `LessThan` | `findByAgeLessThan` | `where x.age < ?1` |
| `GreaterThan` | `findByAgeGreaterThan` | `where x.age > ?1` |
| `IsNull` | `findByAgeIsNull` | `where x.age is null` |
| `IsNotNull` | `findByAgeIsNotNull` | `where x.age is not null` |
| `Like` | `findByFirstnameLike` | `where x.firstname like ?1` |
| `StartingWith` | `findByFirstnameStartingWith` | `where x.firstname like ?1%` |
| `EndingWith` | `findByFirstnameEndingWith` | `where x.firstname like %?1` |
| `Containing` | `findByFirstnameContaining` | `where x.firstname like %?1%` |
| `OrderBy` | `findByAgeOrderByLastnameDesc` | `where x.age = ?1 order by x.lastname desc` |
| `In` | `findByAgeIn(Collection ages)` | `where x.age in ?1` |
| `True` | `findByActiveTrue()` | `where x.active = true` |
| `IgnoreCase` | `findByFirstnameIgnoreCase` | `where UPPER(x.firstname) = UPPER(?1)` |

### Repository Method Examples

```java
public interface UserRepository extends JpaRepository<User, Long> {
    
    // Simple property queries
    List<User> findByLastname(String lastname);
    Optional<User> findByEmail(String email);
    
    // Multiple conditions
    List<User> findByFirstnameAndLastname(String firstname, String lastname);
    List<User> findByFirstnameOrLastname(String firstname, String lastname);
    
    // Limiting results
    User findFirstByOrderByLastnameAsc();
    List<User> findTop10ByLastname(String lastname, Sort sort);
    
    // Counting and existence
    long countByLastname(String lastname);
    boolean existsByEmail(String email);
    
    // Delete operations
    void deleteByLastname(String lastname);
    long deleteByActiveIsFalse();
    
    // Distinct
    List<User> findDistinctByLastname(String lastname);
}
```

## @Query for Complex Queries

### JPQL Queries

```java
public interface UserRepository extends JpaRepository<User, Long> {
    
    // Positional parameters
    @Query("select u from User u where u.emailAddress = ?1")
    User findByEmailAddress(String email);
    
    // Named parameters (preferred)
    @Query("select u from User u where u.firstname = :firstname or u.lastname = :lastname")
    List<User> findByFirstnameOrLastname(
        @Param("firstname") String firstname,
        @Param("lastname") String lastname
    );
    
    // Like expressions
    @Query("select u from User u where u.firstname like %:name%")
    List<User> findByNameContaining(@Param("name") String name);
    
    // Modifying queries (UPDATE/DELETE)
    @Modifying
    @Query("update User u set u.active = false where u.lastLogin < :date")
    int deactivateInactiveUsers(@Param("date") LocalDateTime date);
    
    @Modifying
    @Query("delete from User u where u.active = false")
    void deleteInactiveUsers();
}
```

### Native SQL Queries

```java
public interface UserRepository extends JpaRepository<User, Long> {
    
    @NativeQuery("SELECT * FROM users WHERE email = ?1")
    User findByEmailNative(String email);
    
    // With pagination
    @NativeQuery(
        value = "SELECT * FROM users WHERE lastname = ?1",
        countQuery = "SELECT count(*) FROM users WHERE lastname = ?1"
    )
    Page<User> findByLastnameNative(String lastname, Pageable pageable);
    
    // Returning raw results
    @NativeQuery("SELECT * FROM users WHERE email = ?1")
    Map<String, Object> findRawByEmail(String email);
}
```

## Projection Patterns for Performance

### Interface-Based Projections (Closed)

```java
// Closed projection - only selected fields loaded
public interface UserSummary {
    String getFirstname();
    String getLastname();
    String getEmail();
}

public interface UserRepository extends JpaRepository<User, Long> {
    List<UserSummary> findByLastname(String lastname);
    
    // Dynamic projection
    <T> List<T> findByLastname(String lastname, Class<T> type);
}

// Usage
List<UserSummary> summaries = userRepository.findByLastname("Smith");
List<UserFullDto> dtos = userRepository.findByLastname("Smith", UserFullDto.class);
```

### Class-Based Projections (DTOs)

```java
// Using Java Record (preferred)
public record UserDto(String firstname, String lastname, String email) {}

// JPQL with constructor expression
@Query("select new com.example.UserDto(u.firstname, u.lastname, u.email) from User u where u.active = true")
List<UserDto> findActiveUserDtos();

// Spring Data can auto-rewrite simple queries
@Query("select u from User u where u.lastname = :lastname")
List<UserDto> findDtosByLastname(@Param("lastname") String lastname);
```

### Nested Projections

```java
public interface OrderSummary {
    Long getId();
    LocalDateTime getOrderDate();
    CustomerSummary getCustomer();
    
    interface CustomerSummary {
        String getName();
        String getEmail();
    }
}
```

## N+1 Query Detection and Prevention

### The N+1 Problem

```java
// BAD: N+1 queries - 1 query for orders, N queries for customers
List<Order> orders = orderRepository.findAll();
for (Order order : orders) {
    System.out.println(order.getCustomer().getName()); // Triggers lazy load!
}
```

### Solution 1: JOIN FETCH

```java
public interface OrderRepository extends JpaRepository<Order, Long> {
    
    // Fetch customer in single query
    @Query("SELECT o FROM Order o JOIN FETCH o.customer WHERE o.status = :status")
    List<Order> findByStatusWithCustomer(@Param("status") OrderStatus status);
    
    // Multiple joins
    @Query("SELECT o FROM Order o " +
           "JOIN FETCH o.customer c " +
           "JOIN FETCH o.items i " +
           "WHERE o.id = :id")
    Optional<Order> findByIdWithCustomerAndItems(@Param("id") Long id);
}
```

### Solution 2: @EntityGraph

```java
// Define named entity graph on entity
@Entity
@NamedEntityGraph(
    name = "Order.withCustomerAndItems",
    attributeNodes = {
        @NamedAttributeNode("customer"),
        @NamedAttributeNode("items")
    }
)
public class Order { ... }

// Use in repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    
    @EntityGraph(value = "Order.withCustomerAndItems", type = EntityGraphType.FETCH)
    List<Order> findByStatus(OrderStatus status);
    
    // Ad-hoc entity graph
    @EntityGraph(attributePaths = {"customer", "items"})
    Optional<Order> findById(Long id);
    
    // Subgraph for nested associations
    @EntityGraph(attributePaths = {"customer", "items.product"})
    List<Order> findByCustomerId(Long customerId);
}
```

### Solution 3: Batch Fetching (Hibernate)

```java
// In application.properties
spring.jpa.properties.hibernate.default_batch_fetch_size=25

// Or per-association
@Entity
public class Order {
    @OneToMany(mappedBy = "order")
    @BatchSize(size = 25)
    private List<OrderItem> items;
}
```

### Detecting N+1 Queries

```properties
# Enable SQL logging to detect N+1
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

# Statistics for query count
spring.jpa.properties.hibernate.generate_statistics=true
```

```java
// Use datasource-proxy for query counting in tests
@Test
void shouldNotCauseNPlus1() {
    QueryCountHolder.clear();
    
    List<Order> orders = orderRepository.findByStatusWithCustomer(PENDING);
    orders.forEach(o -> o.getCustomer().getName());
    
    assertThat(QueryCountHolder.getGrandTotal().getSelect()).isEqualTo(1);
}
```

## Transaction Management

### @Transactional Best Practices

```java
@Service
public class OrderService {
    
    // Read-only for queries - enables optimizations
    @Transactional(readOnly = true)
    public List<Order> findActiveOrders() {
        return orderRepository.findByStatus(OrderStatus.ACTIVE);
    }
    
    // Default for write operations
    @Transactional
    public Order createOrder(CreateOrderRequest request) {
        Order order = new Order();
        // ... populate order
        return orderRepository.save(order);
    }
    
    // Explicit rollback rules
    @Transactional(rollbackFor = BusinessException.class)
    public void processOrder(Long orderId) {
        // ...
    }
    
    // Timeout for long operations
    @Transactional(timeout = 30)
    public void batchProcess() {
        // ...
    }
    
    // Propagation for nested transactions
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void auditAction(String action) {
        // Runs in separate transaction
    }
}
```

### Repository-Level Transactions

```java
@Transactional(readOnly = true)
public interface UserRepository extends JpaRepository<User, Long> {
    
    // Inherits readOnly = true
    List<User> findByLastname(String lastname);
    
    // Override for modifying operations
    @Modifying
    @Transactional
    @Query("update User u set u.active = false where u.lastLogin < :date")
    int deactivateOldUsers(@Param("date") LocalDateTime date);
}
```

### Transaction Boundaries

```java
@Service
public class UserManagementService {
    
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    
    // Define transaction at service layer, not repository
    @Transactional
    public void addRoleToAllUsers(String roleName) {
        Role role = roleRepository.findByName(roleName);
        
        for (User user : userRepository.findAll()) {
            user.addRole(role);
            userRepository.save(user);
        }
    }
}
```

## Auditing with @CreatedDate/@LastModifiedDate

### Setup Auditing

```java
@Configuration
@EnableJpaAuditing
public class JpaConfig {
    
    @Bean
    public AuditorAware<String> auditorProvider() {
        return () -> Optional.ofNullable(SecurityContextHolder.getContext())
            .map(SecurityContext::getAuthentication)
            .filter(Authentication::isAuthenticated)
            .map(Authentication::getName);
    }
}
```

### Auditable Base Entity

```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class AuditableEntity {
    
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private Instant updatedAt;
    
    @CreatedBy
    @Column(name = "created_by", updatable = false)
    private String createdBy;
    
    @LastModifiedBy
    @Column(name = "updated_by")
    private String updatedBy;
    
    // Getters...
}

@Entity
public class Order extends AuditableEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    // ... other fields
}
```

### Embedded Audit Metadata

```java
@Embeddable
public class AuditMetadata {
    
    @CreatedDate
    private Instant createdAt;
    
    @LastModifiedDate
    private Instant updatedAt;
    
    @CreatedBy
    private String createdBy;
    
    @LastModifiedBy
    private String updatedBy;
}

@Entity
public class Product {
    @Id
    private Long id;
    
    @Embedded
    private AuditMetadata audit = new AuditMetadata();
}
```

## Performance Optimization Summary

### Query Optimization Checklist

1. **Use projections** when you don't need full entities
2. **Avoid N+1** with JOIN FETCH or @EntityGraph
3. **Use @Transactional(readOnly = true)** for queries
4. **Enable batch fetching** for lazy collections
5. **Use pagination** for large result sets
6. **Index foreign keys** and frequently queried columns

### Pagination

```java
public interface UserRepository extends JpaRepository<User, Long> {
    
    Page<User> findByLastname(String lastname, Pageable pageable);
    Slice<User> findByFirstname(String firstname, Pageable pageable);
    List<User> findByAge(int age, Pageable pageable);
}

// Usage
Pageable pageable = PageRequest.of(0, 20, Sort.by("lastname").ascending());
Page<User> page = userRepository.findByLastname("Smith", pageable);
```

### Avoid Common Mistakes

```java
// BAD: Loading entire entity for ID check
User user = userRepository.findById(id).orElse(null);
return user != null;

// GOOD: Use existsById
return userRepository.existsById(id);

// BAD: Loading all to count
return userRepository.findAll().size();

// GOOD: Use count
return userRepository.count();

// BAD: Loading entity just to get one field
User user = userRepository.findById(id).get();
return user.getEmail();

// GOOD: Use projection
return userRepository.findEmailById(id);
```

## Sources

- Spring Data JPA Reference Documentation
- https://docs.spring.io/spring-data/jpa/reference/
- Query Methods: https://docs.spring.io/spring-data/jpa/reference/jpa/query-methods.html
- Projections: https://docs.spring.io/spring-data/jpa/reference/repositories/projections.html
- Transactions: https://docs.spring.io/spring-data/jpa/reference/jpa/transactions.html
- Auditing: https://docs.spring.io/spring-data/jpa/reference/auditing.html
