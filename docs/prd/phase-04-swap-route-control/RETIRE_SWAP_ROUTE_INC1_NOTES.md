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

MEASURED BY R2's injection harness at `c4bd888` — **and say whose measurement each number
is, because that is the discipline this section is about.** R2 measured the CATCH:
`cqrt_rz_f80` / `cqrt_rz_f16` NOT CAUGHT in **18** accepts, an UNPAIRED `cqrt_x` (a
WRONG-BRANCH PHASE — the L1-lens miscompile class) NOT CAUGHT in **21**, an EXTRA
`cqrt_free` (a HIDDEN MEASUREMENT, Rule 6) NOT CAUGHT in **20**. I did NOT re-run that
harness against `c4bd888`; what I re-measured independently is the ASSERTION-PRESENCE census
that explains it (`$SP/progress/fix_r2_work/audit.py`, which runs each fixture through the
pass and reads its own directives): **18** accepts with no complement Rz negative, **21**
with no `cqrt_x` assertion of any kind, **21** with no `cqrt_free` assertion — the same three
families, with the free column one larger because an injected free is sometimes caught
incidentally by an adjacent `CHECK-NEXT` window. What I DID run the harness for is the AFTER
state, below. Fifteen of the 18 carry, VERBATIM, the same header sentence the
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

**Repaired mechanically, over EVERY accept in the branch** (`repair.py` / `repair2.py`, which
derive every count from the fixture's OWN pass output rather than from a table): the Rz
negative is the complement regex everywhere (the trailing `(` is load-bearing — `cqrt_rz_i1`
is a textual prefix of `cqrt_rz_i16`); every accept has a `cqrt_x` assertion (a blanket
negative where the correct stream has none, an `XCNT-COUNT-n` + `XCNT-NOT` pair where it
legitimately emits them); every accept has a `cqrt_free` assertion on the same rule; the one
accept with no `cqrt_cswap` negative has one; **20 gate-bearing accepts gained
`MDCNT`/`MDTAG`**, the pair that catches a dropped `!cq.branchphase` — the record that stops
round-1's CONFIRMED F-L7-1, which was caught by only 15 of 35 gate-bearing accepts; the three
files that legitimately emit `cqrt_copy_*_controlled` (and therefore cannot carry a blanket
`_controlled` negative) gained `@cqrt_rz_{{[a-z0-9]+}}_controlled(`; the hoisted-temp control
gained an `ACNT` count (an extra `cqrt_rz_i1` after its last free was MISSED, because its
only positives are an ordered chain and its whole point is a negative); and the decl-only
family fixture gained `SWEPT-NOT: call void @cq_phi(` (its blanket negative caught the
RETIRED family and not the void one).

**VALIDATED IN BOTH DIRECTIONS BY THE SAME HARNESS**, repointed at this worktree
(`$SP/progress/fix_r2_work/inj.py`, R2's own script plus six injections of mine), **40 accepts
× 16 mutations**:

| control / injection | MISSED before (R2 @ `c4bd888`) | MISSED after |
|---|---|---|
| `clean` — Control A, the fixture must PASS unmutated | 0 dirty | **0 dirty, 40/40** |
| `knownbad` — Control B, delete the forward kickback gate | caught on all applicable | **0** |
| `cqrt_rz_f80` / `cqrt_rz_f16` | 18 / 18 | **0 / 0** |
| `cqrt_rz_i16` | 3 | **0** |
| an extra `cqrt_free` | 20 | **0** |
| an unpaired `cqrt_x` | 21 | **0** |
| an extra `cqrt_cswap` | 2 | **0** |
| DROP one `!cq.branchphase` | 22 of 35 | **0** |
| a `cqrt_rz_<W>_controlled` after the region | 3 | **0** |
| an extra `cqrt_rz_i1` after the last free | 1 | **0** |
| a surviving `call void @cq_phi(` | 1 | **0** |
| `cqrt_cswap` / `cqrt_rz_i1(−θ)` / drop-the-strip (R2's own three) | as R2 measured | **0** |

**TOTAL MISSED + DIRTY over the whole matrix: 0.**

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
them have now been found by adversarial review and zero by the 1666-fixture suite (the count
was MIS-STATED as 1665 here; corrected by the THIRD C-1 round, §3.11 F-C1B-5). So every
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
| **`commitOutOfLoopInPlaceOps`** (inside `collapseFlattenedLoopRails`, added by the SECOND C-1 round) | yes | **YES — THIS IS F-C1B-1 / F-C1C-1**, and it is the archetype the table is for: a stage whose output is a **PERMISSION** (an entry in `taint.InPlaceRailOps`, i.e. a COMMITMENT that `lowerOps` honours without re-asking), computed over `taint.Tainted` and over `P`'s use list, both of which `repropagateControlMerges` and `lowerRotations` then change | **FENCED AND RE-VERIFIED (round 3, §3.11).** The taint half is closed MONOTONICALLY at the commit (`isa<Constant>(Imm)` — a `Constant` is in no `Tainted.insert` site, so its G2 answer cannot move); every other input is RE-ASKED at `lowerOps` for exactly the ops this stage marked (`taint.PreLoopCommittedInPlaceOps`), under a fresh `DominatorTree`/`LoopInfo` and final taint, declining `cq loop lowering: pre-loop in-place op no longer provable at lowering`. **A silent fallback to out-of-place is NOT sound** — the body marking this stage licensed already stands. The full input table is §3.11 — **and its `P` row was re-done with PROGRAMS by the FOURTH round (§3.14), which RETIRED the `hasOneUse` stability conjunct: it guarded nothing G6/G7 does not, and it refused every Phase-4 MERGE OUT-RAIL structurally (the emitters WRITE `%out` before anything reads it), which was F-I2-1** |
| **the OTHER THREE `InPlaceRailOps` writers** — ⚠ **FOUR sites, not three, and this cell's own enumeration was wrong in BOTH directions (eqpx investigation, §3.16): W1 `emitBreakForward` `:1738` (UNLISTED, and a measured member), W2 `tryCaseA`'s ACCEPT `:2321` (= "round 1's `railRoot` marking", ONE site, not two), W3 `collapseRailPhisIn` step (3) `:2719`, W4 `commitOutOfLoopInPlaceOps` `:3124`** | yes | **YES — THIS IS bd `test_C_libtooling-eqpx` (F-C1C-B, §3.12)**, and it is the row round 3 argued it did not need. Their marking is also a PERMISSION `lowerOps` honours without re-asking; their own fences prove the RAIL (self-cycle, fan-out, record reads) and **none of them proves the IMMEDIATE stays classical**, which is exactly the input `repropagateControlMerges` moves | **FIXED 2026-09-06 (§3.16)** — `lowerOps` Phase 1 re-asks **G2 ALONE** (`inPlaceValueRailOperand`) under FINAL taint for every `InPlaceRailOps` member NOT in `PreLoopCommittedInPlaceOps`, declining loudly with `cq loop lowering: in-place rail op no longer provable at lowering`. It was PRE-EXISTING (byte-identical on the pre-3qlq ORACLE 52d7764) and reachable from plain C for BOTH stems. 16 lit fixtures (8 decline + 8 accept control), 0 new goldens, **0 golden churn** |
| **`collapseFlattenedLoopRails`** | yes | **YES — THIS IS F-R1-1** | **FIXED TWICE**: re-run at the end of `repropagateControlMerges` over the DELTA of `InLoopFlattenedPreds` (round 2) — and the DELTA ITSELF was wrong until the SECOND C-1 review round (F-C1-2(2b), §3.10): as a SET of blocks it could not see a round-2 region flattened into the very `Pred` a round-1 region already used, so a mixed loop holding BOTH was never re-offered. It is a per-block COUNT now, and "round 2 opened something here" is the count having MOVED |
| `deleteGlobalPhases` (P7) | — | — | **already moved AFTER `repropagateControlMerges`** by round-1 F-L3-1 |
| `lowerIOSinks`, `lowerQramReads`, `lowerShadowMemory`, `declineClassicalMuxes`, `declineLiftedStaleRecordOps`, `specialize`, `lowerRotations`, `lowerOps`, `lowerMeasures`, `lowerBreakReversePlay`, `uncompute` | **NO** — all run AFTER | n/a | no action; they see the round-2 CFG and round-2 taint by construction |

**The three residuals above are all in the DECLINE direction** (an unclaimed round-2 shape
falls through to the re-run escape/mux nets, which are loud), which is why they are owner
questions and not fixes. The one that was in the ACCEPT direction — a marking permission
granted on a round-1 premise — is F-R1-1, and it is fixed.

**READ THIS TABLE AS A METHOD, NOT A RESULT.** The question it answers is not "is this stage
correct?" but "**does this stage compute something that a LATER stage consumes, over a
premise round 2 falsifies?**" ⚠ **FOUR defects INSIDE THIS EPIC now answer yes** — F-L3-1 (round 1), F-R1-1
(round 2), and F-C1B-1 + F-C1C-1 (the THIRD C-1 round, §3.11), the last two in a stage the
SECOND C-1 round ADDED to this pipeline WITHOUT giving it a row here — **and a FIFTH answers
yes from BEFORE the epic**: bd `test_C_libtooling-eqpx` (F-C1C-B, §3.12), the same class through
the three OTHER `InPlaceRailOps` writers, reproducing on the pre-3qlq oracle. Those writers had no
row here either until this line; they have one now. Adding a stage between
`lowerControlRegions` and `repropagateControlMerges` means adding its row. All four answer yes
on a MARKING or a DELETION — a stage whose output is a permission or an erasure, consumed much later, where
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

## VERIFICATION AFTER ROUND 2 — only what was run

| gate | result |
|---|---|
| `lit ir-pass/test` on this binary | **1666 discovered · 396 FAILED** (`$SP/progress/fix_r2_lit_FINAL.log`) |
| the red partition | the SAME 396 files as before this round's fixture batch, and **every one inside the 493-file retired-`@cq_phi_<sfx>` migration set** (`comm -23` against `grep -lE '@cq_phi_[a-z0-9]+'` is EMPTY). **0 new reds, 0 newly green.** |
| `ctest -R 'frontend-lit\|runtime\|cq-opt-equivalence' -j6` | **9/9 passed**, 23.4 s |
| the injection matrix | **40 accepts × 16 mutations, 0 MISSED, 0 DIRTY** (table above) |
| STRICT stage 2b (`free_pairing_check.py`, no `--allow-unproven`) | **53 accepting subject outputs, 0 violation(s)** |
| the F-R1-1 fix, mutation-validated one half at a time | 3 build+lit cycles, table above |
| the R1 lens's CLEAR item 10 (rolled vs hand-unrolled per-bit) re-run on this binary | `k2` 21 lines, `k4` 39, `k2r` (two registers, two regions per trip) 78, `kg` (body `cq_theta`) 43 — **all IDENTICAL**; `k32` differs by exactly the frontend canonicalization R1 recorded (`(q>>31)&1` → `icmp sgt q,-1` in the unrolled spelling only). Every ROLLED trace is **byte-identical to main's**, i.e. the clause-(ii-b) widening changed nothing that already worked |
| **NOT run** | the full `ctest` (Rule 19 — the orchestrator owns that gate); `e2e-loop-twin-matrix` (I changed no matrix file); any e2e slice (63 of 66 `cq_phi` slices do not compile on this branch — F-R2-4) |

---

## §3 — the Rule-13 CLEARANCE (2026-09-05), the THREE C-1 FIX ROUNDS, the RE-CLEARANCE and the LANDING (all 2026-09-06)

### 3.1 The verdict, in one paragraph

The independent clearance review of Inc 0 + Inc 1 returned **BLOCK** on ONE finding.
Everything else it re-attacked came out clear: 17 new spellings of the round-1 spine-adjoint
class (0 negative-angle `cqrt_rz_i1` in any subject trace, 7 of the same programs still
cancelling on the round-1 subject), 12 probes for a THIRD once-only-stage instance (none
found in the accept direction), 11 retired-family hand-IR spellings, the unowned shapes, D4's
per-bit + diffusion at K=4/K=31/K=32, and B3's plain-C reachability. Its measured gates:
`lit -q ir-pass/test` 1656 discovered / exit 0; the orchestrator's e2e 329/329; the golden
audit 0 unexplained (30 FINDINGs == exactly the 30 rewritten programs); the injection matrix
68 fixtures × 16 mutations = 1088 cells, 0 MISSED / 0 DIRTY; tree-wide `cqrt_rz` scans 0
non-`i1`, 0 `_controlled`, 0 negative-angle. The BLOCK was **C-1**.

### 3.2 C-1 — root cause

```c
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
```

D4's per-bit idiom (condition register `q` loop-INVARIANT, condition DERIVED per trip)
with ONE ancilla rotation added to the body. That one line makes `r` loop-CARRIED, so
`collapseRailPhisIn` returns **`Collapsed`** rather than `NotClaimed` — and the two
paths were EXCLUSIVE:

* `Collapsed` → `markIfRailLocal(Roots = {r's mint})`. Its "accumulating loop-invariant
  tainted input" clause reads `%q` — tainted, defined outside `L`, not `onRail` — and
  RETURNS. Nothing is marked; `Uncomputation`'s in-loop guard
  (`canRepeat(&BB) && !IterationLocalBlocks.count(&BB)`) silently skips every interior
  candidate in the body.
* `NotClaimed` → `invariantRegisterRoots`, the round-1 F-L5-1 fix, which WOULD have
  admitted `%q`. Never reached; and its own clause (i) refuses any tainted header phi
  anyway.

The mixed loop was served by NEITHER. MEASURED at 542d588: `cq_template_and_i32_hl` **3**,
`cq_template_and_i32_hl_unc` **0**, `opt` exit 0, verify-clean, STRICT stage 2b
`0 violation(s)` (structurally blind — a leaked TEMPLATE-minted rail has no `cqrt_alloc`
to count). Hand-unrolled twin: **3/3**. Pre-3qlq ORACLE on the register-surface twin
(`d1o`/`d1ou`): rolled == unrolled, **37 = 37**, `and_unc` **3**. A REGRESSION against the
oracle of exactly the class round 1 (F-L7-2/F-L5-1) and round 2 (F-R1-1) graded CONFIRMED
MISCOMPILE — three entangled which-path records of `q`'s low bits live through the
`cqrt_ry_i32(h0, 0.9)` diffusion, whose branches then carry distinct ancilla labels
(Rule 8). Rolled and unrolled are DIFFERENT UNITARIES.

### 3.3 The fix — option (a), the capability (Rule 17)

`LoopLowering.cpp`, two edits, no new symbol, no new diagnostic:

1. `invariantRegisterRoots` gains `const SmallPtrSetImpl<Value*> *CarriedRoots` and a
   clause **(0)**: a candidate whose `peelInPlaceBase(V, …, AsLowered=true)` is already a
   carried root is **SKIPPED, not judged**. Without it the body's own `r = cq_theta(r,.1)`
   — which after step (4)'s RAUW reads `%r0`, a value defined OUTSIDE `L` — trips clause
   (iii)'s `isInPlaceGateOnArg0` test and takes the WHOLE extension down with it, so the
   invariant register would not be admitted either. The skip asks the SAME
   `peelInPlaceBase(…, AsLowered=true)` spelling the carried set was keyed on and
   `markIfRailLocal`'s `onRail` will use (Rule 14: three readers, one question).
2. `collapseFlattenedLoopRails`'s `Collapsed` branch computes the invariant roots into a
   **SEPARATE `SmallPtrSet Invariant`** and unions it into `Roots` **only on success**.
   `invariantRegisterRoots` fills its out-set INCREMENTALLY and can return `false` after
   inserting some roots, so passing `Roots` directly would let a FAILED extension pollute
   the carried set `markIfRailLocal` is then called with — a permission granted on a
   register nothing proved. On failure the call is byte-identical to the pre-fix branch.

**The proof is clause (ii)'s OWN, unwidened.** A root mint lowers to `cqrt_alloc_<W>` +
`cqrt_ry_<W>`, and `ChainWalk::isInteriorTerminalHandle` clause (I1) requires
`isTemplateProducer` AND a `cq_template_`-prefixed callee — so an admitted Root can never
be the PREHEADER forward gate whose adjoint `At` lands in the K-times body, the one
multiplicity hazard `markIfRailLocal`'s own comment names. That is a property of the ROOT,
not of whether some OTHER register crosses the back edge, which is exactly why the same
argument carries to the mixed case with nothing added.

**Clause (i) after a collapse is NOT vacuous, and that is stated rather than assumed.**
`collapseRailPhisIn` step (1) `continue`s (rather than declining) for a multi-entry header
phi, an unclean latch/entry pair, a latch that does not peel back to the phi with an
UNTAINTED base, and a derived out-of-place base — so a `Collapsed` return CAN leave a
tainted header phi standing. Clause (i) refuses that loop, and `markIfRailLocal`'s own
`TI && isa<PHINode>(I) && BB == Header` refuses it a second time; the disposition is
today's leak, byte-identical. (Owner question, §3.7.)

### 3.4 Mutation validation — one half at a time (the fix_r2 pattern)

| mutation | lit (the C-1 accept fixture) | `d1i` rolled |
|---|---|---|
| M1 — disable the `CarriedRoots` SKIP | **RED** (rc=1) | 31 lines, `and_unc` **0** |
| M2 — disable the UNION on the `Collapsed` branch | **RED** (rc=1) | 31 lines, `and_unc` **0** |
| RESTORED | **GREEN** | 37 lines, `and_unc` **3** |

Both halves are load-bearing; neither is decoration.

### 3.5 The C-1 POPULATION — rolled vs unrolled on 3 binaries, all STRICT 2b `0 violation(s)`

`and_i32_hl` / `and_i32_hl_unc`, rolled and hand-unrolled, on 542d588 (`subj`) and on the
fix. Byte-diff of the two traces in the last two columns.

| program | subj r/u | fix r/u | subj twin | fix twin |
|---|---|---|---|---|
| `d1` mixed, no diffusion | 3/0 · 3/3 | 3/3 · 3/3 | DIVERGES(6) | **IDENTICAL** |
| `d1i` mixed + diffusion (**C-1**) | 3/0 · 3/3 | 3/3 · 3/3 | DIVERGES(6) | **IDENTICAL** |
| `d1k` kickback on `r` too | 3/0 · 3/3 | 3/3 · 3/3 | DIVERGES(6) | **IDENTICAL** |
| `d11` P3 tree with the per-bit leaf | 3/0 · 3/3 | 3/3 · 3/3 | DIVERGES(6) | **IDENTICAL** |
| `d1w` K=32 (rolled only) | 32/0 | 32/**32** | n/a | n/a |
| `d1d` `q` DEAD | 3/0 | 3/3 | n/a | root + rails LEFT ALLOCATED, nothing freed dirty |
| `n1` carried `cq_theta` + `^9` chain | 3/0 · 3/3 | 3/3 · 3/3 | DIVERGES(8) | MULTISET IDENTICAL (see §3.6) |
| `n2` TWO carried + one invariant | 3/0 · 3/3 | 3/3 · 3/3 | DIVERGES(6) | **IDENTICAL** |
| `n3` invariant register MEASURED in the body | 3/0 · 3/3 | 3/3 · 3/3 | DIVERGES(6) | **IDENTICAL** |
| `n6` carried gate BEFORE the kickback | 3/0 · 3/3 | 3/3 · 3/3 | DIVERGES(6) | **IDENTICAL** |
| `n7` second kickback on the carried register | 6/0 · 6/6 | 6/6 · 6/6 | DIVERGES(12) | **IDENTICAL** |
| `n8` mixed + an ONWARD 6.5 region in the same body ⚠ see §3.10 | 6/0 | 6/**6** | flat twin DECLINES on BOTH | structurally paired, LIFO, per trip — **but this row does NOT generalise** |
| `n5` K=1 | 1/1 · 1/1 | unchanged | IDENTICAL | IDENTICAL |
| `d5` per-bit K=32, no second register | 32/31 | unchanged | DIVERGES(21) | DIVERGES(21) UNMOVED (the documented `(q>>31)&1 → icmp sgt` frontend canonicalisation) |
| `d4` K=4, `d7` two invariant registers, `d9` invariant root chain, `d10` trailing `addc`, `d12` invariant cond measured, `e5` P3 carried leaf, `d6` sequential derived | — | **all UNMOVED** | — | — |
| `d1m` direct compare on the invariant register | DECLINE `condition predates a non-diagonal gate` | same | — | UNMOVED (bd `drbq.12`) |
| `b7` onward hoisted temp | DECLINE `control flow` | same | — | UNMOVED |
| **`d2` hoisted `sext` rail** | 3/0 · 3/3 | 3/0 · 3/3 | DIVERGES(10) | DIVERGES(10), rolled trace **BYTE-UNCHANGED subj==fix** |
| **`d3` hoisted Q+Q rail** | 3/0 · 3/3 | 3/0 · 3/3 | DIVERGES(8) | DIVERGES(8), rolled trace **BYTE-UNCHANGED subj==fix** |
| **`n4` per-bit condition on a `sext` of `q`** | 3/0 · 3/3 | 3/0 · 3/3 | DIVERGES(10) | DIVERGES(10), rolled trace **BYTE-UNCHANGED subj==fix** |
| **`n9` mixed + hoisted `q*3` TEMPLATE rail** | 3/0 · 3/3 | 3/0 · 3/3 | DIVERGES(8) | DIVERGES(8), rolled trace **BYTE-UNCHANGED subj==fix** |
| `n10` a body temp derived from `q` that ESCAPES | 3/0 | 3/0 | — | rolled trace **BYTE-UNCHANGED subj==fix** (the escape clause refuses) |

The last five rows are the DISCRIMINATING CONTROLS: the widening did **not** reach the
Q-R1-1 template-rail class (`n9` is its mixed spelling and is pinned as an accept-and-leak
lit fixture) and did **not** weaken `markIfRailLocal`'s escape clause.

⚠ **CORRECTED 2026-09-06 (the SECOND C-1 review round, finding F-C1-4).** The `d2` and `n4`
rows above were first published as `0/0 | 0/0`. That is a MEASUREMENT ERROR, not a
disposition: both conditions are `i64` (`-O1` hoists a `sext` and the per-bit test is done
at the widened type), so an `and_i32_hl`-only grep reads zero where the trace actually
carries `cq_template_and_i64_hl`. Re-measured width-agnostically on all three binaries:
both are **3 / 0 rolled** against **3 / 3 unrolled**. The DISPOSITION recorded — a leak,
rolled trace byte-unchanged across 542d588, the round-1 C-1 fix and this round's — is
unchanged and was re-confirmed. Any count in this file taken with a width-pinned grep is
suspect for the same reason.

### 3.6 Two residual byte divergences are UNFAITHFUL TWINS, measured, not compiler defects

* **`d1c`** (`r ^= 9` per trip): `clang -O1` FOLDS the unrolled source's three xors into ONE
  (`9^9^9 == 9`). Rolled emits 3 `cqrt_xorc_i32`, unrolled 1 — the two SOURCES are not the
  same program. Same class as the clearance's own `d6u`. This is why `n1` was written (a
  `cq_theta` between the xors defeats the fold; it then comes out multiset-identical).
* **`n1`** and the matrix's four `addpost` cells: MULTISET IDENTICAL
  (`diff <(sort r) <(sort u)` EMPTY, same `_unc`/free/mint counts, same line count); the
  only difference is the POSITION of one `cqrt_addc_i32`/`cqrt_xorc_i32` on the SECOND
  register relative to gates on the DISJOINT first one. Read from the two stage-1 modules
  (Rule 11): `-O1` keeps the volatile `load @off` where the source put it and **SINKS the
  `add`** past the next region in the straight-line spelling, which a loop body cannot do
  across the back edge. Commuting operations on disjoint wires. Present identically on
  542d588.

### 3.7 The 8h7d.5 question, answered: what OTHER set is computed over this closure?

The closure widened is *"the Roots `markIfRailLocal` treats as THE REGISTER"*.
GREP-ESTABLISHED FIRST: `Roots` is a LOCAL of `collapseFlattenedLoopRails`, passed only to
`collapseRailPhisIn`, `invariantRegisterRoots` and `markIfRailLocal`; its ONE product that
escapes the stage is `taint.IterationLocalBlocks`, a set of BLOCKS.

| set / predicate | answer | what MEASURES it |
|---|---|---|
| `markIfRailLocal`'s `onRail` / `AnyLocal` / escape exemption | Adding root `R` makes `onRail` true for in-loop values that PEEL to `R`. **There are none**: an in-loop `cq_theta`/`cq_phi` on `R`'s chain makes clause (iii) refuse the whole extension, and an in-loop dtzb `add`/`xor` is `OutOfPlace` under `AsLowered` (`railValueConsumerDisposition` → `blockCanRepeat` is true in a loop), so the peel stops at the BO. The only effect is that the operand clause no longer returns early for `R` itself. | `n10` (a body temp that ESCAPES): trace BYTE-UNCHANGED subj==fix, `and_unc` still 0. Mutations M1/M2. |
| `Uncomputation`'s `IterationLocalBlocks` consumers — the §4/§2.9 MULTIPLICITY pair | An admitted Root is a `cqrt_alloc_<W>` producer, excluded by (I1), so no interior `At` exists for it. **The `Collapsed`-branch half is UNCHANGED by this edit** — that branch already marked; the carried rail's preheader chain is `cq_theta` calls and marked `InPlaceRailOps`, none of them template producers. | `d1w` K=32: **32 mints / 32 uncs** (a K-vs-1 pairing defect shows as 32 adjoints against 1); `d9` (two-hop preheader root chain), `d10`/`n1` (in-place `addc`/`xorc` on the carried rail), `n8` (round-2 delta, 6/6 LIFO per trip). |
| `FreePoint`'s `TermIterLocal` | An invariant ROOT is defined OUTSIDE `L`, so `TermIterLocal` is false for it and it keeps the ordinary Measured/Escaped path — what the pre-existing header already states. | STRICT 2b `0 violation(s)` on every accepting reproducer (~50); `d1d` leaves root and rails allocated, nothing freed dirty. |
| `staleRailRecordRead` (step 2b) | Asked ONLY of the COLLAPSED `ChainsByRoot`, never of an invariant root's chain — **true before this edit too** (the `NotClaimed` path has the identical gap since F-L5-1). Sound here for a reason that must be STATED rather than inherited: clauses (i)+(iii) mean nothing in the body relabels an invariant root, so the escape exemption has an **EMPTY extension** for those roots. The post-loop diffusion is a rail gate, but that is the pass-wide `declineStaleRecordOps` guard's business and is untouched. ⚠ **If a future change ever admits an in-loop in-place gate on an invariant root, that emptiness ends AND step (2b)'s proof still would not cover it.** | `n3` (invariant register measured INSIDE the body ×3) rolled == unrolled; `d12` unmoved; `n11`/`n12` — the pre-existing alias question, §3.8. |
| `ControlOwnedRails` | Read by clause (ii-b), unchanged — the union path reuses (ii-b) verbatim. | `n8`, whose onward 6.5 `%out` rail discharges 6/6 — ⚠ **and `n8` is not the general case; see §3.10 F-C1-2**. `r33`/`r35`, the same program MINUS `n8`'s round-1 region, leaked 3/0 at this point in the round. |
| `railGateBetween` / `collectRailGates` | Neither reads `Roots`; both take CHAIN MEMBERS. GREP-verified. | no coupling to widen. |

### 3.8 What the matrix axis can now see, and the B3 fixture

**Sub-grid F** (`tools/loop_twin_matrix.py`), **10 cells**, 274 → **284**: D4's per-bit
idiom on a loop-INVARIANT `a` beside a loop-CARRIED `r`, at both polarities, with and
without a post-loop diffusion, and the record axis on each register. Nothing in the 274
put a loop-invariant condition register beside a carried one — every `RY_REGION` compares
`a` directly, which is hoist-inert or opaque — and **no cell anywhere read the loop
index**, which is why 274 cells could not see C-1. Two new `_wrap` parameters, both
defaulted (`index` binds `i` on the flat side; `postloop` emits the diffusion), and every
one of the **1104** pre-existing generated sources is BYTE-UNCHANGED — PROVEN by hashing
them all before and after the edit, not asserted. `addpost` is deliberately NOT in the
sub-grid: its twin is unfaithful for the `-O1` reason in §3.6, and quarantining a
scheduler artefact as a filed compiler defect is what the quarantine file's own header
forbids.

**B3** (`kMsgBreakPhase`, `cq loop lowering: early break preserves a phase answer`) had a
plain-C customer and NO fixture; `lowering_reject_break_phase_answer.ll` now pins Q1's
string after the round-2 carrier fix. `lowering_reject_break_phase_answer_kickback.ll`
pins B3 from the clearance's committed `f1_break_kick_before.subj.s1.ll` (a kickback on
`q==5` before the shipped 7.4 break loop), and
`lowering_break_global_phase_before_accept.ll` is its DISCRIMINATING CONTROL: the same
program with an UNCONDITIONAL `cq_phi(0.3)` — a global phase, DELETED by D2 — ACCEPTS with
a trace BYTE-IDENTICAL to the plain break loop's (209 = 209). Without that control B3
would be a wall rather than a discriminator.

### 3.9 OWNER QUESTIONS from the C-1 fix round

**OQ-C1-1 — a `Collapsed` loop with a SURVIVING tainted header phi.** `collapseRailPhisIn`
step (1) `continue`s in four places, so `Collapsed` does not imply "no tainted header phi
remains". The extension refuses such a loop at clause (i) (and `markIfRailLocal` refuses it
again), so the disposition is today's leak, unchanged. Should the mixed extension serve it
too — i.e. is a loop with ONE claimed rail and ONE unclaimed one a shape to prove, or a
shape to keep refusing? No plain-C reproducer was constructed this round; the refusal is
the Prime-Directive direction either way.

**OQ-C1-2 — an alias measured after a later gate on the same wire, PRE-EXISTING and
loop-independent.** `int q=cq_theta(u,.5); int mark=q; q=cq_theta(q,.9); return
cq_measure(mark);` (`p/n12_flat_alias_measure_after_gate.c`, no loop anywhere) ACCEPTS and
emits `ry(h0,.5); ry(h0,.9); measure(h0)` — the POST-gate register measured where the
source named the PRE-gate value. MEASURED IDENTICAL on the **pre-3qlq ORACLE (52d7764)**,
on 542d588 and on the C-1 fix, so it is neither this round's nor this epic's. It is
recorded here because the mixed-loop probe `n11` is its in-loop spelling and a reader will
otherwise mistake it for C-1 fallout: `n11`'s only change across the fix is the SAME three
`_unc`+`free` pairs `d1i` gains, no reordering. Under Rule 8 an `int` copy is an ALIAS of
the register, not a snapshot — is that the ruled semantics, or is it the 8h7d.5 F1 class
one level out of the loop?

**OQ-C1-3 — the flat twin of a mixed loop with an ONWARD region declines.** `n8`'s
hand-unrolled spelling declines `control flow under quantum control` on BOTH binaries, so
the round-2-delta accept has no twin witness (the clearance already filed this as its §5
item 5 for `b2u`/`b6u`). Its rolled form is structurally paired 6/6 LIFO per trip and
STRICT-2b clean, which is the strongest statement available without a twin.

### 3.10 The SECOND C-1 review round (2026-09-06) — F-C1-1 and F-C1-2

An independent Rule-13 lens re-reviewed the C-1 fix and found **two more CONFIRMED
MISCOMPILES of the same class in the fix's own neighbourhood**, plus two documentation
findings. Read that as the headline: the C-1 fix was itself cleared by its round and the
next round found two holes in it, which is the epic's standing pattern (7 findings over 3
rounds on 8h7d.5 Inc 3; 4 over 4 rounds on drbq Inc 4) and the reason to budget another.
Both findings are **capabilities**, not declines (Rule 17), and both leave the
Prime-Directive leak controls byte-unchanged.

#### F-C1-1 — a PREHEADER in-place `add`/`xor` on the INVARIANT register re-opens C-1

```c
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  q = q + 7;                                    /* the one added line */
  for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
```

MEASURED, rolled `cq_template_and_i32_hl` mints / `_hl_unc` discharges:

| binary | rolled | unrolled | twin |
|---|---|---|---|
| 542d588 (pre-fix subject) | 3 / **0** | 3 / 3 | DIVERGE(6) |
| the round-1 C-1 fix (FIX-1) | 3 / **0** | 3 / 3 | DIVERGE(6) |
| this round | **3 / 3** | 3 / 3 | **IDENTICAL** (38 = 38) |

`opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s), 0 unproven` throughout — the
checker is structurally blind to a leaked TEMPLATE-minted rail. The `q ^= 9` spelling is the
same 3/0 (see the unfaithful-twin note below).

**IT IS PRE-EXISTING AND F-L5-1-ERA, NOT ROUND 1's, and that is a measurement.** The same
program with NO carried register (`p/x1_preadd_noR.c` — the `NotClaimed` path, which round 1
did not touch) leaks identically on 542d588 and on FIX-1, while the pre-3qlq ORACLE on the
register-surface twin (`p/x1o`/`x1ou`) is 3/3 rolled == unrolled. So the regression against
the oracle predates the C-1 fix; the fix simply did not reach it.

**ROOT CAUSE — C-1's own sentence, one stage over: the proof exists and a PRECONDITION
excludes the customer.** `invariantRegisterRoots` clause (ii) peels with `AsLowered=true`,
i.e. only through ops whose DISPOSITION is `InPlace`. A preheader `add` is in neither
`taint.InPlaceRailOps` nor a `blockCanRepeat` block, so `railValueConsumerDisposition`
answers `Unproven`, the peel STOPS at the `add`, `dyn_cast<CallInst>(Root)` fails, and the
whole extension returns false. Meanwhile `lowerOps`' M-C lowers that very op IN PLACE —
`cqrt_addc_i32(h0, 7)` is line 5 of the emitted trace — so the register the body reads IS
the root mint's rail and clause (ii)'s (I1) argument carries verbatim.

**THE FIX — ASK THE OWNER OF THAT DECISION, THEN COMMIT TO ITS ANSWER (Rule 14).** "Will
M-C lower this straight-line dtzb op in place?" has exactly ONE spelling in the tree,
`ArithLowering::classifyInPlaceReassignment` (G1 opcode family, G2 shape+width, G3 the
frozen in-place grid, G4 the stage-2b-provable immediate, G5 the loop/cycle exclusion, G6/G7
no later read of the pre-op value). The new `commitOutOfLoopInPlaceOps` walks each
candidate's CLAIM-time chain and asks it; on success the op joins `taint.InPlaceRailOps`,
which is a **COMMITMENT rather than a hint** — `OpcodeLowering:263` skips M-C classification
for a marked op and `:350` routes it to `rewriteInPlaceValueRail`, and M-C's own G5 refuses
a marked site. One fact, both readers, so the peel and the emitter cannot disagree.

**THE STABILITY CONJUNCT `P->hasOneUse()`, and why it is not decoration.** This prediction
is made BEFORE the round-2 control fixpoint while M-C runs after it, so a G6/G7 answer taken
here could in principle go stale — and a stale "in place" is a WRONG UNITARY (the pre-op
register read after the mutation), not a leak. `hasOneUse` closes that window structurally
rather than by an argument about emitters: the only use of the parent is this op's operand,
and no later stage invents a read of a value that has none (every emitter's operands are its
region's condition, arm values and merge incomings — uses that already exist in the IR). It
costs an over-decline in the Prime-Directive direction, and it is pinned from both sides.

**ROLLBACK.** `invariantRegisterRoots` is split into an `...Impl` plus a wrapper that erases
every marking the commit pass made when the extension FAILS, so `taint` is byte-identical on
entry and exit for any module this path does not serve. The round-1 "separate set, union
only on success" discipline, extended to the one other thing the function now touches.

**THE LEAK CONTROL, and it catches a would-be wrong unitary.** `int keep = q; q = q + 7; …
cq_measure(keep)` (`p/x2_preadd_keep.c`): M-C's G6/G7 refuse, the op mints a FRESH
`cq_template_add_i32_hl` rail, and the loop-invariant TEMPLATE rail the body then reads is
owner question **Q-R1-1** exactly. The extension must refuse it, and does: 3/0 on all three
binaries, rolled trace BYTE-UNCHANGED. Mutation M2 (mark on shape alone) flips exactly this
fixture red, with the trace turning into `cqrt_addc_i32` — i.e. the control is a witness for
a wrong lowering, not merely a missing feature.

#### F-C1-2 — a mixed loop whose in-loop region is ONWARD (round 2) leaks, for TWO independent reasons

```c
int ext_f(int a);                             /* second TU: return a + 100; */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);               /* 6.5 arm -> %out, tainted only at ROUND 2 */
  for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25); r=cq_theta(r,0.1); }
  y=cq_theta(y,0.9); return cq_measure(r)+cq_measure(y); }
```

MEASURED on 542d588 AND on FIX-1: rolled 3 mints / **0** `_unc`, hand-unrolled 3/3, the
`diff` of the two traces EXACTLY the three inserted `_unc` + `cqrt_free` pairs; `opt` exit 0,
verify-clean, STRICT 2b clean. On this round's binary: **3/3, IDENTICAL (47 = 47)**. The
same without the diffusion (`r33`) behaves identically.

**(2a) — THE "ALREADY CLAIMED" FACT WAS A LOCAL, AND THE COLLAPSE HAPPENS IN THE OTHER
CALL.** For an ONWARD region the loop's in-body control is CLASSICAL at round 1 (`%out` does
not exist yet), so ROUND-1 `lowerLoops`/`tryCaseA` claims and collapses the carried rail
ITSELF. By the round-2 `collapseFlattenedLoopRails` there is no tainted header phi left,
`collapseRailPhisIn` returns `NotClaimed`, and the local `CarriedRoots` the round-1 fix
passes is `nullptr` — so clause (0) could not fire and clause (iii) refused on the carried
root's in-body `cq_theta(%r,.1)`, taking the INVARIANT register's discharge with it.
FIXED by `taint.ClaimedRailRoots`: the same fact taken from the TREE, written at BOTH
Case-A collapse sites (`tryCaseA`'s ACCEPT and `collapseRailPhisIn` step (4)) and read by
clause (0) in UNION with the local set. `tryBreak` is deliberately NOT a writer — its rails
belong to `lowerBreakReversePlay`, which carries a different proof.

⚠ **NOT INFERRED FROM "NO HEADER PHI", and that distinction is pinned.** An in-place gate
whose result is DEAD in the body (`int t = cq_theta(r,.1);`) mints no phi and carries no
claim; admitting it would grant the marking on a rail nothing proved. `p/x3_deadgate_body.c`
still leaks 3/0 on all three binaries, BYTE-UNCHANGED, and is committed as
`control_phase_kickback_mixed_onward_deadgate_leak_control.ll`. It is the same program as the
accept fixture with ONE token changed (`r =` -> `int t =`), and the two dispositions are
opposite.

**(2b) — THE ROUND-2 DELTA WAS KEYED ON MEMBERSHIP AND THE ROUND-2 REGION LANDS IN THE SAME
BLOCK.** With a ROUND-1 region beside the onward one (`p/r40_onward_r1open.c`: `if(r==3)
cq_phi(0.2);` in the same body), round 1 flattens into `Pred`, round 2 flattens into THAT
SAME (now larger) block, `AlreadyProcessed` — a set of `BasicBlock *` — does not move, and
the loop is **never re-offered**. MEASURED with an env-gated instrumented build: exactly ONE
`[DBG] loop hdr=` line, `round2=0`. And the ROUND-1 call had bailed `!AnyLocal` — correctly,
because at round 1 the values the onward region derives are not yet tainted — so the marking
happened at NEITHER round. FIXED by making `taint.InLoopFlattenedPreds` a per-block COUNT;
the delta is the count having MOVED.

**The re-offer is the GRANT half of Q-R2-1, and it is measured rather than deferred to.** On
a loop round 1 fully collapsed, `collapseRailPhisIn` finds no tainted header phi, returns
`NotClaimed` WITHOUT mutating (step (1) is pure analysis; the `Collapse` map is empty), and
`markIfRailLocal` only ever inserts blocks. Round-2 taint is a strict SUPERSET of round-1
taint and every clause of `markIfRailLocal` is a REFUSAL over tainted values, so the
re-offered grant is asked with strictly more evidence, never less. The once-only-stage table
in §2 carries the new disposition.

#### ⭐ THE 8h7d.5 LESSON, CAUGHT INSIDE THIS EDIT

*"When you widen a set, ask what OTHER set was computed over the same closure."* Widening
clause (0)'s SKIP alone produced `IRR TRUE roots=1` with **nothing marked**: the skip removed
the candidate from judgement and also from `RootsOut`, and `markIfRailLocal`'s "accumulating
loop-invariant tainted input" clause needs the CLAIMED rail in `Roots` to answer `onRail`.
The measurement is what caught it, not the reasoning — the instrumented build printed the
`TRUE` and the traces were unchanged. Clause (0) now skips the candidate **INTO** `RootsOut`,
and the mutation `M4` (skip without inserting) is the pin.

#### The 8h7d.5 table for THIS round's two closures

| set / predicate | the answer | what MEASURES it |
|---|---|---|
| `taint.InPlaceRailOps` — read by `railValueConsumerDisposition` (hence `peelInPlaceStep(AsLowered)`, the Rule-8 fan-out guard and `collectRailGates`), by M-C's G5, and by `OpcodeLowering:263/:350` | Recording a PREHEADER op makes the FACT-time peel walk through it (intended), COMMITS `lowerOps` to the in-place emitter (intended — it is what makes the peel's premise true), and makes `collectRailGates` follow that op as a rail gate. The last is in the DECLINE direction: more gates ⇒ `staleRailRecordRead` sees MORE staleness, never less. The fan-out guard counts `Unproven` and the marking turns `Unproven` into `InPlace`, so it can only ever count FEWER unproven mutators — also the decline direction, and unreachable here because the op is outside `L`. | The whole 124-program population re-run: **95 rolled traces BYTE-UNCHANGED, 6 moved, and the 6 are exactly the F-C1-1/F-C1-2 shapes**. The `staleRailRecordRead` probes `n3`, `d12`, `r60` unmoved. Mutations M1 and M2. |
| `taint.ClaimedRailRoots` — NEW | ONE reader (clause (0)) and TWO writers (the two Case-A collapse sites). Nothing else is computed over it, which is why the answer is short. Entries cannot dangle at any read: every entry is the still-pre-lowering `cq_theta` root mint (or a clause-(ii-b) `cqrt_alloc` out-rail), both writers run before `lowerRotations` — the only stage that erases a root — and both readers do too. ⚠ RETIREMENT TRIGGER: a stage that erases a `cq_theta` placed between `lowerLoops` and the round-2 collapse needs this set to become a `WeakTrackingVH`, because a recycled address matching a live peel root SKIPS a candidate that must be judged (the over-accept direction). | Mutations M3 and M4. The dead-gate control `x3` (no claim ⇒ still refused). `d1i`/`d1`/`n2`/`n7` unmoved. |
| `taint.InLoopFlattenedPreds` — read by `collapseFlattenedLoopRails`'s trigger (`empty()`) and per-block test (`count(BB)`), and snapshotted by `repropagateControlMerges` | The type change from `SmallPtrSet` to `DenseMap<BB,unsigned>` leaves both of those spellings reading identically. The ONLY behavioural difference is the round-2 delta, which now moves when a count moves. GREP-verified: those three sites are the whole surface. | Mutation M5. The 95 unmoved traces include every module with a round-1-only in-loop region. |

#### F-C1-3 / F-C1-4 — the two documentation findings

* **F-C1-3.** A bare `short q` (`p/r5_short_inv.c`) makes `-O1` hoist `sext i16 %2 to i32`
  into the preheader, so the per-bit condition reads a TEMPLATE rail
  (`cq_template_sext_i16_to_i32`) and clause (ii) refuses. 3/0 vs 3/3 on all three binaries,
  rolled trace BYTE-UNCHANGED across 542d588, FIX-1 and this HEAD. This IS the Q-R1-1 class,
  but PRD §0 E2's wording ("a cast, a Q+Q op, an onward `mul`") reads as if the user wrote
  the cast; here NO cast appears in the program at all — the user wrote a TYPE. E2 now says
  so, and the shape is pinned as the accept-and-leak control
  `control_phase_kickback_mixed_short_sext_leak_control.ll` (0 MISSED / 0 DIRTY under the
  injection matrix).
* **F-C1-4.** §3.5's `d2` and `n4` rows were published as `0/0`; both are **3/0 | 3/3**. The
  conditions are `i64`, so an `and_i32_hl`-pinned grep read zero. Corrected in place with the
  reason; dispositions unchanged.

#### The matrix axis (F-C1-7) — sub-grid F3, and what it cannot reach

`tools/loop_twin_matrix.py` gains a PRE-LOOP slot (`_wrap(preloop=)` + `PRELOOP`, both
defaulted) and **sub-grid F3, 2 cells**, 284 → **286**: a preheader in-place `add` on the
invariant register `a` × the diffusing and non-diffusing per-bit regions, at the `rypost`
carry. Both were `TRACE-DIVERGENCE` on 542d588 AND on FIX-1 (2 mints / 0 `_unc` rolled
against 2/2 unrolled) and are `ACCEPT-IDENTICAL` here — measured BY HAND on all three
binaries, not inferred from the table. The 120-cell product now iterates an explicit
`BASE_PREFIX`, so a new `PREFIX` key cannot silently multiply the long-pole gate; every one
of the **1136** pre-existing generated sources is BYTE-UNCHANGED (`dump_sources.py`,
`comm -23` empty, twice — once after the slot and once after the cells).

**`xorpre` IS EXCLUDED, MEASURED, AND IT IS NOT A COMPILER DEFECT.** `xor` DISTRIBUTES over
a bit test, so on the FLAT side `-O1` rewrites `((a ^ 9) >> i) & 1` to `and %a, 2` / `and
%a, 4` for every bit where the mask is 0, creating uses of the PRE-xor register that the
ROLLED side structurally cannot have (its shift amount is a loop variable). The pre-op value
then has a later read on the flat side ONLY, M-C correctly goes OUT of place there
(`cq_template_xor_i32_hl(h0,9) -> h2`, and the flat side even MEASURES `h2`) while the rolled
side emits `cqrt_xorc_i32(h0,9)`. The two SOURCES are not the same program after `-O1`.
`--regenerate` REFUSED TO WRITE and named exactly that as the first differing line; the two
stage-1 modules were then read (Rule 11). The same artefact makes the PLAIN-C `q ^= 9` pair
(`r71`/`r71u`) an unfaithful twin: its ROLLED trace still moves 3/0 → 3/3 under this fix — the
fix working — but its twin cannot witness it. Dropped from the sub-grid with the measurement
in the code, the `addpost` precedent from round 1; the `xorpre` keys are KEPT so one token
re-tests the claim. `add` does not distribute over a bit test, which is why `addpre` is
faithful.

**WHAT THE MATRIX STRUCTURALLY CANNOT SEE, said plainly.** The instrument is SINGLE-TU, so
F-C1-2's onward shape — whose invariant register is a 6.5 classical-call-arm `%out` rail —
is out of its reach by construction. It is pinned in lit
(`control_phase_kickback_mixed_onward{,_r1open}_inloop.ll`) and at e2e
(`e2e-phase-onward-perbit-loop-mixed-twin-identical`, over `run_slice_multi.sh`) instead.
Nor does the OUT-OF-PLACE half of F-C1-1 appear there: it needs a later read of the PRE-op
value, which the `RECORD` axis spells only for values the loop itself produces.

#### Mutation validation — five cycles, one half at a time

| mutant | fixture that must go RED | result |
|---|---|---|
| M1 `commitOutOfLoopInPlaceOps` returns immediately | `..._mixed_preheader_addc_inloop.ll` | **RED** (CHECK/FCNT/UCNT) |
| M2 mark on SHAPE alone (no M-C fence, no `hasOneUse`) | `..._mixed_preheader_add_outofplace_leak_control.ll` | **RED** (CHECK/PCNT/FCNT/UCNT) |
| M3 clause (0) drops the `ClaimedRailRoots` union | `..._mixed_onward_inloop.ll` | **RED** |
| M4 skip WITHOUT inserting into `RootsOut` | `..._mixed_onward_inloop.ll` | **RED** |
| M5 the round-2 delta reverts to MEMBERSHIP | `..._mixed_onward_r1open_inloop.ll` | **RED** |
| RESTORED | all four | **GREEN** on every prefix |

#### Owner questions from this round

**OQ-C1-4 — the `r40` shape has no twin witness at ANY layer, and it is now a shipped
accept.** A loop holding BOTH a round-1 region and a round-2 onward one lowers rolled and
pairs LIFO per trip, but its hand-unrolled spelling declines `control flow under quantum
control` on 542d588, on FIX-1 and here — the same class as OQ-C1-3 / bd `3qlq.9`. The lit
fixture asserts the per-trip pairing structurally instead. Is the flat decline the shape to
fix, or is a structural pairing assertion the accepted witness for this family?

**OQ-C1-5 — `hasOneUse` is a STRUCTURAL fence standing in for a temporal one.** The honest
statement of F-C1-1's residual is that the commit is a prediction made before the round-2
control fixpoint and re-verified by nobody. `hasOneUse` makes the prediction unfalsifiable
by construction (no later stage can add a read to a value with none), at the cost of
over-declining a program whose pre-op value has a legitimate EARLIER read — where M-C would
accept and the loop keeps today's leak. The alternative is a re-verification in `lowerOps`
(re-ask the fence for exactly the ops this path marked, and decline loudly if it no longer
holds), which needs one more set and one more diagnostic. Which does the owner want?

**OQ-C1-6 — `taint.ClaimedRailRoots` is written by two of the THREE rail-collapse sites.**
`tryBreak` also collapses a rail phi to its root (`LoopLowering.cpp` step (4)) and is
deliberately excluded, because its rails belong to `lowerBreakReversePlay` and the claim
clause (0) skips on is not the one `tryBreak` proves. No reproducer combines a break loop
with an invariant per-bit register; if one exists it keeps today's leak, which is the safe
direction.

### 3.11 The THIRD C-1 review round (2026-09-06) — F-C1B-1, F-C1B-2, F-C1B-5 and F-C1C-1

An independent Rule-13 lens re-reviewed the SECOND C-1 fix and found **a CONFIRMED
MISCOMPILE that round had INTRODUCED**, plus a latent over-accept and three record slips.
Building the fix's own tripwire then found **a SECOND confirmed miscompile in the same
function**, in the half round 2's argument said could not go wrong. Read that as the
headline, and read it together with §3.10's: the C-1 fix was cleared by its round, round 2
found two holes in it AND opened one of its own, and round 3 found one more. That is 3
rounds and 3 findings-per-round on ONE function; budget a fourth.

**THIS ROUND IS NARROWING ONLY.** Every change is in the refuse direction. Over the whole
262-program reproducer corpus (round 1's §3.5 population + review_c1's 60 + fix_c1b's +
review_c1b's 51 + this round's 3) the round-2 binary and this one differ on **6 programs in
the F-C1B-1 / (1a) / F-C1C-1 scope, plus `w3` by design (the F-C1B-2 revert)** — status
normalised and every trace byte-compared: the four F-C1B-1 reproducers (back to 542d588's
stream), `z21` (the disclosed (1a) cost, back to 542d588's stream), `y1` (the new loud
decline) and `w3` (the per-loop `ClaimedRailRoots` key, 3/3 → 3/0, back to 542d588's and the
round-1 fix's stream). **256 unchanged of the 262.**
⚠ **THE "6 AND NO OTHERS" THIS SENTENCE ORIGINALLY CARRIED WAS A BOUND OVER A CORPUS THAT DID
NOT YET CONTAIN ITS OWN SEVENTH MOVER** (round-3 lens finding F-C1C-E): `w3`/`w4` were
authored at 02:59, six minutes after the sweep that produced the number finished at 02:53, so
`popdiff` never saw them — even though the round's OWN step 6b reports `w3` moving, by
design, as the F-C1B-2 pin. Nothing about the FIX changes; the BOUND does. **The lens's
independent re-run over a 299-program corpus that DOES contain them: 286 unchanged / 13
moved**, of which one (`c1c_a1`) is a harness artefact of its own probe (byte-identical
lowered IR modulo `ModuleID`; only a `ptrtoint (ptr @g_tab+12 to i32)` load address differs
between two separately linked binaries), the other 12 all in the REFUSE direction, **0
programs FIX2-DECLINE → SUBJECT-ACCEPT, and no decline string changed**. Quote the 299-corpus
figures, with that command, rather than the 262 one.

#### F-C1B-1 — a commitment taken under ROUND-1 taint and honoured unconditionally at `lowerOps`

```c
int ext_f(int a);                          /* separate TU: return a + 100; */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);            /* 6.5 arm -> %out, tainted at emission     */
  int w = y * 3;                           /* DERIVED from %out: untainted until ROUND 2 */
  int a = cq_theta(u,0.7);
  a = a + w;                               /* EXACTLY ONE tainted operand AT ROUND 1   */
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(a)+cq_measure(r)+cq_measure(y); }
```

MEASURED, trace lines 15/18:

| binary | emitted | disposition |
|---|---|---|
| 542d588 | `mul_i32_hl(h3,3) -> h6` ; **`cq_template_add_i32(h7, h6) -> h8`** ; `mul_i32_hl_unc` ; `free(h6)` | 47 lines, CORRECT |
| the round-1 C-1 fix | byte-identical to 542d588 | CORRECT |
| **the round-2 C-1 fix (638334c)** | `mul_i32_hl(h3,3) -> h6` ; **`cqrt_addc_i32(h7, 6)`** ; no `_unc`, no `free` | **51 lines, WRONG** |
| this round | byte-identical to 542d588 and to the round-1 fix | CORRECT |

The lowered IR was `call void @cqrt_addc_i32(i32 %h4, i32 %h_op)` with
`%h_op = cq_template_mul_i32_hl(%out, 3)` — **a quantum rail handle in the ABI's
classical-immediate slot**, printed by the trace runtime as the bare decimal `6` (`h6`'s id).
The circuit computes `a + 6` where the source says `a + 3*y`, the `3*y` rail is left
allocated with nothing uncomputing it, and `cq_measure(a)` measures a register never
entangled with `y`. `opt` exit 0, verify-clean, **STRICT stage 2b `0 violation(s)`** — 2b's
rule (A1) examines the immediate slot per-rail at a `cqrt_free`, and `%h4` is MEASURED rather
than freed, so its write set is never looked at. **The COMMUTED spelling (`int w = y + 1;`)
is worse: `rewriteInPlaceValueRail` picks its rail by `TL = Tainted.count(L)`, so with both
operands tainted the LEFT one wins and the gate MUTATES THE WRONG REGISTER**
(`cqrt_addc_i32(h6, 7)`, and the per-bit condition is then read off `h6`). Four plain-C
programs, both stems, three derived shapes, all round-2-only.

**ROOT CAUSE — the 8h7d.5 lesson a FIFTH time.** `commitOutOfLoopInPlaceOps` asks
`classifyInPlaceReassignment` at the ROUND-1 `collapseFlattenedLoopRails` call
(`CQLoweringPass.cpp:393`) and writes the answer into `taint.InPlaceRailOps` as a COMMITMENT;
`repropagateControlMerges` (`:409`) then GROWS `taint.Tainted` (everything DERIVED from a 6.5
`%out` is tainted only at round 2); at `lowerOps` (`:536`) `OpcodeLowering:263` skips M-C for
a marked op and `:350` routes it to `rewriteInPlaceValueRail`, which never re-asks the shape.
Round 2's stability conjunct `P->hasOneUse()` reasons entirely about **G6/G7** (a later READ
of the parent). The commit also predicts **G2**, the SHAPE — "the other operand is classical"
— and nothing guarded it. *When you widen a set, ask what OTHER predicate was computed over
the same closure: `hasOneUse` was asked of `P`, and the answer that went stale was about
`Imm`.* And notes §2's ⭐ once-only-stage table asks exactly the right question; round 2 added
a NEW such stage without giving it a row. It has one now.

**THE FIX, BOTH HALVES, AND BOTH ARE LOAD-BEARING (mutation-validated separately).**

* **(1a) the MONOTONE fence at COMMIT time:** commit only when `isa<Constant>(Imm)`. A
  `Constant` can never become tainted — a property of the IR class, not a prediction about a
  later stage, and CHECKED rather than assumed: `IOSinkLowering.cpp:295` already enumerates
  every `taint.Tainted.insert(` site as a `CallInst`/`Instruction`/(clone-local) `Argument`,
  never a `Constant`, and it re-measures at this HEAD (`grep -rn 'Tainted\.insert('
  ir-pass/src` → **37 lines, of which 2 are PROSE** — a comment in `DagTraversal.cpp:127` and
  this fence's own **(A) DIRECTION** comment in `commitOutOfLoopInPlaceOps` (by NAME: a line number here goes stale on the next insertion above it) — i.e. **35 CODE sites**; the file's own
  "30" is older. The count travels with its command, and the command's raw output is 37: the
  round-3 lens re-measured it and found the figure right and the quoted command's output
  mis-stated, F-C1C-E). Measured to keep every shipped
  customer (`r2`'s `7`, `r71`'s `9`, `x1`'s `7`, `z7`'s `-7`; `r33`/`r35`/`r40` have no
  preheader op) and to refuse all four reproducers.
* **(1b) a LOUD TRIPWIRE at `lowerOps` (Rule 1 — never a third path):** every committed op is
  recorded in the new `taint.PreLoopCommittedInPlaceOps` (written and rolled back in lockstep
  with `InPlaceRailOps`), and `lowerOps` Phase 1 RE-ASKS the ONE fence under the FINAL
  `DominatorTree`/`LoopInfo` and FINAL taint, declining
  `cq loop lowering: pre-loop in-place op no longer provable at lowering` on a changed answer.
  Exactly one clause is suppressed — G5's `InPlaceRailOps` SELF-marking disjunct, through a
  new defaulted `IgnoreSelfMarking` parameter threaded `classifyInPlaceReassignment` →
  `inPlaceFenceHolds` (ONE fence body; no second spelling). **A silent fallback to
  out-of-place would NOT be sound**: the commit is what licensed `markIfRailLocal` to mark the
  loop body, and that permission already stands in `taint.IterationLocalBlocks`.
  ⚠ **ONLY the ops THIS path committed are re-asked** — a SCOPE decision, and it is not a
  clean bill of health for the other three. ⚠⚠ **THE SENTENCE THAT USED TO STAND HERE —
  *"the other three `InPlaceRailOps` writers mark a rail they PROVED with their own fences"*
  — IS FALSE AS A BOUND ON THIS DEFECT CLASS, and the round-3 lens measured it false
  (F-C1C-B, §3.12).** Their fences prove the **RAIL** (a closed self-cycle, its fan-out, its
  record reads); **not one of them proves the IMMEDIATE stays classical**, which is the input
  F-C1B-1 turned on. The identical defect is reachable through the LOOP writers — `tryCaseA`
  at `lowerLoops` and `collapseRailPhisIn` step (3) — for the **`xor` stem, from plain C**,
  and it is **PRE-EXISTING**: it reproduces byte-for-byte on the pre-3qlq ORACLE 52d7764, on
  542d588 and on every binary of this epic, so it is neither introduced by round 3 nor
  chargeable to it. Filed as bd **`test_C_libtooling-eqpx`**; §3.12 carries the reproducer,
  the population and the proposed fix. The real reason the re-ask is scoped to this path is
  the one recorded at `TaintSet::PreLoopCommittedInPlaceOps` — re-asking M-C's WHOLE fence
  about another writer's op would put a second recognizer over
  G5's loop clause, which the proof's owner deliberately answers differently — and that
  argument is about the FENCE BODY, not about the other writers being immune.

**THE TWO NETS ARE INDEPENDENT, AND THE MUTATION SHOWS IT.** With (1a) removed, the two
reproducer fixtures do not go silently wrong — they fail with
`OPT_RC=1 :: cq loop lowering: pre-loop in-place op no longer provable at lowering`. Defence
in depth, measured rather than asserted.

**THE COST OF (1a), RECORDED NOT REGRETTED.** `p/z21_preadd_volatile_imm.c` — a `volatile`
load as the immediate, a NEW accept the second round had introduced — returns to the
pre-round-2 leak (3 `and_i32_hl` mints / **0** `_unc`, 32 trace lines, byte-identical to
542d588 and to the round-1 fix, and the same stderr warning). M-C ITSELF still lowers that op
in place at `lowerOps`; what the fence refuses is the PREDICTION of that answer, not the
answer. Pinned as `control_phase_kickback_mixed_preheader_volatile_imm_leak_control.ll`.

#### ⭐ F-C1C-1 — a SECOND confirmed miscompile in the same commit, found by BUILDING the tripwire's customer

The brief predicted (1b) would be unreachable from plain C after (1a). It is reachable —
through the G6/G7 half — and the program that reaches it was WRONG on the round-2 binary:

```c
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int q2=cq_theta(q,0.3);            /* the SAME WIRE, a SECOND SSA name for it */
  int a = q2 + 7;                    /* P = %q2, which really does have ONE use */
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(q)+cq_measure(r)+cq_measure(a); }   /* a LATER read of the PRE-op name */
```

| binary | emitted | measures | disposition |
|---|---|---|---|
| 542d588 / the round-1 fix | `cq_template_add_i32_hl(h0, 7) -> h2` | `h0`,`h1`,**`h2`** | 33 lines, correct |
| **the round-2 fix** | **`cqrt_addc_i32(h0, 7)`** | `h0`,`h1`,**`h0`** | **39 lines, WRONG — `q` and `a` collapse onto ONE register** |
| this round | — | — | LOUD DECLINE |

`P->hasOneUse()`'s written argument — *"no later stage invents a read of a value that has
none"* — is TRUE OF THE SSA VALUE AND FALSE OF THE WIRE. `lowerRotations` RAUWs EVERY member
of a theta chain onto the ONE `cqrt_alloc` handle, so at `lowerOps` the parent is `%h`, whose
user set is the UNION of `%q`'s and `%q2`'s: `hasOneUse` was asked of `%q2` and the read that
makes the in-place choice wrong is a use of `%q`. M-C's own G6/G7 refuse it correctly at
`lowerOps` — which is exactly why 542d588 is right — and the commit pre-empted that refusal
from a program point where the read was invisible.

**THE TWIN IS THE WITNESS.** The hand-unrolled spelling of that source emits the out-of-place
stream on ALL FOUR binaries including the round-2 one, so on the round-2 binary the rolled and
unrolled spellings of ONE source compute DIFFERENT VALUES and the unrolled one matches
542d588.

**COST:** a NEW LOUD DECLINE for a program 542d588 accepted-and-leaked. Prime-Directive
direction. The one-token workaround is pinned as the ACCEPT control
`control_phase_kickback_mixed_preheader_chained_root_inloop.ll` — the same program with
`cq_measure(q)` dropped, which still compiles and still discharges all three per-trip rails.
Buying the shape back means a COMMIT-TIME question about the whole WIRE's use closure rather
than the peeled parent's — a new predicate and another prediction, which is the class of thing
that has now failed twice in this function. **OQ-C1-7**, below.

#### F-C1B-2 — `ClaimedRailRoots` was module-wide; clause (0)'s property is PER-LOOP

Round 2's `taint.ClaimedRailRoots` is keyed on the ROOT VALUE and lives in `TaintSet`, so a
claim made for loop A satisfied clause (0) for loop B, whose own clause (iii) question (is
there an in-loop in-place gate on this root?) was then never asked. The header's own pin
(`p/x3_deadgate_body.c`) is a ONE-LOOP module and structurally cannot bound a module-wide set.

FIXED by keying on `(root, the CLAIMING loop's HEADER)`:
`DenseSet<std::pair<const Value *, const BasicBlock *>>`, both writers pass `L->getHeader()`,
clause (0) asks `{Root, L->getHeader()}`.

**THE LENS GRADED IT LATENT; IT HAS AN OBSERVABLE PLAIN-C PIN AFTER ALL.** The four spellings
the lens built all decline at a later fence. A fifth does not —
`p/w3_claim_across_loops_measured_gate.c`: loop A carries `r` (claimed by `tryCaseA`), loop B
has an ONWARD per-bit region AND an in-body `int s=cq_theta(r,0.2); acc+=cq_measure(s);`.
Rolled `and_i32_hl` mints / `_unc`: **542d588 3/0 · round-1 fix 3/0 · round-2 fix 3/3 · this
round 3/0, byte-identical to 542d588 and the round-1 fix.** So the per-loop key is not a new
over-decline — it REVERTS a widening round 2 introduced by accident. (The hand-unrolled twin
of that source declines on every binary in the epic with `loop-carried rail has multiple
in-place consumers`, so there is no twin witness either way; the lens's LATENT grade was right
about the UNITARY and wrong about the OBSERVABILITY.) The DISCRIMINATING CONTROL is
`p/w4_claim_across_loops_two_invariants.c` — the same module with loop B's in-body gate on `r`
removed — 3/3 and byte-identical on all four binaries.

**THE HEADER-BLOCK KEY, and why a block pointer is admissible inside a Rule-13 fence.** A
mis-key can only ever REFUSE: an unmatched claim makes clause (0) JUDGE the candidate, clause
(iii) refuse it, and the module keep today's leak. It is also MEASURED to survive, for BOTH
writers, with an env-gated instrumented build:

```
z32 / w3   round-2 fix : claimed=1                          -> IRR TRUE -> MARKED 1 blocks
z32 / w3   this round  : claimedTOTAL=1 claimedHERE=0       -> IRR FALSE -> nothing marked
r33        this round  : claimedHERE=1   (written by tryCaseA at ROUND 1, read at ROUND 2 —
                                          across the whole round-2 control fixpoint + flatten)
r40        this round  : claimedHERE=1 at BOTH offers  (writer = collapseRailPhisIn step (4))
```
and every shipped customer (r33/r35/r40/z9/z10/r2/x1/d1) keeps its 3/3 rolled-vs-unrolled
identity. ⚠ RETIREMENT TRIGGER, inherited and narrowed: the dangling-pointer hazard the round-2
header records for the ROOT now needs BOTH the root address AND the header address to be
recycled to matching live values, so the key is strictly narrower than what it replaces — but
it is still an address, and a stage that erases a `cq_theta` or a loop header between
`lowerLoops` and the round-2 collapse would still want a `WeakTrackingVH` or a re-validation.

#### ⭐ THE 8h7d.5 QUESTION FOR THIS ROUND — EVERY INPUT OF `classifyInPlaceReassignment` THE COMMIT EVALUATES AT `:393`, AND WHETHER IT CAN CHANGE BY `:536`

The stages in between are `repropagateControlMerges` (which itself re-runs
`declineTaintEscapes`, `declineStaleRecordOps`, `detectSpecializations`,
`replanReseedSpecialization`, a SECOND full `detectControlRegions`+`lowerControlRegions`, and
the round-2 `collapseFlattenedLoopRails`), then `deleteGlobalPhases`, `lowerIOSinks`,
`lowerQramReads`, `lowerShadowMemory`, `declineClassicalMuxes`, `declineLiftedStaleRecordOps`,
`specialize` and `lowerRotations`.

| input of the fence | read by | can it change between `:393` and `:536`? | disposition |
|---|---|---|---|
| `taint.Tainted` — for **`Imm`** | G2 (`inPlaceReassignRailOperand`) | **YES, and this was F-C1B-1.** `repropagateControlMerges` taints every value derived from a 6.5/4.5 `%out` | **FENCED at the commit by (1a)**: a `Constant` is never inserted into `Tainted` (**35 code sites; the grep returns 37 lines, 2 of them prose**, all `CallInst`/`Instruction`/`Argument`), so for a constant immediate G2's answer is FIXED. Re-asked anyway by (1b) |
| `taint.Tainted` — for **`P`** | G2 | It cannot GAIN taint (it is tainted at commit, and `P` is required tainted); it CAN LOSE it — 30 `taint.Tainted.erase(` sites exist, mostly emitter scrub helpers for a REPLACED instruction | **RE-ASKED by (1b)**: G2 then returns null and the module declines loudly |
| `taint.InPlaceRailOps` — self-membership | G5 first disjunct | YES, by our own write | **SUPPRESSED for the re-ask only** (`IgnoreSelfMarking`), because it is an ownership arbitration and not the question being asked |
| the **CFG** (`LI`, `blockCanRepeat`) | G5 second disjunct | The round-2 flatten only SPLICES a diamond into its `Pred` and ERASES the arm/merge blocks; it adds no edge, so it cannot make an acyclic block reachable from itself, and no stage between the two points creates a loop. **No measured customer.** | **RE-ASKED by (1b)** under a FRESH `LoopInfo` the driver builds per function — so the argument does not have to be trusted |
| the **use lists** (`hasOneUse`, and G6/G7's walk over `P->users()`) | the commit's stability conjunct, G6, G7 | **YES, and this was F-C1C-1.** `lowerRotations` RAUWs every member of a theta chain onto ONE handle, so the parent's user set at `lowerOps` is the UNION of the chain's. (`declineClassicalMuxes`' one-register merge-phi lift RAUWs a merge phi to its wire base and would do the same, but such a phi is already a use of a chain member at commit time, so `hasOneUse` refuses first.) | **RE-ASKED by (1b)**, which is the only reason F-C1C-1 is a loud decline instead of a wrong unitary |
| the **`DominatorTree`** | G6 (`provablyBefore`) | Yes in principle (blocks merge), and vacuous at commit time because `hasOneUse` leaves the G6/G7 loop with no non-`Site` entry | **RE-ASKED by (1b)** under a fresh `DominatorTree` |
| `wd` widths, `bo`'s type | G3, G2 | **NO** — an instruction's type is immutable and `WidthDispatch` is a pure resolver | no action |
| the `InteriorDischargePlan` | G7 | **NO** — `lowerOps` runs before `uncompute`, so it is `nullptr` at both points | no action |

Everything in the "YES" rows is now either fenced monotonically at the commit or re-verified
loudly at the consumer. **The ⭐ once-only-stage table in §2 gains its row for this stage.**

#### Mutation validation — one half at a time, on a private `git archive HEAD` DBG copy

| mutant | fixture that must go RED | result |
|---|---|---|
| RESTORE | — | all 7 GREEN on every prefix |
| **M1** drop `isa<Constant>(Imm)` | the two r2derived accepts + `..._volatile_imm_leak_control.ll` | **RED** — and the two r2derived files fail with `OPT_RC=1 :: cq loop lowering: pre-loop in-place op no longer provable at lowering`, i.e. (1b) catches (1a)'s defect as a REFUSAL |
| **M2** never re-ask at `lowerOps` | `..._reject_preloop_commit_stale.ll` | **RED**, and nothing else moves |
| **M3** revert the per-loop `ClaimedRailRoots` key | `..._claim_across_loops_leak_control.ll` | **RED**, and nothing else moves |
| RESTORE | — | all 7 GREEN |

#### Fixtures (7 new, corpus 1666 → **1673**)

`control_phase_kickback_mixed_preheader_r2derived_imm_outofplace.ll` and
`..._r2derived_commuted_outofplace.ll` (ACCEPTs asserting 542d588's CORRECT out-of-place
stream, RED **on the round-2 binary only**), `..._preheader_volatile_imm_leak_control.ll` and
`..._claim_across_loops_leak_control.ll` (ACCEPT-AND-LEAKS, also RED on the round-2 binary
only), `control_phase_kickback_reject_preloop_commit_stale.ll` (the (1b) DECLINE, RED on all
three earlier binaries), and two DISCRIMINATORS —
`..._preheader_chained_root_inloop.ll` (RED on the two PRE-round-2 binaries, so it pins the
round-2 CAPABILITY that (1b) must not blanket away) and
`..._claim_across_loops_accept_control.ll` (green everywhere, so the per-loop key cannot be a
blanket refusal). Injection matrix over the six accepts: first run **6 MISSED**, after adding
the missing `FCNT`/`XCNT`/`ACNT`/`MDCNT`/`UCNT` prefixes and the two `cqrt_rz_<W>` NOROUTE
negatives, **0 MISSED / 0 DIRTY**.

#### F-C1B-5 — three record slips, corrected

1. `CLAUDE.md`'s "the lit corpus 1660 → 1665" was one short of the tree it shipped in (1666);
   corrected, and extended to this round's 1673.
2. §2's ⭐ table preamble said "zero by the 1665-fixture suite"; corrected to 1666, which is
   what the tree held when that sentence was written.
3. The second round's hand-back said the twin matrix gained *"16 new (4 cells × 2 surfaces × 2
   spellings)"*. That is the PRE-`xorpre`-drop state; the shipped state is **8 new rows / 2
   cells**, which is what §3.10 says and what both the lens and this round re-measured
   (`grep -c '^m_' tools/loop_twin_matrix.expected.txt` → **257**). The hand-back is a session
   artefact and is corrected here rather than edited.

#### Owner questions from this round

**OQ-C1-7 — the (1b) tripwire buys soundness with an over-decline, and the alternative is
another prediction.** F-C1C-1's program (a chained-theta wire whose PRE-op SSA name is read
after the loop) declined nowhere before this round and declines now. The alternative is a
COMMIT-TIME conjunct over the whole WIRE's use closure — "no member of the peel chain has a
use other than its successor" — which would restore 542d588's accept-and-leak for that shape
at the cost of a NEW predicate that is itself a prediction, in the one function whose
predictions have now failed twice. Ship the decline (as here), or buy the shape back?

**OQ-C1-8 — the `isa<Constant>(Imm)` fence costs the volatile-immediate customer, and the
same question applies.** M-C accepts that immediate at `lowerOps` (census 0.5 cleared a
volatile load explicitly, and `slice_control_seq_grover`'s own `off` is that shape); only the
PREDICTION of the answer is refused. Widening (1a) to "a `Constant` OR any value the fence's
G4 already proves stage-2b-classical" would need an argument that the widened class cannot
gain taint at round 2 — true for a `load` today (round 2 taints only `%out` derivations, and a
`load` of a non-escaping local is not one) and not obviously stable.

**OQ-C1-9 — should the commit exist at all, or should `lowerOps` publish its answer BACKWARD?**
Both findings of this round are the same shape: an emitter's decision predicted by an earlier
stage. The structural alternative is to move the whole in-place question to `lowerOps` and
have `lowerLoops` ask a CONSERVATIVE version (would M-C possibly fire?) that only ever
over-declines. That is a re-plumbing of the Rule-13 core, not a review round's call.

### 3.12 What the round-3 LENS found OUTSIDE the round's scope — F-C1C-B, a PRE-EXISTING confirmed miscompile of the same class through the LOOP writers (bd `test_C_libtooling-eqpx`)

The independent lens on round 3 graded the round itself **CLEAR-WITH-ITEMS** (F-C1C-A/C/D/G
CLEAR, F-C1C-E/F DOC). It also probed the ONE sentence round 3 used to bound its own scope —
*"the other three `InPlaceRailOps` writers mark a rail they PROVED with their own fences"* —
and **measured it false**. The finding is **NOT round 3's, NOT this epic's, and cannot block
either**: it reproduces byte-for-byte on the **pre-3qlq ORACLE 52d7764**, on 542d588, on the
round-1 fix, on the round-2 fix and on this branch. It is recorded here because §3.11's
sentence and `OpcodeLowering.cpp`'s comment would otherwise be read by the next round as a
BOUND, which is exactly how the F-C1B-1 class got its second and third instance.

**THE REPRODUCER — plain C, 2 TU, no hand-IR** (lens `p/c1c_m_xor_and_noregion.c`; the second
TU is `int ext_f(int a){ return a + 100; }`):

```c
int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);      /* a 6.5 classical-call arm -> %out           */
  int w = y & 7;                     /* DERIVED from %out: tainted only at ROUND 2 */
  for(int i=0;i<3;i++){ r = r ^ w; } /* an in-BODY rail op, marked by tryCaseA     */
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
```

MEASURED, identical on all five binaries — 21 trace lines, `opt` exit 0, verify-clean, STRICT
stage 2b **`5 rail mint(s) of which 5 left allocated … 0 violation(s), 0 unproven`**:

```
cq_template_and_i32_hl(h3, 7) -> h6      <- w = y & 7 : a QUANTUM rail off the 6.5 out-rail
cqrt_xorc_i32(h1, 6)                     <- r ^= 6 : the bare decimal 6 IS h6's HANDLE ID
cqrt_xorc_i32(h1, 6)
cqrt_xorc_i32(h1, 6)
cqrt_measure_i32(h1) -> 0                <- measures a register never entangled with y
```

Lowered IR: `call void @cqrt_xorc_i32(i32 %h2, i32 %h_op)` with
`%h_op = call i32 @cq_template_and_i32_hl(i32 %out, i32 7)`. `h6` is never `_unc`'d and never
freed. **This is F-C1B-1's defect verbatim, one writer over.** Stage 2b is blind for the
reason it is always blind to this family: its immediate check runs per rail at a `cqrt_free`,
and `h1` is MEASURED rather than freed, so its write set is never looked at.

**POPULATION, measured by the lens on the subject (and identical on 542d588 and, where the
surface allows, on the oracle):**

> ⚠ **PRECISION, added at the landing (2026-09-06, re-clearance record item 5 —
> `inc1-records/session-adc5590a/clearance2.md` §2.5/§5; PRD §0 E10 line 5): "identical on
> 542d588" is true of the DEFECT and NOT of the TRACE for the four IN-REGION members**
> (`c1c_m_xor_and`, `c1c_m_xor_mul`, `c1c_m_xor_add1`, `c1c_w2_bodyxor_r2derived`). Those four
> are ALSO mixed-population programs, so their traces MOVE pre-fix → subject (44 → 50 lines:
> exactly the three `and_i32_hl_unc` + `free` pairs of the C-1 discharge) while
> `railInImmSlot` stays 1 on every binary. `c1c_m_xor_and_noregion` — the reproducer printed
> above — IS byte-identical ORACLE == PRE-FIX == SUBJECT (21 lines, `cmp`), which is the row
> that carries the "pre-existing, not this epic's" claim. Read the table's "identical" column
> as being about the defect.

| probe | in-body op | derived immediate | region in the body? | handle in the immediate slot |
|---|---|---|---|---|
| `c1c_m_xor_and_noregion` | `r ^= w` | `y & 7` | no (round-1 `tryCaseA` is the writer) | **YES** |
| `c1c_m_xor_and` / `c1c_w2_bodyxor_r2derived` | `r ^= w` | `y & 7` | yes (round-2 `collapseRailPhisIn` step (3)) | **YES** |
| `c1c_m_xor_mul` | `r ^= w` | `y * 3` | yes | **YES** |
| `c1c_m_xor_add1` | `r ^= w` | `y + 1` | yes | **YES** |
| `c1c_w2o_..._oldsurface` | `r ^= w` | `y & 7` | yes, register-form `cq_phi` | **YES on the pre-3qlq ORACLE** |
| `c1c_m_add_{and,mul,add1}`, `c1c_m_add_and_noregion`, `z36`, `c1c_w1` | `r += w` | any | either | no — the correct out-of-place Q+Q `cq_template_add_i32(h3, h_op)` |

So it is an **`xor`-stem-only asymmetry as measured**, and `z36` — the one negative probe
review_c1b's scope paragraph rested on — happens to be an `add`. ⚠ The CAUSE of the stem
asymmetry is **not located**; do not read "add is safe" out of this table, read "no `add`
spelling we tried reaches it".

> ⚠ **FALSIFIED 2026-09-06 by the eqpx investigation and the fix increment — see §3.16.** The
> row above is KEPT because its measurements are true of the probes it names; what is retired
> is the reading. The `add` stem is reachable, by FIVE spellings — four plain C
> (`a1_add_gate_in_body`, `a2_add_two_offsets`, `a3_add_xor_mixed`,
> `n08_add_region_gate_in_body`) and one ONE-OPCODE hand-IR mutation of this very table's
> flagship (`hand_add_from_xor.ll` = `c1c_m_xor_and_noregion`'s own stage-1 module with
> `%19 = xor` changed to `%19 = add`, nothing else) — all ACCEPT with
> `cqrt_addc_i32(h?, <handle id>)` on all four binaries measured there. **The CAUSE IS NOW
> LOCATED and it is `clang -O1`, not any fence**: `inPlaceValueRailOperand`
> (`LoopLowering.cpp:145`) admits `Add` and `Xor` identically, and what differs is
> IndVarSimplify's exit-value rewrite, which closed-forms the affine add-recurrence
> (`%10 = mul nuw nsw i32 %9, 3 ; %11 = add i32 %3, %10`) so LoopDeletion removes the loop and
> no writer ever sees the op. ONE extra body op defeats it. The hedge the row wrote for itself
> ("read *no `add` spelling we tried reaches it*") was the right hedge and it is now spent.

**ROOT CAUSE, and it is the same words as F-C1B-1's.** `rewriteInPlaceValueRail`
(`ArithLowering.cpp`) picks the rail with `bool TL = taint.Tainted.count(L)` and passes the
OTHER operand through as the classical immediate, under a comment saying the recognizer proved
exactly one tainted operand. By `lowerOps` BOTH operands are tainted: the loop writers ran at
`lowerLoops` (`CQLoweringPass.cpp:363`) and at `collapseFlattenedLoopRails` (`:393`), and
`repropagateControlMerges` (`:409`) taints the `%out` derivation afterwards. **Their fences
prove the RAIL — the self-cycle, its fan-out, its record reads. None of them proves the
IMMEDIATE stays classical**, and that is the input this defect turns on. It is the ⭐
once-only-stage class of §2's table (a value computed before `repropagateControlMerges` and
consumed after it), reaching the three writers §3.11 left alone.

**PROPOSED FIX (bd `test_C_libtooling-eqpx`, NOT built here).** The shape round 3 shipped for
the preheader writer, applied to the rest: at `lowerOps`, for **every** `InPlaceRailOps`
member, re-ask **G2 alone** ("exactly one tainted operand") under FINAL taint and DECLINE
LOUDLY on a changed answer — G2 alone, not the whole fence, because G5 would always refuse an
in-loop site — with a mirrored decline fixture per stem plus the three reproducer spellings,
and then the 8h7d.5 question asked of all four writers together. **Never a silent fallback to
out-of-place**: the body marking those writers licensed already stands in
`taint.IterationLocalBlocks` (Rule 1, the §3.11 (1b) argument verbatim).

**Reproducers** live in the session-2 scratchpad
(`.../adc5590a-.../scratchpad/progress/review_c1c_work/p/c1c_m_xor*.c`, `c1c_w2*.c`, plus
`tu_extf.c`); bd `test_C_libtooling-eqpx` carries the full description, and the round-3
plain-C corpus that IS committed is `inc1-records/c1-round3/`.

#### The two DOC findings of the same lens, applied above rather than only listed here

* **F-C1C-E** — §3.11's population headline bounded the round over a corpus that did not yet
  contain its own seventh mover (`w3`, created six minutes after the sweep). Corrected in
  place, with the lens's 299-program re-run (286 unchanged / 13 moved, 0 in the accept
  direction) as the figure to quote. And the `35` `Tainted.insert` sites is right while the
  command quoted beside it returns **37 lines, 2 of them prose** — corrected in §3.11, in the
  `LoopLowering.cpp` fence comment, and in the input table.
* **F-C1C-F** — `TaintPropagation.h`'s `ClaimedRailRoots` paragraph argued "a mis-key can only
  ever REFUSE", which covers the **MISS** direction only; the **RECYCLE** direction (root
  address AND header address both recycled to matching live values) is the retirement trigger,
  and the paragraph directly above it records exactly that direction for the root half. One
  sentence added to the header. Not a defect: no spurious match is constructible today, and
  `RegionFlatten` erases ARM/MERGE/COND blocks between the writers and the round-2 reader,
  never a loop HEADER in any measured shape.

### 3.13 The RE-CLEARANCE (2026-09-06) and the LANDING

Full report: `inc1-records/session-adc5590a/clearance2.md`. Five-line summary of the whole C-1
disposition: PRD §0 **E10**.

**VERDICT `CLEAR-WITH-OWNER-QUESTIONS`.** The BLOCK is closed: C-1's population — the flagship
per-bit idiom with a carried register, plus the preheader-in-place and onward spellings rounds
2 and 3 found — is rolled == hand-unrolled byte-identically on the subject (60 pairs, 3 new
`cmp`-gated goldens, the matrix sub-grid F/F3 with no new quarantine cell); the two miscompiles
round 2 introduced are gone (the four F-C1B-1 programs byte-identical to the round-1 fix and to
542d588; the F-C1C-1 class declines loudly); `w3` is back to 542d588's stream. **The tree is a
strict improvement over 542d588 at every layer the review could measure**, and these are its
figures, each with the pair it was measured over: **0 DECLINE→ACCEPT flips over 404 programs**
(PRE-FIX → SUBJECT, 301 unchanged / 103 moved, every mover a discharge or a loud decline);
**1667 of 1673 fixtures byte-identical** between the two binaries on stdout + stderr + exit
code, the 6 movers all in scope; **305 of 308 e2e slices** producing the committed golden on
the PRE-FIX binary too, the 3 exceptions being exactly the three ROLLED mixed goldens PRE-FIX
leaks; **0 stage-2b violations** over 284 accepts (the 2 `unproven` are the `--allow-unproven`
break family, checker output byte-identical to PRE-FIX's); **1328 injection cells (83 × 16) 0
MISSED / 0 DIRTY**; the golden audit unmoved beyond NEW-FILEs; the twin matrix green at 286
cells with `quarantine.txt` **byte-unchanged**; bd `eqpx` byte-identical ORACLE == PRE-FIX ==
SUBJECT. On that verdict **Increments 0 and 1 LANDED on `main` 2026-09-06 as ONE squash commit**
(hash filled by the orchestrator: the squash of branch `3qlq-inc1-fix-c1`, whose tip is recorded
in the landing commit message; `git log main -1` shows the hash).

**WHAT THE VERDICT LEAVES OPEN — four owner questions and one record item, every one a
DISCLOSED class that PRE-DATES this branch, none of them a wrong unitary this tree introduced.**
Read them before widening anything in `LoopLowering` or `ArithLowering`:

* **OQ-C2-1 — the `hasOneUse` over-decline has an ORACLE-DISCHARGED customer, and E2's residual
  list does not name it.** ⚠ **ANSWERED, AND PARTLY CORRECTED, BY §3.14 (the FOURTH C-1
  round): the conjunct is RETIRED — and `m11d` is NOT bought back by retiring it.** Its
  refusal was attributed here to `hasOneUse`; MEASURED on an instrumented build, `m11d`'s
  candidate is refused by **`classifyInPlaceReassignment` ITSELF** (G7 arm (e): at the commit's
  program point loop 1's `(q>>i)&1` is a still-UNLOWERED tainted `and i32`, not a settled
  producer), so the trace is byte-unchanged across §3.14's fix. The half that WAS `hasOneUse`
  is F-I2-1's merge-out-rail family, which §3.14 does buy back. Read the OQ as two claims: the
  conjunct's retirement (done) and `m11d`'s disposition (still a leak, still disclosed, and now
  attributed to the fence rather than to the conjunct). `m11d` (two per-bit loops, no preadd, a diffusion after): loop 2's
  candidate `q+3` has a parent with TWO uses, so `commitOutOfLoopInPlaceOps` refuses on
  `P->hasOneUse()` although M-C lowers that very op IN PLACE — 6 mints / 3 `_unc` rolled, while
  the flat twin on the SUBJECT and the pre-3qlq ORACLE on the old-surface twin both discharge
  all six (oracle rolled == unrolled, 68 = 68). A strict improvement over PRE-FIX (6/0 → 6/3)
  and disclosed as a leak, which is why it is an owner question and not a second BLOCK. The
  question: now that (1b) re-verifies the whole fence at `lowerOps`, is the stability conjunct
  still needed, or can the commit ask M-C alone? If it is kept, name it in E2 and pin it —
  `m11d` is fixture-ready.
* **OQ-C2-2 — `short` (F-C1-3) is the one Q-R1-1 member the ORACLE got RIGHT**, so `r5` is an
  oracle regression rather than an inherited leak: the oracle's peel walks through the `sext`
  the register-form arm forced it to see (3/3 rolled, its flat twin 3/3), while every 3qlq
  binary is 3/0. The other Q-R1-1 members measured (`n9o`, `d2o`, `d3o`, `b01o`) leak on the
  oracle too. Either peel through a hoisted `sext` of a root mint, or record `short` as the
  exception.
* **OQ-C2-3 — widen the Q-R1-1 disclosure by two spellings**: a `switch` lookup table whose
  invariant root is a `cqrt_qram_load` rail, and `-O1`'s SIDEWAYS compare rewrite after a
  preadd (`q=q+7; if(q>5)…` → `icmp sgt %q0, -2`, so `q0` gains a later read and M-C goes out
  of place). Both byte-identical PRE-FIX == SUBJECT; both oracle twins decline.
* **OQ-C2-4 — the OQ-C1-7 over-decline list gains `s20`**, a pre-op name MEASURED before the
  op, where the flat twin is out of place on every binary and correct.
* **Record item — §3.12's "identical on 542d588" is true of the DEFECT and not of the TRACE**
  for the four IN-REGION `eqpx` members. Applied in place, at the §3.12 population table.

---

### 3.14 The FOURTH C-1 round (2026-09-06) — F-I2-1: `P->hasOneUse()` is RETIRED, and the safety is the round-3 tripwire

Full record: `inc1-records/session-adc5590a/c1-round4/fix_c1d.md` (with its lens
`.../c1-round4/review_c1d.md`, verdict CLEAR-WITH-ITEMS). bd `7yd0`. The finding is
`review_inc2_r2`'s **F-I2-1** and it is the same shape the re-clearance had already filed as
**OQ-C2-1** — so read this section as the disposition of BOTH.

**WHO FOUND IT, AND THAT IS THE FIRST FACT.** Not a round on this function: the Rule-13 round
on **Increment 2**, which measured the C-1 machinery in passing and found a rolled ≠ unrolled
divergence on the **LANDED `main` a3c1513**, from thirteen lines of plain C containing no
Inc-2 feature. The re-clearance that landed Inc 0+1 had graded the same conjunct an
over-decline (OQ-C2-1) on a DIFFERENT program and shipped it as a disclosed leak. **Eight
instances over six adversarial rounds on one function, and the eighth was found by a round
that was reviewing something else.**

#### The program, and the two axes whose PRODUCT nothing covered

```c
int q=3,p=7,r=9; q=cq_theta(q,.5); p=cq_theta(p,.25); r=cq_theta(r,.3);
int m = (q > 5) ? p : r;                       /* 4.4 SELECT merge -> %out rail */
m = m + 7;                                     /* PREHEADER dtzb op ON that rail */
for (int i=0;i<4;i++) if ((m>>i)&1) cq_phi(.7);/* D4's per-bit idiom, ROLLED     */
return cq_measure(m);
```

MEASURED on `main` a3c1513: **4 `cq_template_and_i32_hl` mints / 0 `_hl_unc`**, 44 trace lines,
against a hand-unrolled twin of the same source at **4/4**, 52 lines. At K=32: **32 mints / 0**.
`opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s)` — 2b is structurally blind to the
class (a template-minted rail has no `cqrt_alloc` to count). Each leaked rail is one BIT of the
merged register: an entangled which-path record, in the idiom owner decision D4 designates.

The tree had both halves and never their product: six
`control_phase_kickback_mixed_preheader_*.ll` fixtures (every one a `cq_theta` ROOT MINT), one
`control_phase_kickback_inloop_merge_rail.ll` (merge-out-rail root, NO preheader op), and
sub-grid F3's two cells (theta roots). The full `ctest -j6` was green at every one of them.

#### Root cause — and it is `hasOneUse` asking the wrong question, not asking it in the wrong place

`commitOutOfLoopInPlaceOps`' stability conjunct is `P->hasOneUse()`. A Phase-4 merge out-rail
STRUCTURALLY cannot have one use: the emitters **WRITE** it before anything reads it. `hasOneUse`
cannot tell a prior WRITER from a later READER — and `classifyInPlaceReassignment`'s own G6/G7
pair can, and does: a prior void `cqrt_*` writer is `provablyBefore` the op and is settled by
`priorUseIsSettled` arm (c), while a later read is refused by G6.

**THE §3.11 INPUT-STABILITY TABLE'S `P` ROW, RE-DONE WITH PROGRAMS.** The question this round
had to answer is *"what did `hasOneUse` guard that G6/G7 does not?"*, and the answer is
**nothing** — measured on an instrumented build of this branch that prints `P`'s use list and
the fence's verdict at every candidate:

| program | `P`'s users besides the op | `hasOneUse` | G6/G7 | disposition here |
|---|---|---|---|---|
| `r2_preadd_inv` | none | **true** | in place | COMMITTED — unchanged |
| `q5sel_preadd_rolled` | **2 × `cqrt_copy_i32_controlled`** (prior WRITERS, arm (c)) | false | in place | **COMMITTED — the new capability** |
| `q4b_preadd_rolled` | **1 × `cqrt_copy_i32`** (the Phase-4 VALUE-ARM ROUTE's out-rail) | false | in place | **COMMITTED** |
| `x2_preadd_keep` (`int keep=q; q=q+7; … measure(keep)`) | `cq_measure(%2)` — a later READER | false | **REFUSES** | REFUSED, trace byte-unchanged |
| `c2_m11d_two_loops_no_preadd` (OQ-C2-1's own program) | a still-UNLOWERED tainted `and i32` — arm (e) | false | **REFUSES** | REFUSED, trace byte-unchanged |

#### The fix — ONE conjunct, and the safety is (1b)

`if (!P || !P->hasOneUse()) return;` becomes `if (!P) return;`. The commit now asks exactly two
things: (1a) `isa<Constant>(Imm)` (MONOTONE — a property of the IR class, unchanged) and M-C's
own fence. **The temporal net is the round-3 (1b) tripwire**, which re-asks that same fence at
`lowerOps` under the FINAL `DominatorTree`/`LoopInfo` and final taint and declines
`cq loop lowering: pre-loop in-place op no longer provable at lowering`. So a commit true here
and false at lowering — F-C1C-1's wire-vs-SSA class included — is a LOUD DECLINE, never a leak
and never a wrong unitary. A structural stand-in for a temporal question is exactly what (1b)
made unnecessary; keeping both meant paying an over-decline for a net the tripwire already holds.

**THAT SENTENCE IS A MEASUREMENT, NOT AN ARGUMENT.** On mutant M2 (this branch's widened commit
with the (1b) re-ask deleted) all NINE F-C1C-1-class programs ACCEPT and `y1` reproduces the
round-2 wrong unitary verbatim — `cqrt_addc_i32` in place, measures **`h0`, `h1`, `h0`**, 39
lines — while this branch DECLINES every one. The net is the tripwire; `hasOneUse` never was it
(it is TRUE for `y1`).

#### The 8h7d.5 question, asked of THIS widening: what OTHER set is computed over the same closure?

The widening is "more ops enter `taint.InPlaceRailOps` (and, in lockstep,
`taint.PreLoopCommittedInPlaceOps`)". Every reader of those two sets, enumerated by
`grep -rn 'InPlaceRailOps' ir-pass/src ir-pass/include`, with the direction the widening moves it:

| reader | what it does with membership | effect of the widening | direction |
|---|---|---|---|
| `lowerOps` Phase 1's M-C guard conjunct (`!taint.InPlaceRailOps.count(BO)`) / its Phase-2 dispatch (`taint.InPlaceRailOps.count(BO) \|\| InPlaceReassign.count(BO)`), both in `OpcodeLowering.cpp` — by NAME, the lines MOVE | skips M-C's own classification and routes the op to `rewriteInPlaceValueRail` | the op is emitted in place — **this is the subject** | — |
| `inPlaceFenceHolds` G5's self-test | refuses a site already in the set (so the commitment has one owner) | same, by construction; suppressed only for the (1b) re-ask | — |
| `railValueConsumerDisposition` → the **Rule-8 FAN-OUT guard** (the round-1 guard in `tryCaseA` and the round-2 guard in `collapseRailPhisIn`, both `> RailValueUse::OutOfPlace`) | counts a second in-place mutator of one rail and DECLINES loudly | `Unproven` and `InPlace` are **both** `> OutOfPlace`, so the count is arithmetically unchanged — and that is complete ONLY because **a committed op can never have been `OutOfPlace`** (F-C1D-3.1): `railValueConsumerDisposition` returns `OutOfPlace` **exactly** when `blockCanRepeat(BO->getParent())` (its one `OutOfPlace` return — the only one in the function), and `inPlaceFenceHolds`' **G5** refuses precisely that (`ArithLowering.cpp:695-696`, `LI.getLoopFor(...) \|\| blockCanRepeat(...)` → `false`), so the commit cannot mark a repeatable-block op. Strike G5 and the widening WOULD add an `InPlaceUser` and could mint a NEW `kMsgRailFanout` decline | **none** |
| `railValueConsumerDisposition` → `collectRailGates`' `OnThisRail` call (`== InPlace`) | builds the gate set `staleRailRecordRead` reasons over — and its own comment says **a MISSING gate is the OVER-ACCEPT** | the gate set only GROWS | **strictly safer** |
| `peelInPlaceStep(…, AsLowered=true)` — exactly **two** call sites in the tree: clause (ii)'s peel and `markIfRailLocal`'s `onRail`. RE-MEASURED on the rebased tree with `grep -rn 'peelInPlaceStep(\|peelInPlaceBase(' ir-pass/src ir-pass/include` → **24 hits**, of which **4 are prose** and **2 are the declaration and the definition**, i.e. **18 code call sites**, and only these two pass `true` (`LoopLowering.cpp:3214` and `:3412-3413`, the latter wrapped across two lines, which is why a single-line `grep -c 'AsLowered=\*/ *true'` reports 1) | the FACT-time peel crosses an op only when it is really emitted as `cqrt_{addc,xorc}` | crosses more ops — **this is the capability**, and the two sites are the SAME spelling, so they cannot disagree about one value (the F-1/F-3 fix) | — |
| every OTHER `peelInPlaceBase`/`peelInPlaceStep` caller | uses the default `AsLowered=false`, the SHAPE reading | membership is not consulted | **none** |
| `WireWalk` (`declineStaleRecordOps`) | ⚠ **NOT for the reason its own comment gives** (F-C1D-3.2). `WireWalk.cpp:457` says "`declineStaleRecordOps` runs BEFORE `lowerLoops`, so `InPlaceRailOps` …" — which is FALSE for the SECOND call, `declineLiftedStaleRecordOps` at `CQLoweringPass.cpp:522` (and `:848` in the second entry point), both of which run AFTER the commit at `:363`/`:393`. The row survives for a STRONGER reason: `WireWalk` has **no code read of either set at all** — `grep -n 'InPlaceRailOps\|PreLoopCommittedInPlaceOps' ir-pass/src/WireWalk.cpp ir-pass/include/WireWalk.h` returns exactly ONE line, `:457`, and it is PROSE | unreachable, by absence rather than by ordering | **none** |
| `taint.PreLoopCommittedInPlaceOps` → the (1b) tripwire | re-asks the fence at `lowerOps` and declines loudly on a changed answer | more ops re-asked ⇒ more POSSIBLE loud declines | **decline direction; 0 measured over 485 programs** |
| ⭐ **THE ROW THE TABLE DID NOT HAVE — the F-3 question itself** (F-C1D-3.3): when the GATE set widens, what OTHER set was computed over the SAME closure? | `staleRailRecordRead`'s **SKIP** set — the CHAIN — is that set | it is built with `peelInPlaceStep(…, AsLowered=false)`, the SHAPE reading, which crosses a dtzb-shaped `BinaryOperator` **regardless of membership**. So the widening grows the GATE set and the RECORD set (both decline-ward) and **cannot shrink the skip set** | **none — structurally** |

Three of those rows are the ones a future round should re-derive if anything moves: the fan-out
guard's arithmetic (it holds only because the enum orders `Unproven` and `InPlace` on the same
side of `OutOfPlace` **and** because G5 keeps a repeatable-block op out of the set entirely),
`collectRailGates`' `InPlace`-only cell (whose safety rests on M-C's G6/G7 pair, exactly as its own
comment says), and the new skip-set row (whose safety rests on the peel's DEFAULT argument — change
that default and the F-3 hole opens).

⚠ **WHY THE LAST ROW IS THE ONE THAT MATTERS.** It is literally the omission that cost the 8h7d.5
epic a round: F-1 widened the gate set and not the record set, and F-3 was that omission, found one
round later by an adversarial reviewer and not by the fixture corpus. The table above had asked
"who READS this set?" of every reader and had never asked "what OTHER set is derived from the same
closure?" — which is a different question with a different answer.

#### Mutation validation — one half at a time, on a `git archive HEAD` copy

| mutant | what goes RED | result |
|---|---|---|
| **M1** restore `P->hasOneUse()` | `control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll` | **RED** (CHECK / FCNT / UCNT), and **nothing else in the 10-fixture table moves** |
| **M2** delete the (1b) tripwire | `control_phase_kickback_reject_preloop_commit_stale.ll` | **RED** (`OPT_RC=0 CHECK=1`), nothing else moves |
| RESTORE | — | all 10 GREEN on every prefix |

#### What it buys, measured

| program | producer of the invariant root | `main` a3c1513 | this branch |
|---|---|---|---|
| `q5sel_preadd_{rolled,unrolled}` | 4.4 SELECT merge | 4/0 (44) vs 4/4 (52) — **DIVERGE** | **4/4 = 4/4, IDENTICAL 52 = 52** |
| `q4b_preadd_{rolled,unrolled}` | Phase-4 VALUE-ARM ROUTE | 4/0 (57) vs 4/4 (65) — **DIVERGE** | **IDENTICAL 65 = 65** |
| `q7_k32_rolled` (K=32) | 4.4 select merge | 32 mints / **0** | **32/32** — the leak was O(K) |
| `q5v_xor` (`m ^= 7`) | 4.4 select merge | 4/0 | **4/4** — but its twin is UNFAITHFUL (the documented `xorpre`/`r71` `-O1` xor-distribution artefact), so nothing witnesses it |
| `q5v_none` (merge, no preheader op) | boundary control | IDENT | IDENT — **unchanged** |
| `q5ctl_theta_preadd` (theta root, with one) | boundary control | IDENT | IDENT — **unchanged** |

The two boundary controls are what make this the PRODUCT and not either axis alone.

**THE 6.5 CLASSICAL-CALL ARM ROW STAYS ANALYTIC, and it is analytic for a MEASURED reason.**
`int y=5; if (q>5) y=ext_f(7); int m=y+7; for(…)` DECLINES `cq controlled lowering: value-arm
swap-route under quantum control` on BOTH binaries: with a constant else-value `-O1` SINKS the
`+7` into the arm, so the arm is no longer a bare classical call and 6.5 never classifies it.
The row is therefore *unreachable*, not *unfixed* — the same measurement `review_inc2_r2` made
with its own `q5o_call_*` probe. The 4.5 switch data-mux is measured OUT of the population
entirely (all-`ConstantInt` arms fold the preheader op into the case constants — `q5w_mux`,
identical on every binary).

#### ⭐ A THIRD population member, found by SWEEPING and not by the finding — and it has NO MERGE IN IT

The whole-corpus sweep (below) moved one program nobody had predicted:
`c2_m04_onward_then_preadd`, 3 mints / **0** `_unc` on `main` (43 lines) → **3/3** here (49).
Its `P` is an ordinary `cq_theta` ROOT MINT, and the extra use that made `hasOneUse` false is
**the PRECEDING REGION'S OWN COMPARE**. By the commit's program point
(`collapseFlattenedLoopRails`, i.e. after `lowerControlRegions`) that compare is
`cq_template_icmp_sgt_i32_hl`, whose rail is `_unc`'d **and** `cqrt_free`d before the `add` —
so `priorUseIsSettled` arm (d) settles it and M-C lowers the op in place. `hasOneUse` could
see none of that.

Distilled to a SINGLE TU as `g1_region_then_preadd_{rolled,unrolled}.c`
(`if (q > 5) cq_phi(0.4); q = q + 7;` then D4's per-bit loop with a carried `r`): `main`
**3/0 (36 lines) vs its twin 3/3 (42) — DIVERGE**; here **3/3 = 3/3, traces BYTE-IDENTICAL at
42 = 42**. So the population is not "merge out-rails": it is **every `P` whose other users are
all SETTLED PRIOR CONSUMERS**, of which a merge's `cqrt_copy_*` writers (arm (c)) and a
region's discharged compare rail (arm (d)) are two spellings.

#### The whole C-1 population, `main` vs this branch

**485 programs** — the union of every `p/` directory of session `adc5590a` (`fix_c1_work`,
`review_c1_work`, `fix_c1b_work`, `review_c1b_work`, `fix_c1c_work`, `review_c1c_work`,
`clearance2_work` `p`+`p2`+`p3`, `review_inc2_r2_work`) plus this round's own — each run
through the full pipeline on both binaries and compared by normalised STATUS **and** by
byte-diff of the trace.

**477 UNCHANGED, 8 MOVED**, and every mover is named: the six that gain `_unc` + `cqrt_free`
pairs (`q5sel_preadd_rolled`, `q4b_preadd_rolled`, `q7_k32_rolled`, `q5v_xor`,
`c2_m04_onward_then_preadd`, and the two new matrix cells count as two of the six with
`m_addpresel_pbit{,d}`), plus `c1c_a1_constexpr_imm`, whose lowered IR is BYTE-IDENTICAL and
whose only difference is the printed value of a `ptrtoint (@g_tab+12)` load address in two
separately linked binaries — the artefact `review_c1c` recorded on the same probe.

**CLASS-FLIP CENSUS: `ACCEPT→ACCEPT 332 · DECLINE→DECLINE 122 · LINKFAIL 2 · S1FAIL 29`;
0 ACCEPT→DECLINE, 0 DECLINE→ACCEPT, 0 decline strings changed.** (Run as a `bash` script, not
under `zsh` — `review_c1c`'s own methodology note about a scan that answers "0 flips" for the
wrong reason.) STRICT stage 2b over all **332** accepts: **330 `0 violation(s), 0 unproven`,
2 `0 violation(s), 4 unproven`** — `f0_break_plain` and `f3_break_global_phase_before`, the
`--allow-unproven` dtzb break family — **0 violations**.

Two rows of that sweep are worth reading as controls rather than as movers:
* `x2_preadd_keep` (`int keep = q; q = q + 7; … cq_measure(keep)`) is **byte-unchanged** — M-C
  itself goes out of place there (G6 refuses the later read), so the commit still refuses, now
  for the right reason instead of by a proxy.
* `y1_preadd_chained_prerecord` still **declines** with the (1b) string on both binaries.

#### Pinning

* **lit**, corpus 1673 → **1675** (+2):
  `control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll` (the merge out-rail × the
  preheader op) and `control_phase_kickback_mixed_preheader_addc_after_region_inloop.ll` (the
  third class: a preceding region's settled compare, no merge). Both ACCEPT, 8 prefixes each,
  both `OPT_RC=0 CHECK=1 FCNT=1 UCNT=1` — **RED** — on `main` and all-zero here.
  The ⭐ discriminators are `UCNT` (the per-trip `and_i32_hl_unc`, ZERO on `main`) and `FCNT`;
  `PCNT` is the other half of the subject in its own prefix (the preheader op really is
  `cqrt_addc_i32` IN PLACE, exactly once, with no adjoint).
  Injection matrix 2 × 16: **`clean` PASS, 0 MISSED, 0 DIRTY** on both.
  `ctest -R ir-pass-lit` on this build: **Passed, 41.02 s, 0 failed**.
  The reproducers are committed at `inc1-records/c1-round4/` (23 files + a two-binary README),
  the `c1-round3/` precedent.
* **e2e**, `ctest -N` 348 → **351** (`^e2e-` 338 → **341**, `^e2e-slice-` 308 → **310**):
  `slice_control_phase_perbit_loop_merge_preadd{,_unrolled}.c` + goldens by the full pipeline,
  STRICT 2b `0 violation(s), 0 unproven` on both, gated by
  `e2e-phase-perbit-loop-merge-preadd-twin-identical` (**52 = 52**, was 44 vs 52).
* **the twin matrix**, sub-grid **F4** (2 cells, F 12 → 14, total 286 → **288**): a `PREHEAD`
  slot on `_wrap` (defaulted) + one new PREFIX key `addpresel`. Both cells are
  **TRACE-DIVERGENCE on `main`** and **ACCEPT-IDENTICAL** here. **PROVEN byte-unchanged, not
  asserted**: all **1144** pre-existing generated sources hash-identical across both surfaces,
  8 new rows.

---

### 3.15 The round-4 REBASE onto the landed Increment 2 (2026-09-06, session `82e6b530`)

**STATUS: LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the orchestrator:
the squash of branch `c1-round4`, whose tip is recorded in the landing commit message;
`git log main -1` shows the hash). Full record:
`inc1-records/session-82e6b530/rebase_c1d.md`.

**⚠ EVERY `main` FIGURE IN §3.14 IS AGAINST a3c1513.** Round 4 was written on that base;
`main` is now **b99b853** (docs) on top of **258d974** (Inc 2, value arms by the
CONTROLLED-COPY MERGE). The round-4 lens (F-C1D-1) re-measured the finding on the landed
binary and it was still live there — `q4b_preadd` 4/0 (52) vs 4/4 (60), `q5sel_preadd` 4/0
(44) vs 4/4 (52), `g1_region_then_preadd` 3/0 (36) vs 3/3 (42) — so the rebase was a
correctness obligation, not housekeeping.

#### The rebase itself

`git rebase main` in the round-4 worktree. MEASURED overlap
(`git diff --name-only a3c1513 c1-round4` ∩ `… a3c1513 main`) = **exactly five files**:
`CLAUDE.md`, `ROADMAP.md`, `retire-swap-route-PRD.md`, `tests/e2e/CMakeLists.txt` and
`inc1-records/session-adc5590a/briefs/BRIEF_fix_c1d.md`. Only **two hunks in `CLAUDE.md`**
needed hand resolution, both the ctest/lit COUNT paragraphs, both resolved to `main`'s Inc-2
text and then RE-MEASURED on the rebased tree (below); `tests/e2e/CMakeLists.txt` auto-merged
with **both** blocks intact (Inc 2's nine value slices and four `e2e-value-*-twin-identical`
gates AND round 4's merge-preadd pair + gate), the two `BRIEF_fix_c1d.md` copies are
byte-identical, and **`ir-pass/src/LoopLowering.cpp`, `tools/loop_twin_matrix.{py,expected.txt}`
and this file did not conflict at all** — Inc 2 never touched them. `git diff main HEAD --stat
-- ir-pass/src ir-pass/include` is `LoopLowering.cpp` alone until step 4's comment additions.
The branch's duplicate `session-adc5590a/fix_c1d.md` (byte-identical to `main`'s
`session-adc5590a/c1-round4/fix_c1d.md`) is `git rm`'d, with the one cross-reference re-pointed.

#### ⭐ `q4b` — the row §3.14 could only ARGUE, now MEASURED

§3.14's step 17 and its RECORD ITEM say the Inc-2 producer of the merge rail "CANNOT be
measured until the orchestrator rebases this branch onto the landed Inc 2". It is measured now,
on `inc1-records/c1-round4/q4b_preadd_{rolled,unrolled}.c` — the value-arm spelling, whose
`%out` is written by two `cqrt_copy_i32_controlled`:

| binary | rolled (mints / `_unc`, lines) | hand-unrolled twin | `cmp` |
|---|---|---|---|
| `main` **258d974** | **4 / 0, 52** | 4 / 4, 60 | **DIVERGE, 8 lines** |
| REBASED `c1-round4` | **4 / 4, 60** | 4 / 4, 60 | **IDENTICAL** |
| ORACLE **52d7764** | *unexpressible* (stage 1 fails: the shipped `void cq_phi(double)` does not exist there) | — | — |

The rebased ROLLED trace is **byte-identical to `main`'s OWN unrolled twin**, so the comparison
is against the landed compiler's stream rather than against itself; the whole difference from
`main`'s rolled trace is the four missing
`cq_template_and_i32_hl_unc(h{6,8,10,12}, h5, …)` + `cqrt_free(h{6,8,10,12})` pairs — one
leaked which-path ancilla per activation. STRICT 2b is `0 violation(s), 0 unproven` on BOTH
binaries, as the class always is.

**The ORACLE row, stated honestly.** Transliterating to 52d7764's register form
(`p = cq_phi(p, 0.7)`) is a DIFFERENT program, and it is recorded as such: the ROLLED spelling
DECLINES there (`cq taint escape: tainted value muxed by a classical-condition phi`) and the
UNROLLED one accepts at 4/4, 65 lines, emitting **4 `cqrt_cswap` + 4 `cqrt_rz_i32_controlled`**
— the routed, TENSORED per-qubit Rz that §1 shows is the identity on the marked branch. So the
oracle has no rolled/unrolled pair for this shape at all, and its unrolled member is the defect
this epic retired.

**Pinned**, in the §3.14 style:
* **lit**, corpus 1687 → **1690** at the rebase, and → **1691** after the lens on this tree
  (the F-C1E-1 fixture below; `ls ir-pass/test/*.ll | wc -l`, re-measured). The rebase's own
  addition is (round 4's two accepts plus)
  `control_phase_kickback_mixed_value_merge_preadd_inloop.ll` — 10 prefixes, one `%cq-opt`
  spawn, `OPT_RC=0 CHECK=1 FCNT=1 UCNT=1` (**RED**) on `main` 258d974 and **all ten zero**
  here. Its `UCNT` is the ⭐ discriminator (`cq_template_and_i32_hl_unc` = 1 here, **0** on
  `main`) and its `FCNT` the other half (4 frees here, 3 on `main` — the chain FINAL is left
  allocated on purpose, PRD §0 E1). ⚠ Also measured on the PRE-rebase round-4 binary 59f6a95
  (a3c1513 + the fix, no Inc 2): `CHECK=1 HCNT=1 NOROUTE=1 PCNT=1 XCNT=1` — red, because the
  value arm still ROUTES there. That is the discriminator showing the fixture is specific to
  the Inc-2 mechanism, not a defect.
* **e2e**, `ctest -N` 361 → **367** (`^e2e-` 351 → **357**, `^e2e-slice-` 317 → **321**,
  `twin-identical` 24 → **26**, goldens 319 → **323**):
  `slice_control_phase_perbit_loop_value_merge_preadd{,_unrolled}.c` + goldens by the full
  pipeline, STRICT 2b `0 violation(s), 0 unproven` on both, gated by
  `e2e-phase-perbit-loop-value-merge-preadd-twin-identical` (**60 = 60**, was 52 vs 60).
* **the twin matrix is UNTOUCHED** — 259 expected rows + 29 quarantined = **288 cells**,
  `ctest -R e2e-loop-twin-matrix` **Passed, 292.00 s, NO cell moved**.

#### The round-4 lens items, disposed

| item | disposition |
|---|---|
| **F-C1D-1** (the baseline moved; the defect is live on the landed `main`) | **the rebase itself**, plus the `q4b` measurement above |
| **F-C1D-2** (Inc 2's `ArithLowering` CONSUMER-2 comment names a second consumer of the G6/G7 pair whose second net this round removed — sound but unpinned) | **PINNED and ARGUED.** The new fixture's `HCNT` prefix asserts the Inc-2 chain HEAD is emitted OUT of place onto a fresh rail and that `p`'s own rail carries no in-place `cqrt_addc`/`cqrt_xorc` anywhere in the module. The argument is written at `commitOutOfLoopInPlaceOps` in two independent halves — **(A) DIRECTION**: `peelInPlaceStep` returns an OPERAND, so the walk is BACKWARD, and a chain head is a USER of the arm's input `Q`; **(B) THE PEEL STOPS AT THE `cqrt_alloc`**: the merge candidate arrives from `collapseFlattenedLoopRails` (round 2), AFTER `lowerControlRegions` emitted `%out = cqrt_alloc_<W>(0)`, and `peelInPlaceStep`'s first clause returns null for a `CallInst` not in `GateCalls`. Cross-referenced from `ArithLowering.cpp`'s CONSUMER-2 comment (**comments only** — 0 non-comment added lines and 0 removed lines in `ir-pass/src`). Gates re-run on the rebased tree: `control_swap_value_ifelse_head_out_of_place.ll` **1/1**, `control_swap_value` **19/19**, the four `e2e-value-*-twin-identical` gates and all nine Inc-2 value slices **green** (48/48 in the gate group) |
| **F-C1D-3** (three doc-level refinements to §3.14's 8h7d.5 closure table) | **APPLIED, each verified on this tree first** — see that table: the fan-out row now names **G5** as what makes "arithmetically unchanged" complete; the `WireWalk` row's stated reason is corrected (it is FALSE for `declineLiftedStaleRecordOps` at `CQLoweringPass.cpp:522`/`:848`, and the row survives because `WireWalk` has NO code read of either set — one grep hit, prose); and the table gains **the F-3 row it lacked**, the SKIP set. Peel census re-measured: 24 grep hits, 4 prose, 2 decl/defn = **18 code call sites**, **2** at `AsLowered=true` |
| **F-C1D-4** (no `extra_ry` row in the injection matrix; 0 of 25 accepts pinned an Ry count) | **BUILT and CLOSED** — see the table below |

#### F-C1D-4 — the `extra_ry` injection row

Mutation: insert `call void @cqrt_ry_i32(i32 <rail>, double 5.000000e-01)` immediately after the
last `cqrt_free`, `<rail>` = arg-0 of the first `and`/`lshr` `_hl` template call (the register
the condition reads), falling back to the first `cqrt_alloc_*` result. An uncontrolled
non-diagonal gate on the wire the kickback branched on is a different unitary. Accept set =
`grep -L 'RUN: not' ir-pass/test/control_phase_kickback_*.ll` = **44 files** of 62.

| run | `extra_ry` | the other 16 mutations |
|---|---|---|
| first | **25 MISSED**, 0 DIRTY | **0 MISSED / 0 DIRTY**; `clean` PASS on all 44 |
| after each of the 25 gained a `RYCNT` prefix | ⭐ **0 MISSED / 0 DIRTY** | unchanged, 0 / 0 |

Caught by **RYCNT on 26** fixtures and by **CHECK on 18** (whose `CHECK-NEXT` chains the
injected line already broke). Each of the 25 gains ONE extra `%filecheck … --check-prefix=RYCNT
< %t.cqd0.ll` RUN line against the EXISTING `%t.cqd0.ll` — **no second `%cq-opt` spawn** — plus
its own `RYCNT-COUNT-n` / `RYCNT-NOT` block, `n` read from the pass output (1–4 per fixture).
**`RYCNT` is its own prefix and is never folded into `NOROUTE`**: a `COUNT` inside `NOROUTE`
windows every `NOT` after it, which is the Inc-3/Inc-4 recurrence. No decline fixture touched;
`lit --filter 'control_phase_kickback'` **62/62**, `ctest -R ir-pass-lit` **Passed, 53.62 s**.

#### The independent lens ON THE REBASED TREE (`review_c1e`, 2026-09-06) — verdict CLEAR-WITH-ITEMS

The rebase added a NEW customer class to an already-cleared fix (the Inc-2 controlled-copy merge as
a fourth producer of the `%out` rail) plus 25 edited fixtures, so a second lens was budgeted on the
rebased branch `aa9d702` rather than on the pre-rebase round-4 tree. Full record:
`inc1-records/session-82e6b530/review_c1e.md`. What it cleared, in its own measurements: **0
DECLINE → ACCEPT** over **610** comparable programs of a 640-program deduplicated population on
three binaries and over all **1690** lit fixtures (`0 RCDIFF · 0 DIAGDIFF · 3 OUTDIFF`, the three
being round 4's own accepts, each gaining exactly one `_unc` and one `cqrt_free` with the
`addc`/`xorc` count unchanged); **0 ACCEPT → DECLINE**; **0** decline-message changes; STRICT stage
2b clean on all 26 movers; the injection matrix reproduced at **0 MISSED / 0 DIRTY**; and the four
new goldens re-derived GOLDEN-MATCH with both pairs byte-identical. The full `ctest` on that tree
was **367/367** (`$SP/progress/orch_full_ctest_c1e.log`, the orchestrator's run, 385.89 s).

| item | disposition |
|---|---|
| **F-C1E-1** (`DOC`, coverage): the fixture cited in TWO source comments as MEASURING "the commit cannot reach an Inc-2 chain head" cannot discriminate the pair it is cited for | **CORRECTED, and a discriminating fixture ADDED.** See below. |
| **F-C1E-2** (`LEAK`, PRE-EXISTING, byte-identical to `main`) | **RECORDED, not fixed** — PRD §0 **E2**'s residual list, the table below, and the eight reproducer pairs `inc1-records/c1-round4/c1e_a*.c`. |
| **F-C1E-3** (`DOC`, methodology): four of the lens's own attack twins are UNFAITHFUL | **RECORDED** — the sentence below. |
| **F-C1E-4** (`DOC`): the rebase record's "0 hits" grep is self-invalidated | **CORRECTED** in `inc1-records/session-82e6b530/rebase_c1d.md`. |

##### F-C1E-1 — which fixture measures WHAT

`ArithLowering.cpp`'s CONSUMER-2 comment and `LoopLowering.cpp`'s `commitOutOfLoopInPlaceOps`
argument both cited `control_phase_kickback_mixed_value_merge_preadd_inloop.ll` (the `q4b` shape) as
the MEASUREMENT behind "G6/G7 is now the sole net on the commit path". The lens built the mutant the
comment implies — a `git archive` of the subject with `inPlaceFenceHolds`' G6 and G7 `return false`
made unreachable, fresh `cmake`, build RC 0, currency EMPTY — and measured that **the q4b fixture
stays GREEN on it with its emitted copies byte-unchanged**, as do BOTH round-4 e2e goldens. CAUSE,
measured: in that module `clang -O1` reassociates `(p+3)*5` into `p*5 + 15`, so `p`'s only chain
user is a `mul`, and `inPlaceValueRailOperand` admits `add`/`xor` only — **G2's SHAPE half refuses
the head whatever G6/G7 answer**, and the `HCNT-NOT` lines are unfalsifiable by a relaxation of the
pair they were cited for. The property they assert HOLDS; the citation was wrong.

Applied, three things:
1. **Both comments rewritten** (COMMENTS ONLY — `git diff -- ir-pass/src` adds and removes **0**
   non-comment lines) to say that the G6/G7 NET is pinned by
   `control_swap_value_ifelse_head_out_of_place.ll` — the fixture the CONSUMER-2 comment already
   named, which goes **RED (CHECK, NOROUTE)** on that mutant with its two copies collapsing onto ONE
   register — and that the `q4b` fixture's `HCNT` pins the head-out-of-place PROPERTY on the shape
   that made the commit fire, not the net.
2. **A discriminating lit accept added**:
   `ir-pass/test/control_phase_kickback_mixed_value_merge_dtzb_head_preadd_inloop.ll`, from the
   lens's attack program `a22` — `if (q>3){ r = p+3; r = r^9; }`, a preadd on the merge out-rail,
   then D4's per-bit loop. Its chain head IS a dtzb-shaped `add`, inside
   `inPlaceValueRailOperand`'s shape, so nothing but G6/G7 stands between it and an in-place
   `cqrt_addc_i32` on `p`'s rail; the lens measured a22 (with a23/a24) collapsing BOTH controlled
   copies onto one register on the mutant. ⚠ MEASURED and worth knowing: `clang -O1` **folds that
   diamond into a `select`**, so the merge is the 4.4 `SelectMergeEmit` — the same emitter Inc 2's
   `emitValueRegion` delegates to (Rule 14), so the emitted shape is the sibling's. Twelve prefixes,
   one `%cq-opt` spawn; two are new to the family — **`CSRC`** (the two `cqrt_copy_i32_controlled`
   read DISTINCT rails under ONE flag into ONE out-rail: the exact property the mutant breaks) and
   **`QCNT`** (the in-place `xor` budget, its own prefix because a positive `COUNT` after a `NOT`
   WINDOWS that `NOT` and the `xorc` precedes the `addc` here — the Inc-3/Inc-4 recurrence).
   RED/GREEN: on `main` **258d974** `OPT_RC=0` with **CHECK, FCNT, UCNT** red (the leak: 0
   `and_i32_hl_unc` and 2 `cqrt_free` against 1 and 3 here) and the other nine prefixes green; on
   this tree **all twelve green**. The whole IR difference between the two binaries on that module is
   the two lines the subject GAINS — `cq_template_and_i32_hl_unc(%h_op3, %out, %4)` and
   `cqrt_free(%h_op3)`. Injection matrix over it: **`clean` PASS, 0 MISSED, 0 DIRTY** across all 17
   mutations, and re-run over the whole accept set (**45** files after the addition) **0 MISSED /
   0 DIRTY**, `extra_ry` caught by **RYCNT on 27** and **CHECK on 18**.
3. **No e2e slice added** — the lens measured that the e2e layer is blind to this mutation (both
   round-4 goldens still match on the mutant), so a slice would pin nothing the lit fixture does not.
   ⚠ The mutant itself is the LENS's measurement and is NOT in the tree; nothing here rebuilds it.
   What is in the tree is the property it breaks, asserted two ways.

##### F-C1E-2 — the preheader op whose PARENT has a second unlowered tainted user still leaks

RE-MEASURED for this record (full pipeline, STRICT 2b, `main` 258d974 vs this branch; trace counts
are `cq_template_{and,lshr}_i32_hl` MINTS / `_hl_unc` DISCHARGES):

| reproducer (`inc1-records/c1-round4/c1e_…`) | `main` rolled | this branch rolled | unrolled twin | rolled trace |
|---|---|---|---|---|
| `a1_head_add_read_by_loop` | 4/0, 44 | 4/0, 44 | 4/4, 52 | **byte-IDENTICAL** |
| `a2_source_p_preadd` | 4/0, 45 | 4/0, 45 | 4/4, 53 | **byte-IDENTICAL** |
| `a3_chainfinal_preadd` | 4/0, 45 | 4/0, 45 | 4/4, 53 | **byte-IDENTICAL** |
| `a9_out_prevalue_measured` | 4/0, 45 | 4/0, 45 | 4/4, 53 | **byte-IDENTICAL** |
| `a11_select_head_add` | 4/0, 44 | 4/0, 44 | 4/4, 52 | **byte-IDENTICAL** |
| `a4_out_two_loops` | 8/0, 73 | 8/0, 73 | 8/8, 91 | **byte-IDENTICAL** |
| `a17_out_two_loops_nofold` | 8/0, 73 | **8/4, 81** | DECLINES on both binaries | main ≠ branch — a strict IMPROVEMENT |
| `a16_source_p_preadd_diffusion` | DECLINES | DECLINES | DECLINES | — |

MECHANISM: `classifyInPlaceReassignment` refuses the preheader op at **G7 arm (e)** (an unlowered
tainted `mul`/`and` user of `P`) or at **G6** (the merge's copies are emitted AFTER the pre-op, so
`provablyBefore` fails), so the commit never marks it, the op lowers OUT of place onto a fresh rail,
and `invariantRegisterRoots`' peel — which walks only `InPlace` ops — stops short. **Not a wrong
unitary**: `a16`, the diffusion variant of `a2`, declines loudly (`cq controlled lowering: control
flow under quantum control`) on `main`, on the pre-rebase round-4 binary and here. STRICT 2b is
`0 violation(s), 0 unproven` on every accepting row, which is the class's whole hazard — a
TEMPLATE-minted rail has no `cqrt_alloc` for the checker to count.

⚠ **ONE REFINEMENT TO THE LENS'S OWN WORDING**, measured separately here: F-C1E-2 groups
"`a4`/`a17` — 8/0 on main, 8/4 on the subject". That is **`a17` alone**; `a4` is 8/0 on BOTH with
byte-identical rolled traces, and the two sources differ by one token (`p = p + 5` vs `p = p ^ 5`).
`a17` additionally has **no faithful twin** — its unrolled spelling DECLINES `cq controlled
lowering: condition predates a non-diagonal gate under quantum control` on every binary.

##### F-C1E-3 — four of the lens's attack twins are UNFAITHFUL, not defects

`p ^ c` and `p + c` with `c`'s low bits clear let `-O1` DISTRIBUTE the per-bit test onto the PRE-op
register in the UNROLLED spelling ONLY, so the two sources stop being the same program (measured in
the traces: `cq_template_and_i32_hl(h4, 1)` reads the PRE-op rail on the unrolled side and the
post-op rail on the rolled side). Members: `a8` (`^6`), `a10` (`+7; ^6`), `a15` (`+7; +5` folded to
`add %out, 12`) and `a17`. This is the documented OQ-27 / `m_xor_range` quarantine class and
CLAUDE.md's own `addpost` precedent — **recorded here so a later round does not file them as
compiler defects**. `q4b`'s `+7` is immune because 7 has all its low bits set.

##### F-C1E-4 — the rebase record's own grep

`inc1-records/session-82e6b530/rebase_c1d.md` asserted
`grep -rn 'session-adc5590a/fix_c1d.md' --include='*.md' .` → **0 hits**. MEASURED by the lens on
the subject: **5**, all prose — the notes' §3.15 paragraph, `BRIEF_rebase_c1d.md`, and three lines
of the committed record itself, INCLUDING the sentence asserting 0. Re-measured after THIS
paragraph was written: **7**, for the same reason — a `.md` file cannot assert its own absence
from a `--include='*.md'` grep, and each retelling adds hits. The DELETION is correct
(`ls …/session-adc5590a/fix_c1d.md` → no such file) and **no live cross-reference points at the
missing path**; only the claim was stale, because the file that makes it is itself committed under
`.md`. Corrected in place.

---

### 3.16 bd `eqpx` — the consumer tripwire for W1–W3 (2026-09-06)

**STATUS: built on branch `eqpx-fix` (base `main` 0b402d6 = docs-only over the code commit
16b15b3). RED commit `360f7c3`, fix commit `15196f3`, docs commit as recorded by the
orchestrator.** This is the §3.12 / §2-⭐-table row FIXED. It is the FIFTH member of the
once-only-stage class in this file and the SECOND to be closed by a consumer tripwire; §3.11's
(1b) is the first, and this one is its sibling at the same call site.

#### The four writers (MEASURED, and the record named the wrong set)

`grep -n 'InPlaceRailOps.insert(' ir-pass/src/LoopLowering.cpp` returned **four** sites before
this increment. ⚠ IT NO LONGER DOES, AND THAT IS THE ROUND-1 LENS'S FINDING F-E1-1: today the
four writers all call ONE helper, `markInPlaceRailOp`, so that grep returns a SINGLE site
inside the helper and the enumerating command is `grep -n 'markInPlaceRailOp('
ir-pass/src/LoopLowering.cpp`. The line numbers below are true as of the round-2 doc pass; the
four FUNCTION NAMES are the durable key, because a comment edit anywhere above them moves all
four (this table has already been re-synced once for exactly that reason).

| # | writer | line | runs at | its own immediate test |
|---|---|---|---|---|
| W1 | `emitBreakForward` (7.4 break) | `:1738` | `lowerLoops`, `CQLoweringPass.cpp:363` | `DT.dominates(ImmI, Rgn.ExitMerge)` (`:1588`) — a POSITION test for the reverse-play, never classicality |
| W2 | `tryCaseA`'s ACCEPT | `:2321` | `lowerLoops`, `:363` | none |
| W3 | `collapseRailPhisIn` step (3) | `:2719` | `collapseFlattenedLoopRails`, `:393` | none |
| W4 | `commitOutOfLoopInPlaceOps` | `:3124` | via `invariantRegisterRoots`, `:393` | round 3's MONOTONE `isa<Constant>(Imm)` + the (1b) tripwire — **already fenced, and EXCLUDED here** |

`TaintPropagation.h` and §2's ⭐ row both enumerated *"round 1's `railRoot` marking,
`tryCaseA`'s ACCEPT, `collapseRailPhisIn` step (3)"*. The first two are **ONE site**, and the
genuinely unlisted one, **`emitBreakForward`**, is a MEASURED member (`n15`, `n16`, on all four
binaries the investigation ran). Both places are corrected.

#### The two taint-growth events (the record named one)

* **E1 — `lowerControlRegions` (`CQLoweringPass.cpp:376`).** `ClassicalCallArmEmit.cpp:209`
  and `SwitchDataMuxEmit.cpp:144` do `taint.Tainted.insert(Out)` **at emission**, so the BARE
  6.5 / 4.5 merge value is a quantum handle from that moment — AFTER W1/W2, BEFORE W3/W4.
  Measured members needing no derivation at all: `n04`, `n16`.
* **E2 — `repropagateControlMerges` (`:409`).** Everything DERIVED from that `%out`
  (`y&7`, `y*3`, `y+1`).

So "DERIVED from a `%out`" over-narrowed the class by a whole producer path, and a fence
written against E2 alone would have left `n04`/`n16` silent.

#### The ADD row of §3.12 is FALSIFIED — the cause is `clang -O1`, not a fence

Recorded in place at §3.12 above (the row is KEPT, its READING retired). Five spellings reach
the `add` stem: four plain C and one ONE-OPCODE hand-IR mutation of §3.12's own flagship.
`inPlaceValueRailOperand` admits `Add` and `Xor` identically; what differed was IndVarSimplify's
exit-value rewrite closing-forming the affine add-recurrence out of the loop. **`sub`, by
contrast, is safe BY A FENCE** — the same predicate's opcode gate excludes it, and a plain-C
in-loop `r -= w` declines `cq loop lowering: loop-carried tainted value crosses iterations` on
all four binaries.

#### The fix

`ir-pass/src/OpcodeLowering.cpp`, Phase 1, immediately AFTER the (1b)
`PreLoopCommittedInPlaceOps` block and BEFORE the M-C block: for every
`taint.InPlaceRailOps` member NOT in `PreLoopCommittedInPlaceOps`, re-ask **G2 ALONE** —
`inPlaceValueRailOperand(BO, taint)`, the same exported predicate the writers used — under
**FINAL taint**, and decline loudly:

> `cq loop lowering: in-place rail op no longer provable at lowering`

`DiagnosticInfoUnsupported(DS_Error)` + `!dbg`, then `continue` (never enqueued ⇒ never
rewritten ⇒ never erased).

* **G2 ALONE, NOT THE (1b) TRIPWIRE WIDENED.** `inPlaceFenceHolds`' G5 second disjunct
  (`ArithLowering.cpp:695-696`) is NOT gated by `IgnoreSelfMarking` — only the
  `InPlaceRailOps` self-marking disjunct is — and every W1/W2/W3 member is inside a loop by
  construction, so re-asking the whole fence would decline **100 %** of them, shipped ones
  included.
* **NO SILENT FALLBACK TO OUT-OF-PLACE** (Rule 1 — no third path). FOUR permissions the
  marking already bought are standing in the module: `markIfRailLocal`'s
  `taint.IterationLocalBlocks`, the IRREVERSIBLY COLLAPSED rail phi, `taint.ClaimedRailRoots`,
  and — for W1 — the whole forward break transform plus the post-`lowerOps`
  `lowerBreakReversePlay` stage that re-emits this op's adjoint.
* **NOT the writer-side `isa<Constant>(Imm)` analogue**, which costs three MEASURED
  capabilities (`k01`/`k02` Argument immediates, `k03` a volatile-load immediate — all
  ACCEPT today, all still G2-true) against ZERO for the consumer re-ask.
* **NOT gated on `!inBennettClone`** (unlike (1b)): the Phase-2 dispatch honours the marking
  unconditionally, so gating would leave a hole exactly where the dispatch has none. Inert
  either way — `seedClone` builds a FRESH `TaintSet` and clones are built long after
  `lowerLoops` — and measured inert.
* **THE 8h7d.5 QUESTION, answered.** The widening is DECLINE-ONLY: it never REMOVES a member,
  so `railValueConsumerDisposition`'s `InPlace` cell (in `LoopLowering.cpp`, by NAME — the Rule-8
  fan-out guard and `collectRailGates`' forward extension) is byte-unchanged for every module
  that still lowers. A silent REMOVAL would make `collectRailGates` stop following the op and
  judge a rail record read past it FRESH when it is STALE — reopening 8h7d.5 F-1.

#### The STRONGER form, also shipped — the answer to "G2's pick was computed twice"

`TaintSet::InPlaceRailIdx` (`DenseMap<Instruction *, unsigned>`) records the proven rail's
**operand INDEX** — an index, never a `Value *` (the bd drbq Inc-1 dangling defect; RAUW
replaces operands in place without reordering them). Written by `markInPlaceRailOp`, the ONE
helper all four writers now call; ERASED in lockstep by `invariantRegisterRoots`' rollback;
RE-VERIFIED by the Phase-1 re-ask (a disagreement is the same loud decline); and **CONSUMED**
by `ArithLowering::rewriteInPlaceValueRail`, which until now re-derived
`bool TL = taint.Tainted.count(L)` a SECOND time at Phase 2 from a `Tainted` that `promote()`
mutates as Phase 2 runs. That second computation is what made the COMMUTED spelling mutate the
**wrong register**. The M-C straight-line route (`InPlaceReassign`) records no index and keeps
its own pick — its `sub` widening selects the rail with a DIFFERENT predicate
(`inPlaceReassignRailOperand`, handle-LHS only) — so M-C's stream is byte-for-byte untouched,
MEASURED.

#### Red-green (Rule 12) — 16 fixtures, and the 8 declines were RED

RED measured on the FROZEN `main`@16b15b3 binary
(`$SP/bin/main-16b15b3/{cq-opt,libCQPass.so}`) with the investigation's `immcheck.py`; GREEN on
the fix build. Fixture bodies are each reproducer's own `clang -O1` stage-1 module with
`@main` stripped, `!llvm.loop` VERBATIM.

| # | fixture | writer · stem · immediate | RED on `main` | GREEN on `fix` |
|---|---|---|---|---|
| 1 | `lowering_reject_inplace_rail_stale_w2_xor_derived.ll` | W2 · xor · `y&7` (6.5) | rc 0, `railInImm=1`, `cqrt_xorc_i32(%h2, %h_op)` | the mirrored decline |
| 2 | `..._w2_xor_bareout.ll` | W2 · xor · **bare `%out`** (E1) | rc 0, `railInImm=1`, `cqrt_xorc_i32(%h2, %out)` | decline |
| 3 | `..._w2_add_derived.ll` | W2 · **add** · `y&7` | rc 0, `railInImm=1`, `cqrt_addc_i32(%h2, %h_op)` | decline |
| 4 | `..._w3_xor_derived.ll` | W3 · xor · `y&7` | rc 0, `railInImm=1` | decline |
| 5 | `..._w3_add_derived.ll` | W3 · **add** · `y&7` | rc 0, `railInImm=1` | decline |
| 6 | `..._w1_xor_derived.ll` | **W1** · xor · `y&7` | rc 0, `railInImm=**2**` (forward + reverse-play) | decline |
| 7 | `..._w1_xor_bareout.ll` | **W1** · xor · bare `%out` | rc 0, `railInImm=**2**` | decline |
| 8 | `..._w2_xor_commuted_handir.ll` | W2 · xor · commuted — **WRONG REGISTER** (HAND IR; the header says so, and says why: three plain-C spellings all canonicalize back at LLVM 19 `-O1`) | rc 0, `railInImm=1`, `cqrt_xorc_i32(%h_op, %h2)` + `cqrt_measure_i32(%h6)` | decline |

ACCEPT controls, all 8 PASS on **both** binaries with the lowered module byte-identical
(modulo the `; ModuleID` path line) and the trace byte-identical:
`lowering_inplace_rail_{ctlA_const_imm, k01_arg_imm_xor, k02_arg_imm_add, k03_volatile_imm,
n09_w4_preheader, n02_select_merge, n03_value_merge, z36_inregion_add}_accept.ll`.
`k01`/`k03` are the two that separate "G2 alone" from `isa<Constant>`; `n02`/`n03` are the
discriminator that the fence is about **taint**, not about "there is a merge in this module";
`n09` is W4's lane, left alone.

#### THE W1 CRASH-RISK CELL, measured rather than argued

W1 is the one writer with a stage AFTER `lowerOps` — `lowerBreakReversePlay`
(`CQLoweringPass.cpp:543`) walks the LOWERED body and has its own declines
(`kMsgBreakRederive` / `kMsgBreakUninvertible` / `kMsgBreakUncovered`) for an un-lowered op,
and the Phase-1 `continue` leaves the marked `xor` un-lowered in exactly that module.
**MEASURED on `n15` and `n16`: `opt` rc 1 with EXACTLY ONE diagnostic — ours. No second
diagnostic, no crash, no `LLVM ERROR`.** Pinned by three `CHECK-NOT`s in both W1 fixtures, so a
future change that starts firing one tells a human instead of passing as green.

> ⚠ **CORRECTED BY THE CLEARANCE (finding F-CL-1, 2026-09-06): that disposition is TRUE FOR A
> DIFFERENT REASON than the paragraph above gives.** The driver EXITS AT THE FIRST `DS_Error`
> (`cq_opt_main.cpp` installs no diagnostic handler and the `LLVMContext` default exits; stock
> `opt` behaves identically — MEASURED: a two-member module with `@slice` duplicated as `@slice2`
> prints exactly ONE `error:` line and exits rc 1 on BOTH drivers, while the M1 mutant accepts it
> with `railInImm=2`; and 866/866 declining fixtures in the clearance's sweep carry exactly one
> `error:` line). So after the tripwire's `diagnose` the pass NEVER REACHES `lowerBreakReversePlay`
> — the stage does not "behave"; it does not run. The three `break reverse-play` negatives in the
> two W1 fixtures are live for FileCheck but UNREACHABLE under this driver, the same status as the
> vacuous IR-text pair: a tripwire for a driver that continues past the first error, not a
> witness of the stage. The observable contract (rc ≠ 0, 0 bytes emitted) holds on both drivers.

#### WHAT IS NOT COVERED, and what the decline COSTS

* **The alternative — re-asking G2 at the WRITERS after `repropagateControlMerges` — is
  REJECTED**, and the reason is the class this whole file is about. (i) The writers MUTATE
  (`tryCaseA` and `collapseRailPhisIn` collapse and ERASE rail phis; `emitBreakForward`
  performs the whole forward break transform), so "re-running" them is not a re-ask — the
  facts they derived from are gone. (ii) It only MOVES the window: `repropagateControlMerges`
  itself calls `detectAndLowerOnwardControl`, which mints new `%out` rails and taints more, and
  `lowerRotations` plus Phase-2 `promote()` still mutate `Tainted` afterwards. The only
  program point at which the answer cannot go stale is the CONSUMER. (iii) A second writer
  round is a BETTER PREDICTION, not a re-verification — the once-only-stage mistake again. (A
  second writer round *in addition to* the tripwire is defensible as a capability-preserving
  optimisation, and would re-accept some programs this declines; it is a separate increment
  and must never be the fence.)
* **The capability genuinely lost is the SHAPE ITSELF, and it has no correct rolled lowering
  today.** An in-loop in-place rail op whose immediate is a 6.5/4.5 merge value is a Q+Q
  op per iteration; its correct form is the out-of-place Q+Q, which mints a fresh rail every
  trip — the X1 cross-iteration decline. So the loud decline is the honest disposition, and
  **the hand-unrolled spelling still compiles correctly** (`u01`, `u02`, unchanged by this
  increment, emitting `cq_template_xor_i32(h1, h6)` + `and_i32_hl_unc` + `free`).
* **The fence is G2, so it is exactly as wide as G2.** It says nothing about an op whose
  immediate was ALREADY tainted at the writer (there is no marking to adjudicate — `n02`/`n03`)
  and nothing about the M-C route (`InPlaceReassign`, untouched).

#### WHAT WAS RUN — every number below is MEASURED, with the command

| layer | command | result |
|---|---|---|
| the 16 new fixtures, PRE-fix | `lit ir-pass/test --filter 'inplace_rail'` on the pre-fix build | **16 selected · 8 Passed · 8 Failed**, and the 8 Failed are EXACTLY the 8 declines (the RED) |
| the 16 new fixtures, POST-fix | same | **16 Passed** |
| the whole lit corpus | `lit -s ir-pass/test` | **1707 Discovered · 1706 Passed · 1 Expectedly Failed · 0 unexpected**, 37.58 s (1691 + 16). `ctest -R ir-pass-lit` **Passed, 37.66 s** |
| **the 0-golden-churn gate** | `ctest --test-dir build -j6 -R '^e2e-'` | **357/357 passed, 0 failed, 317.36 s**; `git status --porcelain tests/` **EMPTY** — 0 goldens regenerated, 0 new slices |
| **the corpus diff, `main`@16b15b3 vs `fix`** | both binaries over all **1691** pre-existing `.ll` fixtures, comparing exit code / first diagnostic line / output module | **RCDIFF=0 · DIAGDIFF=0 · OUTDIFF=0** |
| the 43-reproducer census (48 programs, incl. 6 extra probes) | `run.sh <p> main` vs `run.sh <p> fix`, STRICT stage 2b | **18 MOVED · 24 UNCHANGED**. The 18 are EXACTLY the programs with `railInImm>=1` on `main`, every one to the mirrored decline. All **23** programs accepting on BOTH: trace `cmp` byte-identical 23/23, lowered module identical 23/23 modulo the `; ModuleID` path line |
| the W1 lane | `cq-opt … -S <n15/n16 body>` on the fix | rc 1, **one** diagnostic (ours), no crash |

**0 new frozen symbols** (owner D3): `runtime/`, `tools/opcode_table.yaml` and `include/` are
untouched by this increment (`git diff --stat`).

**BUDGET THE ROUNDS.** This function has now produced **nine** findings over **seven**
adversarial rounds, two of them introduced by a fix and one — this one — found by a lens
reviewing a different increment. Nothing about a green 1707/357 says the tenth is not here;
the shape to hunt is the one all nine share, a dispatch precondition or a PREDICTION that
excludes (or wrongly admits) a customer the underlying proof already settles.

---

#### THE ROUND-1 ADVERSARIAL LENS on this fix (2026-09-06, session `7bbdb89e`) — verdict `CLEAR-WITH-ITEMS`

Full report `inc1-records/session-7bbdb89e/` (`review_eqpx_r1.md`); the lens's own corpus is
committed at `inc1-records/session-7bbdb89e/eqpx_reproducers_r1/` with a per-file README.

**No over-accept. No introduced miscompile. No crash. No golden moved.** Three DOC/FIXTURE
items (F-E1-1/2/3, all closed by the round-2 doc pass below), two CLEAR record findings
(F-E1-4/5), and the two hand-back OWNER QUESTIONS adjudicated. ⚠ Read the verdict as what it
is: this function's own history is **nine findings over seven rounds, two of them introduced by
a fix**, and one adversarial round is not a clearance.

##### F-E1-4 (CLEAR, record growth) — the class has 15 MORE measured members, and two of them were never silent

Beyond the investigation's 43-program census the lens built 43 new programs; **15 are new
`main` members**, every one declined by the fix with the mirrored string, none accepting on it.
Re-measured independently for this record by the round-2 doc pass on the same two binaries
(`$W/attack_{main,fix}.txt`); the two runs agree on all 15.

| probe | the immediate | `main` | `fix` |
|---|---|---|---|
| `x01_cast_short` | `(int)(short)y` — a CAST off `%out` | A 24, **imm=1** | DECLINE |
| `x02_cast_long` | `(int)((long long)y & 7)` | A 21, **imm=1** | DECLINE |
| `x03_cast_uchar` | `(unsigned char)y` | A 21, **imm=1** | DECLINE |
| `x04_bswap` | `__builtin_bswap32(y)` — a CURATED intrinsic, i.e. a real rail | A 21, **imm=1** | DECLINE |
| `x08_break_imm_in_cond` | W1 break, derived imm ALSO in the break condition | A 223, **imm=2** | DECLINE |
| `x11_phi_imm` | a classical `phi` of `y&7` / `y&3` | A 21, **imm=1** | DECLINE |
| `x12_two_ops_same_imm` | TWO rail ops sharing one immediate | A 24, **imm=2** | DECLINE |
| `x14_shift_imm` | `(y>>1)&7` | A 24, **imm=1** | DECLINE |
| `x15_deep_derived` | a 4-hop `((y*3+1)^2)&7` | A 29, **imm=1** | DECLINE |
| `y05_arm_then_two_loops` | one member loop beside one clean loop | A 27, **imm=1** | DECLINE |
| `y06_imm_arg_and_out` | `(y&7) ^ n` — `%out` MIXED with an Argument | A 24, **imm=1** | DECLINE |
| `y07_add_commuted_derived` | **the commuted `add`, from PLAIN C** | A 24, **imm=1** | DECLINE |
| `y08_nested_region_loop` | in-body region + 2 rail ops | A 53, **imm=1** | DECLINE |
| `x09_i8` | i8 rail, `(signed char)(y&7)` | **rc 134 `LLVM ERROR: Broken module found`** | DECLINE rc 1 |
| `x10_i16` | i16 rail | **rc 134, same** | DECLINE rc 1 |

**⭐ THE i8/i16 BROKEN-MODULE FACE is new to the record and it changes the class's
description.** MEASURED on `main`@16b15b3, first lines of stderr:

    Call parameter type does not match function signature!
      %h_op = call i32 @cq_template_and_i8_hl(i32 %h_cast, i8 7)
     i8  call void @cqrt_xorc_i8(i32 %h2, i32 %h_op)
    LLVM ERROR: Broken module found, compilation aborted!

The in-place ABI's immediate parameter carries the RAIL's LOGICAL width, so at i8/i16
substituting an `i32` handle for it does not even type-check. **At those widths the defect was
a loud abort, not a verify-clean silent miscompile** — the i32 flagship is silent only because
handle and immediate happen to share a width there. Nothing in `investigate_eqpx.md` or §3.12
records this, and it is worth carrying for the general reason: "verify-clean" was a property of
ONE width, not of the class.

**⭐ `y07` RETIRES HALF of §3.12's and `investigate_eqpx.md` §2's "the commuted spelling is
HAND-IR-ONLY".** True of the **wrong-REGISTER** face — `clang -O1` really does canonicalise the
operand order back, which is why fixture 8 of the red-green table is hand IR and says so.
FALSE of the **wrong-IMMEDIATE** face: `r = w + r` in plain C canonicalises to `r + w`, the op
is still marked, and the now-quantum `w` still lands in the immediate slot. So the commuted
`add` IS plain-C reachable; only its register-swap face needs hand IR. Both claims are corrected
in place rather than deleted.

##### F-E1-5 (CLEAR) — ZERO over-declines over 20 purpose-built boundary programs

`d01`..`d20` (Argument imm, `volatile` load, global, `select` of two constants, classical `phi`,
classical call result, `zext`ed classical, `switch`-folded classical, LOOP-VARIANT `r ^= i`,
i8/i16/i64 constants, W1 break with a constant AND with an Argument immediate, two independent
rails, in-region constant AND Argument immediate, the hand-unrolled twin, `add` then `xor`,
preheader-W4 constant): **all 20 ACCEPT on BOTH binaries with identical `lines`/`imm` and trace
`cmp` 20/20 BYTE-IDENTICAL.** Five of them (`d01`, `d05`, `d10`/`d18`, `d11`/`d12`, `d15`) are
precisely the non-Constant classical immediates a writer-side `isa<Constant>(Imm)` fence would
have refused, so their survival is the MEASURED cost argument for re-asking G2 alone at the
CONSUMER rather than fencing at the writer.

##### The lens's independent whole-corpus sweep and its stricter immediate detector

* **Both binaries over all 1707 lit fixtures** (`sweep2.sh`): `fix` **accepts=841 declines=866
  nonstd-rc=0**; `main` **accepts=849 declines=858 nonstd-rc=0**. Accept-set `comm`: **exactly
  the 8 new decline fixtures move accept → decline; ZERO move decline → accept**; **OUTDIFF=0
  over all 841 common accepts** (module byte-identical modulo `ModuleID`). An independent
  reproduction of the hand-back's `RCDIFF=0 · DIAGDIFF=0 · OUTDIFF=0`.
* **`strictimm.py`** — stricter than `immcheck.py`: it reports EVERY non-`Constant` immediate
  WITH ITS DEFINITION, so a rail arriving via `phi`/Argument/`select` cannot hide. Over all
  **841** `fix` accepts: **82 non-constant immediates, ZERO rail producers** (42 `sub i32 0, %k`
  break-counter negations, 16 `add` counter steps, 19 `load volatile` — the `@g` load is ONE of
  those 19, not a sixth class — 3 `cqrt_measure_i32` results, 2 Arguments; the partition was RE-COUNTED by the round-2 lens, F-E2-3, which found this list saying 15 `add` and listing the `@g` load separately, a self-cancelling error that never touched the load-bearing ZERO). On `main` the same sweep reports the 8 rail-producer
  sites. This is the measurement that says the tripwire leaves nothing behind, rather than
  saying the 43 known programs are fixed.

##### MUTANTS — a fence nobody tried to fool is a fence nobody should trust

Built in the lens's own detached worktree at `1333278`, whose baseline `cq-opt` is
`cmp`-BYTE-IDENTICAL to the subject's, so the environment reproduces it exactly.

| mutant | change | result |
|---|---|---|
| **M-A** | the whole eqpx tripwire disabled | `lit --filter inplace_rail` **8 Passed / 8 Failed**, the 8 Failed EXACTLY the 8 declines, each emitting `railInImm` 1 or 2. The decline fixtures pin THIS predicate and nothing else |
| **M-B** | a SILENT out-of-place fallback instead of the decline (`InPlaceRailOps.erase(BO)` + fall-through) | the same **8 go RED** (`lit -s` 1698 Passed / 8 Failed); nothing else moves. The "no third path" property IS pinned — by the `not` wrapper on the RUN line, NOT by the `CHECK-NOT`s (F-E1-2) |
| **M-E** | the recorded operand index FLIPPED **+** the Phase-1 re-verify disabled | **23 fixtures RED**, incl. 4 of the 8 new accept controls. The index plumbing is LIVE and observable when WRONG |
| **M-F** | `unrollConstTripLoops` disabled at BOTH entry points | `n01`/`n02`/`n03` DECLINE `cq loop lowering: loop-carried tainted value crosses iterations`. Adjudication (B) confirmed |

##### Adjudication (A) — the STRONGER form (`InPlaceRailIdx`): **DOC, keep. The lens could not break it.**

The implementer's OWNER QUESTION 1 was that the index plumbing is observationally INERT
(M2+M3: with both halves disabled, 0 of 1707 fixtures move). The lens tried and failed to
construct a Phase-2 event that flips which operand of a marked op is tainted, and the argument
is now written IN SOURCE at `ArithLowering.cpp` (the `InPlaceRailIdx.find` consume), where the
comment previously asserted "a checked fact, not a prediction" without saying why:

1. `rewriteInPlaceValueRail` has **exactly one call site** (`OpcodeLowering.cpp:557`), reached
   only from `Work`, every member of which passed the Phase-1 tripwire. No second route.
2. Every Phase-2 `Tainted` mutation is `promote(repl, orig)` (`ArithLowering.cpp:49`, mirrored
   at `CastLowering.cpp:38`, `CompareLowering.cpp:44`, `IntrinsicLowering.cpp:204`; the body is
   `Tainted.insert(repl); Tainted.erase(orig);`). It INSERTS a freshly created instruction and
   ERASES a value that was ALREADY tainted and has just been RAUW'd to it. So an operand
   UNTAINTED at Phase 1 is neither RAUW'd nor inserted and cannot JOIN `Tainted`; one TAINTED at
   Phase 1 is only ever replaced by another tainted value. Neither direction moves WHICH operand
   is the rail.
3. The one non-`promote` Phase-2 RAUW is `emitInPlaceReassign`'s
   `Site->replaceAllUsesWith(Handle)` (`ArithLowering.cpp:162`), substituting the rail handle
   G2 proved tainted.

**Stated honestly: argued defence-in-depth, not a fence with a red-green of its own** — it
agrees with `TL` on every program in the corpus. It is not decoration either: M-E reddens 23
fixtures, so it is consumed and observable when wrong. Kept because (1)-(3) is a CHAIN a future
stage can break silently, and because retiring the third independent computation of one
predicate is literally the 8h7d.5 F-1/F-3 lesson. **A reviewer who wants to delete it should
break (2) with a program, not with an argument.**

##### Adjudication (B) — the `n02`/`n03` loop collapse is `unrollConstTripLoops`, and it can NEVER claim an eqpx member

The implementer's OWNER QUESTION 2 (a 3-trip loop present in stage-1 and absent from the lowered
module) is **CLEAR — named and measured**. The stage is the Lever-B static-K force-unroll
pre-pass `ir-pass/src/LoopUnrollPrepass.cpp` (`unrollConstTripLoops`, wired at
`CQLoweringPass.cpp:271` and mirrored in the second entry point), confirmed by mutant M-F.

**Why it is not a fifth writer and not an escape past the tripwire — and the reason is
ORDERING, which is the one argument this file trusts.** Gate **U4** is
`loopHasInPlaceRailStructure` (`LoopLowering.cpp:2452`), whose clause (a) asks
`inPlaceValueRailOperand` — **G2 itself** — over every `BinaryOperator` in the loop, and whose
clause (b) asks the header-phi in-place peel. The prepass runs at `:271`, **before** `lowerLoops`
at `:363`, under the SAME ROUND-1 taint the writers read. Therefore:

* whenever a writer WOULD mark (G2 non-null at round 1) U4 clause (a) is TRUE and the prepass
  **REFUSES the unroll**; and
* whenever it DOES unroll, G2 was null at round 1, no writer marks, and the straight-line ops
  reach `lowerOps` as ORDINARY out-of-place Q+Q ops — MEASURED: `n01`/`n02`/`n03` emit
  `cq_template_xor_i32` with `imm=0` on `main`, on `fix` AND on the pre-3qlq oracle.

The two claim sets are disjoint **in both directions**, and taint only GROWS, so growth can only
turn G2 from non-null to NULL, never the reverse. `grep` confirms one `InPlaceRailOps.insert(`
site and four `markInPlaceRailOp(` callers — the prepass is neither.

The collapse itself is **parity-correct and PRE-EXISTING** (byte-identical on the oracle, on
`main` and on `fix`). Re-measured for this record on the `fix` binary, counting
`cq_template_xor_i32(` inside `@slice`: K=2 → **0**, K=3 (the shipped `n02`) → **1**, K=4 → **0**,
K=5 → **1**, i.e. the circuit realises `r ^ (K odd ? w : 0)`, the right value for an xor
involution at every K; and `n02`'s trace is `cmp` **BYTE-IDENTICAL** to its hand-unrolled twin's.
The direction of the difference is FEWER leaked ancillas, never a dirty free. Programs:
`eqpx_reproducers_r1/b_n02_{k2,k4,k5,unrolled}.c`.

##### F-E1-1 / F-E1-2 / F-E1-3 — the three DOC/FIXTURE items, and what closing them measured

**F-E1-1 (closed).** The fix's own load-bearing comments cited
`grep -n 'InPlaceRailOps.insert('` → four sites at `:1698 :2281 :2679 :3084`. Since the four
writers were folded into `markInPlaceRailOp`, that grep returns **ONE** site (inside the
helper), and the four writers are the `markInPlaceRailOp(` callers. `TaintPropagation.h` had the
command right and the numbers stale. All three blocks, the `.ll` fixture headers, §2's ⭐ row and
§3.16's writer table now name the helper as the command, give the four FUNCTION NAMES as the
durable key, and say the numbers move. Dated historical records (`investigate_eqpx.md`,
`NEXT_SESSION_PROMPT.md`, `review_c1b.md`) are left BYTE-UNCHANGED — they are true statements
about the pre-fix tree.

**F-E1-2 (closed).** MEASURED: on a `DiagnosticInfoUnsupported(DS_Error)` decline `cq-opt` writes
**0 bytes to stdout** (`>out 2>err` → rc 1, `wc -c out` = 0, one diagnostic line on stderr), and
the decline RUN line pipes `2>&1`. So FileCheck sees the diagnostic and nothing else, and the
8 fixtures' IR-text `CHECK-NOT`s are STRUCTURALLY UNABLE TO FIRE. The "no silent out-of-place
fallback" property IS pinned — by the `not` inversion, measured with mutant M-B (8 RED, nothing
else moves). Each of the 8 now carries a header block saying which mechanism does the work, and
the pair is kept, LABELLED as documentation of the forbidden output. **The two W1 fixtures'
three `break reverse-play` negatives are a DIFFERENT case and ARE live** — they name STDERR
text, which `2>&1` does pipe. ⚠ This is PRE-EXISTING HOUSE STYLE, not something this increment
introduced: the (1b) template `control_phase_kickback_reject_preloop_commit_stale.ll` carries the
identical vacuous pair and is deliberately left untouched (out of scope). A future reader
weakening a `RUN: not` because "the CHECK-NOTs cover it" would be wrong in every one of these
files.

**F-E1-3 (closed), and the number is the point.** The lens's injection matrix over the 8 NEW
ACCEPT fixtures — 3 injections (a rail-immediate `cqrt_xorc_i32(i32 %h, i32 %rail)`, an extra
out-of-place `cq_template_xor_i32`, an extra `cqrt_free`) × 2 positions (head, tail) × 8
fixtures = 48 — caught **20 of 48**. Position-independent gaps: **an extra `cqrt_free` was
MISSED by ALL EIGHT (16 of 16)**, because no accept fixture carried a free count at all, so a
Rule-6 dirty free inside an accept was invisible. The round-2 doc pass gave every fixture a
whole-file `FCNT` free count (or a pure `FCNT-NOT` where the count is 0) and the missing
rail-immediate / out-of-place negatives: **48 injections, 0 MISSED**, clean control green
(`lit --filter inplace_rail` 16/16). The BEFORE figure was re-measured independently by running
the same script against the pre-edit fixtures restored with `git show 1333278:<path>` — 28
MISSED, reproducing the lens exactly.

⚠ **ONE CORRECTION TO THE PRESCRIPTION, and it is the kind that matters.** The natural
strengthening — "give every accept the whole-file negative
`call void @cqrt_xorc_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})`, since a Constant immediate prints
as `i32 7` and never as `i32 %…`" — is TRUE of `ctlA` and **FALSE of `k01`/`k02`/`k03`**, whose
own legitimate gate is `cqrt_{xorc,addc}_i32(i32 %h, i32 %1)` with an Argument / volatile-load
immediate: the non-Constant classical immediate dtzb deliberately accepts
(G2 itself constrains the immediate ONLY by "not tainted" —
`inPlaceValueRailOperand`, `LoopLowering.cpp:143`; W1's break lane says it outright at (E10),
`LoopLowering.cpp:1568-1570`: *"`dtzb` accepts ANY untainted immediate"*) and the very reason this fix is G2-alone rather than a
writer-side `isa<Constant>(Imm)`. Adding it there would have reddened three shipped accept
controls. Those three get a whole-file EXACT-COUNT `XCNT` prefix for their own stem instead —
the COUNT is the prefix's FIRST directive, so its window is the whole file and an injection is
caught at head AND tail — plus the OTHER stem's rail-immediate negative. No positive count is
inside `NOROUTE` (Inc-3 F-L6-1).

⚠ **A LIT/FILECHECK TRAP, paid for once and worth writing down.** The first draft of the F-E1-2
header quoted the literal tokens `` `CHECK-NOT: cqrt_xorc_i32` `` and `` `RUN: not` `` inside
ENGLISH PROSE in the fixture. lit and FileCheck parse a fixture by SUBSTRING, so those became
REAL directives: all 8 decline fixtures went red with
`.script: line 3: syntax error near unexpected token ')'` — lit had built a RUN line out of a
sentence. **Never write `RUN:`, `CHECK:`, `CHECK-NOT:` or `<PREFIX>-NOT:` inside fixture prose**;
write the token without its colon. (Cheap to hit, and it looks nothing like what it is.)

##### What the round-2 doc pass changed, and what it did NOT

**COMMENTS, FIXTURES AND DOCS ONLY.** Verified two ways: `git diff 1333278 -- ir-pass/src
ir-pass/include | grep '^[+-]' | grep -v '^[+-]\s*//' | grep -v '^+++\|^---'` is **EMPTY**, and
the rebuilt `cq-opt` **and** `libCQPass.so` are both `cmp`-**BYTE-IDENTICAL** to the pre-pass
binaries. So every number the lens measured on `1333278` still stands for the shipped tree — the
doc pass is a statement that behaviour did not move, not a new measurement of it.

##### THE ROUND-2 ADVERSARIAL LENS on the doc pass (2026-09-06, session `7bbdb89e`) — verdict `CLEAR-WITH-ITEMS`

Report: `inc1-records/session-7bbdb89e/review_eqpx_r2.md`. It re-ran the round-1 items and the
two gates round 1 had not, found **no** correctness finding, and raised **four DOC items**, all
four CLOSED by the round-3 doc commit (below). What it MEASURED, and why each number matters:

* **The code did not move.** `git diff 1333278..beb34e0 -- ir-pass/src ir-pass/include` with the
  non-comment filter is **EMPTY**; `cq-opt` **and** `libCQPass.so` `cmp`-**BYTE-IDENTICAL** to
  `$SP/bin/eqpx-1333278/`. So round 1's verdict is exactly as strong — and as weak — as it was.
* **F-E1-3 closed WITH MARGIN.** The lens built a SUPERSET injection matrix — its own 3 injection
  kinds plus a `cqrt_xorc`/`cqrt_addc` with a CONSTANT immediate — **5 kinds × 2 positions × 8
  accept fixtures = 80 injections, 0 MISSED, 0 NOT-APPLIED**, clean control green 8/8. On the
  PRE-edit fixtures (`git show 1333278:`) the same script reads **47/80 MISSED** (and **28/48** on
  the 3-kind subset, reproducing round 1 exactly). `grep -n 'NOROUTE-COUNT'` over the 16 new
  fixtures is **EMPTY** — the F-L6-1 windowing hazard cannot recur here.
* **F-E1-2 closed.** All 8 decline headers name the mechanism and LABEL the IR-text negatives as
  documentation; stdout-on-decline re-measured **0 bytes**; a lit-pipeline emulation over the 8
  declines reads SUBJECT **8 Passed** / M-A **8 RED** / M-B **8 RED**, the two W1 cells going red
  under M-B through their **live** break-reverse-play stderr negatives.
* **F-E1-1 closed.** `grep -n 'markInPlaceRailOp('` → **four callers**; `grep -rn
  'InPlaceRailOps.insert'` → **ONE** real site, inside the helper. The three enumerating blocks
  agree with each other and with the tree.
* **Adjudication (A) re-measured, both halves.** The **M2+M3** binary (the `InPlaceRailIdx`
  consumption REMOVED) over **1707** fixtures: accepts 841 / declines 866, **identical=841,
  OUTDIFF=0** vs the subject — inert when removed. The **M-E** binary (the index written WRONG)
  over the same 1707: **24 fixtures move** (10 OUTDIFF + 14 accept→decline) — live when wrong.
  That pair is the evidence the owner's keep/drop call on the stronger form now rests on.
* **The accept-direction sweep.** Subject over **1707** fixtures: 841 accepts, 866 declines,
  nonstd-rc 0; `strictimm.py` **82** non-constant immediates and `immcheck.py` **0 rail
  producers**. Plus the reproducer corpus (43 + the lens's 43): **38 accepts**, `strictimm` 32,
  **0 rail producers**. **879 accept modules, 0 rail producers.**
* **The two gates round 1 did not run are GREEN.** The orchestrator's full run on this build tree
  (`$SP/progress/orch_full_ctest_eqpx.log`, `TIP=beb34e0`): **`100% tests passed, 0 tests failed
  out of 367`, 350.23 s** — `e2e-loop-twin-matrix` Passed 350.21 s, `ir-pass-lit` Passed 45.19 s,
  `frontend-lit` Passed 5.13 s, `cq-opt-equivalence` Passed 15.87 s, all 7 `runtime_*` Passed. The
  tree is `git status --porcelain`-EMPTY afterwards, so **0 golden churn** is a measurement and not
  an expectation. ⚠ READ from that log by the lens, not re-run by it.

**The four DOC items, and the round-3 commit that closes them** (`wip(eqpx-c):`, this commit —
docs/comments/one new one-line TU only; `cq-opt` again `cmp`-BYTE-IDENTICAL to
`$SP/bin/eqpx-1333278/cq-opt`):

* **F-E2-1** — the published reproducer dir was missing `tu_exth.c`, and its README's two-TU rule
  named only `ext_f`, so `d03_classical_phi_imm.c` / `d05_classical_call_imm.c` LINKFAILed when
  run exactly as the record said. FIXED: `tu_exth.c` committed beside the programs and the rule
  replaced by a per-symbol TABLE. MEASURED, `ext_f` **30** hits / `ext_h` **5** and no third
  symbol; both programs now `ACCEPT … lines=6 imm=0` on `main` AND on `fix`, traces `cmp`
  BYTE-IDENTICAL — the README's recorded rows reproduce.
* **F-E2-2** — the F-E1-1 class RECURRING: line-number citations into `LoopLowering.cpp` that were
  CORRECT on `main` and stale on the subject, because the fix inserts **+40 lines at
  `LoopLowering.cpp:156`**. FIXED by naming the FUNCTION at all of them. Round 3 also **widened the
  sweep to all three edited sources and to the bare `` `:<n>` `` CONTINUATIONS these docs write**
  (`| OpcodeLowering:341 / :428 |`, `(LoopLowering:2187, :2617)`) — a file-qualified-only regex
  finds 8 of the 10 and MISSES 2 (MEASURED by re-running that regex over `beb34e0`) — and found
  **TWO MORE the lens could not see**, in §3.14's own reader table:
  the citations then reading `OpcodeLowering:341` / `:428`, which on `main` were `lowerOps` Phase
  1's M-C guard conjunct and its Phase-2 `rewriteInPlaceValueRail` dispatch, and now name a comment
  and a different comment. Both are FIXED by naming those two, so this paragraph is the only place
  the old numbers survive — **as quotations of a retired citation, not as claims about this tree**.
  MEASURED by `inc1-records/session-7bbdb89e/citation_sweep/` (the script, the 71-row
  hand-adjudicated verdict file, and BOTH raw runs — committed, so this number is re-derivable):
  **BEFORE (tree at `beb34e0`) 62 citations scanned — 43 OK, 10 MISS-INTRODUCED, 9
  MISS-PREEXISTING; AFTER 61 scanned — 43 OK, 0 MISS-INTRODUCED, 9 MISS-PREEXISTING, 9 QUOTED**
  (the QUOTED are this subsection's own retellings of retired numbers, classified so the next
  sweep does not re-raise them, and 0 UNADJUDICATED in both runs).
  ⚠ **The 9 PRE-EXISTING are LEFT UNTOUCHED and named here so the next reader does not re-find
  them** — the numbers below are QUOTED so they can be FOUND, and none of them is a claim about
  this tree: `OpcodeLowering:263` (×4 — §3.10's F-C1-1 subsection, §3.10's 8h7d.5 table, §3.11's
  F-C1B-1 subsection, and one `LoopLowering.cpp` comment block) and `:350` (×2 — the table and that
  comment block), whose subject on `main` was already NEITHER of that file's two real
  `InPlaceRailOps` readers; and §3.14's `LoopLowering.cpp:3214` / `:3412-3413` for
  the two `peelInPlaceBase(…, AsLowered=true)` call sites, which are really in
  `invariantRegisterRootsImpl` and in `markIfRailLocal`. None sits in a paragraph this branch
  edited, and each was wrong on `main` too — so fixing them here would be a claim this round did
  not measure the history of. The verdict file `citation_verdicts.txt` carries all 71 rows — the
  62 of the BEFORE run plus the 9 `QUOTED` this subsection itself mints.
* **F-E2-3** — the `strictimm` partition above said `15 add` and counted the `@g` load as a sixth
  class. RE-COUNTED independently from the lens's own artefact: **42 `sub` · 19 `load volatile`
  (the `@g` load among them) · 16 `add` · 3 `cqrt_measure_i32` · 2 Argument = 82**. Self-cancelling;
  the load-bearing **ZERO rail producers** never moved.
* **F-E2-4** — `CLAUDE.md`'s *"That last one also RETIRES a sentence…"* lost its antecedent when the
  ⭐ FIXED clause was inserted above it. Re-anchored to **THE eqpx MEMBER** explicitly.

**THE RULE THIS SECTION KEEPS RE-LEARNING, now stated once for the whole file: cite the NAME, never
the line.** F-E1-1 was a stale `grep` count, F-E2-2 was ten stale line numbers, and TWO of the ten
were written by the very pass convened to close F-E1-1 — while that pass's own text states the rule.
A line number in a doc is a claim that decays on the next insertion **above** it, silently, with no
gate anywhere in the tree able to see it. Every round-3 edit is therefore **line-count-preserving**
(`OpcodeLowering.cpp` 581 = 581, this file 2836 = 2836 before the append, `CLAUDE.md` 2505 = 2505),
so that nothing else in the record — including `session-82e6b530/rebase_c1d.md`'s
`RETIRE_SWAP_ROUTE_INC1_NOTES.md:1976` — is invalidated by the fixing of it.

**Rule 13 is still NOT satisfied for this fix.** Two lenses on a docs pass are not a clearance, the
binary has not changed since round 1, and this function's history is **nine findings over seven
adversarial rounds, two of them INTRODUCED BY A FIX**. A clearance on the tripwire itself is owed.

#### The CLEARANCE (2026-09-06, Fable, `inc1-records/session-7bbdb89e/clearance_eqpx.md`) — verdict **CLEAR-WITH-OWNER-QUESTIONS**

Re-derived, not re-read: the ruling matched clause by clause against the diff; the 1691 pre-existing
fixtures **0 RCDIFF · 0 DIAGDIFF · 0 OUTDIFF** (main vs fix), the 16 new = exactly 8 accept→decline;
`immcheck` 0 rail producers over all 841 fix accepts; the 42-reproducer census on main/fix/orac
(18 MOVED, all members → the mirrored decline; 24 UNCHANGED; 17 both-accept traces byte-identical;
orac reproduces all 14 members it compiles); the lenses' 47 attacks (13 MOVED + `x09`/`x10` rc 134 →
decline, 25 both-accept identical); its OWN M1 mutant built from `git archive` (baseline `cmp`-identical;
the 8 declines go RED and nothing else moves: identical 1699 / RCDIFF 8); m23 vs fix **1707/1707
identical** and ME **24 move** (the index form: argued-inert, not decoration, not pinned); the
80-injection matrix 0 MISSED. **F-CL-2 — TWO MORE plain-C members, both declined by the fix**
(`clearance_probes/p_k_cmp_zext_imm.c`: the immediate is `(y > 6)`, a compare of the 6.5 `%out`
zext'd — a FLAG rail in the immediate slot; `clearance_probes/p_n_variant_plus_out.c`: `r ^= (w + i)`,
a LOOP-VARIANT classical immediate mixed with `%out`; each main ACCEPT 24 lines imm=1 → fix the
mirrored decline), beside 6 controls (`p_a` in-loop `cq_measure` immediate, `p_s` arm after the loop,
`p_t` Argument immediate beside an unused arm: ACCEPT/ACCEPT byte-identical; `p_c`, `p_m`, `p_q`:
the same pre-existing decline on both). **F-CL-1** is the correction boxed under "THE W1 CRASH-RISK
CELL" above. Two OWNER QUESTIONS stand, neither gating the landing: OQ-1 keep or drop the
operand-INDEX form (recommendation KEEP; either answer is a 0-behaviour change on the corpus);
OQ-2 a docs-only header note on the pre-existing (1b) template fixture
`control_phase_kickback_reject_preloop_commit_stale.ll`, whose IR-text `CHECK-NOT` pair is equally
vacuous on a `RUN: not` line.

