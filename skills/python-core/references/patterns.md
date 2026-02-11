# Python Patterns Reference

Common Python patterns for clean, idiomatic code.

## 1. Context Managers

**Purpose**: Automatic resource management (files, locks, connections).

**Syntax**:
```python
with expression as variable:
    # use variable
# automatic cleanup
```

**Custom Context Manager**:
```python
class DatabaseConnection:
    def __enter__(self):
        self.conn = connect_to_db()
        return self.conn
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.conn.close()
        return False  # Don't suppress exceptions

# Usage
with DatabaseConnection() as conn:
    conn.execute("SELECT * FROM users")
```

**Using contextlib**:
```python
from contextlib import contextmanager

@contextmanager
def file_manager(filename, mode):
    f = open(filename, mode)
    try:
        yield f
    finally:
        f.close()

with file_manager('data.txt', 'r') as f:
    data = f.read()
```

**Common Use Cases**:
- File I/O (`with open()`)
- Database connections
- Lock acquisition/release
- Temporary state changes

---

## 2. Decorators

**Purpose**: Modify or enhance function behavior without changing its code.

**Basic Decorator**:
```python
def my_decorator(func):
    def wrapper(*args, **kwargs):
        print("Before function")
        result = func(*args, **kwargs)
        print("After function")
        return result
    return wrapper

@my_decorator
def say_hello():
    print("Hello!")

# Equivalent to: say_hello = my_decorator(say_hello)
```

**Preserving Metadata with functools.wraps**:
```python
import functools

def timing_decorator(func):
    @functools.wraps(func)  # Preserves func.__name__, __doc__, etc.
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.time() - start:.2f}s")
        return result
    return wrapper
```

**Decorator with Arguments**:
```python
def repeat(times):
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            for _ in range(times):
                result = func(*args, **kwargs)
            return result
        return wrapper
    return decorator

@repeat(times=3)
def greet(name):
    print(f"Hello {name}")
```

**Common Use Cases**:
- Logging, timing, caching
- Authentication/authorization checks
- Input validation
- Retry logic

---

## 3. Comprehensions

**Purpose**: Concise syntax for creating lists, dicts, and sets.

**List Comprehension**:
```python
# Basic
squares = [x**2 for x in range(10)]

# With condition
even_squares = [x**2 for x in range(10) if x % 2 == 0]

# Nested
matrix = [[i*j for j in range(3)] for i in range(3)]
```

**Dict Comprehension**:
```python
# Basic
squares_dict = {x: x**2 for x in range(5)}

# From two lists
keys = ['a', 'b', 'c']
values = [1, 2, 3]
mapping = {k: v for k, v in zip(keys, values)}

# With condition
filtered = {k: v for k, v in data.items() if v > 10}
```

**Set Comprehension**:
```python
unique_lengths = {len(word) for word in words}
```

**Common Use Cases**:
- Transforming collections
- Filtering data
- Creating mappings
- Flattening nested structures

---

## 4. Generators

**Purpose**: Memory-efficient iteration over large datasets.

**Generator Function (yield)**:
```python
def count_up_to(n):
    count = 1
    while count <= n:
        yield count
        count += 1

# Usage
for num in count_up_to(5):
    print(num)  # Prints 1, 2, 3, 4, 5
```

**Generator Expression**:
```python
# Like list comprehension but with ()
squares_gen = (x**2 for x in range(1000000))  # Memory efficient

# vs list comprehension
squares_list = [x**2 for x in range(1000000)]  # Loads all into memory
```

**Practical Example - Reading Large Files**:
```python
def read_large_file(file_path):
    with open(file_path) as f:
        for line in f:
            yield line.strip()

# Process one line at a time
for line in read_large_file('huge.log'):
    if 'ERROR' in line:
        process_error(line)
```

**Common Use Cases**:
- Processing large files
- Infinite sequences
- Pipeline processing
- Memory-constrained environments

---

## 5. Dataclasses

**Purpose**: Reduce boilerplate for classes that mainly store data.

**Basic Dataclass**:
```python
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str
    email: str
    active: bool = True  # Default value

# Auto-generates __init__, __repr__, __eq__
user = User(id=1, name="Alice", email="alice@example.com")
print(user)  # User(id=1, name='Alice', email='alice@example.com', active=True)
```

**With Methods**:
```python
@dataclass
class Point:
    x: float
    y: float
    
    def distance_from_origin(self) -> float:
        return (self.x**2 + self.y**2) ** 0.5
```

**Immutable Dataclass**:
```python
@dataclass(frozen=True)
class Config:
    host: str
    port: int

config = Config("localhost", 8080)
# config.port = 9000  # Raises FrozenInstanceError
```

**Post-Init Processing**:
```python
@dataclass
class Rectangle:
    width: float
    height: float
    area: float = None
    
    def __post_init__(self):
        if self.area is None:
            self.area = self.width * self.height
```

**Common Use Cases**:
- Data transfer objects (DTOs)
- Configuration objects
- API response models
- Reducing boilerplate code

---

## 6. Async/Await Basics

**Purpose**: Concurrent I/O operations without threading complexity.

**Basic Async Function**:
```python
import asyncio

async def fetch_data(url):
    await asyncio.sleep(1)  # Simulate network request
    return f"Data from {url}"

# Run async function
result = asyncio.run(fetch_data("https://api.example.com"))
```

**Running Multiple Tasks Concurrently**:
```python
async def main():
    # Sequential (slow)
    result1 = await fetch_data("url1")
    result2 = await fetch_data("url2")
    
    # Concurrent (fast)
    results = await asyncio.gather(
        fetch_data("url1"),
        fetch_data("url2"),
        fetch_data("url3")
    )
    return results

asyncio.run(main())
```

**Async Context Manager**:
```python
class AsyncDatabase:
    async def __aenter__(self):
        self.conn = await connect_async()
        return self.conn
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.conn.close()

async with AsyncDatabase() as db:
    await db.query("SELECT * FROM users")
```

**Common Use Cases**:
- HTTP requests (with aiohttp)
- Database queries (with asyncpg, motor)
- File I/O (with aiofiles)
- WebSocket connections

**When NOT to Use Async**:
- CPU-bound tasks (use multiprocessing instead)
- Simple scripts with no I/O
- Libraries that don't support async

---

## Summary

| Pattern | Best For | Avoid When |
|---------|----------|------------|
| Context Managers | Resource cleanup | Simple operations |
| Decorators | Cross-cutting concerns | Complex logic |
| Comprehensions | Transforming collections | Complex nested logic |
| Generators | Large datasets | Need random access |
| Dataclasses | Data storage | Complex behavior |
| Async/Await | I/O-bound concurrency | CPU-bound tasks |
