# BRIEF_fix_r1 — Inc 1 part A, Rule-13 ROUND-1 FIX agent
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_impl_inc1a.md`, `$SP/progress/impl_inc1a.md`,
then the lens reports as they exist: `$SP/progress/review_r1_L7.md` (READ IT FULLY — it carries
the round's CONFIRMED miscompile with the root cause and the fix plan), and later
`review_r1_L1/L2/L3/L5.md` (the orchestrator will SEND you each new report; act on each
CONFIRMED / OVER-DECLINE / DOC finding). Agent name: `fix_r1`. Model: opus.

## Where you work
Worktree `$SP/wt/fix-r1`, branch `3qlq-inc1-fix-r1`, created from `fa96336`. Build it in the
background FIRST (both targets, ~6 min). SUBJECT-BEFORE = the main checkout's binary (do NOT touch
main — lenses are still running against it); ORACLE = `$SP/wt/pre-3qlq`. Every reproducer
runs on your binary, on main's binary and on the oracle (old surface).

## F-L7-1 — CONFIRMED MISCOMPILE: the spine adjoints the kickback gate on the ShareCondFlag path
Reproducer `$SP/progress/review_r1_L7/probes/j3_sharecond_measure_only.c`: `int b = (a==5);
if (a==5) cq_phi(.25); return cq_measure(b)+cq_measure(a);` → subject emits `rz_i1(h1,+θ)` … `zext`
… `rz_i1(h1,−θ)` (the whole-DAG spine's adjoint) — the phase is cancelled EXACTLY; the oracle
keeps its gate. Root cause (L7 §F-L7-1): `cqrt_rz_i1(f,θ)` now means "the program's ANSWER kicked
back onto an ancilla" and three spine predicates still read it as a chain gate:
`ChainWalk.cpp:226` (`isInPlaceGateOn` admits the uncontrolled rotation), `ChainWalk.cpp:459`
(`preservesBasisUnderRecord` returns true → interior candidate at `:694` and adjointable at
`Uncomputation.cpp:941`), `EmitInverse.cpp:47/:191` (emits the negated twin). The emitter
(`SwapRouteEmit.cpp:1449` `emitArm`, `:1477` merge-tail loop, and the AngleSelectEmit Rz-stem
site) records the gate NOWHERE.
FIX (L7's plan, which the orchestrator endorses): record every emitted kickback gate in a new
`TaintSet` image (`taint.BranchPhaseGates`) at all three emission sites, the way
`DischargedFlagGates` is recorded; make it OPAQUE to the spine at the three predicates BY
MEMBERSHIP (not by name); a gate the spine cannot recognise → `D.NotClosed` → the flag rail is
LEFT ALLOCATED on the ShareCondFlag path (Rule-6 safe; byte-for-byte the oracle's disposition on
`j3_old`). THEN — the 8h7d.5 F-1/F-3 lesson, mandatory — enumerate what ELSE is computed over
the same closure and write a decision for each: `railOf`, `isTerminalHandle`,
`isInteriorTerminalHandle` (I1/I3), `DagTraversal` step-1 `D.Calls` + step-3 closure,
`Uncomputation`'s moved-anchor scan + clause (d), `preservesBorrowedParent` (1b), the 7.4
`lowerBreakReversePlay` capture, `free_pairing_check.py`'s `classify()` (is `cqrt_rz_i1` still
"transparent" there? it must stay so — it is diagonal — but say it). Also note L7 §F-L7-5: the
non-shared path is protected today only by its own `cqrt_free(Flag)` making the flag an
unrecognized-consumer rail — after your fix the protection must be the membership, on BOTH
paths; write that in the emitter's header, replacing the false "byte-for-byte the rule
emitRegion follows" sentence.
Fixtures: `control_phase_kickback_sharecond_datause.ll` (ACCEPT; whole-file PURE-negative
`NOROUTE-NOT: call void @cqrt_rz_i1(i32 %{{.*}}, double -` and `NOROUTE-NOT: fneg`; the
`CHECK-COUNT-1: call void @cqrt_rz_i1` in its OWN `ACNT` prefix), its `icmp ne` negated twin
(measured to cancel too: `probes/i1_sharecond_negated.c`), and an e2e pair + `cmp`-style
witness: `slice_control_phase_kickback_sharecond.c` vs `..._nophi.c` whose goldens differ by
EXACTLY one `cqrt_rz_i1` line (write a tiny python/ctest check or record the diff in the
slice headers and the notes — there is no `cmp`-of-diff gate; a `compare_files` cannot express
"differs by one line", so add the two goldens and state the diff in both headers).

## F-L7-2 — REGRESSION (orchestrator-measured): the ROLLED in-loop kickback leaks its derived
## condition chain every iteration
`$SP/progress/orch_perbit/perbit_new.c` (`for (i<4) if ((q>>i)&1) cq_phi(.3); q=cq_theta(q,-.5)`)
on the subject: 4 `and_i32_hl` mints, **0** `and_i32_hl_unc`, 4 frees (flags only), and
`warning: non-diagonal gate over a live derived record` at the diffusion — the four leaked `and`
rails are which-path records of q's bits, so the diffusion is DEPHASED and CQ only warns. The
ORACLE on the old surface (`perbit_old.c`) discharges 4/4 with 8 frees; the FLAT K=2 form on
the subject (`perbit_new_flat.c`) discharges 2/2. So the in-body per-iteration discharge of a
derived condition chain does not happen for a kickback region inside the 8h7d.5 rolled loop
(read CLAUDE.md's in-loop paragraph: `collapseFlattenedLoopRails`, `markIfRailLocal`, the M-B
interior partition, `staleRailRecordRead`). Find why the phase-arm path discharged it and the
kickback path does not (likely: the old region had a merge φ / an arm gate on q that the
round-2 collapse keyed on; the kickback has neither, so the derived chain is never marked
rail-local). Fix so the rolled trace is BYTE-IDENTICAL to the hand-unrolled twin (which is the
flat form) — that is the 8h7d.5 witness; pin with a lit fixture (`control_phase_kickback_inloop_
derived_cond.ll`, exactly one `and_unc` per iteration in the rolled body) and confirm on the
prep-b slices `slice_control_phase_perbit_loop{,_unrolled,_k32}.c` (in `$SP/wt/prep-b/tests/e2e/`).
If the honest answer is that the rolled kickback with a derived condition must DECLINE until
the discharge is built, say so as an OWNER QUESTION with the cost (D4's idiom is exactly this
shape) — do not leave a leaking accept.

## F-L7-5 / F-L7-6 — doc truth
Rewrite the `SwapRouteEmit.cpp:1315-1320` ShareCondFlag comment (false equivalence claim); add a
comment at `:1493-1499` recording the inherited unconditional `cqrt_free` after a nullable strip
(NOT a code change unless a lens reaches it).

## Also
- Every fix: red-green (the fixture reddens on main's binary, greens on yours), STRICT stage 2b
  on every reproducer, run on all three binaries.
- Append to `$SP/progress/fix_r1.md` after every step; commit per finding
  (`wip(3qlq-inc1-fix-r1): F-L7-1 …`). More findings will arrive by message from the
  orchestrator as lenses L1/L2/L3/L5 finish — act on them in the same worktree.
- Write `docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC1_NOTES.md` §1 (round 1):
  one paragraph per finding (reproducer, trace, root cause, fix, fixture), in the style of
  `CONTROL_IN_PLACE_INC4_NOTES.md`.
- Hand back per BRIEF_common with: per-finding status, the closure-enumeration table for
  F-L7-1, lit counts on your binary (background), and the OWNER QUESTIONS.
