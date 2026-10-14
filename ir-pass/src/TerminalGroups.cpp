// TerminalGroups.cpp — see the header (bd test_C_libtooling-p3kd.13; the cut
// records of bd r2j3.21 / r2j3.23 / r2j3.24 / p3kd.14).

#include "TerminalGroups.h"

#include "BirthFreeze.h"       // railBornZero (identity-store E2)
#include "ChainWalk.h"         // railOf / isAbiQramStore / isNonPermutationMove
#include "CloneProducer.h"     // isCloneProducer
#include "DagTraversal.h"      // DataDag / recoverDataDag (the cone)
#include "TaintPropagation.h"  // TaintSet::IterationLocalBlocks

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"  // all_of / is_contained
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"   // isPotentiallyReachable
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CFG.h"  // succ_begin (everyPathHits)
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <utility>

using namespace llvm;

namespace cq {

// ── CUT RECORDS — see the header ─────────────────────────────────────────────

namespace {

// Identity-store E2: `S` is an ABI store whose value (its LAST operand, in both
// frozen shapes) is a `cqrt_alloc_<W>` minted from a null constant
// (`railBornZero`: -0.0 is not null), untainted (QramLowering's classical `qval`
// basis handle), and never gated in place.
bool storesZero(const CallInst *S, const TaintSet &taint) {
  if (!isAbiQramStore(S))
    return false;
  const Value *V = S->getArgOperand(S->arg_size() - 1);
  if (taint.Tainted.count(V) || !isAllocMint(V) || isQramArrayHandle(V) ||
      !railBornZero(V, taint))
    return false;
  for (const User *U : V->users())
    if (const auto *G = dyn_cast<CallInst>(U))
      if (isInPlaceGateOn(G, V))
        return false;
  return true;
}

}  // namespace

bool isIdentityStore(const CallInst *S, const TaintSet &taint,
                     DominatorTree &DT) {
  if (!isAbiQramStore(S))
    return false;
  const Value *Arr = railOf(const_cast<CallInst *>(S));
  if (!isQramArrayHandle(Arr) || !storesZero(S, taint))  // E1, E2
    return false;
  for (const User *U : Arr->users()) {
    const auto *C = dyn_cast<CallInst>(U);
    if (!C)
      return false;  // E4: a non-call user — fail closed
    if (C == S)
      continue;
    if (isInPlaceGateOn(C, Arr)) {
      // E3: another store on the array that can run before `S` (a back edge
      // counts) must write 0 too, so every cell still holds 0 when `S` runs. One
      // that cannot reach `S` does not affect it (it is a cut record of its own).
      if (isPotentiallyReachable(C, S, /*ExclusionSet=*/nullptr, &DT) &&
          !storesZero(C, taint))
        return false;
      continue;
    }
    // E4: every other user READS the array — a forward load (`_hl` included) or a
    // load `_unc`. A store `_unc` an earlier group emitted, or anything unknown,
    // refuses.
    const Function *Callee = C->getCalledFunction();
    if (!Callee || !Callee->getName().starts_with("cqrt_qram_load_"))
      return false;
  }
  return true;
}

namespace {

// Does EVERY path from `From` (exclusive) to `To` pass an instruction `Hit`
// accepts? A forward block walk: a block holding a hit (entered from its top, or,
// for `From`'s own block, after `From`) covers every path through it. Reaching
// `To` first, or re-entering `From`'s block (the next activation), is a path
// without one (conservative).
template <typename HitT>
bool everyPathHits(const Instruction *From, const Instruction *To, HitT Hit) {
  const BasicBlock *FB = From->getParent();
  for (const Instruction *I = From->getNextNode(); I; I = I->getNextNode()) {
    if (I == To)
      return false;
    if (Hit(I))
      return true;
  }
  SmallVector<const BasicBlock *, 8> Work(succ_begin(FB), succ_end(FB));
  SmallPtrSet<const BasicBlock *, 16> Seen;
  while (!Work.empty()) {
    const BasicBlock *B = Work.pop_back_val();
    if (!Seen.insert(B).second)
      continue;
    if (B == FB)
      return false;
    bool Covered = false;
    for (const Instruction &I : *B) {
      if (&I == To)
        return false;
      if (Hit(&I)) {
        Covered = true;
        break;
      }
    }
    if (!Covered)
      Work.append(succ_begin(B), succ_end(B));
  }
  return true;
}

}  // namespace

// See the header (R11 r1 A-F2). A later user of the array keeps a store's record
// only if it is a forward LOAD that may read a cell the store wrote; a later store
// or any adjoint never counts. Non-aliasing is claimed only where it is PROVEN:
// two literal indices that differ, or a literal index outside the range of a
// one-bit index register (`cqrt_alloc_i1`, or an `i1`-wide handle). Anything else
// may alias (fail closed: the record counts as kept; p12_forced stays accepted).
bool mayObserveStore(const CallInst *U, const CallInst *S,
                     const TaintSet &taint) {
  const Function *UC = U ? U->getCalledFunction() : nullptr;
  if (!UC || !isAbiQramStore(S))
    return false;
  StringRef UN = UC->getName();
  if (!UN.starts_with("cqrt_qram_load_") || UN.ends_with("_unc"))
    return false;
  const auto *K =
      U->arg_size() == 2 ? dyn_cast<ConstantInt>(U->getArgOperand(1)) : nullptr;
  if (!K)
    return true;  // a quantum-index load may read any cell
  const bool Guarded =
      S->getCalledFunction()->getName().ends_with("_controlled");
  const Value *Idx = S->getArgOperand(Guarded ? 2 : 1);
  if (const auto *SK = dyn_cast<ConstantInt>(Idx))
    return SK->getValue().getSExtValue() == K->getValue().getSExtValue();
  bool OneBit = false;
  if (const auto *IC = dyn_cast<CallInst>(Idx))
    if (const Function *IF = IC->getCalledFunction())
      OneBit = IF->getName() == "cqrt_alloc_i1";
  auto It = taint.HandleWidth.find(const_cast<Value *>(Idx));
  if (It != taint.HandleWidth.end() && It->second == "i1")
    OneBit = true;
  return !(OneBit && K->getValue().getZExtValue() > 1);
}

bool isHazardousCutRecord(CallInst *G, Instruction *At, DominatorTree &DT,
                          const TaintSet &taint,
                          const SmallPtrSetImpl<const CallInst *> &Reversed) {
  if (isIdentityStore(G, taint, DT))
    return false;
  Value *R = railOf(G);
  // The record's CONE: every tainted operand the gate reads besides its own rail
  // (a store's index, value and guarded path flag; a load's array and index; a
  // template's handles), walked backward with no frontier.
  SmallVector<Value *, 4> Ops;
  for (Value *Op : G->args())
    if (Op != R && !isa<Constant>(Op) && taint.Tainted.count(Op) &&
        !llvm::is_contained(Ops, Op))
      Ops.push_back(Op);
  if (Ops.empty())
    return false;  // reads no quantum register: it records nothing quantum
  DataDag Cone = recoverDataDag(Ops, taint, DT);
  for (Value *Root : Cone.Roots)
    if (!isAllocMint(Root))
      return true;  // a φ / select / argument root: its moves are invisible here
  SmallPtrSet<Value *, 16> Members(Cone.Rails.begin(), Cone.Rails.end());
  for (CallInst *C : Cone.Calls)
    if (Value *X = railOf(C))
      if (!isa<Constant>(X))
        Members.insert(X);
  // THE INVARIANT (R11 r1: one final-outcome question per (record, move) pair,
  // L3). The record is harmless for a later non-permutation move M of a cone
  // register iff, on EVERY path from the record to M, it is collapsed or kept:
  //   (a) a measurement of R lies on every path from G to M (R11 r1 C-F1: asked
  //       per move, not per exit);
  //   (b) R is GARBAGE on every path to M: a non-permutation gate on R, and after
  //       it a KEPT reader of R — one no committed plan reverses, a measurement, or
  //       a gate whose rail is measured or still used after M — both lie on every
  //       path from G to M, so no schedule clears R before M (owner ruling
  //       2026-10-03: keep it and warn; R11 r1 A-F1 / C-F2: a reader merely
  //       REACHABLE after the rotation is not that);
  //   (c) the program keeps R across a move of M's register (`recordLiveAcrossMove`,
  //       whose store case counts only a later read that may observe a written
  //       cell, `mayObserveStore`, R11 r1 A-F2).
  auto readsR = [&](const CallInst *C) {
    for (const Value *Op : C->args())
      if (Op == R)
        return true;
    return false;
  };
  auto isMeasureOfR = [&](const Instruction *I) {
    const auto *C = dyn_cast<CallInst>(I);
    return C && isMeasureSink(C) && readsR(C);
  };
  auto garbageOnEveryPath = [&](const Instruction *M) {
    for (User *RotU : R->users()) {
      auto *Rot = dyn_cast<CallInst>(RotU);
      if (!Rot || !isNonPermutationMove(Rot, R) || !DT.dominates(G, Rot) ||
          !DT.dominates(Rot, M))
        continue;
      auto keptReader = [&](const Instruction *I) {
        const auto *U = dyn_cast<CallInst>(I);
        if (!U || U == Rot || isInPlaceGateOn(U, R) || Reversed.count(U) ||
            !readsR(U))
          return false;
        if (isMeasureSink(U))
          return true;
        // R11 r2 F2: the reader's rail is KEPT across M only if it is still used
        // after M (M dominates the use), or a measurement of it collapses it on
        // EVERY path from the reader to M — a measurement on some paths only is
        // not a keep.
        for (const User *W : U->users())
          if (const auto *WI = dyn_cast<Instruction>(W))
            if (DT.dominates(M, WI))
              return true;
        return everyPathHits(U, M, [&](const Instruction *X) {
          const auto *XC = dyn_cast<CallInst>(X);
          if (!XC || !isMeasureSink(XC))
            return false;
          for (const Value *Op : XC->args())
            if (Op == U)
              return true;
          return false;
        });
      };
      if (everyPathHits(Rot, M, keptReader))
        return true;
    }
    return false;
  };
  for (Value *P : Members) {
    if (taint.ControlOwnedRails.count(P) || taint.GraveyardRails.count(P))
      return true;  // another owner's register: fail closed
    for (User *U : P->users()) {
      auto *M = dyn_cast<CallInst>(U);
      if (!M || !isNonPermutationMove(M, P) ||
          !isPotentiallyReachable(G, M, /*ExclusionSet=*/nullptr, &DT))
        continue;
      // (c) asked of THIS move (R11 r2 F1: once per register, a record kept
      // across one move of P waived every other move of P).
      const bool Forced = At && recordLiveAcrossMove(G, R, P, At, DT, taint, M);
      if (Forced || everyPathHits(G, M, isMeasureOfR) || garbageOnEveryPath(M))
        continue;
      return true;
    }
  }
  return false;
}

CallInst *firstHazardousCutRecord(ArrayRef<CallInst *> Cut, Instruction *At,
                                  DominatorTree &DT, const TaintSet &taint,
                                  bool StoresOnly,
                                  const SmallPtrSetImpl<const CallInst *> &Reversed) {
  for (CallInst *G : Cut) {
    if (StoresOnly && !isAbiQramStore(G))
      continue;
    if (isHazardousCutRecord(G, At, DT, taint, Reversed))
      return G;
  }
  return nullptr;
}

// ── GROUP FORMATION (bd p3kd.13) ─────────────────────────────────────────────

void GroupProbe::addPlan(const DataDag &D) {
  Gates.insert(D.Calls.begin(), D.Calls.end());
  for (Value *R : D.Rails)
    if (!D.FrozenRails.count(R) && !isQramArrayHandle(R))
      Frees.insert(R);  // an array is never freed (bd 01po.4; since bd r2j3.21
                        // a walked array is no longer birth-frozen, BirthFreeze.h)
}

namespace {

template <typename SubT, typename SupT>
bool within(const SubT &Sub, const SupT &Sup) {
  return all_of(Sub, [&](const auto *X) { return Sup.count(X) != 0; });
}

// The bd kyy1 "never worse" test — the header's cases. `T` is the template
// terminals' ProbeAsLoud, `TmplOk` its verdict; `U` is the union's Probe. A union
// that leaves a HAZARDOUS cut record is never emitted (bd p3kd.14 — the planner's
// predicate, asked by the planner once and read here, R12): Silent would refuse
// it at emission. Only the union's cut is asked: it is the group's emission that
// would leave a cut record unreversed.
bool neverWorse(const GroupProbe &U, const GroupProbe &T, bool TmplOk) {
  if (U.HazardousCut)
    return false;
  if (TmplOk)
    return within(T.Gates, U.Gates) && within(T.Frees, U.Frees);
  return true;
}

}  // namespace

void reverseTerminalGroups(Function &F, ArrayRef<CallInst *> Terminals,
                           TaintSet &taint, WidthDispatch &wd, DominatorTree &DT,
                           PostDominatorTree &PDT, LoopInfo &LI,
                           SmallPtrSetImpl<const CallInst *> &ReversedGates,
                           SmallPtrSetImpl<Value *> &ReversedRails,
                           SmallVectorImpl<CallInst *> &Pending) {
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
                                ReversedRails, Pending, M, P);
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
