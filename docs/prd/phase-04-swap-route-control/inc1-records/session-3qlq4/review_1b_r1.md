# VERDICT: BLOCK

Rule-13 adversarial review, round 1, of bd `test_C_libtooling-3qlq.4` ("Inc 1b" — the
bare `_Bool` RAIL-LEAF condition), branch `3qlq-inc1b-rail-cond`, against
`main` @ `170ede1`.

> **Tree measured.** The review was commissioned at `aee9212`; the branch advanced to
> `8a8f8cf` during it (two docs/fixture commits, `a34cd22` + `8a8f8cf`). The COMPILER
> source is byte-unchanged across that range — `git diff --stat aee9212..8a8f8cf --
> ir-pass/src ir-pass/include runtime include tools` is EMPTY; the only movers are two
> lit fixtures (`control_inplace_ry_reject_rail_cond.ll` deleted as a duplicate,
> `control_inplace_ry_reject_raw_i1_cond.ll`'s string updated). Every measurement
> below was taken against the `8a8f8cf` build of `libCQPass.so` + `cq-opt`, i.e.
> against the tip, and every finding is about the compiler source both commits share.
> The `main` oracle is a worktree at
> `…/399370cc-…/scratchpad/review_1b/wt-main` (`170ede1`) — still registered; the next
> agent can `git worktree remove` it or reuse it with the `corpus.py` harness beside it.

**One CONFIRMED silent miscompile: F-1b-1.** A plain-C program at `-O1` that
`main` DECLINES now ACCEPTS and emits the phase on the WRONG predicate — the emitted
gate stream is BYTE-IDENTICAL to that of a *different, well-formed* source program.
`opt` exit 0, verify-clean, `free_pairing_check.py` `0 violation(s)`.
The underlying analysis gap is PRE-EXISTING and shared with the compare path
(measured byte-identical on both binaries, F-1b-1 §"parity"), so this increment does
not *introduce* the gap — it **adds a population to it**, and the specific
justification it wrote down for dropping the fence that would have caught the
plain-C case is measurably false (F-1b-4). That is the 8h7d.5 / drbq Inc-3 pattern
("'pre-existing' is true of the defect and FALSE of its population"), and the fix is
small and local.

Everything else measured CLEAN. In particular the polarity identity
`X·P(θ)·X = e^{iθ}·P(−θ)`, the increment's load-bearing new argument, held on every
one of the 14 shapes I could reach (§Negative space A), and the
`emitKickbackGroup` refactor is byte-neutral over the whole pre-existing corpus
(1707 fixtures: 0 unexpected movers, §Negative space F).

---

## What I ran

| layer | what | result |
|---|---|---|
| plain C @ `-O1` | 48 probe programs (`p/p0*`–`p/p9*`) | see below |
| hand IR | 22 modules (`h/h0*`–`h/h3*`) | see below |
| corpus regression | all **1707** `.ll` fixtures in `main`'s tree, `main` binary vs branch binary, stdout+stderr+rc | **1 RCDIFF, 2 DIAGDIFF, 1 OUTDIFF — both movers intended** |
| lit | `lit ir-pass/test --filter 'raw_i1\|rail\|bare_i1'` | **91/91 PASS** (1732 discovered) |
| ctest | `ctest -R 'phase-bool'` | **10/10 PASS** |
| stage 2b | `tools/free_pairing_check.py` on every accepting probe | **0 violation(s)** everywhere |

Probe sources are under
`…/scratchpad/review_1b/{p,h}/`; the `main` oracle is a worktree at
`…/scratchpad/review_1b/wt-main` built from `170ede1`.

---

## F-1b-1 — CONFIRMED-MISCOMPILE: a rail whose PARENT is a TEMPLATE result admits a sibling in-place Ry, and the kickback rides the moved register

**Severity: CONFIRMED-MISCOMPILE** (plain C, `-O1`, `opt` exit 0, verify-clean,
stage-2b clean; `main` declines the same program).

### Reproducer (plain C, `p/p80_sibling_theta_from_C.c`)

```c
#include "CQ.h"
int main(void){
    int  q = cq_theta(0, 0.3);
    bool t = (bool)(q & 1);          /* a TEMPLATE rail: cq_template_icmp_ne_i32_hl */
    bool b = cq_theta(t, 0.5);       /* in-place Ry on t's rail                     */
    bool c = cq_theta(t, 0.9);       /* a SECOND in-place Ry on the SAME rail       */
    if (b) cq_phi(0.7);              /* the branch reads b — a STALE record         */
    return cq_measure(c);
}
```

`clang -O1` hands the pass exactly that (both thetas and the `br` in ONE block):

```llvm
%1 = tail call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
%2 = and i32 %1, 1
%3 = icmp ne i32 %2, 0
%4 = tail call i1 @cq_theta_i1(i1 %3, double 5.000000e-01)
%5 = tail call i1 @cq_theta_i1(i1 %3, double 9.000000e-01)
br i1 %4, label %6, label %7
```

### Measured on THIS binary

```
cqrt_alloc_i32(0) -> h0
cqrt_ry_i32(h0, 0x1.3333333333333p-2)
cq_template_and_i32_hl(h0, 1) -> h1
cq_template_icmp_ne_i32_hl(h1, 0) -> h2
cq_template_and_i32_hl_unc(h1, h0, 1)
cqrt_free(h1)
cqrt_ry_i1(h2, 0x1p-1)                    <-- b
cqrt_ry_i1(h2, 0x1.ccccccccccccdp-1)      <-- c, SAME rail h2
cqrt_rz_i1(h2, 0x1.6666666666666p-1)      <-- the kickback, AFTER both
cqrt_measure_i1(h2) -> 0
```

`python3 tools/free_pairing_check.py`: `0 violation(s)`. On `main`
(`wt-main/build/ir-pass/cq-opt`) the same module declines:
`cq controlled lowering: branch phase on a bare i1 condition under quantum control`.

### Why it is wrong — measured, not argued

`b` and `c` are two in-place Ry on ONE physical rail (`h2`), so the SSA name `%4`
that the branch tests no longer denotes anything the register holds: at the branch
point the register is `Ry(0.9)·Ry(0.5)|t⟩`, which is `c`, not `b`. The compiler
realizes `if (c) cq_phi(0.7)` where the source says `if (b) cq_phi(0.7)`.

Measured directly — the *same* gate stream, byte for byte, for **three different
source programs**:

| file | source predicate | trace |
|---|---|---|
| `p/p80_sibling_theta_from_C.c` | `if (b)` (the subject) | the 10 lines above |
| `p/p80b_ifc.c` | `if (c)` | **byte-identical** (`diff` empty) |
| `p/p80c_wellformed_twin.c` | `bool c0=cq_theta(t,.5); bool c=cq_theta(c0,.9); if (c)` — **well-formed, no aliased name** | **byte-identical** (`diff` empty) |

So the subject's emitted circuit *is* the correct compilation of `p80c`, a different
program, and the subject's own meaning appears nowhere in it. Under CQ's linear rule
(`docs/frontend.md` §3.2, "a rotation consumes the old name") `p80` is a linearity
violation, which the compiler's own policy is to DECLINE — and does decline when the
aliased parent is a theta (see `p/p82`, below).

### Hand-IR minimisation and the cross-block amplification

`h/h21_sibling_theta_template_rail.ll` is the same shape in one block. **`h/h26_crossblock_sibling.ll`** puts the sibling theta in a *classically guarded middle
block* and the branch in a third block; it also ACCEPTS, emitting

```llvm
entry: ... %h_cast = cq_template_trunc_i32_to_i1(%h); cqrt_ry_i1(%h_cast, 0.5); br i1 %cg, mid, pred
mid:   cqrt_ry_i1(%h_cast, 0.9); br pred
pred:  cqrt_rz_i1(%h_cast, 0.7), !cq.branchphase; cqrt_measure_i1(%h_cast)
```

i.e. the phase is applied to a register whose state at the branch depends on a
classical guard the region never saw. A COMPARE condition cannot reach this shape at
all — `condWireDisposition` declines outright on `Cond->getParent() != R.Pred` — so
the cross-block half of this class is **rail-only**.

### Parity: the gap itself is PRE-EXISTING

The *analysis* gap is in the shared walker `WireWalk::findNonDiagonalWireGate`, whose
per-seed BACKWARD ancestry closure crosses an arg-0 edge only when the parent is
itself a `cq_theta_`/`cq_phi_` call:

```cpp
if (isCallToPrefix(CI, "cq_theta_") &&
    (isCallToPrefix(Arg0, "cq_theta_") || isCallToPrefix(Arg0, "cq_phi_"))) {
  V = Arg0; continue;
}
break;  // wire origin (source theta / template result / argument)
```

A `cq_template_*` parent stops the closure, so the sibling theta — a user of the
*parent*, never of the seed — is unreachable by the forward walk. Measured both ways:

* **theta parent ⇒ caught.** `p/p82_sibling_theta_chained_parent.c`
  (`int a=cq_theta(0,.3); int b=cq_theta(a,.5); int c=cq_theta(a,.9); if (b==1) cq_phi(.7);`)
  → `cq controlled lowering: condition predates a non-diagonal gate` on this binary.
  `h/h05_two_alias_rails_xor.ll` (the rail spelling of the same) →
  `cq opcode lowering: operand predates a non-diagonal gate`.
* **template parent ⇒ missed, on BOTH binaries.** `p/p81_sibling_theta_int_twin.c`
  (`int a=q&1; int b=cq_theta(a,.5); int c=cq_theta(a,.9); if (b==1) cq_phi(.7);`)
  ACCEPTS on `main` and on the branch, and the two lowered modules are
  **byte-identical** (`diff` empty). Same for `h/h25_sibling_theta_cmp_twin.ll`.

So the compare half is a separate, older defect that this review found in passing and
that this branch does not move; it should be filed on its own (the `eqpx` precedent).

### Proposed fix

Two independent pieces; (2) is the principled one and (1) is the cheap rail-local
tripwire. Both are decline-only and monotone.

1. **Restore a positional prong to `railCondWireDisposition`, over the RAIL's own
   window.** `condWireDisposition`'s prong scans `[Cond->getNextNode(), BI)` for any
   `cq_theta_` with a TAINTED arg-0 — it fires even on another wire, deliberately.
   Asked over `[RailDef->getNextNode(), BI)` when `RailDef->getParent() == R.Pred`,
   it declines `p80`/`h21` (measured: `%5`'s arg-0 `%3` is tainted). Note this is
   *strictly more* than what the compare path can do, because a compare's window
   starts at the compare and `p81`'s sibling theta sits before it — which is exactly
   why `p81` escapes on both binaries.
   For the cross-block half (`h26`) either re-instate the compare path's
   `Cond->getParent() != R.Pred ⇒ DeclineNow` (this costs the shipped accept
   `control_phase_kickback_rail_cross_block.ll`) or rely on (2).
2. **Cross the chained-theta arg-0 edge whenever the parent is TAINTED**, not only
   when it is spelled `cq_theta_`/`cq_phi_`, in `findNonDiagonalWireGate`'s backward
   ancestry (and in `collectWireValues`'s mirror). That is exactly the relation
   `lowerRotations` uses to decide in-place-ness (`Chained = taint.Tainted.count(Op)`),
   so the closure would then match the physical rail it is reasoning about. This is a
   Rule-13-core change to a walker with many callers: it must be measured over the
   full fixture corpus (my harness `corpus.py` in the scratch dir does exactly this
   diff and takes ~4 min) and expected to produce only new DECLINES.

Whichever is taken, it needs the red-green pair: `p80` (or `h21`) as a decline
fixture mirroring the string character-for-character, plus `h/h26` for the
cross-block half, plus `p/p07_chained_after.c` (a legitimate POST-region chained
theta, currently `ProvenPostRegion`-accepted — see Negative space C) as the
discriminating ACCEPT so the new prong cannot be a blanket refusal.

---

## F-1b-2 — SUSPECTED (over-accept of a stated fence; no wrong unitary found): `railMeasuredBeforeBranch` is dominance-blind on a non-dominating path

**Severity: SUSPECTED / DOC.**

`p/p20_measure_sidepath.c`:

```c
#include "CQ.h"
volatile int v = 1;
int main(void){ bool b = cq_theta((bool)0,0.5); int r = 0;
                if (v) r = cq_measure(b);      /* classical side path */
                if (b) cq_phi(0.7); return r; }
```

Measured (`opt` exit 0, stage 2b clean):

```llvm
%h = call i32 @cqrt_alloc_i1(i1 false)
call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
br i1 %2, label %5, label %3
3: %m = call i1 @cqrt_measure_i1(i32 %h)   ; measured on ONE path
5: call void @cqrt_rz_i1(i32 %h, double 0x3FE6666666666666), !cq.branchphase
```

`h/h04_sidepath_measure.ll` is the hand-IR minimisation.

The fence's own header says a measure "in a block that DOMINATES `Pred` executes
first; a measurement anywhere else is downstream of the region and owns the register
from there on". **The second half is false**: `%3` neither is `Pred` nor dominates
it, yet it executes strictly before the branch on that path. The code is

```cpp
if (M->getParent() == Pred) return true;
if (!DT || DT->dominates(M->getParent(), Pred)) return true;
return false;   // <-- p20 lands here
```

**I could not turn this into a wrong unitary, and I say so plainly.** After the
measurement the register is a basis state, so the emitted `Rz` on it is a global
phase, and the source's `if (b) cq_phi(θ)` on a collapsed `b` is a global phase too —
the two agree. It is a Rule-6 "post-measure gate" in the letter, not in the effect.

It is also **not** a regression: the COMPARE path is weaker still.
`p/p30_int_twin_measure_sidepath.c` shows an *unconditional* `cq_measure(b)` followed
by `if (b == 1) cq_phi(0.7)` ACCEPTING and minting
`cq_template_icmp_eq_i32_hl(h0, 1)` from the measured register; and `p/p21` (the rail
spelling of the unconditional case) DECLINES. So `railMeasuredBeforeBranch` is
strictly stricter than anything the compare path has.

**Proposed fix:** either replace the dominance test with "reaches `Pred` without
re-executing the rail's def" (the `WireWalk::reachesWithoutBarrier` shape, already in
the tree), or — cheaper and honest — correct the header to say what the predicate
actually proves and record the residual, with `p/p20` as a committed
ACCEPT-AND-DOCUMENTED control so the class has a witness.

---

## F-1b-3 — DOC: the one rail-reachable erase site NOT guarded by `!isCondRailLeaf`

`RegionFlatten.cpp` grew three guards this increment, each commented "defence in
depth against erasing a user's rotation on a shape nobody measured":

```cpp
if (Cond && Cond->use_empty() && !isCondRailLeaf(Cond)) { scrubTaint(...); Cond->eraseFromParent(); }
```

`AngleSelectEmit.cpp`'s `emitPhaseAngleSelect` step 4 has the identical construct and
**no guard**:

```cpp
  if (Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();     // Cond IS the user's @cq_theta_i1 on the rail path
  }
```

It is unreachable today, but only by an emission-order accident: step 2 emits the two
`cqrt_rz_i1(Flag, …)` with `Flag == Cond`, so the rail always carries two fresh uses
by the time step 4 runs. That is the same *shape* of accident the Inc-1 record calls
out for F-L7-1 ("whether a user's phase survived depended on which polarity
`clang -O1` canonicalized to … that is an accident, not a fence"). An emitter change
that ever makes both gates fold away (e.g. a future `A == B == 0` peephole, or an
early-out on an empty angle list mirroring `emitKickbackGroup`'s `Angles.empty()`)
would silently delete a user's `cq_theta`.

**Proposed fix:** one token — `if (!RailCond && Cond->use_empty())`, or reuse
`!isCondRailLeaf(Cond)` so the three sites read identically (Rule 14).

---

## F-1b-4 — DOC: two in-source justifications are measurably false

1. `railCondWireDisposition`'s header:
   > "the same-block/positional scan (it bounds the window between a COMPARE and its
   > branch, which for a rail is the whole wire and **is already what the
   > position-free walk asks**)"

   The second clause is what F-1b-1 refutes: the position-free walk asks about the
   seed's *user graph*, the positional scan asks about *any tainted-operand theta in
   the block window*. `p/p80` is in the difference, and the positional prong would
   have declined it. This sentence is currently the recorded reason the prong was
   dropped, so it is load-bearing prose, not a comment.

2. `railMeasuredBeforeBranch`'s header: "a measurement anywhere else is downstream of
   the region" — refuted by `p/p20` (F-1b-2).

Recording both matters for the same reason the `fenv` block in `CLAUDE.md` records
its own: an agent-authored justification that hardens by repetition is how this
project's worst defects got shipped.

---

## F-1b-5 — OVER-DECLINE (list only, all as documented; lower priority)

Each measured on this binary; none is a correctness problem.

| probe | shape | string |
|---|---|---|
| `p/p31`, `p/p65` | loop-CARRIED `_Bool` (header phi condition) — incl. Grover written on a single `bool` | `branch phase on a bare i1 condition` |
| `p/p03`, `p/p06`, `p/p33` | `(int)b` folded by `-O1` into a DATA select on the rail | `bare i1 register condition` (follow-on 1b-B) |
| `h/h10` | value arm | `bare i1 register condition` |
| `h/h12` | in-place `Ry` arm | `bare i1 register condition` |
| `p/p96` | 6.5 classical-call arm | `bare i1 register condition` |
| `p/p35`, `p/p36`, `h/h20` | nest with a NEGATED rail level / rail defined in `Mid` | `branch phase on a bare i1 condition` / `control flow` |
| `p/p47` | `b && v` with `v` classical | `control flow` |
| `h/h30`, `h/h31` | `and i1 %b, true`; the NOT-carrying `select i1 %b, i1 false, i1 %c` | `control flow` |
| `p/p92` | depth-2 nest inside a loop | `condition predates a non-diagonal gate` |
| `h/h23` | rail as a LOOP EXIT condition | `loop under quantum control` |
| `h/h24` | 9 rail leaves | `branch phase condition tree too deep` |
| `p/p41` | rail phase + quantum `break` | `cq loop lowering: early break preserves a phase answer` |
| `p/p71`–`p/p75` | abort-park composed with a phase region — declines for the RAIL **and** the `int` spelling (parity) | `control flow` / `phase-class value escaping` |
| `p/p44`, `p/p61`, `p/p64` | `_Bool` across a function boundary (specialization / return) | specialization + taint-escape strings |

---

## Negative space — probe families that found NOTHING

This is evidence, so it is enumerated.

### A. The polarity identity `X·P(θ)·X = e^{iθ}·P(−θ)` (attack family 1)

Verified analytically against the measured stream on every reachable emission site.
In each case I computed the emitted diagonal and the source's intended diagonal and
confirmed they differ by a scalar multiplying the *whole* operator (hence the whole
state, hence global under D2):

| probe | source | emitted | check |
|---|---|---|---|
| `p/p10` | `if(!b) phi(.7)` | `rz(h,−.7)` | `diag(e^{.7i},1)=e^{.7i}diag(1,e^{−.7i})` ✓ |
| `p/p18`, `h/h14` | merge-tail angle φ, both polarities, incl. the `Negated` diamond | `rz(−A); rz(B)` | ✓ (`FiresOnOne` mapping re-derived by hand for all four (`Arm`,`ArmFalse`,`Pred`) × `ArmNegated` combinations) |
| `p/p45` | `if(!b) t=.9; else t=.3; phi(t)` | `rz(−.9); rz(.3)` | ✓ |
| `h/h13` | if/else with **2 gates in one arm, 1 in the other** | `rz(.9); rz(.4); rz(−.3)` | ✓ — and the ONE-bracket-per-group ancilla form `X·P(θ₁)P(θ₂)·X = e^{i(θ₁+θ₂)}P(−(θ₁+θ₂))` matches the rail form `P(−θ₁)P(−θ₂)` exactly up to that same scalar |
| `p/p46` | `if(b){.9;.4} else {.3;.1}` (two angle selects) | `rz(−.3);rz(.9);rz(−.1);rz(.4)` | ✓ |
| `p/p13`, `p/p14` | two angle selects on one rail / angle select + flat region on one rail | ✓ (all gates diagonal ⇒ commute; order irrelevant) |
| `p/p51` | negated rail region ROLLED ×3 in a loop | `rz(−.7)` ×3 | ✓ — K activations give `e^{−iKθ}`, still a scalar on the whole state |
| `p/p94` | two negated regions with a chained Ry between them | `rz(−.7); ry(.2); rz(−.3)` | ✓ — composition: `V₂·Ry·V₁ = e^{−i(θ₁+θ₂)}·U₂·Ry·U₁` |

**I specifically hunted for a context where the phase is NOT global** — i.e. where the
gate stream is itself controlled, parked or replayed — and found none reachable:

* the 4.3 NEST never emits `rz(−θ)` on a rail: a negated rail root declines in the
  classifier AND is re-asked in the emitter (`p/p35`, `p/p36`), and the inner arm
  always rides the `Conj.G` ancilla (`p/p34`, `slice_control_phase_bool_nest`);
* `CondNetwork::Node::NegL/NegR` — the only `cqrt_x`-on-a-control in the tree — is set
  at exactly one site (`SwapRouteEmit.cpp:1993-1994`, the nest's `Conj`), and that is
  the pair the classifier guards; no tree node ever brackets;
* the 7.2 abort PARK (where a "global" phase inside the parked region would become
  relative) is unreachable in combination with a phase region **at all**: `p/p71`,
  `p/p72`, `p/p74`, `p/p75` all decline, and `p/p74` shows the pure-`int` spelling
  declines identically, so this is not a rail restriction;
* the 7.4 `break` (where a quantum-dependent activation count would do the same) is
  fenced by the B3 rule (`p/p41`);
* a specialization CLONE containing a rail region declines
  (`cq specialization: callee contains a quantum primitive`, `p/p61`);
* `cq_invert` is Phase-8 unimplemented for BOTH spellings (`p/p60` and its `int` twin
  `p/p60b` both leave `__cq_invert_begin` unresolved at link) — pre-existing, out of
  scope.

`fneg` on a RUN-TIME angle: verified emitted correctly and in a dominating position
(`p/p42`, `p/p43` with `volatile double` angles — `%2 = fneg double %1` immediately
before `cqrt_rz_i1(%h, double %2)`). The angle-taint fence (Rule 3) still refuses a
quantum-derived angle BEFORE any emission (`h/h07` → `rotation angle`, `p/p17` →
`control flow`). Tail-φ incomings cannot be defined in an arm: `collectArm` requires
`BB->size() == N + 1` with only phase calls, so the `fneg`'s operand always dominates
`BI` structurally.

### B. The uncompute spine (attack family 2)

I could not make the spine (a) cancel the phase, (b) free the register dirty,
(c) double-free, or (d) leak a borrowed template rail.

* rail DEAD after the region (`p/p01`, `h/h06`): rail left ALLOCATED, `0 cqrt_free` —
  the Rule-6 safe direction, and exactly what the `!cq.branchphase` membership is for.
  No `cqrt_ry_i1(h, −θ)` twin anywhere.
* rail MEASURED after (`p/p02`, `p/p22`), rail measured with a chained parent
  (`p/p11`, `p/p12`).
* rail read as DATA after the phase (`p/p04`): `zext(h0)->h2`, `add`, then
  `zext_unc(h2,h0)`, `free(h2)`; `h0` untouched and unfreed. Correct Bennett
  uncompute of the copy, `h0` never dirty-freed.
* rail borrowed by an out-of-place in-place-shaped op (`h/h03`, `xor i1 %b, true`):
  lowered OUT of place to `cq_template_xor_i1_hl(h, true)` so `%b` is not stale;
  phase correct.
* rail feeding a later region's condition (`p/p05`, `p/p13`, `p/p14`, `p/p93`,
  `p/p94`): all gates diagonal, order preserved, no interference.
* condition-tree ancillas: every network probe frees every ancilla at a proven `|0⟩`
  and strips LIFO (`p/p23` AND, `p/p24` OR, `p/p25` two rails, `p/p26` XOR, `p/p27`
  the De-Morgan'd `!b && q==5` with the `cqrt_x` on the ANCILLA root,
  `h/h32` a SHARED rail subtree feeding two toffolis: 5 mints / 5 verified frees /
  2 left allocated = the two user registers).
* `stripCondNetwork` never strips or frees a rail leaf (rails are not pushed to
  `Out.Leaves`); the post-flatten cascade iterates `Tree.Nodes`/`Tree.Leaves` only, so
  a rail leaf is never erased.

### C. The wire fence (attack family 3)

* chained theta BETWEEN the def and the branch, same block (`p/p08`) and in a
  non-dominating SIBLING block (`h/h01`): both `condition predates a non-diagonal gate`.
* theta reached only through a `select` router before the branch (`h/h02`): declines
  (`CrossValueRouting=true` does its job).
* two aliased rail leaves in one tree (`h/h05`, `%b` and `cq_theta(%b)` xor'd):
  declines.
* chained theta AFTER the region (`p/p07`): ACCEPTS as `ProvenPostRegion`, emitting
  `ry(.5); rz(.7); ry(.2)` — verified this is exactly the source's order.
* in-place `xor` on an i1 rail (`h/h03`): lowered out of place, no staleness.
* the ONE hole is F-1b-1 (template parent).

### D. In-loop (attack family 4) — rolled vs hand-unrolled, byte-identical on 5/5 pairs

`p/p32` (invariant rail + carried register), `p/p50` (ITERATION-LOCAL rail minted per
trip), `p/p51` (negated rail), `p/p52` (two rails), `p/p53` (rail region + compare
region in one body), `p/p90` (rail∧compare TREE per trip — every per-trip ancilla
minted and freed, no O(K) leak), `p/p91` (preheader in-place `add` on the carried
register — the F3 class). Every rolled trace `diff`s empty against its hand-unrolled
twin. `p/p50`'s K leaked iteration-local rails are present identically in the
unrolled twin (the user minted K registers and never measured them) — Rule-6 safe
direction, not an increment artefact.

### E. Rule 1, no third path (attack family 9)

No probe produced an `opt` exit 0 with a surviving `@cq_theta_*`/`@cq_phi`/
`@cq_measure_*` call or a surviving tainted `br i1` (my harness greps for exactly
that). Every non-phase arm class on a rail declines loudly and BEFORE any emission:
value arm (`h/h10`), in-place Ry arm (`h/h12`), empty arm (`h/h11`), `return` arm
(`h/h15`), store arm (`h/h16`), classical-call arm (`p/p96`), data select
(`p/p03`/`p/p33`), Ry-stem angle select (`control_angle_select_reject_rail_ry.ll`).
The three re-ask/drift guards (`emitPhaseKickbackRegion`'s
`(R.ShareCondFlag && !Cond)`, the nest emitter's negated-rail re-ask,
`SelectMergeEmit`'s `!Tree.RailLeaves.empty()`) are all positioned before the first
emission; `R.ShareCondFlag` is structurally unreachable for a rail
(`HasDataUse` is computed only `if (!IsTree && Cmp)`).

I also enumerated every `collectCondTree` caller — the return value changed from
"`Leaves` non-empty" to "either kind non-empty", so each had to decide on
`RailLeaves`. All seven do: `classifyPhaseKickback`, `classifyPhaseKickbackNest`,
`classifySelectRegion`, `SelectMergeEmit`, `Specialization::lowerCloneSelect`
(skips), `emitPhaseKickbackRegion`, `emitPhaseKickbackNestRegion`.
`Specialization::mintCondNetwork` — the third, un-lifted copy of the network — is
reached only through `lowerCloneSelect`, which now skips rail trees, so it cannot see
a rail leaf.

### F. Regression: the `emitKickbackGroup` refactor is byte-neutral

`main` binary vs branch binary over all **1707** `.ll` fixtures in `main`'s tree
(stdout + stderr + exit code):

```
1707 fixtures: 1 RCDIFF, 2 DIAGDIFF, 1 OUTDIFF
  control_inplace_ry_reject_raw_i1_cond.ll  [DIAGDIFF]  1 -> 1
  control_phase_kickback_reject_bare_i1.ll  [RCDIFF,DIAGDIFF,OUTDIFF]  1 -> 0
```

Both are intended and both are covered: the first is the string move
`control flow` → `bare i1 register condition`, and the branch's copy of that fixture
IS updated (it passes); the second is the capability itself, and the branch DELETES
that file in favour of the 17 new accepts. **Zero other fixtures move in any of the
three channels** — so the refactor that replaced the two inline arm loops and the
tail-φ loop with `emitKickbackGroup` + `phaseAngles` emits the identical stream on
every pre-existing shape. `git status --porcelain tests/` is empty (no golden churn);
the 10 new `phase-bool` ctest entries pass.

---

## Owner questions

* **OQ-1b-R1-1.** F-1b-1's fix: rail-local positional prong (cheap, closes the
  same-block half, needs a decision on the cross-block accept
  `control_phase_kickback_rail_cross_block.ll`) versus the shared-walker widening
  (principled, closes both halves *and* the pre-existing compare half, but is a
  Rule-13-core edit to `WireWalk` with many callers). I recommend the shared-walker
  widening with a full-corpus before/after diff, plus the rail-local prong as the
  tripwire — the round-3 `eqpx` precedent, where the narrow re-ask is what made "the
  tripwire is the safety" a measured fact rather than a hope.
* **OQ-1b-R1-2.** The pre-existing compare-side half of F-1b-1 (`p/p81`, `h/h25`:
  identical accept and identical output on `main`) should get its own bd id rather
  than riding this increment.
* **OQ-1b-R1-3.** F-1b-2: fence `railMeasuredBeforeBranch` properly, or correct the
  header and commit `p/p20` as a documented ACCEPT control? Note the compare path is
  weaker (`p/p30`) and would then be the outlier.
