// GuardedStoreArmEmit.cpp — see header. iw81.7: the guarded Shadow store.
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2).
// A store is GENUINELY CONTROLLED (not swap-routed): the diamond is flattened to
// straight-line, the store rewritten to the guarded symbol
// `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)` (Bennett
// `emit_shadow_store_guarded!` — each store CNOT lifted to a Toffoli(flag, ...), a
// no-op on cell+tape when flag=0). The flag is minted from the PRE-store condition
// handle (`q` is unchanged by a store, so it stays recomputable) and left LIVE so
// the whole-DAG LIFO uncompute reverses the guarded store via `..._controlled_unc`
// (flag arg 0) and then strips the flag (the flag-mint compare is a reversible DAG
// ancestor — §6.0 compare `_unc`). Never eagerly strip: an ungated `_unc` over-pops
// the inactive branch (a dephasing silent miscompile).

#include "GuardedStoreArmEmit.h"

#include "ArmAnalysis.h"      // comparePredLowerable
#include "CompareLowering.h"  // lowerCompareToFlag (flag mint)
#include "ControlPlan.h"      // ControlRegion / diagnoseUnderControl
#include "OpcodeSupport.h"    // abiWidthFromType / widthHasReversibleCopy
#include "QramLowering.h"     // guardedShadowStoreShape (the shared shape predicate)
#include "TaintPropagation.h" // TaintSet
#include "WidthDispatch.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// (the house-style dangling-work-list hygiene, mirroring AbortParkEmit). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  if (auto *SI = dyn_cast<StoreInst>(I))
    taint.GuardedStores.erase(SI);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
  }
}

// Loud bail for a detection-guaranteed shape that did not hold at emit time. A
// silently skipped accepted region would hand the tainted `br` to the backend as
// classical control over quantum state (Rule 1).
void bailLoud(const ControlRegion &R) {
  if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
    diagnoseUnderControl(A, "control flow");
  else if (R.Merge)
    diagnoseUnderControl(R.Merge, "control flow");
}

// The tainted operand of an HL compare (exactly one operand tainted), or null if
// the compare is Q+Q or all-classical. Mirrors AbortParkEmit's helper.
Value *hlTaintedOperand(CmpInst *Cond, const TaintSet &Taint) {
  if (Cond->getNumOperands() < 2)
    return nullptr;
  Value *A = Cond->getOperand(0), *B = Cond->getOperand(1);
  bool TA = Taint.Tainted.count(A) != 0, TB = Taint.Tainted.count(B) != 0;
  if (TA == TB)
    return nullptr;
  return TA ? A : B;
}

// The single StoreInst in `BB`, or null if there is not exactly one. Also fails
// (returns null) if `BB` carries any OTHER side effect (a second store, a load, or
// a call) or any instruction whose result is USED OUTSIDE `BB` — a side-effect-only
// store arm has exactly the store's own address/value computation and nothing that
// escapes to the merge (no merge φ). Terminator excluded.
StoreInst *soleSideEffectStore(BasicBlock *BB) {
  StoreInst *Found = nullptr;
  for (Instruction &I : *BB) {
    if (I.isTerminator())
      continue;
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (Found)
        return nullptr;  // a second store — not a single side effect.
      Found = SI;
      continue;
    }
    if (isa<LoadInst>(I) || isa<CallInst>(I) || isa<InvokeInst>(I) ||
        isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I))
      return nullptr;  // another observable side effect — off-shape.
    // Rule-13 [C1]: ANY remaining side-effecting op (a volatile access, any op
    // `mayHaveSideEffects`) would be spliced into `Pred` by the flatten and fire
    // UNCONDITIONALLY (a classical side effect on the wrong branch — trace-
    // invisible, the canonical silent miscompile). A load/call/invoke/atomic/fence
    // are covered above (a non-volatile load is not `mayHaveSideEffects` but is
    // still an observable read we exclude); this is the catch-all for the rest.
    if (I.mayHaveSideEffects())
      return nullptr;
    for (User *U : I.users())
      if (auto *UI = dyn_cast<Instruction>(U))
        if (UI->getParent() != BB)
          return nullptr;  // a value escapes the arm (e.g. a merge φ) — off-shape.
  }
  return Found;
}

// Does the condition read the array as DATA (§3c-conservative)? A guarded store
// whose branch condition transitively LOADs from memory could be writing a cell the
// flag was derived from (the flag would then reference a clobbered value). v1
// declines any condition whose tainted lineage contains a load. The common
// theta-compare condition has no load → accept.
bool conditionReadsMemory(CmpInst *Cond, const TaintSet &Taint) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Seen;
  for (Value *Op : Cond->operands())
    if (Taint.Tainted.count(Op) && Seen.insert(Op).second)
      Work.push_back(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (isa<LoadInst>(V))
      return true;
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;
    for (Value *In : I->operands())
      if (Taint.Tainted.count(In) && Seen.insert(In).second)
        Work.push_back(In);
  }
  return false;
}

}  // namespace

GuardedStoreDisp classifyGuardedStoreArm(BranchInst *BI, TaintSet &Taint,
                                         ControlRegion &R) {
  // Caller guarantees: `BI` is a conditional branch on a tainted condition.
  BasicBlock *Pred = BI->getParent();
  BasicBlock *S0 = BI->getSuccessor(0);  // cond == true
  BasicBlock *S1 = BI->getSuccessor(1);  // cond == false

  DominatorTree DT(*Pred->getParent());
  LoopInfo LI(DT);

  // Which successor is the side-effect-only guarded-store arm? A candidate arm has
  // a single StoreInst, single-pred == Pred, single-succ == the OTHER successor
  // (the merge), and that store passes the shared `guardedShadowStoreShape`.
  auto isStoreArm = [&](BasicBlock *Cand, BasicBlock *Merge) -> StoreInst * {
    if (Cand->getSinglePredecessor() != Pred ||
        Cand->getSingleSuccessor() != Merge)
      return nullptr;
    StoreInst *SI = soleSideEffectStore(Cand);
    if (!SI || !guardedShadowStoreShape(SI, Taint, DT, LI))
      return nullptr;
    return SI;
  };

  BasicBlock *ArmBB = nullptr, *Merge = nullptr;
  bool Negated = false;
  if (isStoreArm(S0, S1)) {
    ArmBB = S0; Merge = S1; Negated = false;
  } else if (isStoreArm(S1, S0)) {
    ArmBB = S1; Merge = S0; Negated = true;
  } else {
    return GuardedStoreDisp::NotApplicable;  // not a store-arm diamond.
  }

  // From here this step OWNS the shape (a side-effect-only bounded-alloca store
  // arm): every unmet precondition is a LOUD decline, never NotApplicable.

  // g5gi — a SWAPPED (FALSE-successor) store arm is now ACCEPTED: the store fires
  // on `¬cond`, minted directly as the inverse-predicate flag (a negated mint, NOT
  // a `cqrt_x` bracket — the spine reverses `icmp_ne_..._unc` identically to the
  // un-negated `_unc`; PRD-g5gi §1). `R.ArmNegated` carries the polarity to the
  // emitter, which passes `negate` to `lowerCompareToFlag`.

  // A merge φ means a value/phase arm rides beside the store (mixed) — off the
  // side-effect-only v1 shape. (soleSideEffectStore already rejects an escaping
  // value, so this is belt-and-suspenders for a Pred-defined φ incoming.)
  if (isa<PHINode>(Merge->front())) {
    diagnoseUnderControl(BI, "guarded store with a merge value");
    return GuardedStoreDisp::Declined;
  }

  auto *Cond = dyn_cast<CmpInst>(BI->getCondition());
  if (!Cond || !comparePredLowerable(Cond)) {
    diagnoseUnderControl(BI, "control flow");
    return GuardedStoreDisp::Declined;
  }
  if (!Cond->hasOneUse()) {
    diagnoseUnderControl(Cond, "condition used outside the branch");
    return GuardedStoreDisp::Declined;
  }
  Value *Q = hlTaintedOperand(Cond, Taint);
  if (!Q) {  // Q+Q — no single HL flag mint.
    diagnoseUnderControl(Cond, "control flow");
    return GuardedStoreDisp::Declined;
  }
  if (!widthHasReversibleCopy(abiWidthFromType(Q->getType()))) {
    diagnoseUnderControl(Cond, "control flow");
    return GuardedStoreDisp::Declined;
  }
  if (conditionReadsMemory(Cond, Taint)) {
    diagnoseUnderControl(Cond, "guarded store whose condition reads memory");
    return GuardedStoreDisp::Declined;
  }

  // ACCEPT. Populate the by-identity plan (like a BranchRegion diamond).
  R.Kind = ControlRegion::GuardedStoreArm;
  R.Pred = Pred;
  R.Arm = ArmBB;
  R.MergeBB = Merge;
  R.Merge = nullptr;  // no merge φ (side-effect-only arm).
  R.Condition = Cond;
  R.ArmNegated = Negated;  // g5gi — a FALSE-successor arm mints the ¬cond flag.
  return GuardedStoreDisp::Accept;
}

void emitGuardedStoreArmRegion(const ControlRegion &R, WidthDispatch &wd,
                               TaintSet &taint) {
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  if (!Cond || !R.Pred || !R.Arm || !R.MergeBB)
    return bailLoud(R);
  auto *BI = dyn_cast<BranchInst>(R.Pred->getTerminator());
  if (!BI || !BI->isConditional())
    return bailLoud(R);
  BasicBlock *ArmBB = R.Arm, *Merge = R.MergeBB;

  // Re-derive the store by identity (the sole side-effect store in the arm) — a
  // pure consumer of the by-identity plan.
  StoreInst *SI = soleSideEffectStore(ArmBB);
  if (!SI)
    return bailLoud(R);

  // 1. Mint the path-predicate flag from the PRE-store condition handle (before
  //    BI). A store does not change `q`'s value, so the flag stays recomputable —
  //    the whole-DAG LIFO strip (`icmp_..._unc`) is valid. g5gi — for a SWAPPED
  //    (FALSE-successor) arm (`R.ArmNegated`) the store fires on `¬cond`, so mint
  //    the INVERSE-predicate flag (`negate`): `flag = icmp_ne(q,k)` for `br [q==k]`.
  //    The spine reverses the negated compare via its own `_unc`, identical to the
  //    un-negated case — only the predicate string differs (PRD-g5gi §1).
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI,
                                   /*negate=*/R.ArmNegated);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed.

  // 2. RECORD (store→flag) so `lowerShadowMemory` emits the GUARDED store. The
  //    StoreInst identity is stable across the flatten (a splice preserves it).
  taint.GuardedStores[SI] = Flag;

  // 2a. Mark the flag as a tainted producer so the whole-DAG LIFO uncompute walks
  //     it: `DagTraversal` enqueues it as a borrowed operand of the guarded store
  //     (arg 0), and reverses the flag-mint compare via its `_unc` (the flag STRIP)
  //     AFTER the store's `_controlled_unc` (SSA dominance — the store's `_unc`
  //     reads the flag). The flag is NOT a data terminal (the store consumes it),
  //     so it is never selected as one; it reverses purely as a DAG ancestor. This
  //     is why the flag is left LIVE (not eagerly stripped) — the strip rides the
  //     same LIFO as the store, guaranteeing store-reverse-then-strip ordering.
  //     LOAD-BEARING ORDERING (Rule-13 landmine): the flag mint MUST precede the
  //     store in program order (it does — the mint is emitted `before BI`, the store
  //     is spliced `before BI` AFTER it). The whole-DAG driver's `railOf` returns
  //     arg 0 = the FLAG for the 4-arg guarded store (not the array), so the flag's
  //     `cqrt_free` is keyed to the flag rail; `Earliest` (first-forward-occurrence)
  //     maps the flag to the icmp (which precedes the store), so the free lands after
  //     the `icmp_..._unc` STRIP, not after the earlier `store_..._controlled_unc`.
  //     A refactor that let the store precede its mint, or dropped the icmp from the
  //     DAG, would free a still-dirty flag (a hidden measurement collapse, Rule 6).
  if (auto *FlagI = dyn_cast<Instruction>(Flag)) {
    taint.Tainted.insert(FlagI);
    taint.BirthOrder[FlagI] = taint.NextBirth++;
  }

  // 3. FLATTEN: splice the arm's non-terminator body (the gep chain + the store)
  //    into `Pred` before BI — AFTER the flag mint, so the flag dominates the
  //    store. `moveBefore` preserves each instruction's identity (SI stays valid).
  SmallVector<Instruction *, 8> ArmBody;
  for (Instruction &I : *ArmBB)
    if (!I.isTerminator())
      ArmBody.push_back(&I);
  for (Instruction *I : ArmBody)
    I->moveBefore(BI);

  // 4. Rewire `Pred` straight to the merge (unconditional), then erase the now-dead
  //    conditional branch, the empty arm block, and the dead compare. The merge has
  //    NO φ (declined otherwise), so dropping the ArmBB→Merge edge needs no φ fixup.
  IRBuilder<> B(BI);
  B.CreateBr(Merge);
  scrubTaint(BI, taint);
  BI->eraseFromParent();
  ArmBB->eraseFromParent();  // unreachable (its sole predecessor Pred is rewired).
  if (Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }
}

}  // namespace cq
