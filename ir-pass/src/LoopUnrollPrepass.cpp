// LoopUnrollPrepass.cpp — 3c6m.55 Inc 2 (Lever B, ticket lf8s): static-K
// force-unroll of proven-constant-trip loops. See LoopUnrollPrepass.h for the
// fence contract (U1–U8) and the PRD (§ Lever B) for the design of record.
//
// Placement (CQLoweringPass.cpp): AFTER the promoteFp80Union + PredMux
// fixpoints — the U7 relevance test (tainted value in-loop / tainted-arg cone)
// must read the SAME settled taint `detectSpecializations` will read, and the
// taint that reaches an `__polevll` accumulator flows through Lever-A-promoted
// unions, so a pre-fixpoint run would mis-classify the target as classical —
// and BEFORE `detectSpecializations`, so both the spec-scan and the later
// clone see the unrolled body, and BEFORE `lowerLoops`, so a claimed loop is
// gone before `tryCaseA` would X1-decline it. Disjointness from the loops
// `lowerLoops` accepts rolled-in-place is structural, not positional:
//   * Case A requires a tainted header phi whose latch incoming peels through
//     in-place gates (`cq_theta`/`cq_phi` calls — U2) or in-place add/xor
//     self-updates (U4) back to the phi itself (U4);
//   * Case B (iteration-local) requires every tainted operand defined in-loop,
//     i.e. an in-loop `cq_theta` mint (U2);
//   * `tryBreak`/Q1 require a tainted exiting condition (U5).
// Every fence failure is a silent SKIP (accept-only, the PredMux discipline):
// the loop keeps its existing loud owner, so this pre-pass adds no decline
// surface and can never turn an accept into a decline.

#include "LoopUnrollPrepass.h"

#include "LoopPlan.h"
#include "TaintPropagation.h"

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/OptimizationRemarkEmitter.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/LoopSimplify.h"
#include "llvm/Transforms/Utils/LoopUtils.h"
#include "llvm/Transforms/Utils/UnrollLoop.h"

#include <cstdlib>

using namespace llvm;

namespace cq {

namespace {

// U6 upper bound. The driver shapes (the openlibm `__polevll` Horner loops)
// have trips 2 and 3; 8 leaves headroom for wider polynomial tables without
// admitting unbounded code growth.
constexpr unsigned kMaxUnrollTrip = 8;

// U8 body-size cap (instructions across the loop's blocks). The `__polevll`
// body is ~7 instructions; 64 × trip 8 bounds the worst-case growth at 512.
constexpr unsigned kMaxUnrollBodySize = 64;

bool isCqFamilyCallee(const Function *F) {
  StringRef N = F->getName();
  return N.starts_with("cq_") || N.starts_with("cqrt_");
}

// U7 cone: every visible non-`cq_*` callee transitively reachable from a call
// site that passes a tainted argument (the Phase-6 spec-candidate cone,
// over-approximated: transitive callees join on ANY call from a cone member,
// mirroring the 6.3 worklist which taints inner call sites only at
// clone-lowering time). Over-approximation is safe — membership only marks a
// loop RELEVANT; every safety fence is per-loop.
void collectTaintedCalleeCone(Module &M, const TaintSet &taint,
                              DenseSet<const Function *> &Cone) {
  SmallVector<const Function *, 8> Work;
  for (Function &F : M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        if (!Callee || Callee->isDeclaration() || isCqFamilyCallee(Callee))
          continue;
        bool TaintedArg = false;
        for (Value *A : CB->args())
          if (taint.Tainted.count(A)) {
            TaintedArg = true;
            break;
          }
        if (TaintedArg && Cone.insert(Callee).second)
          Work.push_back(Callee);
      }
  while (!Work.empty()) {
    const Function *F = Work.pop_back_val();
    for (const BasicBlock &BB : *F)
      for (const Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        if (!Callee || Callee->isDeclaration() || isCqFamilyCallee(Callee))
          continue;
        if (Cone.insert(Callee).second)
          Work.push_back(Callee);
      }
  }
}

// The per-loop fence, U1–U8 (LoopUnrollPrepass.h). Pure analysis; a false
// return leaves the loop byte-untouched for its existing owner.
bool fencePasses(Loop *L, const TaintSet &taint,
                 const SmallPtrSetImpl<CallInst *> &GateCalls,
                 ScalarEvolution &SE, bool FunctionInCone, unsigned &TripOut) {
  // U1 — innermost only; an enclosing const-trip loop is claimed on a later
  // fixpoint turn, once its inner loops have been unrolled away.
  if (!L->isInnermost())
    return false;

  // U2/U2b/U3/U8(size) in one walk over the loop's instructions.
  unsigned Size = 0;
  bool AnyTaintedInLoop = false;
  for (BasicBlock *BB : L->blocks()) {
    for (Instruction &I : *BB) {
      if (++Size > kMaxUnrollBodySize)
        return false;
      if (taint.Tainted.count(&I))
        AnyTaintedInLoop = true;
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        Function *Callee = CB->getCalledFunction();
        // U2: an indirect call is an unprovable callee; a `cq_*`/`cqrt_*`
        // call is the rolled-in-place / measure / QRAM owners' vocabulary;
        // convergent/noduplicate must not be cloned.
        if (!Callee || isCqFamilyCallee(Callee) || CB->isConvergent() ||
            CB->cannotDuplicate())
          return false;
      }
      // U2b: tainted-operand MEMORY allocation/access (or address arithmetic)
      // stays with the L3 tainted-index QRAM/Shadow owner and the escape
      // guard — the memory analog of U3, mirroring `markIfIterationLocal`'s
      // L3 walk. Without this the fence admitted a const-trip tainted-index
      // gep/load/store loop (no cq call, no add/xor rail), converting the
      // rolled form's loud `kMsgQramLoop` decline into an unreviewed
      // straight-line accept — and routing the Shadow store shape into a
      // latent lowerShadowMemory crash (the lf8s Rule-13 review's confirmed
      // blocking find; the crash itself is pre-existing, bd gyc9). AllocaInst
      // is in the class explicitly: it is neither a gep nor mayRead/Write,
      // yet a DEAD tainted-SIZE alloca otherwise rides UnrollLoop's internal
      // trivially-dead cleanup past the escape guard (the fix-delta review's
      // find — deleting dead side-effect-free code is unitary-equivalent,
      // but a decline→accept conversion without per-shape review violates
      // the fence contract). A CLASSICAL memory access (the `@P`/`@Q`
      // coefficient loads — untainted address, untainted value) is
      // unaffected.
      if (isa<AllocaInst>(I) || isa<GetElementPtrInst>(I) ||
          I.mayReadFromMemory() || I.mayWriteToMemory())
        for (Value *Op : I.operands())
          if (taint.Tainted.count(Op))
            return false;
    }
    // U3: tainted in-loop control stays with ControlDetect/RegionTreeDetect/
    // the d8jl in-loop guard (mirrors `tryCaseA` L2); any NON-`br` terminator
    // (switch/callbr/…) is an unproven latch/exit shape — skipping it also
    // keeps the claim path residue-free (a switch latch made `UnrollLoop`
    // bail AFTER the simplify/LCSSA mutation — the Rule-13 review's
    // mutate-on-skip note).
    Instruction *T = BB->getTerminator();
    auto *BI = dyn_cast<BranchInst>(T);
    if (!BI)
      return false;
    if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
      return false;
  }

  // U4 — the shared 799w/dtzb rail-structure predicate (LoopLowering.cpp).
  if (loopHasInPlaceRailStructure(L, taint, GateCalls))
    return false;

  // U5 — one exiting block, conditional `br` on an untainted condition.
  BasicBlock *Exiting = L->getExitingBlock();
  if (!Exiting)
    return false;
  auto *EBI = dyn_cast<BranchInst>(Exiting->getTerminator());
  if (!EBI || !EBI->isConditional() || taint.Tainted.count(EBI->getCondition()))
    return false;

  // U6 — the exact-constant-trip proof. `getSmallConstantTripCount` is the
  // exact count of header executions when SCEV can fold the backedge-taken
  // count to a constant (0 = unknown). Requiring max == exact is the witness
  // that `UnrollLoop`'s internal `CompletelyUnroll = Count == MaxTripCount`
  // fires, so the claim can only produce straight-line code, never a partial
  // unroll (wrong-trip-count = wrong program is the Rule-13 core; both sides
  // of the comparison come from the same SCEV instance the utility receives).
  unsigned Trip = SE.getSmallConstantTripCount(L);
  if (Trip == 0 || Trip > kMaxUnrollTrip ||
      SE.getSmallConstantMaxTripCount(L) != Trip)
    return false;

  // U7 — quantum relevance: the expl-inlined census shape (tainted values in
  // the loop) or the spec-candidate cone (the callee whose clone must inherit
  // the unrolled body). A loop in neither position is not ours to churn.
  if (!AnyTaintedInLoop && !FunctionInCone)
    return false;

  // U8 — clone-safety residue (size counted above).
  if (!L->isSafeToClone() || L->getHeader()->hasAddressTaken())
    return false;

  TripOut = Trip;
  return true;
}

}  // namespace

bool unrollConstTripLoops(Module &M, TaintSet &taint) {
  // The in-place-gate vocabulary for the shared U4 predicate — the same seed
  // `lowerLoops` builds for `tryCaseA`.
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());

  DenseSet<const Function *> Cone;
  collectTaintedCalleeCone(M, taint, Cone);

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    // The LoopLowering.cpp direct-construction idiom: a default TLI is a
    // conservative TLI, sufficient for SCEV's trip-count folding.
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);
    bool FunctionInCone = Cone.count(&F) != 0;

    for (Loop *L : LI.getLoopsInPreorder()) {
      unsigned Trip = 0;
      if (!fencePasses(L, taint, GateCalls, SE, FunctionInCone, Trip))
        continue;

      // Claim. `-O1` rotated loops are routinely NOT in loop-simplify form
      // (the second `__polevll` loop's entry predecessor is the first loop's
      // exiting block — two successors, no dedicated preheader), and
      // `UnrollLoop` bails without a preheader — so normalize first.
      // `simplifyLoop` is semantics-preserving; if the unroll still bails the
      // loop keeps declining with its existing owner, loudly.
      if (!L->isLoopSimplifyForm() &&
          !simplifyLoop(L, &DT, &LI, &SE, &AC, /*MSSAU=*/nullptr,
                        /*PreserveLCSSA=*/false))
        continue;
      if (!L->getLoopPreheader() || !L->getLoopLatch())
        continue;
      // LCSSA is LOAD-BEARING, not optional: `UnrollLoop` rewrites exit values
      // through the exit-block LCSSA phis. On a raw `-O1` loop whose result is
      // used DIRECTLY outside the loop (the `__polevll` accumulator; the
      // red-green fixture), skipping this remapped the out-of-loop use to the
      // FIRST iteration's value and let the dead later iterations fold away —
      // a verify-clean dropped-Horner-step silent miscompile, caught by
      // `lowering_unroll_const_trip.ll` on first contact. (The feasibility
      // spike missed it because `opt -passes=loop-unroll-full` runs inside the
      // loop-pass adaptor, which forms LCSSA before every loop pass.)
      formLCSSARecursively(*L, DT, &LI, &SE);

      // Exact full unroll: Count == the SCEV-proven trip, no runtime
      // remainder. `Force` only rescues the (disabled) runtime-remainder
      // path; the `!llvm.loop.unroll.disable` marker is loop-unroll-PASS
      // cost-model input the utility never reads — set anyway to pin intent.
      TargetTransformInfo TTI(M.getDataLayout());
      OptimizationRemarkEmitter ORE(&F);
      UnrollLoopOptions ULO;
      ULO.Count = Trip;
      ULO.Force = true;
      ULO.Runtime = false;
      ULO.AllowExpensiveTripCount = false;
      ULO.UnrollRemainder = false;
      ULO.ForgetAllSCEV = true;
      LoopUnrollResult R =
          UnrollLoop(L, ULO, &LI, &SE, &DT, &AC, &TTI, &ORE,
                     /*PreserveLCSSA=*/true);
      if (R == LoopUnrollResult::Unmodified)
        continue;
      // U6's max==exact witness makes a partial result unreachable; if it
      // ever fired it would still be semantics-preserving (a smaller loop),
      // adjudicated by the existing owners on the next turn.
      if (std::getenv("CQ_UNROLL_DBG"))
        errs() << "CQ_UNROLL_DBG: fully unrolled trip-" << Trip << " loop in @"
               << F.getName() << "\n";
      return true;  // one claim per call; caller re-propagates.
    }
  }
  return false;
}

}  // namespace cq
