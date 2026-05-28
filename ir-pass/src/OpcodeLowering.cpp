// OpcodeLowering.cpp — Lower tainted arithmetic to per-width template
// calls. M16 generalizes from the Phase 1 `add i32`-only path to:
//
//   add iW  → cq_template_add_iW(_hl)  for W ∈ {1, 8, 16, 32, 64}
//   fadd fW → cq_template_fadd_fW(_hl) for fW ∈ {float, double}
//
// Per-width selection comes from the operand type:
// `Type::getIntegerBitWidth()` for integers, `isFloatTy()` / `isDoubleTy()`
// for floats. Q+Q vs Q+C dispatch is unchanged from Phase 1 — taint-set
// membership of each operand drives it; the symbol name is now produced
// through `WidthDispatch::addTemplate(abiWidth, isQQ)` instead of being
// hardcoded.
//
// Negative path: a tainted instruction whose opcode is not `add` or
// `fadd` (e.g., `sub`, `mul`) — or one whose width has no template (e.g.,
// `fadd half`) — produces a `DiagnosticInfoUnsupported` "no template for
// opcode" error. PRD §"Diagnostics baseline" mandates this stay loud,
// not silent, in Phase 2; Phase 3 widens template coverage.

#include "OpcodeLowering.h"

#include "MidHandleRebind.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Resolve a value's LLVM type to its ABI-width string ("i1"/.../"f64")
// per PRD §"Width unification". Returns "" for unsupported widths (e.g.,
// `half`, `fp128`, `i128`); the caller emits a "no template" diagnostic
// in that case. Integer widths are restricted to the 5 supported
// {1,8,16,32,64}; any other integer width (e.g., i24, i128) is unsupported.
StringRef abiWidthFromType(Type *Ty) {
  if (!Ty)
    return {};
  if (auto *IT = dyn_cast<IntegerType>(Ty)) {
    switch (IT->getBitWidth()) {
    case 1:  return "i1";
    case 8:  return "i8";
    case 16: return "i16";
    case 32: return "i32";
    case 64: return "i64";
    default: return {};
    }
  }
  if (Ty->isFloatTy())  return "f32";
  if (Ty->isDoubleTy()) return "f64";
  return {};
}

// Stringify an instruction's opcode and operand type for diagnostics.
// Produces text like "sub i32" or "fadd half" so a LIT fixture can pin
// the failure mode without depending on the SSA name LLVM picks.
std::string opcodeDescription(BinaryOperator *BO) {
  std::string s;
  raw_string_ostream os(s);
  os << BO->getOpcodeName() << ' ';
  BO->getType()->print(os);
  return os.str();
}

// "No template for opcode" diagnostic. Failure must be loud, not
// silent. We use `DiagnosticInfoUnsupported` to match MeasureLowering's
// pattern (one consistent diagnostic surface across the pass). The
// string carries enough detail that a downstream LIT fixture can
// FileCheck a recognizable substring.
void diagnoseNoTemplate(BinaryOperator *BO) {
  std::string Detail = opcodeDescription(BO);
  std::string Msg = "no template for opcode '" + Detail +
                    "' in tainted context";
  BO->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *BO->getFunction(), Msg));
}

}  // namespace

void lowerOps(Module &M, WidthDispatch &wd, TaintSet &taint,
              RebindMap &rebind) {
  // Walk every tainted BinaryOperator (any opcode) in BB / function
  // order. Collecting up front (rather than walking-and-rewriting in
  // the same loop) sidesteps iterator-invalidation when each lowering
  // RAUWs the original instruction. We catch unsupported opcodes here
  // too so a tainted `sub i32` is reported (loud) rather than left
  // silently in the IR for the verifier to swallow.
  std::vector<BinaryOperator *> TaintedBOs;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO)
          continue;
        if (!taint.Tainted.count(BO))
          continue;
        TaintedBOs.push_back(BO);
      }
    }
  }

  if (TaintedBOs.empty())
    return;

  IRBuilder<> Builder(wd.context());
  std::vector<Instruction *> ToErase;

  for (BinaryOperator *BO : TaintedBOs) {
    // Filter to supported opcodes. `add` covers integer widths
    // {i1, i8, i16, i32, i64}; `fadd` covers {float, double}. Any
    // other opcode (sub, mul, ...) hits the negative path.
    unsigned Op = BO->getOpcode();
    bool IsIntAdd = Op == Instruction::Add;
    bool IsFAdd   = Op == Instruction::FAdd;
    if (!IsIntAdd && !IsFAdd) {
      diagnoseNoTemplate(BO);
      continue;
    }

    // Resolve ABI width from the operand type. PRD §"Width unification":
    // 7 supported widths. Any other width (`half`, `i128`, ...) is
    // reported as unsupported, matching the "no template" surface.
    StringRef AbiWidth = abiWidthFromType(BO->getType());
    if (AbiWidth.empty()) {
      diagnoseNoTemplate(BO);
      continue;
    }
    // Sanity: integer adds must land on integer widths and float adds
    // on float widths. A tainted `add float` (impossible in well-typed
    // IR) would otherwise pick a Q+Q i-template silently.
    if (IsIntAdd && !BO->getType()->isIntegerTy()) {
      diagnoseNoTemplate(BO);
      continue;
    }
    if (IsFAdd && !BO->getType()->isFloatingPointTy()) {
      diagnoseNoTemplate(BO);
      continue;
    }

    Builder.SetInsertPoint(BO);
    Value *A = BO->getOperand(0);
    Value *B = BO->getOperand(1);

    // Dispatch on whether each operand carries a quantum handle.
    // taint.Tainted is authoritative — it covers literals (never
    // tainted) AND non-constant classical sources like fn-args and
    // loaded globals (also never tainted). isa<ConstantInt> would miss
    // the latter; the lowering_q_plus_arg fixture pins this.
    //
    //   * Q+Q (both tainted): symmetric cq_template_add_<W>, ordered
    //     by BirthOrder so the trace is clang-version-stable.
    //   * Q+C / C+Q: cq_template_add_<W>_hl(handle, classical) — swap
    //     when LLVM landed the classical on the lhs.
    //   * C+C: unreachable. A non-tainted op can't have entered the
    //     work list (TaintPropagation only seeds from init returns).
    bool ATainted = taint.Tainted.count(A) != 0;
    bool BTainted = taint.Tainted.count(B) != 0;

    Value *Lhs;
    Value *Rhs;
    bool IsQQ;
    if (ATainted && BTainted) {
      unsigned BA = rebind.BirthOrder.lookup(A);
      unsigned BB_ = rebind.BirthOrder.lookup(B);
      // If either side lacks a BirthOrder, fall back to LLVM's operand
      // order. Not expected in Phase 1/2 shapes but harmless.
      if (BA != 0 && BB_ != 0 && BB_ < BA) {
        Lhs = B;
        Rhs = A;
      } else {
        Lhs = A;
        Rhs = B;
      }
      IsQQ = true;
    } else if (ATainted) {
      Lhs = A;
      Rhs = B;
      IsQQ = false;
    } else {  // BTainted (C+C unreachable)
      Lhs = B;
      Rhs = A;
      IsQQ = false;
    }

    FunctionCallee Callee = wd.addTemplate(AbiWidth, IsQQ);
    CallInst *T = Builder.CreateCall(Callee, {Lhs, Rhs}, "h_sum");
    if (DebugLoc DL = BO->getDebugLoc())
      T->setDebugLoc(DL);
    BO->replaceAllUsesWith(T);

    // Promote the template result into the taint set; drop the now-
    // dead op (its pointer would otherwise dangle in the set after
    // erase). BirthOrder inherits the next slot so a subsequent Q+Q
    // canonicalization sees this handle.
    taint.Tainted.insert(T);
    taint.Tainted.erase(BO);
    rebind.BirthOrder[T] = rebind.NextBirth++;
    ToErase.push_back(BO);
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace cq
