> ⚠ **ERRATA appended by the round-1 FIX agent (2026-09-11, `FIX_A1_R1.md`) — §1's scope sentence,
> "No program that declines on `main` may accept on this branch", was met on the 1776 FIXTURES and
> NOT on the program set.** Rule-13 round-1 finding F-A1-2: rung (ii)'s per-activation barrier lives
> in `railMeasuredBeforeReadPoint`, which the 1b / 1b-B.1 RAIL ladder shares, so **two plain-C
> programs move DECLINE → ACCEPT** — `review_a1_r1_probes/b1.c` (bare-`_Bool` kickback) and `b2.c`
> (the 4.4 data select), both an iteration-local `_Bool` measured inside a bounded loop. Both accepts
> are CORRECT (the register is re-minted every trip; measured: `cqrt_alloc_i1` inside the body), and
> both are now pinned by lit fixtures and an e2e twin pair. **Read the scope sentence as: A.1 is
> decline-monotone on the COMPARE path, and has exactly those two rail-path accept movers, by name.**
> Nothing else in §1 or §1.3 changed; the corpus diff is still `0 RCDIFF / 0 DIAGDIFF / 0 OUTDIFF`.
>
> ⚠ **ERRATA-2, appended by the round-2 FIX agent (2026-09-11, `FIX_A1_R2.md`) — "exactly those two,
> by name" is ALSO wrong, and it is wrong in the direction that matters: it reads as an exhaustive
> claim about PROGRAMS when it is a claim about the two programs anybody had written down.** Rule-13
> round-2 finding F-A1R2-3 measured at least **five** plain-C members of the same class, all
> `DECLINE → ACCEPT`, all correct: `b1`, `b2` (constant seed), `r3` (a loop-CARRIED classical seed
> off the previous trip's `cq_measure`), `b3` (a loop-INVARIANT non-constant seed that `-O1` does NOT
> LICM out of the body — measured) and `b4` (the origin inside a GUARDED sub-block of the body).
> **Read the scope sentence as: A.1 is decline-monotone on the COMPARE path; on the RAIL path rung
> (ii)'s per-activation barrier admits the ITERATION-LOCAL CLASS — a register whose source-theta
> origin re-executes on every path from the measurement back to the read — of which those five are
> the measured members and `r3`/`b3`/`b4` are now pinned beside `b1`/`b2`.** State it as a class with
> its ground, never as a list of names.
>
> ⚠ **ERRATA-3, same agent, same round — the increment is NO LONGER decline-monotone on the FIXTURE
> corpus either, by exactly one file, and it is a deliberate parity decision rather than a
> regression.** Closing F-A1R2-1 (the `Covered` exemption at the two fence-less consumers) turns
> `lowering_live_record_tape_ctrl_observed_accept.ll` from ACCEPT to DECLINE; it is `git mv`'d to
> `lowering_reject_live_record_tape_ctrl_cond_staler.ll` with the whole story in its header. The
> round-2 review's premise that the narrowing "cannot cost the twelve in-loop accepts, all of which
> are `ArmClassify` consumers" is false by that one file: it is a 7.6 I/O-SINK consumer, i.e. one of
> the two the finding is about. See `FIX_A1_R2.md` F-A1R2-1 for the measurement and the open question.

# Brief — Track A.1 "compare-select fence parity", the FENCES (bd `test_C_libtooling-9pum` + `test_C_libtooling-r10v` + bd `r903` NOTES item (b))

Written 2026-09-11 by the orchestrator (session `01NHxGVinGBKbb499HFCuwhT`). Owner decision the same day:
**option 1** — one parity increment for the compare-conditioned control consumers, fences first (this
brief, A.1), widenings second (A.2, a separate brief after A.1's round 1), then bd `3d8q` on its own.

You are the IMPLEMENTATION agent. Model: opus. You work in the git worktree
`/Users/sorenwilkening/Desktop/CQ_trackA` on branch `compare-select-parity` (created by the orchestrator
from `main` 0c7380c) with its OWN `build/` dir. **Never touch `/Users/sorenwilkening/Desktop/CQ_lang/build/`
— that is the frozen pre-change ORACLE binary (`main` 0c7380c) for every A/B measurement in this brief.**
Do NOT commit. Do NOT `git push`. Do NOT run the full `ctest` more than the gate moments in §6 ask for.
Report only what you ran, with the commands.

## 0. What is broken, measured on `main` 0c7380c (2026-09-11, orchestrator's measurement agent)

All three are verify-clean, STRICT stage-2b-clean, `opt` exit 0, plain C, **no diagnostic**. Reproducers
are committed under `docs/prd/phase-04-swap-route-control/inc1-records/`:

| bd | program | what is emitted | root cause |
|---|---|---|---|
| `r10v` | `int b = cq_theta(0,.5); for (i<3) { int a = (b == 1) ? i : 5; acc += cq_measure(a) + cq_measure(b); }` — `session-r9e5/probes/m2_inloop_select_measure_after_compare_twin.c` | 38-line trace; lines 14→15 and 26→27 are `cqrt_measure_i32(h0)` then `cq_template_icmp_eq_i32_hl(h0, 1)`: trips 2/3 mint the flag from a register trip 1 COLLAPSED | `classifySelectRegion` (`ir-pass/src/SelectClassify.cpp`) has NO measured-before rung for a COMPARE leaf; gate 2c asks only the wire question. The RAIL half was fixed in 1b-B.1 (`railMeasuredBeforeReadPoint` + `isPotentiallyReachable`, PRD §14.3 rung 2, §14.7 F-B1-1, F-B1R1-1) |
| `9pum` | two TUs: `int q=cq_theta(3,.5); int y=5; if (q>5) y=ext_f(7); int b=cq_theta(y,.25); int b3=cq_theta(y,.9); int a=(b==1)?2:5; return cq_measure(a)+cq_measure(b3);` — `session-r9e5/review_b1_r2_probes/multi/e13_{caller,lib}.c` (recipe: `run_multi.sh` there — per-TU `-O1`, `llvm-link`, ONE `cq-lowering`) | 26-line trace; lines 13/14/15 `ry(h2,.25); ry(h2,.9); icmp_eq(h2,1)`: the flag minted from the post-`.9` register while the source compares the post-`.25` one | gate 2c's wire walk (`findNonDiagonalWireGate`, with the F-1b-1 ancestry crossing keyed on `Taint.Tainted`) runs inside `detectControlRegions` at ROUND-1 taint; `y` is a 6.5 `%out` derivative, tainted only when `repropagateControlMerges` re-seeds; `lowerRotations` decides `Chained = taint.Tainted.count(Op)` at FINAL taint and puts `b`/`b3` on ONE rail. The RAIL half is F-B1R2-1, fixed in 1b-B.1 by `reverifyRailCondReads` (PRD §14.8) — this is the COMPARE half, measured PRE-EXISTING and byte-identical on `main` |
| `r903` (b) | `int q = cq_theta(0,.5); int m = cq_measure(q); if (q > 3) cq_phi(.3);` — `session-r903/probes/` (`m1`) | accepts; mints `icmp_sgt_hl(%h,3)` AFTER `cqrt_measure_i32(%h)` | on the `br` (kickback) path `condDataUseDisposition`'s `MeasuredEarly` is about the FLAG lineage; "was the condition REGISTER measured?" is asked by NO rung on the compare path. The one-token `_Bool` twin (`m3`) declines. Same rung as `r10v`, read point = the branch |

Read the three bd issues (`bd show test_C_libtooling-{9pum,r10v,r903}`), PRD `retire-swap-route-PRD.md`
§14.3 (the rail ladder — rungs 2 and 3 are what you are mirroring), §14.7 (F-B1-1, F-B1R1-1, F-B1R2-1) and
§14.8 (the re-verification stage), `session-r9e5/FIX_B1_R2.md` (how `reverifyRailCondReads` was built, the
FOUR recording sites and the one the first spelling missed), `CLAUDE.md`'s "INCREMENT 1b-B.1" paragraph, and
bd memories `rail-ladder-read-point-and-wire-closure-r9e5`, `predicate-runs-once-round2-taint-window-r9e5`.

## 1. Scope of A.1 — decline-only, three rungs, mirrored from the rail ladder

**Every change in A.1 is DECLINE-MONOTONE.** No program that declines on `main` may accept on this branch,
and the corpus diff (§5) must show `0 DECLINE→ACCEPT` over all 1776 fixtures and the whole e2e golden set.
The widenings (the DT prong for compare seeds so the S† after a compare select accepts; P1's
`SawValueArm` retirement under a chain-rail fence; `AllowLogicalSelect` for data selects) are **A.2 — NOT
THIS BRIEF**. Do not build them. Do shape the record in §1.2 so A.2 can reuse it (say so in a comment).

### 1.1 Rung (ii) for COMPARE leaves — `condition measured before the control route` (r10v + r903(b))

For every `CmpInst` leaf of a tainted condition, for each TAINTED operand: if some `@cq_measure_*` user of
the operand's **WIRE** (not its SSA name — F-B1R1-1: `railWireNamesBackward`'s closure, the chained-theta
ancestry by `lowerRotations`' own `Chained` relation, stopping at and collecting the first non-theta parent)
can reach the read point on some path, decline with the EXISTING string
`condition measured before the control route`. Read points, exactly as the rail ladder:
- the 4.4 data select: the `SelectInst` itself (`classifySelectRegion`; `SelectMergeEmit` inserts every gate
  immediately before it) — measured-after in the same block must STAY an accept (positional test), a measure
  elsewhere is refused on REACHABILITY (`isPotentiallyReachable`, which answers the same-block-on-a-cycle
  case itself — F-B1-1 is the reason);
- the kickback / nest / angle-select `br` path: `Pred->getTerminator()` (a `cq_measure` user is never a
  terminator, so a same-block one always `comesBefore` it) — this is the r903(b) half; find where the rail
  ladder asks `railMeasuredBeforeReadPoint` for the kickback (`classifyPhaseKickback` step 5b) and ask the
  same of each compare leaf's operand wire. Note `condDataUseDisposition`/`MeasuredEarly` stays as it is
  (it is about the flag lineage, a different question) — do not fold the two.

REUSE (Rule 14): `railMeasuredBeforeReadPoint` / `railWireNamesBackward` (ArmClassify) already answer this
for a rail seed. Generalise the seed (a compare's tainted operand instead of a `cq_theta_i1` result) rather
than writing a second spelling; if the helper's name no longer fits, rename it and update every caller.

### 1.2 Rung (iii) at FINAL taint for COMPARE seeds — the 9pum window

`TaintSet::RailCondReads` (rail + first emitted `cqrt_*` read) is recorded at four sites (`emitCondNode`,
the `CopyRailRoot` cnot, `emitKickbackGroup`, `AngleSelectEmit`) and re-verified by `reverifyRailCondReads`
after the round-2 fixpoint in BOTH entry points. Extend the record to COMPARE SEEDS: for each compare leaf,
record its `condProvenance` seed set (the tainted operands, i.e. the same set gate 2c walks at round 1) and
the leaf's MINT template call as the read point, at EVERY compare-mint site. **Enumerate the sites by grep,
not from memory — "every emission site, or none" is the `markBranchPhaseGate` and `markRailCondRead` lesson
twice over**: `lowerCompareToFlag` callers (`SelectMergeEmit`, the flat kickback, the nest, `AngleSelectEmit`,
`ClassicalCallArmEmit`, `SwitchRouteEmit`/`SwitchValueEmit`/`SwitchDataMuxEmit`, `EqFoldArm`), the
`CondTreeEmit` leaf mint, and `Specialization::mintCondNetwork` (say explicitly whether it is in or out and
why). Then in the re-verification stage re-ask BOTH rungs for compare seeds under FINAL taint and a fresh
DT: (ii) as §1.1 (the wire closure may have grown at round 2), and (iii) the POSITION-FREE
`findNonDiagonalWireGate` (with the `TaintSet` so the F-1b-1 ancestry crossing sees the round-2-chained
sibling) — declining with the same strings, never a silent fallback. The `9pum` reproducer must go
ACCEPT → DECLINE; its onward-classified twin (a compare whose operand is round-2-tainted through the onward
path and has NO sibling theta) must stay ACCEPT.

### 1.3 What must NOT move

- The flat measure-AFTER accept (`control_swap_select_rail_measure_after.ll`'s compare twin — write it if
  it does not exist), every `control_swap_select_*`, `control_phase_kickback_*`, `control_angle_select_*`,
  `control_classical_call_*`, `lowering_switch_*` accept; every e2e golden. Corpus diff: `0 RCDIFF · 0 DIAGDIFF
  · 0 OUTDIFF` over the 1776 pre-existing fixtures and 0 changed goldens, EXCEPT fixtures that pin the
  three holes (there should be none — if one exists, it is an over-accept pin and you list it).
- `AllowLogicalSelect` stays defaulted `false` at the data select (A.2).
- The rail ladder's behaviour, byte-for-byte (its 13 accept + 9 decline + round-2/3 fixtures).
- No new runtime symbol, no YAML, no `include/` change.

## 2. Anchors (VERIFY EACH BY GREP before relying on it; line numbers are from 2026-09-11 measurements)

- `ir-pass/src/SelectClassify.cpp:946` — compare seeds' POSITION-FREE walk; `:951-957` — rail seeds' DT prong;
  `:782` — `collectCondTree` called with `AllowLogicalSelect` defaulted false; `:693-695` — the `xor i1 …, true`
  child refusal (`control flow`).
- `ir-pass/src/ArmClassify.cpp` — `railMeasuredBeforeReadPoint`, `railWireNamesBackward`,
  `railCondWireDisposition`, `condWireDisposition`, `condDataUseDisposition` (`MeasuredEarly`),
  `classifyPhaseKickback` step 5b, `reverifyRailCondReads` (≈`:2075`, note its `dyn_cast<CallInst>` on the
  record — a compare seed's read point is also a `CallInst`, the mint template), P1 at ≈`:3660-3722`
  (`SawValueArm` — A.2, read only).
- `ir-pass/src/CondTreeEmit.cpp` — `markRailCondRead`, the leaf mint, `emitCondNode`, `CopyRailRoot`.
- `ir-pass/src/WireWalk.cpp` — `findNonDiagonalWireGate` (position-free and position-aware modes; the optional
  `TaintSet` for the F-1b-1 ancestry crossing).
- `ir-pass/include/TaintPropagation.h` — `TaintSet::RailCondReads` (a `WeakTrackingVH` pair; keep that — the
  record must survive RAUW).
- `ir-pass/src/CQLoweringPass.cpp` — the two entry points that call `reverifyRailCondReads` after the round-2
  fixpoint; do not move the stage (its placement argument is written at its header — read it).
- `ir-pass/src/OpcodeLowering.cpp` — `declineStaleRecordOps` / `inLowerOpsScope` excludes select-condition
  compares (that is why nothing else catches these); bd `3d8q` is there, NOT this brief.

## 3. Rule 12 — red-green, in this order

For every predicate: write the DECLINE fixture first (`RUN: not %cq-opt … 2>&1 | FileCheck`, mirroring the
string character-for-character), watch it FAIL on the oracle binary
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` (record the command and the output), then
implement minimally, then the ACCEPT controls. Reuse ONE `%cq-opt … > %t.ll` per fixture and point every
prefix at it; never a standalone `-passes=verify` line. Family (names are suggestions; keep the tree's
conventions — `control_swap_reject_select_*` / `control_swap_select_*` for the 4.4 select,
`control_phase_kickback_reject_*` / `control_phase_kickback_*` for the br path):

Declines (each RED on the oracle):
- `..._reject_select_cmp_measured_before.ll` (flat: `m = cq_measure(q); a = (q==1)?2:5;`),
- `..._reject_select_cmp_measured_sidepath.ll` (a measure on another path that reaches the select),
- `..._reject_select_cmp_inloop_measure_after.ll` (the r10v reproducer, loop-VARIANT arm) and
  `..._constarm.ll` (the LICM-hoisted arm — say what -O1 does to it and whether it is a decline or an accept
  control; the rail pair `control_swap_reject_select_rail_inloop_measure_after{,_constarm}.ll` is the model),
- `..._reject_select_cmp_measured_parent_name.ll` (rung (ii) over the WIRE: `q2 = cq_theta(q,.3); m = cq_measure(q); a = (q2==1)?2:5;` — the F-B1R1-1 shape),
- `..._reject_select_cmp_round2_sibling_theta.ll` (9pum, hand IR from the two-TU module) and the plain-C
  two-TU slice (§4),
- `control_phase_kickback_reject_cmp_measured_before.ll` (r903(b), `m1`), `..._measured_sidepath.ll`,
  `..._round2_sibling_theta.ll` (the kickback window for a compare seed — construct it as the rail one was),
- the nest and angle-select spellings of the round-2 window for a compare seed (the reviewer's r07/r09 rail
  shapes have compare twins — write them).
Accept controls (each GREEN on both binaries):
- `..._select_cmp_measure_after.ll` (same block, after), `..._select_cmp_other_register_measured.ll` (the
  closure's STOP pin: a measurement of a DIFFERENT register on the same path), `..._select_cmp_round2_window_accept.ll`
  (a round-2-tainted compare operand with the sibling theta AFTER the select — correct by source order),
  `..._select_cmp_round2_opaque_seed_accept.ll` (an opaque classical seed that stays classical: two registers),
  `control_phase_kickback_cmp_measure_after.ll`.
Injection matrix over every new accept: inject an extra `cqrt_measure` before the read, a sibling `cqrt_ry`
on the condition wire, an extra `cqrt_free`; each must be caught by a prefix (`FCNT`/`XCNT`/`RYCNT`/`MCNT`
whole-file counts). Report MISSED/DIRTY counts; the goal is 0/0.

## 4. e2e (STRICT stage 2b, registered in `tests/e2e/CMakeLists.txt` after the `select_bool` group)

- `slice_control_select_cmp_measure_after.c` (accept, flat) — the twin of `slice_control_select_bool_*` at
  the compare;
- `slice_control_select_cmp_round2_window.c` + `_lib.c` through `run_slice_multi.sh` (accept: the sibling
  AFTER the select on a `%out`-derived operand — the compare twin of
  `slice_control_select_bool_round2_window`);
- the DECLINES are pinned in lit only (a slice must link, so a decline has no golden) — but add each decline's
  plain-C source under `session-9pum/probes/` with its measured verdict on BOTH binaries.
Register nothing that is not measured; read every golden line by line against the analytic stream.

## 5. The corpus-diff harness and the record

Re-create the pre-vs-post harness described in `session-r9e5/IMPL_B1.md` §5 in your scratchpad
(`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/trackA/`):
for every `ir-pass/test/*.ll`, run oracle and subject, compare rc + stdout + stderr; report
`RCDIFF/DIAGDIFF/OUTDIFF` counts and list every mover with its direction. Then the same over
`session-r9e5/probes/`, `review_b1_r{1,2,3}_probes/`, `session-3qlq4/probes/`, `session-r903/probes/`,
`session-l4x4/probes/`, `session-boi6/probes/` (each has a runner/README): list every mover; every mover
must be ACCEPT→DECLINE with one of the three strings, and you must say for each why the decline is right.

Write `session-9pum/IMPL_A1.md`: §0 what was measured before coding, §1 the predicate changes with
file:line, §2 the recording sites (all of them, with the grep that enumerated them), §3 Rule-12 red-green log
(the RED runs on the oracle), §4 e2e, §5 corpus diff + probe diff, §6 gates run (§6 below), §7 open
questions for the reviewer (anything you decided that a reviewer could dispute — say it here, not in a
comment). Put every new probe under `session-9pum/probes/` with a README of verdicts on both binaries.

## 6. Gates (Rule 19), in order, in the worktree

1. Per fixture while iterating: `cd build && lit ir-pass/test --filter '<name>'`.
2. `ctest --test-dir build -R ir-pass-lit --output-on-failure` (expect 1 XFAIL, 0 unexpected).
3. `ctest --test-dir build -j6 -R '^e2e-' --output-on-failure` and `git status --porcelain tests/` (empty
   except your additions).
4. The full `ctest --test-dir build -j6 --output-on-failure` ONCE at the end (this is a Rule-13-core
   change; Rule 19 moment 1 and 5). Report the exact pass/fail line and wall time.
5. `cmake --build build --target cq-opt-equivalence-full` (the diagnostic surface changed).
Report every number as measured; "tests pass" is not a sentence you may write.

## 7. Non-negotiables

- Build BOTH targets (`cmake --build build -j8`), never `--target CQPass` alone.
- Decline-monotone; loud strings only; no silent fallback anywhere; no prediction of what round 2 will
  taint — RE-VERIFY (the eqpx pattern).
- One spelling per predicate (Rule 14): generalise the rail helpers, do not fork them.
- Stop and write it in IMPL_A1.md §7 if a rung, once built, refuses a program whose circuit you believe is
  valid — do NOT weaken the rung to buy it back; the owner's end-goal is expressiveness and A.2 is where
  widenings go, with their own round.
- Do not commit, do not push, do not touch the primary checkout's `build/`.

Final message to the orchestrator (≤40 lines): the three reproducers' before/after; the recording-site
list; corpus diff counts; probe-corpus movers; gate results verbatim; the §7 open questions.
