// RegionFlatten.cpp — see header. CFG flatten for one control region: after its
// emitter has emitted the gate stream into the pred and rewired the data,
// collapse the dead diamond/if-else CFG into the single pred block.
//
// Block identities are captured BEFORE the first erase (the block-lifetime
// hazard — a `BasicBlock*` re-read through freed memory is a SIGSEGV on valid
// input). Erase order is deliberate: the conditional `br` first (so the arms go
// unreachable and the condition compare goes dead), then splice the merge's
// surviving instructions into the pred, then the dead arms before the emptied
// merge (an arm's `br label %merge` is the last reference to the merge block).

#include "RegionFlatten.h"

#include "ControlPlan.h"
#include "LiteralIntegrity.h"  // declineAddressTakenBlocks (bd 7udx)
#include "SelectClassify.h"    // isCondRailLeaf / isCondRailPhiShape (never erase a user's rail)
#include "RailWindow.h"        // isRailWindowCellRead (bd 01po.19 S6)
#include "RegCondLeaf.h"       // isRegCondLeaf (bd dm7f.77)
#include "TaintPropagation.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"  // llvm::reverse
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// so a later module walk (`lowerRotations` / `lowerOps` / `uncompute`) never
// dereferences freed memory (§6.1). A per-TU mirror of the same helper in
// SwapRouteEmit (the house style for trivial taint-set maintenance). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase_value(CI);
  }
}

}  // namespace

void flattenRegion(const ControlRegion &R, TaintSet &taint) {
  // Capture identities before any erase.
  BasicBlock *Pred = R.Pred;
  BasicBlock *Arm = R.Arm;
  BasicBlock *ArmFalse = R.ArmFalse;  // null for a diamond
  BasicBlock *Merge = R.MergeBB;
  if (!Pred || !Merge)
    return;
  auto *BI = dyn_cast<BranchInst>(Pred->getTerminator());
  auto *Cond = dyn_cast_or_null<Instruction>(R.Condition);

  // 0. bd 7udx — BEFORE the first erase. `BasicBlock::~BasicBlock()` replaces
  //    every `BlockAddress` of a destroyed block with `inttoptr (i32 1 to ptr)`,
  //    which folds through a `ptrtoint` to `i32 1` — so erasing an address-taken
  //    arm/merge silently rewrites the compared-against address to 1, on a
  //    WELL-DEFINED source with no UB and no refinement argument to excuse it.
  //    The RAUW is module-wide on the `BlockAddress`, so a bare
  //    `store ptr blockaddress(@f, %arm)` elsewhere is corrupted by the same
  //    erase. `Pred` is NOT listed — it survives the flatten.
  if (declineAddressTakenBlocks({Arm, ArmFalse, Merge}, BI))
    return;

  // 1. Drop the conditional branch — control is now straight-line. This leaves
  //    Pred terminator-less for exactly the next statement (no verify runs in
  //    between), and makes the arms unreachable + the condition compare dead.
  //    Scrub it first: the `br i1` is a USER of the tainted condition, so
  //    TaintPropagation put it in taint.Tainted — erasing without scrubbing
  //    leaves a dangling Instruction* whose heap address a later-minted
  //    instruction could reuse, turning membership probes into false taint
  //    (§6.1 hygiene; §8 adversarial review 2026-06-10). ⚠ Since bd 8e5r the
  //    set drops a deleted key by itself (`ScrubOnDelete.h`) — this is exactly
  //    the hazard that shipped from sites that did NOT scrub — so the explicit
  //    scrub here is now belt-and-braces.
  if (BI) {
    scrubTaint(BI, taint);
    BI->eraseFromParent();
  }

  // 2. Splice the merge block's surviving instructions (the measure / ret that
  //    consumed the RAUW'd phi — the phi itself was already erased upstream)
  //    onto the end of Pred. Pred's terminator becomes the merge's `ret`.
  Pred->splice(Pred->end(), Merge);

  // 3. The condition compare fed only the now-erased branch; erase it dead and
  //    scrub it from the taint set (the condition was tainted). Guard on
  //    use_empty so a (malformed) compare with a stray live use is left for the
  //    verifier rather than silently dropped.
  //    bd 3qlq.4: a RAIL-LEAF condition is the USER'S `cq_theta_i1` — never
  //    this stage's to erase, whatever its use count (the kickback gate keeps it
  //    live in every accepted region; defence in depth against erasing a user's
  //    rotation on a shape nobody measured).
  //    bd `boi6` (D-B) / Track M: the same for a REGION-MERGE φ
  //    (`isCondRailPhiShape`). IT HAS NO SUBJECT TODAY and that is stated as a
  //    measured fact, not a hedge — the only φ-conditioned construct Track M
  //    admits is a 4.4 DATA SELECT, which sets no `Pred`/`MergeBB` and therefore
  //    never reaches this stage, and the φ's own erasure belongs to the PREP
  //    region's `emitInPlaceRotationRegion` (which RAUWs it first, deliberately).
  //    It is added so that the first widening giving a φ-conditioned region a
  //    flatten of its own cannot re-open the L9 block-lifetime hole in silence:
  //    a φ is a MERGE node other instructions' SSA edges still name, and erasing
  //    one here would be exactly the "region whose predecessor is another
  //    region's merge block" family.
  // bd dm7f.77 — nor a REGISTER CONDITION (RegCondLeaf.h): a control emitter
  // may hold it only through a `WeakTrackingVH` (the state prep's recorded
  // control), and `lowerOps` turns it into the register that control reads.
  // bd 01po.19 S6 — nor a quantum-array CELL READ: the same recorded control,
  // retyped to the cell's handle at the rail-window slot.
  if (Cond && Cond->use_empty() && !isCondRailLeaf(Cond) &&
      !isCondRailPhiShape(Cond) && !isRegCondLeaf(Cond) &&
      !isRailWindowCellRead(Cond)) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }

  // 4. Delete the now-unreachable arm block(s), then the emptied merge block.
  if (Arm)
    Arm->eraseFromParent();
  if (ArmFalse)
    ArmFalse->eraseFromParent();
  // dugh (Phase 4×6): the merge block's spliced tail is USUALLY a clean
  // measure/`ret` sink, but with the second-propagation round the merge value
  // `%out` may now flow ONWARD into a downstream block structure whose head is
  // the merge's terminator — e.g. (pre-3qlq register form) `if (q>k) y=f(a);
  // if (cc) y=cq_phi(y,θ); measure y`, where `merge` ends in `br i1 %cc` and a
  // downstream block's phi lists `merge` as a predecessor. Splicing that
  // terminator into `Pred` moves control to `Pred`, but a PHI incoming BLOCK is
  // not an operand-use of the block, so `Merge`'s erase below leaves those phis
  // with a dangling `<badref>` predecessor (the merge-into-pred fixup prevents it).
  // Re-point every successor-phi incoming block `Merge → Pred` — a NO-OP for the
  // clean-tail case (a `ret` has no successors). Runs AFTER the splice (so `Pred`
  // owns the successors) and BEFORE the erase (so no phi dangles).
  Pred->replaceSuccessorsPhiUsesWith(Merge, Pred);
  Merge->eraseFromParent();
}

void flattenRegionTree(const ControlRegion &Outer, const ControlRegion &Inner,
                       ArrayRef<CallInst *> armPhis, TaintSet &taint) {
  // Capture EVERY block identity before the first erase (the block-lifetime
  // hazard). Outer.Arm is the `Mid` block (= Inner.Pred), which holds the
  // intervening gate(s) + the inner condition/branch; Inner.Arm is the inner
  // content arm; both reconverge at the SINGLE shared `Outer.MergeBB`
  // (== Inner.MergeBB), whose sole 3-incoming phi is `Outer.Merge`.
  auto *MergePhi = dyn_cast_or_null<PHINode>(Outer.Merge);
  BasicBlock *Pred = Outer.Pred;       // survives (holds the emitted stream)
  BasicBlock *Mid = Outer.Arm;         // doomed (= Inner.Pred)
  BasicBlock *InnerArm = Inner.Arm;    // doomed
  BasicBlock *Merge = Outer.MergeBB;   // doomed (shared — erased EXACTLY ONCE)
  // bd test_C_libtooling-3qlq Inc 1 part B — `MergePhi` MAY NOW BE NULL. The
  // register-free depth-2 PHASE NEST (`PhaseKickbackNest`) has no merge φ at all:
  // its arm gates are `void @cq_phi(double)`, so nothing flows out of either arm
  // and step 1 below has nothing to collapse. Every other step is unchanged and
  // is exactly what that nest needs (drop both branches, erase both dead
  // condition roots, splice the shared merge into `Pred` EXACTLY ONCE, erase
  // InnerArm → Mid → Merge in that order). A null φ is therefore a legitimate
  // plan, not a malformed one — but the OTHER anchors are still required.
  if (!Pred || !Mid || !InnerArm || !Merge)
    return;  // malformed plan — leave the IR for the verifier rather than crash.
  if (MergePhi && MergePhi->getBasicBlockIndex(Pred) < 0)
    return;
  auto *OuterBI = dyn_cast<BranchInst>(Pred->getTerminator());
  auto *InnerBI = dyn_cast<BranchInst>(Mid->getTerminator());
  auto *OuterCond = dyn_cast_or_null<Instruction>(Outer.Condition);
  auto *InnerCond = dyn_cast_or_null<Instruction>(Inner.Condition);

  // 0. bd 7udx — BEFORE the first erase; see the twin note in `flattenRegion`
  //    for the mechanism. All three doomed blocks are checked; `Pred` survives.
  if (declineAddressTakenBlocks({Mid, InnerArm, Merge}, OuterBI))
    return;

  // 1. (Pre-3qlq register-form nest only: the one caller passes a null φ.) The
  //    3-incoming merge phi collapses to the base `q`. RAUW → q so the
  //    measure that consumed the phi now reads `q`, then scrub + erase it. The
  //    nest is the SOLE owner of this phi (§6.1) — erasing it here, before
  //    `declineClassicalMuxes`, is what keeps the live 3-incoming tainted phi from
  //    false-declining `classical phi` on a half-mutated module.
  if (MergePhi) {
    Value *Q = MergePhi->getIncomingValueForBlock(Pred);
    MergePhi->replaceAllUsesWith(Q);
    scrubTaint(MergePhi, taint);
    MergePhi->eraseFromParent();
  }

  // 2. Branch-first: drop BOTH conditional branches (the inner `br` in `Mid`, then
  //    the outer `Pred`-tail). This leaves `Mid`/`Pred` terminator-less for the
  //    next statements (no verify runs in between) and makes the arms unreachable
  //    + both condition compares dead. Scrub first (each `br i1` is a USER of its
  //    tainted condition — §6.1 hygiene).
  if (InnerBI) {
    scrubTaint(InnerBI, taint);
    InnerBI->eraseFromParent();
  }
  if (OuterBI) {
    scrubTaint(OuterBI, taint);
    OuterBI->eraseFromParent();
  }

  // 3. The condition compares now feed nothing — erase them dead, BEFORE the arm
  //    gates. ORDER IS LOAD-BEARING (§6.1, the WI-3 interlock): the inner compare
  //    `%c2` READS the Mid gate `%g`, so `%g` is not use-empty until `%c2` is
  //    gone. Erasing the arm gates first (the naive flat order) would free `%g`
  //    while `%c2` still references it. Guard on use_empty so a malformed compare
  //    with a stray live use is left for the verifier rather than silently dropped.
  //    (bd `boi6` D-B / Track M: `isCondRailPhiShape` joins `isCondRailLeaf` at
  //    both rungs, for the reason spelled out in `flattenRegion` step 3 — no
  //    subject today, defence in depth against a silent re-opening.)
  if (InnerCond && InnerCond->use_empty() && !isCondRailLeaf(InnerCond) &&
      !isCondRailPhiShape(InnerCond) && !isRegCondLeaf(InnerCond) &&
      !isRailWindowCellRead(InnerCond)) {
    scrubTaint(InnerCond, taint);
    InnerCond->eraseFromParent();
  }
  if (OuterCond && OuterCond->use_empty() && !isCondRailLeaf(OuterCond) &&
      !isCondRailPhiShape(OuterCond) && !isRegCondLeaf(OuterCond) &&
      !isRailWindowCellRead(OuterCond)) {
    scrubTaint(OuterCond, taint);
    OuterCond->eraseFromParent();
  }

  // 4. Erase the arm-gate chains in REVERSE lineage order (Mid-gates-first in,
  //    so the inner-arm gate `%h` — which reads `%g` — goes before `%g`). The one
  //    caller, `emitPhaseKickbackNestRegion`, passes an EMPTY list; only the
  //    pre-3qlq nest emitter passed its `cq_phi_<sfx>` gates here.
  for (CallInst *Phi : reverse(armPhis)) {
    scrubTaint(Phi, taint);
    Phi->eraseFromParent();
  }

  // 5. Splice the SINGLE shared merge's surviving instructions (the measure / ret
  //    that consumed the now-RAUW'd phi) onto the end of `Pred` — EXACTLY ONCE.
  //    Calling the per-region `flattenRegion` twice would erase this shared block
  //    twice (double-free / SIGSEGV); this coordinated splice avoids that.
  Pred->splice(Pred->end(), Merge);

  // 6. Delete the now-unreachable arm blocks (InnerArm before Mid — InnerArm's
  //    `br label %merge` is its only remaining content), then the emptied merge.
  //    InnerArm's branch is the last reference to `Merge`, so it must go before
  //    `Merge` (branch-first lifetime, ET2).
  InnerArm->eraseFromParent();
  Mid->eraseFromParent();
  // dugh (Phase 4×6): re-point any surviving reference to the shared `Merge` (a
  // downstream successor-phi incoming block, when the collapsed nest value flows
  // onward past a classical branch whose head is the spliced merge terminator) at
  // `Pred` before the erase — the standard merge-into-pred fixup, a NO-OP for the
  // clean measure/`ret` tail. See the twin note in `flattenRegion`.
  Pred->replaceSuccessorsPhiUsesWith(Merge, Pred);
  Merge->eraseFromParent();
}

void flattenSwitchRegion(const ControlRegion &R, TaintSet &taint) {
  // Capture EVERY block identity before the first erase (the block-lifetime
  // hazard — a `BasicBlock*` re-read through freed memory is a SIGSEGV on valid
  // input). `Pred` is the switch block (SURVIVES — it holds the emitted
  // stream). The arm blocks (incl. empty passthrough arms whose merge incoming is
  // just the scrutinee) and the merge block are doomed.
  BasicBlock *Pred = R.Pred;
  BasicBlock *Merge = R.MergeBB;
  if (!Pred || !Merge)
    return;  // malformed plan — leave the IR for the verifier rather than crash.
  SmallVector<BasicBlock *, 4> Arms;
  for (const SwitchArm &A : R.SwitchArms)
    if (A.Block)
      Arms.push_back(A.Block);
  auto *SI = dyn_cast<SwitchInst>(Pred->getTerminator());

  // 0. bd 7udx — BEFORE the first erase; see the twin note in `flattenRegion`
  //    for the mechanism. Every doomed arm plus the merge; `Pred` survives.
  {
    SmallVector<BasicBlock *, 8> Doomed(Arms.begin(), Arms.end());
    Doomed.push_back(Merge);
    if (declineAddressTakenBlocks(Doomed, SI))
      return;
  }

  // 1. Drop the `switch` terminator — control is now straight-line. The switch is
  //    a USER of the tainted scrutinee `q` (TaintPropagation put it in
  //    taint.Tainted), so scrub before erase (§6.1 — else a later module walk
  //    dereferences freed memory; since bd 8e5r the set also drops it by itself,
  //    `ScrubOnDelete.h`). This leaves Pred terminator-less for exactly
  //    the next statement (the spliced merge tail; no verify runs in between).
  if (SI) {
    scrubTaint(SI, taint);
    SI->eraseFromParent();
  }

  // 2. Splice the merge block's surviving instructions (the measure / ret that
  //    consumed the now-RAUW'd phi — the phi was erased upstream) onto the end of
  //    Pred. Pred's terminator becomes the merge's `ret`.
  Pred->splice(Pred->end(), Merge);

  // (No dead condition compare to erase: unlike the diamond's i1 `CmpInst`, the
  //  switch scrutinee `q` is the LIVE quantum register — kept alive by the
  //  emitted per-case eq-flags — so it is never use-empty and is NEVER erased.)

  // 3. Delete the now-unreachable arm blocks, then the emptied merge block (each
  //    arm's `br label %merge` was the last reference to the merge block, so the
  //    arms must go first — branch-first lifetime).
  for (BasicBlock *A : Arms)
    A->eraseFromParent();
  // dugh (Phase 4×6): re-point any surviving reference to `merge` (a downstream
  // successor-phi incoming block, when the muxed `%out` flows onward past a
  // classical branch whose head is the spliced merge terminator) at `Pred`
  // before the erase — the standard merge-into-pred fixup, a NO-OP for the clean
  // measure/`ret` tail. See the twin note in `flattenRegion`.
  Pred->replaceSuccessorsPhiUsesWith(Merge, Pred);
  Merge->eraseFromParent();
}

}  // namespace cq
