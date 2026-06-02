// SwitchNormalization.cpp — see header. WP15 (PRD §8.2): rewrite a
// tainted-scrutinee value-merge `switch` into `icmp eq` flags + a nested
// `select` chain, then let the existing select-mux path lower it.
//
// Algorithm (value-merge form — the common case):
//   1. Gate on a tainted scrutinee (`taint.Tainted.count(Sw->getCondition())`);
//      a classical-scrutinee switch is left for the classical backend.
//   2. Require the value-merge shape: every case dest AND the default dest is a
//      DISTINCT block whose UNIQUE predecessor is the switch block and whose
//      body is exactly an unconditional `br merge` (an empty arm); all arms
//      reconverge to one common merge block; the merge carries ≥1 `φ` and has
//      NO predecessor other than the arm blocks. Decline (→ WP12) otherwise.
//   3. For each case value `v_k` mint `f_k = icmp eq %q, v_k` (inserted in the
//      switch block, marked tainted). For each merge `φ`, fold a nested chain
//      `acc = A_default; acc = select f_k, A_k, acc` (per case) and RAUW the
//      `φ` with the final `acc`. Eq-flags are mutually exclusive, so the
//      nesting is order-independent and correct (PRD §8.2 note).
//   4. Replace the `switch` with `br merge` and delete the now-dead arm blocks.
//
// Because the arms are empty, every `φ` incoming value dominates the switch
// block, so hoisting the selects into the switch block is sound. Downstream
// (`detectControlRegions` → `dissolveSelect`) is UNCHANGED: each chain select
// is a tainted-condition select that reduces to the eq-flag mux template.

#include "SwitchNormalization.h"

#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"  // DeleteDeadBlock

#include <utility>

using namespace llvm;

namespace cq {

namespace {

// Is `Arm` a clean EMPTY value-merge arm — its unique predecessor is `SwBB` and
// its body is exactly an unconditional branch? On a match, returns the merge
// block it falls through to; null otherwise. `getUniquePredecessor` (not
// `getSinglePredecessor`) tolerates a switch with several case values targeting
// the same arm block (multiple pred EDGES, one pred BLOCK).
BasicBlock *valueMergeArmTarget(BasicBlock *Arm, BasicBlock *SwBB) {
  if (Arm->getUniquePredecessor() != SwBB)
    return nullptr;
  // Empty arm: the first instruction IS the terminator (no side-effecting body
  // — that is the gated-cascade shape `-aht.3`, left to the WP12 diagnostic).
  if (&Arm->front() != Arm->getTerminator())
    return nullptr;
  auto *Br = dyn_cast<BranchInst>(Arm->getTerminator());
  if (!Br || Br->isConditional())
    return nullptr;
  BasicBlock *Merge = Br->getSuccessor(0);
  if (Merge == Arm)
    return nullptr;  // a degenerate self-loop, not a forward merge.
  return Merge;
}

// Attempt the WP15 value-merge normalization on one tainted-scrutinee switch.
// Returns true if it rewrote the switch (and `Sw` is now erased); false if it
// declined (the switch is left untouched for the WP12 diagnostic).
bool tryNormalizeSwitch(SwitchInst *Sw, TaintSet &taint) {
  BasicBlock *SwBB = Sw->getParent();
  BasicBlock *Default = Sw->getDefaultDest();

  // The arm blocks (default + every distinct case dest) and the common merge.
  SmallPtrSet<BasicBlock *, 8> ArmBlocks;
  BasicBlock *Merge = valueMergeArmTarget(Default, SwBB);
  if (!Merge)
    return false;
  ArmBlocks.insert(Default);
  for (auto Case : Sw->cases()) {
    BasicBlock *CB = Case.getCaseSuccessor();
    BasicBlock *M2 = valueMergeArmTarget(CB, SwBB);
    if (!M2 || M2 != Merge)
      return false;  // not all arms reconverge on one merge.
    ArmBlocks.insert(CB);
  }

  // The merge must carry ≥1 `φ` (else there is no value to select — a no-op or
  // gated switch; leave it for WP12) and must have NO predecessor other than
  // the arm blocks (an extra edge would feed the `φ` a value from outside the
  // switch — not the clean value-merge shape).
  if (!isa<PHINode>(&Merge->front()))
    return false;
  for (BasicBlock *Pred : predecessors(Merge))
    if (!ArmBlocks.count(Pred))
      return false;

  // ── Rewrite. All `φ` incomings dominate `SwBB` (arms are empty), so the
  // eq-flags + selects are sound to insert before the switch terminator. ──
  Value *Scrut = Sw->getCondition();
  IRBuilder<> B(Sw);

  // Mint the eq-flags once (shared across every merge `φ`). Each is a fresh
  // tainted-condition compare so detection lowers it as a control flag.
  SmallVector<std::pair<Value *, BasicBlock *>, 8> CaseFlags;
  for (auto Case : Sw->cases()) {
    Value *Flag = B.CreateICmpEQ(Scrut, Case.getCaseValue(), "sw_eq");
    taint.Tainted.insert(Flag);
    CaseFlags.push_back({Flag, Case.getCaseSuccessor()});
  }

  // Fold each merge `φ` into a nested select chain rooted at the default value.
  for (PHINode &P : make_early_inc_range(Merge->phis())) {
    Value *Acc = P.getIncomingValueForBlock(Default);
    for (auto &CF : CaseFlags) {
      Value *Ak = P.getIncomingValueForBlock(CF.second);
      Acc = B.CreateSelect(CF.first, Ak, Acc, "sw_sel");
    }
    P.replaceAllUsesWith(Acc);
    P.eraseFromParent();
  }

  // Drop the switch; the switch block now falls straight through to the merge.
  // Deleting the (now predecessor-less) arm blocks drops their `br merge`
  // edges, leaving the merge single-predecessor (`SwBB`).
  Sw->eraseFromParent();
  BranchInst::Create(Merge, SwBB);
  for (BasicBlock *Arm : ArmBlocks)
    DeleteDeadBlock(Arm);
  return true;
}

}  // namespace

void normalizeTaintedSwitches(Module &M, TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Collect first: rewriting mutates the CFG, so do not normalize while
    // iterating the function's block list.
    SmallVector<SwitchInst *, 4> Candidates;
    for (BasicBlock &BB : F)
      if (auto *Sw = dyn_cast<SwitchInst>(BB.getTerminator()))
        if (taint.Tainted.count(Sw->getCondition()))
          Candidates.push_back(Sw);
    for (SwitchInst *Sw : Candidates)
      tryNormalizeSwitch(Sw, taint);
  }
}

}  // namespace cq
