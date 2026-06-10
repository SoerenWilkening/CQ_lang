// WireWalk.cpp — Shared forward in-place-gate wire walk. See WireWalk.h for
// the contract and the two consumer modes (ArmClassify position-free;
// OpcodeLowering position-aware). Hoisted from
// ArmClassify::wireGainsNonDiagonalGate (test_C_libtooling-ee5) so the
// straight-line stale-record guard (test_C_libtooling-uzb) reuses the same
// core instead of forking it (Rule 14).

#include "WireWalk.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

bool isCallToPrefix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with(Prefix);
}

}  // namespace

CallInst *findNonDiagonalWireGate(ArrayRef<Value *> Seeds,
                                  bool CrossValueRouting,
                                  const Instruction *EmitPoint,
                                  const DominatorTree *DT) {
  SmallVector<Value *, 16> Work(Seeds.begin(), Seeds.end());
  SmallPtrSet<Value *, 16> Seen;
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    for (User *U : V->users()) {
      if (CrossValueRouting) {
        // PHINodes and select VALUE operands route the same physical handle
        // onward (after rotation lowering's RAUW they are i32-handle muxes),
        // so a theta behind them is still an in-place gate on a wire the
        // seed may denote. A select's CONDITION use is not a routing edge.
        if (auto *P = dyn_cast<PHINode>(U)) {
          Work.push_back(P);
          continue;
        }
        if (auto *Sel = dyn_cast<SelectInst>(U)) {
          if (V != Sel->getCondition())
            Work.push_back(Sel);
          continue;
        }
      }
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI || CI->arg_size() < 1 || CI->getArgOperand(0) != V)
        continue;  // not an in-place gate on this wire (angle/data uses, br).
      if (isCallToPrefix(CI, "cq_theta_")) {
        // Non-diagonal in-place Ry on the wire. Position-free mode: decline
        // unconditionally. Position-aware mode: harmless iff PROVABLY after
        // every execution of `EmitPoint` —
        //   * `DT->dominates(EmitPoint, T)`: every path reaching T already
        //     executed the template (first-execution order), and
        //   * `!isPotentiallyReachable(T, EmitPoint)`: once T fired, the
        //     template never re-executes (a loop back-edge would otherwise
        //     replay the template against the post-Ry wire on iteration 2
        //     while its SSA operand still denotes the pre-Ry record).
        // Both proven ⇒ every template instance precedes every Ry instance
        // on every trace, so the walk may stop here: any theta further down
        // this wire uses (a value dominated by) T's result, hence is also
        // after every template instance, and a reach-back from it would
        // imply a reach-back from T. Unproven ⇒ return T (decline; over-
        // decline is safe, Prime Directive).
        if (EmitPoint && DT && DT->dominates(EmitPoint, CI) &&
            !isPotentiallyReachable(CI, EmitPoint, /*ExclusionSet=*/nullptr,
                                    DT))
          continue;  // provably post-emission on every trace — harmless.
        return CI;
      }
      if (isCallToPrefix(CI, "cq_phi_"))
        Work.push_back(CI);  // diagonal — same wire, keep walking forward.
    }
  }
  return nullptr;
}

}  // namespace cq
