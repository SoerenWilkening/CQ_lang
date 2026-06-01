// ControlledLowering.cpp — see header. Per-region pipeline + the flag's
// compute/uncompute bracket (§1.5).
//
// Ordering within a region (so the linearized block reads compute → controlled
// body → uncompute → continuation):
//   1. ControlFlag mints the forward flag (inserted before the `icmp`).
//   2. Substitution emits the controlled gate body in the arm.
//   3. Dissolution RAUWs the merge `φ` to the in-place handle and erases it.
//   4. The uncompute (`_inv` of the compare template) is minted at the MERGE
//      block's front — i.e. after the arm body, before the continuation —
//      WHILE the `icmp` still stands (linearization erases it next).
//   5. Linearization collapses the diamond into the predecessor.
//
// Regions are walked outer→inner (by `Depth`) and their flags pushed on a LIFO
// stack, the nesting seam (PRD §2.9). WP3's plan is a single flat region.

#include "ControlledLowering.h"

#include "CFGLinearization.h"
#include "CompareLowering.h"  // lowerCompareToFlag (uncompute)
#include "ControlFlag.h"
#include "ControlPlan.h"
#include "ControlledSubstitution.h"
#include "MergeDissolution.h"
#include "TaintPropagation.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Mint the flag uncompute for `region` (the `_inv` twin of its compare
// template) at the merge block's front, so it brackets the controlled body
// (§1.5). Must run while `region.Condition` (the `icmp`) still stands and
// before linearization. No-op if the region has no flag or no merge anchor.
void emitUncompute(ControlRegion &region, WidthDispatch &wd, TaintSet &taint) {
  if (!region.Flag || !region.MergeBB)
    return;
  auto *Cmp = dyn_cast_or_null<CmpInst>(region.Condition);
  if (!Cmp)
    return;
  Instruction *At = &region.MergeBB->front();
  // HL path (`qqWidth` empty), inverse=true → `cq_template_icmp_<pred>_<W>`
  // `_hl_inv(handle, classical)`. The result is the uncompute and is
  // intentionally unconsumed (a balanced ancilla, not a data value).
  (void)lowerCompareToFlag(Cmp, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                           /*before=*/At);
}

}  // namespace

void lowerControlledRegions(Module &M, WidthDispatch &wd, TaintSet &taint,
                            ControlPlan &plan) {
  (void)M;
  if (plan.Regions.empty())
    return;

  // Outer→inner: stable sort by Depth ascending so an enclosing region is
  // bracketed before its nested ones (PRD §2.9). WP3 is flat (all Depth 0).
  SmallVector<ControlRegion *, 4> Order;
  for (ControlRegion &R : plan.Regions)
    Order.push_back(&R);
  std::stable_sort(Order.begin(), Order.end(),
                   [](const ControlRegion *A, const ControlRegion *B) {
                     return A->Depth < B->Depth;
                   });

  // LIFO flag stack — the nesting seam (PRD §2.9). For the flat WP3 case the
  // bracket is emitted per region (compute in ControlFlag, uncompute before
  // linearization), which is the depth-1 specialization of the LIFO discipline.
  SmallVector<Value *, 4> FlagStack;

  for (ControlRegion *RP : Order) {
    ControlRegion &R = *RP;
    if (R.Kind != ControlRegion::BranchRegion)
      continue;  // select-sourced regions are WP4.

    // 1. Control-wire (flag compute). On failure the compare was diagnosed;
    //    leave the region untouched (the `br i1`/`icmp` stay, verify-clean).
    if (!lowerControlFlag(R, wd, taint))
      continue;
    FlagStack.push_back(R.Flag);

    // 2. Controlled substitution of the in-shadow gate bodies.
    substituteControlled(R, wd, taint);

    // 3. Dissolve the merge φ to the in-place handle (must precede block
    //    erasure so no use dangles, §1.6).
    dissolveMerge(R, taint);

    // 4. Flag uncompute, minted while the `icmp` still stands and anchored at
    //    the merge boundary so it brackets the controlled body (§1.5).
    emitUncompute(R, wd, taint);
    FlagStack.pop_back();

    // 5. Collapse the diamond to a single straight-line block; erase the dead
    //    `icmp` last. No `br i32` is ever created (§1.1).
    linearizeRegion(R);
  }
}

}  // namespace cq
