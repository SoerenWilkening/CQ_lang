// LoopLowering.cpp — Phase 7.3 bounded-loop recognition + lowering (epic 799w).
// See LoopPlan.h for the contract and the ordering constraints.
//
// Increment 1 (799w.1) — Case A "in-place persistent accumulator". A
// classically-bounded loop whose every tainted value is a persistent rail
// threaded through a loop-carried header phi, mutated only by IN-PLACE gates
// (`cq_phi`=Rz / chained `cq_theta`=Ry on a tainted operand), lowers ROLLED IN
// PLACE: the loop CFG is preserved and the rail phi(s) — the loop-carried header
// phi AND the zero-trip/exit merge phi the `-O1` guard emits — collapse to the
// single persistent rail, so the body lowers to `cqrt_rz(%h, angle_i)` over a
// loop-invariant handle. The trace is byte-identical to the manually-unrolled
// form. No in-body free, no uncompute (the rail is measured/escaped after L).
//
// Also: the Q1 (quantum/measurement-bounded exit) and X1 (cross-iteration dirty
// rail) LOUD declines. Every other off-pattern loop is LEFT for its existing
// owner (`ControlDetect`/`RegionTreeDetect` for tainted control in the body,
// `kMsgQramLoop` for tainted-index memory, `declineClassicalMuxes`/`FreePoint`
// for an unrecognized live range) — `lowerLoops` claims a loop ONLY when it can
// PROVE the §2.2 sound-rolled invariant (Prime Directive: over-declining /
// not-claiming is safe).

#include "LoopPlan.h"

#include "TaintPropagation.h"
#include "ControlPlan.h"  // diagnoseUnderControl (Q1 reuses the control dialect)
#include "OpcodeSupport.h"  // abiWidthFromType (rail width for the capture allocs)
#include "WidthDispatch.h"

#include "llvm/IR/IRBuilder.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"

#include <optional>
#include <utility>

using namespace llvm;

namespace cq {

namespace {

// The exact diagnostic string the cross-iteration-dirty-rail decline owns
// (PRD-7.3 §2.7). The negative fixture mirrors it CHARACTER-FOR-CHARACTER
// (Rule 12): lowering_reject_loop_cross_iter.ll → kMsgCrossIter. The
// quantum-bounded-loop (Q1) decline reuses the control dialect via
// `diagnoseUnderControl(_, "loop")` → "cq controlled lowering: loop under
// quantum control" (lowering_reject_loop_quantum_bound.ll).
constexpr char kMsgCrossIter[] =
    "cq loop lowering: loop-carried tainted value crosses iterations";

// The fan-out / linear-lineage decline (Rule 8 no-cloning; the Rule-13 review
// 2026-06-26). A rail value read by >1 in-place consumer (value self-update OR
// rotation gate) cannot be lowered by in-place collapse — both mutations would
// serialize onto the one handle (a verify-clean wrong unitary). Mirrored
// CHARACTER-FOR-CHARACTER by lowering_reject_loop_rail_fanout{,_rot}.ll (Rule 12).
constexpr char kMsgRailFanout[] =
    "cq loop lowering: loop-carried rail has multiple in-place consumers";

// Phase 7.4 (epic y05j) — the `tryBreak` decline partition (PRD-7.4 §2.10). Each
// is source-located (`!dbg`) and mirrored CHARACTER-FOR-CHARACTER by a negative
// fixture (Rule 12). The genuinely-quantum-bounded loop is NOT one of these — it
// is left for `tryCaseA`'s existing L1 `diagnoseUnderControl(_, "loop")` (a fused
// exit with no classical bound is not a `break`, PRD-7.4 §2.5 B1 / Risk 4).
//
//  * (the recognized value-arm break is now EMITTED, Inc 2 — `emitBreakForward`
//    transforms it and records a `LoopBreakRegion`; the `kMsgBreakPending` interim
//    decline is retired. A recognized-but-non-canonical sub-shape declines via
//    `kMsgBreakUnemittable` below.)
//  * kMsgBreakPhase — a phase-class escaping answer (Rule 7: a CNOT copy-out
//    dephases; the data-comparison phase break is degenerate). PERMANENT (§2.6).
//  * kMsgBreakNonReconv — the break edge and the natural exit reach distinct
//    blocks / no single merge phi. DEFER (§2.7).
//  * kMsgBreakMultiSite — >1 tainted exiting block. INTERIM → accept in Inc 3
//    (§2.7; the index latch subsumes any cascade), not a deferral.
//  * kMsgBreakNested — `L` is an inner/outer of another tainted loop; the break
//    crosses loops. DEFER, blocked-on the nested-quantum-loop substrate (§2.7).
// Increment 2 (y05j.2) — the EMITTER sub-shape decline. A loop the recognizer
// accepted as a value-arm break but whose body is NOT the proven, emittable
// canonical rolled shape (single-block `header == latch`; ONE in-place value
// rail with a clean `cq_theta`-rooted self-cycle and linear in-place lineage;
// a UNIT-stride up-counting classical induction with the canonical
// `select(brk, true, bound)` fused `icmp eq i.next, n` exit). Non-canonical
// shapes (multi-block body, non-unit / down stride, phase/dirty rail, fan-out)
// are decline-safe near-term widenings — the index-gated capture + whole-loop
// reverse-play is proven only on the canonical shape in this increment (Prime
// Directive: over-declining is safe). Mirror-exact (Rule 12).
constexpr char kMsgBreakUnemittable[] =
    "cq loop lowering: early break body is not a provable rolled single-rail loop";
constexpr char kMsgBreakPhase[] =
    "cq loop lowering: early break preserves a phase answer";
constexpr char kMsgBreakNonReconv[] =
    "cq loop lowering: early break does not reconverge";
constexpr char kMsgBreakMultiSite[] =
    "cq loop lowering: multiple early-break sites";
constexpr char kMsgBreakNested[] =
    "cq loop lowering: early break across nested loops";

void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// Issue dtzb — is `BO` a recognized IN-PLACE value rail self-update? An `add` or
// `xor` (a reversible bijection of the rail GIVEN a classical immediate) with
// EXACTLY ONE tainted operand (the rail) and a CLASSICAL other operand (the
// immediate), of an integer width the in-place ABI serves (≤ 64 bits — there is
// no `cqrt_{addc,xorc}_i128`). Returns the tainted rail operand (the base the
// wire peels to), or null. This is the value analogue of an in-place rotation
// gate: `cqrt_{addc,xorc}_<W>` mutates the one rail handle in place, so its
// result belongs to that rail. The exclusions are the over-accept partition
// (Rule 12): `mul`/`and`/`or`/`shl`/`lshr` are information-LOSING (no in-place
// reversible form), and a TWO-quantum `acc + q` (both operands tainted) has no
// classical immediate — both return null and stay the X1 cross-iteration decline
// (the general two-quantum Cuccaro-adder case is a deferred follow-on). An `fadd`
// is opcode `FAdd`, not `Add`, so fp never reaches here.
Value *inPlaceValueRailOperand(BinaryOperator *BO, const TaintSet &taint) {
  Instruction::BinaryOps Op = BO->getOpcode();
  if (Op != Instruction::Add && Op != Instruction::Xor)
    return nullptr;  // owner scope (dtzb): the add/xor bijection family only.
  Type *Ty = BO->getType();
  if (!Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return nullptr;  // i128 has no in-place ABI (the copyFn > 64 fence twin).
  Value *L = BO->getOperand(0), *R = BO->getOperand(1);
  bool TL = taint.Tainted.count(L) != 0, TR = taint.Tainted.count(R) != 0;
  if (TL == TR)
    return nullptr;  // need EXACTLY one tainted (rail) + one classical (imm).
  return TL ? L : R;
}

// Peel in-place gates off the front of a value's wire, returning the underlying
// base. Two gate kinds peel (both are in-place mutations of the one rail handle,
// their result RAUWs to the operand at lowering): (1) rotation gates
// (`cq_theta`/`cq_phi` whose arg-0 handle is tainted — the 7.3 vocabulary), and
// (2, issue dtzb) value rail self-updates (`q = q OP c`, add/xor + classical
// immediate — `inPlaceValueRailOperand`). Parallels
// `TaintPropagation::resolveWireBase` but returns only the base. Stops at a
// classical-operand `cq_theta` (the rail MINT), at any non-gate value (a phi /
// template producer / argument), and at a two-quantum / non-bijection op (a dirty
// rail → X1).
Value *peelInPlaceBase(Value *V, const SmallPtrSetImpl<CallInst *> &GateCalls,
                       const TaintSet &taint) {
  for (;;) {
    if (auto *CI = dyn_cast<CallInst>(V)) {
      if (!GateCalls.count(CI))
        break;  // not a collected rotation call — V is the base.
      Value *Handle = CI->getArgOperand(0);
      if (!taint.Tainted.count(Handle))
        break;  // classical-operand theta: the mint point IS the base.
      V = Handle;
      continue;
    }
    if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      if (Value *Base = inPlaceValueRailOperand(BO, taint)) {
        V = Base;  // dtzb: peel the in-place value self-update to its rail.
        continue;
      }
    }
    break;
  }
  return V;
}

// Is `CI` an IN-PLACE rotation gate on its arg-0 handle `H` (a collected
// `cq_theta`/`cq_phi` whose arg-0 is `H` and tainted)? Such a gate mints no new
// rail; its result RAUWs to `H` at rotation lowering — so its result belongs to
// `H`'s persistent rail.
bool isInPlaceGateOnArg0(const CallInst *CI, const Value *H,
                         const SmallPtrSetImpl<CallInst *> &GateCalls,
                         const TaintSet &taint) {
  if (!GateCalls.count(const_cast<CallInst *>(CI)))
    return false;
  return CI->arg_size() >= 1 && CI->getArgOperand(0) == H &&
         taint.Tainted.count(const_cast<Value *>(H));
}

bool isMeasureCall(const Instruction *I) {
  const auto *CI = dyn_cast<CallInst>(I);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  // Pre-lowering the front-end form is `@cq_measure_<sfx>`; the `cqrt_measure_`
  // prefix is accepted defensively (mirrors `isMeasureSink`) though `lowerLoops`
  // always runs before measure lowering.
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N.starts_with("cq_measure_") || N.starts_with("cqrt_measure_");
}

// The loop's exiting condition is a live tainted value (`while(q<k)`,
// amplitude-/measurement-derived bound) ⇒ a runtime branch on a qubit — the
// genuinely quantum-controlled loop, a permanent decline (PRD §2.6, L1). Returns
// the offending terminator (for the diagnostic) or null.
Instruction *taintedExit(Loop *L, const TaintSet &taint) {
  SmallVector<BasicBlock *, 4> Exiting;
  L->getExitingBlocks(Exiting);
  for (BasicBlock *EB : Exiting) {
    Instruction *T = EB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return T;
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return T;
    }
  }
  return nullptr;
}

// ── Phase 7.4 (epic y05j) — single value-arm `break` recognition ────────────
//
// All analysis below is PURE SSA/CFG identity on the still-unmutated IR (Rule 9);
// `tryBreak` never mutates in Increment 1 (recognition + decline partition only).

// "Does this value's lineage carry a relative phase (an Rz / `cq_phi`)?" — the
// §2.6 phase fence over the escaping answer (B3). A per-TU mirror of
// `ControlDetect`'s `retLineageCarriesPhase` and the AbortPark/SelectClassify
// twins (the house style sanctions the trivial duplicate — keeping the loop
// partition self-contained, Rule 14). A `cq_theta` (Ry) basis superposition has
// no relative phase and STOPS the walk; a `cq_phi` (Rz) in the lineage is the
// phase carrier. Over-decline-safe (any phi flags it).
bool breakLineageCarriesPhase(Value *Op, const TaintSet &taint) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (auto *CI = dyn_cast<CallInst>(V)) {
      const Function *F = CI->getCalledFunction();
      if (F && F->getName().starts_with("cq_phi_"))
        return true;  // an Rz (cq_phi) — a relative-phase carrier.
    }
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;  // an argument / constant root — basis, not a phase.
    for (Value *In : I->operands())
      if (taint.Tainted.count(In) && Visited.insert(In).second)
        Work.push_back(In);
  }
  return false;
}

// Decompose the `-O1` FUSED loop-exit condition (PRD-7.4 §1.1) into its two
// candidate disjunct operands {break flag, classical bound}. `clang -O1` fuses
// the tainted break flag with the classical loop bound into ONE i1 value; this
// recovers the pair so the caller can taint-partition it (B1). Recognized forms
// (and their successor-swapped continue-polarity twins, Rule 9 — verified in the
// IR spike, /tmp/spike):
//   * `select(%a, i1 true,  %b)`   = %a ∨ %b   (exit-polarity, v1_value)
//   * `select(%a, %b, i1 false)`   = %a ∧ %b   (continue-polarity, v6 inner)
//   * `or  i1 %a, %b`              = %a ∨ %b
//   * `and i1 %a, %b`              = %a ∧ %b   (continue-polarity)
// Taint is predicate/polarity-independent (`taint(icmp) == taint(operands)`), so
// the same {tainted=brk, classical=bound} partition holds for both polarities.
// A 3-non-constant `select` (a genuine i1 data-mux) or any other shape returns
// nullopt ⇒ NOT a recognized fused break (the caller rides L1 / declines —
// over-declining is safe, Prime Directive). `IsOr` records the fusion logic
// (OR = `a ∨ b`, AND = `a ∧ b`) — needed to derive which bound value forces a
// standalone loop exit (the §B5 increment-widening termination proof).
struct FusedExit {
  Value *A;
  Value *B;
  bool IsOr;
};
std::optional<FusedExit> decomposeFusedExit(Value *C) {
  if (auto *SI = dyn_cast<SelectInst>(C)) {
    Value *Cnd = SI->getCondition();
    Value *TV = SI->getTrueValue();
    Value *FV = SI->getFalseValue();
    auto *TC = dyn_cast<ConstantInt>(TV);
    auto *FC = dyn_cast<ConstantInt>(FV);
    if (TC && TC->isOne() && !isa<Constant>(FV))
      return FusedExit{Cnd, FV, /*IsOr=*/true};   // select(a, true, b) = a ∨ b
    if (FC && FC->isZero() && !isa<Constant>(TV))
      return FusedExit{Cnd, TV, /*IsOr=*/false};  // select(a, b, false) = a ∧ b
    return std::nullopt;               // 3-operand mux / both-const — not fused.
  }
  if (auto *BO = dyn_cast<BinaryOperator>(C)) {
    bool IsOr = BO->getOpcode() == Instruction::Or;
    if ((IsOr || BO->getOpcode() == Instruction::And) &&
        BO->getType()->isIntegerTy(1)) {
      Value *A = BO->getOperand(0), *B = BO->getOperand(1);
      if (!isa<Constant>(A) && !isa<Constant>(B))
        return FusedExit{A, B, IsOr};
    }
  }
  return std::nullopt;
}

// The exiting block's terminator condition is tainted (a `br`/`switch` on a
// q-derived value). The unit of the multi-site count (B1) and of `taintedExit`.
bool isTaintedExitingTerminator(const Instruction *T, const TaintSet &taint) {
  if (const auto *BI = dyn_cast<BranchInst>(T))
    return BI->isConditional() && taint.Tainted.count(BI->getCondition());
  if (const auto *SI = dyn_cast<SwitchInst>(T))
    return taint.Tainted.count(SI->getCondition());
  return false;
}

// Does any strictly-deeper subloop of `L` contain a tainted value? Such a loop
// is a NESTED quantum loop; a break alongside it crosses loops (B4 — nested-loop
// break is deferred, blocked-on the nested-quantum-loop substrate, §2.7).
bool subloopHasTaintedValue(Loop *L, const TaintSet &taint, LoopInfo &LI) {
  for (BasicBlock *BB : L->blocks()) {
    if (LI.getLoopFor(BB) == L)
      continue;  // a block of L itself — not a subloop block.
    for (Instruction &I : *BB)
      if (taint.Tainted.count(&I))
        return true;
  }
  return false;
}

// (B5, Risk 4) Does `L` have a real, FINITE CLASSICAL TRIP-COUNT bound — i.e. a
// bound that PROVABLY TERMINATES the loop independent of the quantum break?
// ScalarEvolution answers it: `getSymbolicMaxBackedgeTakenCount` is a computable
// SCEV iff SOME exit gives a finite trip count. The quantum break is an opaque
// `SCEVUnknown` (derived from the `cq_*` call results), so SCEV NEVER manufactures
// a finite bound from it — a computable symbolic max therefore means the loop is
// bounded by its CLASSICAL exit (the induction-driven trip count). It correctly
// handles the `-O1` fused `select(brk, true, bound)` / `and`/`or` exit (verified:
// v1_value's select-fused `i != n` bound yields `(-1 + n)`).
//
// This SUBSUMES the earlier UNSOUND structural "the bound *references* the
// induction counter" check (which proved reference, not termination, and so
// mis-recognized a loop-invariant guard `while((q&1)&&(m!=0))` with a dead
// counter, and the clang-realistic wrong-direction `for(i=0;(q&1)&&(i>=start);i++)`
// — the adversarial-review R4 false-accept family 2026-06-25, the seed of an Inc-2
// silent miscompile). SCEV gives those an Unpredictable max ⇒ they ride L1.
//
// HAZARD (the adversarial-review P3 finding 2026-06-26): when the classical bound
// is VACUOUS (always-true), `getSymbolicMaxBackedgeTakenCount` still returns a
// finite max by bounding the loop via the COUNTER'S OWN nsw/nuw OVERFLOW (under
// `llvm.loop.mustprogress`), NOT via any real classical bound — so a genuinely
// quantum-bounded loop is mis-accepted. The single-counter form (`i>=0`) `clang
// -O1` folds away, but a TWO-COUNTER DIVERGING bound (`while((q&1)&&(i<m))` with
// `m` outrunning `i`, so `i<m` is always true) is NOT folded and reaches the pass
// (SCEV max = INT_MAX). This is therefore guarded at the CALL SITE by
// `boundComparesInductionToInvariant` (the bound must compare the counter against a
// loop-INVARIANT limit — a vacuous two-counter / loop-invariant "bound" has none),
// which is the necessary precondition that makes this query sound. Over-declining
// is safe (Prime Directive): if SCEV cannot prove a finite bound, decline.
bool hasFiniteClassicalTripBound(Loop *L, ScalarEvolution &SE) {
  const SCEV *Max = SE.getSymbolicMaxBackedgeTakenCount(L);
  return Max && !isa<SCEVCouldNotCompute>(Max);
}

// (B5, Risk 4) Is the classical bound a REAL counter-vs-fixed-limit comparison —
// exactly ONE operand loop-invariant? This is the necessary precondition that
// closes the `hasFiniteClassicalTripBound` overflow hazard above AND backstops
// `boundProvablyTerminates`. A genuine trip bound compares the induction against a
// loop-INVARIANT limit (`i < n`). A VACUOUS bound that SCEV bounds only by counter
// overflow has either NO loop-invariant operand (a two-counter diverging `i < m`,
// the P3 false-accept) or TWO (a loop-invariant guard `m != 0`, the dead-counter
// family) — both rejected here. Two-counter CONVERGING bounds (rare, e.g.
// `i < j` with `i++`/`j--`) are conservatively declined too (safe — over-declining
// is always safe; distinguishing converging from diverging needs the same
// unreliable two-counter SCEV reasoning the hazard stems from).
bool boundComparesInductionToInvariant(Value *Bound, Loop *L,
                                       ScalarEvolution &SE) {
  auto *Cmp = dyn_cast<ICmpInst>(Bound);
  if (!Cmp)
    return false;
  bool Inv0 = SE.isLoopInvariant(SE.getSCEV(Cmp->getOperand(0)), L);
  bool Inv1 = SE.isLoopInvariant(SE.getSCEV(Cmp->getOperand(1)), L);
  return Inv0 != Inv1;  // exactly one loop-invariant operand (the fixed limit).
}

// (B5 widening — general CLASSICAL increment) A structural termination proof for
// the value-arm break loops `hasFiniteClassicalTripBound` cannot bound. SCEV's
// `getSymbolicMaxBackedgeTakenCount` is INCOMPLETE on the `-O1` `slt`-with-non-unit
// stride fused exit (e.g. `for(i<n;i+=2)` — verified Unpredictable even standalone,
// no quantum break), so a perfectly classically-bounded non-unit-stride break loop
// over-declines. This proves termination directly for a CLASSICAL CONSTANT step
// (the owner's "purely classical increments" scope, 2026-06-26): the bound
// compares a no-wrap induction AddRec (constant non-zero step) against a
// loop-invariant value, and SCEV's own monotonicity oracle (which requires the
// matching no-wrap flag, so a wrapping counter is rejected) proves the bound moves
// the counter toward the loop-exit value.
//
// SOUNDNESS (the Risk-4 boundary — never accept a genuinely quantum-bounded loop):
//   1. The bound must be a STANDALONE terminator — it forces the loop to exit
//      INDEPENDENT of the quantum break. For the `-O1` OR-fused exit (exit-on-true)
//      a true bound forces exit; for the AND-fused continue (exit-on-false) a false
//      bound forces exit (the §1.1 polarity pairing). Any other pairing means the
//      exit depends on the break ⇒ genuinely quantum-bounded ⇒ reject. This makes
//      `BoundExitValue` (the bound value that forces exit) well-defined.
//   2. The bound must monotonically REACH that exit value: `getMonotonicPredicateType`
//      Increasing ⇒ reaches true, Decreasing ⇒ reaches false; terminates iff the
//      reached value IS the exit value (so an always-true `i>=0` exit-on-false, or a
//      wrong-direction compare, is rejected).
// Used only as an OR-fallback to `hasFiniteClassicalTripBound`, so it can only WIDEN
// acceptance — and both disjuncts are independently sound (each proves a finite
// classical trip bound), so the union never accepts a quantum-bounded loop.
bool boundProvablyTerminates(Value *Bound, bool IsOr, bool ExitTakenOnTrue,
                             Loop *L, ScalarEvolution &SE,
                             const TaintSet &taint) {
  auto *Cmp = dyn_cast<ICmpInst>(Bound);
  if (!Cmp)
    return false;
  // The bound value that STANDALONE forces a loop exit (§soundness 1).
  bool BoundExitValue;
  if (IsOr && ExitTakenOnTrue)
    BoundExitValue = true;
  else if (!IsOr && !ExitTakenOnTrue)
    BoundExitValue = false;
  else
    return false;  // exit depends on the break ⇒ not a standalone classical bound.
  // The induction AddRec (constant non-zero step) vs a loop-invariant limit;
  // normalize so the AddRec is the predicate LHS (as getMonotonicPredicateType wants).
  const SCEV *S0 = SE.getSCEV(Cmp->getOperand(0));
  const SCEV *S1 = SE.getSCEV(Cmp->getOperand(1));
  ICmpInst::Predicate Pred = Cmp->getPredicate();
  const auto *AR = dyn_cast<SCEVAddRecExpr>(S0);
  if (AR && AR->getLoop() == L && SE.isLoopInvariant(S1, L)) {
    // AR is already the LHS.
  } else if ((AR = dyn_cast<SCEVAddRecExpr>(S1)) && AR->getLoop() == L &&
             SE.isLoopInvariant(S0, L)) {
    Pred = ICmpInst::getSwappedPredicate(Pred);
  } else {
    return false;  // not a counter-vs-loop-invariant comparison.
  }
  const SCEV *StepS = AR->getStepRecurrence(SE);
  const auto *Step = dyn_cast<SCEVConstant>(StepS);
  if (!Step || Step->getAPInt().isZero())
    return false;  // non-constant or zero (stuck) step — not a classical counter.
  // SCEV strips no-wrap flags from a SHIFTED induction operand (e.g. `i+2` =
  // {2,+,2}<nuw> loses <nsw>), which defeats the signed-predicate monotonicity
  // check; the canonical header induction phi retains both flags. Recover it (the
  // untainted header phi whose AddRec has the SAME step — monotonic direction is
  // step-determined, so any same-step recurrence gives the same answer), falling
  // back to `AR` itself.
  const SCEVAddRecExpr *MonoAR = AR;
  for (PHINode &P : L->getHeader()->phis()) {
    if (taint.Tainted.count(&P))
      continue;
    if (const auto *PAR = dyn_cast<SCEVAddRecExpr>(SE.getSCEV(&P)))
      if (PAR->getLoop() == L && PAR->getStepRecurrence(SE) == StepS) {
        MonoAR = PAR;
        break;
      }
  }
  // SCEV's monotonicity oracle (internally gated on the matching no-wrap flag).
  auto Mono = SE.getMonotonicPredicateType(MonoAR, Pred);
  if (!Mono)
    return false;
  // Increasing ⇒ bound reaches true; Decreasing ⇒ reaches false. Terminates iff
  // the reached value is the exit value (§soundness 2).
  return *Mono == ScalarEvolution::MonotonicallyIncreasing ? BoundExitValue
                                                           : !BoundExitValue;
}

// ── Increment 2 (y05j.2) — the FORWARD TRANSFORM (pre-lowering) ─────────────
//
// A recognized value-arm break loop, EMITTABLE iff it is the proven canonical
// rolled shape, is rewired here (PRE-lowering — it needs pre-RAUW SSA identity
// and must run before `detectControlRegions`/`declineClassicalMuxes`): the rail
// phi collapses to its in-place handle (dtzb), the loop terminator is stripped to
// the CLASSICAL bound (so the rolled loop runs its FULL trip count — never branch
// the CFG on the quantum `%brk`, PRD §2.9), `R`/`idx`/`out` are minted, and the
// exit merge phi is RAUW'd to `out`. The capture + whole-loop reverse-play is
// EMITTED LATER (post-lowering, `lowerBreakReversePlay`) on the lowered body; this
// records the `LoopBreakRegion` it consumes. Returns true iff the transform ran;
// on a non-canonical sub-shape emits `kMsgBreakUnemittable` and returns false
// (the caller still claims the loop — over-declining is safe, Prime Directive).
bool emitBreakForward(LoopBreakRegion &Rgn, TaintSet &taint, WidthDispatch &wd,
                      const SmallPtrSetImpl<CallInst *> &GateCalls,
                      DominatorTree &DT, bool IsOr) {
  BasicBlock *Header = Rgn.Header;
  BasicBlock *Latch = Rgn.Latch;
  auto *BreakI = cast<Instruction>(Rgn.BreakFlag);  // source-locator anchor.
  auto bail = [&]() {
    diagnose(BreakI, kMsgBreakUnemittable);
    return false;
  };

  // (E1) The proven canonical rolled body is a SINGLE block (the `-O1` rotated
  // loop with `header == latch`). A multi-block body is a near-term widening.
  if (Header != Latch)
    return bail();
  // (E2) The canonical fused exit polarity (`select(brk, true, bound)`, exit on
  // true). The continue-polarity / AND-fused twins are recognizer-accepted but
  // not in this increment's proven emission set.
  if (!IsOr || !Rgn.ExitTakenOnTrue)
    return bail();

  // ── Locate the rail header phi (tainted) + the classical counter phi ──────
  // The canonical body carries EXACTLY one tainted (rail) and one untainted
  // (counter) header phi. Anything else is off-shape.
  PHINode *RailPhi = nullptr, *CounterPhi = nullptr;
  for (PHINode &P : Header->phis()) {
    if (taint.Tainted.count(&P)) {
      if (RailPhi)
        return bail();
      RailPhi = &P;
    } else {
      if (CounterPhi)
        return bail();
      CounterPhi = &P;
    }
  }
  if (!RailPhi || !CounterPhi)
    return bail();

  // ── (E3) The counter is a UNIT up-stride induction: latch-incoming = add(i,1)
  Value *CntLat = CounterPhi->getIncomingValueForBlock(Latch);
  auto *CntAdd = dyn_cast_or_null<BinaryOperator>(CntLat);
  if (!CntAdd || CntAdd->getOpcode() != Instruction::Add)
    return bail();
  Value *StepV = CntAdd->getOperand(0) == CounterPhi   ? CntAdd->getOperand(1)
                 : CntAdd->getOperand(1) == CounterPhi ? CntAdd->getOperand(0)
                                                       : nullptr;
  auto *StepCI = dyn_cast_or_null<ConstantInt>(StepV);
  if (!StepCI || !StepCI->isOne())
    return bail();
  Value *INext = CntAdd;  // `i.next` — the bound compares against this.

  // ── (E4) BoundFlag is the canonical `icmp eq i.next, n` (n loop-invariant) ──
  auto *BoundCmp = dyn_cast<ICmpInst>(Rgn.BoundFlag);
  if (!BoundCmp || BoundCmp->getPredicate() != ICmpInst::ICMP_EQ)
    return bail();
  Value *BoundLimit = BoundCmp->getOperand(0) == INext   ? BoundCmp->getOperand(1)
                      : BoundCmp->getOperand(1) == INext ? BoundCmp->getOperand(0)
                                                         : nullptr;
  if (!BoundLimit)
    return bail();
  // The limit `n` must be loop-invariant (not defined in the single body block).
  if (auto *BLI = dyn_cast<Instruction>(BoundLimit))
    if (BLI->getParent() == Header)
      return bail();

  // ── (E5) The rail is a clean in-place VALUE self-cycle rooted at a mint ────
  if (RailPhi->getNumIncomingValues() != 2)
    return bail();
  Value *RailLat = RailPhi->getIncomingValueForBlock(Latch);
  Value *RailPre = nullptr;
  BasicBlock *PreB = nullptr;
  for (unsigned i = 0; i < 2; ++i)
    if (RailPhi->getIncomingBlock(i) != Latch) {
      RailPre = RailPhi->getIncomingValue(i);
      PreB = RailPhi->getIncomingBlock(i);
    }
  if (!RailPre || !PreB)
    return bail();
  if (peelInPlaceBase(RailLat, GateCalls, taint) != RailPhi)
    return bail();  // latch incoming is not a clean self-cycle (X1 dirty rail).
  Value *Root = peelInPlaceBase(RailPre, GateCalls, taint);
  auto *Mint = dyn_cast<CallInst>(Root);
  if (!Mint || !GateCalls.count(Mint) ||
      taint.Tainted.count(Mint->getArgOperand(0)))
    return bail();  // preheader incoming is not a clean classical-operand mint.
  if (!DT.dominates(Mint, Header))
    return bail();

  // ── (E14) NO pre-loop in-place rail mutation: the rail value ENTERING the loop
  // (`RailPre`, the rail phi's PreB-incoming) must BE the bare mint (`Root`). The dtzb
  // collapse RAUWs the rail phi to `Root = peelInPlaceBase(RailPre)`, which peels
  // THROUGH any pre-loop in-place value/rotation mutation (`q = q ^ 7;` or a pre-loop
  // `cq_phi` between the `cq_theta` mint and the loop), and only the IN-LOOP `RailOps`
  // are marked `InPlaceRailOps`. So a pre-loop mutation orphans to a DEAD out-of-place
  // template handle and is NEVER applied to the in-place rail handle — the post-lowering
  // capture (BreakReversePlay.cpp) then copies a rail handle MISSING that mutation into
  // `out` (a VERIFY-CLEAN WRONG UNITARY, off by the pre-loop mutation; on BOTH edges).
  // E13 does NOT catch it (the escape phi legitimately carries `RailPre`, so escape ==
  // rail by VALUE; the divergence is `Root` ≠ `RailPre` at the HANDLE level). Found by
  // the y05j.2 Rule-13 sign-off 2026-06-28. `Root == RailPre` ⟺ `RailPre` is itself the
  // mint (no peel happened). Decline otherwise (Prime Directive — over-declining is
  // safe; applying the pre-loop mutation in-place to the rail handle is a near-term
  // widening, not this increment's proven shape — the canonical `q = cq_theta(); for(…)`
  // has `RailPre == Root == the mint` and still lowers, lowering_loop_break_*).
  if (Root != RailPre)
    return bail();

  // ── (E13) The escaping/measured answer MUST be the loop RAIL ITSELF on BOTH exit
  // edges — `RailLat` (the rail's post-all-mutations value) on the loop-exit/latch edge
  // AND `RailPre` (the rail's pre-loop value) on the zero-trip bypass edge. The
  // post-lowering capture (BreakReversePlay.cpp captureRailToR + emitExitConsolidation)
  // unconditionally copies the in-place RAIL handle into `R` and then into `out` (the
  // RAUW'd escape phi) — for BOTH the broke branches (capture) and the never-broke /
  // zero-trip branches (the `idx==0` consolidation). Nothing upstream ties the escape
  // phi to the rail: E8 PERMITS `RailLat` to have a non-mutation consumer, and E9/E11
  // ADMIT a break-cond-DERIVED value (`t = f(rail)`, e.g. `t = q*7` — `mul` is
  // information-losing so it is NOT a rail op) as a legitimate body value the escape phi
  // may carry; and the phi's zero-trip incoming is entirely unconstrained. If the
  // program measures/returns a derived `t ≠ RailLat` on the loop edge, or a value
  // `≠ RailPre` on the zero-trip edge (`int ans = 999; for(…){…; ans = q; …} measure(ans)`
  // — n==0 returns 999 but the consolidation yields the rail's initial value), `out` is
  // filled with the RAIL instead of the asked-for answer — a VERIFY-CLEAN WRONG UNITARY
  // (the escape≠rail silent miscompile; BOTH edges idiomatic-C-reachable; found by the
  // y05j.2 Rule-13 re-review 2026-06-27, MISSED originally because every fixture/e2e
  // measures `q` itself so escape == rail held by luck on both edges, never by check).
  // Require the escape phi to be exactly two incomings — `RailLat` from `Latch` and
  // `RailPre` from `PreB`; decline otherwise (Prime Directive — over-declining is safe;
  // capturing a derived answer rather than the rail is a near-term widening, not this
  // increment's proven shape). The canonical `return measure(q)` carries `RailLat`/
  // `RailPre` themselves and still lowers (lowering_loop_break_*).
  {
    int LatchIdx = Rgn.EscapePhi->getBasicBlockIndex(Latch);
    int PreBIdx = Rgn.EscapePhi->getBasicBlockIndex(PreB);
    if (Rgn.EscapePhi->getNumIncomingValues() != 2 || LatchIdx < 0 || PreBIdx < 0 ||
        Rgn.EscapePhi->getIncomingValue(LatchIdx) != RailLat ||
        Rgn.EscapePhi->getIncomingValue(PreBIdx) != RailPre)
      return bail();
  }

  // ── (E15) The rail MINT (`Root`, == `RailPre` after E14) must be read ONLY by the
  // rail phi and the escape phi. After the dtzb collapse RAUWs `RailPhi` → `Root` and
  // lowers the in-loop mutations as in-place gates on `Root`'s handle, `Root` IS the
  // LIVE in-place rail handle at every program point — no longer the frozen initial
  // value. So a break-cond that reads the mint (`int q0 = q; … if (q == q0) break;`)
  // lowers to `icmp_eq(h, h)` (rail vs ITSELF, unconditionally true) — a VERIFY-CLEAN
  // WRONG UNITARY decoupling the break decision from the user predicate (found by the
  // y05j.2 Rule-13 sign-off round 3, 2026-06-28). E8 forbids reading `RailPhi` /
  // intermediate `RailOps` and E9 forbids an UNTAINTED header operand, but the mint is
  // TAINTED and preheader-defined, so both skip it. The ONLY legitimate readers of the
  // mint are `RailPhi` (loop-entry incoming) and `Rgn.EscapePhi` (zero-trip incoming —
  // n==0, the rail is unmutated so reading the mint is correct). Any other user (the
  // break-cond, a separate measure of the snapshot) reads the LIVE rail where it means
  // the frozen mint ⇒ decline (Prime Directive — a frozen-mint snapshot needs a
  // separately allocated copy, a near-term widening, not this increment's proven shape).
  for (User *U : Root->users())
    if (U != RailPhi && U != Rgn.EscapePhi)
      return bail();

  // ── (E6) `PreB` (the rail phi's external/entry predecessor — where R/idx/out are
  // minted) MUST dominate the exit merge. R/idx/out are read in the loop AND in the
  // exit merge (the consolidation/copy-out/reverse-play), so their defs must
  // dominate those uses. This holds for the canonical zero-trip guard block (which
  // dominates the bypassing exit edge) but FAILS for a clang-materialized DEDICATED
  // preheader that the zero-trip guard edge bypasses — minting there yields an
  // ill-dominated module (`opt -verify` aborts on valid C; the Rule-13 review
  // 2026-06-26). Decline (Prime Directive — over-declining is safe).
  if (!DT.dominates(PreB, Rgn.ExitMerge))
    return bail();

  // ── (E12) Capture the forward loop's zero-trip ENTRY guard (PreB's conditional
  // branch into the Header) so the reverse-play companion loop can REUSE it. A
  // re-invented signed `sgt(n, 0)` backward guard would be WRONG for an
  // unsigned-bounded loop (`for (unsigned i=0; i<n; i++)`, whose `-O1` entry guard
  // is `icmp eq n, 0` → enter iff `n != 0`): for `n ≥ 2^31` the forward enters +
  // captures while the signed `sgt(n,0)` skips the whole reverse-play → R/idx freed
  // DIRTY (a Rule-6 hidden measurement; the CRITICAL Rule-13 FINAL finding
  // 2026-06-26). Reusing the forward guard makes the backward loop enter iff the
  // forward did, for ANY signedness. Require PreB to end in a conditional branch
  // with the Header as one successor (the canonical guard shape); decline otherwise.
  auto *GuardBr = dyn_cast<BranchInst>(PreB->getTerminator());
  if (!GuardBr || !GuardBr->isConditional())
    return bail();
  bool LoopOnTrue = GuardBr->getSuccessor(0) == Header;
  if (!LoopOnTrue && GuardBr->getSuccessor(1) != Header)
    return bail();  // PreB does not branch directly to the loop header.
  Rgn.GuardCond = GuardBr->getCondition();
  Rgn.GuardLoopOnTrue = LoopOnTrue;

  // ── (E7) The classical counter must START at the constant 0. The reverse-play
  // companion loop replays the body `BoundLimit` (= `n`) times — which equals the
  // forward trip count ONLY when the rolled loop (now bounded by `icmp eq i.next,
  // n`) runs exactly `n` iterations, i.e. the counter starts at 0. A NON-ZERO start
  // (`for (i = 2; i < n; i++)`) makes the forward run `n - start` iterations while
  // the backward runs `n` — an OVER-REPLAY that leaves `fire`/the rail DIRTY at the
  // `cqrt_free` (a hidden measurement, Rule 6 — the CRITICAL Rule-13 finding
  // 2026-06-26). Tie the two trip counts by requiring start == 0; decline otherwise.
  Value *CntStart = CounterPhi->getIncomingValueForBlock(PreB);
  auto *CntStartC = dyn_cast_or_null<ConstantInt>(CntStart);
  if (!CntStartC || !CntStartC->isZero())
    return bail();

  // Collect the rail self-update VALUE ops (the latch→phi chain). Each must be an
  // in-place value bijection (`inPlaceValueRailOperand`); a rotation gate here is
  // a PHASE rail (B3 should have declined — belt-and-suspenders).
  //
  // (E10) Each rail op's CLASSICAL immediate (the non-rail operand) must be
  // loop-INVARIANT (dominate the exit merge — hence the downstream reverse-play
  // block). `dtzb` (commit 32f63df) accepts ANY untainted immediate — incl. a
  // LOOP-VARIANT one (`q ^= i`, or `q = (i&1) ? q^5 : q^3`). The whole-loop
  // reverse-play re-emits the rail-mut adjoint (`cqrt_{xorc,addc}` /
  // `emitInverseCall`) in the post-loop companion block, reusing the FORWARD
  // immediate — a loop-body value there is undefined (a dominance violation /
  // broken module; the Rule-13 review 2026-06-26). A `ConstantInt` / function-arg
  // immediate is not a body Instruction ⇒ passes; a counter-derived immediate
  // declines (Prime Directive — over-declining is safe).
  SmallVector<BinaryOperator *, 4> RailOps;
  for (Value *V = RailLat; V != RailPhi;) {
    auto *BO = dyn_cast<BinaryOperator>(V);
    if (!BO)
      return bail();
    Value *Base = inPlaceValueRailOperand(BO, taint);
    if (!Base)
      return bail();
    Value *Imm = BO->getOperand(0) == Base ? BO->getOperand(1) : BO->getOperand(0);
    if (auto *ImmI = dyn_cast<Instruction>(Imm))
      if (!DT.dominates(ImmI, Rgn.ExitMerge))
        return bail();  // loop-variant immediate — undefined in the reverse-play.
    RailOps.push_back(BO);
    V = Base;
  }
  // Fan-out / linear-lineage (Rule 8): every rail value has AT MOST ONE in-place
  // consumer (else the collapse serializes two mutators onto the one handle — the
  // verify-clean miscompile `loop-rail-inplace-fanout-miscompile`).
  SmallPtrSet<Value *, 8> RailVals;
  RailVals.insert(Root);
  RailVals.insert(RailPhi);
  for (BinaryOperator *BO : RailOps)
    RailVals.insert(BO);
  for (Value *V : RailVals) {
    unsigned InPlace = 0;
    for (User *U : V->users())
      if (auto *BO = dyn_cast<BinaryOperator>(U))
        if (inPlaceValueRailOperand(BO, taint) == V)
          ++InPlace;
    if (InPlace > 1)
      return bail();
  }

  // ── (E8) The break-cond must read the POST-mutation rail value — NOT the rail
  // HEADER PHI (the pre-mutation value). `clang -O1` strength-reduces a relational
  // ADD-rail break (`q = q + c; if (q > K) break;`) into `icmp sgt(headerphi, K-c)`
  // — the break-cond consumes the PRE-increment rail phi directly, while the answer
  // (escape phi) carries the POST value. The dtzb collapse RAUWs the header phi onto
  // the ONE in-place handle, and the `cqrt_addc` mutation runs BEFORE the break-cond
  // template in program order, so the break-cond would read the POST value — firing
  // one iteration early (a verify-clean WRONG UNITARY, off by the stride; the
  // CRITICAL Rule-13 finding 2026-06-26). The pre/post distinction is unrecoverable
  // after the collapse. GUARD: every NON-FINAL rail value — the header phi AND every
  // intermediate mutation result (all but `RailLat = RailOps.front()`, the
  // post-ALL-mutations latch value) — must be consumed ONLY by the in-place
  // mutation chain (`RailOps`). A non-mutation consumer reads the rail at a
  // PRE-FINAL program point; after the collapse RAUWs every rail value onto the ONE
  // handle and the mutations run in order, that consumer reads the FINAL value —
  // covering BOTH the add-relational strength-reduction (break-cond reads the
  // pre-increment header phi) AND a multi-op-chain intermediate read (break-cond
  // reads `q1` of `q1 = q^9; q2 = q1+3`; the Rule-13 RE-review 2026-06-26). ONLY
  // `RailLat` — the value the escape phi carries — may be read by the break-cond.
  // The canonical single-op xor passes (RailPhi's only user is the one mutation).
  SmallPtrSet<const Value *, 4> RailOpSet(RailOps.begin(), RailOps.end());
  auto consumedOnlyByMutations = [&](Value *RV) {
    for (User *U : RV->users())
      if (!RailOpSet.count(U))
        return false;
    return true;
  };
  if (!consumedOnlyByMutations(RailPhi))
    return bail();
  for (BinaryOperator *BO : RailOps)
    if (BO != RailLat && !consumedOnlyByMutations(BO))
      return bail();

  // ── (E9) The break-cond must read ONLY the (post-mutation) rail + loop-INVARIANTS
  // / constants — never the loop counter or another loop-VARIANT value. The backward
  // reverse-play CLONES the break-cond verbatim; a loop-variant operand (the forward
  // counter `%i`, a loop-variant temp) is undefined in the backward companion loop —
  // a dominance violation / broken module (the Rule-13 review 2026-06-26: a
  // `if ((q & i) == 0) break` clone references `%i`, which `opt -verify` rejects).
  // Walk the break flag's lineage: every Header-defined operand must be a rail value
  // (`RailPhi` / a `RailOp` — incl. the post-mutation `RailLat`) or a tainted
  // break-cond op (recurse); an UNTAINTED Header-defined operand (the counter / a
  // loop-variant classical) declines (Prime Directive — over-declining is safe).
  SmallPtrSet<const Value *, 8> BreakCondOps;  // the tainted break-cond chain (E11).
  {
    SmallVector<Value *, 8> Work;
    SmallPtrSet<Value *, 16> Seen;
    Work.push_back(Rgn.BreakFlag);
    Seen.insert(Rgn.BreakFlag);
    while (!Work.empty()) {
      auto *I = dyn_cast<Instruction>(Work.pop_back_val());
      if (!I || I->getParent() != Header)
        continue;  // constant / argument / loop-invariant (defined outside the body).
                   // A loop-INVARIANT comparand (`q == p`, p defined pre-loop) STOPS
                   // the walk here — its lineage is deliberately NOT inspected, and
                   // that is SOUND even when p carries a RELATIVE PHASE (`p =
                   // cq_phi(p0,θ)`, mvrb) or is a DERIVED tainted handle (`p = p0 + 5`,
                   // 1784). The whole break construct (capture + consolidation +
                   // reverse-play, BreakReversePlay.cpp) emits ONLY basis-PERMUTATION
                   // gates — NO Ry/Rz/H inside it (any phase/derivation on p is built
                   // PRE-LOOP, outside the construct). So the construct is a fixed
                   // permutation π: p's amplitudes (incl. its phase) ride INERT, and p
                   // is consumed EXCLUSIVELY as a QQ-compare control (+matched `_unc`)
                   // — never rotated, copied into `out`, measured, or freed. p is
                   // restored exactly and LEFT ALLOCATED (the Rule-6 safe leak;
                   // `isTerminalHandle(p)` is false, so the whole-DAG spine never
                   // recovers it). Cleared by a 5-lens adversarial Rule-13 sign-off
                   // 2026-06-30 (0 holes). CONTRAST B3 (line ~1027), which DOES fence a
                   // phase ESCAPING ANSWER (the rail itself) — there method-B copies
                   // the rail out, and Rule 7's CNOT-copies-a-label-not-a-phase bites;
                   // a phase on the COMPARAND is never copied out, so it does not.
      if (I == RailPhi || RailOpSet.count(I))
        continue;  // a rail value — the break-cond reads the rail (fine; stop here).
      if (!taint.Tainted.count(I))
        return bail();  // a loop-variant CLASSICAL operand (the counter) — its clone
                        // is undefined in the backward companion loop.
      BreakCondOps.insert(I);  // a tainted break-cond op (recorded for E11 coverage).
      for (Value *Op : I->operands())
        if (Seen.insert(Op).second)
          Work.push_back(Op);
    }
  }

  // ── (E11) BODY COVERAGE — every TAINTED value defined in the body block is a rail
  // value (`RailPhi` / a `RailOp`) or a break-cond op (`BreakCondOps`). A STRAY
  // tainted value (a second compare, an extra tainted producer) is off the proven
  // single-rail-single-break shape AND would break the post-lowering structural
  // re-scan (`discoverLoweredBreak`, BreakReversePlay.cpp), whose single-break-flag
  // invariant a second tainted compare violates — leaving the forward-transformed
  // `out` = |0> (a silent wrong answer; the Rule-13 RE-review 2026-06-26). Declining
  // here, BEFORE any mutation, keeps the forward transform and the post-lowering
  // emission in lock-step (Prime Directive — over-declining is safe). The FUSED EXIT
  // condition (`select(brk, true, bound)` / `or`) is tainted (it uses the break flag)
  // and is the loop terminator the forward transform strips — it is part of the
  // recognized shape, NOT a stray (allowed below). A measure of the rail is not a
  // body value (it lives in the exit block).
  Value *FusedCond = cast<BranchInst>(Header->getTerminator())->getCondition();
  for (Instruction &I : *Header) {
    if (I.isTerminator())
      continue;  // the loop's (tainted-condition) exit branch — loop control the
                 // forward transform rewrites, not a stray data value.
    if (!taint.Tainted.count(&I))
      continue;
    if (&I == RailPhi || RailOpSet.count(&I) || BreakCondOps.count(&I) ||
        &I == FusedCond)
      continue;
    return bail();  // a stray tainted body value — not the proven clean shape.
  }

  // ── Width fences (the in-place / copy ABI serves ≤64-bit integers only) ────
  StringRef RailWidth = abiWidthFromType(RailPhi->getType());
  StringRef IdxWidth = abiWidthFromType(CounterPhi->getType());
  if (!wd.allocFn(RailWidth) || !wd.copyFn(RailWidth) || !wd.allocFn(IdxWidth) ||
      !wd.copyFn(IdxWidth))
    return bail();

  // ── ALL preconditions met — MUTATE (the forward transform) ────────────────
  DebugLoc DL = BreakI->getDebugLoc();
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // (1) Mark the rail self-update ops in-place (dtzb) so `lowerOps` emits the
  //     `cqrt_{addc,xorc}_<W>` in-place gate (one rail handle) rather than the
  //     out-of-place template (the X1 fresh-rail-per-iteration dirty rail).
  for (BinaryOperator *BO : RailOps)
    taint.InPlaceRailOps.insert(BO);

  // (2) Mint R / idx / out = |0> before the loop (in the rail phi's external
  //     predecessor, which dominates both the loop and the exit).
  IRBuilder<> PB(PreB->getTerminator());
  Type *RailTy = RailPhi->getType();
  Type *IdxTy = CounterPhi->getType();
  CallInst *RReg =
      PB.CreateCall(wd.allocFn(RailWidth), {ConstantInt::get(RailTy, 0)}, "cq.brk.R");
  CallInst *IdxReg =
      PB.CreateCall(wd.allocFn(IdxWidth), {ConstantInt::get(IdxTy, 0)}, "cq.brk.idx");
  CallInst *OutReg =
      PB.CreateCall(wd.allocFn(RailWidth), {ConstantInt::get(RailTy, 0)}, "cq.brk.out");
  stamp(RReg);
  stamp(IdxReg);
  stamp(OutReg);
  // R/idx/out are pass-invented control scratch (Phase-7.4 owns reversal/leak):
  // join `Tainted` (so downstream keeps them classified as quantum handles) AND
  // `ControlOwnedRails` (so the whole-DAG `uncompute` spine never selects them as
  // terminals — the reverse-play frees R/idx; out escapes via the measure). The
  // rail Root is likewise break-owned (the reverse-play restores it to its
  // pre-loop state, then LEAVES it allocated — a dirty rail is never freed,
  // Rule 6).
  for (Value *H : {static_cast<Value *>(RReg), static_cast<Value *>(IdxReg),
                   static_cast<Value *>(OutReg)}) {
    taint.Tainted.insert(H);
    taint.ControlOwnedRails.insert(H);
  }
  // NB: the rail Root (`cq_theta`) is RAUW'd to its `cqrt_alloc` handle by
  // `lowerRotations`, so inserting it here would go STALE. The rail handle (and
  // every break-body scratch handle) is excluded from the whole-DAG uncompute
  // spine LATER, in the post-lowering `lowerBreakReversePlay`, where the LOWERED
  // i32 handles are live.

  // (3) RAUW the exit merge phi → out, erase it (BEFORE `declineClassicalMuxes`
  //     would flag a tainted merge phi). `out` is |0> now; the post-lowering
  //     copy-out writes the answer into it before the measure reads it.
  Rgn.EscapePhi->replaceAllUsesWith(OutReg);
  taint.Tainted.erase(Rgn.EscapePhi);
  Rgn.EscapePhi->eraseFromParent();

  // (4) Collapse the rail phi → Root (dtzb Case-A style: RAUW + scrub + erase).
  RailPhi->replaceAllUsesWith(Root);
  taint.Tainted.erase(RailPhi);
  RailPhi->eraseFromParent();

  // (5) Strip the quantum break flag from the loop terminator: branch on the
  //     CLASSICAL bound alone, so the rolled loop runs its full trip count (the
  //     break is realized virtually by `idx`, PRD §2.9). Canonical polarity
  //     (IsOr && ExitTakenOnTrue): exit when bound==true. The successor layout is
  //     unchanged (exit at the true edge). Erase the now-dead fused select; the
  //     break-cond compare stays (use-empty now, but `lowerOps` lowers it by
  //     taint membership and the post-lowering capture consumes its handle).
  auto *Term = cast<BranchInst>(Rgn.ExitingBlock->getTerminator());
  Value *Fused = Term->getCondition();
  Term->setCondition(Rgn.BoundFlag);
  if (auto *FusedI = dyn_cast<Instruction>(Fused))
    if (FusedI != Rgn.BoundFlag && FusedI->use_empty())
      FusedI->eraseFromParent();

  // (6) Record the post-lowering-stable region for `lowerBreakReversePlay`.
  Rgn.CounterPhi = CounterPhi;
  Rgn.BoundLimit = BoundLimit;
  Rgn.RReg = RReg;
  Rgn.IdxReg = IdxReg;
  Rgn.OutReg = OutReg;
  Rgn.RailWidth = RailWidth;
  Rgn.IdxWidth = IdxWidth;
  taint.BreakRegions.push_back(Rgn);
  return true;
}

// Try to recognize one natural loop `L` as a single value-arm `break` loop
// (Phase 7.4, epic y05j). Returns true iff `tryBreak` CLAIMS `L` — either the
// recognized value-arm break (interim decline in Inc 1) or one of the off-pattern
// break declines (phase / non-reconverging / multiple-site / nested, §2.10).
// Returns false ⇒ `L` is NOT a recognized break (genuinely quantum-bounded, a
// bare tainted exit, a both-tainted fused exit, or an unproven body) and is left
// for `tryCaseA` — whose L1 `taintedExit` then gives it the existing
// `loop under quantum control` decline (Prime Directive: not-claiming is safe).
//
// Tried BEFORE `tryCaseA` (PRD-7.4 §2.4): a break loop's value-mutating rail is
// NOT a pure in-place persistent accumulator, so `tryCaseA` would otherwise
// X1/L1-decline it before the partition runs. NO mutation, NO emission (Inc 1).
bool tryBreak(Loop *L, Function &F, TaintSet &taint, WidthDispatch &wd,
              const SmallPtrSetImpl<CallInst *> &GateCalls, DominatorTree &DT,
              LoopInfo &LI, ScalarEvolution &SE) {
  (void)F;
  // Only a loop with a tainted EXIT is a break/quantum-bounded candidate; a
  // classical-exit loop is `tryCaseA`/Case-B territory (leave it).
  if (!taintedExit(L, taint))
    return false;

  // (Multi-site, B1) Count tainted exiting blocks. >1 ⇒ multiple early-break
  // sites (v3_multi) — INTERIM decline, accepted in Inc 3 (§2.7). Checked first:
  // the index-latch generalization is orthogonal to the single-break mechanism.
  SmallVector<BasicBlock *, 4> Exiting;
  L->getExitingBlocks(Exiting);
  unsigned TaintedExiting = 0;
  Instruction *TheExitT = nullptr;
  BasicBlock *TheExitB = nullptr;
  for (BasicBlock *EB : Exiting)
    if (isTaintedExitingTerminator(EB->getTerminator(), taint)) {
      ++TaintedExiting;
      TheExitT = EB->getTerminator();
      TheExitB = EB;
    }
  if (TaintedExiting > 1) {
    diagnose(TheExitT, kMsgBreakMultiSite);
    return true;
  }

  // Exactly one tainted exiting block. Inc-1 lowers only the FUSED conditional
  // branch (a tainted `switch` break is not in the proven set — ride L1).
  auto *BI = dyn_cast<BranchInst>(TheExitT);
  if (!BI || !BI->isConditional())
    return false;
  BasicBlock *S0 = BI->getSuccessor(0), *S1 = BI->getSuccessor(1);
  bool In0 = L->contains(S0), In1 = L->contains(S1);
  if (In0 == In1)
    return false;  // not exactly one in-loop / one exit successor — unproven.
  bool ExitTakenOnTrue = !In0;  // the exit successor is the false edge iff In0.

  // (Non-reconverging, B2) The break and the natural exit must converge to ONE
  // loop-exit block. `getUniqueExitBlock()` is null when the loop has multiple
  // DISTINCT exit blocks (v4_nonreconv: the break edge and the bound edge reach
  // different blocks) ⇒ DEFER decline (§2.7). NB: `getUniqueExitBlock` (not
  // `getExitBlock`) — the latter returns null even for repeat exit EDGES to one
  // shared block, over-declining genuinely-reconverging two-edge loops (the
  // adversarial-review getExitBlock-vs-getUniqueExitBlock note 2026-06-25).
  BasicBlock *ExitBlk = L->getUniqueExitBlock();
  if (!ExitBlk) {
    diagnose(TheExitT, kMsgBreakNonReconv);
    return true;
  }

  // (B1) Decompose the `-O1` fused exit into {break flag, classical bound}. A
  // bare tainted icmp (no fused classical bound — v5_qbound) or a 3-operand mux
  // returns nullopt ⇒ NOT a break: leave it for L1 (genuinely quantum-bounded).
  auto Pair = decomposeFusedExit(BI->getCondition());
  if (!Pair)
    return false;
  Value *A = Pair->A, *B = Pair->B;
  bool TA = taint.Tainted.count(A), TB = taint.Tainted.count(B);
  // The load-bearing partition (Risk 4): EXACTLY one disjunct tainted (the break
  // flag) and the other CLASSICAL (the loop bound). Both tainted ⇒ no classical
  // fall-through ⇒ genuinely quantum-bounded; neither ⇒ not a tainted exit. Both
  // ride L1 (return false).
  if (TA == TB)
    return false;
  Value *BreakFlag = TA ? A : B;
  Value *BoundFlag = TA ? B : A;
  // The break flag must be a stock comparison on a tainted value (a clean
  // single-condition break); a compound tainted disjunct (a nested select/or)
  // is not in the Inc-1 proven set — ride L1.
  if (!isa<ICmpInst>(BreakFlag) && !isa<FCmpInst>(BreakFlag))
    return false;
  Instruction *BreakI = cast<Instruction>(BreakFlag);  // source-locator anchor.

  // (B4, nested) `L` inside another loop, or wrapping a tainted subloop ⇒ the
  // break crosses loops (v6_nested) — DEFER, blocked-on the nested-quantum-loop
  // substrate (§2.7). Checked once the break shape is confirmed (a quantum-
  // bounded nested loop must stay L1, not be relabeled "nested break").
  if (L->getParentLoop() || subloopHasTaintedValue(L, taint, LI)) {
    diagnose(BreakI, kMsgBreakNested);
    return true;
  }

  // (B2) The single exit block must carry exactly one TAINTED merge phi — the
  // escaping answer. Zero / multiple tainted phis is not the clean single-answer
  // reconvergence (ride L1).
  PHINode *EscapePhi = nullptr;
  for (PHINode &P : ExitBlk->phis())
    if (taint.Tainted.count(&P)) {
      if (EscapePhi)
        return false;  // >1 tainted exit phi — unproven.
      EscapePhi = &P;
    }
  if (!EscapePhi)
    return false;

  // (B3) Value-class answer. A phase-class escaping answer (an Rz/`cq_phi` in any
  // incoming lineage — v2_phase) cannot be CNOT-copied out (Rule 7 dephases) and
  // the data-comparison phase break is degenerate ⇒ PERMANENT decline (§2.6).
  for (Value *In : EscapePhi->incoming_values())
    if (taint.Tainted.count(In) && breakLineageCarriesPhase(In, taint)) {
      diagnose(BreakI, kMsgBreakPhase);
      return true;
    }

  // (B5, Risk 4) A proven 7.3 rolled loop with a REAL, PROVABLY-FINITE CLASSICAL
  // TRIP-COUNT bound: single latch, and ScalarEvolution must prove the loop
  // terminates classically (a computable symbolic max backedge-taken count). A
  // loop whose only real termination is the quantum break — whether via a
  // loop-invariant guard (`while((q&1)&&(m!=0))`, dead counter) or a non-bounding
  // counter comparison (always-true `i>=0`, wrong-direction `i>k`, unreachable
  // `i==-1`, identity `i+=0`) — has an UNPREDICTABLE max and must ride L1, NOT be
  // recognized as a value-arm break (the adversarial-review R4 false-accept family
  // 2026-06-25 — the seed of an Inc-2 silent miscompile; the proof lands here in
  // Inc-1 recognition, not Inc 2). SCEV's termination reasoning is the sound proof
  // a structural "bound references the counter" check cannot give.
  BasicBlock *Latch = L->getLoopLatch();
  if (!Latch)
    return false;
  BasicBlock *Header = L->getHeader();
  // The classical bound must compare the induction against a loop-INVARIANT limit
  // (Risk 4 — the necessary precondition that makes the SCEV symbolic-max proof
  // sound against the P3 two-counter-diverging / vacuous-bound overflow hazard).
  if (!boundComparesInductionToInvariant(BoundFlag, L, SE))
    return false;
  // Then EITHER the SCEV symbolic-max proof (fast path; handles eq/unit-stride/
  // downward, incl. the select-fused exit) OR the structural classical-constant-step
  // termination proof (the increment widening — covers the `slt`-non-unit-stride
  // shapes SCEV's symbolic-max leaves Unpredictable). Both prove a finite classical
  // trip bound; with the loop-invariant-limit guard the union never accepts a
  // genuinely quantum-bounded loop (Risk 4).
  if (!hasFiniteClassicalTripBound(L, SE) &&
      !boundProvablyTerminates(BoundFlag, Pair->IsOr, ExitTakenOnTrue, L, SE,
                               taint))
    return false;

  // (B4, body) No OTHER tainted control (a nested diamond/switch beyond the break
  // exit) and no tainted-index memory in the body — those are the existing 7.3
  // L2/L3 owners' (ControlDetect / kMsgQramLoop). Their presence means the body
  // is not the proven invertible single-break shape (ride L1).
  for (BasicBlock *BB : L->blocks()) {
    Instruction *T = BB->getTerminator();
    if (T != TheExitT && isTaintedExitingTerminator(T, taint))
      return false;  // a second tainted br/switch (non-exiting control) in body.
    if (auto *BrI = dyn_cast<BranchInst>(T))
      if (T != TheExitT && BrI->isConditional() &&
          taint.Tainted.count(BrI->getCondition()))
        return false;
    if (auto *SwI = dyn_cast<SwitchInst>(T))
      if (T != TheExitT && taint.Tainted.count(SwI->getCondition()))
        return false;
    for (Instruction &I : *BB) {
      if (isa<GetElementPtrInst>(I) || isa<LoadInst>(I) || isa<StoreInst>(I))
        for (Value *Op : I.operands())
          if (taint.Tainted.count(Op))
            return false;  // tainted-index memory — the kMsgQramLoop owner's.
      // An OBSERVABLE / IRREVERSIBLE body op — a `cq_measure` (Rule 5: the
      // compiler must NEVER emit a measurement the user did not write — and the
      // rolled break runs the body its FULL trip count AND the reverse-play
      // replays it, so an in-body measure would fire ~2n times at the wrong
      // place), or any side-effecting call / volatile-atomic store (a global /
      // I/O effect the full-trip + reverse-play replay would multiply). The
      // break virtualization (PRD §2.9) is sound ONLY for a pure-coherent body;
      // such an op rides L1 (`loop under quantum control`). The canonical
      // value-arm break body is pure arithmetic + phis (the rail mint lives in
      // the preheader), so this never over-declines it (the Rule-13 FINAL review
      // 2026-06-26).
      if (!I.isTerminator() && I.mayHaveSideEffects())
        return false;
    }
  }

  // KNOWN Inc-1 coverage limitation (DECLINE-SAFE — rides L1, not a miscompile;
  // for Inc 2 to widen, NOT a bug to mistake for a quantum-bound classification
  // error): a CONSTANT-bound break (`for(i<8)…break`). `clang -O1` drops the
  // zero-trip guard for a provably-≥1-trip constant bound, so the exit block has a
  // SINGLE predecessor and NO merge phi — the escaping value is consumed directly,
  // and the (B2) `EscapePhi==null` check declines. (A runtime bound keeps the guard
  // ⇒ the merge phi ⇒ recognized — the v1 canonical case.) Inc 2 may fall back to
  // the directly-escaping value when the exit block has one predecessor.
  // (The earlier non-unit-stride gap is CLOSED by the §B5 increment widening above.)
  //
  // RECOGNIZED single value-arm break. Run the FORWARD TRANSFORM (Inc 2, y05j.2):
  // collapse the rail, strip the terminator to the classical bound, mint
  // `R`/`idx`/`out`, RAUW the exit phi → `out`, and record the `LoopBreakRegion`
  // the post-lowering `lowerBreakReversePlay` consumes to emit the index-gated
  // capture + whole-loop reverse-play. `emitBreakForward` declines LOUDLY
  // (`kMsgBreakUnemittable`) for a recognized-but-non-canonical sub-shape; either
  // way the loop is CLAIMED here (NOT mis-declined as the L1 quantum-bounded loop,
  // Risk 4). `kMsgBreakPending` is retired (emission now lands).
  LoopBreakRegion R;
  R.L = L;
  R.Header = Header;
  R.Latch = Latch;
  R.ExitMerge = ExitBlk;
  R.ExitingBlock = TheExitB;
  R.BreakFlag = BreakFlag;
  R.BoundFlag = BoundFlag;
  R.EscapePhi = EscapePhi;
  R.ExitTakenOnTrue = ExitTakenOnTrue;
  emitBreakForward(R, taint, wd, GateCalls, DT, Pair->IsOr);
  return true;
}

// Try to recognize + collapse one natural loop `L` as Case A (in-place
// persistent accumulator). Returns true iff a Case-A collapse (or a LOUD
// X1/Q1 decline) was performed; false ⇒ `L` is left untouched for its existing
// owner (Prime Directive — claim only what is proven).
bool tryCaseA(Loop *L, Function &F, TaintSet &taint,
              const SmallPtrSetImpl<CallInst *> &GateCalls, DominatorTree &DT,
              LoopInfo &LI) {
  // (L1) Quantum/measurement-bounded exit ⇒ permanent decline (§2.6). Checked
  //      FIRST and BEFORE `detectControlRegions`, so Q1 gets the dedicated
  //      `loop under quantum control` message rather than the generic
  //      `nested control flow…` ControlDetect would otherwise emit.
  if (Instruction *TE = taintedExit(L, taint)) {
    diagnoseUnderControl(TE, "loop");
    return true;
  }

  // (L2) Tainted control INSIDE the body (a non-exiting tainted `br`/`switch` —
  // a loop-resident diamond/if-else/switch). 7.3 does NOT lower control-in-loop
  // (§2.8): leave the loop unclaimed so the existing `ControlDetect` /
  // `RegionTreeDetect` owner declines it (`nested control flow under quantum
  // control`, the backedge guard `RegionTreeDetect.cpp`). Crucially this runs
  // BEFORE the X1 header-phi analysis below, so a control-merge latch phi (a
  // tainted nested-diamond merge feeding the backedge) is left for that owner
  // rather than mis-declined as a cross-iteration dirty value rail.
  for (BasicBlock *BB : L->blocks()) {
    Instruction *T = BB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return false;
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return false;
    }
  }

  BasicBlock *Header = L->getHeader();
  BasicBlock *Latch = L->getLoopLatch();
  // Require a single latch — the `-O1` shape (verified). NOTE: a rotated `-O1`
  // loop has a GUARD branch (`if (n>0) goto loop`) as its entry predecessor,
  // which is NOT a dedicated preheader (it has two successors), so
  // `getLoopPreheader()` returns null here — the header phi's external
  // (non-latch) incoming is identified directly from its incoming blocks below.
  // A multi-latch loop is an unproven shape; leave it (conservative).
  if (!Latch)
    return false;

  // railRoot maps every value on a recognized persistent rail to its single
  // root mint (a classical-operand `cq_theta`). Seeded from the clean
  // self-cycle header phis; expanded to a fixpoint over in-place gates and
  // single-root phis below.
  DenseMap<Value *, Value *> railRoot;
  for (PHINode &P : Header->phis()) {
    if (!taint.Tainted.count(&P))
      continue;  // classical induction phi — not a rail.
    // The header phi must have exactly two incomings: one from the latch (the
    // back edge) and one EXTERNAL (the entry/guard edge from outside L). A phi
    // with extra edges (an irreducible / multi-entry shape) is unproven.
    if (P.getNumIncomingValues() != 2)
      return false;  // unproven multi-edge header phi — leave it.
    Value *LatV = nullptr;
    Value *PreV = nullptr;
    for (unsigned i = 0; i < 2; ++i) {
      BasicBlock *IB = P.getIncomingBlock(i);
      if (IB == Latch)
        LatV = P.getIncomingValue(i);
      else if (!L->contains(IB))
        PreV = P.getIncomingValue(i);  // the external (entry) edge.
    }
    if (!PreV || !LatV)
      return false;  // not the clean latch + external-entry pair.
    // (Risk 2) The latch incoming must peel — through IN-PLACE gates ONLY —
    // back to the header phi itself (a closed self-cycle ⇒ a single persistent
    // rail). A latch that peels to a fresh value-op rail (a `cq_template_*`
    // accumulator, X1) is a cross-iteration dirty rail: LOUD decline, never a
    // silent collapse of a loop-variant handle.
    if (peelInPlaceBase(LatV, GateCalls, taint) != &P) {
      // X1 only when the latch carries a genuine tainted dirty rail across the
      // backedge (an `acc=acc+q` fresh-rail accumulator). A header phi we cannot
      // classify either way is left for downstream (conservative).
      Value *LatBase = peelInPlaceBase(LatV, GateCalls, taint);
      if (taint.Tainted.count(LatBase)) {
        diagnose(&P, kMsgCrossIter);
        return true;
      }
      return false;
    }
    // The preheader incoming must peel to a classical-operand `cq_theta` MINT
    // that dominates the loop (the rail origin).
    Value *Root = peelInPlaceBase(PreV, GateCalls, taint);
    auto *Mint = dyn_cast<CallInst>(Root);
    if (!Mint || !GateCalls.count(Mint) ||
        taint.Tainted.count(Mint->getArgOperand(0)))
      return false;  // preheader incoming is not a clean rail mint.
    if (!DT.dominates(Mint, Header))
      return false;
    railRoot[Root] = Root;
    railRoot[&P] = Root;
  }
  if (railRoot.empty())
    return false;  // no persistent rail — Case B / other, not Inc 1.

  // Fixpoint expansion: an in-place gate on a rail value joins the SAME rail; a
  // tainted phi ALL of whose incomings peel to one common root joins that root
  // (the zero-trip/exit merge phi and any inner renaming). A phi whose incomings
  // peel to TWO distinct roots is a cross-rail merge — not clean; bail.
  SmallVector<Value *, 16> Work;
  for (auto &KV : railRoot)
    Work.push_back(KV.first);
  bool PhiAdded = true;
  while (PhiAdded) {
    // (a) drain the in-place-gate worklist. An in-place gate on a rail value V
    // joins V's rail: a rotation gate (`isInPlaceGateOnArg0`, the 7.3 vocabulary)
    // OR a value self-update (`inPlaceValueRailOperand(BO) == V`, issue dtzb —
    // `cqrt_{addc,xorc}` mutates the one rail handle in place, so its result is
    // the same rail).
    while (!Work.empty()) {
      Value *V = Work.pop_back_val();
      Value *R = railRoot[V];
      for (User *U : V->users()) {
        bool InPlace = false;
        if (auto *CI = dyn_cast<CallInst>(U))
          InPlace = isInPlaceGateOnArg0(CI, V, GateCalls, taint);
        else if (auto *BO = dyn_cast<BinaryOperator>(U))
          InPlace = inPlaceValueRailOperand(BO, taint) == V;
        if (!InPlace)
          continue;
        auto *I = cast<Instruction>(U);
        auto It = railRoot.find(I);
        if (It == railRoot.end()) {
          railRoot[I] = R;
          Work.push_back(I);
        } else if (It->second != R) {
          return false;  // a gate result claimed by two rails — not clean.
        }
      }
    }
    // (b) one phi-scan pass: add any tainted phi now fully resolved to one root.
    PhiAdded = false;
    for (BasicBlock &BB : F)
      for (PHINode &P : BB.phis()) {
        if (railRoot.count(&P) || !taint.Tainted.count(&P))
          continue;
        Value *Common = nullptr;
        bool Ok = true, Touches = false;
        for (Value *V : P.incoming_values()) {
          Value *Base = peelInPlaceBase(V, GateCalls, taint);
          auto It = railRoot.find(Base);
          if (It == railRoot.end()) {
            Ok = false;
            break;
          }
          Touches = true;
          if (!Common)
            Common = It->second;
          else if (Common != It->second) {
            Ok = false;  // merges two distinct rails — not a clean renaming.
            break;
          }
        }
        if (Ok && Touches && Common) {
          railRoot[&P] = Common;
          Work.push_back(&P);
          PhiAdded = true;
        }
      }
  }

  // FAN-OUT / linear-lineage guard (Rule 8 no-cloning; the Rule-13 adversarial
  // review 2026-06-26 found this verify-clean over-accept). A rail value may have
  // AT MOST ONE forward IN-PLACE consumer (a single linear chain). MORE than one
  // is FAN-OUT: the rail value is read by two in-place mutators that the collapse
  // would both serialize onto the ONE rail handle — corrupting both (e.g. `%qn =
  // q^9` carried + `%qm = q^3` escaping ⇒ `xorc(h,9); xorc(h,3)` ⇒ measures
  // `q^9^3`, not the source's `q^3`; the rotation twin `rz(h,1); rz(h,2)` = Rz(3)
  // ≠ the source's Rz(2)). In-place mutation needs LINEAR lineage; a fan-out of a
  // superposed source needs an ancilla/`cqrt_cswap`, not in-place collapse. The
  // count covers BOTH gate kinds — value self-updates (dtzb add/xor) AND rotations
  // (cq_phi/rz, the SHARED pre-dtzb gap) — so the same guard closes both. Loud
  // decline (claimed), never a silent serialized collapse (Prime Directive).
  for (auto &KV : railRoot) {
    SmallVector<Instruction *, 2> InPlaceUsers;
    for (User *U : KV.first->users()) {
      if (auto *CI = dyn_cast<CallInst>(U)) {
        if (isInPlaceGateOnArg0(CI, KV.first, GateCalls, taint))
          InPlaceUsers.push_back(CI);
      } else if (auto *BO = dyn_cast<BinaryOperator>(U)) {
        if (inPlaceValueRailOperand(BO, taint) == KV.first)
          InPlaceUsers.push_back(BO);
      }
    }
    if (InPlaceUsers.size() > 1) {
      diagnose(InPlaceUsers.front(), kMsgRailFanout);
      return true;  // recognized but unlowerable fan-out — loud decline.
    }
  }

  // COVERAGE: every tainted value whose innermost loop is exactly `L` must be on
  // a rail (else there is a value op / control / memory in the body — not pure
  // Case A; leave it for Inc 2 / the existing owners). A tainted instruction in
  // a strictly-deeper subloop is NOT this loop's to classify.
  for (BasicBlock *BB : L->blocks()) {
    if (LI.getLoopFor(BB) != L)
      continue;  // a subloop block — owned by the inner loop's pass.
    for (Instruction &I : *BB) {
      if (!taint.Tainted.count(&I))
        continue;
      if (isMeasureCall(&I))
        continue;  // a sink reading the rail — fine.
      if (!railRoot.count(&I))
        return false;  // an uncovered tainted body value — not pure Case A.
    }
  }

  // CLOSURE: every user of a rail value is an in-place gate / phi on the rail, a
  // measure sink, or an escape (`ret`). ANY other consumer — a value-op
  // template producer, a tainted control compare, a store, an unknown call, or
  // the rail used as a classical ANGLE (arg-1) — means the rail is not isolated;
  // leave it (the consumer's own guard declines loudly downstream).
  for (auto &KV : railRoot) {
    Value *V = KV.first;
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        continue;
      if (railRoot.count(I) || isMeasureCall(I) || isa<ReturnInst>(I))
        continue;
      // An in-place gate on the rail whose result is itself a rail is in
      // railRoot (handled above). Anything else is an out-of-rail consumer.
      return false;
    }
  }

  // ACCEPT. Issue dtzb — mark each IN-PLACE VALUE rail self-update so `lowerOps`
  // emits the in-place `cqrt_{addc,xorc}_<W>(handle, imm)` (not the out-of-place
  // `cq_template_<op>_<W>_hl` that mints a fresh per-iteration rail). Rotation
  // gates need NO marking: `lowerRotations` already lowers them in place. Only
  // BinaryOperator rail members exist via `inPlaceValueRailOperand`, so every one
  // is a proven value self-update; mark before the phi collapse erases nothing it
  // depends on (marking only records the op, never mutates it). The op's result
  // goes use-empty after the collapse, but `lowerOps` collects it by taint
  // membership (not use-count) and emits the side-effecting in-place gate.
  for (auto &KV : railRoot)
    if (auto *BO = dyn_cast<BinaryOperator>(KV.first))
      taint.InPlaceRailOps.insert(BO);

  // Collapse every rail PHINode to its root. RAUW to the root mint (the
  // still-pre-lowering `cq_theta` SSA value, SAME type as the phi — no ill-typed
  // `phi double` survives, Risk 5; rotation lowering later maps root→%h). Scrub
  // each erased phi from `Tainted` (the `scrubTaint` precedent) and erase after
  // ALL RAUWs so inter-phi references resolve cleanly.
  SmallVector<PHINode *, 4> Collapse;
  for (auto &KV : railRoot)
    if (auto *P = dyn_cast<PHINode>(KV.first))
      Collapse.push_back(P);
  for (PHINode *P : Collapse)
    P->replaceAllUsesWith(railRoot[P]);
  for (PHINode *P : Collapse) {
    taint.Tainted.erase(P);
    P->eraseFromParent();
  }
  return true;
}

// Increment 2 (799w.2) — Case B: mark a loop whose every tainted value is an
// ITERATION-LOCAL born-and-dies temporary, so the Phase-5 uncompute spine
// recovers each temp's DAG IN-BODY (once per iteration) instead of declining
// (FreePoint kMsgLoopBackedge) or leaking. Pure analysis; the ONLY effect is
// inserting `L`'s blocks into `taint.IterationLocalBlocks` (no mutation). Called
// only when `tryCaseA` left the loop unclaimed.
//
// A loop qualifies iff: classical exit (L1 — a tainted exit was already declined
// Q1 by `tryCaseA`); no tainted control (L2) / tainted-index memory (L3) in the
// body; and every tainted value is iteration-local — NO tainted header phi (no
// loop-carried persistent rail; that is Case A or X1), every tainted value
// DEFINED in L is USED only in L (nothing escapes the loop), and every tainted
// OPERAND of an in-L instruction is DEFINED in L (no loop-invariant tainted input
// minted outside, whose register would accumulate across iterations — the
// `lowering_uncompute_loop_backedge` residual). The spine then PROVES per-DAG
// closure/measure/escape; this predicate only certifies the loop is a sound place
// to lift the backedge guard (Prime Directive: not-marking is always safe).
void markIfIterationLocal(Loop *L, TaintSet &taint, LoopInfo &LI) {
  if (taintedExit(L, taint))
    return;  // Q1 quantum-bounded — never Case B.
  BasicBlock *Header = L->getHeader();
  bool AnyTainted = false;
  for (BasicBlock *BB : L->blocks()) {
    // (L2) tainted control in the body ⇒ the existing ControlDetect owner's.
    Instruction *T = BB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return;
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return;
    }
    if (LI.getLoopFor(BB) != L) {
      // A strictly-deeper SUBLOOP with quantum content is a NESTED quantum loop,
      // not a single-level iteration-local loop: a value rotated by the subloop
      // runs the subloop-trip-count times PER outer iteration, but the spine
      // would reverse it ONCE (a dirty free of an under-reversed rail — a SILENT
      // miscompile, confirmed on a do-while inner loop whose body dominates the
      // outer recovery point, so the divergent-arm backstop does not catch it).
      // Decline to mark (Prime Directive: over-declining is safe — the value's
      // terminal then keeps FreePoint's `kMsgLoopBackedge` reject). 7.3 does not
      // lower nested quantum loops; the subloop is handled (or declined) on its
      // own, never folded into the outer iteration-local set.
      for (Instruction &I : *BB)
        if (taint.Tainted.count(&I))
          return;
      continue;
    }
    for (Instruction &I : *BB) {
      // (L3) tainted-index memory in the body ⇒ the existing kMsgQramLoop owner's.
      if (isa<GetElementPtrInst>(I) || isa<LoadInst>(I) || isa<StoreInst>(I))
        for (Value *Op : I.operands())
          if (taint.Tainted.count(Op))
            return;
      const bool TI = taint.Tainted.count(&I);
      // A tainted HEADER phi is a loop-carried persistent rail (Case A / X1),
      // not an iteration-local temp.
      if (TI && isa<PHINode>(I) && BB == Header)
        return;
      if (TI) {
        AnyTainted = true;
        // Every tainted value defined in L must be used ONLY in L (nothing
        // escapes the loop — the last iteration's value never reads downstream).
        for (User *U : I.users())
          if (auto *UI = dyn_cast<Instruction>(U))
            if (!L->contains(UI->getParent()))
              return;
      }
      // Every tainted OPERAND must be defined in L — a tainted value minted
      // OUTSIDE L and read inside (loop-invariant) is a persistent register that
      // accumulates across iterations, NOT iteration-local.
      for (Value *Op : I.operands())
        if (taint.Tainted.count(Op)) {
          auto *OpI = dyn_cast<Instruction>(Op);
          if (!OpI || !L->contains(OpI->getParent()))
            return;
        }
    }
  }
  if (!AnyTainted)
    return;  // a purely-classical loop — leave it byte-identical.
  for (BasicBlock *BB : L->blocks())
    taint.IterationLocalBlocks.insert(BB);
}

}  // namespace

// Shared with the Lever-B force-unroll pre-pass (LoopUnrollPrepass.cpp, ticket
// lf8s — fence U4; contract in LoopPlan.h). Lives HERE so the disjointness gate
// calls the very predicates `tryCaseA` claims with (`inPlaceValueRailOperand`,
// `peelInPlaceBase`) instead of a re-implementation that could drift (Rule 14).
bool loopHasInPlaceRailStructure(
    Loop *L, const TaintSet &taint,
    const SmallPtrSetImpl<CallInst *> &GateCalls) {
  // (a) A tainted in-place-shaped `add`/`xor` self-update ANYWHERE in the loop
  // (dtzb). Even one whose rail lives OUTSIDE `L` matters: unrolling would
  // duplicate it, flipping the sibling rail's linear-lineage fan-out count
  // (the kMsgRailFanout guard) — over-skipping here is the safe direction.
  for (BasicBlock *BB : L->blocks())
    for (Instruction &I : *BB)
      if (auto *BO = dyn_cast<BinaryOperator>(&I))
        if (inPlaceValueRailOperand(BO, taint))
          return true;
  // (b) A tainted header phi whose latch incoming peels in-place back to the
  // phi itself — the Case-A claim seed (`tryCaseA` Risk 2), including the
  // zero-hop identity carry `phi [x, pre], [%self, latch]` that (a) misses.
  BasicBlock *Latch = L->getLoopLatch();
  if (!Latch)
    return true;  // multi-latch: unproven shape — report rail-structured.
  for (PHINode &P : L->getHeader()->phis()) {
    if (!taint.Tainted.count(&P))
      continue;
    for (unsigned i = 0, e = P.getNumIncomingValues(); i != e; ++i)
      if (P.getIncomingBlock(i) == Latch &&
          peelInPlaceBase(P.getIncomingValue(i), GateCalls, taint) == &P)
        return true;
  }
  return false;
}

void lowerLoops(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // The collected rotation call sites — the in-place-gate wire vocabulary the
  // peel + closure consult (same seed as `declineClassicalMuxes`).
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Cheap skip: a function with no tainted value has no quantum loop.
    bool AnyTainted = false;
    for (Value *V : taint.Tainted)
      if (auto *I = dyn_cast<Instruction>(V))
        if (I->getFunction() == &F) {
          AnyTainted = true;
          break;
        }
    if (!AnyTainted)
      continue;

    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    // ScalarEvolution (built standalone from DT/LI, the same direct-construction
    // idiom as DT/LI) proves the §2.5 B5 finite classical trip bound for the
    // `tryBreak` recognizer (Risk 4). A default `TargetLibraryInfoImpl` is a
    // conservative TLI — sufficient for SCEV's trip-count reasoning.
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);
    // Recognition is pure analysis on the still-unmutated IR; the only mutation
    // is the Case-A phi collapse inside `tryCaseA`, which erases phis (the CFG —
    // blocks + edges — is untouched, so `LI`/`DT` stay valid across loops). A
    // loop `tryCaseA` does not claim (Case A collapse / Q1 / X1) is offered to
    // the Case-B iteration-local recognizer (Increment 2), which only marks
    // blocks for the spine — never mutates.
    //
    // `tryBreak` (Phase 7.4, epic y05j) is tried FIRST (§2.4): a single value-arm
    // break loop's value-mutating rail is not a pure in-place accumulator, so
    // `tryCaseA` would X1/L1-decline it before the value-arm-vs-quantum-bounded
    // partition runs. Inc-1 `tryBreak` is pure analysis (recognition + decline),
    // no mutation — so `LI`/`DT` stay valid for the `tryCaseA` fallthrough.
    for (Loop *L : LI.getLoopsInPreorder()) {
      if (tryBreak(L, F, taint, wd, GateCalls, DT, LI, SE))
        continue;
      if (!tryCaseA(L, F, taint, GateCalls, DT, LI))
        markIfIterationLocal(L, taint, LI);
    }
  }
}

}  // namespace cq
