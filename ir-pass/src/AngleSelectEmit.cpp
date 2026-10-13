// AngleSelectEmit.cpp — see header. Lowers an accepted tainted-condition ANGLE
// select (control-in-place-PRD §12.3, bd drbq Inc 2b), both rotation stems; the
// Ry stem is the X-bracket form since bd dm7f.6 (owner ruling 2026-10-13). Reuses
// `lowerCompareToFlag` (mint + `_unc` strip), `wd.freeFn()` and the drbq
// `taint.ControlledRotations` record verbatim (Rule 14); the original logic is
// the EMISSION ORDER. Step 0 validates (loudly, before any mutation); the later
// steps emit and erase.

#include "AngleSelectEmit.h"

#include "ArmAnalysis.h"       // angleSelectArmsDefined / comparePredLowerable
#include "ChainWalk.h"         // markBranchPhaseGate (3qlq Inc 1 F-L7-1)
#include "CompareLowering.h"   // lowerCompareToFlag + compareFlagMintable (step 0b)
#include "SelectClassify.h"    // isCondRailLeaf / kBareRailCondReason (bd 3qlq.4)
#include "ControlPlan.h"       // ControlRegion / diagnoseUnderControl
#include "ControlledSymbols.h"  // xFn (3qlq Inc 1 phase angle select bracket)
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"     // freeFn

#include "llvm/ADT/STLExtras.h"     // llvm::find
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list (a per-TU mirror of
// `SelectMergeEmit::scrubTaint`; idempotent). The erased classes are the ANGLE
// SELECT and, when dead, the CONDITION COMPARE. The `CallInst` block is
// unreachable as called (round-1 lens L5-5), kept because this TU inserts into
// `ThetaCalls`/`PhiCalls`, so a future erase of a rotation here would need it.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  taint.HandleWidth.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    taint.PhiCalls.erase_value(CI);
    taint.ThetaCalls.erase_value(CI);
  }
}

// ── bd 3qlq Inc 1 — P2, the REGISTER-FREE PHASE ANGLE SELECT ─────────────────
//
// `if (c) cq_phi(A); else cq_phi(B);` reaches the pass as ONE
// `call void @cq_phi(double %sel)`, `%sel = select i1 %c, double A, double B`
// (MEASURED, PRD §6.1 row 2). The stream, at the consumer's position:
//
//     cq_template_icmp_<pred>_<W>_hl(q, lit) -> f     ; flag mint
//     cqrt_x(f); cqrt_rz_i1(f, B); cqrt_x(f)          ; P(B) on the f = 0 branch
//     cqrt_rz_i1(f, A)                                ; P(A) on the f = 1 branch
//     cq_template_icmp_<pred>_<W>_hl_unc(f, q, lit)   ; flag strip → |0>
//     cqrt_free(f)
//
// EXACT (PRD §3): the four gates give `|0⟩` the factor `e^{i(B−A)/2}` and `|1⟩`
// `e^{i(A−B)/2}`, the relative phase `P(A)`-on-1 / `P(B)`-on-0 produces, times a
// global phase. Both arms pass VERBATIM, so a RUN-TIME arm is admitted (owner
// question Q3). NO POLARITY CASE: a `select` means "A when the condition is 1";
// the `cqrt_x` pair is how the `f = 0` gate is expressed, not a polarity fix.
void emitPhaseAngleSelect(SelectInst *Sel, Instruction *Cond, CallInst *T,
                          WidthDispatch &wd, TaintSet &taint) {
  // ---- 0. RE-VALIDATE, before mutating anything. bd 3qlq.4: the condition is a
  // COMPARE or the `_Bool` REGISTER itself (`RailCond`): then the register is the
  // flag (no mint, strip or free) and the `¬b` gate is the diagonal `rz(b, −B)`
  // (`X·P(B)·X = e^{iB}·P(−B)`), never a `cqrt_x` on a user register.
  const bool RailCond = isCondRailLeaf(Cond);
  auto *Cmp = RailCond ? nullptr : dyn_cast<CmpInst>(Cond);
  if (!RailCond && !Cmp) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  Value *A = Sel->getTrueValue();
  Value *B = Sel->getFalseValue();
  if (T->arg_size() != 1 || T->getArgOperand(0) != Sel || !Sel->hasOneUse() ||
      Sel->user_back() != T || Sel->getCondition() != Cond ||
      taint.Tainted.count(A) || taint.Tainted.count(B)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  Instruction *After = T->getNextNode();
  if (T->getParent() != Sel->getParent() ||
      Cond->getParent() != T->getParent() || !Cond->comesBefore(Sel) ||
      !Sel->comesBefore(T) || !After) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // S4's SEMANTIC half, re-asked in lockstep (round-1 L4-1: a PRECEDING region's
  // RAUW in this loop can turn the compare Q+Q, and there is no Q+Q mint here).
  if (RailCond) {
    if (!taint.Tainted.count(Cond)) {
      diagnoseUnderControl(Sel, "control flow");
      return;
    }
  } else {
    const bool LTainted = taint.Tainted.count(Cmp->getOperand(0)) != 0;
    const bool RTainted = taint.Tainted.count(Cmp->getOperand(1)) != 0;
    if (LTainted == RTainted || !comparePredLowerable(Cmp) ||
        !compareFlagMintable(Cmp, taint)) {
      diagnoseUnderControl(Sel, "control flow");
      return;
    }
  }
  FunctionCallee Rz = wd.rzRtFn("i1");
  // `cqrt_x` through `ControlledSymbols`, the ONE spelling of the bracket.
  ControlledSymbols Csyms(*T->getModule(), wd);
  FunctionCallee X = Csyms.xFn();
  if (!Rz || !X) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  // ---- EMISSION STARTS HERE. Nothing below may decline.
  const DebugLoc DL = Sel->getDebugLoc();
  IRBuilder<> Bld(T);
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };

  // ---- 1. FLAG MINT at the consumer (the RAIL is its own flag). `WireRuled`:
  // gate 2c ruled on the leaves before gate 3 dispatched (Track A.1, F-A1R2-1).
  Value *Flag = RailCond ? static_cast<Value *>(Cond)
                         : lowerCompareToFlag(
                               Cmp, wd, taint, /*qqWidth=*/{},
                               /*inverse=*/false, /*before=*/T,
                               /*negate=*/false, /*railToStrip=*/nullptr,
                               /*readKind=*/CondReadKind::WireRuled);
  if (!Flag)
    return;  // UNREACHABLE (lockstep re-ask; `DS_Error` exits). Nothing emitted.

  // ---- 2. THE TWO GATES, RECORDED as branch-phase gates so the uncompute spine
  // never emits their negated twins (round-1 CONFIRMED miscompile F-L7-1).
  if (RailCond) {
    CallInst *G0 = stamp(Bld.CreateCall(Rz, {Flag, Bld.CreateFNeg(B)}));
    markBranchPhaseGate(G0);
    // bd r9e5 (F-B1R2-1): the first gate is this region's control read of the
    // user's register; `reverifyRailCondReads` re-asks it at final taint.
    markRailCondRead(taint, Flag, G0);
    markBranchPhaseGate(stamp(Bld.CreateCall(Rz, {Flag, A})));
  } else {
    stamp(Bld.CreateCall(X, {Flag}));
    markBranchPhaseGate(stamp(Bld.CreateCall(Rz, {Flag, B})));
    stamp(Bld.CreateCall(X, {Flag}));
    markBranchPhaseGate(stamp(Bld.CreateCall(Rz, {Flag, A})));
  }

  // ---- 3. STRIP + FREE after the consumer: no gate here touches a register the
  // compare reads. SKIPPED for a RAIL flag (freeing it is the Rule-5 dirty free).
  if (!RailCond) {
    auto *Strip = dyn_cast_or_null<CallInst>(
        lowerCompareToFlag(Cmp, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                           /*before=*/After, /*negate=*/false,
                           /*railToStrip=*/Flag));
    if (Strip)
      taint.DischargedFlagGates.insert(Strip);
    IRBuilder<> Post(After);
    stamp(Post.CreateCall(wd.freeFn(), {Flag}));
  }

  // ---- 4. ERASE the consumer, the select, then the compare if dead. A RAIL
  // condition is the user's `cq_theta_i1`, never ours to erase (F-1b-3).
  taint.PhaseCalls.erase_value(T);
  T->eraseFromParent();
  scrubTaint(Sel, taint);
  Sel->eraseFromParent();
  if (!isCondRailLeaf(Cond) && Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }
}

}  // namespace

void emitAngleSelectRegion(const ControlRegion &R, WidthDispatch &wd,
                           TaintSet &taint) {
  // ---- 0. RE-VALIDATE THE PLAN BY SSA IDENTITY, BEFORE MUTATING ANYTHING. A
  // silently skipped region leaves the tainted select to the backend (Rule 1); a
  // mid-stream decline leaves a minted flag behind (Inc-2a round-1 F-5).
  auto *Sel = dyn_cast_or_null<SelectInst>(R.Merge);
  // bd 3qlq.4: a compare, or (PHASE stem only) the bare `_Bool` register.
  auto *CondI = dyn_cast_or_null<Instruction>(R.Condition);
  const bool RailCond = isCondRailLeaf(CondI);
  if (!Sel || !CondI || (!RailCond && !isa<CmpInst>(CondI))) {
    if (R.Merge)
      diagnoseUnderControl(R.Merge, "control flow");
    else if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
      diagnoseUnderControl(A, "control flow");
    return;
  }
  auto *T = R.Shadow.size() == 1 ? dyn_cast<CallInst>(R.Shadow.front())
                                 : nullptr;
  Function *Callee = T ? T->getCalledFunction() : nullptr;
  if (!Callee) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // 3qlq Inc 1 (PRD §6.2 row P2): the phase consumer forks the whole emitter.
  if (isRegisterFreePhaseCall(T, taint)) {
    emitPhaseAngleSelect(Sel, CondI, T, wd, taint);
    return;
  }
  if (RailCond) {
    diagnoseUnderControl(Sel, kBareRailCondReason);
    return;
  }
  auto *Cond = cast<CmpInst>(CondI);
  const StringRef CalleeName = Callee->getName();
  const bool IsTheta = CalleeName.starts_with("cq_theta_");
  const bool IsPhi = CalleeName.starts_with("cq_phi_");  // retired register form
  if (!IsTheta && !IsPhi) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // The select is still the consumer's ANGLE only, the consumer its SOLE user,
  // the condition its condition (an earlier region could have rewritten one).
  if (T->arg_size() < 2 || T->getArgOperand(1) != Sel ||
      T->getArgOperand(0) == Sel || !Sel->hasOneUse() ||
      Sel->user_back() != T || Sel->getCondition() != Cond) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  Value *Base = T->getArgOperand(0);
  // A live register, or an UNTAINTED runtime base S3 admitted as state prep (bd
  // z0re). ONE QUESTION, THE CLASSIFIER'S (r1B F-r1B-2): `R.RuntimeSeedAdmitted`.
  // The reverse transition (tainted by an earlier 6.5 RAUW) is caught by the
  // record below plus `declineRound2QuantumPrepSeeds`.
  if (!taint.Tainted.count(Base) && !R.RuntimeSeedAdmitted) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // One block, `Cond` < `Sel` < `T`, and a successor for the strip and the free.
  Instruction *After = T->getNextNode();
  if (T->getParent() != Sel->getParent() || Cond->getParent() != T->getParent() ||
      !Cond->comesBefore(Sel) || !Sel->comesBefore(T) || !After) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // `T` must be in `lowerRotations`' work list; the new rotation goes IMMEDIATELY
  // BEFORE it, in stream order, so `T` lowers with arg-0 already RAUW'd to the
  // handle (appending was byte-identical only by a later RAUW repairing a
  // transiently mistyped call, drbq Inc 2b M15 — recorded, not depended on).
  auto &Work = IsTheta ? taint.ThetaCalls : taint.PhiCalls;
  if (llvm::find(Work, T) == Work.end()) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // A recorded flag on `T` would mean two owners for one gate.
  if (taint.ControlledRotations.count(T)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  Value *A = Sel->getTrueValue();
  Value *B = Sel->getFalseValue();
  // Rule 3 (quantum in the angle), then S1's arm question in lockstep — the SAME
  // `angleSelectArmsDefined`, not a second spelling.
  if (taint.Tainted.count(A) || taint.Tainted.count(B) ||
      !angleSelectArmsDefined(A, B)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  // ---- 0b. RE-ASK S4's SEMANTIC HALF (2b round-1 lens L4-1): a preceding 4.5
  // SwitchDataMux region's RAUW to a TAINTED `%out` can make the compare Q+Q,
  // which has no mint here. Fixture `..._reject_datamux_qq_after_rauw.ll`.
  const bool LTainted = taint.Tainted.count(Cond->getOperand(0)) != 0;
  const bool RTainted = taint.Tainted.count(Cond->getOperand(1)) != 0;
  if (LTainted == RTainted || !comparePredLowerable(Cond) ||
      !compareFlagMintable(Cond, taint)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  // `cqrt_x` through `ControlledSymbols`, the ONE spelling of the bracket.
  ControlledSymbols Csyms(*T->getModule(), wd);
  FunctionCallee X = Csyms.xFn();
  if (!X) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  // ---- EMISSION STARTS HERE. Nothing below may decline.
  //
  // THE ROUTE (owner ruling 2026-10-13, `owner-ruling-angle-select-xbracket`,
  // superseding the subtraction-free triple of dm7f.6): the X-BRACKET form on the
  // minted flag ancilla, the stream the if/else in-place Ry arm emits for the
  // same program (`SwapRouteEmit::emitInPlaceRotationRegion`'s gate loop: the
  // un-negated arm's gate, then `x(f); gate; x(f)` for the negated arm):
  //
  //     f = icmp_<pred>_hl(q, k); ry_c(f, h, A); x(f); ry_c(f, h, B); x(f);
  //     icmp_<pred>_hl_unc(f, q, k); free(f)
  //
  // f = 1 fires `Ry(A)` only; f = 0 (the bracket inverts the ancilla) `Ry(B)`
  // only. Each arm's double reaches exactly ONE controlled gate, verbatim: no
  // arithmetic, no freeze (no arm is read twice), and a non-finite arm never
  // touches the other branch. The `cqrt_x` pair is on the compiler-owned flag,
  // never on a user register.
  const DebugLoc DL = Sel->getDebugLoc();
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  IRBuilder<> Bld(T);  // everything lands immediately before the consumer.

  // ---- 1. THE FLAG MINT, at the consumer. `WireRuled`: gate 2c ruled on this
  // compare's wire before gate 3 dispatched (Track A.1, F-A1R2-1).
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/T,
                                   /*negate=*/false, /*railToStrip=*/nullptr,
                                   /*readKind=*/CondReadKind::WireRuled);
  if (!Flag)
    return;  // UNREACHABLE (step 0b's lockstep re-ask; `DS_Error` exits first).

  // ---- 2. THE TRUE-ARM GATE `R_c(f, A)`: a NEW `@cq_theta_<sfx>` on `Base`,
  // after the mint (its control must dominate it), spelled as the consumer's own
  // callee (pre-`lowerRotations` the register is still a `cq_*` value and every
  // wire walker keys on that name). It goes into `lowerRotations`' work list
  // IMMEDIATELY BEFORE `T`, so `T` lowers with its arg-0 already RAUW'd to the
  // handle. Recorded in `BirthOrder` too (an absent key reads 0, sorting FIRST).
  CallInst *TA = stamp(Bld.CreateCall(Callee, {Base, A}));
  taint.Tainted.insert(TA);
  taint.BirthOrder[TA] = taint.NextBirth++;
  Work.insert(llvm::find(Work, T), TA);
  // bd z0re — the RECORD half of the runtime-seed L1 re-ask: for an untainted
  // base `TA` is the SOURCE theta (`cqrt_alloc(Base)` then the controlled Ry).
  // Keyed on the CLASSIFIER'S verdict, never on the taint seen here (an earlier
  // 6.5 region may have RAUW'd the base).
  if (R.RuntimeSeedAdmitted)
    taint.RuntimeSeedSourceThetas.push_back(TA);

  // ---- 3. THE FALSE-ARM GATE `x(f); R_c(f, B); x(f)`: the consumer `T` itself,
  // rewired onto `TA` with the FALSE arm, so `T` stays the LAST gate and every
  // user of its result reads the post-gate register unchanged. Both gates are
  // recorded so `lowerRotations` mints `cqrt_ry_<W>_controlled` at their
  // positions; the register then carries a controlled Ry, so it is FROZEN:
  // never reverse-played, never freed (`ChainWalk::railCarriesControlledRotation`).
  // The record lives on `TaintSet`, not `ControlPlan` (drbq Inc 1): the yn71
  // fixpoint discards its local `plan2`, so a plan-hosted map would lower an
  // onward gate UNCONDITIONALLY. The closing `x(f)` goes right after `T`, ahead
  // of the strip, so the flag is back to `[pred]` when the strip reads it.
  stamp(Bld.CreateCall(X, {Flag}));
  T->setArgOperand(0, TA);
  T->setArgOperand(1, B);
  taint.ControlledRotations[TA] = Flag;
  taint.ControlledRotations[T] = Flag;
  IRBuilder<> Post(After);
  stamp(Post.CreateCall(X, {Flag}));

  // ---- 4. FLAG STRIP + FREE after the consumer. The strip recomputes the
  // predicate on the condition's registers and returns the flag to |0⟩ (Rule 5),
  // valid because S8 proved the rotated rail disjoint from every condition rail
  // (an untainted base's rail is `TA`'s fresh mint, disjoint by construction).
  // `DischargedFlagGates` feeds `ChainWalk::isInteriorConsumer` clause (c): the
  // `_hl_unc` strip is a PURE READ of its slots >= 1 (re-prove on a change to
  // what it writes). `Strip` null is unreachable; were it null, the free would
  // be DIRTY — recorded rather than restructured.
  auto *Strip = dyn_cast_or_null<CallInst>(
      lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                         /*before=*/After, /*negate=*/false,
                         /*railToStrip=*/Flag));
  if (Strip)
    taint.DischargedFlagGates.insert(Strip);
  stamp(Post.CreateCall(wd.freeFn(), {Flag}));

  // ---- 5. ERASE THE SELECT (its only use, `T`'s angle, now names `B`), then the
  // compare if dead. A dead tainted compare must not stand: `lowerOps` would
  // lower it into a second flag rail nothing strips (six silent cells measured
  // under that deletion, bd ptue 2026-10-05). Scrub before erasing.
  scrubTaint(Sel, taint);
  Sel->eraseFromParent();
  if (Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }
}

}  // namespace cq
