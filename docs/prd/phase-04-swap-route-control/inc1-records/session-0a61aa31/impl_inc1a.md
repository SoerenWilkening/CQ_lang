# progress — impl_inc1a (bd test_C_libtooling-3qlq.2, Inc 1 part A)
Branch `3qlq-inc1` in the MAIN checkout /Users/sorenwilkening/Desktop/CQ_lang, base dfb8e83.
Oracle binary: $SP/wt/pre-3qlq/build/ir-pass/cq-opt (pre-3qlq, 52d7764).

## Step 0 — compile the customer FIRST (DONE 2026-09-05)
Probes in `$SP/progress/impl_inc1a_probes/` (stand-in `void cq_phase(double)`; `.phi.ll` =
the same IR with the callee renamed `@cq_phi`, which is the NEW surface's spelling).
Stage 1 = `/usr/local/opt/llvm@19/bin/clang -I<repo>/include -include CQ.h -O1 -emit-llvm -S`.

MEASURED -O1 shapes — PRD §6.1 CONFIRMED in every row:
| probe | shape read from the IR |
|---|---|
| `p1_flat` | TWO sequential diamonds, arm = one `tail call void @cq_phi(double)` + `br`, merge has **NO φ**. Polarity NOT swapped for `==` (`br i1 %4, label %arm, label %merge`). |
| `p2_angsel` | ONE call on `%3 = select i1 %2, double 9.000000e-01, double 3.000000e-01`; no diamond at all. |
| `p3_nest` | ONE branch on `%5 = select i1 %3, i1 %4, i1 false` (the nest is FOLDED). |
| `p6_rolled` | 8h7d.5 in-loop diamond, no merge φ; two regions per trip; loop rolled with a header φ on `q`. |
| `p_perbit4/32` | rolled; `%6 = shl nuw nsw i32 1, %5` (classical) → `%7 = and i32 %6, %1` (tainted, LH) → `%8 = icmp eq i32 %7, 0` → `br i1 %8, label %merge, label %arm` — i.e. the arm is the **FALSE** successor (`ArmNegated`, Rule 9) and the condition register is a DERIVED base. IR size independent of K (loop body identical at 4 and 32). |
| `p7_uncontrolled` | straight-line call + a classical (`volatile int c`) diamond. |

PRE-INCREMENT DISPOSITION (ORACLE `$SP/wt/pre-3qlq/build/ir-pass/cq-opt`, on the `.phi.ll`):
```
p1_flat         exit=1  cq controlled lowering: nested control flow under quantum control
p2_angsel       exit=1  cq taint escape: tainted value consumed by an unknown callee
p3_nest         exit=1  cq controlled lowering: control flow under quantum control
p6_rolled       exit=1  cq controlled lowering: nested control flow under quantum control
p_perbit4       exit=1  cq controlled lowering: control flow under quantum control
p7_uncontrolled exit=0  — lowers, and the 2 `call void @cq_phi(double)` SURVIVE verbatim
                        (unknown external, no tainted operand → no escape, no delete)
```
So EVERY target shape of part A declines on the oracle, and P7's calls survive into the
lowered IR (they would link-fail: `@cq_phi` has no runtime body). Both facts are the
red half of red-green.

## Step 1 — surface (`include/CQ.h`) (DONE 2026-09-05)
- 15 `cq_phi_<sfx>(x, angle)` decls + the `cq_phi_f80` long-double decl + the
  `CQ_PHI_LDBL_` defines + the whole `_Generic` dispatch macro → ONE
  `void cq_phi(double angle);` extern with the D1/D2/D4 semantics in the comment.
- `tests/frontend/cq_phi_smoke.c` rewritten: 14 per-type CHECKs → `call void @cq_phi(double`,
  `declare void @cq_phi(double`, and a whole-file `CHECK-NOT: @cq_phi_`.
- MEASURED: `ctest --test-dir build -R frontend-lit` → **1/1 Passed (3.44 s)**.

## Steps 2+3 — recognition, P7, P1 kickback (CORE LOWERING WORKS 2026-09-05)
Files: `WidthDispatch.{h,cpp}` (`phaseFn()` = exact `@cq_phi`; 48→49 name table),
`TaintPropagation.{h,cpp}` (`PhaseCalls`; `resolveSources` DROPS the `@cq_phi_<sfx>` family
and validates `void(double)`; `isRegisterFreePhaseCall` = EXACT membership;
`deleteGlobalPhases` = P7), `ControlPlan.h` (`Kind::PhaseKickback`), `ControlShape.h`
(declare `flatRegionRollableInLoop`), `ArmAnalysis.h` + `ArmClassify.cpp`
(`classifyPhaseKickback`), `ControlDetect.cpp` (the THIRD pre-peel),
`SwapRouteEmit.cpp` (`emitPhaseKickbackRegion` + dispatch + the `sequentialChainAlias`
widening), `CQLoweringPass.cpp` (`deleteGlobalPhases` in BOTH entry points; `PhaseCalls`
in all three passthrough early-outs).

### MEASURED on my binary `build/ir-pass/cq-opt` vs the ORACLE
`p1_flat` (PRD §1's own two-diamond Grover) — ORACLE `exit=1 control flow`; SUBJECT
`exit=0`, and the emitted stream is EXACTLY the brief's golden target:
```
cq_template_icmp_eq_i32_hl(h, 5) -> h_cmp1
cqrt_rz_i1(h_cmp1, 0x400921FB54442D18)
cq_template_icmp_eq_i32_hl_unc(h_cmp1, h, 5)
cqrt_free(h_cmp1)
```
`p6_rolled2` (rolled Grover, K=3) — SUBJECT `exit=0`, ROLLED, and **byte-identical to the
pre-3qlq ORACLE stream of the old-surface twin EXCEPT the two lines that were the bug**:
`cqrt_rz_i32_controlled(f, h, PI)` → `cqrt_rz_i1(f, PI)`, twice. That is PRD §10.2 diff
class (a) and nothing else. K-independence MEASURED: 25 `@slice` lines at K=3 and at K=1000.
`p_perbit4/32` (D4's per-bit idiom) — `exit=0`, rolled, 23 `@slice` lines at K=4 AND K=32;
per bit: `and_i32_hl → icmp_eq_hl → x → rz_i1 → x → icmp_eq_hl_unc → free` (PRD §9's shape,
with ONE `_unc`+`free` — the `and` rail is left allocated, Rule 6, and stage 2b agrees).
`p7_uncontrolled` — `exit=0`, both `call void @cq_phi` DELETED, no `cqrt_rz` at all.
**Stage 2b `free_pairing_check.py` STRICT: PASS on all five.**

### PRE-EXISTING, NOT MINE (measured on the ORACLE with the OLD surface)
`p6_rolled` (the same rolled Grover but with `q += off; … q -= off` around the oracle,
`volatile int off`) declines `cq loop lowering: loop-carried tainted value crosses
iterations`. The OLD-SURFACE twin `p6_off_old.c` declines with the IDENTICAL string on the
ORACLE binary (`exit=1`). It is `lowerLoops`' X1 and has nothing to do with `cq_phi`.

### Exact new diagnostic strings (Rule 12 — fixtures mirror these character-for-character)
- `cq controlled lowering: multiple branch phases in one arm under quantum control`
- `cq controlled lowering: branch phase on a bare i1 condition under quantum control`  (Inc 1b / Q4)
- `cq controlled lowering: unclaimed branch phase under quantum control`  (P7's Rule-1 assert)
REUSED unchanged: `cq rotation lowering: unsupported quantum-derived rotation angle`,
`cq rotation lowering: unsupported declared prototype for cq_phi`,
`cq taint escape: tainted value consumed by an unknown callee` (the retired register form),
`cq controlled lowering: {control flow, control flow inside a loop body, control condition
has no template, condition predates a non-diagonal gate, condition measured before the
control route, condition data use neither escaped nor measured, condition data use has no
template} under quantum control`.

## Orchestrator decisions 2026-09-05 (received mid-task, both IMPLEMENTED)
**(1) P2 also arrives as a `phi double`.** IMPLEMENTED as the region's **MERGE-TAIL
ANGLE PHI** (`ArmAnalysis::phaseAngleTail`, ONE spelling asked by both the classifier and
the emitter). MEASURED on the real customer `slice_control_phase_ifelse_derived.c`: `-O1`
leaves a DIAMOND (arm = ONE `cq_phi(0.25)`) **plus** `%5 = phi double [0.125, %arm],
[0.75, %pred]` consumed by `call void @cq_phi(double %5)` in the merge — i.e. NOT "arms
otherwise empty"; the last phase of each arm is sunk into the merge with its angle muxed.
Emitted: `rz_i1(f,.25); rz_i1(f,.125); x(f); rz_i1(f,.75); x(f)`, one mint/strip/free.
Each incoming is bracketed by ITS OWN polarity (`Arm`⇒f, `ArmFalse`⇒¬f, `Pred`⇒¬Arm).
⚠ **THIS FOUND A BROKEN MODULE IN MY OWN INCREMENT, BEFORE SHIPPING.** The pre-refinement
classifier did not look at the merge's phis at all, so it ACCEPTED that customer and
`flattenRegion` spliced the merge away with the `phi double` still in it:
`PHI nodes not grouped at top of basic block!` at **`opt` exit 0** — a broken module, not
a decline. Every merge phi is now accounted for: this one (claimed and erased before the
flatten) or the region is `NotApplicable`.
⚠ **RESIDUAL, hand-IR only, MEASURED:** the variant with BOTH arms genuinely EMPTY never
reaches my classifier — `flattenPredMuxRegions` (CQLoweringPass.cpp:199, ~120 lines BEFORE
`detectControlRegions`) claims it and rewrites it into a **cross-block** angle select, which
`classifyAngleSelect`'s PRE-EXISTING S6 position clause (`Sel->getParent() != BB ||
Cond->getParent() != BB`) refuses. Loud (`rotation angle`), safe, and NOT reachable from
plain C — `if (c) cq_phi(A); else cq_phi(B);` is MEASURED to arrive as a one-block SELECT
(probe `p2_angsel`), which accepts. Localized by instrumenting all 22 `NotApplicable`
returns of `classifyAngleSelect` (gate #20 = S6); the instrumentation is reverted.
Widening S6 is a positional fence in the Rule-13 core and is NOT done here.

**(2) N>1 `cq_phi` per arm.** IMPLEMENTED as an ACCEPT: N `cqrt_rz_i1(f, θ_i)` on ONE
minted flag in source order, ONE `cqrt_x` bracket pair per ARM (not per gate — `cqrt_x` is
self-inverse, and `SwapRouteEmit.cpp`'s audit arithmetic assumes exactly this). PRD §6.3's
first decline row is SUPERSEDED and the classifier header says why: its stated ground
("summing angles is the 2b rounding class again") is a **Ry-stem** ground — under kickback
nothing is summed, each angle is passed through verbatim, and `P(θ₁)·P(θ₂) = P(θ₁+θ₂)`
happens in the hardware. MEASURED: `mod_rej_two_phases` (formerly a decline fixture) now
emits exactly two `cqrt_rz_i1` on one flag, one mint, one strip, one free; stage 2b PASS.
The MIXED-arm decline is unchanged (an arm is `{N × cq_phi, br}` and nothing else).
Also implemented while there: the **IF/ELSE** shape (both single-pred arms reconverging),
since the tail phi makes it reachable.

## Steps 5+6 — fixtures and measurements (DONE 2026-09-05)

### `ir-pass-lit` RED PARTITION (the brief's acceptance criterion)
`ctest --test-dir build -R ir-pass-lit` (log `$SP/progress/impl_inc1a_lit3.log`, 72.9 s):
**1239 passed · 1 expectedly failed · 362 FAILED · corpus 1602.**
Partition, computed as a set difference and not by eye:
```
grep -lE '@cq_phi_[a-z0-9]+' ir-pass/test/*.ll   -> 491 files (the retired family)
red \ that set                                    -> 0
```
**ZERO red outside the migration set.** Also measured: of the 20 fixtures I ADDED,
**0 are red**; and the 362 include the `invoke` spelling
(`lowering_reject_intrinsic_invoke_phi.ll`), which a `call`-only grep misses — the
partition above uses the SYMBOL, not the call form.
`cq-opt-equivalence` (sampled gate): **Passed**, 37.1 s. `frontend-lit` + all 7
`runtime` entries: **8/8 Passed**, 9.2 s.

### ⚠ FOR THE MIGRATION AGENT — A MEASURED FALSE-GREEN CLASS (PRD §11's risk, real)
**155 fixtures reference the retired family and are GREEN** (104 declines, 51
accepts). Of the 51 accepts, **47 only DECLARE it** (harmless) and **4 CALL it**:
`control_swap_switch_phase{,_passthrough}.ll`, `control_swap_switch_scrutinee_measured.ll`,
`lowering_reject_live_record_routed_base_anc.ll` — every one with a CLASSICAL
`ConstantInt` arg-0, which the deleted PHI loop used to RAUW-and-delete.
A green fixture here is NOT evidence the fixture still pins what its header says.

### ⚠ THE EMITTED Rz SET HAS **NOT** SHRUNK TO `cqrt_rz_i1` YET — PART B's SCOPE
PRD §5's table says `cqrt_rz_{i8..f80}` become "not emitted". **FALSE at my HEAD**,
and it is a P4/P5 fact, not a P1/P2/P6/P7 one. MEASURED by sweeping all 1602
fixtures through my binary and grepping the output:
**exactly 3 fixtures still make the pass emit a non-`i1` `cqrt_rz`** — the three
`control_swap_switch_*` ones — and they lower **BYTE-IDENTICALLY to the pre-3qlq
oracle**, `cqrt_rz_i32` on a `cqrt_cswap`-routed rail. The two surviving minters
are `NestedRouteEmit.cpp:116` (P4) and `SwitchRouteEmit.cpp:113` (P5); both
recognize their arm gates by the `"cq_phi_"` prefix and both are PART B's rows.
Not reachable from C (the header no longer declares the family) — hand-IR only.
`RotationLowering::emitRz` (the third minter) is now DEAD — zero callers, measured
— and is annotated in place with a DO-NOT-REVIVE note rather than deleted, so part
B's rewrite of those two emitters has no merge surface pulled out from under it.

### THE GROVER CUSTOMER, FULL PIPELINE, BOTH BINARIES
`$SP/progress/impl_inc1a_probes/grover_{new,old}.c` — the SAME program, mine on the
register-free surface and the oracle's on the retired one. Both: stage 2 exit 0,
**stage 2b `free_pairing_check.py` STRICT PASS**, linked, 15 trace lines.
`diff -u grover.orac.trace grover.subj.trace` is EXACTLY:
```
-cqrt_rz_i32_controlled(h1, h0, 0x1.921fb54442d18p+1)
+cqrt_rz_i1(h1, 0x1.921fb54442d18p+1)
-cqrt_rz_i32_controlled(h2, h0, 0x1.921fb54442d18p+1)
+cqrt_rz_i1(h2, 0x1.921fb54442d18p+1)
```
and nothing else — PRD §10.2 diff class (a), twice. In the SUBJECT trace:
`_controlled` 0 · `cqrt_cswap` 0 · `cqrt_rz_i32` 0 · `cqrt_rz_i1` **2**, on the
FLAG (`h1`/`h2`), with `h0` an operand of no gate but the compare. The oracle's
line put a TENSORED per-qubit Rz on `h0` conditioned on `h1`, i.e. phase
`(-1)^popcount(5) = +1` — the identity (PRD §1).

Other customers, my binary, full pipeline (all `_controlled` 0, `cqrt_cswap` 0):
| probe | trace lines | `cqrt_rz_i1` |
|---|---|---|
| `p6_rolled2` rolled Grover K=3 | 33 | 6 |
| `p_perbit4` D4 per-bit K=4 | 31 | 4 |
| `p_perbit32` D4 per-bit K=32 | 227 | 32 |
| `p2_angsel` P2 angle select | 10 | 2 |
K-INDEPENDENCE MEASURED on the LOWERED IR (not the trace): `p_perbit4` and
`p_perbit32` are both **23 `@slice` lines**; `p6_rolled2` at K=3 and K=1000 are
both **25**.

### Fixtures shipped (Rule 12, red-green; every CHECK DERIVED from the pass output)
**11 accepts** — `control_phase_kickback_{diamond,negated,two_calls,derived_cond,
f64_cond,seq,inloop,ifelse_tail_phi}.ll`,
`control_angle_select_phase_{constants,runtime}.ll`,
`lowering_phi_uncontrolled_deleted.ll`.
**10 declines** — `control_phase_kickback_reject_{bare_i1,tainted_angle,mixed_arm,
multiblock_arm,qq_compare,irreducible_loop}.ll`,
`control_angle_select_phase_reject_{two_consumers,empty_arm_phi}.ll`,
`lowering_reject_legacy_phi_register_form.ll`, and
`lowering_reject_decl_prototype_phi.ll` REWRITTEN (its old assertion —
`… for cq_phi_si32` — died with the family; it now pins the same guard on
`void @cq_phi(double)`, with the decision in its header).
Fixture hygiene applied from the Inc-3 F-L6-1 / Inc-4 F-L7-1 findings: `NOROUTE` is
**whole-file and PURE-NEGATIVE**; every count lives in its OWN `C<n>` prefix (two
counts in one prefix would silently become an ORDER assertion and a trailing `-NOT`
would window to EOF and match the `declare` lines); handle names are derived from
the pass output, never typed. ⚠ A trap worth recording: lit scans EVERY line for
the run-directive token, so quoting it inside a comment MINTS A BOGUS RUN LINE —
it cost 2 red fixtures here.

## OWNER QUESTION — none raised
No implementation finding contradicts a PRD §2 decision or a §12 assumption. The
ONE place the PRD is superseded (§6.3's "N>1 `cq_phi` per arm declines") was
superseded by an ORCHESTRATOR decision received mid-task, recorded above, and the
PRD's stated ground for it is a Ry-stem ground that does not survive D1 — so it is
a coverage refinement, not a contradiction.

## What is LEFT (for the orchestrator / part B / the reviewers)
1. **P3 / P4 / P5 are untouched and are part B's** (compound `select i1`
   conditions, the genuine depth-2 nest, the switch). The nest and switch emitters
   still mint the TENSORED `cqrt_rz_<W>` — measured above; that is the biggest
   single thing left before PRD §5's table is true.
2. **Inc 1b** — the bare tainted `i1` condition (Q4). Pinned as a decline with its
   own message; the correct lowering (the gate on `b`'s own rail, no mint) is known.
3. **The empty-arm `phi double` angle** — an over-decline caused by
   `flattenPredMuxRegions` running before detection; hand-IR only, pinned, cause
   measured. Widening `classifyAngleSelect`'s S6 is a Rule-13-core positional
   change and needs its own round.
4. **Q+Q flag minting** — pre-existing, unchanged, and the reason the kickback
   emitter's `!Flag` bail is REACHABLE (safe: the mint is its first emission, and
   the message is byte-identical to the oracle's for the same shape).
5. **The 540-fixture migration and the 66 e2e slices** are prep-a's and prep-b's;
   my tree is red on 362 of them by construction. The false-green class above is
   the part of that work a green suite cannot find.
6. **`RotationLowering::emitRz` is dead code** — annotated, not deleted; delete it
   with part B's rewrite of the nest/switch emitters.
7. **Rule 13**: this is a core-lowering change (`TaintPropagation`, `ControlDetect`,
   `ArmClassify`, `SwapRouteEmit`, `AngleSelectEmit`, `SelectClassify`,
   `RotationLowering`). It has NOT had an adversarial round. The 8h7d.5/drbq record
   is 4-for-4 on "the first round finds a confirmed silent miscompile", and this
   increment already found TWO defects in its own work before shipping (the
   `flattenRegion`-over-a-surviving-`phi double` BROKEN MODULE, and the
   `sequentialChainAlias` Kind gap that declined the flagship customer). Budget the
   rounds.
