# Six-slot Weapon Switching Implementation Plan

**Goal:** Make the numbered arsenal itself the only weapon-slot model: six fixed slots, direct 1–6 selection, and Q/wheel cycling through every occupied slot.

**Architecture:** `InputFrame` carries a direct-select index. `KeyboardInput` maps top-row numbers. `WeaponController` owns a fixed six-entry array containing persistent runtimes or explicit empty entries. The HUD renders the same six-entry inventory model.

**Tech Stack:** Godot 4.7.2, GDScript, native InputMap and existing no-dependency SceneTree tests.

### Task 1: Specify controller behavior

- [x] Add failing checks for six slots, three occupied entries, three empty entries, direct selection, cooldown persistence, and Q cycling across all occupied entries.
- [x] Run the focused core test and confirm the old two-quick-slot API fails the new contract.

### Task 2: Implement input and runtime selection

- [x] Install and sample `weapon_1` through `weapon_6`.
- [x] Build six fixed slots, route number keys and cyclic selection through one helper, and retain per-weapon ammo, cooldown, and reload interruption rules.

### Task 3: Update HUD, replay, and docs

- [x] Remove quick-slot editing and pass a six-entry inventory snapshot to the HUD.
- [x] Show occupied, empty, and selected slot states while retaining current ammo and reload feedback.
- [x] Extend the engine-event replay for direct selection, empty-slot rejection, state persistence, and Q cycling.
- [x] Document the new controls and inventory model.

### Task 4: Verify and publish

- [x] Run `tools/run_checks.ps1`, rendered replay, and `git diff --check`.
- [x] Commit the verified change, push `main` to the existing private origin, and verify the remote head.
