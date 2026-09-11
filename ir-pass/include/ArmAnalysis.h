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

#include "llvm/ADT/ArrayRef.h"
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
class Module;
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

// bd 3qlq.4 / bd test_C_libtooling-r9e5 (1b-B.1) — has the RAIL-LEAF condition
// `Rail` (a `cq_theta_i1` result, `isCondRailLeaf`) been MEASURED before
// `ReadPoint`? A measured register is classical from there on, so a gate
// controlled on it after the measurement is a post-measure gate (Rule 6's
// loud-reject class) — the rail mirror of `condDataUseDisposition`'s
// `MeasuredEarly`. True (refuse) when a `cq_measure` user of the rail precedes
// `ReadPoint` in its own block, or when `ReadPoint` is potentially REACHABLE
// from that measurement (a dominating block, or a classically-guarded side
// path — round-1 finding F-1b-2). `DT` may be null (only more conservative).
//
// ONE spelling, THREE callers (Rule 14): `classifyPhaseKickback` step 5b and
// `classifyPhaseKickbackNest`, both passing `Pred->getTerminator()` (the gate is
// emitted AT the branch, so every non-terminator of `Pred` precedes it), and —
// since 1b-B.1 — `classifySelectRegion`'s rail rung 2, passing the SELECT
// itself, because the 4.4 copy-merge stream is emitted mid-block immediately
// before it and a same-block measurement AFTER the select is the ordinary
// downstream case. De-anonymized from `ArmClassify.cpp`; the definition still
// lives there, only its linkage and its read-point parameter changed.
//
// bd test_C_libtooling-r10v / -9pum / -r903(b) (Track A.1) — THE SEED IS A WIRE,
// NOT A `cq_theta_i1`. A COMPARE-conditioned control read (`if (q > 3) …`,
// `(b == 1) ? x : y`) asks the IDENTICAL question of the register the compare
// reads, and the register is named by an arbitrary tainted value: a `cq_theta`
// result, a template result (`%t = add %q, 3`), a cast, a phi. The parameter is
// therefore `const Value *` and the body was ALREADY total over that domain
// (`railWireNamesBackward` breaks at the first non-`cq_theta_` name, yielding
// the singleton closure `{Seed}` — which is the right closure for a template
// result, whose own operands are OTHER rails). ONE spelling for both seed
// species (Rule 14); the caller supplies the species by supplying the seed.
bool railMeasuredBeforeReadPoint(const llvm::Value *Rail,
                                 const llvm::Instruction *ReadPoint,
                                 const TaintSet &Taint,
                                 const llvm::DominatorTree *DT);

// bd test_C_libtooling-r9e5, Rule-13 round-1 item F-B1R1-1 — every SSA NAME of
// the physical register `Rail` sits on, walking BACKWARD over the relation
// `lowerRotations` lowers in place by (a chained `cq_theta`'s TAINTED arg-0 is
// the same rail): `Rail` itself, each chained ancestor theta, and the first
// non-theta tainted parent (collected, not entered — its operands are other
// rails). `railMeasuredBeforeReadPoint` asks its measure question over this
// closure so that rung (ii) and rung (iii) of the rail ladder are computed over
// the SAME wire (the 8h7d.5 F-1/F-3 lesson).
// (Track A.1) `Rail` is any tainted value NAMING a register — see
// `railMeasuredBeforeReadPoint` above for why the seed species is the caller's.
void railWireNamesBackward(const llvm::Value *Rail, const TaintSet &Taint,
                           llvm::SmallVectorImpl<const llvm::Value *> &Out);

// bd test_C_libtooling-r9e5 (1b-B.1), Rule-13 ROUND-2 finding F-B1R2-1 — RECORD
// one emitted RAIL CONTROL READ: `Rail` is the user's `cq_theta_i1` result read
// as a control and `FirstRead` the FIRST `cqrt_*` call this region fires on it
// (the 4.4 select's copy-flag `cqrt_cnot`, a rail leaf's first node gate, a
// kickback's first `cqrt_rz_i1`). Called at the EMISSION SITE, so a fifth
// emitter that reads a rail and forgets this call silently re-opens F-B1R2-1
// with no diagnostic anywhere — the same "record at every emission site"
// obligation `ChainWalk::markBranchPhaseGate` carries for F-L7-1. Idempotent for
// an identical `(Rail, FirstRead)` pair; a rail read at two different points
// records both (`reverifyRailCondReads` diagnoses once per rail). Null arguments
// are ignored.
//
// bd test_C_libtooling-r10v / -9pum / -r903(b) (Track A.1) — THE RECORD NOW ALSO
// CARRIES COMPARE SEEDS, and the write half moved INSIDE the one mint. A
// COMPARE-conditioned control read has exactly the same round-2 taint window
// (bd `9pum`: `y` is a 6.5 `%out` derivative, classical at round 1, so the two
// `cq_theta(y, ·)` siblings are two rails to the fence and ONE rail to
// `lowerRotations`). Rather than ask ten emitters to remember a call —
// "every emission site, or none", the `markBranchPhaseGate` / `markRailCondRead`
// lesson twice over — the compare record is written by `lowerCompareToFlag`
// ITSELF (`CompareLowering.cpp`), which is the ONE function that mints a compare
// flag: `Rail` is each member of the compare's `condProvenance` cone (the set
// gate 2c walks) and `FirstRead` is the minted `cq_template_(i|f)cmp_*` call,
// which IS the instruction that reads the register. A new control emitter is
// therefore recorded by construction, and the ONE caller that opts OUT (the
// straight-line data path `rewriteCompare`, which is not a control read and runs
// AFTER this stage anyway) says so at its call site.
void markRailCondRead(TaintSet &Taint, llvm::Value *Rail,
                      llvm::Instruction *FirstRead);

// bd test_C_libtooling-r10v / -r903(b) (Track A.1) — RUNG (ii) FOR THE COMPARE
// LEAVES of a tainted condition, asked at CLASSIFICATION time (detect before
// mutate) by the two consumers the increment scopes: `classifySelectRegion`
// (read point = the `SelectInst`, because `SelectMergeEmit` emits mid-block
// immediately before it) and `classifyPhaseKickback` (read point =
// `Pred->getTerminator()`, because the kickback's stream lands AT the branch).
// Returns the offending leaf, or null. The question is asked over each leaf's
// `condProvenance` cone — the SAME seed set gate 2c walks for rung (iii), so the
// two rungs of the ladder are computed over one closure (the bd 8h7d.5 F-1/F-3
// lesson: when you widen a set, ask what OTHER set was computed over the same
// closure). Every other consumer of a compare condition is covered at FINAL
// taint by `reverifyRailCondReads` over the `lowerCompareToFlag` record.
// (Track A.1) RECORD one emitted COMPARE control read: `Seeds` is the compare's
// `condProvenance` cone and `Read` the minted `cq_template_(i|f)cmp_*` call.
// Called from `lowerCompareToFlag` itself — the ONE compare-flag mint — so the
// record is complete by construction rather than by every emitter remembering.
// Ignores null/empty arguments; idempotent for an identical `Read`.
// `OperandSeeds` is the compare's DIRECT tainted operands (rung (ii)'s set) and
// `Seeds` its `condProvenance` cone (rung (iii)'s) — see `TaintPropagation.h`
// for why the two rungs must not share one set (F-A1-3).
// `WireRuled` (round-2 finding F-A1R2-1) says whether the emitter's classifier
// actually TOOK a round-1 wire disposition over this compare — it is the gate on
// rung (iii)'s taint-blind exemption, and it is supplied by the mint site rather
// than inferred here. See `TaintPropagation.h` for the two consumers whose
// exemption it closes.
void markCmpCondRead(TaintSet &Taint, llvm::ArrayRef<llvm::Value *> Seeds,
                     llvm::ArrayRef<llvm::Value *> OperandSeeds,
                     llvm::Instruction *Read, bool WireRuled);

// (Track A.1) THE COMPARE HALF OF THE RE-VERIFICATION STAGE — the twin of
// `reverifyRailCondReads` above, same slot, same two rungs, same two strings,
// same "loud and final, never a silent fallback" contract. Runs over
// `TaintSet::CmpCondReads`, asking rung (iii) over the whole recorded cone at
// once (see `TaintPropagation.h` for why the cone must not be split). Returns
// true iff it declined.
bool reverifyCmpCondReads(llvm::Module &M, TaintSet &Taint);

llvm::CmpInst *condCmpMeasuredBeforeReadPoint(
    llvm::ArrayRef<llvm::CmpInst *> Leaves, const llvm::Instruction *ReadPoint,
    TaintSet &Taint, const llvm::DominatorTree *DT);

// (Track A.1, Rule-13 round-1 finding F-A1-3) The compare's DIRECT tainted
// operands — the registers the control actually READS, which is rung (ii)'s
// seed set at both the classifier and the backstop. NOT `condProvenance` (every
// tainted ANCESTOR; that is rung (iii)'s set and R4's completeness carrier, and
// using it here refused circuits whose flag reads a separate rail). One
// spelling, two askers. See the definition in `ArmClassify.cpp`.
void condCmpOperandSeeds(const llvm::CmpInst *Cmp, TaintSet &Taint,
                         llvm::SmallVectorImpl<llvm::Value *> &Out);

// bd test_C_libtooling-r9e5 (1b-B.1), Rule-13 ROUND-2 finding F-B1R2-1 — THE
// RE-VERIFICATION STAGE. Re-asks rungs (ii) and (iii) of the §14.3 rail ladder,
// at each recorded read point, with FINAL taint; declines LOUDLY on failure
// (`condition measured before the control route` / `condition predates a
// non-diagonal gate`, anchored on the read point, which carries the region's
// `!dbg`) and lowers nothing further for that rail. Returns true iff it
// declined. MUST run after the round-2 fixpoint (`repropagateControlMerges`) and
// before `lowerRotations` — see the definition's header for the placement
// argument and for why re-asking AFTER emission is sound.
bool reverifyRailCondReads(llvm::Module &M, TaintSet &Taint);

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

// `ClaimedSelects` (bd test_C_libtooling-3qlq Inc 1 part B, P3) collects the
// LOGICAL `select i1` nodes of an ACCEPTED compound condition tree. Those
// selects are part of THIS region's condition — not data muxes — so the caller's
// tainted-`select` scan must skip them, exactly as `Claimed` makes it skip an
// accepted nest's inner `br`. WITHOUT IT the same `select i1 %a, i1 %b, i1 false`
// is handed to `classifySelectRegion` as an i1 DATA select, accepted, and
// `emitSelectRegion` then dereferences a select this emitter has already erased
// — a SIGSEGV on the flagship `if (q==5 && r==3) cq_phi(θ)` customer, MEASURED
// before the set existed. May be null (a caller with no select scan).
PhaseKickbackDisp classifyPhaseKickback(
    llvm::BranchInst *BI, TaintSet &Taint, ControlRegion &Region,
    const llvm::DominatorTree *DT, const llvm::LoopInfo *LI,
    llvm::SmallPtrSetImpl<llvm::Instruction *> *ClaimedSelects = nullptr);

// bd test_C_libtooling-3qlq Inc 1 part B — P4, the GENUINE depth-2 register-free
// PHASE NEST (the one `clang -O1` did NOT fold to a compound branch; the folded
// one is P3). On ACCEPT `Region` is a single `PhaseKickbackNest`, the inner `br`
// is added to `ClaimedBranches` (the FA0 blocker — the inner branch recovers FLAT
// in isolation and would false-decline) and both trees' logical `select i1` nodes
// to `ClaimedSelects`. Declines fire the precise per-shape string; NotApplicable
// falls through to the caller's ordinary shape recovery. See the definition's
// header for the unitary and for why this is ONE region and not the 4.3 pair.
PhaseKickbackDisp classifyPhaseKickbackNest(
    llvm::BranchInst *BI, TaintSet &Taint, ControlRegion &Region,
    const llvm::DominatorTree *DT, const llvm::LoopInfo *LI,
    llvm::SmallPtrSetImpl<llvm::BranchInst *> *ClaimedBranches,
    llvm::SmallPtrSetImpl<llvm::Instruction *> *ClaimedSelects);

AngleSelectDisp classifyAngleSelect(llvm::SelectInst *Sel, const CondTree &Tree,
                                    TaintSet &Taint, WidthDispatch &wd,
                                    llvm::DominatorTree *DT, llvm::LoopInfo *LI,
                                    ControlPlan &plan);

}  // namespace cq

#endif  // CQ_IRPASS_ARM_ANALYSIS_H_
