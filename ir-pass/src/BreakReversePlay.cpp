// BreakReversePlay.cpp — Phase 7.4 Increment 2 (epic y05j) — the POST-LOWERING
// capture + whole-loop reverse-play for a single value-arm `break` loop.
// See LoopPlan.h (`lowerBreakReversePlay`) for the contract and PRD-7.4 §2.2/§2.3.
//
// The forward transform (`emitBreakForward`, LoopLowering.cpp, PRE-lowering) has
// already collapsed the rail to one in-place handle, stripped the loop terminator
// to the classical bound (so the rolled loop runs its FULL trip count — the break
// is virtual, PRD §2.9), minted `R`/`idx`/`out`, and RAUW'd the exit merge phi →
// `out`. This stage runs AFTER `lowerOps`/`lowerRotations` on the fully-LOWERED
// body (i32 handles throughout — the staging that lets the rail-mutation adjoint
// reuse `emitInverseChain`). For each recorded `LoopBreakRegion` it emits:
//   (a) the index-gated copy-not-move CAPTURE into the forward body, after the
//       break-cond, with every per-iteration scratch UNCOMPUTED + FREED in
//       iteration (O(1) carried = rail + R + idx);
//   (b) the loop-exit CONSOLIDATION (`idx==0` ⇒ never-broke full-trip value), the
//       `cqrt_copy_<W>` COPY-OUT into `out`, and the consolidation REVERSE;
//   (c) the backward-counted REVERSE-PLAY companion loop — the whole-loop adjoint
//       `C†` (per iteration), which returns `R`/`idx`/rail to their pre-capture
//       state, disentangling `out` from the which-iteration ancilla — then
//       `cqrt_free(R)`/`free(idx)`.
//
// CORRECTNESS (the Rule-13 core, PRD §2.2a/§6): the forward per-iteration capture
// `C` controls on `fire = brk ∧ (idx==0)` (capture only the FIRST break; `idx`
// latches the iteration as `i+1`); `C` is a clean unitary on `(rail, R, idx)` — all
// scratch (the break-cond `_unc`, the `idx==0`/`idx==i+1` eq-flags, `fire`, the
// `i+1` materialiser) is uncomputed + freed before the backedge. The backward `C†`
// recomputes `fire' = (idx == i'+1)` (the POST-capture control) — and `fire' ≡
// fire` on every amplitude branch (a never-fired/earlier-fired iteration has
// `idx ≠ i'+1`; the first-fire iteration has `idx == i'+1`) — so applying the same
// controlled XORs un-captures `R`/`idx` exactly. `C†` recomputes the break-cond
// (from the same rail value `r_{i'}`) to uncompute `fire` via the same Toffoli, so
// `fire` ends `|0>`. The reverse-play runs the SAME classical `n` times, so the
// rail walks back to `q0`. Every break-body handle joins `taint.ControlOwnedRails`
// so the whole-DAG `uncompute` spine never double-reverses the construct.

#include "LoopPlan.h"

#include "CompareLowering.h"    // emitEqFlag
#include "ControlledSymbols.h"  // copyControlledFn
#include "EmitInverse.h"        // emitInverseCall / emitInverseChain
#include "OpcodeSupport.h"      // abiWidthFromType
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

namespace {

// The fully-lowered handles of one break body, re-derived by a structural scan of
// the proven single-block body (the recognizer + `emitBreakForward` guaranteed the
// shape: one in-place rail gate chain, a tainted break-cond template chain, nothing
// else tainted). The region's `Loop *L` / `BreakFlag` / `EscapePhi` are STALE
// post-lowering (RAUW'd + erased); the scan recovers the surviving i32 handles.
struct LoweredBreak {
  Value *RailHandle = nullptr;            // the in-place rail gate's arg-0 handle
  SmallVector<CallInst *, 4> RailGates;   // the cqrt_{xorc,addc} rail self-updates (program order)
  SmallVector<CallInst *, 4> BreakCond;   // the tainted break-cond template chain (program order)
  CallInst *Brk = nullptr;                // the break-flag compare (the chain's compare result)
};

bool isInPlaceRailGate(const CallInst *CI) {
  const Function *F = CI->getCalledFunction();
  if (!F)
    return false;
  StringRef N = F->getName();
  return (N.starts_with("cqrt_xorc_") || N.starts_with("cqrt_addc_")) &&
         CI->arg_size() == 2;
}

bool isBreakCondTemplate(const CallInst *CI, const TaintSet &taint) {
  const Function *F = CI->getCalledFunction();
  if (!F)
    return false;
  return F->getName().starts_with("cq_template_") &&
         !F->getName().contains("_controlled") &&
         !F->getName().ends_with("_unc") &&
         taint.Tainted.count(const_cast<CallInst *>(CI));
}

bool isCompareTemplate(const CallInst *CI) {
  const Function *F = CI->getCalledFunction();
  StringRef N = F ? F->getName() : StringRef();
  return N.starts_with("cq_template_icmp_") || N.starts_with("cq_template_fcmp_");
}

bool discoverLoweredBreak(BasicBlock *Body, const TaintSet &taint,
                          LoweredBreak &LB) {
  for (Instruction &I : *Body) {
    auto *CI = dyn_cast<CallInst>(&I);
    if (!CI)
      continue;
    if (isInPlaceRailGate(CI)) {
      Value *H = CI->getArgOperand(0);
      if (LB.RailHandle && LB.RailHandle != H)
        return false;  // two distinct rail handles — off-shape.
      LB.RailHandle = H;
      LB.RailGates.push_back(CI);
    } else if (isBreakCondTemplate(CI, taint)) {
      LB.BreakCond.push_back(CI);
      if (isCompareTemplate(CI)) {
        if (LB.Brk)
          return false;  // >1 tainted compare in the body — the single break-flag
                         // invariant (the recognizer's single-tainted-disjunct
                         // partition + E9 lineage walk) is violated; bail rather
                         // than mis-pick the capture control (made load-bearing,
                         // not assumed — the Rule-13 review 2026-06-26).
        LB.Brk = CI;
      }
    }
  }
  // Exactly one compare (the break flag); the chain ends at it.
  return LB.RailHandle && LB.Brk && !LB.RailGates.empty();
}

// ── Gate-emission helpers (all VOID side-effecting `cqrt_*` / `cq_template_*`) ──

CallInst *mintCall(IRBuilder<> &B, FunctionCallee Fn, ArrayRef<Value *> Args,
                   DebugLoc DL, const Twine &Name = "") {
  CallInst *C = B.CreateCall(Fn, Args, Name);
  if (DL)
    C->setDebugLoc(DL);
  return C;
}

FunctionCallee toffoliFn(Module &M) {
  Type *I32 = Type::getInt32Ty(M.getContext());
  return M.getOrInsertFunction(
      "cqrt_toffoli",
      FunctionType::get(Type::getVoidTy(M.getContext()), {I32, I32, I32}, false));
}
FunctionCallee cnotFn(Module &M) {
  Type *I32 = Type::getInt32Ty(M.getContext());
  return M.getOrInsertFunction(
      "cqrt_cnot",
      FunctionType::get(Type::getVoidTy(M.getContext()), {I32, I32}, false));
}

// `flag = (idxHandle == 0)` — a fresh i32 eq-flag (`cq_template_icmp_eq_<W>_hl`).
CallInst *emitEqZero(IRBuilder<> &B, WidthDispatch &wd, Value *IdxHandle,
                     StringRef W, DebugLoc DL) {
  FunctionCallee F = wd.compareTemplateFn("icmp", "eq", W, Shape::HL);
  Type *Lit = wd.llvmWidthType(W);
  return mintCall(B, F, {IdxHandle, ConstantInt::get(Lit, 0)}, DL, "cq.brk.eqz");
}

// Clear a flag/template result minted by `Fwd`: emit its void `_unc` (zero it in
// place by recomputing from the live sources) then `cqrt_free` it.
void clearAndFree(IRBuilder<> &B, CallInst *Fwd, WidthDispatch &wd, DebugLoc DL) {
  emitInverseCall(B, Fwd, wd, /*CurHandle=*/nullptr);
  mintCall(B, wd.freeFn(), {Fwd}, DL);
}

// Clone the break-cond template chain at `B`'s position, remapping each link's
// operands to the cloned predecessors (the rail handle stays — it is the same
// loop-invariant i32). Returns the cloned chain (program order); the last is the
// recomputed break flag.
SmallVector<CallInst *, 4> cloneBreakCond(IRBuilder<> &B,
                                          ArrayRef<CallInst *> Chain) {
  DenseMap<Value *, Value *> VMap;
  SmallVector<CallInst *, 4> Out;
  for (CallInst *C : Chain) {
    auto *NC = cast<CallInst>(C->clone());
    B.Insert(NC);
    for (unsigned i = 0; i < NC->arg_size(); ++i) {
      auto It = VMap.find(NC->getArgOperand(i));
      if (It != VMap.end())
        NC->setArgOperand(i, It->second);
    }
    VMap[C] = NC;
    Out.push_back(NC);
  }
  return Out;
}

// The break-emission context — the lowered handles + the symbols + the widths.
struct BreakEmit {
  Module &M;
  WidthDispatch &wd;
  TaintSet &taint;
  ControlledSymbols csyms;
  LoweredBreak LB;
  Value *Rail;     // the in-place rail handle (i32)
  Value *R;        // capture register
  Value *Idx;      // first-break index
  Value *Out;      // escaping answer
  StringRef RW;    // rail ABI width
  StringRef IW;    // idx/counter ABI width
  Type *IdxLogTy;  // the counter logical type (for the `i+1` immediate)
  DebugLoc DL;

  FunctionCallee copyCtrlR() { return csyms.copyControlledFn(RW); }
  FunctionCallee copyCtrlIdx() { return csyms.copyControlledFn(IW); }
  FunctionCallee allocIdx() { return wd.allocFn(IW); }
  FunctionCallee addcIdx() { return wd.addcFn(IW); }

  // fire-controlled XOR of the rail into R (capture / un-capture; self-inverse).
  void captureRailToR(IRBuilder<> &B, Value *Fire) {
    mintCall(B, copyCtrlR(), {Fire, Rail, R}, DL);
  }
};

// Emit `g = (idx == K)` into a fresh flag and XOR it into `Fire` (a `cqrt_cnot`),
// then uncompute + free `g` and restore `idx`. `K` is a runtime classical value;
// the comparison is `(idx - K) == 0` bracketed so `idx` is restored. Used by BOTH
// the forward fire-clear (so `fire`→0 after the idx-write) and the backward
// fire-set (so `fire`→(idx==K) before the un-capture) — it is its own inverse.
void xorEqKIntoFire(IRBuilder<> &B, BreakEmit &E, Value *Fire, Value *K) {
  Value *NegK = B.CreateNeg(K, "cq.brk.negk");
  mintCall(B, E.addcIdx(), {E.Idx, NegK}, E.DL);     // idx -= K
  CallInst *G = emitEqZero(B, E.wd, E.Idx, E.IW, E.DL);  // g = (idx-K == 0) = (idx==K)
  mintCall(B, cnotFn(E.M), {G, Fire}, E.DL);         // fire ^= g
  clearAndFree(B, G, E.wd, E.DL);                    // g -> 0, free
  mintCall(B, E.addcIdx(), {E.Idx, K}, E.DL);        // idx += K  (restore)
}

// ── (a) FORWARD CAPTURE — emitted into the loop body, after the break-cond ─────
// Inserts before the loop terminator (where `K = i+1` and `brk` are both live).
void emitForwardCapture(BreakEmit &E, Value *K) {
  BasicBlock *Body = E.LB.Brk->getParent();
  IRBuilder<> B(Body->getTerminator());

  // e = (idx == 0)  [not-yet-fired];  fire = brk ∧ e
  CallInst *Efl = emitEqZero(B, E.wd, E.Idx, E.IW, E.DL);
  CallInst *Fire = mintCall(B, E.wd.allocFn("i1"),
                            {ConstantInt::getFalse(E.M.getContext())}, E.DL,
                            "cq.brk.fire");
  mintCall(B, toffoliFn(E.M), {E.LB.Brk, Efl, Fire}, E.DL);

  // CAPTURE (copy, not move): R ^= fire ? rail : 0  — rail left INTACT.
  E.captureRailToR(B, Fire);

  // clear e BEFORE the idx-write (idx still old) — then free it.
  clearAndFree(B, Efl, E.wd, E.DL);

  // IDX-WRITE: idx ^= fire ? (i+1) : 0  via a materialised `K` register.
  CallInst *Ip1 = mintCall(B, E.allocIdx(), {K}, E.DL, "cq.brk.k");
  mintCall(B, E.copyCtrlIdx(), {Fire, Ip1, E.Idx}, E.DL);
  Value *NegK = B.CreateNeg(K, "cq.brk.negk");
  mintCall(B, E.addcIdx(), {Ip1, NegK}, E.DL);  // unload Ip1 -> 0
  mintCall(B, E.wd.freeFn(), {Ip1}, E.DL);

  // clear fire via (idx == i+1) (true iff this iteration first fired), then free.
  xorEqKIntoFire(B, E, Fire, K);
  mintCall(B, E.wd.freeFn(), {Fire}, E.DL);

  // clear the break-cond IN-ITERATION (rail intact ⇒ recompute-and-XOR), free it.
  emitInverseChain(B, E.LB.BreakCond, E.wd);
  for (CallInst *C : E.LB.BreakCond)
    mintCall(B, E.wd.freeFn(), {C}, E.DL);

  // The eq-flags / fire / Ip1 are pass-invented scratch already freed; the
  // capture's controlled copies act on the excluded R/idx/rail.
}

// ── (b) EXIT CONSOLIDATION + COPY-OUT + CONSOLIDATION-REVERSE ───────────────────
// Emitted at the top of the loop-exit block (before the measure of `out`).
//   never-broke branches (idx==0): R ^= rail_final  ⇒ R holds the full-trip value;
//   out ^= R (the basis copy-out);  then UNDO the consolidation (it pairs with the
//   reverse-play, which un-captures the FIRED branches and walks the rail back).
void emitExitConsolidation(BreakEmit &E, BasicBlock *ExitBlk) {
  IRBuilder<> B(&*ExitBlk->getFirstInsertionPt());
  // consolidate
  CallInst *E0 = emitEqZero(B, E.wd, E.Idx, E.IW, E.DL);
  mintCall(B, E.copyCtrlR(), {E0, E.Rail, E.R}, E.DL);
  clearAndFree(B, E0, E.wd, E.DL);
  // copy out:  out ^= R
  mintCall(B, E.wd.copyFn(E.RW), {E.R, E.Out}, E.DL);
  // consolidation REVERSE (self-inverse — pairs with the above; the reverse-play
  // companion loop then un-captures the fired branches + walks the rail back).
  CallInst *E0b = emitEqZero(B, E.wd, E.Idx, E.IW, E.DL);
  mintCall(B, E.copyCtrlR(), {E0b, E.Rail, E.R}, E.DL);
  clearAndFree(B, E0b, E.wd, E.DL);
}

// ── (c) the BACKWARD iteration body `C†` (self-contained; counter `i'`) ────────
// Reverses the forward capture `C` AND the rail mutation, for one iteration, using
// the backward counter `IPrime` (so `K = i'+1`). `Rail` holds `r_{i'}` on entry.
void emitBackwardBody(BreakEmit &E, IRBuilder<> &B, Value *IPrime) {
  Value *One = ConstantInt::get(E.IdxLogTy, 1);
  Value *K = B.CreateAdd(IPrime, One, "cq.brk.kp");  // K = i'+1

  // set fire = (idx == K)  [the POST-capture control ≡ forward `fire`]
  CallInst *Fire = mintCall(B, E.wd.allocFn("i1"),
                            {ConstantInt::getFalse(E.M.getContext())}, E.DL,
                            "cq.brk.fire");
  xorEqKIntoFire(B, E, Fire, K);

  // un-write idx: idx ^= fire ? K : 0  (idx → its pre-fire value)
  CallInst *Ip1 = mintCall(B, E.allocIdx(), {K}, E.DL, "cq.brk.k");
  mintCall(B, E.copyCtrlIdx(), {Fire, Ip1, E.Idx}, E.DL);
  Value *NegK = B.CreateNeg(K, "cq.brk.negk");
  mintCall(B, E.addcIdx(), {Ip1, NegK}, E.DL);  // unload Ip1
  mintCall(B, E.wd.freeFn(), {Ip1}, E.DL);

  // un-capture R: R ^= fire ? rail : 0
  E.captureRailToR(B, Fire);

  // recompute e = (idx == 0) (idx now pre-fire) and the break-cond, then uncompute
  // fire via the SAME Toffoli `fire ^= brk' ∧ e` (≡ forward) ⇒ fire → 0.
  CallInst *Efl = emitEqZero(B, E.wd, E.Idx, E.IW, E.DL);
  SmallVector<CallInst *, 4> Cond = cloneBreakCond(B, E.LB.BreakCond);
  CallInst *BrkP = Cond.back();
  mintCall(B, toffoliFn(E.M), {BrkP, Efl, Fire}, E.DL);
  // clear the recomputed break-cond + e, free everything.
  emitInverseChain(B, Cond, E.wd);
  for (CallInst *C : Cond)
    mintCall(B, E.wd.freeFn(), {C}, E.DL);
  clearAndFree(B, Efl, E.wd, E.DL);
  mintCall(B, E.wd.freeFn(), {Fire}, E.DL);

  // rail-mut INVERSE (xorc self-inverse / addc immediate-negate), reverse order.
  for (CallInst *G : reverse(E.LB.RailGates))
    emitInverseCall(B, G, E.wd, /*CurHandle=*/nullptr);
}

void emitOneBreak(LoopBreakRegion &Rgn, Module &M, WidthDispatch &wd,
                  TaintSet &taint) {
  BasicBlock *Body = Rgn.Header;  // canonical single-block loop (header == latch).
  LoweredBreak LB;
  if (!discoverLoweredBreak(Body, taint, LB)) {
    // DEFENSE-IN-DEPTH (Prime Directive — never silently wrong): `emitBreakForward`
    // already RAUW'd the exit phi to `out` (|0>) and stripped the terminator, so a
    // SILENT return here would leave `out` = |0> (a wrong answer). E11 (body
    // coverage, LoopLowering.cpp) makes this RARE — but it IS reachable: a break-cond
    // lineage with TWO compares (`%c1 = icmp …; %z = zext %c1; %brk = icmp eq %z,0`)
    // passes E11 (both compares are break-cond ops) yet lowers to two
    // `cq_template_icmp` templates, tripping `discoverLoweredBreak`'s single-compare
    // invariant. So if the re-scan fails, fail LOUD (`opt` exits non-zero) rather than
    // emit a wrong unitary (the Rule-13 reviews 2026-06-26).
    if (auto *OR = dyn_cast<Instruction>(Rgn.OutReg))
      OR->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
          *OR->getFunction(),
          "cq loop lowering: break reverse-play could not re-derive the lowered body",
          OR->getDebugLoc()));
    return;
  }

  // Exclude the whole break construct from the whole-DAG uncompute spine.
  taint.ControlOwnedRails.insert(LB.RailHandle);
  for (CallInst *C : LB.BreakCond)
    taint.ControlOwnedRails.insert(C);

  BreakEmit E{M,          wd,        taint, ControlledSymbols(M, wd),
              LB,         LB.RailHandle, Rgn.RReg, Rgn.IdxReg,
              Rgn.OutReg, Rgn.RailWidth, Rgn.IdxWidth,
              wd.llvmWidthType(Rgn.IdxWidth), Body->getTerminator()->getDebugLoc()};

  // K = i+1 = the counter's latch-incoming (`i.next`), live at the terminator.
  Value *K = Rgn.CounterPhi->getIncomingValueForBlock(Body);

  // (a) forward capture.
  emitForwardCapture(E, K);

  // (b) exit consolidation + copy-out, at the loop-exit block. Capture the split
  // point (the FIRST original instruction — the measure of `out`) BEFORE emitting
  // the consolidation, so the consolidation/copy-out/reverse stay in the exit head
  // and the split cleaves only the measure into the tail.
  BasicBlock *ExitBlk = Rgn.ExitMerge;
  Instruction *SplitAt = &*ExitBlk->getFirstInsertionPt();
  emitExitConsolidation(E, ExitBlk);

  // (c) the backward reverse-play companion loop. Split the exit block AFTER the
  // consolidation/copy-out; insert a guarded backward loop counting `i' = n-1 … 0`
  // (the SAME classical `n = BoundLimit` the forward loop ran), then free R/idx.
  BasicBlock *ExitTail = ExitBlk->splitBasicBlock(SplitAt, "cq.brk.tail");
  BasicBlock *RevBody =
      BasicBlock::Create(M.getContext(), "cq.brk.rev", ExitBlk->getParent(), ExitTail);

  Value *N = Rgn.BoundLimit;
  Type *IdxLog = E.IdxLogTy;
  // Replace the unconditional ExitBlk→ExitTail branch with the backward loop guard.
  // REUSE the forward loop's zero-trip entry guard (`Rgn.GuardCond`) so the backward
  // loop enters iff the forward did — for ANY bound signedness (a re-invented signed
  // `sgt(n,0)` would skip the reverse-play for an unsigned `n ≥ 2^31`, leaving R/idx
  // dirty at `cqrt_free`; the Rule-13 FINAL finding). `GuardCond` is loop-invariant
  // (it dominates the exit, hence this block).
  {
    IRBuilder<> GB(ExitBlk->getTerminator());
    Value *Guard = Rgn.GuardLoopOnTrue ? Rgn.GuardCond
                                       : GB.CreateNot(Rgn.GuardCond, "cq.brk.guard");
    GB.CreateCondBr(Guard, RevBody, ExitTail);
    ExitBlk->getTerminator()->eraseFromParent();  // drop the old uncond br.
  }
  // RevBody: i' = phi [n-1, ExitBlk], [i'-1, RevBody]; <C†>; br (i' != 0).
  IRBuilder<> RB(RevBody);
  PHINode *IPrime = RB.CreatePHI(IdxLog, 2, "cq.brk.ip");
  Value *NMinus1 = BinaryOperator::CreateSub(
      N, ConstantInt::get(IdxLog, 1), "cq.brk.n1", ExitBlk->getTerminator());
  IPrime->addIncoming(NMinus1, ExitBlk);
  emitBackwardBody(E, RB, IPrime);
  Value *IDec = RB.CreateSub(IPrime, ConstantInt::get(IdxLog, 1), "cq.brk.ipdec");
  IPrime->addIncoming(IDec, RevBody);
  Value *More = RB.CreateICmpNE(IPrime, ConstantInt::get(IdxLog, 0), "cq.brk.more");
  RB.CreateCondBr(More, RevBody, ExitTail);

  // Free R / idx (now provably |0>) at the head of the exit tail, after the
  // reverse-play. The rail is left allocated at its pre-loop state (a dirty rail
  // is never freed — Rule 6); `out` escapes via the measure.
  IRBuilder<> TB(&*ExitTail->getFirstInsertionPt());
  mintCall(TB, wd.freeFn(), {E.R}, E.DL);
  mintCall(TB, wd.freeFn(), {E.Idx}, E.DL);
}

}  // namespace

void lowerBreakReversePlay(Module &M, WidthDispatch &wd, TaintSet &taint) {
  for (LoopBreakRegion &Rgn : taint.BreakRegions)
    emitOneBreak(Rgn, M, wd, taint);
}

}  // namespace cq
