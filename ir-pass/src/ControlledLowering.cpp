// ControlledLowering.cpp — see header. Per-region pipeline + the flag's
// compute/uncompute bracket (§1.5), LIFO for compound/nested regions (§2.9).
//
// `br`-diamond region (WP3) — ordering within a region (so the linearized
// block reads compute → controlled body → uncompute → continuation):
//   1. ControlFlag mints the forward flag (inserted before the `icmp`).
//   2. Substitution emits the controlled gate body in the arm.
//   3. Dissolution RAUWs the merge `φ` to the in-place handle and erases it.
//   4. The uncompute (`_inv` of the compare template) is minted at the MERGE
//      block's front — i.e. after the arm body, before the continuation —
//      WHILE the `icmp` still stands (linearization erases it next).
//   5. Linearization collapses the diamond into the predecessor.
//
// `select` region (WP4) — same flag/substitution machinery (Substitution is a
// no-op since `Shadow` is empty), but there is NO CFG to linearize.
//
// Compound `&&`/`||` (WP5) — `region.Conj != ConjNone`. `ControlFlag` lowers
// the two sub-compares to flags and `FlagConjunction::combineFlags` ANDs/ORs
// them into the single `region.Flag` (one `cqrt_toffoli`, §1.2). The uncompute
// is the exact LIFO reverse: the conjunction uncompute (`cqrt_toffoli_inv` +
// OR's X-bracket) FIRST, then each sub-flag's compare-uncompute, then the
// sub-compares/select are erased. For a `select i1`-sourced `&&` the carrier is
// a flat 2-block diamond (`br i1 %and, …`); for the un-flattened NESTED shape
// `region.Mid` is set and linearization splices the inner guard block too.
//
// Regions are walked outer→inner (by `Depth`) and their flags pushed on a LIFO
// stack, the nesting seam (PRD §2.9). The realized 2-level nested fixture is a
// single conjunction region (CondA=outer, CondB=inner), so the LIFO is
// per-region; the `Depth`/`ParentFlag` fields stay for a depth-N generalization.

#include "ControlledLowering.h"

#include "CFGLinearization.h"
#include "CompareLowering.h"  // lowerCompareToFlag (uncompute)
#include "ControlFlag.h"
#include "ControlPlan.h"
#include "ControlledSubstitution.h"
#include "ControlledSymbols.h"
#include "FlagConjunction.h"  // uncombineFlags
#include "MergeDissolution.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>
#include <initializer_list>

using namespace llvm;

namespace cq {

namespace {

// Mint the flag uncompute for a region's condition, anchored at `At`, so it
// brackets the controlled body (§1.5). Must run while the condition compare(s)
// still stand.
//
//   * Plain compare (`Conj == ConjNone`): the `_inv` twin of the compare
//     template (the WP3 path).
//   * Compound `&&`/`||`/nesting (`Conj != ConjNone`): the LIFO reverse of the
//     compute — first the conjunction uncompute (`cqrt_toffoli_inv`, plus the
//     De Morgan X-bracket for OR), then EACH sub-flag's compare-uncompute
//     (innermost flag `CondB` first, mirroring the bracket). The sub-flag
//     uncomputes re-derive their flags off the still-standing sub-compares.
void emitUncompute(ControlRegion &region, WidthDispatch &wd,
                   ControlledSymbols &csyms, TaintSet &taint, Instruction *At) {
  if (!region.Flag || !At)
    return;

  if (region.Conj != ControlRegion::ConjNone) {
    auto *CmpA = dyn_cast_or_null<CmpInst>(region.CondA);
    auto *CmpB = dyn_cast_or_null<CmpInst>(region.CondB);
    if (!CmpA || !CmpB || !region.FlagA || !region.FlagB)
      return;
    // (1) Conjunction uncompute FIRST (toffoli_inv + OR X-bracket), the mirror
    //     image of combineFlags, reusing the SAME forward sub-flags
    //     (`region.FlagA`/`FlagB`, which dominate here) so no fresh forward
    //     compare is emitted (§2.9, risk R4).
    uncombineFlags(region.FlagA, region.FlagB, region.Flag, region.Conj, csyms,
                   At);
    // (2) Then each sub-flag's compare-uncompute, innermost (`CondB`) first,
    //     balancing the forward compares minted by `lowerControlFlag`.
    (void)lowerCompareToFlag(CmpB, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                             /*before=*/At);
    (void)lowerCompareToFlag(CmpA, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                             /*before=*/At);
    return;
  }

  auto *Cmp = dyn_cast_or_null<CmpInst>(region.Condition);
  if (!Cmp)
    return;
  // WP6: a Q+Q control condition uncomputes with the QQ `_inv` twin
  // `cq_template_icmp_<pred>_<W>_inv(h1, h2)` (no `_hl`), the mirror of the
  // forward QQ flag in `lowerControlFlag`. Recover the same width from the
  // side-table; the HL path keeps `qqWidth` empty → `_hl_inv(handle, classical)`.
  StringRef QqWidth;
  if (taint.Tainted.count(Cmp->getOperand(0)) &&
      taint.Tainted.count(Cmp->getOperand(1)))
    QqWidth = qqControlWidth(Cmp, taint);
  // inverse=true → the `_inv` twin. The result is the uncompute and is
  // intentionally unconsumed (a balanced ancilla, not a data value).
  (void)lowerCompareToFlag(Cmp, wd, taint, QqWidth, /*inverse=*/true,
                           /*before=*/At);
}

// Erase the listed instructions if dead, deduplicating so the same value is
// never freed twice (for nesting `region.Condition` IS `region.CondA`). Each is
// erased in list order; a select must precede the sub-compares it uses. The
// forward compute and `_inv` uncompute are separate template calls re-read off
// the operands, so once the `select`/`br` is gone the originals are unused.
void eraseDeadConds(std::initializer_list<Value *> Conds) {
  SmallVector<Instruction *, 3> Seen;
  for (Value *V : Conds) {
    auto *I = dyn_cast_or_null<Instruction>(V);
    if (!I || !I->use_empty())
      continue;
    if (llvm::is_contained(Seen, I))
      continue;  // already queued (Condition == CondA for nesting).
    Seen.push_back(I);
  }
  for (Instruction *I : Seen)
    if (I->use_empty())  // re-check: an earlier erase may have freed a user.
      I->eraseFromParent();
}

// Collapse the un-flattened NESTED diamond `Pred -[a]-> {Mid, Merge}`,
// `Mid -[b]-> {Arm, Merge}`, `Arm -> Merge` into the single block `Pred`,
// collection-before-mutation (§1.6). Splices the inner guard block `Mid`'s body
// (its opaque/non-control content) and the gate-body `Arm` through, then the
// merge. The merge `φ` MUST already be dissolved. Returns the splice boundary.
// (Kept local to the orchestrator — the flat-diamond `CFGLinearization` stays
// untouched; this is the WP5 nesting-only collapse, §2.7.)
Instruction *linearizeNested(ControlRegion &region) {
  BasicBlock *Pred = region.Pred;
  BasicBlock *Mid = region.Mid;
  BasicBlock *Arm = region.Arm;
  BasicBlock *Merge = region.MergeBB;
  if (!Pred || !Mid || !Arm || !Merge)
    return nullptr;

  auto *PredBr = dyn_cast<BranchInst>(Pred->getTerminator());
  auto *MidBr = dyn_cast<BranchInst>(Mid->getTerminator());
  auto *ArmBr = dyn_cast<BranchInst>(Arm->getTerminator());
  if (!PredBr || !PredBr->isConditional() || !MidBr || !MidBr->isConditional() ||
      !ArmBr || ArmBr->isConditional())
    return nullptr;

  Instruction *Boundary = &Merge->front();

  // Drop the outer conditional branch; refill `Pred` by splicing.
  PredBr->eraseFromParent();
  // Splice the inner guard `Mid`'s body (all but its `br i1`), then drop it.
  Pred->splice(Pred->end(), Mid, Mid->begin(), MidBr->getIterator());
  MidBr->eraseFromParent();
  // Splice the gate-body `Arm`'s body (all but its `br`), then drop it.
  Pred->splice(Pred->end(), Arm, Arm->begin(), ArmBr->getIterator());
  ArmBr->eraseFromParent();
  // Splice the merge block (body + terminator).
  Pred->splice(Pred->end(), Merge, Merge->begin(), Merge->end());

  // Erase the drained blocks. The dead condition compares are erased by
  // `eraseDeadConds` in the caller after this returns.
  Mid->eraseFromParent();
  Arm->eraseFromParent();
  Merge->eraseFromParent();
  return Boundary;
}

// Collapse a WP8 SYMMETRIC two-content-arm diamond `Pred -[br i1]-> {ArmT,
// ArmF}`, `ArmT -> Merge`, `ArmF -> Merge` into the single block `Pred`
// (collection-before-mutation, §1.6). Both arms hold controlled gate bodies (the
// false arm bracketed by `cqrt_x`), so both bodies splice through. The merge φ
// MUST already be dissolved. Returns the splice boundary. Erases the dead
// condition like `linearizeRegion` (the caller erases any conjunction
// sub-compares).
Instruction *linearizeSymmetric(ControlRegion &region) {
  BasicBlock *Pred = region.Pred;
  BasicBlock *ArmT = region.Arm;
  BasicBlock *ArmF = region.ArmFalse;
  BasicBlock *Merge = region.MergeBB;
  if (!Pred || !ArmT || !ArmF || !Merge)
    return nullptr;

  auto *PredBr = dyn_cast<BranchInst>(Pred->getTerminator());
  auto *ArmTBr = dyn_cast<BranchInst>(ArmT->getTerminator());
  auto *ArmFBr = dyn_cast<BranchInst>(ArmF->getTerminator());
  if (!PredBr || !PredBr->isConditional() || !ArmTBr || ArmTBr->isConditional() ||
      !ArmFBr || ArmFBr->isConditional())
    return nullptr;

  Instruction *Boundary = &Merge->front();

  // Drop the conditional branch; refill `Pred` by splicing both arm bodies then
  // the merge. No `br i32` is ever synthesized (§1.1).
  PredBr->eraseFromParent();
  Pred->splice(Pred->end(), ArmT, ArmT->begin(), ArmTBr->getIterator());
  ArmTBr->eraseFromParent();
  Pred->splice(Pred->end(), ArmF, ArmF->begin(), ArmFBr->getIterator());
  ArmFBr->eraseFromParent();
  Pred->splice(Pred->end(), Merge, Merge->begin(), Merge->end());

  ArmT->eraseFromParent();
  ArmF->eraseFromParent();
  Merge->eraseFromParent();
  if (auto *Cond = dyn_cast_or_null<Instruction>(region.Condition))
    if (Cond->use_empty())
      Cond->eraseFromParent();
  return Boundary;
}

// WP18 (PRD §8.5) — collapse a gated `SwitchRegion` into `Pred`: drop the switch
// terminator, splice each arm's (now controlled) gate body then the merge body
// into `Pred`. The merge φ MUST already be dissolved. Splice order is default
// then cases; the arms are mutually exclusive (controlled on disjoint eq-flags),
// so order is immaterial.
void linearizeSwitch(ControlRegion &region, SwitchInst *Sw) {
  BasicBlock *Pred = region.Pred;
  BasicBlock *Merge = region.MergeBB;
  if (!Pred || !Merge)
    return;
  SmallVector<BasicBlock *, 4> Arms;
  if (region.Arm)
    Arms.push_back(region.Arm);  // the default arm (null for a direct-to-merge
                                 // empty default — nothing to splice/erase).
  for (SwitchArm &A : region.SwitchArms)
    Arms.push_back(A.Block);

  Sw->eraseFromParent();  // drop the N-way terminator; `Pred` falls through.
  for (BasicBlock *Arm : Arms) {
    auto *Br = dyn_cast<BranchInst>(Arm->getTerminator());
    if (!Br)
      continue;
    Pred->splice(Pred->end(), Arm, Arm->begin(), Br->getIterator());
    Br->eraseFromParent();
  }
  Pred->splice(Pred->end(), Merge, Merge->begin(), Merge->end());
  for (BasicBlock *Arm : Arms)
    Arm->eraseFromParent();
  Merge->eraseFromParent();
}

// npu.6: recover a mux base handle's single-Ry prep angle from its already-
// lowered `cqrt_ry_<W>(handle, angle)` call. Rotation lowering ran before this
// (erasing the `cq_theta`), so the angle survives only on the `cqrt_ry`; the
// detection gate's G2 (classical untainted arg-0 ⇒ exactly one Ry on the
// handle) guarantees a unique match. The `_controlled_inv` twin we emit here is
// excluded by `getArgOperand(0) == Handle` (its arg-0 is the control flag).
static Value *recoverRyAngle(Value *Handle) {
  for (User *U : Handle->users()) {
    auto *CI = dyn_cast<CallInst>(U);
    if (!CI)
      continue;
    const Function *Callee = CI->getCalledFunction();
    if (Callee && Callee->getName().starts_with("cqrt_ry_") &&
        CI->arg_size() >= 2 && CI->getArgOperand(0) == Handle)
      return CI->getArgOperand(1);
  }
  return nullptr;
}

// WP18 (PRD §8.5) — lower a gated `SwitchRegion` to per-arm controlled gates.
// Mint an `icmp eq` flag per case; OR-fold them into the default's "none
// matched" control; control each case arm on its own flag and the default on
// ¬OR (a self-inverse `cqrt_x` bracket); dissolve the N-way φ to the in-place
// handle; uncompute reverse-LIFO; linearize the switch away. The arms are
// mutually exclusive (eq on one scrutinee), so exactly one fires per basis
// state — the switch semantics. Manages all per-arm flags itself, so the
// orchestrator routes here BEFORE the single-flag `lowerControlFlag`.
void lowerGatedSwitch(ControlRegion &region, WidthDispatch &wd,
                      ControlledSymbols &csyms, TaintSet &taint) {
  if (!region.Pred || region.SwitchArms.empty())
    return;
  auto *Sw = dyn_cast<SwitchInst>(region.Pred->getTerminator());
  if (!Sw)
    return;
  // Re-read the scrutinee LIVE: rotation lowering ran before this and RAUW'd
  // the `cq_theta` scrutinee to its i32 handle (and erased the theta), so the
  // detection-time `region.Condition` is stale — `Sw->getCondition()` is the
  // current handle.
  Value *Scrut = Sw->getCondition();

  // 1. A per-case forward `icmp_eq_<W>_hl(handle, v_k)` flag, minted DIRECTLY
  //    (no throwaway `icmp`: the handle is i32 but `v_k` carries the logical
  //    width, so a real `icmp eq i32 %h, <W>` would mismatch — `emitEqFlag`
  //    spells the template off the operands instead). Grouped per ARM: a shared
  //    arm (two+ case values folded onto one body, test_C_libtooling-6qg) gets
  //    one eq-flag per case value, OR-folded into the arm flag in step 2.
  //    `AllVals` records every case constant in compute order for the
  //    reverse-LIFO compare-uncompute (step 5).
  SmallVector<SmallVector<Value *, 2>, 4> ArmEq;
  SmallVector<ConstantInt *, 8> AllVals;
  for (SwitchArm &A : region.SwitchArms) {
    SmallVector<Value *, 2> Eqs;
    for (ConstantInt *V : A.Values) {
      Value *Flag = emitEqFlag(Scrut, V, wd, /*inverse=*/false, /*before=*/Sw);
      if (!Flag)
        return;  // unsupported width; leave the switch for the verifier.
      Eqs.push_back(Flag);
      AllVals.push_back(V);
    }
    ArmEq.push_back(std::move(Eqs));
  }

  // 2. Each arm's control flag is the OR of its case eq-flags — a single-case
  //    arm IS its one eq-flag (no fold). `OrSteps` records every OR-combination
  //    (per-arm folds here + the default fold in step 3) in compute order so
  //    step 5 uncomputes them mirror-image (reverse LIFO). For the common
  //    single-case-per-arm switch no per-arm fold is emitted, so `ArmFlags`
  //    equals the old per-case `Flags` and the trace is byte-identical.
  struct OrStep {
    Value *A, *B, *Out;
  };
  SmallVector<OrStep, 8> OrSteps;
  auto orFold = [&](ArrayRef<Value *> Fs) -> Value * {
    Value *Acc = Fs[0];
    for (unsigned i = 1; i < Fs.size(); ++i) {
      Value *Out =
          combineFlags(Acc, Fs[i], ControlRegion::ConjOr, csyms, wd, Sw);
      if (!Out)
        return nullptr;  // unsupported symbol (diagnosed); caller bails.
      OrSteps.push_back({Acc, Fs[i], Out});
      Acc = Out;
    }
    return Acc;
  };
  SmallVector<Value *, 4> ArmFlags;
  for (auto &Eqs : ArmEq) {
    Value *AF = orFold(Eqs);
    if (!AF)
      return;  // unsupported OR symbol; leave the switch for the verifier.
    ArmFlags.push_back(AF);
  }

  // 3. The default's "none matched" control is ¬(f_1 ∨ … ∨ f_n) over ALL the arm
  //    flags (= over every case eq-flag). Needed ONLY when the default arm has a
  //    gate body to control on ¬OR; an empty / direct-to-merge default
  //    (test_C_libtooling-509) has no default gate, so the "no case matched"
  //    outcome is just the absence of any case gate — skip the default fold.
  const bool HasDefaultGate = !region.Shadow.empty();
  Value *OrAll = nullptr;
  if (HasDefaultGate) {
    OrAll = orFold(ArmFlags);
    if (!OrAll)
      return;  // unsupported symbol (diagnosed); leave for the verifier.
  }

  // 4-pre. Control each case arm on its OR-of-cases flag; the default arm (when
  //    it has a gate body) on ¬OrAll (the self-inverse `cqrt_x` bracket — fires
  //    when NO case matched). A direct-to-merge / empty default has no gate.
  for (unsigned k = 0; k < region.SwitchArms.size(); ++k)
    substituteArm(region.SwitchArms[k].Shadow, ArmFlags[k], /*Negate=*/false,
                  region.SwitchArms[k].Block, wd, taint);
  if (HasDefaultGate)
    substituteArm(region.Shadow, OrAll, /*Negate=*/true, region.Arm, wd, taint);

  // 4. Dissolve the N-way merge φ(s). A UNIFORM-base handle φ (post-substitution
  //    every incoming is the same in-place handle) collapses by RAUW to that
  //    handle. A DISTINCT-per-case-handle MUX φ — certified safe by the G0–G7
  //    gate (`region.MuxExch`) — instead lowers MUX-EXCH: a fresh `regOut` and a
  //    per-distinct-base `cqrt_cswap(f_q, regOut, q)` controlled MOVE, then a
  //    `cqrt_ry_<W>_controlled_inv(¬f_q, q, angle)` uncompute of every
  //    NON-selected source (else it stays entangled with the scrutinee and
  //    decoheres regOut). The per-edge selecting flags PARTITION the scrutinee
  //    (exactly one arm fires), so the DEFAULT-selected base's control is the
  //    COMPLEMENT of the OR of the OTHER bases' case-flags — materialized with
  //    the same self-inverse `cqrt_x` bracket as the default arm, never an
  //    explicit `¬OrAll` value. Per-φ, so a uniform sibling φ still dissolves to
  //    its own base.
  //
  //    The mux inserts its `regOut`/`cqrt_cswap`/`cqrt_ry_inv` body at the merge
  //    boundary, which would otherwise become the new `getFirstNonPHI()` and pull
  //    step 5's flag uncompute (eq-flag + OR-fold inverses) AHEAD of the body
  //    that consumes those flags (a verify-clean miscompile). `MuxAnchor`
  //    captures the boundary BEFORE the body is inserted so step 5 uncomputes
  //    AFTER it — the same role `AngleAnchor` plays for reduceAngleSwitchPhi.
  Instruction *MuxAnchor = nullptr;
  for (PHINode &P : make_early_inc_range(region.MergeBB->phis())) {
    // Distinct tainted incoming handles.
    SmallVector<Value *, 4> Handles;
    for (unsigned i = 0, e = P.getNumIncomingValues(); i != e; ++i) {
      Value *In = P.getIncomingValue(i);
      if (taint.Tainted.count(In) && !is_contained(Handles, In))
        Handles.push_back(In);
    }
    if (Handles.empty())
      continue;  // no tainted incoming (malformed); leave for the verifier.

    if (!region.MuxExch || Handles.size() < 2) {
      // Uniform-base φ: RAUW to the in-place handle and erase (byte-identical to
      // the pre-MUX-EXCH behaviour for every non-mux region).
      P.replaceAllUsesWith(Handles.front());
      P.eraseFromParent();
      continue;
    }

    // --- MUX-EXCH (npu.5/.6) ---
    // Group incomings by base handle (accumulating each base's selecting case
    // flags) and identify the default-selected base. The detection gate
    // guarantees the structure; on any unexpected mismatch leave the φ for the
    // verifier (a LOUD broken-module failure, never a silent miscompile).
    SmallVector<std::pair<Value *, SmallVector<Value *, 2>>, 4> CaseFlagsByBase;
    Value *DefaultBase = nullptr;
    bool Ok = true;
    for (unsigned i = 0, e = P.getNumIncomingValues(); i != e; ++i) {
      BasicBlock *IB = P.getIncomingBlock(i);
      Value *H = P.getIncomingValue(i);
      if (IB == region.Arm) {  // the default arm's edge
        DefaultBase = H;
        continue;
      }
      int K = -1;
      for (unsigned a = 0, ae = region.SwitchArms.size(); a < ae; ++a)
        if (region.SwitchArms[a].Block == IB) {
          K = (int)a;
          break;
        }
      if (K < 0) {
        Ok = false;
        break;
      }
      bool Found = false;
      for (auto &Pr : CaseFlagsByBase)
        if (Pr.first == H) {
          Pr.second.push_back(ArmFlags[K]);
          Found = true;
          break;
        }
      if (!Found)
        CaseFlagsByBase.emplace_back(H, SmallVector<Value *, 2>{ArmFlags[K]});
    }
    if (!Ok || !DefaultBase)
      continue;  // structure off (gate should preclude); leave for the verifier.

    // Recover every base's single-Ry prep angle BEFORE mutating use-lists (gate
    // G2 guarantees a unique `cqrt_ry` per base).
    Value *DefaultAngle = recoverRyAngle(DefaultBase);
    SmallVector<Value *, 4> NonDefBases, NonDefAngles;
    for (auto &Pr : CaseFlagsByBase) {
      if (Pr.first == DefaultBase)
        continue;  // the default base's own cases are absorbed by the complement
      Value *Ang = recoverRyAngle(Pr.first);
      if (!Ang) {
        Ok = false;
        break;
      }
      NonDefBases.push_back(Pr.first);
      NonDefAngles.push_back(Ang);
    }
    if (!Ok || !DefaultAngle || NonDefBases.empty())
      continue;

    StringRef W = taint.HandleWidth.lookup(DefaultBase);
    Type *WTy = wd.llvmWidthType(W);
    FunctionCallee Alloc = wd.allocFn(W);
    FunctionCallee Cswap = csyms.cswapFn();
    FunctionCallee X = csyms.xFn();
    FunctionCallee RyInv = csyms.controlledRyInvFn(W);
    Instruction *Boundary = region.MergeBB->getFirstNonPHI();
    if (!WTy || !Alloc || !Cswap || !X || !RyInv || !Boundary)
      continue;  // unsupported width/symbol; leave the φ for the verifier.
    // Pin step-5's uncompute AFTER the mux body inserted before `Boundary`.
    MuxAnchor = Boundary;

    // Per-non-default-base CaseOr(q) (single case ⇒ that flag; shared ⇒ an
    // OR-fold recorded in `OrSteps` for the reverse-LIFO uncompute in step 5).
    SmallVector<Value *, 4> NonDefFlags;
    for (auto &Pr : CaseFlagsByBase) {
      if (Pr.first == DefaultBase)
        continue;
      Value *F = orFold(Pr.second);
      if (!F) {
        Ok = false;
        break;
      }
      NonDefFlags.push_back(F);
    }
    // OtherCaseOr = OR of every non-default base's flag; the default base fires
    // on its complement (≡ its own cases ∨ no-case-matched).
    Value *OtherCaseOr = Ok ? orFold(NonDefFlags) : nullptr;
    if (!Ok || !OtherCaseOr)
      continue;

    IRBuilder<> B(Boundary);
    Value *RegOut =
        B.CreateCall(Alloc, {Constant::getNullValue(WTy)}, "regout");
    // regOut is the muxed quantum register the φ RAUWs to — register it as a
    // tainted handle of the mux width so downstream rotation/measure lowering
    // recognizes it (mirror of RotationLowering's minted-handle bookkeeping).
    taint.Tainted.insert(RegOut);
    taint.HandleWidth[RegOut] = W;
    taint.BirthOrder[RegOut] = taint.NextBirth++;
    // MOVE each selected source into regOut: non-default bases on their positive
    // CaseOr flag; the default base on ¬OtherCaseOr (cqrt_x self-inverse bracket).
    for (unsigned j = 0; j < NonDefBases.size(); ++j)
      B.CreateCall(Cswap, {NonDefFlags[j], RegOut, NonDefBases[j]});
    B.CreateCall(X, {OtherCaseOr});
    B.CreateCall(Cswap, {OtherCaseOr, RegOut, DefaultBase});
    B.CreateCall(X, {OtherCaseOr});
    // UNCOMPUTE every non-selected source's prep: non-default base q on ¬CaseOr(q)
    // (bracket); the default base on OtherCaseOr (positive — it IS ¬f_default).
    for (unsigned j = 0; j < NonDefBases.size(); ++j) {
      B.CreateCall(X, {NonDefFlags[j]});
      B.CreateCall(RyInv, {NonDefFlags[j], NonDefBases[j], NonDefAngles[j]});
      B.CreateCall(X, {NonDefFlags[j]});
    }
    B.CreateCall(RyInv, {OtherCaseOr, DefaultBase, DefaultAngle});

    P.replaceAllUsesWith(RegOut);
    P.eraseFromParent();
  }

  // 4.5 cwk fix (b) PR3: a classical-angle merge φ (a rotation angle dispatched
  //     per case) is lowered as base + per-case controlled-difference, reusing
  //     the per-arm flags minted above (a shared arm's difference fires on the
  //     OR of its cases). Returns the anchor (after the last rotation) so the
  //     flag uncompute lands AFTER the controlled-differences, not on the erased
  //     consumer. Runs after the handle-φ dissolution (so a consumer's arg-0 is
  //     the live handle).
  Instruction *AngleAnchor =
      region.AnglePhi.empty() ? nullptr
                              : reduceAngleSwitchPhi(region, ArmFlags, wd, taint);

  // 5. Uncompute, reverse LIFO, at the merge boundary (compute → controlled
  //    body → uncompute → continuation, §1.5): the OR-folds first (mirror of
  //    `combineFlags`, in reverse compute order — the default fold, then the
  //    per-arm folds), then each per-case compare-uncompute (reverse of the
  //    mint order). Anchor AFTER the angle rotations when an angle φ was lowered
  //    (4.5), AFTER the MUX-EXCH body when a mux φ was lowered (so the flags it
  //    consumes are still live), else at the boundary.
  Instruction *UncomputeAt = AngleAnchor      ? AngleAnchor
                             : MuxAnchor       ? MuxAnchor
                                               : region.MergeBB->getFirstNonPHI();
  if (UncomputeAt) {
    for (int i = (int)OrSteps.size() - 1; i >= 0; --i)
      uncombineFlags(OrSteps[i].A, OrSteps[i].B, OrSteps[i].Out,
                     ControlRegion::ConjOr, csyms, UncomputeAt);
    for (int i = (int)AllVals.size() - 1; i >= 0; --i)
      (void)emitEqFlag(Scrut, AllVals[i], wd, /*inverse=*/true,
                       /*before=*/UncomputeAt);
  }

  // 6. Linearize the switch away.
  linearizeSwitch(region, Sw);
}

}  // namespace

void lowerControlledRegions(Module &M, WidthDispatch &wd, TaintSet &taint,
                            ControlPlan &plan) {
  if (plan.Regions.empty())
    return;

  // Minter for the controlled surface (the `add_<W>_hl_controlled` the
  // classical-arm select reduction needs; `cqrt_toffoli`/`cqrt_x`/
  // `cqrt_alloc_i1` for flag conjunction). Bound to the module + shared width
  // resolver; idempotent/lazy.
  ControlledSymbols csyms(M, wd);

  // Outer→inner: stable sort by Depth ascending so an enclosing region is
  // bracketed before its nested ones (PRD §2.9). The realized fixtures are flat
  // (Depth 0) — nesting is folded into a single conjunction region.
  SmallVector<ControlRegion *, 4> Order;
  for (ControlRegion &R : plan.Regions)
    Order.push_back(&R);
  std::stable_sort(Order.begin(), Order.end(),
                   [](const ControlRegion *A, const ControlRegion *B) {
                     return A->Depth < B->Depth;
                   });

  // LIFO flag stack — the nesting seam (PRD §2.9). The per-region bracket
  // (compute in ControlFlag, uncompute after the controlled body) is the
  // depth-1 specialization of the LIFO discipline; for a conjunction region the
  // uncompute itself is the LIFO reverse of the multi-step compute.
  SmallVector<Value *, 4> FlagStack;

  for (ControlRegion *RP : Order) {
    ControlRegion &R = *RP;

    // WP18: a gated `SwitchRegion` manages its own per-arm eq-flags + the ¬OR
    // default flag — route to the dedicated lowering BEFORE the single-flag
    // `lowerControlFlag` (which the switch does not use).
    if (R.Kind == ControlRegion::SwitchRegion) {
      lowerGatedSwitch(R, wd, csyms, taint);
      continue;
    }

    // WP16: an angle-select CHAIN (the head select's false arm is itself a
    // select) uses a per-case flag bracket, not the single `region.Flag` model
    // — route it to the dedicated reducer BEFORE the generic flag mint (which
    // it would otherwise leave dangling as an unbalanced compute). Detection
    // already validated mutual exclusivity. A single angle select (false arm =
    // base angle) falls through to the WP10 path below.
    if (R.Kind == ControlRegion::AngleSelectRegion)
      if (auto *Head = dyn_cast_or_null<SelectInst>(R.Merge))
        if (isa<SelectInst>(Head->getFalseValue())) {
          reduceAngleSelectChain(R, wd, taint);
          continue;
        }

    // 1. Control-wire (flag compute). For a compound/nested region this lowers
    //    both sub-compares and combines them into the single flag. On failure
    //    the compare/symbol was diagnosed; leave the region untouched
    //    (verify-clean).
    if (!lowerControlFlag(R, wd, csyms, taint))
      continue;
    FlagStack.push_back(R.Flag);

    if (R.Kind == ControlRegion::AngleSelectRegion) {
      // WP10 (Family B2): lower the angle select as controlled-rotation-by-
      // difference. The flag is already minted (step 1); `reduceAngleSelect`
      // emits base + controlled-diff per consumer and returns the uncompute
      // anchor (after the last rotation). No CFG to linearize.
      Instruction *UncomputeAt = reduceAngleSelect(R, wd, taint);
      emitUncompute(R, wd, csyms, taint, UncomputeAt);
      FlagStack.pop_back();
      eraseDeadConds({R.Condition});
      continue;
    }

    if (R.Kind == ControlRegion::SelectRegion) {
      // WP4 classical-arm `select`: no CFG, no in-shadow body. Capture the
      // uncompute anchor (the node after the select — it survives dissolution,
      // which inserts the controlled add BEFORE the select then erases it).
      auto *Sel = dyn_cast_or_null<SelectInst>(R.Merge);
      Instruction *UncomputeAt = Sel ? Sel->getNextNode() : nullptr;

      dissolveMerge(R, wd, csyms, taint);
      emitUncompute(R, wd, csyms, taint, UncomputeAt);
      FlagStack.pop_back();
      // No linearization (a select has no CFG). Erase the now-dead condition
      // (a select region is always a plain compare — no sub-conditions).
      eraseDeadConds({R.Condition});
      continue;
    }

    // --- BranchRegion (WP3 `br`-diamond, WP5 `&&`/`||` + nested) ---
    // 2. Controlled substitution of the in-shadow gate bodies (single-controlled
    //    by the one combined flag).
    substituteControlled(R, wd, taint);

    // 3. Dissolve the merge φ(s) to the in-place handle (must precede block
    //    erasure so no use dangles, §1.6). Capture the uncompute boundary FIRST
    //    — the merge's first non-φ instruction, stable across φ erasure. WP7's
    //    multi-φ dissolution may emit a classical-mux reduction here; anchoring
    //    the uncompute at this point (not the post-dissolution `front()`, which
    //    a reduction would have shifted) keeps compute → uncompute order.
    Instruction *UncomputeAt =
        R.MergeBB ? R.MergeBB->getFirstNonPHI() : nullptr;
    dissolveMerge(R, wd, csyms, taint);

    // cwk fix (b): a classical-angle merge φ (the diamond-form rotation-angle
    // dispatch) is lowered as base + controlled-difference AFTER the gate-handle
    // φ dissolution above (so a consumer's arg-0 is the live handle). It emits
    // rotations in the merge block and erases the consuming `cq_phi` that
    // `getFirstNonPHI()` named — OVERRIDE `UncomputeAt` with the anchor it
    // returns (the surviving node after the last rotation) so the flag uncompute
    // lands AFTER the controlled-difference, not on the erased consumer (§1.5).
    if (!R.AnglePhi.empty())
      if (Instruction *AngleAnchor = reduceAngleDiamondPhi(R, wd, taint))
        UncomputeAt = AngleAnchor;

    // 4. Flag uncompute, minted while the condition compare(s) still stand and
    //    anchored at the merge boundary so it brackets the controlled body
    //    (§1.5). For a conjunction this is the LIFO reverse of the compute.
    emitUncompute(R, wd, csyms, taint, UncomputeAt);
    FlagStack.pop_back();

    // 5. Collapse the diamond to a single straight-line block; the nested shape
    //    (Mid set) splices the inner guard block too. No `br i32` is created
    //    (§1.1). Condition cleanup differs by path to avoid a double-free:
    //      * Nested: `linearizeNested` erases NO condition, so erase the outer
    //        compare (`Condition` == `CondA`) and the inner compare (`CondB`).
    //      * Flat: `linearizeRegion` already erased `region.Condition` (the
    //        plain compare, or the `&&`/`||` select) — so only the conjunction
    //        sub-compares `CondA`/`CondB` remain to erase (they are distinct
    //        from a select condition).
    if (R.Mid) {
      linearizeNested(R);
      eraseDeadConds({R.Condition, R.CondB, R.CondA});
    } else if (R.ArmFalse) {
      linearizeSymmetric(R);  // erases R.Condition when dead.
      if (R.Conj != ControlRegion::ConjNone)
        eraseDeadConds({R.CondB, R.CondA});
    } else {
      linearizeRegion(R);  // erases R.Condition when dead.
      if (R.Conj != ControlRegion::ConjNone)
        eraseDeadConds({R.CondB, R.CondA});
    }
  }
}

}  // namespace cq
