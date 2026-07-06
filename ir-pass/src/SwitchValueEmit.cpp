// SwitchValueEmit.cpp — the mutating swap-route emitter for an accepted tainted
// `switch` whose content arms are homogeneous VALUE chains (4.5 WI-3; PRD Part V
// §20; IMPLEMENTATION-4.5 §4B). The N-way generalization of the 4.2 value diamond
// (`SwapRouteEmit::emitValueRegion`) — method-B (compute → copy-out → reverse-play,
// Rule 7), but routing the SHARED base `p` = the merge default-edge (straight-
// through) incoming, NOT the scrutinee `q` (the C2 anchor — `p != q`, proven in
// `proveSwitchValue`; routing `q` would clobber the eq-flags, §3c).
//
// Per content case the eq-flags `f_i = (q == c_i)` are MUTUALLY EXCLUSIVE (q
// equals at most one case literal), so the per-case route fires only when q == c_i
// and the off-case routes are identities. The forward stage is therefore safely
// INTERLEAVED per case (§4B): mint f_i → |0> rail r_i → cswap route-in (positive-
// polarity, NO ¬-bracket) → replay the chain VERBATIM/UNCONTROLLED on r_i → cswap
// route-back. After all route-backs `p` holds the muxed answer (exactly one case
// settled it; the rest left p untouched). Then ONE uncontrolled `cqrt_copy_<W>(p,
// out)` copy-out (the only basis copy, after route-back, before any R†), the LIFO
// reverse-play (route-back† · body-chain adjoint · route-in†; the cases commute —
// disjoint rails, complementary flag values — so the grouped LIFO equals the global
// adjoint), clean rail frees, the `icmp_inv` flag strips (q == q0 — q is never
// routed), and the flag frees. `p` is restored to p0 and left live; `out` is the
// result; NEITHER is freed (either free is a hidden measurement, Rule 6/8).
//
// Correctness rests on the §8.2 register-threading trace, NOT on `opt -verify`
// (Rule 2). THE §8.5 cswap-arg0 SEAM (verify-clean-invisible): the route cswaps are
// NEVER fed to `emitInverseChain` — `emitInverseCall` may substitute a threaded
// handle into Args[0] (its `CurHandle` path, reserved for Phase-7), which for
// `cqrt_cswap` is the FLAG slot (a rail handle there is a wrong unitary). The
// reverse-play hands the inverter the BODY CHAIN ONLY (void `_unc` forms) and
// brackets the route cswaps itself via `emitRoute` (cswap is self-inverse), exactly
// as `emitValueRegion` does in `SwapRouteEmit.cpp`.

#include "SwitchRouteEmit.h"  // emitSwitchValueRegion (declared beside the phase emit)

#include "ArithLowering.h"     // rewriteBinary (the value-arm chain body, §4)
#include "ArmAnalysis.h"       // walkValueChain (re-derive each arm's chain at emit)
#include "CompareLowering.h"   // emitEqFlag
#include "ControlPlan.h"       // ControlRegion / SwitchArm / diagnoseUnderControl
#include "ControlledSymbols.h" // cswapFn / xFn (via emitRoute)
#include "EmitInverse.h"       // emitInverseChain (the body-chain reverse-play)
#include "OpcodeSupport.h"     // abiWidthFromType (the rail/copy width)
#include "RegionFlatten.h"     // flattenSwitchRegion
#include "SwapRouteEmit.h"     // emitRoute (the reused route/¬-bracket primitive)
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"     // allocFn / copyFn / freeFn / llvmWidthType

#include "llvm/ADT/STLExtras.h"  // llvm::reverse
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// so a later module walk (`lowerRotations` / `lowerOps` / `uncompute`) never
// dereferences freed memory (§6.1 — the dangling-work-list SIGSEGV). A per-TU
// mirror of `SwapRouteEmit::scrubTaint` (the house style for trivial taint-set
// maintenance — duplicated, not exported). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
  }
}

// Loud bail for a detection-guaranteed shape that did not hold at emit time. A
// silently skipped accepted region would hand the tainted `switch` to the backend
// as classical control over quantum state (the one unforgivable bug, Rule 1) — so
// anchor on whatever instruction is still available and decline.
void bailLoud(const ControlRegion &R) {
  if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
    diagnoseUnderControl(A, "control flow");
  else if (R.Merge)
    diagnoseUnderControl(R.Merge, "control flow");
}

// One content case's routed VALUE stream: the case literal (eq-flag source), the
// ordered ORIGINAL chain links (FORWARD/base-first order — erased after rewire),
// and the per-case state threaded through emission.
struct CaseStream {
  ConstantInt *Val = nullptr;
  SmallVector<Instruction *, 6> Chain;
  Value *Flag = nullptr;
  CallInst *Rail = nullptr;        // the case's |0> work rail (chain head; freed)
  SmallVector<CallInst *, 6> Fwd;  // minted forward template calls (forward stage)
};

}  // namespace

void emitSwitchValueRegion(const ControlRegion &R, WidthDispatch &wd,
                           ControlledSymbols &csyms, TaintSet &taint) {
  auto *MergePhi = dyn_cast_or_null<PHINode>(R.Merge);
  Value *Q = R.Condition;  // the scrutinee = the eq-flag source (NOT the routed base).
  if (!MergePhi || !Q || !R.Pred || !R.MergeBB || R.SwitchArms.empty())
    return bailLoud(R);

  // The `switch` terminator — every stream call lands before it, in the switch
  // block, so the routed stream executes unconditionally ahead of the (soon dead)
  // branch. Reading it off Pred keeps detection pure (no cached terminator).
  auto *SI = dyn_cast<SwitchInst>(R.Pred->getTerminator());
  if (!SI)
    return bailLoud(R);

  // Routed base `p` = the merge incoming on the SwitchBB→MergeBB (default-direct)
  // edge — the straight-through value, proven `!= q` by the C2 anchor
  // (`proveSwitchValue`). An empty default + any straight-to-merge case share this
  // one predecessor edge. Recover it here (not cached) so the emitter stays a pure
  // consumer of the by-identity plan.
  int STIdx = MergePhi->getBasicBlockIndex(R.Pred);
  Value *P = STIdx >= 0 ? MergePhi->getIncomingValue(STIdx) : nullptr;
  if (!P || P == Q)
    return bailLoud(R);

  // Recover + validate every CONTENT case's chain by re-walking (pure analysis,
  // idempotent — no mutation has happened for this region yet, so the walk returns
  // the same links `proveSwitchValue` accepted). Each off-pattern result bails
  // LOUDLY (detection proved the shape; this is the Rule-1 defensive bail, never a
  // silent skip).
  SmallVector<CaseStream, 4> Cases;
  for (const SwitchArm &Arm : R.SwitchArms) {
    if (!Arm.Block || Arm.Values.empty())
      continue;  // straight-to-merge / malformed — no chain to route.
    Value *Incoming = MergePhi->getIncomingValueForBlock(Arm.Block);
    if (!Incoming)
      return bailLoud(R);  // arm not a merge-phi pred — detection proved it is.
    if (Incoming == P)
      continue;  // passthrough case — routes `p` unchanged (no rail/route).
    ValueChain VC = walkValueChain(Incoming, Arm.Block, taint, P);
    if (VC.MixedPhi || VC.Base != P || VC.HasQQ || VC.Ops.empty())
      return bailLoud(R);  // not the proven pure linear chain bottoming at p.
    // Library-host parity (the twin-pipeline trap): a chain link
    // `declineStaleRecordOps` marked has already pledged "lower NOTHING";
    // replaying it onto the rail would break that pledge. `opt` exits at the stale
    // DS_Error first, so no lit fixture pins this — Rule-1 defensive bail.
    for (Instruction *Op : VC.Ops)
      if (taint.StaleDeclined.count(Op))
        return bailLoud(R);
    CaseStream CS;
    CS.Val = Arm.Values.front();
    CS.Chain.assign(VC.Ops.begin(), VC.Ops.end());
    Cases.push_back(std::move(CS));
  }
  if (Cases.empty())
    return bailLoud(R);  // no content — `proveSwitchValue` proved SawContent.

  // ONE width for the rails / copy-out, from the chain op's INTEGER SSA type —
  // reliable pre-RAUW (the ops still carry iN; §4 width-source). NEVER the scrutinee
  // suffix (q may be a derived handle) and never a classifying signal (the f64
  // trap). The positive integer fence already passed at G4, so a null here is a
  // malformed plan — bail LOUDLY.
  StringRef Abi = abiWidthFromType(Cases.front().Chain.front()->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Copy = Abi.empty() ? FunctionCallee() : wd.copyFn(Abi);
  if (!RailTy || !Alloc || !Copy)
    return bailLoud(R);

  const DebugLoc DL = SI->getDebugLoc();
  IRBuilder<> B(SI);  // every stream call lands before the `switch`.
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // ---- Forward stage (interleaved per case, §4B): mint flag → |0> rail →
  // route-in → chain VERBATIM on the rail → route-back. The eq-flags are mutually
  // exclusive, so the per-case routes commute and exactly one settles its answer
  // on `p`.
  for (CaseStream &CS : Cases) {
    // 1. Mint eq-flag — cq_template_icmp_eq_<Wq>_hl(q, c_i). Null only on an
    //    unsupported case-literal width; the literal shares the merge-phi width
    //    (G4-validated) so on an ACCEPTED region this is UNREACHABLE — kept as the
    //    Rule-1 defensive bail.
    CS.Flag = emitEqFlag(Q, CS.Val, wd, /*inverse=*/false, /*before=*/SI);
    if (!CS.Flag)
      return bailLoud(R);

    // 2. |0> work rail. Joins `taint.Tainted` so `rewriteBinary` classifies the
    //    retargeted first link as HL (handle + classical) — an untainted rail
    //    would misclassify BOTH operands classical and emit a wrong shape. Rail
    //    users are only cqrt_*/template calls, so `uncompute` never selects it
    //    (isTerminalHandle false).
    CS.Rail = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "rail");
    stamp(CS.Rail);
    taint.Tainted.insert(CS.Rail);
    taint.ControlOwnedRails.insert(CS.Rail);  // DD-4: Phase-4 owns this work rail

    // 3. Route-in (split). Eq-flags are positive-polarity (mutually exclusive) —
    //    no ¬-bracket (Negated=false), so one cswap.
    emitRoute(B, csyms, CS.Flag, P, CS.Rail, /*Negated=*/false, DL);

    // 4. Arm chain VERBATIM + UNCONTROLLED on its OWN rail. Per link in FORWARD
    //    (base-first) order: move to the stream position, retarget the FIRST link's
    //    routed-base operand `p` to the rail handle (later links already point at
    //    their predecessor, rewired by the previous RAUW), then REUSE
    //    `rewriteBinary` — it emits the cq_template_<op>_<W>_hl/_lh call immediately
    //    before the moved op, RAUWs, and bookkeeps taint (Rule 14). The minted call
    //    feeds the reverse-play; the now-use-empty original is erased after rewire.
    for (Instruction *Op : CS.Chain) {
      auto *BO = dyn_cast<BinaryOperator>(Op);
      if (!BO)
        return bailLoud(R);  // walkValueChain records only BinaryOperator links.
      BO->moveBefore(SI);
      if (CS.Fwd.empty())
        BO->replaceUsesOfWith(P, CS.Rail);
      if (!rewriteBinary(BO, wd, taint))
        return;  // already diagnosed (no template) — abort loudly.
      CS.Fwd.push_back(cast<CallInst>(BO->getPrevNode()));
    }

    // 5. Route-back (join = adjoint of the split, same flag — cswap self-inverse)
    //    with the chain-final rail handle. After all route-backs `p` holds the
    //    muxed answer (the matched case's swap moved it; the rest were identities).
    emitRoute(B, csyms, CS.Flag, P, CS.Fwd.back(), /*Negated=*/false, DL);
  }

  // 6. ONE B-keep copy-out: out := the basis-valued answer on `p` (after the
  //    route-backs, before any R†, which destroys it on p). `out` joins
  //    `taint.Tainted` (+BirthOrder) so the RAUW'd merge phi's consumers keep
  //    classifying it as a quantum handle. NEVER free `out`, NEVER free `p`.
  CallInst *Out = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "out");
  stamp(Out);
  CallInst *CopyCall = B.CreateCall(Copy, {P, Out});
  stamp(CopyCall);
  taint.Tainted.insert(Out);
  taint.ControlOwnedRails.insert(Out);  // DD-4: Phase-4 owns this merge out-rail
  taint.BirthOrder[Out] = taint.NextBirth++;
  // bd p119.8 (same gap as p119.6): record the out-rail's LOGICAL ABI width (=
  // `Abi`, the routed value-arm width) so a DOWNSTREAM cast/Q+Q-compare off the
  // RAUW'd merge recovers the real width instead of the laundered i32 (a non-i32
  // value merge feeding `trunc`/a Q+Q compare otherwise over-declines). `Abi` is
  // non-empty (the width guard above bailed otherwise).
  taint.HandleWidth[Out] = Abi;

  // 7. Reverse-play R†, per case in REVERSE emission order (LIFO). Per case:
  //    route-back† (cswap on the chain-final handle), then the chain adjoint in
  //    exact reverse via the void `_unc` forms — the BODY CHAIN ONLY through
  //    `emitInverseChain` (the §8.5 seam: never feed route cswaps to the inverter,
  //    which would thread a rail handle into cqrt_cswap's FLAG slot) — then
  //    route-in† on the case's work rail (the chain head, restored to |0>).
  for (CaseStream &CS : reverse(Cases)) {
    Value *ChainFinal = CS.Fwd.back();
    emitRoute(B, csyms, CS.Flag, P, ChainFinal, /*Negated=*/false, DL);  // route-back†
    if (!emitInverseChain(B, CS.Fwd, wd))                               // R† (void `_unc`)
      return bailLoud(R);  // un-invertible link — never a half-reversed stream.
    // Route-in† on the case's WORK RAIL (`CS.Rail`): the void `_unc` chain zeroed
    // the intermediate rails in place but never touched `CS.Rail` (the chain head,
    // read by the first link), which still holds the routed value p0. The cswap
    // moves p0 back onto P (P == p0) AND returns `CS.Rail` to |0> for a clean free
    // (§3b). Under the old fresh-minting `_inv` this was the threaded `RailFinal`;
    // the void ABI mints no handle, so the chain-head rail IS `CS.Rail`.
    emitRoute(B, csyms, CS.Flag, P, CS.Rail, /*Negated=*/false, DL);    // route-in†
  }

  // 8. Rail frees, same reverse order, each on its case's WORK RAIL (`CS.Rail`) —
  //    provably |0> on every case only AFTER its route-in† (§3b: earlier the rail
  //    holds p0 / f(0) garbage entangled with its flag; a dirty free is a hidden
  //    measurement). The void-`_unc`-zeroed intermediate rails are left allocated
  //    (the accepted leak until the WI-4 whole-DAG per-rail free; Rule 6).
  for (CaseStream &CS : reverse(Cases)) {
    CallInst *RailFree = B.CreateCall(wd.freeFn(), {CS.Rail});
    stamp(RailFree);
  }

  // 9. Flag strip + free. `icmp_inv(q, c_i)` reads pristine `q` (q == q0 — the
  //    value routing threads `p`, never `q`), so the flag returns to |0> with zero
  //    controlled gates. Each strip reads the same pristine `q`, so the order is
  //    free; flow forward to mirror the per-case mint order.
  for (CaseStream &CS : Cases) {
    emitEqFlag(Q, CS.Val, wd, /*inverse=*/true, /*before=*/SI);
    CallInst *FlagFree = B.CreateCall(wd.freeFn(), {CS.Flag});
    stamp(FlagFree);
  }

  // 10. Rewire + erase + scrub + flatten. The measure on the phi becomes a measure
  //     on `out` (the copied answer). Erase each case's chain originals in REVERSE
  //     lineage order so each is use-empty when erased (the chains are disjoint, so
  //     the case order is free — keep the step-7 LIFO); scrub every erased
  //     instruction from all taint work-lists incl. StaleDeclined (§6.1). `p` and
  //     `out` are never freed.
  MergePhi->replaceAllUsesWith(Out);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  for (CaseStream &CS : reverse(Cases))
    for (Instruction *Op : reverse(CS.Chain)) {
      scrubTaint(Op, taint);
      Op->eraseFromParent();
    }
  flattenSwitchRegion(R, taint);
}

}  // namespace cq
