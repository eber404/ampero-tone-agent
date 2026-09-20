# codex4ampero

`codex4ampero` is a Codex-native tone agent and safety-focused local control layer for the **HOTONE Ampero II Stomp**.

You can ask Codex to:

- Make a tone warmer and less harsh.
- Research a song's solo tone online and show a proposal without writing to the device.
- Write an approved tone to `A50-1` and generate a save preview.
- Roll back an unwanted change.

Codex interprets the goal, researches the tone background of a song or artist, queries the real algorithm catalog shipped with the official editor, generates a reviewable plan, and calls a deterministic local control layer only after explicit confirmation. The control layer never lets the language model construct arbitrary device messages directly.

> [!IMPORTANT]
> This is an independent compatibility-research project. It is not an official HOTONE or OpenAI product. The repository does not distribute the HOTONE editor, `HTUSBTools.dll`, the official algorithm catalog, firmware, or prebuilt vendor components.

## Contents

- [Features](#features)
- [Compatibility](#compatibility)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Installation](#installation)
- [Codex Usage](#codex-usage)
- [CLI Usage](#cli-usage)
- [Tone Plans and Save Workflow](#tone-plans-and-save-workflow)
- [Safety Boundary](#safety-boundary)
- [Troubleshooting](#troubleshooting)
- [Development and Testing](#development-and-testing)
- [Publishing to GitHub](#publishing-to-github)
- [License and Trademarks](#license-and-trademarks)

## Features

### Codex-native conversation workflow

- Uses the `$ampero-tone` Skill as the user entry point instead of implementing another chat website or desktop chat UI.
- Collects guitar, pickup, and output-device information in sequence so parameters are not guessed when important context is missing.
- Performs structured web research for a specified song, artist, album, or recording era.
- Separates sourced facts, algorithm-catalog facts, tone-engineering inferences, limitations, and confidence.
- Shows a complete effect chain and parameter proposal before asking for tone feedback, destination approval, and final write confirmation.
- Returns a journal-bound save preview immediately after a successful write, avoiding a redundant interaction.

### Official algorithm catalog mapping

- Automatically discovers the official Ampero II Editor algorithm JSON directory on the local machine.
- Uses real model names, categories, model codes, parameter names, parameter IDs, ranges, steps, and enum values.
- Prevents the model from inventing algorithm names or protocol IDs.
- Supports local catalog search and exact model-detail queries.

### Read-only device capabilities

- Enumerates Ampero II Stomp input and output ports.
- Reads the current Scene.
- Reads the complete current preset, including name, Scene, slot order, enabled state, models, and parameters.
- Reads the current routing template and identifies `Parallel`, `Split->Mix`, `A/B->Y`, `Y->A/B`, and `Serial`.
- Reads and verifies `Axx-y` locations. For example, `A50-1` maps to linear index `150`.

### Controlled write capabilities

- Changes slot models and enabled state.
- Changes model parameters.
- Switches Scenes.
- Switches official routing templates.
- Selects the target preset automatically and requires the device to read back the target index.
- Reads back and verifies every command immediately after writing.
- Records pre-write state in a journal and rolls back completed operations in reverse order if an operation fails midway.

### Independent preset saving

- Normal `plan apply` changes only the device's live editing buffer; it does not save automatically.
- Saving can only bind to a journal whose status is `applied` and whose commands all passed readback verification.
- The controller verifies again before saving that the device is at the journal's exact target location.
- Saving uses a target-specific confirmation token such as `SAVE:A50-1`.
- `save_preview_name` lets the tone preview show the save target, name, 21-byte payload, and irreversible-save warning in advance.
- After a successful apply, the CLI returns the exact journal-bound save preview so the user can confirm or reject saving directly.

### Hang prevention

- The vendor native library and Dart bridge run in an isolated worker process.
- The Skill wrapper applies hard outer timeouts to scanning, snapshots, apply, rollback, and save operations.
- On timeout, the child process is terminated and a structured `WatchdogTimeout` is returned instead of waiting indefinitely.

## Compatibility

Current release: **0.2.0 (Alpha)**

| Item | Status |
| --- | --- |
| Operating system | Windows x64; macOS arm64/x86_64 |
| Verified hardware | HOTONE Ampero II Stomp |
| Python | 3.9+; 64-bit |
| Official editor | Required locally; must be closed during direct device access |
| Algorithm catalog | Read dynamically from the local editor; tested with `v1.0.8` and `v1.0.9` |
| macOS native library | Universal arm64/x86_64 library and required exports verified locally |
| Read-only snapshots | Verified on real hardware |
| Routing reads and Serial switching | Verified on real hardware |
| Model and parameter writes | Verified on real hardware |
| Per-command immediate readbacks | Verified on real hardware |
| Automatic target selection | Implemented and verified |
| Journal and rollback data | Implemented and verified |
| Preset save | Implemented; some firmware may drop the official response after saving |
| Ampero II / Ampero II Stage | Not verified; do not assume protocol equivalence |

On July 18, 2026, a real `A50-1` tone plan containing 21 commands completed with 21 immediate readback verifications. The preset-save payload has also been observed to persist on hardware, but the tested firmware can stop returning an official response after saving. In that ambiguous case, the controller conservatively reports the save as unverified instead of falsely claiming success.

On macOS, editor discovery, universal arm64/x86_64 native-library loading, compiled bridge startup, and bounded device scanning have been verified. A connected-device read/write qualification is still required before claiming macOS hardware-write verification.

## Architecture

```text
Codex conversation
       |
       v
ampero-tone Skill
context collection, web research, proposal approval, destination approval, safety confirmation
       |
       v
Python package: ampero_control
catalog resolution, plan validation, safety limits, previews, journals, rollback, save preparation
       |
       v
Dart NativePort bridge
vendor native-library connection, timer pump, request/response transport, message sending
       |
       v
HOTONE Ampero II Stomp
```

The Dart bridge is required because the official Flutter editor uses the Dart DL API and a real `ReceivePort.nativePort` to receive connected-device messages. Ordinary Python `ctypes` can safely load the native library and scan ports, but it cannot reliably replace this callback model. All connected requests therefore run through a supervised Dart child process.

See [Architecture](docs/architecture.md), [Protocol notes](docs/protocol.md), [Safety](docs/safety.md), [Development](docs/development.md), and the [Changelog](CHANGELOG.md).

## Requirements

1. **Windows x64 or macOS 11+ on arm64/x86_64.**
2. **HOTONE Ampero II Stomp** connected over USB.
3. **Official Ampero II Editor.** Install it from the [HOTONE support site](https://www.hotoneaudio.com/support). At runtime, this project reads the communication library and algorithm catalog from its installation directory.
4. **Python 3.9+ 64-bit.** Use the official Python distribution or a platform package manager.
5. **Dart SDK 3.3+.** Required for the first local bridge build; see [Get Dart](https://dart.dev/get-dart).
6. **Codex CLI.** Required for the conversational agent workflow; see the [official OpenAI Codex CLI documentation](https://developers.openai.com/codex/cli).

### Install Codex CLI

When Node.js/npm is available, install the official package:

```powershell
npm install -g @openai/codex
codex
```

Use the OpenAI documentation for Codex login and authentication details.

## Installation

The recommended setup is to clone the repository and let Codex perform the installation steps.

### 1. Clone the repository

Replace `YOUR_USERNAME` with the actual GitHub username or repository owner:

```powershell
git clone https://github.com/YOUR_USERNAME/codex4ampero.git
cd codex4ampero
```

### 2. Create a Python virtual environment

```powershell
py -3.9 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e .
```

macOS:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e .
```

The installation provides two equivalent commands:

- `codex4ampero` - recommended command name.
- `ampero-control` - backward-compatible alias retained for earlier versions.

### 3. Configure the official editor location

The application checks these locations:

- Environment variable `AMPERO_EDITOR_DIR`.
- `D:\Ampero II`.
- `%ProgramFiles%\Ampero II`.
- `%LOCALAPPDATA%\Ampero II`.
- `/Applications/Ampero II.app`.
- `~/Applications/Ampero II.app`.

If discovery fails, set the environment variable:

```powershell
$env:AMPERO_EDITOR_DIR = "C:\Path\To\Ampero II"
```

```bash
export AMPERO_EDITOR_DIR="/Applications/Ampero II.app"
```

You can also pass the location for one command:

```powershell
codex4ampero --editor-dir "C:\Path\To\Ampero II" --json doctor --scan
```

```bash
codex4ampero --editor-dir "/Applications/Ampero II.app" --json doctor --scan
```

### 4. Build the Dart bridge

If `dart.exe` is on `PATH`:

```powershell
.\scripts\windows\build-bridge.ps1
```

Or specify the Dart executable explicitly:

```powershell
.\scripts\windows\build-bridge.ps1 -DartExe "C:\Path\To\dart.exe"
```

The generated file is `.tools\ampero_bridge.exe`. `.tools/` is ignored by Git and is not published with the repository.

On macOS:

```bash
./scripts/macos/build-bridge.sh
```

The macOS output is `.tools/ampero_bridge`.

### 5. Run diagnostics

Connect the device over USB and fully close the official Ampero II editor:

```powershell
codex4ampero --json doctor --scan
```

A healthy result should include:

- The official editor installation directory.
- Successful loading of `HTUSBTools.dll` on Windows or `HTUSBTools.dylib` on macOS.
- An available compiled bridge.
- `Ampero II Stomp` input and output port indexes.

### 6. Install the Codex Skill

```powershell
.\scripts\windows\install-skill.ps1 -Force
```

On macOS:

```bash
./scripts/macos/install-skill.sh --force
```

The installer:

1. Copies `skills/ampero-tone` to `$CODEX_HOME\skills\ampero-tone`. By default, `$CODEX_HOME` is `%USERPROFILE%\.codex`.
2. Records the current repository directory using a user environment variable on Windows or an installed Skill marker on macOS.
3. Prompts you to restart Codex.

Restart Codex CLI after installation so the new Skill and environment variable take effect.

## Codex Usage

Use the Skill directly in a Codex conversation:

```text
Use $ampero-tone. Run doctor and a read-only device snapshot. Do not change any parameters.
```

```text
Use $ampero-tone. I use a Fender Telecaster into FRFR.
Research the overdriven solo tone from Yorushika's "花に亡霊" online.
Show the detailed chain and parameters before writing anything.
```

```text
Write the approved plan to A50-1. Allow automatic target selection, but show the final target-bound preview first.
```

```text
The tone is too bright. Make only small parameter adjustments; do not change models.
```

The standard Skill workflow is:

1. Collect missing guitar and output information.
2. Run `doctor` and read the current device snapshot.
3. Research the named song or artist online.
4. Query the official local algorithm catalog.
5. Present the complete chain, parameters, reasoning, expected result, and limitations.
6. Get approval for the tone direction.
7. Confirm the exact `Axx-y` destination and automatic-selection behavior.
8. Generate, validate, and show the target-bound plan.
9. Execute `APPLY` only after final user confirmation.
10. Show the journal-bound save preview immediately after a successful write.
11. Save with `SAVE:Axx-y`, or explicitly reject saving.
12. Iterate in small steps from listening feedback and use the journal for rollback when necessary.

## CLI Usage

For daily hardware operations, use the Skill wrapper because it provides an outer watchdog:

```powershell
$python = ".\.venv\Scripts\python.exe"
```

### Doctor and scan

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json doctor --scan
```

### Current preset snapshot

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json device snapshot
& $python .\skills\ampero-tone\scripts\ampero.py --json device snapshot --include-parameters
```

### Read-only routing

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json device routing --timeout 5
```

### Query the official algorithm catalog

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json catalog search "blues" --category DRV
& $python .\skills\ampero-tone\scripts\ampero.py --json catalog show "Dr. Blues" --category DRV
```

### Validate and preview a plan

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json `
    plan validate .\examples\clear-rhythm.plan.json

& $python .\skills\ampero-tone\scripts\ampero.py --json `
    plan preview .\examples\clear-rhythm.plan.json
```

### Apply a plan

Without execution flags, `plan apply` remains a preview:

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json `
    plan apply .\examples\clear-rhythm.plan.json
```

An actual write requires both flags:

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json `
    plan apply .\examples\clear-rhythm.plan.json `
    --execute --confirm APPLY
```

### Roll back

Preview a rollback:

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json `
    plan rollback .\.ampero_journals\APPLY.journal.json
```

Execute it only with the exact rollback confirmation:

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json `
    plan rollback .\.ampero_journals\APPLY.journal.json `
    --execute --confirm ROLLBACK
```

### Save a preset

Generate the irreversible save preview first:

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json `
    plan save .\.ampero_journals\APPLY.journal.json `
    --name "My Preset"
```

Execute only with the target-specific confirmation:

```powershell
& $python .\skills\ampero-tone\scripts\ampero.py --json `
    plan save .\.ampero_journals\APPLY.journal.json `
    --name "My Preset" `
    --execute --confirm SAVE:A50-1
```

## Tone Plans and Save Workflow

Plans use UTF-8 JSON. The current schema version is `1`:

```json
{
  "schema_version": 1,
  "title": "Medium overdrive lead",
  "reason": "Add sustain and midrange while preserving pick dynamics.",
  "target_patch": "A50-1",
  "select_target_patch": true,
  "save_preview_name": "Lead Tone",
  "actions": [
    {
      "type": "set_model",
      "slot": 1,
      "effect": {"name": "Dr. Blues", "category": "DRV"},
      "enabled": true
    },
    {
      "type": "set_parameter",
      "slot": 1,
      "effect": {"name": "Dr. Blues", "category": "DRV"},
      "parameter": "Gain",
      "value": 58
    }
  ]
}
```

See the [full plan schema](skills/ampero-tone/references/plan-schema.md).

`save_preview_name` prepares a save preview only:

- The save preview shown before apply is not yet bound to a journal.
- `plan apply` never saves automatically.
- After a successful apply, the CLI returns a preview bound to the real successful journal.
- Final saving still requires the target-specific `SAVE:Axx-y` confirmation.

## Safety Boundary

- Close the official editor before direct access so two processes do not compete for the device.
- Start with low physical monitor, headphone, speaker, or FRFR volume.
- Preview is the default; writes require `--execute --confirm APPLY`.
- Rollback requires `--execute --confirm ROLLBACK`.
- Saving requires exact `SAVE:Axx-y` and cannot be rolled back by this control layer.
- Output-sensitive parameters whose names contain `level`, `output`, `master`, or `volume` cannot exceed 75% of their catalog range.
- Model changes require a successful read of the old model before a reliable rollback record can be created.
- Every command is restricted to a safety whitelist.
- Firmware, bootloader, preset deletion, factory reset, global I/O, and arbitrary raw messages are not exposed.
- `--allow-unverified-reads` is reserved for controlled protocol research; the Skill never uses it automatically.
- Do not test write operations for the first time during a performance, recording session, or high-volume monitoring.

See the complete [safety model](docs/safety.md).

## Troubleshooting

### `Official editor is running` or port is busy

Fully exit the official Ampero II editor, including orphaned background processes, then retry. The official editor and this project cannot hold direct communication state at the same time.

### Official editor not found

```powershell
$env:AMPERO_EDITOR_DIR = "C:\Path\To\Ampero II"
codex4ampero --json doctor --scan
```

Check that the installation directory contains:

- `Ampero II.exe`
- `assets\HTUSBTools.dll`
- `data\flutter_assets\assets\data`

On macOS, check the app bundle instead:

- `Contents/MacOS/Ampero II`
- `Contents/Frameworks/HTUSBTools.dylib`
- `Contents/Frameworks/App.framework/Resources/flutter_assets/assets/data`

### `bridge_available: false`

Rebuild the bridge:

```powershell
.\scripts\windows\build-bridge.ps1
```

```bash
./scripts/macos/build-bridge.sh
```

Confirm that `.tools\ampero_bridge.exe` on Windows or `.tools/ampero_bridge` on macOS exists.

### Installed Skill cannot find the repository

Reinstall the Skill:

```powershell
.\scripts\windows\install-skill.ps1 -Force
```

```bash
./scripts/macos/install-skill.sh --force
```

Or set the repository path manually:

```powershell
$env:CODEX4AMPERO_ROOT = "C:\Path\To\codex4ampero"
```

The legacy `VIBE_AMPERO_ROOT` variable is still read for compatibility, but new installations set only `CODEX4AMPERO_ROOT`.

### `DeviceTimeoutError` or `WatchdogTimeout`

- Do not retry indefinitely.
- Confirm that the official editor is closed.
- Check the USB cable and device port.
- Terminate any orphaned `ampero_bridge.exe` or `ampero_bridge` process and retry only once.
- After reconnecting USB, run a read-only handshake or snapshot first.
- If an irreversible operation has entered its sending phase, do not resend it automatically.

### Save command timeout

Some firmware may save successfully but fail to return the official response. The controller records:

- Whether the exact target preflight passed.
- Whether the operation entered `sending_save`.
- Whether an official save response was received.

When the state is ambiguous, do not resend automatically. Preserve the `*.save.journal.json` file and verify or save manually on the device.

### Device returns `0xffff`

This means the protocol cannot confirm the current patch location, so writes are blocked by default. To continue, the plan must contain an exact `target_patch`, and the user must freshly confirm that the device display shows the same `Axx-y` label using `--confirm-device-patch`.

## Development and Testing

### Repository structure

```text
codex4ampero/
├── bridge/                      Dart FFI / NativePort bridge
├── docs/                        Architecture, protocol, safety, and development docs
├── examples/                    Schema v1 tone plans
├── scripts/                     Build, test, and Skill installation scripts
├── skills/ampero-tone/          Codex Skill
├── src/ampero_control/          Python control layer
├── tests/                       Unit tests
├── pyproject.toml               Python package metadata
└── README.md                    Project documentation
```

### Run tests

```powershell
.\scripts\windows\test.ps1
```

```bash
./scripts/macos/test.sh
```

Or directly:

```powershell
$env:PYTHONPATH = "src;tests"
python -m unittest discover -s tests -v
```

### Validate the Skill

If the local Codex installation includes `skill-creator`:

```powershell
python "$HOME\.codex\skills\.system\skill-creator\scripts\quick_validate.py" `
    .\skills\ampero-tone
```

### Pre-release checks

```powershell
git diff --check
.\scripts\windows\test.ps1
.\scripts\windows\install-skill.ps1 -Force
```

Do not commit:

- `.ampero_journals/`
- `.tools/`
- Official editor files, `HTUSBTools.dll`, or `HTUSBTools.dylib`
- The official algorithm catalog
- The Dart SDK
- USB captures, user preset backups, or logs containing personal paths

The `.github/workflows/tests.yml` workflow runs the complete unit test suite on Windows and macOS with Python 3.9 and 3.12.

## Publishing to GitHub

Create an empty GitHub repository named `codex4ampero`, then run:

```powershell
git remote add origin https://github.com/YOUR_USERNAME/codex4ampero.git
git push -u origin main
```

If `origin` already exists:

```powershell
git remote set-url origin https://github.com/YOUR_USERNAME/codex4ampero.git
git push -u origin main
```

## License and Trademarks

**No open-source license has been selected yet.** Until a `LICENSE` file is added, default copyright law applies and others do not automatically receive permission to copy, modify, or redistribute the code. Before public release, choose an appropriate license such as MIT, Apache-2.0, GPL, or another license that matches the project goals.

HOTONE, Ampero, Ampero II Stomp, and related product names belong to their respective owners. This project uses these names only to identify compatible devices. OpenAI, Codex, and related names belong to OpenAI. This project is not affiliated with or endorsed by HOTONE or OpenAI.
