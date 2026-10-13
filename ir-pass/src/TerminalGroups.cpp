// TerminalGroups.cpp — see the header (bd test_C_libtooling-p3kd.13).

#include "TerminalGroups.h"

#include "ChainWalk.h"         // railOf
#include "CloneProducer.h"     // isCloneProducer
#include "DagTraversal.h"      // DataDag
#include "TaintPropagation.h"  // TaintSet::IterationLocalBlocks

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"  // all_of
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <utility>

using namespace llvm;

namespace cq {

void GroupProbe::addPlan(const DataDag &D) {
  Gates.insert(D.Calls.begin(), D.Calls.end());
  for (Value *R : D.Rails)
    if (!D.FrozenRails.count(R))
      Frees.insert(R);
}

void GroupProbe::setCut(const DataDag &D,
                        const SmallPtrSetImpl<Value *> &Exempt) {
  for (CallInst *G : D.Calls)
    if (!Gates.count(G) && !Exempt.count(railOf(G)))
      Cut.insert(G);
}

namespace {

template <typename SubT, typename SupT>
bool within(const SubT &Sub, const SupT &Sup) {
  return all_of(Sub, [&](const auto *X) { return Sup.count(X) != 0; });
}

// The bd kyy1 "never worse" test — the header's two cases. `T` is the template
// terminals' ProbeAsLoud, `TmplOk` its verdict; `U` is the union's Probe.
// Under `!TmplOk`, `U.Cut` EMPTY — not `within(U.Cut, U.Gates)`, which is the same
// predicate spelt as if it could differ: `Cut` is taken AFTER the plans commit and
// excludes `Gates` by construction, and the M-B interior partition's plans (which
// may reverse a cut template record) run after every group and are never
// recorded here (R11 r7). Only the union's cut is asked: it is the group's
// emission that would leave a cut record unreversed where main declines.
bool neverWorse(const GroupProbe &U, const GroupProbe &T, bool TmplOk) {
  if (TmplOk)
    return within(T.Gates, U.Gates) && within(T.Frees, U.Frees);
  return U.Cut.empty();
}

}  // namespace

void reverseTerminalGroups(Function &F, ArrayRef<CallInst *> Terminals,
                           TaintSet &taint, WidthDispatch &wd, DominatorTree &DT,
                           PostDominatorTree &PDT, LoopInfo &LI,
                           SmallPtrSetImpl<const CallInst *> &ReversedGates,
                           SmallPtrSetImpl<Value *> &ReversedRails) {
  // The REGULAR group (reversed at the function post-dominator) and one group per
  // Phase-7.3 ITERATION-LOCAL loop (def block ∈ `IterationLocalBlocks`, reversed
  // IN-BODY once per iteration): one union point across that boundary would free
  // in-body rails at function scope (the Risk-1 hazard). Loops in first-seen (BB)
  // order, terminals in program order, for FileCheck-stable emission.
  SmallVector<SmallVector<CallInst *, 8>, 4> Groups(1);  // [0] = regular
  SmallVector<bool, 4> IterLocal(1, false);
  DenseMap<Loop *, unsigned> GroupOfLoop;
  for (CallInst *Term : Terminals) {
    Loop *L = LI.getLoopFor(Term->getParent());
    unsigned G = 0;
    if (L && !taint.IterationLocalBlocks.empty() &&
        taint.IterationLocalBlocks.count(Term->getParent())) {
      auto [It, New] = GroupOfLoop.try_emplace(L, Groups.size());
      if (New) {
        Groups.emplace_back();
        IterLocal.push_back(true);
      }
      G = It->second;
    }
    Groups[G].push_back(Term);
  }

  auto run = [&](ArrayRef<CallInst *> T, bool IL, GroupMode M,
                 GroupProbe *P = nullptr) {
    return reverseTerminalGroup(F, T, taint, wd, DT, PDT, LI, IL, ReversedGates,
                                ReversedRails, M, P);
  };
  SmallVector<std::pair<SmallVector<CallInst *, 8>, bool>, 4> DeferredClones;
  for (unsigned G = 0; G != Groups.size(); ++G) {
    SmallVector<CallInst *, 8> Tmpl, Clone;
    for (CallInst *Term : Groups[G])
      (isCloneProducer(Term, taint) ? Clone : Tmpl).push_back(Term);
    if (!Clone.empty()) {
      // Both probes are side-effect-free (GroupMode), so whichever way this goes,
      // the module the chosen plan sees is the one main's planner would see.
      GroupProbe U, T;
      const bool UnionOk = run(Groups[G], IterLocal[G], GroupMode::Probe, &U);
      // The template terminals' own plan EXACTLY as Loud would make it — no
      // disjointness check (R11 r3 F1), so `TmplOk` false means Loud emits nothing.
      const bool TmplOk = run(Tmpl, IterLocal[G], GroupMode::ProbeAsLoud, &T);
      if (UnionOk && neverWorse(U, T, TmplOk)) {
        // R11 r3 F5 — CHECKED, not argued: the probe accepted every plan of this
        // union, and planning is side-effect-free, so the re-plan must emit them
        // all. A component that refused here after an earlier one emitted would
        // leave the templates with neither the union nor their Loud plan; the
        // components share only BORROWED registers (`partitionByReducedDag`),
        // which no plan reverses or writes, so this cannot fire — loudly if it does.
        if (!run(Groups[G], IterLocal[G], GroupMode::Silent))
          F.getContext().diagnose(DiagnosticInfoUnsupported(
              F, "cq uncompute: internal invariant: a probed terminal union "
                 "refused at emission",
              Groups[G].front()->getDebugLoc()));
        continue;
      }
      DeferredClones.push_back({Clone, IterLocal[G]});
    }
    run(Tmpl, IterLocal[G], GroupMode::Loud);
  }
  for (auto &[Clone, IL] : DeferredClones)
    run(Clone, IL, GroupMode::Silent);
}

}  // namespace cq
