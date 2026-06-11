// SwapRouteEmit.cpp — see header. The mutating swap-route emitter for accepted
// regions. PHASE arms — a one-content-arm diamond (§5a) or a two-arm if/else
// (§5b), lowered by one arm-list-parameterized procedure — emit the coherent,
// zero-controlled-gate routed stream of SCOPING §3a in the §5 contract order
// (an if/else routes BOTH arms to distinct rails, the else under ¬flag via the
// cqrt_x bracket), then rewire + flatten. VALUE arms (4.2, one-content-arm
// DIAMOND only until WI-5) lower by method-B B-keep (§5d): route + verbatim
// chain replay + copy-out + reverse-play R† — see emitValueDiamond.
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2):
//   `(|0> + |1>)/√2 ⊗ |0>_f` ─route+Rz+route→ `(|0>|0>_f + e^{iθ}|1>|1>_f)/√2`
//   ─icmp_inv(q)→ `(|0> + e^{iθ}|1>)/√2 ⊗ |0>_f`: the rail returns to |0>
//   UNCONDITIONALLY (Rz|0>=|0>), q keeps the conditional phase, and the flag is
//   stripped because Rz preserves q's basis value (q == q0). Zero `_controlled`
//   gates, no added measurement (SCOPING §3a/§3b). The value-arm trace is at
//   emitValueDiamond (PRD Part II §8.2).

#include "SwapRouteEmit.h"

#include "ArithLowering.h"       // rewriteBinary (the value-arm chain body, §4)
#include "CompareLowering.h"     // lowerCompareToFlag
#include "ControlPlan.h"         // ControlRegion / ControlPlan
#include "ControlledSymbols.h"   // cswapFn / xFn
#include "EmitInverse.h"         // emitInverseChain (the value-arm reverse-play)
#include "OpcodeSupport.h"       // abiWidthFromType (value-arm rail width)
#include "RegionFlatten.h"       // flattenRegion
#include "TaintPropagation.h"    // TaintSet
#include "WidthDispatch.h"       // allocFn / copyFn / rzRtFn / freeFn / abiWidthFor

#include "llvm/ADT/STLExtras.h"   // llvm::reverse
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// so a later module walk (`lowerRotations` / `lowerOps` / `uncompute`) never
// dereferences freed memory (§6.1 — the dangling-work-list SIGSEGV). A per-TU
// mirror of the same helper in RegionFlatten (the house style for trivial
// taint-set maintenance, cf. the duplicated `isMeasureSink`). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  // §6.1, grown at 4.2 WI-4: the value path erases arm `BinaryOperator`s,
  // which are in `declineStaleRecordOps`' purview — a stale member whose heap
  // address a later-minted instruction reuses would make `lowerOps`' skip
  // probe silently DROP that instruction's lowering (a false StaleDeclined
  // hit). Phase-path erasees are never members (cq_phi/phi/br/branch-feeding
  // compares are out of the stale guard's scope), so this stays idempotent.
  taint.StaleDeclined.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
  }
}

// The trailing suffix of a `<Prefix><sfx>` intrinsic callee (e.g. `si32` from
// `cq_phi_si32`), or "" if `V` is not such a call.
StringRef intrinsicSuffix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return {};
  const Function *F = CI->getCalledFunction();
  if (!F || !F->getName().starts_with(Prefix))
    return {};
  return F->getName().substr(Prefix.size());
}

bool isPhiCall(const Value *V) { return !intrinsicSuffix(V, "cq_phi_").empty(); }

// Walk the arm's merge contribution back along its IN-BLOCK phase spine,
// collecting the `@cq_phi` (Rz) calls DEFINED IN `ArmBB` in FORWARD program order
// (first gate applied first). The chain is `qN = cq_phi(q{N-1}, angle)`; the
// back-walk hops arg-0 handles, so reversing it yields forward order. An empty
// result means a degenerate gate-free arm (`if (q) {}` / an empty else) — handled
// by the caller.
//
// The walk STOPS at the arm-block boundary: a `cq_phi` defined OUTSIDE `ArmBB` is
// a pre-region rotation — the live DERIVED base handle the region ROUTES
// (accepted since test_C_libtooling-9hh), NOT an arm gate. It stays in
// `taint.PhiCalls`, so `lowerRotations` lowers it as an ordinary unconditional
// Rz at its own (pre-stream) position and RAUWs it to the same i32 handle as its
// theta. Bounding here is load-bearing (Rule 10): an unbounded walk would
// collect a pre-region phi SHARED by both arms once per arm, and the §6.1
// reverse-erase would double-free it (SIGSEGV — the WI-3 crash). Keeping the
// per-arm gate list strictly in-block makes that impossible.
SmallVector<CallInst *, 4> collectArmPhis(Value *ArmIncoming,
                                          const BasicBlock *ArmBB) {
  SmallVector<CallInst *, 4> Phis;
  for (Value *V = ArmIncoming; isPhiCall(V);) {
    auto *CI = cast<CallInst>(V);
    if (CI->getParent() != ArmBB)
      break;  // pre-region cq_phi — the derived base handle, not an arm gate.
    Phis.push_back(CI);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  std::reverse(Phis.begin(), Phis.end());
  return Phis;
}

// Emit the route swap `cqrt_cswap(flag, q, rail)`, X-bracketed for an ArmNegated
// (¬flag / FALSE-successor) arm: `cqrt_x(flag); cqrt_cswap(…); cqrt_x(flag)`.
// Used identically for the route-in (split) and the route-back (join = adjoint
// of the split, same flag) — that symmetry is the RSSA join-is-the-inverse-of-
// the-split property (SCOPING §2).
void emitRoute(IRBuilder<> &B, const ControlledSymbols &csyms, Value *Flag,
               Value *Q, Value *Rail, bool Negated, const DebugLoc &DL) {
  FunctionCallee Cswap = csyms.cswapFn();
  FunctionCallee X = csyms.xFn();
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };
  if (Negated)
    stamp(B.CreateCall(X, {Flag}));
  stamp(B.CreateCall(Cswap, {Flag, Q, Rail}));
  if (Negated)
    stamp(B.CreateCall(X, {Flag}));
}

// The value an arm's IN-BLOCK phase spine bottoms at — the routed base handle
// (the live quantum register the arm's gates rotate). For an if/else, which has
// no straight-through (Pred) merge edge, this recovers the routed handle
// `classifyArms` proved BOTH arms share; for a gate-free arm (`ArmIncoming` is the
// base itself) it returns that value unchanged. Bounded at the arm-block boundary
// for the same reason as `collectArmPhis`: a `cq_phi` defined OUTSIDE `ArmBB` is
// the live DERIVED base handle (route THIS), never hopped past to the theta.
Value *phaseSpineBase(Value *ArmIncoming, const BasicBlock *ArmBB) {
  Value *V = ArmIncoming;
  while (isPhiCall(V)) {
    auto *CI = cast<CallInst>(V);
    if (CI->getParent() != ArmBB)
      break;  // pre-region cq_phi — the live derived base handle.
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  return V;
}

// Lower one accepted VALUE-arm DIAMOND (4.2, method-B B-keep; IMPLEMENTATION-4.2
// §4, contract §5d) — emitted into the pred block before the conditional `br`,
// in this exact order (symbol order IS the contract; reordering steps 5–9 is
// trace-plausible, verify-clean, and WRONG):
//
//   1 flag mint        cq_template_icmp_<pred>_<W>_hl(q, lit)
//   2 |0> work rail    cqrt_alloc_<W>(0)        width from the chain op's iN type
//   3 route-in         cqrt_cswap(flag, p, rail)         [¬flag arm X-bracketed]
//   4 arm chain        VERBATIM + UNCONTROLLED on the rail — each link moved,
//                      base-retargeted (first link only), then rewriteBinary
//   5 route-back       cqrt_cswap(flag, p, chainFinal)   p := the muxed answer
//   6 copy-out         out = alloc(0); cqrt_copy_<W>(p, out) — AFTER route-back
//                      (the answer is on p only then), BEFORE route-back† (R†
//                      destroys it on p) — interlock §6.4
//   7 reverse-play R†  route-back† · chain adjoint (_inv twins, emitInverseChain,
//                      BODY CHAIN ONLY — the cswap arg-0 seam, PRD §8.5) · route-in†
//   8 rail free        on the FINAL threaded _inv handle (interlock §6.5) —
//                      provably |0> on BOTH branches only AFTER R† (§3b)
//   9 strip+flag free  icmp_inv(q) + cqrt_free(flag) — valid outright: the
//                      condition register is disjoint from the routed register
//                      in every accepted region (§0 criterion 4)
//  10 rewire           RAUW merge phi -> out; erase chain originals in reverse;
//                      flatten. NEVER free `out` (the answer) or `p` (the
//                      restored source) — either free is a hidden measurement.
//
// Correctness rests on the §8.2 register-threading trace, NOT on `opt -verify`
// (Rule 2): flag=1 routes p0 into the rail, the chain computes f(p0) there, the
// route-back parks f(p0) on p for the copy, and R† re-derives then unwinds the
// chain so p == p0 and rail == |0> again; flag=0 leaves p untouched while the
// chain computes f(0) garbage on the rail thread, which the chain adjoint
// returns to |0>. Both branches end rail == |0> (clean free, not a hidden
// measurement) and p == p0 (so icmp_inv strips the flag). The B-keep boundary
// (kept-source correlation, channels A/B) is documented in PRD §8.2 — binding,
// not a bug. NEVER this path for a phase arm (Rule 7): a CNOT copies a basis
// label, not a phase (verified P0 0.585 -> 0.500, fully dephased).
void emitValueDiamond(const ControlRegion &R, BranchInst *BI, CmpInst *Cond,
                      PHINode *MergePhi, Value *Q, WidthDispatch &wd,
                      ControlledSymbols &csyms, TaintSet &taint) {
  // ABI width from the chain op's INTEGER SSA type — reliable pre-RAUW (the
  // ops still carry iN; PRD §8.1 width-source). NEVER the theta suffix (the
  // routed base may be derived), and never a classifying signal (the f64
  // trap) — classifyArms' positive integer fence already proved validity, so
  // a null here is a malformed plan: decline LOUDLY, lower nothing (Rule 1).
  StringRef Abi = abiWidthFromType(R.Shadow.front()->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Copy = Abi.empty() ? FunctionCallee() : wd.copyFn(Abi);
  if (!RailTy || !Alloc || !Copy) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  // Library-host parity (the twin-pipeline trap, IMPLEMENTATION §6.5): a
  // chain link `declineStaleRecordOps` marked has ALREADY been diagnosed with
  // the pledge "lower NOTHING for this op" (lowerOps honors it by skipping).
  // In the `opt` host that DS_Error exited the process before emission ever
  // runs; in an embedding host that does not exit, replaying the marked link
  // onto the rail here would break the pledge. Decline pre-mutation — no lit
  // fixture can pin this (opt exits at the stale diagnostic first); it is the
  // Rule-1 defensive bail, never a silent skip.
  for (Instruction *Op : R.Shadow)
    if (taint.StaleDeclined.count(Op)) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }

  const DebugLoc DL = BI->getDebugLoc();
  IRBuilder<> B(BI);  // every stream call lands before the conditional br.
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // 1. Flag mint — cq_template_icmp_<pred>_<W>_hl(q, lit).
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).

  // 2. The |0> work rail. It joins `taint.Tainted` so rewriteBinary classifies
  //    the retargeted first link as HL/LH (handle + classical) — an untainted
  //    rail would misclassify BOTH operands as classical and emit a wrong
  //    shape. Its users are only cqrt_*/template calls, so the later
  //    `uncompute` never selects it (isTerminalHandle is false — §6.2).
  CallInst *Rail = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "rail");
  stamp(Rail);
  taint.Tainted.insert(Rail);

  // 3. Route-in (split) — p -> rail, X-bracketed for a ¬flag (FALSE-successor)
  //    arm (Rule 9 polarity rides R.ArmNegated).
  emitRoute(B, csyms, Flag, Q, Rail, R.ArmNegated, DL);

  // 4. Arm chain VERBATIM + UNCONTROLLED on the rail. Per link in FORWARD
  //    (base-first) order: move to the stream position, retarget the FIRST
  //    link's routed-base operand to the rail handle (later links already
  //    point at their predecessor, rewired by the previous RAUW), then REUSE
  //    ArithLowering::rewriteBinary verbatim — it emits the
  //    cq_template_<op>_<W>_hl/_lh call immediately before the moved op,
  //    RAUWs, and bookkeeps taint (Rule 14). The minted call is collected for
  //    the reverse-play; the original (now use-empty) op is erased in step 10.
  SmallVector<CallInst *, 6> Fwd;
  for (Instruction *Op : R.Shadow) {
    auto *BO = dyn_cast<BinaryOperator>(Op);
    if (!BO) {
      // classifyArms records only BinaryOperator links; anything else is a
      // malformed plan — decline LOUDLY, never a silent skip (Rule 1).
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
    BO->moveBefore(BI);
    if (Fwd.empty())
      BO->replaceUsesOfWith(Q, Rail);
    if (!rewriteBinary(BO, wd, taint))
      return;  // already diagnosed (no template) — abort the region loudly.
    // rewriteBinary inserts exactly ONE call, immediately before BO.
    Fwd.push_back(cast<CallInst>(BO->getPrevNode()));
  }

  // 5. Route-back (join = adjoint of the split, same flag + bracket) with the
  //    chain-final handle — the physical rail register's current SSA name.
  //    `p` now holds the muxed answer.
  Value *ChainFinal = Fwd.back();
  emitRoute(B, csyms, Flag, Q, ChainFinal, R.ArmNegated, DL);

  // 6. B-keep copy-out: out := the basis-valued answer. `out` joins
  //    `taint.Tainted` (+BirthOrder) so downstream consumers of the RAUW'd
  //    merge phi keep classifying it as a quantum handle. NEVER free `out`,
  //    NEVER free `p` (PRD §8.5 — the answer / the restored source; a free of
  //    either is a hidden measurement).
  CallInst *Out = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "out");
  stamp(Out);
  CallInst *CopyCall = B.CreateCall(Copy, {Q, Out});
  stamp(CopyCall);
  taint.Tainted.insert(Out);
  taint.BirthOrder[Out] = taint.NextBirth++;

  // 7. Reverse-play R†: route-back†, then the chain adjoint in exact reverse
  //    with `_inv` twins — the BODY CHAIN ONLY through emitInverseChain (the
  //    first real invocation, SCOPING §7.5): the route cswaps are bracketed by
  //    emitRoute because emitInverseCall threads the involution handle into
  //    Args[0], which for cqrt_cswap is the FLAG slot (the seam,
  //    EmitInverse.cpp — feeding cswaps through the chain is a verify-clean
  //    wrong unitary, PRD §8.5) — then route-in† with the THREADED handle.
  emitRoute(B, csyms, Flag, Q, ChainFinal, R.ArmNegated, DL);
  Value *RailFinal = emitInverseChain(B, Fwd, wd, csyms, /*Flag=*/nullptr,
                                      /*Terminal=*/ChainFinal);
  if (!RailFinal) {
    // Every link is a forward uncontrolled template (we just minted them), so
    // this is unreachable — but an un-invertible link must decline LOUDLY,
    // never leave a half-reversed stream (Rule 1).
    diagnoseUnderControl(Cond, "control flow");
    return;
  }
  emitRoute(B, csyms, Flag, Q, RailFinal, R.ArmNegated, DL);

  // 8. Rail free on the FINAL threaded handle — NOT the forward rail/chain
  //    handles (freeing a stale handle version is trace-plausible but wrong,
  //    interlock §6.5). Provably |0> on both branches only AFTER R† (§3b —
  //    earlier it is f(0)-vs-0 entangled with the flag: a dirty free is a
  //    hidden measurement).
  CallInst *RailFree = B.CreateCall(wd.freeFn(), {RailFinal});
  stamp(RailFree);

  // 9. Flag-strip + flag free. Valid outright: the condition register is
  //    disjoint from the routed register in every accepted region (§0
  //    criterion 4 via the diagonal-alias closure), so q == q0 at the strip.
  //    Reads `Cond`'s operands — MUST precede the erase of `Cond` (in
  //    flattenRegion). Do NOT hoist above step 7/8 (strip-after-R† is the
  //    documented order the accept class was cleared under).
  lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                     /*before=*/BI);
  CallInst *FlagFree = B.CreateCall(wd.freeFn(), {Flag});
  stamp(FlagFree);

  // 10. Rewire + erase + scrub + flatten. The measure on the phi becomes a
  //     measure on `out` (the copied answer). Erase the chain originals in
  //     REVERSE lineage order so each is use-empty when erased; scrub every
  //     erased instruction from all taint work-lists incl. StaleDeclined
  //     (§6.1).
  MergePhi->replaceAllUsesWith(Out);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  for (Instruction *Op : reverse(R.Shadow)) {
    scrubTaint(Op, taint);
    Op->eraseFromParent();
  }
  flattenRegion(R, taint);
}

// One content arm's routed phase stream: whether it fires on ¬flag (X-bracketed
// cswap) and its ordered Rz gates to replay verbatim on its own work rail.
struct ArmStream {
  bool Negated;
  SmallVector<CallInst *, 4> Phis;
};

// Lower one accepted phase-arm region — a one-content-arm DIAMOND (§5a) or a
// two-arm IF/ELSE (§5b) — to the coherent swap-route stream, emitted into the
// pred block before the conditional `br`. Both shapes share ONE emission
// procedure parameterized by the arm list: a diamond routes its single content
// arm (Q = the straight-through incoming); an if/else routes BOTH arms to
// DISTINCT |0> rails (Q = the shared phase-spine base), the true arm under flag
// and the false arm under ¬flag via the self-inverse `cqrt_x` bracket. The join
// is the literal adjoint of the split (the SAME cswap-pairs, same flag) — RSSA's
// "phi on both splits and joins" (SCOPING §2).
void emitRegion(const ControlRegion &R, WidthDispatch &wd,
                ControlledSymbols &csyms, TaintSet &taint) {
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  auto *MergePhi = dyn_cast_or_null<PHINode>(R.Merge);
  if (!Cond || !MergePhi || !R.Pred || !R.Arm) {
    // Detection guarantees the shape; if it ever fails to hold, bail LOUDLY — a
    // silently skipped accepted region leaves the tainted `br` to the backend
    // as classical control over quantum state (the unforgivable outcome,
    // Rule 1). Anchor on whatever instruction is still available.
    if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
      diagnoseUnderControl(A, "control flow");
    else if (R.Merge)
      diagnoseUnderControl(R.Merge, "control flow");
    return;
  }
  auto *BI = dyn_cast<BranchInst>(R.Pred->getTerminator());
  if (!BI) {
    diagnoseUnderControl(Cond, "control flow");  // loud, never a silent skip.
    return;
  }

  // Arm list + per-arm polarity. A diamond has one content arm whose polarity
  // rides `R.ArmNegated` (clang -O1 may make the gate arm the FALSE successor,
  // Rule 9). An if/else has two arms assigned by successor: `R.Arm` (S0) fires on
  // flag (unbracketed), `R.ArmFalse` (S1) on ¬flag (X-bracketed) — the flag
  // equals the live branch condition, so this holds under any predicate
  // canonicalization (clang may flip the predicate but the flag tracks it).
  struct ArmInfo {
    BasicBlock *BB;
    bool Negated;
  };
  SmallVector<ArmInfo, 2> Arms;
  if (R.ArmFalse) {
    Arms.push_back({R.Arm, /*Negated=*/false});
    Arms.push_back({R.ArmFalse, /*Negated=*/true});
  } else {
    Arms.push_back({R.Arm, R.ArmNegated});
  }

  // The routed handle Q: a diamond's straight-through (Pred-edge) incoming, or —
  // for an if/else, which has no Pred edge — the shared phase-spine base the arms
  // rotate. Never read width/identity off Q's SSA type (§4 width-source); Q is
  // only the cswap data operand.
  Value *Q = MergePhi->getBasicBlockIndex(R.Pred) >= 0
                 ? MergePhi->getIncomingValueForBlock(R.Pred)
                 : phaseSpineBase(MergePhi->getIncomingValueForBlock(R.Arm),
                                  R.Arm);

  // 4.2 VALUE path (method-B, §4/§5d): classifyArms recorded the arm class +
  // its ordered chain (Shadow, FORWARD order — by FIELD identity: for an
  // orientation-B diamond R.Arm is the FALSE successor and polarity rides
  // ArmNegated). This dispatch MUST precede the phase-stream collection: a
  // value arm has no cq_phi gates, so falling through would hit the
  // identity-region RAUW — a verify-clean silent wrong answer. WI-4 emits the
  // one-content-arm DIAMOND only; classifyArms keeps declining a two-arm
  // value if/else until the WI-5 dual-rail emitter, so anything else here is
  // a malformed plan — decline LOUDLY, lower nothing (Rule 1).
  if (R.ClassArm == ArmClass::Value || R.ClassArmFalse == ArmClass::Value) {
    if (R.ClassArm != ArmClass::Value || R.ArmFalse || R.Shadow.empty()) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
    emitValueDiamond(R, BI, Cond, MergePhi, Q, wd, csyms, taint);
    return;
  }

  // Per-arm ordered phase gates. A gate-free arm (`if (q) {}`, or an empty else)
  // contributes Q unchanged, so routing it would be a no-op cswap pair — skip it
  // (no rail, no route). `AllPhis` collects every gate to scrub + erase after the
  // rewire.
  SmallVector<ArmStream, 2> Streams;
  SmallVector<CallInst *, 8> AllPhis;
  for (const ArmInfo &A : Arms) {
    SmallVector<CallInst *, 4> Phis =
        collectArmPhis(MergePhi->getIncomingValueForBlock(A.BB), A.BB);
    if (Phis.empty())
      continue;
    AllPhis.append(Phis.begin(), Phis.end());
    Streams.push_back({A.Negated, Phis});
  }

  // Identity region — every arm is gate-free (`if (q) {}` diamond, or an
  // empty/empty if/else): there is no quantum op to control. The merge phi is
  // just Q on every edge; RAUW it to Q and flatten the dead CFG. No flag, no
  // rail, no strip — and no rotation width needed for a gate-free region.
  if (Streams.empty()) {
    MergePhi->replaceAllUsesWith(Q);
    scrubTaint(MergePhi, taint);
    MergePhi->eraseFromParent();
    flattenRegion(R, taint);
    return;
  }

  // ABI width from the FIRST gate's `cq_phi` suffix — the rotation width (all
  // arms rotate the same-width routed handle, by classifyArms). The routed handle
  // MAY be a value DERIVED before the region (its own suffix is unreliable), so
  // never read width off Q (§4 width-source).
  StringRef Abi =
      wd.abiWidthFor(intrinsicSuffix(Streams.front().Phis.front(), "cq_phi_"));
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Rz = Abi.empty() ? FunctionCallee() : wd.rzRtFn(Abi);
  if (!RailTy || !Alloc || !Rz) {
    // Unsupported width past detection — decline LOUDLY (a silent leave-in-
    // place would hand the tainted `br` to the backend as classical control
    // while the later rotation lowering fires the arm gates unconditionally).
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  const DebugLoc DL = BI->getDebugLoc();
  IRBuilder<> B(BI);  // every stream call lands before the conditional br.

  // 1. Flag mint — cq_template_icmp_<pred>_<W>_hl(q, lit).
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).

  // 2. One |0> work rail per content arm (allocated up front — the §5b order).
  SmallVector<Value *, 2> Rails;
  for (size_t I = 0; I < Streams.size(); ++I) {
    CallInst *Rail =
        B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "rail");
    if (DL)
      Rail->setDebugLoc(DL);
    Rails.push_back(Rail);
  }

  // 3. Route-in (split) — q -> each rail, X-bracketed for a ¬flag arm.
  for (size_t I = 0; I < Streams.size(); ++I)
    emitRoute(B, csyms, Flag, Q, Rails[I], Streams[I].Negated, DL);

  // 4. Arm bodies, VERBATIM and UNCONTROLLED, each on its OWN rail.
  for (size_t I = 0; I < Streams.size(); ++I)
    for (CallInst *Phi : Streams[I].Phis) {
      CallInst *RzCall = B.CreateCall(Rz, {Rails[I], Phi->getArgOperand(1)});
      if (DebugLoc PDL = Phi->getDebugLoc())
        RzCall->setDebugLoc(PDL);
    }

  // 5. Route-back (join = adjoint of the split, same flag + brackets).
  for (size_t I = 0; I < Streams.size(); ++I)
    emitRoute(B, csyms, Flag, Q, Rails[I], Streams[I].Negated, DL);

  // 6. Rail frees — each rail is |0> for free (Rz|0>=|0>); a clean reset, NOT a
  //    measurement (SCOPING §3b).
  for (Value *Rail : Rails) {
    CallInst *RailFree = B.CreateCall(wd.freeFn(), {Rail});
    if (DL)
      RailFree->setDebugLoc(DL);
  }

  // 7. Flag strip — q == q0 (Rz preserves the basis value), so icmp_inv(q)
  //    returns the flag to |0> with zero controlled gates. Reads `Cond`'s
  //    operands, so it MUST precede the erase of `Cond` (in flattenRegion).
  lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                     /*before=*/BI);

  // 8. Flag free.
  CallInst *FlagFree = B.CreateCall(wd.freeFn(), {Flag});
  if (DL)
    FlagFree->setDebugLoc(DL);

  // 9. Rewire + erase + scrub, then flatten the CFG. The merge phi's value is now
  //    just `q` (a phase arm preserves q's basis identity), so a measure on the
  //    phi becomes a measure on q. Erase the arm cq_phi in REVERSE lineage order
  //    so each is use-empty when erased; scrub every erased instruction (§6.1).
  MergePhi->replaceAllUsesWith(Q);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  for (CallInst *Phi : reverse(AllPhis)) {
    scrubTaint(Phi, taint);
    Phi->eraseFromParent();
  }
  flattenRegion(R, taint);
}

}  // namespace

void lowerControlRegions(Module &M, WidthDispatch &wd, TaintSet &taint,
                         const ControlPlan &plan) {
  if (plan.Regions.empty())
    return;  // nothing accepted — classical / fully-declined module untouched.

  // Pre-flight, while EVERY region's blocks are still valid (the block-lifetime
  // rule): no accepted region may reference a block that flattening another
  // accepted region will erase (its Arm/ArmFalse/MergeBB). Detection forecloses
  // the known sequential layouts (an if/else or diamond merge hosting the next
  // tainted branch declines as nested), so this should be unreachable — but a
  // future shape that slips through must decline LOUDLY here, not dereference
  // freed memory in emitRegion (the §8-confirmed sequential-region SIGSEGV
  // family, 2026-06-10). Pointer-identity checks only; nothing is dereferenced.
  for (const ControlRegion &A : plan.Regions)
    for (const ControlRegion &B : plan.Regions) {
      if (&A == &B)
        continue;
      for (BasicBlock *Doomed : {B.Arm, B.ArmFalse, B.MergeBB}) {
        if (!Doomed)
          continue;
        if (A.Pred == Doomed || A.Arm == Doomed || A.ArmFalse == Doomed ||
            A.MergeBB == Doomed) {
          if (auto *Anchor = dyn_cast_or_null<Instruction>(A.Condition))
            diagnoseUnderControl(Anchor, "control flow");
          else if (A.Merge)
            diagnoseUnderControl(A.Merge, "control flow");
          return;  // lower NOTHING — over-declining is always safe.
        }
      }
    }

  ControlledSymbols csyms(M, wd);
  for (const ControlRegion &R : plan.Regions)
    emitRegion(R, wd, csyms, taint);
}

}  // namespace cq
