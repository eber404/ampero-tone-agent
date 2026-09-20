# Agent Guide

## Project

`ampero-tone-agent` is an AI-native tone agent and local control layer for the
HOTONE Ampero II Stomp.

The project helps users research tones, inspect device state, prepare tone
plans, apply approved changes, and save or roll back results.

## Operating Model

Use this flow:

```text
Codex Skill -> Python control layer -> supervised bridge -> official editor library -> device
```

The Codex Skill is the user-facing entry point. The Python layer validates plans
and safety rules. The bridge handles connected device communication.

Use the official editor installation at runtime. Never add or distribute vendor
libraries, firmware, algorithm catalogs, or user preset data.

## Safety

- Close the official Ampero II Editor before direct device access.
- Use read-only checks before any write.
- Show and validate the complete plan before execution.
- Require explicit `APPLY` confirmation for writes.
- Treat `SAVE:Axx-y` as irreversible.
- Keep journal data for rollback after apply.
- Do not expose firmware, bootloader, factory reset, preset deletion, global I/O, or raw messages.
- Do not guess model names, parameter names, ranges, or protocol identifiers.
- Do not claim hardware behavior without hardware evidence.
- Do not use disabled effects as placeholder models to clear unrelated slots. Modify only slots required by the approved chain; if slot clearing is unsupported, preserve untouched slots and disclose the limitation.

`plan apply` changes the live editing buffer. `plan save` writes a preset and
cannot be undone by this project.

## Platforms

Supported platforms are Windows and macOS.

- macOS commands and scripts live under `scripts/macos/`.
- Windows commands and scripts live under `scripts/windows/`.
- Shared Python control code lives under `src/ampero_control/`.
- Platform-independent behavior belongs in shared code.

Use `Makefile` targets for common setup, build, test, installation, diagnostics,
catalog search, and plan preview commands.

Recommended macOS checks:

```bash
make mac-test
make mac-doctor
make mac-snapshot
make mac-plan-preview PLAN=examples/clear-rhythm.plan.json
```

Recommended Windows checks:

```text
make win-test
make win-doctor
make win-snapshot
make win-plan-preview PLAN=examples/clear-rhythm.plan.json
```

Keep hardware writes as explicit CLI commands. Do not hide `apply`, `rollback`,
or `save` behind general Make targets.

## Development

- Read relevant documentation before changing behavior.
- Add or update tests with behavior changes.
- Run the full test suite before reporting completion.
- Run `git diff --check` before committing.
- Keep changes focused and avoid unrelated refactors.
- Do not commit `.tools/`, `.venv/`, journals, vendor files, catalogs, backups, or logs with personal paths.

Important documentation:

- `README.md`: user setup and command reference.
- `docs/architecture.md`: system boundaries.
- `docs/protocol.md`: compatibility notes.
- `docs/safety.md`: safety model.
- `docs/development.md`: development commands.
- `skills/ampero-tone/`: agent workflow and safety rules.

## Git

Keep commits focused. Review the full branch diff before opening or updating a
pull request. Do not rewrite or force-push shared branches unless explicitly
requested.
