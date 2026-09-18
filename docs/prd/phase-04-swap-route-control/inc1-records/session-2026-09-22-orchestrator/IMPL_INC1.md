# Increment 1 — THE VALUE ARM'S CLASSICAL CONE (bd `test_C_libtooling-fn1q`)

**One line:** a tainted-condition VALUE arm may now hold the pure classical
computation that feeds its chain link's classical operand; `classifyArms` proves
the cone and RECORDS it, `emitValueRegion` hoists it into the pred ahead of the
chain, and the emitted stream is byte-identical to the twin whose cone was
already there.

## 0. Why this is the first increment, and not the one the bead names

`MEASUREMENT.md` is the evidence. In short: the bead's "Va — the array-valued
THRESHOLD declines" is **false** (it accepts, 120 lowered lines), and its
"hand-unroll either and it COMPILES" proves nothing — `-O1` const-folds
`int p[]={3,2,1}` at a now-constant index and if-converts the whole thing, so the
unrolled source presents a `select` shape that was already supported. The real
axis is **`br` vs `select`, and `-O1` picks it**. Every accepting neighbour in this
family accepts because `-O1` if-converted the arm; every decline is `-O1` refusing
to (a non-speculatable load, or too many merge φ for its speculation budget).

The owner's program sits behind FOUR fences. This increment is the one that is
**loop-free, self-contained and reachable from plain C on its own**:
`if (q > 5) p += (k*3 + 7) ^ 5;` declined `impure value arm` with no loop in sight.

## 1. The change, in four places

| file | change |
|---|---|
| `ArmClassify.cpp` | `valueArmIsPureChain` gains an out-parameter and admits a non-chain arm instruction as a CONE member under five conjuncts (K1)–(K5); everything else is still a stray. |
| `ArmClassify.cpp` (call site) | the proven cone is RECORDED on the region (`ShadowCone`/`ShadowConeFalse`) — the emitter re-derives nothing (L1 / Rule 14). |
| `SwapRouteEmit.cpp` | `emitValueRegion` asks the SAME speculation predicate over the cone, hoists it ahead of the chain, and records it in `taint.ValueArmConeOps`. |
| `ArmClassify.cpp` + `CQLoweringPass.cpp` | `declineRound2TaintedArmCone`, the FOURTH re-ask in the post-fixpoint slot. |
| `ControlDetect.cpp` | the `CQ_CTRL_BT` site lever (env-gated, byte-neutral) — not part of the lowering, but it is what made the four fences measurable instead of guessed. |
| `SwapRouteEmit.cpp` (comments) | the F-2 re-proof of the cross-region select pre-flight, whose measured claim this increment falsified, and the F-3 correction to `emitValueRegion`'s header. |

### The five conjuncts

* **(K1) UNTAINTED.** A tainted stray is a quantum value the chain does not
  thread. It also makes the cone strictly independent of the chain — which is
  what licenses hoisting the cone FIRST — and that deduction is asked directly as
  a separate operand test rather than inherited from the taint stage's
  completeness (L1).
* **(K2) NO WRITE, NO SIDE EFFECT.** A write-arm belongs to the 7.5 guarded-store
  owner. It is also what makes (K4)'s memory argument true.
* **(K3) EVERY USER INSIDE THE ARM.** ⚠ **Defensive, and it has no fixture.** For
  every shape `recoverRegion` admits, an arm dominates nothing but itself, so a
  use outside the arm can only be a merge φ — and a second merge φ is refused by
  `soleMergePhi` before this helper is reached. MEASURED unreachable at the
  mutation matrix. Kept because the containment rests on a DIFFERENT stage's
  property; retirement trigger in the source.
* **(K4) `isSafeToSpeculativelyExecute`.** The hoist runs the op
  UNCONDITIONALLY, and that is not a choice — the condition is quantum, so the
  emitted circuit has no classical branch to hide behind. It is the SAME call
  `emitValueRegion`'s existing speculation-totality fence makes on the chain, in
  its NO-CONTEXT form in both places so the two cannot disagree.
* **(K5) NOT A CALL THE LOWERING OWNS.** ⚠ **Added by Rule-13 round 1 (F-1),
  which MEASURED the hole the other four left.** Before the increment, CQ's own
  front-end calls were kept out of a value arm **STRUCTURALLY** — any non-chain
  arm op declined — so no predicate had to name them; (K1)–(K4) replaced that
  structure and **none of them did**. A `declare void @cq_phi(double)` carrying
  `speculatable memory(none) nounwind willreturn` passed all four, was hoisted
  into the pred where it is uncontrolled, and `deleteGlobalPhases` **deleted** it:
  exit 0, no `cqrt_rz_i1` anywhere. Same for `cq_measure` (taint stops at the
  sink, so (K1) cannot see it) and the invert brackets. Asked as the question it
  means — *does a CQ stage OWN this call?*, answered by **declared external vs
  `@llvm.*` intrinsic** — never by a name prefix, which is the bd `11qv` round-4
  (P4) lesson verbatim. ⚠ (K1) independently covers `cq_theta` and `cq_invert_*`;
  (K5) is the **sole** fence only for `cq_phi`, `cq_measure` and the brackets.

  **THE STANDING LESSON: when you replace a STRUCTURAL containment with a set of
  predicates, enumerate what the structure was holding.** Nothing in the corpus
  moved when (K5) landed, and no C program reaches the hole — but hand-written
  `.ll` is this tree's primary fixture surface.

### The hazard `isSafeToSpeculativelyExecute` does NOT cover

A hoisted LOAD is sound only if nothing between the hoist point and the load's old
position can WRITE the location. That holds **by construction, not by analysis**:
the only instructions on that path are the region's `br`, the arm's other cone
members ((K2): no writes) and its chain links (`walkValueChain` admits only
`BinaryOperator`s). ⚠ If either fact changes, the argument must be REBUILT, not
re-quoted.

## 2. The L1 finding on this increment's own design, and its fence

(K1) is asked inside `detectControlRegions`, i.e. at **round-1 taint**.
`repropagateControlMerges` re-seeds taint from the 6.5/4.5 merge `%out` rails, so
a cone member that reads such a merge φ is untainted at round 1 and **tainted
after the fixpoint** — leaving a region already hoisted, merged and FLATTENED on
the premise that its chain link was Q+C, while `lowerOps` at final taint would see
a **Q+Q** link. Q+Q in a value arm is a shape `classifyArms` DEFERS by design
(`Chain.HasQQ`), so round 1 would be shipping an unreviewed widening of exactly
the class the Prime Directive refuses to widen silently.

Cured the way L1 prescribes: RECORD at the site that mutates
(`taint.ValueArmConeOps`, written by the emitter's hoist — a classified-then-
declined region mutates nothing and owes nothing), RE-ASK after the fixpoint in
BOTH entry points (`declineRound2TaintedArmCone`), decline loudly.

⚠ **IT IS REACHABLE, AND THIS PARAGRAPH FIRST SAID IT WAS NOT.** The construction
was argued here and *not* exhibited; **Rule-13 round 1 (attack D) built it** —
`control_swap_value_reject_arm_cone_round2_quantum.ll` — and confirmed by
backtrace that `declineRound2TaintedArmCone` is the predicate that fires.

**Why the implementer's probes missed it, which is the transferable part:** the
probe needs a BLOCK BETWEEN the 6.5 merge and the value region's branch. Without
one the pair declines earlier, at `lowerControlRegions`' `reorderable` precedence
check (bd `test_C_libtooling-35t0`) — and that earlier decline reads exactly like
"the shape does not occur". **A probe that reaches the wrong fence first measures
the wrong fence.** The correction is applied at the source
(`TaintSet::ValueArmConeOps`) in the same change, because a record correction that
is not applied to the source is not a correction (L7).

## 3. What this increment does NOT do

* It does not touch `MergePhiPeel` P9 (the no-in-loop-peel gate), so an **in-loop**
  value arm still declines. That is increment 2 and it carries P9's own written
  `BreakRegions` dangling-φ obligation.
* It does not touch `walkValueChain`'s EMPTY-chain path (`ArmClassify.cpp:6193`),
  so a value arm whose merged value is a CLASSICAL accumulator still declines
  `value-arm swap-route`.
* It does not touch `SwitchArmProve.cpp`'s re-derived mirror of the stray rule.
  The switch path keeps the stricter rule — the safe direction — and a widening
  there is its own increment. ⚠ Rule 14 says one spelling; there are TWO today,
  and this increment moved only one of them. That is a debt, filed.
* It does not make the owner's `example/grover/grover_oracle_uncompute.c` compile.
