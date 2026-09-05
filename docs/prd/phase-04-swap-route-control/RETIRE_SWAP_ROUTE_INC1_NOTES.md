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
| **`collapseFlattenedLoopRails`** | yes | **YES — THIS IS F-R1-1** | **FIXED TWICE**: re-run at the end of `repropagateControlMerges` over the DELTA of `InLoopFlattenedPreds` (round 2) — and the DELTA ITSELF was wrong until the SECOND C-1 review round (F-C1-2(2b), §3.10): as a SET of blocks it could not see a round-2 region flattened into the very `Pred` a round-1 region already used, so a mixed loop holding BOTH was never re-offered. It is a per-block COUNT now, and "round 2 opened something here" is the count having MOVED |
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

## §3 — the Rule-13 CLEARANCE (2026-09-05) and the C-1 FIX ROUND (2026-09-06)

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
