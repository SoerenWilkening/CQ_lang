// RegionFlatten.cpp — see header. CFG flatten for one swap-route region: after
// `SwapRouteEmit` has emitted the routed stream into the pred and rewired the
// data, collapse the dead diamond/if-else CFG into the single pred block.
//
// Block identities are captured BEFORE the first erase (the block-lifetime
// hazard — a `BasicBlock*` re-read through freed memory is a SIGSEGV on valid
// input). Erase order is deliberate: the conditional `br` first (so the arms go
// unreachable and the condition compare goes dead), then splice the merge's
// surviving instructions into the pred, then the dead arms before the emptied
// merge (an arm's `br label %merge` is the last reference to the merge block).

#include "RegionFlatten.h"

#include "ControlPlan.h"
#include "TaintPropagation.h"

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// so a later module walk (`lowerRotations` / `lowerOps` / `uncompute`) never
// dereferences freed memory (§6.1). A per-TU mirror of the same helper in
// SwapRouteEmit (the house style for trivial taint-set maintenance). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
  }
}

}  // namespace

void flattenRegion(const ControlRegion &R, TaintSet &taint) {
  // Capture identities before any erase.
  BasicBlock *Pred = R.Pred;
  BasicBlock *Arm = R.Arm;
  BasicBlock *ArmFalse = R.ArmFalse;  // null for a diamond
  BasicBlock *Merge = R.MergeBB;
  if (!Pred || !Merge)
    return;
  auto *BI = dyn_cast<BranchInst>(Pred->getTerminator());
  auto *Cond = dyn_cast_or_null<Instruction>(R.Condition);

  // 1. Drop the conditional branch — control is now straight-line. This leaves
  //    Pred terminator-less for exactly the next statement (no verify runs in
  //    between), and makes the arms unreachable + the condition compare dead.
  //    Scrub it first: the `br i1` is a USER of the tainted condition, so
  //    TaintPropagation put it in taint.Tainted — erasing without scrubbing
  //    leaves a dangling Instruction* whose heap address a later-minted
  //    instruction could reuse, turning membership probes into false taint
  //    (§6.1 hygiene; §8 adversarial review 2026-06-10).
  if (BI) {
    scrubTaint(BI, taint);
    BI->eraseFromParent();
  }

  // 2. Splice the merge block's surviving instructions (the measure / ret that
  //    consumed the RAUW'd phi — the phi itself was already erased upstream)
  //    onto the end of Pred. Pred's terminator becomes the merge's `ret`.
  Pred->splice(Pred->end(), Merge);

  // 3. The condition compare fed only the now-erased branch; erase it dead and
  //    scrub it from the taint set (the condition was tainted). Guard on
  //    use_empty so a (malformed) compare with a stray live use is left for the
  //    verifier rather than silently dropped.
  if (Cond && Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }

  // 4. Delete the now-unreachable arm block(s), then the emptied merge block.
  if (Arm)
    Arm->eraseFromParent();
  if (ArmFalse)
    ArmFalse->eraseFromParent();
  Merge->eraseFromParent();
}

}  // namespace cq
