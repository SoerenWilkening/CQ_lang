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
#include "WireWalk.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <optional>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Loud decline for a stale-record pure producer. Same
// `DiagnosticInfoUnsupported(DS_Error)` surface + `!dbg` source location as
// the rest of the pass; the negative fixtures mirror the message
// character-for-character (Rule 12).
void diagnoseStaleRecord(Instruction *I) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(),
      "cq opcode lowering: operand predates a non-diagonal gate",
      I->getDebugLoc()));
}

// Is `I` an instruction `lowerOps` would collect? Mirrors the Phase-1
// collection below exactly: the four tainted classes, with branch/select-
// condition compares excluded (Phase 4's — ArmClassify owns their stale
// check via the provenance-seeded wire walk and its own diagnostic).
bool inLowerOpsScope(Instruction &I, TaintSet &taint) {
  if (!taint.Tainted.count(&I))
    return false;
  if (isa<BinaryOperator>(&I) || isa<UnaryOperator>(&I) || isa<CastInst>(&I))
    return true;
  if (auto *Cmp = dyn_cast<CmpInst>(&I))
    return isDataPositionCompare(Cmp);
  return false;
}

}  // namespace

void declineStaleRecordOps(Module &M, TaintSet &taint) {
  // WHY POSITION-AWARE (and why that is not the MINT_AT_COMPARE §4 trap):
  // a pure tainted producer's template is emitted AT THE PRODUCER'S OWN
  // scheduled position, and opaque calls keep their order through the
  // backend — so the schedule this pass sees IS the emitted gate stream.
  // The §4 lesson ("position is not provenance") condemned inferring wire
  // state at one point (the branch-time mint) from the schedule of ANOTHER
  // instruction (the compare); here the inspected point and the emission
  // point are the same instruction, so dominance over the operand's wire
  // gates is exactly the emitted-stream order. Consequences:
  //   * `d = q + 1` SCHEDULED BEFORE a chained `theta(q, t2)` stays
  //     accepted: the template fires pre-Ry, capturing the record onto its
  //     own fresh rail — matching SSA semantics — and the later Ry on `q`'s
  //     wire cannot touch that rail (fixture
  //     lowering_stale_record_add_before_theta.ll pins this boundary).
  //   * the same op SCHEDULED AFTER the chained theta declines: the
  //     template would read the post-Ry basis while `%d` denotes the
  //     pre-Ry record (the confirmed verify-clean miscompile; fixture
  //     lowering_reject_stale_record_add.ll).
  //   * a position-FREE rule would over-decline the first shape — a
  //     legitimate use-then-re-rotate program — for no soundness gain.
  // Diagonal gates (`cq_phi`/Rz) on the wire are basis-preserving and never
  // trigger (bd memory rz-diag-flag-strip-invariant; fixture
  // lowering_stale_record_add_after_phi.ll). An operand that is itself a
  // diagonal ALIAS (`%qd = cq_phi(%q, ·)`) shares `%q`'s physical wire, so a
  // chained theta consuming the SIBLING name `%q` stales it too — the wire
  // walk closes every seed backward through `cq_phi` arg-0 hops before
  // walking forward (test_C_libtooling-6j1; fixtures
  // lowering_reject_stale_record_alias_{sibling,chain}.ll, accept twins
  // lowering_stale_record_alias_{before_theta,producer}.ll).
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Built lazily — only when a tainted in-scope op exists in `F`.
    std::optional<DominatorTree> DT;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (!inLowerOpsScope(I, taint))
          continue;
        for (Value *Op : I.operands()) {
          if (!taint.Tainted.count(Op))
            continue;  // classical operand — no wire.
          if (!DT)
            DT.emplace(F);
          if (findNonDiagonalWireGate(Op, /*CrossValueRouting=*/true, &I,
                                      &*DT)) {
            diagnoseStaleRecord(&I);
            taint.StaleDeclined.insert(&I);
            break;  // one diagnostic per op; lowerOps will skip it.
          }
        }
      }
    }
  }
}

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
        // Stale-record decline (test_C_libtooling-uzb): the diagnostic
        // already fired in `declineStaleRecordOps` (which ran before any
        // mutation); lower NOTHING for this op (emitting its template here
        // would put the wrong unitary in the stream — the template reads
        // the post-Ry basis while the SSA operand denotes the pre-Ry
        // record). Never enqueued ⇒ never rewritten ⇒ never erased.
        if (taint.StaleDeclined.count(&I))
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
