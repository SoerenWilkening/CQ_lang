// MeasureLowering.cpp — Lower `@cq_measure_<sfx>` calls to the matching
// `@cqrt_measure_<W>(handle)` runtime entry per PRD §"Width unification".
// M17 generalizes the M12 path (which was pinned to `cq_measure_si32` →
// `cqrt_measure_i32`) by deriving the runtime symbol per call site:
//
//   1. Resolve the suffix from the front-end intrinsic name (strip the
//      `cq_measure_` prefix).
//   2. Collapse signedness via `WidthDispatch::abiWidthFor(sfx)` (e.g.
//      `si16` → `i16`, `f64` → `f64`).
//   3. Ask `WidthDispatch::measureRtFn(abiWidth)` for the lazy-declared
//      `@cqrt_measure_<W>` FunctionCallee.
//
// The handle argument is always i32 across every width (PRD §"Width
// unification"); only the return-value type varies.

#include "MeasureLowering.h"

#include "MidHandleRebind.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Extract the suffix from a front-end measure intrinsic's name
// (`cq_measure_<sfx>`). Returns "" if the name doesn't match the
// expected prefix; callers treat an empty suffix as an unrecognized
// width and surface a diagnostic.
StringRef suffixFromMeasureName(const CallInst *Measure) {
  Function *Callee = Measure->getCalledFunction();
  if (!Callee)
    return {};
  StringRef N = Callee->getName();
  constexpr StringRef kPrefix = "cq_measure_";
  if (!N.starts_with(kPrefix))
    return {};
  return N.substr(kPrefix.size());
}

}  // namespace

void lowerMeasures(Module &M, WidthDispatch &wd, TaintSet &taint,
                   RebindMap &rebind) {
  (void)M;
  if (taint.MeasureCalls.empty())
    return;

  Type *I32 = wd.i32Ty();
  IRBuilder<> Builder(wd.context());

  std::vector<Instruction *> ToErase;
  for (CallInst *Measure : taint.MeasureCalls) {
    // Resolve the per-call runtime symbol. Suffix → ABI width →
    // FunctionCallee. An unrecognized suffix or width is treated the
    // same as a missing decl: report and skip so the bad call survives
    // to a later verifier run.
    StringRef Sfx = suffixFromMeasureName(Measure);
    StringRef AbiWidth = wd.abiWidthFor(Sfx);
    FunctionCallee MeasureRT = AbiWidth.empty()
                                   ? FunctionCallee()
                                   : wd.measureRtFn(AbiWidth);
    if (!MeasureRT) {
      Measure->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
          *Measure->getFunction(),
          "cq_measure_<sfx>: unrecognized suffix or unsupported ABI width"));
      continue;
    }

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
          "cq_measure_<sfx> operand pattern not recognized; expected "
          "direct cq_init_<sfx> result, insertvalue %struct poison, "
          "<T> %h, 0, or tainted i32 handle"));
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
