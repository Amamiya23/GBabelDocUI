# AGENTS.md

Agentic coding guidelines for pdf2zh-gbabeldocui (pdf2zh_next).

## Project Overview

This is a Python-based PDF document translation project using BabelDoc. The main code lives in `/home/cat/GBabelDocUI/pdf2zh_next/`.

## Build/Lint/Test Commands

### Installation
```bash
uv pip install --no-cache .
```

### Running Tests
```bash
# Run all tests
pytest

# Run a specific test file
pytest test/test_cache.py

# Run a specific test class
pytest test/test_cache.py::TestCache

# Run a specific test method
pytest test/test_cache.py::TestCache::test_basic_set_get
```

### Linting & Formatting
```bash
# Run ruff linter (auto-fix)
ruff check --fix .

# Run ruff formatter
ruff format .

# Run both (pre-commit hook style)
ruff check --fix && ruff format
```

### Pre-commit Hooks
```bash
# Install pre-commit hooks
pre-commit install

# Run all pre-commit hooks manually
pre-commit run --all-files
```

## Code Style Guidelines

### General
- **Python Version**: 3.10 - 3.13
- **Max Line Length**: 88 characters
- **Docstring Convention**: Google style (see `tool.ruff.lint.pydocstyle.convention`)
- **Quotes**: Double quotes for docstrings, single quotes in code
- **Future Imports**: Always use `from __future__ import annotations`

### Imports
- Use `isort` with `force-single-line` (each import on its own line)
- Group order: stdlib → third-party → local
- Always use absolute imports for local packages (e.g., `from pdf2zh_next.config import ...`)

```python
from __future__ import annotations

import asyncio
import logging
from pathlib import Path
from typing import Optional

from fastapi import FastAPI
from pydantic import BaseModel

from pdf2zh_next.config import ConfigManager
from pdf2zh_next.high_level import do_translate_async_stream
```

### Type Annotations
- Use modern type hints with `from __future__ import annotations`
- Use `Optional[X]` over `X | None`
- Use pydantic `Field` for model field definitions with descriptions

```python
from pydantic import BaseModel, Field

class TranslationSettings(BaseModel):
    lang_in: str = Field(default="en", description="Source language code")
    qps: int = Field(default=4, description="QPS limit for translation service")
```

### Naming Conventions
- **Classes**: `PascalCase` (e.g., `TranslationSettings`, `WatermarkOutputMode`)
- **Functions/Variables**: `snake_case` (e.g., `do_translate_file_async`, `translate_engine_settings`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `MAX_LINE_LENGTH`)
- **Private Methods**: Prefix with `_` (e.g., `_validate_settings`)
- **Type Variables**: PascalCase (e.g., `TRANSLATION_ENGINE_SETTING_TYPE`)

### Pydantic Models
- Use pydantic v2 syntax (`BaseModel`, `Field`, `model_validator`)
- Use `model_copy(deep=True)` for deep cloning
- Use enums for fixed sets of choices

```python
class WatermarkOutputMode(enum.Enum):
    Watermarked = "watermarked"
    NoWatermark = "no_watermark"
    Both = "both"
```

### Error Handling
- Use structured logging via `logging.getLogger(__name__)`
- Use specific exception types when possible
- Prefer raising `ValueError` with clear messages for validation errors
- Chain exceptions with `raise ... from e` when appropriate

```python
logger = logging.getLogger(__name__)

def validate_settings(self) -> None:
    if not self.translate_engine_settings:
        raise ValueError("Must provide a translation service")
    try:
        re.compile(pattern)
    except re.error as e:
        raise ValueError(f"Invalid pattern: {e}") from e
```

### Async Code
- Use `asyncio` for async operations
- Use `async for` with async generators
- Prefer `asyncio.create_task()` for fire-and-forget background tasks

```python
async def do_translate_async_stream(settings, file_path):
    async for event in do_translate_async_stream(settings, file_path):
        if event["type"] == "finish":
            break
```

### Logging
- Initialize with `RichHandler` for CLI
- Disable noisy loggers for httpx, openai, httpcore

```python
from rich.logging import RichHandler

logging.basicConfig(level=logging.INFO, handlers=[RichHandler()])
logging.getLogger("httpx").setLevel("CRITICAL")
```

### File Structure
```
pdf2zh_next/
├── __init__.py          # Public API exports
├── main.py              # CLI entry point
├── gui.py               # Gradio UI
├── web_api.py           # FastAPI web server
├── high_level.py        # High-level translation functions
├── auth.py              # Authentication/user management
├── i18n.py              # Internationalization
├── const.py             # Constants
├── config/
│   ├── __init__.py
│   ├── main.py          # ConfigManager
│   ├── model.py         # Pydantic settings models
│   ├── translate_engine_model.py  # Translation engine settings
│   └── cli_env_model.py # CLI environment model
├── translator/
│   ├── __init__.py
│   ├── base_translator.py
│   ├── cache.py
│   ├── utils.py
│   ├── translator_impl/  # Individual engine implementations
│   └── rate_limiter/
└── utils/
    └── asynchronize/
```

### API Design (FastAPI)
- Use Pydantic models for request/response validation
- Use `Depends()` for dependency injection
- Use `HTTPException` for HTTP errors with appropriate status codes
- Document endpoints with docstrings

```python
async def get_current_user(authorization: Optional[str] = Header(None)) -> dict:
    """Validate authentication token and return current user"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    return user_data
```

### Testing
- Use `unittest.TestCase` style
- Use `setUp` and `tearDown` for test fixtures
- Test file naming: `test_*.py`
- Include docstrings for each test method

```python
class TestCache(unittest.TestCase):
    def setUp(self):
        self.test_db = cache.init_test_db()

    def tearDown(self):
        cache.clean_test_db(self.test_db)

    def test_basic_set_get(self):
        """Test basic set and get operations"""
        cache_instance = cache.TranslationCache("test_engine")
        cache_instance.set("hello", "你好")
        result = cache_instance.get("hello")
        self.assertEqual(result, "你好")
```

## Ruff Configuration (from pyproject.toml)

Key lint rules:
- `E`, `F`: Pycodestyle and Pyflakes errors
- `N`: PEP8 naming conventions
- `B`: flake8-bugbear
- `I`: isort
- `UP`: pyupgrade
- `S`: flake8-bandit security
- `C`: mccabe complexity

Ignored rules:
- `E203`: whitespace before ':'
- `E261`: too few spaces before comment
- `E501`: line too long (handled by formatter)
- `E741`: ambiguous variable name
- `F841`: unused variable
- `S101`: use assert (allowed in tests)

Per-file ignores:
- `gui.py`: S104 (starting subprocess)
- `tests/*`: S101 (assert in tests)
- `__init__.py`: F401 (unused imports)
- `docs/*`: A001 (builtin shadowing)

## Configuration Priority

Settings are managed via pydantic-settings with environment variable support. See `config/cli_env_model.py` for environment variable mappings.
