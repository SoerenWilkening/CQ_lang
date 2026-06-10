// RotationLowering.h — Lower `@cq_theta_<sfx>` and `@cq_phi_<sfx>` to
// runtime rotation calls. Replaces the retired mid-struct rebind module:
// under the plain-SSA surface there are no mid-structs to rebind, so
// gate-triggered allocation now happens here, at the theta call site.
//
// Contract (algorithm in RotationLowering.cpp; backend.md §5.1):
//   * The arg-1 ANGLE of EITHER rotation must be classical (untainted). A
//     quantum-derived angle has no fixed unitary → loud decline before any
//     emission, rotation left standing (test_C_libtooling-659; the
//     straight-line twin of ArmClassify::taintedAngleGate).
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

namespace llvm {
class CallInst;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct ControlPlan;

// Lowers every `@cq_theta_<sfx>` / `@cq_phi_<sfx>` collected by
// `propagate` (in `taint.ThetaCalls` / `taint.PhiCalls`), in BB order, and
// erases the originals. Mutates `taint`: inserts minted alloc handles into
// `taint.Tainted`, seeds `taint.BirthOrder`, and records each handle's logical
// ABI width in `taint.HandleWidth` (from the `cq_theta` classical operand,
// before any RAUW launders it — §5.6). `plan` (may be null) names the
// in-shadow gate-body `cq_phi` calls: those are skipped here. For the 4.1
// swap-route emitter (`SwapRouteEmit::lowerControlRegions`) this set is EMPTY
// — it runs before this pass and erases each arm `cq_phi` (§3), so the skip
// never fires; the hook is retained for the §6a control-in-place peephole.
void lowerRotations(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
                    const ControlPlan *plan = nullptr);

// Emit the `cq_phi` gate body as a runtime Rz on the i32 `handle`, controlled
// or uncontrolled (IMPLEMENTATION §5.1/§5.4). Uncontrolled →
// `cqrt_rz_<W>(handle, angle)`; controlled → `cqrt_rz_<W>_controlled(flag,
// handle, angle)` with the flag prepended as arg 0 (PRD §1.2, via
// `ControlledSymbols::controlledRotationFn`). `phi` supplies the width suffix,
// debug loc, and insertion point; the Rz is inserted before it. Returns true
// iff the Rz was emitted (false ⇒ unsupported width, diagnosed loudly, `phi`
// left standing for the verifier). Today only `lowerRotations` calls it
// (uncontrolled); the controlled form is retained solely for the optional §6a
// control-in-place peephole (`ControlledSymbols::controlledRotationFn` reserve
// — `ControlledSubstitution` was excised in 7cde677). PRECONDITION: the caller has
// verified `angle` is classical (untainted) — `lowerRotations` declines a
// tainted angle before calling (test_C_libtooling-659).
bool emitRz(llvm::CallInst *phi, llvm::Value *handle, llvm::Value *angle,
            WidthDispatch &wd, bool controlled, llvm::Value *flag);

}  // namespace cq

#endif  // CQ_IRPASS_ROTATION_LOWERING_H_
