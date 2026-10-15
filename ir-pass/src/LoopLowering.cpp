// LoopLowering.cpp — Phase 7.3 bounded-loop recognition + lowering (epic 799w).
// See LoopPlan.h for the contract and the ordering constraints.
//
// Increment 1 (799w.1) — Case A "in-place persistent accumulator". A
// classically-bounded loop whose every tainted value is a persistent rail
// threaded through a loop-carried header phi, mutated only by IN-PLACE gates
// (chained `cq_theta`=Ry on a tainted operand; the register-form `cq_phi`=Rz is
// retired), lowers ROLLED IN PLACE: the loop CFG is preserved and the rail phi(s)
// — the loop-carried header phi AND the zero-trip/exit merge phi the `-O1` guard
// emits — collapse to the single persistent rail, so the body lowers to
// `cqrt_ry_<W>(%h, angle_i)` over a loop-invariant handle. The trace is
// byte-identical to the manually-unrolled form. No in-body free, no uncompute
// (the rail is measured/escaped after L).
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
#include "ArithLowering.h"  // classifyInPlaceReassignment (the ONE M-C spelling)
#include "CompareLowering.h"  // isDataPositionCompare + compareFlagMintable —
                              // the owners of "is this compare a region FLAG or
                              // DATA" and "does a template exist for it"
                              // (bd test_C_libtooling-7845, conjunct (3))
#include "ControlPlan.h"  // diagnoseUnderControl (Q1 reuses the control dialect)
#include "OpcodeSupport.h"  // abiWidthFromType (rail width for the capture allocs)
#include "WidthDispatch.h"
#include "FreePoint.h"      // blockCanRepeat (the ONE "can this block run twice")
#include "LiteralIntegrity.h"  // valueCarriesUndef (bd zujr, clause (Z4))
#include "RailBankPromote.h"  // isRailBankAlloca/railBankOfPointer (bd zujr, L3)
#include "RailWindow.h"       // railWindowOfPointer (bd 01po.19 S4, Case B)
#include "SelectMergeEmit.h"   // materializeCopySource (bd zujr, the promotion)
#include "QramLowering.h"  // instUnderTaintedControl (bd wt8u, the hand-off)
#include "TaintedControlDependence.h"  // isTaintedBranchTerminator (bd r2j3.6)
#include "AbortParkEmit.h"  // isAbortParkCondition (bd dm7f.7)

#include "llvm/IR/IRBuilder.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/CFG.h"  // isPotentiallyReachable (bd 8h7d.16)
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"  // bd 6n1s — conjunct (1)'s 2nd half
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"  // isSafeToSpeculativelyExecute (bd 8h7d.15, E17)
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"  // WeakTrackingVH (bd wx8g RolledLoopRegionGates)
#include "llvm/Support/raw_ostream.h"  // errs() — the bd bbu0 instrument marker
#include "llvm/TargetParser/Triple.h"

#include <cstdlib>  // getenv — the bd bbu0 instrument gate
#include <optional>
#include <string>
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

}  // namespace

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
//
// Exported since bd test_C_libtooling-6uqc Inc 2a — `ArithLowering`'s M-C
// straight-line in-place-reassignment fence asks the SAME question this
// predicate already answers, and Rule 14 says ask it rather than re-spell it.
// (Declared in LoopPlan.h.)
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

namespace {

// bd test_C_libtooling-eqpx — THE ONE WAY TO JOIN `taint.InPlaceRailOps`, for all
// FOUR writers. ⚠ SINCE THIS HELPER EXISTS, `InPlaceRailOps.insert(` HAS EXACTLY
// ONE SITE (the line below), so the command that enumerates the writers is
// `grep -n 'markInPlaceRailOp(' ir-pass/src/LoopLowering.cpp` — MEASURED, four
// callers (the round-1 lens's finding F-E1-1 corrected the stale `insert` grep and
// the four pre-helper line numbers that stood here):
//     W1 `emitBreakForward`            `:1738`  (7.4 break)
//     W2 `tryCaseA`'s ACCEPT           `:2321`  (round 1)
//     W3 `collapseRailPhisIn` step (3) `:2719`  (round 2)
//     W4 `commitOutOfLoopInPlaceOps`   `:3124`  (the predicted set)
// Cite the four FUNCTION NAMES in preference to the numbers: the numbers are true
// as of this edit and a comment edit above any of them moves all four.
//
// Membership and the proven rail's OPERAND INDEX are written in ONE statement so
// they cannot drift: `lowerOps` Phase 1 re-verifies the index against a fresh
// `inPlaceValueRailOperand` under FINAL taint and `rewriteInPlaceValueRail`
// CONSUMES it, which is what retires the third independent computation of one
// predicate (`ArithLowering.cpp:375`'s `TL = taint.Tainted.count(L)`, taken from
// a `Tainted` that Phase 2's `promote()` mutates as Phase 2 runs — the shape of
// the bd 8h7d.5 F-1/F-3 findings, and what made the eqpx defect's COMMUTED form
// mutate the WRONG REGISTER).
//
// `ProvenRail` is the value the CALLER proved, passed where the caller holds it
// AT THE MARKING STATEMENT (`commitOutOfLoopInPlaceOps`' `P`, one line above its
// own insert). The other three mark from a member LIST built earlier, so they let
// this ask G2 instead — which is not a second opinion: the predicate is pure over
// `(BO, taint)`, none of the three mutates `taint.Tainted` between proving and
// marking, so the answer IS the one they proved. (A parallel rail vector would be
// the drift risk this avoids.) An INDEX, never a `Value *`: RAUW replaces operands in
// place without reordering them, so an index survives every rewrite downstream,
// while a pointer keyed at one stage and read at another is the bd drbq Inc-1
// dangling defect. Erased in lockstep by `invariantRegisterRoots`' rollback.
void markInPlaceRailOp(BinaryOperator *BO, TaintSet &taint,
                       Value *ProvenRail = nullptr) {
  taint.InPlaceRailOps.insert(BO);
  Value *Rail = ProvenRail ? ProvenRail : inPlaceValueRailOperand(BO, taint);
  if (Rail)
    taint.InPlaceRailIdx[BO] = BO->getOperand(0) == Rail ? 0 : 1;
}

// ONE SPELLING of "will this `BinaryOperator` be lowered as an IN-PLACE mutation
// of rail value `V`'s handle?" (bd test_C_libtooling-8h7d.5, Rule-13 round 4,
// finding OD-A). Two independent halves, and conflating them is the defect this
// replaces: the SHAPE (`inPlaceValueRailOperand(BO) == V` — the dtzb `V OP c`
// bijection) says the op COULD be lowered in place; the DISPOSITION says whether
// it WILL be.
//
// In-place value lowering has exactly TWO owners, and this enumerates both:
//   * `taint.InPlaceRailOps` — `lowerLoops`' own proven set (round 1's `railRoot`
//     marking, round 2's step (3)). `Claimed` is the set the CALLER is about to
//     add to it, so a caller that runs BEFORE its own marking (the fan-out guard
//     does — step (2) precedes step (3)) passes its chain and gets the same
//     answer it would after marking. Round 1 passes `railRoot`, where the
//     question is a no-op: its fixpoint has already absorbed every in-place BO
//     consumer of a rail value, by construction.
//   * `ArithLowering`'s M-C in-place reassignment (`classifyInPlaceReassignment`
//     → `inPlaceFenceHolds`), whose **G5** refuses OUTRIGHT any site inside a
//     natural loop or a `blockCanRepeat` block — "the rolled-in-place (799w) and
//     whole-loop reverse-play (y05j/dtzb) machinery owns in-place value gates in
//     loop bodies … straight-line only". So an unmarked, unclaimed BO in a loop
//     body is `OutOfPlace` BY CONSTRUCTION: `lowerOps` mints it a FRESH rail
//     (`cq_template_<op>_<W>_hl`) and the loop-carried register never moves.
//
// `Unproven` is the straight-line remainder — M-C legitimately DOES fire there
// (`for(…){…} int r = q + 9; return cq_measure(r);` emits `cqrt_addc_i32(%h,9)`,
// probe r3h/b4) and nothing here can predict G6/G7's answer. Each caller states
// how it reads that cell, and the two read it OPPOSITE ways on purpose:
//
//   * the FAN-OUT guard counts `Unproven` (Rule 8 linear lineage — an unproven
//     second in-place mutator must decline loudly, Prime Directive);
//   * `collectRailGates`' forward extension follows only `InPlace` (its own
//     header explains why, and that exclusion is sound only because M-C's G6/G7
//     pair refuses a site with a later record read — round 3, bookkeeping 4).
//
// WHAT THIS FIXES. `clang -O1` canonicalizes the two-sided range test
// `if (q > 5 && q < 20)` to `%t = add %q, -6; icmp ult %t, 14`. `%t` has the dtzb
// SHAPE, so the fan-out guard counted it beside the arm's real `cq_phi` and
// declined `kMsgRailFanout` — while the hand-unrolled twin of the same source
// compiled. `%t` is a DERIVED-CONDITION temp inside the loop body: G5 guarantees
// it lowers out of place, so it was never a second mutator of the rail at all.
enum class RailValueUse { NotThisRail, OutOfPlace, Unproven, InPlace };

RailValueUse railValueConsumerDisposition(
    llvm::BinaryOperator *BO, const Value *V, const TaintSet &taint,
    const SmallPtrSetImpl<const Value *> &Claimed) {
  if (inPlaceValueRailOperand(BO, taint) != V)
    return RailValueUse::NotThisRail;
  if (taint.InPlaceRailOps.count(BO) || Claimed.count(BO))
    return RailValueUse::InPlace;
  // G5's own disjunction, asked with the SAME `blockCanRepeat` spelling (which
  // is a strict superset of `LoopInfo::getLoopFor != null`, so one call answers
  // both halves — an irreducible cycle is not a natural loop but still repeats,
  // bd 4p7j / x67f F1).
  if (blockCanRepeat(BO->getParent()))
    return RailValueUse::OutOfPlace;
  return RailValueUse::Unproven;
}

// Peel in-place gates off the front of a value's wire, returning the underlying
// base. Two gate kinds peel (both are in-place mutations of the one rail handle,
// their result RAUWs to the operand at lowering): (1) rotation gates
// (a collected `cq_theta` whose arg-0 handle is tainted — the 7.3 vocabulary), and
// (2, issue dtzb) value rail self-updates (`q = q OP c`, add/xor + classical
// immediate — `inPlaceValueRailOperand`). Parallels
// `TaintPropagation::resolveWireBase` but returns only the base. Stops at a
// classical-operand `cq_theta` (the rail MINT), at any non-gate value (a phi /
// template producer / argument), and at a two-quantum / non-bijection op (a dirty
// rail → X1).
// ONE STEP of that peel: the value `V`'s rail parent, or null when `V` IS the
// base. Split out for bd test_C_libtooling-8h7d.5's round-2 collapse, which must
// ENUMERATE the chain (to mark its in-place value ops and to count fan-out) and
// must do so by walking the IDENTICAL edges `peelInPlaceBase` walks — a
// hand-rolled second walk that took `arg 0` off any call would run PAST the base
// and mark ops that are not on the rail at all, which `lowerOps` would then emit
// as in-place mutations of a register they do not belong to (Rule 14: one
// spelling, asked twice).
//
// TWO READINGS OF THE `BinaryOperator` EDGE, AND `AsLowered` PICKS ONE (bd
// 8h7d.5, Rule-13 round 4 — the third head of finding OD-A). By default the edge
// is the dtzb SHAPE alone: that is the CLAIM-time reading, and it is right for
// every caller that is deciding whether it MAY own a chain, because owning it is
// what makes the op in-place (`tryCaseA`'s `railRoot` fixpoint says the same
// thing about itself, in its own Rule-14 note). `AsLowered` asks the DISPOSITION
// instead — `railValueConsumerDisposition(...) == InPlace` — which is the
// FACT-time reading, for a caller that runs AFTER the marking and is asserting
// "this SSA name IS the register".
//
// Conflating the two is a measured defect, not a hypothetical: `clang -O1`
// canonicalizes `if (q > 5 && q < 20)` inside a loop body to
// `%t = add %q, -6; icmp ult %t, 14`, and `%t` peels to the rail root by SHAPE.
// `markIfRailLocal`'s `onRail` therefore classified a DERIVED-CONDITION TEMP as
// "the register", with two consequences: `AnyLocal` stayed false so the body was
// never certified ITERATION-LOCAL and the uncompute spine's §2.9 acyclic
// backstop LEAKED the whole condition chain once per trip (the rolled trace then
// differs from its hand-unrolled twin's — this increment's load-bearing
// witness); and the temp inherited the rail's EXEMPTION from the escape check,
// which `collectRailGates` — the other spelling of "on this rail" — would never
// have granted it. Two spellings that disagree about one value is finding F-1's
// and F-3's shape a third time; this parameter is how they are made to agree.
Value *peelInPlaceStep(Value *V, const SmallPtrSetImpl<CallInst *> &GateCalls,
                       const TaintSet &taint, bool AsLowered = false) {
  if (auto *CI = dyn_cast<CallInst>(V)) {
    if (!GateCalls.count(CI))
      return nullptr;  // not a collected rotation call — V is the base.
    Value *Handle = CI->getArgOperand(0);
    if (!taint.Tainted.count(Handle))
      return nullptr;  // classical-operand theta: the mint point IS the base.
    return Handle;
  }
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    Value *Base = inPlaceValueRailOperand(BO, taint);  // dtzb self-update, or null.
    if (!AsLowered || !Base)
      return Base;
    // FACT-time: only an op that will really be emitted as `cqrt_{addc,xorc}`
    // keeps the register. `Claimed` is empty — this reading is for callers that
    // run after every claim has been marked, so there is nothing pending.
    SmallPtrSet<const Value *, 1> NoClaim;
    return railValueConsumerDisposition(BO, Base, taint, NoClaim) ==
                   RailValueUse::InPlace
               ? Base
               : nullptr;
  }
  return nullptr;
}

Value *peelInPlaceBase(Value *V, const SmallPtrSetImpl<CallInst *> &GateCalls,
                       const TaintSet &taint, bool AsLowered = false) {
  while (Value *Next = peelInPlaceStep(V, GateCalls, taint, AsLowered))
    V = Next;
  return V;
}

}  // namespace

// bd test_C_libtooling-drbq Increment 3 — `collapseRailPhisIn` step (1)'s
// EXTERNAL-INCOMING claim condition, NAMED so a second caller can ask it.
//
// ONE BODY, TWO CALLERS (Rule 14, and this is the `blockOnCycle` precedent from
// bd drbq Inc 2b's round-1 review): step (1) below asks it of the POST-FLATTEN
// header phi it is about to collapse, and `ArmClassify`'s R7-loop clause (b')
// asks the IDENTICAL question at DETECTION time, before the region is emitted
// and the diamond erased. The reason clause (b') exists at all is row DB of the
// PRD §13.2 partition: a DERIVED out-of-place base (`int r = p * 5;` before the
// loop) makes this test FAIL, step (1) `continue`s, the tainted header phi
// survives the collapse, and the module then declines DOWNSTREAM of emission —
// at `declineClassicalMuxes`, with a message that calls a quantum register a
// classical mux. Asking it at detection turns that into a clean, accurate,
// pre-mutation loud decline.
//
// WHAT IS **NOT** SHARED, stated because it is the one seam: each caller finds
// the phi's EXTERNAL incoming itself. Step (1) spells it `IB == Latch` /
// `else if (!L->contains(IB))` because it needs `LatV` too; this spells it
// `!L->contains(IB)` alone. Under a SINGLE LATCH — which both callers have
// already proved (`collapseRailPhisIn` returns `NotClaimed` without one;
// `ControlDetect::flatRegionRollableInLoop` gate (C) requires one before
// `Region.InLoop` is ever set) — every in-`L` predecessor of the header IS the
// latch, so the two spellings name the same incoming. The LOAD-BEARING half —
// what counts as a peel, and what counts as a clean rail mint — is this one body.
//
// Returns the root mint (a classical-arg-0 `cq_theta` dominating `L`'s header)
// or null. Pure analysis; mutates nothing (Rule 9).
llvm::CallInst *railPhiRootMint(const llvm::PHINode &P, const llvm::Loop *L,
                                const SmallPtrSetImpl<CallInst *> &GateCalls,
                                const TaintSet &taint,
                                const llvm::DominatorTree &DT) {
  auto *NCP = const_cast<PHINode *>(&P);
  if (!taint.Tainted.count(NCP))
    return nullptr;  // classical induction phi — not a rail.
  if (P.getNumIncomingValues() != 2)
    return nullptr;  // multi-entry header phi — leave it (declineClassicalMuxes).
  Value *PreV = nullptr;
  for (unsigned i = 0, e = P.getNumIncomingValues(); i != e; ++i)
    if (!L->contains(P.getIncomingBlock(i))) {
      if (PreV)
        return nullptr;  // two external edges — not the clean latch+entry pair.
      PreV = P.getIncomingValue(i);
    }
  if (!PreV)
    return nullptr;
  // bd `test_C_libtooling-wx8g` — the CLEAN-RAIL-MINT test is now
  // `railChainRootMint` (declared in LoopPlan.h), called here VERBATIM so this
  // function's disposition is byte-unchanged, and called directly by
  // `ArmClassify`'s R7-loop clause (c) for an ITERATION-LOCAL rail, which has no
  // header phi for this function to be asked about. What stays HERE is the
  // POSITION half — the mint dominates the header, i.e. the rail is minted ONCE
  // and crosses the back edge. Clause (c) asks the complementary
  // `L->contains(Mint->getParent())`. Two positions, one mint predicate.
  CallInst *Mint = railChainRootMint(PreV, GateCalls, taint);
  if (!Mint)
    return nullptr;  // not a clean rail mint (a derived out-of-place base).
  if (!DT.dominates(Mint, L->getHeader()))
    return nullptr;
  return Mint;
}

// bd `test_C_libtooling-wx8g` — contract in LoopPlan.h. The clean-rail-mint test
// lifted out of `railPhiRootMint` above. ⚠ TWO defensive conjuncts are NEW and
// both are monotone toward DECLINE, so no accepted module can move: the null
// guard (the direct caller passes a `RotBase` that may be null for a state prep
// whose base is the seed `Constant`) and `arg_size() < 1` (unreachable for a
// collected `cq_theta_*` — `TaintPropagation`'s collection-time prototype
// validation rejects a 0-arg one — but `getArgOperand(0)` on it would be UB,
// and a Release build has no assertion to catch that).
llvm::CallInst *railChainRootMint(llvm::Value *V,
                                  const SmallPtrSetImpl<CallInst *> &GateCalls,
                                  const TaintSet &taint) {
  if (!V)
    return nullptr;
  Value *Root = peelInPlaceBase(V, GateCalls, taint);
  auto *Mint = dyn_cast<CallInst>(Root);
  if (!Mint || !GateCalls.count(Mint) || Mint->arg_size() < 1 ||
      taint.Tainted.count(Mint->getArgOperand(0)))
    return nullptr;  // not a clean rail mint (a derived out-of-place base).
  return Mint;
}

namespace {

// Is `CI` an IN-PLACE rotation gate on its arg-0 handle `H` (a collected
// `cq_theta` whose arg-0 is `H` and tainted)? Such a gate mints no new
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

// Is `CI` a control region's OWN `cq_phi_` arm gate, HOISTED into the pred by
// `SwapRouteEmit` for a controlled-Rz mint? (bd test_C_libtooling-drbq Inc 2a —
// the §6a Rz peephole.) VACUOUS since 3qlq Inc 1 (see the body): nothing hoists
// or mints that gate today, and the paragraphs below are the drbq-era record.
//
// WHY THIS EXISTS, and it is a REPAIR of a structural premise, not a new licence.
// The round-2 fan-out guard's own comment states the premise it runs on: "the
// emitted region stream is NOT counted here and must not be — `cqrt_cswap` /
// `cq_template_*` are not in `GateCalls` … so `isInPlaceGateOnArg0` /
// `inPlaceValueRailOperand` reject them BY CONSTRUCTION". That was true while
// every accepted phase region put its arm gate on a fresh WORK RAIL and erased
// the `@cq_phi`. Inc 2a lowers the same regions CONTROL-IN-PLACE: the `@cq_phi`
// is MOVED to the pred and kept alive (hoist-and-defer), so it is still in
// `GateCalls`, still has the register at arg 0, and the guard started counting
// the region's own gate as a SECOND lineage mutator. MEASURED: 11 accepting
// in-loop fixtures (the whole rolled-Grover family, incl. every `cmp` twin gate)
// flipped to a loud `kMsgRailFanout` whose hand-unrolled twin still compiled —
// the same false-positive SHAPE as the round-4 OD-A finding, one construct over.
//
// WHY EXCLUDING IT IS SOUND, stated as physics and not as convenience. The guard
// refuses Rule-8 fan-out: two in-place mutators reading ONE rail value would both
// serialise onto the collapsed handle (`rz(h,1); rz(h,2)` = Rz(3) where the source
// wanted two registers). A hoisted arm gate is not a second lineage: the region's
// merge φ was RAUW'd to the routed base, so the gate's own RESULT IS DEAD and
// every post-region reader reads the register — the gate is one link in the ONE
// sequence the source wrote, applied to the ONE rail, in program order. It is the
// literal replacement for the route's `cswap; rz(rail); cswap` triple, which this
// guard never counted either, and it is DIAGONAL, so it moves no basis label and
// cannot make any record stale (which is why `collectRailGates` follows a
// `cq_phi` as a rail HOP and not as a gate).
//
// SCOPE, deliberately narrow: membership in `taint.ControlledRotations` is
// written only by an in-place emitter, at emission, for a gate it has already
// fully adjudicated.
//
// ⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L4 finding F-L4-4, a
// PRE-EXISTING defect — all three writers are present in the pre-Inc-4 tree).
// This paragraph and the ⚠ block below both said "the TWO `SwapRouteEmit`
// in-place emitters". THERE ARE THREE WRITERS: `SwapRouteEmit`'s
// `emitInPlaceRotationRegion` (the Inc-1/Inc-4 Ry arm), `SwapRouteEmit`'s
// `emitRegion` (the Inc-2a Rz peephole) and **`AngleSelectEmit`** (Inc 2b, the
// angle select; X-bracket form since bd dm7f.6), which records BOTH STEMS. So an angle-select
// **Rz** entry DOES reach `isHoistedRegionArmGate` — it passes the `cq_phi_`
// test — under an argument written for a different emitter. No consequence for
// Inc 4 (a state-prep entry is keyed on a `cq_theta_` call and the `cq_phi_`
// test refuses it, measured), but the licence below must be read as covering
// three writers, not two. It is NOT a general "ignore this
// rotation" switch — an ordinary in-body `cq_phi`/`cq_theta` is unaffected and
// still counts. Round 1 (`lowerLoops`) can never see a member: it runs BEFORE
// `lowerControlRegions`, so the map is empty and the arm gate is still inside the
// un-flattened arm block; the round-1 call site passes this anyway so the two
// rounds cannot drift apart on the predicate (Rule 14, the OD-A discipline).
//
// ⚠ THE `cq_phi` (Rz) STEM ONLY, AND THE STEM TEST IS THE POINT (bd drbq Inc 2a,
// round-1 review L2 N-2). `taint.ControlledRotations` has **THREE** writers
// (corrected 2026-09-05, lens L4 F-L4-4) — `emitInPlaceRotationRegion` records
// the Inc-1/Inc-4 **Ry** arm (`SwapRouteEmit.cpp`, the `cq_theta` spine),
// `emitRegion` records the Inc-2a **Rz** arm, and `AngleSelectEmit` records the
// angle select's two X-bracket gates at **either** stem — while
// the argument above is DIAGONAL and therefore true of the Rz stem alone. An Ry
// relabels its target on the `f=1` branch: it is a real rail GATE, it CAN make a
// record stale, and the "`collectRailGates` follows it as a HOP" half of the
// argument is simply false of it (`collectRailGates` counts a `cq_theta_` as a
// GATE, at the name test in `noteGate`). Restricting to the stem the proof covers
// costs nothing today — in-loop Ry arms decline before they can reach here (loud
// `control flow inside a loop body` / `condition predates a non-diagonal gate`,
// measured on five shapes: cross-register, second in-place mutator, in-place
// `add`, the `if/else` form, and the out-of-loop control that ACCEPTS) — and it
// stops Inc 3 from INHERITING a licence it was never granted.
//
// ⚠ INCREMENT 3 SHIPPED THE Ry ARM IN A ROLLED LOOP AND DELIBERATELY DID **NOT**
// WIDEN THIS PREDICATE — THE OBLIGATION WAS DISCHARGED BY MECHANISM, NOT BY
// LICENCE (bd test_C_libtooling-drbq Inc 3, PRD §13.4/§13.7). What that obligation
// said is preserved verbatim because it is still the rule for anyone who tries
// again: widening this to `cq_theta_` would be the 8h7d.5 F-1/F-3 shape verbatim —
// TWO INDEPENDENTLY-WRITTEN PREDICATES OVER ONE CLOSURE, this one exempting the
// hoisted gate from the fan-out count while `collectRailGates`' `noteGate` (a
// plain `starts_with("cq_theta_")` name test that never consults
// `ControlledRotations`) would still COUNT it as a rail gate for staleness. Two
// answers for one call.
//
// WHY NEITHER ANSWER HAD TO MOVE. `SwapRouteEmit::emitInPlaceRotationRegion` now
// RAUWs the region's merge φ to the HOISTED GATE rather than to the base (M-β —
// read that site for the two shapes that break under the other convention). So
// under M-β the hoisted `cq_theta` is a CHAIN MEMBER: `%P → T → … → %P`. The
// fan-out count then sees exactly ONE in-place user per rail value **without any
// exemption**, and `noteGate` counts `T` as a relabelling gate **correctly** — an
// Ry genuinely does move the basis, which is the whole reason the Rz argument
// below does not transfer. Two predicates, one closure, one answer, no licence.
//
// ⚠ NARROWING, and it is the premise rather than the conclusion (bd drbq Inc 3,
// round-1 lens L2, L2-F2): "`T` is a chain MEMBER" is true only when `T`'s RESULT
// IS CARRIED around the back edge. When it is not — the region rotates a frozen
// identity-carry φ — `T` joins the closure by the FORWARD extension, so it is in
// `Gates` and in the record set but NOT in `MemberSet`. Nothing breaks today
// because `ArmClassify`'s R6 declines that shape before this file runs (measured,
// lens L2 `s01_frozen_base_region`), but the sentence above is not an invariant
// and must not be quoted as one when R6 moves.
//
// THE `cq_phi_` RESTRICTION THEREFORE STAYS, and it is now load-bearing in the
// other direction: it is what keeps the Rz stem's M-α convention working while the
// Ry stem uses M-β. Retiring `isHoistedRegionArmGate` outright by moving Rz to
// M-β too — leaving ONE emission convention in `SwapRouteEmit` — is filed as
// follow-on `test_C_libtooling-drbq.10`; it touches 26 already-cleared goldens and a stem whose
// current mechanism is *provably* sound (a diagonal gate genuinely is not a rail
// gate), so it is not folded in here. Whoever widens this re-derives the licence;
// nobody inherits it.
bool isHoistedRegionArmGate(const CallInst *CI, const TaintSet &taint) {
  if (!taint.ControlledRotations.count(CI))
    return false;
  const Function *F = CI->getCalledFunction();
  // ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 — the `@cq_phi_<sfx>` family is
  // RETIRED and `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE, so the
  // register-free `void @cq_phi(double)` never reaches here. Kept, not deleted
  // (PRD §6.2 row P6); see the note at `ArmClassify.cpp`'s `isPhiCall` for why
  // widening it would read the wrong operand.
  return F && F->getName().starts_with("cq_phi_");
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

// ── bd test_C_libtooling-8h7d.5, Rule-13 round 1 (finding F1) — THE RAIL-RECORD
//    LIVENESS FENCE. One predicate, asked by BOTH rounds (Rule 14). ──────────
//
// THE INVARIANT IN ONE SENTENCE: an SSA name on a collapsed rail is only a valid
// operand at positions where the physical register still holds the state that
// name denotes.
//
// This is the obligation the two loop rounds share and that round 2 shipped
// without. Collapsing a rail phi RAUWs every member onto ONE handle, so the
// emitted stream reads whatever the wire holds AT THE EMISSION POSITION, while
// the SSA name denotes a fixed prefix of the rail's gate sequence. Inside a loop
// those two disagree the moment ANY rail gate separates them, and the
// disagreement is invisible to every shipped gate:
//
//     for (...) { if (q == 5) q = cq_phi(q, PI); acc = q * 7; q += 3; }
//     return cq_measure(q) + cq_measure(acc);       // (pre-3qlq register form)
//
// `clang -O1` sinks the `mul` past the loop (only `acc`'s last value is read), so
// the emitted `cq_template_mul_i32_hl(%h, 7)` runs after every `cqrt_addc_i32`
// and computes `(q0+3k)*7` where the source says `(q0+3(k-1))*7`. `opt` exits 0,
// `opt -verify` is clean, STRICT stage-2b free-pairing is clean — the shape is
// perfect and only the state is wrong. Round 1 declines the same program (its
// CLOSURE refuses any out-of-rail consumer); round 2 stated that it "deliberately
// does not re-prove COVERAGE/CLOSURE" and collapsed anyway.
//
// AND ROUND 1 HAD ITS OWN HALF OF THE HOLE, older than this increment: its
// CLOSURE admits `isMeasureCall` / `ReturnInst` users of a rail value AT ANY
// POSITION, so `for (…) { last = q; q += off; } return cq_measure(last);` emitted
// `measure(h)` after the loop and measured `q0+3k` for a source that says
// `q0+3(k-1)`. Same defect, same fence, both rounds.
//
// WHY IT IS POSITIONAL AND NOT "NOTHING ESCAPES THE LOOP". Two shapes rule the
// cheap answers out. A blanket "no rail member is read outside `L`" refuses
// `slice_control_grover_loop`'s own `cq_measure(q)` — the customer, and the whole
// point of the increment. A blanket "no rail member has a value-op consumer"
// refuses the region's OWN emitted `cq_template_icmp_eq_i32_hl(%h, 5)`, which is
// a value-op consumer of the very same header phi in every shipped slice. What
// separates the accepts from the miscompiles is neither locality nor consumer
// class — it is whether a rail-relabelling gate runs between the record and the
// read.
//
// THE TEST. For a rail member `v` with definition `D` and a non-member consumer
// reading it at position `p`: FAIL iff some execution path runs `D`, then a rail
// GATE, then `p`, WITHOUT re-executing `D` in between. Re-executing `D` refreshes
// the record (this is the same per-activation reading `WireWalk`'s barrier walk
// takes, spelled as an explicit two-state product walk because the barrier here
// is the record's own definition and the question is about a gate strictly
// between two points, not about a pair).
//
// It gets the asymmetries right for free, which is why it is stated this way:
//   * a pre-loop read of the pre-header chain PASSES (no path from the mint to
//     that read runs a body gate) while a POST-loop read of the same member
//     fails;
//   * the LATCH-carried value read after the loop PASSES (every path from it
//     back to itself re-executes it), which is exactly the customer's
//     `cq_measure(q)`;
//   * a read at the TOP of the body passes; the same read moved below an in-place
//     `addc` fails;
//   * in an UNROTATED loop (`while (c) { gates }`) the header phi read in the exit
//     block PASSES — and correctly, because the exit test runs before that
//     iteration's gates, so the phi's value at the exit edge IS the final state.
//     A rule keyed on "which member is it" could not tell that apart from the
//     rotated shape, where the same read is the miscompile above.
//
// WHICH INSTRUCTIONS COUNT AS GATES. Exactly the ones that relabel the
// computational basis ON THIS RAIL: `cq_theta` (Ry) and the dtzb in-place
// `add`/`xor` (a permutation of the register). An Rz is DIAGONAL and is
// deliberately NOT a gate — the shipped reading of the whole stale-record family
// (WireWalk.h, bd memory rz-diag-flag-strip-invariant); a branch `cq_phi` puts its
// Rz on the flag, so control_swap_inloop_diamond.ll's post-loop read lowers.
// A PHINode is a renaming, not a gate. Gates from a DIFFERENT rail are not
// consulted: they mutate another wire and say nothing about this record (bd
// `hcrg`'s lesson in reverse — fence the unitary, not the bookkeeping).
//
// "ON THIS RAIL" AND NOT "ON THIS CHAIN" — that word is finding F-1 of the SECOND
// Rule-13 round, and it was a CONFIRMED silent miscompile until 2026-08-30. The
// gate set was built from the peeled chain's own members, and a rail is bigger
// than its chain: see `collectRailGates` for the forward extension and for the
// three edge kinds it follows.
constexpr char kMsgRailRecordStale[] =
    "cq loop lowering: rail record read past an in-place gate on the same rail";

// bd `test_C_libtooling-tu9q` clause (ii-d)'s POSTCONDITION — see
// `declineUndischargedExitObligations`. It fires only where clause (ii-d) granted
// a marking on a forecast that `Uncomputation` then did not keep, which is the
// ONE outcome in this area that cannot be absorbed by the Rule-6 leak fallback
// (the marking has already silenced conjunct (1)).
constexpr char kMsgExitObligation[] =
    "cq loop lowering: hoisted invariant rail admitted for in-loop discharge was "
    "not discharged";

// Does re-executing `Def` REFRESH the record — i.e. does the value `Def` produces
// on its next activation name the state the register holds right then? The
// `railGateBetween` walk below cuts every path that re-runs `Def` on exactly that
// premise, so this is the premise's proof (bd 8h7d.5 Rule-13 ROUND 2, finding
// F-2: shipped as an unconditional cut, and one rail shape falsifies it).
//
// A def refreshes iff re-executing it RE-READS THE WIRE. Every in-place gate does
// by construction (it applies its gate to whatever the register currently holds,
// so its result IS the post-gate state), and so does an ordinary rail phi, whose
// carry brings back the value the gates just produced. The one shape that does
// NOT is a phi that carries ITSELF around the loop with no gate on the carry:
//
//     %rec = phi i32 [ %q0, %entry ], [ %rec, %latch ]      ; a ZERO-HOP carry
//
// which step (1) accepts as a rail (`peelInPlaceBase(LatV) == &P` holds
// TRIVIALLY). It re-executes every iteration and yields the SAME value every
// time, so it is a FROZEN alias of the mint — while a sibling chain on the same
// root mint moves the wire underneath it. The cut then suppressed exactly the
// path that carried the staleness, and `%acc = mul %rec, 7` read iteration k's
// register through iteration 0's name (probe `pd1_identity_carry.ll`).
//
// STATED GENERALLY, not as a special case for `In == P`. A carry refreshes only
// if it crosses a rail GATE: an incoming that peels back to the phi itself
// through diagonal / renaming steps only (a re-entrant rename; pre-3qlq also a
// register-form `cq_phi` Rz) is the same frozen record wearing extra phases, and
// a basis-relabelling `cq_theta` or in-place `add`/`xor` on the carry makes it a
// genuine rotating rail (the customer's own header phi: its latch incoming peels
// back through the body `cq_theta`s, so it refreshes and the cut stands).
//
// FROZEN-NESS IS DELIBERATELY NOT PROPAGATED FORWARD, and that is a conclusion,
// not an omission. A gate applied to a frozen record (`%z = cq_theta(%rec, a)`)
// is ITSELF a non-member read of `%rec` at a position where a sibling gate has
// already moved the wire — so the fence declines at `%rec` before any read of
// `%z` is ever reached. The only way `%z` is NOT such a read is when it is a
// chain MEMBER, i.e. when `%rec`'s own carry runs through it, and then `%rec`
// refreshes and there was nothing frozen to propagate.
// ⚠ THAT LAST SENTENCE WAS ROUND 2's ONLY (bd hk9y). Round 1 (`tryCaseA`) passed
// its whole `railRoot` as the skip set, and its fixpoint makes `%z` a member
// WITHOUT `%rec`'s carry running through it; `staleReadOfValue` skipped it and the
// frozen read was never asked (an in-place `xor` reader lowered silently). The
// member skip there then held only for a REFRESHING record; since bd r2j3.13
// round 1 passes only its peeled chains as the skip set, so `%z` is not a
// member at all and the paragraph is true in both rounds by construction.
//
// CONSERVATIVE DIRECTION: answering "no" only ever REMOVES a cut, which only ever
// adds declines, so `false` is the safe default and any shape this cannot classify
// belongs on that side. Every non-phi member is classified, not defaulted: a rail
// member is a phi, an in-place rotation, an in-place `add`/`xor`, or the root mint,
// and each of the last three produces the register state as of its own execution.
// The carry walk terminates for the reason `peelInPlaceBase` does — each step
// ascends the arg-0 / rail-operand def chain, acyclic in SSA, and a phi ends it.
bool recordRefreshedByDef(const Instruction *Def,
                          const SmallPtrSetImpl<CallInst *> &GateCalls,
                          const TaintSet &taint,
                          const SmallPtrSetImpl<const Instruction *> &Gates) {
  const auto *P = dyn_cast<PHINode>(Def);
  if (!P)
    return true;  // an in-place gate: its result is the post-gate register.
  for (Value *In : P->incoming_values()) {
    // Walk the carry back through in-place steps. Reaching `P` without crossing
    // a GATE is a frozen self-carry; crossing a gate first (or landing on some
    // other base) is a real refresh for this edge.
    Value *V = In;
    while (true) {
      if (V == P)
        return false;  // gate-free self-carry — the record never moves.
      if (auto *I = dyn_cast<Instruction>(V))
        if (Gates.count(I))
          break;  // the carry relabels the basis — this edge refreshes.
      Value *Next = peelInPlaceStep(V, GateCalls, taint);
      if (!Next)
        break;  // a different base — not a self-carry.
      V = Next;
    }
  }
  return true;
}

// Is there an execution path `Def` → (some `Gates` member) → `Read` that never
// re-executes `Def`? EXACT two-state product walk over the CFG: the state is
// (block entered at the top, "a gate has fired since `Def`"), which is monotone,
// so each block is scanned at most twice and the walk terminates. `Def`'s own
// block is entered MID-WAY (at `Def`) for the seed scan and is NOT pre-marked, so
// a back edge re-entering it from the top is a genuinely different traversal —
// and one that hits `Def` and CUTS, which is the record refresh.
//
// The cut is CONDITIONAL on `DefRefreshes` (`recordRefreshedByDef` above). Cutting
// is exactly equivalent to RESTARTING the walk at `Def` with `sawGate` cleared,
// which the seed scan already explores — which is why cutting is sound whenever
// the premise holds, and unsound the moment it does not.
//
// Deliberately NOT `llvm::isPotentiallyReachable`: that helper's exclusion set is
// per-BLOCK and it bails `true` past a scan limit, and both endpoints here
// routinely live in the SAME block as the barrier (the flattened loop body is one
// block). The same two reasons `WireWalk::reachesWithoutBarrier` and
// `ControlDetect::regionEntryInLoop` hand-roll their walks.
bool railGateBetween(const Instruction *Def, const Instruction *Read,
                     const SmallPtrSetImpl<const Instruction *> &Gates,
                     bool DefRefreshes) {
  SmallPtrSet<const BasicBlock *, 32> Seen[2];
  SmallVector<std::pair<const BasicBlock *, bool>, 32> Work;
  {  // seed: the tail of `Def`'s own block, from just after `Def`.
    const BasicBlock *B = Def->getParent();
    bool Saw = false;
    for (auto I = std::next(Def->getIterator()), E = B->end(); I != E; ++I) {
      if (&*I == Read && Saw)
        return true;
      if (Gates.count(&*I))
        Saw = true;
    }
    for (const BasicBlock *S : successors(B))
      Work.push_back({S, Saw});
  }
  while (!Work.empty()) {
    auto [B, Saw] = Work.pop_back_val();
    if (!Seen[Saw ? 1 : 0].insert(B).second)
      continue;
    bool Cut = false, S2 = Saw;
    for (const Instruction &I : *B) {
      if (&I == Def && DefRefreshes) {
        Cut = true;  // the record is re-established — a different activation.
        break;
      }
      if (&I == Read && S2)
        return true;
      if (Gates.count(&I))
        S2 = true;
    }
    if (Cut)
      continue;
    for (const BasicBlock *S : successors(B))
      Work.push_back({S, S2});
  }
  return false;
}

// Apply the fence to ONE rail. `Members` is that rail's value set (the chain
// endpoints and everything between, in any order — the predicate needs identity,
// never order) and `GateCalls` the collected `cq_theta` vocabulary.
// Returns the offending CONSUMER (for the `!dbg`-located diagnostic) or null.
//
// A PHI consumer reads its incoming on the EDGE, not in its own block, so its
// read position is the incoming block's TERMINATOR — without that, the `-O1`
// zero-trip guard's exit phi (`phi [PreV, guard], [LatV, latchexit]`, both
// incomings on the rail and both correct on their own edge) would be refused and
// slice_control_grover_loop_dynamic would stop lowering.
//
// THE GATE SET IS THE RAIL'S, NOT THE CHAIN'S (bd 8h7d.5 Rule-13 ROUND 2, finding
// F-1 — shipped reading the chain only, which was a CONFIRMED silent miscompile).
// `Members` is the peeled root→PreV→phi→LatV chain, and a gate can sit on the
// same PHYSICAL register without being on it. The canonical shape is a rotation
// applied to the loop's EXIT value:
//
//     for (…) { if (q==5) q = cq_phi(q,PI); cq_theta(&q,-.5); cq_theta(&q,.5); }
//     int mark = q;  cq_theta(&q, 0.125);   /* arg-0 IS a member, RESULT is not */
//     return cq_measure(mark) + cq_measure(q);      // (pre-3qlq register form)
//
// which emitted `cqrt_ry_i32(%h, 0.125); measure(%h); measure(%h)` — `mark` names
// the pre-Ry record and is measured AFTER it. `opt` exit 0, verify-clean, STRICT
// stage-2b clean. Ry is ALWAYS lowered in place (`lowerRotations` RAUWs the result
// to the handle), so unlike an out-of-place value op there is no escape hatch: the
// wire moves and every earlier name goes stale.
//
// So the rail is extended FORWARD from the chain, through exactly the users that
// keep mutating the SAME handle, and every basis-relabelling one of those is a
// gate. Three edge kinds are followed, and each exclusion is load-bearing:
//
//   * an IN-PLACE ROTATION (`isInPlaceGateOnArg0`) — unconditionally, because
//     `cq_theta` is always lowered in place, and it is a GATE (Ry relabels the
//     basis). The retired register-form `cq_phi` (Rz, diagonal) was followed as
//     a hop but NOT counted as a gate (bd memory `rz-diag-flag-strip-invariant`);
//     that caught `mark = q; q = cq_phi(q,a); cq_theta(&q,b);`, where the Ry's
//     arg-0 is the Rz result and not a chain member (probe g1). `PhiCalls` is
//     empty since 3qlq, so that hop no longer occurs.
//
//   * an in-place VALUE self-update (dtzb `add`/`xor`) — ONLY when it is a chain
//     member or already in `taint.InPlaceRailOps` — the `InPlace` cell of
//     `railValueConsumerDisposition`, which is the ONE spelling of this question
//     (bd 8h7d.5 Rule-13 round 4, OD-A; the fan-out guards and `markIfRailLocal`
//     ask the same predicate and read its `Unproven` cell the OTHER way, each for
//     its own safe direction). Counting an off-chain one would refuse
//     `mark = q; q = q + 9; measure(mark);`, which is CORRECT today because that
//     add lands on a FRESH rail and this register never moves. The walk STOPS
//     there for the same reason — a `cq_theta` on that add's result rotates the
//     fresh rail, not this one.
//
//     PINNED BY TWO FIXTURES, NOT ONE (round-4 correction; this note said
//     "pinned by control_swap_inloop_postloop_railop.ll" as if that were the
//     whole pin). MEASURED 2026-08-30 by disabling BOTH G6 and G7 in
//     `inPlaceFenceHolds` and running all 1293 fixtures: 49 go red, and
//     control_swap_inloop_postloop_railop.ll (this exclusion's accept — the
//     record read that must survive) and control_swap_inloop_postloop_railop_mc.ll
//     (the in-place / out-of-place pair) are both among them. The round-3 note at
//     the G6 site says the `_mc` fixture only reddens when BOTH clauses are
//     relaxed, and that is confirmed and unchanged; what is corrected here is the
//     COUNT of what stands behind the exclusion.
//
//     THAT EXCLUSION IS SOUND ONLY BECAUSE OF M-C's G6/G7 PAIR, AND IT IS A REAL
//     DEPENDENCY ON ANOTHER FILE — stated here because the earlier wording ("an
//     off-chain one is lowered OUT of place by the M-C decision") asserted
//     something MEASURABLY FALSE as if it were unconditional (bd 8h7d.5 Rule-13
//     ROUND 3, bookkeeping item 4). `lowerOps`' M-C in-place reassignment
//     (`classifyInPlaceReassignment`, ArithLowering.cpp) DOES fire post-loop:
//     `for (…) {…} int r = q + 9; return cq_measure(r);` emits
//     `cqrt_addc_i32(%h, 9)` IN PLACE (probe r3h/b4). What keeps the exclusion
//     safe is M-C's position-aware deadness loop — G6 ("no data use AFTER the op",
//     asked POST-RAUW so every rail alias is already unified onto `%h`) and G7 —
//     which refuses exactly when a later record read of the pre-add register
//     exists, so the two dispositions are mutually exclusive: `mark = q;
//     q = q + 9; cq_theta(&q,.25); measure(mark)` falls back to the
//     out-of-place `cq_template_add_i32_hl` (probe r3h/b5). Both are pinned by
//     control_swap_inloop_postloop_railop_mc.ll — and pinned WEAKLY, which is part
//     of the record: measured by mutation, G6 and G7 each refuse that use on their
//     own, so the fixture only reddens if BOTH are relaxed. IF YOU RELAX EITHER,
//     this exclusion becomes an over-accept and must be re-derived HERE first; no
//     test will do it for you.
//
//   * a PHI with SOME incoming already on the rail — a merge that names this
//     register on at least one edge, so a rotation applied to it moves this wire
//     on that edge. `railGateBetween` is an ∃-path test, so "some" (not "all") is
//     the sound side; a phi that also merges a foreign value only ever adds
//     declines. Without it `mark = q; if (n) q = cq_phi(q,a); cq_theta(&q,b);`
//     is missed (probe g3, pre-3qlq register form).
//
// NOT TRANSITIVE PAST THE FIRST GATE, and it does not need to be. If `t2 = t1;
// cq_theta(&t2, …)` with `t1 = m; cq_theta(&t1, …)` and `m` a member, then `Def` (m's
// def) dominates `t1` and `t1` dominates `t2`, so EVERY path from `Def` to `t2`
// crosses `t1`: a `Def`→`t2` path avoiding `t1` could be prefixed by a simple
// entry→`Def` path (which cannot visit `t1`'s block — `Def` dominates it, so the
// path would have to repeat `Def`'s block) to give an entry→`t2` path avoiding
// `t1`, contradicting the dominance. `t1` alone therefore fires the fence at every
// position `t2` would. The forward walk IS still a FIXPOINT, for a different
// reason: the three edge kinds chain (an Rz hop, then a merge phi, then the Ry
// that is the actual gate), and a phi only becomes claimable once one of its
// incomings has joined — which can happen after the phi was first visited.
//
// RULE 14 — WHY THIS IS NOT `tryCaseA`'S `railRoot` FIXPOINT, THOUGH IT LOOKS
// LIKE IT. Round 1 grows a rail forward too (`an in-place gate on a rail value
// joins the SAME rail`, the (a)/(b) fixpoint above `tryCaseA`'s CLOSURE), and the
// question "should these be one spelling?" was asked and answered NO, in this
// round, on the two places they deliberately differ:
//
//   * ROUND 1 follows an off-chain in-place `add`/`xor` UNCONDITIONALLY; this one
//     requires `taint.InPlaceRailOps` (see the second edge kind). Round 1 may:
//     its fixpoint runs BEFORE it marks, and every op it admits it then marks, so
//     "in-place" is a claim it is about to MAKE. Here it is a fact that must
//     already HOLD — a loop reaching round 2 was NOT claimed by round 1, so none
//     of ITS ops carry a mark, and following an unmarked add would refuse the
//     correct `mark = q; q = q + 9; measure(mark)`. (Marks from some OTHER loop's
//     round-1 claim are per-op and simply true, which is why the test is a
//     membership question and not a "has anything been marked yet" one.)
//   * ROUND 1's phi edge needs ALL incomings to peel to one root; this one needs
//     SOME incoming on the rail. Round 1 is building a CLAIM set — a phi merging
//     a foreign value is not a rail it may collapse, so "all" is the sound side
//     there. This is an ∃-PATH staleness witness — one incoming naming the
//     register is one path on which a later gate moves it, so "some" is the sound
//     side here. Each spelling is UNSOUND in the other's job, which is why the
//     union is not available: widening round 1 to "some" would collapse phis it
//     cannot prove, and narrowing this one to "all" silently drops the merge
//     miscompile (lowering_reject_inloop_rail_record_merge_theta.ll).
//
// So two spellings are tolerated, and the pair is PINNED rather than trusted:
// r3g/w1 and r3c/k1 are the SAME C program with and without an in-body tainted
// `if`, i.e. round 1's rail and round 2's, and they ship as
// lowering_reject_loop_rail_record_offchain_theta.ll (round 1, no control) and
// lowering_reject_inloop_rail_record_offchain_theta.ll (round 2). Both must
// decline with the identical message; if the two extensions ever diverge on the
// reach that matters, one of those two fixtures goes red.
//
// `OnRailOut`, when given, receives EVERY value proven to be on this rail — the
// chain members first, in the order they were handed in, then the forward
// extension in discovery order. That out-parameter is finding F-3 of the THIRD
// Rule-13 round, and it is F-1's exact twin one hop out: round 2 widened the GATE
// set to the rail and left the RECORD set at the chain, so a rail value one hop
// off the chain was never asked about (see `staleRailRecordRead`). The order is
// reproducible run-to-run — `Members` arrives in a deterministic order and the
// extension is driven by LLVM use lists, which are construction-ordered, not
// pointer-hashed — which matters because the caller DIAGNOSES from it and a
// wandering `!dbg` location reads as a flaky test later (the same reason
// `tryCaseA` groups its chains in program order).
void collectRailGates(ArrayRef<Value *> Members,
                      const SmallPtrSetImpl<CallInst *> &GateCalls,
                      const TaintSet &taint,
                      SmallPtrSetImpl<const Instruction *> &Gates,
                      SmallVectorImpl<Value *> *OnRailOut = nullptr) {
  // Everything proven to be on this rail — the chain, plus the forward extension.
  SmallPtrSet<const Value *, 32> OnRail;
  SmallVector<Value *, 32> Work;
  for (Value *V : Members)
    if (OnRail.insert(V).second) {
      Work.push_back(V);
      if (OnRailOut)
        OnRailOut->push_back(V);
    }

  auto noteGate = [&](Instruction *I) {
    if (auto *CI = dyn_cast<CallInst>(I)) {
      const Function *Fn = CI->getCalledFunction();
      if (GateCalls.count(CI) && Fn && Fn->getName().starts_with("cq_theta_"))
        Gates.insert(CI);  // Ry — relabels the basis.
    } else if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      if (inPlaceValueRailOperand(BO, taint))
        Gates.insert(BO);  // dtzb `cqrt_{addc,xorc}` — a basis permutation.
    }
  };

  for (Value *V : Members)
    if (auto *I = dyn_cast<Instruction>(V))
      noteGate(I);

  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || OnRail.count(I))
        continue;
      bool OnThisRail = false;
      if (auto *P = dyn_cast<PHINode>(I)) {
        if (!taint.Tainted.count(P))
          continue;  // a classical merge cannot be this register.
        for (Value *In : P->incoming_values())
          if (OnRail.count(In))
            OnThisRail = true;
      } else if (auto *CI = dyn_cast<CallInst>(I)) {
        OnThisRail = isInPlaceGateOnArg0(CI, V, GateCalls, taint);
      } else if (auto *BO = dyn_cast<BinaryOperator>(I)) {
        // `InPlace` ONLY. THE MECHANICS FIRST, BECAUSE THE OLD WORDING HERE READ
        // AS A LIVE CHOICE AND IS NOT ONE (bd 8h7d.5, Rule-13 round-5 cleanup).
        // `Claimed` is EMPTY at this site, and with an empty claim set
        // `railValueConsumerDisposition(...) == InPlace` reduces IDENTICALLY —
        // not conservatively, not approximately — to the predicate this line
        // spelled by hand before OD-A:
        //     `inPlaceValueRailOperand(BO, taint) == V &&
        //      taint.InPlaceRailOps.count(BO)`
        // (read the enum: a shape mismatch is `NotThisRail`, and the only other
        // route to `InPlace` is `Claimed.count(BO)`, which is vacuous here). So
        // this is a Rule-14 respelling with ZERO behaviour change, and "the
        // `Unproven` cell is deliberately not followed" was describing a cell
        // that the old spelling did not reach either. The empty `Claimed` is
        // correct on its own terms: this walk has no marking of its own to
        // anticipate — the chain members it would name are already seeded into
        // `OnRail` before the walk starts.
        //
        // NOW THE POLICY, WHOSE HAZARD DIRECTION IS THE OPPOSITE OF THE FAN-OUT
        // GUARD'S — which is the part worth knowing and the part the old comment
        // flattened into "each direction is the safe one for its own question".
        // There, a missed `Unproven` mutator is a missed DECLINE, so that guard
        // counts the cell. HERE the gate set feeds `staleReadOfValue`'s
        // staleness fence, so a MISSING gate is an OVER-ACCEPT — the
        // unforgivable direction (Prime Directive). `InPlace`-only is therefore
        // load-bearing, and it rests on a proof rather than on symmetry: M-C's
        // G6/G7 pair refuses any in-place reassignment site that has a later
        // record read (round 3, bookkeeping 4), so an `Unproven` BO can never be
        // the gate this fence would have needed. If G6/G7 is ever relaxed, the
        // obligation is to re-derive THIS argument here — not to reflexively
        // widen the cell to `>= Unproven`, which would be a real behaviour change
        // with no measured customer.
        SmallPtrSet<const Value *, 1> NoClaim;
        OnThisRail = railValueConsumerDisposition(BO, V, taint, NoClaim) ==
                     RailValueUse::InPlace;
      }
      if (!OnThisRail)
        continue;
      OnRail.insert(I);
      Work.push_back(I);
      if (OnRailOut)
        OnRailOut->push_back(I);
      noteGate(I);
    }
  }
}

// bd `test_C_libtooling-dm7f.7` — does a rail gate run between `Def` and a point
// where a control emitter re-reads the register through compare `C`? The
// control uses are the terminators (`br`/`switch`) and tainted-condition
// `select`s reached from `C` through i1 logic (`and`/`or`/`xor`, i1 `select`),
// i.e. where a flag minted from `C`'s operands is minted. Data uses (a `zext`,
// an arithmetic consumer) keep the read at `C` and are not followed.
bool railGateBeforeControlUse(const Instruction *Def, const CmpInst *C,
                              const SmallPtrSetImpl<const Instruction *> &Gates,
                              bool DefRefreshes) {
  SmallVector<const Value *, 4> Work{C};
  SmallPtrSet<const Value *, 8> Seen{C};
  while (!Work.empty()) {
    const Value *V = Work.pop_back_val();
    for (const User *U : V->users()) {
      const auto *I = dyn_cast<Instruction>(U);
      if (!I || !Seen.insert(I).second)
        continue;
      if (isa<BranchInst>(I) || isa<SwitchInst>(I) ||
          (isa<SelectInst>(I) && cast<SelectInst>(I)->getCondition() == V)) {
        if (railGateBetween(Def, I, Gates, DefRefreshes))
          return true;
        if (!isa<SelectInst>(I) || !I->getType()->isIntegerTy(1))
          continue;  // a terminator or a data select: the read stops here.
      }
      if (!I->getType()->isIntegerTy(1))
        continue;
      if (isa<SelectInst>(I) ||
          (isa<BinaryOperator>(I) &&
           (I->getOpcode() == Instruction::And ||
            I->getOpcode() == Instruction::Or ||
            I->getOpcode() == Instruction::Xor)))
        Work.push_back(I);
    }
  }
  return false;
}

// ONE rail value against a precomputed gate set. Split out so the step-(5) phi
// fixpoint can ask it AFTER step (4) has erased the header phi — the gates
// themselves survive that erase, the members do not.
Instruction *staleReadOfValue(Value *V,
                              const SmallPtrSetImpl<const Value *> &Members,
                              const SmallPtrSetImpl<const Instruction *> &Gates,
                              const SmallPtrSetImpl<CallInst *> &GateCalls,
                              const TaintSet &taint) {
  auto *Def = dyn_cast<Instruction>(V);
  if (!Def)
    return nullptr;
  // Asked ONCE per record: whether re-executing this def re-reads the wire is a
  // property of the def, not of the consumer (bd 8h7d.5 Rule-13 round 2, F-2).
  const bool Refreshes = recordRefreshedByDef(Def, GateCalls, taint, Gates);
  // ── THE MEMORY HOP FOR THIS FENCE (bd `xdu2.1`, Rule-13 round-2 finding F-1,
  //    2026-09-24 — a P1 OVER-ACCEPT, the bd `3d8q` class through memory again).
  //
  // A rail value PARKED in a rail bank is READ at the bank's cell LOADS, not at
  // the `store` that parks it — the store is only where the name enters memory.
  // Asking the store alone (the generic user loop below) is asking the wrong
  // instruction: the park precedes the loop, so no gate lies between `Def` and
  // it, and the fence passed a program whose bank measures observe the rail
  // AFTER this loop's in-place relabel —
  //   `int b[n]; for(i) b[i]=q; for(k){ if(q>k) cq_phi(.3); q ^= 3; }
  //    for(i) s+=cq_measure(b[i]);`
  // emitted `ry(h0); …; cqrt_xorc_i32(h0,3) x n; measure(h0) x n+1` (exit 0,
  // STRICT 2b clean) while its register spelling `c=q; …; cq_measure(c)`
  // declines here with `kMsgRailRecordStale` (review probes
  // `reviewB_r2/P1_bank.c` / `P1_reg.c`; twin pair `p13`).
  //
  // So every cell load of every bank `V` is parked in is asked the SAME
  // question with the SAME walk as an SSA read would be — but WITHOUT the
  // `Refreshes` cut (corrected by Rule-13 round 3, F-R3-1: the round-2 text
  // here said "the SAME `Refreshes` bit", and that was the P1; see the call
  // below). `railBankCellReadsOf` is
  // the forward hop (`railBankParkedRails`) read backwards over the same address
  // tree and the same `bankStoreRailValue` relation (Rule 14). It is a
  // DECLINE-direction addition: it only adds read points, never removes one.
  //
  // ⚠ WHY HERE AND NOT (ONLY) IN THE READER FENCE'S HOP. `recordStaleQuantumReaders`
  // runs BEFORE `lowerLoops` and walks for `cq_theta_` gates; the in-place
  // `add`/`xor` this collapse commits (`markInPlaceRailOp`, just after this
  // fence at its round-2 call site) does not exist as a gate when that fence
  // runs. This fence is asked at the site that is about to commit the relabel,
  // with the relabel already in `Gates` (`collectRailGates` counts it) — the
  // L1 cure's "ask at the site that asks" rather than a prediction elsewhere.
  // The other in-place minters for a parked rail are enumerated in
  // `TRACK_B.md` §6b with what refuses each.
  {
    SmallVector<LoadInst *, 4> CellReads;
    if (railBankCellReadsOf(V, CellReads))
      for (LoadInst *LD : CellReads)
        // ⚠ `DefRefreshes=false`, NOT `Refreshes` (Rule-13 round 3, F-R3-1 —
        // a P1 that the first spelling of this hop, passing `Refreshes`, let
        // through). The refresh cut says "re-running `Def` makes the NAME
        // denote the new value", which is true of an SSA name and FALSE of a
        // memory cell: cell k keeps the value activation k wrote while later
        // activations re-run `Def` and relabel the wire. With the cut, a park
        // AFTER an in-place op in the same loop —
        //   `for(k){ if(q>k) cq_phi(.3); q ^= 3; b[k] = q; }
        //    for(i) cq_measure(b[i]);`
        // — had every `Def → back edge → gate` path cut at the next `Def`,
        // left `Def → exit → load` gate-free, and ACCEPTED a stream in which
        // every cell reads the FINAL wire (`reviewB_r3/a1_park_after_xor.c`;
        // its hand-unrolled register twin emits the correct out-of-place
        // stream). A re-executed in-place `Def` is therefore a GATE on the
        // parked wire, never a refresh of the cell (L2: the refresh cut is the
        // other set computed over the same closure). Decline-only: `false`
        // can only find more paths.
        if (railGateBetween(Def, LD, Gates, /*DefRefreshes=*/false)) {
          // Name the consumer the register spelling's diagnostic names (the
          // measure), falling back to the load when it has no single reader.
          if (LD->hasOneUse())
            if (auto *R = dyn_cast<Instruction>(*LD->user_begin()))
              return R;
          return LD;
        }
  }
  for (User *U : V->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      continue;
    // bd `test_C_libtooling-g35c` (P1, a silent miscompile on main) — a MEMBER φ
    // IS a read, on each incoming edge, and the skip below no longer reaches it.
    //
    // The skip says "a chain member's own execution is the rail moving, not a
    // read", which is true of an in-place gate and FALSE of a φ: a φ moves
    // nothing, it SELECTS a record per edge, and once the collapse RAUWs it to
    // the root every reader of it reads the CURRENT rail. `tryCaseA` handed this
    // function its whole `railRoot` as `Members` (its peeled chains since bd
    // r2j3.13), and its (b) fixpoint admits any φ whose incomings all peel to the
    // root, so the loop's zero-trip exit φ `phi [%pre, guard], [%post, latch]`
    // was a member, its guard edge carried a PRE-gate name past a gate, and
    // nothing asked it:
    //     `int z = r; cq_theta(&r, .3); for (i < n) { cq_theta(&r, .1); z = r; }
    //      z ^= 1; return cq_measure(z);`
    // emitted `ry(h,.3); xorc(h,1); measure(h)`, which on n == 0 measures the
    // POST-gate rail where the source measures the pre-gate record (its
    // straight-line spelling declines). `lowering_reject_loop_rail_record_zero_
    // trip_merge.ll`; the angle-select and `ret` spellings are
    // `control_angle_select_reject_forward_rail_cycle_zero_trip_{stale,ret}.ll`.
    //
    // So the φ edge test below runs for every φ, member or not (one exception,
    // the member's self edge, at the end of this note). It cannot refuse
    // the shipped exit φ (`phi [PreV, guard], [LatV, latchexit]`, both correct on
    // their own edge, the note on `staleRailRecordRead`): no rail gate lies
    // between `PreV` and the guard's branch, or between `LatV` and the latch's.
    // This NARROWS the skip set (L2): it only adds questions, so it can only add
    // declines. The NON-φ member skip is unchanged. Both rounds share this
    // function; round 2's member φ is the header φ, whose two edges carry `PreV`
    // and `LatV` and pass the same way. Round 2 was not open to the hole itself:
    // its `Members` are the chain only, so the exit φ is a NON-member user of the
    // chain's pre-gate name and was always asked (measured with this change
    // reverted: the in-body-`if` spelling of the program below declines there).
    //
    // ONE EDGE STAYS SKIPPED: a member φ's SELF edge (`UI == V`, the identity
    // carry `phi [%x, pre], [%self, latch]`). That edge carries the φ's own
    // record, nothing from outside it, so it launders no other name; whether
    // that record is still current where it is READ is asked of each of the φ's
    // readers instead (with `Refreshes` false for a frozen carry), including a
    // MEMBER gate on it since bd hk9y (next note). Asking the self edge as well
    // was MEASURED to move `lowering_reject_loop_nested_quantum.ll` — a dead
    // identity carry of a rail the OUTER loop re-mints, which has no reader — off
    // its subject's diagnostic (FreePoint's back-edge reject) onto this one,
    // because the walk counts the re-executed root mint as a gate.
    //
    // bd `test_C_libtooling-hk9y` (silent on main, hand IR) — A MEMBER GATE ON A
    // RECORD THAT DOES NOT REFRESH IS A READ TOO. The non-φ skip below rests on
    // "a member's execution is the rail moving": its operand is the record the
    // chain just produced, so it cannot be stale. That holds for ROUND 2, whose
    // `Members` are the CHAIN (an in-place gate is a member only when the φ's own
    // carry runs through it, and then the φ refreshes). It was FALSE for ROUND 1
    // while its `Members` were `tryCaseA`'s whole `railRoot` (until bd r2j3.13,
    // below; the refresh condition is now defence in depth): the (a) fixpoint absorbs
    // every in-place op on a rail value, including one on a zero-hop identity
    // carry that a sibling chain on the same root moves the wire under —
    //     `%rec = phi [%t, entry], [%rec, loop]; %z = xor %rec, 5;
    //      cq_measure(%z); %g = cq_theta(%p, .1)`   (`%p` the moving header φ)
    // emitted `xorc(h,5); measure(h); ry(h,.1)` per trip: the xor lands on the
    // rail for good, and from trip 2 on it reads iteration 0's record through a
    // frozen name. That is `lowering_reject_inloop_rail_frozen_gate_first.ll`'s
    // shape in round 1, the regression its header warns of (a rail-wide skip set
    // deletes the read that proves the record frozen). So a member gate is
    // skipped only when its record REFRESHES; on a frozen record it gets the
    // positional test like any reader.
    //
    // ⚠ CORRECTED (bd `test_C_libtooling-r2j3.13`, P1, silent on main). This note
    // used to end "a refreshing record's member gate is not re-asked: the
    // round-1 escapes of a moved wire past a refreshing name surface on a φ edge
    // (g35c) or at the pre-`lowerLoops` fences". FALSE: an op the (a) fixpoint
    // absorbed OFF the chain reads its operand at its OWN position, and the root
    // mint always refreshes. `int z = q; for (…) { q += 1; s += cq_measure(q); }
    // z += 5; return s + cq_measure(z);` absorbed `add %root, 5`, skipped it here
    // and emitted `addc(h,5)` after the body's `addc(h,1) x n` (the source's
    // q0 + 5 measured as q0 + n + 5); no Ry on the wire, so the pre-pass saw
    // nothing. Since r2j3.13 round 1 passes its PEELED CHAINS as this skip set
    // (`staleRailRecordRead`'s `Skip`), so an off-chain absorbed op is a
    // non-member reader and is asked; `Members` is the skip set in BOTH rounds
    // now, and the hk9y refresh condition above guards the chain's own frozen
    // carries. Pinned by `lowering_reject_loop_rail_offchain_alias_add.ll` and
    // `loop_caseA_postloop_compare_reject_offchain_alias.ll`.
    if (Members.count(UI) && (isa<PHINode>(UI) ? UI == V : Refreshes))
      continue;  // the chain itself — its own gates are the rail, not a read.
    if (auto *P = dyn_cast<PHINode>(UI)) {
      for (unsigned i = 0, e = P->getNumIncomingValues(); i != e; ++i)
        if (P->getIncomingValue(i) == V &&
            railGateBetween(Def, P->getIncomingBlock(i)->getTerminator(), Gates,
                            Refreshes))
          return P;
      continue;
    }
    if (railGateBetween(Def, UI, Gates, Refreshes))
      return UI;
    // bd `test_C_libtooling-dm7f.7` — A COMPARE IS ALSO READ WHERE ITS FLAG IS
    // MINTED. Every control emitter (kickback, value merge, abort park, condition
    // tree, the 4.4 select) mints the flag at the BRANCH or SELECT the compare
    // drives, not at the compare, so the register is read again THERE. A rail
    // gate between the compare and that point leaves the flag minted from a
    // moved register (`int c = q > 5; if (k > 3) q ^= 3; if (c) abort();` after
    // a Case-A loop: the compare is fresh, the park's mint is not). Asked of each
    // control use reached through i1 logic, with the same walk; the compare is
    // named (the read the source wrote). Decline-only: it adds read points.
    if (auto *C = dyn_cast<CmpInst>(UI))
      if (railGateBeforeControlUse(Def, C, Gates, Refreshes))
        return UI;
  }
  return nullptr;
}

// THE RECORD SET IS THE RAIL'S, THE SKIP SET IS THE CHAIN'S — and they are two
// different sets on purpose (bd 8h7d.5 Rule-13 ROUND 3, finding F-3; another
// CONFIRMED silent miscompile, and F-1's exact twin one hop out).
//
// Round 2 widened `collectRailGates`'s GATE set from the chain to the whole rail
// and left the RECORD loop — the values this fence asks "is any read of you
// stale?" — enumerating chain `Members`. A rail value ONE HOP off the chain was
// therefore never asked about, and this `clang -O1` C program miscompiled (pre-3qlq
// register form):
//     for (i<2) { if (q==5) q=cq_phi(q,PI); cq_theta(&q,-.5); cq_theta(&q,.5); }
//     int a = q; cq_theta(&a, 0.125);  /* arg-0 IS a member — the RESULT is not */
//     int b = a; cq_theta(&b, 0.25);  /* a rail gate AFTER the record `a` */
//     return cq_measure(a) + cq_measure(b);
//
// emitting `ry(h0,.125); ry(h0,.25); measure(h0); measure(h0)` — `a` names the
// pre-`b` register and is measured after `b`. `opt` exit 0, verify-clean, STRICT
// stage-2b clean. So the loop below runs over `RailValues`, the rail's own closure.
//
// THE TWO SETS MUST NOT BE UNIFIED, and a fixture pins the difference. The SKIP
// set answers "whose own in-place execution IS the wire moving?" — a chain member's
// gate is the rail advancing, not a read of it. The RECORD set answers "which SSA
// names denote a state of this rail?" — every value on it, chain or extension.
// Widening the skip set to the rail too was measured and REGRESSES
// lowering_reject_inloop_rail_frozen_gate_first.ll from a decline to an accept: a
// `cq_theta` applied to a FROZEN identity-carry record joins the rail by the
// extension's first edge kind, and skipping it as a "rail step" deletes exactly
// the read that proves the record frozen (round 2's F-2 argument depends on that
// read being visible — see `recordRefreshedByDef`).
//
// `Skip`, when given, REPLACES `Members` as the skip set (bd r2j3.13). Round 2's
// `Members` already are its peeled chains, so it passes nothing. Round 1's are
// its whole `railRoot`, which also holds every op the (a) fixpoint absorbed OFF
// the chain (a post-loop `add %root, 5` on a pre-loop alias), and skipping those
// as "the rail moving" let them read a moved register unasked (silent on main).
// So round 1 passes its peeled chains here and keeps `Members` as the GATE seed:
// an absorbed op is still a gate on this rail, it is just also a read.
Instruction *staleRailRecordRead(ArrayRef<Value *> Members,
                                 const SmallPtrSetImpl<CallInst *> &GateCalls,
                                 const TaintSet &taint,
                                 const SmallPtrSetImpl<const Value *> *Skip =
                                     nullptr) {
  SmallPtrSet<const Value *, 16> MemberSet;
  if (Skip)
    MemberSet.insert(Skip->begin(), Skip->end());
  else
    MemberSet.insert(Members.begin(), Members.end());
  SmallPtrSet<const Instruction *, 8> Gates;
  SmallVector<Value *, 32> RailValues;
  collectRailGates(Members, GateCalls, taint, Gates, &RailValues);
  if (Gates.empty())
    return nullptr;
  // NOTE, so the next reader does not mis-read that early-out as "the pure-Rz rail
  // exits here". It does not. An accepted rail's chain contains its ROOT MINT, and
  // taint has exactly one source (Rule 3), so the mint is a `cq_theta` and `Gates`
  // holds at least it. A pure-Rz loop body therefore reaches the walk below and
  // passes it on POSITION: the mint sits outside the loop and is never re-reachable,
  // so no `Def → gate → read` path exists
  // (control_swap_inloop_{diamond,gatefree_body}.ll). The early-out is a defensive
  // guard for a chain that somehow carries no gate at all, not the diagonal case.
  //
  // `RailValues` leads with `Members` in the order the caller handed them in, so
  // the offender named for an already-declining program is the one round 2 named:
  // the extension is only ever reached when no chain member's read is stale.
  for (Value *V : RailValues)
    if (Instruction *Bad = staleReadOfValue(V, MemberSet, Gates, GateCalls, taint))
      return Bad;
  return nullptr;
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
    if (isTaintedBranchTerminator(T, taint))  // bd dm7f.24: the one spelling.
      return T;
  }
  return nullptr;
}

}  // namespace

// ─────────────────────────────────────────────────────────────────────────────
// bd `test_C_libtooling-zujr` — THE LOOP-CARRIED HANDLE VARIABLE.
//
// THE THIRD KIND OF LOOP-CARRIED REGISTER, and it is the owner's rolled cascade:
//
//     int a = 5; bool b0[3];
//     for (int i = 0; i < 3; ++i) { if (a >= 3) cq_theta(&b0[i], .5);
//                                   if (b0[i]) a -= 3; }
//
// After `clang -O1` the second `if` is if-converted into a 4.4 DATA SELECT and
// `a` is a header φ whose ENTRY incoming is the constant `5` and whose LATCH
// incoming is that select's merge output:
//
//     %a  = phi i32 [ 5, %entry ], [ %merge, %latch ]
//     %a3 = add nsw i32 %a, -3
//     %merge = select i1 %rail, i32 %a3, i32 %a
//
// It is NEITHER of the two kinds the loop layer already knows:
//   * NOT (b)/(b′), the rail that crosses the back edge IN PLACE — the latch
//     incoming does not peel back to the φ (`collapseRailPhisIn`'s closed
//     self-cycle), because `SelectMergeEmit` mints a FRESH `%out = cqrt_alloc_<W>`
//     per activation and RAUWs the merge onto it. `ControlDetect.cpp` already
//     says so in words for the value arm: *"the loop-carried register is a
//     different handle every trip"*.
//   * NOT (c), the ITERATION-LOCAL rail — it manifestly crosses the back edge and
//     its exit value is the program's answer (`cq_measure(a)`).
//
// It is a LOOP-CARRIED HANDLE VARIABLE: a register that crosses the back edge AND
// is re-minted every trip. THE RUNTIME NEEDS NOTHING — a handle is an `i32` and a
// loop-carried `i32` whose φ is selected by CLASSICAL loop control is ordinary
// classical data. The only thing missing from the module is the TRIP-1 register:
// the entry incoming is a classical literal, not a handle, so trip 1 would pass
// `5` where every gate wants a handle. That is what `promoteLoopCarriedHandleSeeds`
// materialises, and it is the owner's ruling of 2026-09-17 (bd memory
// `owner-ruling-loop-carried-handle-2026-09-17`): *"trip-1 PROMOTION accepted —
// materialise `cqrt_alloc_<W>(entry value)` in the preheader … slightly less
// efficient is fine"*. The FLAT twin already does exactly this, as the
// `cqrt_alloc_i32(5)` copy source inside its trip-1 mux.
//
// THE PER-TRIP UNITARY ARGUMENT (Rule 2 — analytic, there is no simulator). Let
// `a_0` be the preheader `cqrt_alloc_<W>(C)` = |C⟩ and `a_k` the register the φ
// names on trip k. Each activation emits, on the ORIGINAL register `a_{k-1}`:
//   (1) a which-path flag built by a reversible template and STRIPPED back to
//       |0⟩ before its free (`a_{k-1}` is not written, so the strip's premise
//       holds);
//   (2) whatever gates the region's own emitter is cleared for;
//   (3) the arm's pure chain on `a_{k-1}` (here `h_op = a_{k-1} − 3`), a fresh
//       rail LEFT ALLOCATED — the 3qlq Inc-2 PRD §0 E1 policy;
//   (4) `a_k = cqrt_alloc_<W>(0)` and the two X-bracketed
//       `cqrt_copy_<W>_controlled`, which write `a_k` once per basis branch and
//       leave `a_{k-1}` untouched.
// So `a_k = flag ? h_op : a_{k-1}` on every basis branch — gate for gate what
// copy k of the hand-unrolled program emits. `a_{k-1}` and `h_op` are left as
// which-path records, which is EXACTLY what the flat twin leaves (measured: 6
// undischarged rails in each form; the flat form's are 2 template + 4 alloc
// because `-O1` const-folds its first two trips, the rolled form's 3 + 3).
//
// ⚠ BYTE-IDENTITY WITH THE HAND-UNROLLED TWIN IS AN INSTRUMENT HERE, NOT THE
// TARGET, and that is the owner's ruling (2): `clang -O1` stamps
// `llvm.loop.unroll.disable` and does not peel, so the rolled form emits a REAL
// compare + strip on EVERY trip, while `-O1` folds the flat twin's trip-1 compare
// to `true` and its trip-2 compare to `!b0[0]`. Same unitary, different bytes. The
// witness is this argument plus a QUARANTINED divergence carrying it.
//
// PURE ANALYSIS; mutates nothing (Rule 9). Asked at FIVE slots over two taint
// sets, which is why it is ONE function and never a second spelling (Rule 14):
//   * `iterationLocalTaintEscape`  — R7-loop clause (c3) / conjunct 1;
//   * `tryCaseA`                   — X1, ROUND 1, pre-emission;
//   * `collapseRailPhisIn`         — X1, ROUND 2, post-emission;
//   * `invariantRegisterRootsImpl` — clause (i), the marking premise, reached
//                                    from `lowerLoops` (ROUND 1);
//   * the SAME clause (i) (and `railLocalQualifies`' header-φ exemption) reached
//     a SECOND time from `declineRound2FalsifiedRailGrants`' re-derivation —
//     FINAL taint, AFTER `promoteLoopCarriedHandleSeeds` and AFTER
//     `declineClassicalMuxes`. ⚠ This fifth slot was missing from this list
//     until xdu2.16's Rule-13 round r1A (F-A1-5). It existed before xdu2.16 in
//     the intact-grant path, where its answer could only ADD to a union with the
//     round-1 roots; since bd `test_C_libtooling-xdu2.16`, for a grant with a
//     NULLED root it is the SOLE source of the carried chain in the fresh root
//     set. It runs on the post-promotion IR (the φ already retyped to the `i32`
//     handle ABI, its latch incoming the merge `%out`), and was measured to answer
//     correctly there (r1A: the fresh roots include the retyped φ and `%out`).
// SCOPE_L1a: the two X1 sites MUST move together or round 2 re-declines what
// round 1 accepted.
//
// ⚠ THE PREDICATE IS DELIBERATELY NOT THE WHOLE PROOF. Two of its five slots run
// at ROUND-1 taint, BEFORE any merge emitter has run, where `ControlOwnedRails`
// is necessarily empty — so clause (Z6) answers by SHAPE there and by the RECORD
// everywhere else. `promoteLoopCarriedHandleSeeds` asks the record at FINAL taint
// and is the ONLY granter of the `declineClassicalMuxes` accept, so a φ this
// predicate admits but the promotion refuses reaches that guard UNPROMOTED and
// DECLINES LOUDLY.
//
// ⚠ "THE SHAPE HALF ONLY EVER DEFERS" IS THE WRONG SENTENCE AND IT IS CORRECTED
// HERE RATHER THAN REPEATED (Rule-13 round 1, F-4). TWO of the first four sites
// DEFER and TWO GRANT (the fifth RE-ASKS a grant; see the last paragraph), and a
// future widening will lean on knowing which:
//
//   DEFER — nothing is permitted, a later owner still speaks:
//     * `tryCaseA`'s X1 (round 1): `return false` leaves the loop unclaimed;
//     * `collapseRailPhisIn`'s X1 (round 2): `continue` leaves the φ.
//   GRANT — a permission is handed out on round-1 evidence:
//     * `iterationLocalTaintEscape` via R7-loop clause (c3): removing an escape
//       lets the REGION through `classifyArms`;
//     * `railLocalQualifies`' header-φ exemption + `invariantRegisterRootsImpl`
//       clause (i), via `lowerLoops`: they grant `markIfRailLocal`, i.e. the
//       SPINE's in-body discharge permission.
//
// WHAT BACKSTOPS THE GRANTS, and it is ONE thing: every path from either grant to
// an emitted module still passes the promotion's record half and then
// `declineClassicalMuxes`, one stage later. The residual escapes from that
// backstop are a `use_empty()` φ (no reader, no mux) and `liftOneRegisterMergePhi`
// succeeding on a header φ — which that function documents itself as refusing for
// "loop-reachable merges". Neither was constructible in the Rule-13 round; both
// are where a widening must look first.
// ⚠ THE FIFTH SLOT IS NOT BACKSTOPPED BY THAT PAIR — it runs after both. It is a
// RE-ASK of a grant the round-1 slot already made (never a new grant of its own),
// so the φ it sees has already been through the promotion and the mux guard; its
// answer only decides whether the xdu2.16 re-derivation is TOTAL, and a `false`
// there is a loud DECLINE (`kMsgRound1GrantFalsified`), never a withdrawal.
// bd `test_C_libtooling-zujr` clause (Z6) — WILL THIS VALUE BE A CONTROL-MERGE
// `%out` RAIL? Contract at the clause. Pure analysis.
static bool latchIsControlMergeRail(Value *LatV, const TaintSet &taint) {
  if (taint.ControlOwnedRails.count(LatV))
    return true;  // POST-emission: the merge emitters' own record (Rule 14).
  // PRE-emission (round-1 taint): the SHAPE those emitters claim. `clang -O1`
  // if-converts `if (b) a -= 3;` to a tainted-condition `select` (the 4.4 data
  // select); when it does not, the diamond survives as a merge φ whose block has
  // a tainted-condition conditional branch among its predecessors' terminators.
  // DEFER-ONLY — see the clause.
  if (auto *SI = dyn_cast<SelectInst>(LatV))
    return taint.Tainted.count(SI->getCondition()) != 0;
  if (auto *MP = dyn_cast<PHINode>(LatV))
    for (BasicBlock *PB : predecessors(MP->getParent()))
      if (auto *BI = dyn_cast<BranchInst>(PB->getTerminator()))
        if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
          return true;
  return false;
}

std::optional<CarriedHandleProof> loopCarriedHandlePhi(
    PHINode &P, const Loop *L, const TaintSet &taint,
    const SmallPtrSetImpl<CallInst *> &GateCalls) {
  // (Z1) A REDUCIBLE, SINGLE-LATCH LOOP WITH A REAL PREHEADER. The preheader is
  //      where the promotion has to put the `cqrt_alloc`, and "there is a block
  //      that runs exactly once per ENTRY to the loop, immediately before the
  //      header" is precisely what `getLoopPreheader()` answers.
  //      ⚠ IT IS NOT WHAT HANDLES THE ZERO-TRIP GUARD, and an earlier wording
  //      here said it was (Rule-13 round 1). `clang -O1` gives a ROTATED loop
  //      `entry -> for.body.preheader -> header`, and that preheader has ONE
  //      successor, so `getLoopPreheader()` returns it happily. The guard is
  //      (Z8)'s subject: the alloc in that preheader is BYPASSED on the zero-trip
  //      edge, which is a statement about the loop's READERS, not about whether
  //      a preheader exists. MEASURED on `loop_carried_handle_reject_guarded.ll`,
  //      whose mutant matrix kills it on (Z8) and on nothing else.
  if (!L || !L->getLoopLatch() || !L->getHeader())
    return std::nullopt;
  BasicBlock *Latch = L->getLoopLatch();
  // bd `test_C_libtooling-h1ip` — THE LOOP'S SINGLE EXTERNAL ENTRY BLOCK, which
  // is the PREHEADER when there is one and the GUARD BLOCK ITSELF when there is
  // not.
  //
  // ⚠ BOTH THE ORIGINAL (Z1) COMMENT AND ITS ROUND-1 CORRECTION WERE
  // OVER-GENERAL, AND THIS IS THE MEASUREMENT THAT SETTLES IT. The original said
  // a rotated loop *has no preheader*; Rule-13 round 1 called that FALSE because
  // `clang -O1` gave `entry -> for.body.preheader -> header`. Measured
  // 2026-09-20 on `probes/h1e_guarded_live.c`, `-O1` emits **NO PREHEADER AT
  // ALL** — the guard branches straight into the header
  // (`br i1 %3, label %header, label %exit`) — so `getLoopPreheader()` returns
  // null and (Z1) refused before (Z8) was ever asked. The truth is that `-O1`
  // emits a preheader SOMETIMES, and a predicate may not depend on which.
  //
  // The requirement is therefore stated as what the promotion actually needs: a
  // SINGLE out-of-loop predecessor of the header, which is where the trip-1
  // register is minted. A second external predecessor is a multi-entry shape and
  // is refused as it always was.
  BasicBlock *Pre = L->getLoopPreheader();
  if (!Pre) {
    for (BasicBlock *PB : predecessors(L->getHeader())) {
      if (L->contains(PB))
        continue;
      if (Pre)
        return std::nullopt;  // more than one external entry — multi-entry.
      Pre = PB;
    }
    if (!Pre)
      return std::nullopt;
    // Without a preheader the entry block necessarily ends in the GUARD's own
    // conditional branch; anything else reaching a header directly is a shape
    // this predicate has never claimed.
    auto *EB = dyn_cast<BranchInst>(Pre->getTerminator());
    if (!EB || !EB->isConditional())
      return std::nullopt;
  }
  if (P.getParent() != L->getHeader() || !taint.Tainted.count(&P))
    return std::nullopt;
  // (Z2) EXACTLY TWO INCOMINGS: the latch and the preheader. A third edge is a
  //      multi-entry / irreducible shape, and an external edge that is NOT the
  //      preheader means the seed is not available at the promotion point.
  if (P.getNumIncomingValues() != 2)
    return std::nullopt;
  CarriedHandleProof Pf;
  Value *LatV = nullptr;
  for (unsigned i = 0; i < 2; ++i) {
    BasicBlock *IB = P.getIncomingBlock(i);
    if (IB == Latch) {
      LatV = P.getIncomingValue(i);
    } else if (IB == Pre) {
      Pf.ExtIdx = i;
      Pf.Seed = P.getIncomingValue(i);
    }
  }
  if (!LatV || !Pf.Seed)
    return std::nullopt;
  // (Z3) THE φ CARRIES A HANDLE, AND A HANDLE IS `i32` AT EVERY WIDTH (Rule 15:
  //      *"a runtime handle is ALWAYS `i32` regardless of width"*).
  //      `cqrt_alloc_<W>` RETURNS `i32` at every width, and so does every merge
  //      `%out`, so an `i1`/`i8`/`i16`/`i64` φ muxes two `i32` values through a
  //      φ of the wrong type. `lowerRotations` gets away with the same mismatch
  //      only because *"that mismatch is transient and laundered by erasure of
  //      the tainted users"* — and a φ is the one tainted user that is NOT
  //      erased, so for a φ the laundering has to be DONE rather than waited for.
  //
  //      ⚠ UNTIL bd `test_C_libtooling-11qv` (2026-09-20) THIS CLAUSE READ
  //      `isIntegerTy(32)` AND THE NARROW WIDTHS DECLINED. That was the
  //      CRASH FENCE, not a taste preference: a build that merely deleted the
  //      test emitted `PHI node operands are not the same type as the result!`
  //      and `opt` aborted with **exit 134**, MEASURED (bd `zujr` conjunct
  //      mutant matrix). The fence is retired only because the promotion now
  //      performs the retype the fence existed to make unnecessary — see
  //      `promoteLoopCarriedHandleSeeds` gates (P4)/(P5). DO NOT widen this
  //      clause again without checking that BOTH still stand.
  //
  //      THE WIDTH ITSELF IS NOT LOST, AND THAT IS THE WHOLE SAFETY ARGUMENT OF
  //      THE RETYPE. `Pf.Abi` is the LOGICAL width, read off the φ's type HERE,
  //      while the type still says it — and the promotion records it in
  //      `taint.HandleWidth`, the side-table that WINS over a laundered `i32`
  //      LLVM type.
  //      ⚠ ITS CONSUMER IS `lowerOps`' UP-FRONT CAST CAPTURE
  //      (`OpcodeLowering.cpp`, `taint.HandleWidth.lookup(Cast->getOperand(0))`),
  //      MEASURED — a narrow carried φ with a `sext i16 %a to i32` user emits
  //      `cq_template_sext_i16_to_i32(i32 %a)`, which is only spellable if the
  //      SOURCE width survived the retype.
  //      ⚠ AN EARLIER WORDING HERE NAMED `logicalOperandWidth` /
  //      `qqSelectLeafWidth` INSTEAD, AND THAT CONSUMER IS STRUCTURALLY
  //      UNREACHABLE (Rule-13 round 4, finding F-4): every caller of it runs
  //      inside control detection/emission, which finishes at
  //      `CQLoweringPass.cpp:616`, while this promotion runs at `:766`. The
  //      other Q+Q path reads the table RAW and takes its loud bail when the
  //      entry is absent — a decline, not a wrong symbol. **Right conclusion,
  //      wrong ground**, which is CLAUDE.md L7, and it is corrected AT THE
  //      SOURCE rather than only in a record — L7's twist cost three review
  //      rounds on one sentence.
  if (!P.getType()->isIntegerTy())
    return std::nullopt;
  Pf.Abi = abiWidthFromType(P.getType());
  // ⚠ `.empty()` IS NOT THE GATE — Rule-13 round 4, finding F-6, and
  // `OpcodeSupport.h` says so in writing: *"a data-mux gate must use
  // `widthHasReversibleCopy`, NEVER plain `.empty()`"*. `abiWidthFromType`
  // answers non-empty for `i80` and `i128`, and `wd.allocFn` resolves BOTH to a
  // `cqrt_alloc_i80` / `cqrt_alloc_i128` the runtime does not define — a phantom
  // mint that links nowhere. Nothing in THIS file stopped it; only a predicate
  // in another one happened to. Asked here, at the width, where it belongs.
  if (!widthHasReversibleCopy(Pf.Abi))
    return std::nullopt;
  Pf.NeedsHandleRetype = !P.getType()->isIntegerTy(32);
  // (Z4) THE SEED IS CLASSICAL AND AVAILABLE IN THE PREHEADER. Untainted, so the
  //      promotion is materialising a CLASSICAL value into a register and not
  //      re-allocating something that is already a handle; and not `undef`
  //      /`poison`, which `normalizeUndefRotationSeed` (bd `z9t1`) normalises at
  //      a SOURCE theta and nothing normalises here.
  if (taint.Tainted.count(Pf.Seed) || valueCarriesUndef(Pf.Seed))
    return std::nullopt;
  if (auto *SI = dyn_cast<Instruction>(Pf.Seed))
    if (L->contains(SI->getParent()))
      return std::nullopt;  // defined in the loop — not available at the promotion.
  // (Z5) THE LATCH INCOMING IS A FRESH TAINTED VALUE, NOT THE CLOSED SELF-CYCLE.
  //      `peelInPlaceBase(LatV) == &P` is EXACTLY `collapseRailPhisIn`'s claim
  //      condition, asked by CALLING it, so this kind and the (b)/(b′) kind
  //      cannot both claim one φ (Rule 14). A rail that crosses the back edge IN
  //      PLACE stays the collapse's; this kind is the complement.
  auto *LatI = dyn_cast<Instruction>(LatV);
  if (!LatI || !L->contains(LatI->getParent()) || !taint.Tainted.count(LatV))
    return std::nullopt;
  if (peelInPlaceBase(LatV, GateCalls, taint) == &P)
    return std::nullopt;
  // (Z6) THE LATCH INCOMING IS A CONTROL-MERGE RAIL — the SCOPE bd `zujr` names:
  //      *"a latch incoming that is a controlled-copy merge `%out` (fresh rail
  //      per activation)"*. That is what makes the per-trip unitary argument
  //      above true: a merge `%out` is a FRESH `|0⟩` rail written once per basis
  //      branch by two X-bracketed controlled copies, leaving the previous
  //      register untouched. A latch incoming that is some OTHER fresh tainted
  //      rail — `acc = acc + q`, the classic accumulator — is a DIFFERENT circuit
  //      with a different argument and is NOT this kind.
  //
  //      ⚠ IT IS ASKED BY THE RECORD WHEREVER THE RECORD EXISTS, AND BY SHAPE
  //      ONLY WHERE IT CANNOT. `taint.ControlOwnedRails` is what every Phase-4
  //      merge emitter writes at its own `Tainted.insert(rail)` site, and it is
  //      the ONLY thing the promotion accepts — but two of this predicate's four
  //      slots run at ROUND-1 taint, BEFORE `lowerControlRegions` has emitted
  //      anything, where that record is necessarily empty. There the question is
  //      asked of the SHAPE those emitters claim.
  //
  //      ⚠ AND THE SHAPE HALF IS ONLY EVER ALLOWED TO **DEFER**, never to
  //      accept — which is why a second spelling of an emitter's claim condition
  //      is admissible here and would not be at an accepting site (the drbq
  //      Inc-3 (b′) defect). The promotion asks the record, and an unpromoted φ
  //      declines at `declineClassicalMuxes`.
  //
  //      ⚠ WITHOUT IT THIS PREDICATE COSTS A **DIAGNOSTIC**, MEASURED: the
  //      `i32` spelling of `lowering_reject_loop_cross_iter.ll`'s accumulator
  //      (`$SES/probes/a14c_accum_i32.ll`) went from the accurate
  //      `cq loop lowering: loop-carried tainted value crosses iterations` to
  //      the misleading `cq taint escape: tainted value muxed by a
  //      classical-condition phi`. Both are declines and the direction is safe,
  //      but a structural guard wearing the wrong label is CLAUDE.md's L6 and is
  //      exactly the defect bd `8h7d.12` is open for.
  if (!latchIsControlMergeRail(LatV, taint))
    return std::nullopt;
  // (Z7) THE TRIP COUNT IS CLASSICAL. This is the whole safety argument for
  //      accepting a φ that `declineClassicalMuxes` would otherwise refuse:
  //      WHICH incoming is live on a given trip is decided by the loop's own
  //      exit test, and if that test is classical the choice is classical — a
  //      handle variable, not a no-cloning data mux. A tainted exit is the Q1
  //      quantum-bounded loop and stays a permanent decline (Rule 18; the bound
  //      derivation is NOT built). Asked by CALLING `taintedExit`.
  if (taintedExit(const_cast<Loop *>(L), taint))
    return std::nullopt;
  // (Z8) EVERY OUT-OF-LOOP READER OF THE VARIABLE READS A HANDLE.
  //      The promotion makes TRIP 1 name a register; it cannot make the
  //      ZERO-TRIP path name one, because the `cqrt_alloc` it mints lives in the
  //      PREHEADER and a ROTATED loop's zero-trip GUARD edge bypasses it. Such a
  //      loop has an exit φ muxing the CLASSICAL seed with the handle, which is a
  //      genuine `declineClassicalMuxes` refusal either way — so this conjunct
  //      does not change WHETHER the module declines, only WHICH owner speaks.
  //      MEASURED (`$SES/probes/a17_guarded.ll`): without it the accurate
  //      `cq loop lowering: loop-carried tainted value crosses iterations`
  //      became `cq taint escape: tainted value muxed by a classical-condition
  //      phi`, anchored at the EXIT φ instead of at the loop — CLAUDE.md's L6, a
  //      structural guard wearing the wrong label, and exactly the defect class
  //      bd `8h7d.12` is open for.
  //      ⚠ IT IS A DECLINE-DIRECTION CONJUNCT AND IT IS NOT THE CAPABILITY.
  //      Hoisting the alloc ABOVE the guard and rewriting the exit φ would make
  //      the guarded loop lower too; that is an ACCEPT-direction widening with
  //      its own Rule-13 round and its own zero-trip question (an allocation the
  //      program may never use), and it is FILED, not smuggled in here.
  //      ⚠ THE GUARDED LOOP IS NO LONGER REFUSED HERE — bd
  //      `test_C_libtooling-h1ip`, OWNER RULING Q1 of 2026-09-20: *hoist the
  //      alloc above the guard and ACCEPT THE DEAD ALLOC*. A `for (i < n)` with
  //      a RUNTIME `n` is what `clang -O1` rotates into
  //      `entry -(guard)-> preheader -> header`, and the guard's false edge
  //      BYPASSES the preheader — so the trip-1 register the promotion mints
  //      there does not exist on the zero-trip path and the exit φ muxes the
  //      CLASSICAL seed against a handle. The fix is to mint it ABOVE the guard
  //      and REWRITE that one incoming, which is what `GuardBB` /
  //      `BypassIncomings` carry to the promotion.
  //      ⚠ THE COST IS THE OWNER'S, TAKEN EXPLICITLY AND NOT HIDDEN: a loop
  //      that runs ZERO times now allocates a register it never uses. It is
  //      left allocated, never freed dirty (Rule 6), and in the
  //      qubits-not-scarce regime that is the accepted trade.
  //      ⚠ AND THE RECORDED INCOMING IS STILL PROVED, NOT ASSUMED. Only an
  //      incoming that (a) belongs to a φ OUTSIDE `L` that reads this variable,
  //      (b) is pointer-identical to the SEED, and (c) arrives on the GUARD's
  //      own edge is rewritable. Anything else is still `std::nullopt`.
  // The guard is the block whose CONDITIONAL branch decides whether the loop runs
  // at all. With a preheader it is that preheader's unique predecessor; WITHOUT
  // one the entry block IS the guard (it branches straight into the header), and
  // in both cases the mint point is that block's terminator — above the branch
  // that can skip the loop.
  if (Pre->getTerminator()->getNumSuccessors() > 1) {
    Pf.GuardBB = Pre;
  } else if (BasicBlock *UP = Pre->getUniquePredecessor()) {
    if (auto *GB = dyn_cast<BranchInst>(UP->getTerminator()))
      if (GB->isConditional() &&
          (GB->getSuccessor(0) == Pre || GB->getSuccessor(1) == Pre))
        Pf.GuardBB = UP;
  }
  for (Value *V : {static_cast<Value *>(&P), LatV})
    for (User *U : V->users()) {
      auto *OP = dyn_cast<PHINode>(U);
      if (!OP || L->contains(OP->getParent()))
        continue;
      // ⚠ EVERY INCOMING OF A φ THIS PREDICATE IS ABOUT TO WHITELIST MUST BE
      // PROVED, NOT JUST THE ONE BEING REWRITTEN — Rule-13 round 4, 2026-09-20,
      // finding F-2 (P2). The `taint.Tainted.count(In) -> continue` below is
      // PRE-EXISTING and was harmless while (Z8) only ever REFUSED; it stopped
      // being harmless the moment the promotion began inserting the **φ**
      // (not the incoming) into `taint.PromotedCarriedHandlePhis`, because
      // `declineClassicalMuxes` accepts on that entry — and its own comment
      // says what it is thereby refusing to refuse: *"distinct registers,
      // derived fresh-rail incomings, cross-block chains"*. A φ over three
      // quantum registers was being admitted on an argument covering ONE edge.
      //
      // So: a tainted incoming is admissible ONLY if it is one of the TWO SSA
      // names this carried variable wears (`&P` or `LatV`, the `V` loop's own
      // subjects). Any other tainted incoming is a THIRD register and the φ is
      // refused — `std::nullopt`, the decline direction, so the module keeps
      // the loud diagnostic it already had.
      bool SawBypass = false;
      for (unsigned i = 0, e = OP->getNumIncomingValues(); i != e; ++i) {
        Value *In = OP->getIncomingValue(i);
        if (In == &P || In == LatV)
          continue;
        if (taint.Tainted.count(In))
          return std::nullopt;  // a THIRD register — F-2.
        // ⚠ POINTER IDENTITY ON A `Constant` IS UNIQUED, and this file's own
        // project records why that matters (CLAUDE.md §4c, the F1 MANUFACTURED
        // identity): `i32 5` is ONE `Value *` however many C objects the source
        // had. It is admissible HERE and the reason is not "it is the same
        // object" — it is that the rewrite gives this incoming a register
        // holding |seed⟩, which is the value the zero-trip path carries
        // WHATEVER object it came from. Two source objects that were both the
        // seed constant end up sharing one register holding their common value;
        // no fence is deceived about a value the program actually wrote, and the
        // rival reading has no lowering to be robbed of (it declines today).
        if (In != Pf.Seed || !Pf.GuardBB ||
            OP->getIncomingBlock(i) != Pf.GuardBB)
          return std::nullopt;
        // ⚠ AND THE MINT POINT MUST NOT ITSELF BE RE-EXECUTED — Rule-13 round
        // 4, finding F-3 (P2). Nothing required `GuardBB` to sit outside every
        // ENCLOSING loop, so a nested nest lowered with the trip-1 register
        // minted ONCE PER OUTER TRIP: a fresh rail each time, under a name the
        // inner loop's φ already holds. `CLAUDE.md` lists nested loops as
        // declining and this path had quietly left that list. The guarded form
        // is therefore admitted only for an OUTERMOST loop; the unguarded path
        // is untouched, which is why this costs no shipped accept.
        if (L->getParentLoop())
          return std::nullopt;
        Pf.BypassIncomings.emplace_back(OP, i);
        SawBypass = true;
      }
      (void)SawBypass;
    }
  Pf.Phi = &P;
  Pf.LatchVal = LatV;
  Pf.Preheader = Pre;
  return Pf;
}

// bd `test_C_libtooling-zujr` — THE CHAIN the escape walk must not count.
//
// (c3) asks *"does an ITERATION-LOCAL TEMP escape `L`?"*. A loop-carried handle
// variable is by definition NOT a temp: it crosses the back edge on purpose and
// its exit value is what the program measures. Counting it made clause (c3)
// refuse the owner's cascade for a register the region does not even rotate —
// bd `8h7d.11`, and the owner's 2026-09-11 ruling makes an over-decline a defect
// to remove, not a safety margin.
//
// THE CHAIN IS THE φ AND ITS LATCH INCOMING, plus the in-place steps between
// them — i.e. the SSA names the ONE variable wears inside one activation, walked
// with `peelInPlaceStep`, the same edges `peelInPlaceBase` walked to prove (Z5).
// It is deliberately NOT the transitive operand cone: `h_op = a − 3` is a TEMP
// that happens to READ the variable, it is not the variable, and exempting it
// would be exactly the over-accept (c3) exists to stop.
void collectCarriedHandleChains(const Loop *L, const TaintSet &taint,
                                SmallPtrSetImpl<const Value *> &Out) {
  if (!L || !L->getHeader())
    return;
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
  for (PHINode &P : L->getHeader()->phis()) {
    std::optional<CarriedHandleProof> Pf =
        loopCarriedHandlePhi(P, L, taint, GateCalls);
    if (!Pf)
      continue;
    Out.insert(&P);
    for (Value *V = Pf->LatchVal; V;
         V = peelInPlaceStep(V, GateCalls, taint, /*AsLowered=*/false)) {
      if (!Out.insert(V).second)
        break;  // already seen — a cycle through a φ ends the walk.
      if (V == &P)
        break;
    }
  }
}

// bd 8h7d.17 — see LoopPlan.h. A function-local static, the pattern of
// `exitDischargeObligations` (no new `TaintSet` field).
std::vector<BreakEscape> &breakEscapeLedger() {
  static std::vector<BreakEscape> Ledger;
  return Ledger;
}

// bd 8h7d.17 — see LoopPlan.h. Post-order DFS, so a link follows its operands.
bool breakEscapeCone(Value *V, const PHINode *CounterPhi, const BasicBlock *Body,
                     const TaintSet &taint, SmallVectorImpl<Instruction *> &Cone) {
  SmallPtrSet<const Value *, 16> Done;
  // Explicit stack of (instruction, next operand index), so a deep cone cannot
  // overflow the native stack.
  SmallVector<std::pair<Instruction *, unsigned>, 16> Stack;
  auto visit = [&](Value *X) -> bool {
    auto *I = dyn_cast<Instruction>(X);
    if (!I || I == CounterPhi || I->getParent() != Body || Done.count(I))
      return true;  // a leaf: constant, argument, the counter, an outside value.
    if (isa<PHINode>(I) || isa<CallBase>(I) ||
        taint.Tainted.count(I) || I->mayReadOrWriteMemory() ||
        !isSafeToSpeculativelyExecute(I))
      return false;
    Done.insert(I);
    Stack.push_back({I, 0});
    return true;
  };
  if (!visit(V))
    return false;
  while (!Stack.empty()) {
    auto &[I, Next] = Stack.back();
    if (Next < I->getNumOperands()) {
      Value *Op = I->getOperand(Next++);
      if (!visit(Op))
        return false;
      continue;
    }
    Cone.push_back(I);
    Stack.pop_back();
  }
  return true;
}

namespace {

// ── Phase 7.4 (epic y05j) — single value-arm `break` recognition ────────────
//
// All analysis below is PURE SSA/CFG identity on the still-unmutated IR (Rule 9);
// `tryBreak` never mutates in Increment 1 (recognition + decline partition only).

// "Does this value's lineage carry a relative phase?" — the §2.6 phase fence
// over the escaping answer (B3). A per-TU mirror of `ControlDetect`'s
// `retLineageCarriesPhase` and the AbortPark/SelectClassify twins (the house
// style sanctions the trivial duplicate — keeping the loop partition
// self-contained, Rule 14). A `cq_theta` (Ry) basis superposition has no
// relative phase; a branch phase whose control meets the answer's lineage (the
// first clause) is the carrier, and the `cq_phi_` lineage row is the vacuous
// retired-form check.
bool breakLineageCarriesPhase(Value *Op, const TaintSet &taint,
                              const BasicBlock *Construct) {
  // ---- THE REGISTER-FREE BRANCH PHASE (bd 3qlq Inc 1 part A, Rule-13 round-1
  // finding F-L5-6 — a latent WIDENING). The `cq_phi_` prefix row below went
  // VACUOUS with the surface change, and the property it protected became
  // UNREPRESENTABLE in the SSA lineage: a register whose branches carry a
  // kickback phase has no `cq_phi` in its operand graph at all, because the gate
  // lands on a flag ancilla the register does not derive from. Without this
  // clause this fence silently answered "no phase" for a value that carries one.
  //
  // Asked PER REGISTER since bd 3by9: `lineageCarriesBranchPhase` asks the
  // control-dependence question the backward walk below cannot (which tainted
  // values each branch phase is a function of) and intersects it with this
  // answer's lineage. The coarse `functionCarriesBranchPhase` this replaced
  // declined a kickback on the break's COMPARAND, which the construct only reads
  // as a control (`lowering_loop_break_qq_phase.ll`). The twins in
  // `ControlDetect` and `AbortParkEmit` still ask the coarse question.
  //
  // bd tinh: `Construct` is the loop header. A branch phase that cannot reach it
  // runs after the construct, a later gate whose keys hold the source's values
  // there (`out`, a register the construct only reads, a value defined outside
  // the loop, an 8h7d.17 escape register; E16 refuses any other in-loop value
  // read after the loop), and is not counted.
  if (lineageCarriesBranchPhase(Op, taint, Construct))
    return true;

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

// An exiting block's terminator condition is tainted (a `br`/`switch` on a
// q-derived value) — the unit of the multi-site count (B1) and of `taintedExit` —
// is asked with `isTaintedBranchTerminator` (TaintedControlDependence.h), which
// replaced the identical `isTaintedExitingTerminator` here (bd r2j3.6 R4-2).

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

  // ── (E17) The zero-trip GUARD block (bd 8h7d.15). Canonically `PreB` IS the
  // guard: it ends in the conditional branch that enters the loop or skips to the
  // exit merge. When `-O1` LICM hoists an invariant into the loop's preheader
  // (`(int)b` for a `_Bool` comparand, `p + k`), that preheader
  // stays a DEDICATED block — one predecessor (the guard), an unconditional branch
  // to the header — which the guard's zero-trip edge bypasses. Everything this
  // emitter needs at "the guard" is then one block up: the R/idx/out mints (read
  // in the exit merge), E13's zero-trip incoming, E12's condition. The preheader's
  // own instructions are read by the loop and, through the reverse-play's clone of
  // the break-cond (BreakReversePlay.cpp `cloneBreakCond`), the rail-op adjoints
  // and the companion loop's `n - 1`, in the exit merge, which the preheader does
  // NOT dominate: left in place they make the module ill-dominated. So they are
  // HOISTED into the guard below, which gives the canonical shape this emitter
  // already lowers. That moves each one onto the zero-trip path, so it must be
  // safe to execute there: `isSafeToSpeculativelyExecute` (no side effect, no
  // trap — a runtime `k / d` hoisted by LICM is refused, it would trap on a path
  // the source never divides on; lowering_reject_break_hoisted_trapping_
  // comparand.ll). A tainted hoisted value is a pure template the construct only
  // READS, as a control, exactly like a comparand derived before the guard
  // (lowering_loop_break_qq_derived.ll). Detection only: nothing moves until
  // every precondition below has passed.
  BasicBlock *GuardB = PreB;  // the block holding the zero-trip guard branch
  SmallVector<Instruction *, 4> PreheaderHoist;
  if (auto *PreBr = dyn_cast<BranchInst>(PreB->getTerminator());
      PreBr && PreBr->isUnconditional()) {
    GuardB = PreB->getSinglePredecessor();
    if (!GuardB || GuardB == PreB)
      return bail();
    for (Instruction &I : *PreB) {
      if (I.isTerminator())
        continue;
      if (isa<PHINode>(I) || !isSafeToSpeculativelyExecute(&I))
        return bail();
      PreheaderHoist.push_back(&I);
    }
  }
  SmallPtrSet<const Instruction *, 4> HoistSet(PreheaderHoist.begin(),
                                              PreheaderHoist.end());

  // ── (E14) NO pre-loop in-place rail mutation: the rail value ENTERING the loop
  // (`RailPre`, the rail phi's PreB-incoming) must BE the bare mint (`Root`). The dtzb
  // collapse RAUWs the rail phi to `Root = peelInPlaceBase(RailPre)`, which peels
  // THROUGH any pre-loop in-place value/rotation mutation (`q = q ^ 7;` or a pre-loop
  // chained `cq_theta` between the mint and the loop), and only the IN-LOOP `RailOps`
  // are marked `InPlaceRailOps`. So a pre-loop mutation orphans to a DEAD out-of-place
  // template handle and is NEVER applied to the in-place rail handle — the post-lowering
  // capture (BreakReversePlay.cpp) then copies a rail handle MISSING that mutation into
  // `out` (a VERIFY-CLEAN WRONG UNITARY, off by the pre-loop mutation; on BOTH edges).
  // E13 does NOT catch it (the escape phi legitimately carries `RailPre`, so escape ==
  // rail by VALUE; the divergence is `Root` ≠ `RailPre` at the HANDLE level). Found by
  // the y05j.2 Rule-13 sign-off 2026-06-28. `Root == RailPre` ⟺ `RailPre` is itself the
  // mint (no peel happened). Decline otherwise (Prime Directive — over-declining is
  // safe; applying the pre-loop mutation in-place to the rail handle is a near-term
  // widening, not this increment's proven shape — the canonical `cq_theta(&q, …); for(…)`
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
  // `RailPre` from the guard (`GuardB`, E17: `PreB` itself unless a dedicated
  // preheader sits between them); decline otherwise (Prime Directive — over-declining
  // is safe; capturing a derived answer rather than the rail is a near-term widening,
  // not this increment's proven shape). The canonical `return measure(q)` carries
  // `RailLat`/`RailPre` themselves and still lowers (lowering_loop_break_*).
  {
    int LatchIdx = Rgn.EscapePhi->getBasicBlockIndex(Latch);
    int PreBIdx = Rgn.EscapePhi->getBasicBlockIndex(GuardB);
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

  // ── (E6) The guard block `GuardB` (E17: `PreB` itself, or the block above a
  // dedicated preheader — where R/idx/out are minted) MUST dominate the exit merge.
  // R/idx/out are read in the loop AND in the exit merge (the consolidation/copy-out/
  // reverse-play), so their defs must dominate those uses. This holds for the
  // canonical zero-trip guard block (which dominates the bypassing exit edge). A
  // clang-materialized DEDICATED preheader that the zero-trip guard edge bypasses is
  // never the mint point: minting there yielded an ill-dominated module (`opt
  // -verify` aborted on valid C; the Rule-13 review 2026-06-26), which is why E17
  // steps up to its guard. Decline (Prime Directive — over-declining is safe).
  if (!DT.dominates(GuardB, Rgn.ExitMerge))
    return bail();

  // ── (E12) Capture the forward loop's zero-trip ENTRY guard (GuardB's conditional
  // branch into the loop) so the reverse-play companion loop can REUSE it. A
  // re-invented signed `sgt(n, 0)` backward guard would be WRONG for an
  // unsigned-bounded loop (`for (unsigned i=0; i<n; i++)`, whose `-O1` entry guard
  // is `icmp eq n, 0` → enter iff `n != 0`): for `n ≥ 2^31` the forward enters +
  // captures while the signed `sgt(n,0)` skips the whole reverse-play → R/idx freed
  // DIRTY (a Rule-6 hidden measurement; the CRITICAL Rule-13 FINAL finding
  // 2026-06-26). Reusing the forward guard makes the backward loop enter iff the
  // forward did, for ANY signedness. Require GuardB to end in a conditional branch
  // with the loop's entry block (the Header, or the dedicated preheader `PreB` of
  // E17, whose only successor is the Header) as one successor; decline otherwise.
  BasicBlock *LoopEntry = GuardB == PreB ? Header : PreB;
  auto *GuardBr = dyn_cast<BranchInst>(GuardB->getTerminator());
  if (!GuardBr || !GuardBr->isConditional())
    return bail();
  bool LoopOnTrue = GuardBr->getSuccessor(0) == LoopEntry;
  if (!LoopOnTrue && GuardBr->getSuccessor(1) != LoopEntry)
    return bail();  // GuardB does not branch directly into the loop.
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
  // declines (Prime Directive — over-declining is safe). An invariant immediate
  // LICM left in a dedicated preheader passes too: E17 hoists it into the guard,
  // which dominates the exit merge.
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
      if (!DT.dominates(ImmI, Rgn.ExitMerge) && !HoistSet.count(ImmI))
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
                   // that is SOUND even when p carries a RELATIVE PHASE (pre-3qlq `p =
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
                   // 2026-06-30 (0 holes). CONTRAST B3 (in `tryBreak`), which DOES fence a
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

  // ── (E16) NOTHING BUT THE ANSWER LEAVES THE LOOP UNCAPTURED — bd 923w (the
  // 3by9 Rule-11 review, round 1, F1), lowered since bd 8h7d.17. Step (5) below
  // strips the break flag from the loop terminator, so the rolled loop runs its
  // FULL classical trip on every branch and the break exists only in `idx`. Any
  // value defined in the loop and read outside it leaves as its full-trip value,
  // not the source's: an LCSSA φ of the counter, `%iex = phi [0, guard], [i.next,
  // loop]`, reads n where the source reads the break iteration + 1, a function of
  // the quantum state. B2 inspects only TAINTED exit φs, so nothing caught it, and
  // step (5) leaves no tainted control above a phase keyed on it, which
  // `deleteGlobalPhases` then deleted as global (923w: a verify-clean dropped
  // relative phase, measured).
  //
  // 8h7d.17 lowers such a value as a CONTROL-MERGE value. The capture rescues the
  // escape φ's value into `out`; an UNTAINTED exit φ `E = φ [Z, guard], [V,
  // latch]` whose `V` is a pure classical function of the counter
  // (`breakEscapeCone`, so the reverse-play can recompute it) gets the same
  // treatment through the ledger (`BreakEscape`, LoopPlan.h): E's users read a
  // fresh register `cq.brk.esc.out`, registered as a control-merge rail so round 2
  // taints them (a phase keyed on it lowers by kickback, a classical sink stays a
  // loud taint escape), and E itself stays, classical, as the never-fired value.
  // E's own classical-ness is asked here at ROUND-1 taint only; its zero-trip
  // incoming can still become a register later (a 6.5 / 4.5 merge `%out`, an
  // earlier break's escape register), so `emitOneBreak` re-asks it at FINAL
  // taint and declines loudly (review round 1, F1).
  // A dead E is left alone (nothing reads its full-trip value). Everything else
  // still refuses: a TAINTED value other than the answer (it would read the
  // restored rail or a freed break-cond flag), a use that is not such an exit φ, a
  // cone with a load, a call or a non-speculatable op, a non-integer width. A
  // value defined OUTSIDE the loop (an exit φ carrying the loop-invariant `n`) is
  // unaffected by the virtualization and passes untouched.
  // lowering_loop_break_escape_classical_counter.ll (accept, the former 923w
  // decline) / lowering_reject_break_escape_counter_classical_sink.ll (the
  // classical sink, loud) / lowering_loop_break_escape_invariant_classical.ll.
  struct EscapeCand {
    PHINode *Phi;
    Instruction *V;
    StringRef W;
  };
  SmallVector<EscapeCand, 2> Escapes;
  {
    SmallPtrSet<const PHINode *, 4> EscSeen;
    for (BasicBlock *BB : Rgn.L->blocks())
      for (Instruction &I : *BB)
        for (User *U : I.users()) {
          auto *UI = cast<Instruction>(U);
          if (Rgn.L->contains(UI->getParent()) || UI == Rgn.EscapePhi)
            continue;
          // Every use outside the loop is a φ of the exit merge (the guard edge
          // bypasses the loop, so nothing else there is dominated by `I`).
          auto *E = dyn_cast<PHINode>(UI);
          if (!E || E->getParent() != Rgn.ExitMerge || taint.Tainted.count(&I) ||
              taint.Tainted.count(E) || E->getNumIncomingValues() != 2)
            return bail();  // a loop value escapes past the virtual break.
          int EL = E->getBasicBlockIndex(Latch), EG = E->getBasicBlockIndex(GuardB);
          if (EL < 0 || EG < 0 || E->getIncomingValue(EL) != &I)
            return bail();
          if (!EscSeen.insert(E).second || E->use_empty())
            continue;
          SmallVector<Instruction *, 8> Cone;
          if (!breakEscapeCone(&I, CounterPhi, Header, taint, Cone))
            return bail();
          // The reverse-play clones the cone after the loop: every operand it
          // reads from outside the body must be defined there too (E10's rule).
          for (Instruction *C : Cone)
            for (Value *Op : C->operands())
              if (auto *OI = dyn_cast<Instruction>(Op))
                if (OI->getParent() != Header && !HoistSet.count(OI) &&
                    !DT.dominates(OI, Rgn.ExitMerge))
                  return bail();
          StringRef W = abiWidthFromType(E->getType());
          if (!E->getType()->isIntegerTy() || !wd.allocFn(W) || !wd.copyFn(W) ||
              !wd.addcFn(W))
            return bail();
          Escapes.push_back({E, &I, W});
        }
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
    markInPlaceRailOp(BO, taint);  // + the proven rail's operand INDEX (eqpx).

  // (1b) E17: hoist a dedicated preheader's instructions into the guard, in
  //      order (each operand is defined in the guard or above, since the guard is
  //      the preheader's only predecessor). UB-implying attributes and metadata
  //      are dropped, as LLVM's own speculation does (`hoistAllInstructionsInto`),
  //      except this pass's own `cq.*` marks (`cq.predmux.predicted` is still read
  //      by the classifiers); the debug location stays the source's. The
  //      preheader is left holding its unconditional branch to the header.
  if (!PreheaderHoist.empty()) {
    SmallVector<StringRef, 32> KindNames;
    GuardB->getContext().getMDKindNames(KindNames);
    for (Instruction *I : PreheaderHoist) {
      SmallVector<unsigned, 8> Keep{LLVMContext::MD_annotation,
                                    LLVMContext::MD_range,
                                    LLVMContext::MD_nonnull,
                                    LLVMContext::MD_align};
      SmallVector<std::pair<unsigned, MDNode *>, 4> MDs;
      I->getAllMetadataOtherThanDebugLoc(MDs);
      for (const auto &KN : MDs)
        if (KN.first < KindNames.size() && KindNames[KN.first].starts_with("cq."))
          Keep.push_back(KN.first);
      I->dropUBImplyingAttrsAndUnknownMetadata(Keep);
      I->moveBefore(GuardB->getTerminator());
    }
  }

  // (2) Mint R / idx / out = |0> before the loop (in the guard block, which
  //     dominates both the loop and the exit — E6/E17).
  IRBuilder<> PB(GuardB->getTerminator());
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
  // Each mint is an i32 HANDLE for a rail of RailWidth / IdxWidth, so record the
  // logical width (bd 01po.3). `out` replaces the user's exit phi below. A consumer
  // that asks `logicalOperandWidth` or the raw record (QRAM index, Q+Q compare and
  // select leaf, lowerOps cast capture, IO tape, abort park) fell back to the i32
  // type without it: an i64 `out` reached `cqrt_qram_load` as an unbracketed
  // 64-bit index, `(long long)q` of an i8 `out` minted `sext_i32_to_i64`, two i64
  // answers compared as `icmp_eq_i32`. A reader that takes the width from the SSA
  // TYPE never sees this record (QramLowering's store-value check declines on the
  // mismatch). lowering_loop_break_{qram_index,out_width,io_tape,abort_park}*.ll.
  taint.HandleWidth[RReg] = RailWidth;
  taint.HandleWidth[IdxReg] = IdxWidth;
  taint.HandleWidth[OutReg] = RailWidth;
  // NB: the rail Root (`cq_theta`) is RAUW'd to its `cqrt_alloc` handle by
  // `lowerRotations`, so inserting it here would go STALE. The rail handle (and
  // every break-body scratch handle) is excluded from the whole-DAG uncompute
  // spine LATER, in the post-lowering `lowerBreakReversePlay`, where the LOWERED
  // i32 handles are live.

  // (2b) bd 8h7d.17 (E16): each escape's capture scratch and control-merge
  //      register, minted |0> in the guard beside R/idx/out and owned by the
  //      construct the same way. `Out` joins `UntaintedMergeRails`, the route
  //      every fresh rail over an UNTAINTED value takes (the 6.5 / 4.5 `%out`,
  //      the IO-sink mux): `repropagateControlMerges` re-seeds taint from it and
  //      re-runs the escape and control guards over the delta. E keeps no user.
  for (const EscapeCand &EC : Escapes) {
    Type *ETy = EC.Phi->getType();
    CallInst *Cap = PB.CreateCall(wd.allocFn(EC.W), {ConstantInt::get(ETy, 0)},
                                  "cq.brk.esc.R");
    CallInst *EOut = PB.CreateCall(wd.allocFn(EC.W), {ConstantInt::get(ETy, 0)},
                                   "cq.brk.esc.out");
    stamp(Cap);
    stamp(EOut);
    for (Value *H : {static_cast<Value *>(Cap), static_cast<Value *>(EOut)}) {
      taint.Tainted.insert(H);
      taint.ControlOwnedRails.insert(H);
      taint.HandleWidth[H] = EC.W;
    }
    taint.UntaintedMergeRails.insert(EOut);
    EC.Phi->replaceAllUsesWith(EOut);
    BreakEscape Rec;
    Rec.Region = OutReg;
    Rec.Phi = EC.Phi;
    Rec.V = EC.V;
    Rec.Out = EOut;
    Rec.Cap = Cap;
    Rec.Width = EC.W;
    breakEscapeLedger().push_back(Rec);
  }

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
    if (isTaintedBranchTerminator(EB->getTerminator(), taint)) {
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

  // (B3) Value-class answer. A phase-class escaping answer (a branch phase, per
  // `breakLineageCarriesPhase` — v2_phase) cannot be CNOT-copied out (Rule 7
  // dephases) and the data-comparison phase break is degenerate ⇒ PERMANENT
  // decline (§2.6). Since bd 3by9 a branch phase counts only when its control
  // meets the answer's own lineage: a kickback on the COMPARAND alone lowers
  // (`lowering_loop_break_qq_phase.ll`); one inside the loop still declines here
  // (`lowering_reject_break_phase_inloop_comparand.ll`). Since bd tinh a branch
  // phase whose block cannot reach the loop header is not counted at all: it is
  // a later gate (`lowering_loop_break_post_phase_answer.ll`), while the same
  // kickback before the loop still declines
  // (`lowering_reject_break_pre_phase_answer.ll`).
  for (Value *In : EscapePhi->incoming_values())
    if (taint.Tainted.count(In) &&
        breakLineageCarriesPhase(In, taint, L->getHeader())) {
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
    // (bd dm7f.24: the inline `br`/`switch` re-test that followed this line was
    // the same predicate spelled a second time, and is gone — R12.)
    if (T != TheExitT && isTaintedBranchTerminator(T, taint))
      return false;  // a second tainted br/switch (non-exiting control) in body.
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

// (`isTaintedBranchTerminator` — `tryCaseA`'s gate L2 and the hand-off below — is
// TaintedControlDependence.h's, the shared spelling since bd r2j3.6 R3-3(d).)

// bd `test_C_libtooling-wt8u` — IS THIS CONSUMER OF A RAIL VALUE THE CONTROL
// CHAIN'S, NOT THE LOOP'S? True for an instruction OUTSIDE `L` that is either
// under tainted control (`instUnderTaintedControl`, the shared "inside a tainted
// arm" predicate) or a φ merging tainted control (some incoming edge leaves a
// tainted branch, or leaves a block under tainted control).
//
// WHY THE RAIL STOPS HERE. `tryCaseA`'s fixpoint used to grow the rail over the
// whole function, so a POST-loop `if (q == 3) cq_theta(&r, .2);` lost its arm
// gate (a) and its merge φ (b) to the rail, and the accept RAUW'd that merge φ
// to the root: detection then saw a tainted diamond with no merge φ and declined
// `control flow under quantum control`. The same fold MARKED an arm `xor` in
// place (`markInPlaceRailOp`), an unconditional `cqrt_xorc` for an op the source
// runs on one branch; only that missing merge φ kept it from the backend. A
// region's arm and merge are emitted by the control chain, under its flag, and
// the loop's collapse owes them only ONE thing: that the register they read at
// their own position holds the record they name. That is the record-liveness
// fence's question (`staleRailRecordRead`), asked of a hand-off like of any
// other non-member reader, and `collectRailGates` still counts a hand-off arm's
// in-place Ry as a GATE on this rail, so a pre-region alias read after the
// region stays loud (`loop_caseA_postloop_region_handoff_reject_stale_alias.ll`).
//
// IN-BODY tainted control never reaches here: gate L2 leaves such a loop
// unclaimed before the fixpoint, and the `L->contains` test keeps the answer
// about the loop's OUTSIDE. A loop that is ITSELF inside a tainted arm gets no
// hand-off at all (the caller's `LoopUnderControl`): its body is under control
// too, and the old whole-function rail, whose collapse leaves the enclosing
// region without its merge φ, is what keeps it declining (`control flow under
// quantum control`, unchanged; probe `a5_loop_in_arm.c`). Conservative
// direction: answering true only leaves a value to the control chain or to
// `declineClassicalMuxes`, both of which lower it or decline loudly; it never
// adds a collapse or a mark.
bool railUseHandedToControl(Instruction *U, const Loop *L, const TaintSet &taint,
                            DominatorTree &DT) {
  if (L->contains(U))
    return false;
  if (auto *P = dyn_cast<PHINode>(U)) {
    for (BasicBlock *IB : P->blocks()) {
      Instruction *T = IB->getTerminator();
      if (isTaintedBranchTerminator(T, taint) ||
          instUnderTaintedControl(T, taint, DT))
        return true;
    }
    return false;
  }
  return instUnderTaintedControl(U, taint, DT);
}

// bd `test_C_libtooling-8h7d.16` — is `I` a compare that reads a rail value
// strictly AFTER `L`: outside `L`, and unable to reach `L`'s header? CLOSURE
// used to refuse every compare, so `for (…) cq_theta(&r, .1);` followed by a
// 7.4 break whose comparand is `r` left the loop unclaimed and the zero-trip
// exit φ declined at `declineClassicalMuxes`.
//
// WHY "CANNOT REACH THE HEADER". A compare's flag is a fresh template rail whose
// `_unc` reads the register again, LATER (at the region's strip, or at the
// spine's LIFO adjoint). A compare that can reach the loop could have that
// adjoint run after the loop's gates moved the register, and the record fence
// asks only "a gate between the record and the READ", never "a gate between
// the read and its adjoint". After the loop every gate of THIS rail precedes
// the read; a later gate on the exit name is a different, exact-SSA record
// question that `declineStaleRecordOps` and the condition-wire fence ask
// before and at detection. `isPotentiallyReachable` errs toward `true` past its
// scan limit, which here only refuses (the pre-8h7d.16 answer).
bool isPostLoopRailCompare(Instruction *I, const Loop *L,
                           const DominatorTree &DT, const LoopInfo &LI) {
  if (!isa<CmpInst>(I) || L->contains(I))
    return false;
  return !isPotentiallyReachable(I, &L->getHeader()->front(),
                                 /*ExclusionSet=*/nullptr, &DT, &LI);
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
  for (BasicBlock *BB : L->blocks())
    if (isTaintedBranchTerminator(BB->getTerminator(), taint))
      return false;

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
  // Per root, the peeled header chains (bd r2j3.13): the record fence's skip set.
  DenseMap<Value *, SmallPtrSet<const Value *, 16>> ChainSkip;
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
      //
      // ── bd `test_C_libtooling-zujr` / bd `ej5w` — THE LOOP-CARRIED HANDLE
      //    VARIABLE IS THE THIRD KIND AND IS NOT THIS DECLINE'S.
      // A φ `loopCarriedHandlePhi` admits is a register that is RE-MINTED every
      // trip, not a dirty rail dragged across the back edge: the promotion gives
      // it a preheader `cqrt_alloc_<W>` and the merge gives it a fresh `%out` per
      // activation. Leave the whole loop unclaimed — `return false`, NOT an
      // accept — so nothing here collapses a loop-variant handle, and so the
      // module still declines loudly at `declineClassicalMuxes` if the promotion
      // later refuses it (this site is not the last owner).
      // ⚠ SCOPE_L1a: this site and `collapseRailPhisIn`'s twin MUST move
      // together, or round 2 re-declines what round 1 accepted. The predicate is
      // STRUCTURAL precisely so both can ask it — here at ROUND-1 taint, before
      // any merge emitter has run, where `taint.ControlOwnedRails` is still empty.
      if (loopCarriedHandlePhi(P, L, taint, GateCalls))
        return false;
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
    // bd r2j3.13 — the PEELED CHAIN (root → … → PreV → P → … → LatV), walked
    // over the same `peelInPlaceStep` edges the two peels above proved, exactly
    // as round 2's `collapseRailPhisIn` enumerates its `Chain`. Only these are
    // "the rail moving" for the record fence's skip; see its call below.
    auto &Skip = ChainSkip[Root];
    Skip.insert(&P);
    for (Value *V = LatV; V && V != &P; V = peelInPlaceStep(V, GateCalls, taint))
      Skip.insert(V);
    for (Value *V = PreV; V && V != Root;
         V = peelInPlaceStep(V, GateCalls, taint))
      Skip.insert(V);
    Skip.insert(Root);
  }
  if (railRoot.empty())
    return false;  // no persistent rail — Case B / other, not Inc 1.

  // Fixpoint expansion: an in-place gate on a rail value joins the SAME rail; a
  // tainted phi ALL of whose incomings peel to one common root joins that root
  // (the zero-trip/exit merge phi and any inner renaming). A phi whose incomings
  // peel to TWO distinct roots is a cross-rail merge — not clean; bail.
  // NEITHER EDGE CROSSES INTO TAINTED CONTROL (bd wt8u): a gate in a tainted arm
  // or a φ merging one is the control chain's (`railUseHandedToControl`); it is
  // left out of the rail and accepted by CLOSURE as a hand-off. Memoized: the
  // predicate may build a post-dominator tree per call. Never for a loop that
  // is itself under tainted control (see `railUseHandedToControl`).
  const bool LoopUnderControl =
      instUnderTaintedControl(Header->getTerminator(), taint, DT);
  DenseMap<Instruction *, bool> HandOffMemo;
  auto handedToControl = [&](Instruction *U) {
    if (LoopUnderControl)
      return false;
    auto [It, New] = HandOffMemo.try_emplace(U, false);
    if (New)
      It->second = railUseHandedToControl(U, L, taint, DT);
    return It->second;
  };
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
        if (handedToControl(I))
          continue;  // an arm's gate — the control chain's (bd wt8u).
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
        if (handedToControl(&P))
          continue;  // a region's merge φ — the control chain's (bd wt8u).
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
  // (chained cq_theta; pre-3qlq also cq_phi/rz, the SHARED pre-dtzb gap) — so the
  // same guard closes both. Loud decline (claimed), never a silent serialized
  // collapse (Prime Directive).
  //
  // COUNTED VIA `railValueConsumerDisposition` (bd 8h7d.5 Rule-13 round 4, OD-A)
  // — the ONE spelling of "will this BO be lowered in place", shared with round 2
  // and with `collectRailGates`. `Claimed` is `railRoot`, and HERE the question
  // is a NO-OP by construction: the (a)/(b) fixpoint above has already absorbed
  // every in-place BO consumer of a rail value into `railRoot`, so every op this
  // guard could count is `InPlace`. It is threaded through anyway so the two
  // rounds cannot drift apart on the predicate again (Rule 14) — and pinned by
  // `control_swap_inloop_range_cond.ll`'s round-1 twin `@range_cond_no_control`,
  // which must keep declining.
  SmallPtrSet<const Value *, 32> Round1Claimed;
  for (auto &KV : railRoot)
    Round1Claimed.insert(KV.first);
  for (auto &KV : railRoot) {
    SmallVector<Instruction *, 2> InPlaceUsers;
    for (User *U : KV.first->users()) {
      if (auto *CI = dyn_cast<CallInst>(U)) {
        if (isInPlaceGateOnArg0(CI, KV.first, GateCalls, taint) &&
            !isHoistedRegionArmGate(CI, taint))
          InPlaceUsers.push_back(CI);
      } else if (auto *BO = dyn_cast<BinaryOperator>(U)) {
        if (railValueConsumerDisposition(BO, KV.first, taint, Round1Claimed) >
            RailValueUse::OutOfPlace)
          InPlaceUsers.push_back(BO);  // `Unproven` counts — see the enum's note.
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
  // measure sink, an escape (`ret`), a post-loop tainted region's arm consumer
  // or merge φ handed to the control chain (bd wt8u, `railUseHandedToControl`),
  // a compare strictly after the loop (bd 8h7d.16, `isPostLoopRailCompare`),
  // or an abort park's own condition compare (bd dm7f.7,
  // `isAbortParkCondition`). ANY other consumer — a value-op template producer,
  // another compare that can reach the loop, a store, an unknown call, or the
  // rail used as a classical ANGLE (arg-1) — means the rail is not isolated;
  // leave it (the consumer's own guard declines loudly downstream). Every
  // admitted non-member read is asked positionally by the record fence below,
  // a compare at its own position AND at every branch/select it drives
  // (`railGateBeforeControlUse`: the control emitters mint the flag there).
  //
  // ⚠ THIS CLAUSE KEEPS A RAIL-BANK-PARKED RAIL OUT OF *THIS* PATH's IN-PLACE
  // RELABEL (Case A) — AND ONLY THIS PATH's. Corrected 2026-09-24 (bd `xdu2.1`,
  // Rule-13 round 2 finding F-1, L7 fixed at the source): the round-1 version of
  // this comment was headed "THIS CLAUSE IS WHAT KEEPS A RAIL-BANK-PARKED RAIL
  // OUT OF THE ROLLED IN-PLACE RELABEL", and that was FALSE. The rolled in-loop
  // COLLAPSE (`collapseRailPhisIn`, round 2) commits the same relabel
  // (`markInPlaceRailOp` after its `staleRailRecordRead` fence) and has no such
  // closure: `int b[n]; for(i) b[i]=q; for(k){ if(q>k) cq_phi(.3); q ^= 3; }
  // for(i) cq_measure(b[i]);` reached it, converted `q ^= 3` in place and
  // accepted a stale bank read (review probe `reviewB_r2/P1_bank.c`). What holds
  // THAT path is now `staleReadOfValue`'s memory hop (`railBankCellReadsOf`),
  // which asks the question at every bank cell LOAD — and `staleRailRecordRead`
  // runs here too (below), so this path is held TWICE: by this closure, which
  // refuses the bank store (or its storage cast) as a non-rail user, and by that
  // fence. `e1_bank` (`reviewB_r1/p/e1_bank.c`, matrix row 33) is this path's
  // shape and declines at `declineClassicalMuxes` once this loop is left
  // unclaimed. The other in-place minters for a parked rail and what refuses
  // each are enumerated in `TRACK_B.md` §6b.
  // RETIREMENT TRIGGER: the day this closure admits a `store` into a rail bank
  // (or its storage cast), the `staleRailRecordRead` call below becomes this
  // path's only wall for `e1_bank` — re-run the matrix row and the
  // `railbank_stale_reject_inloop_xor_*` fixtures against a binary with the
  // closure relaxed BEFORE relaxing it, and keep the fence's bank-load hop.
  for (auto &KV : railRoot) {
    Value *V = KV.first;
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        continue;
      if (railRoot.count(I) || isMeasureCall(I) || isa<ReturnInst>(I))
        continue;
      // bd wt8u — a post-loop tainted region's arm consumer or merge φ is
      // HANDED to the control chain, which reads the collapsed register at the
      // region's own position; the record fence below asks that read like any
      // other non-member read.
      if (handedToControl(I))
        continue;
      // bd 8h7d.16 — a tainted COMPARE reading the rail AFTER the loop (a
      // kickback condition, a 7.4 break comparand, a data flag). The collapse
      // makes it read the register at its own position; the record fence below
      // asks that read positionally, and no rail gate of this loop can run after
      // it (it cannot reach the header), so its flag's later `_unc` reads the
      // same state. A post-loop rail gate AFTER the compare is the stale-record
      // pre-pass's (`operand predates a non-diagonal gate`, asked before this
      // collapse on exact SSA) and the condition-wire fence's.
      if (isPostLoopRailCompare(I, L, DT, LI))
        continue;
      // bd dm7f.7 — an abort park's OWN condition compare, which may sit BEFORE
      // the loop (`if (q > 5) abort(); for (…) cq_theta(&q, .1);`). Its flag is
      // taped by the park and never stripped, so no adjoint of it runs after
      // the loop's gates; the record fence below asks the compare AND the
      // park's branch (`railGateBeforeControlUse`), where the park mints.
      if (auto *C = dyn_cast<CmpInst>(I))
        if (!L->contains(C) && isAbortParkCondition(C, taint))
          continue;
      // An in-place gate on the rail whose result is itself a rail is in
      // railRoot (handled above). Anything else is an out-of-rail consumer.
      return false;
    }
  }

  // RECORD LIVENESS (bd 8h7d.5 Rule-13 round 1, finding F1). CLOSURE above
  // admits a `cq_measure` / `ret` user of a rail value at ANY position, and that
  // admission was itself a silent miscompile: `for (…) { last = q; q += off; }
  // return cq_measure(last);` emitted `measure(h)` AFTER the loop and measured
  // `q0+3k` where the source says `q0+3(k-1)`. The one out-of-loop rail read that
  // is sound is the state the register actually holds at the exit; the fence
  // decides that POSITIONALLY (see `staleRailRecordRead`) rather than by naming a
  // member, because in an unrotated loop the header phi IS that state.
  //
  // Asked PER RAIL — a gate on a sibling rail mutates another wire and says
  // nothing about this record — and LOUDLY: no other owner catches it (measured;
  // the round-1 shape above compiled clean at ba35c1f), so falling through to
  // `declineClassicalMuxes` is not available here.
  {
    // Grouped in PROGRAM ORDER, from the function rather than from `railRoot`.
    // This loop DIAGNOSES, and `railRoot` is a `DenseMap` whose pointer-hashed
    // iteration order would make WHICH offending consumer gets named (and which
    // `!dbg` location the error carries) vary between runs on the same module.
    // The DECISION was deterministic either way — any offender declines — but a
    // wandering source location is exactly the kind of thing that reads as a
    // flaky test later. `MapVector` keeps the root order stable too; round 2's
    // chains are already built in a deterministic order.
    MapVector<Value *, SmallVector<Value *, 8>> ByRoot;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto It = railRoot.find(&I);
        if (It != railRoot.end())
          ByRoot[It->second].push_back(&I);
      }
    // bd r2j3.13 — the SKIP set is the root's peeled header chains
    // (`ChainSkip`), never all of `railRoot`: an op the fixpoint absorbed OFF
    // the chain is a gate AND a read, and is asked like any reader. `KV.second`
    // (every rail value of the root) stays the gate seed.
    for (auto &KV : ByRoot)
      if (Instruction *Bad = staleRailRecordRead(KV.second, GateCalls, taint,
                                                 &ChainSkip[KV.first])) {
        diagnose(Bad, kMsgRailRecordStale);
        return true;  // recognized but unlowerable record escape — loud decline.
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
      markInPlaceRailOp(BO, taint);  // + the proven rail's operand INDEX (eqpx).

  // WRITER 1 OF `taint.ClaimedRailRoots` (bd 3qlq Inc 1, the SECOND C-1 review
  // round, finding F-C1-2(2a)). The round-2 `invariantRegisterRoots` must be able
  // to tell "this candidate is a rail a Case-A collapse already proved" from
  // "this candidate is an invariant register I must judge", and for an ONWARD
  // in-loop region the collapse happened HERE, at round 1, where no round-2 local
  // set can carry it. Recorded per ROOT (the physical wire), which is the same
  // key `ChainsByRoot` and `markIfRailLocal`'s `onRail` use. The claim this
  // records is exactly the one this function just made: the closed self-cycle
  // (Risk 2), the clean classical-operand mint, the Rule-8 fan-out guard and the
  // `staleRailRecordRead` fence above. `tryBreak` is deliberately NOT a writer —
  // its rails belong to `lowerBreakReversePlay`, which has its own capture and
  // reversal discipline, and admitting them here would skip a judgement on a
  // proof this set does not carry.
  // ⭐ PER-LOOP KEY (C-1 round 3, F-C1B-2): the pair `(root, L's header)`, so a
  // claim this loop made cannot satisfy clause (0) for a DIFFERENT loop that
  // reads the same rail — the property being recorded is "*this* loop's collapse
  // proved this rail", not "somebody's did".
  for (auto &KV : railRoot)
    taint.ClaimedRailRoots.insert({KV.second, L->getHeader()});

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
//
// RETURNS whether it MARKED (bd `test_C_libtooling-tu9q`, 2026-09-15). It used to
// be `void`, and the caller had no way to tell "marked" from "refused" without
// re-deriving the predicate or counting set members — a count that is ambiguous
// the moment a nested loop's blocks are already present from an outer one. The
// bool is read by exactly ONE caller (`lowerLoops`) for exactly ONE purpose: to
// offer the ROOT-MINT escape below **only where this marker refused**, which is
// what makes that offer provably ADDITIVE (see the call site).
// bd 01po.19 S6: does `L` load or store a `!cq.railwindow` cell?
bool loopTouchesRailWindow(const Loop *L) {
  for (BasicBlock *BB : L->blocks())
    for (Instruction &I : *BB)
      if (Value *P = getLoadStorePointerOperand(&I); P && railWindowOfPointer(P))
        return true;
  return false;
}

bool markIfIterationLocal(Loop *L, TaintSet &taint, LoopInfo &LI) {
  if (taintedExit(L, taint))
    return false;  // Q1 quantum-bounded — never Case B.
  BasicBlock *Header = L->getHeader();
  bool AnyTainted = false;
  for (BasicBlock *BB : L->blocks()) {
    // (L2) tainted control in the body ⇒ the existing ControlDetect owner's.
    Instruction *T = BB->getTerminator();
    if (isTaintedBranchTerminator(T, taint))  // bd dm7f.24: the one spelling.
      return false;
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
          return false;
      continue;
    }
    for (Instruction &I : *BB) {
      // (L3) tainted-index memory in the body ⇒ the existing kMsgQramLoop owner's.
      // bd 01po.19 S4: a rail stored at a CLASSICAL address into a
      // `!cq.railwindow` handle cell is not tainted-index memory — it is the
      // cell's kept carrier (the spine never reverses it, `isTerminalHandle`),
      // and the cell READ that names it next trip is a BORROWED root, defined
      // in `L` and owned by the array, never by this trip's reversal.
      if (isa<GetElementPtrInst>(I) || isa<LoadInst>(I) || isa<StoreInst>(I))
        for (Value *Op : I.operands())
          if (taint.Tainted.count(Op)) {
            auto *SI = dyn_cast<StoreInst>(&I);
            if (SI && Op == SI->getValueOperand() &&
                Op != SI->getPointerOperand() &&
                railWindowOfPointer(SI->getPointerOperand()) &&
                !taint.Tainted.count(SI->getPointerOperand()))
              continue;
            return false;
          }
      const bool TI = taint.Tainted.count(&I);
      // A tainted HEADER phi is a loop-carried persistent rail (Case A / X1),
      // not an iteration-local temp.
      if (TI && isa<PHINode>(I) && BB == Header)
        return false;
      if (TI) {
        AnyTainted = true;
        // Every tainted value defined in L must be used ONLY in L (nothing
        // escapes the loop — the last iteration's value never reads downstream).
        for (User *U : I.users())
          if (auto *UI = dyn_cast<Instruction>(U))
            if (!L->contains(UI->getParent()))
              return false;
      }
      // Every tainted OPERAND must be defined in L — a tainted value minted
      // OUTSIDE L and read inside (loop-invariant) is a persistent register that
      // accumulates across iterations, NOT iteration-local.
      for (Value *Op : I.operands())
        if (taint.Tainted.count(Op)) {
          auto *OpI = dyn_cast<Instruction>(Op);
          if (!OpI || !L->contains(OpI->getParent()))
            return false;
        }
    }
  }
  if (!AnyTainted)
    return false;  // a purely-classical loop — leave it byte-identical.
  for (BasicBlock *BB : L->blocks())
    taint.IterationLocalBlocks.insert(BB);
  return true;
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

namespace {

// ── bd test_C_libtooling-8h7d.5 (7.3 Inc 3) — ROUND 2: the post-flatten rail ──
//
// Contract + rationale in LoopPlan.h. This is the analysis for ONE loop; it
// reuses `peelInPlaceBase` / `isInPlaceGateOnArg0` / `inPlaceValueRailOperand`
// and the two shipped diagnostics rather than re-spelling any of them (Rule 14),
// so the round-1 and round-2 readings of "a persistent in-place rail" cannot
// drift.
//
// TRI-STATE, not a bool (bd 8h7d.5 Rule-13 round 1). The caller must be able to
// tell a DECLINE from a COLLAPSE: `markIfRailLocal` grants the spine a permission
// to discharge inside the body, and granting it on top of a loud decline is
// bookkeeping on a module that will never be emitted. The pre-round-1 spelling
// returned `true` for both and the caller marked either way.
enum class RailRound2 { NotClaimed, Declined, Collapsed };

// bd `test_C_libtooling-8h7d.14` — RE-OPEN A RAIL'S `-O1` CLOSED EXIT VALUE.
//
// `clang -O1` (IndVars) rewrites the exit value of an affine recurrence in its
// closed form. For `for (i < n) { …; q += 1; } return cq_measure(q);` the exit
// block computes `%x = add %q0, %n` from the ROOT record instead of reading the
// latch value through an LCSSA φ, while the in-body `q += 1` survives (the body
// still reads q). After the collapse `%x` is an out-of-place add on a register
// the loop's in-place `addc`s have already moved: `q0 + 2n`, a wrong value, and
// the record-liveness fence (rightly) declined it as a stale read of `%q0`.
//
// `%x` is not a computation the source asked for; it IS the loop's exit value,
// and ScalarEvolution says so: SCEV(`%x`) == SCEV-at-exit(latch value). Where it
// does, `%x` is replaced by the φ `-O1` would have written, `phi [LatV, latch]`
// in the dedicated exit block, and erased. That φ is an ordinary member of the
// rail's renaming closure (step (5) collapses it onto the root), and its readers
// are asked positionally by the same fence, so a reader past a later gate still
// declines. Equality is the INTEGER value in every computational-basis branch,
// which is exactly what the in-place permutation gates preserve; a reversible
// add or xor on the register realizes the same map.
//
// SCOPE, each conjunct a guard against a different misreading:
//   * the exit block `E` is unique and its ONLY predecessor is the latch, so `%x`
//     runs only after a completed trip (SCEV's exit value is the value at the
//     last iteration; a zero-trip path never reaches `E`);
//   * `%x` is dominated by `E`, outside `L` and at `L`'s parent loop depth (not
//     re-run by a later loop), tainted, of the latch value's type, and a DIRECT
//     user of an out-of-loop chain member (root or pre-header chain) — so the
//     erased op leaves no tainted intermediate behind (bd r2j3.7's dead tainted
//     pure op);
//   * the exit SCEV is computable and loop-invariant for `L`.
// Round 1 (`tryCaseA`) is not a caller: a closed recurrence whose in-body update
// survives needs another in-body reader of the rail, and round 1's COVERAGE
// refuses every such reader but a measure. Returns the number re-opened.
unsigned reopenClosedRailExits(Loop *L, PHINode &P,
                               ArrayRef<Value *> ChainMembers,
                               DominatorTree &DT, LoopInfo &LI,
                               TaintSet &taint) {
  BasicBlock *Latch = L->getLoopLatch();
  BasicBlock *E = L->getExitBlock();
  if (!Latch || !E || E->getSinglePredecessor() != Latch)
    return 0;
  Value *LatV = P.getIncomingValueForBlock(Latch);
  SmallVector<Instruction *, 2> Cands;
  for (Value *M : ChainMembers) {
    auto *MI = dyn_cast<Instruction>(M);
    if (!MI || L->contains(MI))
      continue;
    for (User *U : M->users()) {
      auto *X = dyn_cast<Instruction>(U);
      if (!X || isa<PHINode>(X) || L->contains(X) ||
          !taint.Tainted.count(X) || X->getType() != LatV->getType() ||
          !DT.dominates(E, X->getParent()) ||
          LI.getLoopFor(X->getParent()) != L->getParentLoop() ||
          is_contained(Cands, X))
        continue;
      Cands.push_back(X);
    }
  }
  if (Cands.empty())
    return 0;
  Function &F = *L->getHeader()->getParent();
  AssumptionCache AC(F);
  TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo TLI(TLII);
  ScalarEvolution SE(F, TLI, AC, DT, LI);
  const SCEV *ExitS = SE.getSCEVAtScope(SE.getSCEV(LatV), L->getParentLoop());
  if (isa<SCEVCouldNotCompute>(ExitS) || !SE.isLoopInvariant(ExitS, L))
    return 0;
  PHINode *Exit = nullptr;
  unsigned N = 0;
  for (Instruction *X : Cands) {
    if (SE.getSCEV(X) != ExitS)
      continue;
    if (!Exit) {
      Exit = PHINode::Create(LatV->getType(), 1, "cq.rail.exit");
      Exit->insertBefore(E->getFirstNonPHI());
      Exit->addIncoming(LatV, Latch);
      taint.Tainted.insert(Exit);
    }
    X->replaceAllUsesWith(Exit);
    taint.Tainted.erase(X);
    taint.BirthOrder.erase(X);
    X->eraseFromParent();
    ++N;
  }
  return N;
}

RailRound2 collapseRailPhisIn(Loop *L, Function &F, TaintSet &taint,
                              const SmallPtrSetImpl<CallInst *> &GateCalls,
                              DominatorTree &DT, LoopInfo &LI,
                              SmallPtrSetImpl<Value *> &RootsOut) {
  BasicBlock *Header = L->getHeader();
  BasicBlock *Latch = L->getLoopLatch();
  if (!Latch)
    return RailRound2::NotClaimed;  // multi-latch — unproven, as round 1 (Risk 2).

  // (1) Recognise every collapsible rail phi. PURE ANALYSIS — no mutation until
  //     the whole header has been classified, so an inter-phi reference cannot
  //     read an already-erased phi (the round-1 `Collapse` precedent).
  DenseMap<PHINode *, Value *> Collapse;    // phi → root mint
  SmallVector<Value *, 8> RailMembers;      // every value on an accepted chain
  // The SAME members, grouped PER PHYSICAL WIRE — i.e. keyed on the ROOT MINT,
  // which is exactly one `cqrt_alloc` (rotation lowering RAUWs every member of a
  // root's chain to that one handle). The fan-out guard below is per value and
  // does not care; the F1 record-liveness fence does, in BOTH directions:
  //   * two chains rooted at DIFFERENT mints are two registers, and one's gates
  //     must never stale the other's record — that is what makes two independent
  //     registers with their own tainted `if`s in one loop lowerable;
  //   * two chains rooted at the SAME mint are ONE register wearing two SSA names
  //     (`int a = q, b = q;` — an alias, never a copy; Rule 8), so each one's
  //     gates DO stale the other's records and the two must be merged.
  // Keying on the root is the only spelling that gets both, and it is the same
  // grouping round 1 uses (`ByRoot` over `railRoot`) — Rule 14, ONE predicate
  // asked twice, not two that agree today.
  MapVector<Value *, SmallVector<Value *, 8>> ChainsByRoot;
  for (PHINode &P : Header->phis()) {
    if (!taint.Tainted.count(&P))
      continue;  // classical induction phi — not a rail.
    if (P.getNumIncomingValues() != 2)
      continue;  // multi-entry header phi — leave it (declineClassicalMuxes).
    Value *LatV = nullptr, *PreV = nullptr;
    for (unsigned i = 0; i < 2; ++i) {
      BasicBlock *IB = P.getIncomingBlock(i);
      if (IB == Latch)
        LatV = P.getIncomingValue(i);
      else if (!L->contains(IB))
        PreV = P.getIncomingValue(i);  // the external (entry/guard) edge.
    }
    if (!PreV || !LatV)
      continue;  // not the clean latch + external-entry pair.

    // (Risk 2, verbatim from round 1) The latch incoming must peel — through
    // IN-PLACE gates ONLY — back to the phi itself: a CLOSED self-cycle, i.e.
    // one persistent rail whose handle is the same qubit every iteration. A
    // latch that peels to a fresh value-op rail is X1, the cross-iteration
    // dirty rail, and it declines LOUDLY here rather than silently collapsing a
    // loop-variant handle.
    if (peelInPlaceBase(LatV, GateCalls, taint) != &P) {
      // bd `test_C_libtooling-zujr` / bd `ej5w` — the ROUND-2 twin of `tryCaseA`'s
      // X1 widening, and it MUST move with it (SCOPE_L1a). `continue` leaves the φ
      // uncollapsed for `promoteLoopCarriedHandleSeeds`, which runs after this
      // stage and is the only granter of the `declineClassicalMuxes` accept — so
      // an unpromotable φ still declines, loudly, one stage later.
      if (loopCarriedHandlePhi(P, L, taint, GateCalls))
        continue;
      Value *LatBase = peelInPlaceBase(LatV, GateCalls, taint);
      if (taint.Tainted.count(LatBase)) {
        diagnose(&P, kMsgCrossIter);
        return RailRound2::Declined;
      }
      continue;  // unclassifiable either way — leave it for the mux guard.
    }
    // The external incoming must peel to a classical-operand `cq_theta` MINT
    // that dominates the loop (the rail origin) — the value every rail member
    // RAUWs onto at rotation lowering, and therefore the only sound collapse
    // target. LIFTED to `railPhiRootMint` (above) since bd drbq Inc 3, because
    // `ArmClassify`'s R7-loop clause (b') must ask the identical question at
    // DETECTION time — read that function's header for why, and for the one
    // seam (finding the external incoming) the two callers do not share.
    Value *Root = railPhiRootMint(P, L, GateCalls, taint, DT);
    if (!Root)
      continue;  // not a clean rail mint — leave it.

    // Collect the chain members (root → … → PreV → phi → … → LatV) so the
    // fan-out guard and the in-place marking below see every one of them.
    // Walked with `peelInPlaceStep` — the SAME edges `peelInPlaceBase` walked to
    // prove the two endpoints above, so the enumeration cannot run past the base
    // and cannot disagree with the proof it is enumerating (Rule 14). Both walks
    // TERMINATE: each step ascends the arg-0 / rail-operand def chain, which is
    // acyclic in SSA outside phis, and a phi ends the walk (`peelInPlaceStep`
    // returns null for it).
    SmallVector<Value *, 8> Chain;
    Chain.push_back(&P);
    for (Value *V = LatV; V != &P;) {
      Chain.push_back(V);
      Value *Next = peelInPlaceStep(V, GateCalls, taint);
      if (!Next)
        break;  // cannot happen (the peel above reached `&P`); defensive.
      V = Next;
    }
    for (Value *V = PreV; V != Root;) {
      Chain.push_back(V);
      Value *Next = peelInPlaceStep(V, GateCalls, taint);
      if (!Next)
        break;  // cannot happen (the peel above reached `Root`); defensive.
      V = Next;
    }
    Chain.push_back(Root);
    RailMembers.append(Chain.begin(), Chain.end());
    auto &Merged = ChainsByRoot[Root];
    Merged.append(Chain.begin(), Chain.end());
    Collapse[&P] = Root;
    RootsOut.insert(Root);
  }
  if (Collapse.empty())
    return RailRound2::NotClaimed;

  // (1b) bd 8h7d.14 — each claimed rail's `-O1` CLOSED exit value (`%q0 + n`)
  //      becomes the LCSSA φ it replaced, BEFORE the fences below ask about
  //      it (see `reopenClosedRailExits`). From here on this function returns
  //      Declined or Collapsed, never NotClaimed, and the rewrite is an
  //      integer-value identity either way.
  for (auto &KV : Collapse)
    reopenClosedRailExits(L, *KV.first, ChainsByRoot[KV.second], DT, LI,
                          taint);

  // (2) FAN-OUT / linear-lineage guard (Rule 8 no-cloning) — the SAME guard
  //     round 1 applies, for the same reason: a rail value read by TWO in-place
  //     mutators would have both serialised onto the one handle, corrupting
  //     both (`rz(h,1); rz(h,2)` = Rz(3), not the source's Rz(2)). The emitted
  //     region stream is NOT counted here and must not be (round-1 review of
  //     drbq Inc 2a, L2 N-3, split the reason in two):
  //       * Every emitted call — compare templates and their `_unc` strips, the
  //         kickback `cqrt_rz_i1`, `cqrt_x`, the controlled copies, the park's
  //         `cqrt_cswap` — is rejected BY CONSTRUCTION: none is in `GateCalls`
  //         (which holds only the collected front-end `@cq_theta` sites) or is a
  //         `BinaryOperator`, so `isInPlaceGateOnArg0` /
  //         `inPlaceValueRailOperand` cannot match it.
  //       * The drbq Inc-2a CONTROL-IN-PLACE Rz arm (a hoisted `@cq_phi_`) was
  //         excluded BY PREDICATE, `isHoistedRegionArmGate` at the loop below,
  //         which is vacuous since 3qlq. The Ry arm's hoisted `cq_theta` is a
  //         chain MEMBER under M-β and needs no exemption (that predicate's
  //         header has the argument).
  //
  //     A `BinaryOperator` CONSUMER IS COUNTED ONLY IF IT WILL ACTUALLY BE
  //     LOWERED IN PLACE (bd 8h7d.5 Rule-13 ROUND 4, finding OD-A) — the
  //     `railValueConsumerDisposition` question, shared with round 1 and with
  //     `collectRailGates` (Rule 14). Asking the dtzb SHAPE alone counted a
  //     DERIVED-CONDITION temp: `clang -O1` canonicalizes the owner's own
  //     `if (q > 5 && q < 20)` to `%t = add %q, -6; icmp ult %t, 14`, and `%t`
  //     was tallied beside the arm's real `cq_phi` — a loud `kMsgRailFanout` on a
  //     program whose hand-unrolled twin compiles. `%t` is inside the loop body
  //     and is neither a chain member nor marked, so M-C's G5 refuses it OUTRIGHT
  //     and `lowerOps` mints it a fresh rail; it never touches the loop-carried
  //     register and was never a second mutator.
  //
  //     THE ORDERING IS WHY `Claimed` EXISTS. This guard runs BEFORE step (3)
  //     marks, so `taint.InPlaceRailOps` is still empty for this loop; passing
  //     `RailMembers` (exactly what step (3) will mark) makes the answer
  //     order-independent. A member is `InPlace`; an off-chain in-loop BO is
  //     `OutOfPlace`; an off-chain STRAIGHT-LINE BO stays `Unproven` and is still
  //     counted, because M-C genuinely does fire post-loop (probe r3h/b4) and
  //     no one here can predict G6/G7. Prime Directive: only the case with a
  //     PROOF is dropped.
  SmallPtrSet<const Value *, 32> Claimed(RailMembers.begin(), RailMembers.end());
  for (Value *V : RailMembers) {
    SmallVector<Instruction *, 2> InPlaceUsers;
    for (User *U : V->users()) {
      if (auto *CI = dyn_cast<CallInst>(U)) {
        // The region's OWN hoisted arm gate is not a second mutator — see
        // `isHoistedRegionArmGate` for the full argument (bd drbq Inc 2a). This
        // is the Inc-2a spelling of the premise the block comment above states:
        // "the emitted region stream is NOT counted here and must not be".
        if (isInPlaceGateOnArg0(CI, V, GateCalls, taint) &&
            !isHoistedRegionArmGate(CI, taint))
          InPlaceUsers.push_back(CI);
      } else if (auto *BO = dyn_cast<BinaryOperator>(U)) {
        if (railValueConsumerDisposition(BO, V, taint, Claimed) >
            RailValueUse::OutOfPlace)
          InPlaceUsers.push_back(BO);  // `Unproven` counts — see the enum's note.
      }
    }
    if (InPlaceUsers.size() > 1) {
      diagnose(InPlaceUsers.front(), kMsgRailFanout);
      return RailRound2::Declined;  // unlowerable fan-out — loud decline.
    }
  }

  // (2b) RECORD LIVENESS (bd 8h7d.5 Rule-13 round 1, finding F1) — THE HALF THIS
  //      ROUND SHIPPED WITHOUT. Round 1's COVERAGE/CLOSURE is deliberately not
  //      re-proved here (see LoopPlan.h: the post-flatten body legitimately
  //      contains the region's own emitted stream and a derived condition's
  //      iteration-local rails, which CLOSURE would refuse). But CLOSURE was
  //      carrying TWO obligations, not one, and only the first is inapplicable:
  //        (i) "every tainted body value is on the rail" — a CLAIM condition,
  //            about whether round 1 may own the loop. Not ours; dropped, rightly.
  //       (ii) "a rail record is only read where the register still holds it" —
  //            a UNITARY condition, and it is exactly as binding after the
  //            flatten as before it. Dropping it made (pre-3qlq register form)
  //            `for (…) { if (q==5) q=cq_phi(q,PI); acc = q*7; q += 3; }` emit
  //            the `mul` in the EXIT block against the post-loop register: a
  //            different unitary, `opt` exit 0, verify-clean, stage-2b clean.
  //      Asked PER ROOT MINT (`ChainsByRoot`) — one root is one `cqrt_alloc`, one
  //      physical wire — and that grouping is load-bearing in BOTH directions: a
  //      gate on a DIFFERENT root's rail relabels another register and must not
  //      stale this record (else two independent registers in one loop are
  //      permanently unlowerable, control_swap_inloop_two_registers.ll), while two
  //      chains sharing ONE root are one register wearing two SSA names and MUST
  //      interfere (lowering_reject_inloop_rail_alias_shared_mint.ll — which the
  //      fan-out guard cannot catch, because it counts in-place users PER VALUE
  //      and the shared mint's users there are the phis).
  //      RUNS AFTER the fan-out guard so the Rule-8 message keeps its programs.
  for (auto &KV : ChainsByRoot)
    if (Instruction *Bad = staleRailRecordRead(KV.second, GateCalls, taint)) {
      diagnose(Bad, kMsgRailRecordStale);
      return RailRound2::Declined;
    }

  // (3) Issue dtzb — MARK EVERY IN-PLACE VALUE RAIL SELF-UPDATE, exactly as
  //     round 1 does, and this line is NOT optional bookkeeping: it is what makes
  //     the collapse SOUND for a rail carrying `q += c`.
  //
  //     MEASURED SILENT MISCOMPILE WHEN IT IS MISSING (found 2026-08-29 while
  //     re-measuring `example/grover/grover_loop_frontier.c` with only the
  //     in-loop offsets removed — `opt` exit 0, verify-clean, strict
  //     free-pairing CLEAN, and the only outward sign was one M-A WARNING).
  //     `cq_theta(&a,.5); a += cq_off;` before a loop puts the `add` on the
  //     rail's PRE-header chain, so the header phi's external incoming peels
  //     THROUGH it to the mint — and collapsing the phi to that mint RAUW's every
  //     in-loop use to the PRE-OFFSET handle. `lowerOps` then emits the add
  //     out-of-place into a fresh rail nothing reads, and the whole loop computes
  //     on `a`, not on `a + off`. The wrong unitary, with the right shape.
  //
  //     Marking records the op only (no mutation). The op's result goes use-empty
  //     after the collapse; `lowerOps` collects it by TAINT MEMBERSHIP, not use
  //     count, and emits the side-effecting in-place `cqrt_{addc,xorc}_<W>`.
  //     Rotation gates need no marking (`lowerRotations` already lowers in place).
  for (Value *V : RailMembers)
    if (auto *BO = dyn_cast<BinaryOperator>(V))
      markInPlaceRailOp(BO, taint);  // + the proven rail's operand INDEX (eqpx).

  // Snapshot each rail's GATES and SURVIVING members before step (4) erases the
  // header phis — step (5) needs both and the phis will be gone. Gates are
  // `cq_theta` calls and in-place `add`/`xor`, none of which the collapse erases.
  DenseMap<Value *, SmallPtrSet<const Instruction *, 8>> GatesByRoot;
  DenseMap<Value *, SmallPtrSet<const Value *, 16>> LiveByRoot;
  for (auto &KV : ChainsByRoot) {
    collectRailGates(KV.second, GateCalls, taint, GatesByRoot[KV.first]);
    for (Value *V : KV.second)
      if (!isa<PHINode>(V))
        LiveByRoot[KV.first].insert(V);
  }

  // (4) Collapse. RAUW each rail phi to its root mint (the still-pre-lowering
  //     `cq_theta` SSA value, SAME type — no ill-typed phi survives) and erase
  //     after ALL RAUWs so inter-phi references resolve cleanly. This is exactly
  //     what rotation lowering would produce anyway (every in-place gate RAUWs
  //     its result to its arg-0 handle, so the phi would degenerate to
  //     `phi [%h, pre], [%h, latch]`); doing it HERE is what keeps the emitted
  //     stream identical to the hand-unrolled twin's and the loop ROLLED.
  //
  //     WRITER 2 OF `taint.ClaimedRailRoots` — see `tryCaseA`'s writer for what
  //     the record means and why it must come from the tree rather than from the
  //     caller's local set (bd 3qlq Inc 1, C-1 review round 2, F-C1-2(2a)).
  for (auto &KV : Collapse)
    taint.ClaimedRailRoots.insert({KV.second, L->getHeader()});
  for (auto &KV : Collapse)
    KV.first->replaceAllUsesWith(KV.second);
  for (auto &KV : Collapse) {
    taint.Tainted.erase(KV.first);
    taint.BirthOrder.erase(KV.first);
    KV.first->eraseFromParent();
  }

  // (5) A tainted phi ELSEWHERE whose every incoming now peels to the SAME root
  //     is a pure renaming of that rail (the rotated-loop exit/LCSSA merge, and
  //     any inner router the flatten left behind). Collapse it too — round 1's
  //     fixpoint (b) makes the identical claim. A phi mixing two roots, or one
  //     with an incoming off every rail, is LEFT for `declineClassicalMuxes`.
  for (bool Grew = true; Grew;) {
    Grew = false;
    SmallVector<std::pair<PHINode *, Value *>, 4> More;  // phi → its one root
    for (BasicBlock &BB : F)
      for (PHINode &P : BB.phis()) {
        if (!taint.Tainted.count(&P))
          continue;
        Value *Common = nullptr;
        bool Ok = true;
        for (Value *V : P.incoming_values()) {
          Value *Base = peelInPlaceBase(V, GateCalls, taint);
          bool OnRail = false;
          for (auto &KV : Collapse)
            if (Base == KV.second)
              OnRail = true;
          if (!OnRail) {
            Ok = false;
            break;
          }
          if (!Common)
            Common = Base;
          else if (Common != Base) {
            Ok = false;  // merges two distinct rails — not a clean renaming.
            break;
          }
        }
        if (Ok && Common)
          More.push_back({&P, Common});
      }
    // The SAME record-liveness fence, on the phis this fixpoint is about to
    // claim (bd 8h7d.5 Rule-13 round 1, finding F1 — completing its own edit).
    // A step-(5) phi is a pure RENAMING of the rail, so its consumers are rail
    // reads exactly like a chain member's, and they get the identical treatment:
    // the phi's own value is a faithful name for the register only where no rail
    // gate separates the two. Reached as a USER of the chain, each of these phis
    // was already cleared by (2b); this clears its CONSUMERS.
    //
    // It costs the shipped set nothing and is the reason: the `-O1` zero-trip
    // guard's exit phi (`phi [PreV, guard], [LatV, latchexit]`, the shape
    // slice_control_grover_loop_dynamic hands the pass) sits after the loop with
    // no rail gate below it, so `railGateBetween` is false and it collapses as
    // before.
    for (auto &KV : More) {
      auto GIt = GatesByRoot.find(KV.second);
      auto LIt = LiveByRoot.find(KV.second);
      if (GIt == GatesByRoot.end() || LIt == LiveByRoot.end())
        continue;  // not one of this round's roots — nothing snapshotted.
      SmallPtrSet<const Value *, 16> Skip(LIt->second);
      Skip.insert(KV.first);
      if (Instruction *Bad =
              staleReadOfValue(KV.first, Skip, GIt->second, GateCalls, taint)) {
        diagnose(Bad, kMsgRailRecordStale);
        return RailRound2::Declined;
      }
    }
    // `Common` DOMINATES every use of `P`: each incoming peels to it, so it
    // dominates every incoming definition, hence every predecessor of `P`'s
    // block, hence that block — so the RAUW is well-formed without a re-check.
    for (auto &KV : More) {
      KV.first->replaceAllUsesWith(KV.second);
      taint.Tainted.erase(KV.first);
      taint.BirthOrder.erase(KV.first);
      KV.first->eraseFromParent();
      Grew = true;
    }
  }
  return RailRound2::Collapsed;
}

// ── bd test_C_libtooling-8h7d.5 — the Case-B twin for a loop WITH a rail ─────
//
// `markIfIterationLocal` (Increment 2, 799w.2) certifies a loop in which EVERY
// tainted value is born and dies inside one iteration, and it refuses — by
// design — a loop that reads a tainted value minted OUTSIDE it. That refusal is
// exactly right for the shape it was written for and exactly wrong here: after
// the round-2 collapse the loop reads ONE loop-invariant tainted value, the
// PERSISTENT QUBIT RAIL, and its whole point is to persist. Without a marking
// the spine takes its §2.9 acyclic backstop (`InLoop && !IterLocal → return`,
// Uncomputation.cpp) and LEAKS the condition chain's rails once per iteration —
// measured on the customer program: three `cq_template_*` rails allocated and
// never uncomputed, never freed, where the hand-unrolled twin reverses and frees
// all three. A leak is not a miscompile, but it is a DIFFERENT CIRCUIT from the
// cleared unrolled one, and "the rolled trace equals the unrolled trace" is this
// increment's load-bearing witness.
//
// So: the same certificate, with the rail carved out and NOTHING else.
//   * a value ON the rail (it peels to a collapsed root) is exempt from the
//     escape check — it is the register, owned by the user's `cq_measure`, and it
//     is never a recovered DAG terminal (its def is OUTSIDE the loop, so
//     `FreePoint`'s `TermIterLocal` is false for it and the ordinary
//     Measured/Escaped path still decides it);
//
//     READ THAT EXEMPTION WITH ITS PROOF, NOT AS A PREMISE. This header used to
//     say a rail value "may be read from ANYWHERE and used ANYWHERE — it is the
//     register", and that sentence was FALSE and load-bearing (bd 8h7d.5 Rule-13
//     round 1, finding F1). A rail SSA name denotes one prefix of the rail's gate
//     sequence; it is a faithful name for the register only at positions where
//     the register still holds that prefix. `for (…) { if (q==5) q=cq_phi(q,PI);
//     acc = q*7; q += 3; }` (pre-3qlq) read it one `addc` too late: a different
//     unitary, `opt` exit 0 and stage-2b clean. The exemption is sound HERE only
//     because `collapseRailPhisIn` step (2b) has already PROVEN, for every rail
//     VALUE and every consumer, that no rail-relabelling gate separates the
//     record from its read (`staleRailRecordRead`) — and it declines loudly
//     otherwise, before this function is ever called. It is a conclusion, not an
//     axiom, and it must not outlive that call order. "Every rail VALUE" is the
//     word this sentence needed and did not have until bd 8h7d.5 Rule-13 ROUND 3
//     (finding F-3): it said "every rail MEMBER", and the fence really did only
//     enumerate chain members, so a record one hop off the chain was exempted
//     from a proof this exemption claims to rest on. Both halves are fixed —
//     `staleRailRecordRead` now enumerates the rail's closure, so the premise
//     stated here is the premise actually discharged;
//   * every OTHER tainted value must be defined in `L` and used only in `L` —
//     the unchanged iteration-local obligation;
//   * a tainted OPERAND that is neither on the rail nor defined in `L` is the
//     accumulating loop-invariant register the original guard was protecting
//     against, and still refuses the marking.
// The L2 (tainted control), L3 (tainted-index memory), subloop and
// tainted-header-phi refusals are copied VERBATIM — a surviving tainted header
// phi in particular means the collapse did NOT claim this rail, so nothing here
// may assume one.
//
// Marking is a PERMISSION, not a proof, and both consumers re-verify it:
// `Uncomputation` re-confirms every recovered gate sits in a marked block and
// `FreePoint` re-confirms the insertion point is in-body. Not marking is always
// safe (the leak); this predicate only ever grants.
// bd 3qlq Inc 1, the SECOND C-1 review round — finding **F-C1-1**. COMMIT the
// PREHEADER in-place value gates on a candidate's wire, so the FACT-time peel
// below can walk THROUGH them.
//
// THE DEFECT. `q = u; cq_theta(&q,.5); q = q + 7; for (i<K) if ((q>>i)&1) cq_phi(θ);`
// — one added line over C-1's own reproducer — leaked every per-trip which-path
// rail on 542d588 AND on the round-1 fix (rolled 3 `cq_template_and_i32_hl` / 0
// `_unc` against a hand-unrolled twin at 3/3 and a pre-3qlq ORACLE at 3/3
// IDENTICAL), at `opt` exit 0, verify-clean, STRICT stage-2b clean. It is
// PRE-EXISTING and F-L5-1-era, not round 1's: the same program with NO carried
// register leaks identically on both binaries (`p/x1_preadd_noR.c`, MEASURED).
//
// THE CAUSE IS A PRECONDITION, NOT THE PROOF — C-1's own sentence one stage
// over. Clause (ii) peels with `AsLowered=true`, i.e. through ops whose
// DISPOSITION is `InPlace`; a preheader `add` is neither in `taint.InPlaceRailOps`
// nor in a `blockCanRepeat` block, so `railValueConsumerDisposition` answers
// `Unproven`, the peel STOPS AT THE `add`, `dyn_cast<CallInst>` fails and the
// WHOLE extension returns false. Yet `lowerOps`' M-C then lowers that very op
// IN PLACE — `cqrt_addc_i32(h0, 7)` is in the emitted trace — so the register the
// body reads IS the root mint's rail and clause (ii)'s (I1) argument carries
// verbatim.
//
// SO ASK THE OWNER OF THAT DECISION, AND THEN COMMIT TO ITS ANSWER (Rule 14).
// "Will M-C lower this straight-line dtzb op in place?" has exactly ONE spelling
// in the tree — `ArithLowering::classifyInPlaceReassignment` (G1 the opcode
// family, G2 the shape+width, G3 the frozen in-place grid, G4 the stage-2b
// provable immediate, G5 the loop/cycle exclusion, G6/G7 no later read of the
// pre-op value). A second spelling here is the F-1/F-3 defect by construction.
// On success the op joins `taint.InPlaceRailOps`, which is a COMMITMENT rather
// than a hint: `OpcodeLowering` skips M-C classification for a marked op
// (`:263`) and routes it to `rewriteInPlaceValueRail` (`:350`), and M-C's own G5
// refuses a marked site. ONE FACT, BOTH READERS — the peel and the emitter
// cannot disagree about this op.
//
// ⚠ THE STABILITY CONJUNCT `P->hasOneUse()` IS **RETIRED** (bd
// test_C_libtooling-3qlq Inc 1, the FOURTH C-1 round; bd 7yd0 / OQ-C2-1 /
// review_inc2_r2 finding **F-I2-1**). What it used to say is kept below as
// HISTORY, because the argument is still quoted; what replaces it is the (1b)
// tripwire, which was not in the tree when the conjunct was written.
//
// HISTORY — the argument as shipped by round 2: "this runs BEFORE the round-2
// control fixpoint, while M-C runs after it, so a G6/G7 answer taken here could
// in principle go stale — and a stale 'in place' is a wrong unitary (the pre-op
// register read after the mutation), not a leak. `P->hasOneUse()` closes that
// window STRUCTURALLY rather than by an argument about emitters: the only use of
// `P` is this op's operand, and no later stage invents a read of a value that has
// none." ⚠ THE SECOND HALF OF THAT SENTENCE IS FALSE, and it was measured false
// TWICE, in the OPPOSITE direction each time:
//   * round 3's **F-C1C-1**: `hasOneUse` is a property of the **SSA VALUE**, and
//     the window it guards is a property of the **WIRE**. `lowerRotations` RAUWs
//     every member of a theta chain onto ONE `cqrt_alloc` handle, so a `P` with
//     exactly one use HERE can have two at `lowerOps` — and it was a CONFIRMED
//     silent miscompile (`int q2=q; cq_theta(&q2,.3); int a=q2+7; …; cq_measure(a)`
//     collapsed `q` and `a` onto one register). The conjunct did not stop that;
//     the (1b) tripwire does.
//   * this round's **F-I2-1**: the conjunct also refuses in the other direction,
//     for a reason that has nothing to do with a later read. A Phase-4 merge
//     out-rail `%out` is a `cqrt_alloc_<W>` the emitters WRITE before anything
//     reads it — two `cqrt_copy_<W>_controlled` for the 4.4 select merge and
//     Inc 2's value merge, one `cqrt_copy_<W>` for the Phase-4 value-arm route —
//     so `hasOneUse` is STRUCTURALLY false for EVERY merge out-rail, and it is
//     false because of a PRIOR WRITER, never a LATER READER. `hasOneUse` cannot
//     tell those apart; M-C's own G6/G7 pair can, and does (a prior void
//     `cqrt_*` writer is `provablyBefore` the op and is settled by
//     `priorUseIsSettled` arm (c)).
//
// ⭐ AND THE OBLIGATION THAT ARRIVED WITH THE REBASE ONTO INCREMENT 2: WHY THIS
// COMMIT CANNOT REACH AN INC-2 CHAIN HEAD (bd 3qlq, the round-4 lens finding
// **F-C1D-2**). Inc 2's value-arm merge is sound only because
// `classifyInPlaceReassignment`'s G6/G7 pair ALWAYS refuses M-C on a hoisted
// chain HEAD — the head reads the arm's input `Q`, and `Q` always has a second
// user (the second controlled copy, or the sibling arm's head), so the earlier
// head is refused by G6 and the later by G7. Read that function's "CONSUMER 2"
// comment; it is the whole argument, and until this round `P->hasOneUse()` was a
// SECOND, independent refusal of the same thing on THIS path. Removing it makes
// G6/G7 the sole net here, so the question "can this commit reach a chain head?"
// stops being academic. IT CANNOT, BY CONSTRUCTION, FOR TWO INDEPENDENT REASONS:
//
//   (A) DIRECTION. The walk below is `peelInPlaceStep`, which returns an
//       OPERAND — a rotation gate's arg 0, or `inPlaceValueRailOperand`'s tainted
//       side. It walks BACKWARD, from the loop-invariant candidate toward its
//       base. A chain head is a USER of `Q`, i.e. FORWARD of it, and lives on the
//       arm's side of the merge; it is never `Cur` on a backward walk from a
//       value the loop READS.
//
//   (B) THE PEEL STOPS AT THE `cqrt_alloc`. The merge-out-rail candidate reaches
//       this path from `collapseFlattenedLoopRails` (`CQLoweringPass.cpp`, the
//       ROUND-2 slot), i.e. AFTER `lowerControlRegions` has already emitted
//       `%out = call i32 @cqrt_alloc_<W>(i32 0)` and RAUW'd the merge to it. So
//       the chain is `%13 = add nsw %out, 7` → `%out`, and `peelInPlaceStep`'s
//       FIRST clause refuses a `CallInst` that is not in `GateCalls` (an alloc
//       never is) and returns null. The peel visits exactly {the preheader op,
//       `%out`} and stops; there is no edge from `%out` back to the copies that
//       wrote it, let alone to the chain that fed them.
//
// MEASURED rather than argued, on the rebased tree — AND SAY WHICH FIXTURE
// MEASURES WHAT, because the first version of this paragraph cited the wrong one
// and an independent lens caught it (bd 3qlq, the lens on the REBASED round-4
// tree, finding **F-C1E-1**; it built a binary with BOTH G6 and G7 made
// unreachable and re-ran the family against it).
//
//   * THE G6/G7 NET ITSELF is pinned by
//     `ir-pass/test/control_swap_value_ifelse_head_out_of_place.ll` — the fixture
//     `ArithLowering.cpp`'s own CONSUMER-2 comment names — which goes **RED
//     (CHECK, NOROUTE)** on that mutant, with its two controlled copies collapsing
//     onto ONE register. That is the artefact to re-derive before relaxing either
//     clause.
//   * `control_phase_kickback_mixed_value_merge_preadd_inloop.ll`'s `HCNT` prefix
//     asserts that the Inc-2 chain HEAD of the `q4b` shape is emitted OUT of place
//     onto a fresh rail (`cq_template_mul_i32_hl(%p, 5)` — `clang -O1`
//     reassociates `(p+3)*5` into `p*5 + 15`, so it is a `mul`, not an `add`) and
//     that `p`'s own rail carries NO in-place `cqrt_addc`/`cqrt_xorc` anywhere in
//     the module, while the SAME module's `%out` rail carries exactly one. ⚠ READ
//     THAT FOR WHAT IT IS: in THAT module the head is out of place because
//     `inPlaceValueRailOperand` admits `add`/`xor` only, so **G2's SHAPE half
//     refuses a `mul` whatever G6/G7 answer** — the fixture stays GREEN on the
//     G6/G7-disabled mutant, with its emitted copies byte-unchanged, so its
//     `HCNT-NOT` lines cannot falsify a relaxation of the pair. It pins the
//     *property* (head out of place, `%out` mutated in place beside it) on the
//     shape that made the commit fire; it does not pin the *net*. Its e2e pair is
//     `slice_control_phase_perbit_loop_value_merge_preadd{,_unrolled}.c`, which the
//     lens measured is blind to the same mutation (both goldens still match).
//   * `control_phase_kickback_mixed_value_merge_dtzb_head_preadd_inloop.ll` is the
//     one that DOES discriminate on this path: same idiom, but its chain head is a
//     dtzb-shaped `add` (`p + 3`), inside `inPlaceValueRailOperand`'s shape, so
//     nothing but G6/G7 stands between it and an in-place `cqrt_addc_i32` on `p`'s
//     rail. Its `HCNT` pins the head out of place and its `CSRC` pins the two
//     `cqrt_copy_i32_controlled` reading DISTINCT rails — the property the lens
//     measured collapsing on the mutant.
//
// SO THE COMMIT NOW ASKS EXACTLY TWO THINGS: the immediate is a `Constant`
// ((1a), below — MONOTONE, a property of the IR class), and
// `classifyInPlaceReassignment` — M-C's own fence, the ONE spelling (Rule 14) —
// says in place. THE SAFETY IS (1b), NOT A NEW PREDICATE. `lowerOps` re-asks
// that same fence under the FINAL `DominatorTree`/`LoopInfo` and the FINAL
// taint, and a changed answer is a LOUD `DiagnosticInfoUnsupported` with nothing
// lowered. So a commit that was true here and false at lowering — the whole
// class `hasOneUse` was reaching for, F-C1C-1 included — is a DECLINE, never a
// leak and never a wrong unitary. A structural stand-in for a temporal question
// is exactly what (1b) made unnecessary; keeping both meant paying an
// over-decline for a net the tripwire already holds.
//
// MEASURED, this round, on the pre-fix `main` binary (a3c1513) and on this one
// (rolled `cq_template_and_i32_hl` mints / `_hl_unc` discharges, against the
// hand-unrolled twin of the SAME source):
//   * `p/q5sel_preadd_{rolled,unrolled}.c` — a 4.4 select merge, `m = m + 7`,
//     then D4's per-bit loop: main **4/0 (44 lines) vs twin 4/4 (52)**; here
//     **4/4 = 4/4, traces BYTE-IDENTICAL at 52 lines**.
//   * `p/q4b_preadd_*.c` — the Phase-4 VALUE-ARM ROUTE out-rail (`cqrt_copy_i32`
//     into `%out`): main **4/0 (57) vs 4/4 (65)**; here **IDENTICAL 65 = 65**.
//   * `p/q7_k32_rolled.c` — the same select merge at K=32: main 32 mints / **0**
//     `_unc`; here **32/32**. The leak was O(K).
//   * `p/q5v_none*.c` (merge, NO preheader op) and
//     `p/q5ctl_theta_preadd_*.c` (theta root, WITH one) are the two boundary
//     controls: IDENTICAL on BOTH binaries, so the finding is the PRODUCT of the
//     two axes and this change moves neither axis alone.
// The `x2_preadd_keep.c` control (`int keep = q; q = q + 7; … measure(keep)`) is
// UNCHANGED and must stay so: M-C ITSELF goes out of place there (G6 refuses the
// later read), so `classifyInPlaceReassignment` returns false and this commit
// still refuses — now for the RIGHT reason rather than by a proxy.
//
// ⚠ THE STABILITY CONJUNCT WAS ONLY HALF THE WINDOW, AND THE OTHER HALF WAS A
// CONFIRMED SILENT MISCOMPILE (bd 3qlq Inc 1, the THIRD C-1 review round,
// finding **F-C1B-1**). The paragraph above reasons about **G6/G7** — a later
// READ of the parent — and `hasOneUse` is asked of `P`. The commit ALSO predicts
// **G2**, the SHAPE ("the other operand is CLASSICAL"), and nothing guarded that:
// `taint.Tainted` GROWS at `repropagateControlMerges`, because everything DERIVED
// from a 6.5/4.5 `%out` becomes tainted only at ROUND 2. So
//
//     int y=5; if (q>5) y=ext_f(7);   /* %out, tainted at emission        */
//     int w = y * 3;                  /* DERIVED: untainted until round 2 */
//     a = a + w;                      /* ONE tainted operand AT ROUND 1   */
//
// committed at round 1, and `lowerOps` then honoured the commitment
// unconditionally (`OpcodeLowering:263` skips M-C for a marked op, `:350` routes
// it to `rewriteInPlaceValueRail`, which never re-asks the shape) and emitted
// `call void @cqrt_addc_i32(i32 %h4, i32 %h_op)` — a QUANTUM RAIL HANDLE IN THE
// ABI's CLASSICAL-IMMEDIATE SLOT, printed by the runtime as the bare decimal `6`
// (`h6`'s id). The circuit computes `a + 6` where the source says `a + 3*y`, the
// `3*y` rail is never uncomputed and never freed, and with the operands commuted
// (`int w = y + 1;`) `rewriteInPlaceValueRail`'s `TL = Tainted.count(L)` picks the
// LEFT operand as the rail and MUTATES THE WRONG REGISTER. Four plain-C programs,
// both stems, `opt` exit 0, verify-clean, STRICT stage-2b `0 violation(s)`, all
// correct on 542d588 and on the round-1 fix. This is the 8h7d.5 lesson verbatim:
// **`hasOneUse` was asked of `P`, and the answer that went stale was about `Imm`.**
//
// (1a) THE MONOTONE FENCE: `isa<Constant>(Imm)`. A `Constant` CAN NEVER BECOME
// TAINTED — that is the whole argument, and it is a property of the IR class, not
// a prediction about a later stage. It is CHECKED rather than assumed, and the
// check already exists in the tree: `IOSinkLowering.cpp:295` enumerates every
// `taint.Tainted.insert(` site in `ir-pass/src` and finds a `CallInst`, an
// `Instruction`, or (in the clone-LOCAL taint sets only) an `Argument` — never a
// `Constant`. RE-MEASURED at this HEAD (`grep -rn 'Tainted\.insert(' ir-pass/src`
// → 37 LINES, of which 2 are PROSE — `DagTraversal.cpp:127` and this very comment
// — i.e. **35 CODE sites**, the file's own count of 30 being older; the round-3
// lens re-measured it and found the figure right and the command's output
// mis-quoted beside it, F-C1C-E): the property still holds at every one. So
// G2's "exactly one tainted operand" cannot change answer for a
// constant-immediate op between here and `lowerOps`.
// MEASURED to keep every shipped customer of this path (`r2`'s `7`, `r71`'s `9`,
// `x1`'s `7`, `z7`'s `-7`; `r33`/`r35`/`r40` have no preheader op at all) and to
// refuse all four reproducers. Its ONE cost is `p/z21_preadd_volatile_imm.c` — a
// `volatile` load as the immediate, which M-C itself still accepts at `lowerOps`
// — which returns to the pre-round-2 leak. That is the Prime-Directive direction
// and it is recorded (PRD §0 E2), not regretted.
//
// (1b) AND A LOUD TRIPWIRE AT `lowerOps`, because a fence nobody re-asks is a
// prediction. Every op committed here is recorded in
// `taint.PreLoopCommittedInPlaceOps`, and `lowerOps` re-asks THIS SAME
// `classifyInPlaceReassignment` under FINAL taint and a FINAL `DominatorTree` /
// `LoopInfo`; a changed answer is `DiagnosticInfoUnsupported` and nothing is
// lowered. A silent fallback to out-of-place is NOT sound there — the BODY
// marking this commit licensed (`markIfRailLocal` on the loop) already stands.
//
// Marks into `Marked` so the caller can ROLL BACK when the extension fails, which
// is what keeps this change a strict no-op for every module the extension does
// not serve. The rollback erases from BOTH sets (a stale entry in the tripwire
// set would re-ask a question about an op this path never committed).
void commitOutOfLoopInPlaceOps(Value *V, Loop *L, TaintSet &taint,
                               WidthDispatch &wd, const DominatorTree &DT,
                               const LoopInfo &LI,
                               const SmallPtrSetImpl<CallInst *> &GateCalls,
                               SmallVectorImpl<Instruction *> &Marked) {
  for (Value *Cur = V; Cur;
       Cur = peelInPlaceStep(Cur, GateCalls, taint, /*AsLowered=*/false)) {
    auto *BO = dyn_cast<BinaryOperator>(Cur);
    if (!BO || taint.InPlaceRailOps.count(BO))
      continue;  // a rotation gate / the base, or an op already committed.
    if (L->contains(BO->getParent()))
      return;  // in-loop: M-C's G5 refuses outright, so `OutOfPlace` is the
               // TRUE disposition and the FACT-time peel is already right.
    Value *P = inPlaceValueRailOperand(BO, taint);
    if (!P)
      return;  // not the dtzb shape — stop, and let the peel stop here too.
    // (1a) — the immediate must be a `Constant`, which can never become tainted.
    Value *Imm = BO->getOperand(0) == P ? BO->getOperand(1) : BO->getOperand(0);
    if (!isa<Constant>(Imm))
      return;
    if (!classifyInPlaceReassignment(BO, wd, taint, DT, LI))
      return;
    markInPlaceRailOp(BO, taint, /*ProvenRail=*/P);  // + the INDEX (eqpx).
    taint.PreLoopCommittedInPlaceOps.insert(BO);
    Marked.push_back(BO);
  }
}

// bd test_C_libtooling-3qlq Inc 1 part A, Rule-13 round-1 findings F-L7-2 /
// F-L5-1 / F-L2-1b — THE LOOP-INVARIANT-REGISTER ROOT SET.
//
// THE SHAPE. Owner decision D4 designates
//
//     for (i < K) if ((q >> i) & 1) cq_phi(θ);
//
// as THE way to express a register-wide Z under the register-free surface. Its
// loop body puts NO gate on `q`, so `q` is loop-INVARIANT: the header carries no
// tainted phi, `collapseRailPhisIn` finds nothing to collapse and returns
// `NotClaimed`, `markIfRailLocal` is never called, and `Uncomputation.cpp`'s
// in-loop guard (`canRepeat(&BB) && !IterationLocalBlocks.count(&BB)`) SILENTLY
// SKIPS the body's interior candidates. MEASURED at K=4 and K=32: `K` derived
// condition rails (`cq_template_and_i32_hl(h0, 1<<i)`) minted and NEVER
// `_unc`-reversed, never freed, while the HAND-UNROLLED spelling of the same
// source discharges all K.
//
// WHY THAT IS NOT A "RULE-6 SAFE LEAK". Each leaked rail holds one BIT of `q` —
// a which-path record — and this idiom exists to be a Grover phase oracle whose
// next step is a diffusion that interferes different `x`. Rule 8: "a permutation
// that leaves a rail dirty AND entangled still dephases under later
// interference." Rolled and unrolled are therefore DIFFERENT UNITARIES, which is
// the 8h7d.5 F-4 signature, and `free_pairing_check.py` is structurally blind to
// it (the leaked rail has no `cqrt_alloc`, so it was never counted as minted).
//
// WHY THE REGISTER SURFACE NEVER SHOWED IT: `q = cq_phi(q, θ)` in the arm made
// `q` loop-CARRIED, so the collapse claimed it, `Roots` was non-empty, the body
// was marked, and the pre-3qlq oracle emitted the discharging stream for the
// same program. This is a REGRESSION introduced by the surface change, not an
// inherited hazard.
//
// WHAT THIS FUNCTION DOES, AND THE ONE THING THAT MAKES IT SAFE. It supplies
// `markIfRailLocal` with the `Roots` that a loop-carried rail would have
// supplied, for a loop whose registers are loop-INVARIANT instead — and it
// admits ONLY a ROOT MINT (a classical-arg-0 `cq_theta` dominating the loop),
// never an arbitrary loop-invariant tainted value.
//
// THAT RESTRICTION IS THE WHOLE PROOF, and it is aimed squarely at the hazard
// `markIfRailLocal`'s own comment names ("a recovered gate in the PREHEADER (does
// not repeat) with `At` in a body marked here (repeats K times) would emit K
// adjoints against ONE forward gate. … Widening it — even 'just' to admit a
// hoisted loop-invariant temp — makes it reachable, and no shipped test would go
// red."). A root mint CANNOT be that gate:
//   * it lowers to `cqrt_alloc_<W>` + `cqrt_ry_<W>`, and
//     `ChainWalk::isInteriorTerminalHandle`'s clause (I1) excludes an
//     alloc-minted rail from the M-B interior partition OUTRIGHT, so the
//     interior driver can never claim it and can never place an `At` for it;
//   * a hoisted loop-invariant TEMPLATE rail (`int p = q * 3;` before the loop,
//     read by the body's condition) is exactly the admitted-temp case the
//     comment warns about — and this function REFUSES it, so such a loop is
//     still not marked and its rails still leak. MEASURED as the discriminating
//     control (`z_preheader_rail8`: 8 trips, the `xor`/`and` rails leak, before
//     and after this change, byte-identical).
//     ⚠ THAT RESIDUAL LEAK IS NOT UNIFORMLY BENIGN, AND SINCE 2026-09-14c PART
//     OF IT IS A LOUD DECLINE (bd `s82e`, owner ruling D4). Three shipped
//     fixtures of exactly this shape — `control_phase_kickback_mixed_{hoisted_
//     template,preheader_volatile_imm,short_sext}_leak_control.ll` — end with
//     `cq_theta(&q, .9); cq_measure(q)`, so the leaked per-bit copies of `q`
//     dephase a register that is afterwards ROTATED and MEASURED: rolled and
//     unrolled are DIFFERENT UNITARIES there, not the same one with more
//     garbage. All three headers used to call the leak "the PRIME-DIRECTIVE
//     disposition" / "the safe direction (Rule 6)"; all three were CONVERTED TO
//     DECLINES and the claim is corrected in each (CLAUDE.md L7-with-a-twist: a
//     record correction that is not applied at the site the reader reads is not
//     a correction, which is why this bullet moves too).
//     `declineDephasingUnmarkedLoopRails` (below) owns that sub-case. What
//     remains HERE — a hoisted-template-rail leak with NO later non-diagonal
//     gate on the copied register — still accepts and still leaks, and THAT is
//     what owner question Q-R1-1 is now about. Measured in the same sweep:
//     `control_phase_kickback_mixed_{claim_across_loops,onward_deadgate,
//     preheader_add_outofplace}_leak_control.ll` are UNMOVED.
//     ⚠ So do NOT read this bullet as "refusing the template rail is free". It
//     is free only where nothing interferes the register later; where something
//     does, refusing to mark costs a DECLINE, and bd `tu9q` is the capability
//     that would buy it back.
// Every value the body itself MINTS repeats exactly as its adjoint will, so the
// multiplicity the comment protects is 1:1 by construction here.
//
// THE MIXED LOOP — bd 3qlq Inc 1, the Rule-13 CLEARANCE finding **C-1** (the
// BLOCK verdict, 2026-09-05). Everything above describes a loop with NO carried
// rail at all, because that is the only loop this function could see: its one
// caller reached it on `RailRound2::NotClaimed`. A loop whose condition register
// is INVARIANT and which ALSO carries a second tainted register (`for (i<K) {
// if ((q>>i)&1) cq_phi(θ); cq_theta(&r, .1); }` — the flagship idiom the
// moment the body rotates an ancilla) returns `Collapsed` instead, so this
// function was never asked and `markIfRailLocal` refused on `%q` at its
// "accumulating loop-invariant tainted input" clause. MEASURED at 542d588:
// 3 `cq_template_and_i32_hl` mints, ZERO `_unc` discharges, against a
// hand-unrolled twin that discharges all three and a pre-3qlq ORACLE that
// discharged them too. Three entangled which-path records of `q`'s bits live
// through the `cqrt_ry_i32(%h,0.9)` diffusion that follows: rolled and unrolled
// are DIFFERENT UNITARIES, at `opt` exit 0, verify-clean, STRICT stage-2b clean.
//
// `CarriedRoots` is how that loop is served WITHOUT widening the proof by one
// inch. It is the set `collapseRailPhisIn` just filled (null on the `NotClaimed`
// path, where the behaviour is byte-identical to before). Two things follow from
// passing it, and both are deliberate:
//   * a candidate whose peeled root is ALREADY a carried root is SKIPPED, not
//     judged — see the (0) clause below;
//   * clause (i) is asked AFTER the collapse erased its rail phis, so it is not
//     vacuous there: it still refuses a loop where the collapse claimed ONE rail
//     and left ANOTHER tainted header phi standing (step (1) `continue`s for a
//     multi-entry phi, an unclean latch/entry pair, or a derived out-of-place
//     base). Such a loop is refused here and refused again by `markIfRailLocal`'s
//     own `TI && isa<PHINode>(I) && BB == Header` clause; it keeps today's leak.
//
// Returns true (and fills `RootsOut`) only when EVERY tainted value defined
// outside `L` and read inside it — bar the ones the collapse already owns — is
// such a root mint with no in-place gate inside `L`; false otherwise, in which
// case nothing NEW is admitted and the pre-existing leak stands (not marking is
// always safe). `RootsOut` is filled INCREMENTALLY and may hold roots when this
// returns false, so a caller that unions it into a live set MUST use a temporary
// (see `collapseFlattenedLoopRails`).
// ── bd `test_C_libtooling-tu9q` — THE MEASURE-OWNED INVARIANT RAIL ────────────
//
// `true` iff every user of `V` is a `cq_measure`. Such a rail is OWNED BY THE
// MEASUREMENT in BOTH spellings — it gets no adjoint and no free from either
// partition — so admitting it to `invariantRegisterRoots`' `RootsOut` cannot
// create the multiplicity hazard clause (ii)'s root-mint restriction exists to
// rule out. TWO independent mechanisms say so, and BOTH were read in source
// rather than assumed:
//
//   * `ChainWalk::isInteriorTerminalHandle` clause (I3) requires EVERY user to
//     satisfy `isInteriorConsumer`, and a measure call is none of its three
//     admitted shapes (an in-place gate, a template producer, a recorded flag
//     strip) — so such a rail never enters the M-B INTERIOR partition and the
//     interior driver never places an `At` for it;
//   * `FreePoint::computeFreePoint` returns `FreePointKind::Measured` the moment
//     it sees a measure sink among the users, with no adjoint and no free — so
//     the WHOLE-DAG partition never places one either.
//
// So the preheader forward gate whose `At` could land in a K-times body is
// unbuildable with this spelling too, by a DIFFERENT mechanism from the
// alloc-minted one and stated separately for exactly that reason.
//
// ⚠⚠ **AND THE ARGUMENT ABOVE IS THE WEAKER HALF. THE GROUND IS PHYSICS, NOT
// MULTIPLICITY** (Rule-13 round 2, 2026-09-15 — the reviewer's §I-3, landed at
// the site rather than left in a review file: `CLAUDE.md` L7-with-a-twist).
// Everything up to here argues that no `At` CAN be placed for this rail, which
// is a fact about the two partitions' bookkeeping and dies the day
// `isInteriorTerminalHandle` or `computeFreePoint` is re-spelled. The reason the
// rail is harmless does not depend on either: **a MEASURED rail is not a
// COHERENT which-path record.** The user's own `cq_measure` — the only consumer
// it has — collapses it in the computational basis, which is precisely why
// Rule 6 says the measurement OWNS such a handle and why
// `computeFreePoint` calls the kind `Measured` rather than `Leaked`. The Rule-8
// hazard this whole area exists for (*"a permutation that leaves a rail dirty AND
// entangled still dephases under later interference"*) needs the rail to be
// ENTANGLED at the interference; a rail every one of whose users is a measurement
// is not.
// MEASURED, and it is a NEGATIVE-control measurement rather than an assertion:
// `RotationLowering::warnLiveRecordRotations` — the stage whose whole job is to
// notice a live record standing at a rotation — is **SILENT (0 bytes of stderr)
// on BOTH HALVES of `review_r13_loop/probes/x1_iic_bodyrail_interfered{,_un}.c`**,
// a program that deliberately puts a (ii-c) rail beside an interfered register
// and accepts at 17 == twin 17; on the ORACLE that same stage FIRES with count 1
// on `b7b_w2k_interfered` and count 2 on `b11_cmp_rail_data`. So the instrument
// that sees this class was pointed at this shape and found nothing there.
// ⚠ KEEP BOTH HALVES. The multiplicity half is what makes the admission safe
// for the SPINE's bookkeeping; the physics half is what makes it safe for the
// UNITARY, and it is the one that survives a change to either partition.
//
// WHY IT MATTERS: `-O1` LICM HOISTS a loop-invariant `y & 1` into the preheader,
// so the body of `w2k_noregion_invread` / `w2h_phase_inloop_invread` /
// `w2h3_select_iterlocal_invread` reads a TEMPLATE rail, not the register — and
// clause (ii) refused all three, taking the discharge of the body's genuinely
// iteration-local chain down with it (MEASURED on the ORACLE `0e280fc6…`: 16 vs
// 20, 30 vs 38, 44 vs 48 trace lines against their hand-unrolled twins).
// `invariantRegisterRootsImpl`'s own header records this as the
// `z_preheader_rail8` case it refuses; this is the measure-owned SLICE of it.
//
// ⚠ IT IS DELIBERATELY **NOT** `railIsInterior` (the `declineDephasingUnmarked
// LoopRails` helper below), even though the two agree on every program in the
// tree today. They ask DIFFERENT questions with DIFFERENT safe directions:
// `railIsInterior` asks *"would the hand-unrolled twin discharge this rail?"* to
// decide whether a leak is a DIVERGENCE, and a non-`Instruction` user is
// irrelevant there (it `continue`s past one); this asks *"is this rail PROVABLY
// never given an `At`?"*, where an unclassifiable user is an absence of proof and
// must REFUSE. Folding them into one predicate would need a direction parameter,
// which is how a shared predicate acquires a caller its argument does not reach
// (`CLAUDE.md` L3's mirror). ⚠ RETIREMENT TRIGGER: if `railIsInterior` ever
// grows a measure-independent clause, re-derive this one against it rather than
// assuming they still agree.
bool measureOwnedInvariantRail(Value *V) {
  bool AnyUser = false;
  for (User *U : V->users()) {
    auto *I = dyn_cast<Instruction>(U);
    if (!I)
      return false;  // a constant expression — no block, no proof.
    if (!isMeasureCall(I))
      return false;
    AnyUser = true;
  }
  return AnyUser;
}

// ── bd `test_C_libtooling-tu9q` clause (ii-d)'s OBLIGATION LEDGER ────────────
//
// **WHY A LEDGER EXISTS AT ALL, and it is the reason clause (ii-d) is TOTAL
// rather than a prediction.** That clause grants a MARKING on a forecast about a
// PLACEMENT that a DIFFERENT FILE makes several stages later, over facts
// (`ControlOwnedRails`, borrowed-parent mutations, the convergence fixpoint) that
// are not final at marking time. If `Uncomputation` then refuses, the invariant
// rail LEAKS **and conjunct (1) of `declineDephasingUnmarkedLoopRails` has
// already been silenced by the marking** — the §0.1(b) shape, with no diagnostic
// anywhere. No fence in THIS file can see that outcome, because the outcome is
// produced after this file has finished.
//
// So the grant is RECORDED here and VERIFIED at the tail of `uncompute`, where
// the discharge is a FACT and not a forecast. That is the
// `declineSurvivingIntrinsicCalls` pattern (Rule 1: make a postcondition a
// CHECKED, LOUD property rather than a comment) — and, exactly as there, it is a
// diagnostic and not an `assert`, because Release builds have assertions off and
// Release is what every gate here runs.
//
// ⚠ `WeakTrackingVH`, and it is load-bearing in BOTH directions. `lowerOps` RAUWs
// the `mul`/`sext`/… this clause admitted to the `cq_template_*` CALL that
// replaces it, and a `WeakTrackingVH` FOLLOWS a RAUW — so the ledger names the
// LOWERED rail by the time the postcondition reads it, with no second lookup and
// no name-matching. A handle that goes NULL is a root that no longer exists
// (deleted, not lowered), and the postcondition treats that as DISCHARGED rather
// than as a violation: there is no rail left to leak. That is the same reasoning
// `recordRound1RailGrant`'s header gives for its own `WeakTrackingVH` roots.
//
// ⚠ NO NEW `TaintSet` FIELD, DELIBERATELY. A new member in the MIDDLE of that
// struct is the ODR/layout divergence that segfaulted `cq-opt` while
// `libCQPass.so` lowered correctly (bd `tu9q` IMPL_T2 §13). A function-local
// static is the pattern this file already uses for `deferredDephasingSlot`.
//
// ⚠ CLEARED AT BOTH ENDS, for the reason bd `bbu0` gives for its own slot: a
// second module in the same process must never inherit the first one's ledger.
// `lowerLoops` clears it on entry (it is the FIRST writer's owner and runs once
// per module in BOTH pipeline entry points, `CQLoweringPass.cpp:500` and `:1171`),
// and the postcondition clears it after reading. Either alone would do; both is
// cheap and neither depends on the other having run.
std::vector<WeakTrackingVH> &exitDischargeObligations() {
  static std::vector<WeakTrackingVH> Ledger;
  return Ledger;
}

// bd `test_C_libtooling-tu9q` clause (ii-d) — FORWARD DECLARATION ONLY. The
// definition is at `:~4400`, inside a LATER anonymous-namespace block of this same
// TU; all unnamed-namespace blocks in one TU name the SAME namespace, so this is
// legal and sufficient. ⚠ DO NOT MOVE THE DEFINITION UP: Track S′ owns that
// function and moving it manufactures a merge conflict in the one file two
// sessions have already fought over.
bool mintsOutOfPlaceTemplateRail(Instruction *I, TaintSet &taint);

// bd `test_C_libtooling-tu9q` clause (ii-d) — "is this rail read ONLY by `L`?"
// `Loop::contains` (subloops included) is the right quantifier: the question is
// whether any reader sits outside the cycle whose EXIT the rail is to be
// discharged at. A non-`Instruction` user is unclassifiable and REFUSES, which is
// the safe direction for a GRANTING clause.
bool allUsersInside(const Value *V, const Loop *L) {
  for (const User *U : V->users()) {
    const auto *UI = dyn_cast<Instruction>(U);
    if (!UI || !L->contains(UI->getParent()))
      return false;
  }
  return true;
}

void recordExitDischargeObligation(Value *Root) {
  for (const WeakTrackingVH &H : exitDischargeObligations())
    if (H == Root)
      return;  // idempotent: the three `invariantRegisterRoots` call sites can
               // each re-derive the same root for the same loop.
  exitDischargeObligations().emplace_back(Root);
}

bool invariantRegisterRootsImpl(Loop *L, TaintSet &taint, WidthDispatch &wd,
                                const DominatorTree &DT, const LoopInfo &LI,
                                const SmallPtrSetImpl<CallInst *> &GateCalls,
                                SmallPtrSetImpl<Value *> &RootsOut,
                                const SmallPtrSetImpl<Value *> *CarriedRoots,
                                SmallVectorImpl<Instruction *> &Marked) {
  BasicBlock *Header = L->getHeader();
  // (i) NOTHING LOOP-CARRIED **THAT THE COLLAPSE DID NOT CLAIM**. A surviving
  //     tainted header phi means a rail DOES cross the back edge and nobody
  //     proved it — marking would grant a permission on an unproven rail. On the
  //     `Collapsed` path the claimed rails' phis are already ERASED by
  //     `collapseRailPhisIn` step (4) (it RAUWs each to its root mint and erases
  //     after all RAUWs), so this loop sees only the UNCLAIMED remainder, which
  //     is exactly the set that must still refuse.
  // ⚠ WITH ONE EXEMPTION, bd `test_C_libtooling-zujr`: THE LOOP-CARRIED HANDLE
  // VARIABLE. "A surviving tainted header φ means a rail DOES cross the back
  // edge and nobody proved it" is the premise, and for this φ the second half is
  // FALSE — `loopCarriedHandlePhi` proves it, and `promoteLoopCarriedHandleSeeds`
  // makes trip 1 name a register. It is not the collapse's to claim (the latch
  // incoming is a FRESH merge `%out`, not a closed self-cycle), so waiting for a
  // claim that can never come refused the marking for the whole loop — and then
  // `declineUnmarkedRolledIterLocal`'s conjunct 2 refused the module.
  //
  // ITS CHAIN GOES INTO `RootsOut`, NOT PAST IT. That is CLAUDE.md's L2 caught in
  // this very edit, and it is the same lesson clause (0) below records in
  // capitals: widening the SKIP alone would leave `markIfRailLocal` a `Roots`
  // without the carried register, so its "accumulating loop-invariant tainted
  // input" and "iteration-local temp escaping the loop" clauses would refuse on
  // the variable's own SSA names and nothing would be marked — the extension
  // returns TRUE and the leak stands.
  bool AnyCarried = false;
  for (PHINode &P : Header->phis()) {
    if (!taint.Tainted.count(&P))
      continue;
    if (!loopCarriedHandlePhi(P, L, taint, GateCalls))
      return false;
    SmallPtrSet<const Value *, 8> Chain;
    collectCarriedHandleChains(L, taint, Chain);
    for (const Value *V : Chain)
      RootsOut.insert(const_cast<Value *>(V));
    AnyCarried = true;
  }

  SmallPtrSet<Value *, 4> Cands;
  for (BasicBlock *BB : L->blocks())
    for (Instruction &I : *BB)
      for (Value *Op : I.operands()) {
        if (!taint.Tainted.count(Op))
          continue;
        auto *OpI = dyn_cast<Instruction>(Op);
        if (!OpI)
          return false;  // a tainted non-instruction operand — unclassifiable.
        if (L->contains(OpI->getParent()))
          continue;  // defined in the loop; `markIfRailLocal` handles it.
        Cands.insert(Op);
      }
  // ⚠ `AnyCarried` IS THE SECOND REASON THIS PATH CAN HAVE WORK TO DO (bd
  // `test_C_libtooling-zujr`). The early-out reads "no invariant register read —
  // nothing this path is for", and that is true of the shape this function was
  // built for. A loop-carried HANDLE variable supplies its roots from the header
  // φ instead of from a loop-invariant read, and the owner's cascade has no
  // invariant register at all: bailing here left `markIfRailLocal` unasked and
  // conjunct 2 refused the module.
  if (Cands.empty() && !AnyCarried)
    return false;  // no invariant register read — nothing this path is for.

  // (0-pre) F-C1-1 — commit each candidate's PREHEADER dtzb `add`/`xor` chain
  //         before anything peels, so clause (0)'s and clause (ii)'s FACT-time
  //         peels see the register rather than stopping at the first `add`. A
  //         SEPARATE loop over all candidates, not folded into the one below,
  //         because two candidates can share a chain and the peel of an EARLIER
  //         one must already see a LATER one's commitment.
  for (Value *V : Cands)
    commitOutOfLoopInPlaceOps(V, L, taint, wd, DT, LI, GateCalls, Marked);

  for (Value *V : Cands) {
    // (ii) A ROOT MINT ONLY — the same shape `railPhiRootMint` accepts: a
    //      COLLECTED `cq_theta` whose arg 0 is CLASSICAL. A derived base
    //      (`p = q * 5`) and every other template rail are refused here.
    //
    //      PEELED FIRST, through IN-PLACE gates, with `AsLowered=true` — the
    //      IDENTICAL call `markIfRailLocal`'s own `onRail` makes (Rule 14: the
    //      set this fills and the predicate that reads it must agree by
    //      construction, not by two spellings). Peeling matters for a real
    //      program: `q = u; cq_theta(&q,.3); cq_theta(&q,.1); for(…)` reads the
    //      SECOND theta, whose arg 0 is tainted. Keying on the un-peeled value
    //      refused it — a safe leak, but a rolled≠unrolled DIVERGENCE of exactly
    //      the class this whole path exists to close (MEASURED before the peel
    //      was added). Every member of that chain RAUWs to the ONE
    //      `cqrt_alloc` handle at rotation lowering, so peeling names the
    //      physical wire rather than an SSA name of it.
    Value *Root = peelInPlaceBase(V, GateCalls, taint, /*AsLowered=*/true);
    // (0) A CANDIDATE THE COLLAPSE ALREADY OWNS IS SKIPPED, NOT JUDGED — bd
    //     3qlq Inc 1, the CLEARANCE finding C-1. After `Collapsed` the body no
    //     longer reads the rail PHI; step (4) RAUW'd it to the root mint, so the
    //     carried register's own `%r0` is now a tainted value DEFINED OUTSIDE `L`
    //     AND READ INSIDE IT — i.e. a `Cand` here — whose in-loop user is the
    //     body's `cq_theta(&r, .1)`. Clause (iii) below would see that
    //     `isInPlaceGateOnArg0` user and refuse, taking the whole extension (and
    //     therefore the INVARIANT register's discharge) down with it. But the
    //     carried rail is not this function's to judge: `collapseRailPhisIn` has
    //     already proved it — the closed self-cycle (Risk 2), the Rule-8 fan-out
    //     guard (2), the record-liveness fence (2b) — and its root is in `Roots`
    //     already. Asked by the SAME `peelInPlaceBase(…, AsLowered=true)` spelling
    //     the carried set was keyed on and `markIfRailLocal`'s `onRail` will use,
    //     so the three cannot disagree about one value (Rule 14).
    //     ⚠ THE LOCAL SET IS ONLY HALF THE FACT (bd 3qlq Inc 1, the SECOND
    //     C-1 review round, finding **F-C1-2(2a)**). `CarriedRoots` is what
    //     `collapseRailPhisIn` filled IN THIS CALL, and the commonest mixed
    //     shape has its collapse in the OTHER one: when the in-loop region's
    //     condition reads a 6.5/4.5 `%out` rail the loop's control is CLASSICAL
    //     at round 1, so ROUND-1 `lowerLoops`/`tryCaseA` claims and collapses the
    //     carried rail, and by the round-2 pass there is no header phi left —
    //     `collapseRailPhisIn` returns `NotClaimed` and this set is empty, so
    //     clause (iii) refused on the carried root's in-body `cq_theta` and took
    //     the invariant register's discharge with it (MEASURED 3 mints / 0 `_unc`
    //     on `p/r33_onward_inv_only.c` and `p/r35_onward_diffusion.c`, against
    //     3/3 hand-unrolled, on BOTH the pre-fix and the round-1 binary).
    //     `taint.ClaimedRailRoots` is the same fact taken from the TREE, written
    //     at both Case-A collapse sites; the UNION is what makes the two calls
    //     answer alike. It is never inferred from "no header phi" — a DEAD
    //     in-body gate (`int t = r; cq_theta(&t,.1);`) has neither a phi nor a claim
    //     and must still be refused (`p/x3_deadgate_body.c`, still leaking).
    //     AND IT IS SKIPPED **INTO `RootsOut`**, NOT PAST IT — the 8h7d.5
    //     lesson caught in this very edit ("when you widen a set, ask what OTHER
    //     set was computed over the same closure"). Widening the SKIP alone left
    //     `markIfRailLocal` a `Roots` without the claimed rail, so its
    //     "accumulating loop-invariant tainted input" clause refused on the
    //     body's `cq_theta(%r0,.1)` and nothing was marked — the extension
    //     returned TRUE and the leak stood (MEASURED on `r33`/`r40`: `IRR TRUE
    //     roots=1` and no marking). On the `Collapsed` path the caller's set
    //     already holds it, so the insert is idempotent there and the two call
    //     sites become symmetric. The exemption it grants is the ONE
    //     `markIfRailLocal` documents — "a value ON the rail is the register" —
    //     and it rests on the SAME fences, asked by whichever collapse claimed
    //     the rail: `tryCaseA`'s Risk-2 self-cycle + clean mint + Rule-8 fan-out
    //     + `staleRailRecordRead`, or `collapseRailPhisIn`'s (1)/(2)/(2b).
    //     ⭐ AND THE CLAIM MUST NAME **THIS** LOOP (C-1 round 3, F-C1B-2).
    //     Round 2 keyed this set on the ROOT VALUE alone, module-wide, while the
    //     property being skipped on is PER-LOOP; a claim made for loop A then
    //     satisfied clause (0) for loop B, whose own clause (iii) question was
    //     never asked (MEASURED, `p/z32_claim_across_loops_nomeas.c`). See the
    //     set's own header for why a header-block key can only ever REFUSE.
    if ((CarriedRoots && CarriedRoots->count(Root)) ||
        taint.ClaimedRailRoots.count({Root, L->getHeader()})) {
      RootsOut.insert(Root);
      continue;
    }
    // (ii-c) OR A MEASURE-OWNED LOOP-INVARIANT RAIL — bd `tu9q`. See
    //        `measureOwnedInvariantRail` above for the two mechanisms that make
    //        the multiplicity hazard unbuildable for it. Asked of `V` (the value
    //        the body actually reads), not of `Root`: the peel is an IN-PLACE
    //        peel and a template rail has nothing to peel through, so the two
    //        coincide here — but the property being proved is about the value's
    //        USERS, and `V` is what has them.
    //        ⚠ `RootsOut` takes `Root`, not `V`, because `onRail` matches on
    //        `peelInPlaceBase(Op, AsLowered=true)` and a second key would make
    //        `markIfRailLocal` and this set disagree about one value (Rule 14).
    //        They are the same pointer for every shape this clause admits; the
    //        insert is written this way so a future in-place-peelable spelling
    //        does not silently fall out of the set.
    if (measureOwnedInvariantRail(V)) {
      RootsOut.insert(Root);
      continue;
    }
    // (ii-d) OR A HOISTED OUT-OF-PLACE TEMPLATE RAIL — bd
    //        `test_C_libtooling-tu9q`, the half that increment left. `int p = y*3;`
    //        LICM-hoisted into the preheader and read by the body's condition.
    //
    //        ⚠ **THE MULTIPLICITY ARGUMENT THAT LICENSES (ii), (ii-b) AND (ii-c)
    //        DOES NOT CARRY HERE, AND THAT IS THE WHOLE POINT OF THE CLAUSE.**
    //        Each of those three rests on the rail being a shape
    //        `ChainWalk::isInteriorTerminalHandle` (I1) CANNOT admit — a root mint
    //        and a merge out-rail are `cqrt_alloc_<W>` calls, a measure-owned rail
    //        is refused by (I3) — so no preheader forward gate can ever be paired
    //        with an in-body `At`. A hoisted `cq_template_*` rail is EXACTLY what
    //        (I1) admits. The comment two clauses up says so in those words and
    //        refuses it for that reason; it is admitted here for a DIFFERENT one.
    //
    //        THE LICENCE IS **PLACEMENT**, AND IT LIVES IN ANOTHER FILE.
    //        `Uncomputation::anchorForConsumer` (piece P2) discharges such a rail
    //        ONCE, at a loop exit, and `multiplicityAgrees` (piece P1) refuses
    //        every other pairing — including the preheader-gate / in-body-`At`
    //        one this clause would otherwise open. Both halves are REQUIRED.
    //
    //        ⚠ **AND THE CONJUNCT BELOW IS A NECESSARY CONDITION, NOT THE
    //        LICENCE. AN EARLIER WORDING HERE SAID IT WAS, AND IN A NEST THAT IS
    //        FALSE** (bd `test_C_libtooling-4jok`, Rule-13 round 5 finding F-1,
    //        2026-09-21). It read: *"`loopExitDischargePoint` is the SAME
    //        predicate P2's anchor walk calls (Rule 14): if there is no
    //        once-per-mint point, there is no licence, and the root is refused."*
    //        It IS the same predicate — and it is asked of a DIFFERENT LOOP.
    //        This clause asks it of `L`, the loop being MARKED.
    //        `anchorForConsumer` asks it of `LOut`, the OUTERMOST loop enclosing
    //        the CONSUMER that does not contain the mint
    //        (`Uncomputation.cpp:369-381`). In a nest whose INNER loop has a
    //        unique exit and whose OUTER loop does not, this clause GRANTS and
    //        records an obligation while the anchor returns `nullptr` and has
    //        nowhere to place the discharge. MEASURED:
    //        `loop_pairing_reject_nest_multiexit_hoisted.ll` (grant made, anchor
    //        abandons, the POSTCONDITION declines loudly) against
    //        `loop_pairing_accept_nest_singleexit_hoisted.ll` (one conjunct of
    //        difference — the OUTER loop's exit uniqueness, which this clause
    //        never asks about — and the `_unc` lands at the outer exit BEFORE the
    //        interference). ⚠ `CLAUDE.md` L2: this is the THIRD quantifier
    //        mismatch in this increment and the file states the other two at both
    //        their sites (`markedHeaderOf`'s innermost `LI.getLoopFor` against the
    //        anchor's outermost `Loop::contains`, bd `emkg`); "which loop's exit"
    //        was stated at neither. It is stated here now.
    //
    //        ⚠ **SO THE TOTAL ANSWER IS `declineUndischargedExitObligations`, AND
    //        IT IS LOAD-BEARING RATHER THAN BELT-AND-BRACES.** Do NOT narrow,
    //        move or drop it on the reading that "the clause already refuses" —
    //        the clause cannot, because it cannot see which loop the anchor will
    //        choose. The ledger's own header says the same thing from the other
    //        end: *"no fence in THIS file can see that outcome."*
    //
    //        ⚠ **L3-MIRROR OBLIGATION, DISCHARGED IN WRITING BECAUSE THE CALLEE'S
    //        TRIGGER DEMANDS IT.** `mintsOutOfPlaceTemplateRail`'s header says:
    //        *"this is a SUPPRESSION at both call sites — a `true` here silences a
    //        decline. Any third caller must state which direction it reads the
    //        answer in BEFORE it is added."* **This is that third caller and it
    //        reads the answer in the GRANTING direction**: `true` ⇒ admit a Root ⇒
    //        `markIfRailLocal` may mark the body ⇒ MORE discharge AND a silenced
    //        conjunct (1). Re-derived for that direction, its two `false` arms are
    //        both SAFE here and for the same reason they are safe there — an
    //        IN-PLACE op relabels the register rather than minting a rail, so
    //        there is nothing for (ii-d) to place, and the STALE-MARKING CEDE at
    //        `:~4430` hands the module to `lowerOps`' eqpx tripwire, which
    //        DECLINES it outright. In the granting direction a `false` is a
    //        refusal (safe) and the cede's module never reaches emission at all.
    //        ⚠ RE-AIMED TRIGGER FOR THE NEXT READER: the danger for THIS caller is
    //        the opposite of the danger for the other two. A widening of that
    //        predicate that made it answer `true` for an op `lowerOps` then lowers
    //        IN PLACE would admit a Root with no rail to discharge — re-derive
    //        this clause, do not narrow it.
    //
    //        ⚠ `RootsOut` takes **`Root`, not `V`**, for the reason (ii-c)'s own
    //        comment gives: `markIfRailLocal`'s `onRail` matches on
    //        `peelInPlaceBase(Op, AsLowered=true)`, and a second key would make the
    //        two sets disagree about one value (Rule 14 / `CLAUDE.md` L2). For a
    //        template rail there is nothing to peel through and the two coincide;
    //        it is written this way so a future peelable spelling does not silently
    //        fall out of the set.
    //        ⚠ **AND EVERY USER MUST BE INSIDE `L`. THIS CONJUNCT IS NOT
    //        CONSERVATISM — IT IS THE CLAUSE'S SUBJECT** (added by this
    //        increment's own round 1, after MEASURING what happened without it).
    //        The rail this clause is about is one `-O1` HOISTED OUT OF THE BODY:
    //        `int p = y*3;` whose only reader is the body's condition. A rail that
    //        is ALSO read AFTER the loop is a function-scope value the body
    //        happens to read, and admitting it as a Root is a different claim with
    //        a different placement: `Uncomputation` anchors it past its LAST user,
    //        which is outside the loop, so the loop-exit licence above does not
    //        describe it at all.
    //        MEASURED, and both rows are shipped fixtures that SCOPE_T2 §4 named
    //        as controls that must not move: without this conjunct
    //        `loop_pairing_reject_root_invariant_read_after_loop` (an `and` rail
    //        measured in-loop AND read as DATA after it — clause (ii-c)'s "EVERY
    //        user" quantifier, pinned) and
    //        `lowering_uncompute_interior_loop_consumer_and_after` (a rail read K
    //        times inside and once after) BOTH moved. Neither is the shape this
    //        clause was built for, and for the first one the marking would have
    //        silenced a fence that — its header says so explicitly — has no
    //        post-loop rotation to fire on anyway.
    //        ⚠ **A NARROWING THAT WAS TRIED, MEASURED AND REJECTED — RECORDED SO
    //        THE NEXT AGENT DOES NOT RE-DERIVE IT AS AN IMPROVEMENT.** "Refuse a
    //        loop that CARRIES a claimed rail across its back edge" looks like the
    //        right multiplicity regime and is WRONG: two of this clause's three
    //        intended customers (`…_hoisted_template_leak_control` and
    //        `…_short_sext_leak_control`) have exactly that — their bodies end
    //        `cq_theta(&r, 0.1);` — and the conjunct returned both to a decline
    //        while ALSO flipping `loop_pairing_reject_round2_falsified` to exit 0.
    //        A carried rail and a hoisted rail are INDEPENDENT regimes; the one
    //        this clause reasons about is the hoisted one, and the carried one is
    //        `collapseRailPhisIn`'s, already proved by its own fences.
    if (auto *VI = dyn_cast<Instruction>(V))
      if (!L->contains(VI->getParent()) &&
          mintsOutOfPlaceTemplateRail(VI, taint) &&
          loopExitDischargePoint(L) && allUsersInside(V, L)) {
        RootsOut.insert(Root);
        recordExitDischargeObligation(Root);
        continue;
      }
    auto *Mint = dyn_cast<CallInst>(Root);
    if (!Mint)
      return false;
    // (ii-b) OR A CONTROL-OWNED MERGE OUT-RAIL — bd 3qlq Inc 1, Rule-13 ROUND-2
    //        finding F-R1-1. The clause above admits ONE spelling of "a rail the
    //        M-B interior partition can never claim", and it is not the only one
    //        a `-O1` program produces. The Phase-4 merge emitters mint their
    //        result rail as `%out = cqrt_alloc_<W>(…)` and RAUW the merge phi to
    //        it, so a loop whose invariant register is a merged one reads a
    //        `cqrt_alloc` CallInst — not a `cq_theta` — and clause (ii) refused
    //        it. MEASURED at HEAD, three emitters, `and_i32_hl` minted K times
    //        and `_unc` ZERO times against a hand-unrolled twin that discharges
    //        every one (`p/s1_selectmerge_inloop.c` 4.4 select merge,
    //        `p/s2_switchmux_inloop.c` 4.5 switch data-mux,
    //        `p/o_onward_inloop.c` 6.5 classical-call arm) — the SAME
    //        rolled≠unrolled leak of an entangled which-path record round 1
    //        graded CONFIRMED as F-L7-2.
    //
    //        THE PROOF IS THE SAME PROOF, NOT A NEW ONE, which is the only
    //        reason this widening is admissible inside a Rule-13 fence. Clause
    //        (ii)'s argument is that a root mint can never be the PREHEADER
    //        forward gate whose `At` lands in the K-times body, because
    //        `ChainWalk::isInteriorTerminalHandle` clause (I1) requires
    //        `isTemplateProducer` AND a `cq_template_`-prefixed callee, and a
    //        root mint lowers to `cqrt_alloc_<W>` + `cqrt_ry_<W>`. A merge
    //        out-rail is ALREADY a `cqrt_alloc_<W>` call at this point in the
    //        pipeline (its emitter ran during `lowerControlRegions`), so it
    //        fails the identical (I1) test for the identical reason, and the
    //        whole-DAG partition excludes it twice over (`ControlOwnedRails` is
    //        checked by name at `Uncomputation.cpp:1356` and `:1558`). The
    //        multiplicity hazard `markIfRailLocal`'s comment names is therefore
    //        unbuildable with either spelling as a Root.
    //
    //        BOTH HALVES ARE REQUIRED, deliberately: the `ControlOwnedRails`
    //        MEMBERSHIP (this is a rail Phase-4 minted and owns — it is never
    //        walked, never freed by the spine, and the emitters' own comments
    //        say so) AND the STRUCTURAL `cqrt_alloc_` producer test (so the (I1)
    //        argument above can be read at this site without trusting the set's
    //        insertion discipline). The retired route's Phase-4 WORK rail was in
    //        the same set and not excluded by name: it was allocated and freed
    //        inside its own region, so it could never be a `Cand` here.
    //
    //        The hoisted loop-invariant TEMPLATE rail (`int p = q * 3;` — owner
    //        question Q-R1-1) is UNAFFECTED and still refused: a
    //        `cq_template_mul_i32_hl` rail is exactly what (I1) admits, so it is
    //        exactly what this clause must not. Pinned by the discriminating
    //        control `p/q1_hoisted_temp.c`, still leaking, before and after.
    const bool MergeOutRail = [&] {
      if (!taint.ControlOwnedRails.count(Root))
        return false;
      const Function *Callee = Mint->getCalledFunction();
      return Callee && Callee->getName().starts_with("cqrt_alloc_");
    }();
    if (!MergeOutRail && (!GateCalls.count(Mint) ||
                          taint.Tainted.count(Mint->getArgOperand(0))))
      return false;
    // (iii) THE WHOLE CHAIN MUST BE OUTSIDE `L`. A peel that walks INTO the loop
    //       would mean the body gates the register after all — belt-and-braces,
    //       since clause (i) already refuses a loop with any tainted header phi
    //       and an in-body in-place gate on an SSA register always produces one.
    if (L->contains(Mint->getParent()))
      return false;
    for (User *U : V->users())
      if (auto *UC = dyn_cast<CallInst>(U))
        if (L->contains(UC->getParent()) &&
            isInPlaceGateOnArg0(UC, V, GateCalls, taint))
          return false;
    // (iii-b) A MERGE OUT-RAIL MAY ONLY BE READ INSIDE `L`, never written. The
    //         clause above asks `isInPlaceGateOnArg0`, whose vocabulary is the
    //         collected `cq_theta` calls — the right question for an SSA
    //         register (an in-place gate on one always mints a header phi, which
    //         clause (i) already refuses) and the WRONG one for a rail the
    //         emitters mutate through VOID calls that are in no work list
    //         (`cqrt_copy_<W>_controlled`, `cqrt_x`, `cqrt_cnot`, a
    //         `cq_template_*_unc` strip). None of those is producible inside `L`
    //         for a rail allocated outside it — each Phase-4 emitter mints its
    //         own `%out` and writes it in the same pred block it allocated it in
    //         — so it refuses no WRITE any emitter builds today. It is here
    //         because that is an argument about EMITTERS and this is a fence, and
    //         because a K-times write against a once-executed alloc is precisely
    //         the multiplicity the (I1) argument above rules out for the RECOVERY
    //         direction only.
    //         ⚠ THE SENTENCE THAT STOOD HERE — "this refuses a shape no emitter
    //         builds" — IS FALSE, AND THE REASON IS THE TEST, NOT THE EMITTERS
    //         (xdu2.16 Rule-13 r1B F-B1-4; bd `test_C_libtooling-xdu2.24`; L7). The
    //         clause tests `isVoidTy()` on ANY in-`L` call user, so it cannot tell a
    //         WRITE from a read-only BORROW, and the 4.4 emitter's compare strip
    //         `cq_template_icmp_<p>_<W>_hl_unc(flag, %out_u, k)` is a void call that
    //         only READS the out-rail (a borrowed operand, not arg 0). It is reached
    //         from plain C: `int u = (q>1) ? k1 : k2;` then `for (…) t =
    //         ((u>3) & (r<5)) ? i : 55;` REACHES this clause through bd xdu2.16's
    //         nulled-root re-derivation (the pre-xdu2.16 oracle declined the same
    //         program one step earlier, at the unconditional nulled-root refusal),
    //         while the single-leaf `(u > 3) ? i : 55` accepts on both — an
    //         OVER-DECLINE, the safe direction, filed and NOT fixed here (narrowing
    //         a refusal is an accept-direction change that owes its own round).
    if (MergeOutRail)
      for (User *U : V->users())
        if (auto *UC = dyn_cast<CallInst>(U))
          if (L->contains(UC->getParent()) && UC->getType()->isVoidTy())
            return false;
    RootsOut.insert(Root);
  }
  return true;
}

// The public face of the above: on FAILURE, UNDO every `InPlaceRailOps` marking
// the commit pass made (bd 3qlq Inc 1, C-1 review round 2, F-C1-1). Without the
// rollback a failed extension would still have committed a preheader `add` to the
// in-place emitter — the same answer M-C reaches on its own, but reached HERE and
// therefore a behaviour change for a module this path does not serve. With it,
// `invariantRegisterRoots` returning false leaves `taint` byte-identical to what
// it was on entry, which is the property the round-1 fix's "separate set, union
// only on success" discipline established for `RootsOut` and this extends to the
// one other thing the function now touches.
bool invariantRegisterRoots(Loop *L, TaintSet &taint, WidthDispatch &wd,
                            const DominatorTree &DT, const LoopInfo &LI,
                            const SmallPtrSetImpl<CallInst *> &GateCalls,
                            SmallPtrSetImpl<Value *> &RootsOut,
                            const SmallPtrSetImpl<Value *> *CarriedRoots) {
  SmallVector<Instruction *, 2> Marked;
  if (invariantRegisterRootsImpl(L, taint, wd, DT, LI, GateCalls, RootsOut,
                                 CarriedRoots, Marked))
    return true;
  for (Instruction *I : Marked) {
    taint.InPlaceRailOps.erase(I);
    // bd eqpx: the proven-rail INDEX is written in lockstep with membership
    // (`markInPlaceRailOp`) and must be erased in lockstep too — a stale index
    // would outlive its set and be re-verified for an op this path never marked.
    taint.InPlaceRailIdx.erase(I);
    // BOTH sets, or `lowerOps`' (1b) tripwire would re-ask its question about an
    // op this path did not commit — and answer it under a fence (`inPlaceFence
    // Holds`' own `InPlaceRailOps` self-test, suppressed only for a committed op)
    // that no longer describes the site (bd 3qlq Inc 1, C-1 round 3, F-C1B-1).
    taint.PreLoopCommittedInPlaceOps.erase(I);
  }
  return false;
}

// ── THE REFUSAL HALF OF `markIfRailLocal`, EXTRACTED (bd `tu9q`, 2026-09-15) ──
//
// `true` iff `L` qualifies for the iteration-local marking on `Roots`. Extracted
// so the ROUND-1 grant's L1 RE-ASK (`declineRound2FalsifiedRailGrants`) asks the
// SAME clauses under FINAL taint by CALLING this, never by re-spelling them
// (Rule 14 — the drbq Inc-3 (b′) defect is a SECOND SPELLING of a predicate the
// tree already owned). `WhyNot`, when non-null, receives an instruction to hang a
// diagnostic's `!dbg` on: the offending value where there is one, the loop
// header's terminator for the whole-loop clauses. `AnyLocalOut` receives whether
// the body has an iteration-local TEMP for the spine to place — it is NOT a
// refusal (`markIfRailLocal` bails on it because a pure-rail loop emits the same
// stream marked or unmarked, which is also why the re-ask must not treat it as
// one).
//
// PURE ANALYSIS. It reads `taint` and mutates nothing; the one non-const
// parameter is `taint`, because `peelInPlaceBase` takes it non-const.
bool railLocalQualifies(Loop *L, TaintSet &taint, LoopInfo &LI,
                        const SmallPtrSetImpl<CallInst *> &GateCalls,
                        const SmallPtrSetImpl<Value *> &Roots,
                        bool &AnyLocalOut, Instruction **WhyNot = nullptr) {
  AnyLocalOut = false;
  BasicBlock *Header = L->getHeader();
  auto refuse = [&](Instruction *I) {
    if (WhyNot)
      *WhyNot = I ? I : Header->getTerminator();
    return false;
  };
  if (Roots.empty())
    return refuse(nullptr);
  if (taintedExit(L, taint))
    return refuse(nullptr);  // Q1 quantum-bounded — never markable.
  // `AsLowered` — the FACT-time peel (see `peelInPlaceStep`). Everything this
  // lambda is asked is asked AFTER `collapseRailPhisIn` step (3) has marked every
  // chain member `InPlaceRailOps`, and BOTH of its jobs need the fact rather than
  // the shape: it decides which values are iteration-local TEMPS (whose escape
  // must be checked) and which are THE REGISTER (exempt, because `cq_measure`
  // owns it). A `%t = add %q, -6` derived-condition temp is a temp; peeling it by
  // shape called it the register, silently exempting it AND leaving `AnyLocal`
  // false so the body was never marked at all.
  auto onRail = [&](Value *V) {
    return Roots.count(peelInPlaceBase(V, GateCalls, taint,
                                       /*AsLowered=*/true)) != 0;
  };
  for (BasicBlock *BB : L->blocks()) {
    Instruction *T = BB->getTerminator();
    // (L2) tainted control still standing — not ours (bd dm7f.24: one spelling).
    if (isTaintedBranchTerminator(T, taint))
      return refuse(T);
    if (LI.getLoopFor(BB) != L) {
      // A strictly-deeper SUBLOOP with quantum content runs its gates N times
      // per outer iteration while the spine would reverse them ONCE — the
      // under-reversed dirty free. Verbatim from `markIfIterationLocal`.
      for (Instruction &I : *BB)
        if (taint.Tainted.count(&I))
          return refuse(&I);
      continue;
    }
    for (Instruction &I : *BB) {
      // (L3) tainted-index memory — kMsgQramLoop's.
      //
      // ⚠ WITH ONE EXEMPTION, bd `test_C_libtooling-zujr`: A STORE THAT PARKS A
      // RAIL IN A PROVEN RAIL BANK (bd `xdu2`). `bool b0[N]` promoted by
      // `RailBankPromote` leaves `store i32 %h, ptr %cq.bank.addr` in the body,
      // whose VALUE operand is a tainted HANDLE by construction — so the blanket
      // form refused every banked loop, which is the owner's own cascade. The
      // exemption is narrow in exactly the way the clause's name is: the
      // POINTER operand must still be untainted (a CLASSICAL cell index — a
      // tainted one is genuinely QRAM and keeps the refusal), the bank must be
      // the `!cq.railbank` record `markRailBankAllocas` minted (asked by CALLING
      // `railBankOfPointer`/`isRailBankAlloca`, never re-derived — Rule 14), and
      // the only tainted operand admitted is the value.
      // ⚠ IT DOES NOT HAND THE SPINE ANYTHING NEW, AND THE GROUND IS THE
      // INTERIOR PARTITION'S, NOT THE TERMINAL ONE'S. An earlier wording here
      // cited `railStoredToRailBank` — TRUE CONCLUSION, WRONG PARTITION, and
      // CLAUDE.md L7's exact shape (Rule-13 round 1, F-1). That predicate guards
      // `ChainWalk::isTerminalHandle`; what the marking unlocks is
      // `planInteriorComponent`'s §2.9 exception, and `isInteriorTerminalHandle`
      // NEVER CALLS IT. What actually excludes a banked rail there is clause
      // **(I3)** (a `store` user is not an interior terminal) together with
      // **(I1)** (an alloc-minted producer is excluded outright) — and every
      // rail a bank can hold today IS alloc-minted, so (I1) alone suffices.
      // ⚠ RETIREMENT TRIGGER: the day a bank cell can hold a TEMPLATE-minted
      // rail (bd `xdu2`'s second half), (I1) stops covering it and only (I3)
      // does. Re-derive this exemption then. MEASURED that the gap is EMPTY
      // today: four constructions of a template-minted bank rail all die at
      // `RailBankPromote`'s own fences on BOTH binaries (`cq rail bank: cell
      // type rewrite failed on a proven bank` / `array mixes a rail cell access
      // with an unrecognized one`).
      if (isa<GetElementPtrInst>(I) || isa<LoadInst>(I) || isa<StoreInst>(I)) {
        auto *ST = dyn_cast<StoreInst>(&I);
        const bool BankPark =
            ST && !taint.Tainted.count(ST->getPointerOperand()) &&
            isRailBankAlloca(railBankOfPointer(ST->getPointerOperand()));
        for (Value *Op : I.operands()) {
          if (!taint.Tainted.count(Op))
            continue;
          if (BankPark && Op == ST->getValueOperand())
            continue;
          return refuse(&I);
        }
      }
      const bool TI = taint.Tainted.count(&I) != 0;
      // An unclaimed loop-carried rail — no collapse ran.
      // ⚠ EXCEPT A PROVEN LOOP-CARRIED HANDLE VARIABLE (bd
      // `test_C_libtooling-zujr`), which is unclaimed ON PURPOSE: it is not a
      // rail dragged across the back edge but a register RE-MINTED every trip,
      // and `invariantRegisterRootsImpl` put its chain in `Roots` so `onRail`
      // below already names it. Asked by CALLING the one predicate, at the same
      // FINAL taint that stage asked it at (Rule 14).
      if (TI && isa<PHINode>(I) && BB == Header &&
          !loopCarriedHandlePhi(cast<PHINode>(I), L, taint, GateCalls))
        return refuse(&I);
      if (TI && !onRail(&I)) {
        AnyLocalOut = true;
        for (User *U : I.users())
          if (auto *UI = dyn_cast<Instruction>(U))
            if (!L->contains(UI->getParent()))
              return refuse(&I);  // an iteration-local temp escaping the loop.
      }
      for (Value *Op : I.operands())
        if (taint.Tainted.count(Op)) {
          auto *OpI = dyn_cast<Instruction>(Op);
          if (!OpI)
            return refuse(&I);
          if (!L->contains(OpI->getParent()) && !onRail(Op))
            return refuse(&I);  // an accumulating loop-invariant tainted input.
                     // A SECOND FILE DEPENDS ON THIS CLAUSE, AND IT IS LOAD-
                     // BEARING FOR A UNITARY, NOT A LEAK (bd 8h7d.5 round-5
                     // cleanup). `Uncomputation.cpp`'s §4/§2.9 pair asks each
                     // endpoint separately whether it repeats, never whether the
                     // two repeat EQUALLY: a recovered gate in the PREHEADER
                     // (does not repeat) with `At` in a body marked here (repeats
                     // K times) would emit K adjoints against ONE forward gate.
                     // Refusing to mark a body that reads an outside-`L` tainted
                     // non-rail value is the ONLY reason that pairing cannot be
                     // built today. Widening it — even "just" to admit a hoisted
                     // loop-invariant temp — makes it reachable, and no shipped
                     // test would go red. Re-derive the multiplicity there first.
        }
    }
  }
  return true;
}

// The MARKING half. `true` iff it marked. `AnyLocal` is asked HERE and not inside
// `railLocalQualifies` because a pure-rail loop (no iteration-local temp) is not
// REFUSED — it emits the identical stream marked or unmarked — and the round-1
// grant's re-ask must not read it as a refusal (`bodyHasSpineDischargeCandidate`
// makes the same distinction for `declineUnmarkedRolledIterLocal`, and pretending
// otherwise there cost four correct programs).
bool markIfRailLocal(Loop *L, TaintSet &taint, LoopInfo &LI,
                     const SmallPtrSetImpl<CallInst *> &GateCalls,
                     const SmallPtrSetImpl<Value *> &Roots) {
  bool AnyLocal = false;
  if (!railLocalQualifies(L, taint, LI, GateCalls, Roots, AnyLocal))
    return false;
  if (!AnyLocal)
    return false;  // a pure-rail loop (no temps) — nothing for the spine to place.
  // ONLY `L`'s OWN blocks (bd 8h7d.5 Rule-13 round 1, finding P2). `L->blocks()`
  // includes every strictly-deeper SUBLOOP block, and the subloop refusal above
  // only inspects `taint.Tainted` membership — which the region emitters' own
  // output (`cqrt_rz_i1`, `cqrt_x`, the `_unc` strips) is never in, because they
  // are void calls minted after propagation. So a subloop carrying an EMITTED
  // stream would be certified iteration-local while running its gates N times per
  // outer iteration, and the spine would reverse them ONCE: the under-reversed
  // dirty free (Rule 6). Unreachable today — every nested-loop probe declines
  // earlier, at `ControlDetect::flatRegionRollableInLoop` gate (B) (one depth) or
  // at the subloop refusal above — which is exactly why it is closed structurally
  // rather than left to the guard that cannot see it. `markIfIterationLocal`
  // (Increment 2) has the identical `L->blocks()` shape but is NOT changed here:
  // its own refusal covers every tainted value, and it has no post-flatten
  // emitted stream to miss.
  for (BasicBlock *BB : L->blocks())
    if (LI.getLoopFor(BB) == L)
      taint.IterationLocalBlocks.insert(BB);
  return true;
}

// bd `test_C_libtooling-tu9q` — the L1 RECORD for the ROUND-1 root-mint grant.
// `lowerLoops` runs at ROUND-1 taint in both entry points, so every clause
// `railLocalQualifies` just answered was answered with round-1 evidence. The
// grant is recorded here and re-asked under FINAL taint after the round-2
// fixpoint by `declineRound2FalsifiedRailGrants`.
//
// KEYED ON THE LOOP HEADER BLOCK, never on a `Loop *` — `LoopInfo` owns its
// `Loop` objects and destroys them per function, and a module-scoped set of
// `const Loop *` outliving one is the DANGLING POINTER that shipped a silent
// miscompile in `declineUnmarkedRolledIterLocal` (review round 1, F-W1-1,
// 2026-09-14). A `BasicBlock *` lives as long as the module. The roots are
// `WeakTrackingVH` for the same reason `RolledLoopRegionGates` uses them: a root
// mint is RAUW'd to its `i32` handle by `lowerRotations`, which runs AFTER this
// record is written and BEFORE nothing re-reads it — a NULLED handle is a root
// that no longer exists, and the re-ask never silently skips it: since bd
// `test_C_libtooling-xdu2.16` it discards the whole round-1 root set and requires
// a TOTAL re-derivation under FINAL taint (declining if there is none), where it
// used to decline outright.
void recordRound1RailGrant(Loop *L, TaintSet &taint,
                           const SmallPtrSetImpl<Value *> &Roots) {
  TaintSet::Round1RailGrant G;
  G.Header = L->getHeader();  // a `WeakTrackingVH` — see the struct's header.
  G.Fn = L->getHeader()->getParent();  // the fallback anchor for a nulled header.
  for (Value *R : Roots)
    G.Roots.emplace_back(R);
  taint.Round1RailGrants.push_back(std::move(G));
}

}  // namespace

void collapseFlattenedLoopRails(
    Module &M, WidthDispatch &wd, TaintSet &taint,
    const ScrubMap<const BasicBlock *, unsigned> *AlreadyProcessed) {
  // Round-2 TRIGGER: only a module in which an in-loop tainted-control region
  // was actually emitted + flattened. Everything else is byte-identical, which
  // is what keeps the 250-odd shipped e2e goldens untouched by this increment.
  // ⚠ `empty()` counts LIVE Preds only (bd 8e5r, r1A F-EA-8): "a region was
  // emitted into a block that still exists". The early return is OUTCOME-NEUTRAL,
  // not merely argued equal (bd ec7r's L2 re-ask, TRACK_8E5R.md §15.2 row G10): the
  // loop below only ever `find`s LIVE loop blocks in this table, so a table whose
  // every recorded Pred has died answers "not touched" for every loop whether or not
  // this line returns. (Contrast the bd 2qyz re-sweep gate, which asked a MODULE-WIDE
  // question and was moved onto the lift EVENT record for that reason.)
  if (taint.InLoopFlattenedPreds.empty())
    return;

  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Rebuild DT/LI on the POST-FLATTEN CFG (Rule 11/9 — the round-1 trees are
    // long invalid; the flatten spliced and erased blocks).
    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    for (Loop *L : LI.getLoopsInPreorder()) {
      bool Touched = false;
      bool NewlyTouched = false;
      for (BasicBlock *BB : L->blocks()) {
        auto It = taint.InLoopFlattenedPreds.find(BB);
        if (It == taint.InLoopFlattenedPreds.end())
          continue;
        Touched = true;
        // bd 3qlq Inc 1, Rule-13 ROUND-2 finding F-R1-1 — THE ONWARD PASS.
        // `AlreadyProcessed` is the caller's SNAPSHOT of
        // `taint.InLoopFlattenedPreds` taken before the round-2 control
        // fixpoint; a pred that gained NOTHING since then was already offered to
        // this stage by the round-1 call, and re-offering it is at best a no-op
        // and at worst a second mutation of a rail the first call already
        // claimed. So the onward pass processes ONLY loops the ROUND-2 flatten
        // opened.
        //
        // A COUNT, NOT A MEMBERSHIP (bd 3qlq Inc 1, the SECOND C-1 review round,
        // finding **F-C1-2(2b)**). As a set of BLOCKS this test was structurally
        // blind to the commonest mixed shape: round 1 flattens its own in-loop
        // region into `Pred`, round 2's onward region flattens into that SAME
        // block, membership does not move, and the loop is NEVER RE-OFFERED —
        // while the round-1 marking had already bailed `!AnyLocal`, because at
        // round 1 the values the round-2 region derives are not yet tainted, so
        // nothing was marked at either round and every per-trip which-path rail
        // leaked. MEASURED on `p/r40_onward_r1open.c` (a round-1 `r==3` kickback
        // beside an onward `(y>>i)&1` one): exactly ONE `[DBG] loop hdr=` line,
        // `round2=0`, rolled 3 mints / 0 `_unc`.
        //
        // THE RE-OFFER IS THE **GRANT** HALF OF Q-R2-1, and the comment's worry
        // above is answered by measurement rather than deference: on a loop round
        // 1 fully collapsed, `collapseRailPhisIn` finds no tainted header phi,
        // returns `NotClaimed` WITHOUT mutating (step (1) is pure analysis and
        // the `Collapse` map is empty), and `markIfRailLocal` only ever inserts
        // blocks. Round-2 taint is a strict SUPERSET of round-1 taint, and every
        // clause of `markIfRailLocal` is a REFUSAL over tainted values, so the
        // re-offered grant is asked with strictly more evidence, never less.
        if (AlreadyProcessed) {
          auto PIt = AlreadyProcessed->find(BB);
          unsigned Before = PIt == AlreadyProcessed->end() ? 0u : PIt->second;
          if (It->second <= Before)
            continue;  // nothing NEW was emitted into this block at round 2.
        }
        NewlyTouched = true;
      }
      if (!Touched)
        continue;  // a loop this increment did not open — leave it untouched.
      if (AlreadyProcessed && !NewlyTouched)
        continue;  // round 1 already saw this loop; nothing new opened in it.
      SmallPtrSet<Value *, 4> Roots;
      // Mark ONLY after a real collapse. A DECLINE means `opt` will exit
      // non-zero, and handing the spine an in-body discharge permission for a
      // module that is never emitted is bookkeeping on a corpse (bd 8h7d.5
      // Rule-13 round 1); a NotClaimed loop keeps its pre-existing owner.
      RailRound2 R2 = collapseRailPhisIn(L, F, taint, GateCalls, DT, LI, Roots);
      if (R2 == RailRound2::Collapsed) {
        // THE MIXED LOOP (bd 3qlq Inc 1, the Rule-13 CLEARANCE finding C-1 — the
        // BLOCK). A collapse means SOME register crosses the back edge; it says
        // nothing about whether ANOTHER, loop-INVARIANT one is read in the body.
        // `for (i<K) { if ((q>>i)&1) cq_phi(θ); cq_theta(&r,.1); }` is both at
        // once, and it was served by neither path: this branch handed
        // `markIfRailLocal` the carried root alone, and its "accumulating
        // loop-invariant tainted input" clause then refused on `%q`, so the
        // body's per-bit `and` rails were never discharged (3 mints / 0 `_unc`
        // at 542d588, against 3/3 hand-unrolled and 3/3 on the pre-3qlq oracle —
        // entangled which-path records live through the diffusion that follows).
        //
        // A SEPARATE SET, UNIONED ONLY ON SUCCESS. `invariantRegisterRoots` fills
        // its out-set INCREMENTALLY and can return false after inserting some
        // roots, so handing it `Roots` directly would let a FAILED extension
        // pollute the carried set `markIfRailLocal` is called with — a permission
        // granted on a register nothing proved. On failure the call below is
        // byte-identical to what this branch did before (measured: every
        // pre-existing accept fixture and e2e golden unmoved).
        SmallPtrSet<Value *, 4> Invariant;
        if (invariantRegisterRoots(L, taint, wd, DT, LI, GateCalls, Invariant,
                                   &Roots))
          Roots.insert(Invariant.begin(), Invariant.end());
        markIfRailLocal(L, taint, LI, GateCalls, Roots);
      } else if (R2 == RailRound2::NotClaimed &&
                 invariantRegisterRoots(L, taint, wd, DT, LI, GateCalls, Roots,
                                        /*CarriedRoots=*/nullptr)) {
        // The LOOP-INVARIANT-REGISTER path (bd 3qlq Inc 1 part A, round-1
        // F-L7-2 / F-L5-1). There was no rail phi to collapse because the body
        // gates nothing — the register-free `cq_phi` surface's normal case, and
        // the shape owner decision D4 blesses. `markIfRailLocal` runs UNCHANGED
        // on the supplied roots; see `invariantRegisterRoots` for why a root
        // mint (and only a root mint) is a sound thing to put in that set.
        // `Declined` is deliberately NOT admitted here: `opt` is about to exit
        // non-zero, and granting an in-body discharge permission for a module
        // that is never emitted is bookkeeping on a corpse (bd 8h7d.5 round 1).
        markIfRailLocal(L, taint, LI, GateCalls, Roots);
      } else if (R2 == RailRound2::NotClaimed && loopTouchesRailWindow(L)) {
        // bd 01po.19 S6 — a WINDOW-ARRAY loop (design §6): its cells are
        // memory (borrowed roots, kept-carrier stores), so there is no rail φ
        // to collapse and no invariant register; once its in-loop regions are
        // flattened it is exactly Case B — every remaining tainted value an
        // iteration-local temporary — and the S4 marker (`markIfIterationLocal`,
        // which already admits the cells) is the one that certifies it. Scoped
        // to window loops: no other loop's disposition moves.
        markIfIterationLocal(L, taint, LI);
      }
    }
  }
}

// ── bd `test_C_libtooling-s82e`, OWNER RULING **D4** (2026-09-14c) ───────────
//    THE NARROW DIVERGENT SUB-CASE OF THE UNMARKED-LOOP LEAK, AS A LOUD DECLINE.
//
// WHAT THIS REFUSES, AND WHY IT IS NOT AN ACCEPTED LEAK. When a loop body is not
// marked ITERATION-LOCAL, `Uncomputation`'s in-loop guard
// (`canRepeat(&BB) && !IterationLocalBlocks.count(&BB)`) skips every interior
// candidate in it, so the body's per-trip `cq_template_*` rails are minted and
// never `_unc`-ed and never freed. USUALLY that is Rule 6's accepted qubit leak:
// the leaked rail is a which-path copy of a register that is ALSO garbage — a
// per-trip register nothing reads again — so both forms agree on the retained
// subsystem and only the qubit count differs.
//
// It is NOT a leak when the register the leaked rail copies is STILL LIVE after
// the loop and a NON-DIAGONAL gate lands on it there. MEASURED (bd `s82e`
// Track S, 2026-09-14c, on the frozen ORACLE `cq-opt` 5c6f7490a81c7505…):
//
//     int y = 5; cq_theta(&y, .5);
//     for (k = 1; k <= 2; ++k) s += cq_measure((y >> k) & 1);
//     cq_theta(&y, .9);                       // <-- the interference
//     return s + cq_measure(y);
//
// rolled emits 10 trace lines and its HAND-UNROLLED TWIN 14; the four missing
// lines are `cq_template_lshr_i32_hl_unc` + `cqrt_free`, twice. `cqrt_ry_<W>` is
// TENSORED, so in the rolled form that `Ry(.9)` acts on a register each of whose
// qubits is maximally entangled with an ancilla nobody touches again — a
// DECOHERED mixture — where the twin acts on the pure state. Per qubit the
// `alpha*beta*sin(.9)` interference term is present in one circuit and absent in
// the other, and `cqrt_measure_i32` is the program's ONLY observable. Rolled and
// unrolled are DIFFERENT UNITARIES (`CLAUDE.md` Rule 8). `opt` exit 0,
// verify-clean, and STRICT stage 2b `0 violation(s), 0 unproven` on BOTH halves
// of the pair — the rolled-vs-hand-unrolled trace pair is the ONLY instrument in
// the tree that sees this class, because 2b counts `cqrt_alloc` SITES and a
// template-minted rail has none.
//
// ⚠ RULE 17, STATED HERE BECAUSE THE NEXT READER WILL ASK. This is NOT a decline
// substituted for the lowering we set out to build. The programs this fence was
// BUILT for do not currently receive a valid circuit — they receive an INVALID
// one — so refusing them is the Prime Directive, and the owner's 2026-09-11
// ruling ("do not decline code that leads to a valid quantum circuit") does not
// reach them. ⚠ THAT SENTENCE USED TO SAY "the refused programs", WITHOUT THE
// NARROWING "this fence was BUILT for", AND AS WRITTEN IT WAS MEASURED FALSE: the
// 14c shipping of this fence ALSO refused a shape whose rolled trace is
// BYTE-IDENTICAL to its hand-unrolled twin's, which is an OVER-DECLINE and a
// defect to remove (bd `test_C_libtooling-2g52`, closed 2026-09-15). The
// narrowing stays even though that member is closed: it is the sentence that
// keeps the Rule-17 posture and the over-decline posture apart, and this fence
// has now been measured to hold BOTH at once.
//
// THE DECLINE IS THE INTERIM AND **bd `tu9q`** (P1) IS THE END STATE: it builds
// the pairing so these programs COMPILE. Owner ruling D4 filed the capability rather than
// building it because the decline closes an open P1 silent miscompile now, is far
// narrower than the blanket decline ruling D2 rejected, and does not touch the
// owner's rolled cascade. RETIREMENT TRIGGER: when `tu9q` lands, the FOUR
// `loop_leak_dephase_reject_*` fixtures (two from 14c, two from the 2026-09-15
// widening) become ACCEPTs whose streams are their hand-unrolled twins', rolled —
// re-derive them then; do not delete them. ⚠ AND THE INTERACTION IS THE WHOLE
// FENCE, NOT A FIXTURE DETAIL: `tu9q` does not NARROW this decline, it REPLACES
// it. Every conjunct here exists only to say "the rolled body leaks what the twin
// discharges"; once the rolled body discharges it too, the premise of conjunct
// (1) — an unmarked body discharges nothing in-body — is what changes, and the
// widenings of conjuncts (2) and (3) become widenings of the set that gets the
// PAIRING rather than the set that gets refused. Do not build either one for the
// other's world.
//
// ══ THE COVERAGE CLAIM, TWICE MEASURED — 2026-09-14c and 2026-09-15 ═════════
//
// ⚠ THIS FENCE CATCHES **PART** OF THE DEPHASING CLASS, NOT THE CLASS, AND EVERY
// SENTENCE ABOVE MUST BE READ WITH THAT. The paragraph stays even though the
// three members it used to name are closed, because the retirement trigger it
// carried said in so many words not to narrow it on the strength of one round:
// A COVERAGE CLAIM THAT HAS BEEN MEASURED WRONG ONCE IS THE CLAIM A FUTURE ROUND
// WILL RE-MEASURE. `CLAUDE.md` L7-WITH-A-TWIST — the correction is applied HERE,
// in the source, and not only in a record.
//
// ── ROUND 1 (2026-09-14c, `$PREV/review_r1b/REVIEW_R1B.md`, verdict FINDING)
//    reached the residual from TWO INDEPENDENT DIRECTIONS on the FIRST round, on
//    a fence whose three conjuncts were green. All three findings are CLOSED at
//    2026-09-15 by the widening this comment now describes; each is PINNED by a
//    fixture that was validated by BINARY MUTATION (it does not fire on the
//    pre-fix binary `0e280fc62a91cec2…`), so a regression is visible in lit:
//
//   * bd `test_C_libtooling-c767` (P1, PRE-EXISTING over-accept) — conjunct (2)
//     inspected only rotations OUTSIDE `L`, so the IDENTICAL dephasing with the
//     interfering rotation INSIDE the body ACCEPTED. MEASURED on bd `s82e`'s OWN
//     D4-ruled-BENIGN exhibits plus ONE added line (`cq_theta(&u, .9);`
//     before the trip ends): `w2k_noregion_invread` 20 rolled vs 24 unrolled,
//     `w2h_phase_inloop_invread` 34 vs 42. THE MECHANISM DOES NOT CARE WHERE THE
//     INTERFERENCE SITS — only that the leaked rail's partner is interfered AT
//     ALL. CLOSED: the `L->contains(&BB)` skip is gone and the diagnostic no
//     longer claims a position. Pinned by
//     `loop_leak_dephase_reject_inloop_rotation.ll`.
//   * bd `test_C_libtooling-7845` (P1, PRE-EXISTING over-accept) — conjunct (3)
//     scanned `BinaryOperator` ONLY, on a rationale that is FALSE for a compare
//     used as DATA. MEASURED: five lines of C with no control flow, 10 rolled vs
//     14 unrolled, EVERY OTHER CONJUNCT SATISFIED — a single-conjunct miss.
//     CLOSED: the opcode-class proxy is replaced by the membership question
//     `mintsOutOfPlaceTemplateRail`, asked of the opcode owners. Pinned by
//     `loop_leak_dephase_reject_cmp_rail_data.ll`.
//   * bd `test_C_libtooling-2g52` (P2, OVER-DECLINE introduced by the 14c
//     increment) — a constant-trip loop whose only in-body tainted op is a dtzb
//     IN-PLACE `xor` on a `volatile` operand went ACCEPT(7 lines) → DECLINE with
//     a rolled trace BYTE-IDENTICAL to its hand-unrolled twin's: `cqrt_xorc_i32`
//     relabels the rail, returns no handle and MINTS NOTHING. CLOSED by the same
//     membership question; the L1 composition that makes it sound to read an
//     in-place marking at this pre-`lowerOps` slot is written out in full at
//     `mintsOutOfPlaceTemplateRail`. Pinned by
//     `loop_leak_dephase_accept_inplace_volatile.ll`.
//
// ⚠ AND THE POSTURE OF THE THREE IS NOT THE SAME, which is why they were fixed in
// one change but must not be read as one thing. The first two are P1 SILENT
// MISCOMPILES: those programs receive an INVALID circuit, so refusing them is the
// Prime Directive and the 2026-09-11 over-decline ruling does not reach them. The
// third receives a VALID one and was refused, which by that same ruling is a
// DEFECT TO REMOVE, not a safety margin. Do not let the first posture leak into
// the third when this fence is next widened.
//
// ── WHAT IS STILL NOT BOUNDED, stated so a green suite is not read as closure:
//   * NOTHING MEASURES HOW MANY MEMBERS THE CLASS HAS. Round 1β's own answer to
//     "how many more are there" was "at least two families, found in one round by
//     attacking two named conjuncts", and it budgeted a round 2 rather than
//     reading three green conjuncts as a closure. Read that as still true of the
//     widened ones.
//   * A CAST- OR `fneg`-MINTED INSTANCE HAS NO WITNESS EITHER WAY. Round 1β could
//     not construct one (`-O1` folds `fptrunc(fpext t) → t` and LICM hoists the
//     pair out of the body) and explicitly did NOT claim one unreachable. They
//     are admitted by the membership question because the question admits them,
//     not because an instance was measured.
//   * EVERY INSTRUMENT IN THE TREE IS ONE FUNCTION PER MODULE (bd
//     `test_C_libtooling-1yeu`), so a CROSS-FUNCTION spelling of this leak is
//     invisible to the corpus sweep, to the twin matrices and to every probe on
//     both sides of round 1.
//   * THE SUPERSEDED-VALUE-RAIL DIRECTION (`IMPL_S` §11/§16.3's other half) still
//     has no probe on either side.
//
// ⚠ RETIREMENT TRIGGER for this whole block: any NEW member of the class, and bd
// `tu9q` by name (when the in-loop pairing lands, the whole fence becomes an
// accept path — see below). Re-derive it, and the accept fixtures' headers, from
// whatever the conjuncts then say. Do NOT delete it.
//
// ── A CORRELATED SIGNAL THAT IS NOT A SECOND FENCE (recorded so the next agent
//    finds the relationship instead of re-deriving it) ─────────────────────────
// `RotationLowering::warnLiveRecordRotations` (`kMsgLiveRecord`, "cq rotation
// lowering: non-diagonal gate over a live derived record") FIRES on all three
// divergent probes of this class and is SILENT on both benign ones. MEASURED at
// the closing gate, 2026-09-14c, counting the string in `opt` stderr:
//
//   ORACLE `5c6f7490a81c7505…`   s1_live_shift 2 · s2_live_derived_region 2 ·
//                                b11_cmp_rail_data 2  (the three divergent)
//                                s3_live_rootmint_region 0 ·
//                                w2k_noregion_invread 0  (the two benign)
//   MERGED `0e280fc62a91cec2…`   s1 / s2 exit 1 HERE (`CQLoweringPass.cpp:772`),
//                                so the warn stage (`:864`) NEVER RUNS and its
//                                count is 0 BY PREEMPTION, not by silence
//                                (`LLVMContext::diagnose` EXITS on the first
//                                `DS_Error`, bd `br4a`); b11_cmp_rail_data still
//                                exit 0 with 2 — it is bd `7845`'s residual, the
//                                one member THIS fence misses and that warning
//                                sees.
//
// ⚠ IT IS **NOT** A DIVERGENCE DETECTOR AND MUST NOT BE DESCRIBED AS ONE.
// MEASURED on the same binary: it fires on `slice_control_inplace_ry_loop_leak`
// (1) and on `…_unrolled` (2) — a pair whose traces are BYTE-IDENTICAL under the
// shipped ctest gate `e2e-inplace-ry-loop-leak-twin-identical`. ⚠ And byte
// identity cannot prove that pair CORRECT either: if both halves are wrong the
// same way the twin witness is blind, which is exactly `CLAUDE.md` L10's
// `m_none_pbitd_none_premark_rypost` cell. It is a WARNING by OWNER RULING bd
// `test_C_libtooling-lyyf` (2026-08-29) and the recorded reason is REPORTING
// COMPLETENESS — every offending gate reported instead of the pass ending after
// one — NOT benignity. Promoting it to a decline has a measured cost: 5 of the
// 366 accepting e2e slices emit it (`slice_control_angle_select_ry_derived_base`,
// `slice_control_inplace_ry_derived_base`, `slice_control_inplace_ry_loop_leak`,
// `…_unrolled`, `slice_live_record_source_rail_warn`). Use it as a SIGNAL when
// hunting bd `7845` / bd `c767`; never cite it as coverage.
// ═════════════════════════════════════════════════════════════════════════════
//
// ⚠ WHY IT IS AIMED HERE AND NOT AT `markIfRailLocal`'s CLAUSE, WHICH IS WHERE
// bd `s82e`'s OWN TEXT POINTS. MEASURED: that clause fires for NONE of the five
// leaking programs, because `markIfRailLocal` is never CALLED for any of them —
// `collapseFlattenedLoopRails` opens `if (taint.InLoopFlattenedPreds.empty())
// return;` and that map is filled ONLY by an in-loop region flatten
// (`SwapRouteEmit.cpp`). For a loop with no tainted control flow the only marker
// that runs is `markIfIterationLocal`, whose IDENTICAL "tainted operand defined
// outside `L`" clause has NO `Roots` parameter at all (`CLAUDE.md` L2: 3qlq Inc 1
// widened one of the two sibling clauses and left the other); for the region
// shapes it is `invariantRegisterRootsImpl` clause (ii), and for `w2h`/`w2h3` the
// reason IT refuses a genuine root mint is that `-O1` LICM hoists the invariant
// derived op into the preheader so the body reads a hoisted TEMPLATE rail — the
// `z_preheader_rail8` case that function's own header already records. A decline
// keyed on any ONE of those clauses would move ZERO programs. This stage
// therefore asks the OUTCOME ("is this body unmarked?") and not the CAUSE.
//
// ⚠ L1 — WHY IT IS A POST-FIXPOINT STAGE AND NOT A PREDICATE AT THE REFUSAL.
// `markIfIterationLocal` runs inside `lowerLoops`, which is BEFORE
// `repropagateControlMerges` in both entry points: round-1 taint, never re-asked.
// A predicate written there would be exactly `CLAUDE.md` L1's PREDICATE species —
// blind to any value only `repropagateControlMerges` taints. Reading the OUTCOME
// after the whole round-2 fixpoint needs no record at all and therefore cannot be
// re-opened by a seventh marking site that forgets one (the failure mode L1 names
// for `markBranchPhaseGate`). `taint.IterationLocalBlocks` is FINAL at this slot:
// its three writers are `markIfIterationLocal` (inside `lowerLoops`),
// `markIfRailLocal` via the round-1 `collapseFlattenedLoopRails`, and the same
// function again as the LAST STATEMENT of `repropagateControlMerges`.
// RETIREMENT TRIGGER: a fourth writer added after that fixpoint, or this call
// moved above it, makes this stage read a set that is still moving.
//
// ⚠ IT RUNS AFTER `declineRecordedStaleQuantumReaders`, DELIBERATELY. That fence
// is documented as the last owner to speak because `LLVMContext::diagnose` EXITS
// on the first `DS_Error` (bd `br4a`). Placing this BEFORE it would preempt it and
// change the string a module that already declines prints; placing it AFTER
// extends the backstop chain without moving any existing decline — MEASURED as
// zero string moves over the corpus sweep. It must still be above `lowerRotations`
// only in the weak sense that it reads pre-lowering opcodes; it does not need a
// `WeakTrackingVH` record, because it holds nothing across a stage.
// ⚠ THE STRING MOVED ON 2026-09-15 AND THE MOVE IS PART OF THE FIX, not cosmetic
// (bd `test_C_libtooling-c767`). It used to end "…with a register rotated AFTER
// THE LOOP", which described conjunct (2)'s old `L->contains` SCOPE and not the
// class; the scope is gone, so the claim goes with it. `CLAUDE.md`
// L7-with-a-twist: a correction not applied where it is read off is not a
// correction. Two shipped decline fixtures mirror this character-for-character
// (`loop_leak_dephase_reject_{noregion_live,region_derivedbase_live}.ll`) and two
// more were added with the fix; a drift between them and this literal is a
// Rule-12 failure, not a cosmetic one.
constexpr char kMsgLoopLeakDephases[] =
    "cq loop lowering: rolled body leaks a rail entangled with a rotated "
    "register";

// ── bd `test_C_libtooling-tu9q` — THE L1 RE-ASK OF THE ROUND-1 ROOT-MINT GRANT ─
//
// WHY IT EXISTS. `lowerLoops` offers `markIfRailLocal` the root-mint escape at
// ROUND-1 TAINT (`CQLoweringPass.cpp:393` / `:1000`), and
// `repropagateControlMerges` (`:509` / `:1027`) then re-seeds taint from the
// 6.5/4.5 merge `%out` rails and runs control detection + lowering to a fixpoint.
// Round-2 taint is a strict SUPERSET of round-1 taint, and EVERY clause of
// `railLocalQualifies` is a REFUSAL over tainted values — so a grant made at
// round 1 can be FALSIFIED by round 2 and nothing today would notice. That is
// `CLAUDE.md` L1's PREDICATE species verbatim, and its cure is the pattern, not a
// prediction: RECORD the question at the site that asks it, RE-ASK it after the
// fixpoint, in BOTH entry points, and decline LOUDLY.
//
// ⚠ IT DECLINES; IT DOES NOT WITHDRAW. Silently erasing the blocks from
// `taint.IterationLocalBlocks` would be the worst of both: the marking has
// already licensed `commitOutOfLoopInPlaceOps`' dtzb commitments (whose own
// `lowerOps` tripwire assumes the body marking "already stands"), and a rail the
// spine planned to discharge in-body would revert to a leak with no diagnostic.
// Rule 1: loud, or nothing.
//
// ⚠ IT ASKS BY CALLING `railLocalQualifies`, NEVER BY RE-SPELLING IT (Rule 14).
// `!AnyLocal` is deliberately NOT a refusal here for the same reason
// `bodyHasSpineDischargeCandidate` exists for `declineUnmarkedRolledIterLocal`: a
// body with no iteration-local temp emits the SAME stream marked or unmarked, so
// reading it as a refusal would decline correct programs (it cost four of them
// there).
//
// ⚠ A NULLED ROOT FORCES A TOTAL RE-DERIVATION — it is no longer a refusal by
// itself (bd `test_C_libtooling-xdu2.16`). The roots are `WeakTrackingVH`; a root a
// region emitter erased between the grant and here (the 4.4 emitter's dead
// condition-tree cascade is the measured one) is a root nothing reads any more. The
// grant is then re-derived FROM SCRATCH under FINAL taint by `invariantRegisterRoots`
// — every round-1 root discarded, the re-derivation required TOTAL — and
// `railLocalQualifies` is re-asked on that fresh set alone, which is STRICTLY
// STRONGER than what an intact grant is asked (see the block at the site). A
// nulled grant that cannot be re-derived still declines with this string.
// [HISTORY: until xdu2.16 this paragraph read "A NULLED ROOT IS A REFUSAL … the
// proof the grant rested on no longer has a subject", and it over-declined every
// compound 4.4 condition tree `-O1` LICM-hoists out of a rolled loop.]
//
// RETIREMENT TRIGGER: this stage must stay ABOVE `lowerRotations` (which RAUWs
// every `@cq_theta_*` result to an `i32` handle, so `Roots` would name handles
// and `peelInPlaceBase`'s pre-lowering vocabulary would no longer match) and
// BELOW the round-2 fixpoint (the whole point). Moving it either way makes it a
// silent no-op.
constexpr char kMsgRound1GrantFalsified[] =
    "cq loop lowering: round-1 iteration-local marking falsified by round-2 "
    "taint";

namespace {

// Backward transitive walk over TAINTED operands. "Does the value this rail
// copies descend from one of `Targets`?" Deliberately NOT a second spelling of
// `peelInPlaceBase` (which peels only IN-PLACE gates and would stop at the
// derived base `p = y*3`, missing the region half of the class) and NOT a second
// spelling of `WireWalk`'s wire closure (which answers a POSITION-AWARE
// harmlessness question about staling a read — a different question, and adding
// a third granting caller to it is the L3-mirror trap that already cost a P1).
// The one relation that MUST agree with the rest of the loop layer — "which
// physical rail is this" — is asked by CALLING `peelInPlaceBase` on the
// rotation's operand before the targets are formed, exactly as `markIfRailLocal`'s
// `onRail` and `invariantRegisterRootsImpl` clause (ii) do (Rule 14).
bool taintedAncestryReaches(Value *Start,
                            const SmallPtrSetImpl<Value *> &Targets,
                            const TaintSet &taint) {
  SmallPtrSet<Value *, 16> Seen;
  SmallVector<Value *, 16> WL;
  WL.push_back(Start);
  while (!WL.empty()) {
    Value *V = WL.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    if (Targets.count(V))
      return true;
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;
    for (Value *Op : I->operands())
      if (taint.Tainted.count(Op))
        WL.push_back(Op);
  }
  return false;
}

// INTERIOR, in the only sense that matters here: the hand-unrolled twin would
// discharge this rail. A rail every one of whose users is a `cq_measure` is
// MEASURE-OWNED and is left allocated by BOTH forms (Rule 6 — "never free a
// handle that is Measured"), so it is not a divergence and must not be counted.
// ⚠ The user test deliberately does NOT require the user to be in
// `taint.Tainted`: by this slot a region emitter has replaced the condition
// `icmp` with its own `cq_template_icmp_eq_*` call, which is minted AFTER
// propagation and is therefore in no taint set. Requiring taint here made the
// region half of the class invisible (measured on the `s2` subject).
bool railIsInterior(Instruction *I) {
  for (User *U : I->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      continue;
    if (!isMeasureCall(UI))
      return true;
  }
  return false;
}

// ── bd `test_C_libtooling-7845` + bd `test_C_libtooling-2g52`, 2026-09-15 ─────
// CONJUNCT (3)'s MEMBERSHIP QUESTION, ASKED INSTEAD OF PROXIED.
//
// ONE question, and it is a SET rather than an opcode class (`CLAUDE.md` L4):
// **will `lowerOps` mint an OUT-OF-PLACE `cq_template_*` rail for this
// instruction** — i.e. is there a rail here for the hand-unrolled twin to
// discharge and for the unmarked rolled body to leak? Everything conjunct (3)
// needs follows from that and nothing else does, which is why the predicate is
// spelled as the question and not as `isa<BinaryOperator> || isa<CmpInst>`.
//
// EVERY ROW ASKS AN EXISTING OWNER (Rule 14); not one of them re-derives a
// verdict this file does not own:
//   * binary — `binaryStem` (the supported-set policy layer) for "is there a
//     template", then `railValueConsumerDisposition` — the ONE spelling of "will
//     this `BinaryOperator` be lowered as an IN-PLACE mutation of rail value
//     `V`'s handle" — for "is it a rail MINT or a RELABEL".
//   * compare — `isDataPositionCompare` (is this compare a FLAG Phase 4 owns, or
//     DATA?) and `compareFlagMintable` (does a template exist for its predicate
//     and width?), both exported by `CompareLowering.h` and both already the
//     gate `lowerOps` itself collects behind. THIS IS THE ANSWER TO THE RETIRED
//     RATIONALE: the old comment excluded compares because "a compare rail IS the
//     region's own flag, which `emitCondNetwork` strips and frees itself", which
//     is TRUE OF A FLAG AND FALSE OF DATA — and the discriminator between them is
//     a question the compare owner already answers, so it is asked rather than
//     guessed from the opcode.
//   * cast / `fneg` — `castInScope` / `abiWidthFromType`, the same gates
//     `CastLowering::rewriteCast` and the unary path use. ⚠ Round 1β could not
//     CONSTRUCT a cast-minted divergence (`-O1` folds `fptrunc(fpext t) → t` and
//     LICM hoists the pair out of the body) and explicitly did NOT claim one
//     unreachable. They are in the set because the QUESTION admits them, not
//     because an instance was measured; the honest state is "no witness either
//     way", and the direction of the error if they are wrong here is a DECLINE.
//
// ⚠ WHY READING AN IN-PLACE MARKING AT **THIS** SLOT IS SOUND, WHICH IS THE ONE
// HAZARD OF THE WHOLE PREDICATE. This stage runs BEFORE `lowerOps`, and
// `lowerOps` RE-VERIFIES every pre-loop in-place marking under FINAL taint. A
// conjunct read here therefore reads a marking that is NOT YET FINAL — and it is
// used to SUPPRESS a decline, i.e. `CLAUDE.md` L1's PREDICATE species in the
// GRANTING direction, which is the unsafe one. The argument is a COMPOSITION,
// not an assertion that the marking cannot move:
//   (i) the suppression corroborates with the SAME two tests `lowerOps`' eqpx
//       tripwire re-asks (`OpcodeLowering.cpp`, "WHAT IT RE-ASKS: G2 ALONE"):
//       `inPlaceValueRailOperand(BO, taint)` non-null, and `taint.InPlaceRailIdx`
//       — where it has an entry — still naming that same operand; and
//  (ii) if the marking has gone stale by `lowerOps`, that stage DECLINES LOUDLY
//       (`diagnosePreLoopCommitStale` for W4's set, the eqpx tripwire for
//       W1-W3's) and NEVER falls back silently to out-of-place — Rule 1, no third
//       path, written out at both sites.
// So the composition is total: either the marking stands, and the suppression was
// right because the op relabels a rail and mints nothing; or `opt` exits non-zero
// and no circuit is emitted at all. ⚠ RETIREMENT TRIGGER, by name: if either
// `lowerOps` re-ask ever becomes a silent fallback, or if `InPlaceRailOps` gains
// a writer that runs AFTER this stage, half (ii) is gone and this suppression
// becomes an OVER-ACCEPT — re-derive it from scratch, do not narrow it.
//
// ⚠⚠ **THAT TRIGGER HAS FIRED, AND THE RE-DERIVATION IS RECORDED HERE RATHER
// THAN ONLY IN A REVIEW FILE** (bd `test_C_libtooling-emkg` landing, 2026-09-15;
// `CLAUDE.md` L7-with-a-twist — *a record correction that is not applied to the
// SOURCE is not a correction*, a lesson this project paid three review rounds for
// on one sentence). bd `test_C_libtooling-tu9q` added exactly the writer the
// trigger names: `declineRound2FalsifiedRailGrants` runs IMMEDIATELY AFTER this
// stage (`CQLoweringPass.cpp`, the fence then the grant re-ask, in both entry
// points) and calls `invariantRegisterRoots` → `commitOutOfLoopInPlaceOps` →
// `markInPlaceRailOp`. The trigger fired and NEITHER TRACK READ IT; the Rule-13
// reviewer re-derived it, and the answer is **SAFE — but for three specific
// reasons, none of which is "it probably does not matter":**
//   (a) **THE POPULATIONS ARE DISJOINT.** `commitOutOfLoopInPlaceOps` opens
//       `if (L->contains(BO->getParent())) return;` — it commits OUT-OF-LOOP ops
//       only — while conjunct (3), this predicate's caller, scans `L`'s OWN
//       blocks. No instruction can be in both sets.
//   (b) **THE ROLLBACK CANNOT REMOVE A MARKING THIS STAGE RELIED ON.**
//       `commitOutOfLoopInPlaceOps` skips an op already in `InPlaceRailOps`
//       (`if (!BO || taint.InPlaceRailOps.count(BO)) continue;`), so the
//       `Marked` list it hands back holds ONLY that call's NEW commitments, and
//       `invariantRegisterRoots`' failure path erases only those — which this
//       stage, running earlier, could not have seen.
//   (c) **THE RESIDUAL SKEW POINTS AT DECLINES.** This stage sees a SMALLER
//       in-place set than `lowerOps` eventually will; a smaller in-place set
//       means fewer suppressions, i.e. MORE declines, never fewer.
// ⚠ RE-AIMED TRIGGER: the argument above is about a writer whose population is
// OUT-OF-LOOP. A `markInPlaceRailOp` caller added after this stage that can
// commit an **IN-LOOP** op falsifies (a) outright and (b) with it — that one is
// the over-accept, and it must be re-derived from scratch rather than narrowed.
//
// ⚠ RESIDUAL — CLOSED BY CONSTRUCTION SINCE bd 8e5r (was: bd
// `test_C_libtooling-f8eu` family / round 1β caution (a)). This used to say that
// `taint.InPlaceRailOps` was a raw `Instruction *` set NOTHING SCRUBBED on erase,
// so a recycled allocation could make a NEW instruction test as marked, with only
// the dtzb shape precondition standing in front of it, and that "the proper close
// is to scrub `InPlaceRailOps`/`InPlaceRailIdx` alongside `Tainted`". That close
// has LANDED, totally: both are self-cleaning (`ScrubOnDelete.h`) — a deleted key
// is dropped by LLVM's own `~Value()` callback, and a fresh object at its address
// is NOT a member. The shape precondition is now defence in depth, not the defence
// (Rule-13 r1A F-EA-3, corrected at the source — L7).
bool mintsOutOfPlaceTemplateRail(Instruction *I, TaintSet &taint) {
  if (auto *BO = dyn_cast<BinaryOperator>(I)) {
    if (binaryStem(BO->getOpcode()).empty())
      return false;  // no template — `lowerOps` mints nothing (and declines).
    if (Value *Rail = inPlaceValueRailOperand(BO, taint)) {
      SmallPtrSet<const Value *, 1> NoClaims;
      if (railValueConsumerDisposition(BO, Rail, taint, NoClaims) ==
          RailValueUse::InPlace) {
        auto It = taint.InPlaceRailIdx.find(BO);
        if (It == taint.InPlaceRailIdx.end() ||
            BO->getOperand(It->second) == Rail)
          return false;  // IN PLACE: relabels the rail, MINTS NOTHING.
      }
    } else if (taint.InPlaceRailOps.count(BO)) {
      // ── THE STALE-MARKING CELL, AND IT IS A CEDE RATHER THAN A JUDGEMENT.
      // The op IS marked in-place but the dtzb SHAPE no longer holds under FINAL
      // taint, which is exactly the input `lowerOps`' eqpx tripwire owns: it
      // re-asks `inPlaceValueRailOperand` there and DECLINES with
      // `cq loop lowering: in-place rail op no longer provable at lowering`, a
      // strictly more precise diagnosis of the same module than anything this
      // stage could say. Saying NOTHING here is therefore not a risk: the module
      // still exits non-zero, it exits with the RIGHT string, and this stage is
      // documented as a BACKSTOP AND NEVER A PREEMPTOR (the same reason it is
      // slotted after `declineRecordedStaleQuantumReaders` — `LLVMContext::diagnose`
      // EXITS on the first `DS_Error`, bd `br4a`).
      // ⚠ MEASURED, and it is why this cell exists at all: without it
      // `lowering_reject_inplace_rail_stale_w2_add_derived.ll` goes from the eqpx
      // string to THIS fence's string — a decline→decline STRING MOVE, caught by
      // `ir-pass-lit` and by nothing else in the inner loop. ⚠ RETIREMENT
      // TRIGGER: if `lowerOps` ever stops declining on a stale marking, this cede
      // becomes a SILENT MISS — re-derive it, do not delete it.
      return false;
    }
    return true;
  }
  if (auto *Cmp = dyn_cast<CmpInst>(I))
    return isDataPositionCompare(Cmp) && compareFlagMintable(Cmp, taint);
  if (auto *C = dyn_cast<CastInst>(I))
    // The SOURCE width `lowerOps` will emit from: a laundered i32 handle (a
    // retyped carried phi, a break answer) carries it in `HandleWidth`, not in
    // `getSrcTy()` (R12; lowering_loop_carried_cast_forecast_width.ll).
    return castInScope(C->getOpcodeName(),
                       logicalOperandWidth(C->getOperand(0), taint),
                       abiWidthFromType(C->getDestTy()));
  if (auto *U = dyn_cast<UnaryOperator>(I))
    return U->getOpcode() == Instruction::FNeg &&
           !abiWidthFromType(U->getType()).empty();
  return false;
}

// ── bd `test_C_libtooling-emkg`, 2026-09-15 ──────────────────────────────────
// THE ONE SPELLING OF "ARE `L`'s OWN BODY BLOCKS MARKED ITERATION-LOCAL?", and it
// exists because there were two and they DISAGREED (Rule 14; `CLAUDE.md` L2 —
// *when you WIDEN a set, ask what OTHER set was computed over the same closure*).
//
// `llvm::Loop::blocks()` returns `L`'s blocks INCLUDING every strictly-deeper
// subloop's. `declineUnmarkedRolledIterLocal`'s conjunct 2 has always filtered
// those out (`LI.getLoopFor(BB) != L` — "not `L`'s to mark"), and so has
// `declineDephasingUnmarkedLoopRails`' conjunct (3); its conjunct (1) did NOT, and
// that single missing line was a **P1 OVER-ACCEPT**: a marked INNER loop set
// `Marked` on an inner block, `continue`d, and the ENCLOSING OUTER loop's own
// per-trip which-path rails were never asked about at all — leaked, undischarged,
// at a later non-diagonal gate on the register they copy (Rule 8). Found by
// Rule-13 round 2 of 2026-09-15 on THREE markers at once
// (`markIfIterationLocal`, the bd `test_C_libtooling-tu9q` root-mint escape, and
// its clause (ii-c)); pinned by `loop_leak_dephase_reject_nested_*.ll`, one per
// marker, with `loop_leak_dephase_accept_nested_outer_no_own_rail.ll` as the
// positive control.
//
// ⚠ **ALL, NOT ANY, AND THE POLARITY IS THE SECOND HALF OF THE FIX.** Conjunct (1)
// used to set `Marked` on the FIRST marked block; conjunct 2 has always required
// EVERY own block to be marked. ANY is the ACCEPT direction — a partially-marked
// body would silence the fence — so ALL is the safe polarity and is what both
// callers now get.
//
// **WHY THE TWO ANSWERS COINCIDE TODAY IS AN ENUMERATION, NOT A HOPE, AND IT IS
// SHORT ENOUGH TO RE-RUN:** `grep -n 'IterationLocalBlocks.insert' ir-pass/src`
// finds **exactly two** writers, and NEITHER can mark a PROPER SUBSET of any
// loop's own blocks:
//   * `markIfIterationLocal` inserts **`L->blocks()` — all of them, subloops
//     included**, so for `L` itself and for every loop NESTED INSIDE `L` it
//     covers every own block;
//   * `markIfRailLocal` inserts `L`'s **own** blocks only (`LI.getLoopFor(BB) ==
//     L`), so it covers all of `L`'s and none of any other loop's.
// A DESCENDANT's marking therefore never touches an ancestor's own blocks — which
// is precisely the asymmetry that made the old conjunct (1) wrong — and an
// ANCESTOR's marking (only ever `markIfIterationLocal`'s) covers a descendant's
// own blocks COMPLETELY. Partial marking of one loop's own blocks is unreachable
// from either writer. ⚠ MEASURED AGAINST THAT: the ANY→ALL half moves **0 of 2050
// modules** in `ir-pass/test` (the fix's whole corpus delta is the three, later
// four, nested-loop fixtures, and every one of them moves through the SUBLOOP
// FILTER, not through the polarity). So the polarity half is **unwitnessed, and
// that is stated rather than papered over**.
// ⚠ RETIREMENT TRIGGER, and it is the cheap one to check: a THIRD
// `IterationLocalBlocks.insert` site, or either existing one narrowed to a subset
// of a loop's own blocks, makes ANY and ALL genuinely differ — re-derive this
// paragraph then, and note that the difference would appear as an ACCEPT→DECLINE
// (safe) at this site and as a DECLINE→ACCEPT nowhere.
//
// ⚠ THE `Any` GUARD IS DEFENCE IN DEPTH AND IS EXPECTED NEVER TO FIRE: LLVM's
// `LoopInfo` invariant is `LI.getLoopFor(L->getHeader()) == L`, so a well-formed
// loop always has at least one own block. It is written anyway so the predicate is
// TOTAL — "no own blocks" then answers *not marked*, which keeps the caller's
// fence armed instead of vacuously silencing it.
//
// ⚠ RETIREMENT TRIGGER: this is a SUPPRESSION at both call sites — a `true` here
// silences a decline. Any third caller must state which direction it reads the
// answer in BEFORE it is added, because the argument above is written for the
// suppressing direction only (`CLAUDE.md` L3-mirror: a shared predicate acquires a
// caller its argument does not reach, and the callee's trigger is what stops it).
//
// ⚠⚠ **THE TRIGGER THIS HEADER DID NOT CARRY, ADDED 2026-09-18 (bd
// `test_C_libtooling-6n1s`, review finding F-2).** The three triggers above are
// all about WHICH BLOCKS and WHICH POLARITY. None was about **WHAT THE MARKING
// PROVES**, and that is the one that cost a P1: a caller read `true` as *"this
// body's interior rails are discharged in-body"*, which holds for a SINGLE-BLOCK
// body and fails for a multi-block one, because `markIfRailLocal` marks all of
// `L`'s own blocks while `Uncomputation` places a rail's discharge at the
// POST-DOMINATOR of its consumers — membership, not same-block-as-the-mint.
// **This predicate answers "are the blocks marked" and NOTHING ELSE.** A caller
// that needs the discharge property must ask
// `markedBodyRailsHaveInBodyDischargePoint` (below) as a SECOND conjunct, which
// is what `declineDephasingUnmarkedLoopRails` conjunct (1) now does; a caller
// that needs "may the spine place an in-body free here" must ask
// `Uncomputation` rather than infer it from this.
bool bodyBlocksMarked(const Loop *L, const LoopInfo &LI, const TaintSet &taint) {
  bool Any = false;
  for (BasicBlock *BB : L->blocks()) {
    if (LI.getLoopFor(BB) != L)
      continue;  // a strictly-deeper subloop's block — not `L`'s to mark.
    if (!taint.IterationLocalBlocks.count(BB))
      return false;
    Any = true;
  }
  return Any;
}

// ── bd `test_C_libtooling-6n1s` (P1 OVER-ACCEPT, found by the Rule-13 review of
//    2026-09-18; closed 2026-09-18) ────────────────────────────────────────────
//
// **"MARKED" IS NOT "DISCHARGED", AND READING IT AS ONE WAS A WRONG UNITARY.**
// This is the second half of conjunct (1)'s suppression and it exists because
// the first half's argued premise — *"a marked body discharges in-body, once per
// trip"* — is a statement about a SINGLE-BLOCK body and was shipped as if it
// were a statement about every marked body.
//
// THE WITNESS, measured on the session ORACLE `9bd01598d574b344`
// (`trackT2/probes/t5j_twoblock_noexit_rot.c`): a 4-trip loop whose body is split
// by a RE-JOINING classical `if` — no break, no early exit — leaves all four
// `cq_template_ashr_i32_hl(h0,k)` rails undischarged (ZERO `_unc`, ZERO
// `cqrt_free`) across a trailing `cqrt_ry_i32(h0,0.9)` and `cqrt_measure_i32(h0)`.
// Only one or two bits of each 32-bit rail are measured, so the rest stay
// ENTANGLED with `h0` at the interference: `CLAUDE.md` Rule 8, not a Rule-6
// accepted leak. `opt` exit 0, a WARNING only, and `t5k_twoblock_unmarked_control.c`
// — the SAME two blocks with the marking refused — declines here with the exact
// string, which is what makes the MARKING the door by measurement rather than by
// reading.
//
// ⚠ IT WAS A REGRESSION, AND THE MEASUREMENT NAMES THE CHANGE. On the 2026-09-14
// pre-group binary `0e280fc62a91cec2` the same module DECLINES (with that
// release's spelling, *"…entangled with a register rotated after the loop"*).
// At `74eabd2c` `markIfRailLocal` had exactly TWO call sites, both inside
// `collapseFlattenedLoopRails`, which returns early unless
// `taint.InLoopFlattenedPreds` is non-empty — and `t5j` has no tainted control
// flow at all, so nothing marked it. bd `test_C_libtooling-tu9q`'s round-1
// root-mint escape added the THIRD call site (`lowerLoops`, below), which marks a
// body with no region in it; the suppression then fired on a body the spine had
// never been asked to discharge.
//
// WHAT THIS ASKS, AND WHY IT IS THE RIGHT QUESTION. `Uncomputation`'s M-B interior
// partition anchors a rail's discharge at `dagInsertPoint` — the nearest common
// POST-dominator of its consumers — and §2.9 there refuses any final point that
// repeats without being marked. So the property conjunct (1) needs is not *"is the
// body marked"* but *"does every interior rail this body mints have a per-trip
// point to be discharged at"*, and that is the post-dominator question, asked here
// in the vocabulary this stage has (pre-`lowerOps`, so `mintsOutOfPlaceTemplateRail`
// rather than a `cq_template_*` callee — the same predicate conjunct (3) uses, by
// CALLING it, never by re-spelling it; Rule 14).
//
// ⚠ IT IS A SUFFICIENT CONDITION, NOT AN ORACLE, AND THE APPROXIMATION IS JOINT
// **ON PURPOSE**. The fold below runs over the union of EVERY interior rail's
// block and its users' blocks, not per rail, because `collectInteriorPlans` merges
// rails joined by a producer edge into ONE component with ONE `At`, and a per-rail
// answer would be blind to that merge in the ACCEPT direction (two rails each with
// an in-body point, whose union's point escapes the loop). Folding the union is an
// upper bound on any component's `At`. The price is an OVER-DECLINE whenever two
// genuinely independent components sit in one body and only one of them escapes —
// measured at ZERO shipped fixtures, and FILED rather than absorbed.
//
// ⚠ IT IS A SUPPRESSION-SIDE CONJUNCT: `false` here ARMS a decline. Read with
// `bodyBlocksMarked`'s own retirement trigger, which is why this predicate is a
// separate function with its own name rather than another clause inside that one —
// the two answer different questions and `CLAUDE.md` L3's mirror is explicit that a
// shared predicate must not quietly acquire a caller its argument does not reach.
//
// ⚠ RETIREMENT TRIGGER, and it is the one a widening will trip first: this
// predicate models `Uncomputation::planInteriorComponent`'s PLACEMENT from another
// TU and another stage. The day `dagInsertPoint`, the convergence loop's
// `useCompleteBeforeDischarge`, or §2.9's marked-`At` exception changes what point
// a marked body's rail is discharged at, THIS MUST BE RE-DERIVED — it is not
// enough to re-read it.
//
// ⚠⚠ **F-2 (2026-09-18): THIS PREDICATE HAS NO MEASURED CUSTOMER IN EITHER
// DIRECTION, AND THE SOURCE MUST SAY SO** (`CLAUDE.md` L10 — *"a fence with no
// reachable customer and no failing fixture is a prediction, not a test"*).
// Measured by the independent Rule-13 round: it returned **`true` on all 19 of its
// probes**, including the F-1 witness where `true` is a FALSE NEGATIVE; and the
// implementer's hand-off corpus sweep is **6566 rows, 16 movers, ZERO VERDICT
// FLIPS**, so it declined nothing new anywhere in the tree. **bd `6n1s`'s P1 was
// closed, for the shapes it IS closed for, by the USE-SIDE relaxation alone**
// (`useCompleteBeforeDischarge` makes the rails actually discharge, so conjunct
// (3) never needs to fire). This conjunct contributed nothing measurable. It is
// KEPT because a sufficient condition that is sound in the decline direction costs
// nothing — but do not read it as the fix's fence. The fence is the obligation
// ledger below.
//
// ⚠⚠ **F-3 (2026-09-18): THE LIST OF REFUSALS THIS PREDICATE DOES NOT MODEL WAS
// INCOMPLETE, AND IT OMITTED THE ORDINARY ONE.** It used to name *"clause (d),
// `preservesBasisUnderRecord`, or a `ReversedGates` overlap"* — three exotic
// mechanisms — while leaving out **`planInteriorComponent` §4's per-gate
// `DT.dominates(G, At)` on an ARM-MINTED interior rail, which is the refusal a
// MULTI-BLOCK BODY PRODUCES BY CONSTRUCTION**, i.e. the one this predicate's own
// shape class generates. The list read as exhaustive over rare cases while missing
// the common one; that is F-1's whole mechanism.
//
// **WHICH IS WHY THE SUPPRESSION IS NOW VERIFIED AND NOT TRUSTED.** The more total
// alternative this comment used to name and decline — the
// `declineSurvivingIntrinsicCalls` pattern: record the suppression and VERIFY the
// discharge at the tail of the pass, where it is a fact rather than a prediction —
// **is now what ships** (`markedBodyRailObligations` /
// `declineUndischargedMarkedBodyRails`). This predicate is the cheap early answer;
// the ledger is what makes conjunct (1) total.
// ── bd `test_C_libtooling-6n1s` F-1 (2026-09-18) — THE MARKED BODY'S OBLIGATION
//    LEDGER, and the reason conjunct (1) stopped being a plain suppression ─────
//
// **A PREDICTION ABOUT ANOTHER FILE'S PLACEMENT IS NOT A FENCE.** Conjunct (1)
// suppresses the dephasing decline when a body is marked and its interior rails
// have an in-body post-dominator to be discharged at. Both halves are true of the
// F-1 witness and the rails are still NOT discharged, because
// `Uncomputation::planInteriorComponent` §4 abandons the whole component on the
// per-gate `DT.dominates(G, At)` when the ARM mints one of them. So the record
// below carries the suppression forward and
// `declineUndischargedMarkedBodyRails` decides on the FACT.
//
// ⚠ `WeakTrackingVH`, and it is load-bearing exactly as it is for
// `recordRound1RailGrant`: `lowerOps` RAUWs the `ashr`/`add`/… this stage sees to
// the `cq_template_*` CALL that replaces it, and a `WeakTrackingVH` FOLLOWS a
// RAUW — so the ledger names the LOWERED rail by the time the verifier reads it,
// with no second lookup and no name matching. A handle that goes NULL is a rail
// that no longer exists (deleted, not lowered) and is treated as DISCHARGED:
// there is nothing left to leak.
//
// ⚠ NO NEW `TaintSet` FIELD. A new member in the MIDDLE of that struct is the
// ODR/layout divergence that segfaulted `cq-opt` while `libCQPass.so` lowered
// correctly (bd `tu9q` IMPL_T2 §13). A function-local static is the pattern this
// file already uses for `deferredDephasingSlot`.
//
// ⚠ CLEARED AT BOTH ENDS, for bd `bbu0`'s reason: a second module in the same
// process must never inherit the first one's ledger.
// `declineDephasingUnmarkedLoopRails` clears it on entry (it is the only writer
// and runs once per module in BOTH pipeline entry points), and the verifier
// clears it after reading. Either alone would do; neither depends on the other.
std::vector<WeakTrackingVH> &markedBodyRailObligations() {
  static std::vector<WeakTrackingVH> Ledger;
  return Ledger;
}

void recordMarkedBodyRailObligation(Value *Rail) {
  for (const WeakTrackingVH &H : markedBodyRailObligations())
    if (H == Rail)
      return;  // idempotent.
  markedBodyRailObligations().emplace_back(Rail);
}

bool markedBodyRailsHaveInBodyDischargePoint(Loop *L, const LoopInfo &LI,
                                             TaintSet &taint,
                                             PostDominatorTree &PDT) {
  SmallVector<BasicBlock *, 8> Blocks;
  for (BasicBlock *BB : L->blocks()) {
    if (LI.getLoopFor(BB) != L)
      continue;  // a strictly-deeper subloop's block — not `L`'s to mint in.
                 // `railLocalQualifies` refuses any body with a TAINTED subloop
                 // outright, so this skip cannot hide a rail that reaches here.
    for (Instruction &I : *BB) {
      if (!taint.Tainted.count(&I))
        continue;
      if (!mintsOutOfPlaceTemplateRail(&I, taint))
        continue;  // mints nothing, or relabels the rail IN PLACE — no discharge
                   // is owed and none is placed.
      if (!railIsInterior(&I))
        continue;  // measure-owned: left allocated by the rolled form AND by the
                   // hand-unrolled twin, and a measured copy is not a coherent
                   // which-path record (`measureOwnedInvariantRail`'s physics
                   // half states the same ground from the other side).
      Blocks.push_back(BB);
      for (User *U : I.users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI)
          return false;  // an unclassifiable user — absence of proof, and the
                         // safe direction here is to ARM the fence.
        if (!L->contains(UI->getParent()))
          return false;  // the rail ESCAPES `L`; no per-trip point can exist.
                         // `Loop::contains` — "is this user inside this cycle AT
                         // ALL" — INCLUDES subloops, which is the right
                         // quantifier for THIS question and deliberately not the
                         // own-blocks one the loop above uses for "whose block is
                         // this to mint in" (`CLAUDE.md` L2; bd
                         // `test_C_libtooling-emkg` is the filing that exists
                         // because one predicate answered the other's question).
        Blocks.push_back(UI->getParent());
      }
    }
  }
  if (Blocks.empty())
    return true;  // no interior rail at all — nothing for the suppression to be
                  // wrong about, and `loop_leak_dephase_accept_*` live here.
  BasicBlock *Common = Blocks.front();
  for (BasicBlock *B : ArrayRef<BasicBlock *>(Blocks).drop_front()) {
    Common = PDT.findNearestCommonDominator(Common, B);
    if (!Common)
      return false;  // the consumers do not reconverge — `dagInsertPoint` would
                     // return null and the component leaks.
  }
  // The point must be one of `L`'s OWN blocks AND marked: `L`'s own, because a
  // point in a strictly-deeper subloop repeats N times per outer trip against a
  // once-per-trip mint; marked, because that is the exact exception
  // `planInteriorComponent`'s §2.9 grants and this predicate exists to model.
  return LI.getLoopFor(Common) == L &&
         taint.IterationLocalBlocks.count(Common) != 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// bd `test_C_libtooling-bbu0`, owner ruling **E6 (2026-09-15) = option (D)** —
// THE INSTRUMENT. **IT DECIDES NOTHING SEMANTICALLY** and must not be traded
// against options A/B/C, which are ruled next session **on the number it
// produces** (`$SES/trackD/MEASUREMENT.md`).
//
// WHAT IT EXISTS FOR. The question that separates those options —
//
//     is `RotationLowering::warnLiveRecordRotations` ever SILENT on a module
//     that this fence DECLINES?
//
// — **cannot be asked of any shipped binary.** This fence is called at
// `CQLoweringPass.cpp:772`, the warn stage at `:864`, and `LLVMContext::diagnose`
// **EXITS on the first `DS_Error`** (bd `br4a`). A module that declines here
// NEVER REACHES the warning, so every "0 warnings" row over a declining module is
// **0 BY PREEMPTION, NOT BY SILENCE** — including every `†` row of Track S′'s
// table (`$SES/trackS/QUESTION_bbu0.md` §1/§3, which measured it and said in so
// many words that it did NOT construct a counter-example and does NOT claim one
// exists).
//
// ⚠ WHY THIS SPELLING AND NOT EITHER OF THE TWO THE RULING NAMES. Both literal
// readings were read against the source before anything was written (Rule 11) and
// **both are unimplementable**, for one shared reason that is itself the reason
// the gap exists: *the warning is a question about a LOWERED module and this
// fence is a question about an UNLOWERED one.*
//   * "MOVE THE WARNINGS EARLIER" — `warnLiveRecordRotations` opens with
//     `if (taint.UserChainedRotations.empty()) return false;` and then matches
//     emitted `cqrt_ry_<W>` / `cqrt_ry_<W>_controlled` CALLS. That set is filled
//     by `lowerRotations` at `:774`, AFTER this fence. Called at this slot the
//     stage returns on its first line and is silent on EVERYTHING — which would
//     move the verdict of every accepting module that warns today, and would
//     "measure" SILENT on 100 % of the population while meaning nothing.
//   * "HAVE THE FENCE CONSULT THE WARNING'S RECORD SET" — that set (`RecordSet`
//     + `collectAncestorRecords` / `collectDescendantRecords`) is built INSIDE
//     the warn stage out of emitted `cqrt_*` calls; at this slot it does not
//     exist. Re-deriving it here is the second-spelling defect (Rule 14 / drbq
//     Inc-3 (b′)) that the ruling's own §2 identifies as the REAL duplication —
//     and it is **option C**, which is **not ruled**.
// What IS implementable is the third reading of the same sentence: leave both
// stages exactly where they are and **defer THIS FENCE'S DECLINE past the warn
// stage**, so the warnings are emitted before it. That is literally *"emit the
// warnings BEFORE the fence's decline"*.
//
// WHY THE DEFERRED RUN GIVES THE *RIGHT* NUMBER, not merely a number. This fence
// is **pure analysis** — `LoopPlan.h` says so and the body was re-read for this
// change rather than inherited: a `GateCalls` set, a `DominatorTree`, a
// `LoopInfo`, and calls to `peelInPlaceBase` (`const TaintSet &`),
// `mintsOutOfPlaceTemplateRail`, `railIsInterior` and `taintedAncestryReaches`,
// every one a READ. So suppressing its `diagnose` yields **exactly the pipeline a
// build with this fence DELETED would run**, and the module the warn stage then
// sees is exactly the circuit the fence exists to refuse. ⚠ RETIREMENT TRIGGER:
// the day this fence mutates anything — IR, `taint`, or a plan — the instrument
// stops measuring the fence-deleted pipeline and this paragraph is FALSE.
//
// ⚠ IT CANNOT TURN A DECLINE INTO AN ACCEPT, AND THAT IS THE WHOLE SAFETY
// ARGUMENT — a control-flow fact, not a hope. Under the gate the verdict is
// RECORDED and re-emitted by `emitDeferredDephasingDecline`, which is called
// UNCONDITIONALLY in BOTH entry points; the only paths that skip it are ones a
// `DS_Error` has already exited on. The variable changes WHEN the decline is
// emitted, never WHETHER — and that is **pinned, not argued**: the gated RUN line
// of `loop_leak_dephase_reject_inloop_rotation.ll` is a `not %cq-opt`, so the
// suite fails the moment the gate accepts.
//
// ⚠ THE DEFAULT IS BYTE-IDENTICAL. With the variable unset this returns false and
// the code path is the shipped `diagnose(&I, …); return;`. The `getenv` is
// evaluated AT MOST ONCE PER MODULE and only on the declining path — never on an
// accept. (Precedent for the mechanism is in-tree and long-standing:
// `CQ_CTRL_DBG`, `CQ_RAILBANK_DBG`, `CQ_PREDMUX_DBG`, `CQ_PREDMUX_COUNT`,
// `CQ_UNROLL_DBG`, `CQ_CTLZ_DBG`, `CQ_FP80_DBG`, `CQ_SPEC_DBG`.)
bool deferDephasingDecline() {
  return ::getenv("CQ_BBU0_DEFER_DEPHASE_FENCE") != nullptr;
}

// The deferred verdict. ⚠ **NOT an `Instruction *`, and not a `Function *`
// either.** Everything between this fence's slot and the late slot lowers, RAUWs
// and ERASES (`lowerRotations`, `lowerOps`, `lowerMeasures`,
// `lowerBreakReversePlay`, `lowerLateReassignments`, `uncompute`), so the
// offending instruction is very likely gone by the time the decline is emitted,
// and holding a raw pointer across that window is the "dereferences freed memory
// (SIGSEGV on valid input)" shape `CLAUDE.md` L9 already charged this project
// once. A function NAME is re-looked-up in the module at emit time and a
// `DebugLoc` is a value copy of a reference to a context-uniqued `DILocation`, so
// the deferred diagnostic carries the SAME source location the un-deferred one
// would — which is what makes a deferred row comparable to its control row byte
// for byte apart from ORDER.
struct DeferredDephasing {
  std::string FName;
  DebugLoc Loc;
  bool Armed = false;
};

DeferredDephasing &deferredDephasingSlot() {
  static DeferredDephasing Slot;
  return Slot;
}

}  // namespace

// See the argued block above `kMsgRound1GrantFalsified`. Pure check: it rebuilds
// DT/LI on the post-fixpoint CFG (Rule 11/9 — the round-1 trees are long invalid),
// finds each recorded loop BY HEADER BLOCK, and re-asks `railLocalQualifies`
// under FINAL taint.
void declineRound2FalsifiedRailGrants(Module &M, TaintSet &taint,
                                      WidthDispatch &wd) {
  if (taint.Round1RailGrants.empty())
    return;
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());

  // (0) A NULLED HEADER FIRST, AND LOUDLY. The record is written at ROUND-1 taint
  //     and read after the ROUND-2 fixpoint, and `RegionFlatten` erases blocks in
  //     that window: round-2 taint growth can open a region INSIDE a loop this
  //     grant named, and a header that is also that region's merge block goes with
  //     it. The loop the grant proved something about then does not exist, so the
  //     proof has no subject — refuse. It is asked HERE, before the per-function
  //     walk, because a nulled header cannot be attributed to a function at all;
  //     `Fn` exists solely to give the diagnostic somewhere to land. ⚠ A skip
  //     would be silent, and `taint.IterationLocalBlocks` is a raw `BasicBlock *`
  //     set that NOTHING scrubs (`LoopLowering.cpp`'s own note at the
  //     `declineUnmarkedRolledIterLocal` marking scan), so a grant whose blocks
  //     were erased leaves stale addresses in it — and a freed address is reused
  //     by the next allocation, which is exactly how F-W1-1's `insert(L).second`
  //     returned FALSE FOR A DIFFERENT LOOP.
  for (const TaintSet::Round1RailGrant &G : taint.Round1RailGrants) {
    if (isa_and_nonnull<BasicBlock>(G.Header))
      continue;
    auto *F = dyn_cast_or_null<Function>(G.Fn);
    if (!F || F->isDeclaration() || F->empty())
      continue;  // the whole function is gone — nothing will be emitted from it.
    diagnose(F->getEntryBlock().getTerminator(), kMsgRound1GrantFalsified);
    return;  // `diagnose` EXITS on the first DS_Error (bd `br4a`).
  }

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    bool Any = false;
    for (const TaintSet::Round1RailGrant &G : taint.Round1RailGrants)
      if (auto *H = dyn_cast_or_null<BasicBlock>(G.Header))
        if (H->getParent() == &F) {
          Any = true;
          break;
        }
    if (!Any)
      continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    for (const TaintSet::Round1RailGrant &G : taint.Round1RailGrants) {
      auto *Hdr = dyn_cast_or_null<BasicBlock>(G.Header);
      if (!Hdr || Hdr->getParent() != &F)
        continue;  // another function's record (a nulled one died at (0) above).
      // The LOOP the header headed need not have survived the round-2 flatten:
      // no loop, or a different loop's header, ⇒ no proof ⇒ refuse LOUDLY.
      Loop *L = LI.getLoopFor(Hdr);
      if (!L || L->getHeader() != Hdr) {
        diagnose(Hdr->getTerminator(), kMsgRound1GrantFalsified);
        return;  // `diagnose` EXITS on the first DS_Error (bd `br4a`).
      }
      SmallPtrSet<Value *, 4> Roots;
      bool Nulled = false;
      for (const WeakTrackingVH &R : G.Roots) {
        if (!R) {
          Nulled = true;
          continue;
        }
        Roots.insert(R);
      }
      // ── bd `test_C_libtooling-xdu2.16` — A NULLED ROOT IS NO LONGER A REFUSAL
      //    BY ITSELF; IT FORCES A TOTAL RE-DERIVATION. ─────────────────────────
      //
      // WHAT THIS REPLACED. Until xdu2.16 a nulled root was refused HERE,
      // unconditionally, before any re-derivation, on the ground that "the proof
      // has no subject". Its own comment set the retirement trigger: *"if this is
      // ever measured to fire on a program that should compile, it is an
      // over-decline to FILE (owner ruling 2026-09-11), not a fence to relax in
      // place."* It was measured (bd xdu2.13 Track E, probes p19/p20; xdu2.8's
      // row 13), it WAS filed (bd xdu2.16), and this is that bead's red-green —
      // the trigger used in the ACCEPT direction, through the process it names,
      // not a relaxation in place. What stays: the fence, its string, both entry
      // points, and the refusal of every grant this block cannot re-prove.
      //
      // THE SHAPE, measured on the frozen oracle `438c77bf45c02e3e`: `-O1`
      // LICM-hoists a loop-invariant compound condition (`(q > 1) & (r < 5)`, the
      // hybrid `q && m == n`, or one hoisted compare LEAF under an in-body `and`)
      // into the preheader; at ROUND 1 clause (ii-d) admits that hoisted node as
      // a Root; the 4.4 emitter then consumes the tree — `emitCondNetwork` mints
      // FRESH flags from the LEAVES' OPERANDS immediately before the select, in
      // the body, strips and frees them there — and ERASES the now-dead node
      // (`SelectMergeEmit.cpp`'s root-first dead-tree cascade). The recorded
      // `WeakTrackingVH` goes NULL. The value the root named is gone because
      // NOTHING READS IT ANY MORE: its replacement is the emitter's in-body reads
      // of the leaves' operands, which are themselves outside-`L` tainted reads
      // and therefore exactly what a fresh derivation asks about.
      //
      // WHAT IS ASKED INSTEAD, and why it is the STRONGER question. For a grant
      // with a nulled root, EVERY round-1 root is DISCARDED — the surviving ones
      // too, not unioned — and the grant must be RE-DERIVED FROM SCRATCH under
      // FINAL taint by the owner (`invariantRegisterRoots`, Rule 14), and that
      // re-derivation must be TOTAL: `false` is a refusal here, not "adds
      // nothing". `railLocalQualifies` is then re-asked on the fresh set alone.
      // Compare the intact-grant path below: it UNIONS the round-1 roots with a
      // fresh derivation that may FAIL. `railLocalQualifies` is MONOTONE in its
      // `Roots` (every clause that reads them — `Roots.empty()`, `onRail` in the
      // escaping-temp and invariant-input clauses — refuses less as the set
      // grows), so a nulled grant this block accepts is one the intact-grant path
      // would also accept over the SAME post-fixpoint IR, and on no round-1
      // evidence at all. The change adds no accept the tu9q re-ask's own
      // soundness argument does not already cover.
      //
      // ⚠ WHY THE ERASER'S IDENTITY IS NOT ASKED. A `WeakTrackingVH` goes NULL
      // only when its value is DELETED; a value that is REPLACED (RAUW — including
      // LLVM's own `DeleteDeadBlock`, which RAUWs a dead block's instructions to
      // `poison` before erasing them) is FOLLOWED, not nulled. And a value can
      // only be deleted in a valid module once it has NO users (`~Value` asserts
      // "Uses remain when a value is destroyed" in a +Asserts build; in Release a
      // survivor would be a dangling operand the in-process verifier trips on).
      // So a nulled root was unread when it died and names nothing the current
      // IR reads: it covers no current read, and dropping it can only REMOVE
      // coverage.
      // What the marking must be justified by is the CURRENT IR, and that is
      // exactly what a total FINAL-taint re-derivation plus `railLocalQualifies`
      // certify. The marking's GRANTING readers (`FreePoint`, `Uncomputation`,
      // which place in-body discharges on it) all run AFTER this stage. Its two
      // other readers run BEFORE it — `declineUnmarkedRolledIterLocal`
      // (`CQLoweringPass.cpp:729`/`:1368`) and `declineDephasingUnmarkedLoopRails`
      // (`:905`/`:1446`, immediately above this stage) — and both read it in the
      // SUPPRESSING direction: a marked body silences their decline. That is the
      // arrangement the intact path already relies on (this function's own "STILL
      // MARKS NOTHING" note): a suppression made on a marking this stage then
      // REFUSES is harmless, because the refusal declines the module; a marking
      // this stage certifies justifies the suppression after the fact.
      // ⚠ RESIDUAL, STATED: `railLocalQualifies` keys its operand scan on
      // `taint.Tainted`, and an emitter-minted rail is not in that set. A nulled
      // root whose value were REPLACED by an emitter rail minted OUTSIDE `L` and
      // read inside it would be invisible to the scan. No emitter does that
      // today — every one this window can reach emits at its own `Pred`/select,
      // i.e. in the body for an in-body consumer — but it is a blindness of the
      // scan, not a proof, and it is the same blindness the intact path has.
      // RETIREMENT TRIGGER: an emitter that can hoist its stream OUT of the loop
      // whose body consumes it.
      //
      // ⚠ WHAT THE ROUND-1 GRANT LEFT BEHIND, and why each is safe. (a) The
      // marking itself — re-certified here or declined. (b) Clause (ii-d)'s exit
      // obligation for the erased node — its `WeakTrackingVH` is null too, and
      // `declineUndischargedExitObligations` reads a null obligation as
      // discharged, correctly: the node was never lowered, so there is no rail
      // to leak. (c) `commitOutOfLoopInPlaceOps`' dtzb commitments for the
      // node's preheader chain — re-verified under FINAL taint by `lowerOps`'
      // own tripwire, which declines loudly (a condition-tree `and`/`or`/`xor`
      // has no `add`/`xor`-on-a-rail chain to commit in the first place).
      //
      // ⚠ THE MUTATION RUNS BEFORE A POSSIBLE DECLINE NOW, and that is safe for
      // the reason the intact path's own comment gives: `invariantRegisterRoots`
      // rolls its `InPlaceRailOps` commitments back on failure, so a failed
      // re-derivation leaves `taint` byte-identical, and `diagnose` EXITS on the
      // first `DS_Error` (bd `br4a`), so nothing downstream reads it.
      //
      // ⚠⚠ AND ON THE **SUCCESS** PATH THE FRESH DERIVATION HAS TWO SIDE EFFECTS
      // THAT THE TWO PARAGRAPHS ABOVE DO NOT COVER (xdu2.16 Rule-13 r1A F-A1-3,
      // r1B F-B1-3; L7 — the ground is stated here, not only in the record).
      // Round 1's only candidate was usually the hoisted tree node, so the
      // FRESH candidates — the leaves' registers — were never judged at round 1
      // at all, and the intact path's "idempotent with round 1's" argument below
      // does NOT reach them:
      //   (i) NEW dtzb IN-PLACE COMMITMENTS. `commitOutOfLoopInPlaceOps` may add
      //       a preheader `add`/`xor` on a fresh candidate's chain to
      //       `InPlaceRailOps` / `PreLoopCommittedInPlaceOps` HERE — i.e. AFTER
      //       `declineStaleRecordOps`, `recordStaleQuantumReaders` and
      //       `declineRecordedStaleQuantumReaders` have run, so none of those
      //       fences saw the commitment (measured, r1A `ch/f1`, `ch/f2`: late
      //       `cqrt_addc_i32`/`cqrt_xorc_i32` commitments). SAFE TODAY because
      //       every such commitment is re-verified at `lowerOps` by the (1b)
      //       tripwire, which re-asks `classifyInPlaceReassignment` under FINAL
      //       taint and DECLINES loudly if it no longer holds; and that
      //       predicate's G6 conjunct forbids any later read of the mutated
      //       parent, so there is no reader for the earlier stale-record fences
      //       to have missed (r1A `f1`/`f2` are byte-identical to twins in which
      //       M-C reaches the same decision at `lowerOps`; `f3`, where the parent
      //       IS read later, has G6 refuse → IRR false → a loud decline, the
      //       safe direction). RETIREMENT TRIGGER: the day the (1b) tripwire
      //       stops declining, or G6 admits a later parent read, these late
      //       commitments are unchecked by any stale-record fence.
      //   (ii) NEW (ii-d) EXIT OBLIGATIONS. A fresh derived-rail candidate
      //       (`int p = q*q;`, a hoisted `sext`, `q^m`) is admitted by clause
      //       (ii-d), which records an obligation in the ledger at THIS slot.
      //       `declineUndischargedExitObligations` then enforces it after
      //       `uncompute` — the anchor places the discharge or the module
      //       declines `hoisted invariant rail admitted for in-loop discharge was
      //       not discharged`. That postcondition, not this re-derivation, is
      //       what stops an undischarged fresh root. SAFE because a ledger entry
      //       can only ADD declines, never an accept; MEASURED as the dominant
      //       remaining wall of this shape — r1A: 10 of its 168 probe pairs, r1B:
      //       87 of 510 sweep cell-forms move from this fence's string to the
      //       postcondition's (an over-decline, bd `test_C_libtooling-xdu2.21`).
      //
      // Pinned: `loop_condtree_select_accept_hoisted_{and,mixed_literal,leaf,
      // nest}.ll` and `predmux_guarded_vla_reject_row13_hybrid_select.ll` (L8
      // name) ACCEPT; `loop_condtree_select_reject_nulled_root_not_rederivable
      // .ll` is the neighbour this block must still refuse — a nulled root AND a
      // round-2-tainted derived read that clause (ii-d) cannot admit.
      if (Nulled) {
        SmallPtrSet<Value *, 4> Fresh;
        if (!invariantRegisterRoots(L, taint, wd, DT, LI, GateCalls, Fresh,
                                    /*CarriedRoots=*/nullptr)) {
          diagnose(L->getHeader()->getTerminator(), kMsgRound1GrantFalsified);
          return;  // `diagnose` EXITS on the first DS_Error (bd `br4a`).
        }
        bool AnyLocal = false;
        Instruction *WhyNot = nullptr;
        if (!railLocalQualifies(L, taint, LI, GateCalls, Fresh, AnyLocal,
                                &WhyNot)) {
          diagnose(WhyNot ? WhyNot : L->getHeader()->getTerminator(),
                   kMsgRound1GrantFalsified);
          return;
        }
        continue;
      }
      // ⚠ RE-DERIVE THE ROOTS UNDER **FINAL** TAINT BEFORE RE-ASKING, BY CALLING
      // THE OWNER (`invariantRegisterRoots`), NOT BY RE-SPELLING ITS CLAUSES
      // (Rule 14). Asking `railLocalQualifies` with the ROUND-1 `Roots` alone is
      // asking a DIFFERENT QUESTION and it OVER-DECLINES — measured on the
      // reachability probe `trackT/probes/adv/l1_round2_grow_65arm.ll`: a 6.5
      // classical-call arm OUTSIDE the loop whose merged result is read inside it
      // is UNTAINTED at round 1 (the merge phi's incomings are a classical call
      // result and a constant), so the round-1 grant is made without it; after
      // `repropagateControlMerges` the body reads the emitter's `%out` rail, which
      // clause (ii-b) ADMITS as a merge out-rail — the grant is still justified,
      // it is just justified by a root the round-1 record could not name. The
      // round-2 region path reaches the same conclusion by the same call, and only
      // fails to run here because `collapseFlattenedLoopRails` opens
      // `if (taint.InLoopFlattenedPreds.empty()) return;` and this region is not
      // IN a loop.
      //
      // GRANT-ONLY **FOR AN INTACT GRANT** (a nulled one never reaches here — the
      // xdu2.16 block above reads the same call's FALSE as a refusal), and both
      // halves of that matter: a FALSE return adds nothing
      // (the recorded roots may still suffice on their own), and
      // `invariantRegisterRoots` rolls its own `InPlaceRailOps` commitments back
      // on failure, so a failed re-derivation leaves `taint` byte-identical. A
      // TRUE return's commitments are idempotent with round 1's (`commitOutOfLoop
      // InPlaceOps` skips an op already in `InPlaceRailOps`) and are re-verified
      // under FINAL taint by `lowerOps`' own tripwire, which declines loudly
      // rather than falling back silently.
      //
      // ⚠ THIS FUNCTION STILL MARKS NOTHING. `declineDephasingUnmarkedLoopRails`
      // runs just above and reads `taint.IterationLocalBlocks`; a stage below it
      // that could ADD a marking would make that fence read a set that is still
      // moving, which is exactly the RETIREMENT TRIGGER its own header states.
      // Re-deriving ROOTS is not marking.
      SmallPtrSet<Value *, 4> Fresh;
      if (invariantRegisterRoots(L, taint, wd, DT, LI, GateCalls, Fresh,
                                 /*CarriedRoots=*/nullptr))
        Roots.insert(Fresh.begin(), Fresh.end());
      bool AnyLocal = false;
      Instruction *WhyNot = nullptr;
      if (!railLocalQualifies(L, taint, LI, GateCalls, Roots, AnyLocal,
                              &WhyNot)) {
        diagnose(WhyNot ? WhyNot : L->getHeader()->getTerminator(),
                 kMsgRound1GrantFalsified);
        return;
      }
    }
  }
}

void declineDephasingUnmarkedLoopRails(Module &M, TaintSet &taint) {
  // bd `bbu0` (D): the instrument's slot is cleared HERE — before the
  // `Tainted.empty()` early-out, and unconditionally — so a second module in the
  // same process can never inherit the previous one's armed verdict. Cheap
  // enough to be unconditional, which is better than correct-only-under-the-gate.
  deferredDephasingSlot() = DeferredDephasing{};
  // bd `test_C_libtooling-6n1s` F-1 — the marked-body obligation ledger is cleared
  // HERE, unconditionally and before anything can write it (this stage is its only
  // writer), so a second module in the same process never inherits the first's
  // obligations. Same discipline and same reason as the slot above.
  markedBodyRailObligations().clear();
  if (taint.Tainted.empty())
    return;
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // ⚠ THE CHEAP SKIP WALKS THE FUNCTION, NOT `taint.Tainted`, AND THE
    //    DIRECTION IS THE WHOLE POINT. Looking LIVE POINTERS UP IN the set is the
    //    safe direction and costs nothing. Do not "simplify" it back.
    //    ⚠ CORRECTED 2026-09-25 (bd test_C_libtooling-um24, L7): this note used
    //    to say `lowerLoops`' own prescan — which then iterated the SET and
    //    dereferenced each member — was "sound THERE because it runs before any
    //    region flatten", and that the four `scrubTaint` sites made this stage
    //    safe too. Both halves were a PREDICTION and the first was FALSE:
    //    `lowerLoops` runs after `lowerControlledIOSinks` and after its own
    //    earlier functions' `break` lowering, which erase tainted instructions
    //    without scrubbing, and the prescan SIGSEGVed on four shipped fixtures
    //    under a reusing allocator. The prescan now walks the function as this
    //    one does, and `taint.Tainted` can no longer HOLD a deleted key at all —
    //    it is self-cleaning on deletion (`ScrubOnDelete.h`, bd 8e5r/j8sk), which
    //    also makes this live-pointer lookup EXACT (a fresh instruction at a
    //    freed key's address used to answer `count() == true`).
    bool AnyTainted = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB)
        if (taint.Tainted.count(&I)) {
          AnyTainted = true;
          break;
        }
      if (AnyTainted)
        break;
    }
    if (!AnyTainted)
      continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    // bd `test_C_libtooling-6n1s` — conjunct (1)'s second half asks a
    // POST-dominator question (does a marked body's interior rail have an
    // in-body point to be discharged at?), so the tree is built once per
    // function that has a loop at all, beside the two this stage already builds.
    PostDominatorTree PDT(F);

    for (Loop *L : LI.getLoopsInPreorder()) {
      // (1) THE BODY MUST BE UNMARKED **OR ITS RAILS MUST HAVE A PER-TRIP
      //     DISCHARGE POINT**. A marked body whose interior rails all reconverge
      //     at an in-body post-dominator discharges in-body, once per trip,
      //     against a once-per-trip forward stream — the affirmative 7.3
      //     exception. `s3_live_rootmint_region` is exactly that and is the
      //     positive control: it has the SAME post-loop `Ry` and MUST stay
      //     accepting.
      //
      //     ⚠⚠ **THE SECOND CONJUNCT IS NOT DECORATION AND THE SENTENCE THAT
      //     STOOD HERE WITHOUT IT WAS FALSE** (bd `test_C_libtooling-6n1s`, P1
      //     OVER-ACCEPT, 2026-09-18). It read *"A marked body discharges in-body,
      //     once per trip … and is byte-identical to its hand-unrolled twin"* —
      //     TRUE of a single-block body, FALSE of a multi-block one, and the
      //     counter-example is a plain re-joining classical `if` with no break at
      //     all. `markIfRailLocal` marks **every** own block of `L`, so a body
      //     with internal classical control flow is marked WHOLESALE; whether its
      //     rails are then discharged is a question about
      //     `Uncomputation::dagInsertPoint`, which this conjunct now asks
      //     (`markedBodyRailsHaveInBodyDischargePoint`, above) instead of
      //     assuming. `CLAUDE.md` L7-with-a-twist: the correction is applied HERE,
      //     at the site, and not only in the review that found it.
      //
      //     ⚠ ALSO NOTE WHAT THE OLD SENTENCE PROMISED AND COULD NOT KEEP: byte
      //     identity with the hand-unrolled twin is an INSTRUMENT, not the claim
      //     (owner ruling S3, 2026-09-17). A rolled body that discharges at its
      //     own in-body post-dominator is MULTISET-identical to its twin and
      //     ORDER-divergent by construction, and quoting byte identity as the
      //     property is how a stability measurement gets read as a correctness
      //     one (`CLAUDE.md` §5, the three `*_leak_control` headers).
      //
      //     ⚠ `L`'s OWN BLOCKS, AND IT IS ASKED BY CALLING THE ONE OWNER OF THAT
      //     QUESTION (`bodyBlocksMarked`, above; Rule 14). THE SPELLING THAT USED
      //     TO STAND HERE — an ANY over the raw `L->blocks()` — WAS A **P1
      //     OVER-ACCEPT** (bd `test_C_libtooling-emkg`, closed 2026-09-15; found
      //     by Rule-13 round 2, `review_r13_loop/REVIEW.md` F-1). `Loop::blocks()`
      //     includes every strictly-deeper subloop's blocks, so a marked INNER
      //     loop silenced this entire fence for its ENCLOSING OUTER loop —
      //     conjuncts (2) and (3) were never evaluated for the outer body at all,
      //     even though conjunct (3) EXCLUDES those same inner blocks itself.
      //     The two conjuncts of one fence were reading the same closure through
      //     different quantifiers (`CLAUDE.md` L2), and the sibling stage had the
      //     right spelling the whole time.
      //     MEASURED, three markers, one stage-1 module each, rolled vs
      //     hand-unrolled twin: `markIfIterationLocal` 38 vs 42 (PRE-EXISTING —
      //     it reproduces on the 2026-09-15 ORACLE `0e280fc6…` and needs no
      //     2026-09-15 track); the bd `test_C_libtooling-tu9q` root-mint escape
      //     DECLINE → 30 vs 34; its clause (ii-c) DECLINE → 43 vs 48. The missing
      //     lines are in every case the OUTER body's `cq_template_*_unc` +
      //     `cqrt_free` pairs, standing at a `cqrt_ry_*` on the register they
      //     copy — `opt` exit 0, verify-clean, stage-2b structurally blind
      //     (template-minted rails have no `cqrt_alloc` to count).
      //     ⚠⚠ **THE SUPPRESSION IS NO LONGER A `continue`. IT IS A PROMISE THAT
      //     IS KEPT OR THE MODULE DECLINES** (bd `test_C_libtooling-6n1s`, the
      //     independent Rule-13 round of 2026-09-18, finding F-1).
      //
      //     The first version of this conjunct suppressed the fence outright on
      //     `bodyBlocksMarked && markedBodyRailsHaveInBodyDischargePoint`. That
      //     PREDICTS a placement another file makes several stages later, and the
      //     prediction is WRONG for a shape a multi-block body produces BY
      //     CONSTRUCTION: when the ARM mints an interior rail, the component
      //     contains a gate in the arm, and `planInteriorComponent` §4 abandons
      //     the WHOLE component on `DT.dominates(G, At)` — the `At` is the join,
      //     which the arm does not dominate. MEASURED on
      //     `trackT2/probes/g8_arm_use_derived_owned_rot.c`: 4 `ashr` mints, ZERO
      //     `_unc`, ZERO `cqrt_free`, then `cqrt_ry_i32(h0,0.9)` and
      //     `cqrt_measure_i32(h0)` — four coherent which-path records at a
      //     non-diagonal gate on the register they copy (Rule 8), at `opt` exit 0.
      //     ONE TOKEN away (`g8a`, the arm's rail measure-owned instead of
      //     interior) the same body discharges 4/4.
      //
      //     So the suppression now RECORDS an obligation and
      //     `declineUndischargedMarkedBodyRails` VERIFIES it at the tail of the
      //     pass, where the discharge is a FACT rather than a forecast. This is
      //     the `declineSurvivingIntrinsicCalls` pattern (Rule 1: make a
      //     postcondition a CHECKED, LOUD property, not a comment) — and it is
      //     the alternative `markedBodyRailsHaveInBodyDischargePoint`'s own header
      //     named and declined to take. F-1 is the measured reason to take it.
      //
      //     ⚠ THE RECORD IS TAKEN AT CONJUNCT (3), NOT HERE, and that is the
      //     whole reason this is not a mass over-decline: the hazard needs
      //     conjuncts (2) AND (3) as well, so a loop with no post-loop chained
      //     rotation records NOTHING and is unaffected. Suppressing here only
      //     means "do not decline YET".
      const bool SuppressedByMarking =
          bodyBlocksMarked(L, LI, taint) &&
          markedBodyRailsHaveInBodyDischargePoint(L, LI, taint, PDT);

      // (2) A NON-DIAGONAL GATE ON AN EXISTING REGISTER, ON OR AFTER THE LOOP.
      //     `cq_theta` is the only non-diagonal gate the surface can express
      //     (`cq_phi` is a branch PHASE and diagonal, and a diagonal gate
      //     commutes with a basis-copy record, so it cannot be dephased by one).
      //     A theta whose arg 0 is CLASSICAL is a SOURCE: it mints a fresh rail
      //     and has no existing register to dephase, so only a CHAINED one
      //     counts.
      //
      //     ⚠ THE `L->contains(&BB)` SKIP THAT USED TO STAND HERE WAS A SCOPE,
      //     NOT A PROOF, AND IT IS GONE (bd `test_C_libtooling-c767`, P1, closed
      //     2026-09-15; found by Rule-13 round 1β on the 2026-09-14c binary).
      //     An interfering rotation INSIDE the body was invisible to this walk,
      //     `Rots` came back EMPTY and the loop was passed over — so the
      //     IDENTICAL dephasing accepted. MEASURED on bd `s82e`'s own
      //     D4-ruled-BENIGN exhibits plus one added in-loop line
      //     (`cq_theta(&u, .9);` before the trip ends): `w2k` 20 rolled vs 24
      //     unrolled, `w2h` 34 vs 42, md5-equal to the pre-fix binary in both
      //     (PRE-EXISTING, not a regression that increment introduced). THE
      //     MECHANISM DOES NOT CARE WHERE THE INTERFERENCE SITS — only that the
      //     leaked rail's partner is interfered AT ALL: a body that repeats
      //     carries trip k's undischarged rail across trip k+1's gate whatever
      //     the textual order inside the body, and the hand-unrolled twin
      //     discharges it (measured: its `_unc` + `cqrt_free` pair precedes the
      //     rotation in the trace).
      //
      //     ⚠ AND THE DIAGNOSTIC MOVED WITH THE SKIP, deliberately: the string is
      //     now "…entangled with a ROTATED REGISTER" and no longer claims a
      //     POSITION. `CLAUDE.md` L7-with-a-twist — a correction that is not
      //     applied at the site it describes is not a correction, and a message
      //     that still said "after the loop" would be the next round's finding.
      //
      //     What remains is one condition and it is the DOMINANCE one:
      //     `L->getHeader()` must dominate the gate's block, so every path to the
      //     gate runs the loop (or is inside it — the header dominates every
      //     block of a natural loop, which is why dropping the `contains` skip is
      //     the whole edit). Deliberately not `llvm::isPotentiallyReachable`
      //     (this file's own note at the `provablyBefore` helper explains why its
      //     exclusion set is wrong here). A CFG this misses leaves the
      //     PRE-EXISTING leak exactly as it is today — it can never create a new
      //     over-accept.
      SmallPtrSet<Value *, 4> Rots;
      for (BasicBlock &BB : F) {
        if (!DT.dominates(L->getHeader(), &BB))
          continue;
        for (Instruction &I : BB) {
          auto *CI = dyn_cast<CallInst>(&I);
          if (!CI)
            continue;
          const Function *Callee = CI->getCalledFunction();
          if (!Callee || !Callee->getName().starts_with("cq_theta_") ||
              CI->arg_size() < 1)
            continue;
          Value *Base = CI->getArgOperand(0);
          if (!taint.Tainted.count(Base))
            continue;  // a SOURCE theta — a fresh rail, no register to dephase.
          Rots.insert(peelInPlaceBase(Base, GateCalls, taint));
        }
      }
      if (Rots.empty())
        continue;

      // (3) AN INTERIOR TEMPLATE RAIL IN `L`'s OWN BLOCKS WHOSE ANCESTRY REACHES
      //     ONE OF THEM. The membership test is `mintsOutOfPlaceTemplateRail`
      //     (above) — "will `lowerOps` mint an OUT-OF-PLACE `cq_template_*` rail
      //     for this instruction", asked of the opcode owners rather than proxied
      //     by an opcode class.
      //     `L`'s OWN blocks only, for the reason `markIfRailLocal` gives at its
      //     own `L->blocks()` loop (a strictly-deeper subloop runs N times per
      //     outer trip and is a different multiplicity question).
      //
      //     ⚠ WHAT THIS REPLACED, KEPT BECAUSE THE RETIRED CLAUSE IS THE REASON
      //     THE FIX IS NOT THE OBVIOUS ONE (bd `test_C_libtooling-7845`, P1,
      //     closed 2026-09-15). The test used to be `isa<BinaryOperator>` plus a
      //     non-empty `binaryStem`, justified like this:
      //
      //         "a compare rail is the region's own flag, which `emitCondNetwork`
      //          strips and frees itself, so it is not a divergence and widening
      //          to it would decline shipped accepts."
      //
      //     TRUE of a compare that IS a region flag; FALSE of a compare used as
      //     DATA. `CompareLowering` lowers a tainted `icmp` whose result is
      //     ordinary data into an OUT-OF-PLACE `cq_template_icmp_<pred>_<W>_hl`
      //     rail — an ordinary which-path copy — with NO region and NO
      //     `emitCondNetwork` anywhere in the module. MEASURED: five lines of C,
      //     no control flow, whose only interior rail-minting op is an `icmp`
      //     (`icmp → zext → cq_measure`), 10 trace lines rolled against 14
      //     unrolled, and EVERY OTHER CONJUNCT SATISFIED — a SINGLE-CONJUNCT
      //     miss. `CLAUDE.md` L4: a set-membership question answered by an
      //     opcode-class proxy loses.
      //     ⚠ AND THE SECOND HALF OF THAT CLAUSE WAS NEVER MEASURED WRONG, which
      //     is why the fix is NOT `isa<BinaryOperator> || isa<CmpInst>`: a region
      //     FLAG compare must still be excluded. It is excluded by CALLING the
      //     owner of that distinction (`isDataPositionCompare`), never by
      //     re-deriving it here (Rule 14). The pinned decline is
      //     `loop_leak_dephase_reject_cmp_rail_data.ll`; the shipped region
      //     accepts that must NOT move are the two `loop_leak_dephase_accept_*`
      //     files plus the region corpus measured at the hand-off sweep.
      for (BasicBlock *BB : L->blocks()) {
        if (LI.getLoopFor(BB) != L)
          continue;
        for (Instruction &I : *BB) {
          if (!taint.Tainted.count(&I))
            continue;
          if (!mintsOutOfPlaceTemplateRail(&I, taint))
            continue;
          if (!railIsInterior(&I))
            continue;  // measure-owned — left allocated by BOTH forms.
          if (!taintedAncestryReaches(&I, Rots, taint))
            continue;  // copies a register nothing interferes later.
          // ── bd `test_C_libtooling-6n1s` F-1: THE MARKED BODY'S PROMISE ──────
          // Every conjunct has now fired, so this rail WOULD decline but for the
          // marking. Record it and decide at the tail of the pass on the FACT.
          // ⚠ `continue`, NOT `return`: unlike the two decline paths below (one
          // diagnostic per module, because `diagnose` EXITS on the first
          // `DS_Error`), a recorded obligation is not a verdict yet, so every
          // offending rail in every marked loop of every function must be
          // recorded — the verifier decides which, if any, speaks.
          if (SuppressedByMarking) {
            recordMarkedBodyRailObligation(&I);
            continue;
          }
          if (deferDephasingDecline()) {
            // bd `bbu0` (D) — RECORD and carry on, so that
            // `warnLiveRecordRotations` at the late slot gets to run on this
            // module at all. The decline is emitted by
            // `emitDeferredDephasingDecline` AFTER it. Note the `return` is the
            // SAME one the un-gated path takes: ONE verdict per module either
            // way, so the gate cannot turn one diagnostic into several.
            DeferredDephasing &S = deferredDephasingSlot();
            S.FName = I.getFunction()->getName().str();
            S.Loc = I.getDebugLoc();
            S.Armed = true;
            return;
          }
          diagnose(&I, kMsgLoopLeakDephases);
          return;      // ONE diagnostic: `diagnose` EXITS on the first DS_Error.
        }
      }
    }
  }
}

// bd `test_C_libtooling-bbu0` (owner ruling E6 = option D) — DRAIN the deferred
// verdict. Called UNCONDITIONALLY at the late slot in BOTH entry points,
// immediately after `warnLiveRecordRotations`; a no-op unless
// `CQ_BBU0_DEFER_DEPHASE_FENCE` armed it, which is why the shipped default
// cannot tell it is there. Contract and retirement triggers at
// `deferDephasingDecline` above and in `LoopPlan.h`.
//
// ⚠ THE MARKER LINE IS THE MEASUREMENT'S VACUITY GUARD, NOT DECORATION
// (`CLAUDE.md` L10 — *an instrument's failure mode is to report a pass*). It can
// only be printed from HERE, and HERE is after the warn stage, so a harness that
// sees it KNOWS the warn stage ran and may score a zero warning count as
// SILENCE. Without it, a harness scoring "0 warnings" as silent would be
// measuring its own reachability and would report SILENT on every preempted row
// — which is precisely the defect this whole instrument exists to remove. The
// string is mirrored character-for-character by
// `loop_leak_dephase_reject_inloop_rotation.ll`'s `DEFER` prefix and by
// `$SES/trackD/probes/bbu0_measure.sh`; a drift between the three is a Rule-12
// failure, not a cosmetic one.
// ── bd `test_C_libtooling-6n1s` F-1 — THE MARKED BODY'S POSTCONDITION ─────────
// Contract in `LoopPlan.h`; the reason it exists is at the ledger's definition.
// Called at the LATE slot in BOTH pipeline entry points, AFTER `uncompute`, which
// is the first program point at which "was this rail discharged?" is a FACT.
//
// ⚠ IT REUSES `kMsgLoopLeakDephases`, THE EXISTING bd `s82e` STRING, DELIBERATELY.
// A new string would take the verdict away from a fence that six shipped fixtures
// still pin, and `CQLoweringPass.cpp` records in those words what that costs
// ("…takes the message away from 68 shipped negative fixtures"). The module is
// refused for the reason that fence has always refused this class; only the POINT
// at which the question is asked has moved, from a forecast to a fact.
//
// ⚠ "DISCHARGED" MEANS *PER TRIP*, NOT MERELY *SOMEWHERE*. A body-minted rail
// adjointed once at the loop EXIT would be ONE adjoint against K forward gates —
// a wrong unitary, not a fix — so the discharge must sit INSIDE the loop that
// contains the mint. `Loop::contains` (subloops included) is the right quantifier:
// the question is "does the discharge run inside the cycle the mint runs in".
// ⚠ It is asked on a FRESHLY BUILT `LoopInfo` rather than on
// `taint.IterationLocalBlocks`, on purpose: a stale-TRUE there would be the
// GRANTING direction here. (The set is no longer raw — bd 8e5r made it
// self-cleaning, `ScrubOnDelete.h` — so the stale-TRUE this comment feared cannot
// arise from an erased block any more; the fresh `LoopInfo` stays, as the
// independent answer. Corrected, r1A F-EA-3.)
//
// ⚠ A NULLED handle is a rail that no longer exists and counts as discharged —
// see the ledger's header.
bool declineUndischargedMarkedBodyRails(Module &M) {
  std::vector<WeakTrackingVH> &Ledger = markedBodyRailObligations();
  if (Ledger.empty())
    return false;
  Instruction *Offender = nullptr;
  for (const WeakTrackingVH &H : Ledger) {
    Value *R = H;
    if (!R)
      continue;
    auto *RI = dyn_cast<Instruction>(R);
    if (!RI)
      continue;
    // bd 01po.19.17: the op was lowered IN PLACE onto a quantum-array cell
    // (InPlaceQQ RAUWs it to the cell read): it minted no rail; the cell's own
    // rail is a borrowed root the array keeps (S4), nothing to discharge.
    if (isRailWindowCellRead(RI))
      continue;
    Function *F = RI->getFunction();
    if (!F || F->isDeclaration())
      continue;
    DominatorTree DT(*F);
    LoopInfo LI(DT);
    const Loop *L = LI.getLoopFor(RI->getParent());
    if (!L)
      continue;  // the mint is no longer in a loop — nothing repeats, nothing to
                 // promise. (`-O1` had one here; a later stage removed it.)
    // ⚠ THE QUESTION IS "IS THIS RAIL STILL A **COHERENT** WHICH-PATH RECORD AT
    // THE END OF THE TRIP?", NOT "DOES IT HAVE AN `_unc`". There are TWO
    // dispositions that answer it, and reading only the first is an over-decline
    // measured on a shipped fixture:
    //   (a) it is ADJOINTED and FREED in-body — returned to |0⟩ per trip;
    //   (b) it is **MEASURED** in-body — the measurement projects it in the
    //       computational basis, so the joint state is a product and the record
    //       is not coherent. Rule 6 says the measurement OWNS such a handle,
    //       `FreePoint` calls the kind `Measured` rather than `Leaked`, and
    //       `measureOwnedInvariantRail`'s header states the same physics from the
    //       other side: *"a MEASURED rail is not a COHERENT which-path record …
    //       the Rule-8 hazard needs the rail ENTANGLED at the interference"*.
    // ⚠ MEASURED, not assumed: without clause (b) this postcondition turned
    // `lowering_reject_live_record_post_gate_record_loop.ll` from its ruled
    // WARNING (bd `lyyf`: the dephasing-by-leftover-record class is the USER's
    // circuit, reported and LOWERED) into a DECLINE. That rail is the WIRE
    // `w = q*2` — rotated in place and then `cq_measure`d — and `railIsInterior`
    // calls it interior because it has a NON-measure user (the `cqrt_ry`), which
    // is a different question from "is it measured".
    // ⚠ IN-BODY for both, for the same reason: a disposition that runs once per
    // FUNCTION says nothing about a rail re-minted once per TRIP.
    bool Discharged = false;
    for (User *U : RI->users()) {
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI || CI->arg_size() == 0 || CI->getArgOperand(0) != RI)
        continue;  // an adjoint/sink takes its target at ARG 0; else it READS.
      if (!L->contains(CI->getParent()))
        continue;  // not per-trip — see above.
      const Function *Callee = CI->getCalledFunction();
      StringRef N = Callee ? Callee->getName() : StringRef();
      if (!N.ends_with("_unc") && N != "cqrt_free" &&
          !N.starts_with("cqrt_measure_"))
        continue;
      Discharged = true;
      break;
    }
    if (!Discharged) {
      Offender = RI;
      break;
    }
  }
  Ledger.clear();  // cleared at BOTH ends — see the ledger's header.
  if (!Offender)
    return false;
  diagnose(Offender, kMsgLoopLeakDephases);
  return true;
}

void emitDeferredDephasingDecline(Module &M) {
  DeferredDephasing &S = deferredDephasingSlot();
  if (!S.Armed)
    return;
  S.Armed = false;
  llvm::errs() << "CQ_BBU0_DEFER_DEPHASE_FENCE: cq bbu0 instrument: dephasing "
                  "decline DEFERRED past the warn stage\n";
  // Re-look-up rather than a carried pointer (see `DeferredDephasing`). The
  // fallback exists so the VERDICT CANNOT BE LOST: whatever happened to the
  // recorded function, `opt` must still exit non-zero on a module this fence
  // refused. Unreachable by construction — the fence found the offending
  // instruction inside a defined function of this same module — and loud rather
  // than silent if that ever stops being true.
  Function *F = M.getFunction(S.FName);
  if (!F || F->isDeclaration()) {
    F = nullptr;
    for (Function &G : M)
      if (!G.isDeclaration()) {
        F = &G;
        break;
      }
  }
  if (!F) {
    llvm::errs() << "CQ_BBU0_DEFER_DEPHASE_FENCE: INSTRUMENT LOST THE VERDICT "
                    "for function '"
                 << S.FName << "' — this is a BUG, not an accept\n";
    return;
  }
  F->getContext().diagnose(
      DiagnosticInfoUnsupported(*F, kMsgLoopLeakDephases, S.Loc));
}

// ── bd `test_C_libtooling-tu9q` — THE (ii-d) POSTCONDITION ───────────────────
// Contract and the reason it exists at all are at the ledger's definition above.
// Called from the TAIL of `uncompute`, which is the FIRST point at which "was
// this rail discharged?" is a FACT rather than a forecast.
//
// ⚠ IT IS A LOUD DECLINE, NOT A LEAK, AND THAT ASYMMETRY IS THE DESIGN. Every
// other unprovable step in this area leaves the rail allocated (Rule 6's
// fallback) — but here the marking has ALREADY silenced conjunct (1) of
// `declineDephasingUnmarkedLoopRails`, so a leak at this point is a leak WITH the
// fence for its own hazard class disarmed. There is nothing left to fall back on,
// and Rule 1 says the postcondition must then speak.
//
// ⚠ WHAT COUNTS AS DISCHARGED, and the definition is deliberately GENEROUS in the
// accept direction: any `..._unc` call anywhere in the module naming the rail as
// its out-operand (argument 0), or any `cqrt_free` of it. Being generous is the
// right direction here because this is a BACKSTOP behind a real placement, not
// the placement's own proof — Rule 6 and the `free_pairing_check` gate own
// "freed at |0⟩", and `multiplicityAgrees` owns "adjointed the right number of
// times". Narrowing it to a positional test would make it a SECOND SPELLING of
// `Uncomputation`'s placement (the drbq Inc-3 (b′) defect, Rule 14).
//
// ⚠ A NULLED HANDLE IS NOT A VIOLATION — see the ledger's header: the root was
// deleted rather than lowered, so there is no rail to leak.
bool declineUndischargedExitObligations(Module &M) {
  std::vector<WeakTrackingVH> &Ledger = exitDischargeObligations();
  if (Ledger.empty())
    return false;
  // Collect every discharged rail in ONE walk, rather than re-scanning the module
  // per obligation: the ledger is small but the module need not be.
  SmallPtrSet<const Value *, 16> Discharged;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->arg_size() == 0)
          continue;
        const Function *Callee = CI->getCalledFunction();
        StringRef N = Callee ? Callee->getName() : StringRef();
        if (N.ends_with("_unc") || N == "cqrt_free")
          Discharged.insert(CI->getArgOperand(0));
      }
  }
  Instruction *Offender = nullptr;
  for (const WeakTrackingVH &H : Ledger) {
    Value *R = H;
    if (!R)
      continue;  // the root no longer exists — nothing to discharge.
    // ⚠ **THE OBLIGATION IS VACUOUS IF `lowerOps` LOWERED THE OP IN PLACE, AND
    // THIS IS NOT A LOOPHOLE — IT IS THE CLAUSE'S OWN QUESTION, RE-ASKED IN THE
    // POST-LOWERING VOCABULARY.** Clause (ii-d) admits a root on
    // `mintsOutOfPlaceTemplateRail`, which is a FORECAST made BEFORE
    // `commitOutOfLoopInPlaceOps` and `lowerOps` have finished deciding. The
    // measured case is `q = q + off` with a VOLATILE-LOAD immediate: the (1a)
    // fence (`isa<Constant>(Imm)`) refuses to COMMIT it at `lowerLoops`, so the
    // forecast says "out of place" — and then M-C lowers it IN PLACE anyway, as
    // `cqrt_addc_i32(%h, %off)`. There is no separate rail in the emitted module,
    // so there is nothing to discharge and nothing to leak: the REGISTER is the
    // rail, and the register is the user's to keep.
    //
    // A `WeakTrackingVH` follows RAUW, so the handle now names whatever `lowerOps`
    // put in the op's place: a `cq_template_*` CALL for an out-of-place lowering,
    // and the pre-existing register handle for an in-place one. Asking WHICH is
    // therefore asking the forecast's own question against the fact.
    //
    // ⚠ DIRECTION, because this is the conjunct most likely to be read as a
    // weakening: it narrows the postcondition to the population the clause was
    // ABOUT, and it cannot hide a leaked template rail — a template rail names a
    // `cq_template_*` call by construction, so every module this skips has no such
    // rail at all. ⚠ RETIREMENT TRIGGER: if `lowerOps` ever lowers an op in place
    // while STILL minting a separate rail, this conjunct becomes an over-accept —
    // re-derive it against that emitter rather than narrowing it further.
    auto *RC = dyn_cast<CallInst>(R);
    const Function *RF = RC ? RC->getCalledFunction() : nullptr;
    if (!RF || !RF->getName().starts_with("cq_template_"))
      continue;
    if (Discharged.count(R))
      continue;
    Offender = RC;
    break;
  }
  Ledger.clear();  // see the ledger's header: cleared at BOTH ends.
  if (!Offender)
    return false;
  diagnose(Offender, kMsgExitObligation);
  return true;
}

// bd `test_C_libtooling-tu9q` — THE ONE SPELLING of the loop-exit discharge
// point. Contract, both customers and the GRANTING-direction note in LoopPlan.h.
// Pure analysis; mutates nothing.
BasicBlock *loopExitDischargePoint(const Loop *L) {
  if (!L)
    return nullptr;
  // ⚠ `getUniqueExitBlock`, NOT `getExitBlock`/`getExitingBlock`, and the
  // difference decides a unitary. The question is *"is there ONE place the loop
  // is finished at"*, which is about EXIT blocks (the destinations); an
  // EXITING-block query would answer about the sources and would happily return
  // a single block for a loop that lands in two different places.
  BasicBlock *Exit = const_cast<Loop *>(L)->getUniqueExitBlock();
  if (!Exit)
    return nullptr;  // multi-exit — today's behaviour: the rail LEAKS (Rule 6).
  // A landing pad or a block that is all-φ has no insertion point; the caller is
  // promised it never has to re-check, so the check lives here.
  return Exit->getFirstInsertionPt() == Exit->end() ? nullptr : Exit;
}

// bd `test_C_libtooling-wx8g` — R7-loop CLAUSE (c3). Contract in LoopPlan.h.
// Pure analysis; mutates nothing (Rule 9). `L->blocks()` deliberately INCLUDES
// strictly-deeper subloop blocks — a subloop's temp escaping `L` is the same
// hazard and refusing it is the safe direction.
Instruction *iterationLocalTaintEscape(const Loop *L, const TaintSet &taint) {
  if (!L)
    return nullptr;
  // ── bd `test_C_libtooling-zujr` / bd `8h7d.11` — THE LOOP-CARRIED HANDLE
  //    VARIABLE IS NOT AN ITERATION-LOCAL TEMP.
  //
  // This walk answers *"does an ITERATION-LOCAL TEMP escape `L`?"* — it is
  // `markIfRailLocal`'s own escape clause asked with the EMPTY exemption set, and
  // the monotonicity argument above ("a larger `Roots` exempts strictly MORE
  // values") is exactly why the empty set can only OVER-decline. THIS IS THAT
  // OVER-DECLINE, MEASURED: the owner's rolled cascade was refused because `a` —
  // a register the region does not even rotate — is `cq_measure`d after the loop.
  // Per the owner's 2026-09-11 ruling an over-decline is a defect to remove, not a
  // free safety margin.
  //
  // The exemption is the loop-carried HANDLE CHAIN and nothing else: the φ and the
  // SSA names it wears inside one activation. A temp that merely READS the
  // variable (`h_op = a − 3`) is still a temp and is still counted — exempting the
  // operand cone would be precisely the over-accept this clause exists to stop.
  //
  // ⚠ IT IS DONE HERE, IN THE ONE BODY, AND NOT AT EITHER CALL SITE (CLAUDE.md
  // L2): the SAME question is asked at DETECTION with round-1 taint (R7-loop
  // clause (c3)) and again after the round-2 fixpoint (`declineUnmarkedRolledIterLocal`
  // conjunct 1). A widening applied to one caller and not the other is a round-2
  // decline of what round 1 accepted.
  SmallPtrSet<const Value *, 8> Carried;
  collectCarriedHandleChains(L, taint, Carried);
  for (BasicBlock *BB : L->blocks())
    for (Instruction &I : *BB) {
      if (!taint.Tainted.count(&I))
        continue;
      if (Carried.count(&I))
        continue;
      for (User *U : I.users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI)
          return &I;  // a constant expression has no block — no proof.
        if (!L->contains(UI->getParent()))
          return &I;
      }
    }
  return nullptr;
}

// bd `test_C_libtooling-wx8g` — DOES `L`'s BODY CONTAIN ANYTHING THE WHOLE-DAG
// SPINE WOULD HAVE TO DISCHARGE IN-BODY?
//
// This is conjunct 2's PRECONDITION, and it exists because the marking
// postcondition is only meaningful when there is something to mark FOR.
// `taint.IterationLocalBlocks` is consumed by `FreePoint` + `Uncomputation` to
// place a per-iteration recovery + `cqrt_free` inside the body; with no
// candidate, an unmarked loop and a marked one emit the SAME stream, and
// `markIfRailLocal` says so itself by bailing `!AnyLocal` ("a pure-rail loop (no
// temps) — nothing for the spine to place").
//
// MEASURED, and it is why this predicate exists rather than the blunt form: the
// four `_Bool` customers of clause (c) have NO candidate at all (their bodies
// hold only rotations, a measurement and the merge phi the emitter dissolves),
// and `invariantRegisterRoots` returns false for them for a reason that is
// invisible unless you look at the SLOT — at `collapseFlattenedLoopRails`' call
// site, which runs BEFORE `lowerRotations`, a RAIL condition is not yet an
// OPERAND of anything in the body. `emitInPlaceRotationRegion` records the
// control in `taint.ControlledRotations` (a MAP) and the flatten erased the
// `br`, so the `_Bool`'s only in-loop use has gone and its only remaining users
// are outside. `Cands` is therefore EMPTY, `invariantRegisterRoots` returns
// false at its "no invariant register read" early-out, `markIfRailLocal` is
// never called — and the blunt postcondition declined four programs that are
// byte-identical to their hand-unrolled twins.
//
// THE EXCLUSION LIST IS EXACT AND ITS DIRECTION IS THE SAFETY ARGUMENT. A
// candidate is any tainted instruction in `L`'s blocks EXCEPT the five kinds
// that mint no `cq_template_*` rail for the spine to reverse:
//   * a `@cq_theta_*` call — `lowerRotations` emits `cqrt_alloc_<W>`+`cqrt_ry_<W>`
//     or an in-place `cqrt_ry_<W>`; an alloc-minted rail is excluded from the M-B
//     interior partition OUTRIGHT by `ChainWalk::isInteriorTerminalHandle` clause
//     (I1), and a rail carrying a controlled rotation is FROZEN;
//   * a `@cq_phi_*` call — the retired register form (vacuous since 3qlq; the
//     register-free `@cq_phi` is void and allocates nothing either);
//   * a `@cq_measure_*` call — the sole sink; its result is not tainted;
//   * a `PHINode` — no gate, no rail;
//   * a member of `taint.InPlaceRailOps` — the M-C / dtzb IN-PLACE value rail
//     self-update, added by review round 1 (finding F-W1-3, 2026-09-14) and
//     RE-DERIVED AGAINST `lowerOps` AS THE TRIGGER BELOW DEMANDS, not against
//     this comment. `lowerOps`' Phase-2 dispatch
//     (`OpcodeLowering.cpp`: `taint.InPlaceRailOps.count(BO) ||
//     InPlaceReassign.count(BO)`) routes a member to `rewriteInPlaceValueRail`,
//     which emits `cqrt_{addc,xorc}_<W>(handle, imm)` — a MUTATION OF THE
//     EXISTING HANDLE. No `cqrt_alloc`, no `cq_template_*` rail, nothing for the
//     spine to reverse or free. ⚠ AND THE OTHER LIMB OF THE DISJUNCTION IS WHY
//     THIS IS THE COMMITTED RECORD AND NOT A SECOND SPELLING (Rule 14): the
//     record carries the PROVEN OPERAND INDEX (`taint.InPlaceRailIdx`) precisely
//     so no consumer re-derives the predicate, and the drbq Inc-3 (b′) defect is
//     the counter-example of what re-deriving costs.
//     THE DISPOSITION IS TOTAL — that is what makes the exclusion sound rather
//     than optimistic. A member whose marking went stale is NOT silently lowered
//     out of place: `lowerOps`' two tripwires re-ask it under FINAL taint
//     (`diagnosePreLoopCommitStale` for W4's `PreLoopCommittedInPlaceOps`,
//     `diagnoseRailOpStale` + G2 for W1-W3) and DECLINE LOUDLY — *"NEVER A
//     SILENT FALLBACK TO OUT-OF-PLACE … Rule 1 — no third path"*, in that site's
//     own words. So a member either mints nothing or the module never lowers.
//     ⚠ THE SET IS FINAL HERE, BUT NOT FOR THE REASON THIS COMMENT GAVE FOR
//     ONE REVIEW ROUND — the old wording ("its only `erase` is
//     `invariantRegisterRoots`' rollback, INSIDE `lowerLoops`, which runs
//     before this stage") is MEASURABLY FALSE ON BOTH HALVES (review round 2,
//     finding F-W2-1, 2026-09-14). TWO of `markInPlaceRailOp`'s four call sites
//     and the one `erase` are reached from `collapseFlattenedLoopRails`, NOT
//     from `lowerLoops`:
//         `collapseRailPhisIn`                       (:2747)
//         `commitOutOfLoopInPlaceOps`                (:3152, via
//                                                     `invariantRegisterRootsImpl`)
//         `invariantRegisterRoots`' rollback `erase` (:3479)
//     and `collapseFlattenedLoopRails` runs at ROUND 1 (`CQLoweringPass.cpp:473`)
//     AND AGAIN AS THE LAST STATEMENT of `repropagateControlMerges`
//     (`TaintPropagation.cpp:1816`) — which is its ONLY call in the second entry
//     point. So a writer "after `lowerLoops`" ALREADY EXISTS at HEAD, twice, one
//     of them at ROUND 2; a trigger phrased against `lowerLoops` reads as
//     UNARMED when it is already armed, which is CLAUDE.md L8 inverted.
//     WHAT IS TRUE, and it is all the exclusion needs: the LAST writer is that
//     round-2 `collapseFlattenedLoopRails`, and `declineUnmarkedRolledIterLocal`
//     — this predicate's ONLY caller — runs THREE STATEMENTS later in BOTH entry
//     points (`repropagateControlMerges` → `reverifyRailCondReads` →
//     `reverifyCmpCondReads` → here: `CQLoweringPass.cpp:489/510/519/532` and
//     `:961/967/970/983`). THE MARGIN IS THREE STATEMENTS, NOT A STAGE.
//     ⚠ RETIREMENT TRIGGER, RE-AIMED AT THAT MARGIN: a `markInPlaceRailOp` or
//     `InPlaceRailOps.erase` site added ANYWHERE BETWEEN the round-2
//     `collapseFlattenedLoopRails` and `declineUnmarkedRolledIterLocal`, or
//     either of those two reordered past the other, makes this read a set that
//     is still moving.
//     MEASURED, and it is load-bearing rather than a nicety: with conjunct 2
//     extended to (b′) grants by F-W1-2, `control_inplace_ry_inloop_offset.ll` —
//     a SHIPPED drbq Inc-3 accept — went red, and the debug dump showed its loop
//     holds exactly ONE candidate, `%qn = add i32 %q, 3`, `InPlaceRailOps` = 1.
//     This exclusion is what keeps that accept, and it is the same fact the
//     fixture's own `CHECK: call void @cqrt_addc_i32` has always pinned.
// EVERYTHING else tainted (arithmetic, casts, compares, selects) is lowered by
// `lowerOps` to a `cq_template_*` rail whose `_unc` + free the spine must place,
// so it COUNTS. Emitted `cqrt_*` / `cq_template_*` calls are never in
// `taint.Tainted` (they are minted after propagation) and so cannot mask a real
// candidate. The region's OWN condition compare is not on the list and does not
// need to be: `emitInPlaceRotationRegion` mints the flag from it and ERASES it,
// so by this stage it is not in `L`'s blocks at all (measured on the same dump —
// `offset.ll`'s `%c = icmp eq i32 %q, 5` is simply gone).
// bd 01po.19 S6 added the SIXTH and SEVENTH kinds: a quantum-array CELL READ
// (a borrowed root, never discharged) and a STORE into a cell (a kept-carrier
// sink); neither mints a rail (S4's `isTerminalHandle` / `railStoredToRailWindow`).
// ⚠ RETIREMENT TRIGGER: adding an EIGHTH kind to this list is adding a claim that
// it mints nothing — re-derive it against `lowerOps`, not against this comment.
//
// ⚠ WHAT THIS PREDICATE STILL OVER-COUNTS, MEASURED RATHER THAN GUESSED, so the
// next reader does not re-chase it (review round 1 proposed three shapes; two of
// them are NOT over-declines and the measurement is the reason):
//   * `od4` — a template rail whose ONLY consumer is a `cq_measure` (`cq_measure(r & 3)`).
//     A measured rail is never uncomputed and never freed, so the marking is
//     irrelevant. With conjunct 2 forced off, the rolled stream is BYTE-IDENTICAL
//     to the hand-unrolled twin at 16 = 16 lines. A GENUINE over-decline; it needs
//     its own predicate ("is every consumer of this rail a measurement?") and is
//     FILED, not guessed at here.
//   * `od2`/`od3` — `cq_measure(r + 1)` and `r ^= 3` on an ITERATION-LOCAL rail.
//     The review read these as over-declines from their TWINS' streams. They are
//     NOT: the twin is straight-line, so M-C fires and emits `cqrt_addc_i32` /
//     `cqrt_xorc_i32` in place; the ROLLED site is inside a natural loop, where
//     M-C's G5 refuses OUTRIGHT and no `lowerLoops` writer claims a rail with no
//     header phi — so `InPlaceRailOps` = 0 (measured) and `lowerOps` mints a
//     FRESH `cq_template_{add,xor}_i32_hl` rail per trip that nothing discharges.
//     With conjunct 2 forced off, rolled and twin DIVERGE (`cq_template_add_i32_hl(h1,1)
//     -> h2` vs `cqrt_addc_i32(h1,1)`, twice). The decline is CORRECT and this
//     exclusion deliberately does not reach them: a value not in the record is a
//     value the record does not vouch for.
static bool bodyHasSpineDischargeCandidate(const Loop *L,
                                          const TaintSet &taint) {
  for (BasicBlock *BB : L->blocks())
    for (Instruction &I : *BB) {
      if (!taint.Tainted.count(&I))
        continue;
      if (isa<PHINode>(I))
        continue;
      // bd 01po.19 S6: a quantum-array cell read is a BORROWED ROOT and a
      // store into a cell a KEPT-CARRIER sink (S4): the spine discharges
      // neither, so they owe the marking nothing.
      if (isRailWindowCellRead(&I))
        continue;
      if (const auto *St = dyn_cast<StoreInst>(&I);
          St && railWindowOfPointer(St->getPointerOperand()))
        continue;
      if (const auto *CI = dyn_cast<CallInst>(&I)) {
        const Function *F = CI->getCalledFunction();
        if (F && (F->getName().starts_with("cq_theta_") ||
                  F->getName().starts_with("cq_phi_") ||
                  F->getName().starts_with("cq_measure_")))
          continue;
      }
      // The M-C / dtzb IN-PLACE value rail self-update, asked by CALLING the
      // committed record rather than by re-deriving the shape (Rule 14). See the
      // header for the `lowerOps` re-derivation and for why the disposition is
      // total.
      //
      // ⚠ THE `isa<BinaryOperator>` CONJUNCT IS A LIFETIME FENCE, NOT A TYPE
      // TIDY-UP, and it is BYTE-NEUTRAL for every genuine member (review round
      // 2, finding F-W2-4, 2026-09-14). `taint.InPlaceRailOps` WAS a raw
      // `SmallPtrSet<Instruction *>` whose only removal was
      // `invariantRegisterRoots`' rollback — NEVER scrubbed when an instruction
      // was erased — and this consumer uses MEMBERSHIP TO SUPPRESS A SAFETY
      // CHECK, the ACCEPT direction (F-W1-1's shape one container over, where the
      // dangling key was a `Loop *`): a recycled `Instruction *` would silently
      // have excluded a REAL discharge candidate. ⚠ Since bd 8e5r the set is
      // self-cleaning (`ScrubOnDelete.h`), so a recycled address is no longer a
      // member at all; this conjunct is now defence in depth (r1A F-EA-3).
      // `markInPlaceRailOp` takes a `BinaryOperator *` (LoopLowering.cpp:192) at
      // all four of its call sites, so EVERY genuine member is a
      // `BinaryOperator`: a membership hit on anything else can ONLY be a
      // recycled address, and refusing it costs nothing and closes the half of
      // the hazard `lowerOps` does not cover.
      // THE OTHER HALF — a recycled address landing on a live tainted
      // `BinaryOperator` — is covered by the disposition the exclusion already
      // rests on, and it is TOTAL exactly as the header says: `lowerOps` re-asks
      // EVERY `BinaryOperator` member under FINAL taint — (1b)
      // `classifyInPlaceReassignment` for a `PreLoopCommittedInPlaceOps` member,
      // the eqpx tripwire (`inPlaceValueRailOperand` + the `InPlaceRailIdx`
      // agreement) for every other — and either DECLINES LOUDLY or lowers the op
      // in place, which mints no rail for the spine to discharge. So the
      // exclusion is right whichever way that re-ask goes.
      // ⚠ RETIREMENT TRIGGER: if `markInPlaceRailOp` ever takes a wider type
      // than `BinaryOperator *`, this conjunct silently starts excluding
      // genuine members' siblings — re-derive it against the marker's signature,
      // not against this comment. And if `lowerOps`' two tripwires ever stop
      // covering every `BinaryOperator` member, the second half of the argument
      // goes with them. (The "real scrub" this trigger used to ask for has
      // landed — bd 8e5r's self-cleaning containers — so the recycled-address
      // half is closed by construction; the tripwire half still stands.)
      if (isa<BinaryOperator>(&I) &&
          taint.InPlaceRailOps.count(const_cast<Instruction *>(&I)))
        continue;
      return true;
    }
  return false;
}

// bd `test_C_libtooling-wx8g` — THE RE-ASK HALF of the R7-LOOP CLAUSES, ALL OF
// THEM. Contract in LoopPlan.h; the full L1 argument and the per-entry clause
// bit on `TaintSet::RolledLoopRegionGates`.
//
// PURE CHECK. It rebuilds DT/LI on the POST-FLATTEN CFG (Rule 11/9 — the
// detection trees are long invalid), looks up the loop each recorded HOISTED
// GATE now sits in, and requires every one of that loop's OWN blocks to be in
// `taint.IterationLocalBlocks`. Anything else is a LOUD decline with the string
// the shape has always had; there is no silent fallback and nothing is marked,
// erased or rewritten here (Rule 1).
//
// THE FOUR WAYS IT FIRES, all measured or enumerated at LoopPlan.h:
//   * `markIfRailLocal` was never CALLED — the loop has no root mint to hand it
//     (`collapseRailPhisIn` NotClaimed and `invariantRegisterRoots` false), which
//     is exactly a loop whose CONDITION is iteration-local too;
//   * it was called and returned early (a second still-standing tainted branch,
//     a tainted-index memop, a quantum subloop, an accumulating loop-invariant
//     tainted input, an unclaimed tainted header phi);
//   * its ESCAPE clause refused at FINAL taint where clause (c3) passed at
//     round-1 taint (the L1 PREDICATE species);
//   * the gate no longer sits in any loop at all — no loop, no proof.
// ⚠ `!AnyLocal` IS A FIFTH WAY, and pretending otherwise cost four correct
// programs (measured — see `bodyHasSpineDischargeCandidate`). `markIfRailLocal`
// bails without marking on a loop with no iteration-local TEMP, and so does the
// dispatch that never calls it; in both cases an unmarked loop and a marked one
// emit the SAME stream. Conjunct 2 is therefore asked ONLY when the body has a
// spine-discharge candidate, which is the precondition that separates "unmarked
// and it does not matter" from "unmarked and the per-trip rails will leak".
//
// A NULLED handle is SKIPPED (an erased hoisted gate is no emitted gate — the
// `RailCondReads` direction), and each conjunct is asked of one loop ONCE
// however many regions recorded it — in TWO separate sets, because the
// conjuncts cover different entries and one shared set lets the cheaper entry
// suppress the stricter one's check.
// bd `test_C_libtooling-zujr` — THE PROMOTION. Contract + slot in LoopPlan.h.
//
// THE ONLY MUTATION this increment makes, and it is the owner's ruling (1):
// materialise `cqrt_alloc_<W>(seed)` in the PREHEADER of every proven
// loop-carried handle φ and rewrite the φ's entry incoming to that handle. Trip 1
// then names a REGISTER where the un-promoted module would pass the classical
// literal into a gate slot that wants a handle.
//
// THE THREE THINGS IT ASKS THAT THE STRUCTURAL PREDICATE CANNOT, because they are
// only true (or only knowable) at FINAL taint, after the merge emitters have run:
//
//   (P1) THE LATCH INCOMING IS A CONTROL-MERGE `%out` RAIL, asked by reading
//        `taint.ControlOwnedRails` — the record every Phase-4 merge emitter writes
//        at its own `Tainted.insert(rail)` site. This is the SCOPE bd `zujr`
//        names: *"a latch incoming that is a controlled-copy merge `%out` (fresh
//        rail per activation)"*. It is what makes the per-trip unitary argument
//        at `loopCarriedHandlePhi` true — a merge `%out` is a FRESH `|0⟩` rail
//        written once per basis branch by two X-bracketed controlled copies, with
//        the previous register left untouched. A latch incoming that is some OTHER
//        fresh tainted rail (a `cq_template_add_i32_qq` accumulator, say) is a
//        different circuit with a different argument and is NOT promoted here; it
//        keeps the X1 decline it has always had.
//        ⚠ AND THE RAIL MUST BE MINTED INSIDE `L`. `ControlOwnedRails` is
//        module-scoped; a merge out-rail minted OUTSIDE the loop and merely read
//        inside it is loop-INVARIANT, not re-minted per trip, and the "fresh
//        register every activation" half of the argument would be false for it.
//
//   (P2) `cqrt_alloc_<W>` RESOLVES for the rail's ABI width. Resolved BEFORE any
//        mutation so a resolution failure leaves the module untouched and the
//        unpromoted φ declines at `declineClassicalMuxes` (detect-before-mutate).
//
//   (P3) THE SEED DOMINATES THE PREHEADER TERMINATOR. A `Constant`/`Argument`
//        trivially does; an `Instruction` outside `L` needs the real question
//        asked, and asking it needs a `DominatorTree` this stage builds itself
//        (Rule 11 — the round-1 trees are long invalid; the control flatten
//        spliced and erased blocks).
//
// IT NEVER DECLINES. Every refusal here is a SKIP that leaves the φ unpromoted,
// and an unpromoted tainted φ is precisely what `declineClassicalMuxes` — the very
// next stage — refuses loudly. Adding a second loud owner for that shape would
// give one module two diagnostics for one defect (`LLVMContext::diagnose` EXITS on
// the first `DS_Error` anyway, bd `br4a`, so the second would be dead text).
//
// ⚠ THE PROMOTED HANDLE IS NOT ADDED TO `taint.Tainted`, DELIBERATELY. It is a
// materialised CLASSICAL copy source, exactly what `materializeCopySource` mints
// for a constant select arm (`%selop = cqrt_alloc_i32(2)` in the flat twin), and
// that function is what mints it here too (Rule 14 — one spelling of "make this
// classical value a register"). Tainting it would offer the whole-DAG spine a
// terminal it must not select, and the φ stays tainted regardless because its
// latch incoming is.
//
// ⚠ AND IT IS LEFT ALLOCATED, never freed. On a zero-trip loop the φ's exit value
// IS this register, holding |seed⟩, and the program measures it; on a ≥1-trip loop
// it is the trip-1 which-path record the merge copies out of — the same accepted
// Rule-6 leak the flat twin takes on its own `cqrt_alloc_i32(5)` copy source.
void promoteLoopCarriedHandleSeeds(Module &M, WidthDispatch &wd,
                                   TaintSet &taint) {
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // ⚠ THE CHEAP SKIP WALKS THE FUNCTION, NOT `taint.Tainted`, AND THE
    // DIFFERENCE IS THE ONE `declineDephasingUnmarkedLoopRails` SPELLS OUT
    // (Rule-13 round 1, F-3). Same answer, no dereference of a set member.
    // ⚠ CORRECTED 2026-09-25 (bd test_C_libtooling-um24, L7): this note used to
    // call `lowerLoops`' own set-dereferencing prescan "sound THERE because it
    // runs before any region flatten" — FALSE, it SIGSEGVed on four shipped
    // fixtures (see the neighbour), and it now walks the function as well.
    bool AnyTainted = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB)
        if (taint.Tainted.count(&I)) {
          AnyTainted = true;
          break;
        }
      if (AnyTainted)
        break;
    }
    if (!AnyTainted)
      continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    for (Loop *L : LI.getLoopsInPreorder()) {
      BasicBlock *Hdr = L->getHeader();
      if (!Hdr)
        continue;
      for (PHINode &P : Hdr->phis()) {
        std::optional<CarriedHandleProof> Pf =
            loopCarriedHandlePhi(P, L, taint, GateCalls);
        if (!Pf)
          continue;
        // (P1) — a control-merge `%out` rail, minted INSIDE `L`.
        auto *LatI = dyn_cast<Instruction>(Pf->LatchVal);
        if (!LatI || !taint.ControlOwnedRails.count(Pf->LatchVal) ||
            !L->contains(LatI->getParent()))
          continue;
        // (P2) — resolve the allocator before touching anything.
        FunctionCallee Alloc = wd.allocFn(Pf->Abi);
        if (!Alloc)
          continue;
        // (P3) — the seed is available at the promotion point.
        // ⚠ bd `test_C_libtooling-h1ip`: FOR A GUARDED LOOP THE MINT POINT IS
        // THE GUARD'S OWN TERMINATOR, NOT THE PREHEADER'S — the preheader is
        // BYPASSED on the zero-trip edge, so a register minted there does not
        // exist for the exit φ to name. The dominance question below is
        // therefore asked about THAT point, whichever it is.
        Instruction *PreTerm = Pf->BypassIncomings.empty()
                                   ? Pf->Preheader->getTerminator()
                                   : Pf->GuardBB->getTerminator();
        if (auto *SI = dyn_cast<Instruction>(Pf->Seed))
          if (!DT.dominates(SI, PreTerm))
            continue;
        // (P0) bd `test_C_libtooling-h7ee` Rule-13 ROUND 2, finding R2-1 — A DEAD
        //      φ IS NOT PROMOTED. `declineClassicalMuxes` opens with its own
        //      `if (Phi->use_empty()) continue;`, so a header φ nothing reads is
        //      never refused there — which means the promotion is the LAST owner
        //      for it, and until this clause it MUTATED: it minted a
        //      `cqrt_alloc_<W>(seed)` qubit, and a trace line, for a value the
        //      program does not read, and renumbered every downstream handle.
        //      No unitary was wrong (an `alloc` is neither a measurement nor a
        //      non-diagonal gate, and Rule 6 already accepts a left-allocated
        //      rail), which is why the round filed it P3 — but a qubit minted
        //      for a dead value is a mutation with no customer.
        //      ⚠ IT IS A MUTATION-AVOIDANCE CLAUSE, NOT A FENCE. Nothing is
        //      being made safe; a promotion that does not happen for a value
        //      with no readers changes no verdict. Measured by the round: the
        //      same module with the dead φ deleted (`e1c`) already ACCEPTS.
        //      ⚠ AND IT IS AN IR-LEVEL SHAPE ONLY — `clang -O1` deletes a dead
        //      φ, so no C spelling reaches it. Stated rather than implied, per
        //      the bd `hrts` caveat (CLAUDE.md §5): an IR-level result is not a
        //      C-level one.
        if (P.use_empty())
          continue;
        // (P4) bd `test_C_libtooling-11qv` — EVERY USER OF A φ WE ARE ABOUT TO
        //      RETYPE IS ONE THE LOWERING REWRITES. Asked ONLY when the retype
        //      is owed; an `i32` φ is unaffected and this gate is vacuous for it.
        //
        //      WHY IT EXISTS. `mutateType(i32)` changes the φ UNDER ITS USERS.
        //      Every later stage that consumes a tainted narrow value REPLACES
        //      the consuming instruction — `lowerOps` rewrites a tainted
        //      `add nsw i16 %φ, -3` into `cq_template_add_i16_hl(i32 %φ, i16 -3)`,
        //      `lowerMeasures` rewrites `@cq_measure_si16(i16 %φ)` into
        //      `cqrt_measure_16(i32 %φ)` — so the transient mismatch this retype
        //      opens is closed by the SAME laundering-by-erasure `RotationLowering`
        //      relies on. A user that is NOT rewritten keeps reading a value whose
        //      type moved under it, and the module ends the pass VERIFIER-INVALID:
        //      `opt` ABORTS (exit 134), which is a crash, not a decline — and
        //      Rule 1 says the answer to "unsure" is a LOUD DECLINE, never an abort.
        //
        //      ⚠ A φ USER IS REFUSED EVEN THOUGH IT IS TAINTED, and that is the
        //      one deliberate narrowing here. A second φ carrying this one (an
        //      LCSSA exit φ is the shape that occurs) keeps its NARROW type and
        //      nothing retypes it, so admitting it would just move the invalid
        //      edge one φ outward. Widening to a transitive φ closure is an
        //      ACCEPT-direction change of its own and is FILED, not smuggled in.
        //
        //      IT IS A SKIP, NOT A DECLINE (D2): the un-retyped φ reaches
        //      `declineClassicalMuxes` and is refused there, loudly, one stage
        //      later.
        if (Pf->NeedsHandleRetype) {
          bool AllRewritten = true;
          // ⚠ THE LATCH VALUE IS ASKED THE SAME TYPE QUESTION AS THE φ, AND FOR
          // A DIFFERENT DEFECT — Rule-13 round 4, F-1's surviving half. The
          // merge emitter mints `%out = cqrt_alloc_<W>(…)`, which is `i32` at
          // EVERY width (Rule 15); a NARROW-typed external user of that rail
          // (`extern void sink(short); sink(a);`) is therefore already
          // ill-typed the moment the region lowers. **That defect is
          // PRE-EXISTING and it is not this increment's** — its loop-free twin
          // aborts identically on the ORACLE, measured. But the promotion is
          // what lets this module's loop lower AT ALL, so without this check a
          // program the oracle refused with a clean loud diagnostic would
          // instead ABORT `opt` at exit 134. *"Pre-existing" is true of the
          // defect and FALSE of its population*, and Rule 1 does not care
          // whose defect it is: the answer must be a decline, not a crash.
          // A SKIP here restores exactly the oracle's refusal.
          SmallVector<Value *, 2> RetypeSubjects{&P, Pf->LatchVal};
          for (Value *RS : RetypeSubjects)
          for (User *U : RS->users()) {
            auto *UI = dyn_cast<Instruction>(U);
            if (!UI) {
              AllRewritten = false;
              break;
            }
            // The carried φ ITSELF is a user of the latch value; it is the
            // subject of the retype, not a hazard to it.
            if (UI == &P)
              continue;
            if (isa<PHINode>(UI)) {
              AllRewritten = false;
              break;
            }
            // ⚠ THE QUESTION IS "WILL A LATER STAGE REPLACE THIS USER?", AND IT
            // IS ASKED BY **MEMBERSHIP OF THE INSTRUCTION**, NEVER BY NAME —
            // which is the discipline `ChainWalk`'s `!cq.branchphase` record
            // already states in writing for the same reason.
            //
            // ⚠ AN EARLIER SPELLING OF THIS CLAUSE ASKED BY NAME PREFIX
            // (`cq_`/`cqrt_`) AND IT WAS A **P1** — Rule-13 round 4,
            // 2026-09-20, finding F-1, reproduced from plain C. Those are
            // EXACTLY the prefixes `declineTaintEscapes` EXEMPTS
            // (`cqrt_`, `cq_template_`, `cq_invert_`), so every call that
            // survived the escape guard through that exemption also passed
            // here — **the second list trusted what the first one merely
            // tolerated**. And none of the three is ever rewritten: `cqrt_*`
            // IS the lowered ABI, a hand-written `cq_template_*` is a
            // recognised input class, and `cq_invert_*` is an unbuilt Phase-8
            // handoff. `P.mutateType(i32)` then ran under such a user and the
            // module ended VERIFIER-INVALID: `opt` ABORTED at exit 134
            // (`Call parameter type does not match function signature!`) where
            // the ORACLE emitted a clean loud decline. That is the precise
            // Rule-1 violation this clause exists to prevent, committed by the
            // clause itself.
            //
            // The safe set is therefore the set of users a later stage
            // PROVABLY replaces, and each is asked of a RECORD this pass owns:
            //   * a tainted NON-CALL instruction — `lowerOps` / `CastLowering`
            //     / `CompareLowering` rewrite tainted arithmetic, casts and
            //     compares into `cq_template_*` calls taking `i32` handles;
            //   * a `@cq_theta_*` call, by membership of `taint.ThetaCalls`,
            //     which `lowerRotations` erases;
            //   * a `@cq_measure_*` call, by membership of `taint.MeasureCalls`,
            //     which `lowerMeasures` rewrites to `cqrt_measure_<W>(i32)`.
            // Anything else — including every runtime and template call, and
            // every φ — is a SKIP, so the module declines at
            // `declineClassicalMuxes` one stage later instead of aborting.
            if (taint.Tainted.count(UI) && !isa<CallInst>(UI))
              continue;
            auto *CI = dyn_cast<CallInst>(UI);
            if (!CI) {
              AllRewritten = false;
              break;
            }
            // A `@cq_theta_*` / `@cq_measure_*` call, BY MEMBERSHIP of the
            // records this pass owns: `lowerRotations` erases the first and
            // `lowerMeasures` rewrites the second, so neither survives to read
            // the retyped operand.
            if (llvm::is_contained(taint.ThetaCalls, CI) ||
                llvm::is_contained(taint.MeasureCalls, CI))
              continue;
            // ⚠ EVERY OTHER CALL IS ASKED THE TYPE QUESTION DIRECTLY, WHICH IS
            // THE ONLY QUESTION THAT WAS EVER BEING ASKED: *after the retype,
            // is this operand still well-typed?* A merge emitter has ALREADY
            // run by here and its `cqrt_copy_<W>_controlled(i32, i32, i32)`
            // legitimately takes the φ in an `i32` slot — so for that call the
            // retype is not a hazard, it is the REPAIR, and refusing it would
            // decline this increment's own headline. `cqrt_probe_sink(i16)`,
            // the round-4 P1 probe, is the opposite: its declared parameter is
            // narrow, so after the retype it is broken, and it must SKIP.
            // A vararg slot and an indirect callee have no declared type to
            // check, so both SKIP.
            Function *CF = CI->getCalledFunction();
            if (!CF || CF->isVarArg()) {
              AllRewritten = false;
              break;
            }
            bool EveryUseIsHandleSlot = true;
            for (unsigned ai = 0, ae = CI->arg_size(); ai != ae; ++ai) {
              if (CI->getArgOperand(ai) != RS)
                continue;
              if (ai >= CF->arg_size() ||
                  !CF->getArg(ai)->getType()->isIntegerTy(32)) {
                EveryUseIsHandleSlot = false;
                break;
              }
            }
            if (EveryUseIsHandleSlot)
              continue;
            AllRewritten = false;
            break;
          }
          if (!AllRewritten)
            continue;
        }
        // ---- MUTATION STARTS HERE. Nothing below may refuse.
        IRBuilder<> B(PreTerm);
        Value *H = materializeCopySource(Pf->Seed, Alloc, taint, B,
                                         P.getDebugLoc(), "cq.carried");
        P.setIncomingValue(Pf->ExtIdx, H);
        // bd `test_C_libtooling-h1ip` — THE ZERO-TRIP PATH NAMES THE SAME
        // REGISTER. Each recorded bypass incoming is the SEED arriving at an
        // out-of-loop φ on the GUARD's own edge; rewriting it to `H` makes that
        // φ mux two `i32` HANDLES under the loop's own CLASSICAL guard — the
        // identical argument the header φ already stands on: exactly one incoming
        // is live, and WHICH one is a classical fact the hardware already has.
        // The φ is recorded in the promotion's own set for the same reason the
        // header φ is — it is A MUTATION THIS STAGE MADE, never a prediction and
        // never re-derived at the guard (Rule 14).
        for (auto &BI : Pf->BypassIncomings) {
          BI.first->setIncomingValue(BI.second, H);
          taint.PromotedCarriedHandlePhis.insert(BI.first);
        }
        // bd `test_C_libtooling-11qv` — THE RETYPE, and the width record that
        // makes it safe. `mutateType` is the `RailBankPromote.cpp` idiom (*"the
        // load IS a rail name now"*); here the φ IS a rail name now.
        //
        // ⚠ THE `HandleWidth` RECORD IS NOT BOOKKEEPING — IT IS THE SAFETY
        // ARGUMENT, and `RailBankPromote`'s spelling of this idiom ERASES where
        // this one must WRITE. Its MEASURED consumer is `lowerOps`' up-front
        // CAST CAPTURE (`OpcodeLowering.cpp`,
        // `taint.HandleWidth.lookup(Cast->getOperand(0))`): a narrow carried φ
        // with a `sext i16 %a to i32` user emits
        // `cq_template_sext_i16_to_i32(i32 %a)`, and the SOURCE width in that
        // symbol exists only because this line ran. `Pf->Abi` was read off the
        // φ's type at (Z3), while the type still said it.
        // ⚠ AN EARLIER WORDING NAMED `logicalOperandWidth` INSTEAD —
        // STRUCTURALLY UNREACHABLE from here (Rule-13 round 4, F-4: its callers
        // all run inside control emission, which finishes long before this
        // stage). Right conclusion, wrong ground; corrected at the source.
        if (Pf->NeedsHandleRetype) {
          P.mutateType(Type::getInt32Ty(M.getContext()));
          P.setMetadata(LLVMContext::MD_range, nullptr);
          P.setMetadata(LLVMContext::MD_tbaa, nullptr);
          taint.HandleWidth[&P] = Pf->Abi;
        }
        taint.PromotedCarriedHandlePhis.insert(&P);
      }
    }
  }
}

// ⚠ CONJUNCT 2'S PREMISE IS MEASURED FALSE FOR ONE SHAPE (bd memory
// `r7-loop-grant-twin-parity-falsified-2026-10-15`). The R7-loop grant rests on
// "the rolled form leaks no more than its hand-unrolled twin". Since bd
// r2j3.32 the twin of `slice_control_cascade_loop_carried_handle.c` REVERSES
// its trip-1/trip-2 merge rails (4 rails leaked) while the rolled form cannot
// (6): a loop-carried merge rail is the next trip's copy source, so its
// reversal is LIFO across trips (a post-loop reverse loop, bd 8h7d.20). Conjunct
// 2 does not see it — a merge rail is not a spine discharge candidate. The leak
// is accepted (routing decision (b)); its composition with a later non-diagonal
// gate on what the rails record is fenced loudly by `MergeCarriedFence.h`.
void declineUnmarkedRolledIterLocal(Module &M, TaintSet &taint) {
  if (taint.RolledLoopRegionGates.empty())
    return;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Do the per-function work only if some record lives here — rebuilding
    // DT/LI is not free and most functions have no record.
    bool Any = false;
    for (const TaintSet::RolledLoopGrant &G : taint.RolledLoopRegionGates)
      if (auto *I = dyn_cast_or_null<Instruction>(G.Gate))
        if (I->getParent() && I->getFunction() == &F) {
          Any = true;
          break;
        }
    if (!Any)
      continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    // ⚠ DECLARED HERE, AND KEYED ON THE LOOP HEADER — BOTH HALVES MATTER, AND
    // THE PREVIOUS SPELLING (a module-scoped `SmallPtrSet<const Loop *>`) WAS A
    // DANGLING POINTER THAT SHIPPED A SILENT MISCOMPILE (review round 1,
    // finding F-W1-1, 2026-09-14). `LoopInfo` OWNS its `Loop` objects and
    // destroys them at the end of this iteration; a set of `const Loop *` that
    // outlives it holds freed pointers, the next function's `LoopInfo` re-uses
    // the same allocation, and `insert(L).second` then returns FALSE FOR A
    // DIFFERENT LOOP IN A DIFFERENT FUNCTION — skipping the whole re-ask.
    // MEASURED on two ordinary kernels in one translation unit with no
    // attributes (`b6_noattr.c`): the second kernel's per-trip
    // `cq_template_and_i32_hl` rail was minted twice and uncomputed ZERO times,
    // `opt` exit 0, verify-clean, stage-2b `0 violation(s)`.
    // A `BasicBlock *` lives as long as the module, so the key is stable even
    // if someone later hoists these declarations again; the per-function scope
    // is the primary fix and the header key is the defence in depth, in the
    // style of the two `defence in depth` notes in `ArmClassify`'s R7 block.
    // ⚠ TWO SETS, NOT ONE, AND THAT IS NOT TIDINESS: the conjuncts cover
    // DIFFERENT entries (conjunct 1 only for clause-(c) grants), so a single
    // "already diagnosed this loop" set lets a (b') entry that passed conjunct 2
    // suppress the (c) entry's conjunct 1 — the SAME suppression bug one level
    // down. Each conjunct dedups itself.
    SmallPtrSet<const BasicBlock *, 4> AskedEscape;   // conjunct 1, per loop
    SmallPtrSet<const BasicBlock *, 4> AskedMarking;  // conjunct 2, per loop
    for (const TaintSet::RolledLoopGrant &G : taint.RolledLoopRegionGates) {
      auto *I = dyn_cast_or_null<Instruction>(G.Gate);
      if (!I || !I->getParent() || I->getFunction() != &F)
        continue;  // erased, or another function's record.
      Loop *L = LI.getLoopFor(I->getParent());
      if (!L) {
        diagnoseUnderControl(I, "control flow inside a loop body");
        return;  // `LLVMContext::diagnose` exits on the first DS_Error anyway.
      }
      const BasicBlock *Hdr = L->getHeader();
      // CONJUNCT 1 — clause (c3) AT FINAL TAINT, FOR CLAUSE-(c) GRANTS ONLY.
      // `repropagateControlMerges` can taint a value that was classical when
      // `classifyArms` asked, and `markIfRailLocal`'s marking is ADDITIVE and
      // never withdrawn, so a round-1 grant would otherwise stand over a round-2
      // escape. Asked by calling the SAME body clause (c3) called (Rule 14).
      //
      // ⚠ NOT ASKED OF A (b)/(b') ENTRY, AND THE REASON IS ABOUT PREMISES, NOT
      // ABOUT WHAT "CARRIED" MEANS.
      // THE REASON THIS COMMENT GAVE FOR ONE REVIEW ROUND WAS MEASURABLY FALSE
      // (finding F-W2-2, round 2, 2026-09-14). It read: *"(c3) refuses when
      // anything tainted defined in `L` is read outside `L`, and a loop-CARRIED
      // rotated register is read outside `L` — that is what 'carried' means."*
      // `w2b_sameloop_mixed.c` breaks it: ONE loop carrying BOTH a (b') grant
      // (a carried register rotated in place under a loop-invariant `_Bool`) and
      // a (c) grant (an iteration-local register under a per-trip `_Bool`).
      // It ACCEPTS — 22 trace lines, BYTE-IDENTICAL to its hand-unrolled twin,
      // ORACLE DECLINE — and accepting REQUIRES (c3) to have held, because (c3)
      // is `iterationLocalTaintEscape(L, Taint) == nullptr`: a ∀ OVER THE WHOLE
      // LOOP, not over one register. Meanwhile the (b') carried register is a
      // tainted header φ defined in `L` whose only users (the arm's `cq_theta`,
      // the merge φ, a `cq_measure`) are ALL INSIDE `L`, and
      // `iterationLocalTaintEscape` has no φ exemption. A loop-carried
      // accumulator measured every trip is an ordinary shape, not a contrivance.
      // So "carried ⇒ read outside `L`" is NOT A THEOREM and must not be leaned
      // on by a future widening (CLAUDE.md L7: a wrong reason that happens to
      // reach a right conclusion is exactly the shape that hardens into a rule).
      //
      // THE TRUE REASON — conjunct 1 re-asks a premise that ONLY CLAUSE (c)
      // EVER HAD. (c3) is clause (c)'s own third conjunct, asserted by the
      // classifier at ROUND-1 taint; this is that same clause re-asked at FINAL
      // taint, i.e. the L1 PREDICATE discharge for (c) and for nothing else.
      // Clause (b') never asserted (c3). ITS premise is that the rail's header φ
      // will be CLAIMED by the round-2 collapse — and that premise has its own
      // round-2 re-ask, namely the collapse itself, which declines loudly with
      // `kMsgCrossIter` when the φ is not claimable. Asking (c)'s premise of a
      // (b') entry would be asking a question (b') never answered.
      // The SECOND half of the old sentence is NOT falsified and is kept: asking
      // it there would also decline every shipped drbq Inc-3 in-loop arm — in
      // every (b') shape probed across review rounds 1 and 2 (`w2c_inplace_cmp`,
      // `control_inplace_ry_inloop_offset.ll`'s C analogue, `d1`) the carried
      // register IS read after the loop.
      //
      // Anchored at the ESCAPING VALUE, not at the hoisted gate: its `!dbg` is
      // the source line that reads a per-trip register outside the loop, which
      // is the line the user has to change.
      //
      // ⚠ WITH A FALLBACK, AND THE REASON IS A MEASURED CLASS OF DEFECT, not
      // defensiveness: a diagnostic that loses its `!dbg` reports
      // `<unknown>:0:0` and is INVISIBLE to every gate this project runs except
      // a full-stderr hash — one shipped past a green 1946-fixture lit run, a
      // 0-MISSED injection matrix and a byte-identical 288-cell family (Track P,
      // 2026-09-14). `Esc` is whatever `iterationLocalTaintEscape` found first,
      // and the pass MANUFACTURES tainted values that carry no `!dbg` at all
      // (`MergePhiPeel`'s compare clones, `AngleSelectEmit`'s twin rotation). The
      // hoisted gate `I` is always a SOURCE `@cq_theta` and always has one, so it
      // is the anchor of last resort. Never silently emit the less-located of the
      // two.
      // ⚠ AND THE NULL TEST THAT USED TO STAND HERE (`Esc->getDebugLoc() ? …`)
      // WAS HALF A FIX: a `!dbg` whose LINE IS 0 is non-null and still prints
      // `file:0:0` (review round 2, F-W2-5). `anchorIsLocated` is the ONE
      // spelling of that question (`ControlPlan.h`, beside
      // `diagnoseUnderControl`), shared with `declAnchor` so the two cannot
      // drift.
      if (G.IterationLocal && AskedEscape.insert(Hdr).second)
        if (Instruction *Esc = iterationLocalTaintEscape(L, taint)) {
          // bd `test_C_libtooling-8h7d.12` — THE SAME STRING ITS DETECTION-TIME
          // TWIN USES. This is (c3) re-asked at FINAL taint; one question must
          // not have two names (Rule 14).
          diagnoseUnderControl(anchorIsLocated(Esc) ? Esc : I,
                               "iteration-local value read after the loop");
          return;
        }
      // CONJUNCT 2 — the MARKING postcondition, asked of EVERY grant (finding
      // F-W1-2: a (b') grant leaks exactly the same per-trip rail a (c) grant
      // does, and the leak does not care which clause let the region through),
      // and asked ONLY when the body has something for the spine to discharge
      // (see `bodyHasSpineDischargeCandidate` for the measured reason, and for
      // why its excluded kinds are exact).
      //
      // ⚠ HISTORY, CLOSED BY CONSTRUCTION SINCE bd 8e5r (r1A F-EA-3): this read
      // is in the ACCEPT direction, and `taint.IterationLocalBlocks` USED TO BE a
      // raw `BasicBlock *` set nothing ever scrubbed — a stale pointer that
      // matched a live block would have kept `Marked` true for a block never
      // marked (F-W1-1's shape one container over; review round 2, F-W2-4,
      // 2026-09-14). It is now self-cleaning (`ScrubOnDelete.h`): a BasicBlock IS
      // a Value, its deletion notifies the set, and a fresh block at a dead
      // block's address is NOT a member. The analysis below — why no block is
      // CREATED in the window — was the defence before; it is kept as the
      // record of why the old raw set never fired.
      //
      // WHY IT IS SAFE AT THIS SITE, MEASURED AND NOT ARGUED FROM HABIT: a false
      // positive needs a LIVE `BasicBlock` to sit at the address of an ERASED
      // one, i.e. a BasicBlock ALLOCATED between the marking and this read.
      // `RegionFlatten` does erase blocks between them (round 1 and round 2) —
      // but NOTHING IN THE PASS CREATES ONE. An exhaustive scan of the
      // block-creating APIs over `ir-pass/src` + `ir-pass/include` —
      // `BasicBlock::Create`, `splitBasicBlock`, `SplitBlock`, `SplitEdge`,
      // `SplitBlockPredecessors`, `SplitCriticalEdge`, `CloneBasicBlock`,
      // `CloneFunctionInto`, `InlineFunction`, `UnrollLoop`, `simplifyLoop`,
      // `formLCSSA` — finds exactly four owners, and every one of them is
      // OUTSIDE the window in BOTH entry points:
      //   `LoopUnrollPrepass` (`UnrollLoop`/`simplifyLoop`/`formLCSSA`) runs
      //       BEFORE `lowerLoops`, i.e. before the first marking;
      //   `Specialization` (`BasicBlock::Create`, `CloneFunctionInto`, reached
      //       only from `specialize`) and `BreakReversePlay`
      //       (`splitBasicBlock` + `BasicBlock::Create`, from
      //       `lowerBreakReversePlay`) both run AFTER this stage
      //       (`CQLoweringPass.cpp:654`/`:666` and `:1010`/`:1016` vs `:532`
      //       and `:983`).
      // An address freed here could therefore only be re-occupied by a
      // NON-block allocation, which `L->blocks()` never yields.
      // ⚠ CORRECTED (r1A F-EA-3, L7): this comment used to add that "a
      // `WeakTrackingVH` would not even apply (it tracks `Value`s …)". A
      // `BasicBlock` IS a `Value`, and bd 8e5r's `CallbackVH`-hooked set is the
      // counterexample. Its RETIREMENT TRIGGER ("the day a block-creating stage
      // moves into the window, this read needs a real scrub at the erase sites")
      // is DISCHARGED — the scrub is total now, at deletion, whoever erases — and
      // so is the "NOT A CLEAN BILL" exposure it named for the set's other
      // consumers (`FreePoint` / `Uncomputation`, which run after
      // `lowerBreakReversePlay` creates blocks): a recycled block address is no
      // longer a member for them either.
      if (!AskedMarking.insert(Hdr).second)
        continue;
      if (!bodyHasSpineDischargeCandidate(L, taint))
        continue;
      // ⚠ THE LOOP THAT USED TO STAND HERE IS NOW `bodyBlocksMarked` (bd
      // `test_C_libtooling-emkg`, 2026-09-15). ITS BEHAVIOUR AT **THIS** SITE IS
      // UNCHANGED, and that is the whole point of the change: this spelling was
      // the CORRECT one — `L`'s own blocks, ALL of them — and
      // `declineDephasingUnmarkedLoopRails`' conjunct (1) was the second, wrong
      // spelling of the same question. The predicate's extra `Any` guard cannot
      // move this site: `LI.getLoopFor(L->getHeader()) == L` is a `LoopInfo`
      // invariant, so `L` always has at least one own block and the old `Marked =
      // true` initial value was never observed vacuously. THIS SITE IS THE
      // REFERENCE READING; if the shared predicate and this comment ever
      // disagree, the predicate is what runs.
      if (!bodyBlocksMarked(L, LI, taint)) {
        diagnoseUnderControl(I, "control flow inside a loop body");
        return;
      }
    }
  }
}

void lowerLoops(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // bd `test_C_libtooling-tu9q` — clause (ii-d)'s obligation ledger is cleared
  // HERE, unconditionally and before anything can write it, so a second module in
  // the same process never inherits the first one's obligations. This is the
  // FIRST of the three `invariantRegisterRoots` owners to run, in BOTH pipeline
  // entry points (`CQLoweringPass.cpp:500` and `:1171`); the postcondition clears
  // it again after reading, and neither clear depends on the other having run.
  // Same discipline, and the same reason, as bd `bbu0`'s deferred slot.
  exitDischargeObligations().clear();
  breakEscapeLedger().clear();  // bd 8h7d.17: same discipline, same reason.
  // The collected rotation call sites — the in-place-gate wire vocabulary the
  // peel + closure consult (same seed as `declineClassicalMuxes`).
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Cheap skip: a function with no tainted value has no quantum loop.
    //
    // bd test_C_libtooling-um24 — LIVE POINTERS ARE LOOKED UP IN THE SET; THE
    // SET'S KEYS ARE NEVER DEREFERENCED. This scan used to walk `taint.Tainted`
    // and call `getFunction()` on every key, and a key whose instruction an
    // earlier stage (or this function, for an earlier `F`) had erased made that a
    // use-after-free READ: SIGSEGV on four shipped decline fixtures under a
    // reusing allocator (`CQ_OPT_DEBUG_ALLOC=lifo`) and under a no-reuse one
    // (`=nofree`, where the dead object's parent is null) — on the oracle too.
    // `taint.Tainted` can no longer hold a deleted key (`ScrubOnDelete.h`), but a
    // LIVE key that is momentarily DETACHED would still make `getFunction()` a
    // null dereference, so this takes the same spelling as its two neighbours
    // (`declineDephasingUnmarkedLoopRails`, `promoteLoopCarriedHandleSeeds`): walk the live
    // IR of `F`, ask the set. Same answer, no dereference of a key.
    bool AnyTainted = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB)
        if (taint.Tainted.count(&I)) {
          AnyTainted = true;
          break;
        }
      if (AnyTainted)
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
      if (tryCaseA(L, F, taint, GateCalls, DT, LI))
        continue;
      if (markIfIterationLocal(L, taint, LI))
        continue;
      // ── bd `test_C_libtooling-tu9q` (P1), owner ruling D4's END STATE ──────
      //    THE ROUND-1 ROOT-MINT ESCAPE — THE IN-LOOP PAIRING FOR A LOOP WITH
      //    NO TAINTED CONTROL FLOW.
      //
      // `markIfIterationLocal` refuses ANY loop whose body reads a tainted value
      // minted OUTSIDE `L` ("every tainted OPERAND of an in-L instruction is
      // DEFINED in L"). That refusal is a LEAK, not a decline: the body's
      // per-trip `cq_template_*` rails are minted, the spine's in-loop guard
      // (`canRepeat(&BB) && !IterationLocalBlocks.count(&BB)`) skips them, and
      // neither the `_unc` adjoint nor the `cqrt_free` is emitted — while the
      // HAND-UNROLLED spelling of the same source emits both. MEASURED on the
      // ORACLE `0e280fc6…`: `s1_live_shift.c` 10 trace lines rolled against 14
      // unrolled, the four missing lines being `cq_template_lshr_i32_hl_unc` +
      // `cqrt_free`, twice. Where the register those rails COPY is re-rotated
      // after the loop that is a WRONG UNITARY (Rule 8), which is why bd `s82e`
      // ships `declineDephasingUnmarkedLoopRails` as the INTERIM; this is the
      // capability D4 filed to retire it.
      //
      // ⚠ `markIfRailLocal` IS THE ANSWER, NOT A NEW PREDICATE (Rule 14). The
      // sibling marker already has exactly this escape — `onRail`, over a
      // `Roots` set — and `invariantRegisterRoots` already owns the proof that a
      // root mint is a sound thing to put in that set. Both were built for the
      // ROUND-2 region path (`collapseFlattenedLoopRails`), which opens
      // `if (taint.InLoopFlattenedPreds.empty()) return;` and therefore NEVER
      // RUNS for a loop with no tainted control flow — so for `s1`/`w2k` the only
      // marker that ever ran was the one WITHOUT the escape. `CLAUDE.md` L2
      // verbatim: 3qlq Inc 1 widened one of the two sibling clauses and left the
      // other. This call site is that omission, closed by CALLING the widened
      // sibling rather than by re-spelling it here.
      //
      // ⚠ WHY IT IS PROVABLY ADDITIVE, and why the `markIfIterationLocal(...)`
      // above is ASKED FIRST rather than replaced. `invariantRegisterRoots`
      // returns false on an empty `Cands` (no tainted value defined outside `L`
      // is read inside it), and `Cands` is built from the IDENTICAL quantifier
      // `markIfIterationLocal`'s refusing clause scans. So on every loop where
      // that marker MARKS, this path is not even reached; on every loop where it
      // refuses for some OTHER clause, `markIfRailLocal` asks that same clause
      // again and refuses too (its clause set is a superset — the only clause it
      // relaxes is the one that named `Roots`). The set of loops whose marking
      // CHANGES is therefore exactly: refused by the operand clause, and every
      // outside-`L` tainted read is a proven root mint.
      //
      // ⚠ THE MULTIPLICITY PRICE IS PAID BY THE SAME ARGUMENT, NOT A NEW ONE.
      // `Uncomputation.cpp`'s §4/§2.9 pair asks each endpoint separately whether
      // it repeats and never whether the two repeat EQUALLY, so a recovered gate
      // in the PREHEADER (once) with `At` in a marked body (K times) would emit K
      // adjoints against ONE forward gate. `invariantRegisterRootsImpl` clause
      // (ii) admits ONLY a root mint or a Phase-4 merge out-rail, and BOTH lower
      // to `cqrt_alloc_<W>`, which `ChainWalk::isInteriorTerminalHandle` clause
      // (I1) excludes from the M-B interior partition OUTRIGHT — so neither can
      // ever BE that preheader gate. A hoisted loop-invariant TEMPLATE rail
      // (`int p = q * 3;`) is exactly what (I1) admits and is exactly what clause
      // (ii) refuses.
      // ⚠ **THE NEXT SENTENCE USED TO SAY IT IS "UNCHANGED HERE AND STILL LEAKS
      // (still declines, under bd `s82e`)" AND THAT IS FALSE AS OF THIS COMMIT**
      // (bd `test_C_libtooling-4jok`, Rule-13 round 5 finding F-6). Clause
      // **(ii-d)**, ~2800 lines up in this same file, IS that widening: it admits
      // the hoisted template rail as a Root, licensed by PLACEMENT (P2's anchor)
      // and made total by `declineUndischargedExitObligations`. The old sentence
      // also called for "the real multiplicity test `Uncomputation.cpp:982-1000`
      // specifies" — that test is `multiplicityAgrees` (P1) and it is built.
      // Corrected AT THE SOURCE in the landing commit rather than in a record,
      // because `CLAUDE.md` L7's twist is that a correction which does not land in
      // the source is not a correction: the same false clause was found three
      // times in one session for exactly that reason.
      //
      // ⚠ L1 — this slot is ROUND-1 TAINT. `lowerLoops` runs before
      // `repropagateControlMerges` in BOTH entry points, so every clause asked
      // here is asked with round-1 evidence. The grant is RECORDED
      // (`taint.Round1RailGrants`) and RE-ASKED under FINAL taint by
      // `declineRound2FalsifiedRailGrants`, which shares the refusal predicate
      // with `markIfRailLocal` by CALLING it (Rule 14) and declines loudly rather
      // than silently withdrawing. `markIfIterationLocal`'s own round-1 grant is
      // pre-existing and is NOT re-asked; that is a KNOWN, separate exposure this
      // change does not widen and does not close.
      SmallPtrSet<Value *, 4> Roots;
      if (invariantRegisterRoots(L, taint, wd, DT, LI, GateCalls, Roots,
                                 /*CarriedRoots=*/nullptr) &&
          markIfRailLocal(L, taint, LI, GateCalls, Roots))
        recordRound1RailGrant(L, taint, Roots);
    }
  }
}

}  // namespace cq
