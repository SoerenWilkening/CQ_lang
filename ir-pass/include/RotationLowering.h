// RotationLowering.h — Lower `@cq_theta_<sfx>` and `@cq_phi_<sfx>` to
// runtime rotation calls. Replaces the retired mid-struct rebind module:
// under the plain-SSA surface there are no mid-structs to rebind, so
// gate-triggered allocation now happens here, at the theta call site.
//
// Contract (algorithm in RotationLowering.cpp; backend.md §5.1):
//   * `@cq_theta_<sfx>(operand, angle)`:
//       - classical operand → emit `cqrt_alloc_<W>(operand)` then
//         `cqrt_ry_<W>(handle, angle)`; RAUW the theta result to the i32
//         alloc handle; mark the handle tainted; seed `taint.BirthOrder`.
//       - tainted operand (a chained theta) → emit `cqrt_ry_<W>` on the
//         existing handle only; RAUW the theta result to that operand.
//   * `@cq_phi_<sfx>(operand, angle)`:
//       - tainted operand → emit `cqrt_rz_<W>(handle, angle)`.
//       - classical operand → no rz (Rz on a basis state is unobservable).
//       - RAUW the phi result to its operand either way, then erase.
//
// The theta result's natural type (e.g. `double` for f64) may differ from
// the i32 handle it is RAUW'd to — that cross-type RAUW is laundered by
// erasure (every tainted user is itself lowered to a handle-consuming call
// and erased before the verifier; see IMPLEMENTATION.md §1). The void
// `ry`/`rz` call is NEVER the RAUW target (PRD §2.5).

#ifndef CQ_IRPASS_ROTATION_LOWERING_H_
#define CQ_IRPASS_ROTATION_LOWERING_H_

#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch;
struct TaintSet;

// Lowers every `@cq_theta_<sfx>` / `@cq_phi_<sfx>` collected by
// `propagate` (in `taint.ThetaCalls` / `taint.PhiCalls`), in BB order, and
// erases the originals. Mutates `taint`: inserts minted alloc handles into
// `taint.Tainted` and seeds `taint.BirthOrder` for each.
void lowerRotations(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_ROTATION_LOWERING_H_
