// Specialization.cpp — the Phase 6 specialization driver (step 14, DD-1).

#include "Specialization.h"

#include "BennettWrap.h"
#include "OpcodeLowering.h"
#include "OpcodeSupport.h"
#include "SpecializeClone.h"
#include "SpecializePlan.h"
#include "SpecializeSeed.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <vector>

using namespace llvm;

namespace cq {

namespace {

// A forward `cq_template_*` data call minted into the clone (exclude the void
// `_unc` / fresh-minting `_inv` adjoint twins, though none exist at capture time
// — BennettWrap mints them after). Used to build the forward stream + scratch
// rails for the Bennett wrap.
bool isForwardTemplate(const CallInst *CI) {
  const Function *F = CI->getCalledFunction();
  if (!F)
    return false;
  StringRef N = F->getName();
  return N.starts_with("cq_template_") && !N.ends_with("_unc") &&
         !N.ends_with("_inv");
}

// Erase `V` and its forward cone of consumers that lose ALL taint once `V` is
// scrubbed (§2.7 return-taint correction for a ReturnTainted=false clone). A
// consumer that still reads an independently-tainted operand keeps its taint.
void scrubForwardCone(Value *Root, TaintSet &taint,
                      const SmallPtrSetImpl<const Value *> &TaintedSources) {
  std::vector<Value *> Worklist;
  auto scrub = [&](Value *V) {
    taint.Tainted.erase(V);
    taint.BirthOrder.erase(V);
    if (auto *I = dyn_cast<Instruction>(V))
      taint.StaleDeclined.erase(I);
  };
  scrub(Root);
  Worklist.push_back(Root);
  while (!Worklist.empty()) {
    Value *V = Worklist.back();
    Worklist.pop_back();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || !taint.Tainted.count(I))
        continue;
      // A value that is its OWN taint source — a primary `cq_theta` result, or
      // another specialized-call result that legitimately carries taint — must
      // never be scrubbed transitively (its taint does NOT derive from the
      // scrubbed root). Stopping here also prunes its whole downstream cone from
      // the walk, so a fresh `cq_theta(%r, θ)` seeded from a scrubbed classical
      // `%r` keeps the qubit and every consumer of it tainted (the over-scrub
      // the Rule-13 axis-(g) probe caught). NOT `cq_phi`: a `cq_phi` on a
      // now-classical operand is deleted (Rule 3), so it is correctly scrubbed.
      if (TaintedSources.count(I))
        continue;
      bool HasOtherTaintedOperand = false;
      for (Value *Op : I->operands())
        if (taint.Tainted.count(Op)) {
          HasOtherTaintedOperand = true;
          break;
        }
      if (HasOtherTaintedOperand)
        continue;  // tainted via another path — keep.
      scrub(I);
      Worklist.push_back(I);
    }
  }
}

}  // namespace

bool shouldSpecialize(const CallInst *CI, const SpecPlan &plan) {
  for (const SpecCandidate &C : plan.Pending)
    if (C.Site == CI)
      return true;
  return false;
}

void specialize(Module &M, WidthDispatch &wd, TaintSet &taint, SpecPlan &plan) {
  // Each retargeted site + whether its clone returns a tainted handle (read
  // post-drain for the §2.7 return-taint re-seed). Both fresh clones and cache
  // hits are recorded.
  SmallVector<std::pair<CallInst *, bool>, 4> Retargeted;

  // Drain `Pending` (index loop so a future transitive worklist — 6.3 — can grow
  // it). Each Accept candidate was already proven specializable by detection.
  for (size_t i = 0; i < plan.Pending.size(); ++i) {
    SpecCandidate Cand = plan.Pending[i];
    SpecKey Key{Cand.Callee, Cand.Mask};

    // Cache hit: reuse the existing clone, retarget, record. No re-clone (C7).
    auto It = plan.Cache.find(Key);
    if (It != plan.Cache.end()) {
      Cand.Site->setCalledFunction(It->second.Clone);
      Retargeted.push_back({Cand.Site, It->second.ReturnTainted});
      continue;
    }

    // Miss: clone → seed (fresh disjoint cloneTaint) → scoped data lowering.
    Function *Clone = cloneFor(Cand);
    // Insert the (incomplete) record up front so a self/dedup reference resolves.
    plan.Cache[Key] = SpecRecord{Clone, false};

    TaintSet cloneTaint = seedClone(Clone, Cand.Mask);
    // Scoped lowering: `lowerOps` self-scopes by `cloneTaint` membership (C25) —
    // it walks all of `M` but lowers only the instructions in `cloneTaint`. The
    // clone has no theta/phi/measure (rejected), so no rotation/measure stage is
    // needed. `uncompute` is NEVER called here (DD-1).
    lowerOps(M, wd, cloneTaint);

    // Capture the forward stream + scratch rails (forward program order). The
    // result rail is the `ret` value when it carries taint; a classical /
    // no-output return has no handle to copy out.
    SmallVector<CallInst *, 8> ForwardStream;
    SmallVector<Value *, 8> ScratchRails;
    for (BasicBlock &BB : *Clone)
      for (Instruction &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (isForwardTemplate(CI)) {
            ForwardStream.push_back(CI);
            ScratchRails.push_back(CI);
          }

    auto *Ret = dyn_cast<ReturnInst>(Clone->getEntryBlock().getTerminator());
    Value *RV = Ret ? Ret->getReturnValue() : nullptr;
    bool ReturnTainted = RV && cloneTaint.Tainted.count(RV);
    Value *ResultRail = ReturnTainted ? RV : nullptr;
    StringRef RetW = abiWidthFromType(Clone->getReturnType());

    emitBennettWrap(*Clone, ForwardStream, ResultRail, ScratchRails, RetW, wd,
                    cloneTaint);

    plan.Cache[Key].ReturnTainted = ReturnTainted;
    Cand.Site->setCalledFunction(Clone);
    Retargeted.push_back({Cand.Site, ReturnTainted});
  }

  // §2.7 return-taint re-seed. The original `propagate` conservatively tainted
  // EVERY specialized-call result (a call reading a tainted arg, :305-306). The
  // clone's post-lowering `ReturnTainted` is the precise verdict:
  //   * true  → the result is genuine quantum data; leave it tainted (already in
  //     `taint`, downstream already propagated) — the caller's `:115` uncompute
  //     owns it (C-Taint).
  //   * false → the conservative taint was wrong (the return derives from
  //     classical params only); scrub the result and the forward cone that loses
  //     all taint, so a downstream caller op stays CLASSICAL (WI-1.9).
  // Never-scrub roots: every value whose taint is INDEPENDENT of a scrubbed
  // call result — the primary `cq_theta` sources (a theta result is quantum
  // regardless of its arg-0 seed, Rule 3) and every genuinely-tainted
  // specialized-call result. The walk stops at these, pruning their downstream
  // cones (axis-(g) over-scrub fix). `cq_phi` is deliberately absent — it is
  // not a source, and a `cq_phi` on a now-classical operand must be scrubbed.
  SmallPtrSet<const Value *, 8> TaintedSources;
  for (auto &R : Retargeted)
    if (R.second)
      TaintedSources.insert(R.first);
  for (const CallInst *Theta : taint.ThetaCalls)
    TaintedSources.insert(Theta);
  for (auto &R : Retargeted) {
    CallInst *Site = R.first;
    bool ReturnTainted = R.second;
    if (ReturnTainted) {
      taint.Tainted.insert(Site);  // robustness; usually already present.
    } else if (taint.Tainted.count(Site)) {
      scrubForwardCone(Site, taint, TaintedSources);
    }
  }
}

}  // namespace cq
