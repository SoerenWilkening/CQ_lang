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

// Per-op stale-record check (shared by the straight-line guard and the
// post-lift re-check, Rule 14). For each tainted operand of `I`, walk its
// forward in-place-gate wire; if it gains a non-diagonal gate not provably
// after `I`'s emission point, fire the loud diagnostic, record `I` in
// `StaleDeclined` (so `lowerOps` lowers nothing for it), and return true. `DT`
// must be the dominator tree of `I`'s function.
bool checkStaleOp(Instruction &I, TaintSet &taint, DominatorTree &DT) {
  if (taint.StaleDeclined.count(&I))
    return false;  // already declined — idempotent across the post-lift re-sweep.
  for (Value *Op : I.operands()) {
    if (!taint.Tainted.count(Op))
      continue;  // classical operand — no wire.
    if (findNonDiagonalWireGate(Op, /*CrossValueRouting=*/true, &I, &DT)) {
      diagnoseStaleRecord(&I);
      taint.StaleDeclined.insert(&I);
      return true;  // one diagnostic per op; lowerOps will skip it.
    }
  }
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
        if (!DT)
          DT.emplace(F);  // a tainted in-scope op always has a tainted operand.
        checkStaleOp(I, taint, *DT);
      }
    }
  }
}

void declineLiftedStaleRecordOps(Module &M, TaintSet &taint) {
  // Re-adjudicate stale records exposed by the one-register merge-phi lift
  // (test_C_libtooling-2qyz). `liftOneRegisterMergePhi` (declineClassicalMuxes)
  // RAUWs a proven pure-renaming phi to its wire BASE and erases it — AFTER
  // `declineStaleRecordOps` already ran. An in-scope op that consumed the phi
  // (directly or through intervening in-place-gate hops) now resolves to the
  // base, so a sibling Ry re-rotating the base's wire — invisible to the first
  // guard, whose backward closure stops at the opaque PHINode — now stales it.
  //
  // The re-check is a FULL re-sweep, NOT scoped to the phi's direct users. A
  // Rule-13 adversarial probe (2026-06-11) showed that scoping to the recorded
  // direct consumers is INCOMPLETE: a stale arithmetic op can sit ANY number of
  // in-place-gate hops (a diagonal `cq_phi`/Rz, or a chained `cq_theta`/Ry, both
  // valid wire-sharing users that are not themselves `lowerOps` ops) downstream
  // of the lifted phi, so the genuine stale op is a TRANSITIVE user the direct
  // re-check never visits — a residual silent miscompile. Re-running the
  // COMPLETE `declineStaleRecordOps` on the post-lift IR adjudicates every
  // exposed op: the phi is now the base SSA value, so the (unchanged) WireWalk
  // closure walks each consumer's wire all the way to the origin and finds the
  // sibling regardless of how many hops away the consumer sits (Rule 14 — reuse
  // the exact analysis, add no parallel wire-walk).
  //
  // Gated on a lift having occurred (`LiftedConsumers` is the witness, populated
  // by `liftOneRegisterMergePhi`): a module with no lift skips the re-sweep
  // entirely, so NO message-ownership churn on non-lift fixtures (opt exits at
  // the first DS_Error). The re-sweep is idempotent — `checkStaleOp` skips ops
  // already in `StaleDeclined`, so the first pass's diagnostics are neither
  // duplicated nor re-pointed; only newly-exposed ops are diagnosed (with the
  // accurate stale-record message — the lift proved the phi a pure renaming, so
  // the residual defect IS a stale record). Still BEFORE any rotation lowering
  // (pre-RAUW SSA identity).
  if (taint.LiftedConsumers.empty())
    return;  // no lift occurred — nothing to re-adjudicate.
  declineStaleRecordOps(M, taint);
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
          // Capture widths NOW, before any sibling Phase-2 rewrite RAUWs the
          // operand and makes `getSrcTy()` read the i32 handle (risk R1).
          // `rewriteCast` consumes exactly this captured pair — never the live
          // operand type. This up-front capture is what makes the measured-
          // compare zext bridge emit `cq_template_zext_i1_to_i32` not garbage.
          StringRef FromW = abiWidthFromType(Cast->getSrcTy());
          // BUT a cast directly off a tainted THETA handle is already
          // laundered: RotationLowering (which runs BEFORE lowerOps) RAUW'd the
          // possibly-non-i32 theta result to its i32 handle, so `getSrcTy()`
          // here reads the laundered i32, not the logical source width. Recover
          // it from HandleWidth — the same Increment-A side-table the Q+Q
          // compare path reads, recorded at the theta mint (RotationLowering)
          // and on every arith/cast handle output. For a sibling Phase-2 source
          // (a compare/arith/cast result not yet rewritten at this point)
          // `getSrcTy()` still reads the correct pre-rewrite type and the
          // lookup is empty, so the recovery is inert. That inertness is
          // LOAD-BEARING and rests on an ordering invariant: every Arith/Cast/
          // Compare HandleWidth write happens in Phase 2 (promote(), after
          // RAUW), strictly AFTER this whole Phase-1 capture loop — so no
          // sibling result is in HandleWidth yet here. (Even if one were, its
          // recorded width equals its own result width == this cast's
          // getSrcTy(), so an override would coincide, never give a wrong
          // width.) Only RotationLowering, which runs BEFORE lowerOps,
          // pre-populates HandleWidth for a theta handle — exactly the laundered
          // case this recovery fixes. Without it, a cast off a non-i32 tainted
          // source — `fpext f16->f32`, `sext i8->i32`, `fptosi f16->i32`, ... —
          // captured "i32" and declined (the f16 cast surface, and the latent
          // non-i32-source-cast gap, were unreachable).
          if (StringRef R = taint.HandleWidth.lookup(Cast->getOperand(0));
              !R.empty())
            FromW = R;
          CastW[Cast] = {FromW, abiWidthFromType(Cast->getDestTy())};
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
