// RegionFlatten.cpp — see header. CFG flatten for one swap-route region: after
// `SwapRouteEmit` has emitted the routed stream into the pred and rewired the
// data, collapse the dead diamond/if-else CFG into the single pred block.
//
// Block identities are captured BEFORE the first erase (the block-lifetime
// hazard — a `BasicBlock*` re-read through freed memory is a SIGSEGV on valid
// input). Erase order is deliberate: the conditional `br` first (so the arms go
// unreachable and the condition compare goes dead), then splice the merge's
// surviving instructions into the pred, then the dead arms before the emptied
// merge (an arm's `br label %merge` is the last reference to the merge block).

#include "RegionFlatten.h"

#include "ControlPlan.h"
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
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
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

  // 1. Drop the conditional branch — control is now straight-line. This leaves
  //    Pred terminator-less for exactly the next statement (no verify runs in
  //    between), and makes the arms unreachable + the condition compare dead.
  //    Scrub it first: the `br i1` is a USER of the tainted condition, so
  //    TaintPropagation put it in taint.Tainted — erasing without scrubbing
  //    leaves a dangling Instruction* whose heap address a later-minted
  //    instruction could reuse, turning membership probes into false taint
  //    (§6.1 hygiene; §8 adversarial review 2026-06-10).
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
  if (Cond && Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }

  // 4. Delete the now-unreachable arm block(s), then the emptied merge block.
  if (Arm)
    Arm->eraseFromParent();
  if (ArmFalse)
    ArmFalse->eraseFromParent();
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
  BasicBlock *Pred = Outer.Pred;       // survives (holds the routed stream)
  BasicBlock *Mid = Outer.Arm;         // doomed (= Inner.Pred)
  BasicBlock *InnerArm = Inner.Arm;    // doomed
  BasicBlock *Merge = Outer.MergeBB;   // doomed (shared — erased EXACTLY ONCE)
  if (!MergePhi || !Pred || !Mid || !InnerArm || !Merge)
    return;  // malformed plan — leave the IR for the verifier rather than crash.
  if (MergePhi->getBasicBlockIndex(Pred) < 0)
    return;
  Value *Q = MergePhi->getIncomingValueForBlock(Pred);
  auto *OuterBI = dyn_cast<BranchInst>(Pred->getTerminator());
  auto *InnerBI = dyn_cast<BranchInst>(Mid->getTerminator());
  auto *OuterCond = dyn_cast_or_null<Instruction>(Outer.Condition);
  auto *InnerCond = dyn_cast_or_null<Instruction>(Inner.Condition);

  // 1. Rewire the data: the 3-incoming merge phi collapses to the routed base `q`
  //    (a phase arm preserves q's basis value on every edge). RAUW → q so the
  //    measure that consumed the phi now reads `q`, then scrub + erase it. The
  //    nest is the SOLE owner of this phi (§6.1) — erasing it here, before
  //    `declineClassicalMuxes`, is what keeps the live 3-incoming tainted phi from
  //    false-declining `classical phi` on a half-mutated module.
  MergePhi->replaceAllUsesWith(Q);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();

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
  if (InnerCond && InnerCond->use_empty()) {
    scrubTaint(InnerCond, taint);
    InnerCond->eraseFromParent();
  }
  if (OuterCond && OuterCond->use_empty()) {
    scrubTaint(OuterCond, taint);
    OuterCond->eraseFromParent();
  }

  // 4. Erase the arm-gate chains in REVERSE lineage order (the caller passes them
  //    Mid-gates-first, forward order, so reverse drops the inner-arm gate `%h`
  //    — which reads `%g` — before the Mid gate `%g`, keeping each use-empty).
  //    Scrubbing each from `taint.PhiCalls` is what stops `lowerRotations` from
  //    re-emitting a stray uncontrolled `cqrt_rz` on the wrong register (§6.1).
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
  Merge->eraseFromParent();
}

void flattenSwitchRegion(const ControlRegion &R, TaintSet &taint) {
  // Capture EVERY block identity before the first erase (the block-lifetime
  // hazard — a `BasicBlock*` re-read through freed memory is a SIGSEGV on valid
  // input). `Pred` is the switch block (SURVIVES — it holds the emitted routed
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

  // 1. Drop the `switch` terminator — control is now straight-line. The switch is
  //    a USER of the tainted scrutinee `q` (TaintPropagation put it in
  //    taint.Tainted), so scrub before erase (§6.1 — else a later module walk
  //    dereferences freed memory). This leaves Pred terminator-less for exactly
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
  Merge->eraseFromParent();
}

}  // namespace cq
