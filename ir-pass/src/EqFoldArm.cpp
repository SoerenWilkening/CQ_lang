// EqFoldArm.cpp — The equality-folded `br` diamond accept clause (4.5 WI-5).
// See EqFoldArm.h for the contract and the const-fold rationale.
//
// All analysis is pure SSA reading by value identity, before any mutation
// (Rule 9). The clause is strictly additive: it ONLY turns a const-folded phase
// arm `classifyArms` already declines into an accept; every miss returns false
// and the existing decline paths run unchanged (over-decline is safe — Prime
// Directive). It reuses `armBlockIsPureSpine`/`taintedAngleGate` (ArmAnalysis.h)
// for D6/D7 rather than re-deriving them (Rule 14).

#include "EqFoldArm.h"

#include "ArmAnalysis.h"
#include "ControlPlan.h"
#include "TaintPropagation.h"

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Value.h"

using namespace llvm;

namespace cq {

bool tryEqFoldArm(ControlRegion &Region, const BasicBlock *ArmBB,
                  Value *ArmIncoming, Value *Base, Value *&Routed,
                  TaintSet &Taint) {
  // D1 — the condition is an EQUALITY compare (`icmp eq`/`ne`). Only equality
  //      constrains the operand to a single value, which is what lets `clang
  //      -O1` const-fold `q` to the case literal inside the arm; an ordering
  //      compare (`sgt`/…) never folds and must not be re-anchored here.
  auto *Cond = dyn_cast_or_null<CmpInst>(Region.Condition);
  if (!Cond || !Cond->isEquality())
    return false;

  // D2 — the phase spine bottomed at a `ConstantInt k` (the const-fold), not a
  //      live handle. An un-folded arm bottoms at the routed handle and is
  //      handled by the ordinary `Base == Routed` / leaf-base phase paths; this
  //      clause exists ONLY for the folded-constant base.
  auto *K = dyn_cast<ConstantInt>(Base);
  if (!K)
    return false;

  // D3 — the compare's operands are exactly { one `ConstantInt` C, one
  //      non-constant handle H }, and H is the routed handle. `clang -O1`
  //      canonicalizes the constant to either side, so locate it position-free.
  //      A both-constant or both-non-constant compare is not an eq-fold mint
  //      (return false → fall through → decline). When the region already
  //      anchored a routed handle (a diamond's straight-through, or a prior
  //      arm), H must EQUAL it — a mismatch is a genuine cross-handle multiplexer
  //      (`if(p==k){ q… }`) and MUST fall through to the existing `control flow`
  //      decline (do not weaken that gate; bd test_C_libtooling-bkpz.5 D3).
  auto *C0 = dyn_cast<ConstantInt>(Cond->getOperand(0));
  auto *C1 = dyn_cast<ConstantInt>(Cond->getOperand(1));
  ConstantInt *C = nullptr;
  Value *H = nullptr;
  if (C1 && !C0) {
    C = C1;
    H = Cond->getOperand(0);
  } else if (C0 && !C1) {
    C = C0;
    H = Cond->getOperand(1);
  } else {
    return false;  // neither (two handles) or both (two constants) operands.
  }
  if (Routed && H != Routed)
    return false;  // cross-handle mux — not this arm's routed handle.

  // D4 — the compare literal C equals the folded spine constant k (same width
  //      AND same value). A mismatch (`icmp eq q,7` but the arm folds to
  //      `cq_phi(9,…)`) is an off-pattern shape we cannot prove equals a routed
  //      phase arm — fall through to the `control flow` decline (D4 fixture).
  if (C->getType() != K->getType() || C->getValue() != K->getValue())
    return false;

  // D5 — the routed operand is a tainted quantum handle (criterion 3); a
  //      classical operand is no qubit to route (`icmp_inv` could not strip the
  //      flag off a classical wire).
  if (!Taint.Tainted.count(H))
    return false;

  // D6 — the arm block is a pure phase spine: no fan-out sibling, no stray op
  //      the emitter would silently drop or leave dangling (Rule 8). Reuses the
  //      de-anonymized `armBlockIsPureSpine` (ArmAnalysis.h).
  if (!armBlockIsPureSpine(ArmBB, ArmIncoming))
    return false;

  // D7 — every rotation angle on the spine is classical. A tainted arg-1 angle
  //      has no fixed unitary (the emitter would replay a runtime handle tag —
  //      the f64/angle miscompile family, Rule 3). Reuses `taintedAngleGate`.
  if (taintedAngleGate(ArmIncoming, ArmBB, Base, Taint) != nullptr)
    return false;

  // D8 — POLARITY: `ArmBB` must be the successor on which the equality HOLDS.
  //      D1–D7 prove the arm's spine bottomed at the SAME literal the compare
  //      names; they never ask WHICH edge the arm sits on. The fold `H → k` is
  //      sound only where `H == k` is a THEOREM — the TRUE successor of an
  //      `icmp eq`, the FALSE successor of an `icmp ne`. On the opposite edge
  //      `k` is precisely the value `H` does NOT hold, so `cq_phi(k, θ)` is a
  //      value CLOBBER (the merge takes the rotated CONSTANT, discarding `H`),
  //      not a phase on `H`; re-anchoring it names the wrong basis and the
  //      emitter puts `cqrt_rz_<W>_controlled(f, H, θ)` on exactly the branch
  //      where the source does not rotate `H` at all — a verify-clean wrong
  //      unitary (bd test_C_libtooling-ogw2). This mirrors, one edge over, the
  //      `StraightProvesEq` discipline `straightThroughConstFoldHandle`
  //      (ArmClassify.cpp) already applies to the Pred edge.
  //
  //      ⚠ `control_swap_eqfold_polarity.ll` — `icmp ne` with the folded arm on
  //      the FALSE successor — is the VALID negated shape (`ne`-false IS the
  //      `H == k` region) and MUST STAY ACCEPTING; so is `@ifelse_ne` in
  //      control_swap_eqfold_ifelse.ll. Polarity is a proof obligation, not a
  //      preference for `ArmNegated == false`.
  //
  //      From `clang -O1` C the wrong edge is unreachable (clang folds the
  //      straight-through incoming too, and the region then declines
  //      elsewhere), so this is a HAND-IR over-accept — but a decline is what
  //      the shape is owed either way (Prime Directive). Every miss returns
  //      false, so the existing `control flow` decline fires unchanged.
  auto *Br = dyn_cast_or_null<BranchInst>(
      Region.Pred ? Region.Pred->getTerminator() : nullptr);
  if (!Br || !Br->isConditional() || Br->getCondition() != Cond)
    return false;  // no branch on this compare in the region's pred.
  bool ArmIsTrueEdge;
  if (Br->getSuccessor(0) == ArmBB && Br->getSuccessor(1) != ArmBB)
    ArmIsTrueEdge = true;
  else if (Br->getSuccessor(1) == ArmBB && Br->getSuccessor(0) != ArmBB)
    ArmIsTrueEdge = false;
  else
    return false;  // ArmBB is both successors (or neither) — nothing is proven.
  bool ArmProvesEq;
  if (Cond->getPredicate() == CmpInst::ICMP_EQ)
    ArmProvesEq = ArmIsTrueEdge;
  else if (Cond->getPredicate() == CmpInst::ICMP_NE)
    ArmProvesEq = !ArmIsTrueEdge;
  else
    return false;  // an fcmp equality (D2/D3 make it unreachable) proves nothing
                   // about a ConstantInt fold — decline rather than assume.
  if (!ArmProvesEq)
    return false;

  // ACCEPT — a const-folded phase arm over the tainted handle H. Re-anchor the
  // routed handle by SSA identity (for an if/else's first arm `Routed` was null;
  // for a diamond it already equals H). `Region.RoutedBase` carries it to
  // `emitRegion` so the eq-fold IF/ELSE routes H, not the folded constant base.
  Routed = H;
  Region.setRoutedBase(H);
  return true;
}

}  // namespace cq
