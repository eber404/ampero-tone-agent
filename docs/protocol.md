# Protocol Compatibility Notes

These notes document the independently implemented compatibility subset used by
this project. They are not an official HOTONE API.

## Native Interface

The installed Windows editor provides `assets/HTUSBTools.dll`. The macOS editor
provides `Contents/Frameworks/HTUSBTools.dylib`. Both expose the subset used by
this project:

- `InitDartApiDL(NativeApi.initializeApiDLData)`
- `scanInDevice(name, callback)`
- `scanOutDevice(name, callback)`
- `connectDevice(inIndex, outIndex, productId, receive, state, send)`
- `registerSendPort(device, ReceivePort.nativePort)`
- `sendMidiMessage(device, address, data, dataSize, flag)`
- `timerCallback(device, mode)`
- `disConnectDevice(device)`

The Ampero II Stomp editor uses device name `Ampero II Stomp` and product
identifier `97`.

Input/output scanning is safe through Python `ctypes`. Connected response delivery
requires the Dart DL API and a real Dart NativePort, so requests and sends use the
compiled Dart bridge. The bridge pumps `timerCallback(nullptr, 9)` and
`timerCallback(device, 0)` approximately every 30 milliseconds.

## Message Flags

- Request: `0x11`
- Send: `0x12`
- Error: `0x13`
- Acknowledge: `0x14`
- Retry: `0x15`

## Supported Commands

| Address | Purpose | Payload |
| --- | --- | --- |
| `0x00090000` | Read the selected preset index or load an indexed preset | empty `REQUEST` reads the selected index; `SEND` with a four-byte little-endian index loads that patch |
| `0x01000000` | Read complete current preset | empty request; response contains a preset identifier followed by TLV blocks |
| `0x01040002` | Set/read slot model | slot `int8`, category `int8`, model code `int32`, enabled `int8` |
| `0x01040003` | Set/read one parameter | slot `int16`, parameter ID `int16`, value `float32` |
| `0x01080000` | Read preset inventory | empty request; decoded response contains 300 little-endian `uint16` order entries (600 bytes), then 300 zero-terminated 17-byte names |
| `0x01090004` | Set scene slot states | scene `int8`, then slot-state bytes |
| `0x01090005` | Set one scene's slot parameter array | scene `int16`, slot `int16`, then `float32[]` |
| `0x02000000` | Read current routing template | empty request; response contains a template header and routing topology |
| `0x02000003` | Select factory routing template | template ID `int32`; verified through the `0x02000000` response |
| `0x03000001` | Change/read current scene | scene `int8` for writes |
| `0x05000000` | Save live buffer to preset | target index `int32` plus a zero-padded 17-byte UTF-8 preset name |

Integers and IEEE-754 floats are little-endian. Preset save is exposed only through
the exact-target, journal-bound save workflow. Delete, firmware, bootloader,
factory-reset, global I/O, and unknown command addresses remain excluded.

`0x00090000` is the restored target-selection command. Valid preset indices are
`0` through `299` (inclusive), corresponding to labels `A00-1` through `A99-3`.
`_read_patch_index` rejects indices `>= 300`; `parse_patch_label` additionally
constrains labels to `A(\d+)-([1-3])` by regex, so `A100-1` (index 300) is
rejected by range check even though the label format parses.

## Current-Preset and Inventory Semantics

`device snapshot` first performs the patch-index handshake (screen lock,
software-state warm-up, then `PRESET_INDEX` request), optionally reads the
preset inventory when the index is known, requests the current scene, and then
requests the complete current preset. The preset response is parsed as a
four-byte identifier followed by typed length-value blocks. The implemented
parser uses:

- type `0`: dimensions such as slot and scene counts;
- type `1`: preset name, author, description, and type;
- type `4`: slot order, category IDs, and model codes;
- type `5`: per-scene parameters, enabled states, volume/tempo metadata, and
  scene names.

Unknown TLV types remain ignored rather than being interpreted speculatively.
Model and parameter names are added only when the installed algorithm catalog
contains an exact category/model match.

The complete current-preset response represents the live edit buffer. Its embedded
name is not authoritative for the persisted slot selected on the device. Snapshot
name fields therefore have explicit provenance:

- `edit_buffer_name` is the name parsed from the live current-preset response.
- `patch_name` is the selected slot name read from the preset inventory.
- `preset_name` uses `patch_name` when inventory is available; otherwise it retains
  `edit_buffer_name`.
- `preset_name_source` is `patch_inventory` or `edit_buffer_unverified`.
- `edit_buffer_name_matches_patch` compares the two names only. A match does not
  prove that edit-buffer content equals persisted patch content.
- `patch_name_read_error` explicitly reports an attempted inventory-read or parse
  failure instead of implying that the edit-buffer name was verified.

`device patches` performs one read-only inventory request and returns 300 records
with `index`, `bank`, `patch`, `label`, and `name`. It does not select or load any
patch. The inventory carries no occupancy flag; names like "Empty" are string
values only and do not prove a slot is empty. Use the list to match names visible
on the hardware display or to identify candidate destinations, but require the
device display to confirm emptiness before writing.

`device routing` reads `0x02000000` directly and does not depend on the larger
current-preset response. Routing rollback preflight uses this bounded query so a
temporary `0x01000000` timeout does not block an otherwise verifiable template
change.

The official editor limits preset names to 16 supported printable ASCII
characters and transmits them in a 17-byte zero-padded field. `plan save` uses the
same encoding. The command is bound to a successful apply journal, requires the
device to report that exact target during a recorded preflight, and waits for the
official save response. The current firmware may stop answering normal direct
requests in the same session after save, and it does not reliably answer
independent preset-name or edit-flag queries. Those post-save reads are therefore
not used as false proof of failure.

## Verification Status

The `PRESET_INDEX` dual-use convention and `PRESET_INVENTORY` payload structure
come from a reverse-engineered Ampero II Stage capture and public implementation,
using the exact shared command addresses and request/send conventions. This is
protocol-source evidence, not confirmation that the inventory read behaves the
same way on Ampero II Stomp hardware. `0x01080000` still requires read-only Stomp
confirmation; no verified Stomp inventory behavior is claimed yet.

On July 18, 2026, a connected Ampero II Stomp was verified with the official
editor closed:

- Native-library loading and port enumeration succeeded (`input 0`, `output 1`).
- Current-scene request `0x03000001` returned scene `0`.
- Slot-model request `0x01040002` returned an empty slot for slot `0`.
- Complete current-preset request `0x01000000` returned 5,072 bytes.
- Exact patch location `A50-1` mapped to and read back as linear index `150`.
- A twelve-slot preset named `Hana Solo` was parsed with its scene, routing,
  enabled-state, model, and parameter data.
- The formal Skill `device snapshot --include-parameters` completed successfully
  through the compiled bridge.
- Serial routing, a drive-model replacement, and parameter changes were applied as
  a 21-command plan; all 21 writes received immediate verified readbacks.
- The preset-save payload was observed to persist on hardware in one trial even
  when this firmware stopped returning the official save response. The controller
  correctly leaves such a session unverified rather than claiming success.

Write paths remain guarded by exact plan preview, explicit
`--execute --confirm APPLY`, preflight reads, a command whitelist, immediate
readbacks, and rollback journaling. Preset save remains a separate irreversible
step requiring the target-specific `SAVE:Axx-y` token.
