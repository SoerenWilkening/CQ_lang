// ArithLowering.cpp — per-instruction lowering for the two data-arithmetic
// classes (binary + unary `fneg`). See header for the operand-shape rules.
// Generalizes the Phase-2 `add`/`fadd` body to all 16 in-scope stems with
// HH/HL/LH shapes and commutativity-gated BirthOrder; the driver
// (`OpcodeLowering`) owns collection, program order, and erase.

#include "ArithLowering.h"

#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// Promote `repl` into the taint set as the lowered replacement for `orig`,
// drop `orig` from the set, and give `repl` the next BirthOrder slot. This
// is the exact Phase-2 bookkeeping, shared by the binary and unary paths.
// The driver erases `orig` afterward (we only RAUW + bookkeep here).
void promote(Value *repl, Instruction *orig, TaintSet &taint) {
  taint.Tainted.insert(repl);
  taint.Tainted.erase(orig);
  taint.BirthOrder[repl] = taint.NextBirth++;
}

}  // namespace

bool rewriteBinary(BinaryOperator *bo, WidthDispatch &wd, TaintSet &taint) {
  // Stem + width gating. An out-of-scope opcode (`binaryStem` empty) or an
  // unsupported width (`abiWidthFromType` empty) hits the loud diagnostic
  // and is left un-lowered — the driver must not erase it.
  StringRef Stem = binaryStem(bo->getOpcode());
  if (Stem.empty()) {
    diagnoseNoTemplate(bo);
    return false;
  }
  StringRef AbiWidth = abiWidthFromType(bo->getType());
  if (AbiWidth.empty()) {
    diagnoseNoTemplate(bo);
    return false;
  }
  // Domain sanity: integer stems must land on an integer width and fp
  // stems on an fp width. `binaryStem` already partitions the opcodes; this
  // guards against malformed IR picking a mismatched template.
  const bool FpStem = bo->getType()->isFloatingPointTy();
  const bool IntStem = bo->getType()->isIntegerTy();
  const bool WantsFp = Stem.starts_with("f");  // fadd/fsub/fmul/fdiv/frem
  if ((WantsFp && !FpStem) || (!WantsFp && !IntStem)) {
    diagnoseNoTemplate(bo);
    return false;
  }

  IRBuilder<> Builder(bo);
  Value *A = bo->getOperand(0);
  Value *B = bo->getOperand(1);

  // Operand classification by taint membership (authoritative — covers
  // tainted args/loads as handles and untainted args/literals/globals as
  // classical; `isa<Constant>` would misclassify both, which the
  // `lowering_q_plus_arg` fixture pins).
  const bool ATainted = taint.Tainted.count(A) != 0;
  const bool BTainted = taint.Tainted.count(B) != 0;
  const bool Commutative = isCommutative(bo->getOpcode());

  Value *Lhs = nullptr;
  Value *Rhs = nullptr;
  Shape ShapeSel;
  if (ATainted && BTainted) {
    // HH → symmetric QQ template. Commutative: order by BirthOrder (lower
    // → LHS) for stable traces. Non-commutative: preserve source order
    // (the BirthOrder swap is gated OFF — operand order is semantic).
    Lhs = A;
    Rhs = B;
    if (Commutative) {
      const unsigned BA = taint.BirthOrder.lookup(A);
      const unsigned BB = taint.BirthOrder.lookup(B);
      // 0 means "unassigned"; only swap when both are known and B is
      // lower-birth. Falls back to source order otherwise (harmless).
      if (BA != 0 && BB != 0 && BB < BA) {
        Lhs = B;
        Rhs = A;
      }
    }
    ShapeSel = Shape::QQ;
  } else if (Commutative) {
    // One tainted, commutative → always handle-on-left, literal-on-right
    // `_hl(handle, classical)` regardless of which source side held the
    // classical (the BirthOrder/canonicalization swap is ON).
    Lhs = ATainted ? A : B;
    Rhs = ATainted ? B : A;
    ShapeSel = Shape::HL;
  } else if (ATainted) {
    // Non-commutative, handle on the left, classical on the right → `_hl`
    // with source order preserved.
    Lhs = A;
    Rhs = B;
    ShapeSel = Shape::HL;
  } else {
    // Non-commutative, classical on the left, handle on the right (e.g.
    // `100 - x`, `3 << x`) → `_lh(classical, handle)`, order preserved.
    Lhs = A;
    Rhs = B;
    ShapeSel = Shape::LH;
  }

  FunctionCallee Callee = wd.dataTemplateFn(Stem, AbiWidth, ShapeSel);
  if (!Callee) {
    diagnoseNoTemplate(bo);
    return false;
  }
  CallInst *T = Builder.CreateCall(Callee, {Lhs, Rhs}, "h_op");
  if (DebugLoc DL = bo->getDebugLoc())
    T->setDebugLoc(DL);
  bo->replaceAllUsesWith(T);
  promote(T, bo, taint);
  return true;
}

bool rewriteUnary(UnaryOperator *uo, WidthDispatch &wd, TaintSet &taint) {
  // `fneg` is the only in-scope unary data op. Anything else is out of
  // scope → loud diagnostic, left un-lowered.
  if (uo->getOpcode() != Instruction::FNeg) {
    diagnoseNoTemplate(uo);
    return false;
  }
  StringRef AbiWidth = abiWidthFromType(uo->getType());
  if (AbiWidth.empty() || !uo->getType()->isFloatingPointTy()) {
    diagnoseNoTemplate(uo);
    return false;
  }

  FunctionCallee Callee = wd.dataTemplateFn("fneg", AbiWidth, Shape::Unary);
  if (!Callee) {
    diagnoseNoTemplate(uo);
    return false;
  }
  IRBuilder<> Builder(uo);
  // The operand is the tainted handle (taint reached this fneg through it);
  // the (i32)->i32 unary template consumes it directly.
  CallInst *T = Builder.CreateCall(Callee, {uo->getOperand(0)}, "h_fneg");
  if (DebugLoc DL = uo->getDebugLoc())
    T->setDebugLoc(DL);
  uo->replaceAllUsesWith(T);
  promote(T, uo, taint);
  return true;
}

}  // namespace cq
