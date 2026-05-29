// MeasureLowering.cpp — Lower `@cq_measure_<sfx>` calls to the matching
// `@cqrt_measure_<W>(handle)` runtime entry per PRD §"Width unification".
// Generalizes the original path (which was pinned to `cq_measure_si32` →
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

void lowerMeasures(Module &M, WidthDispatch &wd, TaintSet &taint) {
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

    // Under the plain-SSA surface the measure operand is always already a
    // tainted i32 handle — a theta result RAUW'd to its alloc handle by
    // RotationLowering, or a `cq_template_add_<W>` result from
    // OpcodeLowering. The retired mid-struct patterns (direct init result,
    // insertvalue unwrap) have no inputs and are gone. An operand that is
    // not a tainted i32 handle is reported (loud) and left in place.
    Value *Handle = Measure->getArgOperand(0);
    if (!(Handle->getType() == I32 && taint.Tainted.count(Handle))) {
      Measure->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
          *Measure->getFunction(),
          "cq_measure_<sfx> operand not recognized; expected a tainted "
          "i32 handle"));
      continue;
    }

    Builder.SetInsertPoint(Measure);
    CallInst *NewM = Builder.CreateCall(MeasureRT, {Handle}, "m");
    if (DebugLoc DL = Measure->getDebugLoc())
      NewM->setDebugLoc(DL);
    Measure->replaceAllUsesWith(NewM);
    ToErase.push_back(Measure);
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace cq
