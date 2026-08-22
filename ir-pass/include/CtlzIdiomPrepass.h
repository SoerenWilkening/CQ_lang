// CtlzIdiomPrepass.h — bd ww4c Increment 1: the shift-count loop -> `llvm.ctlz`
// idiom recognizer. Design of record:
// docs/prd/phase-07-expressiveness/PRD-ww4c-ctlz-idiom.md.
//
// A classical IR-to-IR canonicalization, NOT a gate emitter — the same category
// as the shipped `LoopUnrollPrepass` and as stock LLVM's own
// `LoopIdiomRecognize`, which fires on a NEIGHBOURING spelling of this very
// idiom (measured, bd ww4c: openlibm's `for (…; hx > 0; hx <<= 1)` produces no
// ctlz at -O1, -O2 or -O3, while LLVM's `while (x != 0)` produces one at all
// three). Licensed as INJECTION coverage by the owner ruling of 2026-08-22 —
// "yes, it counts as injection coverage — the body stays openlibm's" — because
// Rule 18's axis is WHOSE SOURCE, and structurally rewriting theirs is what
// compilation is.
//
// WHAT IT SUBSTITUTES. For the rotated `-O1` do-while
//     do { c--; x <<= 1; } while ((signed)x > 0)
// on iN (N a power of two) with preheader entry value v, the number of body
// executions is
//     f(v) = 1 + (ctlz_N(v << 1) & (N-1))          exact on the WHOLE domain
// so the escaping counter is
//     c_exit = (C0 - 1) - (ctlz_N(v << 1) & (N-1))
// which is four ops: shl -> ctlz -> and -> sub. DERIVED (PRD §4.1) and verified
// EXHAUSTIVELY over all 2^32 i32 inputs with simulation as the oracle, 0
// mismatches; the i64 row rests on the width-generic proof plus boundary and
// randomized checks and is NOT claimed as exhaustive.
//
// DO NOT "simplify" this back to LLVM's canonical `icmp eq` + `ctlz(x, i1 true)`
// + `sub N, z` + `select`. That repairs the `x != 0` idiom, whose closed form is
// N-cttz-shaped — a DIFFERENT function. For the `sgt 0` idiom the zero repair is
// the MASK (ctlz(0) = N and N & (N-1) = 0), which is why no select, no flag
// mint, no controlled copy and no `cqrt_free` appear anywhere in this file.
//
// THREE EMISSION RULES THAT ARE NOT OPTIONAL (PRD §4.5):
//   1. `is_zero_poison` MUST be the literal `i1 false`. PoisonFacts.cpp:27-38
//      (`curatedIntrinsicCanBePoison`) returns `!Flag || !Flag->isZero()`, so
//      PredMuxFlatten:174-207 accepts a cone containing ctlz/cttz/abs ONLY when
//      the immarg is a ConstantInt ZERO — and LLVM's canonical form emits
//      `i1 true`. Copying it verbatim DECLINES the very cell this pass exists to
//      unblock. (The VALUE is honest either way: intrinsic_table.yaml:33-38
//      drops the immarg and lowers the TOTAL function.)
//   2. NO `nsw`/`nuw`/`exact` on anything emitted — they are poison-generating
//      annotations PredMux would have to neutralise, and the closed form wants
//      wrapping semantics anyway (the 2^32 oracle used them).
//   3. The `and` mask is N-1 taken from the shift recurrence's OWN TYPE, never a
//      literal 31. A width-hardcoded mask is a silent miscompile at every other
//      width.
//
// ZERO NEW FROZEN SYMBOLS. The four emitted ops lower to
// cq_template_{shl_i<N>_hl, ctlz_i<N>, and_i<N>_hl, sub_i<N>_lh} and all four
// `_unc` twins, every one of which already links (`nm -g` on
// build/runtime/libcq_templates.a). No opcode_table.yaml / intrinsic_table.yaml
// edit, no regeneration, Phase-11 freeze surface untouched (Rule 15).
//
// ACCEPT-ONLY, and this is where the analogy to `LoopUnrollPrepass` BREAKS.
// Both are accept-only: an off-fence loop is left byte-untouched and keeps its
// existing loud owner, and neither pass ever diagnoses, so neither can turn an
// accept into a decline. But `LoopUnrollPrepass`'s fence is DISJOINT from the
// rolled-in-place owners by construction (U2/U4/U5 exclude their whole
// vocabulary), whereas THIS PASS AND `tryCaseA`'s Q1 COMPETE FOR THE SAME LOOPS:
// Q1 fires on a tainted exiting condition, which every loop here HAS. So the
// failure mode of this pass is not a wrong decline — it is a WRONG CLAIM, and
// Z1-Z9 have to be airtight rather than merely disjoint.
//
// THE HONESTY OBLIGATION THE RULING CARRIES (PRD §1.1) IS DISCHARGED BY
// CONSTRUCTION, NOT BY ASSERTION. If the fence were tuned until `ilogb`'s
// spellings fell inside it, that would be per-function recognition in a
// structural costume — invisible in the census number and visible only here.
// So Z1-Z9 below mention no function name, no libm source, no seed constant and
// no width the targets happen to use, and the fixture matrix contains BOTH
// directions: shapes that ARE the idiom and are NOT `ilogb`
// (lowering_ctlz_idiom_{i64,generic_seed,narrow_widths}.ll) which must ACCEPT,
// and shapes that RESEMBLE `ilogb` and are NOT the idiom — above all the f80
// mask-shift of `ilogbl`/`logbl` — which must DECLINE. A landing that accepted
// only the three target loops would have failed the obligation with every test
// green.

#ifndef CQ_IRPASS_CTLZIDIOMPREPASS_H
#define CQ_IRPASS_CTLZIDIOMPREPASS_H

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Rewrites AT MOST ONE fence-passing loop per call (so every claim sees fresh
// dominance/taint/LoopInfo state — the flattenPredMuxRegions idiom) and returns
// true iff it mutated the module. Drive to fixpoint with
//   while (recognizeCtlzIdiomLoops(M, taint)) { taint = propagate(…); … }
// The claim MINTS new tainted SSA and ERASES the loop's, so `taint` is STALE
// (dangling entries + missing new ones) after a true return until the caller
// re-propagates. That staleness is not incidental: the rewrite converts a
// CONTROL dependence into a DATA dependence — bd 19v3 §4b measured that the one
// value escaping each of these loops has no `@cq_theta` in its cone and is
// quantum only by virtue of control flow, which Rule 3 does not track. After the
// rewrite it is a tainted `sub`. That is the mechanism, stated plainly: it is
// the reason the cell lowers at all.
//
// The fence (ALL must hold; each failure = silent skip to the existing owner):
//   Z1 TOP-LEVEL innermost loop (no parent loop — a nested one buys no target
//      coverage and opens an unreviewed interaction class), exactly ONE block,
//      which is simultaneously the header,
//      the sole latch and the sole exiting block (a rotated do-while), with a
//      unique OUT-OF-LOOP PREDECESSOR and a unique exit block, and a conditional
//      `br` whose two successors are exactly {header, exit}. PRD §4.1 derives f
//      for THIS control shape; any other has a different closed form or none,
//      and the "body always runs at least once" premise is exactly do-while
//      rotation.
//      Read "unique out-of-loop predecessor", NOT "dedicated preheader", and the
//      difference is load-bearing: measured at -O1, the guarded target loop
//      `s_ilogb.c:40` HAS NO PREHEADER — its guard block ends in a two-way `br`
//      whose other edge runs straight to the return merge. Requiring
//      loop-simplify form would decline one of the three cells this pass exists
//      to reach (Rule 17's exact failure mode), and manufacturing a preheader
//      with `simplifyLoop` would mutate loops the fence then rejects, breaking
//      the accept-only contract. Nothing is inserted into that block anyway.
//   Z2 the header carries EXACTLY two phis — a shift recurrence and a counter —
//      each with exactly two incomings, from the preheader and from the latch.
//      A third loop-carried value is a value we have no closed form for.
//   Z3 the shift recurrence's latch value is `shl <that phi>, 1`, defined IN the
//      loop: opcode exactly Shl, the phi in operand 0, the amount a ConstantInt
//      exactly 1. `ashr`/`lshr`, non-constant amounts and amounts != 1 decline —
//      `ashr` never terminates toward the sign bit, and stride != 1 has a
//      different closed form (bd 19v3 measured SCEV reporting max-trip 32 for
//      strides 1/2/16/31 whose true maxima are 31/16/2/1, wrong in BOTH
//      directions).
//   Z4 the counter's latch value is `add <that phi>, -1` (commutative operands),
//      defined IN the loop, and its preheader incoming is a ConstantInt C0. Any
//      other step is a different closed form, C0 +- k*f.
//   Z5 the exiting condition is `icmp sgt <the recurrence's OWN latch value>, 0`
//      — the compared operand must BE that value, not one derived from it, the
//      constant exactly 0, and the predicate exactly `sgt` AFTER normalising to
//      the CONTINUE sense (Rule 9: -O1 routinely inverts polarity and swaps
//      successors, so the loop is often the FALSE successor). This is the fence
//      that excludes the f80 mask-shift family AND the termination argument: a
//      value repeatedly shifted left marches monotonically into the sign bit, so
//      f <= N on every input; a value DERIVED from it has no such property, and
//      `ilogbl`'s genuinely diverges when the tested word is 0.
//   Z6 the loop contains NOTHING else — the two phis, the shl, the add, the icmp
//      and the br, six instructions and no seventh. Far stricter than "no side
//      effects", and exactly the measured shape. The trip count is observable
//      through any body instruction that is not one of these six: f executions
//      become zero, so the value would be right and the program wrong.
//   Z7 exactly one value escapes, and it is the COUNTER'S latch value: the shift
//      recurrence, both phis and the compare have no out-of-loop user, and the
//      counter has at least one. An escaping shift register would owe a second
//      closed form (v << f) — deferred, not silently dropped.
//   Z8 the shift recurrence's preheader incoming is TAINTED (mirroring
//      `LoopUnrollPrepass`'s U7). A purely classical loop is not ours to churn,
//      and this is the clause that keeps every existing ctest entry byte-stable.
//   Z9 the recurrence is an integer of a width in the SHIPPED ctlz set
//      {i8,i16,i32,i64} (tools/intrinsic_table.yaml:136), and the counter is at
//      that SAME width. i1/i80/i128, vectors and non-integers decline: the mask
//      needs a power-of-two width AND a generated template at that width, and
//      `nm` confirms ctlz stops at i64 while and/shl/sub run to i128 — a fence
//      keyed on the arithmetic alone would over-accept into a link failure.
//
// Z9's same-width clause is the one place this is NARROWER than PRD §5.: a
// counter at a different width would need a zext/trunc whose own reversibility
// and uncompute story is unreviewed surface, and all three target loops carry
// both at i32. Like PRD §5.2's other narrowings (stride != 1, step != -1,
// non-empty body, escaping shift register, i128/i80) it is an ADDITIVE widening
// owed its own Rule-12/13 round, and it is scope rather than evasion under Rule
// 17 because the target loops sit INSIDE the accept set, not outside it.
bool recognizeCtlzIdiomLoops(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CTLZIDIOMPREPASS_H
