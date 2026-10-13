// PoisonFlow.cpp — bd bwfp / dm7f.21: see PoisonFlow.h. The bwfp poison dataflow
// (from CallContract.cpp) plus the speculation-safe twin mode (dm7f.21).
#include "PoisonFlow.h"

#include "CallContract.h"
#include "FlagProof.h"          // createsPoison
#include "SpeculationSafety.h"  // callExecutionIsDefined (declared there)
#include "TwinTotality.h"       // TwinTotality, divisionIsTotal (batch 053)

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

#include <optional>

using namespace llvm;
namespace cq {
namespace pflow {

// Does POISON reach a SINK when `F` runs with the parameters in its mask
// possibly poison? A sink is an operand LLVM itself says is UB on poison
// (`getGuaranteedNonPoisonOps`: a `noundef` return, a branch or switch
// condition, an inner call's `noundef` parameter, a divisor, a pointer). Every
// other poison is tolerated, which is the 6.5 owner's own argument (a poison
// RESULT is never merged on a shielded state;
// control_classical_call_arm_accept_poisonselect_callee.ll). Also refused, as UB
// at the call: an inner call whose calling convention differs from its callee's,
// and a value-constraining parameter attribute (`range`, `nonnull`, ...) a
// defined value may violate. Poison SOURCES include an unproven value-
// constraining return attribute on any callee or call site in the tree (bwfp
// review round 3 F1) and every flag `createsPoison` cannot prove from flag-free
// operand facts (dm7f.21). The strict body walk owns memory, control and
// division; a `speculatable` body (the caller's other admission) may branch and
// loop, so the scan runs to a fixpoint. Union propagation is monotone, so a set
// of poison parameters causes UB iff one of them does.
//
// TWIN MODE (dm7f.21) asks the same question of the callee's speculation-safe
// twin: every parameter possibly poison, and a sink a `freeze` discharges (a
// `ret`, a branch or switch condition, a call argument) is recorded as frozen
// instead of counted; a divisor the twin GUARDS is discharged by the guard
// (TwinTotality.h). `Hard` is UB no edit discharges. A twin's every may-poison
// `ret` is frozen and its value constraints are dropped, so its result is
// defined for any caller. An inner call is redirected to its callee's twin when
// poison reaches a sink there, when the call site's parameter contract holds
// only once the twin drops `range`/`nofpclass`/`returned` (dm7f.25), or when the
// callee's own body is not total (a loop or a guarded divisor in its tree): the
// original then never runs on a frozen value. A plan read off an ORIGINAL body
// is only a first draft: its proofs read facts (`returned`, `range`, `noundef`
// through a `freeze`) that the twin's own edits falsify (R11 round 1, F1/F2),
// so the builder re-asks this walk of each built twin until it plans nothing.
struct Flow {
  bool UB = false;
  bool Hard = false;
  bool RetMayPoison = false;
};

struct Plan {
  SetVector<std::pair<const Instruction *, unsigned>> Freeze;
  SetVector<const CallInst *> StripRet, Redirect;
};

// The flow of `F` with the parameters in `Mask` possibly poison, in one mode.
struct Query {
  const Function *F;
  uint64_t Mask;
  bool Twin;
};

// bd ziuw's lesson, re-learned: the recursive bwfp walk overflowed the 8MB stack
// on a 60000-deep chain (lowering_predmux_purecallee_deep_chain.ll, rc=132, no
// diagnostic). Queries are solved on `Stack`, a heap call path: a body walk that
// meets an unanswered callee query stops, pushes it, and reruns once answered.
struct FlowCtx {
  DenseMap<std::pair<const Function *, uint64_t>, Flow> Memo;
  DenseMap<const Function *, Flow> TwinMemo;
  DenseMap<const Function *, Plan> Plans;
  SmallVector<Query, 16> Stack;
  DenseMap<const Function *, unsigned> Pending;  // functions on `Stack`
  std::optional<Query> Need;  // the first query a body walk could not answer
  TwinTotality Tot;           // which originals a twin may call un-redirected
};
} // namespace pflow
struct TwinPlanner::State { pflow::FlowCtx X; };

namespace {
using namespace pflow;

bool cfgCyclic(const Function &F) {
  for (scc_iterator<const Function *> It = scc_begin(&F); !It.isAtEnd(); ++It)
    if (It.hasCycle())
      return true;
  return false;
}

// A use whose poison `freeze` makes defined without other UB: `ret`, branch or
// switch condition, call argument. Not a divisor or pointer (zero, out of bounds).
bool freezable(const Instruction &I, unsigned OpNo) {
  if (isa<ReturnInst>(I) || isa<BranchInst>(I) || isa<SwitchInst>(I))
    return true;
  const auto *C = dyn_cast<CallInst>(&I);
  return C && OpNo < C->arg_size();
}

// dm7f.30: the divisor of a division the twin guards (`select(bad, 1, freeze d)`,
// TwinTotality.h): the guard's own `freeze` discharges its poison.
bool guarded(const Instruction &I, unsigned OpNo) {
  return !divisionIsTotal(I) && I.getOperand(OpNo) == I.getOperand(1);
}

// A query's answer when it is known (memoized, a declaration, or a call-graph
// cycle through a pending function); otherwise it becomes the walk's need.
std::optional<Flow> ask(const Function &F, uint64_t Mask, bool Twin,
                        FlowCtx &X) {
  if (Twin) {
    if (auto It = X.TwinMemo.find(&F); It != X.TwinMemo.end())
      return It->second;
  } else if (auto It = X.Memo.find({&F, Mask}); It != X.Memo.end()) {
    return It->second;
  }
  Flow V;
  if (F.isDeclaration()) {
    // A bodyless speculatable callee: poison in, poison out; its own `noundef`
    // return is a sink. Its twin is the wrapper (dm7f.26; asked only of a root:
    // an inner declaration is the call branch's question).
    V.RetMayPoison = true;
    V.UB = Twin || (Mask && F.hasRetAttribute(Attribute::NoUndef));
    V.Hard = Twin && !declarationWrapperExists(F);
    return V;
  }
  if (X.Pending.lookup(&F)) {
    V.UB = V.Hard = true;  // a cycle: the strict walk refuses it; never prove through one
    return V;
  }
  if (!X.Need)
    X.Need = Query{&F, Mask, Twin};
  return std::nullopt;
}

// One body, both modes. `P` collects the twin's edits. False when a callee query
// is unanswered (`X.Need`): the caller solves it and walks this body again.
bool walkBody(const Function &F, uint64_t Mask, bool Twin, FlowCtx &X, Flow &V,
              Plan &P) {
  // A cyclic body gets no flag proof; its twin's loops are bounded by the
  // counters TwinTotality.h adds (dm7f.27), the union propagation runs to a
  // fixpoint below, and every sink is frozen on every trip.
  const bool Cyclic = cfgCyclic(F);
  SmallPtrSet<const Value *, 32> May;
  for (const Argument &A : F.args())
    if (A.getArgNo() < 64 && ((Mask >> A.getArgNo()) & 1))
      May.insert(&A);
  auto may = [&](const Value *Op) {
    if (const auto *K = dyn_cast<Constant>(Op))
      return !isa<Function>(K) && !isGuaranteedNotToBeUndefOrPoison(K);
    return May.count(Op) != 0;
  };
  auto mayAt = [&](const Instruction &I, unsigned N) {
    return !P.Freeze.count({&I, N}) && may(I.getOperand(N));
  };
  auto hard = [&] {  // UB no freeze discharges
    V.UB = true;
    V.Hard |= Twin;
  };
  bool Grew = true;
  while (Grew) {
    Grew = false;
    for (const BasicBlock *BB : ReversePostOrderTraversal<const Function *>(&F))
      for (const Instruction &I : *BB) {
        SmallVector<const Value *, 4> Sinks;
        getGuaranteedNonPoisonOps(&I, Sinks);
        const bool IsRet = isa<ReturnInst>(I);
        for (unsigned N = 0, E = I.getNumOperands(); N != E; ++N) {
          if (!mayAt(I, N))
            continue;
          if (IsRet && !Twin)
            V.RetMayPoison = true;
          if (!is_contained(Sinks, I.getOperand(N)) && !(Twin && IsRet))
            continue;
          if (Twin && freezable(I, N))
            P.Freeze.insert({&I, N});
          else if (!(Twin && guarded(I, N)))
            hard();
        }
        if (I.isTerminator()) {
          // An `unreachable` becomes `ret <zero>` in the twin (TwinTotality.h).
          if (Twin && !isa<ReturnInst>(I) && !isa<BranchInst>(I) &&
              !isa<SwitchInst>(I) && !isa<UnreachableInst>(I))
            hard();
          continue;
        }
        if (isa<FreezeInst>(I))
          continue;
        bool Pois = false;
        const auto *C = dyn_cast<CallInst>(&I);
        if (!C) {
          Pois = createsPoison(I, /*AllowProofs=*/!Cyclic);
          for (unsigned N = 0, E = I.getNumOperands(); N != E && !Pois; ++N)
            Pois = mayAt(I, N);
        } else {
          if (!callExecutionIsDefined(C))
            hard();
          const Function *G = C->getCalledFunction();
          // dm7f.25: a contract that holds once a twin drops `range`/`nofpclass`/
          // `returned` forces the redirect (a body's twin only: a declaration's
          // attributes stay its own).
          bool Drop = false;
          uint64_t M = 0;
          for (unsigned N = 0; N != C->arg_size(); ++N) {
            if (!paramContractIsInert(C, N)) {
              if (Twin && G && !G->isDeclaration() && twinParamContractHolds(C, N))
                Drop = true;
              else
                hard();
            }
            // A `noundef` argument was a sink above (frozen, or UB).
            if (!mayAt(*C, N) || C->paramHasAttr(N, Attribute::NoUndef))
              continue;
            if (N < 64)
              M |= uint64_t(1) << N;
            else if (Twin)
              P.Freeze.insert({C, N});  // past the mask: never analysed
            else
              V.UB = true;
          }
          if (!G) {
            Pois = true;
          } else if (G->isIntrinsic() || (Twin && G->isDeclaration())) {
            // The intrinsic's own semantics (`createsPoison` proves a ctlz/cttz/
            // abs poison flag from its operand, and never trusts LLVM's "no
            // poison" for a `noundef` call, bwfp round 5 F1), then the call
            // site's return contract: a `range` LLVM's semantics imply is proven
            // (`callSiteReturnHolds`). A twin drops a site contract it cannot
            // keep. dm7f.26: a bodyless callee in a twin (the wrapper's call)
            // alike, possibly poison through an argument or its own unproven
            // return constraint; `declarationWrapperExists` predicts this branch.
            Pois = M != 0 ||
                   (G->isIntrinsic()
                        ? createsPoison(*C, /*AllowProofs=*/!Cyclic)
                        : !returnAttrsHold(G->getAttributes().getRetAttrs(), *G));
            bool SiteNoUndef = C->getAttributes().hasRetAttr(Attribute::NoUndef);
            const bool AttrPoison = !callSiteReturnHolds(*C);
            if (Twin && (AttrPoison || (Pois && SiteNoUndef))) {
              P.StripRet.insert(C);
              SiteNoUndef = false;
            }
            // A stripped site keeps counting as possibly poison: the facts this
            // walk read through its old `range` no longer hold in the twin.
            Pois |= AttrPoison;
            if (Pois && (SiteNoUndef || G->hasRetAttribute(Attribute::NoUndef)))
              hard();
          } else {
            const bool Ann =
                C->hasPoisonGeneratingFlags() || C->hasPoisonGeneratingMetadata();
            const std::optional<Flow> S = ask(*G, M, /*Twin=*/false, X);
            if (!S)
              return false;
            Pois = S->RetMayPoison || !callSiteReturnHolds(*C) || Ann;
            // The original must never run on a frozen value unless it is total.
            const bool Shape = Twin && (Drop || !X.Tot.originalTotal(*G));
            if (S->UB || (Pois && C->hasRetAttr(Attribute::NoUndef)) || Shape) {
              const std::optional<Flow> T =
                  Twin ? ask(*G, ~uint64_t(0), /*Twin=*/true, X) : S;
              if (!T)
                return false;
              if (!Twin)
                V.UB = true;
              else if (T->Hard || (Ann && C->hasRetAttr(Attribute::NoUndef)))
                hard();
              else
                P.Redirect.insert(C);
              // A twin's result is defined but not the callee's value where that
              // was poison: facts read through its `range`/`returned` no longer
              // hold downstream, so it stays possibly poison.
              Pois = true;
            }
            // Likewise a `returned` argument this plan froze (R11 round 2 F-A:
            // seen now, not one verification round per chained stage).
            for (unsigned N = 0; Twin && N != C->arg_size(); ++N)
              Pois |= P.Freeze.count({C, N}) &&
                      C->paramHasAttr(N, Attribute::Returned);
          }
        }
        if (Pois && May.insert(&I).second)
          Grew = true;
      }
  }
  // An unproven value constraint on `F`'s own return (`range`, `nofpclass`)
  // makes the result poison where it fails, and UB under `noundef`. A twin
  // drops it (its `ret`s are frozen, so the result is defined).
  if (!Twin && !returnAttrsHold(F.getAttributes().getRetAttrs(), F)) {
    V.RetMayPoison = true;
    if (F.hasRetAttribute(Attribute::NoUndef))
      V.UB = true;
  }
  return true;
}

// Each query is pushed at most once (pushed only when neither answered nor
// pending), and a pending callee answers as a cycle, so the loop terminates.
Flow solve(const Function &F, uint64_t Mask, bool Twin, FlowCtx &X) {
  if (std::optional<Flow> V = ask(F, Mask, Twin, X))
    return *V;
  auto push = [&](const Query &Q) {
    X.Stack.push_back(Q);
    ++X.Pending[Q.F];
  };
  push(*X.Need);
  while (!X.Stack.empty()) {
    const Query Q = X.Stack.back();
    Flow V;
    Plan P;
    X.Need.reset();
    if (!walkBody(*Q.F, Q.Mask, Q.Twin, X, V, P)) {
      push(*X.Need);
      continue;
    }
    X.Stack.pop_back();
    --X.Pending[Q.F];
    if (Q.Twin) {
      X.TwinMemo[Q.F] = V;
      X.Plans[Q.F] = std::move(P);
    } else {
      X.Memo[{Q.F, Q.Mask}] = V;
    }
  }
  X.Need.reset();
  return *ask(F, Mask, Twin, X);
}

} // namespace

bool hoistUBWithPoisonArgs(const CallInst *Call, uint64_t PoisonArgs) {
  const Function *F = Call->getCalledFunction();
  if (!F)
    return true;
  FlowCtx X;
  const Flow V = solve(*F, PoisonArgs, /*Twin=*/false, X);
  // The hoisted call's own `noundef` return (call site or callee) is a sink too,
  // and an unproven value constraint on the call site's return is a source.
  const bool RetPoison = V.RetMayPoison || !callSiteReturnHolds(*Call) ||
                         Call->hasPoisonGeneratingFlags() ||
                         Call->hasPoisonGeneratingMetadata();
  return V.UB || (RetPoison && Call->hasRetAttr(Attribute::NoUndef));
}

bool twinFlowIsHard(const Function &F) {
  FlowCtx X;
  return solve(F, ~uint64_t(0), /*Twin=*/true, X).Hard;
}

TwinPlanner::TwinPlanner() : S(std::make_unique<State>()) {}
TwinPlanner::~TwinPlanner() = default;

std::optional<TwinEdits> TwinPlanner::edits(const Function &F) {
  if (solve(F, ~uint64_t(0), /*Twin=*/true, S->X).Hard)
    return std::nullopt;
  const Plan &P = S->X.Plans[&F];
  TwinEdits E;
  E.Freeze.assign(P.Freeze.begin(), P.Freeze.end());
  E.StripRet.assign(P.StripRet.begin(), P.StripRet.end());
  E.Redirect.assign(P.Redirect.begin(), P.Redirect.end());
  return E;
}

// Only a twin under construction changes; no strict answer about it exists yet
// (its callers, built after it, ask those). All else is unchanged.
void TwinPlanner::forget(const Function &F) {
  S->X.TwinMemo.erase(&F);
  S->X.Plans.erase(&F);
}

} // namespace cq
