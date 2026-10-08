// TaintedControlDependence.cpp — see TaintedControlDependence.h (bd r2j3.6, R2-3,
// R3-3(d)).

#include "TaintedControlDependence.h"

#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/IteratedDominanceFrontier.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

bool isTaintedBranchTerminator(const Instruction *T, const TaintSet &taint) {
  if (const auto *BI = dyn_cast<BranchInst>(T))
    return BI->isConditional() &&
           taint.Tainted.count(const_cast<Value *>(BI->getCondition()));
  if (const auto *SI = dyn_cast<SwitchInst>(T))
    return taint.Tainted.count(const_cast<Value *>(SI->getCondition())) != 0;
  return false;
}

bool controlDependsOnTaintedBranch(const Instruction &I, const TaintSet &taint,
                                   PostDominatorTree &PDT) {
  BasicBlock *BB = const_cast<BasicBlock *>(I.getParent());
  // The post-dominance frontier of a block is the set of branches it is control-
  // dependent on; iterating it closes over transitive dependence (a classical `if`
  // nested in a tainted arm is controlled by the tainted branch too).
  ReverseIDFCalculator IDF(PDT);
  SmallPtrSet<BasicBlock *, 1> Def;
  Def.insert(BB);
  IDF.setDefiningBlocks(Def);
  SmallVector<BasicBlock *, 8> Controllers;
  IDF.calculate(Controllers);
  for (BasicBlock *B : Controllers)
    if (isTaintedBranchTerminator(B->getTerminator(), taint))
      return true;
  return false;
}

}  // namespace cq
