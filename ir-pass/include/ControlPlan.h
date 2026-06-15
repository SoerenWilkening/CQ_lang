// ControlPlan.h — Shared data shapes for controlled-region lowering.
//
// NOTE (swap-route-control branch): the old controlled-op lowering that produced
// and consumed a populated `ControlPlan` (ControlDetection / ControlledLowering /
// ControlFlag / ControlledSubstitution / MergeDissolution / CFGLinearization)
// was removed pending the RSSA swap-route emitter. The struct survives because
// `RotationLowering` reads `plan->InShadow` to skip in-shadow gate bodies; the
// WI-1 `detectControlRegions` (ControlDetect.cpp) recognizes the swap-route
// phase-arm shape but, having no emitter yet, declines every tainted region and
// returns an EMPTY plan (no regions, empty InShadow), so every rotation lowers
// uncontrolled. The rich `ControlRegion` fields below are retained as the design
// vocabulary the swap-route emitter will reshape — they are currently unpopulated.
//
// Historical shape (PRD §2.2/§2.6/§2.10/§2.11, IMPLEMENTATION §5.1).
//
// Detection is PURE ANALYSIS (no IR mutation) so it runs before
// `lowerRotations`: the region/shadow membership is by SSA *value* identity,
// which survives the rotation lowering's RAUW-to-handle (the gate-body
// `cq_phi` CallInst* is stable until it is itself erased). `Condition` /
// `Merge` are likewise stable instruction identities.

#ifndef CQ_IRPASS_CONTROL_PLAN_H_
#define CQ_IRPASS_CONTROL_PLAN_H_

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"

namespace llvm {
class BasicBlock;
class ConstantInt;
class Instruction;
class Module;
class PHINode;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// 4.2 (PRD Part II §8.3) — per-arm content class. A region is lowerable only
// when HOMOGENEOUS: all-phase (the 4.1 route + verbatim-Rz replay + icmp_inv
// flag-strip) or all-value (method-B: route + chain replay + copy-out +
// reverse-play) over ONE shared routed base. Any mixture — phase and value
// links in one chain, or a phase arm beside a value arm in an if/else —
// declines `mixed phase/value arm`: a chain carrying both a phase and a
// changed basis has no copy-safe, strip-valid lowering (the CNOT copy
// dephases the Rz answer, Rule 7; §6a control-in-place territory). `Phase` is
// the default so the 4.1 phase-arm paths need not write it.
enum class ArmClass { Phase, Value };

// WP18 (PRD §8.5) — one case arm of a gated `SwitchRegion`: the case constant(s)
// targeting it, its arm block, and the arm's in-shadow gate bodies (the `cq_phi`
// calls that become `_controlled` on the arm's flag). The DEFAULT arm is carried
// by the region's own `Arm`/`Shadow` (controlled on the ¬OR "none-matched" flag).
//
// `Values` holds ALL case constants that target `Block`: usually one, but a
// SHARED arm block — two+ case values folded onto one body by `clang` for
// duplicate-body cases (test_C_libtooling-6qg) — carries several. The arm is then
// controlled on the OR of its cases' `icmp eq` flags (`f_{v1} ∨ … ∨ f_{vm}`),
// which gates both the gate-body substitution and the angle difference.
struct SwitchArm {
  llvm::SmallVector<llvm::ConstantInt *, 2> Values;
  llvm::BasicBlock *Block = nullptr;
  llvm::SmallVector<llvm::Instruction *, 4> Shadow;
};

// One recovered controlled region, normalized from a tainted `select i1` or a
// tainted `br i1` diamond to a single internal shape (IMPLEMENTATION §5.1).
// WP3 builds only the `BranchRegion` (`br`-diamond) case; the `SelectRegion`
// fields/enum are present for WP4 but unused here.
struct ControlRegion {
  // The tainted i1 condition that gates the region: the `br`/`select`
  // condition. For a plain compare it is the `CmpInst` itself; for a
  // compound `&&`/`||` it is the flag-combination `SelectInst`
  // (`select i1 %fa, i1 %fb, i1 false` / `…, i1 true, i1 %fb`, PRD §2.5),
  // whose sub-compares live in `CondA`/`CondB`. Lowered as the control flag
  // by `ControlFlag`; the original instruction stays until linearization
  // erases it (§1.3, keeps the `br i1` well-typed mid-pass).
  llvm::Value *Condition = nullptr;

  // Compound-condition kind (WP5, PRD §2.5). `ConjNone` ⇒ `Condition` is a
  // plain compare (the WP3 path, unchanged). `ConjAnd`/`ConjOr` ⇒ `Condition`
  // is the flag-combination select and `CondA`/`CondB` are its two tainted
  // sub-compares; `ControlFlag` lowers each to its own flag, then
  // `FlagConjunction::combineFlags` ANDs/ORs them into the single
  // `region.Flag` (§1.2). The sub-compares (and the select) are erased with
  // the region's condition cleanup.
  enum ConjKind { ConjNone, ConjAnd, ConjOr } Conj = ConjNone;
  llvm::Value *CondA = nullptr;  // first sub-compare (`%fa`); a `CmpInst`.
  llvm::Value *CondB = nullptr;  // second sub-compare (`%fb`); a `CmpInst`.
  // The two forward sub-flags minted by `ControlFlag` from `CondA`/`CondB`
  // (the inputs to the `combineFlags` Toffoli). Stashed so the uncompute
  // reuses the SAME flag handles for `cqrt_toffoli_inv` (rather than
  // re-deriving them), then balances each with its own compare-uncompute.
  llvm::Value *FlagA = nullptr;
  llvm::Value *FlagB = nullptr;

  // The i32 control flag minted by `ControlFlag::lowerControlFlag`
  // (`CompareLowering::lowerCompareToFlag`, then `FlagConjunction` for a
  // compound/nested condition). Null until that step runs.
  llvm::Value *Flag = nullptr;

  // SelectRegion — a tainted-condition DATA select (the WP4/4.2 mux, integer
  // handle width). BranchRegion — a `br`-diamond (WP3/WP5/WP8). AngleSelectRegion
  // (WP10, Family B2) — a tainted-condition select over the classical rotation
  // ANGLE (`select i1 c, double a, double b`) feeding only rotation-angle
  // operands; lowered as controlled-rotation-by-difference (`Merge` is the
  // select, `Shadow` the consuming `cq_phi`/`cq_theta` calls).
  // SwitchRegion (WP18, PRD §8.5) — a gated multi-arm `switch` whose arms apply
  // distinct SIDE-EFFECTING gate sequences (not a value/angle select). `Pred`
  // is the switch block, `Condition` the tainted scrutinee, `MergeBB` the common
  // merge, `SwitchArms` the case arms (case value(s) + block + gate shadow), and
  // `Arm`/`Shadow` the DEFAULT arm. Lowered by `lowerGatedSwitch`: per-case
  // `icmp eq` flags, each arm controlled on the OR of its cases' flags, the
  // default on the ¬(f_1∨…∨f_n) flag, the N-way φ dissolved, switch linearized.
  enum Kind {
    SelectRegion,
    BranchRegion,
    AngleSelectRegion,
    SwitchRegion
  } Kind = BranchRegion;

  // The merge node: a `SelectInst` (select-sourced) or the merge-block
  // `PHINode` (br-sourced). `SwapRouteEmit` RAUWs/erases it (the excised
  // `MergeDissolution` is gone, 7cde677).
  llvm::Instruction *Merge = nullptr;

  // In-shadow gate-body ops, in program order. For a PHASE arm this is the
  // retained-but-unpopulated 4.1 vocabulary: `SwapRouteEmit` walks the arm
  // blocks directly and replays each `cq_phi` verbatim+uncontrolled on the
  // routed work rail (the excised `ControlledSubstitution`'s `_controlled`
  // lowering survives only as the §6a control-in-place reserve,
  // `ControlledSymbols`). For a VALUE arm (4.2, `ClassArm == Value`)
  // `ArmClassify` populates it with the arm's ordered chain links
  // (FORWARD/base-first order — the §4 emit order: the WI-4 emitter moves +
  // `rewriteBinary`s each link onto the rail, then reverse-plays the minted
  // calls via `emitInverseChain`). `Shadow` is `Arm`'s content and
  // `ShadowFalse` is `ArmFalse`'s — by FIELD identity, not edge truth: for an
  // orientation-B diamond `Arm` is the FALSE successor (`ArmNegated` carries
  // the polarity, Rule 9).
  llvm::SmallVector<llvm::Instruction *, 4> Shadow;

  // 4.2 (PRD Part II §8.3) — the per-arm classes for `Arm` / `ArmFalse`.
  // Meaningful only on a region that survived `classifyArms`; `Phase` is the
  // 4.1 default (phase paths never write these). A value-class arm's ordered
  // chain links live in `Shadow` / `ShadowFalse` above.
  ArmClass ClassArm = ArmClass::Phase;
  ArmClass ClassArmFalse = ArmClass::Phase;

  // br-sourced CFG anchors (null for a select region). `Pred` holds the
  // outer `br i1`; `Arm` is the innermost guarded block (the gate body);
  // `MergeBB` is the common merge.
  llvm::BasicBlock *Pred = nullptr;
  llvm::BasicBlock *Arm = nullptr;
  llvm::BasicBlock *MergeBB = nullptr;

  // WP8 (Family C) symmetric two-content-arm diamond: `if(q){A}else{B}` where
  // BOTH successors hold content and fall through to a common merge. `Arm` is
  // the TRUE arm (gates controlled on `flag`); `ArmFalse` is the FALSE arm
  // (gates controlled on `¬flag` via the §2.5 `cqrt_x` LIFO bracket), and
  // `ShadowFalse` its gate bodies. Null/empty for the one-content-arm diamond
  // (WP3) and select/nested shapes. When `ArmFalse` is set the merge `φ`
  // dissolves by the `Arm`-edge incoming (the merge's predecessors are the two
  // arms, not `Pred`), and linearization splices BOTH arms into `Pred`.
  llvm::BasicBlock *ArmFalse = nullptr;
  llvm::SmallVector<llvm::Instruction *, 4> ShadowFalse;

  // cwk fix (b) (test_C_libtooling-byx) — a wholly-classical scalar-FP merge `φ`
  // (a rotation ANGLE) dispatched under quantum control via the `br`-diamond /
  // gated-switch form: the CFG analog of `AngleSelectRegion`. Detection records
  // the angle `φ`(s) here and their consuming `cq_phi`/`cq_theta` rotations in
  // `AngleConsumers` (which also join `plan.InShadow` so `lowerRotations` skips
  // them — the orchestrator lowers them as base + controlled-difference via
  // `reduceAngleDiamondPhi`). A diamond may also carry an ordinary gate-handle
  // `φ` alongside (the realistic mixed `if(q){gate; ang=a;}` shape); that one is
  // dissolved by `dissolveBranchPhi` as usual, which SKIPS any `φ` listed here.
  // Empty for every region without an angle `φ`.
  llvm::SmallVector<llvm::PHINode *, 2> AnglePhi;
  llvm::SmallVector<llvm::Instruction *, 4> AngleConsumers;

  // WP18 (SwitchRegion) — the case arms. The default arm rides `Arm`/`Shadow`
  // (above). Empty for every non-switch region.
  llvm::SmallVector<SwitchArm, 4> SwitchArms;

  // WP18 follow-on (test_C_libtooling-509): the switch's DEFAULT edge goes
  // STRAIGHT to the merge (an empty `default:`), so there is NO distinct default
  // block — `clang -O1` routes `switch …, label %merge [ … ]`. When true, `Arm`
  // is null (no default gate body / nothing to splice) and the default angle
  // base rides the `Pred` (switch-block) φ edge instead of an `Arm` edge; the
  // default control is implicit (no case matched ⇒ no gate, the unconditional
  // base angle), so `lowerGatedSwitch` skips the ¬OR default substitution and
  // the OR-fold entirely. False for a distinct default block (gated or empty).
  bool SwitchDefaultDirect = false;

  // npu.5/.6 (MUX-EXCH): the merge carries exactly one DISTINCT-per-case-handle
  // mux φ (a coherent multiplexer dispatching case0→qx, case1→qy, …) that PASSED
  // the conservative G0–G7 safety gate in `tryBuildGatedSwitchRegion`. When set,
  // `lowerGatedSwitch` lowers that φ by a fresh `regOut = cqrt_alloc(0)` + a
  // per-distinct-base `cqrt_cswap(f_q, regOut, q)` controlled MOVE + a
  // `cqrt_ry_<W>_controlled_inv(¬f_q, q, angle)` uncompute of every non-selected
  // source (so regOut is not left entangled with the scrutinee), instead of the
  // step-4 first-tainted RAUW (which would silently drop every other-handle
  // edge). False ⇒ every handle φ is uniform-base (the RAUW path) — the gate
  // declined any distinct-base φ to the WP12 diagnostic, so a distinct-base φ
  // never reaches lowering with this false. The mux φ self-identifies at
  // lowering (≥2 distinct tainted incomings); this bit only certifies the gate
  // passed. See the archived
  // docs/archive/old-design/phases/phase04-controlled-form/npu6-mux-exch-gate-spec.md
  // + [[cwk-merge-phi-discriminator]].
  bool MuxExch = false;

  // The single gate arm is the FALSE successor of the `br i1 cond, S0, S1` (i.e.
  // `Arm == S1`), so it is taken when `cond` is FALSE and its gates fire on
  // ¬flag, not flag. `clang` produces this whenever it swaps the branch targets
  // — e.g. `if (u != 5)` canonicalizes to `icmp eq; br eq, Merge, Arm`. The
  // controlled substitution wraps such an arm in the self-inverse `cqrt_x` flag
  // bracket (the same ¬flag mechanism as the WP8 symmetric false arm). False for
  // the ordinary true-successor diamond and for select/symmetric regions (whose
  // polarity is carried explicitly by the arm assignment).
  bool ArmNegated = false;
  // Nested-AND intermediate guard block (WP5, PRD §2.7): for the un-flattened
  // `if (a) { if (b) gate; }` shape, `Pred -[a]-> {Mid, Merge}`,
  // `Mid -[b]-> {Arm, Merge}`, `Arm -> Merge`. `Mid` holds the inner compare
  // `CondB` + the inner `br i1`; it is spliced out at linearization with `Arm`.
  // Null for a flat (WP3) or compound-`&&`-select (single-block-condition)
  // region. When set, `Conj == ConjAnd`, `CondA` is the outer compare, `CondB`
  // the inner — so nesting reuses the conjunction flag machinery verbatim.
  llvm::BasicBlock *Mid = nullptr;

  // Nesting depth (0 = outermost) and the enclosing region, for the
  // single-flag AND model (PRD §2.7). For a nested region (`Depth > 0`),
  // `ParentIdx` is the index of the enclosing region in `ControlPlan::Regions`
  // (an index, not a pointer — the region list is a `SmallVector` that may
  // reallocate as detection pushes; `kNoParent` ⇒ outermost). `ParentFlag` is
  // resolved from the parent's `Flag` at lowering time (the outer→inner Depth
  // sort guarantees the parent's flag is already minted, IMPLEMENTATION
  // §"Nesting"). The inner region's own condition flag is then AND-combined
  // with `ParentFlag` into a single `f_both` (`FlagConjunction`), and every
  // inner controlled op uses that one flag (§1.2). WP3/WP4's flat fixtures
  // leave `ParentIdx == kNoParent` and `ParentFlag` null.
  static constexpr unsigned kNoParent = ~0u;
  unsigned Depth = 0;
  unsigned ParentIdx = kNoParent;
  llvm::Value *ParentFlag = nullptr;

  // 4.3 (IMPLEMENTATION-4.3 §1/§4) — the parent region's work rail (`rail1`),
  // onto which the parent routes its base before the child mints + routes. The
  // child's inner flag is minted FROM this rail (`lowerCompareToFlagRail`), not
  // from the now-stale-on-`q` SSA register the source compare read (§12.2). Null
  // for a flat region or the outermost nest level; populated at EMIT time by
  // `NestedRouteEmit` (WI-3) — WI-1 detection leaves it null (the parent/child
  // link is the existing `ParentIdx`, the same link the pre-flight exemption
  // and the emit-loop child lookup key on; no `ChildIdx` field — MD4).
  llvm::Value *ParentRail = nullptr;

  // ziov WI-1 (owner 2026-06-15) — the tainted condition compare `q>5` is read in
  // BOTH a control (the `br`) AND a data position (`int f = (q>5)`; clang -O1 CSEs
  // them to one `icmp` with two uses). The compare IS the control flag, so the
  // route and the data use must share ONE physical flag: `SwapRouteEmit::emitRegion`
  // mints it once, routes with it, feeds the SAME handle to the data use, and
  // SKIPS the eager strip+free (the data lineage owns the handle — it escapes or
  // is measured, FreePoint → Escaped/Measured, no free). `classifyArms` sets this
  // ONLY when the condition has a non-branch user whose forward lineage is wholly
  // escaped/measured; a dead-within-function lineage declines PERMANENTLY (ziov.2
  // proposed a deferred in-function strip there but it was closed won't-fix — a
  // flag-only strip leaves the data-copy rails entangled with q, a silent
  // miscompile). False for the common no-data-use region (the unchanged eager
  // strip+free path). The VALUE-arm twin is not yet implemented —
  // `emitValueRegion` declines a `ShareCondFlag` region (WI-later).
  bool ShareCondFlag = false;
};

// The full detection result: the recovered regions plus the set of in-shadow
// `cq_phi` calls (so `lowerRotations` skips them — the orchestrator lowers
// them controlled). `InShadow` is keyed on the gate-body `Instruction*`.
struct ControlPlan {
  llvm::SmallVector<ControlRegion, 4> Regions;
  llvm::SmallPtrSet<const llvm::Instruction *, 8> InShadow;
};

// Shared loud-decline primitive (swap-route 4.1 IMPLEMENTATION §2). Emits a
// `DiagnosticInfoUnsupported(DS_Error)` of the form
// `"cq controlled lowering: " + What + " under quantum control"`, anchored on
// `Where`'s `!dbg` so the rejection is source-located and `opt` exits non-zero.
// Defined once in `ControlDetect.cpp`; shared by `ControlDetect`/`ArmClassify`
// so every control decline (shape, §3c clobber, value-arm, nested, select,
// switch) speaks one diagnostic dialect. Over-declining is always safe; a
// silent pass-through of quantum control is the only unforgivable bug.
void diagnoseUnderControl(llvm::Instruction *Where, llvm::StringRef What);

// Pure-analysis detection (swap-route 4.1 IMPLEMENTATION §0/§3). For each
// tainted-condition `br i1`, recognize the §0 clean diamond / if-else shape by
// SSA-value identity (Rule 9 — before any mutation), classify each arm
// (phase / value / §3c clobber) via `ArmClassify`, and decline everything that
// is not a pure-phase-over-tainted-handle region. An accepted phase-arm DIAMOND
// (one content arm, WI-2) or IF/ELSE (two arms, WI-3) is pushed onto
// `plan.Regions` for `SwapRouteEmit::lowerControlRegions`. `plan.InShadow`
// stays empty — the emitter erases each arm `cq_phi` before `lowerRotations`
// runs, so there is no in-place gate body to skip (IMPLEMENTATION §3). A
// classical-condition branch is ignored (detection keys strictly on condition
// taint). No IR is mutated here.
ControlPlan detectControlRegions(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CONTROL_PLAN_H_
