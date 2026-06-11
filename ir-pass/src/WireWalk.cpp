// WireWalk.cpp — Shared forward in-place-gate wire walk. See WireWalk.h for
// the contract and the two consumer modes (ArmClassify position-free;
// OpcodeLowering position-aware). Hoisted from
// ArmClassify::wireGainsNonDiagonalGate (test_C_libtooling-ee5) so the
// straight-line stale-record guard (test_C_libtooling-uzb) reuses the same
// core instead of forking it (Rule 14).

#include "WireWalk.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

bool isCallToPrefix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with(Prefix);
}

}  // namespace

CallInst *findNonDiagonalWireGate(ArrayRef<Value *> Seeds,
                                  bool CrossValueRouting,
                                  const Instruction *EmitPoint,
                                  const DominatorTree *DT) {
  // Diagonal-alias seed closure (test_C_libtooling-6j1): a seed names a basis
  // RECORD, but the physical wire carrying it is shared with the seed's whole
  // diagonal ancestry — rotation lowering RAUWs a `cq_phi` and its arg-0 to
  // the SAME i32 handle, and Rz preserves the computational basis, so a
  // `cq_phi` result denotes its parent's record on its parent's wire. A
  // non-diagonal gate consuming a SIBLING SSA name of that ancestry
  // (`%qd = cq_phi(%q, ·); %q2 = cq_theta(%q, ·)`) is therefore an in-place
  // Ry on the seed's own wire that a forward-only walk from `%qd` can never
  // reach (the walk follows USER edges only). Close every seed BACKWARD
  // through `cq_phi` arg-0 hops before walking forward.
  //
  // The closure stops at the nearest non-`cq_phi` ancestor — the seed's
  // RECORD BOUNDARY (a theta, a template result, an argument), NOT
  // necessarily the physical wire origin: a CHAINED theta is mid-wire, and a
  // sibling Ry behind it stays invisible to this walk — a KNOWN-OPEN
  // pre-existing over-accept family, tracked in test_C_libtooling-6vk. The
  // never-cross-theta stop is a deliberately conservative choice: naively
  // seeding at a theta's parent puts the record-PRODUCING Ry itself on the
  // user frontier and over-declines every legitimate chained-rotation
  // consumer (accept boundary pinned by
  // lowering_stale_record_alias_producer.ll and
  // lowering_stale_record_add_before_theta.ll); a sound extension must
  // exempt ON-ancestry gates while still flagging OFF-ancestry siblings
  // (the 6vk fix sketch). Termination needs no visited set: arg-0 def
  // edges strictly ascend the dominance order for reachable code, and a
  // cyclic call chain is only expressible in UNREACHABLE code, which can
  // never be tainted (taint is a forward fixpoint from `cq_theta`) — the
  // same argument the pre-hoist ArmClassify manual closure relied on.
  SmallVector<Value *, 16> Work;
  for (Value *S : Seeds) {
    for (Value *V = S;;) {
      Work.push_back(V);
      auto *CI = dyn_cast<CallInst>(V);
      if (!CI || !isCallToPrefix(CI, "cq_phi_") || CI->arg_size() < 1)
        break;
      V = CI->getArgOperand(0);
    }
  }
  SmallPtrSet<Value *, 16> Seen;
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    for (User *U : V->users()) {
      if (CrossValueRouting) {
        // PHINodes and select VALUE operands route the same physical handle
        // onward (after rotation lowering's RAUW they are i32-handle muxes),
        // so a theta behind them is still an in-place gate on a wire the
        // seed may denote. A select's CONDITION use is not a routing edge.
        if (auto *P = dyn_cast<PHINode>(U)) {
          Work.push_back(P);
          continue;
        }
        if (auto *Sel = dyn_cast<SelectInst>(U)) {
          if (V != Sel->getCondition())
            Work.push_back(Sel);
          continue;
        }
      }
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI || CI->arg_size() < 1 || CI->getArgOperand(0) != V)
        continue;  // not an in-place gate on this wire (angle/data uses, br).
      if (isCallToPrefix(CI, "cq_theta_")) {
        // Non-diagonal in-place Ry on the wire. Position-free mode: decline
        // unconditionally. Position-aware mode: harmless iff PROVABLY after
        // every execution of `EmitPoint` —
        //   * `DT->dominates(EmitPoint, T)`: every path reaching T already
        //     executed the template (first-execution order), and
        //   * `!isPotentiallyReachable(T, EmitPoint)`: once T fired, the
        //     template never re-executes (a loop back-edge would otherwise
        //     replay the template against the post-Ry wire on iteration 2
        //     while its SSA operand still denotes the pre-Ry record).
        // Both proven ⇒ every template instance precedes every Ry instance
        // on every trace, so the walk may stop here: any theta further down
        // this wire uses (a value dominated by) T's result, hence is also
        // after every template instance, and a reach-back from it would
        // imply a reach-back from T. Unproven ⇒ return T (decline; over-
        // decline is safe, Prime Directive).
        if (EmitPoint && DT && DT->dominates(EmitPoint, CI) &&
            !isPotentiallyReachable(CI, EmitPoint, /*ExclusionSet=*/nullptr,
                                    DT))
          continue;  // provably post-emission on every trace — harmless.
        return CI;
      }
      if (isCallToPrefix(CI, "cq_phi_"))
        Work.push_back(CI);  // diagonal — same wire, keep walking forward.
    }
  }
  return nullptr;
}

}  // namespace cq
