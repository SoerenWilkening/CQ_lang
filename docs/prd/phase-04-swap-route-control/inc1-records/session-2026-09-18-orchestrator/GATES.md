# GATES — session 2026-09-18 (session-level index; per-track files are authoritative)

Format: `<gate> | <cq-opt sha256 first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>`. A gate recorded
here or in any track's `GATES.md` at the hash on disk is CITED, never re-run (PROTOCOL §6.1).

## ORACLE = main cff8f7ac..b1b1dc02 (pass source unchanged since 95949550): cq-opt 9bd01598d574b344

| gate | cq-opt | result | who | when |
|---|---|---|---|---|
| shasum build/ir-pass/cq-opt at open | 9bd01598d574b344 | matches the brief §6 | orchestrator | 2026-09-17 11:30 |
| Wave 0-A per-bead measurements (7 beads) | 9bd01598d574b344 | see `wave0/GATES_A.md` — e2e-loop-twin-quarantine-selftest Passed 2.42 s (52 cases), e2e-negative-vacuity-selftest Passed 22.65 s, e2e-free-pairing-selftest run once | wave0-A | 2026-09-17 |
| Wave 0-B per-bead measurements + 57-bead sweep | 9bd01598d574b344 | see `wave0/GATES_B.md` — 6 kqqv fixtures 6/6, fve8 direct/twin byte-identical, 8h7d.6 census live | wave0-B | 2026-09-17 |
| Group-1 scoping per-probe (a1_apost etc.) | 9bd01598d574b344 | see `trackT2/GATES.md` | scoping | 2026-09-17 |
| review_r13_loopconv per-probe (≈40 probes) | 9bd01598d574b344 | see `review_r13_loopconv/GATES.md`; verdict FINDING (F-1 = bd 6n1s) | reviewer | 2026-09-17 |
| e2e-loop-twin-matrix (382 cells, after Track V) | 9bd01598d574b344 | Passed 618.77 s, 0 failed (load 32–52) | trackV | 2026-09-17 |
| e2e-loop-twin-quarantine-selftest (58 cases) | 9bd01598d574b344 | Passed 1.72 s | trackV | 2026-09-17 |
| main ff to b1b1dc02 (Track V, tools-only); cq-opt re-hashed | 9bd01598d574b344 | unchanged (no pass source in the diff) | orchestrator | 2026-09-17 |

NOT run at this hash by anyone so far: full `ctest -j6`, `ir-pass-lit`, `^e2e-`, `cq-opt-equivalence-full`, a corpus sweep.
Per Rule 19 the full suite is owed at the group landing(s) and at close; a tools-only landing whose compiler is
byte-identical cannot be witnessed by the pass layers, and the closing full run covers the harness change.

## Track X (PARKED, not on main) — subject cq-opt 677472eb67a0b2ea (branch x5fp-clobber-per-activation @ 69414276)

| gate | cq-opt | result | who | when |
|---|---|---|---|---|
| pre-edit worktree build | 9bd01598d574b344 | reproduced the oracle byte for byte | trackX | 2026-09-17 |
| ctest -R ir-pass-lit | 677472eb67a0b2ea | 1/1 Passed 82.53 s, 2087 fixtures | trackX | 2026-09-17 |
| corpus sweep ORACLE-vs-SUBJECT | 677472eb67a0b2ea | PARTIAL — recorded as an ABSENCE: 1744/6446 rows (all ir-pass/test/*.ll), 2 movers = its own new fixtures, 0 pre-existing moved; earlier 564-row probe sample 7 movers all the expected §3c → value-arm swap-route; load 639/692 | trackX | 2026-09-17 |
| a FIRST sweep was relinked under; killed BY TASK ID, output deleted, not reported | 677472eb67a0b2ea | correct handling of the Rule-19 trap (recorded, not a gate) | trackX | 2026-09-17 |

## FINAL — main 014b4381, primary rebuilt ONCE at close: cq-opt 07d937842bfb5135 (bit-identical to the gate worktree's)

| gate | cq-opt | result | who | when |
|---|---|---|---|---|
| full `ctest --test-dir build -j6` (gate worktree, final) | 07d937842bfb5135 | 459/459 in 515.58 s, load 47→5; matrix Passed 280.63 s | merge-and-gate | 2026-09-17 |
| `cq-opt-equivalence-full` (pass 2) | 07d937842bfb5135 | 2099/0 | merge-and-gate | 2026-09-17 |
| corpus sweep ORACLE-vs-SUBJECT (pass 2) | 07d937842bfb5135 | 7010 rows, 156 movers, 0 unattributable, A→D 6 (all 6n1s), D→A 87 (all D) | merge-and-gate | 2026-09-17 |
| primary `cmake --build build -j8` at close + shasum | 07d937842bfb5135 | bit-identical to the gated binary (libCQPass 19dcfde08ffbb69c) | orchestrator | 2026-09-17 18:14 |
| owner's loop program on the closing primary | 07d937842bfb5135 | exit 1, 91:15 `control flow inside a loop body under quantum control` — unchanged | orchestrator | 2026-09-17 18:15 |
| tree counts (`ctest -N` / `ls` / `grep`) | 07d937842bfb5135 | 459 · 449 · 392 · 43 · 2099 · 394 · 449 · 312+70 | orchestrator | 2026-09-17 18:15 |
Per-track detail: `trackT2/GATES.md`, `trackD2/GATES.md`, `trackC/GATES.md`, `trackV/GATES.md`, `trackX/GATES.md`, `gate/GATES.md`, `review_r13_*/GATES.md`.
S2 citation for the closing full suite: the tree is identical to the gate branch's tip (fast-forward) and the rebuilt binary hashes equal — the suite is CITED from the gate's final line, not re-run.
