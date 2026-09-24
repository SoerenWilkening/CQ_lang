// GuardedClassicalRead.h — bd xdu2.8: a CLASSICAL runtime-VLA read under
// quantum control whose in-bounds proof holds only under a CLASSICAL conjunct of
// the arm's own path condition.
//
// THE SHAPE. `int p[m]; for (i<n) if (q && m == n) { a += p[i]; z -= p[i]; }`
// with `q` quantum. PredMux's E4 speculates the arm's load to the region entry,
// where `m == n` is NOT in force, so `classicalRuntimeAllocaReadIsInBounds`
// (asked at the hoist point) correctly refuses: flattening would read `p[i]` out
// of bounds on the path the source never reads it — an INTRODUCED out-of-bounds
// read. That refusal is safe and it is an OVER-DECLINE (owner ruling 2026-09-11):
// the program is valid and the circuit is realizable.
//
// TWO SEPARATE OBLIGATIONS, TWO SEPARATE ANSWERS.
//
//  (A) ADMISSION — "is the SOURCE's read defined wherever the source performs
//      it?" Some classical conjunct F of the arm's path condition (an and/or/
//      select/not tree of a branch condition INSIDE the region, whose taken edge
//      DOMINATES the load) must prove the index in bounds by itself: the loop's
//      exact trip count ≤ the extent (F is `trips == extent`, or `extent ≥ trips`
//      through a common zext chain), or the index < the extent directly. A read
//      with no such F still declines (`E4-load`/`E4-gep`, unchanged): a quantum
//      arm whose read is out of bounds on some basis state is source UB on that
//      branch, and compiling it would be a silent garbage answer.
//
//  (B) EMISSION — "is the SPECULATED read defined on EVERY path?" Made true BY
//      CONSTRUCTION, independent of F, so no poison/undef reasoning about F is
//      needed:
//          %fi = freeze %idx ; %fe = freeze %extent
//          %ok = icmp ult %fi, %fe
//          %p  = select i1 %ok, ptr (gep T, %base, %fi), ptr @cq.guarded.read.zero
//          %v  = load T, ptr %p
//      The address is in the allocation (proved LIVE at the hoist point by the
//      shared shape half) or a private zero constant. Where the source's arm runs,
//      (A) gives `idx < extent`, so `%ok` is true and `%v` is the source's value
//      (E4 forbids any store in the region). Where it does not run, `%v` feeds
//      only the speculated arm arithmetic whose result the flatten's merge select
//      discards — PredMux's ordinary speculation argument, unchanged.
//
// No measurement, no qubit, no new runtime symbol: every inserted instruction is
// classical, and the loaded value keeps occupying the `_hl` literal slot.
//
// ⚠ RESIDUAL, ARGUED NOT CONSTRUCTED: `freeze %extent` is only the allocation's
// size if the alloca's own size operand was not poison. A poison VLA size is the
// source's own UB (C11 6.7.6.2p5) and the pre-existing unguarded proof
// (`classicalRuntimeAllocaReadIsInBounds`) relies on the same value through SCEV.
#ifndef CQ_GUARDED_CLASSICAL_READ_H
#define CQ_GUARDED_CLASSICAL_READ_H

#include "llvm/ADT/SmallPtrSet.h"

namespace llvm {
class BasicBlock;
class DominatorTree;
class LoadInst;
class LoopInfo;
class ScalarEvolution;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Obligation (A). Pure analysis, no mutation. True iff `LI` is a runtime-VLA read
// (the shape half of `classicalRuntimeAllocaReadIsInBounds`, CALLED, not
// re-derived), carries no value metadata a zero could violate, and some classical
// conjunct of its path condition inside `Region` proves its index in bounds.
bool classicalRuntimeAllocaReadIsInBoundsUnderGuard(
    llvm::LoadInst *LI, const TaintSet &Taint, llvm::DominatorTree &DT,
    llvm::LoopInfo &LInfo, llvm::ScalarEvolution &SE,
    const llvm::SmallPtrSetImpl<llvm::BasicBlock *> &Region,
    llvm::BasicBlock *Entry);

// Obligation (B). The mutation, run by the flatten AFTER `LI` has been moved to
// the region entry. Rewrites `LI`'s address to the bounds-checked select above and
// returns the replaced address (the old gep, now possibly dead) so the caller can
// hand it to its dead sweep. Fatal (never silent) if the load no longer has the
// shape (A) proved.
llvm::Value *guardSpeculatedClassicalRead(llvm::LoadInst *LI);

}  // namespace cq

#endif  // CQ_GUARDED_CLASSICAL_READ_H
