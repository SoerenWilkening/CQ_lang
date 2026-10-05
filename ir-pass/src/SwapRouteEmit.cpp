// SwapRouteEmit.cpp — see header. The mutating emitter for accepted control
// regions. The file name is history: since bd test_C_libtooling-3qlq no phase
// or value arm routes, and `emitRoute` survives only for `AbortParkEmit`'s park.
// PHASE arms lower by KICKBACK (`emitPhaseKickbackRegion`, `…NestRegion`): mint
// the flag, an uncontrolled `cqrt_rz_i1(f, θ)` (`cqrt_x`-bracketed for a ¬flag
// arm), the compare `_unc` strip, one `cqrt_free`. VALUE arms — a one-content-arm
// DIAMOND (§5d, WI-4) or a two-arm IF/ELSE (§5e, WI-5) — HOIST the arm chain into
// the pred and merge with the 4.4 controlled-XOR copy pair (`emitSelectRegion`)
// — see emitValueRegion. IN-PLACE ROTATION arms use `cqrt_ry_<W>_controlled`.
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2):
//   `(|0> + |1>)/√2 ⊗ |0>_f` ─mint→ `(|0>|0>_f + |1>|1>_f)/√2` ─rz_i1(f,θ)→
//   `(|0>|0>_f + e^{iθ}|1>|1>_f)/√2` ─icmp_inv(q)→ `(|0> + e^{iθ}|1>)/√2 ⊗ |0>_f`:
//   q keeps the conditional phase, and the flag is stripped because no gate
//   touched q (q == q0). No `_controlled` gate, no added measurement. The
//   value-arm trace is at emitValueRegion (PRD Part II §8.2).

#include "SwapRouteEmit.h"

#include "AbortParkEmit.h"       // emitAbortParkRegion (the 7.2 Inc 3 park cascade)
#include "ArmAnalysis.h"         // phaseAngleTail (3qlq Inc 1 merge-tail angle phi)
#include "CondTreeEmit.h"        // emitCondNetwork / stripCondNetwork (3qlq P3)
#include "SelectClassify.h"      // CondTree / collectCondTree (the shared grammar)
#include "ArithLowering.h"       // rewriteBinary (the value-arm chain body, §4)
#include "ArmAnalysis.h"         // comparePredLowerable (the value-arm pre-mint fence)
#include "AngleSelectEmit.h"     // emitAngleSelectRegion (drbq Inc 2b)
#include "ChainWalk.h"           // markBranchPhaseGate (3qlq Inc 1 F-L7-1)
#include "CompareLowering.h"     // lowerCompareToFlag + compareFlagMintable
#include "ClassicalCallArmEmit.h" // emitClassicalCallArmRegion (the 6.5 merge)
#include "GuardedStoreArmEmit.h"  // emitGuardedStoreArmRegion (iw81.7)
#include "ControlPlan.h"         // ControlRegion / ControlPlan
#include "ControlledSymbols.h"   // cswapFn / xFn
#include "EmitInverse.h"         // emitInverseChain (the value-arm reverse-play)
#include "OpcodeSupport.h"       // abiWidthFromType · abiWidthHasControlledRotation
#include "RegionFlatten.h"   // flattenRegion / flattenRegionTree       // flattenRegion
#include "RotationLowering.h"    // markKeptConditionFlag (bd dm7f.4)
#include "SelectMergeEmit.h"     // emitSelectRegion (the 4.4 select merge)
#include "SwitchRouteEmit.h"     // emitSwitchPhaseRegion (the 4.5 switch phase)
#include "TaintPropagation.h"    // TaintSet
#include "WidthDispatch.h"       // allocFn / copyFn / rzRtFn / freeFn / abiWidthFor

#include "llvm/Analysis/ValueTracking.h"  // isSafeToSpeculativelyExecute (Inc 2)
#include "llvm/ADT/STLExtras.h"   // llvm::reverse / llvm::is_contained
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
#include <cassert>

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
    PC.erase_value(CI);
    // M-B Increment 6's two EMITTER-RECORDED sets (bd test_C_libtooling-160a
    // Rule-13 round, finding F3). This module is NOT their sole writer (it was
    // when this was written): `SwitchRouteEmit.cpp` and `AngleSelectEmit.cpp`
    // also insert into `DischargedFlagGates`, and `RestoringRoutes` has no
    // writer at all (below). This TU-local scrub drops a key only when THIS
    // module erases the call; `DischargedFlagGates` is a `ScrubPtrSet`
    // (ScrubOnDelete.h), which drops a deleted key whoever erases it. The
    // hazard both guard against: a dangling `CallInst *` reused by a later
    // allocation would make
    // `ChainWalk::isInteriorConsumer` / `routeGroupFullyInside` answer YES for
    // an unrelated call, i.e. discharge a chain against a route that never
    // restored anything.
    //
    // TWO BELTS, and this is the SECOND one; the first is that neither key can
    // dangle today. No stage between `lowerControlRegions` and `uncompute`
    // erases a recorded call: `flattenRegion` SPLICES the merge block into
    // `Pred` (moves, never erases the stream), the hcrg sequential ordering
    // erases only arm blocks and emptied merges, and `lowerRotations` /
    // `lowerOps` / `lowerMeasures` / `specialize` erase `cq_*` intrinsic calls
    // only — never a `cq_template_*_unc` or a `cqrt_cswap`. This emitter itself
    // erases only the merge φ and the arm `cq_phi`/`BinaryOperator`s, none of
    // which is ever recorded. And even a dangling key that WERE reused could not
    // be acted on: an admitted strip must additionally pass
    // `TemplateName::isUncHandleSlot` (slot 0, the written flag, is refused) and
    // every operand of the spine's own `_unc`s is in `ReversedRails`, which
    // candidate selection subtracts. The erases below make the argument
    // unnecessary rather than merely correct — cheap, idempotent, fail-closed.
    //
    // A ROUTE GROUP IS DROPPED WHOLE, NOT MEMBER-WISE. The group's only claim is
    // that executing ALL of it restores the base's label; a group missing a
    // member states nothing (one half of a pair leaves the base holding |0> or
    // the arm's copy depending on the flag), and a 3-of-4 remnant would still
    // satisfy the consumer's every-member-inside test. Clearing it makes the
    // group unmatchable, so the component leaks — the safe direction.
    // (Since drbq Inc 2a this module records only `DischargedFlagGates`: the
    // phase path emits no route, so `RestoringRoutes` has no writer anywhere and
    // the loop below is a no-op over an empty container. Kept for the same reason
    // the set is — `AbortParkEmit` still calls `emitRoute` and could start
    // recording; see `Uncomputation::routeGroupFullyInside`.)
    taint.DischargedFlagGates.erase(CI);
    for (auto &Gates : taint.RestoringRoutes)
      if (llvm::is_contained(Gates, CI))
        Gates.clear();
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

// ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 (2026-09-05), AND DELIBERATELY
// KEPT (PRD `retire-swap-route-PRD.md` §6.2 row P6: "every 'Rz is diagonal and
// exempt' clause becomes VACUOUS rather than deleted").
//
// The 15-width `@cq_phi_<sfx>(x, angle)` family is RETIRED: `CQ.h` no longer
// declares it and `resolveSources` no longer resolves it, so no call this
// predicate can match exists in a module the pass lowers. It CANNOT accidentally
// match the register-free replacement, and that is a fact about the strings, not
// a hope: `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE — six characters
// against a seven-character prefix. The new call is recognized by EXACT
// membership instead (`TaintPropagation.h`'s `isRegisterFreePhaseCall`), which is
// also the project's standing accept-side discipline (never a name prefix — the
// `cq_theta_evil` hazard).
//
// KEEPING IT IS THE POINT: a `void(double)` call has no arg-0 WIRE and no arg-1
// ANGLE, so every clause below that follows `getArgOperand(0)` as a rail, or
// reads `getArgOperand(1)` as an angle, would be reading the wrong operand — or
// out of range — if this predicate were widened to admit it. Do not "fix" this by
// making it match `cq_phi`.
bool isPhiCall(const Value *V) { return !intrinsicSuffix(V, "cq_phi_").empty(); }

// `collectArmPhis` and `emitRoute` are DE-ANONYMIZED into the named `cq`
// namespace (declared in SwapRouteEmit.h, WI-3/MD1-style). They were shared with
// the 4.3 `NestedRouteEmit` TU, deleted in 3qlq part B; `emitRoute`'s one caller
// is now `AbortParkEmit` (Rule 14 — one definition of the ¬flag-bracketed swap).
// Their definitions sit below the anonymous block (so they can still see the
// TU-local `isPhiCall`). See the definitions just before `lowerControlRegions`.

// The value an arm's IN-BLOCK `@cq_phi_<sfx>` spine bottoms at (the retired
// register form only, see `isPhiCall`) — the base handle the arm's gates rotate.
// For an if/else, which has no straight-through (Pred) merge edge, this recovers
// the base `classifyArms` proved BOTH arms share; for a gate-free arm
// (`ArmIncoming` is the base itself) it returns that value unchanged. Bounded at
// the arm-block boundary for the same reason as `collectArmPhis`: a `cq_phi_`
// defined OUTSIDE `ArmBB` is the DERIVED base handle, never hopped past.
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

// The base a value chain consumes — its FIRST (base-first) link's sole tainted
// operand, i.e. the `Q` the merge `select` keeps on the straight-through edge
// (nothing is retargeted since 3qlq Inc 2). classifyArms proved every accepted
// link has exactly ONE tainted operand (Q+Q links defer) and, for an if/else,
// that BOTH arms' chains bottom at the SAME base (base-identity). Null on
// anything off that proof — a malformed plan the caller declines loudly (Rule 1).
Value *valueChainBase(ArrayRef<Instruction *> Chain, const TaintSet &taint) {
  if (Chain.empty())
    return nullptr;
  const auto *BO = dyn_cast<BinaryOperator>(Chain.front());
  if (!BO)
    return nullptr;
  Value *Op0 = BO->getOperand(0);
  Value *Op1 = BO->getOperand(1);
  const bool T0 = taint.Tainted.count(Op0) != 0;
  const bool T1 = taint.Tainted.count(Op1) != 0;
  if (T0 == T1)
    return nullptr;  // Q+Q or untainted head — never an accepted chain.
  return T0 ? Op0 : Op1;
}

// One content VALUE arm: its ¬flag polarity, the ordered ORIGINAL chain links
// (the plan's Shadow/ShadowFalse, FORWARD order), and its classical cone.
struct ValueArmStream {
  bool Negated;
  ArrayRef<Instruction *> Chain;   // original IR links (hoisted in step 1)
  // bd `test_C_libtooling-fn1q` increment 1 — the arm's CLASSICAL CONE in BLOCK
  // order, as PROVEN and RECORDED by `valueArmIsPureChain`. Hoisted ahead of the
  // chain in step 1; never re-derived here (L1 / Rule 14). Empty on every region
  // that lowered before that increment.
  ArrayRef<Instruction *> Cone = {};
  CallInst *Rail = nullptr;             // unused since 3qlq Inc 2 (route work rail)
  SmallVector<CallInst *, 6> Fwd = {};  // unused since 3qlq Inc 2
};

// Lower one accepted VALUE-arm region — a one-content-arm DIAMOND (§7.2 V1) or
// a two-arm IF/ELSE (§7.2 V2) — by the CONTROLLED-COPY MERGE (bd
// test_C_libtooling-3qlq Inc 2, retire-swap-route-PRD §7; owner decision D6).
// The pre-3qlq swap route (`alloc w; cswap(f,p,w); chain on w; cswap; alloc out;
// copy(p,out); cswap; chain _unc; cswap; free w; strip; free f` — 4 `cqrt_cswap`
// = 4W Toffoli + 8W CNOT and one W-bit work rail per arm) is RETIRED here; after
// this increment `cqrt_cswap` is minted by `AbortParkEmit` alone.
//
// THE MECHANISM IS A REWRITE, NOT A GATE STREAM. The arm's chain is a proven
// PURE LINEAR chain of `BinaryOperator`s whose only escape is the merge φ
// (`valueArmIsPureChain`, ArmClassify), so the region
//
//     Pred: … br i1 %c, Arm, Merge      Arm: %t = R(%p)      Merge: φ[%t, %p]
//
// is rewritten to the straight-line form `%t = R(%p); %sel = select %c, %t, %p`
// and handed to `emitSelectRegion` — the Rule-13-cleared 4.4 controlled-XOR copy
// merge — VERBATIM (Rule 14). Nothing new is emitted by this function at all:
// every gate in the resulting stream is minted either by `lowerOps` (the hoisted
// chain, exactly as for any straight-line tainted arithmetic) or by
// `emitSelectRegion` (mint · `alloc out` · `copy_controlled(f,t,out)` ·
// `x(f)` · `copy_controlled(f,p,out)` · `x(f)` · strip · `free f`).
//
// WHY THE HOIST IS SOUND. `R` runs UNCONDITIONALLY on the ORIGINAL `p` — which
// the swap route also did (it replayed the chain "VERBATIM + UNCONTROLLED" on a
// routed rail; on the inactive branch it computed `R(0)` garbage there). Three
// things make the unconditional run harmless: (i) every link is a pure total
// template with no memory and no call (`walkValueChain` accepts only
// `binaryStem` opcodes) — ⚠ AND SINCE bd `test_C_libtooling-fn1q` INCREMENT 1
// THE ARM MAY HOLD MORE THAN THE CHAIN: `valueArmIsPureChain` also admits a
// CLASSICAL CONE (the untainted, side-effect-free, non-escaping, speculatable,
// non-CQ-call computation feeding a link's classical operand), which this
// function hoists ahead of the chain. The cone MAY read memory; what keeps that
// sound is an argument about PLACEMENT rather than about purity, and it lives at
// `valueArmIsPureChain` in full: the only instructions between the hoist point
// and a hoisted load's old position are the region's `br`, the arm's other cone
// members (which cannot write) and its chain links (`BinaryOperator`s), so
// nothing on that path can change what the load sees. If either of those two
// facts changes, that argument must be REBUILT, not re-quoted, (ii) each link is
// `isSafeToSpeculativelyExecute` — the ONE new fence below, which refuses a
// possibly-zero / possibly-overflowing tainted-context divisor (`sdiv`/`udiv`/
// `srem`/`urem`), and (iii) the §3c clobber decline (ArmClassify) already
// refuses an arm that rewrites a register the condition reads, so the compare
// strip at the end of `emitSelectRegion` reads the same basis value the mint
// did. The chain writes only FRESH rails: its head link reads `p` (which has a
// later reader — the second controlled copy — so `lowerOps`' M-C in-place
// conversion refuses it) and every later link reads its own predecessor.
//
// THE WITNESS IS BYTE IDENTITY WITH THE PRE-HOISTED SELECT TWIN — the C program
// `int t = R(p); p = (q>5) ? t : p;`, which `clang -O1` hands to the pass in
// exactly the post-rewrite shape and which lowers through the same
// `emitSelectRegion`. (The `?:` spelling of the DIAMOND is NOT a twin: measured
// 2026-09-05, `-O1` compiles `p = (q>5) ? R(p) : p` and `if (q>5) p = R(p)` to
// byte-identical IR — SimplifyCFG's speculation cost threshold, not the source
// spelling, decides select-vs-diamond, so a multi-op `?:` arrives as a diamond
// too.)
//
// THE HOIST ONLY EVER MOVES A LINK LATER WITHIN `Pred` — `moveBefore(BI)`
// lands it immediately before the terminator — so it can never be scheduled
// ABOVE a gate a preceding region already emitted into `Pred`. That is what
// keeps source order across SEQUENTIAL regions (bd hcrg) and across a
// value/phase interleave; it is a property of the insertion point, not of the
// plan, so do not change the insertion point without re-deriving it.
//
// ONE ACCEPT-CLASS WIDENING RIDES ON THE MECHANISM CHANGE, deliberately and
// pinned (Inc-2 round-1 review finding F-V1-1; owner disposition: keep).
// `emitSelectRegion` records `taint.HandleWidth[out]` (bd p119.6) — the side
// table a DOWNSTREAM cast (`OpcodeLowering`) and a DOWNSTREAM Q+Q data compare
// (`CompareLowering::rewriteCompare`) read to recover the logical width of a
// laundered i32 handle. The retired route wrote no such entry, so both
// declined `no template for opcode …` off a value-arm merge. Routing the
// diamond through the select emitter inherits the entry, so `int w = (int)p;`
// and `int e = (p == r);` after a value arm now LOWER, at every width incl. the
// flagship i32. That is a capability gain and the p119.6 fix applying to one
// more path — suppressing it would mean deliberately re-introducing a known
// defect — but it is an accept-class change, so it is pinned rather than
// inherited silently: `control_swap_value_accept_i8_merge_cast.ll`,
// `…_i64_merge_cast.ll`, `…_qq_compare_on_merge{,_i8,_i16}.ll` and the e2e
// slice `slice_control_value_merge_qq_compare`.
//
// ORDER IS LOAD-BEARING: `flattenRegion` runs BEFORE `emitSelectRegion`.
// `flattenRegion` reads `R.Condition` and erases it when use-empty;
// `emitSelectRegion` erases the compare itself in its step 6. Emitting first
// would hand `flattenRegion` a DANGLING `R.Condition` (a use-after-free on
// valid input — the block-lifetime hazard's value-identity twin). With the
// order below the compare is still live at flatten time (the new `select` uses
// it), so `flattenRegion` leaves it and `emitSelectRegion` owns its erase.
void emitValueRegion(const ControlRegion &R, BranchInst *BI, CmpInst *Cond,
                     PHINode *MergePhi, WidthDispatch &wd,
                     ControlledSymbols &csyms, TaintSet &taint) {
  // Arm list by FIELD identity (orientation-B diamond: R.Arm is the FALSE
  // successor, polarity rides ArmNegated; an if/else's R.Arm is the TRUE
  // successor S0 and R.ArmFalse the FALSE successor S1). classifyArms accepts
  // only the homogeneous all-value region with every chain non-empty; anything
  // else here is a malformed plan — decline LOUDLY, lower nothing (Rule 1).
  // ziov WI-1: shared-condition-flag sharing is implemented for PHASE arms only
  // (emitRegion). A VALUE-arm region whose condition is ALSO read as data keeps
  // its pre-3qlq decline: `emitSelectRegion` strips and frees the flag, so the
  // surviving data use would make `lowerOps` mint a SECOND one (the ziov
  // duplicate-mint). Over-declining is safe.
  if (R.ShareCondFlag) {
    diagnoseUnderControl(Cond, "condition used outside the branch");
    return;
  }

  SmallVector<ValueArmStream, 2> Arms;
  if (R.ArmFalse) {
    if (R.ClassArm != ArmClass::Value || R.ClassArmFalse != ArmClass::Value ||
        R.Shadow.empty() || R.ShadowFalse.empty()) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
    Arms.push_back({/*Negated=*/false, R.Shadow, R.ShadowCone});
    Arms.push_back({/*Negated=*/true, R.ShadowFalse, R.ShadowConeFalse});
  } else {
    if (R.ClassArm != ArmClass::Value || R.Shadow.empty()) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
    Arms.push_back({R.ArmNegated, R.Shadow, R.ShadowCone});
  }

  // The base register Q — re-derived per arm as the chain head's sole tainted
  // operand (an if/else merge has no Pred edge to read it from; never read
  // width/identity off Q's SSA type). Every arm must agree, and a diamond's Q
  // must equal the straight-through (Pred-edge) incoming — classifyArms proved
  // both (base-identity), so a mismatch is a malformed plan: decline LOUDLY.
  // Q is ALSO the `select`'s straight-through operand below, so this identity
  // is a correctness precondition of the merge itself.
  Value *Q = valueChainBase(Arms.front().Chain, taint);
  for (const ValueArmStream &A : Arms)
    if (!Q || valueChainBase(A.Chain, taint) != Q) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
  if (!R.ArmFalse &&
      (MergePhi->getBasicBlockIndex(R.Pred) < 0 ||
       MergePhi->getIncomingValueForBlock(R.Pred) != Q)) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  // ABI width from the chain op's INTEGER SSA type — reliable pre-RAUW (the ops
  // still carry iN; PRD §8.1 width-source). NEVER the theta suffix (the
  // base may be derived), and never a classifying signal (the f64 trap) —
  // classifyArms' positive integer fence already proved validity, so a null here
  // is a malformed plan: decline LOUDLY, lower nothing (Rule 1). The merge
  // primitive is now `cqrt_copy_<W>_controlled` (`ControlledSymbols`, minted for
  // 4.4/6.5 — NO new runtime symbol, epic decision D3) rather than the
  // uncontrolled `cqrt_copy_<W>`; `emitSelectRegion` mints it itself from the
  // select's own type, so this check is a PRE-FLIGHT — it must agree with what
  // the select emitter will resolve, and it declines before any mutation.
  //
  // ITS FP ARM IS AN UNREACHED BACKSTOP, and say so rather than implying it
  // fires (Inc-2 round-1 review, finding F-V1-3). `copyControlledFn` returns a
  // null callee for any non-integer width (`ControlledSymbols.cpp`), so an fp
  // value arm arriving here would decline `control flow` — but none can arrive,
  // behind TWO fences ahead of this one: (1) `flattenPredMuxRegions` runs
  // BEFORE `detectControlRegions` and CLAIMS the flat scalar-fp-phi diamond by
  // design (PredMuxFlatten's W5 witness, bd vyqi — "which ArmClassify's fp
  // fence categorically declines"), so a `clang -O1` fp diamond never reaches
  // detection at all (measured: a hand-IR `phi double` diamond lowers to
  // `cqrt_copy_f64_controlled` on BOTH binaries); and (2) for a shape PredMux
  // will not claim, `classifyArms`' `isFPOrFPVectorTy` angle fence declines
  // first (measured on an `fp128` arm: `value-arm swap-route`, identical on
  // both binaries — it does not even reach the fp merge fence). Note the
  // DIRECTION if the lift ever narrows: this pre-flight is STRICTER than the
  // emitter it guards (`emitSelectRegion` would resolve `copyControlledFpFn`),
  // so the pre-3qlq `wd.copyFn(Abi)` spelling, which DOES resolve at
  // f16/f32/f64/f80, would have routed where this declines. Over-declining is
  // safe; nothing measures it, which is why it is written down here.
  StringRef Abi = abiWidthFromType(Arms.front().Chain.front()->getType());
  if (Abi.empty() || !wd.llvmWidthType(Abi) || !wd.allocFn(Abi) ||
      !csyms.copyControlledFn(Abi)) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  // Library-host parity (the twin-pipeline trap, IMPLEMENTATION §6.5): a chain
  // link `declineStaleRecordOps` marked has ALREADY been diagnosed with the
  // pledge "lower NOTHING for this op" (lowerOps honors it by skipping). In the
  // `opt` host that DS_Error exited the process before emission ever runs; in an
  // embedding host that does not exit, HOISTING the marked link into the pred
  // here would break the pledge (and, unlike the pre-3qlq replay, would leave it
  // to `lowerOps`, which skips it — a SILENTLY DROPPED arm op, Rule 5). Decline
  // pre-mutation — no lit fixture can pin this (opt exits at the stale
  // diagnostic first); it is the Rule-1 defensive bail, never a silent skip.
  for (const ValueArmStream &A : Arms)
    for (Instruction *Op : A.Chain)
      if (taint.StaleDeclined.count(Op)) {
        diagnoseUnderControl(Cond, "control flow");
        return;
      }

  // SPECULATION TOTALITY — the ONE new fence of Inc 2 (PRD §10.3 lens 8).
  // `binaryStem` admits `sdiv`/`udiv`/`srem`/`urem`, whose C semantics are
  // UNDEFINED at a zero (or `INT_MIN / -1`) divisor. The divisor of an accepted
  // link is CLASSICAL (a Q+Q link declines at classification), but classical is
  // not the same as non-zero: `if (q>5) p = p / n;` with a run-time classical
  // `n` is a real -O1 shape. Ask LLVM's OWN predicate — the same one SimplifyCFG
  // consults before speculating a block (Rule 14) — rather than hand-rolling a
  // per-opcode table that would drift from it. Shifts by >= bitwidth are POISON,
  // not UB, and `isSafeToSpeculativelyExecute` admits them; the poison never
  // materializes because `lowerOps` replaces every link with a runtime template
  // call and erases the original.
  //
  // NOTE FOR THE RECORD: this hazard is NOT created by the hoist. The pre-3qlq
  // route also ran the chain unconditionally — and say WHY precisely, because
  // the convenient shorthand is wrong (Inc-2 round-1 review, finding F-V1-6):
  // `cqrt_cswap(f, p, rail)` leaves the rail in a SUPERPOSITION of `p0` and `0`
  // correlated with the flag, so the routed chain gate had to be defined over
  // `p0`'s whole range too. It is NOT "the inactive branch computed `0 sdiv n`
  // on a |0> rail" — that is the classical-trace reading, and quoting it would
  // later be used to argue this fence is over-strict. The corrected reading
  // STRENGTHENS the conclusion: the obligation was identical under the route, so
  // this fence NARROWS the accept class relative to HEAD; that direction is
  // always safe (Prime Directive) and is the disposition the PRD asks for.
  // `p / 3` (a non-zero constant divisor) still accepts —
  // `control_swap_value_accept_div_const.ll` is the discriminator.
  //
  // ONE ARM OF THIS FENCE IS EXERCISED BY NOTHING, recorded so nobody assumes
  // it is covered: `isSafeToSpeculativelyExecute`'s `INT_MIN / -1` rule. No C
  // program reaches it — `clang -O1` folds `p / -1` to `sub i32 0, %p` before
  // the pass sees it (measured, round-1 probe `m2_div_neg1.c`), so only the
  // possibly-zero-divisor arm has a reproducer.
  //
  // ⚠ THE CONE IS ASKED THE SAME QUESTION IN THE SAME SPELLING (bd
  // `test_C_libtooling-fn1q` increment 1). `valueArmIsPureChain` already proved
  // it at classification; re-asking here is the LOCKSTEP idiom this file's two
  // siblings use for `comparePredLowerable`/`compareFlagMintable`, and it is
  // free. It must be the SAME call — `isSafeToSpeculativelyExecute` in its
  // NO-CONTEXT form — or the two sites could disagree and a proven-admissible
  // cone member would decline here, after the classifier had counted on it.
  for (const ValueArmStream &A : Arms)
    for (ArrayRef<Instruction *> Ops : {A.Cone, A.Chain})
      for (Instruction *Op : Ops)
        if (!isSafeToSpeculativelyExecute(Op)) {
          diagnoseUnderControl(Op,
                               "value arm op that cannot run unconditionally");
          return;
        }

  // Q+Q CONDITION — keep the pre-3qlq decline. `emitSelectRegion` mints its flag
  // through `lowerCompareToFlag` with the 4.4 `qqSelectLeafWidth`, which SUPPORTS
  // a two-handle compare; the pre-3qlq value path passed an empty width and so
  // declined. Routing the value diamond through the select emitter would
  // therefore WIDEN the accept class as a side effect of a mechanism change,
  // which is exactly the kind of unintended widening the Prime Directive refuses
  // to ship unreviewed. A Q+Q condition for value arms stays a loud decline and
  // is filed as follow-on work, not smuggled in here.
  if (taint.Tainted.count(Cond->getOperand(0)) &&
      taint.Tainted.count(Cond->getOperand(1))) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  // FLAG MINTABILITY, asked PRE-MUTATION (Inc-2 round-1 review, finding F-V1-2).
  // `emitSelectRegion` mints its flag as its own step 1, i.e. AFTER this
  // function has hoisted the chain, built the select, RAUW'd the merge φ and
  // FLATTENED the diamond — so a mint that returns null there is a
  // MUTATE-THEN-DECLINE: loud, but on a module already rewritten. The pre-3qlq
  // route minted the flag as its FIRST emission step, so its bail left the
  // region intact; that property has to be restored explicitly, and it is
  // restored the way this file's two siblings restore it — `AngleSelectEmit`
  // step 0b and `ArmClassify.cpp`'s 6.5 classical-call gate both re-ask
  // `comparePredLowerable` and `compareFlagMintable` in LOCKSTEP for exactly
  // this reason (Rule 14: the same two predicates, never a third spelling).
  // The predicate half is already asked at detection (`ArmClassify.cpp`
  // `classifyArms`); asking it again is free and keeps the pair together so a
  // later change to either cannot silently unpair them.
  //
  // ⚠ IT IS REACHABLE, AND THE ROUND-1 REVIEW'S "no reproducer exists" NOTE IS
  // SUPERSEDED — measured while writing the fence, not assumed. The only shape
  // with `comparePredLowerable` true and `compareFlagMintable` false is an
  // out-of-surface (i128) condition width, and the review recorded that such a
  // `br` "never reaches the control layer at all on EITHER binary" (finding
  // F-V1-9: neither claimed nor declined, only a later `no template for opcode
  // 'icmp i1'` from the compare failing in DATA position — which Rule 1 says
  // cannot happen). That is true of the PHASE arm and FALSE of the VALUE arm:
  // detection DOES hand an i128-condition value diamond to this function, so
  // this fence fires and the module now declines LOUDLY at the compare
  // (`CQ_CTRL_DBG=1` names it). Pinned by
  // `control_swap_value_reject_i128_cond.ll`; red-green measured against the
  // pre-fix binary, which reports only the template error. So this fence also
  // closes the VALUE half of F-V1-9. The PHASE half is untouched and still open
  // (bd test_C_libtooling-3qlq.8; both reproducers are committed under
  // `docs/prd/phase-04-swap-route-control/inc2-records/`). Nothing moved in the
  // accept direction: both binaries exit non-zero on that module and neither
  // emits a gate — this fence can only DECLINE.
  if (!comparePredLowerable(Cond) || !compareFlagMintable(Cond, taint)) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  // ---- From here on the region is COMMITTED: every step mutates. ----

  // 1. HOIST each arm's chain into the pred, in FORWARD (base-first) order, so
  //    each link is still dominated by its operands. The links keep their SSA
  //    identity and stay ORDINARY tainted LLVM instructions — they are lowered
  //    later by `lowerOps` (which is what makes the emitted stream identical to
  //    the pre-hoisted select twin's, M-C in-place conversions included) and
  //    reversed by the whole-DAG LIFO spine. Nothing is retargeted: the head
  //    link keeps reading `Q`, which is exactly what the merge needs.
  //
  // ⚠ THE CONE GOES FIRST, AND THE ORDER IS AN ARGUMENT, NOT A HABIT (bd
  // `test_C_libtooling-fn1q` increment 1). A cone member's in-arm operands are
  // only ever other cone members (`valueArmIsPureChain`'s (K1) refuses a cone
  // member that reads a chain link), and the cone is recorded in BLOCK order, so
  // moving it first — in that order — keeps every definition ahead of its use.
  // The chain then follows in its own base-first order, reading `Q` from the
  // pred and its classical operands from the just-hoisted cone.
  //
  // The cone members stay ORDINARY UNTAINTED LLVM instructions in the pred:
  // `lowerOps` never looks at them, the whole-DAG spine never reverses them, and
  // they emit NO GATE. That is why the lowered stream is identical to the twin
  // whose source already had them in the pred —
  // `control_swap_value_accept_arm_cone{,_prehoisted_twin}.ll`.
  for (const ValueArmStream &A : Arms) {
    for (ArrayRef<Instruction *> Ops : {A.Cone, A.Chain})
      for (Instruction *Op : Ops)
        Op->moveBefore(BI);
    // THE ROUND-2 OBLIGATION, recorded at the irreversible step (L1: record the
    // question where it is ANSWERED, re-ask it where the answer is FINAL).
    // `classifyArms` proved every cone member classical at ROUND-1 taint;
    // `declineRound2TaintedArmCone` re-asks after the fixpoint. Recorded HERE
    // and not at the classifier because a region that is classified and then
    // declined by a later fence has mutated nothing and owes nothing.
    for (Instruction *Op : A.Cone)
      taint.ValueArmConeOps.insert(Op);
  }

  // 2. BUILD THE MERGE SELECT. Polarity (Rule 9): a `select` always means "the
  //    TRUE operand when the condition is 1", so the arm value goes in the slot
  //    its edge selects. For a diamond that is the true operand unless
  //    `ArmNegated` (clang -O1 made the gate arm the FALSE successor); for an
  //    if/else `R.Arm` is S0 (true) and `R.ArmFalse` is S1 (false). Built with
  //    `SelectInst::Create` rather than `IRBuilder::CreateSelect` deliberately:
  //    the builder CONSTANT-FOLDS, and a folded merge would silently erase the
  //    region's controlled copy.
  Value *TrueVal = nullptr;
  Value *FalseVal = nullptr;
  if (R.ArmFalse) {
    TrueVal = Arms[0].Chain.back();
    FalseVal = Arms[1].Chain.back();
  } else if (Arms[0].Negated) {
    TrueVal = Q;
    FalseVal = Arms[0].Chain.back();
  } else {
    TrueVal = Arms[0].Chain.back();
    FalseVal = Q;
  }
  auto *Sel = SelectInst::Create(Cond, TrueVal, FalseVal, "vmerge", BI);
  Sel->setDebugLoc(BI->getDebugLoc());
  // The select is a tainted data mux for exactly as long as it exists (it is
  // RAUW'd to the out-rail and erased inside `emitSelectRegion`). Recording it
  // keeps every "a tainted op's result is tainted" invariant true across the
  // window and gives `scrubTaint` something to remove.
  taint.Tainted.insert(Sel);
  taint.BirthOrder[Sel] = taint.NextBirth++;

  // 3. REWIRE the merge φ onto the select, then drop it. The user's measure /
  //    ret on the φ becomes one on the select and then (step 5) on the out-rail
  //    — no measurement is added (Rule 5).
  MergePhi->replaceAllUsesWith(Sel);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();

  // 4. FLATTEN the dead diamond. The arm block(s) are now empty but for their
  //    `br label %merge`; `flattenRegion` erases the conditional `br`, splices
  //    the merge tail into `Pred`, and deletes the arms and the merge block. It
  //    leaves `Cond` alone (the new select still uses it) — see the ORDER note
  //    in this function's header comment.
  flattenRegion(R, taint);

  // 5. THE 4.4 CONTROLLED-COPY MERGE, VERBATIM (Rule 14). A locally-built
  //    `SelectRegion` view of the rewritten shape: `emitSelectRegion` mints the
  //    flag from `Cond` (a bare compare is the degenerate single-leaf condition
  //    tree), allocates the `|0>` out-rail, emits the two X-bracketed
  //    `cqrt_copy_<W>_controlled`, strips the flag with the compare `_unc`,
  //    frees it, RAUWs the select to the out-rail and erases the select and the
  //    now-dead compare.
  //
  //    WHAT IS LEFT ALLOCATED — and the two halves are NOT the same debt
  //    (Inc-2 round-1 review, findings F-V1-4 / F-V2-3; the PRD's §3/§7.1 target
  //    stream said BOTH were uncomputed and is corrected in
  //    `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1):
  //      * `p` is left allocated exactly as the route left it — keep-source-live
  //        (freeing `p` is PRD §9 follow-on 3qlq.5, not this increment).
  //      * the chain's FINAL rail (`R(p)`; TWO of them for an if/else) is left
  //        allocated AND DIRTY — it is NOT `_unc`'d and NOT freed, which the
  //        route DID do for every rail it minted. The chain's INTERMEDIATES are
  //        still `_unc`'d and freed by the whole-DAG spine; only the final,
  //        whose live consumer is the controlled copy, survives.
  //    Rule-6 sound, and STATE THE REASON PRECISELY — the obvious version is
  //    false (clearance record item R-2, 2026-09-06; PRD §0 E1b). What is NOT
  //    true: "`R(p)` is a deterministic function of the retained `p`, so
  //    tracing the ancilla out leaves the reduced state on (q, p, out)
  //    unchanged." Tracing it out DOES dephase the off-diagonals between `p`
  //    and `p'` whenever `R(p) != R(p')`; a reader who tests that sentence
  //    finds it wrong. What IS true, and is what this emitter rests on:
  //      (a) relative to the SOURCE's live registers (q, out) the reduced
  //          state equals the ROUTE's, because the retained `p_old` already
  //          determines `R(p_old)` — the ancilla records nothing the surviving
  //          registers do not already record; and
  //      (b) on (q, p_old, out) NO CQ-EXPRESSIBLE CONTINUATION can observe the
  //          difference, because `out`'s own retained label already records
  //          `R(p_old)` on the arm branch and `p_old` on the other, and the ABI
  //          mints no in-place Q+Q gate on `out` that could erase it
  //          (`cqrt_copy_<W>_controlled` is minted only with a FRESH |0>
  //          destination).
  //    Clause (b) is a fact about the shipped ABI, not a law of physics. It is
  //    a leak, never a dirty FREE (`free_pairing_check.py` STRICT is clean).
  //    ⚠ CONSEQUENCE FOR 3qlq.5: it is exactly the continuation clause (b)
  //    rules out — freeing `p` while these finals are live is a hidden
  //    measurement of a register they still record — so 3qlq.5 is UNSOUND BY
  //    DEFAULT under this stream and must discharge the finals first.
  ControlRegion S;
  S.Kind = ControlRegion::SelectRegion;
  S.Merge = Sel;
  S.Condition = Cond;
  emitSelectRegion(S, wd, csyms, taint);
}

// One content arm's phase stream on `emitRegion`'s retired-form path: whether it
// fires on ¬flag (X-bracketed) and its ordered `@cq_phi_<sfx>` gates.
struct ArmStream {
  bool Negated;
  SmallVector<CallInst *, 4> Phis;
};

// The arm list + per-arm polarity, shared by every `emitRegion` recipe.
struct ArmInfo {
  BasicBlock *BB;
  bool Negated;
};

// Lower one accepted CONTROL-IN-PLACE ROTATION region (control-in-place-PRD §4
// + §6, bd test_C_libtooling-drbq Inc 1): a diamond or if/else whose every
// content arm is ONE tainted-operand `cq_theta` (Ry) on a register whose
// physical wire is disjoint from every condition wire.
//
// THE STREAM, and how little of it there is:
//     cq_template_icmp_<pred>_<W>_hl(c, lit)      ; flag mint, unchanged
//     [cqrt_x(f)]  <hoisted cq_theta>  [cqrt_x(f)] ; per arm, successor order
//     cq_template_icmp_<pred>_<W>_hl_unc(f, c, lit) ; flag strip, unchanged
//     cqrt_free(f)
// No `cqrt_alloc`, no `cqrt_cswap`, no reverse-play, no work rail at ALL — and
// that is forced, not chosen (PRD §2). The retired route's premise: the arm gate
// is a no-op on the inactive `|0⟩` rail: true for `Rz = diag(1, e^{iθ})`, FALSE
// for `Ry(θ)|0⟩ = cos|0⟩ + sin|1⟩`, which hands the inactive rail back DIRTY and
// ENTANGLED with the flag. Cleaning that needs a controlled `Ry†` — method-A,
// dropped 2026-06-09 precisely because "if you would emit a controlled gate to
// clean a rail, you could have controlled the op in place from the start".
//
// HOIST-AND-DEFER: the `cq_theta` is MOVED (never re-minted) to just before the
// branch and recorded in `taint.ControlledRotations`; `lowerRotations` then
// mints `cqrt_ry_<W>_controlled(f, handle, θ)` there instead of the
// unconditional `cqrt_ry_<W>(handle, θ)`. Deferring keeps every PRE-lowering
// wire walker seeing a `@cq_theta_` on the base where one will fire — an
// over-approximation of a controlled gate as unconditional, which is the safe
// direction for every staleness fence (see `TaintSet::ControlledRotations`).
//
// WHY THE FLAG STRIP IS VALID, which is the whole accept: `icmp_..._unc`
// recomputes the predicate on the CONDITION's registers and XORs it back onto
// `f`. The only register this stream relabels is the arm's base, and R4 proved
// its physical rail is disjoint from every condition rail — so the condition's
// basis at the strip is the basis the mint read, and `f` returns to |0⟩
// unconditionally (Rule 6, then `cqrt_free`).
//
// ⚠ EXCEPT WHEN R4 SAID THE OPPOSITE AND ACCEPTED ANYWAY (bd
// `test_C_libtooling-dm7f.4`, owner ruling 2026-10-03, `R.CondFlagKept`): the
// arm rotates the register the condition reads, so no strip can return `f` to
// |0⟩ and step 3 emits NEITHER the strip NOR the free. `f` is LEFT ALLOCATED,
// holding the pre-Ry predicate entangled with the register (Rule 5), and M-A's
// late guard warns at the controlled Ry. The classifier's clause at R4 carries
// the whole argument.
//
// ---- bd test_C_libtooling-l4x4, sub-increment l4x4.b — THE BARE `_Bool`
//      (RAIL-ROOT) CONDITION. `Cond` is a `Value *` because it is now either a
//      `CmpInst` or the user's own `@cq_theta_i1` CALL (`isCondRailLeaf`). For a
//      rail THREE of the four steps change and the fourth does not:
//
//        step 1  — `Flag = Cond`. NOTHING IS MINTED: the register IS its own
//                  flag, read as a control exactly as the 1b/1b-B.1 emitters
//                  read it. Byte-for-byte the substitution `emitPhaseAngleSelect`
//                  already ships for the phase stem.
//        step 2  — a NEGATED arm may NOT be `cqrt_x`-bracketed. Inc 1b's
//                  invariant is "no `cqrt_x` on a user register, EVER", and
//                  unlike the phase path there is no diagonal identity to escape
//                  through (`X·P(θ)·X = e^{iθ}P(−θ)` needs `P` diagonal; `Ry` is
//                  not). The answer is ANTI-CONTROL BY Ry ADDITIVITY — see the
//                  step-2 comment.
//        step 3  — NO strip and NO free. There is nothing to strip (nothing was
//                  minted) and freeing the user's register would be a hidden
//                  measurement: after `Ry(θ)|0⟩` it is not `|0⟩` (Rule 6). The
//                  register is LEFT ALLOCATED — the same Rule-6-safe leak the
//                  COMPARE form already gives its own condition register, and
//                  MEASURED to be so (probe `t11c`: `%h` appears in no
//                  `cqrt_free`). §2.7.
//        step 4  — UNCHANGED. M-β is a correctness requirement for a state prep
//                  and `flattenRegion` already refuses to erase a rail condition
//                  (`RegionFlatten.cpp`, the 3qlq.4 guard).
void emitInPlaceRotationRegion(const ControlRegion &R, BranchInst *BI,
                               Value *Cond, PHINode *MergePhi,
                               ArrayRef<ArmInfo> Arms, WidthDispatch &wd,
                               ControlledSymbols &csyms, TaintSet &taint) {
  // Anchor for every loud bail below. `Cond` is a `CmpInst` or a `CallInst`;
  // both are `Instruction`s, which is all `diagnoseUnderControl` needs.
  auto *CondI = dyn_cast<Instruction>(Cond);
  if (!CondI) {
    if (MergePhi)
      diagnoseUnderControl(MergePhi, "control flow");
    return;
  }
  const bool RailCond = isCondRailLeaf(Cond);
  if (!RailCond && !isa<CmpInst>(Cond)) {
    diagnoseUnderControl(CondI, "control flow");  // neither compare nor rail.
    return;
  }
  // §2.8 — THE CALLER-INDEPENDENT BACKSTOP. Only `classifyArms` runs the §13.3
  // rail ladder; this emitter has one caller today and the field is what makes
  // that a checked fact rather than a reading of the call graph. Same string the
  // gate itself used before l4x4.b, so a fixture pinning "a rail did not get
  // through" keeps its words.
  if (RailCond && !R.RailLadderProven) {
    diagnoseUnderControl(CondI, kBareRailCondReason);
    return;
  }
  // Re-validate the plan shape by SSA identity before mutating anything. A
  // silently skipped accepted region would leave the tainted `br` to the backend
  // as classical control over quantum state (Rule 1), so every bail is LOUD.
  // `R.RoutedBase` is a `WeakTrackingVH` (see `ControlPlan.h`): an earlier
  // emitter's `MergePhi->replaceAllUsesWith(...)` has already been APPLIED to it
  // if this region's base was that φ, so the comparison against the theta's
  // (equally RAUW-updated) operand below is a comparison of two live values. A
  // raw pointer here compared a FREED address against a live one and declined
  // the increment's own headline shape whenever a classical branch sat between
  // two quantum regions (round-1 review L4 §2 — the verdict depended on textual
  // block order). Null means the handle was ERASED without a replacement: no
  // routed base, no proof, decline loudly.
  Value *Base = R.RoutedBase;
  if (!Base) {
    diagnoseUnderControl(CondI, "control flow");
    return;
  }
  // Pair each arm with its recorded gate. `Shadow` belongs to `R.Arm` and
  // `ShadowFalse` to `R.ArmFalse` by FIELD identity, never by edge truth (for an
  // orientation-B diamond `R.Arm` IS the false successor and the polarity rides
  // `ArmNegated`) — the same convention the phase and value paths use.
  SmallVector<std::pair<CallInst *, bool>, 2> Gates;
  for (const ArmInfo &A : Arms) {
    ArrayRef<Instruction *> Shadow =
        A.BB == R.Arm ? ArrayRef<Instruction *>(R.Shadow)
                      : ArrayRef<Instruction *>(R.ShadowFalse);
    const ArmClass Cls = A.BB == R.Arm ? R.ClassArm : R.ClassArmFalse;
    // UNREACHABLE TODAY, AND IT DECLINES RATHER THAN SKIPS (bd drbq round-2
    // review, lens C §3; round-1 lens L4 §3 found the same dead branch on the
    // phase path). It USED to `continue` with the comment "a gate-free sibling
    // arm contributes the base unchanged" — an assertion of support that does
    // not exist. `Arms` holds one entry for a diamond (whose sole arm is
    // `InPlaceRotation`, or this emitter was not dispatched) and two for an
    // if/else, and an if/else whose sibling arm is anything else — gate-free
    // included, which classifies as PHASE (`Base == Routed`, `armBlockIsPureSpine`
    // trivially true) — declines `mixed phase/value arm` at classification in
    // BOTH processing orders (`ArmClassify`: the phase clause refuses when
    // `SawValueArm || SawRotationArm`, the rotation clause when `SawPhaseArm ||
    // SawValueArm`). So no accepted region reaches this line.
    //
    // Skipping was the WRONG backstop for the day something does reach it: the
    // skipped arm's gates would then be dropped SILENTLY by `flattenRegion`'s
    // arm-block erase — a verify-clean wrong unitary, the exact class this file
    // exists to prevent. A loud decline costs nothing (it is unreachable) and
    // fails in the Prime-Directive direction.
    if (Cls != ArmClass::InPlaceRotation) {
      diagnoseUnderControl(CondI, "control flow");
      return;
    }
    // ⚠ FOR A CONTROLLED STATE PREP (PRD §14, bd test_C_libtooling-drbq Inc 4)
    // `Base` IS THE SEED, and `T->getArgOperand(0) != Base` therefore passes by
    // IDENTITY — for a literal by UNIQUED-CONSTANT POINTER IDENTITY (LLVM uniques
    // `ConstantInt` on type+bits and `ConstantFP` on the `APFloat` bits), and
    // for a RUNTIME seed (bd z0re, 2026-09-28) by SSA identity, both slots
    // having been RAUW-updated together through `R.RoutedBase`'s tracking
    // handle. So this test is *also* a seed check here, by representation. It
    // is recorded rather than relied on: the REAL seed fence is F1 in
    // `ArmClassify`, which has its own string (`state prep seed does not match
    // the merge incoming`) and its own fixtures. This line keeps its own string
    // for the shape it is about — the plan not describing the IR (§14.2a item 1:
    // "passes for a reason nobody wrote down" is what F1 exists to retire).
    auto *T = Shadow.size() == 1 ? dyn_cast<CallInst>(Shadow.front()) : nullptr;
    if (!T || T->getParent() != A.BB || T->arg_size() < 2 ||
        T->getArgOperand(0) != Base) {
      diagnoseUnderControl(CondI, "control flow");
      return;  // the plan does not describe the IR — never emit half a region.
    }
    Gates.push_back({T, A.Negated});
  }
  if (Gates.empty()) {
    diagnoseUnderControl(CondI, "control flow");
    return;  // classification said InPlaceRotation; nothing to hoist is a bug.
  }

  const DebugLoc DL = BI->getDebugLoc();
  IRBuilder<> B(BI);  // every emitted call lands before the conditional br.
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };

  // 1. Flag mint at the BRANCH — byte-identical to the phase path's step 1. The
  //    ziov SHARED-flag position (mint at the compare) cannot arise here:
  //    `classifyArms` declines a `ShareCondFlag` region for this class.
  //
  //    ⚠ FOR A RAIL THE FLAG **IS** THE CONDITION and nothing is minted (l4x4.b,
  //    §2.1). The register is handed to `cqrt_ry_<W>_controlled` as arg-0, which
  //    is a READ-ONLY control — the one class of gate on a user register Inc 1b
  //    already emits (the 4.3 nest's node controls). It is ALWAYS ONE QUBIT:
  //    `isCondRailLeaf` is a `cq_theta_i1` result, so the rail is a
  //    `cqrt_alloc_i1` — exactly the width a minted compare flag has, and nothing
  //    about `cqrt_ry_<W>_controlled`'s tensored semantics changes. 1b-C changes
  //    WHO arg-0 is, and nothing else.
  //
  //    ⚠ MERGE (l4x4.b × Track A.1, 2026-09-11): the two sides of this line are
  //    DISJOINT and both are kept. A COMPARE condition mints a flag and carries
  //    A.1's `readKind=CondReadKind::WireRuled` — this region came through
  //    `classifyArms`, which asked `condWireDisposition` over `Prov` at round-1
  //    taint, so rung (iii)'s taint-blind exemption has a real ruling to respect.
  //    A RAIL condition mints NOTHING, so there is no `CmpCondRead` to record and
  //    no `readKind` to choose: the read is recorded on the RAIL side instead, by
  //    `markRailCondRead` at the two sites in step 2 below, and re-asked by
  //    `reverifyRailCondReads`. `reverifyCmpCondReads` iterates the recorded
  //    entries only — an absent entry is not a hole, it is a region whose
  //    condition was never a compare (the rail ladder in `classifyArms` §13.3
  //    owns it end to end).
  Value *Flag = RailCond
                    ? Cond
                    : lowerCompareToFlag(cast<CmpInst>(Cond), wd, taint,
                                         /*qqWidth=*/{},
                                         /*inverse=*/false, /*before=*/BI,
                                         /*negate=*/false,
                                         /*railToStrip=*/nullptr,
                                         /*readKind=*/CondReadKind::WireRuled);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).
  // bd dm7f.4 — THE RECORD HALF of the kept-flag postcondition
  // (`declineUndischargedKeptFlagChains`, RotationLowering.h): tag the MINT, the
  // one call no later stage replaces, so the late slot can find this region's
  // gates and ask whether the rest of the condition's chain is gone (or the
  // program's own data) when the controlled Ry fires. A rail condition never
  // carries the field (K1); a non-call flag would leave the postcondition
  // nothing to ask, so both bail loudly instead (unreachable today).
  if (R.CondFlagKept) {
    auto *Mint = dyn_cast<CallInst>(Flag);
    if (RailCond || !Mint) {
      diagnoseUnderControl(CondI, "control flow");
      return;
    }
    markKeptConditionFlag(Mint);
  }

  // 2. Per arm in successor order: HOIST the gate, bracketed in the self-inverse
  //    `cqrt_x(f)` pair for a ¬flag (FALSE-successor / else) arm — the SAME
  //    bracket `emitRoute` puts around a negated route, so the two spellings of
  //    "fires on ¬f" cannot drift.
  //
  //    ORDER: `IRBuilder` inserts before `BI` in creation order and
  //    `moveBefore(BI)` lands in the same slot, so `x; T; x` comes out in that
  //    order. Do NOT re-mint `T` — moving it keeps its `!dbg`, its identity in
  //    `taint.ThetaCalls`, and its operand USE (so the later RAUW-to-handle
  //    rewrites it like every other gate).
  //
  //    M-β — THE CHAIN, AND THE SECOND EMISSION CONVENTION IN THIS FILE (bd
  //    test_C_libtooling-drbq Inc 3, PRD §13.4). For an if/else the two hoisted
  //    gates are CHAINED in emission order: `T_f`'s arg-0 is set to `T_t`'s
  //    RESULT, so the two rotations form ONE in-place sequence on ONE rail
  //    instead of two independent readers of `Base`. `setArgOperand` (never a
  //    re-mint) is what keeps the USE rewritten, so `lowerRotations`' later
  //    `Theta->replaceAllUsesWith(Handle)` finds and fixes it exactly as it
  //    fixes every other gate operand — the final lowered IR is unchanged.
  //
  //    WHY IT IS NOT COSMETIC: `LoopLowering`'s round-2 fan-out guard counts
  //    IN-PLACE users PER RAIL VALUE (Rule 8), and two hoisted thetas both
  //    reading `Base` are two of them. Chaining makes the SSA say what is
  //    physically true — the first rotation MOVED the register, so the value
  //    after it is a different state from the value before it — and the guard
  //    then reads the truth with no exemption.
  //
  //    STRUCTURALLY UNREACHABLE, KEPT AS A LOUD DECLINE (bd drbq Inc 3, round-1
  //    lens L4, F-L4-2). `Gates` pairs each `ArmInfo` with `R.Shadow` when
  //    `A.BB == R.Arm` and with `R.ShadowFalse` otherwise, so `R.Arm ==
  //    R.ArmFalse` would put the SAME call in both slots and `setArgOperand(0,
  //    Prev)` with `Prev == G.first` would mint a SELF-REFERENCING call
  //    `%g = call @cq_theta(i32 %g, …)` — invalid SSA, which `opt`'s in-process
  //    verifier would ABORT on rather than decline. Measured unreachable:
  //    `br i1 %c, label %arm, label %arm` declines on both binaries at
  //    `tainted value muxed by a classical-condition phi`, because a 1-incoming
  //    merge φ never becomes a region. This is the same posture the
  //    `Cls != InPlaceRotation` case above was deliberately given (round-2 lens
  //    C §3): an unreachable path in this emitter gets a Prime-Directive decline,
  //    not a `continue` and not a verifier abort. Zero cost.
  //
  //    ---- l4x4.b, §2.3 OPTION A — ANTI-CONTROL BY Ry ADDITIVITY, the ONLY
  //         negation this emitter may spell on a user register.
  //
  //    The `cqrt_x(f)` bracket above is how the COMPARE path fires an arm on
  //    `¬f`, and it is FORBIDDEN here: Inc 1b's invariant is "never a `cqrt_x` on
  //    a user register" (`preservesBorrowedParent` admits an UNCONTROLLED
  //    `cqrt_rz_` on a borrowed parent BY NAME and fails CLOSED on anything else,
  //    so a bracket would freeze every chain that borrows the register), and the
  //    phase path's escape hatch does not exist for `Ry`: `X·P(θ)·X =
  //    e^{iθ}·P(−θ)` is an identity about a DIAGONAL gate.
  //
  //    So `if (!b) r = Ry(r,θ)` is emitted as
  //
  //        cqrt_ry_<W>(h_r, θ)                  ; b = 0 → Ry(θ)
  //        cqrt_ry_<W>_controlled(h_b, h_r, −θ) ; b = 1 → Ry(θ)·Ry(−θ) = I
  //
  //    which is the source's unitary on BOTH branches. Four things make it the
  //    right answer rather than a trick:
  //      * EXACT, and for a stronger reason than the Inc-2b by-difference angle
  //        select. `−θ` is an IEEE sign flip, not an `fsub`, so the whole
  //        `½ ulp(A−B)` / `kAngleSelectMaxRoundingRad` / non-finite-difference
  //        fence has NO SUBJECT and its constant-arms-only narrowing is not
  //        imported. (The one literal hazard that IS real — an `undef` angle
  //        occupying two emitted slots, bd `xy9n` — is refused in `classifyArms`,
  //        before any mutation.)
  //      * WIDTH-SAFE. `cqrt_ry_<W>` is TENSORED (`docs/backend.md` §11.3), so
  //        each of the W qubits independently sees `Ry(θ)Ry(−θ) = I`.
  //      * NO ancilla, no `cqrt_cnot`, no `cqrt_free`, NO NEW SYMBOL — and for a
  //        STATE PREP the unconditional twin acts on the FRESH rail the hoisted
  //        theta mints, so the stream is `alloc(SEED); ry(h,θ); cry(h_b,h,−θ)`.
  //      * IT IS NOT A NEW EMISSION. The cancelling gate is the ORIGINAL hoisted
  //        theta, CHAINED onto a clone of itself — the same `setArgOperand(0,
  //        Prev)` chaining M-β already performs — so `lowerRotations` lowers both
  //        through its ordinary `Chained` path and `Gates.back().first` is still
  //        the last gate in the stream, which is what M-β RAUWs the merge to.
  //
  //    ⚠ ORDER OF `taint.ThetaCalls` IS PART OF THE FIX, NOT BOOKKEEPING. The
  //    twin is inserted immediately BEFORE the original in that list, because
  //    `lowerRotations` documents (and depends on) "a chained theta N+1 takes
  //    theta N's result as its operand" — appending at the END would let the
  //    cancelling gate be lowered with an un-RAUW'd operand, i.e. a transiently
  //    broken module healed only by luck. Same hazard as H-1, same posture.
  //
  //    The COMPARE path keeps its `cqrt_x` bracket BYTE-FOR-BYTE: a minted flag
  //    is an ancilla this emitter owns, the bracket is self-inverse, and every
  //    shipped golden depends on it.
  FunctionCallee X = csyms.xFn();
  // bd `test_C_libtooling-z0re` — THE RECORD HALF of the runtime-seed L1 re-ask,
  // taken HERE, at the one emitter that commits a controlled state prep (the
  // hoist below is the irreversible step; the `ValueArmConeOps` precedent). The
  // SOURCE theta is the first gate, whose arg-0 IS `Base` (checked above) — for
  // the rail-negated arm it stays the unconditional twin and the clone becomes
  // the cancelling gate, so capturing it BEFORE the loop names the right call in
  // both spellings. Recorded only for a RUNTIME seed (a literal can never turn
  // quantum, and the rail bank's preallocated seed is compiler-owned and adopted
  // by `lowerRotations` through `isRailBankSeedAlloc`, not through taint) — and
  // KEYED ON THE CLASSIFIER'S VERDICT (`R.RuntimeSeedAdmitted`), NOT on
  // `isRuntimeStatePrepSeed(Base, taint)` asked here. ⚠ The first spelling asked
  // the taint HERE and it MISSED the very case the record exists for: a 6.5
  // region emitted earlier in this loop had already RAUW'd the seed to its
  // tainted `%out`, so "is it untainted now?" answered no, nothing was recorded,
  // and `…_runtime_seed_round2_quantum.ll` ACCEPTED an unvetted in-place Ry on
  // `%out` (measured, TRACK_Z0RE.md §7).
  CallInst *SourceTheta = Gates.front().first;
  if (R.RuntimeSeedAdmitted)
    taint.RuntimeSeedSourceThetas.push_back(SourceTheta);
  CallInst *Prev = nullptr;
  for (auto &G : Gates) {
    if (Prev == G.first) {
      diagnoseUnderControl(CondI, "control flow");
      return;
    }
    if (RailCond && G.second) {
      // `classifyArms` admits at most ONE content arm for a rail, so `Prev` is
      // null here; the check is the Rule-1 shape, not a live protection.
      if (Prev) {
        diagnoseUnderControl(CondI, kBareRailCondReason);
        return;
      }
      CallInst *T = G.first;
      Value *Angle = T->getArgOperand(1);
      CallInst *TNeg = cast<CallInst>(T->clone());
      // The UNCONDITIONAL twin is `T` itself, left at angle θ and moved into the
      // pred exactly as an un-negated arm's gate is; the CLONE becomes the
      // cancelling controlled gate, chained onto it.
      T->moveBefore(BI);
      TNeg->setArgOperand(0, T);
      if (auto *CF = dyn_cast<ConstantFP>(Angle)) {
        APFloat Neg = CF->getValueAPF();
        Neg.changeSign();  // EXACT: a sign-bit flip, never an `fsub`.
        TNeg->setArgOperand(1, ConstantFP::get(Angle->getType(), Neg));
      } else {
        // A CLASSICAL run-time angle (R2 proved it is not tainted). `fneg` is
        // exact for every finite, infinite and NaN input, so no rounding fence
        // has a subject here either.
        IRBuilder<> NB(BI);
        Value *N = NB.CreateFNeg(Angle, "cqnegangle");
        if (auto *NI = dyn_cast<Instruction>(N))
          NI->setDebugLoc(T->getDebugLoc());
        TNeg->setArgOperand(1, N);
      }
      TNeg->insertBefore(BI);
      stamp(TNeg);
      taint.Tainted.insert(TNeg);
      // Insert into `ThetaCalls` immediately AFTER `T` (see the ⚠ above).
      auto It = llvm::find(taint.ThetaCalls, T);
      taint.ThetaCalls.insert(It == taint.ThetaCalls.end() ? It : std::next(It), TNeg);
      taint.ControlledRotations[TNeg] = Flag;
      markRailCondRead(taint, Flag, TNeg);
      G.first = TNeg;  // M-β's RAUW target is the LAST gate in the stream.
      Prev = TNeg;
      continue;
    }
    if (!RailCond && G.second)
      stamp(B.CreateCall(X, {Flag}));
    G.first->moveBefore(BI);
    if (Prev)
      G.first->setArgOperand(0, Prev);
    taint.ControlledRotations[G.first] = Flag;
    // ---- l4x4.b §2.9 — THE FIFTH `markRailCondRead` SITE. The hoisted theta
    // BECOMES `cqrt_ry_<W>_controlled(h_b, …)`, i.e. this region's first (and
    // only) `cqrt_*` READ of the user's register, so `reverifyRailCondReads`
    // must re-ask rungs (ii)+(iii) against it once taint is final. Forgetting
    // this call re-opens F-B1R2-1 — a CONFIRMED plain-C silent miscompile, `opt`
    // exit 0, verify-clean, stage-2b clean — WITH NO DIAGNOSTIC ANYWHERE. The
    // read point is a still-standing `@cq_theta` at the re-verification's slot
    // (`CQLoweringPass` runs it BEFORE `lowerRotations`), which is what the
    // record needs.
    if (RailCond)
      markRailCondRead(taint, Flag, G.first);
    Prev = G.first;
    if (!RailCond && G.second)
      stamp(B.CreateCall(X, {Flag}));
  }

  // 3. Flag strip + free — byte-identical to the phase path's. Reads
  //    `Cond`'s operands, so it MUST precede the erase of `Cond` (in
  //    `flattenRegion`).
  //
  //    RECORDED as a DISCHARGED FLAG GATE, and the licence is R4, named: the
  //    phase (kickback) path records its strip because it moves no condition
  //    register's basis label, so an interior `_unc` placed after the strip reads
  //    the wire its forward chain read. This path deliberately DOES
  //    relabel its base — but only its base, and R4 proved that rail is disjoint
  //    from every rail the condition's derived chain lives on. So the same
  //    property holds for the same reason, by a different argument. If R4 is
  //    ever widened, THIS recording is one of the things that must be re-proved.
  //    (bd dm7f.4 widened it, and the re-proof is that the widened case emits
  //    no strip at all, so there is nothing to record; see `CondFlagKept` below.)
  //
  //    ⚠ AMENDED 2026-09-05 (round-1 Rule-13 review, lens L5 finding F-L5-2).
  //    FOR A CONTROLLED STATE PREP (Inc 4) R4 IS NOT WIDENED — IT IS **SKIPPED**
  //    (`ArmClassify`'s `if (!StatePrep)` wrapper around the two
  //    `railWireClosure` calls), so "R4 proved" is not the ground on that path.
  //    The licence there is STRUCTURAL and strictly stronger: the relabelled rail
  //    is minted by the hoisted `T` ITSELF — a `cqrt_alloc_<W>` emitted inside
  //    this region's own stream — so no pre-region SSA name for it exists and
  //    disjointness from the condition's chain is a property of construction
  //    rather than of a walk. MEASURED end-to-end on a derived condition that
  //    actually exercises this discharge (`if (sqrt(q+3.) <= 3.5) { r = 0;
  //    cq_theta(&r,.9); }`): the whole `sitofp/fadd/sqrt/fcmp` chain discharges in
  //    LIFO order after the strip, strict stage 2b 8 verified / 0 violations, and
  //    the trace reduces byte-for-byte to the chained twin's on the pre-Inc-4
  //    binary. The sentence above still governs the CHAINED class, where R4 does
  //    run.
  //
  //    ⚠ BOTH ARE SKIPPED WHOLE FOR A RAIL (l4x4.b §1.3 / §2.7), and each half
  //    has its own reason:
  //      * THE STRIP has no subject. It exists to return a MINTED ancilla to
  //        |0⟩ by recomputing the compare; nothing was minted, and the register
  //        carries the user's state, not a predicate.
  //      * THE FREE WOULD BE A HIDDEN MEASUREMENT. `cqrt_free` is a hardware
  //        reset and may be emitted ONLY where the rail is provably |0⟩ (Rule 6).
  //        A condition rail is `Ry(θ)|0⟩ ≠ |0⟩` by construction — it is the
  //        user's `_Bool`. So the register is LEFT ALLOCATED, which is the
  //        REQUIRED direction and not a shortfall.
  //    WHAT THE WHOLE-DAG SPINE THEN DOES WITH IT, read off the three predicates
  //    that decide a rail's fate rather than argued: `isInPlaceGateOn` answers
  //    FALSE for arg-0 of a `_controlled` gate (it requires arg-1 == H) and the
  //    generic `_controlled` bail refuses it outright, so `isTerminalHandle` hits
  //    `return false` and the spine NEVER CLAIMS the register; and
  //    `preservesBasisUnderRecord`'s disqualify list names every `_controlled`
  //    gate, so it is never an M-B interior candidate either. Net: not freed, not
  //    reversed, not adjointed — exactly the disposition the COMPARE form already
  //    gives its own condition register (MEASURED, probe `t11c`: `%h` appears in
  //    no `cqrt_free`). If the register is also MEASURED — the flagship program —
  //    its `cqrt_measure_i1` is an ordinary sink and nothing here changes.
  //    ⚠ `railCarriesControlledRotation` freezes arg-1 (the ROTATED rail), NOT
  //    arg-0; the asymmetry is deliberate and is the only thing standing between
  //    a user register as a control and an M-B interior discharge (§2.7, H-9).
  //
  //    ⚠ AND BOTH ARE SKIPPED FOR A KEPT COMPARE FLAG (bd dm7f.4,
  //    `R.CondFlagKept`, set only by `classifyArms`' R4 clause). The strip would
  //    recompute the predicate on the register the hoisted gate just rotated, so
  //    it would not return `f` to |0⟩ and the free after it would be a hidden
  //    measurement of an entangled ancilla — the exact defect R4 was written to
  //    refuse. Without the strip there is no `DischargedFlagGates` record, so
  //    the spine's interior discharge of a TEMPLATE condition chain lands after
  //    the mint and BEFORE the controlled Ry (measured on `(q & 3) == 1` and a
  //    `sitofp`/`fmul`/`fcmp` chain). Not every chain gets one: a lifted call's
  //    `__cq_q_*` result does not (bd ln16), and the late postcondition
  //    `declineUndischargedKeptFlagChains` refuses such a region loudly (review
  //    round 1, F1). The flag itself is never claimed: its only
  //    user is arg 0 of a `_controlled` gate (`isTerminalHandle` and
  //    `isInteriorConsumer` both refuse that), so it stays allocated, and M-A
  //    reports it at the gate.
  if (!RailCond && !R.CondFlagKept) {
    auto *Strip = dyn_cast_or_null<CallInst>(lowerCompareToFlag(
        cast<CmpInst>(Cond), wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
        /*before=*/BI, /*negate=*/false, /*railToStrip=*/Flag));
    if (Strip)
      taint.DischargedFlagGates.insert(Strip);
    stamp(B.CreateCall(wd.freeFn(), {Flag}));
  }

  // 4. Rewire + erase + scrub, then flatten. The merge φ now denotes the base
  //    register itself — BOTH incomings name the ONE physical rail, exactly as
  //    for a phase arm; what differs is that this rail has been RELABELLED on
  //    the `f=1` branch, which is why R6 refuses any pre-region SSA record of it
  //    that is read after the region. The hoisted thetas are NOT erased here:
  //    they are live instructions in the pred that `lowerRotations` owns.
  //
  //    ⚠ FOR A CONTROLLED STATE PREP (Inc 4, PRD §14.4) M-β IS A CORRECTNESS
  //    REQUIREMENT, NOT THE LOOP-BOOKKEEPING CONVENIENCE IT IS FOR INC 3, and
  //    the state-prep class rides it UNCHANGED because the Ry stem already does
  //    M-β for every `InPlaceRotation` arm. There `Base` is the SEED `Constant`:
  //    the Rz stem's M-α (`RAUW(m → Base)`) would RAUW the merge to the literal
  //    and every consumer of `r` would become a classical `i32 0` — a SILENTLY
  //    CLASSICAL PROGRAM, verify-clean, with the controlled gate still emitted
  //    onto a rail nothing reads. `lowerRotations` then RAUWs `T`'s result to
  //    the fresh alloc handle, so the merge ends up denoting the PREPPED RAIL,
  //    which is what the source's `r` means. Pinned by
  //    control_inplace_ry_stateprep_then_uncond_theta.ll (a post-region
  //    `cq_theta` on `r` lands on the SAME rail under M-β and would have minted a
  //    SECOND, unrelated rail under M-α) and it is the one mutation whose failure
  //    mode is silent — check the lowered IR, not the exit code.
  //
  //    ⚠ TWO RAUW CONVENTIONS LIVE IN THIS FILE, ONE PER STEM, AND WHICH IS
  //    WHICH IS LOAD-BEARING (bd drbq Inc 3, PRD §13.4 + the §12.1 stem table).
  //
  //      Ry — THIS emitter — RAUWs the merge φ to the LAST HOISTED GATE (M-β).
  //      Rz — `emitRegion`'s §6a peephole — RAUWs it to the BASE `Q` (M-α), as
  //           shipped by Inc 2a (since 3qlq it sees only the retired form).
  //
  //    The reason is the physics, not taste. A controlled Rz is
  //    DIAGONAL: the two names denote the same computational-basis state, so
  //    either target is correct and the base is the cheaper one. An Ry MOVES the
  //    register on the `f=1` branch, so the post-gate value is genuinely a
  //    different state and naming it `Base` is a false statement in SSA. Flat,
  //    that falsehood is harmless (the value is dead after `lowerRotations`
  //    collapses everything onto one handle); INSIDE A LOOP it is not, and both
  //    ways it fails are `LoopLowering` bookkeeping rather than a unitary:
  //      * with no post-region gate, `RAUW(m → Base)` makes the loop's carry a
  //        ZERO-HOP IDENTITY CARRY `%P = phi [%r0, entry], [%P, latch]`, which
  //        `recordRefreshedByDef` correctly calls FROZEN (bd
  //        [[identity-carry-phi-does-not-refresh]]) — so `railGateBetween` takes
  //        no cut and the increment's own target shape declines LOUDLY;
  //      * with one, `%P` acquires TWO in-place `cq_theta` users and the round-2
  //        fan-out guard fires `loop-carried rail has multiple in-place
  //        consumers`.
  //    Under M-β the chain is `%P → T → (post-region gate) → %P`: `T` is a chain
  //    MEMBER, so it is in the SKIP set (its own execution IS the wire moving),
  //    it is in `Gates` (it IS a relabelling gate — correct), `%P`'s carry
  //    crosses it so the record refreshes, and every rail value has ONE in-place
  //    user. No predicate is edited and no licence is granted anywhere.
  //
  //    ⚠ "`T` IS A CHAIN MEMBER" HOLDS ONLY WHEN `T`'s RESULT IS CARRIED, and
  //    the narrowing is recorded rather than the sentence trimmed (bd drbq Inc 3,
  //    round-1 lens L2, L2-F2). The chain is built by peeling in-place steps from
  //    the carried latch value, so a region whose merge value is NOT carried
  //    around the back edge — e.g. the region rotates a FROZEN identity-carry φ —
  //    joins the closure by the FORWARD extension instead: `T` is then in `Gates`
  //    and in `OnRailOut` (a RECORD) but NOT in `MemberSet` (the SKIP set). No
  //    defect follows today, and the reason is measured, not assumed: that shape
  //    declines at `ArmClassify`'s R6 before `collapseRailPhisIn` ever runs
  //    (lens L2 `s01_frozen_base_region`). A future widener must not read the
  //    sentence above as an invariant — it is a property of the CARRIED case.
  //
  //    THE ALTERNATIVE WAS REJECTED FOR A NAMED REASON: M-α + widening
  //    `LoopLowering::isHoistedRegionArmGate` to the Ry stem needs TWO
  //    independently-written licences over ONE closure (an exemption from the
  //    fan-out count that `collectRailGates::noteGate` would still contradict for
  //    staleness), which is the bd 8h7d.5 F-1/F-3 shape verbatim — and its
  //    refresh licence would rest on `ArmClassify`'s R6 refusing the alias shape,
  //    i.e. a fence in ANOTHER FILE (bd
  //    [[mint-at-consumer-window-protection-lives-elsewhere]]).
  //
  //    `T` DOMINATES THE MERGE: it was hoisted into `Pred`, which dominates
  //    `MergeBB`, so the RAUW is well-formed. `lowerRotations` then RAUWs every
  //    hoisted theta's result to its arg-0 handle exactly as today, so the FINAL
  //    LOWERED IR IS IDENTICAL under either convention — which is what makes the
  //    whole-corpus lowered-IR diff against the pre-Inc-3 oracle a real witness.
  //
  // ---- ⚠ A FENCE IN ANOTHER FILE DEPENDS ON **WHAT THIS RAUW TARGETS**, not
  //      just on the target dominating the merge (bd `test_C_libtooling-om35`,
  //      round-2 Rule-13 review F-F2-1). `ArmClassify.cpp`'s F2 conjunct
  //      `!PhiDesc.count(V)` excludes the SSA user closure of a state-prep
  //      region's OWN merge φ, and its soundness across the TWO detection
  //      rounds (`repropagateControlMerges`) rests on this line targeting a
  //      value that was ALREADY reachable from the φ it replaces — here
  //      `Gates.back().first` is the arm theta `T`, or the re-chained `T2`, or
  //      the negated clone `TNeg` over `T`, and `inPlaceRotationArmTheta`
  //      (its `hasOneUse` check) made `MergePhi` that theta's SOLE USER. So the
  //      RAUW re-parents users of the φ onto something they already reached
  //      through it and no other region's closure grows.
  //
  //      **RETARGET THIS RAUW TO ANYTHING THAT IS NOT A DESCENDANT OF ONE OF
  //      `MergePhi`'s OWN INCOMINGS — a fresh `select` over the condition, say,
  //      the shape `:536` and `MergePhiPeel.cpp:559` have — AND THAT F2
  //      CONJUNCT MUST BE RE-DERIVED**, not merely re-run. The tripwires are
  //      `ir-pass/test/control_inplace_ry_reject_stateprep_mbeta_base_
  //      offcone.ll` and `…_mbeta_ifelse_rechain.ll`: if either turns into an
  //      ACCEPT, this is the line that did it. Relaxing the `hasOneUse` in
  //      `inPlaceRotationArmTheta` (ArmClassify.cpp) fires the same trigger.
  MergePhi->replaceAllUsesWith(Gates.back().first);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  flattenRegion(R, taint);
}

// Lower one accepted `classifyArms` region — a one-content-arm DIAMOND (§5a) or
// a two-arm IF/ELSE (§5b) — into the pred block before the conditional `br`.
// VALUE arms go to `emitValueRegion`, IN-PLACE ROTATION arms (and every bare
// `_Bool` rail condition) to `emitInPlaceRotationRegion`. The phase-stream path
// after them collects `@cq_phi_<sfx>` arm gates, i.e. only the RETIRED register
// form, whose use `resolveSources` declines first (bd 3qlq); a register-free
// `cq_phi` arm is claimed by `classifyPhaseKickback` and lowered by kickback.
// On that path the true arm fires on flag, the false arm on ¬flag via the
// self-inverse `cqrt_x` bracket (Q = the straight-through or shared spine base).
void emitRegion(const ControlRegion &R, WidthDispatch &wd,
                ControlledSymbols &csyms, TaintSet &taint) {
  // ---- bd test_C_libtooling-l4x4 (l4x4.b). `R.Condition` may now be a BARE
  // `_Bool` REGISTER (`isCondRailLeaf`) instead of a `CmpInst`, but ONLY for the
  // control-in-place ROTATION class — `classifyArms` re-declines every other arm
  // class on a rail (§2.6). So the rail is dispatched to
  // `emitInPlaceRotationRegion` BEFORE the `CmpInst` cast below, and every path
  // that follows still sees a real compare. `RailCondI` is non-null exactly when
  // the condition is a rail.
  auto *RailCondI = isCondRailLeaf(R.Condition)
                        ? dyn_cast_or_null<CallInst>(R.Condition)
                        : nullptr;
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  if (RailCondI) {
    auto *RailMergePhi = dyn_cast_or_null<PHINode>(R.Merge);
    auto *RailBI = R.Pred ? dyn_cast<BranchInst>(R.Pred->getTerminator())
                          : nullptr;
    if (!RailMergePhi || !R.Pred || !R.Arm || !RailBI ||
        (R.ClassArm != ArmClass::InPlaceRotation &&
         R.ClassArmFalse != ArmClass::InPlaceRotation)) {
      // Loud, never a silent skip: a rail-condition region that reaches the
      // emitter with a plan describing anything else must not be handed to the
      // backend as classical control over quantum state (Rule 1).
      diagnoseUnderControl(RailCondI, "control flow");
      return;
    }
    SmallVector<ArmInfo, 2> RailArms;
    if (R.ArmFalse) {
      RailArms.push_back({R.Arm, /*Negated=*/false});
      RailArms.push_back({R.ArmFalse, /*Negated=*/true});
    } else {
      RailArms.push_back({R.Arm, R.ArmNegated});
    }
    emitInPlaceRotationRegion(R, RailBI, RailCondI, RailMergePhi, RailArms, wd,
                              csyms, taint);
    return;
  }
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
  SmallVector<ArmInfo, 2> Arms;
  if (R.ArmFalse) {
    Arms.push_back({R.Arm, /*Negated=*/false});
    Arms.push_back({R.ArmFalse, /*Negated=*/true});
  } else {
    Arms.push_back({R.Arm, R.ArmNegated});
  }

  // 4.2 VALUE path (§5d/§5e, the select merge since 3qlq): classifyArms
  // recorded the per-arm class + ordered chain (Shadow/ShadowFalse, FORWARD
  // order — by FIELD identity: for an orientation-B diamond R.Arm is the FALSE
  // successor and polarity rides ArmNegated). This dispatch MUST precede the
  // phase-stream collection: a value arm has no cq_phi gates, so falling through
  // would hit the identity-region RAUW — a verify-clean silent wrong answer. The
  // value emitter validates the plan shape and derives its own base handle (an
  // if/else merge has no Pred edge to read it from).
  if (R.ClassArm == ArmClass::Value || R.ClassArmFalse == ArmClass::Value) {
    emitValueRegion(R, BI, Cond, MergePhi, wd, csyms, taint);
    return;
  }

  // CONTROL-IN-PLACE ROTATION path (control-in-place-PRD §6, bd
  // test_C_libtooling-drbq Inc 1). Dispatched HERE for the same reason the value
  // path is: a rotation arm has no `cq_phi` gates, so falling through to the
  // phase-stream collection would find an empty stream and hit the
  // identity-region RAUW — a verify-clean silently WRONG answer (the arm's Ry
  // would be dropped and the merge rewired to the untouched base).
  if (R.ClassArm == ArmClass::InPlaceRotation ||
      R.ClassArmFalse == ArmClass::InPlaceRotation) {
    emitInPlaceRotationRegion(R, BI, Cond, MergePhi, Arms, wd, csyms, taint);
    return;
  }

  // FROM HERE ON every arm is a retired `@cq_phi_<sfx>` spine (see the header);
  // the prose below records the drbq Inc 2a design of this path.
  //
  // The base handle Q: a diamond's straight-through (Pred-edge) incoming, or —
  // for an if/else, which has no Pred edge — the shared phase-spine base the arms
  // rotate. Never read width/identity off Q's SSA type (§4 width-source); Q is
  // only the gates' arg-0 anchor and the merge's RAUW target.
  //
  // 4.5 WI-5 (eq-fold re-anchor): when `clang -O1` const-folds an `if(q==k)`
  // arm's gate base to the literal `k`, classifyArms recorded the PROVEN base
  // handle in `R.RoutedBase` — PREFER it. The eq-fold IF/ELSE has no Pred edge
  // AND its first arm's `phaseSpineBase` bottoms at the folded constant `k`, so
  // the default derivation would anchor on (and RAUW the merge to) a CONSTANT — a
  // verify-clean wrong unitary (the measure-operand guard only catches it when
  // the merge happens to feed a measure; an escaping merge would miscompile
  // silently). `R.RoutedBase` is null for every non-eq-fold region, so the
  // default path below is byte-identical there.
  //
  // ⚠ `RoutedBase` IS A `WeakTrackingVH` and it may be null for TWO different
  // reasons (round-1 Rule-13 review L4 §1, a CONFIRMED SIGSEGV). Never recorded
  // ⇒ derive, as before. RECORDED AND SINCE ERASED ⇒ the handle this region was
  // proven to rotate no longer exists, and falling through to the derivation
  // would anchor on the folded constant — exactly the miscompile this field
  // prevents. That case declines LOUDLY. (Before the handle, a raw `Value *`
  // here was simply DEREFERENCED after the earlier region's
  // `MergePhi->eraseFromParent()`, which is the crash.)
  //
  // ⚠ AN UNFIXTURABLE BACKSTOP — KEEP IT, and here is why it cannot have a
  // Rule-12 fixture and why the NULL test is nonetheless the RIGHT test (bd drbq
  // round-2 review, lens C §4, which set out to refute it and failed). Every way
  // a `WeakTrackingVH` can go null was enumerated:
  //   * every merge-φ collapse RAUWs BEFORE erasing (this file's four sites,
  //     `RegionFlatten`, `SelectMergeEmit`, `ClassicalCallArmEmit`,
  //     `SwitchRouteEmit`, `SwitchValueEmit`, `SwitchDataMuxEmit`), so the handle
  //     MOVES and never nulls;
  //   * the erase-WITHOUT-RAUW sites are the condition compare — all
  //     `use_empty`-guarded, and a routed base is never a compare anyway (the
  //     eq-fold records the compare's OPERAND) — and the arm/`Mid` BLOCK erases.
  //     A value defined in an arm block dominates nothing outside it (its only
  //     successor is a 2-predecessor merge) so it cannot be another region's
  //     routed base, and a nested pair's in-`Mid` derivation is declined outright
  //     by `RegionTreeDetect`'s `RailClosure` gate.
  // The one thing that looked like a hole and is not: a block erase does NOT
  // leave the handle pointing at `poison`. `BasicBlock::eraseFromParent()`
  // destroys each contained `Instruction` through `Value::~Value()`, which calls
  // `ValueHandleBase::ValueIsDeleted` and NULLS a `WeakTracking` handle — so a
  // corpse cannot slip past a null test. (`Utils`' `DeleteDeadBlock` is the
  // RAUW-to-poison path, and it is not what runs here.)
  // Precedent for a kept, unfixturable backstop: `lowerControlRegions`' Kahn
  // cycle decline.
  if (R.RoutedBaseRecorded && !R.RoutedBase) {
    diagnoseUnderControl(Cond, "control flow");
    return;
  }
  Value *Recorded = R.RoutedBase;
  Value *Q = Recorded ? Recorded
             : MergePhi->getBasicBlockIndex(R.Pred) >= 0
                 ? MergePhi->getIncomingValueForBlock(R.Pred)
                 : phaseSpineBase(MergePhi->getIncomingValueForBlock(R.Arm),
                                  R.Arm);

  // Per-arm ordered phase gates. A gate-free arm (`if (q) {}`, or an empty else)
  // contributes Q unchanged, so there is nothing to control — skip it (no gate,
  // no bracket). The pre-2a route skipped exactly the same arms for exactly the
  // same reason (routing a gate-free arm is a no-op cswap pair), so this is not
  // a behaviour change: an arm that contributed nothing then contributes nothing
  // now.
  //
  // There is no `AllPhis` list any more: the gates are HOISTED, not re-minted and
  // erased, so nothing is collected for a post-rewire erase pass (step 4).
  SmallVector<ArmStream, 2> Streams;
  for (const ArmInfo &A : Arms) {
    SmallVector<CallInst *, 4> Phis =
        collectArmPhis(MergePhi->getIncomingValueForBlock(A.BB), A.BB);
    if (Phis.empty())
      continue;
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

  // ABI width from the FIRST gate's `cq_phi_` suffix — the rotation width (all
  // arms rotate the same-width base handle, by classifyArms). The base handle
  // MAY be a value DERIVED before the region (its own suffix is unreliable), so
  // never read width off Q (§4 width-source).
  //
  // THE WIDTH FENCE IS NOW `abiWidthHasControlledRotation`, not `rzRtFn`/`allocFn`
  // (bd test_C_libtooling-drbq Inc 2a): the stream this path emitted was
  // `cqrt_rz_<W>_controlled`, so the width that must exist is the CONTROLLED one.
  // MEASURED to be a strictly equal set on this frontend, not a narrowing:
  // `abiWidthFor` maps every `cq_phi_<sfx>` spelling `CQ.h` exposed into
  // {i1,i8,i16,i32,i64,f16,f32,f64,f80} (`WidthDispatch.cpp`'s `kRows`), which is
  // exactly `abiWidthHasControlledRotation`'s set — `i80`/`i128` are intermediate
  // widths no `cq_phi` suffix names. So this is detect-before-mutate defence in
  // depth against hand-written IR, and it is asked with the SAME predicate the
  // minter (`ControlledSymbols::controlledRotationFn`) gates on (Rule 14).
  StringRef Abi =
      wd.abiWidthFor(intrinsicSuffix(Streams.front().Phis.front(), "cq_phi_"));
  if (Abi.empty() || !abiWidthHasControlledRotation(Abi)) {
    // Unsupported width past detection — decline LOUDLY (a silent leave-in-
    // place would hand the tainted `br` to the backend as classical control
    // while the later rotation lowering fires the arm gates unconditionally).
    diagnoseUnderControl(Cond, "control flow");
    return;
  }

  // THE §5 CONST-FOLD RE-ANCHOR IS **VALIDATED HERE, BEFORE ANY MUTATION**, and
  // only APPLIED in the emission loop below (bd drbq Inc 2a, round-1 review
  // L1 F-5 = L2 N-1). It used to be one fused test-and-assign inside the
  // emission loop, where the decline could fire AFTER the flag mint, after a
  // lone `cqrt_x` opener, and after a previous arm's gates had been hoisted and
  // recorded in `taint.ControlledRotations` — i.e. a loud reject on a HALF-
  // EMITTED region, which Rule 1 ("lower nothing") forbids and which the sibling
  // `emitInPlaceRotationRegion` states as its own invariant ("never emit half a
  // region", all four of its bails precede its flag mint). No reaching program
  // was found — `classifyArms` proves `Base == Routed` per arm so the assignment
  // is a no-op for every non-folded shape, and the eq-fold path re-anchors
  // `Region.RoutedBase` to the very handle the arm rotates — but "unreachable by
  // argument" is exactly the class this project's history says does get reached,
  // and the fix is one read-only loop. Every decline in `emitRegion` now precedes
  // the first emitted instruction.
  //
  // WHAT IS VALIDATED (the fence itself is unchanged, only its position): a first
  // spine gate whose arg 0 is neither `Q` nor a `Constant` is a shape
  // classification did not prove, and it declines LOUDLY rather than being
  // silently re-anchored — which would be a data-mux rewrite. The diagnostic
  // string is character-identical to the one the fused form emitted, so the
  // negative fixtures are unmoved.
  for (const ArmStream &S : Streams) {
    Value *A0 = S.Phis.front()->getArgOperand(0);
    if (A0 != Q && !isa<Constant>(A0)) {
      diagnoseUnderControl(Cond, "control flow");
      return;
    }
  }

  const DebugLoc DL = BI->getDebugLoc();
  IRBuilder<> B(BI);  // every stream call lands before the conditional br.
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };

  // 1. Flag mint — cq_template_icmp_<pred>_<W>_hl(q, lit). On the ziov share path
  //    (R.ShareCondFlag — the condition is ALSO read as data) the flag is minted
  //    at the COMPARE's position so it DOMINATES every data use (a data `zext` may
  //    precede the gate stream); otherwise it lands at the branch as before.
  Instruction *FlagAt = R.ShareCondFlag ? Cond->getNextNode() : BI;
  // (Track A.1, F-A1R2-1) `WireRuled`: `classifyArms` asked
  // `condWireDisposition` over this region's `Prov` at round-1 taint.
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/FlagAt,
                                   /*negate=*/false, /*railToStrip=*/nullptr,
                                   /*readKind=*/CondReadKind::WireRuled);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported / Q+Q).

  // ziov WI-1: share THIS flag with the data use. Record it (do NOT RAUW) so
  // `lowerOps`'s rewriteCompare REUSES it for the surviving data-position compare
  // instead of minting a SECOND flag (the ziov bug). Recording — not RAUWing here
  // — defers the i1→i32 launder to lowerOps Phase 2, AFTER Phase 1 captures the
  // data casts' i1 source width (RAUWing now would corrupt `zext i1→i32` into a
  // templateless `zext i32→i32`). The eager strip+free (step 3) is SKIPPED
  // below: the data lineage owns the handle (escaped/measured, classifyArms-
  // proven) — stripping/freeing it is a read-after-collapse / hidden measurement.
  if (R.ShareCondFlag)
    taint.SharedCondFlags[Cond] = Flag;

  // 2. THE ARM GATES, CONTROL-IN-PLACE (control-in-place-PRD §12.2, bd
  //    test_C_libtooling-drbq Inc 2a — the §6a peephole, default-on for this FLAT
  //    path). Per arm in successor order, HOIST the arm's `cq_phi` spine to just
  //    before the branch and record each gate against the flag it must fire under;
  //    `lowerRotations` minted `cqrt_rz_<W>_controlled(f, handle, θ)` there until
  //    3qlq deleted its PHI loop (it mints no `cqrt_rz_<W>` of any form now).
  //
  //    WHAT THIS REPLACES, exactly — the route QUINTUPLE, per arm:
  //        cqrt_alloc_<W>(0) -> rail ; cqrt_cswap(f, q, rail)
  //        ; cqrt_rz_<W>(rail, θ) ; cqrt_cswap(f, q, rail) ; cqrt_free(rail)
  //    becomes ONE `cqrt_rz_<W>_controlled(f, q, θ)` per gate. The flag mint, the
  //    `cqrt_x` bracket, the strip and the flag free are byte-identical and in the
  //    same order; NOTHING else moves. That is the whole claim, and
  //    `tools/golden_multiset_audit.py` is what checks it per golden.
  //
  //    THE TWO ARE THE SAME UNITARY, and it is an identity rather than an
  //    approximation: with `w = |0⟩`, `cswap(f,q,w) · Rz_w(θ) · cswap(f,q,w)`
  //    applies `Rz(θ)` to `q` exactly on the `f=1` branch and, on `f=0`, applies
  //    `Rz(θ)` to a rail still holding `|0⟩` — which under the project's
  //    `Rz = diag(1, e^{iθ})` convention is the identity with NO global-phase
  //    residue. So `cRz(f, q, θ)` is equal, not merely equivalent up to phase.
  //    (This is exactly why the Ry stem could never route — PRD §2 —, and it is
  //    also why the peephole is a peephole here and the MECHANISM there.)
  //
  //    THE `cqrt_x` COUNT IS THE ONE THING THAT DOES CHANGE, AND IT MUST BE SAID
  //    OUT LOUD because PRD §9.2's literal wording ("the `cqrt_x` brackets …
  //    unchanged") does not survive contact with a NEGATED arm. The route
  //    bracketed EACH of its two `cqrt_cswap`s, so a ¬flag arm carried FOUR
  //    `cqrt_x(f)`; this path brackets the arm's gate run ONCE, so it carries
  //    TWO. The bracket is still the same self-inverse pair on the same flag in
  //    the same place — there are simply two fewer of them because there are two
  //    fewer gates to bracket. The audit models that arithmetic explicitly
  //    (`-2 cqrt_x` per collapsed NEGATED arm) rather than waiving it.
  //
  //    HOIST-AND-DEFER, not emit-here (PRD §6, and the Inc-1 recipe verbatim):
  //    keeping the `@cq_phi_` call alive until `lowerRotations` means every stage
  //    between here and there — `collapseFlattenedLoopRails`, `lowerIOSinks`,
  //    `lowerQramReads`, `lowerShadowMemory`, `declineClassicalMuxes`,
  //    `specialize`, `declineLiftedStaleRecordOps` — keeps seeing the SAME
  //    pre-lowering vocabulary it saw before this increment: a diagonal `cq_phi`
  //    on the register, at arg 0. `LoopLowering::collectRailGates` in particular
  //    follows a `cq_phi` as a RAIL HOP that is not a gate (Rz is diagonal), which
  //    is the reading the 8h7d.5 rolled-loop fences were cleared under.
  //
  //    ORDER: `IRBuilder` inserts before `BI` in creation order and
  //    `moveBefore(BI)` lands in the same slot, so `x; rz…; x` comes out in that
  //    order. Do NOT re-mint the gate — moving it keeps its `!dbg`, its identity
  //    in `taint.PhiCalls`, and its operand USE (so the later RAUW-to-handle
  //    rewrites it like every other gate).
  FunctionCallee X = csyms.xFn();
  for (ArmStream &S : Streams) {
    if (S.Negated)
      stamp(B.CreateCall(X, {Flag}));
    // THE §5 CONST-FOLD RE-ANCHOR, AND IT IS LOAD-BEARING HERE IN A WAY IT IS
    // NOT ON THE ROUTE (bd drbq Inc 2a). The route read ONLY arg 1 (the angle)
    // off the arm gate and put the rotation on its own work rail, so an arm
    // whose `cq_phi_` bottoms at a folded `ConstantInt k` (the 4.5 `tryEqFoldArm`
    // shape: `clang -O1` proves `q == k` inside the arm and value-propagates it)
    // routed correctly with no re-anchor at all. Hoist-and-defer reads arg 0:
    // `lowerRotations`' phi loop would see an UNTAINTED operand, emit NOTHING,
    // and RAUW the gate to the constant — the arm's Rz silently DROPPED, a
    // verify-clean wrong unitary. `Region.RoutedBase` is the handle
    // `tryEqFoldArm`/`straightThroughConstFoldHandle` PROVED the arm rotates, and
    // `Q` is it; re-anchoring arg 0 to `Q` is the same move `SwitchRouteEmit`
    // made "by physics" for the pre-3qlq switch spine.
    //
    // FENCED, because a silent re-anchor of anything else would be a data-mux
    // rewrite: a first spine gate whose arg 0 is neither `Q` nor a `Constant` is
    // a shape classification did not prove, and it declines LOUDLY rather than
    // being rewritten. (For every non-folded region — diamond, if/else,
    // sequential, in-loop — `classifyArms`' `Base == Routed` gate already makes
    // this a no-op assignment.)
    //
    // THE DECLINE ITSELF LIVES IN THE PRE-EMISSION VALIDATION LOOP ABOVE (Rule 1
    // — never bail mid-emission); what is left here is only the ASSIGNMENT, on a
    // shape already proven. The assert-by-construction is that the loop above
    // ran over the same `Streams` in the same order with the same `Q`.
    CallInst *First = S.Phis.front();
    if (First->getArgOperand(0) != Q)
      First->setArgOperand(0, Q);  // pre-validated: it is a `Constant`.
    for (CallInst *Phi : S.Phis) {
      Phi->moveBefore(BI);
      taint.ControlledRotations[Phi] = Flag;
    }
    if (S.Negated)
      stamp(B.CreateCall(X, {Flag}));
  }

  // 3. Flag strip + free — the eager ancilla cleanup, byte-identical to the
  //    pre-2a route's steps 7-8. SKIPPED on the ziov share path
  //    (R.ShareCondFlag): the condition is also live as DATA, so the flag's last
  //    use is downstream (the escaped/measured data lineage owns it). Stripping
  //    here would return the flag to |0> before the data read
  //    (read-after-collapse); freeing it would be a hidden measurement. The data lineage is the flag's reclaimer (FreePoint →
  //    Escaped/Measured, no free). The only other case — a dead-within-function
  //    lineage — is declined upstream by classifyArms and stays declined.
  if (!R.ShareCondFlag) {
    // Flag strip — `q == q0` (Rz is DIAGONAL, so it preserves the basis value of
    // whatever register it fires on, controlled or not), so `icmp_inv(q)` returns
    // the flag to |0> with zero extra gates. Reads `Cond`'s operands, so it MUST
    // precede the erase of `Cond` (in flattenRegion).
    //
    // RECORDED as a DISCHARGED FLAG GATE (M-B Increment 6, clause (d2)). For the
    // compare operands in its shifted handle slots this call is a pure READ — it
    // recomputes the predicate and XORs it onto `Flag`, leaving every operand at
    // its forward basis — so a DERIVED condition's provenance chain is dead the
    // instant it returns. Recording it here lets `ChainWalk::isInteriorConsumer`
    // count it as a consumer, which moves the interior partition's
    // `dagInsertPoint` PAST this line and is the only place that chain may legally
    // be discharged (bd 6uqc's P0).
    //
    // THE LICENCE MOVED WITH THE MECHANISM, AND IT GOT STRONGER, NOT WEAKER. The
    // pre-2a route's ground was "step 3/5 restore `Q`'s basis label AS A GROUP,
    // so an adjoint placed after the strip reads the wire the forward chain
    // read". This path emitted no route at all: its only gate on `Q` was a
    // CONTROLLED Rz, `diag(1, e^{iθ})` on `f=1` and `I` on `f=0` —
    // DIAGONAL either way, so `Q`'s basis label is not merely restored, it is
    // never moved. The property the recording needs therefore holds pointwise
    // rather than as a group property of two swaps. (The Ry stem is the
    // counterexample that makes this a real distinction: `emitInPlaceRotationRegion`
    // records its strip too, but on the strictly different R4 ground that the
    // relabelled register is a proven-disjoint wire from every condition wire.)
    auto *Strip = dyn_cast_or_null<CallInst>(
        lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                           /*before=*/BI, /*negate=*/false,
                           /*railToStrip=*/Flag));
    if (Strip)
      taint.DischargedFlagGates.insert(Strip);

    // Flag free.
    stamp(B.CreateCall(wd.freeFn(), {Flag}));
  }

  // 4. Rewire + erase + scrub, then flatten the CFG. The merge phi's value is now
  //    just `q` (a phase arm preserves q's basis identity — and a CONTROLLED
  //    diagonal gate preserves it on both branches), so a measure on the phi
  //    becomes a measure on q.
  //
  //    THE ARM `cq_phi` CALLS ARE **NOT** ERASED HERE — they were MOVED to the
  //    pred at step 2 and were owned by `lowerRotations` (the hoist-and-defer
  //    contract; its PHI loop is deleted since 3qlq, so nothing lowers them now).
  //    The pre-2a route re-minted each gate on a work rail and erased the
  //    original. Nothing scrubs them from `taint.PhiCalls` either.
  MergePhi->replaceAllUsesWith(Q);
  scrubTaint(MergePhi, taint);
  MergePhi->eraseFromParent();
  flattenRegion(R, taint);
}

}  // namespace

// Walk the arm's merge contribution back along its IN-BLOCK phase spine,
// collecting the `@cq_phi_<sfx>` calls DEFINED IN `ArmBB` in FORWARD program
// order (first gate applied first). That is the RETIRED register form
// `qN = cq_phi_<sfx>(q{N-1}, angle)` (see `isPhiCall`), so on an accepted module
// the result is always empty. The back-walk hops arg-0 handles, so reversing it
// yields forward order. An empty result is handled by the caller.
//
// The walk STOPS at the arm-block boundary: a `cq_phi_` defined OUTSIDE `ArmBB`
// is a pre-region rotation — the DERIVED base handle (accepted since
// test_C_libtooling-9hh), NOT an arm gate; pre-3qlq `lowerRotations` lowered it
// as an ordinary unconditional Rz at its own position. Bounding here is
// load-bearing (Rule 10): an unbounded walk would
// collect a pre-region phi SHARED by both arms once per arm, and the §6.1
// reverse-erase would double-free it (SIGSEGV — the WI-3 crash). Keeping the
// per-arm gate list strictly in-block makes that impossible. De-anonymized
// (named `cq`, declared in the header) for the since-deleted `NestedRouteEmit`.
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

// Emit the swap `cqrt_cswap(flag, q, rail)`, X-bracketed for an ArmNegated
// (¬flag / FALSE-successor) arm: `cqrt_x(flag); cqrt_cswap(…); cqrt_x(flag)`.
// Its one caller is `AbortParkEmit` (the 7.2 park of q into a kept graveyard
// rail); the pre-3qlq phase, value and 4.3 nest routes also used it for their
// route-in and route-back. De-anonymized (named `cq`, declared in the header)
// so every caller shares the SAME bracket logic (a drift in the ¬flag polarity
// here would be a silent miscompile).
CallInst *emitRoute(IRBuilder<> &B, const ControlledSymbols &csyms, Value *Flag,
                    Value *Q, Value *Rail, bool Negated, const DebugLoc &DL) {
  FunctionCallee Cswap = csyms.cswapFn();
  FunctionCallee X = csyms.xFn();
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  if (Negated)
    stamp(B.CreateCall(X, {Flag}));
  // The ONE gate on the base `Q`. The X brackets are on the FLAG, so a
  // caller collecting a `RestoringRoute` group over `Q` wants exactly this call
  // and not the brackets (M-B Increment 6).
  CallInst *Swap = stamp(B.CreateCall(Cswap, {Flag, Q, Rail}));
  if (Negated)
    stamp(B.CreateCall(X, {Flag}));
  return Swap;
}


// ── bd test_C_libtooling-3qlq Inc 1 — P1, the FLAT KICKBACK EMITTER ─────────
//
// The whole emitted stream, for `if (q == 5) cq_phi(PI);` (PRD §1's target):
//
//     cq_template_icmp_eq_i32_hl(h0, 5) -> h1        ; flag mint
//     cqrt_rz_i1(h1, 0x1.921fb54442d18p+1)           ; P(θ) ON THE FLAG
//     cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)      ; flag strip → |0>
//     cqrt_free(h1)                                  ; clean free (Rule 6)
//
// FOUR LINES, AND `q` IS NOT AN OPERAND OF ANY OF THEM except as the compare's
// input. That is the entire point of the increment (PRD §1): the shipped
// `cqrt_rz_<W>_controlled(f, h, θ)` this REPLACES was TENSORED — Rz on each
// qubit of the register — so the marked branch got `(−1)^popcount(target)` and
// `|0…0⟩` could not be marked at all, making every Grover golden a
// self-consistent trace of the IDENTITY on `q`.
//
// WHY THERE IS NO ROUTE, NO WORK RAIL AND NO `_controlled` GATE (PRD §3). With
// `f = c(x)` in a |0⟩ ancilla the state is `Σ a_x |x⟩|c(x)⟩`; a diagonal
// `P(θ)` on the ANCILLA gives `Σ a_x e^{iθ c(x)} |x⟩|c(x)⟩`; the compare `_unc`
// is the permutation `|x, c(x)⟩ → |x, 0⟩`, so the ancilla comes back |0⟩ ON
// EVERY BRANCH and the phase is left on the branch. One single-qubit gate. The
// `cqrt_cswap` route and the controlled-copy route are both junk-free for a
// diagonal gate too, at `2W` Fredkin / `2W` Toffoli respectively — the kickback
// needs neither.
//
// WHAT THIS SHARES WITH ITS SIBLINGS, VERBATIM (Rule 14). The mint, the `cqrt_x`
// negation bracket, the `_unc` strip and the free are the SAME four calls
// `emitRegion` (§B1) and `emitInPlaceRotationRegion` make, in the same order,
// through the same `lowerCompareToFlag` / `csyms.xFn()` / `wd.freeFn()`
// spellings. Only the gate between the brackets differs, and the merge handling:
//
//   * there is NO RAUW AT ALL. `emitRegion`'s M-α (`MergePhi → Q`) and
//     `emitInPlaceRotationRegion`'s M-β (`MergePhi → last hoisted gate`) both
//     answer "what does the merged name denote"; a kickback merges no name, so
//     the question does not arise and neither convention is instantiated here.
//     `R.Merge` is null by construction (`classifyPhaseKickback` sets it so) and
//     `flattenRegion` therefore never touches a φ — the same shape
//     `lowerControlledIOSinks` flattens for the void-I/O diamond.
//   * the gate is NOT recorded in `taint.ControlledRotations`. That map is the
//     hoist-and-defer channel to `lowerRotations` for a gate that must become
//     `_controlled`; this gate is UNCONTROLLED and is emitted here, finished.
//
// THE ZIOV SHARED-FLAG PATH IS HONOURED (`R.ShareCondFlag`): when the condition
// compare is ALSO read as data, the flag is minted at the COMPARE so it
// dominates every data use, and the strip+free are SKIPPED here because the data
// lineage owns the flag.
//
// ⚠ THAT IS THE SAME FOUR LINES `emitRegion` WRITES AND IT IS **NOT** THE SAME
// MODULE — the earlier spelling of this paragraph said "byte-for-byte the rule
// `emitRegion` follows", and that false equivalence is precisely where the
// Rule-13 round-1 CONFIRMED SILENT MISCOMPILE F-L7-1 / F-L1-1 / F-L2-1 lived.
// `emitRegion`'s arm gate was then `cqrt_rz_<W>_controlled` (a retired-form-only
// path now), which `ChainWalk::isInPlaceGateOn` deliberately REFUSES (Inc 2a,
// `ChainWalk.cpp`'s stem-split note) — so handing `emitRegion`'s flag to the
// data lineage hands over a rail carrying an UNRECOGNIZED consumer, and the
// spine leaves it alone.
// THIS emitter's gate is a plain `cqrt_rz_i1`, which that predicate ADMITTED. So
// "the data lineage owns the flag" was, for this path and not for its sibling,
// the sentence that AUTHORISED the whole-DAG spine to emit `cqrt_rz_i1(f, -θ)`
// and cancel the user's phase exactly. Two emitters, one sentence, opposite
// consequences.
//
// WHAT MAKES IT TRUE NOW, ON BOTH PATHS AND BY THE SAME MECHANISM: every gate
// this emitter mints is recorded with `ChainWalk::markBranchPhaseGate`, and the
// three spine predicates refuse a member outright. On the SHARE path that turns
// the flag into an unrecognized-consumer rail (`D.NotClosed`) — left allocated,
// Rule-6 safe, and byte-for-byte the pre-3qlq oracle's disposition on the same
// source. On the NON-share path the strip+free below still fire, and the record
// is what keeps them the ONLY discharge: before it, that path was protected only
// by its own `cqrt_free(Flag)` happening to make the flag an unrecognized-consumer
// rail, which is an accident of this emitter's own emission order and not a fence
// (lens L7 §F-L7-5). The protection is now the membership, on BOTH paths.
// bd test_C_libtooling-3qlq.4 (Inc 1b) — ONE spelling of "fire P(θ) for each
// angle when `Ctl == FiresOnOne`", shared by the flat kickback (arms and the
// merge-tail incomings) and the nest (outer arm on its root, inner arm on the
// conjunction). Two forms, chosen by WHAT `Ctl` IS:
//
//   * an ANCILLA this region minted (a compare flag or a network node): the
//     pre-1b stream, verbatim — `x; rz(θ₁) … rz(θₙ); x` for a `¬Ctl` group,
//     ONE bracket pair per group (`cqrt_x` is self-inverse).
//   * the USER'S REGISTER (`CtlIsRail` — a bare `_Bool` condition): NO `cqrt_x`
//     ever touches it. A `¬rail` gate is emitted as `rz(rail, −θ)`, on the
//     identity `X·P(θ)·X = diag(e^{iθ}, 1) = e^{iθ}·P(−θ)`: the same unitary up
//     to the GLOBAL phase e^{iθ}, which owner decision D2 already declares
//     unobservable (an uncontrolled `cq_phi` is deleted on that ground). `−θ`
//     is `fneg`, exact in IEEE for every double and constant-folded for a
//     `ConstantFP`, so no rounding class is introduced (unlike 2b's `A−B`).
//
// WHY the diagonal form and not the bracket on a register — three predicates
// that read the lowered stream would each turn a `cqrt_x(rail)` into a wrong
// or over-conservative answer: `Uncomputation::preservesBorrowedParent` fails
// CLOSED on any gate it does not name (a chain BORROWING the register as a
// parent would freeze — a leak), `ChainWalk::isInPlaceGateOn` deliberately
// never recovers `cqrt_x`, and the region-level invariant every fence in this
// file rests on ("this region emits NO non-diagonal gate on any condition
// register") would be false. With `rz` alone the register carries exactly one
// new consumer per gate, diagonal, membership-recorded, and the whole-DAG spine
// reads it the way it already reads the flag's gate.
//
// EVERY gate is RECORDED (`markBranchPhaseGate`) for the F-L7-1 reason the
// callers state; a seventh emission site that omits it re-opens that
// miscompile with no diagnostic anywhere.
//
// EXPORTED (SwapRouteEmit.h) for bd dm7f.3, body unchanged: the guarded-store
// region's phase arms (`GuardedStoreArmEmit`) fire through this one spelling.
void emitKickbackGroup(IRBuilder<> &B, FunctionCallee Rz, FunctionCallee X,
                       Value *Ctl, bool CtlIsRail, ArrayRef<Value *> Angles,
                       bool Neg, const DebugLoc &DL, TaintSet &taint) {
  if (Angles.empty())
    return;
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  const bool Bracket = Neg && !CtlIsRail;
  if (Bracket)
    stamp(B.CreateCall(X, {Ctl}));
  bool Recorded = false;
  for (Value *Angle : Angles) {
    Value *A = Neg && CtlIsRail ? B.CreateFNeg(Angle) : Angle;
    CallInst *G = stamp(B.CreateCall(Rz, {Ctl, A}));
    markBranchPhaseGate(G);
    // bd test_C_libtooling-r9e5 (1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1) — on
    // the USER'S REGISTER this gate is a control READ of a rail, so the FIRST
    // one of each group is recorded for the round-2 re-verification of the
    // §14.3 ladder. A region emits one group per arm plus one per bracketed tail
    // incoming, all into the same contiguous window before the branch, so the
    // extra entries a multi-arm region records answer identically to the first —
    // and `reverifyRailCondReads` diagnoses once per rail either way.
    if (CtlIsRail && !Recorded) {
      markRailCondRead(taint, Ctl, G);
      Recorded = true;
    }
  }
  if (Bracket)
    stamp(B.CreateCall(X, {Ctl}));
}

static SmallVector<Value *, 4> phaseAngles(ArrayRef<Instruction *> Gates) {
  SmallVector<Value *, 4> Out;
  for (Instruction *I : Gates)
    Out.push_back(cast<CallInst>(I)->getArgOperand(0));
  return Out;
}

void emitPhaseKickbackRegion(const ControlRegion &R, WidthDispatch &wd,
                             const ControlledSymbols &csyms, TaintSet &taint) {
  // ---- 0. RE-VALIDATE THE PLAN BY SSA IDENTITY, BEFORE MUTATING ANYTHING.
  // Every decline below precedes the FIRST emitted instruction, for the reason
  // the sibling emitters state: a region that declines MID-STREAM leaves a
  // minted flag and a half-lowered arm behind (the Inc-2a round-1 F-5 finding).
  auto *BI = R.Pred ? dyn_cast<BranchInst>(R.Pred->getTerminator()) : nullptr;
  // bd `3qps` (Track P) — THE CONDITION IS READ FROM A LIVE ANCHOR, NEVER FROM
  // THE PLAN'S CACHED POINTER, and `R.Condition` is from here on POINTER-COMPARED
  // ONLY. This is bd `boi6`'s H-1 discipline (`SelectMergeEmit` re-reads
  // `cast<SelectInst>(R.Merge)->getCondition()` for the identical reason), asked
  // at the anchor a kickback actually has: `R.Merge` is null by construction, so
  // the live anchor is the branch's own operand.
  //
  // IT IS NOT A THEORETICAL HAZARD FOR THIS KIND, and the reason is the opposite
  // of the select's. A merge-φ-conditioned kickback sits in the PREP's `MergeBB`,
  // so the bd `hcrg` pre-flight gives it `Precedes[kickback] = {prep}` and it is
  // emitted FIRST, while the φ is still live — which is exactly what this emitter
  // wants. But nothing here may DEPEND on that: if a future order ever emits the
  // prep first, M-β has RAUW'd the `br`'s operand to the hoisted theta and
  // `flattenRegion` has FREED the φ, so `R.Condition` is a dangling pointer.
  // Reading `BI->getCondition()` makes that case a LOUD DECLINE at the identity
  // check below rather than a `dyn_cast` on freed memory.
  // ⚠ Do NOT "fix" the plan field with a `WeakTrackingVH` (bd `boi6` H-1, tried
  // and wrong): the φ is legitimately REPLACED, not deleted, so a tracking handle
  // would silently follow the RAUW and HIDE the ordering premise instead of
  // checking it.
  Value *const CondV = BI ? BI->getCondition() : nullptr;
  auto anchor = [&]() -> Instruction * {
    if (auto *A = dyn_cast_or_null<Instruction>(CondV))
      return A;
    return BI;
  };
  // The condition is re-derived through the SAME `collectCondTree` grammar the
  // classifier accepted with (Rule 14 — the walk cannot drift). A bare compare
  // is the degenerate single-leaf tree and takes the pre-part-B code below,
  // byte-for-byte; a COMPOUND tree (P3) takes the shared `CondTreeEmit` network.
  // BOTH flags must match `classifyPhaseKickback`'s literally, `AllowRailPhi`
  // included (bd `3qps`): a narrower walk here would report drift on every accept
  // the classifier just created, a wider one would emit a shape nothing proved.
  CondTree Tree;
  if (!BI || !BI->isConditional() || !R.Arm || !R.MergeBB || !R.Condition ||
      CondV != R.Condition ||
      !collectCondTree(CondV, Tree, /*AllowLogicalSelect=*/true,
                       /*AllowRailPhi=*/true)) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  const bool IsTree = !Tree.Nodes.empty();
  // bd 3qlq.4: a node-less tree has ONE leaf, a COMPARE (`Cond`, the pre-1b
  // path), a RAIL (`RailCond`, the `_Bool` register itself — its own flag) or —
  // bd `3qps` — a REGION-MERGE φ (`RailPhiCond`), which denotes that same
  // register and is its own flag for the identical reason.
  auto *Cond = IsTree || Tree.Leaves.empty() ? nullptr : Tree.Leaves.front();
  CallInst *RailCond =
      !IsTree && !Tree.RailLeaves.empty() ? Tree.RailLeaves.front() : nullptr;
  PHINode *RailPhiCond =
      !IsTree && !Tree.RailPhiLeaves.empty() ? Tree.RailPhiLeaves.front()
                                             : nullptr;
  if ((!IsTree && !Cond && !RailCond && !RailPhiCond) ||
      (R.ShareCondFlag && !Cond)) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;  // detection/emission drift — before the first emission.
  }
  // Each recorded gate must still be a one-operand phase call in the arm the
  // plan says it is in, with an angle defined OUTSIDE that arm (the classifier's
  // `Arm->size() == N + 1` makes the latter structural, but it is an EMISSION
  // fact — the angle has to dominate `BI`, where the gate is hoisted to — so it
  // is re-asked here rather than inherited).
  auto validGates = [&](ArrayRef<Instruction *> Gates, BasicBlock *BB) {
    for (Instruction *I : Gates) {
      auto *CI = dyn_cast<CallInst>(I);
      if (!CI || CI->getParent() != BB || CI->arg_size() != 1)
        return false;
      if (auto *AngI = dyn_cast<Instruction>(CI->getArgOperand(0)))
        if (AngI->getParent() == BB)
          return false;
    }
    return true;
  };
  if (!validGates(R.Shadow, R.Arm) ||
      (R.ArmFalse && !validGates(R.ShadowFalse, R.ArmFalse)) ||
      (!R.ArmFalse && !R.ShadowFalse.empty())) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  // The MERGE-TAIL ANGLE PHI, re-asked through the SAME predicate detection used
  // (Rule 14 — never a second spelling). Its ABSENCE is as load-bearing as its
  // presence: a φ left standing in a merge `flattenRegion` splices away is a
  // BROKEN MODULE (`PHI nodes not grouped at top of basic block!`, MEASURED on
  // `slice_control_phase_ifelse_derived`), so if the merge carries a φ that is
  // not this one, decline rather than flatten over it.
  //
  // ⚠ NOT "at `opt` exit 0" — that half of the original sentence is MEASURED
  // FALSE (Rule-13 round-1 F-L3-5). `cq-opt` runs `VerifierPass` after this pass
  // with `FatalErrors=true`, so a broken module ABORTS with
  // `LLVM ERROR: Broken module found, compilation aborted!`, exit **134**, and no
  // `-o` is written. See `ArmAnalysis.h`'s note on `phaseAngleTail` for the
  // measurement and for what IS true about `cq-opt`'s exit behaviour.
  PHINode *TailPhi = nullptr;
  CallInst *TailCall = nullptr;
  const bool HasTail = phaseAngleTail(R.MergeBB, taint, TailPhi, TailCall);
  if (!HasTail && !R.MergeBB->phis().empty()) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  if (R.Shadow.empty() && R.ShadowFalse.empty() && !HasTail) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  // `cqrt_rz_i1` is the ONLY Rz this pass emits after 3qlq (PRD §5). Resolve it
  // BEFORE any mutation so a resolution failure is a decline, not a half-stream.
  FunctionCallee Rz = wd.rzRtFn("i1");
  if (!Rz) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }

  // ---- EMISSION STARTS HERE. Nothing below may decline.
  const DebugLoc DL = R.Shadow.empty()
                          ? (HasTail ? TailCall->getDebugLoc() : BI->getDebugLoc())
                          : R.Shadow.front()->getDebugLoc();
  IRBuilder<> B(BI);
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };

  // ---- 1. FLAG MINT — `cq_template_icmp_<pred>_<W>_hl(q, lit)`. Position rule
  // copied from `emitRegion` step 1: at the COMPARE on the ziov share path (so
  // the one physical flag dominates every data use), at the branch otherwise.
  //
  // COMPOUND TREE (P3): the network is the 4.4 select's, shared through
  // `CondTreeEmit` — one flag per leaf, one `|0>` ancilla per and/or/xor node,
  // the ROOT ancilla carrying the whole predicate. `ShareCondFlag` is FALSE for
  // a tree by construction (the classifier declines every out-of-tree use), so
  // the position rule degenerates to "at the branch".
  CondNetwork Net;
  SmallVector<CallInst *, 4> LeafStrips;
  if (IsTree) {
    // (Track A.1, F-A1R2-1) `LeafWireRuled` — `classifyPhaseKickback` asked
    // `condWireDisposition` / `railCondWireDisposition` over this tree's own
    // `Prov` before the region was pushed.
    switch (emitCondNetwork(CondV, Tree, wd, csyms, taint, /*Before=*/BI,
                            DL, /*AllowQQLeaves=*/false, Net,
                            /*CopyRailRoot=*/false, /*LeafWireRuled=*/true)) {
    case CondNetDisp::Ok:
      break;
    case CondNetDisp::MintDiagnosed:
      // `lowerCompareToFlag` was already LOUD; a second message here would only
      // change what a decline fixture reads. The classifier proved every leaf
      // mintable, so this is drift — but it is still a decline, not a skip.
      return;
    case CondNetDisp::Malformed:
      if (Instruction *A = anchor())
        diagnoseUnderControl(A, "control flow");
      return;
    }
  }
  Instruction *FlagAt = R.ShareCondFlag ? Cond->getNextNode() : BI;
  // bd 3qlq.4: for a RAIL condition the flag IS the register (no mint), and
  // `FlagIsRail` selects the diagonal polarity form in `emitKickbackGroup` and
  // skips the strip+free below. A tree's root is an ancilla unless the tree IS
  // a rail (`Net.RootIsRail`, the node-less case — unreachable here since a
  // node-less tree takes the `RailCond` path, but asked rather than assumed).
  // ⚠ SAME FOR A REGION-MERGE φ ROOT, and it is the ground F-P1-4 wanted stated:
  // a node-less tree takes the `RailPhiCond` path below, so for a φ ROOT this
  // ternary evaluates `(RailCond != nullptr || RailPhiCond != nullptr)` and
  // `Net.RootIsRail` is NEVER READ. `CondTreeEmit`'s widening of that field is
  // therefore defence in depth with no subject at this consumer — correct in
  // direction, but it is not what keeps a `cqrt_x` off the user's register here.
  // What keeps it off is this `||`.
  // (Track A.1, F-A1R2-1) `WireRuled`: `classifyPhaseKickback` asked
  // `condWireDisposition` (or `railCondWireDisposition`) over `Prov` at round-1
  // taint before this region was pushed.
  // bd `3qps`: a REGION-MERGE φ is the flag on the SAME terms as a rail leaf —
  // `FlagIsRail` selects `emitKickbackGroup`'s diagonal `rz(−θ)` polarity form
  // (NEVER a `cqrt_x` on the user's register) and skips the strip+free below,
  // because nothing was minted. By the time `lowerRotations` runs, the prep's
  // M-β has RAUW'd this φ to the hoisted `cq_theta_i1` call and that call to its
  // `i32` handle, so the gate's operand is the register — no `i1` φ survives into
  // a `cqrt_*` argument.
  Value *Flag = IsTree        ? Net.Root
                : RailCond    ? static_cast<Value *>(RailCond)
                : RailPhiCond ? static_cast<Value *>(RailPhiCond)
                              : lowerCompareToFlag(
                                    Cond, wd, taint, /*qqWidth=*/{},
                                    /*inverse=*/false, /*before=*/FlagAt,
                                    /*negate=*/false, /*railToStrip=*/nullptr,
                                    /*readKind=*/CondReadKind::WireRuled);
  const bool FlagIsRail =
      IsTree ? Net.RootIsRail : (RailCond != nullptr || RailPhiCond != nullptr);
  if (!Flag)
    // REACHABLE, and say so plainly rather than calling it unreachable — an
    // overstated justification is how a real bail later gets deleted as dead.
    // `classifyPhaseKickback` asks `compareFlagMintable` (a dry run of the
    // template lookup) but deliberately does NOT ask whether the compare is
    // Q+Q, so a `q == p` condition reaches here and `lowerCompareToFlag` fails.
    //
    // THAT IS SAFE AND IT IS THE PRE-EXISTING DISPOSITION, both MEASURED. Safe:
    // the mint is the FIRST emission, so returning leaves the module exactly as
    // it was — this is not a mid-stream bail (contrast `AngleSelectEmit`, whose
    // `fsub` and unconditional twin precede its mint, which is why IT re-asks
    // the semantic half at step 0b). Pre-existing: `lowerCompareToFlag` has
    // already diagnosed `no template for opcode 'icmp i1' in tainted context`,
    // which is CHARACTER-FOR-CHARACTER what the pre-3qlq oracle emits for the
    // same Q+Q phase diamond in the retired register form (measured on
    // `$SP/wt/pre-3qlq` 2026-09-05) — so this shape's message did not churn.
    // `emitRegion`'s flat phase path has the identical structure and comment.
    // Q+Q flag minting is a filed follow-on (PRD §9), not a defect here.
    return;
  if (R.ShareCondFlag)
    taint.SharedCondFlags[Cond] = Flag;

  // ---- 2. THE GATES — `cqrt_rz_i1(f, θ)` each, UNCONTROLLED, in SOURCE ORDER,
  // `cqrt_x`-bracketed per arm-polarity.
  //
  // N GATES ARE EXACT AND NEED NO ARITHMETIC (orchestrator decision 2026-09-05,
  // PRD §6.3 row 1 superseded — see `classifyPhaseKickback`'s header). Each
  // angle is passed through VERBATIM; the composition `P(θ₁)·P(θ₂) = P(θ₁+θ₂)`
  // happens in the hardware, not in this compiler, so there is no `fsub`, no
  // rounding residual and no bound to fence — unlike the 2b by-difference Ry
  // form, whose whole arm-value fence exists because it realizes `A − B`.
  //
  // ONE BRACKET PAIR PER ARM, not per gate: `cqrt_x` is self-inverse, so
  // `x;g1;x;x;g2;x` and `x;g1;g2;x` are the same unitary and the second is what
  // the flat phase path has emitted since Inc 2a.
  //
  // ⚠ READ THAT AS "PER ARM", NEVER AS "PER REGION" — the earlier spelling of
  // this comment said the second and was MEASURED FALSE in four programs, two of
  // them plain C (lens L1 §F-L1-3). The merge-tail loop at step 2b brackets EACH
  // INCOMING by its own polarity, independently of the arm's bracket, so one
  // source arm can carry TWO pairs: `if(q!=5){cq_phi(.9);cq_phi(.3);}else
  // {cq_phi(.11);}` emits `x; rz(.9); x; x; rz(.3); x; rz(.11)` — FOUR `cqrt_x`,
  // two of them adjacent and cancelling. Correct (an involution), and not what
  // the comment claimed. The accurate rule is: one pair per ARM, plus one per
  // BRACKETED TAIL INCOMING.
  //
  // ⚠ AND THE OLD CITATION OF `SwapRouteEmit.cpp:1063`'s `-2 cqrt_x` audit
  // arithmetic WAS A FALSE DEPENDENCY, also L1 §F-L1-3. That note is the drbq
  // Inc-2a route→control-in-place COLLAPSE arithmetic, and
  // `tools/golden_multiset_audit.py` models `-2 cqrt_x` per COLLAPSED QUINTUPLE.
  // The kickback path feeds neither: it collapses no quintuple and appears in no
  // pre-3qlq golden. Nothing downstream depends on this choice — it is a shape
  // decision, argued from the involution above and from nothing else.
  FunctionCallee X = csyms.xFn();
  // EVERY emitted kickback gate is RECORDED (`ChainWalk::markBranchPhaseGate`,
  // inside `emitKickbackGroup`) so the whole-DAG uncompute spine treats it as
  // opaque. Without the record the spine reads `cqrt_rz_i1(f, θ)` as an
  // ordinary in-place rotation on `f`'s chain and emits `cqrt_rz_i1(f, -θ)`,
  // cancelling the user's phase exactly — the Rule-13 round-1 CONFIRMED
  // miscompile F-L7-1 / F-L1-1. The `¬flag` form depends on what the flag IS
  // (an ancilla: the `cqrt_x` bracket; the user's register: `rz(−θ)`) — see
  // the helper's header (bd 3qlq.4).
  auto emitArm = [&](ArrayRef<Instruction *> Gates, bool Neg) {
    emitKickbackGroup(B, Rz, X, Flag, FlagIsRail, phaseAngles(Gates), Neg, DL,
                      taint);
  };
  emitArm(R.Shadow, R.ArmNegated);
  // The FALSE arm of an if/else always fires on ¬f — `ArmNegated` is the
  // DIAMOND's polarity and is false for an if/else, so the bracket here is
  // unconditional (the field convention: `Shadow` is `Arm`'s, `ShadowFalse` is
  // `ArmFalse`'s, by field identity and not by edge truth).
  emitArm(R.ShadowFalse, /*Neg=*/true);

  // ---- 2b. THE MERGE-TAIL ANGLE PHI: one gate per incoming, each bracketed by
  // THAT incoming's own polarity. `%a = phi double [A, %arm], [B, %pred]` means
  // "A when the arm ran, B otherwise", so the gate for the `%arm` incoming fires
  // on the arm's polarity and the `%pred` incoming's fires on its negation. Walk
  // the incoming list in index order so the emitted stream is a deterministic
  // function of the IR.
  if (HasTail)
    for (unsigned I = 0; I != 2; ++I) {
      BasicBlock *In = TailPhi->getIncomingBlock(I);
      // `Arm` fires on f == 1 unless the diamond polarity is inverted; `ArmFalse`
      // always fires on f == 0; the straight-through `Pred` edge is taken exactly
      // when `Arm` is not, so its polarity is `Arm`'s negation.
      const bool FiresOnOne = In == R.Arm         ? !R.ArmNegated
                              : In == R.ArmFalse  ? false
                                                  : R.ArmNegated;
      // Recorded for the same reason as the arm gates above (F-L7-1); the
      // `¬flag` form is the helper's (ancilla: bracket; rail: `rz(−θ)`).
      emitKickbackGroup(B, Rz, X, Flag, FlagIsRail,
                        {TailPhi->getIncomingValue(I)}, /*Neg=*/!FiresOnOne, DL,
                        taint);
    }

  // ---- 3. STRIP + FREE. The strip recomputes the predicate on the CONDITION's
  // OWN registers and XORs it back onto the flag, returning it to |0⟩ so the free
  // is clean (Rule 6). Its validity here is unconditional in a way no other arm
  // class can claim: this region emits NO gate on any condition register at all,
  // so the basis the strip reads is identically the basis the mint read.
  // (`emitRegion` needs §3c for the same conclusion; the Ry path needs S8's
  // disjoint-wire proof.)
  //
  // SKIPPED WHOLE on the ziov share path: the data lineage owns the flag and
  // discharges it downstream — freeing it here would be a use-after-free.
  if (IsTree) {
    // The exact LIFO mirror of the network: every node's self-inverse undo (then
    // its ancilla's proven-|0> free) in reverse post-order, then every leaf's
    // `_unc` strip against its OWN rail (then that rail's free) in reverse mint
    // order. `ShareCondFlag` cannot be set for a tree, so there is no skip case.
    // Each leaf strip is recorded in `DischargedFlagGates` for the same reason
    // the single-compare one is: it is the point past which a DERIVED
    // condition's chain may be discharged by the whole-DAG spine
    // (`ChainWalk::isInteriorConsumer`).
    stripCondNetwork(Net, wd, csyms, taint, /*Before=*/BI, DL,
                     /*AllowQQLeaves=*/false, &LeafStrips);
    for (CallInst *S : LeafStrips)
      taint.DischargedFlagGates.insert(S);
  } else if (!R.ShareCondFlag && !FlagIsRail) {
    // (bd 3qlq.4: a RAIL flag is the user's register — nothing was minted, so
    // there is nothing to strip and NOTHING TO FREE; the register stays the
    // user's, carrying one diagonal, membership-recorded consumer.)
    auto *Strip = dyn_cast_or_null<CallInst>(
        lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                           /*before=*/BI, /*negate=*/false,
                           /*railToStrip=*/Flag));
    if (Strip)
      taint.DischargedFlagGates.insert(Strip);
    stamp(B.CreateCall(wd.freeFn(), {Flag}));
  }

  // ---- 4. ERASE THE ARM CALLS AND THE TAIL, THEN FLATTEN. Each call is erased
  // rather than hoisted: its whole content is now a `cqrt_rz_i1` above. Scrub
  // from `PhaseCalls` first so `deleteGlobalPhases` (which derives its survivors
  // from the IR) and any later module walk cannot dereference freed memory.
  auto erasePhase = [&](CallInst *CI) {
    auto &PC = taint.PhaseCalls;
    PC.erase_value(CI);
    CI->eraseFromParent();
  };
  for (Instruction *I : R.Shadow)
    erasePhase(cast<CallInst>(I));
  for (Instruction *I : R.ShadowFalse)
    erasePhase(cast<CallInst>(I));
  if (HasTail) {
    // Consumer first (it is the φ's only user), then the φ — which MUST go
    // before `flattenRegion` splices its block away.
    erasePhase(TailCall);
    scrubTaint(TailPhi, taint);
    TailPhi->eraseFromParent();
  }
  // `R.Merge` is null, so `flattenRegion` dissolves no φ — it splices the arm(s)
  // and merge blocks into `Pred` and rewires the branch, exactly as it does for
  // the void-I/O diamond. It also erases `R.Condition` — the tree ROOT — once
  // the branch is gone and the root is use-empty.
  Value *const Root = CondV;
  flattenRegion(R, taint);
  // A COMPOUND tree's INTERIOR is not `flattenRegion`'s to erase, and leaving it
  // is not harmless: the mint and strip built FRESH templates from the leaves'
  // operands, so with the root gone every node and leaf is dead — and a dead
  // TAINTED compare is exactly what `lowerOps` would lower into a spurious
  // template plus a leaked flag rail a few steps later. Cascade ROOT-FIRST
  // (nodes in reverse post-order, then leaves in reverse) so each child's use
  // count has already dropped when it is tested — the discipline
  // `SelectMergeEmit` step 6 follows. `Root` is compared by POINTER only (it may
  // already be freed memory); nothing is dereferenced through it, and no
  // instruction is created between the flatten and here, so no address can have
  // been recycled. A leaf or node with a SURVIVING user is left alone (the
  // classifier declines every out-of-tree use, so that is defence in depth).
  for (Instruction *N : llvm::reverse(Tree.Nodes))
    if (N != Root && N->use_empty()) {
      scrubTaint(N, taint);
      N->eraseFromParent();
    }
  for (CmpInst *Leaf : llvm::reverse(Tree.Leaves))
    if (Leaf != Root && Leaf->use_empty()) {
      scrubTaint(Leaf, taint);
      Leaf->eraseFromParent();
    }
}


// ── bd test_C_libtooling-3qlq Inc 1 part B — P4, the GENUINE depth-2 NEST ────
//
// The register-free replacement for `NestedRouteEmit::lowerNestedRegion` (which
// is DELETED with this increment). See `classifyPhaseKickbackNest` for the
// shape, the unitary and the scope; the whole emission is:
//
//   1  the OUTER condition network            -> rootA           (CondTreeEmit)
//   2  [x(rootA)] rz_i1(rootA, θ_i) …  [x(rootA)]   the outer arm's phases
//   3  the INNER condition network            -> rootB           (CondTreeEmit)
//   4  g = alloc_i1(0);  toffoli(rootA, rootB, g)   X-bracketed per polarity
//   5  rz_i1(g, θ_j) …                              the inner arm's phases
//   6  the same bracketed toffoli again; free(g)    (self-inverse, g back to |0>)
//   7  strip the INNER network, then the OUTER one  (exact LIFO)
//   8  erase both arms' phase calls, flatten the region tree, cascade-erase the
//      two condition trees' interiors
//
// ZERO `cqrt_cswap`, ZERO work rails, ZERO `_controlled` gates, and the only Rz
// is `cqrt_rz_i1` — which is the whole point of the epic. Compare the 4.3 route
// this replaces: two `cqrt_alloc_<W>` work rails, FOUR `cqrt_cswap`, an inner
// flag minted FROM rail1, and a TENSORED `cqrt_rz_<W>` that could never mark
// |0..0> (PRD §1/§3).
//
// WHY THE ORDER IN 1-3 IS WHAT IT IS. The outer arm's phases ride `rootA` alone,
// so they may be emitted as soon as the outer network exists; the inner
// network's leaves read registers no gate in this region touches, so minting it
// after those phases reads exactly the same basis it would read before them.
// Emitting the inner network SECOND keeps the LIFO strip in step 7 the literal
// reverse of the mint order, which is what makes each free a proven-|0> free.
void emitPhaseKickbackNestRegion(const ControlRegion &R, WidthDispatch &wd,
                                 const ControlledSymbols &csyms,
                                 TaintSet &taint) {
  // ---- 0. RE-VALIDATE BY SSA IDENTITY BEFORE MUTATING ANYTHING. Every decline
  // below precedes the FIRST emitted instruction (the Inc-2a round-1 F-5
  // finding: a mid-stream decline leaves a half-built network behind).
  auto *BI = R.Pred ? dyn_cast<BranchInst>(R.Pred->getTerminator()) : nullptr;
  auto *InnerBI = R.Arm ? dyn_cast<BranchInst>(R.Arm->getTerminator()) : nullptr;
  auto anchor = [&]() -> Instruction * {
    if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
      return A;
    return BI;
  };
  CondTree OuterTree, InnerTree;
  if (!BI || !InnerBI || !BI->isConditional() || !InnerBI->isConditional() ||
      !R.Arm || !R.ArmFalse || !R.MergeBB || !R.Condition ||
      !R.InnerCondition || BI->getCondition() != R.Condition ||
      InnerBI->getCondition() != R.InnerCondition ||
      !collectCondTree(R.Condition, OuterTree, /*AllowLogicalSelect=*/true) ||
      !collectCondTree(R.InnerCondition, InnerTree,
                       /*AllowLogicalSelect=*/true) ||
      !R.MergeBB->phis().empty()) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  // Each recorded gate must still be a one-operand phase call in the block the
  // plan says, with its ANGLE defined OUTSIDE that block — an EMISSION fact (the
  // gate is hoisted to `BI`, so the angle has to dominate it), re-asked rather
  // than inherited.
  auto validGates = [&](ArrayRef<Instruction *> Gates, BasicBlock *BB) {
    for (Instruction *I : Gates) {
      auto *CI = dyn_cast<CallInst>(I);
      if (!CI || CI->getParent() != BB || CI->arg_size() != 1)
        return false;
      if (auto *AngI = dyn_cast<Instruction>(CI->getArgOperand(0)))
        if (AngI->getParent() == R.Arm || AngI->getParent() == R.ArmFalse)
          return false;
    }
    return true;
  };
  if (!validGates(R.Shadow, R.Arm) || !validGates(R.ShadowFalse, R.ArmFalse) ||
      (R.Shadow.empty() && R.ShadowFalse.empty())) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  // `cqrt_rz_i1` is the ONLY Rz this pass emits after 3qlq (PRD §5), and the
  // conjunction needs an i1 ancilla allocator. Resolve BOTH before any mutation
  // so a resolution failure is a decline and not a half-stream.
  FunctionCallee Rz = wd.rzRtFn("i1");
  FunctionCallee AllocI1 = wd.allocFn("i1");
  if (!Rz || !AllocI1) {
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }

  // ---- EMISSION STARTS HERE. Nothing below may decline.
  const DebugLoc DL = !R.Shadow.empty()      ? R.Shadow.front()->getDebugLoc()
                      : !R.ShadowFalse.empty() ? R.ShadowFalse.front()->getDebugLoc()
                                               : BI->getDebugLoc();
  IRBuilder<> B(BI);
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  FunctionCallee X = csyms.xFn();
  // bd 3qlq.4 — a NEGATED level whose root is a bare RAIL is refused by the
  // classifier (its conjunction control would need a `cqrt_x` bracket on the
  // user's register); re-asked HERE, before the first emission, as the drift
  // guard every emitter carries.
  const bool OuterRootIsRail =
      OuterTree.Nodes.empty() && !OuterTree.RailLeaves.empty();
  const bool InnerRootIsRail =
      InnerTree.Nodes.empty() && !InnerTree.RailLeaves.empty();
  if ((OuterRootIsRail && R.ArmNegated) ||
      (InnerRootIsRail && R.InnerArmNegated)) {
    diagnoseUnderControl(BI, "branch phase on a bare i1 condition");
    return;
  }
  auto emitArm = [&](ArrayRef<Instruction *> Gates, Value *Ctl, bool CtlIsRail,
                     bool Neg) {
    // ONE bracket pair per ARM, not per gate: `cqrt_x` is self-inverse, so
    // `x;g1;x;x;g2;x` and `x;g1;g2;x` are the same unitary and the second is
    // what every sibling phase emitter has emitted since drbq Inc 2a. On a RAIL
    // root (bd 3qlq.4) the group helper uses `rz(−θ)` instead of any bracket.
    //
    // RECORDED (inside `emitKickbackGroup`), exactly as the flat emitter
    // records its arm gates (bd 3qlq Inc 1, Rule-13 round-1 F-L7-1). `Ctl` is
    // the OUTER root for the outer arm — a minted flag/node ancilla, or since
    // 1b the user's own `_Bool` register — and the CONJUNCTION ancilla for the
    // inner one. An ancilla the region owns would otherwise be read by
    // `ChainWalk::isInPlaceGateOn` as an ordinary in-place rotation on a
    // reclaimable rail — which is how the whole-DAG spine came to emit
    // `cqrt_rz_i1(f, -θ)` and cancel a user's phase EXACTLY. The record is
    // what makes the gate opaque; a NEW emission site that omits it re-opens
    // that miscompile with no diagnostic anywhere.
    emitKickbackGroup(B, Rz, X, Ctl, CtlIsRail, phaseAngles(Gates), Neg, DL,
                      taint);
  };

  // 1-2. OUTER network, then the outer arm's phases on its root.
  CondNetwork OuterNet;
  // (Track A.1, F-A1R2-1) `LeafWireRuled` — `classifyPhaseKickbackNest` walks
  // EACH level's own leaf+rail `condProvenance` union with
  // `findNonDiagonalWireGate` at round-1 taint before the nest is pushed.
  switch (emitCondNetwork(R.Condition, OuterTree, wd, csyms, taint,
                          /*Before=*/BI, DL, /*AllowQQLeaves=*/false,
                          OuterNet, /*CopyRailRoot=*/false,
                          /*LeafWireRuled=*/true)) {
  case CondNetDisp::Ok:
    break;
  case CondNetDisp::MintDiagnosed:
    return;  // `lowerCompareToFlag` was already LOUD; do not double-diagnose.
  case CondNetDisp::Malformed:
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }
  emitArm(R.Shadow, OuterNet.Root, OuterNet.RootIsRail, R.ArmNegated);

  // 3. INNER network. Its leaves read registers NO gate in this region touches
  // (the classifier proved `Mid` holds nothing but void phase calls and the
  // tree), so minting it here — at the OUTER branch, after the outer arm's
  // phases — reads exactly the basis the source compare reads.
  CondNetwork InnerNet;
  switch (emitCondNetwork(R.InnerCondition, InnerTree, wd, csyms, taint,
                          /*Before=*/BI, DL, /*AllowQQLeaves=*/false,
                          InnerNet, /*CopyRailRoot=*/false,
                          /*LeafWireRuled=*/true)) {
  case CondNetDisp::Ok:
    break;
  case CondNetDisp::MintDiagnosed:
  case CondNetDisp::Malformed:
    // ⚠ A MID-STREAM BAIL, and the ONLY one in this emitter — the outer network
    // and the outer arm's phases are already emitted. It is REACHABLE only
    // through detection/emission drift (the classifier ran the identical
    // per-leaf ladder over this identical tree), and the outcome is a LOUD
    // `DS_Error`, so `opt` exits non-zero and nothing downstream consumes the
    // half-stream. Say that plainly rather than calling it unreachable.
    if (Instruction *A = anchor())
      diagnoseUnderControl(A, "control flow");
    return;
  }

  // 4-6. THE CONJUNCTION. `g = (rootA ⊕ OuterNeg) ∧ (rootB ⊕ InnerNeg)` on a
  // fresh |0> ancilla, the inner arm's phases on `g`, then the SAME node again —
  // `cqrt_toffoli` and `cqrt_x` are each self-inverse and the controls are
  // read-only, so `g` returns to |0> EXACTLY and its free is clean (Rule 6).
  CondNetwork::Node Conj;
  Conj.Opc = Instruction::And;
  Conj.L = OuterNet.Root;
  Conj.R = InnerNet.Root;
  Conj.NegL = R.ArmNegated;
  Conj.NegR = R.InnerArmNegated;
  Conj.G = stamp(B.CreateCall(
      AllocI1, {Constant::getNullValue(Type::getInt1Ty(BI->getContext()))},
      "g"));
  // bd test_C_libtooling-r9e5 (1b-B.1, F-B1R2-1) — `&taint` because EITHER level
  // root may be the user's own `_Bool` register (`OuterRootIsRail` /
  // `InnerRootIsRail` above), in which case this toffoli is a control read of it
  // — and for an inner rail it is the ONLY one, since the inner arm's phases
  // ride the conjunction ancilla. `emitCondNode` owns the recording so this call
  // and `emitCondNetwork`'s cannot drift apart.
  emitCondNode(Conj, csyms, B, DL, /*Inverse=*/false, &taint);
  emitArm(R.ShadowFalse, Conj.G, /*CtlIsRail=*/false, /*Neg=*/false);
  emitCondNode(Conj, csyms, B, DL, /*Inverse=*/true);
  stamp(B.CreateCall(wd.freeFn(), {Conj.G}));

  // 7. STRIP, exact LIFO: the inner network (minted last) first, then the outer.
  // Each leaf strip is recorded in `DischargedFlagGates` for the same reason the
  // flat path records its one strip — it is the point past which a DERIVED
  // condition's chain may be discharged by the whole-DAG spine
  // (`ChainWalk::isInteriorConsumer`).
  SmallVector<CallInst *, 4> LeafStrips;
  stripCondNetwork(InnerNet, wd, csyms, taint, /*Before=*/BI, DL,
                   /*AllowQQLeaves=*/false, &LeafStrips);
  stripCondNetwork(OuterNet, wd, csyms, taint, /*Before=*/BI, DL,
                   /*AllowQQLeaves=*/false, &LeafStrips);
  for (CallInst *S : LeafStrips)
    taint.DischargedFlagGates.insert(S);

  // 8. ERASE THE ARM CALLS, THEN FLATTEN, THEN THE TREE INTERIORS. Each phase
  // call is erased rather than hoisted: its whole content is a `cqrt_rz_i1`
  // above. Scrub from `PhaseCalls` first so `deleteGlobalPhases` — which derives
  // its survivors from the IR — and any later module walk cannot dereference
  // freed memory.
  auto erasePhase = [&](CallInst *CI) {
    auto &PC = taint.PhaseCalls;
    PC.erase_value(CI);
    CI->eraseFromParent();
  };
  for (Instruction *I : R.Shadow)
    erasePhase(cast<CallInst>(I));
  for (Instruction *I : R.ShadowFalse)
    erasePhase(cast<CallInst>(I));
  // `flattenRegionTree` is the SHARED three-block teardown (Rule 14): drop both
  // branches, erase both dead condition ROOTS, splice the shared merge into
  // `Pred` EXACTLY ONCE, erase InnerArm → Mid → Merge in that order. It takes a
  // NULL merge φ since this increment — this nest has none — and an EMPTY arm-gate
  // list, because the phase calls are already gone.
  //
  // ⚠ `Inner.Condition` MUST BE RE-POINTED AT THE INNER ROOT. `flattenRegionTree`
  // erases `Outer.Condition` and `Inner.Condition` as two separate dead values;
  // leaving the copy's inherited `Condition` in place makes it erase the OUTER
  // root TWICE — a double free, MEASURED as a SIGSEGV inside the flatten on the
  // very first P4 run.
  ControlRegion Outer = R, Inner = R;
  Outer.Merge = nullptr;
  Outer.Arm = R.Arm;
  Inner.Merge = nullptr;
  Inner.Condition = R.InnerCondition;
  Inner.Arm = R.ArmFalse;
  Inner.Pred = R.Arm;
  // The tree INTERIORS are not the flatten's to erase (it owns only the two
  // ROOTS), and leaving one behind is not harmless: with its root gone every
  // node and leaf is dead, and a dead TAINTED compare is exactly what `lowerOps`
  // would turn into a spurious template plus a leaked flag rail a few steps
  // later.
  //
  // ⚠ ONLY `Pred`-RESIDENT TREE INSTRUCTIONS SURVIVE THE FLATTEN, AND THE LIST
  // MUST BE SNAPSHOTTED BEFORE IT RUNS. `flattenRegionTree` erases `Mid` and
  // `InnerArm` WHOLESALE, and the inner condition tree normally lives in `Mid`
  // — so a post-flatten walk over `InnerTree` would call `use_empty()` on
  // instructions the block destructor already freed. MEASURED: SIGSEGV inside
  // `ValueSymbolTable::reinsertValue` on the very first compound-inner nest
  // (`if (q>5) { cq_phi; if (q<9 && r==3) cq_phi; }`); the single-compare nests
  // were silently fine only because their inner tree is JUST the root, which is
  // skipped. Capture the survivors first, then erase after.
  //
  // That the destroyed instructions are safe to destroy is the classifier's data-use
  // fence, not luck: every tree instruction's users must lie inside its own tree or be
  // its level's branch, and the flatten erases both branches and both roots before
  // either block goes — so nothing in `Mid`/`InnerArm` still has a use when its
  // block is deleted. Relax that fence and this becomes a dangling-use UB, not a
  // decline.
  Value *const OuterRoot = R.Condition;
  Value *const InnerRoot = R.InnerCondition;
  BasicBlock *const Survivor = R.Pred;
  SmallVector<Instruction *, 8> Cascade;
  for (const CondTree *T : {&InnerTree, &OuterTree}) {
    for (Instruction *N : llvm::reverse(T->Nodes))
      if (N != OuterRoot && N != InnerRoot && N->getParent() == Survivor)
        Cascade.push_back(N);
    for (CmpInst *Leaf : llvm::reverse(T->Leaves))
      if (Leaf != OuterRoot && Leaf != InnerRoot && Leaf->getParent() == Survivor)
        Cascade.push_back(Leaf);
  }
  flattenRegionTree(Outer, Inner, /*armPhis=*/{}, taint);
  // ROOT-FIRST within each tree (the snapshot above is already in that order), so
  // a child's use count has dropped before it is tested. The roots are compared
  // by POINTER only — they may already be freed memory; nothing is dereferenced
  // through them, and no instruction is created between the flatten and here.
  for (Instruction *I : Cascade)
    if (I->use_empty()) {
      scrubTaint(I, taint);
      I->eraseFromParent();
    }
}

void lowerControlRegions(Module &M, WidthDispatch &wd, TaintSet &taint,
                         const ControlPlan &plan) {
  if (plan.Regions.empty())
    return;  // nothing accepted — classical / fully-declined module untouched.

  const auto &Regions = plan.Regions;

  // A coordinated parent/child pair (a Depth-N region and its Depth-(N+1) child,
  // linked by `ParentIdx`) DELIBERATELY shares blocks: the 4.3 nest's Outer and
  // Inner share `MergeBB` and `Outer.Arm == Inner.Pred` (§0 criterion 1).
  // The deleted `NestedRouteEmit` tore the pair down together, so the pre-flight
  // below EXEMPTS such a pair (vestigial since 3qlq: nothing pushes a Depth-1
  // region) while staying active for independent / sequential ones (MD0).
  auto coordinated = [&](size_t a, size_t b) {
    const ControlRegion &A = Regions[a], &B = Regions[b];
    return (B.Depth == A.Depth + 1 && B.ParentIdx == a) ||
           (A.Depth == B.Depth + 1 && A.ParentIdx == b);
  };

  // The blocks a region's flatten actually ERASES (its "doomed" set) — what the
  // pre-flight below must protect from another region's references. iw81.7/g5gi: a
  // `GuardedStoreArm` flatten erases ONLY its `Arm` block (it splices the gep+store
  // into `Pred` and rewires `Pred → MergeBB` unconditionally — `MergeBB` and `Pred`
  // SURVIVE, unlike the phase / if-else flatten which erases `MergeBB`). So a
  // guarded store's genuine doomed set is `{Arm}`, NOT `{Arm, ArmFalse, MergeBB}` —
  // exempting `MergeBB` is what un-blocks two guarded diamonds sharing a block (the
  // first's `MergeBB` is the second's `Pred`; PRD-g5gi §2). The exemption is
  // KIND-scoped: every OTHER region kind keeps `{Arm, ArmFalse, MergeBB}`, so a
  // guarded region whose `Pred` is a PHASE region's (really-erased) merge still
  // declines — the protection is intact in that direction (defense-in-depth).
  auto doomedBlocks = [&](const ControlRegion &R) {
    SmallVector<BasicBlock *, 3> Doomed;
    Doomed.push_back(R.Arm);
    if (R.Kind != ControlRegion::GuardedStoreArm) {
      Doomed.push_back(R.ArmFalse);
      Doomed.push_back(R.MergeBB);
    }
    return Doomed;
  };

  // Does region `i` own a coordinated Depth-(N+1) child (the 4.3 nest)?
  auto hasChild = [&](size_t i) {
    for (size_t j = 0; j < Regions.size(); ++j)
      if (Regions[j].Depth == Regions[i].Depth + 1 && Regions[j].ParentIdx == i)
        return true;
    return false;
  };

  // The SEQUENTIAL-CHAIN alias (bd hcrg) — the one block alias that emission
  // ORDER can resolve, and the only one this function is allowed to accept.
  //
  // `if (q){…} …; if (q'){…}` is, after clang -O1, two flat regions where the
  // FIRST one's merge block hosts the SECOND one's conditional branch — i.e.
  // `A.Pred == B.MergeBB` with B the earlier region. That alias used to be a
  // detection-time decline (`nested control flow`) because `flattenRegion`
  // splices B's merge into B's pred and ERASES it, dangling A's `Pred` pointer:
  // a use-after-free, SIGSEGV on valid input (§8 adversarial review 2026-06-10).
  //
  // Nothing about that is semantic — it is a teardown-ORDER bug. Emit A FIRST
  // and it cannot arise: A's blocks are all still live (B's flatten has not run),
  // A's own flatten erases only {A.Arm, A.ArmFalse, A.MergeBB} — none of which is
  // any block of B — and A's tail is spliced into A.Pred, which IS B's merge and
  // SURVIVES its own flatten by construction (`flattenRegion` never erases a
  // Pred). B then flattens with every one of its blocks intact, carrying A's
  // already-emitted stream along in the splice. Program order of the emitted
  // gates is unaffected: each emitter inserts POSITIONALLY into its own pred
  // block, so B's stream still precedes A's in the final linear block.
  //
  // The predicate is deliberately narrow — the chain shape and nothing else:
  // both regions flat, childless, Depth-0 `BranchRegion`s, and `A.Pred ==
  // B.MergeBB` must be the ONLY block A shares with B's doomed set. A genuine
  // OVERLAP (two regions sharing an arm or a merge) is not reorderable and keeps
  // declining below, as does anything involving a nest, a switch, a select or any
  // other kind. Over-declining is always safe (Prime Directive); this widens the
  // accept set by exactly one proven shape.
  //
  // STRUCTURAL LEMMA (bd hcrg Rule-13 clearance, block-lifetime lens): among
  // `BranchRegion`s, `A.Pred == B.MergeBB` is the ONLY block alias that can
  // occur at all, so the "…and nothing else" loop below is defence-in-depth over
  // a provably empty space. Three facts, each read off the recognizers:
  //   1. A `Pred` ends in a CONDITIONAL br, and every recognizer in
  //      `recoverRegion` requires `uncondSucc(arm)` non-null ⇒ `A.Pred` can never
  //      be `B.Arm`/`B.ArmFalse`. (Same for the other kinds: an `AbortPark` arm
  //      ends in `unreachable`, a `GuardedStoreArm`/`ClassicalCallArm` arm in an
  //      unconditional br.)
  //   2. A merge has exactly TWO predecessors (`soleMergePhi` demands a
  //      2-incoming phi, and a phi must list every pred) while an arm has exactly
  //      ONE (`getSinglePredecessor() == Pred`) ⇒ an arm and a merge are never
  //      the same block, in either direction.
  //   3. Two distinct `BranchRegion`s cannot SHARE a `MergeBB`: its pred set is
  //      `{Pred, Arm}` or `{Arm, ArmFalse}`, and equality forces either the same
  //      `Pred` (hence the same terminator, hence the same region) or an arm
  //      ending in a conditional br, which (1) excludes.
  // The loop stays because the lemma is a property of TODAY's recognizers: a
  // future shape that relaxes any of the three must fail this predicate LOUDLY
  // rather than silently acquire a reorder it was never cleared for.
  //
  // KNOWN AND ACCEPTED, worth writing down before someone rediscovers it in a
  // trace (bd hcrg Rule-13 clearance, unitary lens): a chain of VALUE regions
  // stacks leftovers PER REGION — each region's merged `%out`, its source rail
  // and (since 3qlq Inc 2) the chain's final rail stay allocated.
  // Every region is individually correct and `free_pairing_check.py` is clean on
  // the chain (Rule 6 leaves a not-provably-|0> rail ALLOCATED rather than
  // freeing it dirty), but the leak is now linear in chain length where before
  // it was capped at one, because chained value arms used to decline outright.
  // Qubits are not scarce in this regime (PRD §8.2); if that ever changes, this
  // is the shape to revisit first.
  //
  // WIDENED to `PhaseKickback` (bd test_C_libtooling-3qlq Inc 1). The hcrg
  // argument above transfers WORD FOR WORD to a kickback region: its flatten
  // erases exactly `{Arm, MergeBB}` (`ArmFalse` is null), its `Pred` survives by
  // construction, and its emitter inserts positionally into that `Pred` — so
  // emitting the LATER region first is sound for the identical reason. The
  // STRUCTURAL LEMMA transfers too, but only because `classifyPhaseKickback`
  // asks `MergeBB->hasNPredecessors(2)` explicitly: point 2 (an arm has one
  // pred, a merge two, so they are never the same block) and point 3 (two
  // distinct regions cannot share a merge) are read off `soleMergePhi`'s
  // 2-incoming φ for a `BranchRegion`, and a kickback merge has no φ to read.
  // That is why the check is in the classifier and not left to the flatten.
  //
  // MEASURED: without this widening the flagship two-diamond Grover customer
  // (`if (q==5) cq_phi(π); … if (q==0) cq_phi(π);` — PRD §1's own program)
  // declines `control flow`, because region 2's `Pred` IS region 1's `MergeBB`.
  auto sequentialChainAlias = [&](size_t ai, size_t bi) {
    auto reorderable = [](const ControlRegion &R) {
      return R.Kind == ControlRegion::BranchRegion ||
             R.Kind == ControlRegion::PhaseKickback;
    };
    const ControlRegion &A = Regions[ai], &B = Regions[bi];
    if (!reorderable(A) || !reorderable(B))
      return false;
    if (A.Depth != 0 || B.Depth != 0 || hasChild(ai) || hasChild(bi))
      return false;
    if (!A.Pred || !B.MergeBB || A.Pred != B.MergeBB)
      return false;
    // …and NOTHING else of A's aliases a block B's flatten will erase.
    for (BasicBlock *Doomed : doomedBlocks(B)) {
      if (!Doomed)
        continue;
      if (A.Arm == Doomed || A.ArmFalse == Doomed || A.MergeBB == Doomed)
        return false;  // a real overlap, not a chain.
      if (A.Pred == Doomed && Doomed != B.MergeBB)
        return false;  // A's pred aliases an ARM — not the chain shape.
    }
    return true;
  };

  // Fail-loud decline shared by the overlap and cycle paths below.
  // INVARIANT (WI-5 §8 review, NIT — keep this path fail-loud): every region
  // recovered today sets BOTH `Condition = BI->getCondition()` (an Instruction)
  // AND `Merge` (a PHINode), so one of the two diagnose arms ALWAYS fires — this
  // never silently skips a tainted br (Rule 1). A FUTURE region kind that leaves
  // both null (e.g. a synthesized flag-combination Value) MUST add a fallback
  // diagnostic here (anchor on a region block's terminator); a bare return past
  // both arms would be a silent accept of quantum-controlled flow — the one
  // unforgivable bug (Prime Directive).
  // ⚠ RETIREMENT TRIGGER (bd `boi6` D-B / Track M, round-1 finding F-M7; the
  // premise CORRECTED by round-2 finding F2-2, which caught the round-1 fix
  // falsifying its own comment).
  //
  // `A.Condition` is a RAW `Value *` and this reads it. A `SelectRegion` REACHES
  // this lambda — do not read the old claim that it cannot. The F-M1 edge loop at
  // `:2639` calls `declineRegion(Regions[i])` on a `SelectRegion` directly, and
  // because that loop can leave `Pending[select] >= 1`, the Kahn backstop at
  // `:2667` can now find a select `!Done` and decline it too. Only the alias
  // pre-flight's `declineRegion` (`:2573`) still cannot see one, and that is the
  // null block fields plus `if (!Doomed) continue;`, not any `Kind` test.
  //
  // It is nevertheless SAFE TODAY, for a reason about TIME rather than about kind:
  // all three call sites run BEFORE any emission (the pre-flight, the edge loop and
  // the Kahn backstop all precede the `for (size_t i : Order)` emission loop at
  // `:2685`, and each returns immediately after diagnosing, lowering NOTHING). No
  // M-β RAUW and no `RegionFlatten` erasure has happened yet, so every region's
  // `Condition` — a `SelectRegion`'s merge φ included — is still a live
  // instruction, and the `A.Merge` arm is available as the fallback anchor.
  //
  // SO THE TRIGGER IS ABOUT THE EMISSION-TIME READERS, NOT ABOUT THIS LAMBDA: the
  // day a region's condition is read from the plan's cached pointer AFTER another
  // region has been emitted (the `fg9k` value arm on a φ is the obvious candidate,
  // and a fourth `declineRegion` call site placed inside the emission loop is the
  // other), that read can dereference freed memory. The fix is the one
  // `emitSelectRegion` took: re-read from the live instruction, never from the
  // plan's cached pointer.
  auto declineRegion = [&](const ControlRegion &A) {
    if (auto *Anchor = dyn_cast_or_null<Instruction>(A.Condition))
      diagnoseUnderControl(Anchor, "control flow");
    else if (A.Merge)
      diagnoseUnderControl(A.Merge, "control flow");
  };

  // Pre-flight + emission order, computed while EVERY region's blocks are still
  // valid (the block-lifetime rule): no accepted region may be emitted AFTER
  // another (non-coordinated) accepted region has erased a block it names
  // (Arm/ArmFalse/MergeBB). Every such alias is either resolved by ordering (the
  // proven sequential chain above) or declined LOUDLY here — never dereferenced
  // in emitRegion (the §8-confirmed sequential-region SIGSEGV family,
  // 2026-06-10). Pointer-identity checks only; nothing is dereferenced.
  //
  // `Precedes[a]` lists the regions that must be emitted AFTER `a`; `Pending[b]`
  // counts how many regions must be emitted BEFORE `b`.
  const size_t N = Regions.size();
  SmallVector<SmallVector<size_t, 2>, 8> Precedes(N);
  SmallVector<unsigned, 8> Pending(N, 0);
  for (size_t a = 0; a < N; ++a)
    for (size_t b = 0; b < N; ++b) {
      if (a == b || coordinated(a, b))
        continue;
      const ControlRegion &A = Regions[a], &B = Regions[b];
      bool Aliases = false;
      for (BasicBlock *Doomed : doomedBlocks(B)) {
        if (!Doomed)
          continue;
        if (A.Pred == Doomed || A.Arm == Doomed || A.ArmFalse == Doomed ||
            A.MergeBB == Doomed)
          Aliases = true;
      }
      if (!Aliases)
        continue;
      if (!sequentialChainAlias(a, b)) {
        declineRegion(A);
        return;  // lower NOTHING — over-declining is always safe.
      }
      Precedes[a].push_back(b);  // A names a block B's flatten erases → A first.
      ++Pending[b];
    }

  // Kahn topological order. Ties break on plan index, so a module with no alias
  // at all keeps the exact plan order it has always had (`Pending` all zero →
  // `Order` == 0,1,2,…): this reordering is INERT for every shape that lowered
  // before — which is why the whole 241-golden e2e layer is byte-identical
  // across this change. Each ordered pair contributes AT MOST ONE edge (the
  // `Aliases` flag is a bool, not a counter), so `Pending` cannot underflow and
  // `Done` cannot admit a region twice.
  //
  // A cycle (mutual aliasing that no order can satisfy) leaves regions
  // unscheduled — decline loudly rather than pick one and dereference the other.
  // UNREACHABLE TODAY, DELIBERATELY KEPT, AND IT CANNOT BE GIVEN A FIXTURE (bd
  // hcrg Rule-13 clearance) — but NOT for the reason this comment used to give,
  // and the correction matters because the old one invited deleting the branch
  // (bd drbq Inc 3, round-1 lens L4, F-L4-1). It said a precedence cycle needs a
  // CFG cycle through the region entries, "and `regionEntryInLoop` declines
  // every flat region on a cycle at DETECTION
  // (`control_swap_reject_seq_in_loop.ll`)". BOTH HALVES ARE FALSE AT HEAD: that
  // fixture was renamed to `control_swap_inloop_seq.ll` AND FLIPPED TO ACCEPT by
  // 8h7d.5, and flat regions on a cycle DO reach the plan — two sequential phase
  // regions in a loop lower today (exit 0, both binaries), and since Inc 3 so
  // does the Ry-arm twin. So the population this backstop reasons about is
  // NON-EMPTY and growing.
  //
  // What is still true is the narrower claim: a precedence CYCLE needs a
  // region's `MergeBB` to be a loop header, i.e. a merge φ with three or more
  // predecessors, and region recovery refuses that (`soleMergePhi` requires
  // exactly 2 incomings). Lens L4 could not construct one. Do not delete this as
  // dead code: it is the backstop for the day merge recovery is widened, and a
  // bare fall-through here would emit a partial region set over freed blocks.
  // bd `boi6` D-B / Track M, round-1 finding F-M1 — THE MERGE-φ SELECT'S ONE EDGE.
  //
  // A `SelectRegion` is INERT in everything above: all four of its block fields
  // are null, so it never `Aliases` as `A` and `doomedBlocks` yields nothing for
  // it as `B`. For a compare- or rail-conditioned select that is exactly right —
  // nothing rewrites its condition, so any position will do. For a MERGE-φ
  // -conditioned select it is WRONG, and the hole was measured on plain C
  // (`r03_order_third_region.c`): the select's condition is the prep diamond's φ,
  // which `emitInPlaceRotationRegion`'s M-β RAUWs to the hoisted `cq_theta` and
  // then ERASES — so the select MUST be emitted after the prep. Left inert, it is
  // not: a following `PhaseKickback` whose `Pred` is the prep's `MergeBB` takes
  // the sanctioned `sequentialChainAlias` edge `Precedes[kickback] = {prep}`,
  // which schedules the prep LAST, after the select, whose re-read then finds the
  // φ still live and fires the loud H-1 backstop. An OVER-DECLINE.
  //
  // ⚠ THE EDGE IS ADDED BY *CALLING* THE CLASSIFIER'S RECORD, NEVER BY RE-DERIVING
  // ITS PREDICATE (Rule 14 — the drbq Inc-3 (b′) defect was a second spelling of a
  // predicate the tree already owned). `classifySelectRegion` ran the §M.0 ladder,
  // committed the admitting region's index in `PrepRegionIdxs`, and this loop only
  // transcribes it. Nothing here knows what an `InPlaceRotation` arm is.
  //
  // bd `4aiu` (Track P) — ONE EDGE PER φ LEAF. With Track M's ROOT-ONLY conjunct
  // gone a select's condition tree may carry several φ leaves, each rewritten by
  // a DIFFERENT prep region's M-β, so each owes its own "prep before me" edge.
  // Each `Aliases` pair still contributes at most one edge here because the
  // classifier records at most one index per DISTINCT leaf and two distinct
  // leaves cannot name one region (a `BranchRegion` has exactly one `Merge`), so
  // `Pending` cannot be double-counted.
  //
  // IT CANNOT CREATE A CYCLE, and the argument is structural rather than
  // empirical: this is the ONLY way a `SelectRegion` acquires an edge, and every
  // such edge points INTO it. A node with no outgoing edges cannot lie on a cycle,
  // so the Kahn backstop below keeps exactly the population it had.
  //
  // The `PrepRegionIdxs` bound is re-checked rather than trusted: detection only
  // ever `push_back`s, so a stale or out-of-range index is not reachable, but a
  // silent skip here would restore the over-decline with no diagnostic — so an
  // out-of-range index declines LOUDLY instead (Rule 1, never a third path).
  for (size_t i = 0; i < N; ++i) {
    if (Regions[i].Kind != ControlRegion::SelectRegion)
      continue;
    for (unsigned P : Regions[i].PrepRegionIdxs) {
      if (P == ControlRegion::kNoParent)
        continue;  // never recorded, but a skip must not be a silent one.
      if (P >= N || P == i) {
        declineRegion(Regions[i]);
        return;  // lower NOTHING — over-declining is always safe.
      }
      Precedes[P].push_back(i);
      ++Pending[i];
    }
  }

  // bd `test_C_libtooling-hn29` / `-leyd` / `-52og` (Track P′) — THE SAME FIELD,
  // THE OPPOSITE DIRECTION, FOR A `PhaseKickback`. Read this beside the loop
  // above, never instead of it.
  //
  // A merge-φ-conditioned KICKBACK must be emitted BEFORE the prep whose φ it
  // reads, because it consumes the φ AS A VALUE: the prep's M-β RAUWs that φ to
  // the hoisted `cq_theta` and `flattenRegion` then frees it, and
  // `emitPhaseKickbackRegion`'s `CondV != R.Condition` identity check (bd `3qps`)
  // turns a prep-first order into a loud `control flow` decline. A `SelectRegion`
  // wants the reverse — `SelectMergeEmit` RE-READS its condition and therefore
  // needs M-β to have already run. Two emitters, two needs, one field; the `Kind`
  // test at the top of each loop is what keeps them apart.
  //
  // UNTIL THIS INCREMENT THE KICKBACK NEEDED NO EDGE, and the reason it does now
  // is exactly the reason the increment exists. `ArmClassify`'s step-5c theorem
  // derives `Precedes[kickback] = {prep}` from `P->getParent() == Region.Pred`
  // ⟹ `kickback.Pred == prep.MergeBB` ⟹ the bd `hcrg` `Aliases` test fires. Track
  // P′ admits φ leaves that are NOT in `Pred`, so that hypothesis fails and the
  // sanctioned alias edge is simply absent — MEASURED on `a1_clean_gap2.ll` and
  // on bd `52og`'s in-loop customer, where plan (detection) order puts the prep
  // first and the module declines `control flow`. The edge restores the order the
  // adjacency used to supply for free.
  //
  // ⚠ DEDUPED AGAINST THE ALIAS EDGE, DELIBERATELY. When the φ IS in `Pred` the
  // alias loop above has ALREADY added this exact edge; adding it twice would
  // leave `Pending[prep]` at 2 with two matching decrements — arithmetically
  // harmless today, but it falsifies the Kahn comment's stated invariant ("each
  // ordered pair contributes AT MOST ONE edge … so `Pending` cannot underflow"),
  // and an invariant that is only accidentally true is how the next change breaks
  // it silently.
  //
  // ⚠ IT CAN CREATE A CYCLE WHERE THE SELECT'S EDGE COULD NOT, and that is stated
  // rather than argued away: a select gains only INCOMING edges, while this gains
  // OUTGOING ones. A cycle needs the prep to also require emission after the
  // kickback, i.e. `prep.Pred` ∈ `doomedBlocks(kickback)` — the prep would have to
  // sit AFTER the kickback in the CFG, while its merge φ dominates the kickback's
  // branch, which no dominance relation permits. The Kahn backstop below is the
  // enforcement rather than this paragraph: a cycle leaves regions unscheduled and
  // declines LOUDLY, lowering nothing.
  for (size_t i = 0; i < N; ++i) {
    if (Regions[i].Kind != ControlRegion::PhaseKickback)
      continue;
    for (unsigned P : Regions[i].PrepRegionIdxs) {
      if (P == ControlRegion::kNoParent)
        continue;  // never recorded, but a skip must not be a silent one.
      if (P >= N || P == i) {
        declineRegion(Regions[i]);
        return;  // lower NOTHING — over-declining is always safe.
      }
      if (llvm::is_contained(Precedes[i], P))
        continue;  // the sanctioned alias edge already says exactly this.
      Precedes[i].push_back(P);
      ++Pending[P];
    }
  }

  SmallVector<size_t, 8> Order;
  Order.reserve(N);
  SmallVector<bool, 8> Done(N, false);
  for (bool Progress = true; Progress;) {
    Progress = false;
    for (size_t i = 0; i < N; ++i)
      if (!Done[i] && Pending[i] == 0) {
        Done[i] = true;
        Order.push_back(i);
        for (size_t j : Precedes[i])
          --Pending[j];
        Progress = true;
      }
  }
  if (Order.size() != N) {
    for (size_t i = 0; i < N; ++i)
      if (!Done[i]) {
        declineRegion(Regions[i]);
        return;  // lower NOTHING — over-declining is always safe.
      }
  }

  ControlledSymbols csyms(M, wd);
  // Emit. Each Kind dispatches to its emitter; a flat (Depth-0) `BranchRegion`
  // takes `emitRegion`. A Depth>0 child is SKIPPED: re-visiting one would
  // dereference erased blocks (blocker MD4). Since 3qlq nothing pushes a Depth-1
  // region and the 4.3 `NestedRouteEmit` nest dispatch is gone (see below); the
  // register-free depth-2 nest is one `PhaseKickbackNest` region. The plan is
  // `const` (COMPLETENESS#7).
  // Iterate the ORDER computed above, not the plan order — `i` stays the real
  // plan index so the `ParentIdx` child lookup below is unaffected.
  for (size_t i : Order) {
    const ControlRegion &R = Regions[i];
    if (R.Kind == ControlRegion::SelectRegion) {
      // 4.4 — a tainted-condition integer-data select: the controlled-XOR copy
      // merge (no CFG diamond, no rail/route, no child nest). Its block fields
      // are all null, so the pre-flight above treated it as inert (the
      // `if (!Doomed) continue;` guard). Dispatch + continue BEFORE the Depth /
      // child-lookup branch, which keys on null CFG anchors.
      emitSelectRegion(R, wd, csyms, taint);
      continue;
    }
    if (R.Kind == ControlRegion::AngleSelectRegion) {
      // drbq Inc 2b (control-in-place-PRD §12.3) — a tainted-condition select
      // over the classical rotation ANGLE, feeding ONE chained
      // `cq_theta`/`cq_phi`. Lowered BY DIFFERENCE (unconditional `R(h,B)`, flag
      // mint, `R_controlled(f,h,A−B)`, strip, free): no CFG diamond, no rail, no
      // route, no flatten, no child nest — its block fields are all null, so the
      // pre-flight above treated it as inert (the `if (!Doomed) continue;`
      // guard), exactly as for a `SelectRegion`. Dispatch + continue BEFORE the
      // Depth / child-lookup branch, which keys on null CFG anchors.
      //
      // ⚠ BEING INERT TO THE PRE-FLIGHT IS SAFE FOR A REASON THAT LIVES
      // ELSEWHERE, so state it here rather than leaving the next reader to
      // rediscover it (bd drbq Inc 2b, notes finding I). A select in another
      // region's `Pred` is never erased and one in its `MergeBB` is SPLICED into
      // the pred and survives — but one in an `Arm` would be FREED, and plan
      // order puts that region first, so this emitter's "re-validate by SSA
      // identity" would be reading freed memory rather than validating. It
      // cannot happen at HEAD, and ⚠ THE REASON CHANGED AT bd
      // `test_C_libtooling-fn1q` INCREMENT 1 — re-proved here rather than
      // re-quoted, because that increment FALSIFIED the old one and this
      // comment's own retirement trigger (below) is what demanded the re-proof
      // (Rule-13 round 1, finding F-2).
      //
      // THE OLD REASON, NOW FALSE: "every region kind that erases an arm
      // constrains that arm to a shape a `select` cannot satisfy", naming
      // `valueArmIsPureChain` among the fences. `valueArmIsPureChain` now ADMITS
      // a `select` in a value arm — as a CLASSICAL CONE member, hoisted into the
      // pred — so a `select` can satisfy it, and an accept fixture exists
      // (Rule-13 round-1 probe `P1_untainted_select_cone.ll`).
      //
      // THE CURRENT REASON, and it is about the ANGLE select specifically rather
      // than about selects in general. An `AngleSelectRegion`'s select is a
      // TAINTED-CONDITION select over a rotation ANGLE whose consumer is a
      // `cq_theta`/`cq_phi` CALL. Two cone conjuncts close it, and which one
      // fires depends on where that call sits:
      //   * consumer INSIDE the arm  → the call is a non-intrinsic `CallInst`,
      //     which cone conjunct **(K5)** refuses, so the whole ARM declines and
      //     no region erases it (measured: `control flow`, identical on the
      //     pre-increment oracle);
      //   * consumer OUTSIDE the arm → the select escapes its block, which cone
      //     conjunct **(K3)** refuses (measured: `rotation angle`, identical on
      //     the oracle).
      // The other listed fences (`armBlockIsPureSpine`, `inPlaceRotationArmTheta`,
      // `classifyClassicalCallArm`'s `Arm->size() != 2`, the guarded-store
      // gep+store shape, `AbortPark`'s sink+`unreachable`) are unchanged.
      //
      // ⚠ RETIREMENT TRIGGER, RESTATED BECAUSE IT JUST PAID FOR ITSELF: a future
      // region kind that erases a block whose contents it does not fix — or any
      // widening of (K3) or (K5) — must extend the pre-flight to this Kind or
      // RE-PROVE this purity. Re-proving means building the shape and measuring
      // both binaries, as the two measurements above were; it does not mean
      // editing this paragraph.
      emitAngleSelectRegion(R, wd, taint);
      continue;
    }
    if (R.Kind == ControlRegion::SwitchRegion) {
      // 4.5 — a tainted-condition `switch`. Its Pred (switch block) + MergeBB are
      // set, so the pre-flight above covered the shared merge; the case-arm blocks
      // are single-pred(switch) (resolveArm) and so cannot alias another region's
      // Pred/Arm/Merge, so leaving them out of the pre-flight is safe (§6.4
      // decision (a) — treat like select). Dispatch by content class BEFORE the
      // Depth / child-lookup branch (a switch carries no `ParentIdx` nest link).
      if (R.SwitchCls == SwitchClass::Phase) {
        emitSwitchPhaseRegion(R, wd, csyms, taint);
      } else if (R.SwitchCls == SwitchClass::Value) {
        // 4.5 WI-3 — homogeneous value-chain switch: preload + XOR-delta over the
        // shared base `p` = the merge default-edge incoming (`p != q`).
        emitSwitchValueRegion(R, wd, csyms, taint);
      } else if (R.SwitchCls == SwitchClass::DataMux) {
        // 4.5 WI-4 — all-ConstantInt data-mux: PRELOAD %out=cqrt_alloc(v_d) +
        // per content case the XOR-delta controlled copy (no route, no ¬-bracket;
        // the default is the preload). IMPLEMENTATION-4.5 §4C.
        emitSwitchDataMuxRegion(R, wd, csyms, taint);
      } else {
        // An unknown future SwitchClass — never silently skip a tainted switch
        // (Prime Directive): bail LOUDLY.
        if (auto *Anchor = dyn_cast_or_null<Instruction>(R.Merge))
          diagnoseUnderControl(Anchor, "control flow");
        else if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
          diagnoseUnderControl(A, "control flow");
      }
      continue;
    }
    if (R.Kind == ControlRegion::AbortPark) {
      // 7.2 Inc 3 — abort/exit park cascade: mint the flag, `cqrt_cswap` the
      // routed handle into a KEPT graveyard rail (self-bracketed), record the
      // abort flag on the tape, and run the sibling/downstream UNCONTROLLED. Its
      // Pred/Arm/Condition are set (Merge/MergeBB/ArmFalse null — the sink arm has
      // nothing to merge and the sibling SURVIVES), so the cross-region pre-flight
      // above covered the sole doomed block (the sink Arm) and the non-null
      // Condition kept its diagnose arm live. No nest link — dispatch + continue
      // BEFORE the Depth / child-lookup branch (which keys on CFG anchors).
      emitAbortParkRegion(R, wd, csyms, taint);
      continue;
    }
    if (R.Kind == ControlRegion::GuardedStoreArm) {
      // iw81.7 — a tainted-index Shadow store inside a tainted-condition diamond
      // arm: mint the path-predicate flag, record (store→flag), FLATTEN the diamond
      // (splice the gep+store into Pred, rewire straight to the merge), leave the
      // flag LIVE. `lowerShadowMemory` then emits the guarded store; the whole-DAG
      // LIFO uncompute reverses it (`..._controlled_unc`) and strips the flag. Its
      // Pred/Arm/MergeBB are set (a real diamond), so the cross-region pre-flight
      // above covered the block-lifetime hazard. No nest link — dispatch + continue
      // BEFORE the Depth / child-lookup branch.
      emitGuardedStoreArmRegion(R, wd, taint);
      continue;
    }
    if (R.Kind == ControlRegion::ClassicalCallArm) {
      // 6.5 (DD-7) — a pure classical call inside a tainted-condition diamond
      // arm: hoist the call into Pred, then the 4.4-style controlled-copy merge
      // over the FLATTENED diamond (no clone, no cswap/route, no reverse-play).
      // Its Pred/Arm/MergeBB are set (a real diamond), so the cross-region
      // pre-flight above already covered the block-lifetime hazard (WI-5.8). It
      // carries no `ParentIdx` nest link, so dispatch + continue BEFORE the
      // Depth / child-lookup branch.
      emitClassicalCallArmRegion(R, wd, csyms, taint);
      continue;
    }
    if (R.Kind == ControlRegion::PhaseKickbackNest) {
      // 3qlq Inc 1 (P4) — the GENUINE depth-2 register-free PHASE NEST: two
      // condition networks, ONE `cqrt_toffoli` conjunction ancilla, `cqrt_rz_i1`
      // on the outer root and on the conjunction, exact LIFO undo. ONE region
      // (no `ParentIdx` link), its doomed blocks `{Arm, ArmFalse, MergeBB}` =
      // `{Mid, InnerArm, Merge}` already covered by the cross-region pre-flight
      // above. Dispatch + continue BEFORE the Depth / child-lookup branch.
      emitPhaseKickbackNestRegion(R, wd, csyms, taint);
      continue;
    }
    if (R.Kind == ControlRegion::PhaseKickback) {
      // 3qlq Inc 1 (P1) — the register-free BRANCH PHASE by kickback: mint the
      // flag, ONE UNCONTROLLED `cqrt_rz_i1(f, θ)` on it, strip, free, flatten.
      // Its Pred/Arm/MergeBB are set (a real diamond) so the cross-region
      // pre-flight above covered the block-lifetime hazard; `Merge` is NULL (a
      // void arm has no φ), which is exactly why detection had to PRE-PEEL it.
      // No nest link — dispatch + continue BEFORE the Depth / child-lookup
      // branch. The in-loop `Pred` is recorded for the same reason `emitRegion`
      // records it (the round-2 rail collapse's sole trigger); a kickback leaves
      // nothing FOR that collapse to claim, but the loop may hold other regions
      // that do. INCREMENTED, not inserted (bd 3qlq Inc 1, C-1 review round 2,
      // F-C1-2(2b)): the round-2 onward pass keys its delta on the COUNT moving,
      // because a round-2 region routinely flattens into the very `Pred` a
      // round-1 region already used and a set could not see that.
      if (R.InLoop)
        ++taint.InLoopFlattenedPreds[R.Pred];
      emitPhaseKickbackRegion(R, wd, csyms, taint);
      continue;
    }
    if (R.Depth > 0)
      continue;  // a nested child — owned by its parent's dispatch.
    // ⚠ THE PARENT/CHILD NEST DISPATCH IS GONE (bd test_C_libtooling-3qlq Inc 1
    // part B). It called `NestedRouteEmit::lowerNestedRegion`, which is DELETED
    // along with the 4.3 swap-routed nest it emitted: that emitter's per-level
    // `cqrt_cswap` route existed only to carry a REGISTER-form arm gate, and one
    // of its two work-rail replays was the TENSORED `cqrt_rz_<W>` this epic
    // exists to retire. Its detector (`recoverRegionTree`) now declines instead
    // of accepting — every criterion it proves is a consequence of the register
    // form — so NOTHING pushes a Depth-1 region any more, and the
    // `Depth > 0`/`ParentIdx` machinery above is the vestige that makes that
    // fact checkable rather than assumed. The REGISTER-FREE depth-2 nest is a
    // SINGLE `PhaseKickbackNest` region dispatched a few lines above.
    //
    // bd test_C_libtooling-8h7d.5 — record the SURVIVING `Pred` of an in-loop
    // region BEFORE `emitRegion` runs (it ends in `flattenRegion`, which erases
    // `Arm`/`MergeBB` but never a `Pred`). This is the sole trigger for the
    // round-2 rail collapse (`collapseFlattenedLoopRails`); a module with no
    // in-loop region records nothing and is byte-identical. INCREMENTED, not
    // inserted — see the `PhaseKickback` site above (F-C1-2(2b)).
    if (R.InLoop)
      ++taint.InLoopFlattenedPreds[R.Pred];
    emitRegion(R, wd, csyms, taint);
  }
}

}  // namespace cq
