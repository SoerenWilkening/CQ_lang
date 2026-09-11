# FIX_A1_R1 — Track A.1, the round-1 Rule-13 fix (`review_a1_r1.md`, verdict **BLOCK**)

Fix record for the five findings of the round-1 adversarial review of branch `compare-select-parity`
(worktree `/Users/sorenwilkening/Desktop/CQ_trackA`, from `main` 0c7380c). **Checkpointed on the
branch as `b439944` (`wip(control):`, to be squashed at landing) and NOT pushed** — this line read
"not committed, not pushed" until 2026-09-11 and was stale by the time the round-2 review read it
(round-2 item F-A1R2-5). ORACLE for every A/B figure: `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
(+ `libCQPass.so`) at `main` 0c7380c, read-only. Nothing was written under the primary checkout or
the other worktrees. Both targets (`CQPass` **and** `cq-opt`) were rebuilt after every source edit.

Read `review_a1_r1.md` first; this file is per finding → change (file:line) → fixtures →
measurements, then the round-2 open questions.

---

## F-A1-1 — the BLOCKER: rung (iii)'s round-2 re-ask is now a SET DIFFERENCE, not a boolean

### What was wrong

`reverifyCmpCondReads` suppressed the whole rung-(iii) re-ask for an entry whenever
`findNonDiagonalWireGate(Seeds, …, /*Taint=*/nullptr)` returned non-null. That walker returns **ONE
gate**, so the code tested *"is SOME gate visible taint-blind?"* while the comment asserted *"is
THIS gate visible taint-blind?"*. In `k7` the taint-blind walk returns the post-region S-dagger
`%18 = cq_theta(%13, -0.25)` — a gate `condWireDisposition`'s DT prong legitimately proves
post-region and ACCEPTS — and its visibility suppressed the re-ask about `%14 = cq_theta(%6, 0.9)`,
the sibling only round-2 taint puts on the same rail. bd `9pum` returned verbatim, from two TUs of
plain C, at `opt` exit 0.

### The change

* `ir-pass/include/WireWalk.h` — `findNonDiagonalWireGate` gains a trailing
  `const SmallPtrSetImpl<const CallInst *> *Covered = nullptr`: gates a caller has already ruled on
  are skipped as EVIDENCE while their own forward wire is still walked (the exemption names a gate,
  never a subtree). New sibling `collectNonDiagonalWireGates(…, SmallVectorImpl<CallInst *> &Out)`
  — the ENUMERATING face of the same walk.
* `ir-pass/src/WireWalk.cpp` — ONE implementation, `walkNonDiagonalWireGates` (Rule 14); the two
  public faces are three-line wrappers. `Out != nullptr` appends every staling gate and keeps
  walking (pushing the gate forward, so the enumeration is transitive); `Covered` is tested BEFORE
  the harmlessness proof, because it is an identity question that needs neither positions nor a
  tree — which is what keeps the two walks of the difference comparable.
  **Every existing caller passes neither and is byte-for-byte unchanged** (measured: corpus diff).
* `ir-pass/src/ArmClassify.cpp`, `reverifyCmpCondReads` rung (iii) — the taint-blind set is
  ENUMERATED and handed back as `Covered`:

```cpp
SmallVector<CallInst *, 8> BlindGates;
collectNonDiagonalWireGates(Seeds, true, nullptr, nullptr, /*Taint=*/nullptr, BlindGates);
SmallPtrSet<const CallInst *, 8> Covered(BlindGates.begin(), BlindGates.end());
if (!findNonDiagonalWireGate(Seeds, true, nullptr, nullptr, &Taint, &Covered))
  continue;                                   // every final-taint gate was the classifier's
if (findNonDiagonalWireGate(Seeds, true, Read, DT, &Taint, &Covered))
  diagnoseUnderControl(Read, "condition predates a non-diagonal gate");
```

  The soundness of using the taint-BLIND set as the exempt set is a containment, and it is written
  at the call site: the F-1b-1 crossing only ADDS values to the backward closure, so
  **blind ⊆ round-1 ⊆ final** — exempting the blind set exempts no more than the classifier actually
  saw, and is therefore conservative toward DECLINE relative to the round-1 ruling.

### Fixtures

| file | kind | oracle | pre-fix subject | here |
|---|---|---|---|---|
| `control_phase_kickback_reject_cmp_round2_sibling_theta_sdagger.ll` | DECLINE, the committed two-TU stage-1 module of `k7` | **ACCEPT (rc 0, no diagnostic)** | **ACCEPT** | DECLINE |
| `control_phase_kickback_cmp_sdagger_post_region.ll` | ACCEPT control — the S-dagger ALONE, no round-2 sibling | ACCEPT | ACCEPT | ACCEPT |
| `control_phase_kickback_reject_cmp_round2_sibling_theta.ll` (pre-existing) | the same program WITHOUT the S-dagger | ACCEPT | DECLINE | DECLINE |
| `session-9pum/probes/k10_caller.c` + `review_a1_r1_probes/lib3.c` | the plain-C form of the accept control | ACCEPT | ACCEPT | ACCEPT |

⚠ **Say precisely what the ACCEPT control does and does not prove, because the obvious claim is
wrong.** It is NOT true that "re-ask about every gate" would decline `k10`: with the suppression
simply deleted, `k10`'s only gate is the S-dagger, the position-AWARE prong would be asked about it,
and in an acyclic function a post-region gate is PROVEN harmless there — so `k10` survives that
spelling too. What "re-ask about every gate" actually costs is the **twelve shipped in-loop
accepts** the implementer measured (IMPL §5), where `collapseFlattenedLoopRails` has erased the
loop-header rail phi that `gateIsHarmless`' barrier needs, so the position-aware prong cannot prove
anything. `k10`'s job is narrower and still real: it pins that the S-dagger capability survives the
CHANGE — the thing this fix could most easily have broken — and it is the file that goes red if the
exempt set is ever widened into a suppression again or narrowed into a blanket refusal at the
position-free stage. The mutation measurement for the exempt set itself is below.

### Measurements

* `review_a1_r1_probes/run.sh`, both binaries, before and after — `k7` **ACCEPT → DECLINE**
  `condition predates a non-diagonal gate`; `o3_kick.ll` **ACCEPT → DECLINE**; `k8`, `k9`
  unchanged (DECLINE); `k6` unchanged (DECLINE on both).
* the twelve in-loop accepts the "unconditional re-ask" spelling would have cost: **all green**
  (`ir-pass-lit`, and the corpus diff below shows 0 movers).

---

## F-A1-2 — the two RAIL-path accept movers are pinned, and the record is corrected

Both accepts are CORRECT and the physical premise was re-checked rather than assumed: the lowered
body keeps `cqrt_alloc_i1` INSIDE the loop, so every trip mints a fresh register and the body
measurement owns only its own trip's rail.

* `ir-pass/test/control_phase_kickback_rail_inloop_iterlocal_measure_after.ll` — ACCEPT (`b1.c`
  verbatim `clang -O1`), **ORACLE rc 1** `condition measured before the control route`.
* `ir-pass/test/control_swap_select_rail_inloop_iterlocal_measure_after.ll` — ACCEPT (`b2.c`),
  **ORACLE rc 1**, same string.
* Both carry per-activation `ACNT` / `MCNT` / `RYCNT` / `FCNT` / `XCNT` whole-file counts and a
  `CHECK-LABEL` pinning the mint INSIDE the loop block (which is the ground of the accept), plus a
  `NOROUTE` negative.

**e2e — the traces ARE byte-identical, so the twin pair is registered** (measured first, as the
brief required):

* `tests/e2e/slice_control_phase_bool_loop_iterlocal.c` + golden (12 lines), STRICT stage 2b
  `1 file(s), 2 rail mint(s) … 0 violation(s), 0 unproven`;
* `tests/e2e/slice_control_phase_bool_loop_iterlocal_unrolled.c` + golden (12 lines), STRICT
  stage 2b `3 rail mint(s) … 0 violation(s)`;
* `e2e-phase-bool-loop-iterlocal-twin-identical` (`compare_files`) — **12 = 12**.

The trace is the argument: `h0`, `h1`, `h2` — three DISTINCT handles, one
`alloc + ry + rz + measure` group per trip. ⚠ And the pair records something no lit fixture can:
**on `main` 0c7380c the ROLLED form DECLINES (rc 1) while its hand-unrolled twin ACCEPTS (rc 0)** —
measured — so this is a rolled ≠ unrolled divergence that the barrier CLOSES.

**The record is corrected** in two places, both as ERRATA rather than by rewriting what was
believed: `IMPL_A1.md` §5 (with the two movers named) and an ERRATA block at the head of
`BRIEF_A1.md` §1. The corrected sentence is: *A.1 is decline-monotone on the COMPARE path, and has
exactly these two rail-path ACCEPT movers, by name.* ⚠ **CORRECTED in round 2 (F-A1R2-3): the
class has at least FIVE measured plain-C members (`b1`, `b2`, `r3`, `b3`, `b4`) and must be stated
as a class — an iteration-local register whose source-theta origin re-executes on every path from
the measurement back to the read — not as a list of names. See `FIX_A1_R2.md`.**

---

## F-A1-3 — rung (ii)'s seed is NARROWED to the compare's direct operands' WIRES

### The change

* `ir-pass/src/ArmClassify.cpp` — new `condCmpOperandSeeds(Cmp, Taint, Out)`: the compare's DIRECT
  tainted operands. ONE spelling, two askers.
* `condCmpMeasuredBeforeReadPoint` now seeds from it instead of `condProvenance`.
* `TaintSet::CmpCondRead` gains `OperandSeeds` beside `Seeds` (`ir-pass/include/TaintPropagation.h`),
  written by `lowerCompareToFlag` (`ir-pass/src/CompareLowering.cpp`) at the same statement as the
  cone, because the `CmpInst` does not survive to the backstop; `reverifyCmpCondReads`' rung (ii)
  reads `OperandSeeds` and rung (iii) keeps the cone.
  **The two rungs ask different questions and must not share one set** — "one closure" was the wrong
  unification of the 8h7d.5 lesson; what that lesson actually constrains here is `gateIsHarmless`
  growing its barrier set from the seed ARRAY, which is rung (iii)'s, and is untouched.
* `railWireNamesBackward` — the WIRE is unchanged except that it now CROSSES an IN-PLACE
  relabelling (`taint.InPlaceRailOps` + `InPlaceRailIdx`, the eqpx spelling: the set and the proven
  operand index written by one helper). The narrowing is of the SEED, never of the wire.

### Measured, and it corrects the review's own table by two rows

| probe | source | oracle | pre-fix | here | why |
|---|---|---|---|---|---|
| `c1.c` | `int t = q + 3; m = cq_measure(q); a = (t==5)?2:5;` | ACCEPT | DECLINE | **ACCEPT** | the add lowers OUT of place — `cq_template_add_i32_hl(%h,3)` mints a FRESH rail and the flag reads `%h_op` |
| `c10.c` | `short t = (short) q; …` | ACCEPT | DECLINE | **ACCEPT** | same: `-O1` gives `and i32 %1, 65535`, a separate out-of-place rail |
| `c2.c` | `long long t = (long long) q; …` | ACCEPT | DECLINE | **DECLINE** | ⚠ `-O1` FOLDS the sext: the stage-1 IR is `icmp eq i32 %1, 5`, so the compare's DIRECT operand IS the measured register |
| `c9.c` | `int t = q + 3; … if (t > 3) …` | ACCEPT | DECLINE | **DECLINE** | ⚠ `-O1` rewrites `(q+3)>3` to `icmp sgt i32 %1, 0` — same register, bd `r903` item (b) verbatim |
| `c7.c`, `c8.c` | the MIRROR (derived rail measured, parent controlled) | ACCEPT | ACCEPT | ACCEPT | the asymmetry that made this a defect is gone |
| `c3.c`, `c4.c` | controls (other register / measure-after) | ACCEPT | ACCEPT | ACCEPT | unchanged |

So **two of the four reported over-declines were not over-declines**: their stage-1 IR puts the
measured register directly in the compare. That is the discriminating fact the narrowing rests on —
it is about the WIRE the EMITTED gate reads, not about the source spelling — and it is pinned by
`control_phase_kickback_reject_cmp_derived_folded_to_parent.ll` (`c9`, ORACLE rc 0 ⇒ RED).

### Fixtures

* `control_swap_select_cmp_derived_operand_parent_measured.ll` — ACCEPT (`c1`), asserting WHICH rail
  the flag reads (`%h_op`, not `%h`) plus the whole-file `NOPOST` negative on the measured register (mutation-validated), `MCNT`/`FCNT`/`NOROUTE`.
* `control_swap_select_cmp_parent_operand_derived_measured.ll` — ACCEPT (`c7`), the mirror; also the
  STOP pin for the wire closure (a measurement of `%h_op` is not a measurement of `%h`).
* `control_phase_kickback_reject_cmp_derived_folded_to_parent.ll` — DECLINE (`c9`), RED on the oracle.

### The IN-PLACE face, measured — and it has no reachable DECLINE today

The brief asked for both faces. The ACCEPT face is the whole corpus (0 movers, below). For the
DECLINE face I could not build a program that reaches the crossing: every spelling I tried is
pre-empted ONE STAGE EARLIER by `LoopLowering::staleRailRecordRead`
(`cq loop lowering: rail record read past an in-place gate on the same rail`), on BOTH binaries —
committed as `probes/ip1_inplace_preloop_measure.c` (measure before the loop) and
`probes/ip3_inplace_inbody_measure.c` (measure in the body); two further variants (`ip2`, `ip4`)
decline the same way or on `loop-carried tainted value crosses iterations`. That is not surprising:
a `cq_measure` of a rail name past an in-place gate IS `staleRailRecordRead`'s subject.

The crossing is therefore **insurance, not a live fence**, and it is kept for one stated reason: it
makes the narrowing's soundness LOCAL instead of resting on another stage's fence (the same
dependency `railWireNamesBackward`'s existing STOP already carries as the F-B1R2-3 retirement
trigger). It is monotone toward decline and costs 0 movers. Flagged as round-2 open question **Q-3**.

---

## F-A1-4 — PRE-EXISTING, filed: the `switch` mints eq-flags from a measured scrutinee

No code. The reviewer's `sw1.ll` / `sw2.ll` are copied to `session-9pum/probes/` and the README row
points at **bd `test_C_libtooling-lo7u`** (filed by the orchestrator 2026-09-11). Verdicts re-measured
here: `sw1.ll` (the `switch` spelling) ACCEPT on both binaries; `sw2.ll` (the `icmp`+`br` twin of the
same program) ACCEPT on the oracle, DECLINE here. `Switch{Route,Value,DataMux}Emit` mint through
`emitEqFlag(Q, caseValue, …)`, which has no `CmpInst` and never reaches `lowerCompareToFlag`, so
neither the new rung nor `CmpCondReads` covers it.

---

## F-A1-5 — the three DOC items

**(a) The one place the stage fails toward ACCEPT** is now marked as such in
`reverifyCmpCondReads`, with the argument written out: `WeakTrackingVH` **follows** a RAUW, so the
common case (a cone member RAUW'd to a 6.5/4.5 `%out` by `SelectMergeEmit`) keeps its entry and is
re-asked on the NEW value; a null therefore means the value was ERASED, and an erased value carries
no wire, has no `cq_measure` user and can gain no gate. With every seed gone there is no register
left to ask about. **Retirement trigger, written at the line:** a stage that erases a LIVE cone
member without RAUW-ing it makes this `continue` skip a real obligation, and it must then become a
decline. (I did not change it to a decline: measured, no entry in the corpus or the probe set
reaches it with a live register.)

**(b) O-5 is now measured, not argued** — `IMPL_A1.md` §7 O-5 carries the two verdicts:
`sp1.c` declines `cq specialization: callee contains tainted control flow under quantum lift`,
`sp2.c` declines `callee contains a quantum primitive (cq_*)`, both on both binaries.

**(c) The two ladders' divergence is stated** at `reverifyCmpCondReads`' header: this stage is
**strictly weaker than `reverifyRailCondReads` at rung (iii)** (the rail twin asks both prongs
unconditionally about every gate; this one asks only about the round-2 crossing, because for the
compare consumers the round-1 ruling can be an ACCEPT it cannot re-derive after the flatten), and
**rung (ii) is narrower by one deliberate step** (direct operands, not the cone). Rung (ii) itself
is identical in both, which is what makes the stage a real backstop.

## Mutation validation of the exempt set itself — the measurement that replaces the argument

Two mutants, each built from the shipped tree, `lit ir-pass/test` run on each, source restored and
both targets rebuilt afterwards (`grep -c MUTANT ir-pass/src/ArmClassify.cpp` → 0).

**M-1 — the exempt set DISABLED** (`Covered` passed as `nullptr` in both calls, i.e. "re-ask
position-free about EVERY gate at final taint"). **12 fixtures RED**, and they are exactly the class
IMPL §5 measured — nothing else moves:
`control_swap_inloop_{derived_cond,offwire_theta,range_cond,post_region_theta,postloop_railop,postloop_railop_mc,two_registers,railop_inplace}.ll`,
`control_phase_kickback_{inloop_body_gate,mixed_onward_r1open_inloop}.ll`,
`control_angle_select_rz_loop_rail_exit_block.ll`,
`lowering_live_record_tape_ctrl_observed_accept.ll`
(1803 discovered, 1790 passed, 1 XFAIL, **12 failed**). ⚠ Note what is NOT in that list:
`control_phase_kickback_cmp_sdagger_post_region.ll` stays GREEN under M-1, which is the measured
form of the correction above — the S-dagger survives "re-ask about everything" because the
position-AWARE prong proves it harmless; what the exempt set buys is the twelve IN-LOOP accepts,
where the round-2 rail collapse has erased the barrier phi that proof needs.

**M-2 — the pre-fix BOOLEAN suppression restored** (`if (!BlindGates.empty()) continue;` added after
the set-difference test). **EXACTLY ONE fixture RED**:
`control_phase_kickback_reject_cmp_round2_sibling_theta_sdagger.ll` (1803 discovered, 1801 passed,
1 XFAIL, **1 failed**). That is the red-green witness for F-A1-1 against the EXACT previous
spelling, not merely against `main`: the new decline fixture reddens if and only if the boolean
comes back, and nothing else in the corpus notices.

---

## Injection matrix over the round-1 fix's new ACCEPT fixtures

`scratchpad/trackA_fix/inject.py` — one gate injected immediately before each fixture's first
control read (`cq_template_*cmp*` / `cqrt_cnot` / `cqrt_rz_i1`), four mutations (an extra
`cqrt_measure`, a sibling `cqrt_ry` on the condition wire, an extra `cqrt_free`, an extra `cqrt_x`),
naming the module's first `cqrt_alloc` handle; "caught" means SOME prefix goes red, and the clean
control must stay green.

**First run: 1 MISSED** — `control_phase_kickback_cmp_sdagger_post_region.ll` was blind to an
injected `cqrt_x`, having no `XCNT`. After adding the whole-file count (`XCNT-COUNT-2` — the two
brackets belong to the 6.5 arm's copy merge; the kickback region emits none):
**5 accepts x 4 mutations, 0 MISSED, 0 DIRTY.**

Separately mutation-validated: the `NOPOST` whole-file negative on
`control_swap_select_cmp_derived_operand_parent_measured.ll` (the flag must never be minted from the
measured `%h`) — clean `FileCheck rc=0`, with one
`cq_template_icmp_eq_i32_hl(i32 %h, i32 9)` injected `rc=1`. It is a separate prefix precisely
because a trailing `CHECK-NOT` after the positives is windowed and asserts nothing.

---

## Gates (Rule 19), in the brief's order

| gate | command | result |
|---|---|---|
| per fixture | `cd build && lit -v ir-pass/test --filter '<name>'` | used throughout; every new fixture green, every new DECLINE RED on the oracle |
| lit | `ctest --test-dir build -R ir-pass-lit --output-on-failure` | **Passed, 78.11 s, 0 failed** (taken mid-sequence, at 1796 fixtures; the final colour is the full-suite row below, which runs the same entry on the shipped binary, and the post-mutation re-run: 1803 discovered, 1802 passed, 1 XFAIL) |
| lit detail | `cd build && lit -s ir-pass/test` | **1803 discovered · 1802 passed · 1 expectedly failed · 0 unexpected**, 109.57 s |
| corpus diff | `python3 scratchpad/trackA_fix/corpus_diff.py` (oracle vs subject, rc + stdout + stderr, over every `git ls-tree 0c7380c ir-pass/test/*.ll`) | **`FIXTURES=1776 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0`** — run twice, once after the F-A1-1 fix alone and once on the final binary |
| probe diff | `python3 scratchpad/trackA_fix/probe_diff.py` | **`probes=129 movers=17 clangfail=0`**, every mover listed below |
| reviewer probes | `session-9pum/review_a1_r1_probes/run.sh` | every row re-derived on both binaries. Against the ORACLE: `k7`/`o3_kick` **ACCEPT → DECLINE**. Against the PRE-FIX SUBJECT (the baseline run kept in the scratchpad): `k7`/`o3_kick` **ACCEPT → DECLINE** and `c1`/`c10` **DECLINE → ACCEPT**; every other row is unchanged in both comparisons |
| e2e | `ctest --test-dir build -j6 -R '^e2e-' --output-on-failure` | **382/382 passed, 0 failed, 973.94 s** (`e2e-loop-twin-matrix` alone 973.89 s — the long pole) |
| goldens | `git status --porcelain tests/` | `M tests/e2e/CMakeLists.txt` + the increment's own untracked additions ONLY — **no pre-existing golden changed** |
| full suite | `ctest --test-dir build -j6 --output-on-failure` | **392/392 passed, 0 failed, 1253.36 s** (`-j6`; `e2e-loop-twin-matrix` alone 1253.26 s) — Rule-19 gate moments 1 and 5 |
| equivalence | `cmake --build build --target cq-opt-equivalence-full` | **`cq_opt_equivalence: compared 1803 fixtures, 0 mismatch(es)`** |

Counts, measured: `ls ir-pass/test/*.ll | wc -l` → **1803** (1796 + 7);
`ls tests/e2e/*.expected.log | wc -l` → **345** (343 + 2);
`ctest --test-dir build -N | tail -1` → **392** (389 + 3), `^e2e-` **382**, `^e2e-slice-` **343**.


### The 17 probe-corpus movers (oracle → final subject)

**15 ACCEPT → DECLINE**, each a target shape: `9pum_caller.c` and
`review_b1_r2_probes/multi/e13_caller.c` (bd `9pum`, `predates a non-diagonal gate`);
`o3_kick.ll` (F-A1-1's hand-IR form, the same string) — ⚠ this one is NEW in this round, it
ACCEPTED on the pre-fix subject; `r10v.c` and
`session-r9e5/probes/m2_inloop_select_measure_after_compare_twin.c` (bd `r10v`); `r903b.c` (bd
`r903` item (b)); `d1`/`d2`/`d3`/`d4` (the four decline probes the increment shipped);
`sw2.ll` (the `icmp`+`br` twin of the `switch` gap — its `switch` spelling `sw1.ll` is unmoved,
which IS finding F-A1-4); `g3.c` (the value arm, backstop coverage); and — NEW in this round —
`c2.c` and `c9.c`, which the review listed as over-declines and which are NOT (their `-O1` compare
reads the measured register itself).

**2 DECLINE → ACCEPT**: `b1.c`, `b2.c` — the two F-A1-2 movers, by name, both correct, both pinned.

`c1.c` and `c10.c` are NOT movers against the oracle (they accept on both); they are movers against
the PRE-FIX subject, which is what makes them F-A1-3's red-green evidence.

⚠ Harness caveat, stated so the number is readable: `probe_diff.py` pairs two-TU probes by
`<stem>_lib.c`, so `review_a1_r1_probes`' `*_caller.c` + `lib3.c` pairs are compiled there as SINGLE
TUs (with `ext_f` an opaque declaration, which declines `control flow` on both binaries and is not a
mover). Those pairs are measured correctly by the reviewer's own `run.sh`, quoted above.

---

## Round-2 open questions

**Q-1 — the residual of rung (iii) is NARROWER, not empty, and it is the same shape O-3 named.** A
gate that was already reachable TAINT-BLIND at round 1, and whose WIRE the round-2 merge then
changed, is exempted here BY IDENTITY. The set difference stops one gate's visibility from
suppressing the question about every other gate on the wire; it does not let this stage re-derive a
ruling whose positions and barrier phi `RegionFlatten` and `collapseFlattenedLoopRails` have erased.
Closing it needs the classifier's own disposition recorded per compare (a second record, a second
round — A.2 or later). I did not find a program in the class; I did not prove it empty, and round 1
found a member of the last class I said that about.

**Q-2 — the taint-blind set is a LOWER bound on what the classifier saw, and the difference is an
over-decline, not an over-accept.** `blind ⊆ round-1 ⊆ final`. A gate that round-1 taint could
reach but the taint-blind walk cannot is NOT exempted, so it is re-asked position-aware and may
decline a program the classifier legitimately accepted. Measured cost: 0 movers over 1776 fixtures
and the probe corpora. The exact fix, if one is ever wanted, is the same per-compare disposition
record as Q-1 — not a wider exempt set.

**Q-3 — ANSWERED IN ROUND 2: KEEP IT. THERE IS A REACHABLE DECLINE FACE, from single-TU plain
`clang -O1` C** (F-A1R2-2, probe `f4f.c`, now pinned by
`control_phase_kickback_reject_cmp_inplace_xor_measured_parent.ll` with the accept control
`control_phase_kickback_cmp_inplace_xor_other_register.ll`). The round-1 probes missed it for a
measured `-O1` reason, not a failure of imagination: `ip1`/`ip3` used `add`, and `-O1` rewrites
`(q+1) > 5` SIDEWAYS onto the pre-`add` value, so the measured register lands directly in the
compare and the crossing is never needed; `xor` does not distribute over the compare. The original
question, left as written: **the `InPlaceRailOps` crossing in `railWireNamesBackward` has no
reachable DECLINE face at HEAD** (measured: `ip1`/`ip3`, pre-empted by `LoopLowering::staleRailRecordRead`). Keep it as local
insurance, or delete it and record the dependency on that stage as a retirement trigger? I kept it,
because the alternative makes a Rule-13 fence's soundness rest on a fence in another file — but it
is an untested branch and a reviewer may reasonably want it gone.

**Q-4 — rung (ii) is skipped when `OperandSeeds` is empty while `Seeds` is not.** Structurally this
needs a compare with a tainted ancestor and no tainted OPERAND, which cannot mint a quantum flag —
so it should be unreachable — but it is the (a)-class "fails toward accept" branch a second time and
I did not construct a witness either way.

**Q-5 — `condCmpOperandSeeds` collects BOTH operands of a Q+Q compare.** That is the conservative
direction (two registers asked instead of one) and costs nothing measured, but no fixture pins the
Q+Q face of rung (ii) specifically; the Q+Q declines that exist fire on other gates first.
