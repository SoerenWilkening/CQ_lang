# BRIEF_prep_b_slices — Inc 1 prep (b): the 66 e2e `.c` rewrites + the new §6.5 slices at PRE-increment dispositions
Read `$SP/briefs/BRIEF_common.md` first. Agent name: `prep_b`. Model: opus.

## Where you work
Worktree `$SP/wt/prep-b`, branch `3qlq-inc1-slices` (from main dfb8e83). You touch
`tests/e2e/*.c` (existing 66 + new), `tests/e2e/CMakeLists.txt` (registrations for the new
slices + `cmp` twin gates), and
`docs/prd/phase-04-swap-route-control/inc1-records/PRE_DISPOSITIONS.md`. You do NOT touch
goldens (`.expected.log`) — they are regenerated after the lowering exists, under the audit.
You do NOT touch `ir-pass/`. You run the ORACLE for pre-increment dispositions.

## The surface change (PRD §4.1)
`x = cq_phi(x, θ);` → `cq_phi(θ);` (one extern `void cq_phi(double)`). Rule for the 66
rewrites: MECHANICAL and FAITHFUL — every `<lhs> = cq_phi(<expr>, <angle>)` statement becomes
`cq_phi(<angle>)` at the same position. Do not delete uncontrolled calls yourself (the pass
deletes them, D2; the source documents intent). When `<lhs>` differs from `<expr>` (e.g.
`b = cq_phi(a, θ)` — a rename through the gate) the rewrite must add `b = a;` so data flow is
preserved; flag every such site in the report. When the old call was a `bool`/`i1` phase on
a compare result (the explicit-ancilla kickback spelling, e.g. `bool m = (q==5);
m = cq_phi(m, PI);`) rewrite to `if (q == 5) cq_phi(PI);` and flag it.
For each rewritten slice add ONE header line: `// 3qlq Inc 1: migrated to register-free
cq_phi (<what changed>)`. For every `slice_control_*grover*` slice the header gets the
FINDING (PRD §1): the pre-3qlq golden encoded a controlled TENSORED Rz = the identity on q;
"oracle: mark |5>" is TRUE only from Inc 1 on. Do not silently rewrite old comments that
claimed the oracle worked — append the correction.

Population: `grep -l 'cq_phi' tests/e2e/*.c` (66 at HEAD). Some are NOT control slices
(`slice_bitint.c`, `slice_f80.c`, `slice_intrinsic_*.c`, `slice_uncompute_dead_*.c`,
`slice_loop_phase_accum.c`, `spec_*_caller.c`, …): there the Rz was an in-place gate used to
keep a chain/taint shape; read each header and say in the report whether the slice's
PURPOSE survives the deletion (the pass deletes the uncontrolled call; the data flow is the
same handle). If a slice's purpose was the Rz gate itself, keep the call (it becomes a
deleted global phase) and note that the golden will lose that line — the audit's
substitution (c).

## New slices (PRD §6.5) — write the `.c`, register in CMakeLists.txt, NO golden yet
- `slice_control_phase_grover.c` (flat; 2 Grover iterations hand-written: `q = cq_theta(q,.3);
  if (q == 5) cq_phi(PI); q = cq_theta(q, .3); if (q == 0) cq_phi(PI);` ×2, then measure),
  `slice_control_phase_grover_loop.c` (the same as `for (i < K)`, K=3) and
  `slice_control_phase_grover_loop_unrolled.c` (hand-unrolled twin) + a `cmp` twin gate
  (copy the pattern of `e2e-cmp-...` / `compare_files` gates around CMakeLists.txt:579).
- `slice_control_phase_perbit_loop.c` (D4's idiom, K=4): `for (i<4) if ((q >> i) & 1)
  cq_phi(.3);` and `..._perbit_loop_unrolled.c` (K=4 by hand), `cmp` gate; plus
  `slice_control_phase_perbit_loop_k32.c` (K=32, rolled only — the K-independence witness).
- `slice_control_phase_nest.c` (`if (q == 5) { if (r == 3) cq_phi(.3); }`) vs
  `slice_control_phase_andcond.c` (`if (q == 5 && r == 3) cq_phi(.3);`) + `cmp` gate
  (byte-identical by construction: `-O1` folds both to `select i1 %a, i1 %b, false`).
  ALSO a genuine nest that survives SimplifyCFG's fold threshold (inner block carries a
  `cq_theta` on a third register before the inner compare): `slice_control_phase_nest_deep.c`.
- `slice_control_phase_angle_select.c` (`if (q==5) cq_phi(.9); else cq_phi(.3);`) and
  `slice_control_phase_angle_select_runtime_arms.c` (angles are function PARAMETERS).
Every new slice: a header stating the shape, the expected trace SHAPE in words (e.g.
"flag mint → cqrt_rz_i1 → _unc → free per region, no cswap, no _controlled"), and the
PRE-increment disposition (measured, next step).

## Pre-increment dispositions (Rule 16 — the record the increment's diff is measured against)
For EVERY rewritten and new slice, run stage 1 (`clang -O1` with the NEW header — you must
temporarily use a header with `void cq_phi(double);`: put a copy of `include/CQ.h` with the
15-width family replaced by the one extern under `$SP/progress/prep_b_include/CQ.h` and
`-I` that; do NOT commit a CQ.h change — the implementer owns it) and then the ORACLE
cq-opt. Record in `PRE_DISPOSITIONS.md` one row per slice: file | pre-increment result
(exit code + exact diagnostic string, or "accepts, N trace lines") | expected post-increment
class (P1/P2/P3/P4/P5/P6/P7 or decline row of §6.3). Expect the oracle to DECLINE everything
with a `cq_phi(...)` under tainted control (unknown call) and to accept the rest with the
uncontrolled Rz lines GONE from stage 1's IR already? — no: with the void extern the call
survives stage 1 as `call void @cq_phi(double)`; the ORACLE treats it as an unknown external
call → measure what it does and write it down exactly.

## Commit
Two commits on your branch: (1) the 66 rewrites + headers, (2) the new slices + CMake +
PRE_DISPOSITIONS.md. Hand back per BRIEF_common with the counts and the list of flagged sites.
