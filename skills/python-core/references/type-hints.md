# Advanced Type Hints Reference

Advanced typing patterns for type-safe Python code.

## TypeVar and Generics

**TypeVar** - Create type variables for generic functions:

```python
from typing import TypeVar, List

T = TypeVar('T')

def first(items: List[T]) -> T:
    return items[0]

# Type checker infers return type based on input
num = first([1, 2, 3])  # num: int
name = first(['Alice', 'Bob'])  # name: str
```

**Constrained TypeVar**:
```python
from typing import TypeVar

# Only allow str or bytes
AnyStr = TypeVar('AnyStr', str, bytes)

def concat(x: AnyStr, y: AnyStr) -> AnyStr:
    return x + y

concat("hello", "world")  # OK
concat(b"hello", b"world")  # OK
# concat("hello", b"world")  # Error: mixed types
```

**Bounded TypeVar**:
```python
from typing import TypeVar

class Animal:
    def speak(self) -> str:
        return "..."

T = TypeVar('T', bound=Animal)

def make_speak(animal: T) -> T:
    print(animal.speak())
    return animal
```

## Generic Classes

```python
from typing import Generic, TypeVar

T = TypeVar('T')

class Stack(Generic[T]):
    def __init__(self) -> None:
        self.items: List[T] = []
    
    def push(self, item: T) -> None:
        self.items.append(item)
    
    def pop(self) -> T:
        return self.items.pop()

# Usage
int_stack = Stack[int]()
int_stack.push(1)
int_stack.push(2)
# int_stack.push("hello")  # Type error

str_stack = Stack[str]()
str_stack.push("hello")
```

**Multiple Type Parameters**:
```python
from typing import Generic, TypeVar

K = TypeVar('K')
V = TypeVar('V')

class Pair(Generic[K, V]):
    def __init__(self, key: K, value: V):
        self.key = key
        self.value = value

pair = Pair[str, int]("age", 25)
```

## Protocols (Structural Subtyping)

**Protocol** - Define interfaces without inheritance:

```python
from typing import Protocol

class Drawable(Protocol):
    def draw(self) -> None:
        ...

class Circle:
    def draw(self) -> None:
        print("Drawing circle")

class Square:
    def draw(self) -> None:
        print("Drawing square")

def render(shape: Drawable) -> None:
    shape.draw()

# Both work without inheriting from Drawable
render(Circle())
render(Square())
```

**Protocol with Properties**:
```python
from typing import Protocol

class Sized(Protocol):
    @property
    def size(self) -> int:
        ...

class MyList:
    def __init__(self, items: list):
        self._items = items
    
    @property
    def size(self) -> int:
        return len(self._items)

def process_sized(obj: Sized) -> None:
    print(f"Size: {obj.size}")

process_sized(MyList([1, 2, 3]))  # OK
```

## Union Types and Optional

**Union** - Value can be one of several types:

```python
from typing import Union

def process_id(id: Union[int, str]) -> str:
    if isinstance(id, int):
        return f"ID-{id:05d}"
    return id

# Python 3.10+ syntax
def process_id(id: int | str) -> str:
    if isinstance(id, int):
        return f"ID-{id:05d}"
    return id
```

**Optional** - Value can be None:

```python
from typing import Optional

def find_user(user_id: int) -> Optional[str]:
    users = {1: "Alice", 2: "Bob"}
    return users.get(user_id)  # Returns str or None

# Python 3.10+ syntax
def find_user(user_id: int) -> str | None:
    users = {1: "Alice", 2: "Bob"}
    return users.get(user_id)
```

## Type Guards

**isinstance() Type Narrowing**:

```python
def process_value(val: int | str) -> str:
    if isinstance(val, int):
        # Type checker knows val is int here
        return str(val * 2)
    # Type checker knows val is str here
    return val.upper()
```

**Custom Type Guard**:

```python
from typing import TypeGuard

def is_str_list(val: list) -> TypeGuard[list[str]]:
    return all(isinstance(x, str) for x in val)

def process_strings(items: list) -> None:
    if is_str_list(items):
        # Type checker knows items is list[str] here
        for item in items:
            print(item.upper())  # OK: item is str
```

## Callable Types

```python
from typing import Callable

def apply_twice(func: Callable[[int], int], value: int) -> int:
    return func(func(value))

def double(x: int) -> int:
    return x * 2

result = apply_twice(double, 5)  # Returns 20
```

**With Multiple Arguments**:

```python
from typing import Callable

def execute(func: Callable[[str, int], bool], name: str, age: int) -> bool:
    return func(name, age)

def is_adult(name: str, age: int) -> bool:
    return age >= 18
```

## Literal Types

```python
from typing import Literal

def set_mode(mode: Literal["read", "write", "append"]) -> None:
    print(f"Mode: {mode}")

set_mode("read")  # OK
# set_mode("delete")  # Type error
```

## Type Aliases

```python
from typing import TypeAlias

# Python 3.10+
UserId: TypeAlias = int | str
UserDict: TypeAlias = dict[str, str | int]

def get_user(user_id: UserId) -> UserDict:
    return {"name": "Alice", "age": 25}
```

## Type Checking Configuration

**mypy.ini**:
```ini
[mypy]
python_version = 3.10
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_any_generics = True
```

**pyproject.toml** (mypy):
```toml
[tool.mypy]
python_version = "3.10"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

**pyproject.toml** (pyright):
```toml
[tool.pyright]
pythonVersion = "3.10"
typeCheckingMode = "strict"
reportMissingTypeStubs = false
```

## Common Patterns

**Factory Function**:
```python
from typing import TypeVar, Type

T = TypeVar('T')

def create_instance(cls: Type[T]) -> T:
    return cls()

class User:
    pass

user = create_instance(User)  # Type: User
```

**Overload for Different Signatures**:
```python
from typing import overload

@overload
def process(data: str) -> str: ...

@overload
def process(data: int) -> int: ...

def process(data: str | int) -> str | int:
    if isinstance(data, str):
        return data.upper()
    return data * 2
```

## Best Practices

1. **Start with basic types**, add complexity as needed
2. **Use Protocol** for duck typing instead of inheritance
3. **Prefer `|` over `Union`** in Python 3.10+
4. **Use `TypeAlias`** for complex types used multiple times
5. **Enable strict mode** in type checker configuration
6. **Don't use `Any`** unless absolutely necessary
7. **Use type guards** for runtime type narrowing

## Common Type Checker Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Incompatible return value type` | Function returns wrong type | Fix return type or annotation |
| `Argument has incompatible type` | Passing wrong type to function | Check function signature |
| `Need type annotation` | Variable type can't be inferred | Add explicit type annotation |
| `Unsupported operand type` | Operation on incompatible types | Add type guard or fix types |
