// CFGLinearization.cpp — see header. Collapses `Pred -[br i1]-> {Arm, Merge}`,
// `Arm -[br]-> Merge` into the single block `Pred`, in collection-before-
// mutation order (§1.6):
//
//   1. Snapshot the splice boundary: the first instruction of the merge block
//      (downstream's uncompute insertion point).
//   2. Drop `Pred`'s `br i1` terminator (no `br i32` is ever synthesized).
//   3. Splice the arm's body (everything before its unconditional terminator)
//      onto the end of `Pred`, then drop the arm's terminator.
//   4. Splice the merge block's body onto the end of `Pred`.
//   5. Erase the now-empty arm and merge blocks, then the dead `icmp` last.
//
// The merge `φ` MUST already be dissolved (MergeDissolution) so no use dangles
// when the blocks are folded.

#include "CFGLinearization.h"

#include "ControlPlan.h"

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

Instruction *linearizeRegion(ControlRegion &region) {
  BasicBlock *Pred = region.Pred;
  BasicBlock *Arm = region.Arm;
  BasicBlock *Merge = region.MergeBB;
  if (!Pred || !Arm || !Merge)
    return nullptr;

  auto *PredBr = dyn_cast<BranchInst>(Pred->getTerminator());
  auto *ArmBr = dyn_cast<BranchInst>(Arm->getTerminator());
  if (!PredBr || !PredBr->isConditional() || !ArmBr || ArmBr->isConditional())
    return nullptr;

  // (1) Boundary = the merge block's first instruction (post-dissolution this
  // is its `ret`/whatever followed the φ). The flag uncompute lands here.
  Instruction *Boundary = &Merge->front();

  // (2) Drop the conditional branch. `Pred` is now terminator-less; we refill
  // it by splicing. No `br i32` (or any branch) is created (§1.1).
  PredBr->eraseFromParent();

  // (3) Splice the arm BODY (all but its terminator) to the end of `Pred`,
  // then erase the arm's now-orphaned terminator. `BasicBlock::splice` moves
  // the instruction sublist in place — preserving order and SSA defs.
  Pred->splice(Pred->end(), Arm, Arm->begin(), ArmBr->getIterator());
  ArmBr->eraseFromParent();

  // (4) Splice the entire merge block (its body + terminator) to the end of
  // `Pred`. `Boundary` rides along — still valid as an insertion anchor.
  Pred->splice(Pred->end(), Merge, Merge->begin(), Merge->end());

  // (5) Erase the drained blocks, then the dead condition `icmp` LAST (it has
  // no users now: the `br i1` is gone, and the flag was minted as a separate
  // template call). Erasing the icmp before its `br i1` user would dangle.
  Arm->eraseFromParent();
  Merge->eraseFromParent();
  if (auto *Cond = dyn_cast_or_null<Instruction>(region.Condition))
    if (Cond->use_empty())
      Cond->eraseFromParent();

  return Boundary;
}

}  // namespace cq
