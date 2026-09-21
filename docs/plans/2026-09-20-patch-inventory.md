# Patch Inventory Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Correct target selection and distinguish the selected slot name from the live edit-buffer name using one read-only inventory request.

**Architecture:** Keep the vendor-library transport boundary unchanged. Add one documented request address and a bounded parser for the Ampero family's 300-entry inventory, then let `DeviceController` enrich snapshots and expose labeled patch entries. Preserve degraded snapshot behavior by reporting inventory errors explicitly.

**Tech Stack:** Python 3, `unittest`, existing Dart bridge/vendor native library.

---

### Task 1: Restore Correct Target Selection

**Files:**
- Modify: `tests/test_controller.py:123-126,546-586`
- Modify: `src/ampero_control/controller.py:435-450`

**Step 1: Write the failing regression test**

Make `FakeTransport.send` update its selected index only for `Command.PRESET_INDEX`.
Assert auto-selection sends exactly:

```python
(int(Command.PRESET_INDEX), pack_int(150, 4), int(MessageFlag.SEND))
```

Also assert no `Command.PRESET_CHANGE` message exists.

**Step 2: Run test and verify RED**

Run: `.venv/bin/python -m unittest tests.test_controller.ControllerTests.test_apply_can_auto_select_unknown_target_patch`

Expected: failure because production sends `PRESET_CHANGE`, so readback remains unknown.

**Step 3: Implement minimal correction**

Change `_select_target_patch` to send `Command.PRESET_INDEX`. Remove the unsupported `PRESET_CHANGE` enum member if no code uses it.

**Step 4: Run targeted test and verify GREEN**

Run the same command. Expected: one passing test.

### Task 2: Parse Patch Inventory

**Files:**
- Modify: `src/ampero_control/constants.py`
- Modify: `src/ampero_control/preset.py`
- Modify: `tests/test_preset.py`

**Step 1: Write failing parser tests**

Build a 300-entry fixture containing a 600-byte index table followed by 300 fixed 17-byte names. Assert `parse_patch_names` returns exactly 300 decoded names and rejects a payload shorter than 5,700 bytes with `PresetFormatError`.

**Step 2: Run tests and verify RED**

Run: `.venv/bin/python -m unittest tests.test_preset.PresetParserTests.test_parses_patch_names tests.test_preset.PresetParserTests.test_rejects_short_patch_inventory`

Expected: import failure because `parse_patch_names` does not exist.

**Step 3: Implement minimal parser**

Add `Command.PRESET_INVENTORY = 0x01080000`. Add constants for 300 entries, two index bytes, and 17 name bytes. Validate minimum payload size, skip the 600-byte index/order table (intentionally ignored; positional mapping is used instead), decode each zero-terminated name with existing `_text`, and return a tuple.

**Step 4: Run parser tests and verify GREEN**

Run the same command. Expected: two passing tests.

### Task 3: Expose Inventory and Separate Names

**Files:**
- Modify: `src/ampero_control/controller.py:111-162`
- Modify: `src/ampero_control/cli.py:35-50,140-199`
- Modify: `tests/test_controller.py`
- Modify: `tests/test_cli.py`

**Step 1: Write failing controller tests**

Teach `FakeTransport` to answer `PRESET_INVENTORY` with an inventory whose selected slot is named `Empty` while `CURRENT_PRESET` remains `Fixture`.

Assert `controller.patches()` returns labeled records and snapshot reports:

```python
snapshot["patch_name"] == "Empty"
snapshot["preset_name"] == "Empty"
snapshot["edit_buffer_name"] == "Fixture"
snapshot["edit_buffer_name_matches_patch"] is False
snapshot["preset_name_source"] == "patch_inventory"
```

Add an inventory-timeout transport. Assert snapshot survives, preserves the edit-buffer name, sets `preset_name_source` to `edit_buffer_unverified`, and includes `patch_name_read_error`.

Add an out-of-range selected-index transport. Assert index `300` is rejected,
snapshot remains degraded with `edit_buffer_unverified`, and no inventory request is
made. Valid indices are `0..299`, labeled `A00-1..A99-3`.

**Step 2: Run tests and verify RED**

Run targeted controller tests. Expected: missing method/fields.

**Step 3: Implement minimal controller behavior**

Add `_read_patch_names`, `patches`, and snapshot enrichment. Inventory failures must be caught as `AmperoError`; malformed payload errors remain explicit. Validate the selected index before indexing the inventory. Do not perform writes or target selection.

**Step 4: Add CLI parser coverage**

Add `device patches` and assert `build_parser().parse_args(["device", "patches"])` selects it. Route it to `DeviceController.patches()`.

**Step 5: Run targeted tests and verify GREEN**

Run: `.venv/bin/python -m unittest tests.test_controller tests.test_cli`

Expected: all targeted tests pass.

### Task 4: Document Compatibility and Verify

**Files:**
- Modify: `docs/protocol.md`
- Modify: `README.md`
- Modify: `skills/ampero-tone/SKILL.md`
- Modify: `skills/ampero-tone/references/conversation-flow.md`
- Modify: `docs/plans/2026-09-20-patch-inventory-design.md`
- Modify: `docs/plans/2026-09-20-patch-inventory.md`

**Step 1: Document behavior**

Document `0x00090000` request/send dual use, `0x01080000` inventory read, name-source fields, destination inventory workflow, and that inventory evidence came from reverse-engineered Ampero II Stage capture/public implementation using the exact shared address conventions but still needs read-only Stomp hardware confirmation.

**Step 2: Run full verification**

Run: `make mac-test`

Expected: zero failures.

Run: `rtk git diff --check`

Expected: no whitespace errors.

**Step 3: Review scope**

Run: `rtk git diff -- src/ampero_control/constants.py src/ampero_control/controller.py src/ampero_control/preset.py src/ampero_control/cli.py tests/test_controller.py tests/test_preset.py tests/test_cli.py docs/protocol.md README.md skills/ampero-tone/SKILL.md skills/ampero-tone/references/conversation-flow.md`

The plan files `docs/plans/2026-09-20-patch-inventory-design.md` and
`docs/plans/2026-09-20-patch-inventory.md` are newly added and untracked; they
appear in `git status` output, not in `git diff` against HEAD.

Confirm no hardware operation ran and unrelated Windows/example changes remain untouched.
