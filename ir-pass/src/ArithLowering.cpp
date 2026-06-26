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
//
// Phase 7.1 Increment A: `handleWidth` records the lowered handle's LOGICAL
// ABI width on `repl` (the data result width — Increment A's first reader is
// the Q+Q data-position compare, which recovers it from `HandleWidth`). Empty
// ⇒ no record (the pre-7.1 behavior; a genuinely-missing entry rides the Q+Q
// decline rather than defaulting to i32). R-A scrub: `HandleWidth.erase(orig)`
// mirrors the `Tainted.erase` — with `Value*` pointer reuse a stale entry at
// `orig`'s reused address would otherwise feed a wrong width into a later Q+Q
// compare (a verify-clean miscompile). The erase happens UNCONDITIONALLY (even
// when `handleWidth` is empty) so no stale `orig` record survives.
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
  // Record the result handle's LOGICAL width (the binary op's own ABI width,
  // already validated non-empty at :45) so a downstream Q+Q data compare can
  // recover it (Increment A). The i32-laundered handle type loses this width.
  promote(T, bo, taint, AbiWidth);
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
  // Record the fneg result handle's LOGICAL fp width (validated non-empty at
  // :134) for a downstream Q+Q fp data compare (Increment A).
  promote(T, uo, taint, AbiWidth);
  return true;
}

bool rewriteInPlaceValueRail(BinaryOperator *bo, WidthDispatch &wd,
                             TaintSet &taint) {
  // `bo` is a `lowerLoops`-proven rail self-update (issue dtzb). Pick the
  // in-place symbol by opcode; the logical width is the op's OWN result type
  // (the rail operand was RAUW'd to the i32 handle by rotation lowering, but
  // `bo`'s result type still carries the width — the cross-type-laundered
  // operand never changes `bo`'s type).
  StringRef AbiWidth = abiWidthFromType(bo->getType());
  FunctionCallee Callee = bo->getOpcode() == Instruction::Xor
                              ? wd.xorcFn(AbiWidth)
                              : wd.addcFn(AbiWidth);
  if (!Callee) {
    // Unsupported width — `inPlaceValueRailOperand` applies the SAME ≤64-integer
    // fence, so this is unreachable; never mint a phantom symbol or leave an
    // ill-typed op (Rule 1). Loud decline.
    diagnoseNoTemplate(bo);
    return false;
  }
  // Exactly one operand is tainted (the rail handle, i32 by now — handles join
  // `Tainted` at the theta mint); the other is the classical immediate at the
  // rail's logical width. The recognizer proved this (one tainted operand), so
  // the selection is unambiguous.
  Value *L = bo->getOperand(0), *R = bo->getOperand(1);
  bool TL = taint.Tainted.count(L) != 0;
  Value *Handle = TL ? L : R;
  Value *Imm = TL ? R : L;
  IRBuilder<> Builder(bo);
  CallInst *C = Builder.CreateCall(Callee, {Handle, Imm});
  if (DebugLoc DL = bo->getDebugLoc())
    C->setDebugLoc(DL);
  // In-place: the result IS the rail handle (same register, mutated state). RAUW
  // to the handle — a no-op when the Case-A phi collapse already left `bo`
  // use-empty (the single-op value accumulator), and the correct rewire for a
  // chained self-update (`q1 = q ^ 9; q2 = q1 ^ 3` — `q1`'s RAUW feeds `q2`). The
  // void in-place gate is not itself a tainted producer; the handle stays
  // tainted. The driver erases `bo`.
  bo->replaceAllUsesWith(Handle);
  return true;
}

}  // namespace cq
