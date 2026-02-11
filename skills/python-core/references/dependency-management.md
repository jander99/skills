# Python Dependency Management Reference

Modern dependency management with uv, poetry, and pip.

## Tool Selection Guide

**Use uv** (recommended for new projects):
- Fast, modern dependency resolver
- Built-in virtual environment management
- Compatible with pip and pyproject.toml
- Best for: New projects, fast workflows

**Use poetry**:
- Mature, feature-rich dependency management
- Excellent for library publishing
- Best for: Existing poetry projects, publishing packages

**Use pip + venv**:
- Standard library tools
- Universal compatibility
- Best for: Legacy projects, simple scripts, learning

---

## uv Workflows

**Installation**:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Initialize New Project**:
```bash
uv init my-project
cd my-project
```

Creates:
```
my-project/
├── pyproject.toml
├── README.md
└── src/
    └── my_project/
        └── __init__.py
```

**Add Dependencies**:
```bash
# Add package
uv add requests

# Add dev dependency
uv add --dev pytest

# Add with version constraint
uv add "pandas>=2.0,<3.0"
```

**Sync Environment**:
```bash
# Install all dependencies from pyproject.toml
uv sync

# Sync without dev dependencies
uv sync --no-dev
```

**Run Commands**:
```bash
# Run Python script
uv run python script.py

# Run installed command
uv run pytest

# Run with specific Python version
uv run --python 3.11 python script.py
```

**Remove Dependencies**:
```bash
uv remove requests
```

**Example pyproject.toml (uv)**:
```toml
[project]
name = "my-project"
version = "0.1.0"
description = "My Python project"
requires-python = ">=3.10"
dependencies = [
    "requests>=2.31.0",
    "pandas>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "mypy>=1.0.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

---

## poetry Workflows

**Installation**:
```bash
curl -sSL https://install.python-poetry.org | python3 -
```

**Initialize New Project**:
```bash
poetry new my-project
cd my-project
```

**Initialize in Existing Directory**:
```bash
poetry init
```

**Add Dependencies**:
```bash
# Add package
poetry add requests

# Add dev dependency
poetry add --group dev pytest

# Add with version constraint
poetry add "pandas^2.0"
```

**Install Dependencies**:
```bash
# Install from pyproject.toml
poetry install

# Install without dev dependencies
poetry install --without dev
```

**Run Commands**:
```bash
# Run in virtual environment
poetry run python script.py
poetry run pytest

# Activate shell
poetry shell
```

**Update Dependencies**:
```bash
# Update all
poetry update

# Update specific package
poetry update requests
```

**Remove Dependencies**:
```bash
poetry remove requests
```

**Example pyproject.toml (poetry)**:
```toml
[tool.poetry]
name = "my-project"
version = "0.1.0"
description = "My Python project"
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = "^3.10"
requests = "^2.31.0"
pandas = "^2.0.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.0.0"
mypy = "^1.0.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

---

## pip + venv Workflows

**Create Virtual Environment**:
```bash
# Create venv
python -m venv .venv

# Activate (Linux/Mac)
source .venv/bin/activate

# Activate (Windows)
.venv\Scripts\activate
```

**Install Dependencies**:
```bash
# Install package
pip install requests

# Install from requirements.txt
pip install -r requirements.txt

# Install with version
pip install "pandas>=2.0,<3.0"
```

**Freeze Dependencies**:
```bash
# Generate requirements.txt
pip freeze > requirements.txt
```

**Deactivate Environment**:
```bash
deactivate
```

**Example requirements.txt**:
```
requests==2.31.0
pandas==2.0.3
pytest==7.4.0
```

**Example requirements-dev.txt**:
```
-r requirements.txt
pytest==7.4.0
mypy==1.5.0
black==23.7.0
```

---

## pyproject.toml vs requirements.txt

**pyproject.toml** (modern, recommended):
- Standard format (PEP 518, 621)
- Supports version ranges
- Includes metadata (name, version, authors)
- Used by uv, poetry, pip (with build tools)

**requirements.txt** (legacy):
- Simple, widely supported
- Exact versions (from `pip freeze`)
- No metadata
- Used by pip

---

## Common Tasks

**Check Installed Packages**:
```bash
# uv
uv pip list

# poetry
poetry show

# pip
pip list
```

**Upgrade Package**:
```bash
# uv
uv add --upgrade requests

# poetry
poetry update requests

# pip
pip install --upgrade requests
```

**Lock Dependencies**:
```bash
# uv (automatic with uv.lock)
uv sync

# poetry (creates poetry.lock)
poetry lock

# pip (manual with pip freeze)
pip freeze > requirements.txt
```

---

## Best Practices

1. **Prefer uv for new projects** - fastest, modern tooling
2. **Use virtual environments** - isolate project dependencies
3. **Pin versions in production** - ensure reproducible builds
4. **Use version ranges in libraries** - allow flexibility
5. **Separate dev dependencies** - don't install in production
6. **Commit lock files** - ensure consistent environments
7. **Document Python version** - specify in pyproject.toml or README

---

## Migration Guide

**From pip to uv**:
```bash
# 1. Create pyproject.toml from requirements.txt
uv init

# 2. Add dependencies
cat requirements.txt | xargs -I {} uv add {}

# 3. Sync environment
uv sync
```

**From poetry to uv**:
```bash
# pyproject.toml is compatible, just:
uv sync
```

**From uv to poetry**:
```bash
# pyproject.toml is compatible, just:
poetry install
```
