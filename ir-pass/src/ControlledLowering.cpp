// ControlledLowering.cpp — see header. Per-region pipeline + the flag's
// compute/uncompute bracket (§1.5), LIFO for compound/nested regions (§2.9).
//
// `br`-diamond region (WP3) — ordering within a region (so the linearized
// block reads compute → controlled body → uncompute → continuation):
//   1. ControlFlag mints the forward flag (inserted before the `icmp`).
//   2. Substitution emits the controlled gate body in the arm.
//   3. Dissolution RAUWs the merge `φ` to the in-place handle and erases it.
//   4. The uncompute (`_inv` of the compare template) is minted at the MERGE
//      block's front — i.e. after the arm body, before the continuation —
//      WHILE the `icmp` still stands (linearization erases it next).
//   5. Linearization collapses the diamond into the predecessor.
//
// `select` region (WP4) — same flag/substitution machinery (Substitution is a
// no-op since `Shadow` is empty), but there is NO CFG to linearize.
//
// Compound `&&`/`||` (WP5) — `region.Conj != ConjNone`. `ControlFlag` lowers
// the two sub-compares to flags and `FlagConjunction::combineFlags` ANDs/ORs
// them into the single `region.Flag` (one `cqrt_toffoli`, §1.2). The uncompute
// is the exact LIFO reverse: the conjunction uncompute (`cqrt_toffoli_inv` +
// OR's X-bracket) FIRST, then each sub-flag's compare-uncompute, then the
// sub-compares/select are erased. For a `select i1`-sourced `&&` the carrier is
// a flat 2-block diamond (`br i1 %and, …`); for the un-flattened NESTED shape
// `region.Mid` is set and linearization splices the inner guard block too.
//
// Regions are walked outer→inner (by `Depth`) and their flags pushed on a LIFO
// stack, the nesting seam (PRD §2.9). The realized 2-level nested fixture is a
// single conjunction region (CondA=outer, CondB=inner), so the LIFO is
// per-region; the `Depth`/`ParentFlag` fields stay for a depth-N generalization.

#include "ControlledLowering.h"

#include "CFGLinearization.h"
#include "CompareLowering.h"  // lowerCompareToFlag (uncompute)
#include "ControlFlag.h"
#include "ControlPlan.h"
#include "ControlledSubstitution.h"
#include "ControlledSymbols.h"
#include "FlagConjunction.h"  // uncombineFlags
#include "MergeDissolution.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>
#include <initializer_list>

using namespace llvm;

namespace cq {

namespace {

// Mint the flag uncompute for a region's condition, anchored at `At`, so it
// brackets the controlled body (§1.5). Must run while the condition compare(s)
// still stand.
//
//   * Plain compare (`Conj == ConjNone`): the `_inv` twin of the compare
//     template (the WP3 path).
//   * Compound `&&`/`||`/nesting (`Conj != ConjNone`): the LIFO reverse of the
//     compute — first the conjunction uncompute (`cqrt_toffoli_inv`, plus the
//     De Morgan X-bracket for OR), then EACH sub-flag's compare-uncompute
//     (innermost flag `CondB` first, mirroring the bracket). The sub-flag
//     uncomputes re-derive their flags off the still-standing sub-compares.
void emitUncompute(ControlRegion &region, WidthDispatch &wd,
                   ControlledSymbols &csyms, TaintSet &taint, Instruction *At) {
  if (!region.Flag || !At)
    return;

  if (region.Conj != ControlRegion::ConjNone) {
    auto *CmpA = dyn_cast_or_null<CmpInst>(region.CondA);
    auto *CmpB = dyn_cast_or_null<CmpInst>(region.CondB);
    if (!CmpA || !CmpB || !region.FlagA || !region.FlagB)
      return;
    // (1) Conjunction uncompute FIRST (toffoli_inv + OR X-bracket), the mirror
    //     image of combineFlags, reusing the SAME forward sub-flags
    //     (`region.FlagA`/`FlagB`, which dominate here) so no fresh forward
    //     compare is emitted (§2.9, risk R4).
    uncombineFlags(region.FlagA, region.FlagB, region.Flag, region.Conj, csyms,
                   At);
    // (2) Then each sub-flag's compare-uncompute, innermost (`CondB`) first,
    //     balancing the forward compares minted by `lowerControlFlag`.
    (void)lowerCompareToFlag(CmpB, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                             /*before=*/At);
    (void)lowerCompareToFlag(CmpA, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                             /*before=*/At);
    return;
  }

  auto *Cmp = dyn_cast_or_null<CmpInst>(region.Condition);
  if (!Cmp)
    return;
  // WP6: a Q+Q control condition uncomputes with the QQ `_inv` twin
  // `cq_template_icmp_<pred>_<W>_inv(h1, h2)` (no `_hl`), the mirror of the
  // forward QQ flag in `lowerControlFlag`. Recover the same width from the
  // side-table; the HL path keeps `qqWidth` empty → `_hl_inv(handle, classical)`.
  StringRef QqWidth;
  if (taint.Tainted.count(Cmp->getOperand(0)) &&
      taint.Tainted.count(Cmp->getOperand(1)))
    QqWidth = qqControlWidth(Cmp, taint);
  // inverse=true → the `_inv` twin. The result is the uncompute and is
  // intentionally unconsumed (a balanced ancilla, not a data value).
  (void)lowerCompareToFlag(Cmp, wd, taint, QqWidth, /*inverse=*/true,
                           /*before=*/At);
}

// Erase the listed instructions if dead, deduplicating so the same value is
// never freed twice (for nesting `region.Condition` IS `region.CondA`). Each is
// erased in list order; a select must precede the sub-compares it uses. The
// forward compute and `_inv` uncompute are separate template calls re-read off
// the operands, so once the `select`/`br` is gone the originals are unused.
void eraseDeadConds(std::initializer_list<Value *> Conds) {
  SmallVector<Instruction *, 3> Seen;
  for (Value *V : Conds) {
    auto *I = dyn_cast_or_null<Instruction>(V);
    if (!I || !I->use_empty())
      continue;
    if (llvm::is_contained(Seen, I))
      continue;  // already queued (Condition == CondA for nesting).
    Seen.push_back(I);
  }
  for (Instruction *I : Seen)
    if (I->use_empty())  // re-check: an earlier erase may have freed a user.
      I->eraseFromParent();
}

// Collapse the un-flattened NESTED diamond `Pred -[a]-> {Mid, Merge}`,
// `Mid -[b]-> {Arm, Merge}`, `Arm -> Merge` into the single block `Pred`,
// collection-before-mutation (§1.6). Splices the inner guard block `Mid`'s body
// (its opaque/non-control content) and the gate-body `Arm` through, then the
// merge. The merge `φ` MUST already be dissolved. Returns the splice boundary.
// (Kept local to the orchestrator — the flat-diamond `CFGLinearization` stays
// untouched; this is the WP5 nesting-only collapse, §2.7.)
Instruction *linearizeNested(ControlRegion &region) {
  BasicBlock *Pred = region.Pred;
  BasicBlock *Mid = region.Mid;
  BasicBlock *Arm = region.Arm;
  BasicBlock *Merge = region.MergeBB;
  if (!Pred || !Mid || !Arm || !Merge)
    return nullptr;

  auto *PredBr = dyn_cast<BranchInst>(Pred->getTerminator());
  auto *MidBr = dyn_cast<BranchInst>(Mid->getTerminator());
  auto *ArmBr = dyn_cast<BranchInst>(Arm->getTerminator());
  if (!PredBr || !PredBr->isConditional() || !MidBr || !MidBr->isConditional() ||
      !ArmBr || ArmBr->isConditional())
    return nullptr;

  Instruction *Boundary = &Merge->front();

  // Drop the outer conditional branch; refill `Pred` by splicing.
  PredBr->eraseFromParent();
  // Splice the inner guard `Mid`'s body (all but its `br i1`), then drop it.
  Pred->splice(Pred->end(), Mid, Mid->begin(), MidBr->getIterator());
  MidBr->eraseFromParent();
  // Splice the gate-body `Arm`'s body (all but its `br`), then drop it.
  Pred->splice(Pred->end(), Arm, Arm->begin(), ArmBr->getIterator());
  ArmBr->eraseFromParent();
  // Splice the merge block (body + terminator).
  Pred->splice(Pred->end(), Merge, Merge->begin(), Merge->end());

  // Erase the drained blocks. The dead condition compares are erased by
  // `eraseDeadConds` in the caller after this returns.
  Mid->eraseFromParent();
  Arm->eraseFromParent();
  Merge->eraseFromParent();
  return Boundary;
}

// Collapse a WP8 SYMMETRIC two-content-arm diamond `Pred -[br i1]-> {ArmT,
// ArmF}`, `ArmT -> Merge`, `ArmF -> Merge` into the single block `Pred`
// (collection-before-mutation, §1.6). Both arms hold controlled gate bodies (the
// false arm bracketed by `cqrt_x`), so both bodies splice through. The merge φ
// MUST already be dissolved. Returns the splice boundary. Erases the dead
// condition like `linearizeRegion` (the caller erases any conjunction
// sub-compares).
Instruction *linearizeSymmetric(ControlRegion &region) {
  BasicBlock *Pred = region.Pred;
  BasicBlock *ArmT = region.Arm;
  BasicBlock *ArmF = region.ArmFalse;
  BasicBlock *Merge = region.MergeBB;
  if (!Pred || !ArmT || !ArmF || !Merge)
    return nullptr;

  auto *PredBr = dyn_cast<BranchInst>(Pred->getTerminator());
  auto *ArmTBr = dyn_cast<BranchInst>(ArmT->getTerminator());
  auto *ArmFBr = dyn_cast<BranchInst>(ArmF->getTerminator());
  if (!PredBr || !PredBr->isConditional() || !ArmTBr || ArmTBr->isConditional() ||
      !ArmFBr || ArmFBr->isConditional())
    return nullptr;

  Instruction *Boundary = &Merge->front();

  // Drop the conditional branch; refill `Pred` by splicing both arm bodies then
  // the merge. No `br i32` is ever synthesized (§1.1).
  PredBr->eraseFromParent();
  Pred->splice(Pred->end(), ArmT, ArmT->begin(), ArmTBr->getIterator());
  ArmTBr->eraseFromParent();
  Pred->splice(Pred->end(), ArmF, ArmF->begin(), ArmFBr->getIterator());
  ArmFBr->eraseFromParent();
  Pred->splice(Pred->end(), Merge, Merge->begin(), Merge->end());

  ArmT->eraseFromParent();
  ArmF->eraseFromParent();
  Merge->eraseFromParent();
  if (auto *Cond = dyn_cast_or_null<Instruction>(region.Condition))
    if (Cond->use_empty())
      Cond->eraseFromParent();
  return Boundary;
}

}  // namespace

void lowerControlledRegions(Module &M, WidthDispatch &wd, TaintSet &taint,
                            ControlPlan &plan) {
  if (plan.Regions.empty())
    return;

  // Minter for the controlled surface (the `add_<W>_hl_controlled` the
  // classical-arm select reduction needs; `cqrt_toffoli`/`cqrt_x`/
  // `cqrt_alloc_i1` for flag conjunction). Bound to the module + shared width
  // resolver; idempotent/lazy.
  ControlledSymbols csyms(M, wd);

  // Outer→inner: stable sort by Depth ascending so an enclosing region is
  // bracketed before its nested ones (PRD §2.9). The realized fixtures are flat
  // (Depth 0) — nesting is folded into a single conjunction region.
  SmallVector<ControlRegion *, 4> Order;
  for (ControlRegion &R : plan.Regions)
    Order.push_back(&R);
  std::stable_sort(Order.begin(), Order.end(),
                   [](const ControlRegion *A, const ControlRegion *B) {
                     return A->Depth < B->Depth;
                   });

  // LIFO flag stack — the nesting seam (PRD §2.9). The per-region bracket
  // (compute in ControlFlag, uncompute after the controlled body) is the
  // depth-1 specialization of the LIFO discipline; for a conjunction region the
  // uncompute itself is the LIFO reverse of the multi-step compute.
  SmallVector<Value *, 4> FlagStack;

  for (ControlRegion *RP : Order) {
    ControlRegion &R = *RP;

    // 1. Control-wire (flag compute). For a compound/nested region this lowers
    //    both sub-compares and combines them into the single flag. On failure
    //    the compare/symbol was diagnosed; leave the region untouched
    //    (verify-clean).
    if (!lowerControlFlag(R, wd, csyms, taint))
      continue;
    FlagStack.push_back(R.Flag);

    if (R.Kind == ControlRegion::SelectRegion) {
      // WP4 classical-arm `select`: no CFG, no in-shadow body. Capture the
      // uncompute anchor (the node after the select — it survives dissolution,
      // which inserts the controlled add BEFORE the select then erases it).
      auto *Sel = dyn_cast_or_null<SelectInst>(R.Merge);
      Instruction *UncomputeAt = Sel ? Sel->getNextNode() : nullptr;

      dissolveMerge(R, wd, csyms, taint);
      emitUncompute(R, wd, csyms, taint, UncomputeAt);
      FlagStack.pop_back();
      // No linearization (a select has no CFG). Erase the now-dead condition
      // (a select region is always a plain compare — no sub-conditions).
      eraseDeadConds({R.Condition});
      continue;
    }

    // --- BranchRegion (WP3 `br`-diamond, WP5 `&&`/`||` + nested) ---
    // 2. Controlled substitution of the in-shadow gate bodies (single-controlled
    //    by the one combined flag).
    substituteControlled(R, wd, taint);

    // 3. Dissolve the merge φ(s) to the in-place handle (must precede block
    //    erasure so no use dangles, §1.6). Capture the uncompute boundary FIRST
    //    — the merge's first non-φ instruction, stable across φ erasure. WP7's
    //    multi-φ dissolution may emit a classical-mux reduction here; anchoring
    //    the uncompute at this point (not the post-dissolution `front()`, which
    //    a reduction would have shifted) keeps compute → uncompute order.
    Instruction *UncomputeAt =
        R.MergeBB ? R.MergeBB->getFirstNonPHI() : nullptr;
    dissolveMerge(R, wd, csyms, taint);

    // 4. Flag uncompute, minted while the condition compare(s) still stand and
    //    anchored at the merge boundary so it brackets the controlled body
    //    (§1.5). For a conjunction this is the LIFO reverse of the compute.
    emitUncompute(R, wd, csyms, taint, UncomputeAt);
    FlagStack.pop_back();

    // 5. Collapse the diamond to a single straight-line block; the nested shape
    //    (Mid set) splices the inner guard block too. No `br i32` is created
    //    (§1.1). Condition cleanup differs by path to avoid a double-free:
    //      * Nested: `linearizeNested` erases NO condition, so erase the outer
    //        compare (`Condition` == `CondA`) and the inner compare (`CondB`).
    //      * Flat: `linearizeRegion` already erased `region.Condition` (the
    //        plain compare, or the `&&`/`||` select) — so only the conjunction
    //        sub-compares `CondA`/`CondB` remain to erase (they are distinct
    //        from a select condition).
    if (R.Mid) {
      linearizeNested(R);
      eraseDeadConds({R.Condition, R.CondB, R.CondA});
    } else if (R.ArmFalse) {
      linearizeSymmetric(R);  // erases R.Condition when dead.
      if (R.Conj != ControlRegion::ConjNone)
        eraseDeadConds({R.CondB, R.CondA});
    } else {
      linearizeRegion(R);  // erases R.Condition when dead.
      if (R.Conj != ControlRegion::ConjNone)
        eraseDeadConds({R.CondB, R.CondA});
    }
  }
}

}  // namespace cq
