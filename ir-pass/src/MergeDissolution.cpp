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
// `select` case (`region.Merge` is a `SelectInst`): `select i1 %c, A, B` means
// `%c ? A : B`. With the control flag = lowered condition the reduction is one
// of THREE, dispatched on arm taint:
//
//   [classical, classical] (WP4): result `B + flag·(A−B)`. Emit a HOST
//   `%d = sub A, B` (plain LLVM, stays classical — both operands classical, so
//   the `sub` is never tainted/lowered; constants fold, runtime args stay a
//   real `sub`), then `cqrt_alloc_<W>(B)` to seed a handle at the false arm,
//   then `cq_template_add_<W>_hl_controlled(flag, regB, %d)`.
//
//   MIXED — exactly ONE tainted arm (mux.1): one arm is a tainted handle Q,
//   the other a classical C, so the host `sub` would not stay classical. Build
//   the difference with the UNCONTROLLED data template `%d = sub_<W>_hl(Q, C)`
//   (handle−classical → handle) instead, seed `cqrt_alloc_<W>(C)` from the
//   CLASSICAL arm, and use the Shape::QQ controlled add
//   `cq_template_add_<W>_controlled(ctrl, regC, %d)` (both addends are
//   handles). `ctrl` is the flag when Q is the TRUE arm; when Q is the FALSE
//   arm the add is wrapped in a self-inverse `cqrt_x` flag bracket so it fires
//   on ¬flag (`f ? C : Q`). Result = `C + ctrl·(Q−C)` = `ctrl ? Q : C`.
//
//   BOTH arms tainted (mux.2): neither arm is classical, so neither the host
//   `sub` (mixed/classical paths) nor the `cqrt_alloc(C)`-from-classical seed
//   apply, and a consuming/in-place strategy is unsafe — an arm may be live
//   elsewhere. Build an additive copy into a FRESH ancilla:
//   `regOut = cqrt_alloc_<W>(0)`, `cq_template_add_<W>_controlled(f, regOut,
//   A)` (regOut += f·A), then a self-inverse `cqrt_x` flag bracket around
//   `cq_template_add_<W>_controlled(f, regOut, B)` (regOut += ¬f·B). Result =
//   `f·A + ¬f·B = f ? A : B`. A and B are READ as the add's b_handle operand,
//   never consumed, so both source handles stay live for their other uses.
//
// Either way: RAUW the select to the controlled-add result, erase it, and
// register the result as a fresh tainted i32 handle. The source arm handles
// are never erased — only the select node is.

#include "MergeDissolution.h"

#include "ControlPlan.h"
#include "ControlledSymbols.h"
#include "OpcodeSupport.h"  // abiWidthFromType
#include "TaintPropagation.h"
#include "TemplateName.h"  // cq::Shape
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"  // ConstantInt
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

// `select` reduction (PRD §2.6). Three arm shapes, dispatched on arm taint:
//   * [classical, classical] (WP4): `y = B + flag·(A−B)` — host `sub A−B` →
//     `cqrt_alloc_<W>(B)` → `cq_template_add_<W>_hl_controlled(flag, regB, %d)`.
//   * MIXED, exactly one tainted arm (mux.1): one arm is a tainted handle Q,
//     the other a classical C. Result = `C + ctrl·(Q−C)` = `ctrl ? Q : C`,
//     built from the UNCONTROLLED `sub_<W>_hl(Qhandle, Cclassical)` delta, a
//     register `cqrt_alloc_<W>(C)` seeded from the classical arm, and the
//     Shape::QQ `cq_template_add_<W>_controlled(ctrl, regC, delta)`. `ctrl` is
//     the flag when Q is the TRUE arm (`select %f, Q, C` = f?Q:C); when Q is
//     the FALSE arm (`select %f, C, Q` = f?C:Q) we need ¬f, emitted as an
//     `cqrt_x` bracket around the controlled add (X is its own inverse, so the
//     pair restores the flag for its own compare-uncompute — no extra bracket
//     bookkeeping in `emitUncompute`).
//   * BOTH tainted (mux.2): both arms are tainted i32 handles A (true) / B
//     (false). No classical operand, so the difference/seed strategies above
//     do not apply — and an arm may be live elsewhere, so it must NOT be
//     consumed. Build `regOut = cqrt_alloc_<W>(0)` (a fresh ancilla), then
//     `add_<W>_controlled(flag, regOut, A)` (regOut += flag·A) and, inside a
//     self-inverse `cqrt_x` flag bracket, `add_<W>_controlled(flag, regOut, B)`
//     (regOut += ¬flag·B). Result = `flag·A + ¬flag·B = flag ? A : B`. A and B
//     are only READ (the add's b_handle), never erased — they stay live.
void dissolveSelect(ControlRegion &region, WidthDispatch &wd,
                    ControlledSymbols &csyms, TaintSet &taint) {
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

  // Arm-taint discriminator. Detection builds a SelectRegion for every non-i1
  // tainted-condition select; here we split on arm taint into the three
  // reductions (neither / exactly one / both).
  const bool TrueTainted = taint.Tainted.count(A) != 0;
  const bool FalseTainted = taint.Tainted.count(B) != 0;

  FunctionCallee Alloc = wd.allocFn(AbiWidth);
  if (!Alloc)
    return;  // unsupported width — leave the select standing (verify-clean).

  CallInst *Res = nullptr;
  IRBuilder<> Builder(Sel);

  if (!TrueTainted && !FalseTainted) {
    // ── [classical, classical] (WP4) — kept byte-identical ──
    FunctionCallee Add =
        csyms.controlledDataTemplateFn("add", AbiWidth, Shape::HL,
                                       /*inverse=*/false);
    if (!Add)
      return;  // unsupported width — leave the select standing (verify-clean).

    // (1) Host difference `%d = A − B`. Plain LLVM `sub` — both arms classical,
    // so it stays classical (never tainted, never lowered). For constants LLVM
    // folds it (10−20 → -10); for runtime args it is a real `sub`.
    Value *Delta = Builder.CreateSub(A, B, "d");
    // (2) Seed a handle initialized to the false arm B.
    CallInst *RegB = Builder.CreateCall(Alloc, {B}, "h");
    // (3) Controlled add of the classical delta onto regB, gated by the flag
    // (arg 0). `_hl` is (flag, handle, classical).
    Res = Builder.CreateCall(Add, {region.Flag, RegB, Delta}, "h_sel");
    if (DebugLoc DL = Sel->getDebugLoc()) {
      RegB->setDebugLoc(DL);
      Res->setDebugLoc(DL);
    }
  } else if (TrueTainted != FalseTainted) {
    // ── MIXED, exactly one tainted arm (mux.1) ──
    // Q is the tainted handle, C the classical arm; `QisTrue` ⇒ ctrl = flag,
    // else ctrl = ¬flag (the `cqrt_x` bracket below).
    const bool QisTrue = TrueTainted;
    Value *Q = QisTrue ? A : B;
    Value *C = QisTrue ? B : A;

    // delta = Q − C via the UNCONTROLLED `sub_<W>_hl` template (handle, classical)
    // → i32 handle. `Q` may still be its pre-lowering stock op (data-position
    // ops lower AFTER controlled regions); it is i32-typed and tainted, so the
    // later `lowerOps` RAUW propagates its handle into this call's operand.
    FunctionCallee SubHL = wd.dataTemplateFn("sub", AbiWidth, Shape::HL);
    FunctionCallee AddQQ =
        csyms.controlledDataTemplateFn("add", AbiWidth, Shape::QQ,
                                       /*inverse=*/false);
    if (!SubHL || !AddQQ)
      return;  // unsupported width — leave the select standing (verify-clean).

    Value *Delta = Builder.CreateCall(SubHL, {Q, C}, "d_mux");
    // Seed a handle initialized to the classical arm C.
    CallInst *RegC = Builder.CreateCall(Alloc, {C}, "h");

    // ¬flag bracket when Q is the FALSE arm: X(flag); add; X(flag). The pair is
    // self-inverse, so the flag is restored for the standard compare-uncompute.
    FunctionCallee X;
    if (!QisTrue) {
      X = csyms.xFn();
      if (!X)
        return;  // unsupported — leave the select standing (verify-clean).
      Builder.CreateCall(X, {region.Flag});
    }
    Res = Builder.CreateCall(AddQQ, {region.Flag, RegC, Delta}, "h_sel");
    if (!QisTrue)
      Builder.CreateCall(X, {region.Flag});

    if (DebugLoc DL = Sel->getDebugLoc()) {
      if (auto *DCall = dyn_cast<Instruction>(Delta))
        DCall->setDebugLoc(DL);
      RegC->setDebugLoc(DL);
      Res->setDebugLoc(DL);
    }
  } else {
    // ── BOTH arms tainted (mux.2) ──
    // A and B are tainted i32 handles (hp / hq). No classical operand, so the
    // mixed/classical seed strategies do not apply, and an arm may be live
    // elsewhere (so consuming one is unsafe). Copy additively into a FRESH
    // ancilla: regOut = alloc(0); regOut += flag·A; regOut += ¬flag·B (¬flag
    // via a self-inverse `cqrt_x` flag bracket). Result = flag ? A : B. Both A
    // and B are only READ as the QQ add's b_handle — never erased or consumed.
    FunctionCallee AddQQ =
        csyms.controlledDataTemplateFn("add", AbiWidth, Shape::QQ,
                                       /*inverse=*/false);
    FunctionCallee X = csyms.xFn();  // void cqrt_x(i32); self-inverse.
    if (!AddQQ || !X)
      return;  // unsupported width — leave the select standing (verify-clean).

    // Fresh ancilla seeded to 0. The alloc takes the classical init value at the
    // select's value width; 0 of that integer type matches allocFn's parameter.
    Value *Zero = ConstantInt::get(A->getType(), 0);
    CallInst *RegOut = Builder.CreateCall(Alloc, {Zero}, "h");

    // regOut += flag·A.
    CallInst *Acc1 = Builder.CreateCall(AddQQ, {region.Flag, RegOut, A}, "h_sel");
    // ¬flag bracket: X(flag); regOut += flag·B (now ¬flag·B); X(flag). The pair
    // is self-inverse, so the flag is restored for the standard compare-uncompute.
    Builder.CreateCall(X, {region.Flag});
    CallInst *Acc2 = Builder.CreateCall(AddQQ, {region.Flag, Acc1, B}, "h_sel");
    Builder.CreateCall(X, {region.Flag});
    Res = Acc2;

    if (DebugLoc DL = Sel->getDebugLoc()) {
      RegOut->setDebugLoc(DL);
      Acc1->setDebugLoc(DL);
      Acc2->setDebugLoc(DL);
    }
  }

  Sel->replaceAllUsesWith(Res);
  Sel->eraseFromParent();
  region.Merge = nullptr;  // dissolved.

  // The reduction's result is a fresh i32 quantum handle (the dissolved `y`).
  // Register it as tainted (with a BirthOrder slot, matching the data-path
  // bookkeeping) so downstream consumers — a `cq_measure`, or further tainted
  // arithmetic — recognize it. Without this, a `y = (q>0)?A:B; measure(y);`
  // slice trips MeasureLowering's "operand not a tainted i32 handle" guard
  // (the `br`-diamond case is fine: it RAUWs to an already-tainted in-place
  // handle, never minting a new one). The seed register / delta are consumed
  // in-place by the add, so only the final `Res` needs tracking.
  taint.Tainted.insert(Res);
  taint.BirthOrder[Res] = taint.NextBirth++;
}

}  // namespace

void dissolveMerge(ControlRegion &region, WidthDispatch &wd,
                   ControlledSymbols &csyms, TaintSet &taint) {
  if (region.Kind == ControlRegion::SelectRegion)
    dissolveSelect(region, wd, csyms, taint);
  else
    dissolveBranchPhi(region);
}

}  // namespace cq
