// OpcodeLowering.cpp — Lower tainted `add i32` to template calls.
// Behavior preserved from the pre-M12 monolith's step 5.

#include "OpcodeLowering.h"

#include "MidHandleRebind.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <vector>

using namespace llvm;

namespace cq {

void lowerOps(Module &M, WidthDispatch &wd, TaintSet &taint,
              RebindMap &rebind) {
  Type *I32 = wd.i32Ty();

  // Collect tainted i32 adds in BB / function order. Collecting up
  // front (rather than walking-and-rewriting in the same loop)
  // sidesteps iterator-invalidation when each lowering RAUWs the add.
  std::vector<BinaryOperator *> TaintedAdds;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO)
          continue;
        if (BO->getOpcode() != Instruction::Add)
          continue;
        if (BO->getType() != I32)
          continue;
        if (!taint.Tainted.count(BO))
          continue;
        TaintedAdds.push_back(BO);
      }
    }
  }

  if (TaintedAdds.empty())
    return;

  IRBuilder<> Builder(wd.context());
  std::vector<Instruction *> ToErase;

  for (BinaryOperator *Add : TaintedAdds) {
    Builder.SetInsertPoint(Add);
    Value *A = Add->getOperand(0);
    Value *B = Add->getOperand(1);

    // Dispatch on whether each operand carries a quantum handle.
    // taint.Tainted is authoritative — it covers literals (never
    // tainted) AND non-constant classical sources like fn-args and
    // loaded globals (also never tainted). isa<ConstantInt> would miss
    // the latter; the lowering_q_plus_arg fixture pins this.
    //
    //   * Q+Q (both tainted): symmetric cq_template_add_i32, ordered
    //     by BirthOrder so the trace is clang-version-stable.
    //   * Q+C / C+Q: cq_template_add_i32_hl(handle, classical) — swap
    //     when LLVM landed the classical on the lhs.
    //   * C+C: unreachable. A non-tainted add can't have entered the
    //     work list (TaintPropagation only seeds from init returns).
    bool ATainted = taint.Tainted.count(A) != 0;
    bool BTainted = taint.Tainted.count(B) != 0;

    Value *Lhs;
    Value *Rhs;
    bool IsHL;
    if (ATainted && BTainted) {
      unsigned BA = rebind.BirthOrder.lookup(A);
      unsigned BB = rebind.BirthOrder.lookup(B);
      // If either side lacks a BirthOrder (e.g., taint reached it via a
      // path other than alloc-emission or prior template-result), fall
      // back to LLVM's operand order. Not expected in Phase 1/2 shapes
      // but harmless.
      if (BA != 0 && BB != 0 && BB < BA) {
        Lhs = B;
        Rhs = A;
      } else {
        Lhs = A;
        Rhs = B;
      }
      IsHL = false;
    } else if (ATainted) {
      Lhs = A;
      Rhs = B;
      IsHL = true;
    } else {  // BTainted (C+C unreachable)
      Lhs = B;
      Rhs = A;
      IsHL = true;
    }

    FunctionCallee Callee = wd.addTemplate(IsHL);
    CallInst *T = Builder.CreateCall(Callee, {Lhs, Rhs}, "h_sum");
    if (DebugLoc DL = Add->getDebugLoc())
      T->setDebugLoc(DL);
    Add->replaceAllUsesWith(T);

    // Promote the template result into the taint set; drop the now-
    // dead add (its pointer would otherwise dangle in the set after
    // erase). BirthOrder inherits the next slot so a subsequent Q+Q
    // canonicalization sees this handle.
    taint.Tainted.insert(T);
    taint.Tainted.erase(Add);
    rebind.BirthOrder[T] = rebind.NextBirth++;
    ToErase.push_back(Add);
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace cq
