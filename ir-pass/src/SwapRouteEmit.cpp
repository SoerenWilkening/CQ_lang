// SwapRouteEmit.cpp — see header. The mutating swap-route emitter for accepted
// phase-arm regions — a one-content-arm diamond (§5a) or a two-arm if/else
// (§5b), lowered by one arm-list-parameterized procedure. Emits the coherent,
// zero-controlled-gate routed stream of SCOPING §3a in the §5 contract order
// (an if/else routes BOTH arms to distinct rails, the else under ¬flag via the
// cqrt_x bracket), then rewires + flattens.
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

// Walk the arm's merge contribution back along its IN-BLOCK phase spine,
// collecting the `@cq_phi` (Rz) calls DEFINED IN `ArmBB` in FORWARD program order
// (first gate applied first). The chain is `qN = cq_phi(q{N-1}, angle)`; the
// back-walk hops arg-0 handles, so reversing it yields forward order. An empty
// result means a degenerate gate-free arm (`if (q) {}` / an empty else) — handled
// by the caller.
//
// The walk STOPS at the arm-block boundary: a `cq_phi` defined OUTSIDE `ArmBB` is
// a pre-region rotation — the live DERIVED base handle the region ROUTES
// (accepted since test_C_libtooling-9hh), NOT an arm gate. It stays in
// `taint.PhiCalls`, so `lowerRotations` lowers it as an ordinary unconditional
// Rz at its own (pre-stream) position and RAUWs it to the same i32 handle as its
// theta. Bounding here is load-bearing (Rule 10): an unbounded walk would
// collect a pre-region phi SHARED by both arms once per arm, and the §6.1
// reverse-erase would double-free it (SIGSEGV — the WI-3 crash). Keeping the
// per-arm gate list strictly in-block makes that impossible.
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

// One content arm's routed phase stream: whether it fires on ¬flag (X-bracketed
// cswap) and its ordered Rz gates to replay verbatim on its own work rail.
struct ArmStream {
  bool Negated;
  SmallVector<CallInst *, 4> Phis;
};

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
                const ControlledSymbols &csyms, TaintSet &taint) {
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
  struct ArmInfo {
    BasicBlock *BB;
    bool Negated;
  };
  SmallVector<ArmInfo, 2> Arms;
  if (R.ArmFalse) {
    Arms.push_back({R.Arm, /*Negated=*/false});
    Arms.push_back({R.ArmFalse, /*Negated=*/true});
  } else {
    Arms.push_back({R.Arm, R.ArmNegated});
  }

  // The routed handle Q: a diamond's straight-through (Pred-edge) incoming, or —
  // for an if/else, which has no Pred edge — the shared phase-spine base the arms
  // rotate. Never read width/identity off Q's SSA type (§4 width-source); Q is
  // only the cswap data operand.
  Value *Q = MergePhi->getBasicBlockIndex(R.Pred) >= 0
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

  // 1. Flag mint — cq_template_icmp_<pred>_<W>_hl(q, lit).
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).

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
  for (size_t I = 0; I < Streams.size(); ++I)
    emitRoute(B, csyms, Flag, Q, Rails[I], Streams[I].Negated, DL);

  // 4. Arm bodies, VERBATIM and UNCONTROLLED, each on its OWN rail.
  for (size_t I = 0; I < Streams.size(); ++I)
    for (CallInst *Phi : Streams[I].Phis) {
      CallInst *RzCall = B.CreateCall(Rz, {Rails[I], Phi->getArgOperand(1)});
      if (DebugLoc PDL = Phi->getDebugLoc())
        RzCall->setDebugLoc(PDL);
    }

  // 5. Route-back (join = adjoint of the split, same flag + brackets).
  for (size_t I = 0; I < Streams.size(); ++I)
    emitRoute(B, csyms, Flag, Q, Rails[I], Streams[I].Negated, DL);

  // 6. Rail frees — each rail is |0> for free (Rz|0>=|0>); a clean reset, NOT a
  //    measurement (SCOPING §3b).
  for (Value *Rail : Rails) {
    CallInst *RailFree = B.CreateCall(wd.freeFn(), {Rail});
    if (DL)
      RailFree->setDebugLoc(DL);
  }

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
  for (CallInst *Phi : reverse(AllPhis)) {
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

  // Pre-flight, while EVERY region's blocks are still valid (the block-lifetime
  // rule): no accepted region may reference a block that flattening another
  // accepted region will erase (its Arm/ArmFalse/MergeBB). Detection forecloses
  // the known sequential layouts (an if/else or diamond merge hosting the next
  // tainted branch declines as nested), so this should be unreachable — but a
  // future shape that slips through must decline LOUDLY here, not dereference
  // freed memory in emitRegion (the §8-confirmed sequential-region SIGSEGV
  // family, 2026-06-10). Pointer-identity checks only; nothing is dereferenced.
  for (const ControlRegion &A : plan.Regions)
    for (const ControlRegion &B : plan.Regions) {
      if (&A == &B)
        continue;
      for (BasicBlock *Doomed : {B.Arm, B.ArmFalse, B.MergeBB}) {
        if (!Doomed)
          continue;
        if (A.Pred == Doomed || A.Arm == Doomed || A.ArmFalse == Doomed ||
            A.MergeBB == Doomed) {
          if (auto *Anchor = dyn_cast_or_null<Instruction>(A.Condition))
            diagnoseUnderControl(Anchor, "control flow");
          else if (A.Merge)
            diagnoseUnderControl(A.Merge, "control flow");
          return;  // lower NOTHING — over-declining is always safe.
        }
      }
    }

  ControlledSymbols csyms(M, wd);
  for (const ControlRegion &R : plan.Regions)
    emitRegion(R, wd, csyms, taint);
}

}  // namespace cq
