// MergeDissolution.cpp — see header. Dissolves a region's merge node, keyed on
// the merge instruction kind (PRD §2.6, IMPLEMENTATION §5.5).
//
// `[modified, original]` `br` case (`region.Merge` is a `PHINode`): the merge
// `φ[rotated_y, y]` has one incoming value per predecessor — the MODIFIED arm
// from `region.Arm`, the ORIGINAL (in-place) handle from `region.Pred` (the
// diamond predecessor's fall-through edge). The in-place handle is the original
// arm's value — RAUW the whole merge to it and erase. Classifying by predecessor
// edge (rather than by raw arm taint) is robust to the substitution RAUW having
// already rewritten the modified arm's value to the same handle (risk R2): the
// `region.Pred` edge is definitionally the unmodified path.
//
// `select` case (`region.Merge` is a `SelectInst`): `select i1 %c, A, B` means
// `%c ? A : B`. With the control flag = lowered condition the reduction is one
// of THREE, dispatched on arm taint:
//
//   [classical, classical] (WP4): result `B + flag·(A−B)`. Emit a HOST
//   `%d = sub A, B` (plain LLVM, stays classical — both operands classical, so
//   the `sub` is never tainted/lowered; constants fold, runtime args stay a
//   real `sub`), then `cqrt_alloc_<W>(B)` to seed a handle at the false arm,
//   then `cq_template_add_<W>_hl_controlled(flag, regB, %d)`.
//
//   MIXED — exactly ONE tainted arm (mux.1): one arm is a tainted handle Q,
//   the other a classical C, so the host `sub` would not stay classical. Build
//   the difference with the UNCONTROLLED data template `%d = sub_<W>_hl(Q, C)`
//   (handle−classical → handle) instead, seed `cqrt_alloc_<W>(C)` from the
//   CLASSICAL arm, and use the Shape::QQ controlled add
//   `cq_template_add_<W>_controlled(ctrl, regC, %d)` (both addends are
//   handles). `ctrl` is the flag when Q is the TRUE arm; when Q is the FALSE
//   arm the add is wrapped in a self-inverse `cqrt_x` flag bracket so it fires
//   on ¬flag (`f ? C : Q`). Result = `C + ctrl·(Q−C)` = `ctrl ? Q : C`.
//
//   BOTH arms tainted (mux.2): neither arm is classical, so neither the host
//   `sub` (mixed/classical paths) nor the `cqrt_alloc(C)`-from-classical seed
//   apply, and a consuming/in-place strategy is unsafe — an arm may be live
//   elsewhere. Build an additive copy into a FRESH ancilla:
//   `regOut = cqrt_alloc_<W>(0)`, `cq_template_add_<W>_controlled(f, regOut,
//   A)` (regOut += f·A), then a self-inverse `cqrt_x` flag bracket around
//   `cq_template_add_<W>_controlled(f, regOut, B)` (regOut += ¬f·B). Result =
//   `f·A + ¬f·B = f ? A : B`. A and B are READ as the add's b_handle operand,
//   never consumed, so both source handles stay live for their other uses.
//
// Either way: RAUW the select to the controlled-add result, erase it, and
// register the result as a fresh tainted i32 handle. The source arm handles
// are never erased — only the select node is.

#include "MergeDissolution.h"

#include "CompareLowering.h"  // lowerCompareToFlag (WP16 per-case flags)
#include "ControlPlan.h"
#include "ControlledSymbols.h"
#include "OpcodeSupport.h"  // abiWidthFromType
#include "RotationLowering.h"  // emitRz (WP10 base + controlled-difference)
#include "TaintPropagation.h"
#include "TemplateName.h"  // cq::Shape
#include "WidthDispatch.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"  // make_early_inc_range
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"  // phis(), getFirstNonPHI
#include "llvm/IR/Constants.h"   // ConstantInt
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <utility>

using namespace llvm;

namespace cq {

namespace {

// §5.5 host-difference reduction for a `[classical, classical]` mux under
// quantum control: `result = B + flag·(A−B)`. Emit a HOST `%d = A − B` (plain
// LLVM — both operands classical, so the `sub` never taints/lowers; constants
// fold), `cqrt_alloc_<W>(B)` to seed a handle at the false/in-place arm, then
// `cq_template_add_<W>_hl_controlled(flag, regB, %d)`. Inserts before
// `InsertPt`. Returns the controlled-add result (a fresh i32 handle) — the
// CALLER registers it as tainted — or null on an unsupported width. Shared by
// the WP4 `select` [classical,classical] arm-shape and the WP7 classical-data
// merge `φ` that rode along under a gate.
CallInst *reduceClassicalMux(Value *A, Value *B, Value *Flag,
                             Instruction *InsertPt, WidthDispatch &wd,
                             ControlledSymbols &csyms, DebugLoc DL) {
  StringRef AbiWidth = abiWidthFromType(A->getType());
  if (AbiWidth.empty())
    return nullptr;  // unsupported value width.
  FunctionCallee Alloc = wd.allocFn(AbiWidth);
  FunctionCallee Add = csyms.controlledDataTemplateFn("add", AbiWidth, Shape::HL,
                                                      /*inverse=*/false);
  if (!Alloc || !Add)
    return nullptr;  // unsupported width.

  IRBuilder<> Builder(InsertPt);
  // (1) Host difference `%d = A − B` (folds for constants; a real `sub` for
  //     runtime args — classical either way).
  Value *Delta = Builder.CreateSub(A, B, "d");
  // (2) Seed a handle initialized to the false/in-place arm B.
  CallInst *RegB = Builder.CreateCall(Alloc, {B}, "h");
  // (3) Controlled add of the classical delta onto regB, gated by the flag.
  CallInst *Res = Builder.CreateCall(Add, {Flag, RegB, Delta}, "h_sel");
  if (DL) {
    RegB->setDebugLoc(DL);
    Res->setDebugLoc(DL);
  }
  return Res;
}

// The surviving node after the LAST consumer in PROGRAM (block) order — the
// flag-uncompute anchor for the angle reducers (WP10 select / cwk-fix-(b)
// diamond). The consumer lists are collected in `users()` order (LLVM use-list =
// reverse-of-creation), NOT program order, so anchoring off the last-ITERATED
// consumer's successor can land the uncompute MID-bracket — the controlled
// rotations of the program-later consumers would then fire on an already
// uncomputed flag (a verify-clean SILENT miscompile). Walk the block and take
// the successor of the block-latest consumer instead. Call BEFORE erasing the
// consumers (so the returned node is valid and not itself a consumer — the
// block-last consumer's successor is by definition not a consumer). All
// consumers share one block (the merge); empty list ⇒ null.
Instruction *anchorAfterLastConsumer(const SmallVectorImpl<Instruction *> &Cons) {
  if (Cons.empty())
    return nullptr;
  BasicBlock *BB = Cons.front()->getParent();
  Instruction *Last = nullptr;
  for (Instruction &I : *BB)
    if (llvm::is_contained(Cons, &I))
      Last = &I;
  return Last ? Last->getNextNode() : nullptr;
}

// WP7 `br`-diamond merge dissolution — dissolve EVERY φ in the merge block, not
// just `region.Merge`. A single-arm diamond may carry ≥2 φ: multiple gated
// handles (`if(q){u=g(u); v=g(v);}`), or a classical data assignment riding
// alongside a gate (`if(q){y=5; u=g(u);}`). Leaving any φ behind makes CFG
// linearization splice it mid-block → `PHI nodes not grouped` (or, by φ order, a
// verify-clean WRONG module). Each φ is classified by its arm taint and
// dissolved by its own class (risk R8 — per-φ, not once per region):
//   * gate-handle φ ([mod, orig]; substitution already rewrote `mod` to the
//     in-place handle): RAUW to the unmodified `region.Pred`-edge handle, erase.
//   * classical-data φ ([classical, classical]): a classical mux under the
//     quantum guard — reduce via §5.5 (`reduceClassicalMux`).
void dissolveBranchPhi(ControlRegion &region, WidthDispatch &wd,
                       ControlledSymbols &csyms, TaintSet &taint) {
  BasicBlock *MergeBB = region.MergeBB;
  // The "in-place" merge edge. For a one-content-arm diamond it is `region.Pred`
  // (the unmodified fall-through). For a WP8 symmetric two-content-arm diamond
  // `Pred` is NOT a merge predecessor (both arms are) — key on the TRUE arm
  // edge instead; post-substitution both arm edges carry the same in-place
  // handle, so either works and the true-arm edge is canonical.
  BasicBlock *InPlaceEdge = region.ArmFalse ? region.Arm : region.Pred;
  if (!MergeBB || !InPlaceEdge)
    return;

  // Stable insertion anchor for any classical-data reduction: the merge's first
  // non-φ instruction (it survives φ erasure). The orchestrator anchors the
  // flag uncompute at this same point (captured pre-dissolution), so a
  // reduction emitted here stays BEFORE the uncompute (compute → uncompute).
  Instruction *InsertPt = MergeBB->getFirstNonPHI();

  for (PHINode &P : make_early_inc_range(MergeBB->phis())) {
    // A classical-angle `φ` (cwk fix (b)) is OWNED by `reduceAngleDiamondPhi`
    // (base + controlled-difference rotations) — never the integer-handle
    // `reduceClassicalMux` path, which would mislower the `phi double`. Skip it
    // here; the orchestrator runs the angle reducer after this dissolution.
    if (llvm::is_contained(region.AnglePhi, &P))
      continue;
    int PredIdx = P.getBasicBlockIndex(InPlaceEdge);
    if (PredIdx < 0)
      continue;  // not wired through this diamond's Pred edge; leave it.
    Value *InPlace = P.getIncomingValue(PredIdx);

    // The "modified" arm-edge incoming (a diamond merge has the Pred and Arm
    // edges; take the first non-Pred incoming).
    Value *Modified = nullptr;
    for (unsigned k = 0, e = P.getNumIncomingValues(); k != e; ++k)
      if (static_cast<int>(k) != PredIdx) {
        Modified = P.getIncomingValue(k);
        break;
      }

    // Gate-handle φ: either incoming is tainted (post-substitution both are the
    // same in-place handle). RAUW to the in-place HANDLE — the TAINTED incoming.
    // Normally that is the unmodified Pred edge, but `clang` can value-propagate
    // the Pred edge to a CONSTANT when the branch condition pins it (e.g.
    // `if (u != 5)` canonicalizes to `icmp eq`, so the merge's straight-through
    // edge is the known literal `5`, not the handle). In that case the handle
    // rides the modified arm edge; RAUWing to the Pred constant would drop the
    // handle and emit e.g. `cq_measure(5)`. Prefer whichever incoming is tainted.
    const bool InTainted = taint.Tainted.count(InPlace) != 0;
    const bool ModTainted = Modified && taint.Tainted.count(Modified) != 0;
    if (InTainted || ModTainted) {
      Value *Handle = InTainted ? InPlace : Modified;
      P.replaceAllUsesWith(Handle);
      P.eraseFromParent();
      continue;
    }

    // Classical-data φ: A = arm/modified value, B = Pred/in-place value.
    if (!Modified || !region.Flag)
      continue;  // malformed; leave it well-typed for the verifier.
    CallInst *Res = reduceClassicalMux(Modified, InPlace, region.Flag, InsertPt,
                                       wd, csyms, P.getDebugLoc());
    if (!Res)
      continue;  // unsupported width; leave the φ for the verifier.
    P.replaceAllUsesWith(Res);
    P.eraseFromParent();
    taint.Tainted.insert(Res);
    taint.BirthOrder[Res] = taint.NextBirth++;
  }

  region.Merge = nullptr;  // dissolved; linearization must not touch it again.
}

// `select` reduction (PRD §2.6). Three arm shapes, dispatched on arm taint:
//   * [classical, classical] (WP4): `y = B + flag·(A−B)` — host `sub A−B` →
//     `cqrt_alloc_<W>(B)` → `cq_template_add_<W>_hl_controlled(flag, regB, %d)`.
//   * MIXED, exactly one tainted arm (mux.1): one arm is a tainted handle Q,
//     the other a classical C. Result = `C + ctrl·(Q−C)` = `ctrl ? Q : C`,
//     built from the UNCONTROLLED `sub_<W>_hl(Qhandle, Cclassical)` delta, a
//     register `cqrt_alloc_<W>(C)` seeded from the classical arm, and the
//     Shape::QQ `cq_template_add_<W>_controlled(ctrl, regC, delta)`. `ctrl` is
//     the flag when Q is the TRUE arm (`select %f, Q, C` = f?Q:C); when Q is
//     the FALSE arm (`select %f, C, Q` = f?C:Q) we need ¬f, emitted as an
//     `cqrt_x` bracket around the controlled add (X is its own inverse, so the
//     pair restores the flag for its own compare-uncompute — no extra bracket
//     bookkeeping in `emitUncompute`).
//   * BOTH tainted (mux.2): both arms are tainted i32 handles A (true) / B
//     (false). No classical operand, so the difference/seed strategies above
//     do not apply — and an arm may be live elsewhere, so it must NOT be
//     consumed. Build `regOut = cqrt_alloc_<W>(0)` (a fresh ancilla), then
//     `add_<W>_controlled(flag, regOut, A)` (regOut += flag·A) and, inside a
//     self-inverse `cqrt_x` flag bracket, `add_<W>_controlled(flag, regOut, B)`
//     (regOut += ¬flag·B). Result = `flag·A + ¬flag·B = flag ? A : B`. A and B
//     are only READ (the add's b_handle), never erased — they stay live.
void dissolveSelect(ControlRegion &region, WidthDispatch &wd,
                    ControlledSymbols &csyms, TaintSet &taint) {
  auto *Sel = dyn_cast_or_null<SelectInst>(region.Merge);
  if (!Sel || !region.Flag)
    return;  // no flag (ControlFlag failed) → leave the select for the verifier.

  Value *A = Sel->getTrueValue();   // flag=1 arm.
  Value *B = Sel->getFalseValue();  // flag=0 arm.

  // Arm-taint discriminator. Detection builds a SelectRegion for every non-i1
  // tainted-condition select; here we split on arm taint into the three
  // reductions (neither / exactly one / both).
  const bool TrueTainted = taint.Tainted.count(A) != 0;
  const bool FalseTainted = taint.Tainted.count(B) != 0;

  // WP11 (Family F): the LOGICAL handle width. A tainted arm that is a DIRECT
  // `cq_theta` result has been laundered to an i32 handle (handles are always
  // i32, PRD §"Width unification"), so its LLVM type (i32) is NOT the logical
  // width — read the §2.4 `HandleWidth` side-table recorded at the rotation
  // mint. Fall back to the arm's LLVM type only for a tainted arm that is still
  // a pre-lowering stock op (its real width survives) or a genuinely classical
  // arm. Both arms share the logical width in a well-formed mux, so a tainted
  // arm's recorded width is authoritative. Without this, an i64 both-tainted
  // mux of direct theta handles reads i32 off the laundered type and emits
  // `cqrt_alloc_i32` + `add_i32_controlled` for i64 data — a silent
  // width-collapse miscompile (Phase 4.2 i32 muxes are unaffected: their arms
  // are i32 arithmetic ops, not laundered handles, so the fallback returns i32).
  StringRef AbiWidth;
  if (TrueTainted)
    AbiWidth = taint.HandleWidth.lookup(A);
  if (AbiWidth.empty() && FalseTainted)
    AbiWidth = taint.HandleWidth.lookup(B);
  if (AbiWidth.empty())
    AbiWidth = abiWidthFromType(A->getType());
  if (AbiWidth.empty())
    return;  // missing/unsupported width (risk R3); leave it for the verifier.

  FunctionCallee Alloc = wd.allocFn(AbiWidth);
  if (!Alloc)
    return;  // unsupported width — leave the select standing (verify-clean).

  CallInst *Res = nullptr;
  IRBuilder<> Builder(Sel);

  if (!TrueTainted && !FalseTainted) {
    // ── [classical, classical] (WP4) — the §5.5 host-difference reduction,
    // shared with WP7's classical-data merge φ via `reduceClassicalMux`. ──
    Res = reduceClassicalMux(A, B, region.Flag, /*InsertPt=*/Sel, wd, csyms,
                             Sel->getDebugLoc());
    if (!Res)
      return;  // unsupported width — leave the select standing (verify-clean).
  } else if (TrueTainted != FalseTainted) {
    // ── MIXED, exactly one tainted arm (mux.1) ──
    // Q is the tainted handle, C the classical arm; `QisTrue` ⇒ ctrl = flag,
    // else ctrl = ¬flag (the `cqrt_x` bracket below).
    const bool QisTrue = TrueTainted;
    Value *Q = QisTrue ? A : B;
    Value *C = QisTrue ? B : A;

    // delta = Q − C via the UNCONTROLLED `sub_<W>_hl` template (handle, classical)
    // → i32 handle. `Q` may still be its pre-lowering stock op (data-position
    // ops lower AFTER controlled regions); it is i32-typed and tainted, so the
    // later `lowerOps` RAUW propagates its handle into this call's operand.
    FunctionCallee SubHL = wd.dataTemplateFn("sub", AbiWidth, Shape::HL);
    FunctionCallee AddQQ =
        csyms.controlledDataTemplateFn("add", AbiWidth, Shape::QQ,
                                       /*inverse=*/false);
    if (!SubHL || !AddQQ)
      return;  // unsupported width — leave the select standing (verify-clean).

    Value *Delta = Builder.CreateCall(SubHL, {Q, C}, "d_mux");
    // Seed a handle initialized to the classical arm C.
    CallInst *RegC = Builder.CreateCall(Alloc, {C}, "h");

    // ¬flag bracket when Q is the FALSE arm: X(flag); add; X(flag). The pair is
    // self-inverse, so the flag is restored for the standard compare-uncompute.
    FunctionCallee X;
    if (!QisTrue) {
      X = csyms.xFn();
      if (!X)
        return;  // unsupported — leave the select standing (verify-clean).
      Builder.CreateCall(X, {region.Flag});
    }
    Res = Builder.CreateCall(AddQQ, {region.Flag, RegC, Delta}, "h_sel");
    if (!QisTrue)
      Builder.CreateCall(X, {region.Flag});

    if (DebugLoc DL = Sel->getDebugLoc()) {
      if (auto *DCall = dyn_cast<Instruction>(Delta))
        DCall->setDebugLoc(DL);
      RegC->setDebugLoc(DL);
      Res->setDebugLoc(DL);
    }
  } else {
    // ── BOTH arms tainted (mux.2) ──
    // A and B are tainted i32 handles (hp / hq). No classical operand, so the
    // mixed/classical seed strategies do not apply, and an arm may be live
    // elsewhere (so consuming one is unsafe). Copy additively into a FRESH
    // ancilla: regOut = alloc(0); regOut += flag·A; regOut += ¬flag·B (¬flag
    // via a self-inverse `cqrt_x` flag bracket). Result = flag ? A : B. Both A
    // and B are only READ as the QQ add's b_handle — never erased or consumed.
    FunctionCallee AddQQ =
        csyms.controlledDataTemplateFn("add", AbiWidth, Shape::QQ,
                                       /*inverse=*/false);
    FunctionCallee X = csyms.xFn();  // void cqrt_x(i32); self-inverse.
    if (!AddQQ || !X)
      return;  // unsupported width — leave the select standing (verify-clean).

    // Fresh ancilla seeded to 0. The alloc's init value carries the LOGICAL
    // width (i64 for an i64 mux), NOT the laundered arm type (i32) — take the
    // zero's type straight from `allocFn`'s parameter so it matches (WP11).
    Type *InitTy = Alloc.getFunctionType()->getParamType(0);
    Value *Zero = ConstantInt::get(InitTy, 0);
    CallInst *RegOut = Builder.CreateCall(Alloc, {Zero}, "h");

    // regOut += flag·A.
    CallInst *Acc1 = Builder.CreateCall(AddQQ, {region.Flag, RegOut, A}, "h_sel");
    // ¬flag bracket: X(flag); regOut += flag·B (now ¬flag·B); X(flag). The pair
    // is self-inverse, so the flag is restored for the standard compare-uncompute.
    Builder.CreateCall(X, {region.Flag});
    CallInst *Acc2 = Builder.CreateCall(AddQQ, {region.Flag, Acc1, B}, "h_sel");
    Builder.CreateCall(X, {region.Flag});
    Res = Acc2;

    if (DebugLoc DL = Sel->getDebugLoc()) {
      RegOut->setDebugLoc(DL);
      Acc1->setDebugLoc(DL);
      Acc2->setDebugLoc(DL);
    }
  }

  Sel->replaceAllUsesWith(Res);
  Sel->eraseFromParent();
  region.Merge = nullptr;  // dissolved.

  // The reduction's result is a fresh i32 quantum handle (the dissolved `y`).
  // Register it as tainted (with a BirthOrder slot, matching the data-path
  // bookkeeping) so downstream consumers — a `cq_measure`, or further tainted
  // arithmetic — recognize it. Without this, a `y = (q>0)?A:B; measure(y);`
  // slice trips MeasureLowering's "operand not a tainted i32 handle" guard
  // (the `br`-diamond case is fine: it RAUWs to an already-tainted in-place
  // handle, never minting a new one). The seed register / delta are consumed
  // in-place by the add, so only the final `Res` needs tracking.
  taint.Tainted.insert(Res);
  taint.BirthOrder[Res] = taint.NextBirth++;
}

}  // namespace

void dissolveMerge(ControlRegion &region, WidthDispatch &wd,
                   ControlledSymbols &csyms, TaintSet &taint) {
  if (region.Kind == ControlRegion::SelectRegion)
    dissolveSelect(region, wd, csyms, taint);
  else
    dissolveBranchPhi(region, wd, csyms, taint);
}

Instruction *reduceAngleSelect(ControlRegion &region, WidthDispatch &wd,
                               TaintSet &taint) {
  auto *Sel = dyn_cast_or_null<SelectInst>(region.Merge);
  if (!Sel || !region.Flag)
    return nullptr;  // no flag (ControlFlag failed) → leave for the verifier.

  // `select i1 c, a, b` = `c ? a : b`. Ry/Rz are angle-additive, so
  // `Rz(b + f·(a−b)) = Rz(b) · ctrl_f Rz(a−b)`: emit the unconditional BASE
  // rotation by the false-arm angle `b`, then a flag-controlled DIFFERENCE
  // rotation by `a − b`. When the flag (= lowered condition) is 1 the total
  // angle is `a`, when 0 it is `b` — exactly the select.
  Value *A = Sel->getTrueValue();   // flag=1 angle.
  Value *B = Sel->getFalseValue();  // flag=0 angle (the base).

  SmallVector<Instruction *, 4> ToErase;
  for (Instruction *S : region.Shadow) {
    auto *Phi = dyn_cast<CallInst>(S);
    if (!Phi || Phi->arg_size() < 2)
      continue;
    Value *Handle = Phi->getArgOperand(0);  // the rotation handle (arg 0).

    // BASE: unconditional `cqrt_rz_<W>(handle, b)`. `emitRz` reads the width
    // suffix off the `cq_phi` callee and inserts before it.
    if (!emitRz(Phi, Handle, B, wd, /*controlled=*/false, /*flag=*/nullptr))
      continue;  // unsupported width — leave the rotation for the verifier.
    // DIFFERENCE angle `a − b`: a HOST fp `fsub` (both angles classical — the
    // angle taint-discipline keeps them so; constants fold).
    IRBuilder<> Builder(Phi);
    Value *Diff = Builder.CreateFSub(A, B, "ang_diff");
    if (auto *DI = dyn_cast<Instruction>(Diff))
      if (DebugLoc DL = Phi->getDebugLoc())
        DI->setDebugLoc(DL);
    // CONTROLLED: `cqrt_rz_<W>_controlled(flag, handle, a−b)`.
    if (!emitRz(Phi, Handle, Diff, wd, /*controlled=*/true, region.Flag))
      continue;

    Phi->replaceAllUsesWith(Handle);  // the phi value is the in-place handle.
    taint.ControlFlag[Handle] = region.Flag;
    ToErase.push_back(Phi);
  }

  // Uncompute after the program-order-last rotation — off the block-last
  // consumer, NOT the last-iterated one (`region.Shadow` is use-list order, so
  // a multi-rotation angle select would otherwise land the uncompute mid-bracket
  // → controlled rotations on an uncomputed flag, a silent miscompile).
  Instruction *Anchor = anchorAfterLastConsumer(ToErase);
  for (Instruction *I : ToErase)
    I->eraseFromParent();
  // Erase the now-dead angle select (all consuming rotations are gone).
  if (Sel->use_empty())
    Sel->eraseFromParent();
  region.Merge = nullptr;
  return Anchor;
}

// cwk fix (b) (test_C_libtooling-byx) — the `br`-diamond analog of
// `reduceAngleSelect`: lower a classical-angle merge `φ` (recorded in
// `region.AnglePhi`, feeding the rotations in `region.AngleConsumers`) as
// controlled-rotation-by-difference. Per consuming `cq_phi`/`cq_theta`, emit the
// unconditional BASE `Rz(handle, base)` then a flag-controlled DIFFERENCE
// `Rz_controlled(flag, handle, arm − base)` — Ry/Rz angle-additivity, so the
// total angle is `arm` when the flag holds and `base` otherwise.
//
// POLARITY (C2) is read off the φ's INCOMING EDGES, never select-style
// true/false: the `flag==0` (ZERO) edge carries the BASE angle, the `flag==1`
// (ONE) edge the arm angle. Both are named EXPLICITLY per shape (NOT "the first
// non-zero incoming" — that scan only works for a 2-way φ):
//   * symmetric diamond (WP8):   zero=`ArmFalse`,  one=`Arm` (the true arm)
//   * swapped one-arm (`ArmNegated`): zero=`Arm`,  one=`Pred` (arm is the FALSE
//     successor, taken when the condition is false)
//   * ordinary one-arm diamond:  zero=`Pred`,      one=`Arm` (straight-through)
//   * nested-AND `a ∧ b` (PR2):  zero=`Pred`,      one=`Arm` (innermost arm) —
//     the 3-way φ's base rides BOTH the `Mid` and `Pred` edges (the inner- and
//     outer-guard-false paths, SSA-identical), so it reduces to the same 2-way
//     base/arm form on the COMBINED conjunction flag (`region.Flag`).
//   ⚠ Do NOT reuse `dissolveBranchPhi`'s `InPlaceEdge = ArmFalse ? Arm : Pred`:
//   that names the `flag==1` (Arm/Pred) edge and is sound there only because a
//   gate-handle φ carries the SAME handle on both edges. The two angle edges
//   differ, so the base must be the `flag==0` edge — using the wrong edge swaps
//   base/diff (a silent miscompile in the symmetric and ArmNegated shapes).
//
// Runs AFTER `dissolveBranchPhi` (which dissolves any sibling gate-handle φ), so
// a consumer's arg-0 handle is read LIVE. Returns the uncompute anchor (the node
// after the last rotation, surviving the consumer erasure) for the orchestrator
// to anchor the flag uncompute, or null on failure. `region.Flag` must be minted.
Instruction *reduceAngleDiamondPhi(ControlRegion &region, WidthDispatch &wd,
                                   TaintSet &taint) {
  if (!region.Flag)
    return nullptr;  // no flag (ControlFlag failed) → leave for the verifier.

  // Emit every consumer's base + controlled-difference FIRST, collecting the
  // lowered consumers; the uncompute anchor is computed afterward off the
  // block-LAST consumer (so it lands after ALL rotations, not after whichever
  // consumer happened to be last in use-list order — risk: a mid-bracket
  // uncompute, see `anchorAfterLastConsumer`).
  SmallVector<Instruction *, 4> ToErase;
  for (PHINode *P : region.AnglePhi) {
    if (!P)
      continue;
    // The flag==0 (BASE) edge and the flag==1 (ARM) edge, named EXPLICITLY per
    // shape rather than "the first non-zero incoming" — that scan is only sound
    // for a 2-way φ, but the nested-AND form (PR2) has a 3-way φ whose base
    // rides BOTH the `Mid` (inner-guard-false) and `Pred` (outer-guard-false)
    // edges, so "first non-zero" can latch the wrong edge depending on φ order.
    //   * symmetric diamond:        zero=ArmFalse,  one=Arm  (=armT)
    //   * swapped one-arm diamond:  zero=Arm,       one=Pred  (ArmNegated)
    //   * ordinary one-arm diamond: zero=Pred,      one=Arm
    //   * nested-AND (`a ∧ b`):     zero=Pred,      one=Arm  (innermost arm)
    BasicBlock *ZeroEdge = region.ArmFalse
                               ? region.ArmFalse
                               : (region.ArmNegated ? region.Arm : region.Pred);
    BasicBlock *OneEdge = region.ArmNegated ? region.Pred : region.Arm;
    int Zi = ZeroEdge ? P->getBasicBlockIndex(ZeroEdge) : -1;
    int Oi = OneEdge ? P->getBasicBlockIndex(OneEdge) : -1;
    if (Zi < 0 || Oi < 0)
      continue;  // malformed (missing flag edge); leave the φ for the verifier.
    Value *Base = P->getIncomingValue(Zi);     // the flag==0 (base) angle.
    Value *ArmAngle = P->getIncomingValue(Oi);  // the flag==1 (arm) angle.
    // Defensive (no silent miscompile): every incoming OTHER than the flag==1
    // arm edge must carry the base angle. For a 2-way φ this is trivially the
    // single zero edge; for the nested-AND 3-way φ the `Mid` and `Pred` edges
    // both carry the pre-existing angle (SSA gives them the SAME value), so they
    // equal Base. A differing edge means this is not a clean 2-way-on-the-
    // conjunction dispatch — leave the φ for the verifier (a loud "PHI nodes not
    // grouped") rather than rotate by a wrong difference.
    bool CleanBase = true;
    for (unsigned k = 0, e = P->getNumIncomingValues(); k != e; ++k)
      if (static_cast<int>(k) != Oi && P->getIncomingValue(k) != Base) {
        CleanBase = false;
        break;
      }
    if (!CleanBase)
      continue;

    for (Instruction *S : region.AngleConsumers) {
      auto *Phi = dyn_cast<CallInst>(S);
      if (!Phi || Phi->arg_size() < 2 || Phi->getArgOperand(1) != P)
        continue;  // not a rotation consuming THIS angle φ.
      Value *Handle = Phi->getArgOperand(0);  // re-read LIVE (post handle-φ RAUW).
      // BASE: unconditional `cqrt_rz_<W>(handle, base)`.
      if (!emitRz(Phi, Handle, Base, wd, /*controlled=*/false, /*flag=*/nullptr))
        continue;  // unsupported width — leave the rotation for the verifier.
      // DIFFERENCE angle `arm − base`: a HOST fp `fsub` (both angles classical).
      IRBuilder<> Builder(Phi);
      Value *Diff = Builder.CreateFSub(ArmAngle, Base, "ang_diff");
      if (auto *DI = dyn_cast<Instruction>(Diff))
        if (DebugLoc DL = Phi->getDebugLoc())
          DI->setDebugLoc(DL);
      // CONTROLLED: `cqrt_rz_<W>_controlled(flag, handle, arm − base)`.
      if (!emitRz(Phi, Handle, Diff, wd, /*controlled=*/true, region.Flag))
        continue;
      Phi->replaceAllUsesWith(Handle);  // the φ value is the in-place handle.
      taint.ControlFlag[Handle] = region.Flag;
      ToErase.push_back(Phi);
    }
  }

  // The uncompute lands after the program-order-last rotation (compute → body →
  // uncompute, §1.5). Compute it before erasing — the block-last consumer's
  // successor survives (it is not itself a consumer).
  Instruction *Anchor = anchorAfterLastConsumer(ToErase);
  for (Instruction *I : ToErase)
    I->eraseFromParent();
  for (PHINode *P : region.AnglePhi)
    if (P && P->use_empty())
      P->eraseFromParent();  // the angle φ is dead once its rotations are gone.
  region.AnglePhi.clear();
  return Anchor;
}

// cwk fix (b) PR3 (test_C_libtooling-byx) — the gated-`switch` analog of
// `reduceAngleSelectChain`: lower a gated `SwitchRegion`'s classical-angle merge
// `φ`(s) (`region.AnglePhi`, consumed by `region.AngleConsumers`) as base +
// per-case controlled-difference. The BASE angle is the DEFAULT arm's `φ`
// incoming (`region.Arm`, applied unconditionally — the angle when no case
// matched); each case `k` adds `Rz_controlled(CaseFlags[k], handle, a_k − base)`
// where `a_k` is the `φ` incoming from `region.SwitchArms[k].Block`. The cases
// are mutually exclusive (eq on one scrutinee), so the total angle is `a_k` for
// the matching case and `base` for the default — exactly the switch dispatch.
//
// REUSES the per-case eq-flags `lowerGatedSwitch` already minted for the arm
// gate bodies (`CaseFlags[k]` ↔ `region.SwitchArms[k]`), so no fresh compares
// are emitted — the single compute/uncompute bracket the gates live in covers
// the angle rotations too. The default's ¬OR "none-matched" flag is NOT needed:
// the unconditional base IS the default angle. Runs AFTER the handle-φ
// dissolution (step 4) and BEFORE the flag uncompute (step 5); returns the
// uncompute anchor (the node after the last rotation, surviving the consumer
// erasure) so the uncompute lands after the controlled-differences, or null.
Instruction *reduceAngleSwitchPhi(ControlRegion &region,
                                  ArrayRef<Value *> CaseFlags, WidthDispatch &wd,
                                  TaintSet &taint) {
  // `taint` is part of the reducer signature for consistency with the diamond /
  // select-chain reducers, but the switch-angle reduction RAUWs to an
  // already-tainted handle and uses per-case flags (no single `region.Flag` to
  // stamp on `taint.ControlFlag`), so nothing new is registered here.
  (void)taint;
  if (region.AnglePhi.empty() || !region.Arm)
    return nullptr;
  if (CaseFlags.size() != region.SwitchArms.size())
    return nullptr;  // flag/arm count mismatch (malformed); leave for verifier.

  SmallVector<Instruction *, 4> ToErase;
  for (PHINode *P : region.AnglePhi) {
    if (!P)
      continue;
    int Di = P->getBasicBlockIndex(region.Arm);  // the default (base) edge.
    if (Di < 0)
      continue;  // no default edge; leave the φ for the verifier.
    Value *Base = P->getIncomingValue(Di);

    for (Instruction *S : region.AngleConsumers) {
      auto *Phi = dyn_cast<CallInst>(S);
      if (!Phi || Phi->arg_size() < 2 || Phi->getArgOperand(1) != P)
        continue;  // not a rotation consuming THIS angle φ.
      Value *Handle = Phi->getArgOperand(0);  // re-read LIVE (post handle-φ RAUW).
      DebugLoc DL = Phi->getDebugLoc();

      // BASE: unconditional `cqrt_rz_<W>(handle, default-angle)`.
      if (!emitRz(Phi, Handle, Base, wd, /*controlled=*/false, /*flag=*/nullptr))
        continue;  // unsupported width — leave the rotation for the verifier.

      // One controlled-DIFFERENCE rotation per case, on its eq-flag. The flags
      // are mutually exclusive, so the differences are independent (no nesting).
      for (unsigned k = 0; k < region.SwitchArms.size(); ++k) {
        int Ai = P->getBasicBlockIndex(region.SwitchArms[k].Block);
        if (Ai < 0)
          continue;  // this case is not a φ predecessor; no difference to add.
        Value *Ak = P->getIncomingValue(Ai);
        IRBuilder<> Builder(Phi);
        Value *Diff = Builder.CreateFSub(Ak, Base, "ang_diff");
        if (auto *DI = dyn_cast<Instruction>(Diff))
          if (DL)
            DI->setDebugLoc(DL);
        if (!emitRz(Phi, Handle, Diff, wd, /*controlled=*/true, CaseFlags[k]))
          continue;
      }

      Phi->replaceAllUsesWith(Handle);  // the φ value is the in-place handle.
      ToErase.push_back(Phi);
    }
  }

  // Uncompute anchor: after the program-order-last rotation (consumers are
  // collected in use-list order, so derive it off the block-last consumer — see
  // `anchorAfterLastConsumer`).
  Instruction *Anchor = anchorAfterLastConsumer(ToErase);
  for (Instruction *I : ToErase)
    I->eraseFromParent();
  for (PHINode *P : region.AnglePhi)
    if (P && P->use_empty())
      P->eraseFromParent();
  region.AnglePhi.clear();
  return Anchor;
}

void reduceAngleSelectChain(ControlRegion &region, WidthDispatch &wd,
                            TaintSet &taint) {
  auto *Head = dyn_cast_or_null<SelectInst>(region.Merge);
  if (!Head)
    return;

  // Walk the false-arm chain (outer→inner): collect (condition, case-angle)
  // pairs and the non-select base angle. Detection validated the chain is
  // mutually exclusive (each condition `icmp eq` against one scrutinee with a
  // distinct constant), so the nested select equals the additive form
  // `base + Σ_k f_k·(a_k − base)` this lowers to.
  SmallVector<std::pair<CmpInst *, Value *>, 4> Cases;
  SmallVector<SelectInst *, 4> ChainSelects;
  SelectInst *Cur = Head;
  Value *Base = nullptr;
  while (Cur) {
    auto *Cmp = dyn_cast<CmpInst>(Cur->getCondition());
    if (!Cmp)
      return;  // malformed post-validation; leave the chain for the verifier.
    Cases.push_back({Cmp, Cur->getTrueValue()});
    ChainSelects.push_back(Cur);
    Value *F = Cur->getFalseValue();
    if (auto *Next = dyn_cast<SelectInst>(F)) {
      Cur = Next;
      continue;
    }
    Base = F;
    break;
  }
  if (!Base)
    return;

  SmallVector<Instruction *, 4> ToErase;
  for (Instruction *S : region.Shadow) {
    auto *Phi = dyn_cast<CallInst>(S);
    if (!Phi || Phi->arg_size() < 2)
      continue;
    Value *Handle = Phi->getArgOperand(0);
    DebugLoc DL = Phi->getDebugLoc();

    // Unconditional BASE rotation by the default angle.
    if (!emitRz(Phi, Handle, Base, wd, /*controlled=*/false, /*flag=*/nullptr))
      continue;  // unsupported width — leave the rotation for the verifier.

    // One controlled-DIFFERENCE rotation per case, each inside its own
    // compare compute/uncompute bracket. The eq-flags are mutually exclusive,
    // so independent (non-overlapping) brackets are correct — no LIFO nesting.
    for (auto &C : Cases) {
      CmpInst *Cmp = C.first;
      Value *Ak = C.second;
      Value *Flag = lowerCompareToFlag(Cmp, wd, taint, /*qqWidth=*/{},
                                       /*inverse=*/false, /*before=*/Phi);
      if (!Flag)
        continue;  // unsupported compare (diagnosed) — skip this case.
      IRBuilder<> Builder(Phi);
      Value *Diff = Builder.CreateFSub(Ak, Base, "ang_diff");
      if (auto *DI = dyn_cast<Instruction>(Diff))
        if (DL)
          DI->setDebugLoc(DL);
      if (!emitRz(Phi, Handle, Diff, wd, /*controlled=*/true, Flag))
        continue;
      // Uncompute the flag (`_inv` twin), restoring the balanced ancilla.
      (void)lowerCompareToFlag(Cmp, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                               /*before=*/Phi);
    }

    Phi->replaceAllUsesWith(Handle);  // the rotation value is the in-place handle.
    ToErase.push_back(Phi);
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
  // Erase the chain selects (head→inner; each dead once its single consumer is
  // gone) then their now-dead condition compares.
  for (SelectInst *Sel : ChainSelects)
    if (Sel->use_empty())
      Sel->eraseFromParent();
  for (auto &C : Cases)
    if (C.first->use_empty())
      C.first->eraseFromParent();
  region.Merge = nullptr;
}

}  // namespace cq
