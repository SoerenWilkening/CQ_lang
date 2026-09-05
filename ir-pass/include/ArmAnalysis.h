// ArmAnalysis.h — Shared per-arm lineage analyses for swap-route control.
//
// Declares the by-SSA-identity walks `ArmClassify.cpp` uses to classify an arm's
// contribution to the merge `φ` (phase spine / value chain / tainted-angle gate)
// plus the condition-provenance and diagonal-alias closure helpers. De-anonymized
// from `ArmClassify.cpp`'s anonymous namespace (WI-0/MD1) so the 4.3
// `RegionTreeDetect` (criteria-4/5 RAUW-collapse + mint-from-rail) and
// `ArmHomogeneity` (the §12.5 PASS-1 per-arm class split) TUs can reuse them
// rather than re-implement the lineage logic. PURE REFACTOR: the definitions
// still live in `ArmClassify.cpp`, only their linkage changed (anonymous → named
// `cq`); the tiny `isPhiCall`/`isThetaCall`/`isCallToPrefix` predicates stay
// TU-local (they collide with the same-named anon helpers in `SwapRouteEmit.cpp`/
// `WireWalk.cpp` if promoted).
//
// All analysis is pure SSA reading — NO IR is mutated (Rule 9). The per-use arg-1
// angle exclusion (the f64/angle miscompile family, Rule 3) is replicated inside
// `condProvenance`/`taintedAngleGate` verbatim from `TaintPropagation.cpp`. See
// swap-route 4.1/4.2 IMPLEMENTATION §3 and 4.3 IMPLEMENTATION-4.3 §3.

#ifndef CQ_IRPASS_ARM_ANALYSIS_H_
#define CQ_IRPASS_ARM_ANALYSIS_H_

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class BasicBlock;
class BranchInst;
class PHINode;
class CallInst;
class CmpInst;
class DominatorTree;
class Instruction;
class LoopInfo;
class SelectInst;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct ControlRegion;
struct CondTree;
struct ControlPlan;
struct TaintSet;

// Walk the PHASE spine WITHIN one arm block: while `V` is a `cq_phi` (Rz) call
// DEFINED IN `ArmBB`, follow its arg-0 handle operand (arg 1 is the classical
// angle). Returns the first value the chain bottoms at — the arm's base handle, a
// value-changing op, OR a `cq_phi` defined OUTSIDE `ArmBB` (a pre-region rotation,
// i.e. the live DERIVED base handle the arm extends). The arm-block bound is
// LOAD-BEARING (an unbounded walk hops past a shared pre-region `cq_phi` to the
// theta source → double-collect/UAF; see the .cpp).
llvm::Value *walkPhaseSpine(llvm::Value *V, const llvm::BasicBlock *ArmBB);

// PURE PHASE ARM body check (Rule 8 linearity + no stray ops): every
// non-terminator instruction in `ArmBB` must lie on the `cq_phi` (Rz) spine of
// `ArmIncoming` — no fan-out sibling, no stray `cq_measure`/`cq_theta`/arithmetic
// the swap-route emitter would silently drop or leave dangling in
// `taint.PhiCalls`. De-anonymized from `ArmClassify.cpp` (WI-5) so `EqFoldArm`'s
// D6 reuses the one predicate (Rule 14) rather than re-deriving it; the body
// still lives in `ArmClassify.cpp`, only its linkage changed (anonymous → named
// `cq`).
bool armBlockIsPureSpine(const llvm::BasicBlock *ArmBB,
                         const llvm::Value *ArmIncoming);

// Backward taint provenance of the branch condition: every tainted value
// reachable by walking operand edges back from `Cond`, stopping at `cq_theta`
// sources. Replicates the per-use arg-1 angle exclusion verbatim — the angle
// operand of a `cq_phi` is classical and must never be collected as a condition
// operand (the f64/angle miscompile family). Only tainted values are recorded.
void condProvenance(llvm::Value *Cond, TaintSet &Taint,
                    llvm::SmallPtrSetImpl<llvm::Value *> &Out);

// The routed base's first DIAGONAL-ALIAS hit in `Prov`, or null. Walks the
// pre-region `cq_phi` arg-0 chain from `Routed`: rotation lowering RAUWs a
// `%qd = cq_phi(%q, ·)` and its `%q` to the SAME i32 handle, so SSA-value
// disjointness from the condition's provenance is NOT wire disjointness. Pure
// reading walk — no collection, so the arm-block bounding discipline (which
// guards COLLECTION) does not apply.
llvm::Value *diagonalAliasHit(llvm::Value *Routed,
                              const llvm::SmallPtrSetImpl<llvm::Value *> &Prov);

// One arm's candidate VALUE chain — the value twin of `walkPhaseSpine`.
struct ValueChain {
  // The chain links in FORWARD (program/base-first) order — the §4 emit order
  // the value emitter replays them in. Collected merge-first, reversed at end.
  llvm::SmallVector<llvm::Instruction *, 6> Ops;
  // The value the walk bottomed at (never itself a link). For a routable arm
  // this must be EXACTLY the routed slot (base-identity — the Defect-2 fix).
  llvm::Value *Base = nullptr;
  // The walk reached an IN-ARM `cq_phi` link: a phase gate inside a value
  // lineage (`if(q>5){rz(p,a); p=p+3}`) → `mixed phase/value arm`. The
  // offending call is stashed for the diagnostic anchor.
  llvm::Instruction *MixedPhi = nullptr;
  // Some link consumed a SECOND tainted operand (a Q+Q link, `p = p + r`) — a
  // recognized value shape not yet routed (defer, PRD §8.3).
  bool HasQQ = false;
};

// Walk the VALUE chain WITHIN one arm block: while `V` is a supported tainted
// integer/fp `BinaryOperator` DEFINED IN `ArmBB`, follow its threaded operand
// (the sole tainted one). Returns the chain and the value it bottoms at.
// ARM-BLOCK-BOUNDED for the same load-bearing reason as `walkPhaseSpine`.
ValueChain walkValueChain(llvm::Value *ArmIncoming, const llvm::BasicBlock *ArmBB,
                          TaintSet &Taint, llvm::Value *RoutedHint);

// The first rotation whose arg-1 ANGLE operand is TAINTED — quantum-derived data
// in the angle slot — among the arm's IN-BLOCK spine gates and (for a derived
// base) the pre-region base `cq_phi` itself. Null if every angle is classical.
// A tainted angle has no fixed unitary (the emitter would replay it as a runtime
// handle tag) — the only sound disposition is a loud decline (Rule 3).
llvm::CallInst *taintedAngleGate(llvm::Value *ArmIncoming,
                                 const llvm::BasicBlock *ArmBB, llvm::Value *Base,
                                 TaintSet &Taint);

// ziov WI-1 / ziov.3: disposition of a tainted CONTROL compare's NON-branch
// (data) uses — the Q/C-boundary question raised when `q>5` is read in BOTH a
// `br` (control) AND a data position (`int f=(q>5)`; clang -O1 CSEs the two to one
// `icmp` with two uses). `ShareOk` = the data lineage is owned downstream (escapes
// via `ret` or is measured AFTER the route) so a phase region can mint ONE flag
// and skip its strip+free; `MeasuredEarly` = the lineage is measured IN
// `RouteBlock`, collapsing the flag BEFORE the route controls on it; `Unowned` =
// the lineage is dead-within-function or reaches an unrecognized hole (a dirty
// entangled rail, no owner). `RouteBlock` is the region's route block (`Region.
// Pred`). The FLAT phase path (`classifyArms`) SHARES on `ShareOk` and declines
// the other two; the NESTED path (`recoverRegionTree`) declines ALL THREE — nested
// flag-SHARING is a later WI (the `ShareOk` arm flips to accept then). Pure forward
// SSA walk, before any mutation (Rule 9). De-anonymized from `ArmClassify.cpp` so
// `RegionTreeDetect` reuses the one predicate (Rule 14); the definition still lives
// in `ArmClassify.cpp`.
// `Unlowerable` = a data op on the condition lineage (a cast to an unsupported
// width / out-of-scope pair, e.g. `sext i1→i128`) has NO template, so accepting
// the region would route+flatten it and only THEN hit `lowerOps`'s loud "no
// template" decline — a mutate-then-decline (Rule 9 violation, ziov.4). Declining
// it in detection keeps detect-before-mutate. The FLAT path declines it; the
// NESTED path declines it too (it declines every cond-data-use disposition).
enum class CondDataDisp { ShareOk, MeasuredEarly, Unowned, Unlowerable };

CondDataDisp condDataUseDisposition(llvm::Instruction *Cond,
                                    const llvm::BasicBlock *RouteBlock,
                                    const TaintSet &Taint);

// Whether a control/data `CmpInst`'s predicate has a lowering template — the
// predicate axis of `compareInScope`, with the icmp/fcmp family derived from the
// instruction. An out-of-scope fcmp predicate (outside {oeq,une,olt,ogt,ole,oge})
// has NO template (test_C_libtooling-jvun); a control region whose CONDITION uses
// one must decline in DETECTION, before emit mints a flag from it. The flat flag
// mint is emit step 1, but a NESTED inner mint follows the outer route/replay, so
// without this pre-mutation gate an out-of-scope inner condition is a
// mutate-then-decline (Rule 9). Shared by `condDataUseDisposition` (data lineage),
// `classifyArms` (flat control condition), and `recoverRegionTree` (nested
// outer+inner conditions).
bool comparePredLowerable(const llvm::CmpInst *Cmp);

// ---- ANGLE-SELECT BY DIFFERENCE (control-in-place-PRD §12.3, bd
//      test_C_libtooling-drbq Inc 2b) -----------------------------------------
//
// The disposition of one tainted-condition `select` that reaches a rotation's
// arg-1 ANGLE slot. THREE states, because two of them belong to different
// owners:
//   * `Accepted`      — a `ControlRegion{Kind = AngleSelectRegion, Merge = Sel,
//                       Condition = the compare, Shadow = {the consumer}}` was
//                       pushed for `AngleSelectEmit`; the caller returns.
//   * `Declined`      — THIS classifier already fired its own precise loud
//                       diagnostic (the loop / condition-wire / stale-record
//                       strings, which `rotation angle` would MISLABEL); the
//                       caller returns without adding a second one.
//   * `NotApplicable` — nothing was emitted and nothing was pushed: the shape is
//                       outside the 2b accept class, and the caller falls
//                       through to its pre-existing `rotation angle` decline,
//                       byte-identical to what it fired before this increment.
//
// Hosted in `ArmClassify.cpp` rather than `SelectClassify.cpp` because its R4/R6
// halves ARE `classifyArms`' — `railWireClosure` / `forwardRailHop` /
// `cannotFollowGate` are TU-local there and must stay ONE spelling (Rule 14).
// Pure analysis: no IR is mutated (Rule 9).
enum class AngleSelectDisp { Accepted, Declined, NotApplicable };

// Are the two ANGLE ARMS of a 2b select realizable by the by-difference stream?
// FOUR refusals in one predicate, all added by the Inc-2b round-1 Rule-13 review
// (lenses L5-1 / L7-F1 / L7-F2 / L7-F6), which found that S1–S10 asked about the
// arms' TYPE and TAINT and never about their VALUES:
//   * either arm carries `undef`/`poison` (asked through the SHARED
//     `valueCarriesUndef`, so a `ConstantExpr` carrying one is caught);
//   * either arm is a non-finite `ConstantFP`;
//   * both arms are `ConstantFP` and their DIFFERENCE is non-finite (two finite
//     arms CAN overflow: `DBL_MAX − (−DBL_MAX)`);
//   * both are `ConstantFP` and the by-difference ROUNDING residual
//     `delta = A − (B + fl(A−B))`, computed EXACTLY by TwoSum in APFloat,
//     exceeds the placeholder bound `kAngleSelectMaxRoundingRad = 2^-40 rad`.
// A RUN-TIME arm (a parameter, a load, a call result, an `fpext`, a run-time
// `fsub`) is REFUSED — clause (2c), the Rule-13 CLEARANCE narrowing (finding
// F-11, owner option (2): the accept class is CONSTANT arms only). There is no
// compile-time difference to evaluate, so the two clauses above cannot run at
// all, and the `fsub` the emitter would synthesize carries an error UNBOUNDED in
// absolute radians (measured 0.858 rad from plain C) and can be `inf`/`NaN` from
// two FINITE arms. Widening back is owner option (1), one line at (2c).
//
// TWO CALLERS, ONE SPELLING (Rule 14): `classifyAngleSelect`'s S1 (returning
// `NotApplicable`, so the caller's pre-existing `rotation angle` decline fires
// unchanged — no new string) and `emitAngleSelectRegion`'s step-0 re-ask (a
// plan/IR-mismatch `control flow` decline, so no path can reach emission with a
// bad arm). Pure analysis; the derivation is at the definition in
// `ArmClassify.cpp`.
bool angleSelectArmsAdmissible(const llvm::Value *A, const llvm::Value *B);

// bd test_C_libtooling-3qlq Inc 1 (PRD `retire-swap-route-PRD.md` §6.2 row P1) —
// the FLAT KICKBACK DIAMOND classifier. Same three-way disposition contract as
// `classifyAbortPark` / `classifyGuardedStoreArm` / `classifyClassicalCallArm`,
// and for the same reason: it is a PRE-PEEL in `handleBranchRegion`, tried
// BEFORE `recoverRegion`, because a void arm produces no merge φ and every one
// of `recoverRegion`'s recognizers requires a non-null `soleMergePhi`.
//
//   Accept        — `Region` is populated as a `PhaseKickback` region (Merge
//                   NULL, MergeBB set) and the caller pushes it onto the plan.
//   Declined      — a precise diagnostic has ALREADY been fired; the caller
//                   returns and lowers nothing.
//   NotApplicable — `Region` may have been written and MUST be treated as
//                   scratch by the caller (`handleBranchRegion` reuses one
//                   `ControlRegion` across its pre-peels, exactly as it does for
//                   the two existing ones); the shape is someone else's.
//
// Pure analysis (Rule 9): recognition is by SSA-value identity and nothing is
// mutated.
enum class PhaseKickbackDisp { Accept, Declined, NotApplicable };

// The MERGE-TAIL ANGLE PHI of a kickback region, or false (bd
// test_C_libtooling-3qlq Inc 1, orchestrator refinement (1), 2026-09-05).
//
// `clang -O1` does NOT always fold `if (c) cq_phi(A); else cq_phi(B);` into one
// call on a `select` over the angle. When the two arms differ by more than the
// angle — the MEASURED customer is `tests/e2e/slice_control_phase_ifelse_
// derived.c`, whose true arm carries TWO phases and its false arm one — it
// leaves a DIAMOND plus, in the merge block:
//
//     %a = phi double [ 1.250000e-01, %arm ], [ 7.500000e-01, %pred ]
//     call void @cq_phi(double %a)
//
// i.e. the LAST phase of each arm sunk into the merge with its angle muxed. That
// is the same P2 lowering as the `select` spelling — one `cqrt_rz_i1` per
// incoming, on the region's own flag, bracketed by that incoming's polarity —
// and it needs no arithmetic, so a run-time incoming would be admissible too
// (they are `ConstantFP` in every measured case).
//
// ⚠ THIS PREDICATE IS ALSO A CORRECTNESS FENCE FOR THE PLAIN P1 ACCEPT, not only
// the entry to a widening. `flattenRegion` splices the arm and merge blocks into
// `Pred` and erases them; a PHINode left standing in that merge becomes a phi
// with the wrong predecessor count in a block that no longer branches — MEASURED
// as `PHI nodes not grouped at top of basic block!` — a BROKEN MODULE, on
// exactly the customer above.
//
// ⚠ AND SAY WHAT `opt` DOES WITH IT, because the first spelling of this sentence
// said "at `opt` exit 0" and that is MEASURED FALSE (Rule-13 round-1 finding
// F-L3-5, re-measured here). `cq-opt` builds the pipeline
// `CQLoweringPass -> VerifierPass -> print` (`ir-pass/tools/cq_opt_main.cpp`),
// and `VerifierPass`'s default `FatalErrors=true` makes a failure a
// `report_fatal_error`: the process ABORTS with
// `LLVM ERROR: Broken module found, compilation aborted!`, **exit 134
// (SIGABRT)**, and NO module is written (measured:
// `opt -disable-verify -passes=verify` on a dominance-violating module,
// rc=134). Stock `opt` is the same. So a broken module is loud, not silent, and
// nothing in this tree relies on the false claim.
//
// The claim mattered enough to correct rather than delete: a false "exit 0 on a
// verifier failure" in the Rule-13 core would tell the next reader that every
// fixture relying on verify-clean-implies-exit-0 is weaker than documented,
// which is not true and would license the wrong kind of caution. What IS true and
// worth carrying: `cq-opt` exits at the FIRST `DS_Error`
// (`LLVMContext::diagnose`'s default handler `exit(1)`) and never writes `-o`, so
// two independent declines in one module print ONE line — which is why a decline
// can never be masked by a later stage's abort.
//
// The FENCE itself is unaffected and stays exactly as it was: the classifier must
// decide about EVERY phi in the merge -- this one it claims and the emitter
// erases, and any other one makes the whole region `NotApplicable`.
//
// ONE SPELLING, asked by BOTH the classifier (to accept) and the emitter (to
// re-validate before mutating) — never two (Rule 14). On true, `Phi` and
// `Consumer` are set; on false they are untouched.
bool phaseAngleTail(llvm::BasicBlock *MergeBB, const TaintSet &Taint,
                    llvm::PHINode *&Phi, llvm::CallInst *&Consumer);

PhaseKickbackDisp classifyPhaseKickback(llvm::BranchInst *BI, TaintSet &Taint,
                                        ControlRegion &Region,
                                        const llvm::DominatorTree *DT,
                                        const llvm::LoopInfo *LI);

AngleSelectDisp classifyAngleSelect(llvm::SelectInst *Sel, const CondTree &Tree,
                                    TaintSet &Taint, WidthDispatch &wd,
                                    llvm::DominatorTree *DT, llvm::LoopInfo *LI,
                                    ControlPlan &plan);

}  // namespace cq

#endif  // CQ_IRPASS_ARM_ANALYSIS_H_
