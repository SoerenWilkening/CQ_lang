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
//
// INVERTIBILITY (bd test_C_libtooling-zea5). Every call this module adjoints is
// PRE-SCANNED with `isInverseEmittable` in `emitOneBreak`, BEFORE the first gate is
// emitted — the same WI-5 treatment the whole-DAG driver got (`Uncomputation.cpp`,
// PRD §2.12) and `emitBennettWrap` step (a). An un-invertible link declines LOUDLY
// (`kMsgBreakUninvertible`, `opt` exits non-zero) and emits NOTHING.
//
// Before that scan this module reproduced the exact PRE-WI-5 defect
// `lowering_uncompute_uninvertible.ll` documents: `emitInverseChain`'s un-invertible
// `false` was DISCARDED and the `cqrt_free` of every chain member was emitted anyway
// — a hardware reset of an un-reversed, still-entangled rail, i.e. a hidden
// projective collapse (Rules 5/6/8). MEASURED on `lowering_reject_break_-
// uninvertible_cond.ll`: `opt` rc=0, `opt -verify` clean, the compare's `_unc`
// emitted while the un-invertible link's was not (a genuinely half-reversed chain),
// and both members freed — in the forward body AND again in the backward companion
// loop. Stage 2b cannot substitute for this gate: it reports the rails UNPROVEN, and
// the loop-break slices necessarily run `--allow-unproven` (the whole-loop
// reverse-play is a Bennett recompute whose write history crosses a back edge), so
// the checker exits 0 on the broken module — as it does on the correct one.
//
// Soundness previously rested on an UNWRITTEN property of the discovery predicates,
// and the gap was real: `isBreakCondTemplate` accepts a `cq_template_…_inv` call (it
// excludes only `_controlled` / `_unc`) that `isInverseEmittable` REJECTS — the same
// two-predicates-one-gate class as bd uow0 / 1fim.
//
// THE PREDICATES STAY ASYMMETRIC ON PURPOSE — but they are INCOMPARABLE, NOT NESTED,
// and getting that backwards is how the next defect stays hidden. Along `_inv`
// discovery is WIDER, which is why collecting-then-declining is the right call here:
// the fix does NOT teach `isBreakCondTemplate` to skip `_inv`, because an uncollected
// link gets neither an adjoint nor a diagnostic, whereas a collected one declines
// loudly and source-located.
//
// Along OTHER axes discovery is NARROWER, and that direction is a live PRE-EXISTING
// defect this pre-scan structurally CANNOT reach (bd test_C_libtooling-9g9n — filed,
// not fixed here). `isInverseEmittable` ACCEPTS a specialization-clone call
// `@__cq_q_*` (EmitInverse.cpp, the Phase-6.3 clause); `isBreakCondTemplate` requires
// the `cq_template_` prefix and rejects it. `discoverLoweredBreak` returns true
// anyway (it asks only for a rail handle plus one compare), so `cloneBreakCond` emits
// a backward companion chain that still names the FORWARD body's SSA value.
// MEASURED, from five lines of ordinary C (a `__attribute__((noinline))` pure helper
// in the break condition, specialized by Phase 6): `opt` prints "Instruction does not
// dominate all uses!" and dies with "LLVM ERROR: Broken module found", rc=134 — NOT a
// source-located decline. The same shape reaches it through any producer minted into
// the body AFTER `LoopLowering`'s E11 coverage check ran (e.g. a 4.4 select-merge
// rail). E9's own comment names this exact failure mode as the thing it prevents; it
// bails on an UNTAINTED body operand and waves TAINTED ones through, which is sound
// only if every tainted break-cond op is later cloned — and `isBreakCondTemplate` is
// narrower than "tainted", so that premise does not hold.
//
// AND CORRECT THE OBVIOUS-SOUNDING RATIONALE, because the comfortable version is
// false: a skipped link does NOT produce a silent dirty free. Its rail is left
// ALLOCATED (the sanctioned Rule-6 fallback), and the observable outcome is the
// broken-module abort above. The reason to keep discovery wide-and-declining is the
// DIAGNOSTIC, not a dirty free it averts.
//
// Every emission site ALSO checks its bool and suppresses the frees it owns
// (`clearAndFree` / `clearChainAndFree`, and the `OK` thread through to the
// `R`/`idx` frees). That is defense-in-depth — unreachable after the pre-scan, over
// the SAME predicate — mirroring `emitBennettWrap` step (d), and it must stay a
// runtime check, never an `assert`: the shipped build is `-DCMAKE_BUILD_TYPE=Release`.

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

// The two loud declines this stage owns. Both fire AFTER `emitBreakForward` has
// already RAUW'd the exit phi to `out` and stripped the loop terminator, so a
// SILENT return would leave a wrong answer behind — `opt` must exit non-zero.
constexpr char kMsgBreakRederive[] =
    "cq loop lowering: break reverse-play could not re-derive the lowered body";
constexpr char kMsgBreakUninvertible[] =
    "cq loop lowering: break reverse-play cannot invert a lowered body gate";

void diagnoseAt(Value *Where, StringRef Msg) {
  auto *I = dyn_cast_or_null<Instruction>(Where);
  if (!I)
    return;
  I->getFunction()->getContext().diagnose(
      DiagnosticInfoUnsupported(*I->getFunction(), Msg, I->getDebugLoc()));
}

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
//
// THE FREE IS CONDITIONAL ON THE ADJOINT (bd zea5). `emitInverseCall` returns false
// for a callee outside `isInverseEmittable`'s set; freeing then resets a rail no
// adjoint ever zeroed — a hidden projective collapse (Rule 6), not a lifetime op.
// Returns the adjoint's verdict; the caller propagates it to the loud decline.
[[nodiscard]] bool clearAndFree(IRBuilder<> &B, CallInst *Fwd, WidthDispatch &wd,
                                DebugLoc DL) {
  if (!emitInverseCall(B, Fwd, wd, /*CurHandle=*/nullptr))
    return false;
  mintCall(B, wd.freeFn(), {Fwd}, DL);
  return true;
}

// Clear a whole forward chain (reverse-program-order void `_unc`) and free every
// member — the frees ONLY if the WHOLE chain inverted (bd zea5). `emitInverseChain`
// ANDs its per-link results and emits the adjoints it CAN, so a partial `false` is
// a genuinely half-reversed chain: the surviving members were recomputed from
// sources no longer holding their forward values, and freeing them is unsound too.
// Returns the chain's verdict.
[[nodiscard]] bool clearChainAndFree(IRBuilder<> &B, ArrayRef<CallInst *> Chain,
                                     WidthDispatch &wd, DebugLoc DL) {
  if (!emitInverseChain(B, Chain, wd))
    return false;
  for (CallInst *C : Chain)
    mintCall(B, wd.freeFn(), {C}, DL);
  return true;
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
// Returns `g`'s clear verdict (`g` is this function's own `emitEqZero` compare, so
// false is unreachable — the bool is threaded, never discarded; bd zea5).
[[nodiscard]] bool xorEqKIntoFire(IRBuilder<> &B, BreakEmit &E, Value *Fire,
                                  Value *K) {
  Value *NegK = B.CreateNeg(K, "cq.brk.negk");
  mintCall(B, E.addcIdx(), {E.Idx, NegK}, E.DL);     // idx -= K
  CallInst *G = emitEqZero(B, E.wd, E.Idx, E.IW, E.DL);  // g = (idx-K == 0) = (idx==K)
  mintCall(B, cnotFn(E.M), {G, Fire}, E.DL);         // fire ^= g
  bool OK = clearAndFree(B, G, E.wd, E.DL);          // g -> 0, free
  mintCall(B, E.addcIdx(), {E.Idx, K}, E.DL);        // idx += K  (restore)
  return OK;
}

// ── (a) FORWARD CAPTURE — emitted into the loop body, after the break-cond ─────
// Inserts before the loop terminator (where `K = i+1` and `brk` are both live).
// Returns false iff some adjoint it owns was un-invertible (bd zea5) — every clear
// runs regardless (no `&&` short-circuit: skipping an emission would leave a
// DIFFERENT half-built construct), only the frees are suppressed, and the caller
// declines loudly.
[[nodiscard]] bool emitForwardCapture(BreakEmit &E, Value *K) {
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
  bool OK = clearAndFree(B, Efl, E.wd, E.DL);

  // IDX-WRITE: idx ^= fire ? (i+1) : 0  via a materialised `K` register.
  CallInst *Ip1 = mintCall(B, E.allocIdx(), {K}, E.DL, "cq.brk.k");
  mintCall(B, E.copyCtrlIdx(), {Fire, Ip1, E.Idx}, E.DL);
  Value *NegK = B.CreateNeg(K, "cq.brk.negk");
  mintCall(B, E.addcIdx(), {Ip1, NegK}, E.DL);  // unload Ip1 -> 0
  mintCall(B, E.wd.freeFn(), {Ip1}, E.DL);

  // clear fire via (idx == i+1) (true iff this iteration first fired), then free.
  // `fire` itself is this emitter's own `cqrt_alloc_i1` |0> ancilla returned to |0>
  // by the line above, so its free rides `OK` (never freed on a failed clear).
  bool FireOK = xorEqKIntoFire(B, E, Fire, K);
  OK = FireOK && OK;
  if (FireOK)
    mintCall(B, E.wd.freeFn(), {Fire}, E.DL);

  // clear the break-cond IN-ITERATION (rail intact ⇒ recompute-and-XOR), free it.
  OK = clearChainAndFree(B, E.LB.BreakCond, E.wd, E.DL) && OK;

  // The eq-flags / fire / Ip1 are pass-invented scratch already freed; the
  // capture's controlled copies act on the excluded R/idx/rail.
  return OK;
}

// ── (b) EXIT CONSOLIDATION + COPY-OUT + CONSOLIDATION-REVERSE ───────────────────
// Emitted at the top of the loop-exit block (before the measure of `out`).
//   never-broke branches (idx==0): R ^= rail_final  ⇒ R holds the full-trip value;
//   out ^= R (the basis copy-out);  then UNDO the consolidation (it pairs with the
//   reverse-play, which un-captures the FIRED branches and walks the rail back).
[[nodiscard]] bool emitExitConsolidation(BreakEmit &E, BasicBlock *ExitBlk) {
  IRBuilder<> B(&*ExitBlk->getFirstInsertionPt());
  // consolidate
  CallInst *E0 = emitEqZero(B, E.wd, E.Idx, E.IW, E.DL);
  mintCall(B, E.copyCtrlR(), {E0, E.Rail, E.R}, E.DL);
  bool OK = clearAndFree(B, E0, E.wd, E.DL);
  // copy out:  out ^= R
  mintCall(B, E.wd.copyFn(E.RW), {E.R, E.Out}, E.DL);
  // consolidation REVERSE (self-inverse — pairs with the above; the reverse-play
  // companion loop then un-captures the fired branches + walks the rail back).
  CallInst *E0b = emitEqZero(B, E.wd, E.Idx, E.IW, E.DL);
  mintCall(B, E.copyCtrlR(), {E0b, E.Rail, E.R}, E.DL);
  OK = clearAndFree(B, E0b, E.wd, E.DL) && OK;  // both clears run — no short-circuit.
  return OK;
}

// ── (c) the BACKWARD iteration body `C†` (self-contained; counter `i'`) ────────
// Reverses the forward capture `C` AND the rail mutation, for one iteration, using
// the backward counter `IPrime` (so `K = i'+1`). `Rail` holds `r_{i'}` on entry.
// Returns false iff some adjoint it owns was un-invertible (bd zea5). It still emits
// the full block either way — the caller has CFG surgery in flight and a bare early
// return here would leave a terminator-less block (a malformed module `opt -verify`
// rejects, which is a WORSE outcome than the loud decline the caller then renders).
[[nodiscard]] bool emitBackwardBody(BreakEmit &E, IRBuilder<> &B, Value *IPrime) {
  Value *One = ConstantInt::get(E.IdxLogTy, 1);
  Value *K = B.CreateAdd(IPrime, One, "cq.brk.kp");  // K = i'+1

  // set fire = (idx == K)  [the POST-capture control ≡ forward `fire`]
  CallInst *Fire = mintCall(B, E.wd.allocFn("i1"),
                            {ConstantInt::getFalse(E.M.getContext())}, E.DL,
                            "cq.brk.fire");
  bool OK = xorEqKIntoFire(B, E, Fire, K);

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
  // clear the recomputed break-cond + e, free everything. `Cond` is a CLONE of
  // `E.LB.BreakCond` — same callees, same arities — so the pre-scan of the original
  // covers it exactly (the clone is what makes that identity load-bearing).
  OK = clearChainAndFree(B, Cond, E.wd, E.DL) && OK;
  bool EflOK = clearAndFree(B, Efl, E.wd, E.DL);
  OK = EflOK && OK;
  // `fire` is |0> only once BOTH the recomputed-cond Toffoli above and the
  // `xorEqKIntoFire` set are accounted for; free it only on a clean sheet.
  if (OK)
    mintCall(B, E.wd.freeFn(), {Fire}, E.DL);

  // rail-mut INVERSE (xorc self-inverse / addc immediate-negate), reverse order.
  // No free here — the rail is left allocated at its pre-loop state (Rule 6) — but
  // a failure still poisons `OK`: an un-walked rail makes the caller's R/idx frees
  // dirty, which is precisely the free this bead is about.
  for (CallInst *G : reverse(E.LB.RailGates))
    OK = emitInverseCall(B, G, E.wd, /*CurHandle=*/nullptr) && OK;
  return OK;
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
    diagnoseAt(Rgn.OutReg, kMsgBreakRederive);
    return;
  }

  // ── INVERTIBILITY PRE-SCAN (bd zea5; the WI-5 treatment, PRD §2.12/§2.10) ────
  // Every call this stage will adjoint, checked with the CANONICAL accept predicate
  // BEFORE the first gate is emitted — so an un-invertible link yields NO
  // half-reversed chain and, above all, NO free of a rail no adjoint zeroed. Both
  // discovered sets are scanned even though each is currently a subset of
  // `isInverseEmittable` by construction (`isInPlaceRailGate` re-spells that
  // predicate's xorc/addc clause; `isBreakCondTemplate` is WIDER — it admits the
  // `_inv` twin). Resting on that census is exactly what bd uow0 / 8gi5 / e4zs /
  // 1fim each proved unsafe: this scan is the mechanical statement of it, and it
  // stays correct if either discovery predicate is later widened.
  // `E.LB.BreakCond` is also cloned verbatim into the backward companion loop
  // (`cloneBreakCond` copies callee and arity), so scanning the original covers the
  // clone; `emitBackwardBody` re-states that identity at the use.
  for (CallInst *G : LB.RailGates)
    if (!isInverseEmittable(G)) {
      diagnoseAt(G, kMsgBreakUninvertible);
      return;
    }
  for (CallInst *G : LB.BreakCond)
    if (!isInverseEmittable(G)) {
      diagnoseAt(G, kMsgBreakUninvertible);
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

  // (a) forward capture. `OK` accumulates the DEFENSE-IN-DEPTH verdict of every
  // adjoint the three stages emit — unreachable-false after the pre-scan above (same
  // predicate), and a runtime check rather than an `assert` because the shipped build
  // is Release. On false the construct is finished structurally (so the module stays
  // well-formed for `opt -verify`) but NOTHING is freed and the stage declines loudly.
  bool OK = emitForwardCapture(E, K);

  // (b) exit consolidation + copy-out, at the loop-exit block. Capture the split
  // point (the FIRST original instruction — the measure of `out`) BEFORE emitting
  // the consolidation, so the consolidation/copy-out/reverse stay in the exit head
  // and the split cleaves only the measure into the tail.
  BasicBlock *ExitBlk = Rgn.ExitMerge;
  Instruction *SplitAt = &*ExitBlk->getFirstInsertionPt();
  OK = emitExitConsolidation(E, ExitBlk) && OK;

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
  OK = emitBackwardBody(E, RB, IPrime) && OK;
  Value *IDec = RB.CreateSub(IPrime, ConstantInt::get(IdxLog, 1), "cq.brk.ipdec");
  IPrime->addIncoming(IDec, RevBody);
  Value *More = RB.CreateICmpNE(IPrime, ConstantInt::get(IdxLog, 0), "cq.brk.more");
  RB.CreateCondBr(More, RevBody, ExitTail);

  // Free R / idx (now provably |0>) at the head of the exit tail, after the
  // reverse-play. The rail is left allocated at its pre-loop state (a dirty rail
  // is never freed — Rule 6); `out` escapes via the measure.
  //
  // R IS RECORDED ONTO A CARRIER THIS REVERSAL NEVER TOUCHES — `cqrt_copy_i32(R,
  // out)` in the exit consolidation above — and `out` can then be TAPED (measured:
  // a break loop followed by a `printf` compiles rc=0 and ends
  // `free(R); free(idx); cqrt_tape_write_i32(tape, out)`). So the bd 261j(a) record
  // invariant applies here (bd memory [record-freeze-invariant-2026-08-10]), and
  // the free is sound for a REASON, not by accident of ordering — bd urlv proposed
  // "sound only because the frees precede the record", which is the wrong way round
  // and is not what makes it work:
  //
  //   R is a BENNETT SCRATCH. It is allocated at |0> by this emitter, is written
  //   ONLY by `cqrt_copy_i32_controlled` (a basis permutation conditioned on
  //   h/idx/fire), is copied out, and is then returned to |0> by the EXACT adjoint
  //   replay this function emits — invariant clauses (a)-(d), with (b) holding
  //   because W contains no rotation. `idx` is the same shape (`cqrt_addc`/
  //   controlled copies). The 261j defect needed a recorded `cqrt_ry` rail, whose
  //   cond(W) is EMPTY and which is not trivial on |0>.
  //
  // THE TRIPWIRE, since this is an analytic argument and not a mechanical one:
  // stage 2b cannot prove it (`UNPROVEN U1-cross-stream` — the write history
  // crosses a back edge), which is why the loop-break slices carry the documented
  // `--allow-unproven` waiver. A ROTATION reaching R would break the argument. R is
  // emitter-minted and unnameable from source, so no user program can put one
  // there; a widening of the capture path could. Re-run this entry if you touch it.
  //
  // AND THE ARGUMENT'S PRECONDITION IS `OK` (bd zea5): "returned to |0> by the EXACT
  // adjoint replay this function emits" is FALSE the moment one of those adjoints was
  // not emitted. So a failed replay suppresses BOTH frees and declines loudly —
  // R/idx are left allocated (the Rule-6 fallback for a rail not provably |0>), never
  // reset dirty. Unreachable after the pre-scan; the check is what makes it a
  // property rather than a census.
  if (!OK) {
    diagnoseAt(Rgn.OutReg, kMsgBreakUninvertible);
    return;
  }
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
