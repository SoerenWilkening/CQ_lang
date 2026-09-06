# review_r1_L1 — Rule-13 round 1, lens L1 (KICKBACK POLARITY) on bd test_C_libtooling-3qlq Inc 1 part A

READ-ONLY lens. Nothing in `/Users/sorenwilkening/Desktop/CQ_lang` was edited or rebuilt.
SUBJECT `/Users/sorenwilkening/Desktop/CQ_lang` @ `fa96336` (branch `3qlq-inc1`),
binaries `build/ir-pass/cq-opt` + `build/ir-pass/libCQPass.so`, archives `build/runtime/*.a`.
ORACLE `$SP/wt/pre-3qlq` (`52d7764`, old `cq_phi(x,θ)` surface), its own binaries + archives.
All reproducers, traces, lowered IR and logs: `$SP/progress/review_r1_L1/`
(`probes/` 67 files, `out/` 51 traces, `run.sh` = the 4-stage pipeline incl. STRICT stage 2b,
`polarity_matrix.py` + `polarity_matrix.out`).

## What I measured, and how (so the CLEAR half is a measurement, not an impression)

**`polarity_matrix.py`** — for 33 spellings it does not trust the emitter's brackets at all.
It reads the SUBJECT's trace, parses the flag MINT line (`cq_template_icmp_<pred>_i32_hl(h0, K) -> f`),
evaluates `pred(q,K)` over `q ∈ [-8,16]` to get the set `S` where `f == 1`, walks the stream
tracking the parity of `cqrt_x(f)` (parity 0 ⇒ the gate fires on `S`, parity 1 ⇒ on its
complement), and compares the resulting `q → multiset of angles` against the SOURCE's own
expectation. **33 cases, 30 OK, 3 MISMATCH — and all 3 mismatches are F-L1-1, not polarity**
(they read `[+θ, −θ]`, i.e. net zero, on the marked branch).

Spellings covered and MEASURED correct: `==`, `!=`, `!(==)`, `<`, `>`, `<=` (→ `slt K+1`),
`>=` (→ `sgt K−1`), unsigned `ult`, `fcmp oeq` on the FALSE successor, `fcmp une` on the TRUE
one, `fcmp uno` on the FALSE one, `icmp ne` on BOTH successors (hand IR — `-O1` never leaves
it), constant-on-the-LEFT on both successors (`icmp eq i32 5, %q`; `icmp sgt i32 5, %q` →
`flipPredicate` → `icmp_slt_hl(q,5)`), `else`-only, if/else via the angle `select`, N gates in
one arm, the merge-tail `phi double` in FOUR configurations (positive diamond, NEGATED diamond,
incoming order `[Arm,Pred]` and `[Pred,Arm]`, and a genuine if/else with `[ArmFalse,Arm]`), a
genuine hand-IR if/else with 0/1/2 gates per arm, a derived condition (`(q>>i)&1` at K=4/32),
the per-bit D4 idiom, two sequential regions of OPPOSITE polarity, an in-loop NEGATED kickback
(rolled trace BYTE-IDENTICAL to its hand-unrolled twin — `out/s5_loop_neg.subj.trace` vs
`out/s5u_loop_neg.subj.trace`), a run-time-armed angle select, and the empty-arm `phi double`
that `-O1` turns into an angle select (which ACCEPTS from C, both polarities, correctly).

**Bracket closure.** Over ALL 51 traces I scanned every `cqrt_x(h)` and asserted the parity of
each flag is EVEN at every `cq_template_*_unc(h,…)` strip and every `cqrt_free(h)`:
**0 violations**. The brackets are emitted in pairs by construction (`emitArm` and the tail loop
each open and close inside one `if (Neg)`/`if (!FiresOnOne)`), so this is a check of the
construction, and it holds.

**Verdict on the lens's own question:** the `cqrt_x` bracket is present exactly when the arm
executes on `c == false`, in every spelling I could reach, and it is always closed before the
strip. The polarity ternary at `SwapRouteEmit.cpp:1472` is correct in all three of its branches
(verified by hand IR for the two that plain C cannot reach). **The finding below is not a
polarity error — it is a POLARITY-DEPENDENT one: the correct answer survives only on the arms
that happen to carry a `cqrt_x`.**

---

## F-L1-1 — CONFIRMED-MISCOMPILE: on the ziov shared-flag path the whole-DAG uncompute spine emits the ADJOINT of the kickback gate, so the branch phase is exactly cancelled and the circuit is the IDENTITY on `q`

**Claim.** When the condition compare is ALSO read as data (`R.ShareCondFlag`, the shipped ziov
accept), `emitPhaseKickbackRegion` skips the strip+free and leaves the flag to the data lineage.
The flag then becomes an ordinary reclaimable rail for the Phase-5 whole-DAG spine, which
recognises `cqrt_rz_i1(f, θ)` as an in-place gate on it, emits `cqrt_rz_i1(f, −θ)` as its
adjoint, strips and frees. `P(θ)·P(−θ) = I`: the kickback answer is deleted.

**Reproducer (plain C, `clang -O1`, 8 lines).**
`$SP/progress/review_r1_L1/probes/u4_datause_new.c` — which is **character-for-character the
body of the SHIPPED e2e slice `tests/e2e/slice_control_cond_datause.c` as prep-b has ALREADY
rewritten it** (`$SP/wt/prep-b/tests/e2e/slice_control_cond_datause.c`, verified identical):

```c
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int f = (q > 5);                       /* DATA use of the condition compare */
    if (q > 5) { cq_phi(0.25); cq_phi(0.75); }
    return cq_measure(q + f);
}
```

**SUBJECT trace** (`out/u4_datause_new.subj.trace`; stage 2 exit 0, **stage 2b STRICT PASS**
— "4 verified, 0 violation(s), 0 unproven" — linked, run):

```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1p-2)              <-- P(0.25)   the kickback answer
cqrt_rz_i1(h1, 0x1.8p-1)            <-- P(0.75)   the kickback answer
cq_template_zext_i1_to_i32(h1) -> h2
cq_template_add_i32(h0, h2) -> h3
cq_template_zext_i1_to_i32_unc(h2, h1)
cqrt_free(h2)
cqrt_rz_i1(h1, -0x1.8p-1)           <-- P(-0.75)  ADJOINT, cancels
cqrt_rz_i1(h1, -0x1p-2)             <-- P(-0.25)  ADJOINT, cancels
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h3) -> 0
```

**ORACLE trace, same program in the old surface** (`tests/e2e/slice_control_cond_datause.c`
verbatim, run on `$SP/wt/pre-3qlq`; identical to the committed golden):

```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cqrt_rz_i32_controlled(h1, h0, 0x1.8p-1)
cq_template_zext_i1_to_i32(h1) -> h2
cq_template_add_i32(h0, h2) -> h3
cq_template_zext_i1_to_i32_unc(h2, h1)
cqrt_free(h2)
cqrt_measure_i32(h3) -> 0
```

**The class is NEW to this increment.** The oracle's phase gates sit on the REGISTER `h0`
(which is measured, hence never reclaimed), so nothing inverts them. The kickback moves the
answer ONTO the flag — which is precisely the rail the spine reclaims.

**Analytic argument — the phase each basis branch receives.**
Let `c(x) = [x > 5]`. Intended (PRD §3): mint `Σ_x a_x|x⟩|0⟩ → Σ_x a_x|x⟩|c(x)⟩`; apply
`P(0.25)·P(0.75) = P(1.0)` to the ancilla → `Σ_x a_x e^{i·1.0·c(x)}|x⟩|c(x)⟩`; strip →
`Σ_x a_x e^{i·1.0·c(x)}|x⟩|0⟩`. Branch `x>5` gets relative phase **1.0**, branch `x≤5` gets **0**.
Emitted: the operator applied to the ancilla is `P(0.25)P(0.75)P(−0.75)P(−0.25) = P(0) = I`, so
the state before the strip is `Σ_x a_x|x⟩|c(x)⟩` and after it `Σ_x a_x|x⟩|0⟩`. Branch `x>5` gets
**0**, branch `x≤5` gets **0**. **The emitted circuit is the identity on `q`** — the exact defect
PRD §1 says this increment exists to remove (`grover-goldens-are-identity-tensored-rz`),
arriving through a different door.
(The reasoning is convention-independent: under `Rz = diag(e^{−iθ/2},e^{iθ/2})` the four factors
still multiply to the identity, and under `diag(1,e^{iθ})` likewise.)

**Second, MINIMAL reproducer whose ORACLE TWIN DECLINES** (so this is an accept the increment
newly opens, and opens wrong): `probes/u9_share_measureflag.c`

```c
int slice(void){ int q=3; q=cq_theta(q,0.5); int f=(q>5); if(q>5){cq_phi(0.25);} return cq_measure(f); }
```
SUBJECT (`out/u9_share_measureflag.subj.trace`): `icmp_sgt_hl -> h1 ; rz_i1(h1,0.25) ; zext(h1)->h2 ;`
**`rz_i1(h1,-0.25)`** `; icmp_sgt_hl_unc ; free(h1) ; measure(h2)`.
ORACLE, old-surface twin (`probes/o9_old_twin.c`): `exit=1`,
`cq controlled lowering: control flow under quantum control`.
A third (`probes/u7_datause_one.c`, one gate, `cq_measure(q+f)`) behaves identically; its
old-surface twin `probes/o7_old_twin.c` ACCEPTS on the oracle and does **not** invert.

**Why it is polarity-dependent, which is what puts it in this lens.** The identical program with
the arm on the FALSE successor is CORRECT — measured, `probes/u6_datause_negshare.c`
(`if (!f) { cq_phi(0.25); cq_phi(0.75); }`) emits `x(h1); rz(0.25); rz(0.75); x(h1); zext; add;
zext_unc; free(h2)` and h1 is simply LEAKED, phase intact. Root cause of the asymmetry:
`ChainWalk::isInPlaceGateOn` deliberately does NOT recognise `cqrt_x`
(`ir-pass/src/ChainWalk.cpp:383-385`, `:640-655`), so a flag carrying a bracket becomes an
UNRECOGNIZED consumer → the DAG is `NotClosed` → Rule-6-safe leak → nothing is inverted. The
answer therefore survives **by accident, and only on the negated arms**. Same for the
merge-tail-with-a-`Pred`-incoming spelling (`probes/u8_share_tail.c`, correct — it has a bracket).

**Neither shipped gate can see it.** `opt -verify` clean; `free_pairing_check.py` STRICT PASSES
(and is *cleaner* than the correct circuit — it now sees a proven `|0⟩` free where before it saw
a leak); no golden exists yet, and the one prep-b is about to regenerate will simply record the
cancellation as expected output. That is the `165/174` failure mode in gate form: a green suite
around a number/trace that measures a program which does nothing.

**Root cause, exactly.**
* `ir-pass/src/ChainWalk.cpp:226-229` — `isInPlaceGateOn`'s uncontrolled-rotation row
  `(N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_")) && G->arg_size()==2 &&
  G->getArgOperand(0)==H` admits `cqrt_rz_i1(f,θ)` on the FLAG. Its own comment ("an
  uncontrolled `cqrt_ry_<W>(H,θ)` is reversible by the spine and must stay so",
  `ChainWalk.cpp:275-277`) is true of a rotation on a DATA rail and **false of the 3qlq
  kickback gate, which is the ANSWER rather than scratch**.
* `ir-pass/src/EmitInverse.cpp:47-49` / `:192-200` then mint `cqrt_rz_i1(f, −θ)`.
* The window exists only because `ir-pass/src/SwapRouteEmit.cpp:1492` (`if (!R.ShareCondFlag)`)
  hands the flag to the data lineage un-frozen, having recorded nothing about the gates it just
  put on it — contrast the non-share path, which strips and frees and is CLEAN in all 30 of my
  non-share probes.

**Proposed fix (primary), following the drbq Inc 1 precedent verbatim.** Freeze the flag the way
`ChainWalk::railCarriesControlledRotation` (`ir-pass/src/ChainWalk.cpp:271-311`) freezes a
controlled-rotation rail: record the minted flag in a new `TaintSet::BranchPhaseFlags` at
`ir-pass/src/SwapRouteEmit.cpp:1403-1409` (immediately after `lowerCompareToFlag`, and only when
`R.ShareCondFlag` — the non-share flag is already discharged in-region), and make the
`taint`-taking entry points `ChainWalk::isTerminalHandle` / `isInteriorConsumer` and
`DagTraversal`'s closure scan treat a member as an unrecognized consumer → `NotClosed` → leak.
That reproduces, ON PURPOSE, the outcome the negated spelling already gets by accident, which is
the Rule-6-safe direction (a leaked flag, never a dirty free). Note this is a Rule-13 change to
`ChainWalk`, so it needs its own adversarial pass — the `.cpp:136-150` note warns that six
emitters read `isTerminalHandle`'s verdict.
**Interim, strictly safe alternative (Prime Directive):** decline the share path outright in
`ir-pass/src/ArmClassify.cpp:3656-3660` (`case CondDataDisp::ShareOk:` → a loud decline instead
of `Region.ShareCondFlag = true`). Cost: `slice_control_cond_datause` regresses accept →
decline, which is strictly better than shipping a golden of the identity. Rule 17 says a decline
is not the escape hatch for a TARGET shape — the shared-flag kickback is not named in PRD §6.2's
P1–P7 rows, so I read it as outside the increment's target and therefore a legitimate interim.

**Pinning fixtures required (Rule 12).**
* `ir-pass/test/control_phase_kickback_share_flag.ll` — the ziov shape in hand IR (`%c` with a
  `zext i1 %c` data user feeding the measured value). Whichever disposition is chosen, the accept
  form must carry a whole-file `NOROUTE-NOT: call void @cqrt_rz_i1(i32 %{{.*}}, double -` and an
  `XCNT-COUNT-1: call void @cqrt_rz_i1(` — the count alone does NOT catch this (the module has
  two `cqrt_rz_i1`, which is why every existing `C1-COUNT-n` prefix would stay green).
* `ir-pass/test/control_phase_kickback_share_flag_negated.ll` — the `probes/u6` twin, the
  measured control that keeps the polarity a discriminator rather than a decoration.
* e2e: `tests/e2e/slice_control_cond_datause.expected.log` must not contain a NEGATIVE angle.

---

## F-L1-2 — DOC-OR-FIXTURE-TRUTH: three polarity branches and the whole shared-flag path ship with ZERO fixture coverage — and the uncovered one is where F-L1-1 lives

**Measured**, over the 11 accept fixtures the hand-back names (`grep`ped and parsed, not eyeballed):

| polarity branch of the emitter | fixtures covering it |
|---|---|
| `emitArm(R.Shadow, /*Neg=*/false)` — diamond, arm on TRUE | 6 of the 8 kickback accepts (`seq` carries two such regions) |
| `emitArm(R.Shadow, /*Neg=*/true)` — diamond, arm on FALSE | 2 (`_negated`, `_derived_cond`) |
| `emitArm(R.ShadowFalse, /*Neg=*/true)` — a genuine IF/ELSE (`ArmFalse != null`) | **0** |
| tail-φ `In == R.ArmFalse ? false` (`SwapRouteEmit.cpp:1474`) | **0** |
| tail-φ `In == Pred` with `R.ArmNegated == true` (`:1475`) | **0** |
| tail-φ with the `Pred` incoming at index 0 | **0** |
| `R.ShareCondFlag` (`:1403` mint position, `:1492` skip) | **0** |

Command: no fixture in `ir-pass/test/control_phase_kickback_*.ll` has a block reached from both
branch successors (an if/else), none has a `zext i1 %c`/`sext i1 %c` data use, and none declares
more than `COUNT-2: call void @cqrt_x` — i.e. **no accept fixture emits two bracket pairs**, which
is the signature of every one of these branches.

I exercised all of them by hand IR and **all are CORRECT today**:
`probes/x1_ifelse_notail.ll` (0.9 on `q==5`, 0.3 otherwise), `x2_ifelse_emptytrue.ll`,
`x3_ifelse_emptyfalse.ll`, `x4_ifelse_2each.ll` (`{0.9,0.3}` on `q>5`, `{0.11,0.5}` on `q≤5`,
one bracket pair per arm), `h5_tail_predfirst.ll`, `h6_tail_neg_predfirst.ll`,
`h7_ifelse_tail_swapped.ll`. So this is a COVERAGE finding, not a miscompile — but Rule 12 says
an accept-predicate ships with its fixture, and the increment's own hand-back records the if/else
as "implemented while there".

**The if/else appears to be UNREACHABLE from `clang -O1`**, which is worth stating because it
changes what the fixtures must be: every C spelling I tried collapses to something else —
one gate per arm folds to an angle `select` (`probes/h_ifelse.c`), two-and-one folds to a
DIAMOND plus a merge-tail φ (`probes/k_tail.c`), and two-and-two folds to two `select`s
(`probes/w1_ifelse_2each.c`, see F-L1-4). So `emitArm(R.ShadowFalse, true)` is hand-IR-only
live code in the Rule-13 core. Either pin it with hand-IR accepts or say in the classifier that
it is unreachable-from-C and why.

**Proposed fixtures:** `control_phase_kickback_ifelse.ll` (= `probes/x1`),
`control_phase_kickback_ifelse_tail_armfalse.ll` (= `probes/h7`, the only shape that exercises
all three ternary branches at once), `control_phase_kickback_negated_tail_phi.ll` (= `probes/h6`,
4 × `cqrt_x`), plus the two share-flag files from F-L1-1.

---

## F-L1-3 — DOC-OR-FIXTURE-TRUTH: "ONE BRACKET PAIR PER ARM, not per gate" is false for the merge-tail spelling, and the audit-arithmetic sentence attached to it does not apply here

`ir-pass/src/SwapRouteEmit.cpp:1438-1441` and the header of
`ir-pass/test/control_phase_kickback_negated.ll` both assert: *"ONE BRACKET PAIR PER ARM, not per
gate: `cqrt_x` is self-inverse … `SwapRouteEmit.cpp:1063`'s `-2 cqrt_x` audit arithmetic assumes
exactly this."*

**Measured false in four programs, two of them plain C.** A merge-tail incoming is bracketed by
its OWN `if (!FiresOnOne)` (`SwapRouteEmit.cpp:1475-1479`), independently of the arm's bracket, so
one source arm can carry TWO pairs:
* `probes/l_tail_ne.c` (plain C, `if(q!=5){cq_phi(.9);cq_phi(.3);}else{cq_phi(.11);}`) →
  `x; rz(0.9); x; x; rz(0.3); x; rz(0.11)` — **4 `cqrt_x`**, two of them adjacent and cancelling.
* `probes/u8_share_tail.c` (plain C) — 2 pairs.
* `probes/h6_tail_neg_predfirst.ll`, `probes/h7_ifelse_tail_swapped.ll` — 2 pairs each.

The unitary is right (`cqrt_x` is an involution and the parity check above is clean), so this is
truth-of-the-comment, not correctness. Two consequences worth acting on: (i) the sentence should
say "one pair per arm PLUS one per bracketed tail incoming"; (ii) `SwapRouteEmit.cpp:1063` is the
drbq Inc-2a route→control-in-place collapse note and `tools/golden_multiset_audit.py` models
`-2 cqrt_x` per COLLAPSED QUINTUPLE — the kickback path feeds neither, so citing it as the thing
that "assumes exactly this" is a false dependency claim that the prep-c audit extension may
inherit. Suggested pin: the `probes/h6`/`h7` fixtures of F-L1-2, with an explicit
`XCNT-COUNT-4: call void @cqrt_x(`.

---

## F-L1-4 — OVER-DECLINE: two-or-more `cq_phi` in EACH arm of an if/else declines, although N-per-arm was explicitly accepted for the diamond

Orchestrator decision (2) accepted N gates per arm ("N `cqrt_rz_i1(f,θ_i)` on ONE flag, exact,
nothing summed"). That holds for the DIAMOND spelling (`probes/j_two.c`, `k_tail.c` — accept),
but the two `-O1` shapes the same construct takes in an if/else both decline:

* `probes/w1_ifelse_2each.c` — `if(q==5){cq_phi(.9);cq_phi(.3);}else{cq_phi(.11);cq_phi(.5);}`
  `-O1` emits TWO `select double` on one compare feeding TWO `cq_phi`; SUBJECT `exit=1`,
  `cq controlled lowering: rotation angle under quantum control`. (`probes/w2_…_ne.c` identical.)
* `probes/w3_ifelse_3v2.c` — `if(q>5){3 gates}else{2 gates}` → a diamond with ONE arm gate and
  **TWO** merge-tail `phi double`; `phaseAngleTail` refuses more than one φ
  (`ArmClassify.cpp:3405-3410`) → SUBJECT `exit=1`,
  `cq controlled lowering: control flow under quantum control`.

Both are loud and safe, so this is informational, not a Prime-Directive problem. It is reported
because "N gates per arm" reads, in the classifier header, as a property of the CONSTRUCT while
it is in fact a property of the one CFG spelling, and because a user writing the most natural
`if/else` with two phases per side gets a decline that mentions a "rotation angle" they never
wrote. If it is meant to stay declined, the classifier header should say which spellings the
acceptance covers.

---

## F-L1-5 — OVER-DECLINE (hand-IR only, pre-existing class, misleading message)

`probes/h9_two_br_one_cmp.ll` — two kickback diamonds branching on ONE CSE'd compare — declines
`cq controlled lowering: condition predates a non-diagonal gate under quantum control`, although
no gate of any kind exists between the compare and either branch. This is the bd `drbq.12` P4
precondition (`Cond->getParent() != R.Pred`) firing on the second region, whose `Pred` is the
first region's merge. Not reachable from C (`-O1` merges the two `if`s — `probes/s3_two_br.c`
ACCEPTS, correctly, as one two-gate arm). Reported only because the message names a cause that is
absent, which costs a future reader time.

---

## What I checked and found CLEAR (so the negative results are on the record)

* **Bracket presence/absence**: 33-case polarity matrix, 30 OK / 3 = F-L1-1; `polarity_matrix.out`.
* **Bracket closure before the strip and before the free**: 51 traces, 0 parity violations.
* **`clang -O1` canonicalisations**: `!=`→`eq`+swapped successors, `!(==)`, `>=`→`sgt K−1`,
  `<=`→`slt K+1`, unsigned, `fcmp` ordered/unordered — all correct, incl. the NaN-relevant
  `oeq`-on-false ≡ `une` and `uno`-on-false ≡ `ord` identities.
* **Constant on the LEFT**: `flipPredicate` is applied identically by the mint and by the strip
  (both go through `lowerCompareImpl` with `negate=false`), so mint and `_unc` name the SAME
  symbol; measured on both successors.
* **`xor i1 %c, true`** and **`select i1 %c, i1 false, i1 true`** as branch conditions: both
  decline `branch phase on a bare i1 condition` (`probes/h4`, `probes/y1`) — over-decline, safe,
  and `-O1` never produces either from `!(q==k)`.
* **3-predecessor merge** (`probes/h13`) and **two merge φ / a φ with two uses**
  (`probes/y2`, `y3`): decline `control flow`. A φ is never left standing in a block the flatten
  splices — the broken-module class the implementer found in their own work does not recur in
  any of my 67 probes.
* **Scratch-`ControlRegion` leakage across the three pre-peels**: `classifyAbortPark`
  (`AbortParkEmit.cpp:325-329`) and `classifyGuardedStoreArm` (`GuardedStoreArmEmit.cpp:214-220`)
  write only `{Kind,Pred,Arm,MergeBB,Merge,Condition,ArmNegated}`, all of which
  `classifyPhaseKickback` overwrites, and neither touches `ShareCondFlag`/`InLoop`. No stale
  polarity can be inherited. CLEAR.
* **`if (c) cq_phi(A); else cq_phi(A);`** (same angle) and **`cq_phi(classical ? A : B)`**:
  `-O1` folds both to an unconditional call, deleted by P7 — correct, a phase on both branches
  IS global (`probes/s7`, `s8`).
* **In-loop**: `probes/s5_loop_neg.c` (NEGATED kickback, K=2) is BYTE-IDENTICAL to its
  hand-unrolled twin `probes/s5u_loop_neg.c`. The per-bit D4 idiom at K=4 is correct in polarity
  but is NOT byte-identical to its unrolled twin (`probes/s6_perbit.c` vs `s6u_perbit.c`): the
  rolled form leaves the four `and` rails allocated where the unrolled form `_unc`s and frees
  them. Rule-6 safe (a leak), polarity-identical, and the same rolled≠unrolled class already
  quarantined as bd `test_C_libtooling-1m5p`; flagged here for L5 rather than claimed as mine.
* **Sequential regions of OPPOSITE polarity** under the hcrg reordering (`probes/s4_seq_mixed.c`):
  source order and brackets both preserved.
* **Angle select (P2)**, constant and RUN-TIME arms: `x(f); rz(B); x(f); rz(A)` — `A` on `f==1`,
  `B` on `f==0`, correct for `==` and `!=` spellings and for run-time arms (`probes/z1`).

## Verdict

**F-L1-1 CONFIRMED-MISCOMPILE** — plain-C, `clang -O1`, verify-clean, stage-2b-STRICT-clean, and
its reproducer is a SHIPPED e2e slice already rewritten to the new surface, so the next golden
regeneration would commit the identity as expected output. It must be fixed or the shared-flag
path declined before Inc 1a ships. Plus **F-L1-2 / F-L1-3 DOC-OR-FIXTURE-TRUTH** (the if/else,
the negated-tail and the shared-flag branches of the polarity logic ship with zero fixture
coverage; the "one bracket pair per arm" claim and its audit-arithmetic citation are false for the
merge-tail spelling) and **F-L1-4 / F-L1-5 OVER-DECLINE** (informational, both loud and safe).
On the lens's own question — is the `cqrt_x` bracket present exactly when the arm executes on
`c == false`, and closed before the strip — **CLEAR, over 33 measured spellings and 51 traces.**
