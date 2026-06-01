// MergeDissolution.cpp — see header. Dissolves a region's merge node, keyed on
// the merge instruction kind (PRD §2.6, IMPLEMENTATION §5.5).
//
// `[modified, original]` `br` case (`region.Merge` is a `PHINode`): the merge
// `φ[rotated_y, y]` has one incoming value per predecessor — the MODIFIED arm
// from `region.Arm`, the ORIGINAL (in-place) handle from `region.Pred` (the
// diamond predecessor's fall-through edge). The in-place handle is the original
// arm's value — RAUW the whole merge to it and erase. Classifying by predecessor
// edge (rather than by raw arm taint) is robust to the substitution RAUW having
// already rewritten the modified arm's value to the same handle (risk R2): the
// `region.Pred` edge is definitionally the unmodified path.
//
// `[classical, classical]` `select` case (`region.Merge` is a `SelectInst`):
// `select i1 %c, A, B` means `%c ? A : B`. With the control flag = lowered
// condition, the result must be `B + flag·(A−B)` (flag=1 → A, flag=0 → B). So
// emit, at the select: a HOST `%d = sub A, B` (plain LLVM, stays classical —
// both arms are classical, so the operands are classical and the `sub` is never
// tainted/lowered), then `cqrt_alloc_<W>(B)` to seed a handle at the false arm,
// then `cq_template_add_<W>_hl_controlled(flag, regB, %d)`. RAUW the select
// result to the controlled-add result and erase. Runtime-variable arms reduce
// identically — the only difference is `%d` is a real `sub`, not a folded
// literal (the `_hl` slot has always been a classical-operand slot).

#include "MergeDissolution.h"

#include "ControlPlan.h"
#include "ControlledSymbols.h"
#include "OpcodeSupport.h"  // abiWidthFromType
#include "TaintPropagation.h"
#include "TemplateName.h"  // cq::Shape
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// WP3 `[modified, original]` `br`-diamond merge `φ`.
void dissolveBranchPhi(ControlRegion &region) {
  auto *Merge = dyn_cast_or_null<PHINode>(region.Merge);
  if (!Merge || !region.Pred)
    return;

  int PredIdx = Merge->getBasicBlockIndex(region.Pred);
  if (PredIdx < 0)
    return;  // not the expected diamond wiring; leave it for the verifier.
  Value *InPlace = Merge->getIncomingValue(PredIdx);

  Merge->replaceAllUsesWith(InPlace);
  Merge->eraseFromParent();
  region.Merge = nullptr;  // dissolved; linearization must not touch it again.
}

// WP4 `[classical, classical]` `select` reduction (PRD §2.6).
void dissolveSelect(ControlRegion &region, WidthDispatch &wd,
                    ControlledSymbols &csyms) {
  auto *Sel = dyn_cast_or_null<SelectInst>(region.Merge);
  if (!Sel || !region.Flag)
    return;  // no flag (ControlFlag failed) → leave the select for the verifier.

  Value *A = Sel->getTrueValue();   // flag=1 arm.
  Value *B = Sel->getFalseValue();  // flag=0 arm.

  // Width is the ABI width of the select's value type (e.g. i32). The two arms
  // share that type (a well-formed select), so reading it off A is exact.
  StringRef AbiWidth = abiWidthFromType(A->getType());
  if (AbiWidth.empty())
    return;  // unsupported value width; leave it well-typed for the verifier.

  FunctionCallee Alloc = wd.allocFn(AbiWidth);
  FunctionCallee Add =
      csyms.controlledDataTemplateFn("add", AbiWidth, Shape::HL,
                                     /*inverse=*/false);
  if (!Alloc || !Add)
    return;  // unsupported width — leave the select standing (verify-clean).

  IRBuilder<> Builder(Sel);
  // (1) Host difference `%d = A − B`. Plain LLVM `sub` — both arms classical,
  // so it stays classical (never tainted, never lowered). For constants LLVM
  // folds it (10−20 → -10); for runtime args it is a real `sub`.
  Value *Delta = Builder.CreateSub(A, B, "d");
  // (2) Seed a handle initialized to the false arm B.
  CallInst *RegB = Builder.CreateCall(Alloc, {B}, "h");
  // (3) Controlled add of the classical delta onto regB, gated by the flag
  // (arg 0). `_hl` is (flag, handle, classical).
  CallInst *Res = Builder.CreateCall(Add, {region.Flag, RegB, Delta}, "h_sel");
  if (DebugLoc DL = Sel->getDebugLoc()) {
    RegB->setDebugLoc(DL);
    Res->setDebugLoc(DL);
  }

  Sel->replaceAllUsesWith(Res);
  Sel->eraseFromParent();
  region.Merge = nullptr;  // dissolved.
}

}  // namespace

void dissolveMerge(ControlRegion &region, WidthDispatch &wd,
                   ControlledSymbols &csyms, TaintSet &taint) {
  (void)taint;
  if (region.Kind == ControlRegion::SelectRegion)
    dissolveSelect(region, wd, csyms);
  else
    dissolveBranchPhi(region);
}

}  // namespace cq
