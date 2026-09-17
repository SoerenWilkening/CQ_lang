# GATES_B — Wave 0-B, session 2026-09-18 (bead closure by measurement)

Binary under every line below: `build/ir-pass/cq-opt` sha256
`9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3`
(verified by `shasum -a 256` at session open, before any measurement; matches
`$SES/PROTOCOL.md`'s ORACLE block exactly).

Format (PROTOCOL.md): `<gate> | <hash16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>`

## CITED, not re-run (PROTOCOL §6.1 — same hash ⇒ same result)

```
lit --filter 'acyclic_nondominated|backedge_.*desc_collider' | 9bd01598d574b344 | 6 passed / 0 failed | cited: $THIS/GATES.md line 11 (claude, 2026-09-17 10:50)
```

## RAN

```
shasum -a 256 build/ir-pass/cq-opt | 9bd01598d574b344 | 9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3 — MATCHES the PROTOCOL oracle block | wave0-B | 2026-09-17 11:40
probe fve8_direct (int main(void){int u; return cq_measure(u);}) | 9bd01598d574b344 | opt exit=0, stderr 0 bytes; 2b "0 rail mint(s) of which 0 left allocated, 0 template rail mint(s) of which 0 left dirty, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven"; 0 trace lines | wave0-B | 2026-09-17 11:45
probe fve8_zero (written-zero twin) | 9bd01598d574b344 | opt exit=0, stderr 0 bytes; identical 2b line; 0 trace lines | wave0-B | 2026-09-17 11:45
REFINEMENT diff fve8_direct vs fve8_zero, -O1 (no -g), ModuleID+source_filename stripped | 9bd01598d574b344 | EMPTY — lowered modules BYTE-IDENTICAL; both are `define i32 @main() { ret i32 0 }` | wave0-B | 2026-09-17 11:47
probe fve8_e9_quantum (int u; int q=cq_theta(0,0.3); return cq_measure(q+u);) | 9bd01598d574b344 | opt exit=0, stderr 0 bytes, 2 trace lines, NO cqrt_measure in the module — the E9/F-E2-1 ruled behaviour | wave0-B | 2026-09-17 11:48
probe fve8_e9_zerotwin (int u = 0) | 9bd01598d574b344 | opt exit=0, 3 trace lines, WITH cqrt_measure_i32(h0) | wave0-B | 2026-09-17 11:48
lit --filter lowering_accept_measure_undef_zero | 9bd01598d574b344 | 1 of 2082 run, 1 Passed, 0 Failed | wave0-B | 2026-09-17 11:50
lit --filter lowering_reject_measure_undef_global_init | 9bd01598d574b344 | 1 of 2082 run, 1 Passed, 0 Failed | wave0-B | 2026-09-17 11:50
lit --filter lowering_reject_measure_undef_operand | 9bd01598d574b344 | 1 of 2082 run, 1 Passed, 0 Failed | wave0-B | 2026-09-17 11:50
lit --filter (kqqv 6-fixture batch: control_predmux_*) | 9bd01598d574b344 | 6 of 2082 run, 6 PASS, 0 FAIL, 6.09 s | wave0-B | 2026-09-17 11:52
probe slice_control_cascade_three_bools (the headline slice, for bd 8h7d.6) | 9bd01598d574b344 | opt exit=0; 2b "9 rail mint(s) of which 7 left allocated, 2 template rail mint(s) of which 1 left dirty, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven" | wave0-B | 2026-09-17 12:05
probe p58tc (bead 58tc's own witness, K=3 — clang -O1 UNROLLS it) | 9bd01598d574b344 | opt exit=0, stderr 0 bytes, 18 trace lines | wave0-B | 2026-09-17 12:15
probe p58tc_k100 / p58tc_rt (rolled) | 9bd01598d574b344 | BOTH opt exit=0, stderr 0 bytes; lowered module K-INDEPENDENT 73 lines at K=100 and K=1000; rolled(n=3) trace RAW BYTE-IDENTICAL to the unrolled K=3 trace, 18 = 18 | wave0-B | 2026-09-17 12:18
probe p58tc_unobs (post-gate record z, never observed) | 9bd01598d574b344 | opt exit=0 with 441 bytes stderr: 2 x warning "cq rotation lowering: non-diagonal gate over a live derived record" | wave0-B | 2026-09-17 12:22
probe p58tc_obs (z OBSERVED in body) | 9bd01598d574b344 | opt exit=0 with 437 bytes stderr — SAME warning; the in-body observation did NOT exempt | wave0-B | 2026-09-17 12:22
probe p58tc_obs_all (z, q and w ALL observed in body) | 9bd01598d574b344 | opt exit=0 with 445 bytes stderr — STILL WARNS. Decisive for bd 58tc | wave0-B | 2026-09-17 12:24
```

## NOT RUN, deliberately

No build, no `ctest`, no `ir-pass-lit`, no `^e2e-`, no corpus sweep, no matrix.
Wave 0-B builds nothing and edits no source, fixture or test. `ctest -R
'^e2e-free-pairing-selftest$'` and `ctest -R '^e2e-loop-twin-quarantine-selftest$'`
were IN-FLIGHT under wave0-A at this hash when Wave 0-B needed evidence about
`free_pairing_check.py`; per §6.1 Wave 0-B did NOT start a second run and took its
evidence from the per-probe pipeline instead.
