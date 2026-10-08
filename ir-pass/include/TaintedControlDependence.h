// TaintedControlDependence.h — "does `I` run only on some outcomes of a TAINTED
// branch?", asked as TRUE control dependence (bd test_C_libtooling-r2j3.6, review
// round 2 R2-3), and the shared spelling of "this terminator is a tainted branch".
//
// WHY A SECOND "UNDER TAINTED CONTROL" BESIDE `instUnderTaintedControl`
// (QramLowering.h). That one asks "is `I` dominated by a tainted-branch block it
// does not post-dominate", which OVER-APPROXIMATES control dependence: a block after
// a tainted region's merge, inside an unrelated CLASSICAL `if`, is dominated by the
// tainted branch and does not post-dominate it, yet it is not controlled by it
// (review probe p4_prior_phase_sibling: `if (c > 3) cq_phi(.2);` before the classical
// sibling-arm shape made that shape decline). Its customers — the QRAM carve, the
// loop hand-off (bd wt8u), the stale sweep's 01po.7 grant — are left on it, because
// correcting it would move their verdicts and that has NOT been measured (in either
// direction: for the loop hand-off a false "under control" restores the whole-
// function rail, LoopLowering.cpp, so the over-approximation is not simply the
// decline side there). r2j3.6 follow-up F9 is that measurement. The lifted-call
// stale policy (OpcodeLowering.cpp) GRANTS on the "not under tainted control" side,
// so it asks the exact answer: the iterated post-dominance frontier of `I`'s block
// (LLVM's `ReverseIDFCalculator`, the standard construction of transitive control
// dependence) contains a block whose terminator is a tainted branch.

#ifndef CQ_IRPASS_TAINTED_CONTROL_DEPENDENCE_H_
#define CQ_IRPASS_TAINTED_CONTROL_DEPENDENCE_H_

namespace llvm {
class Instruction;
class PostDominatorTree;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Is `T` a conditional `br` or a `switch` on a TAINTED condition? Moved here verbatim
// from LoopLowering.cpp (bd r2j3.6 review rounds 3-4): `controlDependsOnTaintedBranch`
// below, `instUnderTaintedControl` (QramLowering.cpp) and LoopLowering's `tryCaseA`
// gate L2, wt8u hand-off and break-exit count (the former `isTaintedExitingTerminator`)
// ask it. ⚠ NOT YET THE ONLY SPELLING: identical bodies remain as
// `isTaintedCtrlTerm` (PredMuxFlatten.cpp) and `isTaintedControlTerminator`
// (ReturnMerge.cpp); consolidating them is an r2j3.6 follow-up.
bool isTaintedBranchTerminator(const llvm::Instruction *T, const TaintSet &taint);

// True iff `I`'s block is (transitively) control-dependent on a terminator for which
// `isTaintedBranchTerminator` holds. `PDT` is `I`'s function's.
bool controlDependsOnTaintedBranch(const llvm::Instruction &I,
                                   const TaintSet &taint,
                                   llvm::PostDominatorTree &PDT);

}  // namespace cq

#endif  // CQ_IRPASS_TAINTED_CONTROL_DEPENDENCE_H_
