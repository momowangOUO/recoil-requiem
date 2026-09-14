# V claw melee

Implemented 2026-09-14. V requests one emergency claw strike per press, on the ground or in the air. No player-visible narrative wording is added.

| Parameter | Value |
| --- | --- |
| Windup / hit period / recovery | 0.08 / 0.08 / 0.22 seconds |
| Start-to-start cooldown | 0.65 seconds, owned by player rather than gun |
| Base damage / impulse | 35 / 260; existing enemy mass and zone multipliers apply |
| Attack box | 24×26 logical pixels, forward of torso at y=-24 |
| Lunge contribution | At most 22 horizontal logical pixels over hit period |

The attack snapshots starting facing and source position. Mouse aim cannot redirect an active strike. The lunge uses collision-tested additional displacement, so existing recoil velocity is preserved; ordinary movement, gravity and jump physics still apply. No Y impulse, invulnerability, target lock, ammunition use or `shot_fired` event is introduced. Only one airborne lunge assist is available before landing; later airborne claw attacks still work after cooldown but add no movement. Ground motion or recoil can make total travel greater than the 22-pixel claw contribution.

During the hit period, samples at no more than 4-pixel spacing cover the actual movement path. Each sample queries enemy areas and checks stone-wall occlusion. Hits are deduplicated by receiver, including overlapping body and weakpoint areas. Shield front reduction, back damage, exposed weakpoints, mass-based push and hurt reactions are delegated to existing `receive_hit` logic. Open grating does not occlude the attack.

Priority: death and accepted damage cancel melee immediately. Damage keeps the remaining cooldown and air-lunge usage. Hurt stun rejects V without buffering it. A valid V press has priority over shooting and reload on the same frame; shooting/reload remain blocked through recovery. Switching slots is allowed, but does not reset melee or its cooldown. Reload cancellation discards incomplete progress while keeping already loaded shells. A V press rejected by cooldown does not prevent otherwise valid gun input. Pause freezes the active animation and cooldown; pause/resume and window focus loss use the existing input suppression path to require release of a held V. Production respawn resets melee state; full trial reset creates a fresh controller.

Artwork and source prompts: `assets/characters/requiem/CLAW_MELEE_V1.md`. Existing v5 body and independent authored sleeves are retained.

Verification:

- `tests/test_claw_melee.gd`: 111 checks at time of implementation, covering controller timing, ground/air lunge, recoil preservation, fast path crossing, wall blocking, ammo/shot exclusion, switching cooldown, shell reload cancellation, damage/death/respawn/pause, actual V events and held-key suppression, shield and weakpoint behavior, both facings and authored sleeve lengths across the action.
- `tests/test_arm_rig.gd`: 5627 checks for the existing gun rig passed after this change.
- `tests/capture_claw_melee.gd`: production stage capture, windup / strike / recovery in both directions. Output is under `artifacts/claw/`, including 640×360 native-world captures.
- `tools/run_checks.ps1` includes the melee fixture. Whole-project regression and Windows export are performed by the coordinating task after integration.

Red/green evidence: `artifacts/claw-red-behavior.log` recorded 10 failed behavior checks before implementation; `artifacts/claw-rig-red.log` caught 22 overextended sleeve poses before wrist reach was corrected. Final isolated result is in `artifacts/claw-final.log`.
