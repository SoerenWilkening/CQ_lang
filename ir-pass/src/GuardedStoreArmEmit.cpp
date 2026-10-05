// GuardedStoreArmEmit.cpp — see header. iw81.7: the guarded Shadow store.
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2).
// A store is GENUINELY CONTROLLED (not swap-routed): the diamond is flattened to
// straight-line, the store rewritten to the guarded symbol
// `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)` (Bennett
// `emit_shadow_store_guarded!` — each store CNOT lifted to a Toffoli(flag, ...), a
// no-op on cell+tape when flag=0). The flag is minted from the PRE-store condition
// handle (`q` is unchanged by a store, so it stays recomputable) and left LIVE so
// the whole-DAG LIFO uncompute reverses the guarded store via `..._controlled_unc`
// (flag arg 0) and then strips the flag (the flag-mint compare is a reversible DAG
// ancestor — §6.0 compare `_unc`). Never eagerly strip: an ungated `_unc` over-pops
// the inactive branch (a dephasing silent miscompile).
//
// bd dm7f.3 — THE COMPOSED REGION. The same step also owns an IF/ELSE whose arms
// each hold at most one guarded store, and an arm that holds register-free
// `cq_phi` calls beside (or instead of) its store, provided the region has at
// least one store. Each store gets its own flag (the FALSE arm's a negated mint);
// the phases ride a SEPARATE ancilla minted, kicked (`emitKickbackGroup`), stripped
// and freed by this emitter — never a store flag, which the spine strips (a
// branch-phase gate is opaque to it, `ChainWalk.h`). Analytic trace:
// control_guarded_store_ifelse_phase.ll's header.

#include "GuardedStoreArmEmit.h"

#include "ArmAnalysis.h"      // comparePredLowerable
#include "CompareLowering.h"  // lowerCompareToFlag (flag mint)
#include "ControlPlan.h"      // ControlRegion / diagnoseUnderControl
#include "ControlledSymbols.h" // xFn (the kickback's ¬flag bracket, bd dm7f.3)
#include "LiteralIntegrity.h" // declineAddressTakenBlocks (bd 7udx)
#include "OpcodeSupport.h"    // abiWidthFromType / widthHasReversibleCopy
#include "QramLowering.h"     // guardedShadowStoreShape (the shared shape predicate)
#include "SwapRouteEmit.h"    // emitKickbackGroup (bd dm7f.3, the one phase spelling)
#include "TaintPropagation.h" // TaintSet / isRegisterFreePhaseCall
#include "WidthDispatch.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"  // isSafeToSpeculativelyExecute
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// (the house-style dangling-work-list hygiene, mirroring AbortParkEmit). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  if (auto *SI = dyn_cast<StoreInst>(I))
    taint.GuardedStores.erase(SI);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase_value(CI);
  }
}

// Loud bail for a detection-guaranteed shape that did not hold at emit time. A
// silently skipped accepted region would hand the tainted `br` to the backend as
// classical control over quantum state (Rule 1).
void bailLoud(const ControlRegion &R) {
  if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
    diagnoseUnderControl(A, "control flow");
  else if (R.Merge)
    diagnoseUnderControl(R.Merge, "control flow");
}

// The tainted operand of an HL compare (exactly one operand tainted), or null if
// the compare is Q+Q or all-classical. Mirrors AbortParkEmit's helper.
Value *hlTaintedOperand(CmpInst *Cond, const TaintSet &Taint) {
  if (Cond->getNumOperands() < 2)
    return nullptr;
  Value *A = Cond->getOperand(0), *B = Cond->getOperand(1);
  bool TA = Taint.Tainted.count(A) != 0, TB = Taint.Tainted.count(B) != 0;
  if (TA == TB)
    return nullptr;
  return TA ? A : B;
}

// The CONTENT of one side-effect-only arm (bd dm7f.3 generalizes the iw81.7
// single-store arm): at most ONE `StoreInst`, any number of register-free
// branch-phase calls (`void @cq_phi(double)`, asked by EXACT membership —
// `isRegisterFreePhaseCall` — never by name), and side-effect-free instructions
// whose values stay inside the arm. `Ok` is false for anything else: a second
// store, a load, any other call, a side effect, or a value USED OUTSIDE the arm
// (a merge φ). Terminator excluded. It replaces `soleSideEffectStore`, the purity
// gate fixture headers name (lowering_reject_qram_guarded_store_two_arm.ll,
// …_side_effect.ll): a store-only arm reads as `Ok`, one `Store`, no `Phases`.
struct ArmContent {
  bool Ok = false;
  StoreInst *Store = nullptr;
  SmallVector<CallInst *, 2> Phases;
};

ArmContent armContent(BasicBlock *BB, const TaintSet &Taint) {
  ArmContent C;
  for (Instruction &I : *BB) {
    if (I.isTerminator())
      continue;
    if (isa<PHINode>(I))
      return ArmContent();  // the flatten would splice it mid-block: off-shape.
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (C.Store)
        return ArmContent();  // a second store — not a single side effect.
      C.Store = SI;
      continue;
    }
    if (auto *CI = dyn_cast<CallInst>(&I))
      if (isRegisterFreePhaseCall(CI, Taint) && CI->arg_size() == 1) {
        C.Phases.push_back(CI);  // a branch phase: lowered by kickback, erased.
        continue;
      }
    if (isa<LoadInst>(I) || isa<CallInst>(I) || isa<InvokeInst>(I) ||
        isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I))
      return ArmContent();  // another observable side effect — off-shape.
    // Rule-13 [C1]: ANY remaining side-effecting op (a volatile access, any op
    // `mayHaveSideEffects`) would be spliced into `Pred` by the flatten and fire
    // UNCONDITIONALLY (a classical side effect on the wrong branch — trace-
    // invisible, the canonical silent miscompile). A load/call/invoke/atomic/fence
    // are covered above (a non-volatile load is not `mayHaveSideEffects` but is
    // still an observable read we exclude); this is the catch-all for the rest.
    if (I.mayHaveSideEffects())
      return ArmContent();
    for (User *U : I.users())
      if (auto *UI = dyn_cast<Instruction>(U))
        if (UI->getParent() != BB)
          return ArmContent();  // a value escapes the arm (e.g. a merge φ).
  }
  C.Ok = true;
  return C;
}

// Does the condition read the array as DATA (§3c-conservative)? A guarded store
// whose branch condition transitively LOADs from memory could be writing a cell the
// flag was derived from (the flag would then reference a clobbered value). v1
// declines any condition whose tainted lineage contains a load. The common
// theta-compare condition has no load → accept.
bool conditionReadsMemory(CmpInst *Cond, const TaintSet &Taint) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Seen;
  for (Value *Op : Cond->operands())
    if (Taint.Tainted.count(Op) && Seen.insert(Op).second)
      Work.push_back(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (isa<LoadInst>(V))
      return true;
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;
    for (Value *In : I->operands())
      if (Taint.Tainted.count(In) && Seen.insert(In).second)
        Work.push_back(In);
  }
  return false;
}

// bd dm7f.3, L1 — may the classical value `V` become TAINTED at round 2?
//
// THE PREMISE, re-checked against every producer (review round 1, finding 2):
// `repropagateControlMerges` re-seeds forward taint only from
// `taint.UntaintedMergeRails`, and exactly three emitters fill it — 6.5
// `ClassicalCallArmEmit`, 4.5 `SwitchDataMuxEmit` and the 7.6 I/O-sink value mux
// (`IOSinkLowering`) — each RAUWing the MERGE φ of a region whose `br`/`switch`
// condition is tainted. The onward round (`detectAndLowerOnwardControl`, the
// `%out2` rails) runs the same emitters on a condition that turned quantum at
// round 2. Everything else round 2 taints is reached by plain data flow from
// those rails: operands, φ incomings, a `select`'s condition and arms, the
// arguments of a call that a re-planned specialization lifts. So `V` "may" turn
// quantum iff its operand cone reaches (a) a tainted value or (b) a φ whose
// deciding branches — the conditional terminators between the merge's immediate
// dominator and its incoming blocks — have a tainted or may-turn-tainted
// condition. A `select` and a classical φ are walked through, not refused: a
// classical ternary angle or a loop counter stays classical (the first version
// answered "may" for ANY φ or `select`, an over-decline with a misleading string).
// A `cq_measure` result is classical for good (the sink, asked by exact
// membership in `MeasureCalls`): the walk does not enter its operand, so
// measurement feed-forward stays admitted. Unreachable merges, and deciding
// terminators other than `br`/`switch`, answer "may".
//
// MEASURED reason it exists: `int y = (p>3) ? g(k) : 7; …; if (c<3) { arr[q&7]=7;
// cq_phi((double)y); }` has a classical angle at round 1, and at round 2 the
// `sitofp` of the 6.5 `%out` lowers to `cq_template_sitofp_i32_to_f64` feeding
// `cqrt_rz_i1`: a broken module (`opt` abort, exit 134).
// RETIREMENT TRIGGER: a round-2 re-ask of branch-phase angles and guarded store
// values (RECORD at emission, RE-ASK after the fixpoint, L1) replaces this.
bool mergeDecidersInto(const PHINode *P, const DominatorTree &DT,
                       SmallVectorImpl<const Value *> &Work,
                       SmallPtrSetImpl<const Value *> &Seen) {
  const DomTreeNode *N = DT.getNode(P->getParent());
  if (!N || !N->getIDom())
    return false;  // unreachable (or entry) merge: unproven.
  const BasicBlock *D = N->getIDom()->getBlock();
  // Every block on a path from `D` to an incoming block, `D` included. A block
  // reached backward without passing `D` is dominated by `D` (else a path from
  // the entry to the incoming block would avoid `D`).
  SmallVector<const BasicBlock *, 8> BW;
  SmallPtrSet<const BasicBlock *, 16> SeenB;
  for (const BasicBlock *IB : P->blocks())
    if (SeenB.insert(IB).second)
      BW.push_back(IB);
  while (!BW.empty()) {
    const BasicBlock *B = BW.pop_back_val();
    const Instruction *T = B->getTerminator();
    const Value *C = nullptr;
    if (const auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional())
        C = BI->getCondition();
    } else if (const auto *SI = dyn_cast<SwitchInst>(T)) {
      C = SI->getCondition();
    } else {
      return false;  // invoke / indirectbr / callbr deciding the merge: unproven.
    }
    if (C && Seen.insert(C).second)
      Work.push_back(C);
    if (B == D)
      continue;
    for (const BasicBlock *PB : predecessors(B))
      if (SeenB.insert(PB).second)
        BW.push_back(PB);
  }
  return true;
}

bool mayTaintAtRound2(const Value *V, const TaintSet &Taint,
                      const DominatorTree &DT) {
  SmallVector<const Value *, 8> Work{V};
  SmallPtrSet<const Value *, 16> Seen{V};
  while (!Work.empty()) {
    const Value *X = Work.pop_back_val();
    if (Taint.Tainted.count(const_cast<Value *>(X)))
      return true;  // quantum already (a deciding condition, typically).
    const auto *I = dyn_cast<Instruction>(X);
    if (!I)
      continue;  // a constant, global or argument: fixed for the whole run.
    if (const auto *CI = dyn_cast<CallInst>(I))
      if (is_contained(Taint.MeasureCalls, CI))
        continue;
    if (const auto *P = dyn_cast<PHINode>(I))
      if (!mergeDecidersInto(P, DT, Work, Seen))
        return true;
    for (const Value *Op : I->operands())  // φ incomings, `select` cond + arms
      if (Seen.insert(Op).second)
        Work.push_back(Op);
  }
  return false;
}

// The region's CFG shape, read off `BI` alone (pure CFG identity, no mutation):
// a ONE-ARMED diamond in either polarity (`Arm` a single-pred block of `Pred`
// whose single successor is the other successor, the merge; Rule 9: `clang -O1`
// takes `if (q != k)`'s arm on the FALSE edge, `Negated`), or — bd dm7f.3 — an
// IF/ELSE (`Arm` the TRUE successor, `ArmFalse` the FALSE one, both single-pred
// blocks of `Pred` whose single successor is one common merge). Shared by the
// classifier and the emitter's re-derivation so the two cannot drift.
struct StoreRegionShape {
  BasicBlock *Arm = nullptr, *ArmFalse = nullptr, *Merge = nullptr;
  bool Negated = false;
};

bool storeRegionShape(BranchInst *BI, StoreRegionShape &Out) {
  BasicBlock *Pred = BI->getParent();
  BasicBlock *S0 = BI->getSuccessor(0);  // cond == true
  BasicBlock *S1 = BI->getSuccessor(1);  // cond == false
  auto armOf = [&](BasicBlock *Cand, BasicBlock *M) {
    return Cand != M && Cand != Pred && Cand->getSinglePredecessor() == Pred &&
           Cand->getSingleSuccessor() == M;
  };
  if (armOf(S0, S1)) {
    Out = {S0, nullptr, S1, false};
    return true;
  }
  if (armOf(S1, S0)) {
    Out = {S1, nullptr, S0, true};
    return true;
  }
  BasicBlock *M = S0->getSingleSuccessor();
  if (S0 != S1 && M && M != Pred && armOf(S0, M) && armOf(S1, M)) {
    Out = {S0, S1, M, false};
    return true;
  }
  return false;
}

}  // namespace

GuardedStoreDisp classifyGuardedStoreArm(BranchInst *BI, TaintSet &Taint,
                                         ControlRegion &R) {
  // Caller guarantees: `BI` is a conditional branch on a tainted condition.
  BasicBlock *Pred = BI->getParent();
  DominatorTree DT(*Pred->getParent());
  LoopInfo LI(DT);

  // Is this a guarded-store region at all? The shape (one-armed or if/else),
  // every arm's content side-effect-only (at most one store, register-free
  // phase calls, nothing escaping), every store a guarded Shadow store
  // (`guardedShadowStoreShape`, the predicate the taint-escape carve deferred
  // on), and at least ONE store: an if/else of phase calls alone is
  // `classifyPhaseKickback`'s, which runs next.
  StoreRegionShape Sh;
  if (!storeRegionShape(BI, Sh))
    return GuardedStoreDisp::NotApplicable;
  ArmContent CT = armContent(Sh.Arm, Taint), CF;
  if (!CT.Ok)
    return GuardedStoreDisp::NotApplicable;
  if (Sh.ArmFalse) {
    CF = armContent(Sh.ArmFalse, Taint);
    if (!CF.Ok)
      return GuardedStoreDisp::NotApplicable;
  }
  if (!CT.Store && !CF.Store)
    return GuardedStoreDisp::NotApplicable;  // no store — not this step's shape.
  for (StoreInst *SI : {CT.Store, CF.Store})
    if (SI && !guardedShadowStoreShape(SI, Taint, DT, LI))
      return GuardedStoreDisp::NotApplicable;

  // From here this step OWNS the shape (a side-effect-only bounded-alloca store
  // arm): every unmet precondition is a LOUD decline, never NotApplicable.

  // g5gi — a SWAPPED (FALSE-successor) store arm is ACCEPTED: the store fires on
  // `¬cond`, minted directly as the inverse-predicate flag (a negated mint, NOT a
  // `cqrt_x` bracket — the spine reverses `icmp_ne_..._unc` identically to the
  // un-negated `_unc`; PRD-g5gi §1). `R.ArmNegated` carries the polarity to the
  // emitter, which passes `negate` to `lowerCompareToFlag`. An if/else's FALSE
  // arm takes the same negated mint (bd dm7f.3).

  // A merge φ means a value/phase arm rides beside the store (mixed) — off the
  // side-effect-only shape. (`armContent` already rejects an escaping value, so
  // this is belt-and-suspenders for a Pred-defined φ incoming.)
  if (isa<PHINode>(Sh.Merge->front())) {
    diagnoseUnderControl(BI, "guarded store with a merge value");
    return GuardedStoreDisp::Declined;
  }

  auto *Cond = dyn_cast<CmpInst>(BI->getCondition());
  if (!Cond || !comparePredLowerable(Cond)) {
    diagnoseUnderControl(BI, "control flow");
    return GuardedStoreDisp::Declined;
  }
  if (!Cond->hasOneUse()) {
    diagnoseUnderControl(Cond, "condition used outside the branch");
    return GuardedStoreDisp::Declined;
  }
  Value *Q = hlTaintedOperand(Cond, Taint);
  if (!Q) {  // Q+Q — no single HL flag mint.
    diagnoseUnderControl(Cond, "control flow");
    return GuardedStoreDisp::Declined;
  }
  if (!widthHasReversibleCopy(logicalOperandWidth(Q, Taint))) {  // bd r2j3.5
    diagnoseUnderControl(Cond, "control flow");
    return GuardedStoreDisp::Declined;
  }
  if (conditionReadsMemory(Cond, Taint)) {
    diagnoseUnderControl(Cond, "guarded store whose condition reads memory");
    return GuardedStoreDisp::Declined;
  }

  // bd dm7f.3 — THE COMPOSED REGION: an if/else, or an arm carrying a
  // register-free branch phase beside its store. Each clause below is asked only
  // of a composed region, so the shipped one-armed store-only population is
  // unchanged:
  //   * a phase ANGLE is classical (Rule 3; the refusal and the string
  //     `classifyPhaseKickback` gives a quantum-derived angle) and stays so
  //     after round 2 (`mayTaintAtRound2`, L1: this region is emitted at round
  //     1 and nothing re-asks its angle);
  //   * every UNTAINTED arm instruction is speculatable: the flatten runs it on
  //     EVERY branch (a classical computation cannot be conditioned on a quantum
  //     flag), so a trapping one (`sdiv` by a run-time zero) would fire where the
  //     source never ran it. The value arm's classical cone asks the same (fn1q
  //     K4). The one-armed store-only arm hoists the same way and is NOT asked
  //     here (pre-existing; reported with bd dm7f.3);
  //   * no stored VALUE is tainted, now or at round 2. The flatten hoists a
  //     tainted value chain into `Pred` unconditionally and nothing discharges it
  //     (bd r2j3.9, a latent silent miscompile masked today by the stale-record
  //     guard), so a composed region must not add customers to that path (L9).
  //     RETIREMENT TRIGGER: lift this clause in the change that closes r2j3.9.
  const bool Composed = Sh.ArmFalse || !CT.Phases.empty();
  for (const ArmContent *C : {&CT, &CF})
    for (CallInst *P : C->Phases)
      if (Taint.Tainted.count(P->getArgOperand(0)) ||
          mayTaintAtRound2(P->getArgOperand(0), Taint, DT)) {
        diagnoseUnderControl(P, "rotation angle");
        return GuardedStoreDisp::Declined;
      }
  if (Composed) {
    for (BasicBlock *BB : {Sh.Arm, Sh.ArmFalse}) {
      if (!BB)
        continue;
      for (Instruction &I : *BB) {
        if (I.isTerminator() || isa<StoreInst>(I) || isa<CallInst>(I))
          continue;  // the store and the phase calls (the only calls admitted).
        if (!Taint.Tainted.count(&I) && !isSafeToSpeculativelyExecute(&I)) {
          diagnoseUnderControl(&I, "control flow");
          return GuardedStoreDisp::Declined;
        }
      }
    }
    for (StoreInst *SI : {CT.Store, CF.Store})
      if (SI && (Taint.Tainted.count(SI->getValueOperand()) ||
                 mayTaintAtRound2(SI->getValueOperand(), Taint, DT))) {
        diagnoseUnderControl(SI, "guarded store of a quantum value in a "
                                 "composed region");
        return GuardedStoreDisp::Declined;
      }
  }

  // ACCEPT. Populate the by-identity plan (like a BranchRegion diamond).
  // `Shadow`/`ShadowFalse` are `Arm`'s/`ArmFalse`'s phase calls, the field
  // convention `PhaseKickback` uses.
  R.Kind = ControlRegion::GuardedStoreArm;
  R.Pred = Pred;
  R.Arm = Sh.Arm;
  R.ArmFalse = Sh.ArmFalse;  // bd dm7f.3: null for the one-armed diamond.
  R.MergeBB = Sh.Merge;
  R.Merge = nullptr;  // no merge φ (side-effect-only arm).
  R.Condition = Cond;
  R.ArmNegated = Sh.Negated;  // g5gi — a FALSE-successor arm mints the ¬cond flag.
  R.Shadow.assign(CT.Phases.begin(), CT.Phases.end());
  R.ShadowFalse.assign(CF.Phases.begin(), CF.Phases.end());
  return GuardedStoreDisp::Accept;
}

void emitGuardedStoreArmRegion(const ControlRegion &R, WidthDispatch &wd,
                               TaintSet &taint) {
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  if (!Cond || !R.Pred || !R.Arm || !R.MergeBB)
    return bailLoud(R);
  auto *BI = dyn_cast<BranchInst>(R.Pred->getTerminator());
  if (!BI || !BI->isConditional() || BI->getCondition() != Cond)
    return bailLoud(R);

  // 0. RE-DERIVE THE PLAN BY IDENTITY, BEFORE ANY MUTATION: the shape and each
  //    arm's content (its store, its phase calls) must be what the classifier
  //    recorded. Drift is a loud decline that lowers NOTHING.
  StoreRegionShape Sh;
  if (!storeRegionShape(BI, Sh) || Sh.Arm != R.Arm ||
      Sh.ArmFalse != R.ArmFalse || Sh.Merge != R.MergeBB ||
      Sh.Negated != R.ArmNegated)
    return bailLoud(R);
  ArmContent CT = armContent(Sh.Arm, taint), CF;
  if (Sh.ArmFalse)
    CF = armContent(Sh.ArmFalse, taint);
  auto samePhases = [](const ArmContent &C,
                       const SmallVectorImpl<Instruction *> &Plan) {
    if (C.Phases.size() != Plan.size())
      return false;
    for (size_t I = 0; I != Plan.size(); ++I)
      if (C.Phases[I] != Plan[I])
        return false;
    return true;
  };
  if (!CT.Ok || (Sh.ArmFalse && !CF.Ok) || (!CT.Store && !CF.Store) ||
      !samePhases(CT, R.Shadow) || !samePhases(CF, R.ShadowFalse))
    return bailLoud(R);
  const bool HasPhase = !CT.Phases.empty() || !CF.Phases.empty();
  FunctionCallee Rz = HasPhase ? wd.rzRtFn("i1") : FunctionCallee();
  if (HasPhase && !Rz)
    return bailLoud(R);  // resolved BEFORE any mutation: a decline, not a half-stream.

  // bd 7udx — FIRST, before ANY mutation, not merely before the block erase.
  // `hasAddressTaken()` is position-independent, so the check is free to sit here,
  // and it MUST: step 1 below hoists the whole arm body — INCLUDING THE STORE —
  // unconditionally into `Pred` and erases the conditional branch. A decline
  // after that point would leave a module that performs, on every path, a store
  // the source performed only under a tainted condition. That is a WRONG module,
  // not an unlowered one, and it is only masked by `opt`'s diagnostic handler
  // calling `exit(1)`. The arm blocks are the only blocks this function erases
  // (the merge survives), and the only blocks whose `BlockAddress` the erase
  // would RAUW to `inttoptr (i32 1 to ptr)`.
  SmallVector<BasicBlock *, 2> Doomed{Sh.Arm};
  if (Sh.ArmFalse)
    Doomed.push_back(Sh.ArmFalse);
  if (declineAddressTakenBlocks(Doomed, BI))
    return;

  // 1. PER STORE ARM: mint the path-predicate flag from the PRE-store condition
  //    handle (before BI), RECORD (store→flag), then FLATTEN that arm (splice its
  //    non-terminator body — the gep chain, the store, any pure ops, never its
  //    phase calls — into `Pred` before BI, AFTER its flag mint, so the flag
  //    dominates the store; `moveBefore` preserves identity, SI stays valid).
  //    A store does not change `q`'s value, so the flag stays recomputable — the
  //    whole-DAG LIFO strip (`icmp_..._unc`) is valid. The TRUE arm fires on
  //    `cond` (`negate` = the one-armed diamond's polarity, g5gi); an if/else's
  //    FALSE arm fires on `¬cond` and takes the NEGATED MINT (bd dm7f.3), never
  //    a `cqrt_x` bracket: the spine may reverse its store through
  //    `..._controlled_unc(flag, …)` and strips the flag with its own `_unc`, so
  //    the flag must DENOTE the arm's predicate for the store's whole lifetime.
  //    (Track A.1, F-A1R2-1) `Unruled`: `classifyGuardedStoreArm` is a pre-peel
  //    that pushes the region and returns before the generic `recoverRegion` /
  //    `classifyArms` path, and this file has no wire walk (MEASURED). That gap
  //    is a CONFIRMED silent miscompile on `main` — `gs1.c` minted
  //    `cqrt_qram_store_i32_controlled` from a register a sibling in-place Ry had
  //    relabelled — and it is closed by the unexempted re-ask this asks for.
  //
  //    Each flag is marked a tainted producer so the whole-DAG LIFO uncompute
  //    walks it: `DagTraversal` enqueues it as a borrowed operand of the guarded
  //    store (arg 0), and reverses the flag-mint compare via its `_unc` (the flag
  //    STRIP) AFTER the store's `_controlled_unc` (SSA dominance — the store's
  //    `_unc` reads the flag). The flag is NOT a data terminal (the store consumes
  //    it), so it is never selected as one; it reverses purely as a DAG ancestor.
  //    This is why the flag is left LIVE (not eagerly stripped) — WHEN THE SPINE
  //    REVERSES THE STORE, the strip rides the same LIFO as the store,
  //    guaranteeing store-reverse-then-strip ordering. When the store is NEVER
  //    reversed (main-resident, or its DAG bails) there is no store `_unc` and,
  //    before bd r2j3.1, no strip at all: the flag stood live as a copy of the
  //    condition across later gates on it. Since r2j3.1 the M-B interior
  //    partition takes it instead (`ChainWalk::isInteriorConsumer` (b″): a store
  //    reads its flag and preserves it) and strips it right after the store.
  //    LOAD-BEARING ORDERING (Rule-13 landmine): the flag mint MUST precede the
  //    store in program order (it does — the mint is emitted `before BI`, the
  //    store is spliced `before BI` AFTER it). The whole-DAG driver frees each
  //    rail after the adjoint of the earliest forward gate that TOUCHES it; the
  //    flag's earliest touch is its own icmp mint, so the free lands after the
  //    `icmp_..._unc` STRIP, not after the earlier `store_..._controlled_unc`. A
  //    refactor that let the store precede its mint, or dropped the icmp from the
  //    DAG, would free a still-dirty flag (a hidden measurement collapse, Rule 6).
  //
  //    THAT CONCLUSION IS UNCHANGED BY bd test_C_libtooling-uow0, but its MECHANISM
  //    is — the note is corrected rather than deleted because the old wording was
  //    a true statement about the old code and a false one about this code, which
  //    is exactly how a stale justification becomes a wrong de-facto ruling (Rule
  //    0). `railOf` USED to return arg 0 = the FLAG for the 4-arg guarded store,
  //    so the store counted as a WRITE of the flag and the ordering came out right
  //    by accident. It now returns arg 1 = the ARRAY (what the gate actually
  //    writes), and the ordering is instead supplied by the driver keying on READS
  //    as well as writes. Do not re-derive "the store's `railOf` is the flag".
  auto flattenArm = [&](BasicBlock *BB, const ArmContent &C, bool Negate) {
    if (C.Store) {
      Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                       /*inverse=*/false, /*before=*/BI,
                                       /*negate=*/Negate,
                                       /*railToStrip=*/nullptr,
                                       /*readKind=*/CondReadKind::Unruled);
      if (!Flag)
        return false;  // lowerCompareToFlag already diagnosed.
      taint.GuardedStores[C.Store] = Flag;
      if (auto *FlagI = dyn_cast<Instruction>(Flag)) {
        taint.Tainted.insert(FlagI);
        taint.BirthOrder[FlagI] = taint.NextBirth++;
      }
    }
    SmallVector<Instruction *, 8> Body;
    for (Instruction &I : *BB)
      if (!I.isTerminator() && !is_contained(C.Phases, &I))
        Body.push_back(&I);
    for (Instruction *I : Body)
      I->moveBefore(BI);
    return true;
  };
  if (!flattenArm(Sh.Arm, CT, /*Negate=*/R.ArmNegated))
    return;
  if (Sh.ArmFalse && !flattenArm(Sh.ArmFalse, CF, /*Negate=*/true))
    return;

  // 2. bd dm7f.3 — THE PHASE ARMS, BY KICKBACK ON THEIR OWN FLAG. A register-free
  //    `cq_phi(θ)` in an arm is a branch phase: `P(θ)` on exactly the branches
  //    where that arm runs. It is NEVER put on a store flag from step 1: a
  //    recorded branch-phase gate is an OPAQUE consumer to the whole-DAG spine
  //    (`ChainWalk.h`, `isBranchPhaseGate`), so a store flag carrying one would
  //    be left allocated and UNSTRIPPED — a live copy of the condition across
  //    any later gate on its register. Instead the kickback stream of
  //    `emitPhaseKickbackRegion`, verbatim: mint `f2` (un-negated), fire each
  //    arm's angles through `emitKickbackGroup` (the one spelling — `cqrt_x`-
  //    bracketed for a `¬cond` arm, i.e. the one-armed FALSE-successor arm or an
  //    if/else's `ArmFalse`; every gate recorded with `markBranchPhaseGate`),
  //    STRIP `f2` with the compare's `_unc` and FREE it. With `f2 = c(x)` in a
  //    |0> ancilla, `P(θ)` on it gives `Σ a_x e^{iθ c(x)} |x>|c(x)>`, and the
  //    strip returns it to |0> on every branch because nothing between the mint
  //    and the strip writes the condition's registers (the stores write the
  //    array only; `conditionReadsMemory` refused a condition that reads it).
  //    Emitted AFTER the splices so an angle computed inside an arm (a
  //    speculatable classical op, now in `Pred`) dominates its gate. The gates
  //    are diagonal on a qubit the guarded stores only read, so the position is
  //    unitary-neutral.
  if (HasPhase) {
    const DebugLoc DL = !CT.Phases.empty() ? CT.Phases.front()->getDebugLoc()
                                           : CF.Phases.front()->getDebugLoc();
    Value *F2 = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI,
                                   /*negate=*/false, /*railToStrip=*/nullptr,
                                   /*readKind=*/CondReadKind::Unruled);
    if (!F2)
      return;  // lowerCompareToFlag already diagnosed.
    IRBuilder<> B(BI);
    ControlledSymbols csyms(*BI->getModule(), wd);
    auto angles = [](const ArmContent &C) {
      SmallVector<Value *, 2> A;
      for (CallInst *P : C.Phases)
        A.push_back(P->getArgOperand(0));
      return A;
    };
    emitKickbackGroup(B, Rz, csyms.xFn(), F2, /*CtlIsRail=*/false, angles(CT),
                      /*Neg=*/R.ArmNegated, DL, taint);
    emitKickbackGroup(B, Rz, csyms.xFn(), F2, /*CtlIsRail=*/false, angles(CF),
                      /*Neg=*/true, DL, taint);
    auto *Strip = dyn_cast_or_null<CallInst>(
        lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                           /*before=*/BI, /*negate=*/false,
                           /*railToStrip=*/F2));
    if (Strip)
      taint.DischargedFlagGates.insert(Strip);
    CallInst *Free = B.CreateCall(wd.freeFn(), {F2});
    if (DL)
      Free->setDebugLoc(DL);
    // Each phase call's whole content is now a gate above: scrub it from
    // `PhaseCalls` (so `deleteGlobalPhases` cannot dereference it) and erase.
    for (const ArmContent *C : {&CT, &CF})
      for (CallInst *P : C->Phases) {
        taint.PhaseCalls.erase_value(P);
        P->eraseFromParent();
      }
  }

  // 3. Rewire `Pred` straight to the merge (unconditional), then erase the
  //    now-dead conditional branch, the emptied arm block(s), and the dead
  //    compare. The merge has NO φ (declined otherwise), so dropping the
  //    arm→merge edges needs no φ fixup.
  //    ⚠ `lowerControlRegions`' cross-region pre-flight lists only `Arm` as a
  //    guarded store's doomed block. `ArmFalse` is erased too, and no other
  //    region can name it: it has ONE predecessor (`Pred`, whose conditional
  //    branch is this region's) and ends in an UNCONDITIONAL `br`, so it is no
  //    region's `Pred`, no other region's arm (that region's `Pred` would be
  //    this one) and no region's merge (each recognizer's merge has two
  //    predecessors). Defence in depth would add it to that doomed set.
  IRBuilder<> B(BI);
  B.CreateBr(Sh.Merge);
  scrubTaint(BI, taint);
  BI->eraseFromParent();
  // The bd 7udx guard for these erases already ran at the TOP of the function —
  // deliberately, because by this line the arm bodies have been hoisted and the
  // branch erased, so a decline here would leave a wrong module rather than an
  // unlowered one. Do not move it back down to "just before the erase".
  for (BasicBlock *BB : Doomed)
    BB->eraseFromParent();  // unreachable (its sole predecessor Pred is rewired).
  if (Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }
}

}  // namespace cq
