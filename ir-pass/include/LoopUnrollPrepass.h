// LoopUnrollPrepass.h — 3c6m.55 Inc 2 (Lever B, ticket lf8s): static-K
// force-unroll of small PROVEN-constant-trip loops (extends the 8h7d
// "static-K unroll" widening; the X1 kMsgCrossIter fallback LoopPlan.h calls
// "a deferred follow-on").
//
// A classical IR-to-IR canonicalization, NOT a gate emitter (the PredMux
// precedent): a loop whose trip count SCEV proves to be an exact small
// compile-time constant is semantically EQUAL to its straight-line unrolling,
// so replaying the body K times via `llvm::UnrollLoop` turns an
// un-lowerable rolled shape (the openlibm `__polevll` Horner loops — a tainted
// fmuladd accumulator over const coefficient tables, marked
// `!llvm.loop.unroll.disable` so `-O1` keeps them) into the straight-line
// tainted dataflow the shipped substrate already lowers. The unroll UTILITY
// never consults the `unroll.disable` metadata (that is loop-unroll-PASS
// cost-model input), which is exactly why calling it directly overrides
// openlibm's marker.
//
// ACCEPT-ONLY discipline: an off-fence loop is left byte-untouched and keeps
// its existing loud owner (`tryCaseA` X1/L1, ControlDetect, the spec-scan…);
// this pre-pass never diagnoses. The fence is DISJOINT from every loop the
// 799w/y05j rolled-in-place owner claims — see `unrollConstTripLoops` below
// and the gate proof in docs/prd/phase-07-expressiveness/
// PRD-3c6m.55-coshl-transcendental-epic.md (§ Lever B, Inc-2 outcome).

#ifndef CQ_IRPASS_LOOPUNROLLPREPASS_H
#define CQ_IRPASS_LOOPUNROLLPREPASS_H

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Fully unrolls AT MOST ONE fence-passing loop per call (so every claim sees
// fresh dominance/taint/LoopInfo state — the flattenPredMuxRegions idiom) and
// returns true iff it mutated the module. Drive to fixpoint with
// `while (unrollConstTripLoops(M, taint)) taint = propagate(…)`; the unroll
// erases loop phis and clones body instructions, so `taint` is STALE (dangling
// + missing clones) after a true return until the caller re-propagates.
//
// The fence (ALL must hold; each failure = silent skip to the existing owner):
//   U1 innermost loop (an outer const-trip loop is claimed on a later call,
//      after its inner loops have been unrolled away);
//   U2 no `cq_*`/`cqrt_*` call and no indirect/convergent/noduplicate call in
//      the loop (excludes every Case-B/rotation/measure shape — a tainted
//      value minted in-loop IS an in-loop `cq_theta`);
//   U2b no memory allocation, access, or address arithmetic
//      (alloca/load/store/gep/…) with a TAINTED operand in the loop —
//      tainted-index QRAM/Shadow loops stay with the L3 `kMsgQramLoop` owner
//      and a tainted-size alloca with the escape guard (the memory analog of
//      U3, mirroring `markIfIterationLocal`'s L3 walk; the lf8s Rule-13
//      review's confirmed blocking find — without it a const-trip
//      tainted-index loop unrolled into an unreviewed accept, and a DEAD
//      tainted-size alloca rode UnrollLoop's internal DCE past the escape
//      guard). Classical loads (the `@P`/`@Q` coefficient tables) are
//      unaffected;
//   U3 every in-loop terminator is a `br`, and no conditional `br` condition
//      is tainted (tainted in-loop control stays with its ControlDetect/
//      RegionTreeDetect/d8jl owners — mirrors `tryCaseA` L2; the non-`br`
//      exclusion also keeps the claim path residue-free — a switch latch made
//      `UnrollLoop` bail after the simplify/LCSSA mutation);
//   U4 no 799w/dtzb in-place rail structure (`loopHasInPlaceRailStructure`,
//      the SHARED LoopLowering predicate): no tainted header phi peeling
//      in-place to itself (Case-A claim seed) and no tainted in-place-shaped
//      add/xor anywhere in the loop (whose duplication could flip a sibling
//      rail's linear-lineage fan-out count);
//   U5 a single exiting block ending in a conditional `br` on an UNTAINTED
//      condition (excludes Q1 quantum-bounded + y05j break territory
//      structurally, not just via SCEV);
//   U6 SCEV proves an exact constant trip count 1..kMaxUnrollTrip with
//      max-trip == exact-trip (the CompletelyUnroll witness — wrong trip
//      count = wrong program, the Rule-13 core);
//   U7 quantum-relevant: a tainted value inside the loop (the expl-inlined
//      census shape) OR the enclosing function is in the tainted-callee cone
//      (a visible non-`cq_*` callee transitively reached from a call site
//      passing a tainted argument — the Phase-6 spec-candidate shape, so the
//      later clone inherits the unrolled body); a purely-classical loop in
//      neither position is NOT ours to churn;
//   U8 `isSafeToClone`, header address not taken, body ≤ kMaxUnrollBodySize
//      instructions (code-growth fence).
// A fence-passing loop is put in loop-simplify form (`llvm::simplifyLoop`) if
// needed, then `llvm::UnrollLoop(Count = trip, Runtime = false)` replays it;
// only a `FullyUnrolled` result counts as the claim.
bool unrollConstTripLoops(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_LOOPUNROLLPREPASS_H
