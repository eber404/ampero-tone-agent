#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python_executable="${AMPERO_PYTHON:-}"

if [[ -z "$python_executable" ]]; then
    if [[ -x "$project_root/.venv/bin/python" ]]; then
        python_executable="$project_root/.venv/bin/python"
    elif command -v python3 >/dev/null 2>&1; then
        python_executable="$(command -v python3)"
    fi
fi

if [[ -z "$python_executable" || ! -x "$python_executable" ]]; then
    printf '%s\n' "Python 3.9+ not found. Set AMPERO_PYTHON." >&2
    exit 1
fi

export PYTHONPATH="$project_root/src${PYTHONPATH:+:$PYTHONPATH}"
exec "$python_executable" -B -m unittest discover -s "$project_root/tests" -v
