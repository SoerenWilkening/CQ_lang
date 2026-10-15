// RailWindowQ.cpp — bd `test_C_libtooling-01po.19` S2: the quantization point
// (moved out of RailWindow.cpp verbatim by S4 review round 1 to keep that file
// under 400 lines). Contract in RailWindow.h.

#include "RailWindow.h"

#include "QramLowering.h"  // railBankInstReaches
#include "TaintPropagation.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

Instruction *ncd(DominatorTree &DT, Instruction *A, Instruction *B) {
  if (A->getParent() == B->getParent())
    return A->comesBefore(B) ? A : B;
  BasicBlock *N = DT.findNearestCommonDominator(A->getParent(), B->getParent());
  if (N == A->getParent())
    return A;
  if (N == B->getParent())
    return B;
  return N->getTerminator();
}

}  // namespace

// S2: the quantization point (null only for an array with no tainted store,
// which the claim already refused).
Instruction *railWindowQuantizationPoint(const RailWindowAccesses &Acc,
                                         const TaintSet &taint,
                                         DominatorTree &DT, LoopInfo &LI) {
  if (Acc.ScopeStart)
    return Acc.ScopeStart;  // F3 (a): re-quantized per iteration.
  Instruction *Q = nullptr;
  for (StoreInst *S : Acc.Stores) {
    if (!taint.Tainted.count(S->getValueOperand()))
      continue;
    Instruction *P = S;
    if (Loop *L = LI.getLoopFor(S->getParent())) {
      L = L->getOutermostLoop();
      if (BasicBlock *PH = L->getLoopPreheader())
        P = PH->getTerminator();
      else if (auto *N = DT.getNode(L->getHeader())->getIDom())
        P = N->getBlock()->getTerminator();
    }
    Q = Q ? ncd(DT, Q, P) : P;
  }
  if (!Q)
    return nullptr;
  SmallVector<Instruction *, 32> All(Acc.Loads.begin(), Acc.Loads.end());
  All.append(Acc.Stores.begin(), Acc.Stores.end());
  // Hoist until Q dominates every access reachable from it AND runs once: a
  // point inside a cycle (LoopInfo's or an irreducible one) moves to its
  // immediate dominator's terminator. The entry block is in no cycle and
  // dominates everything, so this always terminates with a point.
  for (bool Changed = true; Changed;) {
    Changed = false;
    for (Instruction *A : All)
      if (A != Q && !DT.dominates(Q, A) && railBankInstReaches(Q, A)) {
        Q = ncd(DT, Q, A);
        Changed = true;
      }
    if (railBankInstReaches(Q, Q)) {
      auto *N = DT.getNode(Q->getParent())->getIDom();
      Q = N ? N->getBlock()->getTerminator()
            : &*Q->getParent()->getFirstInsertionPt();
      Changed = true;
    }
  }
  return Q;
}


}  // namespace cq
