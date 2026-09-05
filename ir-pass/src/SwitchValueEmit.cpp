// SwitchValueEmit.cpp — the mutating swap-route emitter for an accepted tainted
// `switch` whose content arms are homogeneous VALUE chains (4.5 WI-3; PRD Part V
// §20; IMPLEMENTATION-4.5 §4B). The N-way generalization of the 4.2 value diamond
// (`SwapRouteEmit::emitValueRegion`) — method-B (compute → copy-out → reverse-play,
// Rule 7), but routing the SHARED base `p` = the merge default-edge (straight-
// through) incoming, NOT the scrutinee `q` (the C2 anchor — `p != q`, proven in
// `proveSwitchValue`; routing `q` would clobber the eq-flags, §3c).
//
// Per content case the eq-flags `f_i = (q == c_i)` are MUTUALLY EXCLUSIVE (q
// equals at most one case literal), so the per-case route fires only when q == c_i
// and the off-case routes are identities. The forward stage is therefore safely
// INTERLEAVED per case (§4B): mint f_i → |0> rail r_i → cswap route-in (positive-
// polarity, NO ¬-bracket) → replay the chain VERBATIM/UNCONTROLLED on r_i → cswap
// route-back. After all route-backs `p` holds the muxed answer (exactly one case
// settled it; the rest left p untouched). Then ONE uncontrolled `cqrt_copy_<W>(p,
// out)` copy-out (the only basis copy, after route-back, before any R†), the LIFO
// reverse-play (route-back† · body-chain adjoint · route-in†; the cases commute —
// disjoint rails, complementary flag values — so the grouped LIFO equals the global
// adjoint), clean rail frees, the `icmp_inv` flag strips (q == q0 — q is never
// routed), and the flag frees. `p` is restored to p0 and left live; `out` is the
// result; NEITHER is freed (either free is a hidden measurement, Rule 6/8).
//
// Correctness rests on the §8.2 register-threading trace, NOT on `opt -verify`
// (Rule 2). THE §8.5 cswap-arg0 SEAM (verify-clean-invisible): the route cswaps are
// NEVER fed to `emitInverseChain` — `emitInverseCall` may substitute a threaded
// handle into Args[0] (its `CurHandle` path, reserved for Phase-7), which for
// `cqrt_cswap` is the FLAG slot (a rail handle there is a wrong unitary). The
// reverse-play hands the inverter the BODY CHAIN ONLY (void `_unc` forms) and
// brackets the route cswaps itself via `emitRoute` (cswap is self-inverse), exactly
// as `emitValueRegion` does in `SwapRouteEmit.cpp`.

#include "SwitchRouteEmit.h"  // emitSwitchValueRegion (declared beside the phase emit)

#include "ArmAnalysis.h"       // walkValueChain (re-derive each arm's chain at emit)
#include "CompareLowering.h"   // emitEqFlag
#include "ControlPlan.h"       // ControlRegion / SwitchArm / diagnoseUnderControl
#include "ControlledSymbols.h" // copyControlledFn (the 4.4/6.5 merge primitive)
#include "OpcodeSupport.h"     // abiWidthFromType (the rail/copy width)
#include "RegionFlatten.h"     // flattenSwitchRegion
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"     // allocFn / copyFn / freeFn / llvmWidthType

#include "llvm/Analysis/ValueTracking.h"  // isSafeToSpeculativelyExecute (Inc 2)
#include "llvm/ADT/STLExtras.h"  // llvm::reverse
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
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
  if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
    diagnoseUnderControl(A, "control flow");
  else if (R.Merge)
    diagnoseUnderControl(R.Merge, "control flow");
}

// One content case's routed VALUE stream: the case literal (eq-flag source), the
// ordered ORIGINAL chain links (FORWARD/base-first order — erased after rewire),
// and the per-case state threaded through emission.
struct CaseStream {
  ConstantInt *Val = nullptr;
  SmallVector<Instruction *, 6> Chain;  // the arm's ORIGINAL links (HOISTED, kept)
  Value *Flag = nullptr;                // the case's eq-flag (stripped + freed)
  Instruction *Delta = nullptr;         // `R_i(p) ^ p`, the controlled-copy source
};

}  // namespace

void emitSwitchValueRegion(const ControlRegion &R, WidthDispatch &wd,
                           ControlledSymbols &csyms, TaintSet &taint) {
  auto *MergePhi = dyn_cast_or_null<PHINode>(R.Merge);
  Value *Q = R.Condition;  // the scrutinee = the eq-flag source (never written).
  if (!MergePhi || !Q || !R.Pred || !R.MergeBB || R.SwitchArms.empty())
    return bailLoud(R);

  // The `switch` terminator — every emitted call and every hoisted chain link
  // lands before it, in the switch block, so the whole stream executes
  // unconditionally ahead of the (soon dead) branch. Reading it off Pred keeps
  // the emitter a pure consumer of the by-identity plan (no cached terminator).
  auto *SI = dyn_cast<SwitchInst>(R.Pred->getTerminator());
  if (!SI)
    return bailLoud(R);

  // Routed base `p` = the merge incoming on the SwitchBB→MergeBB (default-direct)
  // edge — the straight-through value, proven `!= q` by the C2 anchor
  // (`proveSwitchValue`). An empty default + any straight-to-merge case share this
  // one predecessor edge. Recover it here (not cached) so the emitter stays a pure
  // consumer of the by-identity plan.
  int STIdx = MergePhi->getBasicBlockIndex(R.Pred);
  Value *P = STIdx >= 0 ? MergePhi->getIncomingValue(STIdx) : nullptr;
  if (!P || P == Q)
    return bailLoud(R);

  // Recover + validate every CONTENT case's chain by re-walking (pure analysis,
  // idempotent — no mutation has happened for this region yet, so the walk returns
  // the same links `proveSwitchValue` accepted). Each off-pattern result bails
  // LOUDLY (detection proved the shape; this is the Rule-1 defensive bail, never a
  // silent skip).
  SmallVector<CaseStream, 4> Cases;
  for (const SwitchArm &Arm : R.SwitchArms) {
    if (!Arm.Block || Arm.Values.empty())
      continue;  // straight-to-merge / malformed — no chain to route.
    Value *Incoming = MergePhi->getIncomingValueForBlock(Arm.Block);
    if (!Incoming)
      return bailLoud(R);  // arm not a merge-phi pred — detection proved it is.
    if (Incoming == P)
      continue;  // passthrough case — `out` already holds p (the preload).
    ValueChain VC = walkValueChain(Incoming, Arm.Block, taint, P);
    if (VC.MixedPhi || VC.Base != P || VC.HasQQ || VC.Ops.empty())
      return bailLoud(R);  // not the proven pure linear chain bottoming at p.
    // Library-host parity (the twin-pipeline trap): a chain link
    // `declineStaleRecordOps` marked has already pledged "lower NOTHING"; hoisting
    // it here would break that pledge and, since `lowerOps` skips it, would SILENTLY
    // DROP an arm op (Rule 5). `opt` exits at the stale DS_Error first, so no lit
    // fixture pins this — Rule-1 defensive bail.
    for (Instruction *Op : VC.Ops)
      if (taint.StaleDeclined.count(Op))
        return bailLoud(R);
    // SPECULATION TOTALITY — the switch twin of the diamond fence (PRD §10.3 lens
    // 8; SwapRouteEmit::emitValueRegion). Every chain link now runs
    // UNCONDITIONALLY on the ORIGINAL `p`, so a link whose C semantics are
    // UNDEFINED for some operand value (`sdiv`/`udiv`/`srem`/`urem` with a
    // possibly-zero or `INT_MIN / -1` classical divisor) must decline. Ask LLVM's
    // OWN predicate — the one SimplifyCFG consults before speculating a block
    // (Rule 14) — never a hand-rolled per-opcode table. The pre-3qlq route ran the
    // chain unconditionally too (on a `|0>` rail, i.e. `0 sdiv n`), so this fence
    // NARROWS the accept class rather than repairing a regression; that direction
    // is always safe (Prime Directive).
    for (Instruction *Op : VC.Ops)
      if (!isSafeToSpeculativelyExecute(Op)) {
        diagnoseUnderControl(Op, "value arm op that cannot run unconditionally");
        return;
      }
    // GROUPED CASE LABELS — assert, never silently accept (PRD §10.3 lens 8).
    // The XOR-delta merge gates arm i on the SINGLE eq-flag `q == Values.front()`,
    // so an arm reached by two or more literals (`case 0: case 1: p = p+1;`) would
    // apply its delta on ONE of them and SILENTLY drop the rest — a verify-clean
    // wrong mux. `SwitchClassify`'s grouped-case decline (C4) already refuses that
    // shape, so this is the Rule-1 defensive bail on a shape detection proved
    // absent, never a silent skip. (The retired route had the identical
    // `Values.front()` read and the identical exposure.)
    if (Arm.Values.size() != 1)
      return bailLoud(R);
    CaseStream CS;
    CS.Val = Arm.Values.front();
    CS.Chain.assign(VC.Ops.begin(), VC.Ops.end());
    Cases.push_back(std::move(CS));
  }
  if (Cases.empty())
    return bailLoud(R);  // no content — `proveSwitchValue` proved SawContent.

  // MUTUAL EXCLUSION — assert, never assume (PRD §10.3 lens 8). The whole
  // correctness argument for "preload `out = p`, then `out ^= f_i · d_i` for every
  // case" is that AT MOST ONE `f_i` is 1; two equal case literals would apply two
  // deltas on the same branch and yield `p ^ d_a ^ d_b`, a verify-clean wrong
  // answer. `SwitchInst` semantics guarantee distinctness (LLVM's verifier rejects
  // a duplicated case value), so this loop can never fire — which is exactly why it
  // is cheap enough to keep as a written assertion rather than a comment. N is the
  // number of content cases (small); the quadratic scan is not a cost.
  for (size_t i = 0; i + 1 < Cases.size(); ++i)
    for (size_t j = i + 1; j < Cases.size(); ++j)
      if (Cases[i].Val->getValue() == Cases[j].Val->getValue())
        return bailLoud(R);

  // ONE width for the out-rail / deltas / copies, from the chain op's INTEGER SSA
  // type — reliable pre-RAUW (the ops still carry iN; §4 width-source). NEVER the
  // scrutinee suffix (q may be a derived handle) and never a classifying signal
  // (the f64 trap). The positive integer fence already passed at G4, so a null here
  // is a malformed plan — bail LOUDLY. Two copy minters: the UNCONTROLLED
  // `cqrt_copy_<W>` for the preload and the 4.4/6.5 `cqrt_copy_<W>_controlled` for
  // the per-case XOR-delta merge. NO new runtime symbol (epic decision D3).
  StringRef Abi = abiWidthFromType(Cases.front().Chain.front()->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Copy = Abi.empty() ? FunctionCallee() : wd.copyFn(Abi);
  FunctionCallee CopyC =
      Abi.empty() ? FunctionCallee() : csyms.copyControlledFn(Abi);
  if (!RailTy || !Alloc || !Copy || !CopyC)
    return bailLoud(R);

  const DebugLoc DL = SI->getDebugLoc();
  IRBuilder<> B(SI);  // every emitted call lands before the `switch`.
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // 1. PRELOAD — `out = |0>`, then the ONE uncontrolled basis copy `out ^= p`, so
  //    `out` holds the straight-through value on every branch before any case
  //    fires. This is the 4.5 data-mux's `cqrt_alloc_<W>(v_d)` preload with the
  //    default literal replaced by the quantum register `p` (which cannot be an
  //    alloc immediate). `out` joins `taint.Tainted` (+BirthOrder) so the RAUW'd
  //    merge phi's consumers keep classifying it as a quantum handle; its users are
  //    the preload copy + the N controlled copies (as dst) + the user's measure /
  //    ret, so `uncompute` never selects it (isTerminalHandle false). NEVER freed —
  //    the live result, owned by the user's measure / ret (Rule 6).
  CallInst *Out = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "out");
  stamp(Out);
  taint.Tainted.insert(Out);
  taint.ControlOwnedRails.insert(Out);  // DD-4: Phase-4 owns this merge out-rail
  taint.BirthOrder[Out] = taint.NextBirth++;
  // bd p119.8 (same gap as p119.6): record the out-rail's LOGICAL ABI width (=
  // `Abi`, the routed value-arm width) so a DOWNSTREAM cast/Q+Q-compare off the
  // RAUW'd merge recovers the real width instead of the laundered i32.
  taint.HandleWidth[Out] = Abi;
  stamp(B.CreateCall(Copy, {P, Out}));

  // 2. Per CONTENT case, in source order: HOIST the chain onto the ORIGINAL `p`,
  //    build the XOR-DELTA `d_i = R_i(p) ^ p`, mint the eq-flag, and merge with ONE
  //    controlled copy `out ^= f_i · d_i`. The eq-flags are MUTUALLY EXCLUSIVE (q
  //    equals at most one case literal), so at most one delta is applied and
  //    `out = R_i(p)` on case i, `out = p` on every other branch. That mutual
  //    exclusion is a property of `switch` SEMANTICS — LLVM forbids duplicate case
  //    values in a `SwitchInst` and the verifier enforces it — so no conjunction
  //    flag and no ¬-bracket is needed anywhere in this emitter.
  //
  //    ORDERING: the hoisted chain links and the delta are ORDINARY tainted LLVM
  //    instructions moved/created before `SI`; they are lowered LATER by `lowerOps`
  //    (which is what lets the chain take the same in-place M-C conversions any
  //    straight-line tainted arithmetic gets) and reversed by the whole-DAG LIFO
  //    spine. Interleaving them with this builder's calls in ONE loop keeps the
  //    emitted trace in per-case order.
  for (CaseStream &CS : Cases) {
    // a. Hoist the chain, forward (base-first) order — each link stays dominated
    //    by its operands. Nothing is retargeted: the head link keeps reading `p`,
    //    which is exactly what the delta needs.
    for (Instruction *Op : CS.Chain)
      Op->moveBefore(SI);
    Value *ArmVal = CS.Chain.back();

    // b. XOR-delta `d_i = R_i(p) ^ p` — a Q+Q `xor` (both operands are quantum
    //    handles), lowered by `lowerOps` to `cq_template_xor_<W>` on a fresh rail
    //    and reversed by the spine's `_unc` twin (`tools/opcode_table.yaml` ships
    //    fwd_qq / unc_qq for `xor` at every integer width). Recorded in
    //    `taint.Tainted` + `BirthOrder` exactly as a source-level tainted op would
    //    be, so `lowerOps` claims it and the spine orders it.
    auto *Delta = BinaryOperator::CreateXor(ArmVal, P, "delta", SI);
    Delta->setDebugLoc(DL);
    taint.Tainted.insert(Delta);
    taint.BirthOrder[Delta] = taint.NextBirth++;
    CS.Delta = Delta;

    // c. Mint eq-flag — cq_template_icmp_eq_<Wq>_hl(q, c_i). Null only on an
    //    unsupported case-literal width; the literal shares the merge-phi width
    //    (G4-validated) so on an ACCEPTED region this is UNREACHABLE — kept as the
    //    Rule-1 defensive bail.
    CS.Flag = emitEqFlag(Q, CS.Val, wd, /*inverse=*/false, /*before=*/SI);
    if (!CS.Flag)
      return bailLoud(R);

    // d. Controlled XOR copy — cqrt_copy_<W>_controlled(f_i, d_i, out): out ^= d_i
    //    iff f_i = 1 (flag arg-0, src arg-1, dst arg-2 — PRD §1.2).
    stamp(B.CreateCall(CopyC, {CS.Flag, Delta, Out}));
  }

// bd urlv audit — NO KEPT-CARRIER RECORD REACHES THE N EQ-FLAGS FREED BELOW. Each is minted BY THIS EMITTER at |0> and stripped back to |0> by its own
  // `icmp_eq_inv` immediately before its free. They are
// never an operand of a gate that writes a carrier the reversal does not touch:
// this module mints NO `cqrt_tape_write_*` (only `IOSinkLowering` and
// `AbortParkEmit` do), and its copies write a fresh `out`. So the bd 261j(a)
// freeze is not owed here and is deliberately not duplicated (bd memory
// [record-freeze-invariant-2026-08-10]). Re-check if this emitter ever tapes.
  // 3. STRIP + FREE all N flags. Each `icmp_eq_inv(q, c_i)` reads PRISTINE q
  //    (q == q0 — the copies write `out`, never q, and the hoisted chains write
  //    fresh rails), so each flag returns to |0> with zero controlled gates and is
  //    free-able. The strips run AFTER all copies, flowing forward to mirror the
  //    per-case mint order.
  for (CaseStream &CS : Cases) {
    emitEqFlag(Q, CS.Val, wd, /*inverse=*/true, /*before=*/SI,
               /*railToStrip=*/CS.Flag);
    CallInst *FlagFree = B.CreateCall(wd.freeFn(), {CS.Flag});
    stamp(FlagFree);
  }

  // 4. REWIRE + scrub + flatten. The measure on the phi becomes a measure on `out`
  //    (the muxed answer; no measurement is added — Rule 5). The hoisted chain
  //    links and the deltas are NOT erased here — unlike the retired route, which
  //    replayed and then erased them, they ARE the surviving computation and
  //    `lowerOps`/the spine own them from now on. `p`, `out` and the chain rails
  //    are never freed by this emitter (Rule 6/8; freeing the source is PRD §9
  //    follow-on work).
  MergePhi->replaceAllUsesWith(Out);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  flattenSwitchRegion(R, taint);
}

}  // namespace cq
