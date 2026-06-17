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

#include "llvm/IR/Constants.h"
#include "llvm/IR/InstrTypes.h"
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

  // ACCEPT — a const-folded phase arm over the tainted handle H. Re-anchor the
  // routed handle by SSA identity (for an if/else's first arm `Routed` was null;
  // for a diamond it already equals H). `Region.RoutedBase` carries it to
  // `emitRegion` so the eq-fold IF/ELSE routes H, not the folded constant base.
  Routed = H;
  Region.RoutedBase = H;
  return true;
}

}  // namespace cq
