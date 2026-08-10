// SwitchDataMuxEmit.cpp — the mutating emitter for an accepted tainted `switch`
// whose merge incomings are ALL `ConstantInt` (4.5 WI-4; PRD Part V §20;
// IMPLEMENTATION-4.5 §4C). The N-way generalization of the 4.4 `select`
// controlled-XOR merge (`SelectMergeEmit::emitSelectRegion`): a compile-time
// multiplexer over the scrutinee `q`, lowered as a PRELOAD + per-case XOR-delta
// controlled copy. NO rail, NO route `cqrt_cswap`, NO ¬-bracket, NO reverse-play
// — the simplest of the three switch recipes.
//
//   1. PRELOAD   %out = cqrt_alloc_<W>(v_d)   — v_d = the default / straight-
//                through (SwitchBB→MergeBB edge) literal. %out is NOT |0> (unlike
//                the select rail); it already holds the default answer.
//   2. per content case i (incoming v_i ≠ v_d):
//        a. f_i = cq_template_icmp_eq_<W>_hl(q, c_i)       (the eq-flag)
//        b. %d_i = cqrt_alloc_<W>(v_i ^ v_d)               (compile-time XOR-delta)
//        c. cqrt_copy_<W>_controlled(f_i, %d_i, %out)      (out ^= d_i iff f_i=1)
//   3. strip + free all N flags: cq_template_icmp_eq_<W>_hl_inv(q, c_i) then
//      cqrt_free(f_i)  — each strip reads PRISTINE q (the copies write %out, never
//      q, so q == q0 throughout and the strip is structurally valid).
//   4. RAUW the merge phi → %out; scrub + erase it; flatten the dead N-way CFG.
//
// Correctness (analytic, NOT `opt -verify` — Rule 2): with %out preloaded to v_d
// and the case literals DISTINCT, the eq-flags are MUTUALLY EXCLUSIVE — q equals
// at most one c_i, so at most one controlled copy fires. The matched case k gives
// out = v_d ⊕ (v_k ⊕ v_d) = v_k; no case matching (the default) leaves out = v_d.
// There is NO double-write on any basis branch, so the §6.9 NO-¬-bracket recipe is
// exact (a spurious cqrt_x would double-write yet pass a count-only CHECK — pinned
// by the §7 CHECK-NOT). The default is the PRELOAD, not a synthesized ¬OR flag (the
// excised `FlagConjunction` is NOT revived). q, %out, and every XOR-delta scratch
// %d_i are left ALLOCATED (a benign classical leak, Rule 6); %d_i is left UNTAINTED
// so `uncompute` never selects it, and %out is safe from `uncompute` only because
// `isTerminalHandle` rejects it (it has ≥1 non-benign controlled-copy consumer,
// §6.7). Reuses `emitEqFlag` (mint/strip), `allocFn`/`freeFn`, and
// `copyControlledFn` verbatim (Rule 14); the only original logic is the §4C
// ordering.

#include "SwitchRouteEmit.h"  // emitSwitchDataMuxRegion (declared beside phase/value)

#include "CompareLowering.h"   // emitEqFlag
#include "ControlPlan.h"       // ControlRegion / SwitchArm / diagnoseUnderControl
#include "ControlledSymbols.h" // copyControlledFn
#include "OpcodeSupport.h"     // abiWidthFromType
#include "RegionFlatten.h"     // flattenSwitchRegion
#include "SelectMergeEmit.h"   // materializeCopySource (shared, WI-5.1)
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"     // allocFn / freeFn / llvmWidthType

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
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
  if (R.Merge)
    diagnoseUnderControl(R.Merge, "control flow");
  else if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
    diagnoseUnderControl(A, "control flow");
}

}  // namespace

void emitSwitchDataMuxRegion(const ControlRegion &R, WidthDispatch &wd,
                             ControlledSymbols &csyms, TaintSet &taint) {
  auto *MergePhi = dyn_cast_or_null<PHINode>(R.Merge);
  Value *Q = R.Condition;  // the scrutinee = the eq-flag source (never written).
  if (!MergePhi || !Q || !R.Pred || !R.MergeBB || R.SwitchArms.empty())
    return bailLoud(R);

  // The `switch` terminator — every emitted call lands before it, in the switch
  // block, so the data-mux executes unconditionally ahead of the (soon dead)
  // branch. Reading it off Pred keeps the emitter a pure consumer of the
  // by-identity plan (no cached terminator).
  auto *SI = dyn_cast<SwitchInst>(R.Pred->getTerminator());
  if (!SI)
    return bailLoud(R);

  // The default literal v_d = the merge incoming on the SwitchBB→MergeBB
  // (default-direct) edge — the straight-through value, proven `ConstantInt` by
  // G6 `proveSwitchDataMux`. Recover it here (not cached) so the emitter stays a
  // pure consumer of the by-identity plan.
  int STIdx = MergePhi->getBasicBlockIndex(R.Pred);
  auto *Vd =
      STIdx >= 0 ? dyn_cast<ConstantInt>(MergePhi->getIncomingValue(STIdx))
                 : nullptr;
  if (!Vd)
    return bailLoud(R);  // proveSwitchDataMux proved every incoming ConstantInt.

  // ONE width for the preload / deltas / copy, from the merge phi's INTEGER SSA
  // type — reliable pre-RAUW (emit precedes `lowerRotations`; the phi still
  // carries iN). NEVER the scrutinee suffix (q may be a derived handle) and never
  // a classifying signal (the f64 trap). The positive integer fence already passed
  // at G4, so a null here is a malformed plan — bail LOUDLY.
  StringRef Abi = abiWidthFromType(MergePhi->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee CopyC = Abi.empty() ? FunctionCallee() : csyms.copyControlledFn(Abi);
  if (!RailTy || !Alloc || !CopyC)
    return bailLoud(R);

  const DebugLoc DL = SI->getDebugLoc();
  IRBuilder<> B(SI);  // every emitted call lands before the `switch`.
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // 1. PRELOAD %out = cqrt_alloc_<W>(v_d). %out joins `taint.Tainted` (+BirthOrder)
  //    so the RAUW'd merge phi's consumers keep classifying it as a quantum handle;
  //    its users are the N controlled copies (as dst) + the user's measure/ret, so
  //    `uncompute` never selects it (isTerminalHandle false — §6.7). NEVER freed
  //    (the live result, owned by the user's measure / ret — Rule 6).
  CallInst *Out = B.CreateCall(Alloc, {Vd}, "out");
  stamp(Out);
  taint.Tainted.insert(Out);
  taint.ControlOwnedRails.insert(Out);  // DD-4: Phase-4 owns this data-mux out-rail
  // dugh (Phase 4×6): the all-ConstantInt data-mux merge is ALWAYS data-untainted,
  // so record the out-rail for `repropagateControlMerges` to re-seed. An onward
  // QUANTUM flow (`z = rm + 1; measure z`) is then re-tainted and lowers; an onward
  // classical escape / a new tainted-condition control on `rm` declines via the
  // re-run net (replacing the pre-8mld `proveSwitchDataMux` merge-out gate).
  taint.UntaintedMergeRails.insert(Out);
  taint.BirthOrder[Out] = taint.NextBirth++;
  // bd p119.8 (same gap as p119.6): record the out-rail's LOGICAL ABI width (=
  // `Abi`, the data-mux width) so a DOWNSTREAM cast/Q+Q-compare off the RAUW'd merge
  // recovers the real width instead of the laundered i32 (getSrcTy-after-RAUW). A
  // non-i32 data-mux (i8/i16/i64) feeding `trunc`/`sext`/`zext`/a Q+Q `icmp`
  // otherwise over-declines. `Abi` is non-empty (the `!RailTy` bail above returned
  // otherwise). Persists across `repropagateControlMerges` (a plain side-table).
  taint.HandleWidth[Out] = Abi;

  // 2. Per CONTENT case (incoming v_i ≠ v_d): mint eq-flag → XOR-delta alloc →
  //    controlled copy. A passthrough case (v_i == v_d) needs no copy — %out
  //    already holds v_d on that branch — so skip it (the ConstantInts are uniqued,
  //    so pointer identity is value identity at one width).
  SmallVector<Value *, 4> Flags;
  SmallVector<ConstantInt *, 4> CaseVals;
  for (const SwitchArm &Arm : R.SwitchArms) {
    if (!Arm.Block || Arm.Values.empty())
      continue;  // straight-to-merge / malformed — no distinct incoming.
    auto *Vi =
        dyn_cast_or_null<ConstantInt>(MergePhi->getIncomingValueForBlock(Arm.Block));
    if (!Vi)
      return bailLoud(R);  // proveSwitchDataMux proved every incoming ConstantInt.
    if (Vi == Vd)
      continue;  // passthrough — %out already holds v_d on this branch.
    ConstantInt *Ci = Arm.Values.front();

    // a. Mint eq-flag — cq_template_icmp_eq_<Wq>_hl(q, c_i). Null only on an
    //    unsupported case-literal width; the literal shares the merge-phi width
    //    (G4-validated) so on an ACCEPTED region this is UNREACHABLE — kept as the
    //    Rule-1 defensive bail.
    Value *Flag = emitEqFlag(Q, Ci, wd, /*inverse=*/false, /*before=*/SI);
    if (!Flag)
      return bailLoud(R);

    // b. XOR-delta scratch %d_i = cqrt_alloc_<W>(v_i ^ v_d), a COMPILE-TIME
    //    constant (both APInts share the merge-phi width). Left UNTAINTED so
    //    `uncompute` never selects it (a benign classical leak; never freed — §4C,
    //    open-Q-6). Materialized through the SHARED `materializeCopySource`
    //    (WI-5.1 promotion — retires the §4C inline duplication, Rule 14): a
    //    `ConstantInt` is never tainted, so it always takes the alloc path; the
    //    `delta` name preserves the byte-for-byte fixture stream.
    Constant *Delta =
        ConstantInt::get(RailTy->getContext(), Vi->getValue() ^ Vd->getValue());
    Value *DeltaRail =
        materializeCopySource(Delta, Alloc, taint, B, DL, "delta");

    // c. Controlled XOR copy — cqrt_copy_<W>_controlled(f_i, d_i, out): out ^= d_i
    //    iff f_i = 1 (flag arg-0, src arg-1, dst arg-2 — PRD §1.2).
    stamp(B.CreateCall(CopyC, {Flag, DeltaRail, Out}));

    Flags.push_back(Flag);
    CaseVals.push_back(Ci);
  }
  if (Flags.empty())
    return bailLoud(R);  // SawContent proved ≥1 content case.

// bd urlv audit — NO KEPT-CARRIER RECORD REACHES THE N EQ-FLAGS FREED BELOW. Each is minted BY THIS EMITTER at |0> and stripped back to |0> by its own
  // `icmp_eq_inv` immediately before its free. They are
// never an operand of a gate that writes a carrier the reversal does not touch:
// this module mints NO `cqrt_tape_write_*` (only `IOSinkLowering` and
// `AbortParkEmit` do), and its copies write a fresh `out`. So the bd 261j(a)
// freeze is not owed here and is deliberately not duplicated (bd memory
// [record-freeze-invariant-2026-08-10]). Re-check if this emitter ever tapes.
  // 3. STRIP + FREE all N flags. Each `icmp_eq_inv(q, c_i)` reads PRISTINE q
  //    (q == q0 — the copies write %out, never q), so each flag returns to |0>
  //    with zero controlled gates and is free-able. The strips run AFTER all
  //    copies (the §4C ORDER), flowing forward to mirror the per-case mint order.
  for (size_t i = 0; i < Flags.size(); ++i) {
    emitEqFlag(Q, CaseVals[i], wd, /*inverse=*/true, /*before=*/SI,
               /*railToStrip=*/Flags[i]);
    stamp(B.CreateCall(wd.freeFn(), {Flags[i]}));
  }

  // 4. REWIRE + scrub + flatten. The measure on the phi becomes a measure on %out
  //    (the muxed answer; no measurement is added — Rule 5). Erase the phi, scrub
  //    it from every taint work-list (§6.1), then flatten the dead N-way CFG (the
  //    switch becomes straight-line; the empty arm blocks + merge are erased). q,
  //    %out, and every %d_i are never freed.
  MergePhi->replaceAllUsesWith(Out);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  flattenSwitchRegion(R, taint);
}

}  // namespace cq
