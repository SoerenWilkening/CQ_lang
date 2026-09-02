// SwapRouteEmit.cpp — see header. The mutating swap-route emitter for accepted
// regions. PHASE arms — a one-content-arm diamond (§5a) or a two-arm if/else
// (§5b), lowered by one arm-list-parameterized procedure — emit the coherent,
// zero-controlled-gate routed stream of SCOPING §3a in the §5 contract order
// (an if/else routes BOTH arms to distinct rails, the else under ¬flag via the
// cqrt_x bracket), then rewire + flatten. VALUE arms — a one-content-arm
// DIAMOND (§5d, WI-4) or a two-arm IF/ELSE (§5e, WI-5), likewise one
// arm-list-parameterized procedure — lower by method-B B-keep: route +
// verbatim chain replay + ONE copy-out + per-arm reverse-play R† — see
// emitValueRegion.
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2):
//   `(|0> + |1>)/√2 ⊗ |0>_f` ─route+Rz+route→ `(|0>|0>_f + e^{iθ}|1>|1>_f)/√2`
//   ─icmp_inv(q)→ `(|0> + e^{iθ}|1>)/√2 ⊗ |0>_f`: the rail returns to |0>
//   UNCONDITIONALLY (Rz|0>=|0>), q keeps the conditional phase, and the flag is
//   stripped because Rz preserves q's basis value (q == q0). Zero `_controlled`
//   gates, no added measurement (SCOPING §3a/§3b). The value-arm trace is at
//   emitValueRegion (PRD Part II §8.2).

#include "SwapRouteEmit.h"

#include "AbortParkEmit.h"       // emitAbortParkRegion (the 7.2 Inc 3 park cascade)
#include "ArithLowering.h"       // rewriteBinary (the value-arm chain body, §4)
#include "CompareLowering.h"     // lowerCompareToFlag
#include "ClassicalCallArmEmit.h" // emitClassicalCallArmRegion (the 6.5 merge)
#include "GuardedStoreArmEmit.h"  // emitGuardedStoreArmRegion (iw81.7)
#include "ControlPlan.h"         // ControlRegion / ControlPlan
#include "ControlledSymbols.h"   // cswapFn / xFn
#include "EmitInverse.h"         // emitInverseChain (the value-arm reverse-play)
#include "NestedRouteEmit.h"     // lowerNestedRegion (the depth-2 nest dispatch)
#include "OpcodeSupport.h"       // abiWidthFromType (value-arm rail width)
#include "RegionFlatten.h"       // flattenRegion
#include "SelectMergeEmit.h"     // emitSelectRegion (the 4.4 select merge)
#include "SwitchRouteEmit.h"     // emitSwitchPhaseRegion (the 4.5 switch phase)
#include "TaintPropagation.h"    // TaintSet
#include "WidthDispatch.h"       // allocFn / copyFn / rzRtFn / freeFn / abiWidthFor

#include "llvm/ADT/STLExtras.h"   // llvm::reverse / llvm::is_contained
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <algorithm>
#include <cassert>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// so a later module walk (`lowerRotations` / `lowerOps` / `uncompute`) never
// dereferences freed memory (§6.1 — the dangling-work-list SIGSEGV). A per-TU
// mirror of the same helper in RegionFlatten (the house style for trivial
// taint-set maintenance, cf. the duplicated `isMeasureSink`). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  // §6.1, grown at 4.2 WI-4: the value path erases arm `BinaryOperator`s,
  // which are in `declineStaleRecordOps`' purview — a stale member whose heap
  // address a later-minted instruction reuses would make `lowerOps`' skip
  // probe silently DROP that instruction's lowering (a false StaleDeclined
  // hit). Phase-path erasees are never members (cq_phi/phi/br/branch-feeding
  // compares are out of the stale guard's scope), so this stays idempotent.
  taint.StaleDeclined.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
    // M-B Increment 6's two EMITTER-RECORDED sets (bd test_C_libtooling-160a
    // Rule-13 round, finding F3). This module is their sole writer, so it is
    // also where a recorded key must be dropped if the call it names is ever
    // erased — a dangling `CallInst *` reused by a later allocation would make
    // `ChainWalk::isInteriorConsumer` / `routeGroupFullyInside` answer YES for
    // an unrelated call, i.e. discharge a chain against a route that never
    // restored anything.
    //
    // TWO BELTS, and this is the SECOND one; the first is that neither key can
    // dangle today. No stage between `lowerControlRegions` and `uncompute`
    // erases a recorded call: `flattenRegion` SPLICES the merge block into
    // `Pred` (moves, never erases the stream), the hcrg sequential ordering
    // erases only arm blocks and emptied merges, and `lowerRotations` /
    // `lowerOps` / `lowerMeasures` / `specialize` erase `cq_*` intrinsic calls
    // only — never a `cq_template_*_unc` or a `cqrt_cswap`. This emitter itself
    // erases only the merge φ and the arm `cq_phi`/`BinaryOperator`s, none of
    // which is ever recorded. And even a dangling key that WERE reused could not
    // be acted on: an admitted strip must additionally pass
    // `TemplateName::isUncHandleSlot` (slot 0, the written flag, is refused) and
    // every operand of the spine's own `_unc`s is in `ReversedRails`, which
    // candidate selection subtracts. The erases below make the argument
    // unnecessary rather than merely correct — cheap, idempotent, fail-closed.
    //
    // A ROUTE GROUP IS DROPPED WHOLE, NOT MEMBER-WISE. The group's only claim is
    // that executing ALL of it restores the base's label; a group missing a
    // member states nothing (one half of a pair leaves the base holding |0> or
    // the arm's copy depending on the flag), and a 3-of-4 remnant would still
    // satisfy the consumer's every-member-inside test. Clearing it makes the
    // group unmatchable, so the component leaks — the safe direction.
    taint.DischargedFlagGates.erase(CI);
    for (auto &Gates : taint.RestoringRoutes)
      if (llvm::is_contained(Gates, CI))
        Gates.clear();
  }
}

// The trailing suffix of a `<Prefix><sfx>` intrinsic callee (e.g. `si32` from
// `cq_phi_si32`), or "" if `V` is not such a call.
StringRef intrinsicSuffix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return {};
  const Function *F = CI->getCalledFunction();
  if (!F || !F->getName().starts_with(Prefix))
    return {};
  return F->getName().substr(Prefix.size());
}

bool isPhiCall(const Value *V) { return !intrinsicSuffix(V, "cq_phi_").empty(); }

// `collectArmPhis` and `emitRoute` are DE-ANONYMIZED into the named `cq`
// namespace (declared in SwapRouteEmit.h, WI-3/MD1-style) so the 4.3
// `NestedRouteEmit` TU can reuse the SAME bounded arm-gate collector and the SAME
// ¬flag-bracketed router at both nest levels (Rule 14 — one definition of the
// correctness-critical routing primitive, no drift-prone copy). Their definitions
// move below the anonymous block (so they can still see the TU-local `isPhiCall`);
// behavior is unchanged. See the definitions just before `lowerControlRegions`.

// The value an arm's IN-BLOCK phase spine bottoms at — the routed base handle
// (the live quantum register the arm's gates rotate). For an if/else, which has
// no straight-through (Pred) merge edge, this recovers the routed handle
// `classifyArms` proved BOTH arms share; for a gate-free arm (`ArmIncoming` is the
// base itself) it returns that value unchanged. Bounded at the arm-block boundary
// for the same reason as `collectArmPhis`: a `cq_phi` defined OUTSIDE `ArmBB` is
// the live DERIVED base handle (route THIS), never hopped past to the theta.
Value *phaseSpineBase(Value *ArmIncoming, const BasicBlock *ArmBB) {
  Value *V = ArmIncoming;
  while (isPhiCall(V)) {
    auto *CI = cast<CallInst>(V);
    if (CI->getParent() != ArmBB)
      break;  // pre-region cq_phi — the live derived base handle.
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  return V;
}

// The routed base a value chain consumes — its FIRST (base-first) link's sole
// tainted operand, i.e. the exact SSA value the step-4 rail retarget must
// substitute. classifyArms proved every accepted link has exactly ONE tainted
// operand (Q+Q links defer) and, for an if/else, that BOTH arms' chains bottom
// at the SAME base (base-identity). Null on anything off that proof — a
// malformed plan the caller declines loudly (Rule 1).
Value *valueChainBase(ArrayRef<Instruction *> Chain, const TaintSet &taint) {
  if (Chain.empty())
    return nullptr;
  const auto *BO = dyn_cast<BinaryOperator>(Chain.front());
  if (!BO)
    return nullptr;
  Value *Op0 = BO->getOperand(0);
  Value *Op1 = BO->getOperand(1);
  const bool T0 = taint.Tainted.count(Op0) != 0;
  const bool T1 = taint.Tainted.count(Op1) != 0;
  if (T0 == T1)
    return nullptr;  // Q+Q or untainted head — never an accepted chain.
  return T0 ? Op0 : Op1;
}

// One content arm's routed VALUE stream: its ¬flag polarity, the ordered
// ORIGINAL chain links (the plan's Shadow/ShadowFalse, FORWARD order), and the
// per-arm state threaded through emission.
struct ValueArmStream {
  bool Negated;
  ArrayRef<Instruction *> Chain;   // original IR links (erased in step 10)
  CallInst *Rail = nullptr;             // the arm's |0> work rail (chain head; freed)
  SmallVector<CallInst *, 6> Fwd = {};  // minted forward template calls (step 4)
};

// Lower one accepted VALUE-arm region — a one-content-arm DIAMOND (§5d, WI-4)
// or a two-arm IF/ELSE (§5e, WI-5) — by method-B B-keep (IMPLEMENTATION-4.2
// §4), one arm-list-parameterized procedure (the value twin of the phase
// emitRegion below). Emitted into the pred block before the conditional `br`,
// in this exact order (symbol order IS the contract; reordering steps 5–9 is
// trace-plausible, verify-clean, and WRONG):
//
//   1 flag mint        cq_template_icmp_<pred>_<W>_hl(q, lit)
//   2 |0> work rails   cqrt_alloc_<W>(0) per content arm — width from the
//                      chain op's iN type
//   3 route-ins        cqrt_cswap(flag, p, rail) per arm  [¬flag X-bracketed:
//                      the else arm, or a FALSE-successor diamond arm]
//   4 arm chains       VERBATIM + UNCONTROLLED, each on its OWN rail — each
//                      link moved, base-retargeted (first link only), then
//                      rewriteBinary
//   5 route-backs      cqrt_cswap(flag, p, chainFinal) per arm — after ALL
//                      route-backs p holds the muxed answer (each branch's
//                      swap fires on a disjoint flag value)
//   6 ONE copy-out     out = alloc(0); cqrt_copy_<W>(p, out) — AFTER the
//                      route-backs (the answer is on p only then), BEFORE any
//                      route-back† (R† destroys it on p) — interlock §6.4
//   7 reverse-play R†  per arm in REVERSE emission order (LIFO): route-back† ·
//                      chain adjoint (void `_unc` forms, emitInverseChain, BODY
//                      CHAIN ONLY — the cswap arg-0 seam, PRD §8.5) · route-in†
//                      on the work rail. Arm blocks commute (disjoint rails; the
//                      route cswaps fire on complementary flag values), so the
//                      grouped per-arm order equals the literal global adjoint.
//   8 rail frees       on each arm's WORK RAIL `A.Rail` (the route-in†'d chain
//                      head) — provably |0> on BOTH branches only AFTER R† +
//                      route-in† (§3b); the `_unc`-zeroed intermediates leak
//   9 strip+flag free  icmp_inv(q) + cqrt_free(flag) — valid outright: the
//                      condition register is disjoint from the routed register
//                      in every accepted region (§0 criterion 4)
//  10 rewire           RAUW merge phi -> out; erase chain originals in
//                      reverse; flatten. NEVER free `out` (the answer) or `p`
//                      (the restored source) — either free is a hidden
//                      measurement.
//
// Correctness rests on the §8.2 register-threading trace, NOT on `opt -verify`
// (Rule 2). Diamond: flag=1 routes p0 into the rail, the chain computes f(p0)
// there, the route-back parks f(p0) on p for the copy, and R† re-derives then
// unwinds the chain so p == p0 and rail == |0> again; flag=0 leaves p
// untouched while the chain computes f(0) garbage on the rail thread, which
// the chain adjoint returns to |0>. If/else: the two route-ins park p0 on the
// SELECTED rail and |0> on p in BOTH branches; the selected chain computes
// f(p0)/g(p0) while the other computes f(0)/g(0) garbage; the two route-backs
// (complementary controls) park the selected answer on p; each arm's R† block
// unwinds its own rail — the selected one back through p (restoring p0), the
// garbage one in place. Both branches end every rail == |0> (clean frees, not
// hidden measurements) and p == p0 (so icmp_inv strips the flag). The B-keep
// boundary (kept-source correlation, channels A/B) is documented in PRD §8.2
// — binding, not a bug. NEVER this path for a phase arm (Rule 7): a CNOT
// copies a basis label, not a phase (verified P0 0.585 -> 0.500, dephased).
void emitValueRegion(const ControlRegion &R, BranchInst *BI, CmpInst *Cond,
                     PHINode *MergePhi, WidthDispatch &wd,
                     ControlledSymbols &csyms, TaintSet &taint) {
  // Arm list by FIELD identity (orientation-B diamond: R.Arm is the FALSE
  // successor, polarity rides ArmNegated; an if/else routes R.Arm under flag
  // and R.ArmFalse under ¬flag — the same assignment as the phase path).
  // classifyArms accepts only the homogeneous all-value region with every
  // chain non-empty; anything else here is a malformed plan — decline LOUDLY,
  // lower nothing (Rule 1).
  // ziov WI-1: shared-condition-flag sharing is implemented for PHASE arms only
  // (emitRegion). A VALUE-arm region whose condition is ALSO read as data is a
  // later WI — decline LOUDLY here rather than mint a flag, strip+free it (step
  // 9), and let `lowerOps` mint a second flag for the surviving data use (the
  // very ziov duplicate-mint, now in the value path). Over-declining is safe.
  if (R.ShareCondFlag) {
    diagnoseUnderControl(Cond, "condition used outside the branch");
    return;
  }

  SmallVector<ValueArmStream, 2> Arms;
  if (R.ArmFalse) {
    if (R.ClassArm != ArmClass::Value || R.ClassArmFalse != ArmClass::Value ||
        R.Shadow.empty() || R.ShadowFalse.empty()) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
    Arms.push_back({/*Negated=*/false, R.Shadow});
    Arms.push_back({/*Negated=*/true, R.ShadowFalse});
  } else {
    if (R.ClassArm != ArmClass::Value || R.Shadow.empty()) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
    Arms.push_back({R.ArmNegated, R.Shadow});
  }

  // The routed register Q — re-derived per arm as the chain head's sole
  // tainted operand (an if/else merge has no Pred edge to read it from; never
  // read width/identity off Q's SSA type). Every arm must agree, and a
  // diamond's Q must equal the straight-through (Pred-edge) incoming —
  // classifyArms proved both (base-identity), so a mismatch is a malformed
  // plan: decline LOUDLY, lower nothing (Rule 1).
  Value *Q = valueChainBase(Arms.front().Chain, taint);
  for (const ValueArmStream &A : Arms)
    if (!Q || valueChainBase(A.Chain, taint) != Q) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
  if (!R.ArmFalse &&
      (MergePhi->getBasicBlockIndex(R.Pred) < 0 ||
       MergePhi->getIncomingValueForBlock(R.Pred) != Q)) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  // ABI width from the chain op's INTEGER SSA type — reliable pre-RAUW (the
  // ops still carry iN; PRD §8.1 width-source). NEVER the theta suffix (the
  // routed base may be derived), and never a classifying signal (the f64
  // trap) — classifyArms' positive integer fence already proved validity, so
  // a null here is a malformed plan: decline LOUDLY, lower nothing (Rule 1).
  StringRef Abi = abiWidthFromType(Arms.front().Chain.front()->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Copy = Abi.empty() ? FunctionCallee() : wd.copyFn(Abi);
  if (!RailTy || !Alloc || !Copy) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  // Library-host parity (the twin-pipeline trap, IMPLEMENTATION §6.5): a
  // chain link `declineStaleRecordOps` marked has ALREADY been diagnosed with
  // the pledge "lower NOTHING for this op" (lowerOps honors it by skipping).
  // In the `opt` host that DS_Error exited the process before emission ever
  // runs; in an embedding host that does not exit, replaying the marked link
  // onto the rail here would break the pledge. Decline pre-mutation — no lit
  // fixture can pin this (opt exits at the stale diagnostic first); it is the
  // Rule-1 defensive bail, never a silent skip.
  for (const ValueArmStream &A : Arms)
    for (Instruction *Op : A.Chain)
      if (taint.StaleDeclined.count(Op)) {
        diagnoseUnderControl(Cond, "control flow");
        return;
      }

  const DebugLoc DL = BI->getDebugLoc();
  IRBuilder<> B(BI);  // every stream call lands before the conditional br.
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // 1. Flag mint — cq_template_icmp_<pred>_<W>_hl(q, lit).
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).

  // 2. One |0> work rail per content arm (allocated up front — the §5b order).
  //    Each joins `taint.Tainted` so rewriteBinary classifies the retargeted
  //    first link as HL/LH (handle + classical) — an untainted rail would
  //    misclassify BOTH operands as classical and emit a wrong shape. Rail
  //    users are only cqrt_*/template calls, so the later `uncompute` never
  //    selects them (isTerminalHandle is false — §6.2).
  for (ValueArmStream &A : Arms) {
    A.Rail = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "rail");
    stamp(A.Rail);
    taint.Tainted.insert(A.Rail);
    taint.ControlOwnedRails.insert(A.Rail);  // DD-4: Phase-4 owns this work rail
  }

  // 3. Route-ins (split) — p -> each arm's rail, X-bracketed for a ¬flag arm.
  for (ValueArmStream &A : Arms)
    emitRoute(B, csyms, Flag, Q, A.Rail, A.Negated, DL);

  // 4. Arm chains VERBATIM + UNCONTROLLED, each on its OWN rail. Per link in
  //    FORWARD (base-first) order: move to the stream position, retarget the
  //    FIRST link's routed-base operand to the arm's rail handle (later links
  //    already point at their predecessor, rewired by the previous RAUW),
  //    then REUSE ArithLowering::rewriteBinary verbatim — it emits the
  //    cq_template_<op>_<W>_hl/_lh call immediately before the moved op,
  //    RAUWs, and bookkeeps taint (Rule 14). The minted call is collected for
  //    the reverse-play; the original (now use-empty) op is erased in step 10.
  for (ValueArmStream &A : Arms)
    for (Instruction *Op : A.Chain) {
      auto *BO = dyn_cast<BinaryOperator>(Op);
      if (!BO) {
        // classifyArms records only BinaryOperator links; anything else is a
        // malformed plan — decline LOUDLY, never a silent skip (Rule 1).
        diagnoseUnderControl(Cond, "control flow");
        return;
      }
      BO->moveBefore(BI);
      if (A.Fwd.empty())
        BO->replaceUsesOfWith(Q, A.Rail);
      if (!rewriteBinary(BO, wd, taint))
        return;  // already diagnosed (no template) — abort the region loudly.
      // rewriteBinary inserts exactly ONE call, immediately before BO.
      A.Fwd.push_back(cast<CallInst>(BO->getPrevNode()));
    }

  // 5. Route-backs (join = adjoint of the split, same flag + brackets) with
  //    each arm's chain-final handle — the physical rail register's current
  //    SSA name. After ALL route-backs `p` holds the muxed answer: each
  //    branch's swap fires on a disjoint flag value, so the swaps commute and
  //    exactly one moves its answer onto p per branch.
  for (ValueArmStream &A : Arms)
    emitRoute(B, csyms, Flag, Q, A.Fwd.back(), A.Negated, DL);

  // 6. ONE B-keep copy-out: out := the basis-valued answer. `out` joins
  //    `taint.Tainted` (+BirthOrder) so downstream consumers of the RAUW'd
  //    merge phi keep classifying it as a quantum handle. NEVER free `out`,
  //    NEVER free `p` (PRD §8.5 — the answer / the restored source; a free of
  //    either is a hidden measurement).
  CallInst *Out = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "out");
  stamp(Out);
  CallInst *CopyCall = B.CreateCall(Copy, {Q, Out});
  stamp(CopyCall);
  taint.Tainted.insert(Out);
  taint.ControlOwnedRails.insert(Out);  // DD-4: Phase-4 owns this merge out-rail
  taint.BirthOrder[Out] = taint.NextBirth++;

  // 7. Reverse-play R†, per arm in REVERSE emission order (LIFO — the grouped
  //    blocks equal the literal global adjoint because arm streams commute:
  //    chains act on disjoint rails and route cswaps fire on complementary
  //    flag values). Per arm: route-back†, then the chain adjoint in exact
  //    reverse via the void in-place `_unc` forms — the BODY CHAIN ONLY through
  //    emitInverseChain (SCOPING §7.5): the route cswaps are bracketed by
  //    emitRoute because emitInverseCall would thread a handle into Args[0],
  //    which for cqrt_cswap is the FLAG slot (the seam, EmitInverse.cpp —
  //    feeding cswaps through the chain is a verify-clean wrong unitary, PRD
  //    §8.5) — then route-in† on the work rail (the chain head, restored to |0>).
  for (ValueArmStream &A : reverse(Arms)) {
    Value *ChainFinal = A.Fwd.back();
    emitRoute(B, csyms, Flag, Q, ChainFinal, A.Negated, DL);  // route-back†
    if (!emitInverseChain(B, A.Fwd, wd, &taint.SpineOps)) {   // R† (void `_unc`)
      // Every link is a forward uncontrolled template (we just minted them),
      // so this is unreachable — but an un-invertible link must decline
      // LOUDLY, never leave a half-reversed stream (Rule 1).
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
    // Route-in† on the arm's WORK RAIL (`A.Rail`): the void `_unc` chain zeroed
    // the intermediate rails in place but never touched `A.Rail` (the chain head,
    // read by the first link), which still holds the routed value p0. The cswap
    // moves p0 back onto Q (Q == q0) AND returns `A.Rail` to |0> for a clean free
    // (§3b). Under the old fresh-minting `_inv` this was the threaded `RailFinal`;
    // the void ABI mints no handle, so the chain-head rail IS `A.Rail`.
    emitRoute(B, csyms, Flag, Q, A.Rail, A.Negated, DL);     // route-in†
  }

  // NO KEPT-CARRIER RECORD CAN REACH THE RAILS FREED IN 8-9 (bd urlv audit; the
  // invariant is bd memory [record-freeze-invariant-2026-08-10]). Both classes —
  // the per-arm work rail and the path-predicate flag — are minted BY THIS EMITTER
  // at |0>, are returned to |0> by this emitter's own adjoint immediately below,
  // and are never an operand of a gate that writes a carrier the reversal does not
  // touch: the method-B copy-out writes the fresh `out` and READS a data rail this
  // emitter never frees, and this module mints NO `cqrt_tape_write_*` (only
  // `IOSinkLowering` and `AbortParkEmit` do). The 261j freeze is therefore not
  // owed here, and is deliberately not duplicated. Re-check this if a copy
  // destination ever becomes one of these rails, or if this emitter ever tapes.

  // 8. Rail frees, same reverse order, each on its arm's WORK RAIL (`A.Rail`) —
  //    provably |0> on both branches only AFTER its route-in† (§3b — earlier the
  //    rail holds p0 / f(0)-vs-0 garbage entangled with the flag: a dirty free is
  //    a hidden measurement). The intermediate forward-chain rails were zeroed by
  //    the void `_unc` chain and are left allocated (the accepted leak until the
  //    WI-4 whole-DAG per-rail free; NEVER freed dirty, Rule 6).
  for (ValueArmStream &A : reverse(Arms)) {
    CallInst *RailFree = B.CreateCall(wd.freeFn(), {A.Rail});
    stamp(RailFree);
  }

  // 9. Flag-strip + flag free. Valid outright: the condition register is
  //    disjoint from the routed register in every accepted region (§0
  //    criterion 4 via the diagonal-alias closure), so q == q0 at the strip.
  //    Reads `Cond`'s operands — MUST precede the erase of `Cond` (in
  //    flattenRegion). Do NOT hoist above step 7/8 (strip-after-R† is the
  //    documented order the accept class was cleared under).
  lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                     /*before=*/BI, /*negate=*/false, /*railToStrip=*/Flag);
  CallInst *FlagFree = B.CreateCall(wd.freeFn(), {Flag});
  stamp(FlagFree);

  // 10. Rewire + erase + scrub + flatten. The measure on the phi becomes a
  //     measure on `out` (the copied answer). Erase each arm's chain
  //     originals in REVERSE lineage order so each is use-empty when erased
  //     (the chains are disjoint, so the arm order is free — keep the step-7
  //     LIFO); scrub every erased instruction from all taint work-lists incl.
  //     StaleDeclined (§6.1).
  MergePhi->replaceAllUsesWith(Out);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  for (ValueArmStream &A : reverse(Arms))
    for (Instruction *Op : reverse(A.Chain)) {
      scrubTaint(Op, taint);
      Op->eraseFromParent();
    }
  flattenRegion(R, taint);
}

// One content arm's routed phase stream: whether it fires on ¬flag (X-bracketed
// cswap) and its ordered Rz gates to replay verbatim on its own work rail.
struct ArmStream {
  bool Negated;
  SmallVector<CallInst *, 4> Phis;
};

// The arm list + per-arm polarity, shared by every `emitRegion` recipe.
struct ArmInfo {
  BasicBlock *BB;
  bool Negated;
};

// Lower one accepted CONTROL-IN-PLACE ROTATION region (control-in-place-PRD §4
// + §6, bd test_C_libtooling-drbq Inc 1): a diamond or if/else whose every
// content arm is ONE tainted-operand `cq_theta` (Ry) on a register whose
// physical wire is disjoint from every condition wire.
//
// THE STREAM, and how little of it there is:
//     cq_template_icmp_<pred>_<W>_hl(c, lit)      ; flag mint, unchanged
//     [cqrt_x(f)]  <hoisted cq_theta>  [cqrt_x(f)] ; per arm, successor order
//     cq_template_icmp_<pred>_<W>_hl_unc(f, c, lit) ; flag strip, unchanged
//     cqrt_free(f)
// No `cqrt_alloc`, no `cqrt_cswap`, no reverse-play, no work rail at ALL — and
// that is forced, not chosen (PRD §2). The route's premise is that the arm gate
// is a no-op on the inactive `|0⟩` rail: true for `Rz = diag(1, e^{iθ})`, FALSE
// for `Ry(θ)|0⟩ = cos|0⟩ + sin|1⟩`, which hands the inactive rail back DIRTY and
// ENTANGLED with the flag. Cleaning that needs a controlled `Ry†` — method-A,
// dropped 2026-06-09 precisely because "if you would emit a controlled gate to
// clean a rail, you could have controlled the op in place from the start".
//
// HOIST-AND-DEFER: the `cq_theta` is MOVED (never re-minted) to just before the
// branch and recorded in `taint.ControlledRotations`; `lowerRotations` then
// mints `cqrt_ry_<W>_controlled(f, handle, θ)` there instead of the
// unconditional `cqrt_ry_<W>(handle, θ)`. Deferring keeps every PRE-lowering
// wire walker seeing a `@cq_theta_` on the base where one will fire — an
// over-approximation of a controlled gate as unconditional, which is the safe
// direction for every staleness fence (see `TaintSet::ControlledRotations`).
//
// WHY THE FLAG STRIP IS VALID, which is the whole accept: `icmp_..._unc`
// recomputes the predicate on the CONDITION's registers and XORs it back onto
// `f`. The only register this stream relabels is the arm's base, and R4 proved
// its physical rail is disjoint from every condition rail — so the condition's
// basis at the strip is the basis the mint read, and `f` returns to |0⟩
// unconditionally (Rule 6, then `cqrt_free`).
void emitInPlaceRotationRegion(const ControlRegion &R, BranchInst *BI,
                               CmpInst *Cond, PHINode *MergePhi,
                               ArrayRef<ArmInfo> Arms, WidthDispatch &wd,
                               ControlledSymbols &csyms, TaintSet &taint) {
  // Re-validate the plan shape by SSA identity before mutating anything. A
  // silently skipped accepted region would leave the tainted `br` to the backend
  // as classical control over quantum state (Rule 1), so every bail is LOUD.
  // `R.RoutedBase` is a `WeakTrackingVH` (see `ControlPlan.h`): an earlier
  // emitter's `MergePhi->replaceAllUsesWith(...)` has already been APPLIED to it
  // if this region's base was that φ, so the comparison against the theta's
  // (equally RAUW-updated) operand below is a comparison of two live values. A
  // raw pointer here compared a FREED address against a live one and declined
  // the increment's own headline shape whenever a classical branch sat between
  // two quantum regions (round-1 review L4 §2 — the verdict depended on textual
  // block order). Null means the handle was ERASED without a replacement: no
  // routed base, no proof, decline loudly.
  Value *Base = R.RoutedBase;
  if (!Base) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }
  // Pair each arm with its recorded gate. `Shadow` belongs to `R.Arm` and
  // `ShadowFalse` to `R.ArmFalse` by FIELD identity, never by edge truth (for an
  // orientation-B diamond `R.Arm` IS the false successor and the polarity rides
  // `ArmNegated`) — the same convention the phase and value paths use.
  SmallVector<std::pair<CallInst *, bool>, 2> Gates;
  for (const ArmInfo &A : Arms) {
    ArrayRef<Instruction *> Shadow =
        A.BB == R.Arm ? ArrayRef<Instruction *>(R.Shadow)
                      : ArrayRef<Instruction *>(R.ShadowFalse);
    const ArmClass Cls = A.BB == R.Arm ? R.ClassArm : R.ClassArmFalse;
    // UNREACHABLE TODAY, AND IT DECLINES RATHER THAN SKIPS (bd drbq round-2
    // review, lens C §3; round-1 lens L4 §3 found the same dead branch on the
    // phase path). It USED to `continue` with the comment "a gate-free sibling
    // arm contributes the base unchanged" — an assertion of support that does
    // not exist. `Arms` holds one entry for a diamond (whose sole arm is
    // `InPlaceRotation`, or this emitter was not dispatched) and two for an
    // if/else, and an if/else whose sibling arm is anything else — gate-free
    // included, which classifies as PHASE (`Base == Routed`, `armBlockIsPureSpine`
    // trivially true) — declines `mixed phase/value arm` at classification in
    // BOTH processing orders (`ArmClassify`: the phase clause refuses when
    // `SawValueArm || SawRotationArm`, the rotation clause when `SawPhaseArm ||
    // SawValueArm`). So no accepted region reaches this line.
    //
    // Skipping was the WRONG backstop for the day something does reach it: the
    // skipped arm's gates would then be dropped SILENTLY by `flattenRegion`'s
    // arm-block erase — a verify-clean wrong unitary, the exact class this file
    // exists to prevent. A loud decline costs nothing (it is unreachable) and
    // fails in the Prime-Directive direction.
    if (Cls != ArmClass::InPlaceRotation) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
    auto *T = Shadow.size() == 1 ? dyn_cast<CallInst>(Shadow.front()) : nullptr;
    if (!T || T->getParent() != A.BB || T->arg_size() < 2 ||
        T->getArgOperand(0) != Base) {
      diagnoseUnderControl(Cond, "control flow");
      return;  // the plan does not describe the IR — never emit half a region.
    }
    Gates.push_back({T, A.Negated});
  }
  if (Gates.empty()) {
    diagnoseUnderControl(Cond, "control flow");
    return;  // classification said InPlaceRotation; nothing to hoist is a bug.
  }

  const DebugLoc DL = BI->getDebugLoc();
  IRBuilder<> B(BI);  // every emitted call lands before the conditional br.
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };

  // 1. Flag mint at the BRANCH — byte-identical to the phase path's step 1. The
  //    ziov SHARED-flag position (mint at the compare) cannot arise here:
  //    `classifyArms` declines a `ShareCondFlag` region for this class.
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).

  // 2. Per arm in successor order: HOIST the gate, bracketed in the self-inverse
  //    `cqrt_x(f)` pair for a ¬flag (FALSE-successor / else) arm — the SAME
  //    bracket `emitRoute` puts around a negated route, so the two spellings of
  //    "fires on ¬f" cannot drift.
  //
  //    ORDER: `IRBuilder` inserts before `BI` in creation order and
  //    `moveBefore(BI)` lands in the same slot, so `x; T; x` comes out in that
  //    order. Do NOT re-mint `T` — moving it keeps its `!dbg`, its identity in
  //    `taint.ThetaCalls`, and its operand USE (so the later RAUW-to-handle
  //    rewrites it like every other gate).
  FunctionCallee X = csyms.xFn();
  for (auto &G : Gates) {
    if (G.second)
      stamp(B.CreateCall(X, {Flag}));
    G.first->moveBefore(BI);
    taint.ControlledRotations[G.first] = Flag;
    if (G.second)
      stamp(B.CreateCall(X, {Flag}));
  }

  // 3. Flag strip + free — byte-identical to the phase path's steps 7-8. Reads
  //    `Cond`'s operands, so it MUST precede the erase of `Cond` (in
  //    `flattenRegion`).
  //
  //    RECORDED as a DISCHARGED FLAG GATE, and the licence is R4, named: the
  //    phase path records its strip because its route restores `Q`'s basis label
  //    as a group, so an interior `_unc` placed after the strip reads the wire
  //    its forward chain read. This path has no route AND deliberately DOES
  //    relabel its base — but only its base, and R4 proved that rail is disjoint
  //    from every rail the condition's derived chain lives on. So the same
  //    property holds for the same reason, by a different argument. If R4 is
  //    ever widened, THIS recording is one of the things that must be re-proved.
  auto *Strip = dyn_cast_or_null<CallInst>(
      lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                         /*before=*/BI, /*negate=*/false, /*railToStrip=*/Flag));
  if (Strip)
    taint.DischargedFlagGates.insert(Strip);
  stamp(B.CreateCall(wd.freeFn(), {Flag}));

  // 4. Rewire + erase + scrub, then flatten. The merge φ now denotes the base
  //    register itself — BOTH incomings name the ONE physical rail, exactly as
  //    for a phase arm; what differs is that this rail has been RELABELLED on
  //    the `f=1` branch, which is why R6 refuses any pre-region SSA record of it
  //    that is read after the region. The hoisted thetas are NOT erased here:
  //    they are live instructions in the pred that `lowerRotations` owns.
  MergePhi->replaceAllUsesWith(Base);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  flattenRegion(R, taint);
}

// Lower one accepted phase-arm region — a one-content-arm DIAMOND (§5a) or a
// two-arm IF/ELSE (§5b) — to the coherent swap-route stream, emitted into the
// pred block before the conditional `br`. Both shapes share ONE emission
// procedure parameterized by the arm list: a diamond routes its single content
// arm (Q = the straight-through incoming); an if/else routes BOTH arms to
// DISTINCT |0> rails (Q = the shared phase-spine base), the true arm under flag
// and the false arm under ¬flag via the self-inverse `cqrt_x` bracket. The join
// is the literal adjoint of the split (the SAME cswap-pairs, same flag) — RSSA's
// "phi on both splits and joins" (SCOPING §2).
void emitRegion(const ControlRegion &R, WidthDispatch &wd,
                ControlledSymbols &csyms, TaintSet &taint) {
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  auto *MergePhi = dyn_cast_or_null<PHINode>(R.Merge);
  if (!Cond || !MergePhi || !R.Pred || !R.Arm) {
    // Detection guarantees the shape; if it ever fails to hold, bail LOUDLY — a
    // silently skipped accepted region leaves the tainted `br` to the backend
    // as classical control over quantum state (the unforgivable outcome,
    // Rule 1). Anchor on whatever instruction is still available.
    if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
      diagnoseUnderControl(A, "control flow");
    else if (R.Merge)
      diagnoseUnderControl(R.Merge, "control flow");
    return;
  }
  auto *BI = dyn_cast<BranchInst>(R.Pred->getTerminator());
  if (!BI) {
    diagnoseUnderControl(Cond, "control flow");  // loud, never a silent skip.
    return;
  }

  // Arm list + per-arm polarity. A diamond has one content arm whose polarity
  // rides `R.ArmNegated` (clang -O1 may make the gate arm the FALSE successor,
  // Rule 9). An if/else has two arms assigned by successor: `R.Arm` (S0) fires on
  // flag (unbracketed), `R.ArmFalse` (S1) on ¬flag (X-bracketed) — the flag
  // equals the live branch condition, so this holds under any predicate
  // canonicalization (clang may flip the predicate but the flag tracks it).
  SmallVector<ArmInfo, 2> Arms;
  if (R.ArmFalse) {
    Arms.push_back({R.Arm, /*Negated=*/false});
    Arms.push_back({R.ArmFalse, /*Negated=*/true});
  } else {
    Arms.push_back({R.Arm, R.ArmNegated});
  }

  // 4.2 VALUE path (method-B, §4/§5d/§5e): classifyArms recorded the per-arm
  // class + ordered chain (Shadow/ShadowFalse, FORWARD order — by FIELD
  // identity: for an orientation-B diamond R.Arm is the FALSE successor and
  // polarity rides ArmNegated). This dispatch MUST precede the phase-stream
  // collection: a value arm has no cq_phi gates, so falling through would hit
  // the identity-region RAUW — a verify-clean silent wrong answer. The value
  // emitter validates the plan shape and derives its own routed handle (an
  // if/else merge has no Pred edge to read it from).
  if (R.ClassArm == ArmClass::Value || R.ClassArmFalse == ArmClass::Value) {
    emitValueRegion(R, BI, Cond, MergePhi, wd, csyms, taint);
    return;
  }

  // CONTROL-IN-PLACE ROTATION path (control-in-place-PRD §6, bd
  // test_C_libtooling-drbq Inc 1). Dispatched HERE for the same reason the value
  // path is: a rotation arm has no `cq_phi` gates, so falling through to the
  // phase-stream collection would find an empty stream and hit the
  // identity-region RAUW — a verify-clean silently WRONG answer (the arm's Ry
  // would be dropped and the merge rewired to the untouched base).
  if (R.ClassArm == ArmClass::InPlaceRotation ||
      R.ClassArmFalse == ArmClass::InPlaceRotation) {
    emitInPlaceRotationRegion(R, BI, Cond, MergePhi, Arms, wd, csyms, taint);
    return;
  }

  // The routed handle Q: a diamond's straight-through (Pred-edge) incoming, or —
  // for an if/else, which has no Pred edge — the shared phase-spine base the arms
  // rotate. Never read width/identity off Q's SSA type (§4 width-source); Q is
  // only the cswap data operand.
  //
  // 4.5 WI-5 (eq-fold re-anchor): when `clang -O1` const-folds an `if(q==k)`
  // arm's gate base to the literal `k`, classifyArms recorded the PROVEN routed
  // handle in `R.RoutedBase` — PREFER it. The eq-fold IF/ELSE has no Pred edge
  // AND its first arm's `phaseSpineBase` bottoms at the folded constant `k`, so
  // the default derivation would route (and RAUW the merge to) a CONSTANT — a
  // verify-clean wrong unitary (the measure-operand guard only catches it when
  // the merge happens to feed a measure; an escaping merge would miscompile
  // silently). `R.RoutedBase` is null for every non-eq-fold region, so the
  // default path below is byte-identical there.
  //
  // ⚠ `RoutedBase` IS A `WeakTrackingVH` and it may be null for TWO different
  // reasons (round-1 Rule-13 review L4 §1, a CONFIRMED SIGSEGV). Never recorded
  // ⇒ derive, as before. RECORDED AND SINCE ERASED ⇒ the handle this region was
  // proven to route no longer exists, and falling through to the derivation
  // would route the folded constant — exactly the miscompile this field
  // prevents. That case declines LOUDLY. (Before the handle, a raw `Value *`
  // here was simply DEREFERENCED after the earlier region's
  // `MergePhi->eraseFromParent()`, which is the crash.)
  //
  // ⚠ AN UNFIXTURABLE BACKSTOP — KEEP IT, and here is why it cannot have a
  // Rule-12 fixture and why the NULL test is nonetheless the RIGHT test (bd drbq
  // round-2 review, lens C §4, which set out to refute it and failed). Every way
  // a `WeakTrackingVH` can go null was enumerated:
  //   * every merge-φ collapse RAUWs BEFORE erasing (this file's four sites,
  //     `RegionFlatten`, `SelectMergeEmit`, `ClassicalCallArmEmit`,
  //     `SwitchRouteEmit`, `SwitchValueEmit`, `SwitchDataMuxEmit`), so the handle
  //     MOVES and never nulls;
  //   * the erase-WITHOUT-RAUW sites are the condition compare — all
  //     `use_empty`-guarded, and a routed base is never a compare anyway (the
  //     eq-fold records the compare's OPERAND) — and the arm/`Mid` BLOCK erases.
  //     A value defined in an arm block dominates nothing outside it (its only
  //     successor is a 2-predecessor merge) so it cannot be another region's
  //     routed base, and a nested pair's in-`Mid` derivation is declined outright
  //     by `RegionTreeDetect`'s `RailClosure` gate.
  // The one thing that looked like a hole and is not: a block erase does NOT
  // leave the handle pointing at `poison`. `BasicBlock::eraseFromParent()`
  // destroys each contained `Instruction` through `Value::~Value()`, which calls
  // `ValueHandleBase::ValueIsDeleted` and NULLS a `WeakTracking` handle — so a
  // corpse cannot slip past a null test. (`Utils`' `DeleteDeadBlock` is the
  // RAUW-to-poison path, and it is not what runs here.)
  // Precedent for a kept, unfixturable backstop: `lowerControlRegions`' Kahn
  // cycle decline.
  if (R.RoutedBaseRecorded && !R.RoutedBase) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }
  Value *Recorded = R.RoutedBase;
  Value *Q = Recorded ? Recorded
             : MergePhi->getBasicBlockIndex(R.Pred) >= 0
                 ? MergePhi->getIncomingValueForBlock(R.Pred)
                 : phaseSpineBase(MergePhi->getIncomingValueForBlock(R.Arm),
                                  R.Arm);

  // Per-arm ordered phase gates. A gate-free arm (`if (q) {}`, or an empty else)
  // contributes Q unchanged, so routing it would be a no-op cswap pair — skip it
  // (no rail, no route). `AllPhis` collects every gate to scrub + erase after the
  // rewire.
  SmallVector<ArmStream, 2> Streams;
  SmallVector<CallInst *, 8> AllPhis;
  for (const ArmInfo &A : Arms) {
    SmallVector<CallInst *, 4> Phis =
        collectArmPhis(MergePhi->getIncomingValueForBlock(A.BB), A.BB);
    if (Phis.empty())
      continue;
    AllPhis.append(Phis.begin(), Phis.end());
    Streams.push_back({A.Negated, Phis});
  }

  // Identity region — every arm is gate-free (`if (q) {}` diamond, or an
  // empty/empty if/else): there is no quantum op to control. The merge phi is
  // just Q on every edge; RAUW it to Q and flatten the dead CFG. No flag, no
  // rail, no strip — and no rotation width needed for a gate-free region.
  if (Streams.empty()) {
    MergePhi->replaceAllUsesWith(Q);
    scrubTaint(MergePhi, taint);
    MergePhi->eraseFromParent();
    flattenRegion(R, taint);
    return;
  }

  // ABI width from the FIRST gate's `cq_phi` suffix — the rotation width (all
  // arms rotate the same-width routed handle, by classifyArms). The routed handle
  // MAY be a value DERIVED before the region (its own suffix is unreliable), so
  // never read width off Q (§4 width-source).
  StringRef Abi =
      wd.abiWidthFor(intrinsicSuffix(Streams.front().Phis.front(), "cq_phi_"));
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Rz = Abi.empty() ? FunctionCallee() : wd.rzRtFn(Abi);
  if (!RailTy || !Alloc || !Rz) {
    // Unsupported width past detection — decline LOUDLY (a silent leave-in-
    // place would hand the tainted `br` to the backend as classical control
    // while the later rotation lowering fires the arm gates unconditionally).
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  const DebugLoc DL = BI->getDebugLoc();
  IRBuilder<> B(BI);  // every stream call lands before the conditional br.

  // 1. Flag mint — cq_template_icmp_<pred>_<W>_hl(q, lit). On the ziov share path
  //    (R.ShareCondFlag — the condition is ALSO read as data) the flag is minted
  //    at the COMPARE's position so it DOMINATES every data use (a data `zext` may
  //    precede the routed stream); otherwise it lands at the branch as before.
  Instruction *FlagAt = R.ShareCondFlag ? Cond->getNextNode() : BI;
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/FlagAt);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).

  // ziov WI-1: share THIS flag with the data use. Record it (do NOT RAUW) so
  // `lowerOps`'s rewriteCompare REUSES it for the surviving data-position compare
  // instead of minting a SECOND flag (the ziov bug). Recording — not RAUWing here
  // — defers the i1→i32 launder to lowerOps Phase 2, AFTER Phase 1 captures the
  // data casts' i1 source width (RAUWing now would corrupt `zext i1→i32` into a
  // templateless `zext i32→i32`). The eager strip+free (steps 7-8) is SKIPPED
  // below: the data lineage owns the handle (escaped/measured, classifyArms-
  // proven) — stripping/freeing it is a read-after-collapse / hidden measurement.
  if (R.ShareCondFlag)
    taint.SharedCondFlags[Cond] = Flag;

  // 2. One |0> work rail per content arm (allocated up front — the §5b order).
  SmallVector<Value *, 2> Rails;
  for (size_t I = 0; I < Streams.size(); ++I) {
    CallInst *Rail =
        B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "rail");
    if (DL)
      Rail->setDebugLoc(DL);
    Rails.push_back(Rail);
  }

  // 3. Route-in (split) — q -> each rail, X-bracketed for a ¬flag arm.
  //
  //    Every cswap on `Q` this region emits is collected into ONE
  //    `TaintSet::RestoringRoute` group (M-B Increment 6, clause (d2)). The claim
  //    the group makes is narrow and provable: executing the WHOLE group leaves
  //    `Q`'s BASIS LABEL exactly as it found it, because step 5 replays the SAME
  //    cswaps under the SAME flag (RSSA "the join is the adjoint of the split")
  //    and, in the if/else shape, at most one arm's swap fires per branch so the
  //    two pairs commute. The Rz between them is DIAGONAL and lands on a work
  //    RAIL, never on `Q`.
  //
  //    IT IS THE GROUP, NOT THE GATE, THAT RESTORES. One half of a pair leaves
  //    `Q` holding |0> (or the arm's copy) depending on the flag — which is why
  //    the consumer proves every member is inside its interval before it reads
  //    `Q` past the route. The method-B VALUE path records NOTHING: its
  //    route-back swaps in the arm's ANSWER, so it is not the adjoint of its
  //    split and `Q`'s label genuinely changes.
  SmallVector<const CallInst *, 4> Route;
  for (size_t I = 0; I < Streams.size(); ++I)
    Route.push_back(emitRoute(B, csyms, Flag, Q, Rails[I], Streams[I].Negated, DL));

  // 4. Arm bodies, VERBATIM and UNCONTROLLED, each on its OWN rail.
  for (size_t I = 0; I < Streams.size(); ++I)
    for (CallInst *Phi : Streams[I].Phis) {
      CallInst *RzCall = B.CreateCall(Rz, {Rails[I], Phi->getArgOperand(1)});
      if (DebugLoc PDL = Phi->getDebugLoc())
        RzCall->setDebugLoc(PDL);
    }

  // 5. Route-back (join = adjoint of the split, same flag + brackets).
  for (size_t I = 0; I < Streams.size(); ++I)
    Route.push_back(emitRoute(B, csyms, Flag, Q, Rails[I], Streams[I].Negated, DL));

  // ⚠ THE CONSUMER READS THE ROUTED BASE FROM ARG 1, POSITIONALLY (bd
  //   test_C_libtooling-160a Rule-13 round, finding F6). `Uncomputation::
  //   routeGroupFullyInside`'s HOMOGENEITY test — "every member of this group
  //   routes the SAME base the scan is reasoning about" — is
  //   `G->getArgOperand(1) == P`, and `cqrt_cswap(flag, a, b)` is PHYSICALLY
  //   SYMMETRIC in `a`/`b`: nothing in the runtime ABI distinguishes the base
  //   from the work rail. What makes the read safe is a CONVENTION with exactly
  //   one owner — THIS FUNCTION. `emitRegion` is the ONLY writer of
  //   `RestoringRoutes`, every member comes from `emitRoute`, and `emitRoute`
  //   always builds `{Flag, Q, Rail}` with the routed base in arg 1 (asserted
  //   below). A FUTURE EMITTER THAT RECORDS A GROUP WITH THE BASE IN ARG 2 MUST
  //   UPDATE BOTH SITES; recording one here without doing so would silently
  //   exempt a swap that moved some OTHER register into or out of `P`'s rail.
  //   (The work rail can never be mistaken for the base: it is a fresh
  //   `cqrt_alloc` minted at step 2 and never a template operand, so it is never
  //   a borrowed parent. The FLAG could only become one on the ziov share path,
  //   where the group's base `Q != Flag` makes homogeneity refuse anyway.)
  assert(llvm::all_of(Route,
                      [&](const CallInst *G) {
                        return G->arg_size() >= 2 &&
                               G->getArgOperand(1) == Q;
                      }) &&
         "RestoringRoutes convention: the routed base is cqrt_cswap arg 1");
  taint.RestoringRoutes.push_back(Route);

  // 6. Rail frees — each rail is |0> for free (Rz|0>=|0>); a clean reset, NOT a
  //    measurement (SCOPING §3b). No kept-carrier record reaches these rails or the
  //    flag freed at 8: both are minted here at |0>, adjointed here, and are never
  //    an operand of a tape write or a copy destination — this module mints none
  //    (bd urlv audit; the same reasoning as the value-arm note above).
  for (Value *Rail : Rails) {
    CallInst *RailFree = B.CreateCall(wd.freeFn(), {Rail});
    if (DL)
      RailFree->setDebugLoc(DL);
  }

  // 7-8. Flag strip + free — the eager ancilla cleanup. SKIPPED on the ziov
  //       share path (R.ShareCondFlag): the condition is also live as DATA, so
  //       the flag's last use is downstream (the escaped/measured data lineage
  //       owns it), NOT the route-back. Stripping here would return the flag to
  //       |0> before the data read (read-after-collapse); freeing it would be a
  //       hidden measurement. The data lineage is the flag's reclaimer
  //       (FreePoint → Escaped/Measured, no free). The only other case — a
  //       dead-within-function lineage — is declined upstream by classifyArms and
  //       stays declined: ziov.2 proposed a deferred strip there but it was closed
  //       won't-fix (a flag-ONLY strip leaves the data-copy rails entangled with
  //       q, a silent miscompile; see classifyArms' Unowned note). So on this
  //       share path the flag is NEVER stripped or freed here.
  if (!R.ShareCondFlag) {
    // 7. Flag strip — q == q0 (Rz preserves the basis value), so icmp_inv(q)
    //    returns the flag to |0> with zero controlled gates. Reads `Cond`'s
    //    operands, so it MUST precede the erase of `Cond` (in flattenRegion).
    //
    //    RECORDED as a DISCHARGED FLAG GATE (M-B Increment 6, clause (d2)). For
    //    the compare operands in its shifted handle slots this call is a pure
    //    READ — it recomputes the predicate and XORs it onto `Flag`, leaving
    //    every operand at its forward basis — so a DERIVED condition's
    //    provenance chain is dead the instant it returns. Recording it here lets
    //    `ChainWalk::isInteriorConsumer` count it as a consumer, which moves the
    //    interior partition's insertion point PAST this line and is the only
    //    place that chain may legally be uncomputed (before it, the strip would
    //    read freed rails; the whole `if (sqrt(a+3.0) <= 5.0)` shape leaked at
    //    Increment 5 for exactly that reason — bd 6uqc's P0).
    //
    //    THE PHASE PATH ONLY, and that is the fence. This emitter's route
    //    restores `Q`'s basis label as a group (step 3), so an adjoint placed
    //    after the strip reads the same wire the forward chain read. Recording a
    //    strip whose emitter does NOT have that property would place a discharge
    //    after a route that moved the base — a `_unc` reading the wrong basis.
    auto *Strip = dyn_cast_or_null<CallInst>(
        lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                           /*before=*/BI, /*negate=*/false,
                           /*railToStrip=*/Flag));
    if (Strip)
      taint.DischargedFlagGates.insert(Strip);

    // 8. Flag free.
    CallInst *FlagFree = B.CreateCall(wd.freeFn(), {Flag});
    if (DL)
      FlagFree->setDebugLoc(DL);
  }

  // 9. Rewire + erase + scrub, then flatten the CFG. The merge phi's value is now
  //    just `q` (a phase arm preserves q's basis identity), so a measure on the
  //    phi becomes a measure on q. Erase the arm cq_phi in REVERSE lineage order
  //    so each is use-empty when erased; scrub every erased instruction (§6.1).
  MergePhi->replaceAllUsesWith(Q);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  for (CallInst *Phi : reverse(AllPhis)) {
    scrubTaint(Phi, taint);
    Phi->eraseFromParent();
  }
  flattenRegion(R, taint);
}

}  // namespace

// Walk the arm's merge contribution back along its IN-BLOCK phase spine,
// collecting the `@cq_phi` (Rz) calls DEFINED IN `ArmBB` in FORWARD program order
// (first gate applied first). The chain is `qN = cq_phi(q{N-1}, angle)`; the
// back-walk hops arg-0 handles, so reversing it yields forward order. An empty
// result means a degenerate gate-free arm (`if (q) {}` / an empty else / a
// gate-free `Mid`) — handled by the caller.
//
// The walk STOPS at the arm-block boundary: a `cq_phi` defined OUTSIDE `ArmBB` is
// a pre-region rotation — the live DERIVED base handle the region ROUTES
// (accepted since test_C_libtooling-9hh), NOT an arm gate. It stays in
// `taint.PhiCalls`, so `lowerRotations` lowers it as an ordinary unconditional
// Rz at its own (pre-stream) position and RAUWs it to the same i32 handle as its
// theta. Bounding here is load-bearing (Rule 10): an unbounded walk would
// collect a pre-region phi SHARED by both arms once per arm, and the §6.1
// reverse-erase would double-free it (SIGSEGV — the WI-3 crash). Keeping the
// per-arm gate list strictly in-block makes that impossible. De-anonymized
// (named `cq`, declared in the header) so `NestedRouteEmit` reuses it per level.
SmallVector<CallInst *, 4> collectArmPhis(Value *ArmIncoming,
                                          const BasicBlock *ArmBB) {
  SmallVector<CallInst *, 4> Phis;
  for (Value *V = ArmIncoming; isPhiCall(V);) {
    auto *CI = cast<CallInst>(V);
    if (CI->getParent() != ArmBB)
      break;  // pre-region cq_phi — the derived base handle, not an arm gate.
    Phis.push_back(CI);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  std::reverse(Phis.begin(), Phis.end());
  return Phis;
}

// Emit the route swap `cqrt_cswap(flag, q, rail)`, X-bracketed for an ArmNegated
// (¬flag / FALSE-successor) arm: `cqrt_x(flag); cqrt_cswap(…); cqrt_x(flag)`.
// Used identically for the route-in (split) and the route-back (join = adjoint
// of the split, same flag) — that symmetry is the RSSA join-is-the-inverse-of-
// the-split property (SCOPING §2). De-anonymized (named `cq`, declared in the
// header) so `NestedRouteEmit` routes both nest levels through the SAME bracket
// logic (a drift in the ¬flag polarity here would be a silent miscompile).
CallInst *emitRoute(IRBuilder<> &B, const ControlledSymbols &csyms, Value *Flag,
                    Value *Q, Value *Rail, bool Negated, const DebugLoc &DL) {
  FunctionCallee Cswap = csyms.cswapFn();
  FunctionCallee X = csyms.xFn();
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  if (Negated)
    stamp(B.CreateCall(X, {Flag}));
  // The ONE gate on the routed base `Q`. The X brackets are on the FLAG, so a
  // caller collecting a `RestoringRoute` group over `Q` wants exactly this call
  // and not the brackets (M-B Increment 6).
  CallInst *Swap = stamp(B.CreateCall(Cswap, {Flag, Q, Rail}));
  if (Negated)
    stamp(B.CreateCall(X, {Flag}));
  return Swap;
}

void lowerControlRegions(Module &M, WidthDispatch &wd, TaintSet &taint,
                         const ControlPlan &plan) {
  if (plan.Regions.empty())
    return;  // nothing accepted — classical / fully-declined module untouched.

  const auto &Regions = plan.Regions;

  // A coordinated parent/child pair (a Depth-N region and its Depth-(N+1) child,
  // linked by `ParentIdx`) DELIBERATELY shares blocks: the 4.3 nest's Outer and
  // Inner share `MergeBB` and `Outer.Arm == Inner.Pred` (§0 criterion 1).
  // `NestedRouteEmit` tears the pair down together (one shared-merge erase), so
  // the cross-region pre-flight below must EXEMPT such a pair while staying active
  // for genuinely independent / sequential regions (blocker MD0).
  auto coordinated = [&](size_t a, size_t b) {
    const ControlRegion &A = Regions[a], &B = Regions[b];
    return (B.Depth == A.Depth + 1 && B.ParentIdx == a) ||
           (A.Depth == B.Depth + 1 && A.ParentIdx == b);
  };

  // The blocks a region's flatten actually ERASES (its "doomed" set) — what the
  // pre-flight below must protect from another region's references. iw81.7/g5gi: a
  // `GuardedStoreArm` flatten erases ONLY its `Arm` block (it splices the gep+store
  // into `Pred` and rewires `Pred → MergeBB` unconditionally — `MergeBB` and `Pred`
  // SURVIVE, unlike the phase / if-else flatten which erases `MergeBB`). So a
  // guarded store's genuine doomed set is `{Arm}`, NOT `{Arm, ArmFalse, MergeBB}` —
  // exempting `MergeBB` is what un-blocks two guarded diamonds sharing a block (the
  // first's `MergeBB` is the second's `Pred`; PRD-g5gi §2). The exemption is
  // KIND-scoped: every OTHER region kind keeps `{Arm, ArmFalse, MergeBB}`, so a
  // guarded region whose `Pred` is a PHASE region's (really-erased) merge still
  // declines — the protection is intact in that direction (defense-in-depth).
  auto doomedBlocks = [&](const ControlRegion &R) {
    SmallVector<BasicBlock *, 3> Doomed;
    Doomed.push_back(R.Arm);
    if (R.Kind != ControlRegion::GuardedStoreArm) {
      Doomed.push_back(R.ArmFalse);
      Doomed.push_back(R.MergeBB);
    }
    return Doomed;
  };

  // Does region `i` own a coordinated Depth-(N+1) child (the 4.3 nest)?
  auto hasChild = [&](size_t i) {
    for (size_t j = 0; j < Regions.size(); ++j)
      if (Regions[j].Depth == Regions[i].Depth + 1 && Regions[j].ParentIdx == i)
        return true;
    return false;
  };

  // The SEQUENTIAL-CHAIN alias (bd hcrg) — the one block alias that emission
  // ORDER can resolve, and the only one this function is allowed to accept.
  //
  // `if (q){…} …; if (q'){…}` is, after clang -O1, two flat regions where the
  // FIRST one's merge block hosts the SECOND one's conditional branch — i.e.
  // `A.Pred == B.MergeBB` with B the earlier region. That alias used to be a
  // detection-time decline (`nested control flow`) because `flattenRegion`
  // splices B's merge into B's pred and ERASES it, dangling A's `Pred` pointer:
  // a use-after-free, SIGSEGV on valid input (§8 adversarial review 2026-06-10).
  //
  // Nothing about that is semantic — it is a teardown-ORDER bug. Emit A FIRST
  // and it cannot arise: A's blocks are all still live (B's flatten has not run),
  // A's own flatten erases only {A.Arm, A.ArmFalse, A.MergeBB} — none of which is
  // any block of B — and A's tail is spliced into A.Pred, which IS B's merge and
  // SURVIVES its own flatten by construction (`flattenRegion` never erases a
  // Pred). B then flattens with every one of its blocks intact, carrying A's
  // already-emitted stream along in the splice. Program order of the emitted
  // gates is unaffected: each emitter inserts POSITIONALLY into its own pred
  // block, so B's stream still precedes A's in the final linear block.
  //
  // The predicate is deliberately narrow — the chain shape and nothing else:
  // both regions flat, childless, Depth-0 `BranchRegion`s, and `A.Pred ==
  // B.MergeBB` must be the ONLY block A shares with B's doomed set. A genuine
  // OVERLAP (two regions sharing an arm or a merge) is not reorderable and keeps
  // declining below, as does anything involving a nest, a switch, a select or any
  // other kind. Over-declining is always safe (Prime Directive); this widens the
  // accept set by exactly one proven shape.
  //
  // STRUCTURAL LEMMA (bd hcrg Rule-13 clearance, block-lifetime lens): among
  // `BranchRegion`s, `A.Pred == B.MergeBB` is the ONLY block alias that can
  // occur at all, so the "…and nothing else" loop below is defence-in-depth over
  // a provably empty space. Three facts, each read off the recognizers:
  //   1. A `Pred` ends in a CONDITIONAL br, and every recognizer in
  //      `recoverRegion` requires `uncondSucc(arm)` non-null ⇒ `A.Pred` can never
  //      be `B.Arm`/`B.ArmFalse`. (Same for the other kinds: an `AbortPark` arm
  //      ends in `unreachable`, a `GuardedStoreArm`/`ClassicalCallArm` arm in an
  //      unconditional br.)
  //   2. A merge has exactly TWO predecessors (`soleMergePhi` demands a
  //      2-incoming phi, and a phi must list every pred) while an arm has exactly
  //      ONE (`getSinglePredecessor() == Pred`) ⇒ an arm and a merge are never
  //      the same block, in either direction.
  //   3. Two distinct `BranchRegion`s cannot SHARE a `MergeBB`: its pred set is
  //      `{Pred, Arm}` or `{Arm, ArmFalse}`, and equality forces either the same
  //      `Pred` (hence the same terminator, hence the same region) or an arm
  //      ending in a conditional br, which (1) excludes.
  // The loop stays because the lemma is a property of TODAY's recognizers: a
  // future shape that relaxes any of the three must fail this predicate LOUDLY
  // rather than silently acquire a reorder it was never cleared for.
  //
  // KNOWN AND ACCEPTED, worth writing down before someone rediscovers it in a
  // trace (bd hcrg Rule-13 clearance, unitary lens): a chain of VALUE (method-B)
  // regions stacks ONE B-keep leftover PER REGION — each region's copied-out
  // `%out` plus its source rail stay allocated and entangled with the answer.
  // Every region is individually correct and `free_pairing_check.py` is clean on
  // the chain (Rule 6 leaves a not-provably-|0> rail ALLOCATED rather than
  // freeing it dirty), but the leak is now linear in chain length where before
  // it was capped at one, because chained value arms used to decline outright.
  // Qubits are not scarce in this regime (PRD §8.2); if that ever changes, this
  // is the shape to revisit first.
  auto sequentialChainAlias = [&](size_t ai, size_t bi) {
    const ControlRegion &A = Regions[ai], &B = Regions[bi];
    if (A.Kind != ControlRegion::BranchRegion ||
        B.Kind != ControlRegion::BranchRegion)
      return false;
    if (A.Depth != 0 || B.Depth != 0 || hasChild(ai) || hasChild(bi))
      return false;
    if (!A.Pred || !B.MergeBB || A.Pred != B.MergeBB)
      return false;
    // …and NOTHING else of A's aliases a block B's flatten will erase.
    for (BasicBlock *Doomed : doomedBlocks(B)) {
      if (!Doomed)
        continue;
      if (A.Arm == Doomed || A.ArmFalse == Doomed || A.MergeBB == Doomed)
        return false;  // a real overlap, not a chain.
      if (A.Pred == Doomed && Doomed != B.MergeBB)
        return false;  // A's pred aliases an ARM — not the chain shape.
    }
    return true;
  };

  // Fail-loud decline shared by the overlap and cycle paths below.
  // INVARIANT (WI-5 §8 review, NIT — keep this path fail-loud): every region
  // recovered today sets BOTH `Condition = BI->getCondition()` (an Instruction)
  // AND `Merge` (a PHINode), so one of the two diagnose arms ALWAYS fires — this
  // never silently skips a tainted br (Rule 1). A FUTURE region kind that leaves
  // both null (e.g. a synthesized flag-combination Value) MUST add a fallback
  // diagnostic here (anchor on a region block's terminator); a bare return past
  // both arms would be a silent accept of quantum-controlled flow — the one
  // unforgivable bug (Prime Directive).
  auto declineRegion = [&](const ControlRegion &A) {
    if (auto *Anchor = dyn_cast_or_null<Instruction>(A.Condition))
      diagnoseUnderControl(Anchor, "control flow");
    else if (A.Merge)
      diagnoseUnderControl(A.Merge, "control flow");
  };

  // Pre-flight + emission order, computed while EVERY region's blocks are still
  // valid (the block-lifetime rule): no accepted region may be emitted AFTER
  // another (non-coordinated) accepted region has erased a block it names
  // (Arm/ArmFalse/MergeBB). Every such alias is either resolved by ordering (the
  // proven sequential chain above) or declined LOUDLY here — never dereferenced
  // in emitRegion (the §8-confirmed sequential-region SIGSEGV family,
  // 2026-06-10). Pointer-identity checks only; nothing is dereferenced.
  //
  // `Precedes[a]` lists the regions that must be emitted AFTER `a`; `Pending[b]`
  // counts how many regions must be emitted BEFORE `b`.
  const size_t N = Regions.size();
  SmallVector<SmallVector<size_t, 2>, 8> Precedes(N);
  SmallVector<unsigned, 8> Pending(N, 0);
  for (size_t a = 0; a < N; ++a)
    for (size_t b = 0; b < N; ++b) {
      if (a == b || coordinated(a, b))
        continue;
      const ControlRegion &A = Regions[a], &B = Regions[b];
      bool Aliases = false;
      for (BasicBlock *Doomed : doomedBlocks(B)) {
        if (!Doomed)
          continue;
        if (A.Pred == Doomed || A.Arm == Doomed || A.ArmFalse == Doomed ||
            A.MergeBB == Doomed)
          Aliases = true;
      }
      if (!Aliases)
        continue;
      if (!sequentialChainAlias(a, b)) {
        declineRegion(A);
        return;  // lower NOTHING — over-declining is always safe.
      }
      Precedes[a].push_back(b);  // A names a block B's flatten erases → A first.
      ++Pending[b];
    }

  // Kahn topological order. Ties break on plan index, so a module with no alias
  // at all keeps the exact plan order it has always had (`Pending` all zero →
  // `Order` == 0,1,2,…): this reordering is INERT for every shape that lowered
  // before — which is why the whole 241-golden e2e layer is byte-identical
  // across this change. Each ordered pair contributes AT MOST ONE edge (the
  // `Aliases` flag is a bool, not a counter), so `Pending` cannot underflow and
  // `Done` cannot admit a region twice.
  //
  // A cycle (mutual aliasing that no order can satisfy) leaves regions
  // unscheduled — decline loudly rather than pick one and dereference the other.
  // UNREACHABLE TODAY, DELIBERATELY KEPT, AND IT CANNOT BE GIVEN A FIXTURE (bd
  // hcrg Rule-13 clearance): a precedence cycle needs `A.Pred == B.MergeBB`
  // transitively back to `A`, which IS a CFG cycle through the region entries —
  // and `regionEntryInLoop` declines every flat region on a cycle at DETECTION,
  // before the plan is built (`control_swap_reject_seq_in_loop.ll`). So no input
  // can exercise this branch while that guard stands. Do not delete it as dead
  // code: it is the backstop for the day the loop guard is narrowed, and a bare
  // fall-through here would emit a partial region set over freed blocks.
  SmallVector<size_t, 8> Order;
  Order.reserve(N);
  SmallVector<bool, 8> Done(N, false);
  for (bool Progress = true; Progress;) {
    Progress = false;
    for (size_t i = 0; i < N; ++i)
      if (!Done[i] && Pending[i] == 0) {
        Done[i] = true;
        Order.push_back(i);
        for (size_t j : Precedes[i])
          --Pending[j];
        Progress = true;
      }
  }
  if (Order.size() != N) {
    for (size_t i = 0; i < N; ++i)
      if (!Done[i]) {
        declineRegion(Regions[i]);
        return;  // lower NOTHING — over-declining is always safe.
      }
  }

  ControlledSymbols csyms(M, wd);
  // Emit. A Depth-0 region with a coordinated Depth-1 child is the proven depth-2
  // nest — dispatch BOTH to `NestedRouteEmit::lowerNestedRegion` (it consumes +
  // flattens the child too), and SKIP the child in this loop: re-visiting a
  // Depth>0 region would dereference erased blocks (blocker MD4). `plan.Regions`
  // is already outer→inner (detection pushes Outer before Inner, §3.1), so no sort
  // is needed (the plan is `const`, COMPLETENESS#7). A flat (Depth-0, childless)
  // region takes the unchanged `emitRegion` path.
  // Iterate the ORDER computed above, not the plan order — `i` stays the real
  // plan index so the `ParentIdx` child lookup below is unaffected.
  for (size_t i : Order) {
    const ControlRegion &R = Regions[i];
    if (R.Kind == ControlRegion::SelectRegion) {
      // 4.4 — a tainted-condition integer-data select: the controlled-XOR copy
      // merge (no CFG diamond, no rail/route, no child nest). Its block fields
      // are all null, so the pre-flight above treated it as inert (the
      // `if (!Doomed) continue;` guard). Dispatch + continue BEFORE the Depth /
      // child-lookup branch, which keys on null CFG anchors.
      emitSelectRegion(R, wd, csyms, taint);
      continue;
    }
    if (R.Kind == ControlRegion::SwitchRegion) {
      // 4.5 — a tainted-condition `switch`. Its Pred (switch block) + MergeBB are
      // set, so the pre-flight above covered the shared merge; the case-arm blocks
      // are single-pred(switch) (resolveArm) and so cannot alias another region's
      // Pred/Arm/Merge, so leaving them out of the pre-flight is safe (§6.4
      // decision (a) — treat like select). Dispatch by content class BEFORE the
      // Depth / child-lookup branch (a switch carries no `ParentIdx` nest link).
      if (R.SwitchCls == SwitchClass::Phase) {
        emitSwitchPhaseRegion(R, wd, csyms, taint);
      } else if (R.SwitchCls == SwitchClass::Value) {
        // 4.5 WI-3 — homogeneous value-chain switch: the N-way method-B over the
        // shared routed base `p` = the merge default-edge incoming (`p != q`).
        emitSwitchValueRegion(R, wd, csyms, taint);
      } else if (R.SwitchCls == SwitchClass::DataMux) {
        // 4.5 WI-4 — all-ConstantInt data-mux: PRELOAD %out=cqrt_alloc(v_d) +
        // per content case the XOR-delta controlled copy (no route, no ¬-bracket;
        // the default is the preload). IMPLEMENTATION-4.5 §4C.
        emitSwitchDataMuxRegion(R, wd, csyms, taint);
      } else {
        // An unknown future SwitchClass — never silently skip a tainted switch
        // (Prime Directive): bail LOUDLY.
        if (auto *Anchor = dyn_cast_or_null<Instruction>(R.Merge))
          diagnoseUnderControl(Anchor, "control flow");
        else if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
          diagnoseUnderControl(A, "control flow");
      }
      continue;
    }
    if (R.Kind == ControlRegion::AbortPark) {
      // 7.2 Inc 3 — abort/exit park cascade: mint the flag, `cqrt_cswap` the
      // routed handle into a KEPT graveyard rail (self-bracketed), record the
      // abort flag on the tape, and run the sibling/downstream UNCONTROLLED. Its
      // Pred/Arm/Condition are set (Merge/MergeBB/ArmFalse null — the sink arm has
      // nothing to merge and the sibling SURVIVES), so the cross-region pre-flight
      // above covered the sole doomed block (the sink Arm) and the non-null
      // Condition kept its diagnose arm live. No nest link — dispatch + continue
      // BEFORE the Depth / child-lookup branch (which keys on CFG anchors).
      emitAbortParkRegion(R, wd, csyms, taint);
      continue;
    }
    if (R.Kind == ControlRegion::GuardedStoreArm) {
      // iw81.7 — a tainted-index Shadow store inside a tainted-condition diamond
      // arm: mint the path-predicate flag, record (store→flag), FLATTEN the diamond
      // (splice the gep+store into Pred, rewire straight to the merge), leave the
      // flag LIVE. `lowerShadowMemory` then emits the guarded store; the whole-DAG
      // LIFO uncompute reverses it (`..._controlled_unc`) and strips the flag. Its
      // Pred/Arm/MergeBB are set (a real diamond), so the cross-region pre-flight
      // above covered the block-lifetime hazard. No nest link — dispatch + continue
      // BEFORE the Depth / child-lookup branch.
      emitGuardedStoreArmRegion(R, wd, taint);
      continue;
    }
    if (R.Kind == ControlRegion::ClassicalCallArm) {
      // 6.5 (DD-7) — a pure classical call inside a tainted-condition diamond
      // arm: hoist the call into Pred, then the 4.4-style controlled-copy merge
      // over the FLATTENED diamond (no clone, no cswap/route, no reverse-play).
      // Its Pred/Arm/MergeBB are set (a real diamond), so the cross-region
      // pre-flight above already covered the block-lifetime hazard (WI-5.8). It
      // carries no `ParentIdx` nest link, so dispatch + continue BEFORE the
      // Depth / child-lookup branch.
      emitClassicalCallArmRegion(R, wd, csyms, taint);
      continue;
    }
    if (R.Depth > 0)
      continue;  // a nested child — owned by its parent's dispatch.
    const ControlRegion *Child = nullptr;
    for (size_t j = 0; j < Regions.size(); ++j)
      if (Regions[j].Depth == R.Depth + 1 && Regions[j].ParentIdx == i) {
        Child = &Regions[j];
        break;
      }
    if (Child)
      lowerNestedRegion(R, *Child, wd, csyms, taint);
    else {
      // bd test_C_libtooling-8h7d.5 — record the SURVIVING `Pred` of an in-loop
      // region BEFORE `emitRegion` runs (it ends in `flattenRegion`, which
      // erases `Arm`/`MergeBB` but never a `Pred`). This is the sole trigger
      // for the round-2 rail collapse (`collapseFlattenedLoopRails`); a module
      // with no in-loop region records nothing and is byte-identical.
      if (R.InLoop)
        taint.InLoopFlattenedPreds.insert(R.Pred);
      emitRegion(R, wd, csyms, taint);
    }
  }
}

}  // namespace cq
