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

**Recorded at all SIX emission sites** — ⚠ this sentence said "THREE" when it shipped, in a
tree that already had six, and it is the ONE sentence whose whole job is to let a reader
audit "is every emitter marked?" (Rule-13 round-2 findings F-R1-3 / F-R2-2; round 1's own
hand-back records finding the two extra minters during the Inc-1b merge, and the notes were
never updated). MEASURED with `grep -rn 'markBranchPhaseGate' ir-pass/src`: SIX
`markBranchPhaseGate` calls wrapping SIX `CreateCall(Rz, …)` expressions, in FOUR files,
belonging to FIVE emitters — `SwapRouteEmit.cpp:1538` (P1 flat, arm loop), `:1568` (P1 flat,
merge tail), `:1773` (P4 `emitPhaseKickbackNestRegion`), `SwitchRouteEmit.cpp:179` (P5
`emitSwitchPhaseRegion`), and `AngleSelectEmit.cpp:179`/`:181` (P2, the Rz stem's two
gates). Every one is pinned by at least one fixture (the per-site map is in
`ChainWalk.h`'s comment). A SEVENTH emitter that mints a kickback gate and forgets the call
re-opens this with no diagnostic anywhere — which is not hypothetical: sites 3 and 4 are
exactly that, caught by the merge rather than by a test.

> **DEVIATION FROM THE REVIEW'S PROPOSED FIX, recorded so the owner can overrule it.** The
> L7 plan (endorsed by the orchestrator) said `taint.BranchPhaseGates`, a `TaintSet`
> pointer set. The QUESTION ASKED IS THE SAME — membership of the emitted instruction,
> never a name — but the storage is instruction METADATA (`!cq.branchphase`), for three
> reasons measurable in this tree. (1) The three predicates are PURE per-gate functions
> with no `TaintSet` parameter, asked from **22 call sites in 7 files** (⚠ the shipped text
> said "19 in 6"; round-2 lens R2 measured 21/7 and I measure 22/7 — the residue is whether
> `ChainWalk.cpp`'s adjacent `isInPlaceGateOn`/`preservesBasisUnderRecord` pair counts once
> or twice. The argument is unaffected in every reading; the figure is corrected because a
> census in a write-up that does not reproduce is the F-L6-2 class, and this one sits in the
> paragraph that RECORDS F-L6-2. Re-measure, do not trust:
> `grep -rn 'isInPlaceGateOn(\|preservesBasisUnderRecord(\|isInverseEmittable(' ir-pass/src`
> minus the three definitions), three of which
> (`railOf`, `railCarriesControlledRotation`, `ArithLowering::priorUseIsSettled`) have no
> `TaintSet` in scope at all; threading one through is a cross-cutting signature change to
> the Rule-13 core made in service of a fix to the Rule-13 core. (2) A `Value *` set keyed
> at emission and read many stages later is the bd `drbq` Inc-1 round-1 defect VERBATIM —
> that set dangled when a later stage RAUW'd and erased the key, and the freeze silently
> stopped applying; metadata dies with its instruction. (3) Metadata survives
> `CloneFunctionInto` (Phase-6 specialization), where a pointer set silently would not —
> ⚠ stated as a PROPERTY OF THE RECORD and NOT as a live argument (Rule-13 round-2 finding
> F-R1-5): it is unreachable at this HEAD by the round's OWN other fix, since F-L3-3 makes a
> callee containing any `cq_phi` a loud reject (`cq specialization: callee contains a quantum
> primitive (cq_*); only classical functions are lifted`), so no clone can contain a kickback
> gate to lose. Reasons (1) and (2) are measured and carry the choice alone.
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
| `Uncomputation::preservesBorrowedParent` clause **(1)** | **`true` — it ADMITS the kickback gate, by NAME** | ⚠ **THE ROW ROUND 1 OMITTED, and the omission mattered because this table claims to be COMPLETE** (Rule-13 round-2 finding F-R1-4). `Uncomputation.cpp:591` tests `starts_with("cqrt_rz_") && !ends_with("_controlled") && arity 2 && arg0 == P`, which a kickback gate matches EXACTLY — so this predicate answers `true` for the same instruction the three predicates above were taught to refuse. **The verdict is SOUND and must NOT be narrowed "for symmetry":** the three ask *"may the spine ADJOINT this gate?"* (no — that cancels the answer), this one asks *"does this gate DISTURB the borrowed parent's basis label?"* (no — it is diagonal, whoever emitted it). It is REACHED, not hypothetical: `u8_share_tail` discharges the `zext` rail with the FLAG as borrowed parent while that flag carries three `cqrt_rz_i1` gates. Narrowing it would silently delete that discharge, and clause (1b) below records that the identical narrowing of the CONTROLLED twin cost nine modules theirs. A note to that effect now ships at the site. |
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
* **The e2e witness — AND IT IS ON ANOTHER BRANCH, which round 2 is right to flag**
  (finding F-R2-4): prep-b's already-rewritten `tests/e2e/slice_control_cond_datause.c`
  run on this binary is BYTE-IDENTICAL to its committed (old-surface) golden EXCEPT the two
  intended lines `cqrt_rz_i32_controlled(h1, h0, θ)` → `cqrt_rz_i1(h1, θ)` — PRD §10.2 diff
  class (a), twice, and nothing else. Before the fix that same slice emitted two extra
  NEGATED angles. ⚠ THE REWRITTEN SLICE IS NOT IN **THIS** TREE: it lands with branch
  `3qlq-inc1-slices` (prep-b), merged before the epic's commit. MEASURED at this HEAD,
  **63 of the 66** `tests/e2e/*.c` that call `cq_phi` fail STAGE 1 against the
  register-free `CQ.h`, so **stage 2b runs on not one program Inc 1 lowers and
  `ir-pass-lit` is this branch's only gate** — which is why the F-R2-1 assertion repair
  below is not bookkeeping.
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

---

## §2 — Rule-13 adversarial round 2 (2026-09-05)

Two read-only lenses (R1 = the round-1 FIXES, adversarially; R2 = fixture / doc truth of the
whole branch) plus one hand-off from the slice-migration agent (F-B2-2). Both lenses returned
**NOT CLEAR**. R1 found **one CONFIRMED rolled≠unrolled divergence** and **one plain-C
OVER-DECLINE**, both in code round 1 had just written; R2 found **0 miscompiles and 0
over-accepts** and **five substantive fixture/doc-truth findings, one systemic**.

**The round's own lesson, and it is round 1's lesson pointing back at round 1.** Round 1
closed with "point round 2 at the sets this round NARROWED, because 'a set was narrowed and a
consumer was not re-asked' is the failure mode two of this round's three CONFIRMED defects
share." Round 2 found both of its substantive defects there — but the shape was one level up
from what that sentence predicted:

* **F-R1-1** is a STAGE that runs once, in a pipeline that now has two rounds, whose premise
  ("the marking stage runs after this flatten") is round-2-FALSE. That is F-L3-1's own shape,
  one increment later, in a different stage. Round 1 moved `deleteGlobalPhases` for exactly
  this reason and did not ask the same question of the stage sitting one line ABOVE it.
* **F-R1-2** is a PREDICATE whose header promised one property (`CONTROL-DEPENDENT ON`) and
  whose body computed a weaker one (`reached from`), where the gap is invisible at the slot
  the code was copied FROM and load-bearing at the slot it was copied TO.

Both are "a thing that was true where it was written and false where it was used". The
round-2 discipline that follows is written at the end of this section as the
**"what else runs once before round 2"** table, which is the artifact this round owes the
next one.

### F-R1-1 — CONFIRMED. An in-loop kickback whose loop-invariant register is a Phase-4 MERGE OUT-RAIL leaked one entangled which-path record per activation.

**Reproducer** (2 TU, the shipped onward harness; `p/o_onward_inloop.c` + `p/j1_lib.c`):

```c
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5; if (q > 5) y = ext_f(7);          /* 6.5 classical-call arm -> %out */
    for (int i = 0; i < 3; ++i)
        if (((y >> i) & 1)) cq_phi(0.25);        /* D4's per-bit idiom, ROLLED     */
    return cq_measure(y);
}
```

MEASURED at `c4bd888`: `opt` exit 0, verify-clean, **STRICT stage 2b `0 violation(s)`**, 34
trace lines, THREE `cq_template_and_i32_hl` mints and **ZERO** `_unc` discharges, against a
hand-unrolled twin that discharges all three (40 lines). `diff` of the two traces is exactly
three inserted `_unc` + `cqrt_free` pairs. Each leaked rail holds one BIT of `y` — a
which-path record — and R1's interference probe (`y = cq_theta(y, 0.9);` after the loop)
compiles at rc 0 with the `cqrt_ry_i32` executing while all three records are live. Rolled
and unrolled are different unitaries: the 8h7d.5 F-4 signature, which round 1 itself graded
CONFIRMED as F-L7-2 on the flat surface. Stage 2b is structurally blind to it (a leaked
TEMPLATE-minted rail has no `cqrt_alloc` to count), as its own header says.

**THE POPULATION IS WIDER THAN THE REPORT, and finding that out is what made the fix two
halves instead of one.** R1 located the cause as stage ORDER and proposed either re-running
the collapse or declining a round-2 in-loop region. I built the two adjacent populations
before touching anything, and both are **ROUND-1** regions with the identical leak:

| probe | rolled `and_hl` / `and_unc` / `free` (before) | after |
|---|---|---|
| `p/s1_selectmerge_inloop.c` — 4.4 tainted-condition SELECT merge (`y = (q>5)?7:5`) | 3 / **0** / 4 | 3 / **3** / 7 |
| `p/s2_switchmux_inloop.c` — 4.5 switch DATA-MUX | 3 / **0** / 5 | 3 / **3** / 8 |
| `p/o_onward_inloop.c` — 6.5 classical-call arm (ROUND 2) | 3 / **0** / 4 | 3 / **3** / 7 |

So the common cause is not "round 2": it is **`invariantRegisterRoots` clause (ii) admitting
exactly ONE spelling of "a rail the M-B interior partition can never claim"** — a
classical-arg-0 `cq_theta` root mint — when a `-O1` program routinely produces another one.
Fixing only the stage order leaves s1 and s2; fixing only the clause leaves the onward case.

**THE FIX, both halves.**

*(A) `LoopLowering::invariantRegisterRoots` clause (ii-b).* A **CONTROL-OWNED MERGE OUT-RAIL**
is admitted as a Root: `taint.ControlOwnedRails` MEMBERSHIP **and** a structural
`cqrt_alloc_`-prefixed producer, both required. The proof is clause (ii)'s OWN proof, not a
new one — clause (ii) is sound because `ChainWalk::isInteriorTerminalHandle` clause (I1)
needs `isTemplateProducer` AND a `cq_template_`-prefixed callee, so a root mint (which lowers
to `cqrt_alloc_<W>` + `cqrt_ry_<W>`) can never be the preheader forward gate whose interior
`At` lands in the K-times body. A merge out-rail is ALREADY a `cqrt_alloc_<W>` call at this
point in the pipeline and fails (I1) identically, and the whole-DAG partition excludes it
twice over (`ControlOwnedRails` is checked by name at `Uncomputation.cpp:1356`/`:1558`). A new
clause **(iii-b)** requires such a root to be READ-ONLY inside the loop (any VOID `cqrt_*`
user inside `L` refuses) — the emitters never build that shape, and the clause says so rather
than relying on it. The hoisted `cq_template_mul_i32_hl` rail of owner question Q-R1-1 is what
(I1) ADMITS, so it is what this clause must not, and it is **still refused, measured**.

*(B) the ONWARD loop-rail pass.* `repropagateControlMerges` calls the SAME
`collapseFlattenedLoopRails` a second time at its end, handed the snapshot of
`taint.InLoopFlattenedPreds` taken at entry, so it processes exactly the loops ROUND 2
opened and every pre-round-2 module is byte-identical. It lives INSIDE that function rather
than at the two `CQLoweringPass` call sites so both entry points get it. ⚠ The
`runOnFunction` shim calls neither collapse — a PRE-EXISTING twin-pipeline divergence
inherited from bd 8h7d.5, recorded and not repaired (that shim has zero callers, and the file
already documents four module-wide stages the same way).

**MEASURED after the fix** (`$SP/progress/fix_r2_work/run.sh`, subject vs main @ `c4bd888`):
the onward rolled trace is **BYTE-IDENTICAL to its hand-unrolled twin** (40 lines each); s1
and s2 discharge 3/3; the interference probe discharges 3/3; R1's discriminating control
(the loop reading the `cq_theta` ROOT instead of `%out`) is unchanged; `q1_hoisted_temp` is
byte-identical to main and still leaking. STRICT 2b PASS on every probe.

**MUTATION-VALIDATED ONE HALF AT A TIME** (three build+lit cycles):

| mutation | `..._onward_inloop.ll` | `..._inloop_merge_rail.ll` | the two controls |
|---|---|---|---|
| (B) the onward call deleted | **FAIL** | PASS | green |
| (A) clause (ii-b) disabled | **FAIL** | **FAIL** | green |
| restored | PASS | PASS | green |

**Fixtures.** `control_phase_kickback_onward_inloop.ll` (ACCEPT; `UCNT` and `FCNT` are the
discriminators — measured per prefix against main's binary, `ACNT`/`XCNT`/`NOROUTE` pass
there) and `control_phase_kickback_inloop_merge_rail.ll` (ACCEPT; the round-1 half). Both red
on main, green here.

**WHAT THE DELTA DOES NOT DO, stated because it is the honest limit.** A loop ROUND 1
processed is not re-examined under round-2 taint, so a marking GRANTED at round 1 stands even
if a value that becomes tainted at round 2 would have made `markIfRailLocal` refuse. Marking
is additive and neither call ever unmarks. The residual is bounded by construction: round 2
taints only `%out` rails and their derivations; an `%out` rail is itself an admitted Root
(clause (ii-b)); and a DERIVED one is a template rail whose in-loop region round 2 would have
to claim first. It is recorded here rather than fenced because an unmark would have to be
scoped to the blocks THIS stage marked (`IterationLocalBlocks` is shared with the Case-B
`markIfIterationLocal` owner) — a bookkeeping change to the Rule-13 core with no measured
customer. **OWNER QUESTION Q-R2-1.**

### F-R1-2 — OVER-DECLINE (plain C), introduced by round 1's own F-L5-6 fix, together with a "LATENT / unreachable at HEAD" claim that is measurably false.

```c
void abort(void);
int slice(int u){ int q = cq_theta(u, 0.5);
  if (q == 5) abort();      /* the 7.2 abort park                        */
  cq_phi(0.75);             /* UNCONDITIONAL -> a GLOBAL phase; D2 DELETES it */
  return cq_measure(q); }
```

declined `cq controlled lowering: phase-class value escaping under quantum control`, while
the SAME statement one line EARLIER compiled and the round-1 binary compiled BOTH to the
identical 8-line trace. **A statement the compiler is required to delete made a compiling
program stop compiling.** The classically-guarded twin (`if (g) cq_phi(0.75);` after the
park) declined too.

**Root cause.** `functionCarriesBranchPhase` asked `reachedThroughTaintedBranch` — which is
`deleteGlobalPhases`' Rule-1 assert and answers "is a tainted branch anywhere on any path
reaching this block". At P7's slot that crudeness is SOUND (every tainted `br` is by then
claimed-and-erased or declined, so the honest answer is always "no" and a "yes" means the
invariant broke); at the three carriers' slot, which is BEFORE `lowerControlRegions`, every
tainted `br` still stands and the predicate answers something strictly weaker than the
`CONTROL-DEPENDENT ON` its header promises.

**Fix.** A second, separately-named predicate `controlDependentOnTaintedBranch`: `BB`
post-dominates a CONTINUING successor of the tainted branch and does not post-dominate the
branch itself. **Post-dominance is read over RETURNING paths only**, and that clause is
load-bearing rather than a detail — a textbook `PostDominatorTree` treats the park's
`unreachable` arm as its own root, which makes the remainder "control-dependent" on the park
and keeps the decline. The returning-paths reading matches the physics: the park is coherent
routing, `q` is `cqrt_cswap`ed into a graveyard rail and the remainder runs on EVERY branch,
so a phase after a park really is global. The crude walk stays as a cheap pre-filter (it is
implied by control dependence, so it can only skip work) and keeps its own name — **two
questions, two spellings, which is what Rule 14 actually asks for.**

**MEASURED**: `g_abort_uncond_phase` rc 1 → rc 0, 8 lines, BYTE-IDENTICAL to the same program
with the phase deleted by hand AND to the round-1 subject's trace; the class-guarded twin
likewise; the phase-before-the-branch program unchanged; R1's CLEAR item 6 (three
classically-controlled phases that must be DELETED, not declined) unchanged.

**THE FENCE IS STILL A DISCRIMINATOR, and I had to construct the discriminator** because
R1's own probe is not one: `if (q==7) cq_phi(.75); if (q==5) abort();` is folded by
`clang -O1` into ONE `switch` with an abort case, declines earlier at `control flow`, and
never reaches the carrier at all. `if (q>7) cq_phi(.75); if (q==5) abort();` does not fold,
reaches the carrier, and **still declines** on both binaries.

**Fixtures.** `control_phase_kickback_abort_global_phase.ll` (ACCEPT, red on main) and
`control_phase_kickback_reject_abort_branch_phase.ll` (DECLINE). Their headers say explicitly
that the pair differs in ONE respect — whether the `cq_phi` sits on an ARM or on the path
every returning execution takes — so a future change that makes both accept or both decline
has broken the predicate in one direction or the other.

**And the write-up claim is corrected.** Round 1 graded F-L5-6 *"FIXED (coarse,
over-declining; LATENT — unreachable at HEAD)"*. The `return` and `break` carriers ARE held
shut by earlier fences (measured: `value-arm swap-route` and `loop under quantum control` on
both binaries); the ABORT PARK is not, in either direction — it was reachable with a GLOBAL
phase (the over-decline) and it is reachable with a genuine BRANCH phase (the fence doing its
job). "Unreachable at HEAD" was false about both halves.

### F-R1-3 / F-R2-2 — DOC. The emission-site enumeration said THREE; the tree it shipped in had SIX, in the one comment whose whole job is to make that audit possible.

`ChainWalk.h`'s `markBranchPhaseGate` comment and this file's F-L7-1 paragraph both said
"three today". MEASURED (`grep -rn 'markBranchPhaseGate' ir-pass/src`): **six** calls
wrapping **six** `CreateCall(Rz, …)` expressions, in **four** files, belonging to **five**
emitters. Round 1's own hand-back records finding the two extra minters during the Inc-1b
merge; the sentinel sentence was never updated. Both places now enumerate all six WITH the
fixture that pins each, and say to re-measure rather than trust the list.

### F-R1-4 — DOC. The F-L7-1 closure table was short by one row, and the missing row is a `cqrt_rz_` NAME test that ADMITS the gate the fix refuses.

`Uncomputation::preservesBorrowedParent` clause **(1)** (`Uncomputation.cpp:591`) tests
`starts_with("cqrt_rz_") && !ends_with("_controlled") && arity 2 && arg0 == P` — which a
kickback gate matches EXACTLY. The table listed clause (1b) and marked it unchanged; it did
not list clause (1). **The verdict `true` is SOUND**: the three narrowed predicates ask "may
the spine ADJOINT this gate?" (no) and this one asks "does this gate DISTURB the borrowed
parent's basis label?" (no — it is diagonal, whoever emitted it). It is REACHED, not
hypothetical (`u8_share_tail`). The row is added, and a note now ships at the site saying the
verdict must NOT be narrowed "for symmetry" — clause (1b)'s own comment records that the
identical narrowing of the CONTROLLED twin cost nine modules their whole interior discharge.

### F-R1-5 / F-R2-5 — DOC. A reason that is unreachable by the round's own other fix, and a census that does not reproduce.

Reason **(3)** for choosing metadata over a `TaintSet` set ("metadata survives
`CloneFunctionInto`") is not a live hazard at this HEAD: F-L3-3's own fix makes a callee
containing ANY `cq_phi` a loud reject, so no clone can contain a kickback gate to lose. It is
restated as a PROPERTY of the record. Reasons (1) and (2) are measured and carry the choice
alone. The "19 call sites in 6 files" figure is **22 in 7** by my measurement (R2 measured
21/7; the residue is whether `ChainWalk.cpp`'s adjacent `isInPlaceGateOn` /
`preservesBasisUnderRecord` pair counts once or twice). The argument is unaffected in every
reading; the figure is corrected because a census that does not reproduce is the F-L6-2
class, and this one sat in the paragraph that RECORDS F-L6-2.

### F-R2-1 — SYSTEMIC (the round's headline on the fixture layer). Round 1's assertion repairs were applied to the corpus in front of it and to nothing else in the merged tree.

MEASURED by R2's injection harness at `c4bd888`, and re-measured by me: `cqrt_rz_f80` /
`cqrt_rz_f16` NOT CAUGHT in **18** accepts, an UNPAIRED `cqrt_x` (a WRONG-BRANCH PHASE — the
L1-lens miscompile class) NOT CAUGHT in **21**, an EXTRA `cqrt_free` (a HIDDEN MEASUREMENT,
Rule 6) NOT CAUGHT in **20**. Fifteen of the 18 carry, VERBATIM, the same header sentence the
round-1 repair was made to make true. The provenance partitions exactly: the 18 with the
complement regex are part A's 11 plus the 7 written after that repair; the 15 enumerating six
of eight widths are EXACTLY part B's (a parallel branch that never saw it); the 3 one-width
files are the round-1 fix agent's OWN accepts, written before it repaired the same defect in
eleven inherited files and never revisited.

**Why it is worse here than the same finding was in round 1**: at this HEAD **63 of the 66**
`tests/e2e/*.c` that call `cq_phi` FAIL STAGE 1 against the register-free `CQ.h`, so stage 2b
— which R2 measured DOES catch dropped-strip / extra-free / unpaired-`cqrt_x` on exactly the
nest and switch shapes whose fixtures are blind — runs on **not one program Inc 1 lowers**.
`ir-pass-lit` is this branch's only gate.

**Repaired mechanically, over EVERY accept in the branch** (`$SP/progress/fix_r2_work/repair.py`,
which derives every count from the fixture's OWN pass output rather than from a table): the
Rz negative is the complement regex everywhere (the trailing `(` is load-bearing —
`cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`); every accept has a `cqrt_x` assertion (a
blanket negative where the correct stream has none, an `XCNT-COUNT-n` + `XCNT-NOT` pair where
it legitimately emits them); every accept has a `cqrt_free` assertion on the same rule; and
the one accept with no `cqrt_cswap` negative has one.

### F-R2-3 / F-R2-4 / F-R2-6 / F-R2-7 / F-R2-8 — the rest of the fixture-truth batch.

* **F-R2-3.** Two fixture headers still carried the "BROKEN MODULE at `opt` exit 0" claim
  round-1 F-L3-5 measured FALSE (a `report_fatal_error`, **exit 134**, no module written) —
  one of them written on part B's branch AFTER the correction, i.e. the false claim had
  already propagated once. Both corrected, each naming the finding that corrected it.
* **F-R2-4.** Four shipped documents cite e2e witnesses that are absent or non-compiling
  here. Each is now marked "on branch `3qlq-inc1-slices` (prep-b), merged before this epic's
  commit", and the 63-of-66 measurement is stated where the claim is made rather than left
  for a reader to discover.
* **F-R2-6.** `control_phase_switch_reject_default_body.ll` did not pin its named cause:
  deleting the default arm's phase still declines; only re-pointing the default EDGE at the
  merge accepts. RENAMED to `control_phase_switch_reject_default_edge.ll` and retitled to the
  edge condition, with the mutation recorded and the consequence stated (an EMPTY-but-distinct
  default block declines too — an over-decline, not plain-C reachable because SimplifyCFG
  folds it, and deliberately NOT given a fixture of its own that would be the same
  discriminator under a second name).
* **F-R2-7.** The `!cq.branchphase` record for the whole `AngleSelectEmit` stem — two of the
  six emission sites — was pinned by ONE file in 1665, whose stated subject is the `inf`-arm
  pass-through. The two flagship P2 accepts now carry `MDCNT`/`MDTAG` and assert the
  `, !cq.branchphase` suffix on their `CHECK-NEXT` gate lines. Dropping the mark there now
  reddens three files instead of one.
* **F-R2-8.** `control_phase_kickback_onward_merge.ll` was the weakest accept in the family
  on the axis its own finding is about. It now has the complement Rz negative, a `cqrt_cswap`
  negative, `XCNT`/`FCNT` counts, and — the substantive half — a full ordered `CHECK` chain
  for the ROUND-1 6.5 classical-call-arm region that shares its function, which was entirely
  unasserted while the fixture's whole point is the interaction between the two rounds.

### F-B2-2 (hand-off from the slice-migration agent) — a Q+Q kickback condition declined in the OPCODE layer, not the control layer. Rule 1's third path.

MEASURED by prep_b2 from C: the pre-3qlq ORACLE declines `if (q == p) cq_phi(θ)` with
`cq controlled lowering: control flow under quantum control`; the subject declined it with
`no template for opcode 'icmp i1' in tainted context`. `classifyPhaseKickback` deliberately
did not ask whether the compare was Q+Q, so the region was ACCEPTED at detection and
`lowerCompareToFlag` returned null at the emitter's step 1 — leaving the tainted `br`
**neither claimed nor declined by the control layer**. It was sound only incidentally (the
mint is the first emission, so nothing had been mutated), and it named an OPCODE where the
user wrote a BRANCH.

⚠ The shipped fixture header asserted the opposite and was wrong in BOTH halves: it said the
oracle "emits the same string for the same shape" and therefore that "the surface change
churned no message here". The message DID churn, and it churned LAYERS.

**Fix.** One reason string for the whole phase path (`kQQCondReason` =
`quantum-quantum compare condition`), asked BEFORE any emission, per LEAF, on the
single-compare path and inside a condition tree alike, and asked again by P4's nest ladder.
It replaces three spellings of one question across two layers (`no template for opcode` on
P1-single, `control flow` on P1-tree and on P4). **P5 is exempt STRUCTURALLY, not by
omission**: a switch's flags are `scrutinee == <ConstantInt>`, so a Q+Q eq-flag cannot be
built. `compareFlagMintable` cannot carry this fence and never could — bd adia deliberately
lifted its categorical Q+Q decline for the 4.4 select, which DOES have a Q+Q mint.

**Fixtures.** `control_phase_kickback_reject_qq_compare.ll` and
`control_phase_kickback_reject_tree_qq_leaf.ll` re-pointed at the control-layer string, each
with a `CHECK-NOT: no template for opcode` so the old layer cannot come back; plus a new
`control_phase_nest_reject_qq_leaf.ll` so the shared string is a discriminator at BOTH
classifiers rather than asserted at one. All three red on main's binary.

---

## ⭐ WHAT ELSE RUNS ONCE BEFORE ROUND 2 — the table this round owes the next one

F-L3-1 (round 1) and F-R1-1 (round 2) are the same defect in two different stages: *a stage
standing where a ONE-ROUND pipeline put it, whose premise is FALSE once
`repropagateControlMerges` runs a SECOND full round of control detection + lowering.* Two of
them have now been found by adversarial review and zero by the 1665-fixture suite. So every
stage between `lowerControlRegions` and `repropagateControlMerges` is asked the question
explicitly here, with a disposition. **`repropagateControlMerges` itself already re-runs four
stages** (`declineTaintEscapes`, `declineStaleRecordOps`, `detectSpecializations`,
`replanReseedSpecialization`) — those four are the pattern, not the exception.

| stage, in pipeline order | runs before round 2? | is its premise round-2-false? | disposition |
|---|---|---|---|
| `foldIdentityBitcasts`, `foldVolatileConst*Loads` | yes | **no** — pure syntactic folds over IR shape, and round 2 creates no new bitcast/volatile-load | no action |
| `promoteFp80Union`, `flattenPredMuxRegions`, `recognizeCtlzIdiomLoops` | yes, each to a FIXPOINT with a full re-`propagate` | **no** — each is already a fixpoint, and round 2 adds no fp80 union / PredMux region / ctlz loop (its output is `cqrt_alloc` rails and flattened diamonds) | no action |
| `detectSpecializations` | yes | **YES** — and it is ALREADY re-run inside `repropagateControlMerges` (bd 9paa), with `replanReseedSpecialization` beside it for the frozen-mask half (bd 0vvq / afmv) | **already handled**; ⚠ but see **Q-R2-2** — at ROUND 1 it pre-empts D2 entirely (R1's F-R1-6) |
| `declineTaintEscapes` | yes | **YES** — a round-2 `%out` derivation can be a new escape | **already handled** (re-run inside `repropagateControlMerges`) |
| `declineStaleRecordOps` | yes | **YES** — a round-2-tainted op can be scheduled past a wire gate | **already handled** (re-run inside `repropagateControlMerges`) |
| `lowerControlledIOSinks` | yes | **YES in principle** — an onward `if (%out > k) printf(...)` is a round-2 I/O-under-control shape | **NOT re-run. Over-DECLINES, MEASURED** (`$SP/progress/fix_r2_work/p/z1_onward_io.c`, 2 TU): rc 1, `cq controlled lowering: control flow under quantum control` — the round-2 `detectControlRegions` sees a void-arm diamond with no merge φ and refuses it. The identical program with a ROUND-1 condition ACCEPTS (`p/z3_io_flat.c`, 8 trace lines), so the difference really is the round. Safe direction, no customer. **Q-R2-3** |
| `lowerLoops` (Q1 / Case A / Case B) | yes | **YES in principle** — a loop whose EXIT condition becomes tainted at round 2 | **NOT re-run. Over-DECLINES, MEASURED** (`p/z2_onward_loopexit.c`: `while (%out > 0) { cq_phi(.25); y = y-1; }`): rc 1, `cq controlled lowering: nested control flow under quantum control`. Q1's own message would have been `loop under quantum control`; the CONTROL layer refuses first, so the decline is loud and in the right layer even though it is not Q1's. Recorded as a residual, **Q-R2-3** |
| **`collapseFlattenedLoopRails`** | yes | **YES — THIS IS F-R1-1** | **FIXED**: re-run at the end of `repropagateControlMerges` over the DELTA of `InLoopFlattenedPreds` |
| `deleteGlobalPhases` (P7) | — | — | **already moved AFTER `repropagateControlMerges`** by round-1 F-L3-1 |
| `lowerIOSinks`, `lowerQramReads`, `lowerShadowMemory`, `declineClassicalMuxes`, `declineLiftedStaleRecordOps`, `specialize`, `lowerRotations`, `lowerOps`, `lowerMeasures`, `lowerBreakReversePlay`, `uncompute` | **NO** — all run AFTER | n/a | no action; they see the round-2 CFG and round-2 taint by construction |

**The three residuals above are all in the DECLINE direction** (an unclaimed round-2 shape
falls through to the re-run escape/mux nets, which are loud), which is why they are owner
questions and not fixes. The one that was in the ACCEPT direction — a marking permission
granted on a round-1 premise — is F-R1-1, and it is fixed.

**READ THIS TABLE AS A METHOD, NOT A RESULT.** The question it answers is not "is this stage
correct?" but "**does this stage compute something that a LATER stage consumes, over a
premise round 2 falsifies?**" Both defects found so far answer yes on a MARKING or a
DELETION — a stage whose output is a permission or an erasure, consumed much later, where
being asked at the wrong time is invisible to `opt -verify`, invisible to the golden diff,
and invisible to stage 2b.

## OWNER QUESTIONS FROM ROUND 2

**Q-R2-1 — the round-1 marking is never re-verified under round-2 taint.** `markIfRailLocal`
only ever GRANTS, and neither collapse call unmarks, so a permission granted at round 1
survives a round-2 taint change that would have refused it. Bounded by construction (round 2
taints only `%out` rails, which are themselves admitted Roots, and their derivations, which
are template rails whose in-loop region round 2 must claim first) and with no measured
customer. Making it exact means scoping an UNMARK to the blocks this stage marked, since
`IterationLocalBlocks` is shared with the Case-B `markIfIterationLocal` owner — a bookkeeping
change to the Rule-13 core. Do it now, or file it?

**Q-R2-2 — at ROUND 1, `detectSpecializations` pre-empts D2 entirely** (R1's F-R1-6,
disposition unchanged from `fa96336` and matching the oracle, so not a regression). A
`static int h(int x){ cq_phi(PI); return x+1; }` called with a tainted argument declines
`callee contains a quantum primitive (cq_*)`, although D2 says that phase is a GLOBAL phase
and is DELETED — after which `h` is `return x+1`, a clean lift. It is the one D2-designated
shape that never gets D2's treatment. Owner-scale: it is a question about where P7 sits
relative to the spec scan, not a fix a review round should make.

**Q-R2-3 — two stages before the round-2 fixpoint are not re-run, and both over-decline.**
`lowerControlledIOSinks` (an onward `if (%out > k) printf(...)`) and `lowerLoops` (a loop
whose exit condition becomes tainted at round 2). Both fall through to the re-run escape /
classical-mux nets and decline LOUDLY, so the Prime Directive is satisfied and no customer
exists today. Are they owed the same treatment `collapseFlattenedLoopRails` just got, or is
"round 2 emits only rails and flattened diamonds, so these shapes are exotic" the ruling?
