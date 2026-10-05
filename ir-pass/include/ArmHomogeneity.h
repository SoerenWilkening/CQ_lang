// ArmHomogeneity.h — Tree-homogeneity gate for the register-form depth-2 nest.
//
// The §12.5 split (IMPLEMENTATION-4.3 §3.2): classify every arm in a recovered
// depth-2 region TREE as Phase or Value, then gate the tree on HOMOGENEITY —
// all-phase passes on to `recoverRegionTree`'s later criteria, which since bd
// 3qlq Inc 1 part B also end in a decline (RegionTreeDetect.h); any value arm
// declines `mixed phase/value arm` (mixed) or `value-arm swap-route` (pure-value),
// and a stray op in the outer arm (the `Mid` block, which also holds the inner
// condition/branch — the COMPLETENESS#5 carve-out) declines `impure phase arm`.
//
// Called by `RegionTreeDetect` over the proven tree shape, BEFORE the criterion-4
// RAUW-collapse (FA2: the order that yields the §5h decline table — a value-op
// merge incoming does not collapse through the `cq_phi` diagonal-alias closure,
// so RAUW-collapse run first would mis-fire `control flow` on a value nest). The
// flat-region path keeps `ArmClassify::classifyArms` untouched (MD2); this is the
// tree-only homogeneity twin, reusing the de-anonymized per-arm walks
// (`walkPhaseSpine` / `walkValueChain` / `taintedAngleGate`, ArmAnalysis.h).
//
// Pure SSA analysis — NO IR is mutated (Rule 9). Fires at most one loud
// diagnostic; over-declining is always safe (Prime Directive).

#ifndef CQ_IRPASS_ARM_HOMOGENEITY_H_
#define CQ_IRPASS_ARM_HOMOGENEITY_H_

namespace llvm {
class BasicBlock;
class Instruction;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Gate the depth-2 region tree on phase-homogeneity (criterion 6).
//   * `Mid` / `MidIncoming` — the OUTER arm block and its shared-merge incoming
//     value (the intervening gate output `%g`); `Mid` also holds `InnerCond`
//     and the inner branch (carved out of the Mid purity scan).
//   * `InnerArm` / `InnerArmIncoming` — the inner content arm and its
//     shared-merge incoming value (`%h`).
//   * `InnerCond` — the inner branch condition (its compare + in-`Mid` operand
//     lineage are the legitimate non-gate Mid content the carve-out allows).
//   * `Anchor` — the instruction the homogeneity / impurity diagnostics attach
//     their `!dbg` to (the outer branch).
// Returns true iff every arm is a pure phase chain (the tree is all-phase). On
// any value/impure/tainted-angle arm, fires the precise loud diagnostic and
// returns false.
bool treeHomogeneous(llvm::BasicBlock *Mid, llvm::Value *MidIncoming,
                     llvm::Value *InnerCond, llvm::BasicBlock *InnerArm,
                     llvm::Value *InnerArmIncoming, TaintSet &Taint,
                     llvm::Instruction *Anchor);

}  // namespace cq

#endif  // CQ_IRPASS_ARM_HOMOGENEITY_H_
