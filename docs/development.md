# Development

## Requirements

- Windows x64 or macOS 11+
- Python 3.9 or newer, x64 or arm64
- Official Ampero II editor installed
- Dart SDK when rebuilding the bridge
- Ampero II Stomp connected by USB for hardware tests

## Python Commands

Prefer the Skill wrapper for hardware operations because it adds a worker-process
watchdog.

Windows PowerShell:

```powershell
$python = if ($env:AMPERO_PYTHON) {
    $env:AMPERO_PYTHON
} else {
    (Get-Command python).Source
}

& $python .\skills\ampero-tone\scripts\ampero.py --json doctor --scan
& $python .\skills\ampero-tone\scripts\ampero.py --json device snapshot --include-parameters
```

macOS:

```bash
python="${AMPERO_PYTHON:-.venv/bin/python}"
"$python" skills/ampero-tone/scripts/ampero.py --json doctor --scan
"$python" skills/ampero-tone/scripts/ampero.py --json device snapshot --include-parameters
```

## Tests

Windows:

```powershell
.\scripts\test.ps1
```

macOS:

```bash
./scripts/test.sh
```

Set `AMPERO_PYTHON` to override Python discovery on either platform.

## Dart Bridge

The platform build script checks `.tools/dart-sdk/bin` before `PATH`. A different
SDK can be supplied explicitly.

Windows:

```powershell
.\scripts\build-bridge.ps1 -DartExe C:\Path\To\dart.exe
```

macOS:

```bash
./scripts/build-bridge.sh /path/to/dart
```

The generated `.tools/ampero_bridge.exe` or `.tools/ampero_bridge`, Dart SDK,
package cache, journals, and vendor binaries are ignored by Git.

## Skill Installation

Windows:

```powershell
.\scripts\install-skill.ps1 -Force
```

macOS:

```bash
./scripts/install-skill.sh --force
```

Restart Codex after installation. Do not commit generated journals, bridge
binaries, the official algorithm catalog, `HTUSBTools.dll`, or
`HTUSBTools.dylib`.
