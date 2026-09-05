# RETIRE_SWAP_ROUTE_INC1_NOTES — bd `test_C_libtooling-3qlq.2`, Increment 1 part A
## §1 — Rule-13 adversarial round 1 (2026-09-05)

Increment 1 part A is the register-free `cq_phi` by **kickback**: `void cq_phi(double)`
means "multiply the amplitude of the CURRENT BRANCH by `e^{iθ}`", and under a tainted
condition it is `mint f = c(x)` → `cqrt_rz_i1(f, θ)` UNCONTROLLED → the ordinary compare
`_unc` strip → `cqrt_free(f)`. It replaces `cqrt_rz_<W>_controlled(f, h, θ)`, which is
TENSORED and therefore put phase `(−1)^popcount(target)` on the marked branch and could
never mark `|0…0⟩` at all — the defect that made every shipped Grover golden the identity
on `q` (PRD §1).

**Round 1 ran EIGHT independent lenses (L1–L8) against `fa96336`. It found THREE
CONFIRMED defects of the class this project exists to stop — each one `opt` exit 0,
verify-clean and STRICT-stage-2b-clean — plus two over-declines of declared accept shapes,
one latent widening, and eleven doc/fixture-truth items.** Two of the three CONFIRMED
defects were found by more than one lens independently.

Everything below was **measured on three binaries**: SUBJECT-BEFORE = the main checkout at
`fa96336`; SUBJECT-AFTER = this branch; ORACLE = `$SP/wt/pre-3qlq` (`52d7764`, the retired
register surface). The full pipeline is stage 1 (`clang -O1`) → stage 2 (`cq-opt`) → stage
2b (`free_pairing_check.py`, STRICT) → stage 3 (link) → stage 4 (run).

---

### F-L7-1 / F-L1-1 / F-L2-1 — CONFIRMED MISCOMPILE. The uncompute spine adjointed the kickback gate and cancelled the user's phase EXACTLY.

**Found independently by three lenses.** On the ziov `ShareCondFlag` path — where the
condition compare is ALSO read as data, so `emitPhaseKickbackRegion` skips its own
strip+free and hands the flag to the data lineage — the Phase-5 whole-DAG uncompute spine
treated the flag as an ordinary reclaimable rail.

**Reproducer** (plain C, `clang -O1`, 4 statements;
`$SP/progress/review_r1_L7/probes/j3_sharecond_measure_only.c`):

```c
int a = cq_theta(u, 0.5);
int b = (a == 5);          /* the compare is ALSO read as data -> ShareCondFlag */
if (a == 5) cq_phi(0.25);  /* the kickback */
return cq_measure(b) + cq_measure(a);
```

SUBJECT-BEFORE emitted `rz_i1(h1, +θ)` … `zext(h1) -> h2` … **`rz_i1(h1, −θ)`** … strip …
free. Both gates are diagonal in the same basis label and the copy between them moves no
label, so `P(θ)·P(−θ) = I` **exactly**: the emitted circuit was byte-for-byte the circuit
for the same program with the `cq_phi` DELETED. The ORACLE keeps its phase gate on the
same source, so this is a fidelity REGRESSION, not an inherited hazard. It is PRD §1's own
defect class arriving through a different door.

**Root cause — a symbol whose MEANING changed and a set that was not told.** Before 3qlq,
`cqrt_rz_<W>(h, θ)` meant "the user wrote `x = cq_phi(x, θ)`" — a genuine member of `x`'s
reversible chain whose adjoint on uncompute is CORRECT. After D1/D2 it means "the
program's ANSWER, kicked back onto an ancilla". Three spine predicates still read it the
old way: `ChainWalk::isInPlaceGateOn`'s uncontrolled-rotation row (so the gate joined
`D.Calls`), `ChainWalk::preservesBasisUnderRecord`'s `cqrt_rz_` row (so the interior group
could adjoint it), and `EmitInverse::isInverseEmittable` (which emits the negated twin).

**Fix — MEMBERSHIP, not a name.** `ChainWalk::markBranchPhaseGate` /
`isBranchPhaseGate` record every emitted kickback gate, and all three predicates refuse a
member FIRST. The gate becomes an UNRECOGNIZED consumer ⇒ `D.NotClosed` ⇒ the flag rail is
LEFT ALLOCATED — Rule-6 safe (a leak, never a dirty free), and byte-for-byte the ORACLE's
own disposition on the same source. It is the same move Inc 2a made one stem over for
`cqrt_rz_<W>_controlled`.

**Recorded at all THREE emission sites** (`SwapRouteEmit::emitPhaseKickbackRegion`'s arm
loop and its merge-tail loop, and `AngleSelectEmit`'s Rz stem). A fourth emitter that mints
a kickback gate and forgets the call re-opens this with no diagnostic anywhere.

> **DEVIATION FROM THE REVIEW'S PROPOSED FIX, recorded so the owner can overrule it.** The
> L7 plan (endorsed by the orchestrator) said `taint.BranchPhaseGates`, a `TaintSet`
> pointer set. The QUESTION ASKED IS THE SAME — membership of the emitted instruction,
> never a name — but the storage is instruction METADATA (`!cq.branchphase`), for three
> reasons measurable in this tree. (1) The three predicates are PURE per-gate functions
> with no `TaintSet` parameter, asked from **19 call sites in 6 files**, three of which
> (`railOf`, `railCarriesControlledRotation`, `ArithLowering::priorUseIsSettled`) have no
> `TaintSet` in scope at all; threading one through is a cross-cutting signature change to
> the Rule-13 core made in service of a fix to the Rule-13 core. (2) A `Value *` set keyed
> at emission and read many stages later is the bd `drbq` Inc-1 round-1 defect VERBATIM —
> that set dangled when a later stage RAUW'd and erased the key, and the freeze silently
> stopped applying; metadata dies with its instruction. (3) Metadata survives
> `CloneFunctionInto` (Phase-6 specialization), where a pointer set silently would not.
> There is exactly ONE spelling of the question either way (Rule 14), and the record is
> visible in the lowered `.ll`, which is the artifact every fixture and
> `free_pairing_check.py` read.

**WHAT ELSE IS COMPUTED OVER THAT CLOSURE** — asked because this is a set NARROWING and the
bd `8h7d.5` F-1/F-3 lesson ("when you widen a set, ask what OTHER set was computed over the
same closure") cuts both ways. One decision per consumer:

| consumer | verdict after the fix | decision |
|---|---|---|
| `ChainWalk::railOf` | returns null for a kickback gate | **Correct and required.** `railOf` is DERIVED from `isInPlaceGateOn` (bd uow0), so it moves with it by construction. Attributing the gate to the flag would be the mis-attribution that finding was about. |
| `ChainWalk::isTerminalHandle` | FALSE for the flag rail | **Intended, and it is the sharp end.** The gate is now an unrecognized user, so the rail is never a dead terminal. Not-a-terminal ⇒ not freed ⇒ a leak, which is the safe direction (Rule 6). |
| `isInteriorTerminalHandle` (I1/I3) | the flag is not an interior candidate | (I1) already excluded `cqrt_alloc_`-minted rails; (I3) now fails because `isInteriorConsumer` refuses the gate. Both routes agree. |
| `ChainWalk::isInteriorConsumer` | FALSE | Follows from `isInPlaceGateOn` (clause (a) is `isInPlaceGateOn && preservesBasisUnderRecord`, and BOTH now refuse). Belt-and-braces by design. |
| `DagTraversal` step-1 `D.Calls` | the gate does not join | **The mechanism of the fix.** No membership ⇒ no adjoint. |
| `DagTraversal` step-3 closure | sets `D.NotClosed` | **Intended.** An unrecognized consumer marks the DAG not-closed, which is what leaves the rail allocated. |
| `Uncomputation`'s moved-anchor scan | never sees the gate | It keys on `isInPlaceGateOn`; a refused gate is not an in-place basis-relabelling gate to it. Correct — a diagonal gate relabels nothing, so there is no anchor question to answer. |
| `Uncomputation` clause (d) | unchanged | Reached only for recovered gates. |
| `Uncomputation::preservesBorrowedParent` clause (1b) | unchanged | It is about `cqrt_{ry,rz}_<W>_controlled` at arg 1 — a different spelling, a different family, and the kickback gate is UNCONTROLLED with the flag at arg 0. Deliberately NOT touched: deleting or widening it reintroduces the measured nine-module regression Inc 2a's notes record. |
| the 7.4 `lowerBreakReversePlay` capture | cannot capture it | Its rail-gate pre-scan is `isInverseEmittable`, which now refuses. Correct: reverse-playing a branch phase would cancel it exactly as the spine did. |
| `tools/free_pairing_check.py`'s `classify()` | `cqrt_rz` stays TRANSPARENT | **Say it explicitly rather than leave it silent: this is correct and must NOT change.** The gate is DIAGONAL — it moves no basis label and is not a rail event — so it is not a `cqrt_free` pairing question at any width. The checker was, and remains, structurally blind to this whole finding; it reported `0 violations` on every reproducer, and on the broken circuit it was arguably *happier* than on the correct one, because the spine's reversal is what made the free provable. That is the honest statement of what stage 2b does and does not witness. |

**Both polarities are now correct BY DESIGN, which they were not before.** Lens L1 measured
that the defect was POLARITY-DEPENDENT: the NEGATED arm survived only because its
`cqrt_x(f)` bracket made the flag carry an unrecognized consumer, and the un-negated arm
did not. Whether a user's phase survived depended on which branch polarity `clang -O1`
happened to canonicalize to. That is an accident, not a fence. The same applies to the
NON-share path, which was protected only by its own `cqrt_free(Flag)`; the emitter's
`ShareCondFlag` comment now says the protection is the membership, on BOTH paths (it
previously claimed a "byte-for-byte the rule `emitRegion` follows" equivalence, and the
falseness of that claim is precisely where the miscompile lived — `emitRegion`'s gate is
`cqrt_rz_<W>_controlled`, which `isInPlaceGateOn` REFUSES).

**Measured after the fix.**
* `j3_sharecond_measure_only`, `i1_sharecond_negated`, `u4_datause_new`, `u7_datause_one`,
  `u9_share_measureflag`: the phase survives, the flag rail is left allocated, STRICT 2b PASS.
* `u6_datause_negshare` and `u8_share_tail` (the polarities that were already correct by
  accident): BYTE-IDENTICAL to SUBJECT-BEFORE.
* **The e2e witness**: prep-b's already-rewritten `tests/e2e/slice_control_cond_datause.c`
  run on this binary is BYTE-IDENTICAL to its committed (old-surface) golden EXCEPT the two
  intended lines `cqrt_rz_i32_controlled(h1, h0, θ)` → `cqrt_rz_i1(h1, θ)` — PRD §10.2 diff
  class (a), twice, and nothing else. Before the fix that same slice emitted two extra
  NEGATED angles.
* `diff` of the ORACLE's `j3_old` trace against this binary's `j3` trace is EXACTLY
  `-cqrt_rz_i32_controlled(h1, h0, 0x1p-2)` / `+cqrt_rz_i1(h1, 0x1p-2)`.

> ⚠ **A CORRECTION TO THE BRIEF AND TO L7.** Both asked for an e2e pair whose goldens
> "differ by EXACTLY one `cqrt_rz_i1` line". That is not achievable and should not be: adding
> the kickback also legitimately REMOVES the strip and the free, because the spine can no
> longer close a rail carrying an opaque gate — which is exactly what the ORACLE does on the
> same pair. The correct witness is SUBJECT-with-phase vs ORACLE-with-phase, above.

**Fixtures.** `control_phase_kickback_share_flag.ll` (ACCEPT; the `-O1` IR of `u9`
verbatim, whole-file pure-negative `NOROUTE` carrying `double -` and `fneg`, the count in
its own `ACNT` prefix, zero frees in `FCNT`) and
`control_phase_kickback_share_flag_negated.ll` (the polarity that was already green — it
reddens on SUBJECT-BEFORE on the `!cq.branchphase` assertion ALONE, which is the honest
statement of what it pins on that half: THE RECORD). Both green here, both red on
SUBJECT-BEFORE. A COUNT alone does not catch this defect — the broken module has TWO
`cqrt_rz_i1` — which is why the discriminator names the NEGATED ANGLE.

---

### F-L3-1 — CONFIRMED MISCOMPILE. P7 deleted a branch phase whose region had never been looked at, and the orphaned angle select was then lowered as quantum fp DATA.

`deleteGlobalPhases` (PRD row P7 — "an uncontrolled or classically-controlled branch phase
is a GLOBAL phase and is deleted", owner decision D2) ran immediately after
`lowerControlRegions`. Its soundness argument is Rule 1's: *by then every tainted `br` has
been claimed or declined, so a survivor sits under CLASSICAL control only.* **That premise
was false at that program point**, because `repropagateControlMerges` — which runs 30 lines
LATER — is not a taint touch-up: its `detectAndLowerOnwardControl` is a **second, full round
of `detectControlRegions` + `lowerControlRegions`**.

A `cq_phi` under an ONWARD tainted branch — one whose condition reads a 6.5
classical-call-arm or 4.5 switch-data-mux `%out` rail, and is therefore CLASSICAL at round 1
— was therefore deleted as a "global phase" before its region existed.

**Reproducer A** (`$SP/progress/review_r1_L3/repro/repro_t1_onward_angle_select.ll`, from
plain C through the shipped two-TU onward harness):

```c
int y = 5;
if (q > 5) y = ext_f(7);                        /* 6.5 classical-call arm -> %out */
if (y > 50) cq_phi(0.9); else cq_phi(0.3);      /* P2 on the ONWARD rail */
```

**Two defects per deletion, and the second is worse.** (1) The branch phase vanished.
(2) With its only consumer gone, the ANGLE `select` was re-classified at round 2 as plain
fp DATA and lowered through the 4.4/kjd1 merge — measured
`cqrt_alloc_f64(0x1.ccccccccccccdp-1)` … `cqrt_copy_f64_controlled(...)`, i.e. **a rotation
ANGLE materialised on a quantum f64 rail**, an operand of nothing and never freed. That is
the Rule-3 wire-crossing `CLAUDE.md` names outright ("a floating-point merge φ is an angle,
not data — do not cross these wires"). `opt` exit 0, STRICT 2b PASS, linked, 23 trace lines,
**zero `cqrt_rz` of any width**.

**Reproducer B** (`repro_n1_onward_phase_valuearm.ll`) is an **over-accept of a shape the
pre-3qlq oracle declines loudly** (`mixed phase/value arm under quantum control`): an onward
arm carrying `{cq_phi(0.25); w = w + 1;}` compiled at exit 0 with `w` routed under the very
same flag by `cqrt_cswap` — so the compiler itself treated the branch as
quantum-conditional while dropping the phase on it.

**Neither fence could see it, and both failures are structural, not accidental.** At the old
position (i) the onward branch's condition is not yet in `taint.Tainted`, so the Rule-1
assert's `reachedThroughTaintedBranch` walk had nothing to find, and (ii) the ROUND-1 tainted
`br` that walk would otherwise have found on the predecessor path had already been ERASED by
its own region's flatten.

**Fix — the stage's POSITION.** `deleteGlobalPhases` now runs AFTER
`repropagateControlMerges` in BOTH entry points. The premise becomes true rather than
aspirational, and the Rule-1 assert is asked with ROUND-2 taint on the ROUND-2 CFG, which is
its correct position. The stages the call CROSSED were re-asked in writing at the call site
(the 8h7d.5 discipline): `declineTaintEscapes` already carves `taint.PhaseCalls`, round-2
`detectSpecializations` reads `PhaseCalls` since F-L3-3 below, and
`collapseFlattenedLoopRails` keys on rail gates, which a register-free phase call is not.

**Measured after the fix**: reproducer A emits 4 `cqrt_rz_i1` and **0**
`cqrt_copy_f64_controlled`, and its stream is character-for-character the correct circuit
L3 specified; reproducer B declines `impure value arm under quantum control`, the same
string its round-1 control produces.

**Fixtures.** `control_phase_kickback_onward_merge.ll` (ACCEPT) and
`control_phase_kickback_reject_onward_mixed_arm.ll` (DECLINE), both verbatim L3's modules,
both red on SUBJECT-BEFORE.

**F-L3-2 came free with it** and is worth stating because of what it says about grading: the
new-surface twin of the SHIPPED slice `tests/e2e/onward_ctl_phase_caller.c` had regressed
accept → decline (`control flow`), because round 2 met an EMPTY tainted diamond after the
phase was deleted. **That decline was not a protection.** It was an accident of the residual
being unlowerable; when the residual IS lowerable you get F-L3-1 instead. Same root, same
fix: it now emits 2 `cqrt_rz_i1`.

---

### F-L7-2 / F-L5-1 / F-L2-1b — CONFIRMED MISCOMPILE. D4's per-bit idiom, ROLLED, leaked one ENTANGLED rail per activation.

Owner decision D4 designates

```c
for (int i = 0; i < K; ++i) if ((q >> i) & 1) cq_phi(θ);
```

as THE way to express a register-wide Z under the register-free surface. Rolled, it minted
`cq_template_and_i32_hl(h, 1<<i)` per trip and NEVER `_unc`-reversed or freed it — 4 of them
at K=4, 32 at K=32 — while the HAND-UNROLLED spelling of the same source discharged all K.
The pre-3qlq ORACLE emitted the DISCHARGING stream for the same program.

**Why it is not a "Rule-6 safe leak", which is how it was cleared in the implementation
hand-back.** Each leaked rail holds one BIT of `q` — a which-path record — and this idiom
exists to be a Grover phase oracle whose next step is a diffusion that interferes different
`x`. Rule 8: *"a permutation that leaves a rail dirty AND entangled still dephases under
later interference."* Rolled and unrolled were **different unitaries** — the 8h7d.5 F-4
signature — and both shipped gates were blind: `opt` exit 0, verify-clean, and STRICT
`free_pairing_check.py` `0 violation(s)` because the leaked rail has no `cqrt_alloc` and was
never counted as minted (the checker's own header says so). The hand-back cleared it by
citing that checker, which is the one instrument documented as unable to see this class.

**Root cause.** `markIfRailLocal` is called ONLY when `collapseRailPhisIn` returns
`Collapsed`. Under the register surface `q = cq_phi(q, θ)` in the arm made `q`
LOOP-CARRIED, so there WAS a rail phi to collapse. Register-free, a kickback body gates
nothing, `q` is loop-INVARIANT, there is no rail phi, `markIfRailLocal` never runs, and
`Uncomputation.cpp`'s `if (canRepeat(&BB) && !taint.IterationLocalBlocks.count(&BB)) continue;`
SILENTLY skips every interior candidate in the body. **The shape the register surface could
not produce is the one the new surface makes normal.**

**Fix — the CAPABILITY fix (a), in a bounded form.** A new
`LoopLowering::invariantRegisterRoots` supplies `markIfRailLocal` — **UNCHANGED** — with the
`Roots` a loop-carried rail would have supplied, for a loop whose registers are
loop-INVARIANT. It admits **only a ROOT MINT** (a classical-arg-0 `cq_theta`, PEELED through
in-place gates with the identical `peelInPlaceBase(..., AsLowered=true)` call
`markIfRailLocal::onRail` makes — Rule 14), and only when the header carries NO tainted phi
at all.

**That restriction is the proof, and it is aimed at a hazard the code already warns about.**
`markIfRailLocal`'s own comment says: *"a recovered gate in the PREHEADER (does not repeat)
with `At` in a body marked here (repeats K times) would emit K adjoints against ONE forward
gate. … Widening it — even 'just' to admit a hoisted loop-invariant temp — makes it
reachable, and no shipped test would go red."* A ROOT MINT cannot be that gate: it lowers to
`cqrt_alloc_<W>`, and `ChainWalk::isInteriorTerminalHandle`'s clause (I1) excludes an
alloc-minted rail from the M-B interior partition OUTRIGHT, so no `At` can ever be placed
for it. Everything the body itself mints repeats exactly as its adjoint will, so the
multiplicity is 1:1 by construction.

**Measured.**

| probe | SUBJECT-BEFORE | SUBJECT-AFTER |
|---|---|---|
| per-bit K=4, rolled vs hand-unrolled | 4 mints / **0** `_unc` / 4 frees vs 4/4/8 → DIVERGE | **BYTE-IDENTICAL**, 39 lines, 4/4/8 both |
| per-bit K=32 | 32 mints, **0** `_unc` | 32 mints, **32** `_unc`, 64 frees |
| per-bit + diffusion (the orchestrator's reproducer) | 2× `warning: non-diagonal gate over a live derived record`, rolled ≠ unrolled | **no warning**, rolled == unrolled |
| per-bit with the register DEAD after the loop | leaks | rolled == unrolled; the diff vs before is EXACTLY the K discharge pairs — the alloc root is still left allocated, i.e. the multiplicity hazard did NOT materialise |
| `q = cq_theta(u,.3); q = cq_theta(q,.1);` then the per-bit loop | leaks | IDENTICAL to its twin — this is why the root is PEELED; the un-peeled first draft left it diverging |
| TWO invariant root mints, two regions per trip | — | rolled == unrolled |
| the NINE rolled/unrolled pairs L5 measured CLEAN | identical | still identical, and **byte-identical to SUBJECT-BEFORE's output** |

**⚠ A KNOWN, UNFIXED RESIDUAL, on Prime-Directive grounds and not on a proof.** A HOISTED
loop-invariant TEMPLATE rail read by the body's condition (`int p = q * 3;` before a per-bit
loop over `p`) is REFUSED by the root-mint restriction, so that loop still leaks and is
rolled ≠ unrolled. Under a deliberate MUTATION admitting any loop-invariant tainted value,
that program's rails DO discharge and the preheader `mul` rail is NOT reversed K times —
i.e. **I could not EXHIBIT the hazard the comment names, which is not the same as showing it
absent.** The comment says it is reachable and untested; widening a Rule-13-core clause on
"I could not break it in one afternoon" is exactly the reasoning this project's history says
not to trust. **OWNER QUESTION Q-R1-1** (below).

**Fixtures.** `control_phase_kickback_inloop_derived_cond.ll` (ACCEPT — its `UCNT` count was
ZERO before the fix while every other directive in it passed) and
`control_phase_kickback_inloop_reject_hoisted_temp.ll` (the DISCRIMINATING CONTROL,
**mutation-validated in both directions**: deleting the root-mint test makes its negatives
fire while the sibling stays green).

---

### F-L6-1 — CONFIRMED Rule-1 "no third path" violation. A stale-header Grover oracle was neither lowered nor declined.

`ArmClassify::isPhiCall` still recognised a retired `@cq_phi_<sfx>` call by the `cq_phi_`
PREFIX and CLAIMED it as an arm gate; `emitInPlaceRotationRegion` hoisted it and recorded
`taint.ControlledRotations`; and the `PhiCalls` loop in `RotationLowering` that used to lower
it had been DELETED (correctly — `taint.PhiCalls` is permanently empty). Nothing consumed the
claimed gate.

**The boundary is ONE CHARACTER wide, and the flagship customer is on the wrong side of it.**
Three spellings decline through `declineTaintEscapes`, which fires only on a TAINTED OPERAND.
For `if (q == 5) q = cq_phi(q, PI)` — the Grover oracle — `clang -O1` CONST-FOLDS arg 0 to a
classical `i32 5` on the equality edge (the drbq Inc-4 F2 fold class), so there is no tainted
operand and the guard structurally cannot fire. Result: `opt` exit 0, verify-clean, STRICT
stage 2b PASS, the flag minted and stripped and freed, **the phase gate DROPPED** (the
identity on `q`), and `@cq_phi_si32` left unlowered in the emitted module. The only thing
that noticed was `ld`. It is one linkable body away from being silent, and the shipped
comment claiming these "decline LOUDLY through `declineTaintEscapes`" was true of three
spellings and false of the fourth.

**Two fixes, and the second is the general one.** (1) `resolveSources` declines ANY USE of a
retired `@cq_phi_<sfx>` under its own reserved-name string. (2)
`declineSurvivingIntrinsicCalls`, at the END of both pipeline entry points, turns the pass's
documented postcondition — "no `@cq_theta_<sfx>` / `@cq_phi_<sfx>` / `@cq_measure_<sfx>`
remains in the IR after this pass" — from a comment into a **checked property**, because
`eraseDeadDecls` only erases declarations that are already unused and is structurally blind
to a surviving CALL. Loud, not `assert` — a Release build has assertions off, and that is the
build every gate in this tree runs.

**The `!use_empty()` gating is a DELIBERATE narrowing of the reserved-name rule** the other 33
front-end names follow ("even for a decl with NO call sites"), and it is argued at the clause:
a declare-only retired symbol is provably inert (measured — swept when quantum is present,
byte-identical passthrough when it is not), while a decl-only decline would redden ~490
mid-migration fixtures for no correctness gain. The set that can reach a wrong unitary is
exactly the set with a USE. What is LOST is the family's PROTOTYPE validation for a
declaration with no call site; recorded in `lowering_legacy_phi_decl_prototype_family.ll`.

**⚠ BLAST RADIUS, MEASURED AND OWED TO THE MERGE: 34 fixtures go red.** Every one of them
CALLS the retired family (verified by grep — zero outside prep-a's migration set). They
include the three the orchestrator predicted — `control_swap_switch_phase.ll`,
`control_swap_switch_phase_passthrough.ll`, `control_swap_switch_scrutinee_measured.ll`,
which are part B's P5 rows — and `lowering_reject_live_record_routed_base_anc.ll`, the ONE
green fixture that was blind to a surviving retired call. The other 30 are decline fixtures
whose string is now pre-empted by the earlier reserved-name decline. Full list in the
`fix_r1` hand-back.

**Fixtures.** `lowering_reject_legacy_phi_register_form_eqfold.ll` (the const-folded module,
red on SUBJECT-BEFORE), `lowering_legacy_phi_decl_prototype_family.ll` (records the
declare-only DECISION and what was lost), and `lowering_reject_legacy_phi_register_form.ll`
rewritten to the new string with its old header's false reassurance corrected in place.

---

### F-L3-4 — OVER-ACCEPT, loud at the linker and silent at the compiler.

`deleteGlobalPhases` derived its survivors with a `dyn_cast<CallInst>` **filter**, so a
NON-CALL user of `@cq_phi` (an address-take, `void (*volatile pf)(double) = cq_phi;`) simply
fell out of the walk: the pass lowered nothing for it, the extern survived into the lowered
module, and `opt` exited 0 on a module it had not lowered. Loud at `ld` is not loud at the
compiler, and Rule 1 says there is no third path. Any user of `@cq_phi` that is not a direct
call to it is now a loud decline. Fixture `lowering_reject_phi_address_taken.ll`, whose
header records which of the three spellings takes which message (the `invoke` one is caught
at collection; an indirect call under a tainted branch declines at `detectControlRegions`).

### F-L3-3 — the specialization recognizers were reading a permanently-empty set.

`SpecializeReject::buildIntrinsicSets` and `SpecializeDetect::intrinsicSites` both unioned
`taint.PhiCalls`, which is the RETIRED family and is now permanently empty. The reject stayed
LOUD — so this is not a miscompile — but on the WRONG GROUND: a branch phase in a
specialization candidate declined `callee contains a non-reversibilizable construct under
quantum lift (nested call)`, the unrelated declaration-only-callee fallback, where the oracle
said `callee contains a quantum primitive (cq_*)`. Safety had silently moved onto an accident:
if `@cq_phi` ever acquires a body in the module the scan would recurse into it, find nothing,
and clone a Bennett-wrapped body containing an unlowered branch phase. `taint.PhaseCalls` added
to both. It matters MORE after the P7 re-ordering, because the round-2 `detectSpecializations`
now sees surviving `cq_phi` calls. Fixture `lowering_reject_spec_branch_phase.ll`.

### F-L4-1 — the one arm-value clause that DOES have a subject for the phase stem.

`classifyAngleSelect`'s `IsPhase` fork skipped `angleSelectArmsAdmissible` WHOLESALE, on the
argument that the phase stem performs no arithmetic on the angles. That is TRUE of the
non-finite-arm, non-finite-difference, rounding-bound and constant-arms-only clauses — all
four fence the `A − B` subtraction only the Ry stem performs — and FALSE of clause (1),
`valueCarriesUndef`, which is about a value that is not a NUMBER AT ALL. Measured (hand IR):
an `undef`/`poison` arm reached `cqrt_rz_i1(f, double undef)`, which is the bd xy9n
literal-integrity class — at the `-O0` stage 3 the backend may read one `undef` as two
different values, so the emitted angle stops denoting the source's. The oracle declined.
Split so the phase stem asks `valueCarriesUndef` and nothing else, with the comment naming
WHICH clauses have no subject. Fixtures
`control_angle_select_phase_reject_{undef,poison}_arm.ll`, plus the ACCEPT control
`control_angle_select_phase_nonfinite_arm.ll` recording that a NON-FINITE arm is
DELIBERATELY passed through — the same disposition an uncontrolled `cq_theta(q, inf)` already
has on both binaries — so nobody re-enables the whole fence later.

### F-L5-6 — LATENT WIDENING: the phase-carrier property became unrepresentable.

Three fences ask "does this escaping value's lineage carry a RELATIVE PHASE?" and decline if
it does: `LoopLowering::breakLineageCarriesPhase` (the §2.6 B3 fence),
`ControlDetect::retLineageCarriesPhase` (controlled `return`) and `AbortParkEmit::
lineageCarriesPhase` (the 7.2 abort park). All three answered by looking for a
`cq_phi_`-prefixed CALL in the value's own operand graph. **After D1/D2 that property is not
representable in the lineage at all**: a register whose branches carry a kickback phase has
NO `cq_phi` in its operand graph, because the gate lands on a flag ancilla the register does
not derive from. All three silently began answering "no phase" for a value that carries one
— a WIDENING, the one direction a vacuity audit exists to catch. (Two of the three DID get a
"⚠ VACUOUS" note, and its stated reason — no arg-0 wire, no arg-1 angle — is right for the
WIRE-walking predicates and a non-sequitur for a CARRIER predicate, which reads no operand.)

Fix: one new exported `functionCarriesBranchPhase(F, taint)` — is there a branch phase in `F`
that is CONTROL-DEPENDENT on a tainted branch, reusing `deleteGlobalPhases`' own
`reachedThroughTaintedBranch` walk (Rule 14) — asked first by all three. Deliberately COARSE
and over-declining: every consumer turns `true` into a loud decline. **Timing is why it
cannot be an emitter-written record**: all three carriers run BEFORE `lowerControlRegions`,
so a set filled in `emitPhaseKickbackRegion` would always be empty when they read it.
**LATENT at this HEAD** — no plain-C program reaches any of the three fences (each is held
shut by an earlier shape fence), which is what L5 measured too.

### F-L3-7 / F-L5-5 — a compound condition was reported as "a bare i1 condition".

`classifyPhaseKickback` step 5 gave EVERY non-`CmpInst` condition the message
`branch phase on a bare i1 condition`, deliberately. It is FALSE about the two commonest
programs that reach it — `if (c) { if (q==5) cq_phi(θ); }` with `c` classical, and the folded
nest — both of which arrive as `select i1 %a, i1 %b, false`, a condition TREE, one of them
mixing a CLASSICAL guard with a tainted compare. It was also a diagnostic REGRESSION against
the oracle, which said `control flow` and was right about all of them. Split by SHAPE: a
condition TREE takes `control flow` (P3/P4, part B), a tainted `i1` VALUE keeps the bare-i1
string (Inc 1b's shape). That pair is what lets Inc 1b's fixture stay a DISCRIMINATOR — when
1b lands and clears the bare-i1 shape, the string must stop firing, and under the old
spelling it would have gone on firing here with no fixture able to tell. Fixture
`control_phase_kickback_reject_compound_cond.ll`.

### F-L3-5 — the shipped "`opt` exit 0 on a verifier failure" claim is MEASURED FALSE.

Two shipped comments (`ArmAnalysis.h`'s `phaseAngleTail` note and its `SwapRouteEmit.cpp`
twin) said a φ left standing in a spliced merge is "a BROKEN MODULE at `opt` exit 0".
Re-measured here: `cq-opt` builds `CQLoweringPass → VerifierPass → print` with LLVM's default
`FatalErrors=true`, so a broken module **aborts** — `LLVM ERROR: Broken module found,
compilation aborted!`, **exit 134 (SIGABRT)**, no module written. Both comments corrected. The
alarming reading ("every fixture relying on verify-clean ⇒ exit 0 is weaker than documented")
is NOT reproduced. What IS true and now recorded there: `cq-opt` exits at the FIRST
`DS_Error` and never writes `-o`, which is why a decline can never be masked by a later
stage's abort. Leaving a false claim of that kind in the Rule-13 core is the
hardened-by-repetition failure mode `CLAUDE.md` records for the `fenv` prose.

### F-L5-3 — the one P6 accept fixture pinned IR `clang -O1` cannot produce.

`control_phase_kickback_inloop.ll` puts the compare in the loop HEADER on a register the body
never gates, and its header called that "Grover written as `for (…) { oracle; diffusion; }`"
— there is no diffusion in it and no gate on the register at all. From C, that program has a
LOOP-INVARIANT condition register, so `-O1` LICM-hoists the compare into the preheader and
`condWireDisposition`'s P4 precondition declines it: **bd `drbq.12`'s over-decline arriving at
the phase stem, where it did not previously exist** (under the register surface a phase arm
always gated `q`). Header corrected; the two reachable halves added as
`control_phase_kickback_inloop_body_gate.ll` (ACCEPT — a body `cq_theta` makes the register
loop-variant) and `control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll` (DECLINE —
the Ry stem has had this fixture since drbq Inc 3; the phase stem had none).

### F-L5-4 — P2 in a loop declines, although PRD §6.2 row P6 declares it an accept shape.

`if (q==5) cq_phi(.9); else cq_phi(.3);` inside a rolled loop declines
`condition predates a non-diagonal gate under quantum control`, from the kjd1 gate-2c / P4
window fence rather than from the angle-select S7 loop prong. DECLINE-BOTH (the hand-unrolled
twin declines identically), so it is not a rolled/unrolled asymmetry. Pinned by
`control_angle_select_phase_reject_in_loop.ll` so the red-green exists when P6 is completed.
**OWNER QUESTION Q-R1-2.**

### F-L1-2 / F-L1-3 — three emitter polarity branches, and the whole shared-flag path, shipped with ZERO fixture coverage.

`emitArm(R.ShadowFalse, /*Neg=*/true)`, the tail-φ `ArmFalse` branch and the tail-φ
`Pred`-first-under-inverted-polarity branch had no fixture; nor did `ShareCondFlag`, which is
where F-L7-1 lived. All are pinned now
(`control_phase_kickback_{ifelse,ifelse_tail_armfalse,negated_tail_phi,share_flag,share_flag_negated}.ll`),
each header stating that `clang -O1` cannot produce the shape and why — every C spelling of
an if/else folds to an angle select, to a diamond plus a merge-tail φ, or to two selects. So
`emitArm(R.ShadowFalse, true)` is hand-IR-only LIVE code in the Rule-13 core, and it is now
pinned by hand IR rather than unpinned.
**F-L1-3**: the shipped "ONE BRACKET PAIR PER ARM" comment was being read as per REGION and is
false for the merge-tail spelling (4 `cqrt_x` from plain C, because a bracketed tail incoming
carries its own pair); and its citation of `SwapRouteEmit.cpp:1063`'s `-2 cqrt_x` audit
arithmetic was a FALSE DEPENDENCY — that note is the Inc-2a collapse arithmetic and the
kickback path feeds neither it nor `tools/golden_multiset_audit.py`. Both corrected, and the
count is now an `XCNT-COUNT-4` assertion in two files rather than a sentence.

### F-L6-3 / F-L6-4 / F-L8-1 / F-L8-2 / F-L4-2 — fixture-integrity repairs, each validated by injection.

* `tests/frontend/cq_phi_smoke.c`'s whole-module "no `@cq_phi_` family" claim was spelled as a
  TRAILING negative after a positive directive, so it WINDOWED from that match to EOF — and
  the `declare` block sits after the function bodies, so the window excluded exactly the place
  an old-family CALL appears. An injected `call i32 @cq_phi_si32(...)` inside `@use()` was NOT
  caught. Moved to its own whole-file pure-negative prefix; re-validated by injection (clean
  passes, injection caught). **This is the Inc-3 F-L6-1 windowing lesson recurring in the file
  this increment rewrote.**
* All 11 enumerating accepts listed SIX of the EIGHT non-`i1` Rz widths — `f16` and `f80` were
  absent from all 11, so the block's own claim ("no TENSORED Rz at any width") was 6/8 true.
  Replaced with ONE complement regex, validated in BOTH directions: it fires on injected
  `cqrt_rz_{f80,f16,i16,i32}` and does NOT fire on the clean output's `cqrt_rz_i1`. The
  trailing `(` is load-bearing — `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
* Three fixtures that emit NO `cqrt_x` had no negative for it, so an unpaired polarity gate —
  which inverts which branch the phase lands on — would have passed them silently. Added.

### F-L6-7 — `WidthDispatch::phiFn` was dead code with no annotation.

It now has exactly one caller (F-L6-1's reserved-name decline) and a DO-NOT-REVIVE block
saying the lookup exists so a retired spelling can be REFUSED, never lowered — the same
annotation `RotationLowering::emitRz` already carries.

### F-L3-6 — the AXIS-F hazard note was missing a fourth module-wide stage.

`runOnFunction`'s `onlyInF` scopes the WORK LISTS, but `deleteGlobalPhases` derives its
survivors from `wd.phaseFn()->users()`, which is module-wide — so the (dead) shim would delete
`cq_phi` calls in functions other than `F`, and since F-L3-4 would decline on an address-take
anywhere in `M`. Named in the note beside the three stages already listed.

### F-L8-3 / F-L8-4 / F-L6-2 — three claims in the increment's own write-up that do not reproduce.

* **F-L8-3.** The Rule-1 assert string `cq controlled lowering: unclaimed branch phase
  under quantum control` has **NO fixture** — three files mention it in PROSE and none
  exercises it. Lens L3 probed 90+ shapes and could not reach it, for a structural reason
  worth carrying: every region kind that CLAIMS a tainted `br` also REMOVES it (the flatten,
  the 7.2 abort park's `br label`, the loop lowering's bound), and every kind that declines
  exits `opt` at its first `DS_Error`. Constructing a module that reaches it would itself be
  a third-path finding, not a fixture. The three headers now SAY that, rather than implying
  coverage. The assert is kept and is now correctly POSITIONED (F-L3-1), because the hazard
  it was written for is real — at the old slot it could not see an ONWARD region's tainted
  branch at all, which was this round's second CONFIRMED miscompile.
* **F-L8-4.** The implementation hand-back's "Exact new diagnostic strings" list names
  `cq controlled lowering: multiple branch phases in one arm under quantum control`. That
  string exists **nowhere in `ir-pass/src`** (verified by grep) — it was SUPERSEDED by the
  mid-increment decision to ACCEPT N `cq_phi` per arm and was never removed from the list.
  **NOT SHIPPED.**
* **F-L6-2.** The same hand-back's census — "155 fixtures reference the retired family and
  are GREEN (104 declines, 51 accepts)" — does not reproduce. Measured at `fa96336`:
  `grep -lE '@cq_phi_[a-z0-9]+' ir-pass/test/*.ll` = **491**, red = **362**, so **129 green
  (103 declines / 26 accepts; 35 with a live CALL, of which 4 accept)**. The FOUR accepts
  that CALL it are exactly the four named, so only the totals are wrong. No variant of the
  grep produces 155. Everything else in that file's fixture arithmetic DOES reproduce.

### F-L8-5 — a hand-off to the migration agent, not a fix.

`ir-pass/test/control_angle_select_reject_runtime_arms_rz.ll` is RED (it is in the retired
family set) and asserts that the **Rz stem REFUSES run-time arms**. Under owner question Q3
— assumed YES, and implemented — the register-free phase stem ADMITS them. That fixture must
be **REWRITTEN AS AN ACCEPT** by prep-a, not merely re-spelled onto the new surface;
re-pointing its string would pin the opposite of the shipped semantics. The Ry stem's
`control_angle_select_ry_reject_runtime_arms.ll` is unchanged and must stay a decline
(clearance blocker F-11).

---

## OWNER QUESTIONS FROM ROUND 1

**Q-R1-1 — the hoisted-loop-invariant-TEMPLATE-rail leak.** `invariantRegisterRoots` admits
only a ROOT MINT, so `int p = q * 3;` before a per-bit loop over `p` still leaks one rail per
activation and is rolled ≠ unrolled. Widening it to any loop-invariant tainted value makes
that program's rails discharge and did NOT produce the multiplicity defect
`markIfRailLocal`'s comment warns about when I looked for it — but that comment says the
defect is reachable and untested, and the widening is a Rule-13-core change that needs its own
adversarial round. Cost of the narrow form: hand-unrolling works, and so does using the root
register itself. Pinned by `control_phase_kickback_inloop_reject_hoisted_temp.ll`,
mutation-validated in both directions.

**Q-R1-2 — P2 inside a loop.** PRD §6.2 row P6 declares "P1–P3 inside a classically-bounded
loop" an accept shape; P2 declines on the kjd1 gate-2c / P4 positional window, DECLINE-BOTH.
The fix is the class drbq Inc 3 solved for the Ry arm with `recordLivePerActivation`. Is P6
scoped to P1 for this increment, or is the positional widening owed here?

**Q-R1-3 (from L6, F-L6-6) — a DEFINED `void @cq_phi(double)` in the module.** A module that
DEFINES it with an observable body has every call to it SILENTLY deleted by P7 (a
wrong-PROTOTYPE `@cq_phi` declines loudly; a right-prototype DEFINITION is captured in
silence). `cq_phi` / `void(double)` is a plain, short, collidable C signature, where the old
surface needed one of 15 suffixed names. Should a defined `@cq_phi` be a loud decline under
the reserved-name rule the other 33 names follow? **Not implemented here** — it is a surface
decision, and the `!use_empty` narrowing above deliberately did not reach for it.

**Q-R1-4 (from L6, F-L6-6) — a classical INT argument is silently a radian angle.**
`volatile int g = 7; if (q == 5) cq_phi(c);` compiles with no diagnostic at
`-Wall -Wextra -Wconversion` and emits a 7-radian phase. The lowering is correct; the point
is that the one-argument surface no longer separates "register" from "angle" in the type
system, so a mis-ported call is a legal program. The realistic migration slip (a TAINTED
operand) IS caught loudly.

**Q-R1-5 (from L1, F-L1-4) — N ≥ 2 `cq_phi` per arm of an if/else.** The orchestrator's
mid-increment decision accepted N gates per arm, which holds for the DIAMOND spelling; the two
`-O1` shapes an if/else takes both decline (two selects on one compare → `rotation angle`; a
diamond with TWO merge-tail φ → `control flow`). Both loud and safe. Is "N per arm" meant as a
property of the CONSTRUCT or of the one CFG spelling?

---

## What round 1 did NOT clear, and what it says about round 2

Three CONFIRMED defects, three lenses finding the same one independently, and one of the
three (F-L6-1) reachable only through a door — a stale header — that no positive test opens.
The 8h7d.5/drbq record is now **5-for-5** on "the first adversarial round on a core increment
finds a confirmed defect". Two of the three here are the SAME failure mode one level apart: a
SET or a STAGE whose meaning changed while its consumers were not re-asked (`isInPlaceGateOn`
still reading `cqrt_rz_` the old way; `deleteGlobalPhases` still standing where a
one-round pipeline had put it). **Budget round 2, and point it at the sets this round
NARROWED** — the branch-phase membership and the invariant-register roots — because that is
the direction this round's own findings say gets missed.
