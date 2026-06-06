# Optimized Python Development Template

A modern Python development template using uv for fast package management and Nix for reproducible environments.

## Features

- **uv Package Manager**: Lightning-fast Python package installer and resolver
- **Python 3.12**: Latest Python with modern features
- **Modern Tooling**: Ruff for linting/formatting, mypy for type checking
- **Comprehensive Testing**: pytest with coverage, async support, and parallel execution
- **Reproducible Builds**: Nix flakes for consistent environments
- **Task Automation**: Just for common development tasks
- **CI Ready**: Pre-configured checks and testing pipeline

## Quick Start

1. **Clone or copy this template to your project directory**

2. **Enter the development environment**
   ```bash
   nix develop
   # or with direnv
   echo "use flake" > .envrc && direnv allow
   ```

3. **Set up the project**
   ```bash
   just venv           # Create virtual environment
   just install        # Install dependencies
   ```

4. **Start developing**
   ```bash
   just test           # Run tests
   just lint           # Check code quality
   just help           # See all commands
   ```

## Project Structure

```
.
├── flake.nix          # Nix development environment
├── pyproject.toml     # Project configuration
├── justfile           # Task automation
├── src/               # Source code
├── tests/             # Test files
├── .venv/             # Virtual environment (created)
└── .uv-cache/         # uv cache (created)
```

## Common Tasks

```bash
# Setup
just venv               # Create virtual environment
just install            # Install dependencies
just add PACKAGE        # Add new dependency

# Development
just test               # Run tests
just test-cov           # Run tests with coverage
just test-parallel      # Run tests in parallel
just watch              # Run tests on file changes

# Code Quality
just lint               # Check code with ruff
just fmt                # Format code with ruff
just typecheck          # Type check with mypy
just fix                # Auto-fix linting issues
just format-all         # Format and fix everything

# Checks
just check              # Run all checks (lint, type, test)
just dev                # Format, fix, and check
just ci                 # Full CI pipeline

# Debugging & Profiling
just repl               # IPython REPL with project
just debug FILE         # Run with debugger
just profile FILE       # Profile performance
just memprofile FILE    # Profile memory usage

# Project Management
just clean              # Clean build artifacts
just clean-all          # Clean everything including venv
just freeze             # Update requirements.txt
just new-module NAME    # Create new module
just new-test NAME      # Create new test file
```

## Configuration

### pyproject.toml

The template includes comprehensive configuration for:

- **pytest**: Testing with coverage, markers, and sensible defaults
- **mypy**: Strict type checking configuration
- **ruff**: Fast linting and formatting (replaces black, isort, flake8)
- **coverage**: Code coverage reporting

### Virtual Environment

Always activate the virtual environment:

```bash
source .venv/bin/activate
```

Or use direnv for automatic activation.

## Testing

```bash
# Run all tests
just test

# With coverage
just test-cov

# Specific file
just test-file tests/test_mymodule.py

# Match pattern
just test-match "test_user"

# Parallel execution
just test-parallel

# Only fast tests
just quick
```

### Test Markers

Mark tests with decorators:

```python
@pytest.mark.slow
def test_slow_operation():
    pass

@pytest.mark.integration
def test_api_integration():
    pass
```

Run specific markers:
```bash
pytest -m "not slow"      # Skip slow tests
pytest -m integration     # Only integration tests
```

## Type Checking

The template uses mypy with strict configuration:

```bash
just typecheck
```

Add type hints to your code:

```python
def greet(name: str) -> str:
    return f"Hello, {name}!"
```

## Linting and Formatting

Ruff replaces multiple tools (black, isort, flake8, etc.):

```bash
just lint       # Check issues
just fmt        # Format code
just fix        # Auto-fix issues
just format-all # Format and fix everything
```

## Package Management with uv

uv is significantly faster than pip:

```bash
# Add dependency
just add requests

# Install from requirements.txt
just install-req

# Update all packages
just update

# Freeze current environment
just freeze
```

## Development Workflow

### Starting a new feature

```bash
just dev                    # Format and check everything
just new-module myfeature   # Create module structure
just new-test myfeature     # Create test file
# Write code and tests
just test-cov               # Verify with coverage
```

### Before committing

```bash
just ci                     # Run full CI pipeline
```

## Performance

### Profiling CPU

```bash
just profile src/mymodule.py
just profile-view           # View results
```

### Profiling Memory

```bash
just memprofile src/mymodule.py
```

## Debugging

### Using ipdb

```bash
just debug src/mymodule.py
```

Or add breakpoint in code:
```python
import ipdb; ipdb.set_trace()
```

### Interactive Shell

```bash
just repl       # IPython with project loaded
just shell      # Python with project in path
```

## CI/CD Integration

The template is ready for CI/CD:

```yaml
# Example GitHub Actions
- name: Run tests
  run: nix develop --command just ci
```

## Tips

1. **Use uv for speed**: uv is 10-100x faster than pip
2. **Enable direnv**: Automatic environment activation
3. **Run checks before commit**: `just dev`
4. **Use type hints**: Better IDE support and fewer bugs
5. **Write tests first**: TDD with `just watch`
6. **Profile before optimizing**: Use `just profile`

## Resources

- [uv Documentation](https://github.com/astral-sh/uv)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [pytest Documentation](https://docs.pytest.org/)
- [mypy Documentation](https://mypy.readthedocs.io/)
