// ControlPlan.h — Shared data shapes for Phase-4 controlled-region lowering
// (PRD §2.2/§2.6/§2.10/§2.11, IMPLEMENTATION §5.1). `ControlDetection`
// produces a `ControlPlan`; `ControlledLowering` and its helpers
// (`ControlFlag`, `ControlledSubstitution`, `MergeDissolution`,
// `CFGLinearization`) consume it, and `RotationLowering` reads its
// `InShadow` set to skip the gate-body `cq_phi` calls it must NOT lower
// uncontrolled.
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
  // `PHINode` (br-sourced). `MergeDissolution` rewrites/erases it.
  llvm::Instruction *Merge = nullptr;

  // In-shadow gate-body ops (the `then`-arm `cq_phi` calls), in program
  // order. `ControlledSubstitution` lowers each to its `_controlled` variant.
  // For a symmetric two-content-arm diamond (WP8) this holds the TRUE arm's
  // gates (controlled on `flag`); `ShadowFalse` holds the FALSE arm's.
  llvm::SmallVector<llvm::Instruction *, 4> Shadow;

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
};

// The full detection result: the recovered regions plus the set of in-shadow
// `cq_phi` calls (so `lowerRotations` skips them — the orchestrator lowers
// them controlled). `InShadow` is keyed on the gate-body `Instruction*`.
struct ControlPlan {
  llvm::SmallVector<ControlRegion, 4> Regions;
  llvm::SmallPtrSet<const llvm::Instruction *, 8> InShadow;
};

// Pure-analysis detection (IMPLEMENTATION §5.1, PRD §2.2): for each
// tainted-condition `br i1`, recognize the 2-block diamond + merge `φ`, build
// a `BranchRegion`, and record the arm's `cq_phi` in `plan.InShadow`. A
// classical-condition branch is ignored (§1.3). An arm that escapes
// (`ret`/`@cq_measure_*`/out-of-region `br`) → loud `DiagnosticInfoUnsupported`
// and the region is skipped (PRD §5). No IR is mutated.
ControlPlan detectControlRegions(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CONTROL_PLAN_H_
