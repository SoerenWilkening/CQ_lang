// ControlledLowering.h — Orchestrator for Phase-4 controlled-region lowering
// (PRD §2.9/§2.10, IMPLEMENTATION §5). Consumes the `ControlPlan` produced by
// `detectControlRegions` and, per region, runs the full pipeline:
//
//   ControlFlag  → mint the i32 control flag (compute, §1.5)
//   Substitution → lower in-shadow gate bodies to `_controlled` variants
//   Dissolution  → RAUW the merge `φ` to the in-place handle, erase it
//   (uncompute)  → mint the compare template's `_inv` twin (uncompute, §1.5)
//   Linearization→ collapse the `br`-diamond to a single block
//
// The flag's compute/uncompute bracket is balanced here, LIFO for nests (PRD
// §2.9): regions are walked outer→inner so the LIFO stack naturally pairs each
// uncompute with its compute. WP3 has a single flat region; the stack is the
// nesting seam (WP6). No `cqrt_free` here — Phase 4 brackets only the control
// flag, not data handles.

#ifndef CQ_IRPASS_CONTROLLED_LOWERING_H_
#define CQ_IRPASS_CONTROLLED_LOWERING_H_

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct ControlPlan;

// Lower every region in `plan`, walking outer→inner. Mutates the IR (control
// flags minted, gate bodies controlled, merges dissolved, diamonds
// linearized) and `taint` (control-flag map). A region whose flag/substitution
// could not be lowered (unsupported width — already diagnosed) is left as-is.
// Idempotent on an empty plan (no regions → no-op, no decls leaked).
void lowerControlledRegions(llvm::Module &M, WidthDispatch &wd,
                            TaintSet &taint, ControlPlan &plan);

}  // namespace cq

#endif  // CQ_IRPASS_CONTROLLED_LOWERING_H_
