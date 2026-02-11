# Pytest Testing Reference

Essential pytest patterns for writing effective tests.

## Basic Test Structure

```python
# test_calculator.py
def test_addition():
    assert 2 + 2 == 4

def test_subtraction():
    result = 10 - 3
    assert result == 7
```

Run tests: `pytest` or `pytest test_calculator.py`

## Fixtures

**Basic Fixture**:
```python
import pytest

@pytest.fixture
def sample_data():
    return [1, 2, 3, 4, 5]

def test_sum(sample_data):
    assert sum(sample_data) == 15

def test_length(sample_data):
    assert len(sample_data) == 5
```

**Fixture with Setup/Teardown**:
```python
@pytest.fixture
def database_connection():
    # Setup
    conn = create_connection()
    yield conn
    # Teardown
    conn.close()

def test_query(database_connection):
    result = database_connection.execute("SELECT 1")
    assert result is not None
```

**Fixture Scopes**:
```python
@pytest.fixture(scope="function")  # Default: new instance per test
def func_fixture():
    return "function scope"

@pytest.fixture(scope="module")  # One instance per module
def module_fixture():
    return "module scope"

@pytest.fixture(scope="session")  # One instance per test session
def session_fixture():
    return "session scope"
```

## Parametrize

**Basic Parametrize**:
```python
import pytest

@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (4, 16),
])
def test_square(input, expected):
    assert input ** 2 == expected
```

**Multiple Parameters**:
```python
@pytest.mark.parametrize("x,y,expected", [
    (1, 1, 2),
    (2, 3, 5),
    (10, 5, 15),
])
def test_addition(x, y, expected):
    assert x + y == expected
```

**Parametrize with IDs**:
```python
@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
], ids=["two_squared", "three_squared"])
def test_square(input, expected):
    assert input ** 2 == expected
```

## Assertions

**Basic Assertions**:
```python
def test_assertions():
    assert 1 + 1 == 2
    assert "hello".upper() == "HELLO"
    assert [1, 2, 3] == [1, 2, 3]
```

**Exception Assertions**:
```python
import pytest

def test_exception():
    with pytest.raises(ValueError):
        int("not a number")

def test_exception_message():
    with pytest.raises(ValueError, match="invalid literal"):
        int("not a number")
```

**Approximate Comparisons**:
```python
def test_float_comparison():
    assert 0.1 + 0.2 == pytest.approx(0.3)
    assert 10.0 == pytest.approx(10.1, abs=0.2)
```

## Mocking

**Mock with unittest.mock**:
```python
from unittest.mock import Mock, patch

def test_mock_function():
    mock_func = Mock(return_value=42)
    result = mock_func()
    assert result == 42
    mock_func.assert_called_once()
```

**Patch External Dependencies**:
```python
from unittest.mock import patch

def get_user_data(user_id):
    response = requests.get(f"https://api.example.com/users/{user_id}")
    return response.json()

@patch('requests.get')
def test_get_user_data(mock_get):
    mock_get.return_value.json.return_value = {"id": 1, "name": "Alice"}
    
    result = get_user_data(1)
    
    assert result["name"] == "Alice"
    mock_get.assert_called_once_with("https://api.example.com/users/1")
```

**pytest-mock Plugin**:
```python
def test_with_mocker(mocker):
    mock_func = mocker.patch('module.function')
    mock_func.return_value = "mocked"
    
    result = module.function()
    assert result == "mocked"
```

## Running Tests

```bash
# Run all tests
pytest

# Run specific file
pytest test_calculator.py

# Run specific test
pytest test_calculator.py::test_addition

# Run with verbose output
pytest -v

# Run with coverage
pytest --cov=mymodule

# Run tests matching pattern
pytest -k "test_add"

# Stop on first failure
pytest -x

# Show print statements
pytest -s
```

## Common Patterns

**Setup/Teardown with Fixtures**:
```python
@pytest.fixture
def temp_file():
    file = open("temp.txt", "w")
    file.write("test data")
    file.close()
    yield "temp.txt"
    os.remove("temp.txt")
```

**Combining Fixtures**:
```python
@pytest.fixture
def user():
    return {"name": "Alice", "age": 25}

@pytest.fixture
def user_with_email(user):
    user["email"] = "alice@example.com"
    return user

def test_user(user_with_email):
    assert user_with_email["email"] == "alice@example.com"
```
