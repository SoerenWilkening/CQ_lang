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
#include "ArmAnalysis.h"         // phaseAngleTail (3qlq Inc 1 merge-tail angle phi)
#include "CondTreeEmit.h"        // emitCondNetwork / stripCondNetwork (3qlq P3)
#include "SelectClassify.h"      // CondTree / collectCondTree (the shared grammar)
#include "ArithLowering.h"       // rewriteBinary (the value-arm chain body, §4)
#include "AngleSelectEmit.h"     // emitAngleSelectRegion (drbq Inc 2b)
#include "CompareLowering.h"     // lowerCompareToFlag
#include "ClassicalCallArmEmit.h" // emitClassicalCallArmRegion (the 6.5 merge)
#include "GuardedStoreArmEmit.h"  // emitGuardedStoreArmRegion (iw81.7)
#include "ControlPlan.h"         // ControlRegion / ControlPlan
#include "ControlledSymbols.h"   // cswapFn / xFn
#include "EmitInverse.h"         // emitInverseChain (the value-arm reverse-play)
#include "NestedRouteEmit.h"     // lowerNestedRegion (the depth-2 nest dispatch)
#include "OpcodeSupport.h"       // abiWidthFromType · abiWidthHasControlledRotation
#include "RegionFlatten.h"   // flattenRegion / flattenRegionTree       // flattenRegion
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
    // (Since drbq Inc 2a this module records only `DischargedFlagGates`: the
    // phase path emits no route, so `RestoringRoutes` has no writer anywhere and
    // the loop below is a no-op over an empty container. Kept for the same reason
    // the set is — three other emitters still call `emitRoute` and any of them
    // could start recording; see `Uncomputation::routeGroupFullyInside`.)
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

// ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 (2026-09-05), AND DELIBERATELY
// KEPT (PRD `retire-swap-route-PRD.md` §6.2 row P6: "every 'Rz is diagonal and
// exempt' clause becomes VACUOUS rather than deleted").
//
// The 15-width `@cq_phi_<sfx>(x, angle)` family is RETIRED: `CQ.h` no longer
// declares it and `resolveSources` no longer resolves it, so no call this
// predicate can match exists in a module the pass lowers. It CANNOT accidentally
// match the register-free replacement, and that is a fact about the strings, not
// a hope: `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE — six characters
// against a seven-character prefix. The new call is recognized by EXACT
// membership instead (`TaintPropagation.h`'s `isRegisterFreePhaseCall`), which is
// also the project's standing accept-side discipline (never a name prefix — the
// `cq_theta_evil` hazard).
//
// KEEPING IT IS THE POINT: a `void(double)` call has no arg-0 WIRE and no arg-1
// ANGLE, so every clause below that follows `getArgOperand(0)` as a rail, or
// reads `getArgOperand(1)` as an angle, would be reading the wrong operand — or
// out of range — if this predicate were widened to admit it. Do not "fix" this by
// making it match `cq_phi`.
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
    // ⚠ FOR A CONTROLLED STATE PREP (PRD §14, bd test_C_libtooling-drbq Inc 4)
    // `Base` IS THE SEED `Constant`, and `T->getArgOperand(0) != Base` therefore
    // passes by UNIQUED-CONSTANT POINTER IDENTITY — LLVM uniques `ConstantInt`
    // on type+bits and `ConstantFP` on the `APFloat` bits, so this test is
    // *also* a seed check here, by representation. It is recorded rather than
    // relied on: the REAL seed fence is F1 in `ArmClassify`, which has its own
    // string (`state prep seed does not match the merge incoming`) and its own
    // fixtures. This line keeps its own string for the shape it is about — the
    // plan not describing the IR (§14.2a item 1: "passes for a reason nobody
    // wrote down" is what F1 exists to retire).
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
  //
  //    M-β — THE CHAIN, AND THE SECOND EMISSION CONVENTION IN THIS FILE (bd
  //    test_C_libtooling-drbq Inc 3, PRD §13.4). For an if/else the two hoisted
  //    gates are CHAINED in emission order: `T_f`'s arg-0 is set to `T_t`'s
  //    RESULT, so the two rotations form ONE in-place sequence on ONE rail
  //    instead of two independent readers of `Base`. `setArgOperand` (never a
  //    re-mint) is what keeps the USE rewritten, so `lowerRotations`' later
  //    `Theta->replaceAllUsesWith(Handle)` finds and fixes it exactly as it
  //    fixes every other gate operand — the final lowered IR is unchanged.
  //
  //    WHY IT IS NOT COSMETIC: `LoopLowering`'s round-2 fan-out guard counts
  //    IN-PLACE users PER RAIL VALUE (Rule 8), and two hoisted thetas both
  //    reading `Base` are two of them. Chaining makes the SSA say what is
  //    physically true — the first rotation MOVED the register, so the value
  //    after it is a different state from the value before it — and the guard
  //    then reads the truth with no exemption.
  //
  //    STRUCTURALLY UNREACHABLE, KEPT AS A LOUD DECLINE (bd drbq Inc 3, round-1
  //    lens L4, F-L4-2). `Gates` pairs each `ArmInfo` with `R.Shadow` when
  //    `A.BB == R.Arm` and with `R.ShadowFalse` otherwise, so `R.Arm ==
  //    R.ArmFalse` would put the SAME call in both slots and `setArgOperand(0,
  //    Prev)` with `Prev == G.first` would mint a SELF-REFERENCING call
  //    `%g = call @cq_theta(i32 %g, …)` — invalid SSA, which `opt`'s in-process
  //    verifier would ABORT on rather than decline. Measured unreachable:
  //    `br i1 %c, label %arm, label %arm` declines on both binaries at
  //    `tainted value muxed by a classical-condition phi`, because a 1-incoming
  //    merge φ never becomes a region. This is the same posture the
  //    `Cls != InPlaceRotation` case above was deliberately given (round-2 lens
  //    C §3): an unreachable path in this emitter gets a Prime-Directive decline,
  //    not a `continue` and not a verifier abort. Zero cost.
  FunctionCallee X = csyms.xFn();
  CallInst *Prev = nullptr;
  for (auto &G : Gates) {
    if (Prev == G.first) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
    if (G.second)
      stamp(B.CreateCall(X, {Flag}));
    G.first->moveBefore(BI);
    if (Prev)
      G.first->setArgOperand(0, Prev);
    taint.ControlledRotations[G.first] = Flag;
    Prev = G.first;
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
  //
  //    ⚠ AMENDED 2026-09-05 (round-1 Rule-13 review, lens L5 finding F-L5-2).
  //    FOR A CONTROLLED STATE PREP (Inc 4) R4 IS NOT WIDENED — IT IS **SKIPPED**
  //    (`ArmClassify`'s `if (!StatePrep)` wrapper around the two
  //    `railWireClosure` calls), so "R4 proved" is not the ground on that path.
  //    The licence there is STRUCTURAL and strictly stronger: the relabelled rail
  //    is minted by the hoisted `T` ITSELF — a `cqrt_alloc_<W>` emitted inside
  //    this region's own stream — so no pre-region SSA name for it exists and
  //    disjointness from the condition's chain is a property of construction
  //    rather than of a walk. MEASURED end-to-end on a derived condition that
  //    actually exercises this discharge (`if (sqrt(q+3.) <= 3.5) r =
  //    cq_theta(0,.9);`): the whole `sitofp/fadd/sqrt/fcmp` chain discharges in
  //    LIFO order after the strip, strict stage 2b 8 verified / 0 violations, and
  //    the trace reduces byte-for-byte to the chained twin's on the pre-Inc-4
  //    binary. The sentence above still governs the CHAINED class, where R4 does
  //    run.
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
  //
  //    ⚠ FOR A CONTROLLED STATE PREP (Inc 4, PRD §14.4) M-β IS A CORRECTNESS
  //    REQUIREMENT, NOT THE LOOP-BOOKKEEPING CONVENIENCE IT IS FOR INC 3, and
  //    the state-prep class rides it UNCHANGED because the Ry stem already does
  //    M-β for every `InPlaceRotation` arm. There `Base` is the SEED `Constant`:
  //    the Rz stem's M-α (`RAUW(m → Base)`) would RAUW the merge to the literal
  //    and every consumer of `r` would become a classical `i32 0` — a SILENTLY
  //    CLASSICAL PROGRAM, verify-clean, with the controlled gate still emitted
  //    onto a rail nothing reads. `lowerRotations` then RAUWs `T`'s result to
  //    the fresh alloc handle, so the merge ends up denoting the PREPPED RAIL,
  //    which is what the source's `r` means. Pinned by
  //    control_inplace_ry_stateprep_then_uncond_theta.ll (a post-region
  //    `cq_theta` on `r` lands on the SAME rail under M-β and would have minted a
  //    SECOND, unrelated rail under M-α) and it is the one mutation whose failure
  //    mode is silent — check the lowered IR, not the exit code.
  //
  //    ⚠ TWO RAUW CONVENTIONS LIVE IN THIS FILE, ONE PER STEM, AND WHICH IS
  //    WHICH IS LOAD-BEARING (bd drbq Inc 3, PRD §13.4 + the §12.1 stem table).
  //
  //      Ry — THIS emitter — RAUWs the merge φ to the LAST HOISTED GATE (M-β).
  //      Rz — `emitRegion`'s §6a peephole — RAUWs it to the BASE `Q` (M-α), as
  //           shipped by Inc 2a and UNCHANGED here.
  //
  //    The reason is the physics, not taste. `cqrt_rz_<W>_controlled` is
  //    DIAGONAL: the two names denote the same computational-basis state, so
  //    either target is correct and the base is the cheaper one. An Ry MOVES the
  //    register on the `f=1` branch, so the post-gate value is genuinely a
  //    different state and naming it `Base` is a false statement in SSA. Flat,
  //    that falsehood is harmless (the value is dead after `lowerRotations`
  //    collapses everything onto one handle); INSIDE A LOOP it is not, and both
  //    ways it fails are `LoopLowering` bookkeeping rather than a unitary:
  //      * with no post-region gate, `RAUW(m → Base)` makes the loop's carry a
  //        ZERO-HOP IDENTITY CARRY `%P = phi [%r0, entry], [%P, latch]`, which
  //        `recordRefreshedByDef` correctly calls FROZEN (bd
  //        [[identity-carry-phi-does-not-refresh]]) — so `railGateBetween` takes
  //        no cut and the increment's own target shape declines LOUDLY;
  //      * with one, `%P` acquires TWO in-place `cq_theta` users and the round-2
  //        fan-out guard fires `loop-carried rail has multiple in-place
  //        consumers`.
  //    Under M-β the chain is `%P → T → (post-region gate) → %P`: `T` is a chain
  //    MEMBER, so it is in the SKIP set (its own execution IS the wire moving),
  //    it is in `Gates` (it IS a relabelling gate — correct), `%P`'s carry
  //    crosses it so the record refreshes, and every rail value has ONE in-place
  //    user. No predicate is edited and no licence is granted anywhere.
  //
  //    ⚠ "`T` IS A CHAIN MEMBER" HOLDS ONLY WHEN `T`'s RESULT IS CARRIED, and
  //    the narrowing is recorded rather than the sentence trimmed (bd drbq Inc 3,
  //    round-1 lens L2, L2-F2). The chain is built by peeling in-place steps from
  //    the carried latch value, so a region whose merge value is NOT carried
  //    around the back edge — e.g. the region rotates a FROZEN identity-carry φ —
  //    joins the closure by the FORWARD extension instead: `T` is then in `Gates`
  //    and in `OnRailOut` (a RECORD) but NOT in `MemberSet` (the SKIP set). No
  //    defect follows today, and the reason is measured, not assumed: that shape
  //    declines at `ArmClassify`'s R6 before `collapseRailPhisIn` ever runs
  //    (lens L2 `s01_frozen_base_region`). A future widener must not read the
  //    sentence above as an invariant — it is a property of the CARRIED case.
  //
  //    THE ALTERNATIVE WAS REJECTED FOR A NAMED REASON: M-α + widening
  //    `LoopLowering::isHoistedRegionArmGate` to the Ry stem needs TWO
  //    independently-written licences over ONE closure (an exemption from the
  //    fan-out count that `collectRailGates::noteGate` would still contradict for
  //    staleness), which is the bd 8h7d.5 F-1/F-3 shape verbatim — and its
  //    refresh licence would rest on `ArmClassify`'s R6 refusing the alias shape,
  //    i.e. a fence in ANOTHER FILE (bd
  //    [[mint-at-consumer-window-protection-lives-elsewhere]]).
  //
  //    `T` DOMINATES THE MERGE: it was hoisted into `Pred`, which dominates
  //    `MergeBB`, so the RAUW is well-formed. `lowerRotations` then RAUWs every
  //    hoisted theta's result to its arg-0 handle exactly as today, so the FINAL
  //    LOWERED IR IS IDENTICAL under either convention — which is what makes the
  //    whole-corpus lowered-IR diff against the pre-Inc-3 oracle a real witness.
  MergePhi->replaceAllUsesWith(Gates.back().first);
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
  // contributes Q unchanged, so there is nothing to control — skip it (no gate,
  // no bracket). The pre-2a route skipped exactly the same arms for exactly the
  // same reason (routing a gate-free arm is a no-op cswap pair), so this is not
  // a behaviour change: an arm that contributed nothing then contributes nothing
  // now.
  //
  // There is no `AllPhis` list any more: the gates are HOISTED, not re-minted and
  // erased, so nothing is collected for a post-rewire erase pass (step 4).
  SmallVector<ArmStream, 2> Streams;
  for (const ArmInfo &A : Arms) {
    SmallVector<CallInst *, 4> Phis =
        collectArmPhis(MergePhi->getIncomingValueForBlock(A.BB), A.BB);
    if (Phis.empty())
      continue;
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
  //
  // THE WIDTH FENCE IS NOW `abiWidthHasControlledRotation`, not `rzRtFn`/`allocFn`
  // (bd test_C_libtooling-drbq Inc 2a): the stream this path emits is
  // `cqrt_rz_<W>_controlled`, so the width that must exist is the CONTROLLED one.
  // MEASURED to be a strictly equal set on this frontend, not a narrowing:
  // `abiWidthFor` maps every `cq_phi_<sfx>` spelling `CQ.h` exposes into
  // {i1,i8,i16,i32,i64,f16,f32,f64,f80} (`WidthDispatch.cpp`'s `kRows`), which is
  // exactly `abiWidthHasControlledRotation`'s set — `i80`/`i128` are intermediate
  // widths no `cq_phi` suffix names. So this is detect-before-mutate defence in
  // depth against hand-written IR, and it is asked with the SAME predicate the
  // minter (`ControlledSymbols::controlledRotationFn`) gates on (Rule 14).
  StringRef Abi =
      wd.abiWidthFor(intrinsicSuffix(Streams.front().Phis.front(), "cq_phi_"));
  if (Abi.empty() || !abiWidthHasControlledRotation(Abi)) {
    // Unsupported width past detection — decline LOUDLY (a silent leave-in-
    // place would hand the tainted `br` to the backend as classical control
    // while the later rotation lowering fires the arm gates unconditionally).
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  // THE §5 CONST-FOLD RE-ANCHOR IS **VALIDATED HERE, BEFORE ANY MUTATION**, and
  // only APPLIED in the emission loop below (bd drbq Inc 2a, round-1 review
  // L1 F-5 = L2 N-1). It used to be one fused test-and-assign inside the
  // emission loop, where the decline could fire AFTER the flag mint, after a
  // lone `cqrt_x` opener, and after a previous arm's gates had been hoisted and
  // recorded in `taint.ControlledRotations` — i.e. a loud reject on a HALF-
  // EMITTED region, which Rule 1 ("lower nothing") forbids and which the sibling
  // `emitInPlaceRotationRegion` states as its own invariant ("never emit half a
  // region", all four of its bails precede its flag mint). No reaching program
  // was found — `classifyArms` proves `Base == Routed` per arm so the assignment
  // is a no-op for every non-folded shape, and the eq-fold path re-anchors
  // `Region.RoutedBase` to the very handle the arm rotates — but "unreachable by
  // argument" is exactly the class this project's history says does get reached,
  // and the fix is one read-only loop. Every decline in `emitRegion` now precedes
  // the first emitted instruction.
  //
  // WHAT IS VALIDATED (the fence itself is unchanged, only its position): a first
  // spine gate whose arg 0 is neither `Q` nor a `Constant` is a shape
  // classification did not prove, and it declines LOUDLY rather than being
  // silently re-anchored — which would be a data-mux rewrite. The diagnostic
  // string is character-identical to the one the fused form emitted, so the
  // negative fixtures are unmoved.
  for (const ArmStream &S : Streams) {
    Value *A0 = S.Phis.front()->getArgOperand(0);
    if (A0 != Q && !isa<Constant>(A0)) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
  }

  const DebugLoc DL = BI->getDebugLoc();
  IRBuilder<> B(BI);  // every stream call lands before the conditional br.
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };

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
  // templateless `zext i32→i32`). The eager strip+free (step 3) is SKIPPED
  // below: the data lineage owns the handle (escaped/measured, classifyArms-
  // proven) — stripping/freeing it is a read-after-collapse / hidden measurement.
  if (R.ShareCondFlag)
    taint.SharedCondFlags[Cond] = Flag;

  // 2. THE ARM GATES, CONTROL-IN-PLACE (control-in-place-PRD §12.2, bd
  //    test_C_libtooling-drbq Inc 2a — the §6a peephole, default-on for this FLAT
  //    path). Per arm in successor order, HOIST the arm's `cq_phi` spine to just
  //    before the branch and record each gate against the flag it must fire under;
  //    `lowerRotations` then mints `cqrt_rz_<W>_controlled(f, handle, θ)` at the
  //    hoisted position instead of the unconditional `cqrt_rz_<W>(handle, θ)`.
  //
  //    WHAT THIS REPLACES, exactly — the route QUINTUPLE, per arm:
  //        cqrt_alloc_<W>(0) -> rail ; cqrt_cswap(f, q, rail)
  //        ; cqrt_rz_<W>(rail, θ) ; cqrt_cswap(f, q, rail) ; cqrt_free(rail)
  //    becomes ONE `cqrt_rz_<W>_controlled(f, q, θ)` per gate. The flag mint, the
  //    `cqrt_x` bracket, the strip and the flag free are byte-identical and in the
  //    same order; NOTHING else moves. That is the whole claim, and
  //    `tools/golden_multiset_audit.py` is what checks it per golden.
  //
  //    THE TWO ARE THE SAME UNITARY, and it is an identity rather than an
  //    approximation: with `w = |0⟩`, `cswap(f,q,w) · Rz_w(θ) · cswap(f,q,w)`
  //    applies `Rz(θ)` to `q` exactly on the `f=1` branch and, on `f=0`, applies
  //    `Rz(θ)` to a rail still holding `|0⟩` — which under the project's
  //    `Rz = diag(1, e^{iθ})` convention is the identity with NO global-phase
  //    residue. So `cRz(f, q, θ)` is equal, not merely equivalent up to phase.
  //    (This is exactly why the Ry stem could never route — PRD §2 —, and it is
  //    also why the peephole is a peephole here and the MECHANISM there.)
  //
  //    THE `cqrt_x` COUNT IS THE ONE THING THAT DOES CHANGE, AND IT MUST BE SAID
  //    OUT LOUD because PRD §9.2's literal wording ("the `cqrt_x` brackets …
  //    unchanged") does not survive contact with a NEGATED arm. The route
  //    brackets EACH of its two `cqrt_cswap`s, so a ¬flag arm carries FOUR
  //    `cqrt_x(f)`; this path brackets the arm's gate run ONCE, so it carries
  //    TWO. The bracket is still the same self-inverse pair on the same flag in
  //    the same place — there are simply two fewer of them because there are two
  //    fewer gates to bracket. The audit models that arithmetic explicitly
  //    (`-2 cqrt_x` per collapsed NEGATED arm) rather than waiving it.
  //
  //    HOIST-AND-DEFER, not emit-here (PRD §6, and the Inc-1 recipe verbatim):
  //    keeping the `@cq_phi_` call alive until `lowerRotations` means every stage
  //    between here and there — `collapseFlattenedLoopRails`, `lowerIOSinks`,
  //    `lowerQramReads`, `lowerShadowMemory`, `declineClassicalMuxes`,
  //    `declineLiftedStaleRecordOps`, `specialize` — keeps seeing the SAME
  //    pre-lowering vocabulary it saw before this increment: a diagonal `cq_phi`
  //    on the register, at arg 0. `LoopLowering::collectRailGates` in particular
  //    follows a `cq_phi` as a RAIL HOP that is not a gate (Rz is diagonal), which
  //    is the reading the 8h7d.5 rolled-loop fences were cleared under.
  //
  //    ORDER: `IRBuilder` inserts before `BI` in creation order and
  //    `moveBefore(BI)` lands in the same slot, so `x; rz…; x` comes out in that
  //    order. Do NOT re-mint the gate — moving it keeps its `!dbg`, its identity
  //    in `taint.PhiCalls`, and its operand USE (so the later RAUW-to-handle
  //    rewrites it like every other gate).
  FunctionCallee X = csyms.xFn();
  for (ArmStream &S : Streams) {
    if (S.Negated)
      stamp(B.CreateCall(X, {Flag}));
    // THE §5 CONST-FOLD RE-ANCHOR, AND IT IS LOAD-BEARING HERE IN A WAY IT IS
    // NOT ON THE ROUTE (bd drbq Inc 2a). The route reads ONLY arg 1 (the angle)
    // off the arm gate and puts the rotation on its own work rail, so an arm
    // whose `cq_phi` bottoms at a folded `ConstantInt k` (the 4.5 `tryEqFoldArm`
    // shape: `clang -O1` proves `q == k` inside the arm and value-propagates it)
    // routes correctly with no re-anchor at all. Hoist-and-defer reads arg 0:
    // `lowerRotations`' phi loop would see an UNTAINTED operand, emit NOTHING,
    // and RAUW the gate to the constant — the arm's Rz silently DROPPED, a
    // verify-clean wrong unitary. `Region.RoutedBase` is the handle
    // `tryEqFoldArm`/`straightThroughConstFoldHandle` PROVED the arm rotates, and
    // `Q` is it; re-anchoring arg 0 to `Q` is the same move `SwitchRouteEmit`
    // makes "by physics" for the switch spine.
    //
    // FENCED, because a silent re-anchor of anything else would be a data-mux
    // rewrite: a first spine gate whose arg 0 is neither `Q` nor a `Constant` is
    // a shape classification did not prove, and it declines LOUDLY rather than
    // being rewritten. (For every non-folded region — diamond, if/else,
    // sequential, in-loop — `classifyArms`' `Base == Routed` gate already makes
    // this a no-op assignment.)
    //
    // THE DECLINE ITSELF LIVES IN THE PRE-EMISSION VALIDATION LOOP ABOVE (Rule 1
    // — never bail mid-emission); what is left here is only the ASSIGNMENT, on a
    // shape already proven. The assert-by-construction is that the loop above
    // ran over the same `Streams` in the same order with the same `Q`.
    CallInst *First = S.Phis.front();
    if (First->getArgOperand(0) != Q)
      First->setArgOperand(0, Q);  // pre-validated: it is a `Constant`.
    for (CallInst *Phi : S.Phis) {
      Phi->moveBefore(BI);
      taint.ControlledRotations[Phi] = Flag;
    }
    if (S.Negated)
      stamp(B.CreateCall(X, {Flag}));
  }

  // 3. Flag strip + free — the eager ancilla cleanup, byte-identical to the
  //    route's steps 7-8. SKIPPED on the ziov share path (R.ShareCondFlag): the
  //    condition is also live as DATA, so the flag's last use is downstream (the
  //    escaped/measured data lineage owns it). Stripping here would return the
  //    flag to |0> before the data read (read-after-collapse); freeing it would be
  //    a hidden measurement. The data lineage is the flag's reclaimer (FreePoint →
  //    Escaped/Measured, no free). The only other case — a dead-within-function
  //    lineage — is declined upstream by classifyArms and stays declined.
  if (!R.ShareCondFlag) {
    // Flag strip — `q == q0` (Rz is DIAGONAL, so it preserves the basis value of
    // whatever register it fires on, controlled or not), so `icmp_inv(q)` returns
    // the flag to |0> with zero extra gates. Reads `Cond`'s operands, so it MUST
    // precede the erase of `Cond` (in flattenRegion).
    //
    // RECORDED as a DISCHARGED FLAG GATE (M-B Increment 6, clause (d2)). For the
    // compare operands in its shifted handle slots this call is a pure READ — it
    // recomputes the predicate and XORs it onto `Flag`, leaving every operand at
    // its forward basis — so a DERIVED condition's provenance chain is dead the
    // instant it returns. Recording it here lets `ChainWalk::isInteriorConsumer`
    // count it as a consumer, which moves the interior partition's
    // `dagInsertPoint` PAST this line and is the only place that chain may legally
    // be discharged (bd 6uqc's P0).
    //
    // THE LICENCE MOVED WITH THE MECHANISM, AND IT GOT STRONGER, NOT WEAKER. The
    // route's ground was "step 3/5 restore `Q`'s basis label AS A GROUP, so an
    // adjoint placed after the strip reads the wire the forward chain read". This
    // path emits no route at all: its only gate on `Q` is a CONTROLLED Rz, which
    // is `diag(1, e^{iθ})` on the `f=1` branch and `I` on the `f=0` branch —
    // DIAGONAL either way, so `Q`'s basis label is not merely restored, it is
    // never moved. The property the recording needs therefore holds pointwise
    // rather than as a group property of two swaps. (The Ry stem is the
    // counterexample that makes this a real distinction: `emitInPlaceRotationRegion`
    // records its strip too, but on the strictly different R4 ground that the
    // relabelled register is a proven-disjoint wire from every condition wire.)
    auto *Strip = dyn_cast_or_null<CallInst>(
        lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                           /*before=*/BI, /*negate=*/false,
                           /*railToStrip=*/Flag));
    if (Strip)
      taint.DischargedFlagGates.insert(Strip);

    // Flag free.
    stamp(B.CreateCall(wd.freeFn(), {Flag}));
  }

  // 4. Rewire + erase + scrub, then flatten the CFG. The merge phi's value is now
  //    just `q` (a phase arm preserves q's basis identity — and a CONTROLLED
  //    diagonal gate preserves it on both branches), so a measure on the phi
  //    becomes a measure on q.
  //
  //    THE ARM `cq_phi` CALLS ARE **NOT** ERASED HERE — they were MOVED to the
  //    pred at step 2 and are live instructions `lowerRotations` owns (the
  //    hoist-and-defer contract). That is the one structural difference from the
  //    route path, which re-minted each gate on a work rail and erased the
  //    original. Nothing scrubs them from `taint.PhiCalls` either: membership is
  //    exactly what makes `lowerRotations` lower them.
  MergePhi->replaceAllUsesWith(Q);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
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


// ── bd test_C_libtooling-3qlq Inc 1 — P1, the FLAT KICKBACK EMITTER ─────────
//
// The whole emitted stream, for `if (q == 5) cq_phi(PI);` (PRD §1's target):
//
//     cq_template_icmp_eq_i32_hl(h0, 5) -> h1        ; flag mint
//     cqrt_rz_i1(h1, 0x1.921fb54442d18p+1)           ; P(θ) ON THE FLAG
//     cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)      ; flag strip → |0>
//     cqrt_free(h1)                                  ; clean free (Rule 6)
//
// FOUR LINES, AND `q` IS NOT AN OPERAND OF ANY OF THEM except as the compare's
// input. That is the entire point of the increment (PRD §1): the shipped
// `cqrt_rz_<W>_controlled(f, h, θ)` this REPLACES was TENSORED — Rz on each
// qubit of the register — so the marked branch got `(−1)^popcount(target)` and
// `|0…0⟩` could not be marked at all, making every Grover golden a
// self-consistent trace of the IDENTITY on `q`.
//
// WHY THERE IS NO ROUTE, NO WORK RAIL AND NO `_controlled` GATE (PRD §3). With
// `f = c(x)` in a |0⟩ ancilla the state is `Σ a_x |x⟩|c(x)⟩`; a diagonal
// `P(θ)` on the ANCILLA gives `Σ a_x e^{iθ c(x)} |x⟩|c(x)⟩`; the compare `_unc`
// is the permutation `|x, c(x)⟩ → |x, 0⟩`, so the ancilla comes back |0⟩ ON
// EVERY BRANCH and the phase is left on the branch. One single-qubit gate. The
// `cqrt_cswap` route and the controlled-copy route are both junk-free for a
// diagonal gate too, at `2W` Fredkin / `2W` Toffoli respectively — the kickback
// needs neither.
//
// WHAT THIS SHARES WITH ITS SIBLINGS, VERBATIM (Rule 14). The mint, the `cqrt_x`
// negation bracket, the `_unc` strip and the free are the SAME four calls
// `emitRegion` (§B1) and `emitInPlaceRotationRegion` make, in the same order,
// through the same `lowerCompareToFlag` / `csyms.xFn()` / `wd.freeFn()`
// spellings. Only the gate between the brackets differs, and the merge handling:
//
//   * there is NO RAUW AT ALL. `emitRegion`'s M-α (`MergePhi → Q`) and
//     `emitInPlaceRotationRegion`'s M-β (`MergePhi → last hoisted gate`) both
//     answer "what does the merged name denote"; a kickback merges no name, so
//     the question does not arise and neither convention is instantiated here.
//     `R.Merge` is null by construction (`classifyPhaseKickback` sets it so) and
//     `flattenRegion` therefore never touches a φ — the same shape
//     `lowerControlledIOSinks` flattens for the void-I/O diamond.
//   * the gate is NOT recorded in `taint.ControlledRotations`. That map is the
//     hoist-and-defer channel to `lowerRotations` for a gate that must become
//     `_controlled`; this gate is UNCONTROLLED and is emitted here, finished.
//
// THE ZIOV SHARED-FLAG PATH IS HONOURED (`R.ShareCondFlag`): when the condition
// compare is ALSO read as data, the flag is minted at the COMPARE so it
// dominates every data use, and the strip+free are SKIPPED because the data
// lineage owns the flag — byte-for-byte the rule `emitRegion` follows.
void emitPhaseKickbackRegion(const ControlRegion &R, WidthDispatch &wd,
                             const ControlledSymbols &csyms, TaintSet &taint) {
  // ---- 0. RE-VALIDATE THE PLAN BY SSA IDENTITY, BEFORE MUTATING ANYTHING.
  // Every decline below precedes the FIRST emitted instruction, for the reason
  // the sibling emitters state: a region that declines MID-STREAM leaves a
  // minted flag and a half-lowered arm behind (the Inc-2a round-1 F-5 finding).
  auto *BI = R.Pred ? dyn_cast<BranchInst>(R.Pred->getTerminator()) : nullptr;
  auto anchor = [&]() -> Instruction * {
    if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
      return A;
    return BI;
  };
  // The condition is re-derived through the SAME `collectCondTree` grammar the
  // classifier accepted with (Rule 14 — the walk cannot drift). A bare compare
  // is the degenerate single-leaf tree and takes the pre-part-B code below,
  // byte-for-byte; a COMPOUND tree (P3) takes the shared `CondTreeEmit` network.
  CondTree Tree;
  if (!BI || !BI->isConditional() || !R.Arm || !R.MergeBB || !R.Condition ||
      BI->getCondition() != R.Condition ||
      !collectCondTree(R.Condition, Tree, /*AllowLogicalSelect=*/true)) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  const bool IsTree = !Tree.Nodes.empty();
  auto *Cond = IsTree ? nullptr : Tree.Leaves.front();
  // Each recorded gate must still be a one-operand phase call in the arm the
  // plan says it is in, with an angle defined OUTSIDE that arm (the classifier's
  // `Arm->size() == N + 1` makes the latter structural, but it is an EMISSION
  // fact — the angle has to dominate `BI`, where the gate is hoisted to — so it
  // is re-asked here rather than inherited).
  auto validGates = [&](ArrayRef<Instruction *> Gates, BasicBlock *BB) {
    for (Instruction *I : Gates) {
      auto *CI = dyn_cast<CallInst>(I);
      if (!CI || CI->getParent() != BB || CI->arg_size() != 1)
        return false;
      if (auto *AngI = dyn_cast<Instruction>(CI->getArgOperand(0)))
        if (AngI->getParent() == BB)
          return false;
    }
    return true;
  };
  if (!validGates(R.Shadow, R.Arm) ||
      (R.ArmFalse && !validGates(R.ShadowFalse, R.ArmFalse)) ||
      (!R.ArmFalse && !R.ShadowFalse.empty())) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  // The MERGE-TAIL ANGLE PHI, re-asked through the SAME predicate detection used
  // (Rule 14 — never a second spelling). Its ABSENCE is as load-bearing as its
  // presence: a φ left standing in a merge `flattenRegion` splices away is a
  // BROKEN MODULE at `opt` exit 0 (`PHI nodes not grouped at top of basic
  // block!`, MEASURED on `slice_control_phase_ifelse_derived`), so if the merge
  // carries a φ that is not this one, decline rather than flatten over it.
  PHINode *TailPhi = nullptr;
  CallInst *TailCall = nullptr;
  const bool HasTail = phaseAngleTail(R.MergeBB, taint, TailPhi, TailCall);
  if (!HasTail && !R.MergeBB->phis().empty()) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  if (R.Shadow.empty() && R.ShadowFalse.empty() && !HasTail) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  // `cqrt_rz_i1` is the ONLY Rz this pass emits after 3qlq (PRD §5). Resolve it
  // BEFORE any mutation so a resolution failure is a decline, not a half-stream.
  FunctionCallee Rz = wd.rzRtFn("i1");
  if (!Rz) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }

  // ---- EMISSION STARTS HERE. Nothing below may decline.
  const DebugLoc DL = R.Shadow.empty()
                          ? (HasTail ? TailCall->getDebugLoc() : BI->getDebugLoc())
                          : R.Shadow.front()->getDebugLoc();
  IRBuilder<> B(BI);
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };

  // ---- 1. FLAG MINT — `cq_template_icmp_<pred>_<W>_hl(q, lit)`. Position rule
  // copied from `emitRegion` step 1: at the COMPARE on the ziov share path (so
  // the one physical flag dominates every data use), at the branch otherwise.
  //
  // COMPOUND TREE (P3): the network is the 4.4 select's, shared through
  // `CondTreeEmit` — one flag per leaf, one `|0>` ancilla per and/or/xor node,
  // the ROOT ancilla carrying the whole predicate. `ShareCondFlag` is FALSE for
  // a tree by construction (the classifier declines every out-of-tree use), so
  // the position rule degenerates to "at the branch".
  CondNetwork Net;
  SmallVector<CallInst *, 4> LeafStrips;
  if (IsTree) {
    switch (emitCondNetwork(R.Condition, Tree, wd, csyms, taint, /*Before=*/BI,
                            DL, /*AllowQQLeaves=*/false, Net)) {
    case CondNetDisp::Ok:
      break;
    case CondNetDisp::MintDiagnosed:
      // `lowerCompareToFlag` was already LOUD; a second message here would only
      // change what a decline fixture reads. The classifier proved every leaf
      // mintable, so this is drift — but it is still a decline, not a skip.
      return;
    case CondNetDisp::Malformed:
      if (Instruction *A = anchor())
        diagnoseUnderControl(A, "control flow");
      return;
    }
  }
  Instruction *FlagAt = R.ShareCondFlag ? Cond->getNextNode() : BI;
  Value *Flag = IsTree ? Net.Root
                       : lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                            /*inverse=*/false,
                                            /*before=*/FlagAt);
  if (!Flag)
    // REACHABLE, and say so plainly rather than calling it unreachable — an
    // overstated justification is how a real bail later gets deleted as dead.
    // `classifyPhaseKickback` asks `compareFlagMintable` (a dry run of the
    // template lookup) but deliberately does NOT ask whether the compare is
    // Q+Q, so a `q == p` condition reaches here and `lowerCompareToFlag` fails.
    //
    // THAT IS SAFE AND IT IS THE PRE-EXISTING DISPOSITION, both MEASURED. Safe:
    // the mint is the FIRST emission, so returning leaves the module exactly as
    // it was — this is not a mid-stream bail (contrast `AngleSelectEmit`, whose
    // `fsub` and unconditional twin precede its mint, which is why IT re-asks
    // the semantic half at step 0b). Pre-existing: `lowerCompareToFlag` has
    // already diagnosed `no template for opcode 'icmp i1' in tainted context`,
    // which is CHARACTER-FOR-CHARACTER what the pre-3qlq oracle emits for the
    // same Q+Q phase diamond in the retired register form (measured on
    // `$SP/wt/pre-3qlq` 2026-09-05) — so this shape's message did not churn.
    // `emitRegion`'s flat phase path has the identical structure and comment.
    // Q+Q flag minting is a filed follow-on (PRD §9), not a defect here.
    return;
  if (R.ShareCondFlag)
    taint.SharedCondFlags[Cond] = Flag;

  // ---- 2. THE GATES — `cqrt_rz_i1(f, θ)` each, UNCONTROLLED, in SOURCE ORDER,
  // `cqrt_x`-bracketed per arm-polarity.
  //
  // N GATES ARE EXACT AND NEED NO ARITHMETIC (orchestrator decision 2026-09-05,
  // PRD §6.3 row 1 superseded — see `classifyPhaseKickback`'s header). Each
  // angle is passed through VERBATIM; the composition `P(θ₁)·P(θ₂) = P(θ₁+θ₂)`
  // happens in the hardware, not in this compiler, so there is no `fsub`, no
  // rounding residual and no bound to fence — unlike the 2b by-difference Ry
  // form, whose whole arm-value fence exists because it realizes `A − B`.
  //
  // ONE BRACKET PAIR PER ARM, not per gate: `cqrt_x` is self-inverse, so
  // `x;g1;x;x;g2;x` and `x;g1;g2;x` are the same unitary and the second is what
  // the flat phase path has emitted since Inc 2a (`SwapRouteEmit.cpp:1063`'s
  // `-2 cqrt_x` audit arithmetic assumes exactly this).
  FunctionCallee X = csyms.xFn();
  auto emitArm = [&](ArrayRef<Instruction *> Gates, bool Neg) {
    if (Gates.empty())
      return;
    if (Neg)
      stamp(B.CreateCall(X, {Flag}));
    for (Instruction *I : Gates)
      stamp(B.CreateCall(Rz, {Flag, cast<CallInst>(I)->getArgOperand(0)}));
    if (Neg)
      stamp(B.CreateCall(X, {Flag}));
  };
  emitArm(R.Shadow, R.ArmNegated);
  // The FALSE arm of an if/else always fires on ¬f — `ArmNegated` is the
  // DIAMOND's polarity and is false for an if/else, so the bracket here is
  // unconditional (the field convention: `Shadow` is `Arm`'s, `ShadowFalse` is
  // `ArmFalse`'s, by field identity and not by edge truth).
  emitArm(R.ShadowFalse, /*Neg=*/true);

  // ---- 2b. THE MERGE-TAIL ANGLE PHI: one gate per incoming, each bracketed by
  // THAT incoming's own polarity. `%a = phi double [A, %arm], [B, %pred]` means
  // "A when the arm ran, B otherwise", so the gate for the `%arm` incoming fires
  // on the arm's polarity and the `%pred` incoming's fires on its negation. Walk
  // the incoming list in index order so the emitted stream is a deterministic
  // function of the IR.
  if (HasTail)
    for (unsigned I = 0; I != 2; ++I) {
      BasicBlock *In = TailPhi->getIncomingBlock(I);
      // `Arm` fires on f == 1 unless the diamond polarity is inverted; `ArmFalse`
      // always fires on f == 0; the straight-through `Pred` edge is taken exactly
      // when `Arm` is not, so its polarity is `Arm`'s negation.
      const bool FiresOnOne = In == R.Arm         ? !R.ArmNegated
                              : In == R.ArmFalse  ? false
                                                  : R.ArmNegated;
      if (!FiresOnOne)
        stamp(B.CreateCall(X, {Flag}));
      stamp(B.CreateCall(Rz, {Flag, TailPhi->getIncomingValue(I)}));
      if (!FiresOnOne)
        stamp(B.CreateCall(X, {Flag}));
    }

  // ---- 3. STRIP + FREE. The strip recomputes the predicate on the CONDITION's
  // OWN registers and XORs it back onto the flag, returning it to |0⟩ so the free
  // is clean (Rule 6). Its validity here is unconditional in a way no other arm
  // class can claim: this region emits NO gate on any condition register at all,
  // so the basis the strip reads is identically the basis the mint read.
  // (`emitRegion` needs §3c for the same conclusion; the Ry path needs S8's
  // disjoint-wire proof.)
  //
  // SKIPPED WHOLE on the ziov share path: the data lineage owns the flag and
  // discharges it downstream — freeing it here would be a use-after-free.
  if (IsTree) {
    // The exact LIFO mirror of the network: every node's self-inverse undo (then
    // its ancilla's proven-|0> free) in reverse post-order, then every leaf's
    // `_unc` strip against its OWN rail (then that rail's free) in reverse mint
    // order. `ShareCondFlag` cannot be set for a tree, so there is no skip case.
    // Each leaf strip is recorded in `DischargedFlagGates` for the same reason
    // the single-compare one is: it is the point past which a DERIVED
    // condition's chain may be discharged by the whole-DAG spine
    // (`ChainWalk::isInteriorConsumer`).
    stripCondNetwork(Net, wd, csyms, taint, /*Before=*/BI, DL,
                     /*AllowQQLeaves=*/false, &LeafStrips);
    for (CallInst *S : LeafStrips)
      taint.DischargedFlagGates.insert(S);
  } else if (!R.ShareCondFlag) {
    auto *Strip = dyn_cast_or_null<CallInst>(
        lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                           /*before=*/BI, /*negate=*/false,
                           /*railToStrip=*/Flag));
    if (Strip)
      taint.DischargedFlagGates.insert(Strip);
    stamp(B.CreateCall(wd.freeFn(), {Flag}));
  }

  // ---- 4. ERASE THE ARM CALLS AND THE TAIL, THEN FLATTEN. Each call is erased
  // rather than hoisted: its whole content is now a `cqrt_rz_i1` above. Scrub
  // from `PhaseCalls` first so `deleteGlobalPhases` (which derives its survivors
  // from the IR) and any later module walk cannot dereference freed memory.
  auto erasePhase = [&](CallInst *CI) {
    auto &PC = taint.PhaseCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
    CI->eraseFromParent();
  };
  for (Instruction *I : R.Shadow)
    erasePhase(cast<CallInst>(I));
  for (Instruction *I : R.ShadowFalse)
    erasePhase(cast<CallInst>(I));
  if (HasTail) {
    // Consumer first (it is the φ's only user), then the φ — which MUST go
    // before `flattenRegion` splices its block away.
    erasePhase(TailCall);
    scrubTaint(TailPhi, taint);
    TailPhi->eraseFromParent();
  }
  // `R.Merge` is null, so `flattenRegion` dissolves no φ — it splices the arm(s)
  // and merge blocks into `Pred` and rewires the branch, exactly as it does for
  // the void-I/O diamond. It also erases `R.Condition` — the tree ROOT — once
  // the branch is gone and the root is use-empty.
  Value *const Root = R.Condition;
  flattenRegion(R, taint);
  // A COMPOUND tree's INTERIOR is not `flattenRegion`'s to erase, and leaving it
  // is not harmless: the mint and strip built FRESH templates from the leaves'
  // operands, so with the root gone every node and leaf is dead — and a dead
  // TAINTED compare is exactly what `lowerOps` would lower into a spurious
  // template plus a leaked flag rail a few steps later. Cascade ROOT-FIRST
  // (nodes in reverse post-order, then leaves in reverse) so each child's use
  // count has already dropped when it is tested — the discipline
  // `SelectMergeEmit` step 6 follows. `Root` is compared by POINTER only (it may
  // already be freed memory); nothing is dereferenced through it, and no
  // instruction is created between the flatten and here, so no address can have
  // been recycled. A leaf or node with a SURVIVING user is left alone (the
  // classifier declines every out-of-tree use, so that is defence in depth).
  for (Instruction *N : llvm::reverse(Tree.Nodes))
    if (N != Root && N->use_empty()) {
      scrubTaint(N, taint);
      N->eraseFromParent();
    }
  for (CmpInst *Leaf : llvm::reverse(Tree.Leaves))
    if (Leaf != Root && Leaf->use_empty()) {
      scrubTaint(Leaf, taint);
      Leaf->eraseFromParent();
    }
}


// ── bd test_C_libtooling-3qlq Inc 1 part B — P4, the GENUINE depth-2 NEST ────
//
// The register-free replacement for `NestedRouteEmit::lowerNestedRegion` (which
// is DELETED with this increment). See `classifyPhaseKickbackNest` for the
// shape, the unitary and the scope; the whole emission is:
//
//   1  the OUTER condition network            -> rootA           (CondTreeEmit)
//   2  [x(rootA)] rz_i1(rootA, θ_i) …  [x(rootA)]   the outer arm's phases
//   3  the INNER condition network            -> rootB           (CondTreeEmit)
//   4  g = alloc_i1(0);  toffoli(rootA, rootB, g)   X-bracketed per polarity
//   5  rz_i1(g, θ_j) …                              the inner arm's phases
//   6  the same bracketed toffoli again; free(g)    (self-inverse, g back to |0>)
//   7  strip the INNER network, then the OUTER one  (exact LIFO)
//   8  erase both arms' phase calls, flatten the region tree, cascade-erase the
//      two condition trees' interiors
//
// ZERO `cqrt_cswap`, ZERO work rails, ZERO `_controlled` gates, and the only Rz
// is `cqrt_rz_i1` — which is the whole point of the epic. Compare the 4.3 route
// this replaces: two `cqrt_alloc_<W>` work rails, FOUR `cqrt_cswap`, an inner
// flag minted FROM rail1, and a TENSORED `cqrt_rz_<W>` that could never mark
// |0..0> (PRD §1/§3).
//
// WHY THE ORDER IN 1-3 IS WHAT IT IS. The outer arm's phases ride `rootA` alone,
// so they may be emitted as soon as the outer network exists; the inner
// network's leaves read registers no gate in this region touches, so minting it
// after those phases reads exactly the same basis it would read before them.
// Emitting the inner network SECOND keeps the LIFO strip in step 7 the literal
// reverse of the mint order, which is what makes each free a proven-|0> free.
void emitPhaseKickbackNestRegion(const ControlRegion &R, WidthDispatch &wd,
                                 const ControlledSymbols &csyms,
                                 TaintSet &taint) {
  // ---- 0. RE-VALIDATE BY SSA IDENTITY BEFORE MUTATING ANYTHING. Every decline
  // below precedes the FIRST emitted instruction (the Inc-2a round-1 F-5
  // finding: a mid-stream decline leaves a half-built network behind).
  auto *BI = R.Pred ? dyn_cast<BranchInst>(R.Pred->getTerminator()) : nullptr;
  auto *InnerBI = R.Arm ? dyn_cast<BranchInst>(R.Arm->getTerminator()) : nullptr;
  auto anchor = [&]() -> Instruction * {
    if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
      return A;
    return BI;
  };
  CondTree OuterTree, InnerTree;
  if (!BI || !InnerBI || !BI->isConditional() || !InnerBI->isConditional() ||
      !R.Arm || !R.ArmFalse || !R.MergeBB || !R.Condition ||
      !R.InnerCondition || BI->getCondition() != R.Condition ||
      InnerBI->getCondition() != R.InnerCondition ||
      !collectCondTree(R.Condition, OuterTree, /*AllowLogicalSelect=*/true) ||
      !collectCondTree(R.InnerCondition, InnerTree,
                       /*AllowLogicalSelect=*/true) ||
      !R.MergeBB->phis().empty()) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  // Each recorded gate must still be a one-operand phase call in the block the
  // plan says, with its ANGLE defined OUTSIDE that block — an EMISSION fact (the
  // gate is hoisted to `BI`, so the angle has to dominate it), re-asked rather
  // than inherited.
  auto validGates = [&](ArrayRef<Instruction *> Gates, BasicBlock *BB) {
    for (Instruction *I : Gates) {
      auto *CI = dyn_cast<CallInst>(I);
      if (!CI || CI->getParent() != BB || CI->arg_size() != 1)
        return false;
      if (auto *AngI = dyn_cast<Instruction>(CI->getArgOperand(0)))
        if (AngI->getParent() == R.Arm || AngI->getParent() == R.ArmFalse)
          return false;
    }
    return true;
  };
  if (!validGates(R.Shadow, R.Arm) || !validGates(R.ShadowFalse, R.ArmFalse) ||
      (R.Shadow.empty() && R.ShadowFalse.empty())) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  // `cqrt_rz_i1` is the ONLY Rz this pass emits after 3qlq (PRD §5), and the
  // conjunction needs an i1 ancilla allocator. Resolve BOTH before any mutation
  // so a resolution failure is a decline and not a half-stream.
  FunctionCallee Rz = wd.rzRtFn("i1");
  FunctionCallee AllocI1 = wd.allocFn("i1");
  if (!Rz || !AllocI1) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }

  // ---- EMISSION STARTS HERE. Nothing below may decline.
  const DebugLoc DL = !R.Shadow.empty()      ? R.Shadow.front()->getDebugLoc()
                      : !R.ShadowFalse.empty() ? R.ShadowFalse.front()->getDebugLoc()
                                               : BI->getDebugLoc();
  IRBuilder<> B(BI);
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  FunctionCallee X = csyms.xFn();
  auto emitArm = [&](ArrayRef<Instruction *> Gates, Value *Ctl, bool Neg) {
    if (Gates.empty())
      return;
    // ONE bracket pair per ARM, not per gate: `cqrt_x` is self-inverse, so
    // `x;g1;x;x;g2;x` and `x;g1;g2;x` are the same unitary and the second is
    // what every sibling phase emitter has emitted since drbq Inc 2a.
    if (Neg)
      stamp(B.CreateCall(X, {Ctl}));
    for (Instruction *I : Gates)
      stamp(B.CreateCall(Rz, {Ctl, cast<CallInst>(I)->getArgOperand(0)}));
    if (Neg)
      stamp(B.CreateCall(X, {Ctl}));
  };

  // 1-2. OUTER network, then the outer arm's phases on its root.
  CondNetwork OuterNet;
  switch (emitCondNetwork(R.Condition, OuterTree, wd, csyms, taint,
                          /*Before=*/BI, DL, /*AllowQQLeaves=*/false,
                          OuterNet)) {
  case CondNetDisp::Ok:
    break;
  case CondNetDisp::MintDiagnosed:
    return;  // `lowerCompareToFlag` was already LOUD; do not double-diagnose.
  case CondNetDisp::Malformed:
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  emitArm(R.Shadow, OuterNet.Root, R.ArmNegated);

  // 3. INNER network. Its leaves read registers NO gate in this region touches
  // (the classifier proved `Mid` holds nothing but void phase calls and the
  // tree), so minting it here — at the OUTER branch, after the outer arm's
  // phases — reads exactly the basis the source compare reads.
  CondNetwork InnerNet;
  switch (emitCondNetwork(R.InnerCondition, InnerTree, wd, csyms, taint,
                          /*Before=*/BI, DL, /*AllowQQLeaves=*/false,
                          InnerNet)) {
  case CondNetDisp::Ok:
    break;
  case CondNetDisp::MintDiagnosed:
  case CondNetDisp::Malformed:
    // ⚠ A MID-STREAM BAIL, and the ONLY one in this emitter — the outer network
    // and the outer arm's phases are already emitted. It is REACHABLE only
    // through detection/emission drift (the classifier ran the identical
    // per-leaf ladder over this identical tree), and the outcome is a LOUD
    // `DS_Error`, so `opt` exits non-zero and nothing downstream consumes the
    // half-stream. Say that plainly rather than calling it unreachable.
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }

  // 4-6. THE CONJUNCTION. `g = (rootA ⊕ OuterNeg) ∧ (rootB ⊕ InnerNeg)` on a
  // fresh |0> ancilla, the inner arm's phases on `g`, then the SAME node again —
  // `cqrt_toffoli` and `cqrt_x` are each self-inverse and the controls are
  // read-only, so `g` returns to |0> EXACTLY and its free is clean (Rule 6).
  CondNetwork::Node Conj;
  Conj.Opc = Instruction::And;
  Conj.L = OuterNet.Root;
  Conj.R = InnerNet.Root;
  Conj.NegL = R.ArmNegated;
  Conj.NegR = R.InnerArmNegated;
  Conj.G = stamp(B.CreateCall(
      AllocI1, {Constant::getNullValue(Type::getInt1Ty(BI->getContext()))},
      "g"));
  emitCondNode(Conj, csyms, B, DL, /*Inverse=*/false);
  emitArm(R.ShadowFalse, Conj.G, /*Neg=*/false);
  emitCondNode(Conj, csyms, B, DL, /*Inverse=*/true);
  stamp(B.CreateCall(wd.freeFn(), {Conj.G}));

  // 7. STRIP, exact LIFO: the inner network (minted last) first, then the outer.
  // Each leaf strip is recorded in `DischargedFlagGates` for the same reason the
  // flat path records its one strip — it is the point past which a DERIVED
  // condition's chain may be discharged by the whole-DAG spine
  // (`ChainWalk::isInteriorConsumer`).
  SmallVector<CallInst *, 4> LeafStrips;
  stripCondNetwork(InnerNet, wd, csyms, taint, /*Before=*/BI, DL,
                   /*AllowQQLeaves=*/false, &LeafStrips);
  stripCondNetwork(OuterNet, wd, csyms, taint, /*Before=*/BI, DL,
                   /*AllowQQLeaves=*/false, &LeafStrips);
  for (CallInst *S : LeafStrips)
    taint.DischargedFlagGates.insert(S);

  // 8. ERASE THE ARM CALLS, THEN FLATTEN, THEN THE TREE INTERIORS. Each phase
  // call is erased rather than hoisted: its whole content is a `cqrt_rz_i1`
  // above. Scrub from `PhaseCalls` first so `deleteGlobalPhases` — which derives
  // its survivors from the IR — and any later module walk cannot dereference
  // freed memory.
  auto erasePhase = [&](CallInst *CI) {
    auto &PC = taint.PhaseCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
    CI->eraseFromParent();
  };
  for (Instruction *I : R.Shadow)
    erasePhase(cast<CallInst>(I));
  for (Instruction *I : R.ShadowFalse)
    erasePhase(cast<CallInst>(I));
  // `flattenRegionTree` is the SHARED three-block teardown (Rule 14): drop both
  // branches, erase both dead condition ROOTS, splice the shared merge into
  // `Pred` EXACTLY ONCE, erase InnerArm → Mid → Merge in that order. It takes a
  // NULL merge φ since this increment — this nest has none — and an EMPTY arm-gate
  // list, because the phase calls are already gone.
  //
  // ⚠ `Inner.Condition` MUST BE RE-POINTED AT THE INNER ROOT. `flattenRegionTree`
  // erases `Outer.Condition` and `Inner.Condition` as two separate dead values;
  // leaving the copy's inherited `Condition` in place makes it erase the OUTER
  // root TWICE — a double free, MEASURED as a SIGSEGV inside the flatten on the
  // very first P4 run.
  ControlRegion Outer = R, Inner = R;
  Outer.Merge = nullptr;
  Outer.Arm = R.Arm;
  Inner.Merge = nullptr;
  Inner.Condition = R.InnerCondition;
  Inner.Arm = R.ArmFalse;
  Inner.Pred = R.Arm;
  flattenRegionTree(Outer, Inner, /*armPhis=*/{}, taint);
  // The tree INTERIORS are not the flatten's to erase (it owns only the two
  // roots), and leaving them is not harmless: with their roots gone every node
  // and leaf is dead, and a dead TAINTED compare is exactly what `lowerOps`
  // would turn into a spurious template plus a leaked flag rail. Cascade
  // ROOT-FIRST per tree, comparing against the captured roots by POINTER only
  // (they may already be freed memory; nothing is dereferenced through them, and
  // no instruction is created between the flatten and here).
  Value *const OuterRoot = R.Condition;
  Value *const InnerRoot = R.InnerCondition;
  for (const CondTree *T : {&InnerTree, &OuterTree}) {
    for (Instruction *N : llvm::reverse(T->Nodes))
      if (N != OuterRoot && N != InnerRoot && N->use_empty()) {
        scrubTaint(N, taint);
        N->eraseFromParent();
      }
    for (CmpInst *Leaf : llvm::reverse(T->Leaves))
      if (Leaf != OuterRoot && Leaf != InnerRoot && Leaf->use_empty()) {
        scrubTaint(Leaf, taint);
        Leaf->eraseFromParent();
      }
  }
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
  //
  // WIDENED to `PhaseKickback` (bd test_C_libtooling-3qlq Inc 1). The hcrg
  // argument above transfers WORD FOR WORD to a kickback region: its flatten
  // erases exactly `{Arm, MergeBB}` (`ArmFalse` is null), its `Pred` survives by
  // construction, and its emitter inserts positionally into that `Pred` — so
  // emitting the LATER region first is sound for the identical reason. The
  // STRUCTURAL LEMMA transfers too, but only because `classifyPhaseKickback`
  // asks `MergeBB->hasNPredecessors(2)` explicitly: point 2 (an arm has one
  // pred, a merge two, so they are never the same block) and point 3 (two
  // distinct regions cannot share a merge) are read off `soleMergePhi`'s
  // 2-incoming φ for a `BranchRegion`, and a kickback merge has no φ to read.
  // That is why the check is in the classifier and not left to the flatten.
  //
  // MEASURED: without this widening the flagship two-diamond Grover customer
  // (`if (q==5) cq_phi(π); … if (q==0) cq_phi(π);` — PRD §1's own program)
  // declines `control flow`, because region 2's `Pred` IS region 1's `MergeBB`.
  auto sequentialChainAlias = [&](size_t ai, size_t bi) {
    auto reorderable = [](const ControlRegion &R) {
      return R.Kind == ControlRegion::BranchRegion ||
             R.Kind == ControlRegion::PhaseKickback;
    };
    const ControlRegion &A = Regions[ai], &B = Regions[bi];
    if (!reorderable(A) || !reorderable(B))
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
  // hcrg Rule-13 clearance) — but NOT for the reason this comment used to give,
  // and the correction matters because the old one invited deleting the branch
  // (bd drbq Inc 3, round-1 lens L4, F-L4-1). It said a precedence cycle needs a
  // CFG cycle through the region entries, "and `regionEntryInLoop` declines
  // every flat region on a cycle at DETECTION
  // (`control_swap_reject_seq_in_loop.ll`)". BOTH HALVES ARE FALSE AT HEAD: that
  // fixture was renamed to `control_swap_inloop_seq.ll` AND FLIPPED TO ACCEPT by
  // 8h7d.5, and flat regions on a cycle DO reach the plan — two sequential phase
  // regions in a loop lower today (exit 0, both binaries), and since Inc 3 so
  // does the Ry-arm twin. So the population this backstop reasons about is
  // NON-EMPTY and growing.
  //
  // What is still true is the narrower claim: a precedence CYCLE needs a
  // region's `MergeBB` to be a loop header, i.e. a merge φ with three or more
  // predecessors, and region recovery refuses that (`soleMergePhi` requires
  // exactly 2 incomings). Lens L4 could not construct one. Do not delete this as
  // dead code: it is the backstop for the day merge recovery is widened, and a
  // bare fall-through here would emit a partial region set over freed blocks.
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
    if (R.Kind == ControlRegion::AngleSelectRegion) {
      // drbq Inc 2b (control-in-place-PRD §12.3) — a tainted-condition select
      // over the classical rotation ANGLE, feeding ONE chained
      // `cq_theta`/`cq_phi`. Lowered BY DIFFERENCE (unconditional `R(h,B)`, flag
      // mint, `R_controlled(f,h,A−B)`, strip, free): no CFG diamond, no rail, no
      // route, no flatten, no child nest — its block fields are all null, so the
      // pre-flight above treated it as inert (the `if (!Doomed) continue;`
      // guard), exactly as for a `SelectRegion`. Dispatch + continue BEFORE the
      // Depth / child-lookup branch, which keys on null CFG anchors.
      //
      // ⚠ BEING INERT TO THE PRE-FLIGHT IS SAFE FOR A REASON THAT LIVES
      // ELSEWHERE, so state it here rather than leaving the next reader to
      // rediscover it (bd drbq Inc 2b, notes finding I). A select in another
      // region's `Pred` is never erased and one in its `MergeBB` is SPLICED into
      // the pred and survives — but one in an `Arm` would be FREED, and plan
      // order puts that region first, so this emitter's "re-validate by SSA
      // identity" would be reading freed memory rather than validating. It
      // cannot happen at HEAD because EVERY region kind that erases an arm
      // constrains that arm to a shape a `select` cannot satisfy
      // (`armBlockIsPureSpine`, `valueArmIsPureChain`,
      // `inPlaceRotationArmTheta`, `classifyClassicalCallArm`'s
      // `Arm->size() != 2`, the guarded-store gep+store shape, `AbortPark`'s
      // sink+`unreachable`) — measured on a hand-IR diamond carrying a pure
      // classical call AND a tainted angle select in one arm: declines
      // `control flow`, clean under `libgmalloc`. A future region kind that
      // erases a block whose contents it does not fix must extend the pre-flight
      // to this Kind or re-prove that purity.
      emitAngleSelectRegion(R, wd, taint);
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
    if (R.Kind == ControlRegion::PhaseKickbackNest) {
      // 3qlq Inc 1 (P4) — the GENUINE depth-2 register-free PHASE NEST: two
      // condition networks, ONE `cqrt_toffoli` conjunction ancilla, `cqrt_rz_i1`
      // on the outer root and on the conjunction, exact LIFO undo. ONE region
      // (no `ParentIdx` link), its doomed blocks `{Arm, ArmFalse, MergeBB}` =
      // `{Mid, InnerArm, Merge}` already covered by the cross-region pre-flight
      // above. Dispatch + continue BEFORE the Depth / child-lookup branch.
      emitPhaseKickbackNestRegion(R, wd, csyms, taint);
      continue;
    }
    if (R.Kind == ControlRegion::PhaseKickback) {
      // 3qlq Inc 1 (P1) — the register-free BRANCH PHASE by kickback: mint the
      // flag, ONE UNCONTROLLED `cqrt_rz_i1(f, θ)` on it, strip, free, flatten.
      // Its Pred/Arm/MergeBB are set (a real diamond) so the cross-region
      // pre-flight above covered the block-lifetime hazard; `Merge` is NULL (a
      // void arm has no φ), which is exactly why detection had to PRE-PEEL it.
      // No nest link — dispatch + continue BEFORE the Depth / child-lookup
      // branch. The in-loop `Pred` is recorded for the same reason `emitRegion`
      // records it (the round-2 rail collapse's sole trigger); a kickback leaves
      // nothing FOR that collapse to claim, but the loop may hold other regions
      // that do.
      if (R.InLoop)
        taint.InLoopFlattenedPreds.insert(R.Pred);
      emitPhaseKickbackRegion(R, wd, csyms, taint);
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
