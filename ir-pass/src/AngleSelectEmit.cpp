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
#include "CondTreeEmit.h"      // emitCondNetwork / stripCondNetwork (bd dm7f.54)
#include "SelectClassify.h"    // isCondRailLeaf / kBareRailCondReason (bd 3qlq.4)
#include "SwapRouteEmit.h"     // eraseDeadCondTreeInterior (bd dm7f.54)
#include "ControlPlan.h"       // ControlRegion / diagnoseUnderControl
#include "ControlledSymbols.h"  // xFn (3qlq Inc 1 phase angle select bracket)
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"     // freeFn

#include "llvm/ADT/DenseMap.h"
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

#include <functional>

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
  auto *T = R.Shadow.size() == 1 ? dyn_cast<CallInst>(R.Shadow.front())
                                 : nullptr;
  Function *Callee = T ? T->getCalledFunction() : nullptr;
  if (!Sel || !Callee) {
    if (R.Merge)
      diagnoseUnderControl(R.Merge, "control flow");
    return;
  }
  // 3qlq Inc 1 (PRD §6.2 row P2): the phase consumer forks the whole emitter.
  // bd 3qlq.4: its condition is a compare or the bare `_Bool` register, read
  // from the plan (a phase angle select has no φ leaf, so `R.Condition` is
  // live: nothing erases a compare or a rail before this region).
  if (isRegisterFreePhaseCall(T, taint)) {
    auto *CondI = dyn_cast_or_null<Instruction>(R.Condition);
    if (!CondI || (!isCondRailLeaf(CondI) && !isa<CmpInst>(CondI))) {
      diagnoseUnderControl(Sel, "control flow");
      return;
    }
    emitPhaseAngleSelect(Sel, CondI, T, wd, taint);
    return;
  }
  // ---- bd test_C_libtooling-dm7f.54 — THE Ry STEM, ONE EMITTER FOR EVERY
  // CONDITION KIND AND FOR THE NESTED MUX.
  //
  // CONDITIONS ARE READ OFF THE LIVE SELECTS, never off `R.Condition`: for a
  // claimed region-merge φ root (or φ leaf) the prep region emitted FIRST (the
  // `PrepRegionIdxs` edge) has RAUW'd the φ to its hoisted `cq_theta_i1` and
  // erased it, so the plan's raw pointer may be freed memory — exactly
  // `SelectMergeEmit`'s H-1. A member whose condition is a bare COMPARE mints
  // the shipped flag (`lowerCompareToFlag`); any other (`NetCond`: a rail, a
  // former φ, a compound tree) mints through `CondTreeEmit` with `CopyRailRoot`,
  // so every flag is an ancilla this region owns and no `cqrt_x` touches a user
  // register.
  //
  // THE MUX (item E, reporter t4 line 3): `collectAngleMux` lists the members
  // (pre-order) and the leaf angles (emission order). Each leaf angle reaches
  // EXACTLY ONE controlled gate, the X-bracket form of the owner ruling
  // (`owner-ruling-angle-select-xbracket-2026-10-13`) applied per level:
  //
  //   emit(S, ctl):  f = mint(cond S)
  //     ctl = none:  emit(T_S, f); x(f); emit(F_S, f); x(f)
  //     ctl = c:     p = |0>; toffoli(c, f, p); emit(T_S, p); toffoli(c, f, p)
  //                  x(f); toffoli(c, f, p); emit(F_S, p); toffoli(c, f, p); x(f)
  //                  free(p)
  //     strip(f)
  //   emit(leaf θ, ctl):  ry_controlled(ctl, h, θ)
  //
  // `p` is the PATH PREDICATE `c ∧ f` (then `c ∧ ¬f`) on a fresh |0> ancilla —
  // Bennett.jl's `_and_wire!` / `_not_wire!` path-predicate construction
  // (src/lowering/phi.jl:4-28), with the negation spelled by the self-inverse
  // `cqrt_x` bracket on the compiler-owned `f`. Each toffoli pair returns `p` to
  // |0> on every basis branch (`c`, `f` are unchanged between the pair; the
  // controlled Ry acts on the target only), so `free(p)` is a proven-|0> free.
  // For a one-member mux the recursion emits exactly the shipped stream
  // (`f = mint; ry_c(f,h,A); x(f); ry_c(f,h,B); x(f); strip`).
  //
  // THE GATES are `cq_theta` calls recorded in `taint.ControlledRotations`
  // (`lowerRotations` mints `cqrt_ry_<W>_controlled`): the first leaf's on
  // `Base`, each next one CHAINED on the previous, and the LAST leaf's is `T`
  // itself, rewired, so every user of `T` reads the post-mux register. Every
  // emission up to and including `T` lands BEFORE `T`; everything after the last
  // leaf (closing brackets, path-predicate undos, strips) lands AFTER `T`.
  const StringRef CalleeName = Callee->getName();
  const bool IsTheta = CalleeName.starts_with("cq_theta_");
  const bool IsPhi = CalleeName.starts_with("cq_phi_");  // retired register form
  if (!IsTheta && !IsPhi) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // The select is still the consumer's ANGLE only, the consumer its SOLE user.
  if (T->arg_size() < 2 || T->getArgOperand(1) != Sel ||
      T->getArgOperand(0) == Sel || !Sel->hasOneUse() ||
      Sel->user_back() != T) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  SmallVector<SelectInst *, 4> Members;
  SmallVector<Value *, 8> Leaves;
  if (!collectAngleMux(Sel, taint, Members, Leaves) || Leaves.size() < 2 ||
      (Members.size() > 1 && !IsTheta)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  Value *Base = T->getArgOperand(0);
  // A live register, or an UNTAINTED runtime base S3 admitted as state prep (bd
  // z0re). ONE QUESTION, THE CLASSIFIER'S (r1B F-r1B-2): `R.RuntimeSeedAdmitted`.
  // The reverse transition (tainted by an earlier 6.5 RAUW) is caught by the
  // record below plus `declineRound2QuantumPrepSeeds`. bd dm7f.54: or a
  // `nomerge` LITERAL seed, re-asked through the classifier's ONE predicate.
  if (!taint.Tainted.count(Base) && !R.RuntimeSeedAdmitted &&
      !angleSelectLiteralSeedAdmissible(T)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  Instruction *After = T->getNextNode();
  if (!After) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // Per member, in lockstep with the classifier's S4/S6, before any emission.
  // A `NetCond` tree is re-derived with gate 2's grammar but WITHOUT
  // `AllowRailPhi`: by now every φ leaf is its prep's hoisted `cq_theta_i1`, a
  // rail leaf; a φ still standing means the precedence edge was not honoured,
  // and the walk then fails LOUDLY rather than reading a stale name.
  struct MemberFlag {
    SelectInst *S;
    CmpInst *Cmp;  // non-null: the bare-compare member
    CondTree Tree;  // `NetCond` members
  };
  SmallVector<MemberFlag, 4> MF;
  DenseMap<const Value *, unsigned> MemberIdx;
  for (SelectInst *M : Members) {
    MemberFlag F{M, dyn_cast<CmpInst>(M->getCondition()), CondTree()};
    if (M->getParent() != T->getParent() || !M->comesBefore(T)) {
      diagnoseUnderControl(Sel, "control flow");
      return;
    }
    if (F.Cmp) {
      const bool LT = taint.Tainted.count(F.Cmp->getOperand(0)) != 0;
      const bool RT = taint.Tainted.count(F.Cmp->getOperand(1)) != 0;
      // 2b round-1 lens L4-1: a preceding 4.5 SwitchDataMux RAUW can make the
      // compare Q+Q, which has no mint here.
      if (F.Cmp->getParent() != T->getParent() || !F.Cmp->comesBefore(M) ||
          LT == RT || !comparePredLowerable(F.Cmp) ||
          !compareFlagMintable(F.Cmp, taint)) {
        diagnoseUnderControl(Sel, "control flow");
        return;
      }
    } else {
      if (!IsTheta) {
        diagnoseUnderControl(Sel, kBareRailCondReason);
        return;
      }
      if (!collectCondTree(M->getCondition(), F.Tree,
                           /*AllowLogicalSelect=*/true,
                           /*AllowRailPhi=*/false) ||
          !F.Tree.LiteralLeaves.empty() || !F.Tree.RailPhiLeaves.empty()) {
        diagnoseUnderControl(Sel, "control flow");
        return;
      }
      // The caller-independent backstop `SelectMergeEmit` carries: a rail read
      // as a control only through a classifier that asked the rail ladder.
      // ⚠ (item G) `R.RailLadderProven` is ONE bit computed over the
      // CLASSIFIER's leaves. A rail leaf HERE that the classifier saw as a
      // rail too was laddered (gate 2 per member + S11); one it saw as a φ is
      // that φ's prep's hoisted theta, laddered as the φ. The bit is sound
      // ONLY while M-β is the sole emission step that turns a non-rail leaf
      // into a rail leaf between detection and here. RETIREMENT TRIGGER: a
      // second such rewrite must re-ask the ladder per leaf at this line.
      if (!F.Tree.RailLeaves.empty() && !R.RailLadderProven) {
        diagnoseUnderControl(Sel, kBareRailCondReason);
        return;
      }
      for (CmpInst *Leaf : F.Tree.Leaves) {
        const bool LT = taint.Tainted.count(Leaf->getOperand(0)) != 0;
        const bool RT = taint.Tainted.count(Leaf->getOperand(1)) != 0;
        if (LT == RT || !comparePredLowerable(Leaf) ||
            !compareFlagMintable(Leaf, taint)) {
          diagnoseUnderControl(Sel, "control flow");
          return;
        }
      }
      for (CallInst *Rail : F.Tree.RailLeaves)
        if (!taint.Tainted.count(Rail)) {
          diagnoseUnderControl(Sel, "control flow");
          return;
        }
    }
    MemberIdx[M] = MF.size();
    MF.push_back(std::move(F));
  }
  // `T` must be in `lowerRotations`' work list; each new rotation goes
  // IMMEDIATELY BEFORE it, in stream order, so `T` lowers with arg-0 already
  // RAUW'd to the handle (drbq Inc 2b M15).
  auto &Work = IsTheta ? taint.ThetaCalls : taint.PhiCalls;
  if (llvm::find(Work, T) == Work.end() || taint.ControlledRotations.count(T)) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  // Rule 3 and S1's arm question in lockstep, per LEAF.
  for (Value *L : Leaves)
    if (taint.Tainted.count(L) || !angleSelectArmsDefined(L, L)) {
      diagnoseUnderControl(Sel, "control flow");
      return;
    }
  ControlledSymbols Csyms(*T->getModule(), wd);
  FunctionCallee X = Csyms.xFn();
  FunctionCallee Toff = Csyms.toffoliFn();
  FunctionCallee AllocI1 = wd.allocFn("i1");
  if (!X || (Members.size() > 1 && (!Toff || !AllocI1))) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  // ---- EMISSION STARTS HERE. Nothing below may decline (a mint failure in
  // `lowerCompareToFlag` / the network is already LOUD and `DS_Error` exits).
  const DebugLoc DL = Sel->getDebugLoc();
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  IRBuilder<> Bld(T);
  bool PastT = false;  // once the last leaf's gate (`T`) is placed
  Instruction *Point = T;  // the instruction every emission lands before
  CallInst *Prev = nullptr;
  size_t LeafNo = 0;
  Type *I1Ty = Type::getInt1Ty(T->getContext());
  SmallVector<CallInst *, 4> AllStrips;
  bool Failed = false;

  // One leaf: its gate, controlled on `Ctl`.
  auto emitLeaf = [&](Value *Angle, Value *Ctl) {
    const bool Last = (++LeafNo == Leaves.size());
    CallInst *G;
    if (Last) {
      G = T;  // rewired in place: `T` stays the LAST gate.
      T->setArgOperand(0, Prev ? static_cast<Value *>(Prev) : Base);
      T->setArgOperand(1, Angle);
      PastT = true;
      Point = After;
      Bld.SetInsertPoint(After);
    } else {
      G = stamp(Bld.CreateCall(Callee,
                               {Prev ? static_cast<Value *>(Prev) : Base, Angle}));
      taint.Tainted.insert(G);
      taint.BirthOrder[G] = taint.NextBirth++;
      Work.insert(llvm::find(Work, T), G);
      // bd z0re — the RECORD half of the runtime-seed L1 re-ask: the first gate
      // is the SOURCE theta (`cqrt_alloc(Base)` then the controlled Ry). Keyed
      // on the CLASSIFIER'S verdict, never on the taint seen here.
      if (!Prev && R.RuntimeSeedAdmitted)
        taint.RuntimeSeedSourceThetas.push_back(G);
    }
    taint.ControlledRotations[G] = Ctl;
    Prev = G;
  };

  // One member's flag: minted at the current point, returned with its strip.
  auto mintFlag = [&](MemberFlag &F, CondNetwork &Net) -> Value * {
    if (F.Cmp)
      return lowerCompareToFlag(F.Cmp, wd, taint, /*qqWidth=*/{},
                                /*inverse=*/false, /*before=*/Point,
                                /*negate=*/false, /*railToStrip=*/nullptr,
                                /*readKind=*/CondReadKind::WireRuled);
    // `LeafWireRuled`: gate 2c ruled on these leaves (each member is a
    // tainted-condition select that passed gate 2 on its own condition).
    switch (emitCondNetwork(F.S->getCondition(), F.Tree, wd, Csyms, taint,
                            /*Before=*/Point, DL, /*AllowQQLeaves=*/false, Net,
                            /*CopyRailRoot=*/true, /*LeafWireRuled=*/true)) {
    case CondNetDisp::Ok:
      break;
    case CondNetDisp::MintDiagnosed:
      return nullptr;
    case CondNetDisp::Malformed:
      diagnoseUnderControl(Sel, "control flow");
      return nullptr;
    }
    // The inverted drift guard: the root is `cqrt_x`-bracketed below, so it
    // MUST be an ancilla this region owns.
    if (Net.RootIsRail || !Net.Root) {
      diagnoseUnderControl(Sel, "control flow");
      return nullptr;
    }
    return Net.Root;
  };
  auto stripFlag = [&](MemberFlag &F, CondNetwork &Net, Value *Flag) {
    // The strip recomputes each predicate on the condition's registers: valid
    // because S8 proved the rotated rail disjoint from every condition rail of
    // every member (or the rail is a fresh seed's), and nothing else here moves
    // a basis label. `DischargedFlagGates` feeds `ChainWalk::isInteriorConsumer`
    // clause (c) (the `_hl_unc` strip is a PURE READ of its slots >= 1).
    if (F.Cmp) {
      auto *Strip = dyn_cast_or_null<CallInst>(lowerCompareToFlag(
          F.Cmp, wd, taint, /*qqWidth=*/{}, /*inverse=*/true, /*before=*/Point,
          /*negate=*/false, /*railToStrip=*/Flag));
      if (Strip)
        taint.DischargedFlagGates.insert(Strip);
      stamp(Bld.CreateCall(wd.freeFn(), {Flag}));
      return;
    }
    SmallVector<CallInst *, 4> LeafStrips;
    stripCondNetwork(Net, wd, Csyms, taint, /*Before=*/Point, DL,
                     /*AllowQQLeaves=*/false, &LeafStrips);
    for (CallInst *S : LeafStrips)
      taint.DischargedFlagGates.insert(S);
  };

  std::function<void(Value *, Value *)> emitNode = [&](Value *V, Value *Ctl) {
    if (Failed)
      return;
    auto It = MemberIdx.find(V);
    if (It == MemberIdx.end()) {
      emitLeaf(V, Ctl);
      return;
    }
    MemberFlag &F = MF[It->second];
    CondNetwork Net;
    Value *Flag = mintFlag(F, Net);
    if (!Flag) {
      Failed = true;
      return;
    }
    Value *TV = F.S->getTrueValue();
    Value *FV = F.S->getFalseValue();
    if (!Ctl) {
      emitNode(TV, Flag);
      stamp(Bld.CreateCall(X, {Flag}));
      emitNode(FV, Flag);
      stamp(Bld.CreateCall(X, {Flag}));
    } else {
      CallInst *P = stamp(
          Bld.CreateCall(AllocI1, {Constant::getNullValue(I1Ty)}, "p"));
      stamp(Bld.CreateCall(Toff, {Ctl, Flag, P}));
      emitNode(TV, P);
      stamp(Bld.CreateCall(Toff, {Ctl, Flag, P}));
      stamp(Bld.CreateCall(X, {Flag}));
      stamp(Bld.CreateCall(Toff, {Ctl, Flag, P}));
      emitNode(FV, P);
      stamp(Bld.CreateCall(Toff, {Ctl, Flag, P}));
      stamp(Bld.CreateCall(X, {Flag}));
      stamp(Bld.CreateCall(wd.freeFn(), {P}));
    }
    stripFlag(F, Net, Flag);
  };
  emitNode(Sel, nullptr);
  if (Failed)
    return;  // already LOUD; `DS_Error` exits.
  if (!PastT) {
    diagnoseUnderControl(Sel, "control flow");  // unreachable: >= 2 leaves.
    return;
  }

  // ---- ERASE every member (pre-order: each one's only user, its parent or
  // `T`'s angle slot, is gone first), then each member's condition if dead. A
  // dead tainted compare must not stand: `lowerOps` would lower it into a
  // second flag rail nothing strips (bd ptue). A `NetCond` tree erases its dead
  // ROOT (never a rail: the user's register) and then its dead interior through
  // the ONE cascade (`eraseDeadCondTreeInterior`); a root or node with another
  // user (item D) is left for that user.
  SmallVector<std::pair<Value *, MemberFlag *>, 4> Conds;
  for (MemberFlag &F : MF)
    Conds.push_back({F.S->getCondition(), &F});
  for (SelectInst *M : Members) {
    scrubTaint(M, taint);
    M->eraseFromParent();
  }
  for (auto &[CondV, F] : Conds) {
    if (F->Cmp) {
      if (F->Cmp->use_empty()) {
        scrubTaint(F->Cmp, taint);
        F->Cmp->eraseFromParent();
      }
      continue;
    }
    auto *RootI = dyn_cast<Instruction>(CondV);
    if (RootI && !isCondRailLeaf(RootI) && RootI->use_empty()) {
      scrubTaint(RootI, taint);
      RootI->eraseFromParent();
    }
    eraseDeadCondTreeInterior(F->Tree, CondV, taint);
  }
}

}  // namespace cq
