#!/bin/bash
# Find Python interpreter for a project without activating venv
# Usage: find_python.sh <project_root>

PROJECT_ROOT="$1"

if [ -z "$PROJECT_ROOT" ] || [ ! -f "$PROJECT_ROOT/pyproject.toml" ]; then
    # No pyproject.toml, use system Python
    which python3 || which python
    exit 0
fi

# Try uv first (most common based on user's setup)
if command -v uv &> /dev/null; then
    # Use uv run to get the Python path
    PYTHON_PATH=$(uv run --directory "$PROJECT_ROOT" python -c "import sys; print(sys.executable)" 2>/dev/null)
    if [ -n "$PYTHON_PATH" ] && [ -x "$PYTHON_PATH" ]; then
        echo "$PYTHON_PATH"
        exit 0
    fi
fi

# Try poetry
if command -v poetry &> /dev/null && [ -f "$PROJECT_ROOT/poetry.lock" ]; then
    PYTHON_PATH=$(poetry env info --path 2>/dev/null)
    if [ -n "$PYTHON_PATH" ] && [ -x "$PYTHON_PATH/bin/python" ]; then
        echo "$PYTHON_PATH/bin/python"
        exit 0
    fi
fi

# Check for venv in project root
for venv_dir in .venv venv env virtualenv; do
    if [ -x "$PROJECT_ROOT/$venv_dir/bin/python" ]; then
        echo "$PROJECT_ROOT/$venv_dir/bin/python"
        exit 0
    fi
done

# Use system Python
which python3 || which python
