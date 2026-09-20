#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
force=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --codex-home)
            codex_home="$2"
            shift 2
            ;;
        --force)
            force=true
            shift
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

source_dir="$project_root/skills/ampero-tone"
destination_root="$codex_home/skills"
destination="$destination_root/ampero-tone"

if [[ -e "$destination" ]]; then
    if [[ "$force" != true ]]; then
        printf 'Skill already exists at %s. Re-run with --force to replace it.\n' "$destination" >&2
        exit 1
    fi
    rm -rf "$destination"
fi

mkdir -p "$destination_root"
cp -R "$source_dir" "$destination"
printf '%s\n' "$project_root" > "$destination/.codex4ampero-root"
printf 'Installed ampero-tone skill to %s\n' "$destination"
printf '%s\n' "Restart Codex before using the skill."
