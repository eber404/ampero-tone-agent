# Patch Inventory Design

## Problem

The current-preset response describes the live edit buffer. Its embedded name can
remain from the previous loaded preset when the hardware display points at an empty
slot. Treating that name as the selected slot name reports stale state.

Target selection also regressed from `PRESET_INDEX` (`0x00090000`) to
`PRESET_CHANGE` (`0x03000003`). Protocol evidence shows that `PRESET_INDEX` is the
shared address for reading the selected index and loading an indexed patch; request
flags and payload distinguish those operations.

## Design

Restore target loading through `PRESET_INDEX` with a four-byte index payload. Keep
the exact index readback requirement. `_read_patch_index` rejects indices `>= 300`;
`parse_patch_label` constrains labels to `A(\d+)-([1-3])` by regex, so `A100-1`
(index 300) is rejected by range check even though the label format parses.

Add the read-only preset inventory command at `0x01080000`. The 5700-byte payload
contains a 600-byte index/order table followed by 300 zero-terminated 17-byte
names. The implementation intentionally skips the index table and uses positional
mapping: name at position `i` corresponds to preset index `i`. Expose a
`device patches` operation so the agent can list all destination candidates
without loading patches. The inventory carries no occupancy flag; names like
"Empty" are string values only and do not prove a slot is empty.

During `device snapshot`, retain the current-preset name as `edit_buffer_name` and
report the selected inventory entry as `patch_name`. Keep `preset_name` for current
callers, but source it from the inventory when patch location and inventory are both
available. `edit_buffer_name_matches_patch` compares names only and does not prove
content equality; absence or parse failure must remain explicit rather than silently
proving identity.

## Safety

Inventory and snapshot additions use request-only operations. They never select,
modify, apply, save, delete, or send raw arbitrary messages. Automatic selection
keeps existing warning, explicit plan approval, target readback, and journaling.

## Testing

Regression tests must first fail with the current code. They cover the exact target
selection address, inventory parsing, patch listing, snapshot name separation, and
malformed inventory rejection. Existing full tests and `git diff --check` remain
required before completion. New plan files are untracked and appear in
`git status`, not in `git diff` against HEAD.
