# Campaign state foundation

Status: implemented and tested in isolation, 2026-09-14. Not connected to the main scene or a shipping save slot. No candidate story, NPC, dialogue or quest content is registered.

## Owned files

- `scripts/campaign/quest_definition.gd`: native Resource with `quest_id`, `prerequisite_flags`, `objective_flags`, and optional `completed_flag`.
- `scripts/campaign/campaign_state.gd`: native RefCounted authority for permanent facts, evidence, completed quest IDs, visited regions, result IDs, current region and checkpoint.
- `tests/test_campaign_state.gd`: standalone headless regression with synthetic fixture IDs.

## Contract

Call `configure(catalog, quests)` once on a new instance. The catalog contains arrays `facts`, `evidence`, `regions`, and a `checkpoints` dictionary mapping checkpoint IDs to region IDs. Configuration validates duplicate/invalid IDs, quest references and checkpoint regions, then copies the supplied resources. Facts and evidence share a non-overlapping ID namespace. IDs contain only letters, digits, `_`, `.`, or `-`; entity IDs do not depend on node paths. There are no authored production definitions yet.

Every prerequisite and objective is an AND condition. Completing a quest may append its explicitly registered completion fact. Recalculation repeats until no new quests complete, allowing dependencies to resolve independently of definition order. Facts only accumulate. Alternative decisions require distinct explicit facts and future approved application logic; there is no expression language or interpretation of narrative text.

`apply_event(event)` takes string fields `event_id`, `source_id`, `kind`, `id`, and `result_id`. Kinds are `fact`, `evidence`, `visit`, and `checkpoint`. The target ID must exist in the corresponding catalog. Event/source IDs are syntax-checked, not mapped to scene nodes. The caller assigns a stable unique result ID to each one-time result. A repeated result ID does nothing. Repeated visits/checkpoint activations that should execute again need distinct result IDs; one-time pickup/decision/shortcut results must reuse their original ID. The state does not spawn rewards.

All valid new events first record permanent state, recalculate quests, emit `changed`, then emit `quest_completed(quest_id)` once for each newly completed quest. `quest_status(id)` is read-only and returns `unknown`, `locked`, `active`, or `completed`. `snapshot()` and `encounter_state()` return deep copies. Read-only UI code must use these queries rather than events.

Evidence records immediately, even while a quest is locked. Accepting a quest is an explicit prerequisite fact; existing evidence can then satisfy it without replaying an investigation. Completed outcomes are persisted and validated against their facts on load; quest state is reconstructed without replaying completion signals or external rewards.

`set_encounter_state(dictionary)` keeps temporary combat data separate. `restore_checkpoint()` clears that temporary dictionary, restores the checkpoint's region, returns the checkpoint ID, and preserves permanent facts, evidence, outcomes, discoveries and deduplication IDs. A future scene adapter must map that ID to a position and reset actors, ammo/health policy and projectiles. This module does not currently move the player or rebuild scenes.

## Storage

`save_to(path)` and `load_from(path)` return Godot Error codes. The caller provides a `user://` file path; no default slot is touched. Save schema version is 1, with eight exact top-level fields. Unknown versions, malformed JSON, invalid types, unregistered IDs and inconsistent quest outcomes are rejected before memory replacement. Loading a missing file returns `ERR_FILE_NOT_FOUND`; a failed load leaves both permanent and encounter state intact.

Saving validates the in-memory snapshot and any existing destination, writes and flushes a sibling `.tmp`, closes it and reads it back through the schema validator. It then moves the previous valid destination to `.bak` and renames the validated temporary file into place. If the final rename fails, it attempts to move the backup back to the destination. All operation errors propagate. A backup may be explicitly loaded with `load_from(path + ".bak")`; recovery is not automatic. A missing destination with an existing backup refuses a new save, preserving interrupted-save evidence. Existing corrupt destinations are never silently overwritten.

The save code is synchronous and intended for one owner of a slot. It does not implement multi-process locking, cryptographic integrity, arbitrary player-state serialization or a migration from a nonexistent old campaign save. OS-level power-loss durability and failure of the rollback rename itself are not guaranteed; the backup remains the recovery artifact. Loading a backup does not repair the disk destination. An explicit future recovery UI can handle that separately.

## Verification

Command: `D:/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path D:/recoil-requiem --script res://tests/test_campaign_state.gd`.

TDD evidence: first behavioral run failed `Early evidence completes on acceptance` against the stub; the state implementation passed it. Storage tests then failed missing-save/save assertions against the storage stubs; storage implementation passed. Final isolated run: **34 checks, 0 failures**. Cases include early evidence, later prerequisite, branch order, deduplication, reference validation, copied snapshots, death/checkpoint separation, actual file round trip, malformed/version/type/reference/outcome errors, explicit backup load and backup replacement failure preserving the valid destination. Tests use and clean only `user://campaign_state_test_fixture/`.

No rendered verification is necessary for this isolated nonvisual service. Main gameplay, door/NPC adapters, actual quest UI, region streaming and production saves remain unconnected. The main agent owns adding the fixture to `tools/run_checks.ps1` and running broader checks.

Engine API references checked against current official documentation: [FileAccess](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html), [DirAccess](https://docs.godotengine.org/en/stable/classes/class_diraccess.html). Executed with installed Godot 4.7.2 stable.
