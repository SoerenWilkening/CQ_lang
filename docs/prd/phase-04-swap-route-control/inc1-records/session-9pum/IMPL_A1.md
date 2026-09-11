> ⚠ **ERRATA, 2026-09-11: this file is the PRE-REVIEW record and four of its claims were corrected
> by the round-1 Rule-13 review (`review_a1_r1.md`, verdict BLOCK) and its fix (`FIX_A1_R1.md`).**
> The corrections are inlined below as quoted blocks at §5 and §7 (O-2, O-3, O-5, O-7); the original
> sentences are left standing rather than rewritten, so what was believed and what was measured can
> both be read. The headline: **O-3 was not empty** (F-A1-1, a confirmed silent miscompile),
> **the increment is not decline-monotone on the program set** (F-A1-2, two rail-path accept movers),
> and **rung (ii)'s seed was too wide** (F-A1-3, an over-decline). Read `FIX_A1_R1.md` first.

# IMPL_A1 — Track A.1, the compare-conditioned control ladder (bd `test_C_libtooling-r10v`, `-9pum`, `-r903` item (b))

Implementation record. Branch `compare-select-parity` (worktree
`/Users/sorenwilkening/Desktop/CQ_trackA`), from `main` 0c7380c. **Checkpointed on the branch as
`b439944` (a `wip(control):` commit, to be squashed at landing) and NOT pushed** — the "not
committed" this line carried until 2026-09-11 was true when written and stale by the time the
round-2 review read it (round-2 item F-A1R2-5).
ORACLE for every A/B figure below: `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
(+ `libCQPass.so`) at `main` 0c7380c, read-only.

---

## §0 — What was measured BEFORE any code was written

All three holes reproduce on the oracle. Commands (`$ORA` = the oracle bin dir):

```
clang -Iinclude -include CQ.h -O1 -emit-llvm -S <p>.c -o s1.ll
$ORA/cq-opt -load-pass-plugin $ORA/libCQPass.so -passes=cq-lowering -S s1.ll -o s2.ll ; echo $?
```

| bd | probe | oracle | the emitted stream |
|---|---|---|---|
| `r10v` | `probes/r10v.c` (= `session-r9e5/probes/m2_inloop_select_measure_after_compare_twin.c`) | **ACCEPT, rc 0** | trips 2/3 mint the merge flag from a register trip 1 collapsed |
| `r903` (b) | `probes/r903b.c` | **ACCEPT, rc 0** | `cqrt_measure_i32(%h)` then `cq_template_icmp_sgt_i32_hl(%h, 3)` then `cqrt_rz_i1` — MEASURED, dumped in full in the fixture header |
| `9pum` | `probes/9pum_{caller,lib}.c` (= `review_b1_r2_probes/multi/e13_*`) | **ACCEPT, rc 0** | `ry(h2,.25); ry(h2,.9); icmp_eq(h2,1)` — the flag minted from the post-`.9` register |

All three verify-clean and STRICT-stage-2b clean, no diagnostic.

Two further facts were measured before coding, and both changed the design:

* **`lowerCompareToFlag` is the ONE compare-flag mint.** `grep -rn 'lowerCompareToFlag(' ir-pass/src`
  returns **19 call sites across 8 emitter files** outside `CompareLowering.cpp` (measured:
  `grep -rn 'lowerCompareToFlag(' ir-pass/src/*.cpp | grep -v CompareLowering.cpp | grep -vc '//'`
  → 19; `grep -rln … | grep -v CompareLowering | wc -l` → 8) — see §2. Recording at the ten
  emitters would repeat the `markBranchPhaseGate` / `markRailCondRead` failure mode verbatim (the
  rail record's FIRST spelling already missed the 4.3 nest's conjunction toffoli, `FIX_B1_R2.md`).
* **`WireWalk::gateIsHarmless` consults the whole seed ARRAY**, not just the seed, to grow its
  per-activation barrier set (`WireWalk.cpp`, the `for (Value *S : Seeds)` loop over superseding
  wire-tracking phis). This is why the compare record stores the whole `condProvenance` cone as ONE
  entry; the first spelling stored one entry per cone member and turned **14 shipped in-loop
  accepts into declines** (measured, §5).

---

## §1 — The predicate changes

### 1a. The two rail helpers now take a WIRE SEED, not a `cq_theta_i1`

* `ir-pass/src/ArmClassify.cpp:1868` `railWireNamesBackward(const Value *Rail, …)` — was
  `const CallInst *`. The body was already total over `Value` (it breaks at the first
  non-`cq_theta_` name, yielding `{Seed}`), which is the right closure for a template result.
* `ir-pass/src/ArmClassify.cpp:1915` `railMeasuredBeforeReadPoint(const Value *Rail, …)` — same.
* Declarations + contract in `ir-pass/include/ArmAnalysis.h`.
* **NOT renamed.** "rail" in this tree means a physical register wire, and a compare's tainted
  operand names one; `railWireNamesBackward` reads correctly for both species. Open question O-1.

### 1b. Rung (ii) gains a PER-ACTIVATION BARRIER (`ArmClassify.cpp:1967`, `:1999`)

`railMeasuredBeforeReadPoint` previously refused on `isPotentiallyReachable(M, ReadPoint)` alone.
That is the wrong question inside a loop: it is TRUE around any back edge, so an
**iteration-local** register — minted fresh every trip — reads as measured-before.

The barrier is `Names.back()` (the wire ORIGIN, where the backward walk stopped) **when and only
when it is a SOURCE theta** (a `cq_theta_*` whose arg-0 is not tainted). Such a theta lowers to a
fresh `cqrt_alloc_<W>` + `cqrt_ry_<W>` on every execution, so a measurement followed by a
re-execution of the origin on every path back to the read point collapsed a register this read can
no longer name. A CHAINED theta is refused (an in-place Ry refreshes nothing); a non-theta origin
is refused too (an out-of-place template does mint a fresh rail, but M-C can lower the same op in
place and this predicate runs before that decision). **A missing barrier DECLINES.**

The walk is `WireWalk::everyPathReExecutes` — the same one `gateIsHarmless`' leg 2 uses for rung
(iii), asked rather than re-spelt (Rule 14). A straight-line `M` → `ReadPoint` inside one
activation is unaffected: that path does not cross the origin, so the rung still refuses (which is
`r903b`).

**This was forced by measurement, not chosen**: without it, five shipped fixtures move —
`control_swap_inloop_diamond_iterlocal.ll`, `control_swap_inloop_seq.ll` (ACCEPT → DECLINE) and
`control_swap_reject_inloop_{irreducible,multilatch,second_cycle}.ll` (which keep declining but on
the WRONG rung, a DIAGDIFF). All five are the iteration-local shape.
Pinned by `control_swap_select_cmp_inloop_iterlocal_measure_after.ll`.

### 1c. Rung (ii) for COMPARE leaves — `condCmpMeasuredBeforeReadPoint` (`ArmClassify.cpp:2033`)

New helper: for each `CmpInst` leaf, for each member of its `condProvenance` cone, ask
`railMeasuredBeforeReadPoint` over that member's own wire closure. Returns the offending leaf.

Two callers, the two consumers the brief scopes, detect-before-mutate:

* `ir-pass/src/SelectClassify.cpp:867` — read point `Sel` (`SelectMergeEmit` emits its whole stream
  immediately before it, so a same-block measure AFTER the select is the ordinary downstream case).
* `ir-pass/src/ArmClassify.cpp:4483` (`classifyPhaseKickback`, after step 5b's rail loop) — read
  point `Region.Pred->getTerminator()`.

`condDataUseDisposition`'s `MeasuredEarly` is untouched and NOT folded in: it asks whether the
FLAG's own data lineage was collapsed (the ziov `atk9` share-path hazard); this asks whether the
condition REGISTER was. `r903b` has no data use at all, so `MeasuredEarly` has no subject there.

**The seed set is the provenance CONE, not the compare's direct operands** — the brief's §1.1 says
"tainted operands". The cone is what gate 2c (rung iii) already walks, so the two rungs are
computed over ONE closure (the bd `8h7d.5` F-1/F-3 lesson as a construction); and the difference is
reachable (`int t = q + 3; m = cq_measure(q); if (t == 5) …` — `t`'s rail is entangled with `q`'s,
so the mint on `t` is still a post-measure gate). Measured: with the cone, **0 movers** over the
1776 fixtures and 0 over the 114 probes — i.e. the wider seed set costs nothing on any program in
the tree. I did NOT separately measure the operands-only variant; the claim is that the cone is
free here, not that it catches something the operands miss on a committed program. Open question
O-2.

### 1d. The COMPARE CONTROL-READ RECORD

* `ir-pass/include/TaintPropagation.h:357` — `TaintSet::CmpCondRead { Seeds; Read; }` and
  `:361 CmpCondReads`. `WeakTrackingVH` on every handle, as `RailCondReads` has.
* `ir-pass/src/ArmClassify.cpp:2358` `markCmpCondRead(Taint, Seeds, Read)` — one entry per mint,
  idempotent on `Read`.
* `ir-pass/src/CompareLowering.cpp:304` — the write, inside `lowerCompareImpl`, for FORWARD mints
  only (`!inverse`), gated by a new `recordCondRead` parameter **defaulting to TRUE**
  (`CompareLowering.h`). A new control emitter is recorded by construction; a caller that forgets
  fails toward a DECLINE, which is the Prime Directive's direction.

### 1e. `reverifyCmpCondReads` (`ArmClassify.cpp:2249`), called at `CQLoweringPass.cpp:440` and `:864`

Immediately after `reverifyRailCondReads`, in BOTH entry points, in the same slot (after the
round-2 fixpoint, before `lowerRotations`). Its header does not repeat the rail stage's placement
argument, the "why re-asking after emission is sound" argument, the four post-slot taint mutations
or the `DS_Error`-exits-inside-`diagnose` reading of "loud and final" — they apply verbatim and are
cross-referenced.

* **Rung (ii)** is asked on EVERY entry, per seed, over that seed's wire closure. It has no
  position-aware prong, so the flatten does not disturb it. This is what makes the stage a real
  backstop for the consumers that get no classifier clause: the angle select, the 6.5
  classical-call arm, the abort park, the guarded store, the controlled I/O sink.
* **Rung (iii)** is asked ONLY inside the round-2 window, and the window is measured MECHANICALLY:
  `findNonDiagonalWireGate` consults the taint set in exactly ONE place — the F-1b-1 chained-theta
  arg-0 crossing — and its forward half tests no taint at all. So the walk is run twice:
  **taint-aware DIRTY ∧ taint-blind CLEAN** ⇒ this gate is on the wire only because of a rail merge
  the classifier did not know about ⇒ re-ask the DT prong and decline if unproven. A gate that is
  already reachable taint-blind was visible to the classifier, which ruled on it, and **that ruling
  cannot be re-derived here** — `RegionFlatten` has erased the diamond and the round-2
  `collapseFlattenedLoopRails` has erased the loop-header rail phi that `gateIsHarmless`' barrier
  needs. Asking anyway costs 12 shipped in-loop accepts (§5). Residual: O-3.

### 1f. What did NOT change

`AllowLogicalSelect` still defaults `false` at the data select. P1 / `SawValueArm` untouched. No DT
prong added for compare seeds at classification. `reverifyRailCondReads` is byte-for-byte the rail
ladder's (the one experimental widening of it was reverted — see the comment at `ArmClassify.cpp`
in that loop). No runtime symbol, no `tools/opcode_table.yaml`, no `include/` change
(`git status --porcelain runtime/ tools/opcode_table.yaml include/` is empty).

---

## §2 — The recording sites, enumerated by grep

```
grep -rn "lowerCompareToFlag(\|emitEqFlag(\|lowerCompareToFlagRail(" ir-pass/src/*.cpp \
  | grep -v CompareLowering.cpp
```

| file | calls | in the record? |
|---|---|---|
| `SwapRouteEmit.cpp` | 6 | **YES** — flat kickback, value region, `emitRegion` (forward mints only; the `inverse=true` strips are not reads) |
| `AngleSelectEmit.cpp` | 4 | **YES** |
| `CondTreeEmit.cpp` | 2 | **YES** — the leaf mint, which is the path `SelectMergeEmit`, the flat kickback and the 4.3 nest all take |
| `ClassicalCallArmEmit.cpp` | 2 | **YES** (6.5) |
| `IOSinkLowering.cpp` | 2 | **YES** (7.6 controlled sink; `lowerControlledIOSinks` runs before `detectControlRegions`, so its records are re-verified too) |
| `AbortParkEmit.cpp` | 1 | **YES** (7.2) |
| `GuardedStoreArmEmit.cpp` | 1 | **YES** |
| `Specialization.cpp` (`mintCondNetwork`) | 1 | **OUT, structurally** — it passes the CLONE's `cloneTaint`, so the record lands in a different `TaintSet` the stage never reads; and `specialize` runs AFTER this stage anyway. Nothing was added to force it out; it is out by construction. Recorded as O-5. |
| `CompareLowering.cpp` `rewriteCompare` | 1 | **OUT, explicitly** — the straight-line DATA path, `/*recordCondRead=*/false` with both reasons written at the call site (`:507`) |
| `CompareLowering.cpp` `lowerCompareToFlagRail` | (definition) | **IN** by default; it has **ZERO callers at HEAD** (measured — the 4.3 nest stopped routing at 3qlq Inc 1), so the choice costs nothing and fails toward decline if revived |
| `Switch{Route,Value,DataMux}Emit.cpp` | 2 each | **OUT** — they mint through `emitEqFlag(Q, caseValue, …)`, not `lowerCompareToFlag`; there is no `CmpInst`. O-4. |

---

## §3 — Rule 12 red-green log

Every DECLINE fixture was written first and run on the ORACLE binary. `RUN: not %cq-opt …` means
RED there is `oracle rc == 0`:

```
$ORA/cq-opt -load-pass-plugin $ORA/libCQPass.so -passes=cq-lowering -S <fixture> -o /dev/null ; echo $?
```

| fixture | oracle rc | subject rc |
|---|---|---|
| `control_swap_reject_select_cmp_measured_before.ll` | 0 (RED) | 1 |
| `control_swap_reject_select_cmp_measured_sidepath.ll` | 0 (RED) | 1 |
| `control_swap_reject_select_cmp_measured_parent_name.ll` | 0 (RED) | 1 |
| `control_swap_reject_select_cmp_inloop_measure_after.ll` | 0 (RED) | 1 |
| `control_swap_reject_select_cmp_inloop_measure_after_constarm.ll` | 0 (RED) | 1 |
| `control_swap_reject_select_cmp_round2_sibling_theta.ll` | 0 (RED) | 1 |
| `control_swap_reject_select_cmp_round2_plainc_twotu.ll` | 0 (RED) | 1 |
| `control_phase_kickback_reject_cmp_measured_before.ll` | 0 (RED) | 1 |
| `control_phase_kickback_reject_cmp_measured_sidepath.ll` | 0 (RED) | 1 |
| `control_phase_kickback_reject_cmp_round2_sibling_theta.ll` | 0 (RED) | 1 |
| `control_phase_nest_reject_cmp_round2_sibling_theta.ll` | 0 (RED) | 1 |
| `control_angle_select_reject_cmp_round2_sibling_theta.ll` | 0 (RED) | 1 |
| `control_phase_nest_reject_cmp_measured_before.ll` | 0 (RED) | 1 |

**13 declines + 7 accepts = 20 new fixtures**, corpus **1776 → 1796**.

`control_phase_nest_reject_cmp_measured_before.ll` is the **only** fixture in the increment that
pins the BACKSTOP rather than a classifier clause: `classifyPhaseKickbackNest` has no compare
rung-(ii) clause, so that program is refused by `reverifyCmpCondReads` alone, over the record
`lowerCompareToFlag` writes at `CondTreeEmit`'s leaf mint. It is the direct evidence for the
design decision in §1d — and the nest's conjunction toffoli is precisely the emitter the rail
record's first spelling missed (bd `r9e5`, `FIX_B1_R2.md`). The 7 accepts
(`control_swap_select_cmp_{measure_after,other_register_measured,inloop_hoisted_measure_after,inloop_iterlocal_measure_after,round2_window_accept,round2_opaque_seed_accept}.ll`
and `control_phase_kickback_cmp_measure_after.ll`) are GREEN on BOTH binaries and byte-unchanged.

Each fixture uses ONE `%cq-opt … > %t.cqd0.ll` with every prefix pointed at it; no standalone
`-passes=verify` line.

**Injection matrix** over all 7 new accepts × 4 mutations injected immediately before the first
control read (an extra `cqrt_measure`, a sibling `cqrt_ry` on the condition wire, an extra
`cqrt_free`, an extra `cqrt_x`): first run **2 MISSED** (`..._round2_window_accept.ll` was blind to
an extra measure and an extra `cqrt_x` — it had no `MCNT`/`XCNT`); after adding those two whole-file
exact-count prefixes, **28 mutations, 0 MISSED, 0 DIRTY**. Harness:
`scratchpad/trackA/inject.py`.

---

## §4 — e2e

Two new slices, both ACCEPTS and both discriminators (the increment's content is three new
DECLINES, so what e2e must witness is that the neighbouring CORRECT programs still lower). The
DECLINE half has no e2e home — `run_slice*.sh` runs under `set -euo pipefail` and byte-diffs a
golden, so a program whose `opt` exits non-zero cannot be a passing slice — and is pinned in lit,
exactly as the 1b-B.1 round-2 pair was.

* `tests/e2e/slice_control_select_cmp_measure_after.c` (+ golden, 14 lines, STRICT stage 2b:
  `8 rail mints, 8 left allocated, 2 free sites: 2 verified, 0 violations, 0 unproven`). The
  assertion is ORDER: `cq_template_icmp_eq_i32_hl(h0, 1)` at line 3, `cqrt_measure_i32(h0)` at line
  13. Registered as `e2e-slice-control-select-cmp-measure-after`.
* `tests/e2e/slice_control_select_cmp_round2_window.c` + `_lib.c` through `run_slice_multi.sh`
  (+ golden, 31 lines, STRICT stage 2b: `7 rail mints, 7 left allocated, 3 free sites: 3 verified,
  0 violations, 0 unproven`). The assertion is again ORDER: `cqrt_ry_i32(h6, 0x1p-2)` (`b`), the
  merge on `h6`, `cqrt_free(h7)`, THEN `cqrt_ry_i32(h6, 0x1.ccccccccccccdp-1)` (`b3`) — source
  order, with both siblings on ONE rail. Registered as
  `e2e-slice-control-select-cmp-round2-window`.

Both goldens were read line by line against the analytic stream before registration. Goldens
**341 → 343**; ctest entries **387 → 389**.

Note on the first slice: its `main` originally did the arithmetic itself, which (a) returned
non-zero and tripped `set -euo pipefail` and (b) let `-O1` DCE the merge down to a 3-line trace.
It is now `slice()` + `main(){ (void) slice(); return 0; }` with BOTH results measured, which is
the tree's convention and what keeps the merge alive.

---

## §5 — Corpus diff and probe diff

**Fixture corpus** (`scratchpad/trackA/corpus_diff.py`; oracle vs subject over every
`ir-pass/test/*.ll` present on `main`, comparing rc + stdout + stderr):

```
FIXTURES=1776 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0
```

**0 DECLINE→ACCEPT, 0 ACCEPT→DECLINE, 0 changed diagnostics, 0 changed output.** No pre-existing
fixture pinned any of the three holes, so the "if one exists, list it" case is empty.

> ⚠ **CORRECTION (round-1 fix, `FIX_A1_R1.md`; finding F-A1-2). "Decline-monotone" is true of the
> 1776 FIXTURES and false of the PROGRAM SET, and the difference is exactly two programs.** The
> increment is decline-monotone **on the COMPARE path**; on the **RAIL** path it has **two named
> ACCEPT movers**, because rung (ii)'s per-activation barrier (§1b) lives in
> `railMeasuredBeforeReadPoint`, which is SHARED with the 1b / 1b-B.1 rail ladder
> (`classifyPhaseKickback` step 5b, `classifySelectRegion`'s rail loop, `reverifyRailCondReads`).
> The two are `review_a1_r1_probes/b1.c` (a bare-`_Bool` kickback) and `b2.c` (the 4.4 data select),
> both `for (i<3) { _Bool b = cq_theta(0,.5); …; acc += cq_measure(b); }`: **DECLINE on `main`
> 0c7380c, ACCEPT here.** Both accepts are CORRECT and the physical premise was checked rather than
> assumed — the lowered body keeps `cqrt_alloc_i1` INSIDE the loop, so each trip is a fresh register
> and the body measurement owns only its own trip. They are now pinned by
> `control_phase_kickback_rail_inloop_iterlocal_measure_after.ll`,
> `control_swap_select_rail_inloop_iterlocal_measure_after.ll` and the e2e pair
> `slice_control_phase_bool_loop_iterlocal{,_unrolled}` + `e2e-phase-bool-loop-iterlocal-twin-identical`.
> The e2e pair also records something the lit fixtures cannot: on `main` the ROLLED form DECLINES
> while its hand-unrolled twin ACCEPTS (measured), so this is a rolled ≠ unrolled divergence the fix
> CLOSES — 12 = 12, byte-identical.
>
> ⚠ **AND "EXACTLY TWO, BY NAME" IS ITSELF CORRECTED (round-2 finding F-A1R2-3, `FIX_A1_R2.md`).**
> The class — an ITERATION-LOCAL register whose SOURCE-theta origin re-executes on every path from
> the measurement back to the read — has at least **five** measured plain-C members: `b1`, `b2`
> (constant seed), `r3` (loop-CARRIED classical seed), `b3` (loop-INVARIANT non-constant seed, NOT
> LICM'd out) and `b4` (origin in a guarded sub-block). `r3`/`b3`/`b4` are pinned by
> `control_phase_kickback_rail_inloop_iterlocal_{carried_seed,invariant_seed,guarded_block}.ll`.
> Say the CLASS and its ground; a list of names reads as an exhaustive claim about programs and is
> not one. ⚠ **And the FIXTURE-corpus monotonicity above is now broken by exactly one file** — see
> `FIX_A1_R2.md` F-A1R2-1 (`lowering_live_record_tape_ctrl_observed_accept.ll` → `..._reject_...`).
>
> The narrowing of rung (ii)'s seed (F-A1-3, `FIX_A1_R1.md`) adds two more ACCEPT movers, both on the
> COMPARE path and both against the FIRST Track-A.1 build rather than against `main`:
> `review_a1_r1_probes/c1.c` and `c10.c` accepted on `main`, were over-declined by the first build,
> and accept again here. Against `main` they are not movers at all.

Two intermediate spellings were rejected BY this measurement, and both are worth the reviewer's
attention because each looked correct:

1. **One record entry per cone member** (rung (iii) asked with a singleton seed array): **14
   movers**, all ACCEPT→DECLINE, all in-loop. Cause: `gateIsHarmless` grows its barrier set from
   the seed array.
2. **Rung (iii) re-asked unconditionally** (both prongs, whole cone): **12 movers**, all
   ACCEPT→DECLINE, all in-loop (`control_swap_inloop_post_region_theta.ll` and 11 siblings, plus
   `control_angle_select_rz_loop_rail_exit_block.ll` and
   `lowering_live_record_tape_ctrl_observed_accept.ll`). Cause: the position-aware prong's barrier
   (the loop-header rail phi) is erased by the round-2 rail collapse before this stage runs.

**Probe corpora** (`scratchpad/trackA/probe_diff.py`; `session-r9e5/probes`,
`review_b1_r{1,2,3}_probes` incl. their `multi/` two-TU pairs, `session-3qlq4/probes`,
`review_1b_r1_probes`, and this session's `session-9pum/probes`; `session-r903`, `session-l4x4`,
`session-boi6` do not exist in this worktree):

```
probes=114 clangfail=0 movers=8
```

All 8 are ACCEPT→DECLINE, each with one of the two existing strings, and each is a target shape:

| probe | new diagnostic | why the decline is right |
|---|---|---|
| `session-r9e5/probes/m2_inloop_select_measure_after_compare_twin.c` | measured before | bd `r10v` itself — trips 2/3 control on a collapsed register |
| `review_b1_r2_probes/multi/e13_caller.c` | predates a non-diagonal gate | bd `9pum` itself — the flag is minted from `Ry(.9)Ry(.25)\|y⟩` while the source compares `Ry(.25)\|y⟩` |
| `session-9pum/probes/r10v.c` | measured before | same program as the first row |
| `session-9pum/probes/r903b.c` | measured before | bd `r903` (b) — flag minted after `cqrt_measure_i32` on the same handle |
| `session-9pum/probes/d1_sel_cmp_measured_before.c` | measured before | flat select twin of `r903b` |
| `session-9pum/probes/d2_sel_cmp_measured_sidepath.c` | measured before | on the guarded path the register is collapsed before the mint |
| `session-9pum/probes/d3_sel_cmp_measured_parent_name.c` | measured before | `q` and `q2` are ONE rail after `lowerRotations`; the measure names the parent |
| `session-9pum/probes/d4_kick_cmp_measured_sidepath.c` | measured before | `br`-path twin of `d2` |

---

## §6 — Gates run (Rule 19), with the numbers

| gate | command | result |
|---|---|---|
| per fixture | `cd build && lit ir-pass/test --filter '<name>'` | used throughout |
| lit | `ctest --test-dir build -R ir-pass-lit --output-on-failure` | **Passed, 161.65 s, 0 failed** |
| lit detail | `cd build && lit -s ir-pass/test` | **1795 discovered · 1794 passed · 1 expectedly failed · 0 unexpected**, 135.80 s — taken at 1795 fixtures; the 20th new fixture landed after it and the `ctest -R ir-pass-lit` entry in the full run above (81.24 s, Passed) covers all 1796 |
| e2e | `ctest --test-dir build -j6 -R '^e2e-' --output-on-failure` | **379/379 passed, 0 failed, 2703.08 s** (`e2e-loop-twin-matrix` alone was 1807.76 s and is the long pole) |
| `git status --porcelain tests/` | — | `M tests/e2e/CMakeLists.txt` + the 5 new untracked files ONLY — **no pre-existing golden changed** |
| full suite | `ctest --test-dir build -j6 --output-on-failure` | **388/389 passed, 1 failed, 1542.69 s** — the one failure is `e2e-loop-twin-matrix` and it is CONTENTION, established three ways (below) |
| the re-run | `ctest --test-dir build -R '^e2e-loop-twin-matrix$' --output-on-failure` | **1/1 Passed, 1012.46 s** |
| equivalence | `cmake --build build --target cq-opt-equivalence-full` | **compared 1796 fixtures, 0 mismatch(es)** |

### The one full-suite failure, and why it is not a regression

`e2e-loop-twin-matrix` reported `FAILED (12)` in the `-j6` full run. All twelve messages derive
from **six** cells, and every one of the six is `stage 4 (run) exited -9` — SIGKILL
(`grep -c 'exited -9'` → 6). The other six are the consequential
`verdict changed: expected ACCEPT-IDENTICAL, got HARNESS-ERROR` and one
`QUARANTINE STALE — REMOVE IT` for a cell that never got to diverge because its binary was killed.

Three independent facts say contention, which is exactly the disposition CLAUDE.md prescribes
("Contention causes false FAILURES, never false passes … re-run any -j failure serially BEFORE
calling it a regression"):

1. the machine was running the other parallel tracks — `uptime` load averages sampled during this
   run were **113, 140, 118** (1-minute), against 6 physical cores;
2. **the same test passed on the same binary and the same tree** in the `^e2e-` gate 90 minutes
   earlier: `379/379 passed, e2e-loop-twin-matrix … Passed 1807.76 sec`;
3. re-run **alone**: `1/1 Passed, 1012.46 sec`, 0 failed.

A SIGKILL of a slice binary is also the wrong shape for a lowering regression: a miscompile from
this change would show as a TRACE-DIVERGENCE or a decline-string move, both of which the matrix
reports by name, and neither appeared.

Counts, measured: `ls ir-pass/test/*.ll \| wc -l` → **1796**;
`ls tests/e2e/*.expected.log \| wc -l` → **343**; `ctest --test-dir build -N \| tail -1` → **389**.

---

## §7 — Open questions for the reviewer

Everything here is a decision a reviewer could dispute. None is hidden in a comment.

**O-1 — the helpers kept their `rail` names.** `railWireNamesBackward` and
`railMeasuredBeforeReadPoint` now take any tainted value naming a register. The brief offered a
rename; I kept the names because "rail" in this tree means a physical register wire and a compare's
tainted operand names one — and because renaming would strand the name in ~20 shipped fixture
headers that describe the 1b-B.1 history. If the reviewer prefers `condWire*`, it is a mechanical
rename of 2 functions and their 6 call sites.

**O-2 — rung (ii) seeds from the `condProvenance` CONE, not the compare's direct operands.** The
brief's §1.1 says "for each TAINTED operand". The cone is strictly wider and I chose it so that
rungs (ii) and (iii) are computed over ONE closure (the bd `8h7d.5` F-1/F-3 lesson). Cost measured:
0 movers over 1776 fixtures and 114 probes. If a reviewer thinks the cone over-declines, the
narrowing is one line in `condCmpMeasuredBeforeReadPoint`.

> **ANSWERED, round-1 finding F-A1-3 (OVER-DECLINE, plain C): the cone was wrong and is NARROWED.**
> "0 movers over the corpus" measured that the cone costs nothing on programs already in the tree; it
> did not measure what it costs on programs that are not, and two of the reviewer's four were real
> (`c1`, `c10`). Rung (ii) now seeds from `condCmpOperandSeeds` — the compare's DIRECT tainted
> operands — at BOTH askers (`condCmpMeasuredBeforeReadPoint` and, through the record's new
> `OperandSeeds` field, `reverifyCmpCondReads`). Rung (iii) keeps the cone, so the 8h7d.5 lesson is
> preserved where it applies (`gateIsHarmless` grows its barrier set from the seed ARRAY) and is not
> applied where it does not: the two rungs ask DIFFERENT questions, and "one closure" was the wrong
> unification. The WIRE is untouched and now crosses `taint.InPlaceRailOps` as well.

**O-3 — THE RESIDUAL OF RUNG (iii), and it is the one thing I could not close.** A gate that was
ALREADY reachable taint-blind at round 1, and whose WIRE the round-2 merge then changed, is not
re-examined by `reverifyCmpCondReads`. The classifier looked at that gate and ruled on it; what
this stage cannot do is re-derive the ruling, because the flatten and the round-2
`collapseFlattenedLoopRails` have erased the positions and the barrier phi that ruling used. I
found no program in this class (it needs a condition whose wire already carries a visible gate AND
a round-2 rail merge on the same wire), but I did not prove it empty. The honest closure is to
record the classifier's own disposition per compare at classification time and re-ask only where it
said CLEAN — which is a second record and a second round, i.e. A.2 or later, not a line change
here. **I did not weaken any rung to avoid this; I narrowed the RE-ASK, and the classifier's
round-1 answer still stands unmodified underneath it.**

> **ANSWERED, round-1 finding F-A1-1 (CONFIRMED SILENT MISCOMPILE, the BLOCKER): O-3 was NOT empty.**
> `review_a1_r1_probes/k7_caller.c` + `lib3.c` is a member, plain C, two TUs, and it is `k8` — this
> increment's own decline — plus ONE line. The re-ask was suppressed by a BOOLEAN while
> `findNonDiagonalWireGate` returns ONE GATE, so "SOME gate is visible taint-blind" stood in for
> "THIS gate is", and a legitimately-accepted S-dagger bought the whole program back. It is now a SET
> DIFFERENCE: `collectNonDiagonalWireGates` enumerates the taint-blind set and it is handed back as
> the walk's `Covered` exempt set. The residual is narrower, not gone — a gate the classifier
> ACCEPTED whose wire the round-2 merge then changed is still exempted by identity — and closing that
> still needs the classifier's disposition recorded per compare.

**O-4 — the SWITCH is out of the record and I could not measure whether it has the same hole.**
`Switch{Route,Value,DataMux}Emit` mint through `emitEqFlag(Q, caseValue, …)`, which has no
`CmpInst` and never reaches `lowerCompareToFlag`. The obvious probe
(`probes/x1_switch_measured_before.c`: `m = cq_measure(q); switch (q) { … }`) declines
`control flow` on BOTH binaries, so the shape is pre-empted by an earlier gate at that spelling and
I have **no measured evidence either way**. Extending the record to `emitEqFlag` is a ~5-line
change (the seed is the scrutinee) but it is out of A.1's stated scope and would need its own
decline partition. Filed here rather than done.

**O-5 — `Specialization::mintCondNetwork` is OUT by construction, not by a written fence.** It
passes the clone's `cloneTaint`, so its records land in a `TaintSet` this stage never reads, and
`specialize` runs after the stage anyway. Both facts are true today and neither is asserted
anywhere. If the specializer is ever given the module `TaintSet`, the record silently starts
working and has never been reviewed for that path.

> **MEASURED (round-1 item F-A1-5(b)): the path is not reachable with a control read at all, on
> EITHER binary.** `review_a1_r1_probes/sp1.c` (a tainted-condition `select` inside a lifted callee)
> declines `cq specialization: callee contains tainted control flow under quantum lift`, and
> `sp2.c` (a branch phase inside it) declines `callee contains a quantum primitive (cq_*)` — both on
> `main` 0c7380c and here. "Out by construction" was an argument from two structural facts; this is
> the measurement that says so, and it belongs beside them.

**O-6 — `reverifyCmpCondReads` is a SECOND function beside `reverifyRailCondReads`, not a merge.**
They share both rung helpers but differ in one real way: the rail ladder is asked per RAIL with a
singleton cone, the compare ladder over the whole cone at once, and merging them would change the
rail path's `Seeds` array (which `gateIsHarmless` reads). The brief requires the rail ladder
byte-for-byte, so I kept them apart. If a reviewer wants one loop, the entry needs a seed-species
tag and the rail entries must still be asked singly.

**O-7 — the per-activation barrier (§1b) is a WIDENING of a Rule-13-core predicate in the ACCEPT
direction.** It exists to stop an over-decline of 5 shipped fixtures, and I restricted it as far as
I could (source theta only). The argument is that a source theta's every execution mints a fresh
`cqrt_alloc_<W>` — which is the same (I1) ground `markIfRailLocal` rests on — but this is the
clause to attack first if the reviewer is looking for a hole.

> **ATTACKED SIX WAYS AND IT HELD (round-1 review), including the attack the reviewer expected to
> land — the round-2 window on the barrier ITSELF (`o7a_caller.c`: a `cq_theta` that is a SOURCE at
> round-1 taint and CHAINED at final taint), which the UNGATED rung (ii) in `reverifyCmpCondReads`
> catches: ORACLE ACCEPT (the r10v miscompile), SUBJECT DECLINE.** What the barrier DID cost is
> F-A1-2 — it reaches the SHARED rail ladder, with two plain-C accept movers — now pinned by two lit
> fixtures and an e2e twin pair, and the monotonicity claim in §5 is corrected accordingly.

**Nothing in A.1 refused a program whose circuit I believe is valid.** The two candidate
over-declines I hit (the 14 and the 12 in-loop movers) were both fixed by making the predicate
sharper, not by weakening it; both are now pinned by accept fixtures whose headers say what goes
red if the sharpening is deleted.
