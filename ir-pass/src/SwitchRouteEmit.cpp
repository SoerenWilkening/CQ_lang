// SwitchRouteEmit.cpp — see header. The mutating swap-route emitter for an
// accepted tainted `switch` region. WI-2 lands the PHASE class
// (`emitSwitchPhaseRegion`): the N-way generalization of the 4.1 phase diamond
// (`SwapRouteEmit::emitRegion`) — per content case, mint an eq-flag, route the
// scrutinee into a |0> rail under that flag, replay the folded gate's ANGLE
// (arg-1) verbatim/uncontrolled on the rail, route back, free the rail, strip +
// free the flag. ZERO controlled gates beyond the route cswaps; the scrutinee
// `q` is never freed (the live result).
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2).
// The eq-flags f_i = (q == c_i) are MUTUALLY EXCLUSIVE (q equals at most one
// case literal), so each case's route fires only when q == c_i; off-case the
// rail stays |0> and Rz|0>=|0> is a no-op. Each case's route-back restores q's
// basis value (cswap is self-inverse), so the NEXT case's eq-flag — and the
// final icmp_inv strip — read the pristine q (Rz preserves the basis value,
// q == q0). Phases accumulate on q; the rail and flag return to |0> for free.
//
// THE BLOCKER (§5, verify-clean-invisible, no downstream backstop): `clang -O1`
// folds each phase arm gate to `cq_phi(i32 c_i, θ_i)` — arg-0 is the CASE
// LITERAL, not q. If such a gate survives to `lowerRotations`
// (CQLoweringPass.cpp:110), RotationLowering reads arg-0 (untainted) → emits no
// rz, then RAUWs the gate result to the constant c_i → the merge phi degenerates
// into a verify-clean WRONG data-mux. The fix is OWNED HERE, executed DURING emit
// (before rotations, in both orchestrator entry points): (1) re-anchor by physics
// — step 4 reads ONLY arg-1, never RAUWs arg-0; (2) scrub+erase each folded gate
// (incl. its `taint.PhiCalls` removal) BEFORE the N-way flatten / rotations.

#include "SwitchRouteEmit.h"

#include "CompareLowering.h"     // emitEqFlag
#include "ControlPlan.h"         // ControlRegion / SwitchArm / diagnoseUnderControl
#include "ControlledSymbols.h"   // cswapFn / xFn (via emitRoute)
#include "OpcodeSupport.h"       // abiWidthFromType (the rail/rz width)
#include "RegionFlatten.h"       // flattenSwitchRegion
#include "SwapRouteEmit.h"       // collectArmPhis / emitRoute (reused primitives)
#include "TaintPropagation.h"    // TaintSet
#include "WidthDispatch.h"       // allocFn / rzRtFn / freeFn / llvmWidthType

#include "llvm/ADT/STLExtras.h"   // llvm::reverse
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
// maintenance — duplicated, not exported). Idempotent. The `PhiCalls` removal is
// load-bearing for the §5 re-anchor: a folded `cq_phi` left in `taint.PhiCalls`
// is re-walked by `lowerRotations` and RAUW'd to its (constant) arg-0.
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
// silently skipped accepted region would hand the tainted `switch` to the
// backend as classical control over quantum state (the one unforgivable bug,
// Rule 1) — so anchor on whatever instruction is still available and decline.
void bailLoud(const ControlRegion &R) {
  if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
    diagnoseUnderControl(A, "control flow");
  else if (R.Merge)
    diagnoseUnderControl(R.Merge, "control flow");
}

}  // namespace

void emitSwitchPhaseRegion(const ControlRegion &R, WidthDispatch &wd,
                           ControlledSymbols &csyms, TaintSet &taint) {
  auto *MergePhi = dyn_cast_or_null<PHINode>(R.Merge);
  Value *Q = R.Condition;  // routed base = the scrutinee (§4A).
  if (!MergePhi || !Q || !R.Pred || !R.MergeBB || R.SwitchArms.empty())
    return bailLoud(R);

  // The `switch` terminator — every stream call lands before it, in the switch
  // block, so the routed stream executes unconditionally ahead of the (soon
  // dead) branch. Reading it off Pred keeps detection pure (no cached
  // terminator).
  auto *SI = dyn_cast<SwitchInst>(R.Pred->getTerminator());
  if (!SI)
    return bailLoud(R);

  // ONE width for the rail / rz / free. By `proveSwitchPhase` the merge-phi type
  // equals each folded gate's (cq_phi) type equals each case literal's type
  // equals the scrutinee's type — so this single width is the rotation width too,
  // and `emitEqFlag` (which derives the FLAG width from each case literal) mints
  // the byte-identical width. Never read width off Q's SSA type when Q is a
  // derived handle (§4 width-source) — but the merge-phi type is reliable here
  // (its straight-through incoming IS Q, proven == the scrutinee).
  StringRef Abi = abiWidthFromType(MergePhi->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Rz = Abi.empty() ? FunctionCallee() : wd.rzRtFn(Abi);
  if (!RailTy || !Alloc || !Rz)
    return bailLoud(R);  // unsupported width past detection — never silent.

  const DebugLoc DL = SI->getDebugLoc();
  IRBuilder<> B(SI);  // every stream call lands before the `switch`.

  // The folded `cq_phi(c_i,θ_i)` gates across ALL content arms, to scrub+erase
  // AFTER the rewire (the §5 re-anchor). Each arm's spine is independent (bottoms
  // at its own case literal in its own block), so a global reverse-erase is
  // per-arm reverse-lineage.
  SmallVector<CallInst *, 8> AllPhis;

  for (const SwitchArm &Arm : R.SwitchArms) {
    BasicBlock *ArmBB = Arm.Block;
    if (!ArmBB || Arm.Values.empty())
      continue;  // straight-to-merge / malformed — nothing to route.
    Value *Incoming = MergePhi->getIncomingValueForBlock(ArmBB);
    if (!Incoming)
      continue;
    SmallVector<CallInst *, 4> Phis = collectArmPhis(Incoming, ArmBB);
    if (Phis.empty())
      continue;  // empty passthrough arm — routes q unchanged (no rail/route).
    ConstantInt *CaseVal = Arm.Values.front();

    // 1. Mint eq-flag — cq_template_icmp_eq_<W>_hl(q, c_i). `emitEqFlag` nulls
    //    only on an unsupported case-literal width — but the case literal shares
    //    the merge-phi type (`proveSwitchPhase`'s width guard) whose width was
    //    already validated above (RailTy/Alloc/Rz non-null), so on an ACCEPTED
    //    region this is UNREACHABLE. Kept as the Rule-1 defensive bail (never
    //    silently skip), matching the `emitRegion`/`emitValueRegion` house
    //    pattern: a mid-loop bail leaves the per-case stream emitted so far
    //    standing, but `diagnoseUnderControl` is a DS_Error so the `opt` host
    //    exits before `lowerRotations` runs — no folded gate can degenerate.
    Value *Flag = emitEqFlag(Q, CaseVal, wd, /*inverse=*/false, /*before=*/SI);
    if (!Flag)
      return bailLoud(R);

    // 2. |0> work rail.
    CallInst *Rail =
        B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "rail");
    if (DL)
      Rail->setDebugLoc(DL);

    // 3. Route-in. Eq-flags are positive-polarity (mutually exclusive) — no
    //    ¬-bracket (Negated=false), so one cswap.
    emitRoute(B, csyms, Flag, Q, Rail, /*Negated=*/false, DL);

    // 4. Replay — ARG-1 (angle) ONLY (the §5 re-anchor by physics; arg-0 = the
    //    case literal is DISCARDED, never RAUW'd). One rz per folded gate on the
    //    spine, in forward program order.
    for (CallInst *Phi : Phis) {
      CallInst *RzCall = B.CreateCall(Rz, {Rail, Phi->getArgOperand(1)});
      if (DebugLoc PDL = Phi->getDebugLoc())
        RzCall->setDebugLoc(PDL);
    }

    // 5. Route-back (join = adjoint of the split, same flag — cswap is
    //    self-inverse).
    emitRoute(B, csyms, Flag, Q, Rail, /*Negated=*/false, DL);

    // 6. Free rail — provably |0> (off-case the rail never moved; on-case the
    //    route round-trips a basis permutation and Rz|0>=|0>). A clean reset, NOT
    //    a measurement (SCOPING §3b).
    CallInst *RailFree = B.CreateCall(wd.freeFn(), {Rail});
    if (DL)
      RailFree->setDebugLoc(DL);

    // 7. Strip flag — q == q0 (Rz preserves the basis value), so icmp_inv(q,c_i)
    //    returns the flag to |0> with zero controlled gates.
    emitEqFlag(Q, CaseVal, wd, /*inverse=*/true, /*before=*/SI);

    // 8. Free flag.
    CallInst *FlagFree = B.CreateCall(wd.freeFn(), {Flag});
    if (DL)
      FlagFree->setDebugLoc(DL);

    AllPhis.append(Phis.begin(), Phis.end());
  }

  // 9. Rewire + re-anchor SCRUB + flatten. The merge phi's value is now just `q`
  //    (a phase arm preserves q's basis identity on every edge), so a measure on
  //    the phi becomes a measure on q. RAUW → q, scrub+erase the phi, THEN
  //    scrub+erase each folded `cq_phi` in REVERSE lineage order (each is
  //    use-empty once the merge phi is gone) — this is the §5 re-anchor: the
  //    `PhiCalls` removal stops `lowerRotations` from RAUW'ing a surviving folded
  //    gate to its constant arg-0 (the BLOCKER). Then flatten the N-way CFG.
  MergePhi->replaceAllUsesWith(Q);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  for (CallInst *Phi : reverse(AllPhis)) {
    scrubTaint(Phi, taint);
    Phi->eraseFromParent();
  }
  flattenSwitchRegion(R, taint);
}

}  // namespace cq
