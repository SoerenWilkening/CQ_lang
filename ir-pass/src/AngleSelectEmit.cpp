// AngleSelectEmit.cpp — see header. The by-difference lowering for an accepted
// tainted-condition ANGLE select (control-in-place-PRD §12.3, bd
// test_C_libtooling-drbq Increment 2b), both rotation stems.
//
// Reuses `lowerCompareToFlag` (mint + `_unc` strip), `wd.freeFn()` and the drbq
// `taint.ControlledRotations` hoist-and-defer record verbatim (Rule 14). The only
// original logic here is the EMISSION ORDER, which IS the contract: the
// unconditional twin FIRST, then the mint, then the rewired consumer, then the
// strip, then the free — because that order is what makes the emitted stream
// byte-identical to the manual by-difference diamond the pre-2b binary lowers.
// (The function is numbered 0..6 below — 0 and 0b validate, 1..5 emit, 6 erases;
// the earlier "five-step" wording counted only the emitting half and is corrected
// here rather than in the step numbering, round-1 review lens L6-N11.)

#include "AngleSelectEmit.h"

#include "ArmAnalysis.h"       // angleSelectArmsAdmissible / comparePredLowerable
#include "ChainWalk.h"         // markBranchPhaseGate (3qlq Inc 1 F-L7-1)
#include "CompareLowering.h"   // lowerCompareToFlag + compareFlagMintable (step 0b)
#include "ControlPlan.h"       // ControlRegion / diagnoseUnderControl
#include "ControlledSymbols.h"  // xFn (3qlq Inc 1 phase angle select bracket)
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"     // freeFn

#include "llvm/ADT/STLExtras.h"     // llvm::find
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/ADT/StringRef.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// so a later module walk (`lowerRotations` / `lowerOps` / `uncompute`) never
// dereferences freed memory. A per-TU mirror of `SelectMergeEmit::scrubTaint`
// (the house style for trivial taint-set maintenance). Idempotent.
//
// The two erased classes here are the ANGLE SELECT itself (which IS tainted — a
// select is a user of its tainted condition, so `propagate` marks it) and, when
// it goes dead, the CONDITION COMPARE. Leaving a dead tainted compare standing
// is not cosmetic: `lowerOps` would lower it into a `cq_template_icmp_*` flag
// rail that nothing strips and nothing frees — an unpaired, condition-entangled
// leak (the `SelectMergeEmit.cpp` step-6 discipline, verbatim).
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  taint.HandleWidth.erase(I);
  // THE BLOCK BELOW IS UNREACHABLE AS CALLED and is kept as defence in depth,
  // not as the distinguishing feature (round-1 Rule-13 review, lens L5-5 — the
  // notes' §3(a) table presented it as what separates this scrub from its
  // siblings, which is false). The two erased classes are a `SelectInst` and a
  // `CmpInst`; neither is ever a `CallInst`, so the `PhiCalls`/`ThetaCalls`
  // removal never runs today. What IS true and IS the difference from the
  // sibling scrubs is that this TU is the only one whose emitter also INSERTS
  // into `ThetaCalls`/`PhiCalls` (the unconditional twin), so a future erase of
  // a rotation from here is the shape this block exists for.
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
    auto &TC = taint.ThetaCalls;
    TC.erase(std::remove(TC.begin(), TC.end(), CI), TC.end());
  }
}


// ── bd test_C_libtooling-3qlq Inc 1 — P2, the REGISTER-FREE PHASE ANGLE SELECT ─
//
// `if (c) cq_phi(A); else cq_phi(B);` never reaches the pass as a diamond:
// `clang -O1` sinks both calls into ONE `call void @cq_phi(double %sel)` with
// `%sel = select i1 %c, double A, double B` (MEASURED, PRD §6.1 row 2). The
// emitted stream, at the consumer's position, is:
//
//     cq_template_icmp_<pred>_<W>_hl(q, lit) -> f     ; flag mint
//     cqrt_x(f); cqrt_rz_i1(f, B); cqrt_x(f)          ; P(B) on the f = 0 branch
//     cqrt_rz_i1(f, A)                                ; P(A) on the f = 1 branch
//     cq_template_icmp_<pred>_<W>_hl_unc(f, q, lit)   ; flag strip → |0>
//     cqrt_free(f)
//
// WHY THIS IS EXACT WHERE THE BY-DIFFERENCE FORM IS NOT (PRD §3). Under
// `Rz(θ) = diag(e^{−iθ/2}, e^{iθ/2})` the four gates give `|0⟩` the factor
// `e^{i(B−A)/2}` and `|1⟩` the factor `e^{i(A−B)/2}` — a RELATIVE phase of
// `e^{i(A−B)}` between the two branches, which is the same relative phase
// `P(A)`-on-1 / `P(B)`-on-0 produces, times an unobservable global phase. No
// `fsub` is performed, so no value the source did not name enters a gate slot:
// `A` and `B` are passed through VERBATIM. That is the whole reason a RUN-TIME
// arm is admitted here (owner question Q3) while the by-difference Ry stem below
// refuses one — there, `fl(A−B)` is unbounded in absolute radians (MEASURED at
// 0.858 rad for `π`/`1e16`) and can be `inf` from two finite arms.
//
// THERE IS NO POLARITY CASE. A `select` means "A when the condition is 1", full
// stop — unlike a `br` diamond, whose gate arm `clang -O1` often makes the FALSE
// successor (Rule 9). The `cqrt_x` bracket here is not a polarity fix: it is how
// the `f = 0` branch's gate is expressed at all, and it is the same self-inverse
// pair every "fires on ¬f" emission in this tree uses.
void emitPhaseAngleSelect(SelectInst *Sel, CmpInst *Cond, CallInst *T,
                          WidthDispatch &wd, TaintSet &taint) {
  // ---- 0. RE-VALIDATE, before mutating anything (the step-0 discipline of the
  // by-difference emitter: a mid-stream decline leaves a minted flag and a
  // half-rewired consumer behind).
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
  // S4's SEMANTIC half, re-asked in lockstep (the round-1 L4-1 repair, which
  // applies here for the identical reason: a PRECEDING region's RAUW in this
  // same `lowerControlRegions` loop can turn the compare Q+Q between detection
  // and now, and this emitter has no Q+Q mint either).
  const bool LTainted = taint.Tainted.count(Cond->getOperand(0)) != 0;
  const bool RTainted = taint.Tainted.count(Cond->getOperand(1)) != 0;
  if (LTainted == RTainted || !comparePredLowerable(Cond) ||
      !compareFlagMintable(Cond, taint)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  FunctionCallee Rz = wd.rzRtFn("i1");
  // `cqrt_x` through `ControlledSymbols` — the ONE spelling of the negation
  // bracket in this tree (Rule 14). The object is a trivial `{Module&,
  // WidthDispatch&}` wrapper whose resolvers are `getOrInsertFunction`, i.e.
  // idempotent, so constructing one here costs nothing and cannot mint a second
  // symbol.
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

  // ---- 1. FLAG MINT, at the consumer — byte-identical to every other path's
  // step 1 (`lowerCompareToFlag` classifies the operands by taint and applies
  // the classical-on-left predicate flip itself).
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/T);
  if (!Flag)
    // UNREACHABLE for the two reasons the sibling records — the lockstep re-ask
    // above, and `DS_Error` → `exit(1)` inside `lowerCompareToFlag`'s own
    // failure path. Nothing has been emitted yet, so the `return` is honest
    // defence in depth rather than a mid-stream bail.
    return;

  // ---- 2. THE TWO GATES. Both RECORDED as branch-phase (kickback) gates
  // (`ChainWalk::markBranchPhaseGate`) so the whole-DAG uncompute spine treats
  // them as opaque and never emits their negated twins — the Rule-13 round-1
  // CONFIRMED miscompile F-L7-1, whose reproducer lives on the sibling flat path
  // but whose mechanism (`isInPlaceGateOn` admitting an uncontrolled `cqrt_rz_`)
  // is shared by every producer of this symbol.
  stamp(Bld.CreateCall(X, {Flag}));
  markBranchPhaseGate(stamp(Bld.CreateCall(Rz, {Flag, B})));
  stamp(Bld.CreateCall(X, {Flag}));
  markBranchPhaseGate(stamp(Bld.CreateCall(Rz, {Flag, A})));

  // ---- 3. STRIP + FREE, after the consumer's position. Valid unconditionally:
  // this region emits no gate on any register the compare reads, so the basis
  // the strip recomputes is identically the basis the mint read.
  auto *Strip = dyn_cast_or_null<CallInst>(
      lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                         /*before=*/After, /*negate=*/false,
                         /*railToStrip=*/Flag));
  if (Strip)
    taint.DischargedFlagGates.insert(Strip);
  IRBuilder<> Post(After);
  stamp(Post.CreateCall(wd.freeFn(), {Flag}));

  // ---- 4. ERASE the consumer, then the select, then the compare if it is now
  // dead. The order is forced by the use lists (the call uses the select, the
  // select uses the compare). Leaving a dead tainted COMPARE standing is not
  // cosmetic — `lowerOps` would lower it into a second `cq_template_icmp_*` flag
  // rail that nothing strips and nothing frees (the `SelectMergeEmit` step-6
  // discipline, verbatim).
  auto &PC = taint.PhaseCalls;
  PC.erase(std::remove(PC.begin(), PC.end(), T), PC.end());
  T->eraseFromParent();
  scrubTaint(Sel, taint);
  Sel->eraseFromParent();
  if (Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }
}

}  // namespace

void emitAngleSelectRegion(const ControlRegion &R, WidthDispatch &wd,
                           TaintSet &taint) {
  // ---- 0. RE-VALIDATE THE PLAN BY SSA IDENTITY, BEFORE MUTATING ANYTHING.
  //
  // Every decline below is LOUD and every one precedes the FIRST emitted
  // instruction. Both halves are deliberate: a silently skipped accepted region
  // leaves the tainted select to the backend as classical control over quantum
  // state (Rule 1, the unforgivable outcome), and a region that declines
  // MID-STREAM leaves a minted flag and a half-rewired gate behind — the Inc-2a
  // round-1 F-5 finding, whose fix was to move every check ahead of the first
  // emission. The sibling `emitInPlaceRotationRegion` states the same invariant.
  //
  // *** AND IT ONLY BECAME TRUE OF THIS FUNCTION IN THE 2b ROUND-1 RULE-13 REVIEW
  // *** (lens L4-1). Step 0 as shipped asked IDENTITY only; step 0b below adds
  // S4's SEMANTIC re-ask, which is the half a preceding region's RAUW can
  // invalidate. Read the two together — identity alone is not "the plan describes
  // the IR".
  auto *Sel = dyn_cast_or_null<SelectInst>(R.Merge);
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  if (!Sel || !Cond) {
    if (R.Merge)
      diagnoseUnderControl(R.Merge, "control flow");
    else if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
      diagnoseUnderControl(A, "control flow");
    return;
  }
  auto *T = R.Shadow.size() == 1 ? dyn_cast<CallInst>(R.Shadow.front())
                                 : nullptr;
  if (!T) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  Function *Callee = T->getCalledFunction();
  if (!Callee) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // bd test_C_libtooling-3qlq Inc 1 (PRD §6.2 row P2) — the REGISTER-FREE
  // BRANCH-PHASE consumer takes a DIFFERENT lowering, not a different symbol,
  // so it forks the whole emitter rather than a `Callee` string:
  //
  //   x(f); rz_i1(f, B); x(f); rz_i1(f, A)
  //
  // `P(A)` on `f = 1`, `P(B)` on `f = 0`, EXACT, no subtraction. Everything the
  // by-difference form below exists to fence — the `fsub` the source never
  // wrote, its `½ ulp(A−B)` residual, the `2^-40` bound, the constant-arms-only
  // narrowing of clearance blocker F-11 — has no subject here, which is why a
  // RUN-TIME arm is admissible for this stem (owner question Q3) and remains
  // refused for the Ry one.
  if (isRegisterFreePhaseCall(T, taint)) {
    emitPhaseAngleSelect(Sel, Cond, T, wd, taint);
    return;
  }
  const StringRef CalleeName = Callee->getName();
  const bool IsTheta = CalleeName.starts_with("cq_theta_");
  const bool IsPhi = CalleeName.starts_with("cq_phi_");
  if (!IsTheta && !IsPhi) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // The select must still be the consumer's ANGLE and nothing else; the consumer
  // must still be the select's SOLE user; the condition must still be the
  // select's. Detection proved all three, and detection ran before any emitter —
  // but another region emitted earlier in this same `lowerControlRegions` loop
  // could in principle have rewritten one of them, and "the plan does not
  // describe the IR" must be a decline, never a dereference (the round-1 L4
  // `RoutedBase` lesson one shape over).
  if (T->arg_size() < 2 || T->getArgOperand(1) != Sel ||
      T->getArgOperand(0) == Sel || !Sel->hasOneUse() ||
      Sel->user_back() != T || Sel->getCondition() != Cond) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  Value *Base = T->getArgOperand(0);
  if (!taint.Tainted.count(Base)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // Position: one block, `Cond` before `Sel` before `T`, and a successor for `T`
  // to hang the strip and the free on. Detection proved the ordering; the
  // successor is asked HERE because it is an emission fact, not a shape fact
  // (`T` has a user, so it is never a terminator — but a null next node would
  // otherwise be a null dereference rather than a decline).
  Instruction *After = T->getNextNode();
  if (T->getParent() != Sel->getParent() || Cond->getParent() != T->getParent() ||
      !Cond->comesBefore(Sel) || !Sel->comesBefore(T) || !After) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // `T` must still be in the work list `lowerRotations` walks, and the twin goes
  // IMMEDIATELY BEFORE it there.
  //
  // ⚠ THE FIRST DRAFT OF THIS COMMENT SAID "ORDER IS LOAD-BEARING … appending at
  // the END would mint an ill-typed `cqrt_*` call", AND THE MUTATION TEST SAID
  // OTHERWISE — recorded because an overstated justification is how a real fence
  // later gets deleted as redundant. Measured (bd drbq Inc 2b, mutation M15):
  // replacing this with `Work.push_back(T0)` produces BYTE-IDENTICAL output on
  // every fixture, at i8, at f64 and at i32, with `opt` exit 0. The repair is
  // accidental and comes from `lowerRotations` itself: lowering `T` first DOES
  // create `cqrt_ry_<W>_controlled(f, <T0, still i8/double-typed>, θ)`, but
  // lowering `T0` on the next iteration ends with
  // `T0->replaceAllUsesWith(Handle)`, which rewrites that very operand to the
  // i32 handle before the verifier ever runs. The emitted STREAM order is
  // unaffected either way, because each `cqrt_*` is inserted at its own
  // rotation's position, not in work-list order.
  //
  // THE POSITION IS KEPT ANYWAY, for two reasons that are not "it would
  // miscompile": (1) appending creates a genuinely MALFORMED instruction for the
  // span of one loop iteration, which an assertions-ON LLVM aborts on
  // (`CallInst::Create`'s operand-type assert) — this build is assertions-OFF,
  // so the whole difference is invisible here and would surface only elsewhere;
  // (2) relying on a later RAUW to repair a mistyped call is exactly the kind of
  // accidental correctness this project records rather than depends on, and it
  // would stop holding the moment a rotation is lowered without that RAUW.
  // `control_angle_select_ry_{f64_fcmp,i8}.ll` pin the RESULT (every rotation
  // call takes an i32 handle); no fixture can pin the transient.
  auto &Work = IsTheta ? taint.ThetaCalls : taint.PhiCalls;
  auto Slot = llvm::find(Work, T);
  if (Slot == Work.end()) {
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
  if (taint.Tainted.count(A) || taint.Tainted.count(B)) {
    diagnoseUnderControl(Sel, "control flow");  // Rule 3 — quantum in the angle.
    return;
  }
  // ARM VALUES, re-asked in lockstep with S1's second half (Rule 14 — the SAME
  // `angleSelectArmsAdmissible`, not a second spelling; verified single-spelling
  // by the clearance review, §2, and re-verified here). Detection proved it, but
  // the whole point of step 0 is that a plan can stop describing the IR, and an
  // undef/poison/non-finite/badly-rounded/RUN-TIME arm reaching `CreateFSub`
  // below is a value the source never named landing in a gate slot. Since the
  // clearance narrowing this ALSO carries the constant-arms-only clause (2c), so
  // there is no path on which the emitter synthesizes an `fsub` over anything
  // but two `ConstantFP`s.
  if (!angleSelectArmsAdmissible(A, B)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  // ---- 0b. RE-ASK S4's SEMANTIC HALF, NOT JUST SSA IDENTITY.
  //
  // *** THIS IS THE ROUND-1 RULE-13 REPAIR (bd drbq Inc 2b, lens L4-1) AND IT IS
  // THE REASON THE "NOTHING BELOW MAY DECLINE" LINE BELOW IS NOW TRUE. *** Every
  // check above this point asks about SSA IDENTITY — is `%ang` still the
  // consumer's angle, is `%c` still its condition. S4 also asked a SEMANTIC
  // question that identity cannot preserve: how many operands of the compare are
  // TAINTED, and can a flag be minted from it. Both answers can CHANGE between
  // detection and this emitter, because another region emits first in the same
  // `lowerControlRegions` loop:
  //
  //   a preceding 4.5 SwitchDataMux region RAUWs its all-`ConstantInt` merge phi
  //   to a freshly minted TAINTED `%out` rail, and a compare that read that phi
  //   as its CLASSICAL operand becomes Q+Q — a shape S4 refuses and this emitter
  //   has no mint for.
  //
  // Before this clause the module got as far as steps 1–2 (the `fsub` and the
  // unconditional twin, the twin already inserted into `taint.Tainted`,
  // `BirthOrder` and the rotation work list) and only THEN bailed inside step 3,
  // with `lowerCompareToFlag`'s MISLABELLED `no template for opcode 'icmp i1' in
  // tainted context`. That is a MID-STREAM decline: loud today only because
  // `DS_Error` calls `exit(1)`, i.e. because the process dies before anyone can
  // see the half-emitted module. Fixture:
  // `control_angle_select_reject_datamux_qq_after_rauw.ll`.
  const bool LTainted = taint.Tainted.count(Cond->getOperand(0)) != 0;
  const bool RTainted = taint.Tainted.count(Cond->getOperand(1)) != 0;
  if (LTainted == RTainted || !comparePredLowerable(Cond) ||
      !compareFlagMintable(Cond, taint)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  // ---- EMISSION STARTS HERE. Nothing below may decline.
  const DebugLoc DL = Sel->getDebugLoc();
  auto stamp = [&](Instruction *I) {
    if (DL)
      I->setDebugLoc(DL);
    return I;
  };
  IRBuilder<> Bld(T);  // everything lands immediately before the consumer.

  // ---- 1. THE ANGLE DIFFERENCE `A − B`, computed ONCE.
  //
  // `IRBuilder`'s constant folder turns two `ConstantFP`s into a `ConstantFP`
  // (APFloat subtract, IEEE round-to-nearest — the same evaluation `clang` gives
  // the manual twin's `0.9 - 0.3`, which is why the byte-diff against the twin
  // is exact and not merely close).
  //
  // SINCE THE CLEARANCE NARROWING (finding F-11, owner option (2) — constant
  // arms only) THAT IS THE ONLY CASE THAT REACHES HERE: clause (2c) of
  // `angleSelectArmsAdmissible` refuses a run-time arm at DETECTION and again at
  // step 0, so this call ALWAYS folds and NO `fsub` instruction survives it —
  // which is why no fixture in the family carries an `fsub` line any more.
  // `CreateFSub` is kept rather than replaced by a hand-rolled APFloat subtract
  // for two reasons: it is the same folder `clang` applies to the manual twin's
  // `A - B` (Rule 14 — one spelling of the arithmetic, which is what makes the
  // byte-diff against the twin exact), and if owner option (1) ever restores
  // run-time arms this line produces a real `fsub double` again with no other
  // change. Such an `fsub` would stay CLASSICAL — both operands untainted by the
  // accept predicate, so `lowerOps` never sees it and `declineTaintedAngle`
  // never fires on it — which is why the `dyn_cast<Instruction>` stamp below is
  // kept too, presently inert.
  Value *D = Bld.CreateFSub(A, B, "cqang");
  if (auto *DI = dyn_cast<Instruction>(D))
    stamp(DI);

  // ---- 2. THE UNCONDITIONAL TWIN `R(base, B)`.
  //
  // Spelled as the SAME `@cq_theta_<sfx>` / `@cq_phi_<sfx>` callee the consumer
  // uses, never as a `cqrt_*` runtime call: pre-`lowerRotations` the register is
  // still a `cq_*` SSA value (for an f64 register, `double`-typed), and every
  // pre-lowering wire walker recognizes an in-place gate by that spelling with
  // the wire at arg 0. Inserted into the taint sets exactly as
  // `RotationLowering` does for a minted handle, and into the rotation work list
  // IMMEDIATELY BEFORE `T` (see the `Slot` note above).
  CallInst *T0 = Bld.CreateCall(Callee, {Base, B});
  stamp(T0);
  // MEASURED INERT, KEPT AS DEFENCE IN DEPTH (round-1 Rule-13 review, lens L5-4):
  // dropping these two lines produced 0 red fixtures and 0 output diffs. They are
  // kept because `BirthOrder.lookup` returns 0 for an absent key rather than
  // failing, so a future reader that orders by birth would silently sort the twin
  // FIRST in the whole module — the kind of wrong answer that has no symptom.
  taint.Tainted.insert(T0);
  taint.BirthOrder[T0] = taint.NextBirth++;
  Work.insert(Slot, T0);

  // ---- 3. THE FLAG MINT, at the consumer.
  //
  // Byte-identical to every other path's step 1. `lowerCompareToFlag` classifies
  // the operands by taint and applies the classical-on-left predicate flip
  // itself, so a `5 == q` source mints the same `_hl` symbol a `q == 5` one does.
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/T);
  if (!Flag)
    // UNREACHABLE, and say WHY rather than calling it a bail (round-1 Rule-13
    // review, lens L1-1 / L4-1). This is NOT a "pre-emission" check — the `fsub`
    // and the unconditional twin are already in the IR by the time control gets
    // here, so returning would leave TWO rotations on the register and a
    // half-rewired consumer. It is unreachable for TWO independent reasons:
    // step 0b re-asks `compareFlagMintable` in lockstep with this call (the
    // dry-run predicate exists for exactly that), and `lowerCompareToFlag`'s own
    // failure path diagnoses with `DS_Error`, which `LLVMContext::diagnose`
    // turns into `exit(1)` before this line is reached at all. The `return` is
    // kept as defence in depth against a future `DS_Warning` re-grading, not as
    // a decline.
    return;

  // ---- 4. REWIRE THE CONSUMER: chain it onto the twin, give it the DIFFERENCE
  //         angle, and record the flag so `lowerRotations` mints the CONTROLLED
  //         rotation at this position instead of the unconditional one.
  //
  // The record lives on `TaintSet`, not on `ControlPlan`, for the reason drbq
  // Inc 1 records at the field: there is not ONE plan per compilation (the yn71
  // onward-control fixpoint builds a local `plan2`, emits it and discards it,
  // while `lowerRotations` is handed the FIRST plan), so a plan-hosted map would
  // silently lower an onward region's gate UNCONDITIONALLY — a wrong unitary.
  T->setArgOperand(0, T0);
  T->setArgOperand(1, D);
  taint.ControlledRotations[T] = Flag;

  // ---- 5. FLAG STRIP + FREE, after the consumer.
  //
  // The strip recomputes the predicate on the CONDITION's registers and XORs it
  // back onto the flag, returning it to |0⟩ so the `cqrt_free` is clean (Rule 6).
  // Its validity is the accept predicate's whole content:
  //   * for `cq_phi` the gates between mint and strip are DIAGONAL, so no basis
  //     label moves at all and the strip is valid even when the rotated register
  //     IS a condition register (PRD §3c — the stem separator);
  //   * for `cq_theta` S8 proved the rotated register's PHYSICAL rail is disjoint
  //     from every rail the condition reads, so the condition's basis at the
  //     strip is the basis the mint read (PRD §3).
  //
  // `DischargedFlagGates` records the strip. THE JUSTIFICATION FOR THAT RECORD IS
  // NOT S8 (round-1 Rule-13 review, lens L1-2 — the first draft said "if S8 is
  // ever widened, this recording must be re-proved", which named the wrong
  // trigger). What the record buys is `ChainWalk::isInteriorConsumer`'s clause
  // (c): the `_unc` strip is a PURE READ of its slots >= 1, so a rail appearing
  // there is not thereby a live forward consumer. That property is
  // UNCONDITIONAL on the `cq_template_<op>_<W>_hl_unc` symbol — it holds whatever
  // S8 says about wires. The real re-proof triggers are (i) a change to what
  // `_hl_unc` WRITES, and (ii) a SECOND minter of that symbol with different
  // effects. Readers: `ChainWalk.cpp:767` (that clause) and `:836`
  // (`isInteriorTerminalHandle`); `SwapRouteEmit.cpp:113` scrubs the set.
  //
  // `Strip` null is UNREACHABLE for the same two reasons the mint's null is
  // (step 0b's lockstep re-ask, and `DS_Error` → `exit(1)`); the
  // `dyn_cast_or_null` and the `if` are defence in depth. Note what the code
  // does NOT do if it ever were null: the `cqrt_free` below fires REGARDLESS,
  // which on an unstripped flag would be a DIRTY free (Rule 6). Recorded rather
  // than restructured, because restructuring it would mean choosing between a
  // dirty free and a leaked flag on a path that cannot be taken.
  auto *Strip = dyn_cast_or_null<CallInst>(
      lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                         /*before=*/After, /*negate=*/false,
                         /*railToStrip=*/Flag));
  if (Strip)
    taint.DischargedFlagGates.insert(Strip);
  IRBuilder<> Post(After);
  stamp(Post.CreateCall(wd.freeFn(), {Flag}));

  // ---- 6. ERASE THE SELECT, then the compare if it is now dead.
  //
  // The select's only user was the consumer's angle slot, which now names `D`,
  // so it is dead. The compare is dead too in the canonical single-use case (the
  // mint and the strip built FRESH template calls from its OPERANDS —
  // `lowerCompareToFlag` does not consume the compare) and the accept predicate
  // required exactly that one user; the `use_empty` guard is kept anyway, since
  // a surviving user means `lowerOps` still owns it. Scrub before erasing so no
  // later module walk dereferences freed memory.
  //
  // WHAT LEAVING THE COMPARE STANDING WOULD ACTUALLY COST — measured, because the
  // first draft of this comment said "a silent leak" and that is only sometimes
  // true (round-1 Rule-13 review, lens L5-6). Deleting the erase turns 14 of the
  // 46 angle-select fixtures RED, and on MOST shapes the failure is LOUD:
  // `lowerOps` lowers the dead tainted compare into a second
  // `cq_template_icmp_*_hl` flag rail that nothing strips, and `Uncomputation`
  // then refuses with `dead chain would free a measured register`. The EXCEPTION
  // is `control_angle_select_ry_lifted_phi_base.ll`, where `opt` exits 0 with a
  // never-stripped, condition-entangled second flag rail: strict stage 2b passes
  // and FileCheck was green. That fixture now carries a
  // `CNT-COUNT-1: cq_template_icmp_eq_i32_hl(` so the silent cell is fenced too.
  scrubTaint(Sel, taint);
  Sel->eraseFromParent();
  if (Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }
}

}  // namespace cq
