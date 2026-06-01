// ControlledLowering.cpp — see header. Per-region pipeline + the flag's
// compute/uncompute bracket (§1.5).
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
// no-op since `Shadow` is empty), but there is NO CFG to linearize (a select is
// a single-block value): ControlFlag mints the flag, MergeDissolution reduces
// the classical-arm select to `alloc(B)` + `add_hl_controlled`, then the
// uncompute is anchored after that controlled add (the bracket), and the now-dead
// `icmp` condition is erased (matching the `br` path's dead-icmp cleanup).
//
// Regions are walked outer→inner (by `Depth`) and their flags pushed on a LIFO
// stack, the nesting seam (PRD §2.9). WP3/WP4 plans are flat (Depth 0).

#include "ControlledLowering.h"

#include "CFGLinearization.h"
#include "CompareLowering.h"  // lowerCompareToFlag (uncompute)
#include "ControlFlag.h"
#include "ControlPlan.h"
#include "ControlledSubstitution.h"
#include "ControlledSymbols.h"
#include "MergeDissolution.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Mint the flag uncompute for `region` (the `_inv` twin of its compare
// template), anchored at `At`, so it brackets the controlled body (§1.5). Must
// run while `region.Condition` (the `icmp`) still stands. No-op if the region
// has no flag or the condition is not a compare.
void emitUncompute(ControlRegion &region, WidthDispatch &wd, TaintSet &taint,
                   Instruction *At) {
  if (!region.Flag || !At)
    return;
  auto *Cmp = dyn_cast_or_null<CmpInst>(region.Condition);
  if (!Cmp)
    return;
  // HL path (`qqWidth` empty), inverse=true → `cq_template_icmp_<pred>_<W>`
  // `_hl_inv(handle, classical)`. The result is the uncompute and is
  // intentionally unconsumed (a balanced ancilla, not a data value).
  (void)lowerCompareToFlag(Cmp, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                           /*before=*/At);
}

// Erase `region.Condition` if it is now a dead instruction. The forward flag
// compute and the `_inv` uncompute are separate template calls re-read off the
// condition's operands, so once the `select`/`br` is gone the original `icmp`
// has no users. Mirrors the `br` path's dead-icmp cleanup in linearization.
void eraseDeadCondition(ControlRegion &region) {
  if (auto *Cond = dyn_cast_or_null<Instruction>(region.Condition))
    if (Cond->use_empty())
      Cond->eraseFromParent();
}

}  // namespace

void lowerControlledRegions(Module &M, WidthDispatch &wd, TaintSet &taint,
                            ControlPlan &plan) {
  if (plan.Regions.empty())
    return;

  // Minter for the controlled surface (the `add_<W>_hl_controlled` the
  // classical-arm select reduction needs). Bound to the module + shared
  // width resolver; idempotent/lazy, so a plan with no select region leaks
  // no decls beyond what the regions actually emit.
  ControlledSymbols csyms(M, wd);

  // Outer→inner: stable sort by Depth ascending so an enclosing region is
  // bracketed before its nested ones (PRD §2.9). WP3/WP4 are flat (Depth 0).
  SmallVector<ControlRegion *, 4> Order;
  for (ControlRegion &R : plan.Regions)
    Order.push_back(&R);
  std::stable_sort(Order.begin(), Order.end(),
                   [](const ControlRegion *A, const ControlRegion *B) {
                     return A->Depth < B->Depth;
                   });

  // LIFO flag stack — the nesting seam (PRD §2.9). For the flat WP3/WP4 case
  // the bracket is emitted per region (compute in ControlFlag, uncompute after
  // the controlled body), the depth-1 specialization of the LIFO discipline.
  SmallVector<Value *, 4> FlagStack;

  for (ControlRegion *RP : Order) {
    ControlRegion &R = *RP;

    // 1. Control-wire (flag compute). On failure the compare was diagnosed;
    //    leave the region untouched (the `select`/`br`/`icmp` stay,
    //    verify-clean).
    if (!lowerControlFlag(R, wd, taint))
      continue;
    FlagStack.push_back(R.Flag);

    if (R.Kind == ControlRegion::SelectRegion) {
      // WP4 classical-arm `select`: no CFG, no in-shadow body. Capture the
      // uncompute anchor (the node after the select — it survives dissolution,
      // which inserts the controlled add BEFORE the select then erases it).
      auto *Sel = dyn_cast_or_null<SelectInst>(R.Merge);
      Instruction *UncomputeAt = Sel ? Sel->getNextNode() : nullptr;

      // 2. Reduce the select to `alloc(B)` + `add_<W>_hl_controlled(flag,·,A−B)`
      //    and RAUW its result.
      dissolveMerge(R, wd, csyms, taint);

      // 3. Flag uncompute, anchored after the controlled add so it brackets the
      //    body (§1.5), minted while the `icmp` still stands.
      emitUncompute(R, wd, taint, UncomputeAt);
      FlagStack.pop_back();

      // 4. No linearization (a select has no CFG). Erase the now-dead `icmp`.
      eraseDeadCondition(R);
      continue;
    }

    // --- BranchRegion (WP3 `br`-diamond) ---
    // 2. Controlled substitution of the in-shadow gate bodies.
    substituteControlled(R, wd, taint);

    // 3. Dissolve the merge φ to the in-place handle (must precede block
    //    erasure so no use dangles, §1.6).
    dissolveMerge(R, wd, csyms, taint);

    // 4. Flag uncompute, minted while the `icmp` still stands and anchored at
    //    the merge boundary so it brackets the controlled body (§1.5).
    emitUncompute(R, wd, taint, R.MergeBB ? &R.MergeBB->front() : nullptr);
    FlagStack.pop_back();

    // 5. Collapse the diamond to a single straight-line block; erase the dead
    //    `icmp` last. No `br i32` is ever created (§1.1).
    linearizeRegion(R);
  }
}

}  // namespace cq
