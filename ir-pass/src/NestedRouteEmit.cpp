// NestedRouteEmit.cpp — see header. The recursive swap-route emitter for the
// proven depth-2 homogeneous-phase nest (§0/§5g). Lowers the outer level exactly
// like the flat `emitRegion` (flag mint → route-in → arm replay → route-back →
// free → strip), but BETWEEN the outer route-in and route-back it recurses into
// the inner diamond — minting the inner flag FROM the parent rail (§12.2) and
// tearing the inner level down LIFO (free rail2 → strip f2 vs rail1 → free f2)
// INSIDE the outer bracket, before the outer route-back empties rail1 to |0⟩.
//
// Correctness rests on the §8 four-row (f1,f2) basis trace, NOT on `opt -verify`
// (Rule 2): the inner effect reaches `q` iff f1∧f2 with NO conjunction ancilla.
//   * f1=0 (q∉outer arm): rail1 stays |0⟩, so the inner flag MINTS TO `c2(0)`
//     (e.g. icmp(0<9)=1, NOT a literal 0) — the inner cswaps DO fire but swap
//     |0⟩↔|0⟩ and rz(|0⟩)=|0⟩, so nothing reaches q; the inner strip recomputes
//     `c2(0)` on rail1 (still |0⟩) and un-XORs the flag back to |0⟩. q untouched.
//   * f1=1,f2=0 (q∈outer, q∉inner): rail1 holds g(q); the inner flag is 0 so no
//     inner swap, the inner gate fires on rail2=|0⟩ — q gets the outer phase only.
//   * f1=1,f2=1: the inner gate fires on rail2 (which holds g(q)) and routes back
//     — q gets BOTH phases.
// Every rail/flag is provably |0⟩ in population after its strip/free (correctness
// rests on rail1==|0⟩ at BOTH the inner mint and the inner strip, so the strip
// un-XORs cleanly — §12.3), so every `cqrt_free` is a clean reset, not a
// measurement. A phase nest copies NOTHING out (zero
// `cqrt_copy`/`_controlled`/`cqrt_toffoli`) — a CNOT copy would dephase q (Rule 7).

#include "NestedRouteEmit.h"

#include "CompareLowering.h"     // lowerCompareToFlag / lowerCompareToFlagRail
#include "ControlPlan.h"         // ControlRegion / diagnoseUnderControl
#include "ControlledSymbols.h"   // ControlledSymbols (cswap/x for emitRoute)
#include "OpcodeSupport.h"       // abiWidthFromType (rail/rz width, pre-RAUW)
#include "RegionFlatten.h"       // flattenRegionTree
#include "SwapRouteEmit.h"       // collectArmPhis / emitRoute (reused, Rule 14)
#include "TaintPropagation.h"    // TaintSet
#include "WidthDispatch.h"       // allocFn / rzRtFn / freeFn / llvmWidthType

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

void lowerNestedRegion(const ControlRegion &Outer, const ControlRegion &Inner,
                       WidthDispatch &wd, ControlledSymbols &csyms,
                       TaintSet &taint) {
  auto *OuterCond = dyn_cast_or_null<CmpInst>(Outer.Condition);
  auto *InnerCond = dyn_cast_or_null<CmpInst>(Inner.Condition);
  auto *MergePhi = dyn_cast_or_null<PHINode>(Outer.Merge);
  BasicBlock *Pred = Outer.Pred;
  BasicBlock *Mid = Outer.Arm;        // outer arm = inner pred: intervening gate(s)
                                      // + the inner condition/branch live here.
  BasicBlock *InnerArm = Inner.Arm;

  // Detection (`recoverRegionTree`) guarantees the shape; if any anchor is
  // missing, bail LOUDLY — a silently skipped accepted nest leaves a tainted `br`
  // to the backend as classical control over quantum state (Rule 1).
  if (!OuterCond || !InnerCond || !MergePhi || !Pred || !Mid || !InnerArm) {
    if (auto *A = dyn_cast_or_null<Instruction>(Outer.Condition))
      diagnoseUnderControl(A, "control flow");
    else if (Outer.Merge)
      diagnoseUnderControl(Outer.Merge, "control flow");
    return;
  }
  auto *OuterBI = dyn_cast<BranchInst>(Pred->getTerminator());
  if (!OuterBI || MergePhi->getBasicBlockIndex(Pred) < 0) {
    diagnoseUnderControl(OuterCond, "control flow");
    return;
  }

  // The routed base Q — the outer diamond's straight-through (Pred-edge) merge
  // incoming (`%q`). Never read width/identity off Q's SSA type; Q is only the
  // cswap data operand (§4 width-source).
  Value *Q = MergePhi->getIncomingValueForBlock(Pred);

  // Per-level ordered IN-BLOCK gates (bounded — Rule 10, never hop a shared
  // pre-region phi). `Mid` holds the outer arm's intervening gate(s) (`%g` chain);
  // `InnerArm` holds the inner arm's gate(s) (`%h` chain). Either may be empty (a
  // gate-free `Mid` is the degenerate accept; both empty is the identity nest).
  SmallVector<CallInst *, 4> MidPhis =
      collectArmPhis(MergePhi->getIncomingValueForBlock(Mid), Mid);
  SmallVector<CallInst *, 4> ArmPhis =
      collectArmPhis(MergePhi->getIncomingValueForBlock(InnerArm), InnerArm);

  // Mid gates FIRST (forward cross-block lineage: the Mid gate `%g` is the arg-0
  // producer of the inner-arm gate `%h`), so `flattenRegionTree`'s reverse-erase
  // drops the consumer (`%h`) before the producer (`%g`) and each is use-empty
  // when freed (§6.1, ET1).
  SmallVector<CallInst *, 8> AllArmPhis;
  AllArmPhis.append(MidPhis.begin(), MidPhis.end());
  AllArmPhis.append(ArmPhis.begin(), ArmPhis.end());

  // Identity nest — every arm gate-free (`if (q){if(q'){}}`): the merge phi is Q
  // on every edge, there is no quantum op to control. RAUW → Q and flatten; no
  // flag, no rail, no strip (mirrors `emitRegion`'s gate-free identity early-out).
  if (AllArmPhis.empty()) {
    flattenRegionTree(Outer, Inner, AllArmPhis, taint);
    return;
  }

  // ABI rail/rotation width from the first available gate's RESULT type (i32 for
  // `cq_phi_si32`, double for `cq_phi_f64`) — reliable pre-RAUW; the handle stays
  // i32 (Rule 15) so the width only selects the rail/rz symbol names. Never read
  // width off Q (a derived base's own suffix is unreliable, the f64 trap).
  CallInst *WidthGate = !MidPhis.empty() ? MidPhis.front() : ArmPhis.front();
  StringRef Abi = abiWidthFromType(WidthGate->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Rz = Abi.empty() ? FunctionCallee() : wd.rzRtFn(Abi);
  if (!RailTy || !Alloc || !Rz) {
    // Unsupported width past detection — decline LOUDLY (a silent leave-in-place
    // would hand the tainted `br` to the backend while later rotation lowering
    // fires the arm gates unconditionally).
    diagnoseUnderControl(OuterCond, "control flow");
    return;
  }

  const DebugLoc DL = OuterBI->getDebugLoc();
  IRBuilder<> B(OuterBI);  // every stream call lands before the outer br.
  auto allocRail = [&]() {
    CallInst *R = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "rail");
    if (DL)
      R->setDebugLoc(DL);
    return R;
  };
  auto replay = [&](ArrayRef<CallInst *> Phis, Value *Rail) {
    // Verbatim + uncontrolled Rz of each gate's classical angle (arg 1) on the
    // rail — the rail holds the routed value's amplitude on the f=1 path and |0⟩
    // (Rz|0⟩=|0⟩) on the f=0 path, so the conditional phase lands iff the flag.
    for (CallInst *Phi : Phis) {
      CallInst *RzCall = B.CreateCall(Rz, {Rail, Phi->getArgOperand(1)});
      if (DebugLoc PDL = Phi->getDebugLoc())
        RzCall->setDebugLoc(PDL);
    }
  };
  // bd urlv audit — NO KEPT-CARRIER RECORD REACHES ANYTHING THIS FREES. Every
  // handle passed here is a per-level work rail or flag minted BY THIS EMITTER at
  // |0> and returned to |0> by its own route-back / `_inv` strip beforehand; none
  // is ever an operand of a gate writing a carrier the reversal does not touch, and
  // this module mints NO `cqrt_tape_write_*` (only `IOSinkLowering` and
  // `AbortParkEmit` do). The bd 261j(a) freeze is not owed here and is deliberately
  // not duplicated (bd memory [record-freeze-invariant-2026-08-10]).
  auto freeHandle = [&](Value *H) {
    CallInst *F = B.CreateCall(wd.freeFn(), {H});
    if (DL)
      F->setDebugLoc(DL);
  };

  // 1. OUTER mint + route-in — the flat-diamond outer level verbatim.
  Value *F1 = lowerCompareToFlag(OuterCond, wd, taint, /*qqWidth=*/{},
                                 /*inverse=*/false, /*before=*/OuterBI);
  if (!F1)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).
  CallInst *Rail1 = allocRail();
  emitRoute(B, csyms, F1, Q, Rail1, Outer.ArmNegated, DL);

  // 2. OUTER arm body replay on rail1 (the intervening `cq_phi` gates; `%g` now
  //    lives on rail1).
  replay(MidPhis, Rail1);

  // 3. INNER, with base := rail1 (mint FROM the rail — the parent-routed value's
  //    amplitude lives on rail1, the stale `%g` register holds |0⟩ on f1=1).
  Value *F2 = lowerCompareToFlagRail(InnerCond, /*railBase=*/Rail1, wd, taint,
                                     /*qqWidth=*/{}, /*inverse=*/false,
                                     /*before=*/OuterBI);
  if (!F2)
    return;  // already diagnosed.
  CallInst *Rail2 = allocRail();
  emitRoute(B, csyms, F2, Rail1, Rail2, Inner.ArmNegated, DL);  // inner route-in
  replay(ArmPhis, Rail2);                                       // inner arm body
  emitRoute(B, csyms, F2, Rail1, Rail2, Inner.ArmNegated, DL);  // inner route-BACK

  // 4. INNER clean-up, inside the outer bracket (LIFO — §12.3, the load-bearing
  //    order). (i) The inner route-back (step 3's last cswap) restored rail1's
  //    mint value, so rail2 is |0⟩ (Rz|0⟩=|0⟩) — a clean free. (ii) The inner
  //    strip recomputes `c2(rail1)` while rail1 STILL holds that mint value
  //    (BEFORE the outer route-back empties it), so `%f2` returns to |0⟩ — a clean
  //    free. A misordered strip (after the outer route-back) recomputes c2 on
  //    rail1=|0⟩ and dirty-frees `%f2` = a hidden measurement (verify-clean).
  freeHandle(Rail2);
  lowerCompareToFlagRail(InnerCond, Rail1, wd, taint, /*qqWidth=*/{},
                         /*inverse=*/true, /*before=*/OuterBI,
                         /*railToStrip=*/F2);                    // STRIP f2 vs rail1
  freeHandle(F2);

  // 5. OUTER route-back + clean-up (the flat-diamond outer level verbatim).
  emitRoute(B, csyms, F1, Q, Rail1, Outer.ArmNegated, DL);      // outer route-BACK
  freeHandle(Rail1);                                            // rail1 |0> free
  lowerCompareToFlag(OuterCond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                     /*before=*/OuterBI, /*negate=*/false,
                     /*railToStrip=*/F1);                       // STRIP f1 vs q
  freeHandle(F1);

  // 6. REWIRE + FLATTEN. `flattenRegionTree` owns the FULL ordered teardown: RAUW
  //    the shared 3-incoming merge phi → Q (so the measure reads `q`, a phase arm
  //    preserves q's basis identity), then erase — in the one order that keeps
  //    every value use-empty when freed — both branches, both compares, both
  //    arm-gate chains (reverse lineage), and the single shared-merge splice.
  //    The arm-gate erase lives in `flattenRegionTree` (not inline here) because
  //    the Mid gate `%g` is READ BY the inner compare `%c2`, so the compares must
  //    be erased BEFORE the gates — and the compares are flatten's to erase. The
  //    merge phi is erased here-and-now (before `declineClassicalMuxes`): the nest
  //    is its sole owner (§6.1).
  flattenRegionTree(Outer, Inner, AllArmPhis, taint);
}

}  // namespace cq
