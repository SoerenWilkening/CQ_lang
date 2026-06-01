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
class Instruction;
class Module;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

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

  enum Kind { SelectRegion, BranchRegion } Kind = BranchRegion;

  // The merge node: a `SelectInst` (select-sourced) or the merge-block
  // `PHINode` (br-sourced). `MergeDissolution` rewrites/erases it.
  llvm::Instruction *Merge = nullptr;

  // In-shadow gate-body ops (the `then`-arm `cq_phi` calls), in program
  // order. `ControlledSubstitution` lowers each to its `_controlled` variant.
  llvm::SmallVector<llvm::Instruction *, 4> Shadow;

  // br-sourced CFG anchors (null for a select region). `Pred` holds the
  // outer `br i1`; `Arm` is the innermost guarded block (the gate body);
  // `MergeBB` is the common merge.
  llvm::BasicBlock *Pred = nullptr;
  llvm::BasicBlock *Arm = nullptr;
  llvm::BasicBlock *MergeBB = nullptr;
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
