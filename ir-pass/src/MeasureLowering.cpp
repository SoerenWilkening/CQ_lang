// MeasureLowering.cpp — Lower `@cq_measure_si32` calls to
// `@cqrt_measure_i32`. Behavior preserved from the pre-M12 monolith's
// step 6.

#include "MeasureLowering.h"

#include "MidHandleRebind.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <vector>

using namespace llvm;

namespace cq {

void lowerMeasures(Module &M, WidthDispatch &wd, TaintSet &taint,
                   RebindMap &rebind) {
  (void)M;
  if (taint.MeasureCalls.empty())
    return;

  FunctionCallee MeasureRT = wd.measureRtFn();
  Type *I32 = wd.i32Ty();
  IRBuilder<> Builder(wd.context());

  std::vector<Instruction *> ToErase;
  for (CallInst *Measure : taint.MeasureCalls) {
    Value *StructArg = Measure->getArgOperand(0);
    Value *Handle = nullptr;
    InsertValueInst *IVToErase = nullptr;

    if (auto It = rebind.StructToHandle.find(StructArg);
        It != rebind.StructToHandle.end()) {
      // Pattern (a): init result was already mapped to a handle by
      // rebind. Use the recorded handle directly.
      Handle = It->second;
    } else if (auto *IV = dyn_cast<InsertValueInst>(StructArg)) {
      if (IV->getNumIndices() == 1 && IV->getIndices()[0] == 0) {
        // Pattern (b): pull the handle out of the insertvalue. We can
        // safely erase the insertvalue iff this measure is its only
        // user; otherwise something else still wants the struct view.
        Handle = IV->getInsertedValueOperand();
        if (IV->hasOneUse())
          IVToErase = IV;
      }
    } else if (StructArg->getType() == I32 && taint.Tainted.count(StructArg)) {
      // Pattern (c): flattened-struct shape — the arg is already a
      // tainted i32 handle (init result post-SROA, or a template
      // result from OpcodeLowering). Use it as-is.
      Handle = StructArg;
    }

    if (!Handle) {
      Measure->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
          *Measure->getFunction(),
          "cq_measure_si32 operand pattern not recognized; expected "
          "direct cq_init_si32 result, insertvalue %struct poison, "
          "i32 %h, 0, or tainted i32 handle"));
      continue;
    }

    Builder.SetInsertPoint(Measure);
    CallInst *NewM = Builder.CreateCall(MeasureRT, {Handle}, "m");
    if (DebugLoc DL = Measure->getDebugLoc())
      NewM->setDebugLoc(DL);
    Measure->replaceAllUsesWith(NewM);
    ToErase.push_back(Measure);
    if (IVToErase)
      ToErase.push_back(IVToErase);
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace cq
