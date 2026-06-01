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
  // The tainted i1 condition (cmp result / select cond). Lowered as the
  // control flag by `ControlFlag`; the original instruction stays until
  // linearization erases it (§1.3, keeps the `br i1` well-typed mid-pass).
  llvm::Value *Condition = nullptr;
  // The i32 control flag minted by `ControlFlag::lowerControlFlag`
  // (`CompareLowering::lowerCompareToFlag`). Null until that step runs.
  llvm::Value *Flag = nullptr;

  enum Kind { SelectRegion, BranchRegion } Kind = BranchRegion;

  // The merge node: a `SelectInst` (select-sourced) or the merge-block
  // `PHINode` (br-sourced). `MergeDissolution` rewrites/erases it.
  llvm::Instruction *Merge = nullptr;

  // In-shadow gate-body ops (the `then`-arm `cq_phi` calls), in program
  // order. `ControlledSubstitution` lowers each to its `_controlled` variant.
  llvm::SmallVector<llvm::Instruction *, 4> Shadow;

  // br-sourced CFG anchors (null for a select region). `Pred` holds the
  // `br i1`; `Arm` is the single guarded block; `MergeBB` is the merge.
  llvm::BasicBlock *Pred = nullptr;
  llvm::BasicBlock *Arm = nullptr;
  llvm::BasicBlock *MergeBB = nullptr;

  // Nesting depth (0 = outermost) and the enclosing region's flag, for the
  // single-flag AND model (PRD §2.7). Unused by WP3's flat fixture.
  unsigned Depth = 0;
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
