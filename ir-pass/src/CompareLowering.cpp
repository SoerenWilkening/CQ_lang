// CompareLowering.cpp — per-instruction lowering for tainted data-position
// `CmpInst` (`icmp`/`fcmp`). See header for the data-position gate, the
// operand-shape rules, the predicate-flip canonicalization, and the
// flag-handle invariant. Models its collect-emit-RAUW-bookkeep structure on
// `ArithLowering`; the driver (`OpcodeLowering`) owns collection, program
// order, and erase.

#include "CompareLowering.h"

#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "TemplateName.h"  // cq::Shape, cq::compareName
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"  // ConstantInt
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"

#include <string>

using namespace llvm;

namespace cq {

namespace {

// Promote `repl` (the i32 flag handle) into the taint set as the lowered
// replacement for `orig` (the i1 compare), drop `orig`, and give `repl` the
// next BirthOrder slot. Exact Phase-2/ArithLowering bookkeeping. The driver
// erases `orig` afterward (we only RAUW + bookkeep here).
//
// Phase 7.1 Increment A R-A scrub: `HandleWidth.erase(orig)` mirrors the
// `Tainted.erase` so no stale width survives at the erased compare's address
// (verify-clean if a reused `Value*` kept it). A compare result is an i1 flag
// handle, NOT a data-width value, so NO width is recorded for `repl` (the
// `handleWidth` arg defaults empty); only arith/cast results record a logical
// data width. See ArithLowering::promote for the rationale.
void promote(Value *repl, Instruction *orig, TaintSet &taint,
             StringRef handleWidth = {}) {
  taint.Tainted.insert(repl);
  taint.Tainted.erase(orig);
  taint.BirthOrder[repl] = taint.NextBirth++;
  taint.HandleWidth.erase(orig);
  if (!handleWidth.empty())
    taint.HandleWidth[repl] = handleWidth;
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

// Shared classify-and-emit core for the data-path mint (`lowerCompareToFlag`)
// and the swap-route inner-condition mint (`lowerCompareToFlagRail`). Operands
// are classified by taint exactly once so BOTH callers mint byte-identical
// signatures (§4 "the same template machinery"); when `railBase` is non-null it
// is substituted for the parent-routed handle operand (see
// `lowerCompareToFlagRail`). `railBase` is null on the data path.
static Value *lowerCompareImpl(CmpInst *cmp, WidthDispatch &wd, TaintSet &taint,
                               StringRef qqWidth, bool inverse,
                               Instruction *before, Value *railBase) {
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

  CmpInst::Predicate Pred = cmp->getPredicate();
  StringRef AbiWidth;
  Value *Lhs = nullptr;
  Value *Rhs = nullptr;
  Shape ShapeSel;

  if (ATainted && BTainted) {
    // Q+Q. The data path (Phase 3) bails here: the logical width is
    // unrecoverable from two i32-laundered handles, and falling back to the
    // laundered i32 type would silently emit a wrong/nonexistent symbol.
    // Phase 4's CONTROL path may pass `qqWidth` (recovered from the
    // `HandleWidth` side-table, PRD §2.4); without it, stay HL-only — diagnose
    // and return null (the caller leaves the well-typed `icmp`, so `opt
    // -verify` stays clean). WP3's fixture is HL, so `qqWidth` is empty here.
    if (qqWidth.empty()) {
      diagnoseNoTemplate(cmp);
      return nullptr;
    }
    AbiWidth = qqWidth;
    Lhs = A;  // HH template: both operands are handles, no flip needed.
    Rhs = B;
    ShapeSel = Shape::QQ;
  } else {
    // Q+C / C+Q. Width is the data width of the values compared — NOT the i1
    // result type. Read it from the CLASSICAL operand: a tainted operand is an
    // i32 handle whose logical width was laundered away by rotation lowering,
    // but a classical operand keeps its real LLVM type (`float 1.0` stays
    // `float`). For `_hl` (one handle, one classical) this recovers the true
    // width (e.g. `f32` for `fcmp une float %h, 1.0`).
    Type *WidthTy = !ATainted ? A->getType() : B->getType();
    AbiWidth = abiWidthFromType(WidthTy);
    if (AbiWidth.empty()) {
      diagnoseNoTemplate(cmp);
      return nullptr;
    }
    if (BTainted) {
      // Classical on the LEFT (A), handle on the right (B): flip the predicate
      // so the handle moves to the LHS, then emit `_hl(handle, classical)`.
      // There are NO `_lh` compare templates (PRD §2.4); `5 < x` ⇒ `x > 5`.
      Lhs = B;
      Rhs = A;
      Pred = flipPredicate(Pred);
    } else {
      // Handle on the LEFT (A), classical on the right (B): already `_hl`,
      // predicate unchanged.
      Lhs = A;
      Rhs = B;
    }
    ShapeSel = Shape::HL;
  }

  // Swap-route inner condition (§4/§12.2): the parent-routed operand's
  // amplitude physically lives on `railBase` after the outer route-in — the
  // original SSA register holds |0> on the f1=1 path — so the inner flag must
  // be minted FROM the rail, not from that now-stale register. The
  // classification above lands the parent-routed handle in `Lhs` (for HL the
  // sole tainted operand, moved left directly or via `flipPredicate`; for the
  // Q+Q forward seam, operand 0), so the substitution is exactly
  // `Lhs := railBase`, leaving `Rhs` (the classical operand that fixed
  // `AbiWidth`) untouched. A plain mint off the stale register would compute
  // the wrong predicate — verify-clean (§6 hazard 3). Null on the data path.
  if (railBase)
    Lhs = railBase;

  StringRef PredName = CmpInst::getPredicateName(Pred);
  // Predicate-scope gate (test_C_libtooling-jvun): an out-of-scope fcmp
  // predicate (anything outside {oeq,une,olt,ogt,ole,oge}) has NO generated
  // template. Without this check `compareTemplateFn` would `getOrInsertFunction`
  // a non-existent `cq_template_fcmp_<pred>_<W>_hl` symbol — opt exits 0,
  // `opt -verify` is clean, and the program LINK-FAILS at Stage 3 (a verify-clean
  // miscompile, Rule 1). Decline LOUDLY and leave `cmp` standing (well-typed i1,
  // verify-clean), exactly like the unsupported-width / Q+Q bails above. Checked
  // on the FINAL (post-`flipPredicate`) predicate; the flip never moves an
  // in-scope predicate out of scope (`getSwappedPredicate` keeps ogt↔olt etc.
  // in scope, self-maps une/oeq), and covers both the forward and `_inv` paths.
  if (!compareInScope(Op, PredName)) {
    diagnoseNoTemplate(cmp);
    return nullptr;
  }
  FunctionCallee Callee;
  if (!inverse) {
    // Forward compute: resolve via the shared `WidthDispatch` resolver so the
    // data path and the control path mint byte-identical signatures.
    Callee = wd.compareTemplateFn(Op, PredName, AbiWidth, ShapeSel);
  } else {
    // Uncompute (§1.5): the `_inv` twin of the SAME plain compare template
    // (these are plain compares, NOT controlled). Mint it directly via the
    // TemplateName inverse axis with the identical HL/QQ signature so it
    // matches the generated `cq_template_icmp_<pred>_<W>_hl_inv` C decl. Kept
    // local (not a new `WidthDispatch` parameter) so the data-path resolver
    // stays untouched.
    Module &M = *cmp->getModule();
    LLVMContext &Ctx = M.getContext();
    Type *Handle = Type::getInt32Ty(Ctx);
    std::string Name = compareName(Op, PredName, AbiWidth, ShapeSel,
                                   /*controlled=*/false, /*inverse=*/true);
    if (ShapeSel == Shape::QQ) {
      Callee = M.getOrInsertFunction(
          Name, FunctionType::get(Handle, {Handle, Handle}, false));
    } else {
      Type *Classical = wd.llvmWidthType(AbiWidth);
      if (Classical)
        Callee = M.getOrInsertFunction(
            Name, FunctionType::get(Handle, {Handle, Classical}, false));
    }
  }
  if (!Callee) {
    diagnoseNoTemplate(cmp);
    return nullptr;
  }

  // The template returns an i32 flag handle (never i1). Insert before the
  // caller-chosen point (the uncompute lands after the controlled region),
  // defaulting to the compare itself (the forward compute). This helper does
  // NOT RAUW or erase `cmp` — that is `rewriteCompare`'s data-path job; the
  // control path leaves `cmp` standing until linearization (§1.3).
  IRBuilder<> Builder(before ? before : cmp);
  CallInst *T = Builder.CreateCall(Callee, {Lhs, Rhs}, "h_cmp");
  if (DebugLoc DL = cmp->getDebugLoc())
    T->setDebugLoc(DL);
  return T;
}

Value *lowerCompareToFlag(CmpInst *cmp, WidthDispatch &wd, TaintSet &taint,
                          StringRef qqWidth, bool inverse,
                          Instruction *before) {
  return lowerCompareImpl(cmp, wd, taint, qqWidth, inverse, before,
                          /*railBase=*/nullptr);
}

Value *lowerCompareToFlagRail(CmpInst *cmp, Value *railBase, WidthDispatch &wd,
                              TaintSet &taint, StringRef qqWidth, bool inverse,
                              Instruction *before) {
  return lowerCompareImpl(cmp, wd, taint, qqWidth, inverse, before, railBase);
}

Value *emitEqFlag(Value *handle, ConstantInt *caseValue, WidthDispatch &wd,
                  bool inverse, Instruction *before) {
  if (!handle || !caseValue || !before)
    return nullptr;
  StringRef AbiWidth = abiWidthFromType(caseValue->getType());
  if (AbiWidth.empty())
    return nullptr;  // unsupported case-value width.

  // HL form: handle on the left, the case constant (at its real width) on the
  // right. Forward = the shared resolver (byte-identical to the data path);
  // inverse = the `_inv` twin minted directly (same shape), mirroring
  // `lowerCompareToFlag`.
  FunctionCallee Callee;
  if (!inverse) {
    Callee = wd.compareTemplateFn("icmp", "eq", AbiWidth, Shape::HL);
  } else {
    Module &M = *before->getModule();
    Type *Handle = Type::getInt32Ty(M.getContext());
    Type *Classical = wd.llvmWidthType(AbiWidth);
    if (!Classical)
      return nullptr;
    std::string Name = compareName("icmp", "eq", AbiWidth, Shape::HL,
                                   /*controlled=*/false, /*inverse=*/true);
    Callee = M.getOrInsertFunction(
        Name, FunctionType::get(Handle, {Handle, Classical}, false));
  }
  if (!Callee)
    return nullptr;

  IRBuilder<> Builder(before);
  return Builder.CreateCall(Callee, {handle, caseValue}, "h_cmp");
}

bool rewriteCompare(CmpInst *cmp, WidthDispatch &wd, TaintSet &taint) {
  // Data-position path (Phase 3): mint the flag via the shared helper (HL
  // only — `qqWidth` empty keeps the Q+Q bail), then RAUW the i1 compare
  // result with the i32 flag handle (a cross-type RAUW, laundered by erasure;
  // IMPLEMENTATION §1.2 / risk R2, guarded by the per-fixture `verify` RUN
  // line) and bookkeep. A null flag means the helper diagnosed (unsupported
  // width / Q+Q) and left the compare standing — the driver must NOT erase it.
  // ziov WI-1: if `SwapRouteEmit::emitRegion` already minted a SHARED control
  // flag for this exact compare (the condition is the control flag AND a data
  // value), REUSE it — minting a second flag here is the ziov duplicate-mint. The
  // shared flag was positioned at the compare so it dominates every data use;
  // RAUW the now-redundant compare onto it (the same cross-type i1→i32 launder as
  // the fresh-mint path below, but the data casts' i1 widths were already captured
  // in Phase 1) and bookkeep. The driver erases `cmp` afterward.
  if (Value *Shared = taint.SharedCondFlags.lookup(cmp)) {
    cmp->replaceAllUsesWith(Shared);
    promote(Shared, cmp, taint);
    return true;
  }
  // Phase 7.1 Increment A: a tainted Q+Q (both-operands-tainted) DATA-position
  // compare. After rotation lowering both operands are i32-laundered handles,
  // so the logical width is unrecoverable from their SSA type — it is recovered
  // from the `HandleWidth` side-table (recorded at each operand's rotation /
  // arith / cast mint). AGREEMENT-OR-DECLINE (Prime Directive): pass `qqWidth`
  // to the already-built `Shape::QQ` branch ONLY when both operands carry a
  // non-empty recorded width AND the two widths AGREE. On disagreement, or any
  // missing entry, leave `qqWidth` empty — `lowerCompareImpl`'s existing loud
  // Q+Q bail fires (`diagnoseNoTemplate`). NEVER pick one width on disagreement
  // (a wrong-width symbol, verify-clean), NEVER default empty -> i32 (the same
  // class of silent miscompile). A Q+C compare is untouched here (`qqWidth`
  // empty is the HL path's normal state); only when BOTH are tainted is the
  // recovered width consulted.
  StringRef QqWidth;
  Value *A = cmp->getOperand(0);
  Value *B = cmp->getOperand(1);
  if (taint.Tainted.count(A) && taint.Tainted.count(B)) {
    StringRef WA = taint.HandleWidth.lookup(A);
    StringRef WB = taint.HandleWidth.lookup(B);
    if (!WA.empty() && WA == WB)
      QqWidth = WA;  // agreement: feed the recovered logical width.
    // else QqWidth stays empty -> the Q+Q loud decline (disagreement / absent).
  }
  Value *Flag = lowerCompareToFlag(cmp, wd, taint, QqWidth);
  if (!Flag)
    return false;
  cmp->replaceAllUsesWith(Flag);
  promote(Flag, cmp, taint);
  return true;
}

}  // namespace cq
