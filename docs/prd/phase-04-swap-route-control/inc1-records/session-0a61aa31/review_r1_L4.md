# review_r1_L4 — Rule-13 ROUND 1, lens L4: the ANGLE SELECT, both stems
bd `test_C_libtooling-3qlq.2` Inc 1 part A (register-free `cq_phi` by kickback).
READ-ONLY. Nothing in the checkout was edited, and `build/` was never rebuilt.

SUBJECT `/Users/sorenwilkening/Desktop/CQ_lang` @ `fa96336` (branch `3qlq-inc1`),
        `build/ir-pass/cq-opt` + `build/ir-pass/libCQPass.so` + `build/runtime/*.a`,
        `include/CQ.h` = the new `void cq_phi(double)`.
ORACLE  `$SP/wt/pre-3qlq` @ `52d7764`, its own `cq-opt` / `libCQPass.so` / archives,
        `include/CQ.h` = the retired 15-width `cq_phi_<sfx>(x, angle)` family.
HARNESS `$SP/progress/review_r1_L4/run.sh <file.{c,ll}> <subj|orac>` — stage 1
        (`clang -O1 -I<repo>/include -include CQ.h`) → stage 2 (`cq-opt
        -passes=cq-lowering`) → stage 2b (`tools/free_pairing_check.py`, **STRICT**,
        never `--allow-unproven`) → stage 3 (link, templates before runtime) →
        stage 4 (run). Artifacts in `out/<base>.<which>.{s1.ll,s2.ll,2b.txt,trace,
        diag,status}`.
MEASURED **72 full-pipeline runs** over 43 C probes (`p/`) and 26 hand-IR probes
        (`repro/`): **42 ACCEPT-and-run, 28 loud stage-2 declines**, 1 link failure
        and 1 stage-1 failure that are my own probe errors, not findings
        (`cat out/*.status | awk '{print $1}' | sort | uniq -c`). Every accept was
        stage-2b STRICT checked, linked and RUN. Plus two instrument runs described
        under "What else I ran".

---

## SUMMARY OF GRADES
| # | grade | one line |
|---|---|---|
| F-L4-1 | DOC-OR-FIXTURE-TRUTH (+ narrow OVER-ACCEPT residual, hand-IR-only) | the `IsPhase` fork skips `angleSelectArmsAdmissible` WHOLESALE and the shipped comment says every clause "has no subject" — true of clauses (2a)/(2b)/(2c)/(3), FALSE of clause (1): an `undef`/`poison` arm now reaches a gate slot verbatim, where the oracle declined it |
| F-L4-2 | DOC-OR-FIXTURE-TRUTH (red-green validated) | **10 of the 11 accept fixtures the increment shipped are BLIND to `cqrt_rz_f80` and `cqrt_rz_f16`** — the two Rz widths missing from every `NOROUTE-NOT` list — while PRD §5's whole claim is "the emitted Rz set becomes `cqrt_rz_i1` only" |
| F-L4-3 | DOC-OR-FIXTURE-TRUTH | P2 ships **4 fixtures** (2 accept / 2 decline) for a stem whose accept class is *defined by removing six S-clauses*; **8 of the 10 measured decline shapes are unpinned**, including the one that keeps F-L7-1 out of this path |
| F-L4-4 | CLEAR | the emitted `x(f); rz_i1(f,B); x(f); rz_i1(f,A)` is the correct unitary per basis branch, up to a global phase; the bracket is closed BEFORE the strip in every measured trace; polarity has no case and 6 `-O1` spellings confirm it |
| F-L4-5 | CLEAR | neither of the round's two confirmed findings has a *new* door on the angle-select path: F-L7-1's `ShareCondFlag` is structurally unreachable (S4's `Cond->hasOneUse()`, measured), and F-L3-1 reproduces here unchanged and is L3's |
| F-L4-6 | CLEAR | the merge-tail `phi double` (`ArmAnalysis::phaseAngleTail`) is polarity-correct in both diamond polarities and refuses 3-incoming / phi-of-phi / tainted-incoming spellings loudly |

---

## F-L4-1 — DOC-OR-FIXTURE-TRUTH (with a narrow, hand-IR-only OVER-ACCEPT residual)

**Claim (one line).** `classifyAngleSelect` skips the ENTIRE arm-value fence for the
register-free phase stem (`ArmClassify.cpp:4565`, `if (!IsPhase &&
!angleSelectArmsAdmissible(A, B))`), and the shipped justification —
"*every clause of that fence has no subject*" (`ArmClassify.cpp:4541-4551` and the
twin at `AngleSelectEmit.cpp:249-256`) — is **over-broad**. Clauses (2a) non-finite
arm, (2b) non-finite difference, (2c) run-time arm and (3) the 2^-40 rounding
residual genuinely have no subject (no subtraction is performed). Clause **(1)**
`valueCarriesUndef` does: the arm value is copied VERBATIM into an emitted gate
slot, so an `undef`/`poison` arm lands in `cqrt_rz_i1`'s angle operand.

### Measured, subject vs oracle (the four classes the oracle declined)
Reproducers `repro/v_{undefA,poisonA,nanA,infA,cexprA}.ll` (subject, phase stem,
`select i1 %c, double <ARM>, double 3.0e-01` consumed by `call void @cq_phi`) and
`repro/orz_{undef,poison,nan,inf,ok}.ll` (ORACLE, the same module in the retired
register surface, `%q2 = call i32 @cq_phi_si32(i32 %q, double %s)`).

| arm | ORACLE (`cq_phi_si32` angle select) | SUBJECT (register-free phase select) |
|---|---|---|
| `9.0e-01` (control) | ACCEPT, 8 trace lines | ACCEPT, 10 trace lines |
| `undef` | **decline** `cq controlled lowering: rotation angle under quantum control` | **ACCEPT** → `call void @cqrt_rz_i1(i32 %h_cmp, double undef)` |
| `poison` | **decline**, same string | **ACCEPT** → `… double poison` |
| `0x7FF8…` (NaN) | **decline**, same string | **ACCEPT** → `… double 0x7FF8000000000000` |
| `0x7FF0…` (+inf) | **decline**, same string | **ACCEPT** → `… double 0x7FF0000000000000` |
| `bitcast (i64 ptrtoint (ptr @g to i64) to double)` | (clause 1b) | **ACCEPT** → `… double bitcast (i64 ptrtoint (ptr @g to i64) to double)` |

Linked and RUN on the subject (`out/v_*.subj.trace`):
```
cqrt_rz_i1(h1, nan)                      <- v_nanA
cqrt_rz_i1(h1, inf)                      <- v_infA
cqrt_rz_i1(h1, 0x1.800000004p-1037)      <- v_undefA   (undef materialised at stage 3)
cqrt_rz_i1(h1, 0x1.800000004p-1037)      <- v_poisonA
```
Both arms `undef` DO decline, and not through this fence:
`cq literal integrity: undef/poison literal reaches two emitted gate operands`
(`repro/v_undefBoth.ll`) — the module-wide `declineUnpairedUndefLiterals`,
threshold **2 per function**.

### Which half of this is CORRECT, stated first
**`nan` / `inf` / `ConstantExpr` are the right disposition and the oracle's decline
was a by-difference artifact.** Measured baseline `repro/unc_inf.ll` (an
UNCONTROLLED `cq_theta(q, inf)` / `cq_theta(q, nan)`): **both binaries accept and
emit `cqrt_ry_i32(h0, inf)` / `cqrt_ry_i32(h0, nan)` verbatim**, 4 trace lines each.
So the compiler's standing semantics already is "a source-named non-finite angle
passes through"; clause (2a) exists only because `inf − x` can be `nan` in a
difference this stem never takes. Same argument for a link-time `ConstantExpr`: the
emitted angle IS the value the source named, resolved by the linker. Those three
acceptances are consistent with the rest of the compiler and should be **pinned as
deliberate**, not fenced.

### What remains, and why it is a finding rather than a shrug
`undef` / `poison` is **not a value the source named** — it is LLVM's "any value",
and the emitted circuit realises it as a concrete garbage angle. Three facts make
it worth a decision rather than an omission:
1. the ORACLE declined exactly this construct, loudly, for the Rz stem;
2. the only thing standing between one such slot and the fence is
   `declineUnpairedUndefLiterals`' threshold of **2**, whose own header argues a
   lone slot is safe *because it has no adjoint* (`LiteralIntegrity.cpp:193-201`)
   — and F-L7-1 is this round's demonstration that "no adjoint exists" is exactly
   the premise that stops holding when a gate set moves;
3. nothing records the decision. The shipped comment asserts the opposite of the
   measurement, in two places, in a file whose other fences carry 25-line
   derivations.

**Reachability, honestly: hand-IR only at this clang.** `clang -O1` InstSimplify
folds `select %c, double undef, double K` to `K`. The natural C spelling
`double a; if (q == 5) a = 0.9; cq_phi(a);` (`p/e01_undef_arm.c`) arrives as an
UNCONDITIONAL `cq_phi(double 9.0e-01)` and is deleted as a global phase — 3 trace
lines, no select at all (`out/e01_undef_arm.subj.s1.ll`). I could not construct a
plain-C reproducer. Graded DOC-OR-FIXTURE-TRUTH for that reason, not CONFIRMED.

### Proposed fix (`ir-pass/src/ArmClassify.cpp:4562-4566`)
Split the predicate so each stem asks exactly what it owns (Rule 14, one spelling):
`armsRealizable(A,B)` = today's clauses (1) + (1b), asked by **both** stems;
`armsDifferenceAdmissible(A,B)` = clauses (2a)/(2b)/(2c)/(3), asked by the Ry stem
only. Minimal edit if the split is judged too large:
```cpp
if (IsPhase) { if (valueCarriesUndef(A) || valueCarriesUndef(B))
                 return AngleSelectDisp::NotApplicable; }
else if (!angleSelectArmsAdmissible(A, B)) return AngleSelectDisp::NotApplicable;
```
(`valueCarriesUndef` is already exported — `ir-pass/include/LiteralIntegrity.h:370`.)
Then correct the two comments so they say *which* clauses have no subject.

### Fixtures that should pin it
* `control_angle_select_phase_reject_undef_arm.ll`, `..._reject_poison_arm.ll` —
  DECLINE, mirroring `cq controlled lowering: rotation angle under quantum control`
  character-for-character (`repro/v_undefA.ll`, `repro/v_poisonA.ll` are the modules).
* `control_angle_select_phase_nonfinite_arm.ll` — **ACCEPT**, the deliberate
  decision that a source-named `inf`/`nan` passes through, with `repro/unc_inf.ll`'s
  uncontrolled baseline quoted in the header as the reason. Without this the next
  reviewer "fixes" the non-finite half too and silently narrows the stem.
* `control_angle_select_phase_constexpr_arm.ll` — ACCEPT, same rationale for the
  link-time constant (module `repro/v_cexprA.ll`; note it needs a DEFINED `@g` to
  link, mine is `external` and only stage 3 fails).

---

## F-L4-2 — DOC-OR-FIXTURE-TRUTH (red-green validated with a full control set)

**Claim.** Every `NOROUTE-NOT` list in the phase family enumerates
`cqrt_rz_{i8,i16,i32,i64,f32,f64}` and **omits `cqrt_rz_f16` and `cqrt_rz_f80`**,
which are real shipped runtime symbols (`grep -o "cqrt_rz_[a-z0-9]*"
runtime/cq_runtime.h` → i1, i8, i16, i32, i64, f16, f32, f64). So the assertion
"this region emits no Rz of any other width" is blind to 2 of the 8.

**Measured** (`$SP/progress/review_r1_L4/inject.py`; one `cqrt_rz_<W>` call injected
immediately before the first `ret` of the pass's own output, i.e. OUTSIDE the
positive `CHECK-NEXT` chain, then every RUN prefix of the fixture re-checked):

```
control_angle_select_phase_constants     clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
control_angle_select_phase_runtime       clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
control_phase_kickback_diamond           clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
control_phase_kickback_ifelse_tail_phi   clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
control_phase_kickback_negated           clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
control_phase_kickback_two_calls         clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
control_phase_kickback_seq               clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
control_phase_kickback_inloop            clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
control_phase_kickback_derived_cond      clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
control_phase_kickback_f64_cond          clean=PASS f80=PASSES(blind) f16=PASSES(blind) i32=caught cswap=caught
lowering_phi_uncontrolled_deleted        clean=PASS f80=caught        f16=caught        i32=caught cswap=caught
```
CONTROLS, as the brief demands (two Inc-4 harnesses lied to their agents):
the clean run PASSES on all 11; `cqrt_rz_i32` and `cqrt_cswap` are CAUGHT by all 11;
and `lowering_phi_uncontrolled_deleted` catches f16/f80 — because its assertion is a
prefix-free `CHECK-NOT: cqrt_rz`, i.e. the ONE fixture in the family that spells the
claim as the claim. An earlier injection of mine placed the call before the free and
was caught by the positive `CHECK-NEXT` chain, not by `NOROUTE` — which is why the
site above is outside that chain and why the naive test would have said "covered".

**Why it matters now, not later.** PRD §5's table and the increment's own hand-back
say the emitted Rz set becomes `cqrt_rz_i1` only; the implementer measured that
**three** fixtures still make the pass emit a non-`i1` `cqrt_rz` through
`NestedRouteEmit.cpp:116` and `SwitchRouteEmit.cpp:113`, and **part B is being
written against that claim right now**. `cqrt_rz_f80` is also the exact width the
f80 libm census cells use. A width-completeness assertion with two holes is the
assertion that will be quoted when part B lands.

**Proposed fix.** Add the two missing `NOROUTE-NOT` lines to all 10 fixtures.
Prefer the exhaustive enumeration over a regex: `cqrt_rz_i1` is a textual prefix of
`cqrt_rz_i16`, so a "not i1" pattern is easy to get subtly wrong. Two smaller
truths in the same headers: `control_angle_select_phase_constants.ll:61` and
`control_angle_select_phase_runtime.ll:57` both say "every count lives in its own
**GCNT** prefix" while the prefixes are actually `C1`…`C4` / `C1`…`C3`.

---

## F-L4-3 — DOC-OR-FIXTURE-TRUTH (Rule-12 coverage of the P2 accept class)

**Claim.** `ls ir-pass/test/control_angle_select_phase_*.ll` = **4 files**
(`phase_constants`, `phase_runtime`, `phase_reject_two_consumers`,
`phase_reject_empty_arm_phi`) — 2 accepts and 2 declines for a stem whose accept
class is *defined by not asking* six of the ten S-clauses. Of the six skips only
(2c) (run-time arms) is pinned, by `phase_runtime`; clauses (1), (1b), (2a), (2b)
and (3) are pinned by nothing (that is F-L4-1's mechanism). And of the decline
partition I measured, **8 of the 10 shapes below have no fixture** (7 distinct
diagnostic strings — the two loop rows share one):

| shape (all measured on the SUBJECT, full pipeline) | probe | diagnostic | pinned? |
|---|---|---|---|
| nested selects on the angle `c1?A:(c2?B:C)` | `p/c01_nested_sel.c` | `cq controlled lowering: rotation angle under quantum control` | **no** |
| two `cq_phi` consumers of one select | `p/c02_two_consumers.c` | same | yes |
| select feeding a `cq_phi` AND a `cq_theta` | `p/c03_phi_and_theta.c` | same | **no** |
| tainted angle arm | `p/c08_tainted_angle2.c` | same | **no** |
| Q+Q compare | `p/q01_qq_sel.c` | same | **no** |
| shared compare (would be `ShareCondFlag`) | `p/m01_angsel_sharecond.c` | same | **no** ⟵ see F-L4-5 |
| compound `&&` condition tree | `p/c07_compound2.c` | `cq controlled lowering: control flow under quantum control` | **no** |
| select + consumer inside a bounded loop | `p/c09_sel_in_loop2.c` | `cq controlled lowering: control flow inside a loop body under quantum control` | **no** |
| loop-INVARIANT condition, consumer in the body (LICM-hoisted select) | `p/n01_loopinv_sel.c` | same | **no** |
| both arms empty, PredMux-rewritten | (implementer's) | `rotation angle` | yes |

Every one of those is a LOUD, correct decline today. The finding is that six
fences were removed for this stem and the decline partition documenting what is
LEFT was not written; the `m01` row in particular is the sole reason F-L7-1's
cancellation cannot reach P2, and it is asserted by no test.

**Proposed fix.** Eight `control_angle_select_phase_reject_*.ll` files, each
mirroring the string above character-for-character; the modules are the `.s1.ll`
files already sitting in `out/`.

---

## F-L4-4 — CLEAR: the unitary, the bracket order, and polarity

**No byte-identity twin exists** for the register-free phase angle select (prep d's
measurement — the void surface has no manual spelling of it), so the argument is
analytic, per basis branch, against the measured gate stream.

Emitted stream (measured, `out/a01_sel_const.subj.trace`), for
`if (q==5) cq_phi(0.9); else cq_phi(0.3);`:
```
cq_template_icmp_eq_i32_hl(h0, 5) -> h1     ; f = c(x)
cqrt_x(h1)
cqrt_rz_i1(h1, 0x1.3333333333333p-2)        ; B = 0.3
cqrt_x(h1)
cqrt_rz_i1(h1, 0x1.ccccccccccccdp-1)        ; A = 0.9
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)   ; strip -> |0>
cqrt_free(h1)
```
With `Rz(θ) = diag(e^{−iθ/2}, e^{+iθ/2})` on the flag, and the flag in `|c(x)⟩`:

* branch `c = 1`: `x` sends it to `|0⟩`, so `rz(B)` contributes `e^{−iB/2}`; `x`
  restores `|1⟩`, so `rz(A)` contributes `e^{+iA/2}`. Total `e^{+i(A−B)/2}`.
* branch `c = 0`: `x` sends it to `|1⟩` ⇒ `e^{+iB/2}`; back to `|0⟩` ⇒ `e^{−iA/2}`.
  Total `e^{+i(B−A)/2}`.

Ratio between the two branches is `e^{i(A−B)}`, which is exactly the ratio the
specification `P(A)` on `c=1` / `P(B)` on `c=0` produces; the two differ by the
overall factor `e^{−i(A+B)/2}`, which is branch-INDEPENDENT and therefore an
unobservable global phase. No `fsub` is performed and both `A` and `B` reach their
gate slot verbatim — measured for run-time arms too (`out/a02_sel_runtime.subj.s2.ll`
lines 17/19: `call void @cqrt_rz_i1(i32 %h_cmp, double %3)` / `double %2`, the two
`load volatile double`s). That is the whole ground for admitting run-time arms here
(owner Q3) while the by-difference Ry stem refuses them, and I confirm the refusal is
still stem-local: `p/a03_sel_runtime_ry.c` declines
`cq controlled lowering: rotation angle under quantum control` on the SUBJECT and on
the ORACLE, and `repro/v_ry_{cexpr,undef,nan,inf}.ll` decline with that same string on
the subject. **The 2^-40 fence is retired for the phase stem only.**

**Bracket order vs the strip.** The two `cqrt_x` are self-inverse and BOTH precede
the strip in every one of the 42 accepting traces, so the `_unc` reads the flag in
exactly the state the mint left it — checked mechanically over all 42:
`grep -c 'cqrt_x('` is EVEN in every one (0 odd; note the `(` — a bare `cqrt_x`
also matches the in-place `cqrt_xorc_i32`, which is how I first mis-measured this),
and **0 traces** have a `cqrt_x(` between a `_unc` strip and the `cqrt_free` that
follows it.

**Polarity has no case, and six `-O1` spellings confirm it** (`p/g_*.c`; a `select`
always means "true value when the condition is 1"):

| source | `-O1` IR | emitted (bracketed gate first) | correct? |
|---|---|---|---|
| `q != 5` | `icmp eq` + `select %c, 0.3, 0.9` | `x; rz(0.9); x; rz(0.3)` | ✓ 0.9 on `q!=5` |
| `!(q == 5)` | idem | idem | ✓ |
| `q < 5` | `icmp slt` + `select %c, 0.9, 0.3` | `x; rz(0.3); x; rz(0.9)` | ✓ |
| `q > 5` / `(unsigned)q < 5u` / `5 == q` | `sgt`/`ult`/`eq` | idem | ✓ |

---

## F-L4-5 — CLEAR: neither confirmed finding of this round has a NEW door here

**(a) F-L7-1 (`ShareCondFlag` spine adjoint) is structurally unreachable on the
angle-select path.** `classifyAngleSelect` S4 requires `Cond->hasOneUse()`
(`ArmClassify.cpp`, S4), so a compare that is also read as data can never be an
angle-select condition — there is no `ShareCondFlag` branch in
`emitPhaseAngleSelect` at all, the flag is always stripped and always freed inside
the region, and the spine therefore sees an unrecognised-consumer rail.
MEASURED independently of L7: `p/m01_angsel_sharecond.c`
(`int b = (q==5); cq_phi(b ? 0.9 : 0.3); return cq_measure(b) + cq_measure(q);`,
whose `-O1` IR really does have `%3 = icmp eq` used by both a `zext` and the
`select`) declines
`cq controlled lowering: rotation angle under quantum control`. And no cancelling
adjoint appears anywhere: over all 42 accepting traces the ONLY negated
`cqrt_rz_i1` line is my own probe's SOURCE-NAMED `-inf` arm
(`repro/v_infBoth.ll`, `select %c, double 0xFFF0…, double 0x7FF0…`); there is no
adjoint of an emitted kickback gate in any trace.
*This is a decline nothing pins* — it is row 6 of F-L4-3.

**(b) F-L3-1 (onward tainted condition) reproduces here unchanged and is L3's.**
I re-ran L3's own module `repro_t1_onward_angle_select.ll` on the subject:
exit 0, STRICT 2b PASS, 23 trace lines, `grep -c cqrt_rz` = **0**,
`grep -c cqrt_copy_f64_controlled` = **5**, `grep -c 'call void @cq_phi'` = **0**.
Same defect, same door (`deleteGlobalPhases` at `CQLoweringPass.cpp:342` running
before `repropagateControlMerges` at `:375`); the angle-select stem is the VICTIM,
not a second entry point. Not re-reported.

---

## F-L4-6 — CLEAR: the merge-tail `phi double` (`ArmAnalysis::phaseAngleTail`)

The per-incoming polarity rule `SwapRouteEmit.cpp` —
`FiresOnOne = In==Arm ? !ArmNegated : In==ArmFalse ? false : ArmNegated` — is
correct in both diamond polarities, measured on real `-O1` C:

* `p/t01_ifelse_tail.c` (`if (q>5) {phi(.25); phi(.125);} else {phi(.75);}`),
  `-O1` gives `br i1 %sgt, %arm, %merge` + `%5 = phi double [.125,%arm],[.75,%0]`.
  Emitted `rz(.25); rz(.125); x; rz(.75); x` — `.25+.125` on `f=1`, `.75` on `f=0`. ✓
* `p/t02_ifelse_tail_swapped.c` (the same program written `if (q<=5) … else …`),
  `-O1` inverts to `icmp slt %q, 6` with the ARM as the **false** successor.
  Emitted `x; rz(.25); x; x; rz(.125); x; rz(.75)` — the two gates that fire when
  the arm ran are both bracketed, the straight-through `.75` is not. ✓ (The
  `x; x` adjacency is a redundant pair, not a defect: `cqrt_x` is self-inverse.)
* `p/f01_shared_cmp.c` — a one-armed diamond whose tail phi carries the second
  phase: `rz(.9); rz(.2); x; rz(.4); x`. ✓

Off-pattern tail spellings all decline loudly:
`repro/t_3inc.ll` (three incomings / three preds) →
`cq controlled lowering: nested control flow under quantum control`;
`repro/t_phiphi.ll` (the tail phi feeding another phi) →
`cq controlled lowering: control flow under quantum control`;
`repro/t_tainted_inc2.ll` (a `sitofp`-tainted incoming) →
`cq controlled lowering: value-arm swap-route under quantum control`.
A `Pred` incoming in the IF/ELSE shape is unconstructible (`hasNPredecessors(2)`
forces the merge's preds to be exactly the two arms), so the third arm of the
`FiresOnOne` ternary is reachable only from the DIAMOND, which is what `t01`/`t02`
exercise. A `cq_theta` sitting in the merge BETWEEN the phi and its consumer is
also handled correctly (`repro/t_h_theta_merge.ll`): the mint, gates, strip and free
are all emitted at the branch and the post-region `cqrt_ry_i32(h0, 0x1.999…p-2)`
lands AFTER the free, so the strip reads the pre-Ry basis the mint read.

---

## What else I ran (both are measurements, not gates)

**1. Whole-corpus disposition flip sweep** (`flipsweep.sh` → `flipsweep.txt`; all
1602 committed `.ll` fixtures, copied to `$SP/progress/review_r1_L4/littree/` so the
checkout stayed untouched, run through BOTH binaries):
```
oracle=ACCEPT subject=ACCEPT   612
oracle=ACCEPT subject=decline  149     <- all 149 mention @cq_phi_<sfx> (measured, 0 exceptions): the migration set
oracle=decline subject=ACCEPT   10     <- EXACTLY the 10 new accept fixtures the increment added
oracle=decline subject=decline 831
```
The 10 are `control_angle_select_phase_{constants,runtime}` and
`control_phase_kickback_{derived_cond,diamond,f64_cond,ifelse_tail_phi,inloop,negated,seq,two_calls}`.
**Zero unexpected over-accepts at the fixture level.**

**2. The `control_angle_select_*` family under lit** (74 files, subject binaries,
`lit --filter 'control_angle_select'` against my copied tree): **28 red, and all 28
mention `@cq_phi_<sfx>`** — i.e. entirely the migration set. No Ry-stem fixture
regressed, and the accept→decline flips inside the family
(`ry_alias_pre_gate`, `ry_lifted_phi_{base,after_select}`,
`forward_rail_cycle_frozen`, `rz_*`) are all modules that also CALL the retired
family. The one worth naming for the migration agent is
`control_angle_select_forward_rail_cycle_frozen.ll`: it is the SOLE fixture pinning
S7 asymmetry 1 (a cycle carrying a gate on the rail forward of `T`), and it is
currently declining, so that asymmetry is unpinned until migration lands.

## Things I checked and found sound (no finding, recorded so they are not re-derived)
* **The in-place `cqrt_addc`/`cqrt_xorc` window hazard** `CLAUDE.md` flags for 2b
  applies verbatim to this stem (the flag is minted AT THE CONSUMER) and is
  protected for the same reason. `repro/w01_inplace_in_window.ll` puts
  `%e = add i32 %d, 5` textually BETWEEN the select and the `cq_phi` on the
  condition's own derived rail; `lowerOps` lowers it OUT of place
  (`cq_template_add_i32_hl(h1, 5) -> h2`) because the emitter's own mint and strip
  are later reads of `h1`, so the mint still reads the source predicate. Trace 14
  lines, STRICT 2b `2 verified, 0 violations`.
* Derived and deep-derived conditions uncompute AFTER the strip and free clean —
  `p/c10_or_cond.c` (`q==5||q==7` → `and i32 %q, -3`) gives
  `…_unc(h2,h1,5); and_i32_hl_unc(h1,h0,-3); free(h1); free(h2)`;
  `p/k02_deep_derived_measured.c` keeps the in-place `cqrt_xorc`/`cqrt_addc` chain
  live and consistent between mint and strip. STRICT 2b clean on both.
* Multi-region composition is order-correct and leaks nothing:
  `p/d01` (two angle selects), `p/d02` (kickback then select), `p/d03` (select then
  kickback), `p/n02` (three regions on three registers, 24 trace lines, source
  order preserved, one mint/strip/free each).
* An angle select in a `noinline` callee reached under taint declines
  `cq specialization: callee contains a non-reversibilizable construct under
  quantum lift (nested call)` (`p/h01`, `p/h02`) — safe over-decline.
* Comparing a register that was ALREADY measured, then angle-selecting on it,
  accepts on the subject — and its Ry twin `p/e02_measured_cond_ry.c` accepts
  **byte-identically on the ORACLE** (11 lines each), so that is pre-existing and
  not this increment's. It is also physically harmless: after the measurement the
  register is a basis state and the branch phase is a global phase.

## OWNER QUESTION
None. Nothing I measured contradicts a PRD §2 decision or a §12 assumption; in
particular Q3 (run-time arms admitted for the Rz/phase angle select) is measured
sound — no arithmetic is performed on the angles and both arms are already
evaluated SSA operands of the select, so the emitted circuit introduces no value
the source did not name. F-L4-1 asks the owner for nothing; it asks the fix agent
for one clause and four fixtures (two declines, two deliberate-accept controls).

---

## VERDICT — L4: **NOT CLEAR on fixture/doc truth, CLEAR on the unitary.**
Zero CONFIRMED-MISCOMPILEs in this lens. The emitted
`x(f); rz_i1(f,B); x(f); rz_i1(f,A)` is the correct unitary on every basis branch
up to a global phase, the bracket closes before the strip in all 42 accepting
traces, polarity has no case and six `-O1` spellings prove it, the merge-tail
`phi double` is polarity-correct in both diamond polarities, the whole 1602-fixture
corpus produces exactly the 10 intended new accepts, and neither of the round's two
confirmed findings has a new door here (F-L7-1 is structurally excluded by S4's
`Cond->hasOneUse()`; F-L3-1 reproduces unchanged and is L3's).
Three DOC-OR-FIXTURE-TRUTH findings stand: **F-L4-1** the arm-value fence is skipped
wholesale on a justification that is false for its `undef`/`poison` clause (the
oracle declined that class; hand-IR-only at this clang, and the non-finite /
link-time-constant half of the same skip is CORRECT and should be pinned as
deliberate); **F-L4-2** ten of the eleven shipped accept fixtures are blind to
`cqrt_rz_f80` and `cqrt_rz_f16`, red-green validated with controls, in the exact
week part B rewrites the two remaining non-`i1` Rz minters; **F-L4-3** the P2 stem
ships four fixtures for an accept class defined by removing six S-clauses, leaving
eight measured decline shapes unpinned — including the `hasOneUse` decline that is
the only thing keeping F-L7-1 out of this path.
