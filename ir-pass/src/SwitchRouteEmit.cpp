// SwitchRouteEmit.cpp — see header. The emitter for an accepted tainted-`switch`
// PHASE region.
//
// ⚠ THE SWAP ROUTE IS GONE FROM THIS FILE (bd test_C_libtooling-3qlq Inc 1 part
// B, PRD `retire-swap-route-PRD.md` §5/§6.2 row P5). What used to be here — per
// content case, mint an eq-flag, `cqrt_cswap` the scrutinee into a `|0>` work
// rail under it, replay the folded gate's arg-1 angle as a TENSORED
// `cqrt_rz_<W>` on that rail, route back, free the rail, strip, free the flag —
// is REPLACED by the register-free KICKBACK: mint the eq-flag, put the case's
// phases on THE FLAG with `cqrt_rz_i1`, strip, free. No work rail, no
// `cqrt_cswap`, and `cqrt_rz_i1` is the ONLY Rz this pass emits after 3qlq.
//
// WHY THE OLD FORM HAD TO GO, and it is not a cost argument. `cqrt_rz_<W>` is
// TENSORED — an Rz on each of W qubits — so routing `q` into a rail and applying
// it puts phase `(-1)^popcount(k_i)` on the marked branch and CANNOT mark
// `|0..0>` at all. Every golden the routed form ever produced was the identity
// on `q` (PRD §1). The kickback is the fix: with `f_i = (q == k_i)` in a |0>
// ancilla the state is `Σ a_x |x>|c_i(x)>`, a diagonal `P(θ_i)` ON THE ANCILLA
// gives `Σ a_x e^{iθ_i c_i(x)} |x>|c_i(x)>`, and the `_unc` strip — a
// permutation `|x, c_i(x)> → |x, 0>` — returns the ancilla to |0> on EVERY
// branch, leaving the phase on the branch.
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2).
// The eq-flags are MUTUALLY EXCLUSIVE (`q` equals at most one case literal) and
// NOTHING here takes `q` as anything but a compare operand, so each case's
// phases land on exactly its own branch and every later mint — and every strip —
// reads the pristine `q`. Each flag is minted at |0> and returned to |0> by its
// own strip on the line above its free, so every `cqrt_free` is a clean reset
// and never a hidden measurement (Rule 6). Nothing is copied, so Rule 8 has no
// subject.
//
// THE §5 CONST-FOLD RE-ANCHOR SCRUB IS RETIRED WITH THE ROUTE. Its blocker was
// that `clang -O1` folds an arm gate's arg-0 handle to the case literal, so a
// surviving `cq_phi(i32 c_i, θ_i)` would RAUW the merge φ to a constant — a
// verify-clean wrong data mux with no downstream backstop. A register-free
// `cq_phi(double)` has no arg-0 to fold and this region has no merge φ to
// degenerate. The gates are still scrubbed from `taint.PhaseCalls` before they
// are erased, but for the ordinary dangling-pointer reason every emitter has.

#include "SwitchRouteEmit.h"

#include "CompareLowering.h"     // emitEqFlag
#include "ControlPlan.h"         // ControlRegion / SwitchArm / diagnoseUnderControl
#include "RegionFlatten.h"       // flattenSwitchRegion
#include "TaintPropagation.h"    // TaintSet
#include "ChainWalk.h"           // markBranchPhaseGate (3qlq Inc 1 F-L7-1)
#include "WidthDispatch.h"       // rzRtFn / freeFn

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
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
    auto &PhC = taint.PhaseCalls;
    PhC.erase(std::remove(PhC.begin(), PhC.end(), CI), PhC.end());
  }
}

// Loud bail for a detection-guaranteed shape that did not hold at emit time. A
// silently skipped accepted region would hand the tainted `switch` to the
// backend as classical control over quantum state (the one unforgivable bug,
// Rule 1) — so anchor on whatever instruction is still available and decline.
void bailLoud(const ControlRegion &R) {
  if (R.Pred)
    if (auto *SI = dyn_cast_or_null<SwitchInst>(R.Pred->getTerminator()))
      return diagnoseUnderControl(SI, "control flow");
  if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
    diagnoseUnderControl(A, "control flow");
}

}  // namespace

void emitSwitchPhaseRegion(const ControlRegion &R, WidthDispatch &wd,
                           ControlledSymbols &csyms, TaintSet &taint) {
  (void)csyms;  // no route, no bracket: the kickback needs no controlled symbol.
  Value *Q = R.Condition;  // the scrutinee — a compare operand and NOTHING else.
  if (!Q || !R.Pred || !R.MergeBB || R.SwitchArms.empty())
    return bailLoud(R);
  // ⚠ `R.Merge` MUST BE NULL. It is the marker of the register-free shape that
  // `classifyPhaseKickbackSwitch` accepts, and a non-null φ here would mean the
  // plan came from somewhere that expected the retired routed lowering — decline
  // rather than flatten over a φ nobody will dissolve (a φ left standing in a
  // spliced-away block is a BROKEN MODULE at `opt` exit 0).
  if (R.Merge)
    return bailLoud(R);

  // The `switch` terminator — every emitted call lands before it, in the switch
  // block, so the whole stream executes unconditionally ahead of the (soon dead)
  // terminator. Read off `Pred` so detection stays pure (no cached terminator).
  auto *SI = dyn_cast<SwitchInst>(R.Pred->getTerminator());
  if (!SI || SI->getCondition() != Q)
    return bailLoud(R);

  // ---- 0. RE-VALIDATE BY SSA IDENTITY BEFORE MUTATING ANYTHING (the Inc-2a
  // round-1 F-5 discipline: every decline precedes the FIRST emission).
  FunctionCallee Rz = wd.rzRtFn("i1");  // the ONLY Rz this pass emits (PRD §5).
  if (!Rz)
    return bailLoud(R);
  for (const SwitchArm &Arm : R.SwitchArms) {
    if (!Arm.Block || Arm.Values.size() != 1 || !Arm.Values.front())
      return bailLoud(R);
    for (Instruction *I : Arm.Shadow) {
      auto *CI = dyn_cast<CallInst>(I);
      if (!CI || CI->getParent() != Arm.Block || CI->arg_size() != 1)
        return bailLoud(R);
      // The ANGLE must be defined OUTSIDE the arm — an EMISSION fact (the gate
      // is hoisted to the switch, so the angle has to dominate it) rather than
      // an inherited one, so it is re-asked here.
      if (auto *AngI = dyn_cast<Instruction>(CI->getArgOperand(0)))
        if (AngI->getParent() == Arm.Block)
          return bailLoud(R);
    }
  }

  // ---- EMISSION STARTS HERE. Nothing below may decline.
  const DebugLoc DL = SI->getDebugLoc();
  IRBuilder<> B(SI);
  SmallVector<CallInst *, 8> AllGates;

  for (const SwitchArm &Arm : R.SwitchArms) {
    if (Arm.Shadow.empty())
      continue;  // an EMPTY `case k: break;` — no gate, nothing to mint.
    ConstantInt *CaseVal = Arm.Values.front();

    // 1. MINT the eq-flag `cq_template_icmp_eq_<W>_hl(q, k_i)`. Detection proved
    //    every case literal's width, so a null here is drift — but it is still a
    //    decline and never a silent skip. It is also a MID-STREAM bail once a
    //    previous case has emitted, which is why the width was asked at
    //    detection; the outcome is a `DS_Error`, so `opt` exits before anything
    //    downstream consumes the half-stream.
    Value *Flag = emitEqFlag(Q, CaseVal, wd, /*inverse=*/false, /*before=*/SI);
    if (!Flag)
      return bailLoud(R);

    // 2. THE PHASES, on the FLAG, uncontrolled, in source order. N gates need no
    //    arithmetic: each angle is passed through VERBATIM and
    //    `P(θ_1)·P(θ_2) = P(θ_1+θ_2)` happens in the hardware, not in this
    //    compiler (the same argument the flat kickback's N-gate arm rests on).
    //    There is NO `cqrt_x` bracket anywhere: an eq-flag is positive-polarity
    //    by construction, so no case ever fires on a negation.
    for (Instruction *I : Arm.Shadow) {
      CallInst *RzCall =
          B.CreateCall(Rz, {Flag, cast<CallInst>(I)->getArgOperand(0)});
      if (DebugLoc GDL = I->getDebugLoc())
        RzCall->setDebugLoc(GDL);
      // RECORDED as a branch-phase (kickback) gate — bd 3qlq Inc 1, Rule-13
      // round-1 finding F-L7-1. Identical reason to the flat and nest emitters:
      // without the record `ChainWalk::isInPlaceGateOn` reads this as an
      // ordinary in-place rotation on the eq-flag rail, the gate joins
      // `D.Calls`, and the whole-DAG spine emits `cqrt_rz_i1(f, -θ)` — which
      // cancels the user's phase EXACTLY, since both gates are diagonal in the
      // same basis label. EVERY `cqrt_rz_i1` this pass emits must carry it.
      markBranchPhaseGate(RzCall);
      AllGates.push_back(cast<CallInst>(I));
    }

    // 3. STRIP + FREE. The strip recomputes `q == k_i` and XORs it back onto the
    //    flag, returning it to |0> so the free is clean (Rule 6). Its validity is
    //    unconditional in a way no routed form could claim: this region emits NO
    //    gate on `q` at all, so the basis the strip reads is identically the
    //    basis the mint read. Recorded in `DischargedFlagGates` — the channel
    //    that lets the whole-DAG spine discharge a DERIVED scrutinee's chain past
    //    the strip (`ChainWalk::isInteriorConsumer`); the routed form recorded
    //    nothing, which left `switch (q*3)` with an undischarged chain.
    auto *Strip = dyn_cast_or_null<CallInst>(
        emitEqFlag(Q, CaseVal, wd, /*inverse=*/true, /*before=*/SI,
                   /*railToStrip=*/Flag));
    if (Strip)
      taint.DischargedFlagGates.insert(Strip);
    CallInst *FlagFree = B.CreateCall(wd.freeFn(), {Flag});
    if (DL)
      FlagFree->setDebugLoc(DL);
  }

  // ---- 4. ERASE THE ARM CALLS, THEN FLATTEN. Each call is erased rather than
  // hoisted: its whole content is a `cqrt_rz_i1` above. Scrub from `PhaseCalls`
  // first so `deleteGlobalPhases` — which derives its survivors from the IR —
  // and any later module walk cannot dereference freed memory. There is no merge
  // φ to RAUW and no folded arg-0 to re-anchor: both were consequences of the
  // register form.
  for (CallInst *G : reverse(AllGates)) {
    scrubTaint(G, taint);
    G->eraseFromParent();
  }
  flattenSwitchRegion(R, taint);
}

}  // namespace cq
