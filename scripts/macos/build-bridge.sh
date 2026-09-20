#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bridge_root="$project_root/bridge"
output="$project_root/.tools/ampero_bridge"
dart_executable="${1:-${AMPERO_DART_EXE:-}}"

if [[ -z "$dart_executable" ]]; then
    local_dart="$project_root/.tools/dart-sdk/bin/dart"
    if [[ -x "$local_dart" ]]; then
        dart_executable="$local_dart"
    elif command -v dart >/dev/null 2>&1; then
        dart_executable="$(command -v dart)"
    fi
fi

if [[ -z "$dart_executable" || ! -x "$dart_executable" ]]; then
    printf '%s\n' "Dart SDK not found. Install Dart, add dart to PATH, pass its path, or set AMPERO_DART_EXE." >&2
    exit 1
fi

mkdir -p "$project_root/.tools"
(
    cd "$bridge_root"
    "$dart_executable" pub get
    "$dart_executable" analyze
    "$dart_executable" compile exe bin/ampero_bridge.dart -o "$output"
)
chmod +x "$output"
printf 'Built %s\n' "$output"
