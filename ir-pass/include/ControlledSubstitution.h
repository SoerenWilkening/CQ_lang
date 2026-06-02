// ControlledSubstitution.h — Lower a region's in-shadow gate bodies to their
// `_controlled` template variants (PRD §2.10, IMPLEMENTATION §5.4). For each
// `region.Shadow` `cq_phi(h, θ)`: emit `cqrt_rz_<W>_controlled(flag, h, θ)`
// (via the shared `RotationLowering::emitRz`), RAUW the `cq_phi` result to the
// in-place handle `h` (the controlled Rz mutates `h`; the phi value IS the
// handle), record `taint.ControlFlag[h] = flag`, and erase the `cq_phi`. WP3's
// only shadow op is the gate body; in-shadow data-arith/cast is the §5.4
// forward seam (inert for the realized menu).

#ifndef CQ_IRPASS_CONTROLLED_SUBSTITUTION_H_
#define CQ_IRPASS_CONTROLLED_SUBSTITUTION_H_

namespace llvm {
class BasicBlock;
class Instruction;
class Value;
template <typename T> class ArrayRef;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct ControlRegion;

// Substitute every in-shadow op in `region` with its controlled variant,
// controlled by `region.Flag` (which must be set — call `lowerControlFlag`
// first). Erases the lowered `cq_phi` calls. A shadow op with an unsupported
// width is diagnosed (by `emitRz`) and left standing for the verifier.
void substituteControlled(ControlRegion &region, WidthDispatch &wd,
                          TaintSet &taint);

// Substitute ONE arm's in-shadow `cq_phi` gate bodies with their controlled
// `cqrt_rz_<W>_controlled(Flag, handle, angle)` forms (RAUW the `cq_phi` to its
// in-place handle, erase). When `Negate`, wrap the arm in a self-inverse
// `cqrt_x(Flag)` bracket so the gates fire on ¬Flag (the §2.5 ¬flag mechanism).
// Exposed for the WP18 gated-switch lowering, which controls each case arm on
// its own eq-flag (and the default arm on the ¬OR flag). `ArmBlock` supplies the
// terminator the trailing `cqrt_x` anchors before.
void substituteArm(llvm::ArrayRef<llvm::Instruction *> Shadow, llvm::Value *Flag,
                   bool Negate, llvm::BasicBlock *ArmBlock, WidthDispatch &wd,
                   TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CONTROLLED_SUBSTITUTION_H_
