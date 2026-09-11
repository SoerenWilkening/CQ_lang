# Brief — Track D: bd `test_C_libtooling-l4x4` sub-increment **l4x4.b** — the in-place controlled-Ry ARM and the controlled STATE PREP on a bare `_Bool` (rail-root) condition, including the NEGATED condition

Written 2026-09-11 by the orchestrator (session `01NHxGVinGBKbb499HFCuwhT`). Owner end-goal for this
session: compile every program with a valid circuit; over-declines are the defect. THE CUSTOMER is
`example/grover/grover_oracle_uncompute.c` as of 2026-09-11 (snapshot:
`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/owner_file_2026-09-11.c`):
after bd `b6ap` (the multi-phi peel, built on branch `merge-phi-peel`) its second region is
`if (!b0) b1 = cq_theta(b1, 0.5)` — a STATE PREP of a `_Bool` under a NEGATED bare-rail condition (the arm is
the FALSE successor) — and it stops on `bare i1 register condition` at the prep arm. This increment removes
that wall. The `i1`-seed F2 collision it would hit next is REMOVED by Track C (`f2-condwire-narrowing`,
checkpoint 578dbc4), which is why this branch is based on that checkpoint, not on `main`.

You are the IMPLEMENTATION agent. Model: opus. Worktree `/Users/sorenwilkening/Desktop/CQ_l4x4`, branch
`l4x4b-bool-ry-arm` (from `f2-condwire-narrowing` @ 578dbc4), its OWN `build/`. **Never write under
`/Users/sorenwilkening/Desktop/CQ_lang/`, `/Users/sorenwilkening/Desktop/CQ_f2/`, `CQ_b6ap/` or `CQ_trackA/`.**
ORACLE for A/B: `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` + `libCQPass.so` (main 0c7380c);
SECOND reference: `/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass/cq-opt` (the F2 branch — your base; use
it to separate "moved because of F2" from "moved because of me"). Do NOT commit, do NOT push. Report only
what you ran.

## 0. Read first

`SCOPE_l4x4.md` beside this file — ALL of it (§0.1 the 31-probe measurement table; §1 every `CmpInst`
site with file:line; §2.1 the target streams read off the compare twins; §2.2 H-1 the `ControlledRotations`
raw-`Value*` hazard — a BUILD-TIME blocker, the drbq Inc-1 stale-set shape; §2.3 negation, four options —
the DECIDED one is below; §2.5 F1/F2 for a rail condition; §2.6 the re-decline partition shared with
`fg9k`/`54ur`; §2.7 the structural freeze with a LIVE register as the control; §2.8 `RailLadderProven`;
§2.9 `markRailCondRead` fifth and sixth sites; §3 hazards H-1..H-n; §4 fixtures/slices; §5 cost) and its
`probes/README.md`. Then `CLAUDE.md` (Prime Directive; Rules 1, 6, 7, 8, 12, 13, 14, 17, 19; the drbq
control-in-place paragraphs — Inc 1 `cqrt_ry_<W>_controlled`, the structural freeze, R4/R6, M-α/M-β; Inc 4
state prep, F1/F2; "INCREMENT 1b" — the diagonal-only invariant "NO `cqrt_x` ON A USER REGISTER, EVER" and
why `preservesBorrowedParent` makes it load-bearing; "INCREMENT 1b-B.1" — `CopyRailRoot`, the rail ladder,
`markRailCondRead`, `reverifyRailCondReads`), PRD `retire-swap-route-PRD.md` §13–§14,
`control-in-place-PRD.md` §4/§12.3/§14, and `session-f2-i1/IMPL_f2.md` (what your base changed in F2).

## 1. Scope — l4x4.b ONLY

IN: (a) the flat DIAMOND in-place Ry arm on a bare-rail condition, `if (b) r = cq_theta(r, θ)` with `r`'s
wire disjoint from `b`'s; (b) the controlled STATE PREP on a bare-rail condition, `int r = SEED; if (b)
r = cq_theta(SEED, θ)` and the `_Bool` seed (now admitted by F2's narrowing); (c) the NEGATED condition
`if (!b)` for both (plain-C reachable — SCOPE `t7`: the arm is the false successor). OUT: the Ry-stem ANGLE
SELECT (`l4x4.a`, separate — do NOT touch `classifyAngleSelect`/`AngleSelectEmit` beyond what (a)/(b) need);
the IN-LOOP rail form (`l4x4.c`, carved out — it must KEEP declining, with a fixture: SCOPE §2.4); the value
arm (`fg9k`), the 6.5 arm (`54ur`), the phase classes (already shipped) — the five-class re-decline
partition of SCOPE §2.6 must be written ONCE and every other class must keep its decline at
`ArmClassify.cpp:2392`'s site with `bare i1 register condition`.

## 2. Decisions taken by the orchestrator

1. **Lowering** (SCOPE §2.1): `Flag = RailCond ? Cond : lowerCompareToFlag(…)` at the in-place emitter;
   `cqrt_ry_<W>_controlled(h_b, h, θ)` with the REGISTER as the control; no mint, no strip, no free for the
   flag; the register carries only a read-only control. No new runtime symbol (all nine widths declared,
   `cq_runtime.h:229-237`).
2. **Negation by Ry additivity** (SCOPE §2.3's recommendation): `ry(h, θ); ry_controlled(h_b, h, −θ)`
   — fires `Ry(θ)` when `b = 0`, `Ry(θ)Ry(−θ) = I` when `b = 1`; the angle is `fneg` (exact), never
   `fsub`, so the Inc-2b rounding fence has no subject; reuse `AngleSelectEmit`'s unconditional-twin
   emission (Rule 14) rather than a new spelling. **NO `cqrt_x` on the register, ever.** For the state prep
   the unconditional twin acts on the FRESH rail, so `alloc(SEED); ry(h, θ); ry_controlled(h_b, h, −θ)`.
   Pin both polarities with count prefixes (`XCNT-NOT` on the register's handle, exactly one `_controlled`).
3. **H-1 first** (SCOPE §2.2): `taint.ControlledRotations` holds a raw `Value*`; a rail condition's
   control is the `i1` CALL that `lowerRotations` erases. Fix it the way the drbq round-1 Rule-13 fix did
   for the rotated register — STRUCTURALLY (derive from the emitted gate's own operand, or a
   `WeakTrackingVH` that follows the RAUW) — and pin it with a fixture that would SIGSEGV/misfreeze on the
   raw pointer.
4. **The freeze** (SCOPE §2.7): `railCarriesControlledRotation` derives the ROTATED rail from arg-1; the
   CONTROL is now a live user register — say in IMPL exactly what the whole-DAG spine does with `b`
   afterwards (borrowed parent? left allocated? the `_unc` of a chain that borrows `b`), and pin it.
5. **Ladder** (SCOPE §2.5, §2.8): §13.3's rail ladder at the branch — tainted; `railMeasuredBeforeReadPoint`
   at `Pred->getTerminator()`; `railCondWireDisposition`; R4 disjoint wires (`b` vs `r`); R6 stale record;
   F1/F2 as on your base — and set `RailLadderProven`; the emitter refuses a rail tree without it.
6. **`markRailCondRead`** at every new rail read (SCOPE §2.9: the controlled-Ry's control operand is a rail
   READ; both the diamond and the prep) so `reverifyRailCondReads` re-asks rungs (ii)+(iii) at final taint.
   Enumerate the sites by grep after you add yours; the count in `CLAUDE.md` moves from four.
7. **M-β** for the merge phi (a correctness requirement for the prep — CLAUDE.md: M-α would RAUW the merge
   to the SEED and make `r` classical).

## 3. Rule 12 — red-green, in this order (SCOPE §4.1/§4.2 are the family; mirror the strings exactly)

Declines first, each RED on the oracle AND on the F2 base: Ry on the CONDITION's own wire
(`if (b) b = cq_theta(b, θ)` — SCOPE says F1 catches it, `state prep merged with a quantum register`;
confirm and pin); a sibling theta on `b`'s rail before the branch (F-1b-1's class); `b` measured before the
branch; a theta between `b`'s def and the branch; the IN-LOOP form (`t5`, l4x4.c — keeps `bare i1 register
condition` or a loop string, say which); the value arm / 6.5 arm / phase-nest-negated classes
(`bare i1 register condition`, unchanged); a Q+Q chained arm; a multi-gate arm (R1). Then the accepts: the
diamond both polarities, i8/i32/i64 widths, the prep with `int` seed and with `_Bool` seed (the owner's
shape — RED on the oracle at `bare i1`, RED on the F2 base at `bare i1`, GREEN here), the prep negated, the
S† after the region (`t8` — decide by the P1 argument: an in-place arm copies nothing, so `ProvenPostRegion`
carries; ACCEPT, pinned), two regions on one `b`. Injection matrix (extra `cqrt_x` on `h_b`, extra
`cqrt_free`, `_controlled` with swapped control/target, missing unconditional twin on a negated shape): 0
MISSED / 0 DIRTY, with the counts.

## 4. e2e (STRICT stage 2b, registered after the `inplace_ry_stateprep` group)

`slice_control_inplace_ry_bool_{diamond,negated,stateprep,stateprep_negated}.c` + their `int` compare twins
where the reduction is statable (the Inc-4 precedent: NO `compare_files` gate between a bool slice and its
int twin — state the reduction in the header). And the OWNER'S FILE: on this branch alone it still stops at
`control flow` (b6ap is on another branch) — put it in `probes/` with the measured string; additionally
construct the owner's second region IN ISOLATION (`bool b0 = cq_theta(false,.5); bool b1 = 0; if (b0 == 0)
b1 = cq_theta(b1, .5); return cq_measure(b0) + cq_measure(b1);`) as `slice_control_inplace_ry_bool_stateprep_negated.c`
— that is the shape b6ap will hand to this code, read its golden line by line: `alloc_i1(0) -> h0; ry_i1(h0,.5);
alloc_i1(0) -> h1; ry_i1(h1, .5); ry_i1_controlled(h0, h1, -.5); measure; measure`, no `cqrt_x`, no free.

## 5. Record + corpus diff

`IMPL_l4x4b.md` beside this file: §0 measured before coding (re-run SCOPE §0.1's table on your build),
§1 the classifier sites (file:line) and the ONE re-decline partition, §2 the emitter and H-1's fix, §3 the
freeze disposition of `b`, §4 red-green log, §5 e2e, §6 corpus diff — THREE-WAY: oracle vs F2-base vs
subject over all fixtures (report movers attributable to F2 separately from yours; yours must be
DECLINE→ACCEPT only, `bare i1 register condition` string, each listed), §7 open questions. Probes under
`probes/` with the README extended. Harness: `session-r9e5/IMPL_B1.md` §5, scratch
`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/`.

## 6. Gates (Rule 19), in order

1. `lit --filter` per fixture. 2. `ctest -R ir-pass-lit`. 3. `ctest -j6 -R '^e2e-'` + `git status --porcelain tests/`.
4. Full `ctest -j6` ONCE at the end (Rule-13 core; moments 1 and 5) — exact pass line + wall time; NEVER
relink under a running measurement and NEVER `pkill` by an unverified pattern (Track C lost its matrix
result that way — read `session-f2-i1/IMPL_f2.md` §5b/§5c). 5. `cq-opt-equivalence-full` if a diagnostic
string was added/moved.

## 7. Non-negotiables

Build BOTH targets (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
-DCMAKE_BUILD_TYPE=Release && cmake --build build -j8`). No `cqrt_x` on a user register. No new symbol, no
YAML, no `include/`. Loud strings only. Do not touch `classifyAngleSelect` beyond need. Do not commit/push.
If H-1 cannot be fixed structurally, STOP and write why.

Final message (≤40 lines): the sites, H-1's fix, the freeze disposition of `b`, movers (three-way),
the owner's isolated second region's trace, gate lines verbatim, §7 open questions.
