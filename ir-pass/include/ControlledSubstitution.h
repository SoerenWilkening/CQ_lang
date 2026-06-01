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

}  // namespace cq

#endif  // CQ_IRPASS_CONTROLLED_SUBSTITUTION_H_
