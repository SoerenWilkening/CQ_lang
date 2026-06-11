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
  // Seed closure + forward wire walk, PER SEED (test_C_libtooling-6j1, extended
  // for test_C_libtooling-6vk). A seed names a basis RECORD; the physical wire
  // carrying it is shared with the seed's whole ANCESTRY — rotation lowering
  // RAUWs a `cq_phi` (Rz, diagonal) AND a CHAINED `cq_theta` (Ry whose arg-0 is
  // itself a live quantum wire) and their arg-0 to the SAME i32 handle. So a
  // non-diagonal gate consuming a SIBLING SSA name of that ancestry
  // (`%q2 = cq_theta(%q, ·)` while the seed reads `%q` or a `cq_phi`/chained
  // theta over `%q`) is an in-place Ry on the seed's own wire that a forward-
  // only walk from the seed can never reach (it follows USER edges only).
  //
  // Close every seed BACKWARD through `cq_phi` arg-0 hops AND chained-`cq_theta`
  // arg-0 hops to the wire origin, recording the ON-ANCESTRY gates (the seed and
  // every gate that BUILT its record). That backward chain is exactly the gates
  // that PRODUCE the seed's record — they precede it on every trace and can
  // never stale it — so they are EXEMPT from the forward staling-gate frontier;
  // only an OFF-ancestry sibling theta (a second user of a shared parent handle,
  // NOT on the seed's own arg-0 chain) is stale evidence. This is the 6vk fix
  // sketch: the over-decline the previous never-cross-theta stop avoided came
  // ONLY from flagging the producing theta, which the exemption now prevents
  // (accept boundary pinned by lowering_stale_record_alias_producer.ll,
  // lowering_stale_record_add_before_theta.ll,
  // lowering_stale_record_chained_theta_onancestry.ll). A SOURCE theta's arg-0
  // is the classical init (not a quantum wire), so the closure stops there and
  // never reaches into classical scaffolding.
  //
  // The exempt set is per the ORIGINAL seed's own ancestry, so each seed is
  // walked INDEPENDENTLY: a theta off-ancestry of one seed but on-ancestry of
  // another must still be flagged for the first (it stales that seed's record),
  // which a shared/unioned exempt set would unsoundly hide. Termination needs no
  // visited set on the backward closure: arg-0 def edges strictly ascend the
  // dominance order for reachable (tainted) code, so the chain cannot cycle —
  // the same argument the pre-hoist ArmClassify manual closure relied on, now
  // also covering the chained-theta arg-0 edge.
  for (Value *Seed : Seeds) {
    SmallVector<Value *, 16> Work;
    SmallPtrSet<Value *, 16> Exempt;  // on-ancestry producers — never stale the record
    for (Value *V = Seed;;) {
      Work.push_back(V);
      Exempt.insert(V);
      auto *CI = dyn_cast<CallInst>(V);
      if (!CI || CI->arg_size() < 1)
        break;  // a non-call ancestor — the wire origin / record boundary.
      Value *Arg0 = CI->getArgOperand(0);
      if (isCallToPrefix(CI, "cq_phi_")) {
        V = Arg0;  // diagonal Rz hop — same wire, same basis record.
        continue;
      }
      // A CHAINED theta (arg-0 is itself a `cq_theta`/`cq_phi` quantum wire) is
      // an in-place Ry whose arg-0 shares the wire; cross it to reach the parent
      // record. A SOURCE theta (arg-0 is the classical init) is the wire origin.
      if (isCallToPrefix(CI, "cq_theta_") &&
          (isCallToPrefix(Arg0, "cq_theta_") || isCallToPrefix(Arg0, "cq_phi_"))) {
        V = Arg0;
        continue;
      }
      break;  // wire origin (source theta / template result / argument).
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
          // An ON-ancestry producing theta builds the seed's record (it is on
          // the seed's own backward arg-0 chain); it never stales the record,
          // and it is already on `Work`, so its own forward wire is walked from
          // there. Skip it as a staling candidate.
          if (Exempt.count(CI))
            continue;
          // An OFF-ancestry sibling Ry on a shared wire IS stale evidence.
          // Position-free mode (`EmitPoint` null): decline unconditionally.
          // Position-aware mode: harmless iff PROVABLY after every execution of
          // `EmitPoint` —
          //   * `DT->dominates(EmitPoint, T)`: every path reaching T already
          //     executed the template (first-execution order), and
          //   * `!isPotentiallyReachable(T, EmitPoint)`: once T fired, the
          //     template never re-executes (a loop back-edge would otherwise
          //     replay the template against the post-Ry wire on iteration 2
          //     while its SSA operand still denotes the pre-Ry record).
          // Both proven ⇒ every template instance precedes every Ry instance on
          // every trace — harmless. Unproven ⇒ return T (decline; over-decline
          // is safe, Prime Directive).
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
  }
  return nullptr;
}

}  // namespace cq
