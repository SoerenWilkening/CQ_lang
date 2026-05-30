// OpcodeLowering.cpp — the single ordered driver for tainted data-opcode
// lowering (Phase 3; PRD §2.2/§2.3, IMPLEMENTATION §1.4/§5.3). It owns
// collection, program order, cast-width capture, dispatch, and erase; the
// per-instruction emit + RAUW + bookkeeping lives in the class lowerers
// (`ArithLowering`, `CompareLowering`, `CastLowering`).
//
// One program-order walk over all four tainted instruction classes
// (`BinaryOperator`, `UnaryOperator`, `CmpInst`, `CastInst`) builds:
//   * `Work`  — instructions to rewrite, in program order. SSA dominance
//     guarantees producers precede consumers, so when a consumer is
//     rewritten its operands are already template handles (RAUW propagated
//     them) and already in `taint.Tainted` (IMPLEMENTATION §1.4).
//   * `CastW` — captured (from,to) ABI widths per tainted cast, recorded
//     BEFORE any rewrite mutates an operand. `CastInst::getSrcTy()` reads
//     `getOperand(0)->getType()`, so once the operand is RAUW'd to an i32
//     handle the source width is lost (PRD §2.3 / risk R1). Capture is why
//     collection is fully up-front.
//
// After collection the driver iterates `Work`, dispatches by `dyn_cast` to
// the matching rewriter, and erases ONLY the instructions that were
// actually rewritten. A rewriter returns false when it diagnosed/left an
// op un-lowered (unsupported opcode/width) — that op must stay in the IR
// (erasing a still-used value would corrupt it / break `opt -verify`).
//
// All four classes are live: binary + unary (ArithLowering), compare
// (CompareLowering), and cast (CastLowering). Each rewriter returns false on
// an unsupported op so the driver leaves it un-lowered and `opt -verify`
// stays clean.

#include "OpcodeLowering.h"

#include "ArithLowering.h"
#include "CastLowering.h"
#include "CompareLowering.h"
#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <vector>

using namespace llvm;

namespace cq {

void lowerOps(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // ── Phase 1: one program-order collection over all four classes ──
  // Gated by taint membership. Casts also capture (from,to) widths here,
  // before any rewrite corrupts the operand type (PRD §2.3).
  std::vector<Instruction *> Work;
  DenseMap<CastInst *, CastWidths> CastW;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (!taint.Tainted.count(&I))
          continue;
        if (isa<BinaryOperator>(&I) || isa<UnaryOperator>(&I)) {
          Work.push_back(&I);
        } else if (auto *Cmp = dyn_cast<CmpInst>(&I)) {
          // A branch/select-feeding compare is Phase 4's — never enqueue
          // it (so it is never rewritten or erased). Data-position compares
          // are enqueued and lowered by CompareLowering::rewriteCompare.
          if (isDataPositionCompare(Cmp))
            Work.push_back(&I);
        } else if (auto *Cast = dyn_cast<CastInst>(&I)) {
          // Capture widths NOW, before any rewrite RAUWs the operand and
          // makes `getSrcTy()` read the i32 handle (risk R1). `rewriteCast`
          // consumes exactly this captured pair — never the live operand
          // type. This up-front capture is what makes the measured-compare
          // zext bridge emit `cq_template_zext_i1_to_i32` instead of garbage.
          CastW[Cast] = {abiWidthFromType(Cast->getSrcTy()),
                         abiWidthFromType(Cast->getDestTy())};
          Work.push_back(&I);
        }
      }
    }
  }

  if (Work.empty())
    return;

  // ── Phase 2: rewrite in program order, dispatch by dyn_cast ──
  // Each rewriter does emit + RAUW + taint/BirthOrder bookkeeping and
  // returns true iff it rewrote the op (and the driver may erase it).
  // false ⇒ diagnosed/inert/left un-lowered ⇒ MUST NOT be erased.
  std::vector<Instruction *> ToErase;
  for (Instruction *I : Work) {
    bool Rewritten = false;
    if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      Rewritten = rewriteBinary(BO, wd, taint);
    } else if (auto *UO = dyn_cast<UnaryOperator>(I)) {
      Rewritten = rewriteUnary(UO, wd, taint);
    } else if (auto *Cmp = dyn_cast<CmpInst>(I)) {
      Rewritten = rewriteCompare(Cmp, wd, taint);
    } else if (auto *Cast = dyn_cast<CastInst>(I)) {
      Rewritten = rewriteCast(Cast, CastW[Cast], wd, taint);
    }
    if (Rewritten)
      ToErase.push_back(I);
  }

  // ── Phase 3: erase only the rewritten originals ──
  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace cq
