# Fix brief — Track A.1, after round-1 Rule-13 review `review_a1_r1.md` (verdict BLOCK)

Worktree `/Users/sorenwilkening/Desktop/CQ_trackA`, branch `compare-select-parity`. Read `review_a1_r1.md`
in full, then `IMPL_A1.md` (§7 O-1..O-7), `BRIEF_A1.md`, and the reviewer's probes
(`review_a1_r1_probes/`, `run.sh`, README). You are the FIX agent (opus). Do NOT commit/push; never write
under `/Users/sorenwilkening/Desktop/CQ_lang/` or the other worktrees; the ORACLE stays
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` + `libCQPass.so`. Report only what you ran.

## F-A1-1 — CONFIRMED-MISCOMPILE, the BLOCKER (fix first)

`k7_caller.c` + `lib3.c` (two TUs): the increment's own `k8` decline plus ONE line, `int b2 = cq_theta(b,
-0.25)` (the S† shape), ACCEPTS on the subject byte-identical to the oracle — `ry(%out,.25); ry(%out,.9);
icmp_sgt(%out,1); rz_i1` — bd `9pum` verbatim. Cause (`ArmClassify.cpp:2343`): `reverifyCmpCondReads`
asks rung (iii) only when "taint-aware DIRTY ∧ taint-blind CLEAN", but `findNonDiagonalWireGate` returns
ONE gate, so a gate visible taint-blind (the S†, which `condWireDisposition`'s DT prong at `:1722`
ACCEPTED positionally at round 1 as `ProvenPostRegion`, consumers `:2724` and `:4595`) suppresses the
re-ask about a DIFFERENT gate only round-2 taint reveals (the sibling `.9`). "The classifier ruled on it"
≠ "declined". `k9` (the same extra line on ANOTHER register) declines — the fence is defeated by making
the wire DIRTIER.

Fix as the reviewer sketches: compare gate SETS, not booleans. Compute the set of non-diagonal gates on
the wire taint-BLIND (what round 1 could see and ruled on) and the set taint-AWARE at final taint; any
gate in the aware set that is NOT in the blind set is NEW and must be re-asked position-free (declining
`condition predates a non-diagonal gate`) — i.e. an EXEMPT set on the walk (gates the round-1 ruling
covered), never a boolean. If `findNonDiagonalWireGate` cannot enumerate, add an enumerating variant
(same walk, collect instead of return-first) and use it for BOTH sets — one spelling (Rule 14). Pin with
`k7`+`lib3` as a two-TU decline (lit hand IR from the linked module, and a plain-C `probes/` entry with
both TUs), `k8`, `k9`, and a control where the ONLY gate is the S† (must stay ACCEPT — the S† after a
compare PHASE region is a shipped accept; the S† after a compare SELECT declines on `main` and is A.2's —
must not move either way here). Re-run the reviewer's 12 in-loop accepts that the earlier
"unconditional re-ask" spelling cost (IMPL §5) — the set-diff must not cost them; if it does, the exempt
set is too small and you widen the EXEMPT set with the round-1-visible gates, not the suppression.

## F-A1-2 — the widening the corpus could not see: pin it and correct the record

`b1.c` / `b2.c` (bare `_Bool`, iteration-local register in a loop) went DECLINE → ACCEPT on the shared
rail helper because of the per-activation barrier (O-7). The reviewer judged both CORRECT
(`cqrt_alloc_i1` inside the body — measured). Add both as lit ACCEPT fixtures (`control_swap_select_rail_inloop_iterlocal_measure_after.ll`
and the kickback twin) with headers stating exactly why the accept is right (the register is re-minted
each trip; the measurement is of the PREVIOUS trip's rail), with `ACNT`/`MCNT` counts per activation,
and an e2e slice pair (rolled + hand-unrolled, `compare_files` twin gate) if the traces are byte-identical
— measure first. Then correct BRIEF §1 / IMPL §5's "decline-monotone" claim: the increment is
decline-monotone on the COMPARE path and has exactly these two rail-path ACCEPT movers, by name.

## F-A1-3 — OVER-DECLINE: narrow the cone to the direct tainted operands' WIRES

`c1`,`c2`,`c9`,`c10`: `int t = q + 3; int m = cq_measure(q); int a = (t == 5) ? …` declines although the flag
reads `t`, a SEPARATE rail (out-of-place add), never the measured `q`; the mirror (`c7`,`c8`: measure the
derived rail, control the parent) accepts on both binaries. Seed rung (ii) from the compare's DIRECT
tainted operands (BRIEF §1.1's spelling) and their WIRE closure (`railWireNamesBackward` — the chained-
theta relation), NOT from the whole `condProvenance` cone. ⚠ The wire question must still cover an
IN-PLACE relabelling: `int t = q + 3` lowered IN PLACE by M-C (dtzb `cqrt_addc`) is `q`'s rail renamed —
MEASURE which of `c1`/`c2`/`c9`/`c10` is in place vs out of place on the subject (`cqrt_addc_i32` vs
`cq_template_add_i32_hl` in the trace) and make sure the in-place case still DECLINES (the measured
register IS the flag's rail). If `railWireNamesBackward` does not follow `taint.InPlaceRailOps`, extend it
by asking that set (one spelling — the same set `staleRailRecordRead` uses), and pin both faces. The
narrowing must cost 0 movers over the 1776 (IMPL said direct-operands = 0 movers; re-measure).

## F-A1-4 — pre-existing, FILED by the orchestrator (bd issue created 2026-09-11; grep `bd list` for
"SWITCH mints its eq-flags from a MEASURED scrutinee"). Add the reviewer's `sw1.ll`/`sw2.ll` under
`probes/` with a README line pointing at the issue; no code.

## F-A1-5 — DOC ×3

(a) mark `if (Seeds.empty()) continue;` in `reverifyCmpCondReads` as the one place that fails toward
ACCEPT, with the argument why an empty seed set is safe there (or change it to decline if it is not —
measure); (b) record O-5 as measured unreachable (`sp1`/`sp2` decline in the specializer) in IMPL §7;
(c) state in the compare ladder's header that it is strictly WEAKER than the rail twin at rung (iii)
(position-free only, no DT prong — A.2's) so nobody reads parity as equality.

## Gates, in order

`lit --filter` per fixture → `ctest -R ir-pass-lit` → `ctest -j6 -R '^e2e-'` + `git status --porcelain
tests/` → the corpus diff over the 1776 (expect `0/0/0` on the compare path; list the rail movers) →
re-run `review_a1_r1_probes/run.sh` and the implementer's `probes/` (every verdict listed; `k7` must be
DECLINE, `c1/c2/c9/c10` ACCEPT unless in-place, `b1/b2` ACCEPT) → full `ctest -j6` ONCE (this is a
Rule-13-core change; never relink under a running measurement, never `pkill` by pattern) →
`cq-opt-equivalence-full`. Append `FIX_A1_R1.md` beside this file: per finding → change (file:line) →
fixtures → measurements; then the round-2 open questions.

Final message ≤30 lines: per finding one line (what changed, where, measured outcome), the gate lines
verbatim, movers, open questions.
