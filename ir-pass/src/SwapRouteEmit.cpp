// SwapRouteEmit.cpp — see header. The mutating swap-route emitter for accepted
// phase-arm diamond regions. Emits the coherent, zero-controlled-gate routed
// stream of SCOPING §3a in the §5 contract order, then rewires + flattens.
//
// Correctness rests on statevector reasoning, NOT on `opt -verify` (Rule 2):
//   `(|0> + |1>)/√2 ⊗ |0>_f` ─route+Rz+route→ `(|0>|0>_f + e^{iθ}|1>|1>_f)/√2`
//   ─icmp_inv(q)→ `(|0> + e^{iθ}|1>)/√2 ⊗ |0>_f`: the rail returns to |0>
//   UNCONDITIONALLY (Rz|0>=|0>), q keeps the conditional phase, and the flag is
//   stripped because Rz preserves q's basis value (q == q0). Zero `_controlled`
//   gates, no added measurement (SCOPING §3a/§3b).

#include "SwapRouteEmit.h"

#include "CompareLowering.h"     // lowerCompareToFlag
#include "ControlPlan.h"         // ControlRegion / ControlPlan
#include "ControlledSymbols.h"   // cswapFn / xFn
#include "RegionFlatten.h"       // flattenRegion
#include "TaintPropagation.h"    // TaintSet
#include "WidthDispatch.h"       // allocFn / rzRtFn / freeFn / abiWidthFor

#include "llvm/ADT/STLExtras.h"   // llvm::reverse
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
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
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

// Walk the arm's merge contribution back along its phase spine, collecting the
// `@cq_phi` (Rz) calls in FORWARD program order (first gate applied first). The
// chain is `qN = cq_phi(q{N-1}, angle)`; the back-walk hops arg-0 handles, so
// reversing it yields forward order. An empty result means a degenerate empty
// arm (`if (q) {}`) — handled by the caller.
SmallVector<CallInst *, 4> collectArmPhis(Value *ArmIncoming) {
  SmallVector<CallInst *, 4> Phis;
  for (Value *V = ArmIncoming; isPhiCall(V);) {
    auto *CI = cast<CallInst>(V);
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
// the-split property (SCOPING §2).
void emitRoute(IRBuilder<> &B, const ControlledSymbols &csyms, Value *Flag,
               Value *Q, Value *Rail, bool Negated, const DebugLoc &DL) {
  FunctionCallee Cswap = csyms.cswapFn();
  FunctionCallee X = csyms.xFn();
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };
  if (Negated)
    stamp(B.CreateCall(X, {Flag}));
  stamp(B.CreateCall(Cswap, {Flag, Q, Rail}));
  if (Negated)
    stamp(B.CreateCall(X, {Flag}));
}

// Lower one accepted phase-arm diamond region (the §5a contract) to the
// swap-route stream, emitted into the pred block before the conditional `br`.
void emitDiamond(const ControlRegion &R, WidthDispatch &wd,
                 const ControlledSymbols &csyms, TaintSet &taint) {
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  auto *MergePhi = dyn_cast_or_null<PHINode>(R.Merge);
  if (!Cond || !MergePhi || !R.Pred || !R.Arm)
    return;  // detection guarantees the shape; bail defensively.
  auto *BI = dyn_cast<BranchInst>(R.Pred->getTerminator());
  if (!BI)
    return;

  // The routed handle: the diamond's straight-through (Pred-edge) incoming — the
  // live quantum register the arm's phases must land on. The arm's ordered phase
  // gates: the Rz chain on the arm-edge incoming.
  Value *Q = MergePhi->getIncomingValueForBlock(R.Pred);
  SmallVector<CallInst *, 4> ArmPhis =
      collectArmPhis(MergePhi->getIncomingValueForBlock(R.Arm));

  // Empty arm (`if (q) {}`) — the arm contributes no gate, so the merge phi is
  // just `q` on both edges (classifyArms accepted it because Base == Routed ==
  // Q). It is pure identity: route NOTHING (no flag, no rail, no strip — there is
  // no quantum op to control), just RAUW the phi to q and flatten the dead CFG.
  // This is both correct and avoids needing a rotation width for a gate-free arm.
  if (ArmPhis.empty()) {
    MergePhi->replaceAllUsesWith(Q);
    scrubTaint(MergePhi, taint);
    MergePhi->eraseFromParent();
    flattenRegion(R, taint);
    return;
  }

  // ABI width: from the arm cq_phi suffix — the rotation width. The routed
  // handle MAY be a value DERIVED before the region (its own suffix is
  // unreliable), so never read width off Q (§4 width-source). ArmPhis is
  // non-empty here (the empty arm returned above).
  StringRef Abi = wd.abiWidthFor(intrinsicSuffix(ArmPhis.front(), "cq_phi_"));
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Rz = Abi.empty() ? FunctionCallee() : wd.rzRtFn(Abi);
  if (!RailTy || !Alloc || !Rz)
    return;  // unsupported width — detection should not have accepted; leave it.

  const DebugLoc DL = BI->getDebugLoc();
  IRBuilder<> B(BI);  // every stream call lands before the conditional br.

  // 1. Flag mint — cq_template_icmp_<pred>_<W>_hl(q, lit).
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).

  // 2. |0> work rail.
  CallInst *Rail = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "rail");
  if (DL)
    Rail->setDebugLoc(DL);

  // 3. Route-in (split).
  emitRoute(B, csyms, Flag, Q, Rail, R.ArmNegated, DL);

  // 4. Arm body, VERBATIM and UNCONTROLLED, on the rail.
  for (CallInst *Phi : ArmPhis) {
    CallInst *RzCall = B.CreateCall(Rz, {Rail, Phi->getArgOperand(1)});
    if (DebugLoc PDL = Phi->getDebugLoc())
      RzCall->setDebugLoc(PDL);
  }

  // 5. Route-back (join = adjoint of the split, same flag + bracket).
  emitRoute(B, csyms, Flag, Q, Rail, R.ArmNegated, DL);

  // 6. Rail free — the rail is |0> for free (Rz|0>=|0>); a clean reset, NOT a
  //    measurement (SCOPING §3b).
  CallInst *RailFree = B.CreateCall(wd.freeFn(), {Rail});
  if (DL)
    RailFree->setDebugLoc(DL);

  // 7. Flag strip — q == q0 (Rz preserves the basis value), so icmp_inv(q)
  //    returns the flag to |0> with zero controlled gates. Reads `Cond`'s
  //    operands, so it MUST precede the erase of `Cond` (in flattenRegion).
  lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                     /*before=*/BI);

  // 8. Flag free.
  CallInst *FlagFree = B.CreateCall(wd.freeFn(), {Flag});
  if (DL)
    FlagFree->setDebugLoc(DL);

  // 9. Rewire + erase + scrub, then flatten the CFG. The merge phi's value is now
  //    just `q` (a phase arm preserves q's basis identity), so a measure on the
  //    phi becomes a measure on q. Erase the arm cq_phi in REVERSE lineage order
  //    so each is use-empty when erased; scrub every erased instruction (§6.1).
  MergePhi->replaceAllUsesWith(Q);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  for (CallInst *Phi : reverse(ArmPhis)) {
    scrubTaint(Phi, taint);
    Phi->eraseFromParent();
  }
  flattenRegion(R, taint);
}

}  // namespace

void lowerControlRegions(Module &M, WidthDispatch &wd, TaintSet &taint,
                         const ControlPlan &plan) {
  if (plan.Regions.empty())
    return;  // nothing accepted — classical / fully-declined module untouched.
  ControlledSymbols csyms(M, wd);
  for (const ControlRegion &R : plan.Regions)
    emitDiamond(R, wd, csyms, taint);
}

}  // namespace cq
