// CompareLowering.cpp — per-instruction lowering for tainted data-position
// `CmpInst` (`icmp`/`fcmp`). See header for the data-position gate, the
// operand-shape rules, the predicate-flip canonicalization, and the
// flag-handle invariant. Models its collect-emit-RAUW-bookkeep structure on
// `ArithLowering`; the driver (`OpcodeLowering`) owns collection, program
// order, and erase.

#include "CompareLowering.h"

#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "TemplateName.h"  // cq::Shape
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

namespace {

// Promote `repl` (the i32 flag handle) into the taint set as the lowered
// replacement for `orig` (the i1 compare), drop `orig`, and give `repl` the
// next BirthOrder slot. Exact Phase-2/ArithLowering bookkeeping. The driver
// erases `orig` afterward (we only RAUW + bookkeep here).
void promote(Value *repl, Instruction *orig, TaintSet &taint) {
  taint.Tainted.insert(repl);
  taint.Tainted.erase(orig);
  taint.BirthOrder[repl] = taint.NextBirth++;
}

}  // namespace

bool isDataPositionCompare(CmpInst *cmp) {
  // A result feeding a branch (terminator) or a select condition is Phase
  // 4's — it must stay the original i1. Any such user disqualifies the whole
  // compare (a compare feeding BOTH data and a branch is left untouched;
  // risk R3). A select that uses the compare as a *value* (not the
  // condition) is fine — but in practice the condition is the only i1 use.
  for (User *U : cmp->users()) {
    if (isa<BranchInst>(U))
      return false;
    if (auto *Sel = dyn_cast<SelectInst>(U))
      if (Sel->getCondition() == cmp)
        return false;
  }
  return true;
}

bool rewriteCompare(CmpInst *cmp, WidthDispatch &wd, TaintSet &taint) {
  // `op` is the family stem the symbol table uses: "icmp" / "fcmp". The
  // predicate range partition is authoritative (an fcmp predicate is < 32;
  // an icmp predicate is in [32,..]); `isa<ICmpInst>` would do as well.
  const bool IsFp = cmp->isFPPredicate();
  StringRef Op = IsFp ? "fcmp" : "icmp";

  Value *A = cmp->getOperand(0);
  Value *B = cmp->getOperand(1);
  // Operand classification by taint membership (authoritative — matches
  // ArithLowering; covers tainted args/loads as handles and untainted
  // args/literals/globals as classical).
  const bool ATainted = taint.Tainted.count(A) != 0;
  const bool BTainted = taint.Tainted.count(B) != 0;

  // Q+Q (both operands tainted) data-position compares are UNSUPPORTED in
  // Phase 3 and diagnosed loudly. The logical width is genuinely
  // unrecoverable here: both operands are i32-laundered handles (the earlier
  // rotation lowering RAUW'd the rotation result to an i32 handle, erasing
  // the qubit's i1/i16/f32 width), so there is no classical operand to read a
  // real width from. Falling back to operand 0's laundered i32 type would
  // silently emit a wrong/nonexistent symbol (e.g. `cq_template_fcmp_une_i32`,
  // which is both the wrong width and an integer-compare name on a float
  // compare) with no diagnostic. Deferred to a later phase; until then this
  // matches every other unsupported path — diagnose and leave un-lowered (the
  // driver keeps the well-typed `icmp`/`fcmp`, so `opt -verify` stays clean).
  if (ATainted && BTainted) {
    diagnoseNoTemplate(cmp);
    return false;
  }

  // Width is the data width of the values being compared — NOT the i1 result
  // type. Read it from the CLASSICAL operand: a tainted operand is an i32
  // handle whose original logical width was laundered away by the earlier
  // rotation lowering (the qubit's i1/i16/f32 width does not survive as the
  // handle's i32 type), but a classical operand keeps its real LLVM type
  // (`float 1.0` stays `float`). For the `_hl` shapes (one handle, one
  // classical) this recovers the true width (e.g. `f32` for `fcmp une float
  // %h, 1.0`).
  Type *WidthTy = !ATainted ? A->getType() : B->getType();
  StringRef AbiWidth = abiWidthFromType(WidthTy);
  if (AbiWidth.empty()) {
    diagnoseNoTemplate(cmp);
    return false;
  }

  CmpInst::Predicate Pred = cmp->getPredicate();
  Value *Lhs = nullptr;
  Value *Rhs = nullptr;
  Shape ShapeSel;
  if (BTainted) {
    // Classical on the LEFT (A), handle on the right (B): flip the predicate
    // so the handle moves to the LHS, then emit `_hl(handle, classical)`.
    // There are NO `_lh` compare templates (PRD §2.4); `5 < x` ⇒ `x > 5`.
    Lhs = B;
    Rhs = A;
    Pred = flipPredicate(Pred);
    ShapeSel = Shape::HL;
  } else {
    // Handle on the LEFT (A), classical on the right (B): already the `_hl`
    // shape, predicate unchanged.
    Lhs = A;
    Rhs = B;
    ShapeSel = Shape::HL;
  }

  StringRef PredName = CmpInst::getPredicateName(Pred);
  FunctionCallee Callee = wd.compareTemplateFn(Op, PredName, AbiWidth, ShapeSel);
  if (!Callee) {
    diagnoseNoTemplate(cmp);
    return false;
  }

  IRBuilder<> Builder(cmp);
  // The template returns an i32 flag handle (never i1). RAUW the i1 compare
  // result with this i32 handle — a cross-type RAUW, laundered by erasure
  // (IMPLEMENTATION §1.2 / risk R2; verified clean on this assertions-OFF
  // LLVM-19, guarded by the per-fixture `verify` RUN line).
  CallInst *T = Builder.CreateCall(Callee, {Lhs, Rhs}, "h_cmp");
  if (DebugLoc DL = cmp->getDebugLoc())
    T->setDebugLoc(DL);
  cmp->replaceAllUsesWith(T);
  promote(T, cmp, taint);
  return true;
}

}  // namespace cq
