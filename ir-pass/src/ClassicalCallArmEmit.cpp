// ClassicalCallArmEmit.cpp — see header. The mutating emitter for an accepted
// 6.5 classical-call-under-quantum-control region (DD-7, PRD §2.13): a pure
// classical call inside a tainted-condition diamond arm runs classically and its
// i32 result routes into the controlled register via the 4.4 controlled-XOR copy
// merge over a FLATTENED diamond. NO clone, NO cswap/route, NO reverse-play.
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2),
// and is the diamond twin of `SelectMergeEmit`'s argument: with `%out`
// allocated to |0>, `copy_c(f, True, out)` writes True iff f=1 and the
// X-bracketed `copy_c(f, False, out)` writes False iff f=0, so `%out = f ? True :
// False` with no double-write on either basis branch — provided the `cqrt_x`
// encloses ONLY the second copy (the §16.3 bracket-order hazard, invisible to a
// count-only CHECK). The flag is stripped by `icmp_inv` (q is untouched — the
// copies write `out`, never q — so q == q0) and freed; q, `%out`, the
// materialized scratch, and the hoisted call are left allocated (Rule 6/8).
// Hoisting the call into `Pred` so it runs UNCONDITIONALLY needs TWO properties,
// not one. PURITY (the §2.13 / WI-5.4 rejection set) is why nothing observable
// moves — its result on the inactive branch is computed-and-discarded. TOTALITY
// is why the extra execution is not UB the source never had, and purity does not
// imply it: bd wve8 shipped a `memory(none) nounwind willreturn` callee whose body
// divided by its argument, and the program SIGFPEd on a source whose guard has
// zero amplitude. `classifyClassicalCallArm` proves both before this file runs.

#include "ClassicalCallArmEmit.h"

#include "ArmClassify.h"      // freezeDischargesHoistedArg (bd 9hea; claim+emit share it)

#include "CompareLowering.h"    // lowerCompareToFlag (mint + _inv strip)
#include "ControlPlan.h"        // ControlRegion / diagnoseUnderControl
#include "ControlledSymbols.h"  // copyControlledFn / xFn
#include "OpcodeSupport.h"      // abiWidthFromType
#include "RegionFlatten.h"      // flattenRegion
#include "SelectMergeEmit.h"    // materializeCopySource (shared, WI-5.1)
#include "SpeculationSafety.h"  // hoistedArgPoisonIsUB (bd bwfp; claim+emit share it)
#include "TaintPropagation.h"   // TaintSet
#include "WidthDispatch.h"      // allocFn / freeFn / llvmWidthType

#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/ValueTracking.h"  // isGuaranteedNotToBeUndefOrPoison (bd 9hea)
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
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
// maintenance). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase_value(CI);
  }
}

// Loud bail for a detection-guaranteed shape that did not hold at emit time. A
// silently skipped accepted region would hand the tainted `br` to the backend as
// classical control over quantum state (the one unforgivable bug, Rule 1).
void bailLoud(const ControlRegion &R) {
  if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
    diagnoseUnderControl(A, "control flow");
  else if (R.Merge)
    diagnoseUnderControl(R.Merge, "control flow");
}

}  // namespace

void emitClassicalCallArmRegion(const ControlRegion &R, WidthDispatch &wd,
                                ControlledSymbols &csyms, TaintSet &taint) {
  auto *MergePhi = dyn_cast_or_null<PHINode>(R.Merge);
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  if (!MergePhi || !Cond || !R.Pred || !R.Arm || !R.MergeBB)
    return bailLoud(R);
  auto *BI = dyn_cast<BranchInst>(R.Pred->getTerminator());
  if (!BI)
    return bailLoud(R);
  if (MergePhi->getBasicBlockIndex(R.Pred) < 0 ||
      MergePhi->getBasicBlockIndex(R.Arm) < 0)
    return bailLoud(R);

  // The diamond's two merge incomings (re-derived — a pure consumer of the
  // by-identity plan): the tainted straight-through `q` (Pred edge) and the
  // classical call result (Arm edge). `classifyClassicalCallArm` proved the Arm
  // incoming is a direct, pure, all-classical-args, non-intrinsic CallInst with a
  // classical (non-tainted) result; re-validate the CallInst shape and bail
  // loudly otherwise (never a silent skip, Rule 1).
  Value *StraightThrough = MergePhi->getIncomingValueForBlock(R.Pred);
  Value *ArmIncoming = MergePhi->getIncomingValueForBlock(R.Arm);
  auto *Call = dyn_cast_or_null<CallInst>(ArmIncoming);
  if (!Call || Call->getParent() != R.Arm)
    return bailLoud(R);

  // ONE width for the rail / copy, from the merge phi's SSA type — reliable
  // pre-RAUW (emit precedes `lowerRotations`; the phi still carries its real
  // logical type). The fp/i128 RESULT gate (DD-7, the f64 trap): `copyControlledFn`
  // is non-null ONLY for an INTEGER ABI width — an fp merge (valid `abiWidthFromType`
  // yet null `copyControlledFn`) or an unsupported width DECLINES LOUDLY here,
  // before any mutation (never mint dead ABI; never key on `abiWidthFromType`
  // non-empty). Same gate as `SelectMergeEmit`.
  StringRef Abi = abiWidthFromType(MergePhi->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Copy =
      Abi.empty() ? FunctionCallee() : csyms.copyControlledFn(Abi);
  if (!RailTy || !Alloc || !Copy)
    return bailLoud(R);

  // True/False = the merge values on the cond-TRUE / cond-FALSE edges (the flag
  // is the live condition). Oriented by `ArmNegated` (Rule 9): un-negated diamond
  // ⇒ the Arm is the TRUE successor, so True = the call result, False = `q`;
  // negated ⇒ the Arm is the FALSE successor (clang -O1 swapped them for
  // `if(q!=k)`), so True = `q`, False = the call result.
  Value *TrueSrc = R.ArmNegated ? StraightThrough : ArmIncoming;
  Value *FalseSrc = R.ArmNegated ? ArmIncoming : StraightThrough;

  const DebugLoc DL = Cond->getDebugLoc();

  // 0. HOIST the call to just before the conditional `br`, where it runs
  //    UNCONDITIONALLY. Moving it OUT of the arm is mandatory: `flattenRegion`
  //    (step 6) erases the arm block, which would otherwise drop the call (and
  //    its result). Its args are all classical and external to the arm (the arm
  //    is exactly call + br, by classification), so they dominate this insertion
  //    point. `materializeCopySource(call)` below then reads the hoisted result.
  //
  //    *** "INERT, THE CALLEE IS PURE" WAS THIS COMMENT'S JUSTIFICATION AND IT
  //    WAS NOT ENOUGH (bd wve8). *** Purity makes the hoist inert only in the
  //    sense that nothing OBSERVABLE moves; it says nothing about whether the
  //    callee is DEFINED on the arguments, and `mayHaveSideEffects()` — write ||
  //    throw || !willReturn — does not cover immediate UB. A `memory(none)
  //    nounwind willreturn` callee whose body was `return 100 / x;` was hoisted
  //    here and the program SIGFPEd on a source that never evaluates it (the
  //    guard has zero amplitude). `classifyClassicalCallArm` now additionally
  //    proves TOTALITY — `isSafeToSpeculativelyExecute` (the `speculatable`
  //    attribute, which clang really does emit on the intrinsics it lowers
  //    builtins to) or `isSpeculatableTotalCallee` (the STRICT body walk, not the
  //    lax `isSpeculatablePureCallee`, whose memory and terminator clauses defer
  //    their obligation to a clone 6.5 never mints) — plus an argument clause for
  //    `noundef` parameters. Read the full argument at that gate; if you widen it,
  //    THIS is the line that cashes the widening.
  // bd 9hea — COMPUTE THE FREEZE SET *BEFORE* THE MOVE, then hoist, then freeze.
  //
  // *** THE ORDER IS THE CORRECTNESS ARGUMENT, NOT A STYLE CHOICE (bd iwz1). ***
  // `freezeDischargesHoistedArg` consults `isGuaranteedNotToBeUndefOrPoison`, which
  // also reasons from USES. Once the call is unconditional, a `noundef` parameter
  // operand is itself a use-based proof that the operand is defined, so the same
  // query flips 0 -> 1 after `moveBefore` and the hoisted call SELF-LICENSES the very
  // argument that needed freezing. Querying here — call still in `R.Arm`, exactly the
  // position `classifyClassicalCallArm` used — makes claim and emit agree by
  // construction rather than by coincidence.
  SmallVector<unsigned, 4> NeedFreeze;
  for (unsigned Ai = 0, Ae = Call->arg_size(); Ai != Ae; ++Ai)
    if (hoistedArgPoisonIsUB(Call, Ai) &&
        !llvm::isGuaranteedNotToBeUndefOrPoison(Call->getArgOperand(Ai))) {
      // The classifier declined anything this predicate refuses, so a false here is
      // unreachable; bail loudly rather than hoist an un-frozen poison argument.
      if (!freezeDischargesHoistedArg(Call, Ai))
        return bailLoud(R);
      NeedFreeze.push_back(Ai);
    }

  Call->moveBefore(BI);

  // `freeze` each recorded argument, immediately before the now-unconditional call.
  // The operands are all classical and external to the arm (the arm is exactly
  // call + br by classification), so they dominate this point. `freeze` is a codegen
  // no-op: it adds NO gate, and the emitted circuit is byte-identical to what the
  // same module produced when the argument happened to be provably defined.
  for (unsigned Ai : NeedFreeze) {
    auto *Fr = new FreezeInst(Call->getArgOperand(Ai),
                              Call->getArgOperand(Ai)->getName() + ".fr", Call);
    if (DL)
      Fr->setDebugLoc(DL);
    Call->setArgOperand(Ai, Fr);
  }

  IRBuilder<> B(BI);  // every emitted call lands before the conditional br.
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // 1. MINT the flag — cq_template_icmp_<pred>_<Wc>_hl(q, k).
  // (Track A.1, F-A1R2-1) `Unruled`: `classifyClassicalCallArm` runs BEFORE
  // `classifyArms` in `handleBranchRegion` and RETURNS on Accept, so
  // `condWireDisposition` never sees this compare; the 6.5 classifier has no
  // wire clause of its own (MEASURED: no `findNonDiagonalWireGate` in
  // `classifyClassicalCallArm`). No round-1 ruling ⇒ no exemption.
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI,
                                   /*negate=*/false, /*railToStrip=*/nullptr,
                                   /*readKind=*/CondReadKind::Unruled);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported width / Q+Q).

  // 2. ALLOC the |0> result rail (Wd). It joins `taint.Tainted` (+BirthOrder) so
  //    downstream consumers of the RAUW'd phi keep classifying it as a quantum
  //    handle; its users are cqrt_*/template calls, so `uncompute` never selects
  //    it (isTerminalHandle false) and it is never freed (the live result, owned
  //    by the user's measure / ret). DD-4: Phase-4 owns this merge out-rail.
  CallInst *Out = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "out");
  stamp(Out);
  taint.Tainted.insert(Out);
  taint.ControlOwnedRails.insert(Out);
  // dugh (Phase 4×6): record the merge out-rail so `repropagateControlMerges` (run
  // right after `lowerControlRegions`) re-seeds a forward propagation from it. The
  // merge phi is data-untainted whenever the straight-through is a classical
  // constant (`int y = 5; if (q>k) y = f(a)`), so the first `propagate` classified
  // its onward consumers as classical; the second round re-taints an onward QUANTUM
  // flow so it lowers, while an onward CLASSICAL escape declines via the re-run
  // escape net. Idempotent when the straight-through is the tainted `q` (the merge
  // was already tainted; its onward users are already in `Tainted`).
  taint.UntaintedMergeRails.insert(Out);
  taint.BirthOrder[Out] = taint.NextBirth++;
  // bd p119.8 (same gap as p119.6): record the out-rail's LOGICAL ABI width (=
  // `Abi`, the classical-call merge width) so a DOWNSTREAM cast/Q+Q-compare off the
  // RAUW'd merge recovers the real width, not the laundered i32. Inert when the
  // merge is i32 (the common 6.5 shape) but restores the producer invariant for a
  // non-i32 integer call result. `Abi` is non-empty (the width guard bailed otherwise).
  taint.HandleWidth[Out] = Abi;

  // 3. COPY the TRUE value on the flag (materialize if classical) — fires on f=1.
  //    The classical call result materializes to a fresh `cqrt_alloc_<Wd>` handle
  //    (an UNTAINTED basis-valued classical copy-source, not a qubit — Rule 6/8);
  //    the tainted `q` materializes to itself (the identity).
  Value *TrueMat = materializeCopySource(TrueSrc, Alloc, taint, B, DL);
  stamp(B.CreateCall(Copy, {Flag, TrueMat, Out}));

  // 4. COPY the FALSE value on ¬flag, X-bracketed (the 4.1 self-inverse cqrt_x
  //    convention). The bracket encloses ONLY this second copy: a mis-bracket
  //    (x before BOTH copies) yields the identical symbol multiset yet writes
  //    True then False on one basis branch = wrong %out (§16.3, load-bearing).
  stamp(B.CreateCall(csyms.xFn(), {Flag}));
  Value *FalseMat = materializeCopySource(FalseSrc, Alloc, taint, B, DL);
  stamp(B.CreateCall(Copy, {Flag, FalseMat, Out}));
  stamp(B.CreateCall(csyms.xFn(), {Flag}));

  // 5. STRIP the flag + the SINGLE free. Structurally valid outright — and the
  //    real invariant is general (NOT "the straight-through must be q"): the copy
  //    DESTINATION is the fresh `%out` alloc, never any operand of `Cond`, so
  //    EVERY value `Cond` reads is pristine at strip time (q == q0 in the
  //    canonical case; equally valid when the straight-through incoming is a
  //    classical constant or any non-`q` value). The `_inv` therefore un-computes
  //    the flag to |0> (provably free-able). Reads Cond's operands — MUST precede
  //    the erase of Cond (in flattenRegion). See [[6-5-classical-call-arm]].
// bd urlv audit — NO KEPT-CARRIER RECORD REACHES THE FLAG FREED HERE. It is minted BY THIS EMITTER at |0> and stripped back to |0> by the `_inv`
  // on the line above. They are
// never an operand of a gate that writes a carrier the reversal does not touch:
// this module mints NO `cqrt_tape_write_*` (only `IOSinkLowering` and
// `AbortParkEmit` do), and its copies write a fresh `out`. So the bd 261j(a)
// freeze is not owed here and is deliberately not duplicated (bd memory
// [record-freeze-invariant-2026-08-10]). Re-check if this emitter ever tapes.
  lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                     /*before=*/BI, /*negate=*/false, /*railToStrip=*/Flag);
  stamp(B.CreateCall(wd.freeFn(), {Flag}));

  // 6. REWIRE — RAUW %phi -> %out, scrub, erase the phi, then FLATTEN the diamond
  //    (value-arm discipline: block identities are captured before the first
  //    erase inside flattenRegion; the hoisted call already left the arm, so the
  //    now-empty arm block erases cleanly). The user's measure/ret on the phi
  //    becomes one on %out (no measurement is added — Rule 5).
  MergePhi->replaceAllUsesWith(Out);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  flattenRegion(R, taint);
}

}  // namespace cq
