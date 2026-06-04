// EmitInverse.h — The standalone, reusable adjoint spine (Phase 5, PRD §2.3).
//
// Given a forward `CallInst` (or an ordered forward chain), emit the per-call
// INVERSE at a caller-supplied `IRBuilder` insertion point and return the
// produced SSA value (the data handle the next reversed link consumes). This
// module owns NEITHER selection NOR placement — the caller positions the
// builder and supplies the forward call(s). That decoupling is deliberate:
// Phase 7 (manual `cq_invert_*`, beads test_C_libtooling-42t) reuses
// `emitInverseCall` on its own bracketed sequence with zero Phase-5 coupling.
//
// Dispatch is by callee-name suffix (the per-call inversion recipe, PRD §2.3):
//
//   * Uncontrolled rotation `cqrt_ry_<W>(h, θ)` / `cqrt_rz_<W>(h, θ)`
//     (arg_size 2, arg0 = handle): re-emit the SAME forward symbol with a
//     NEGATED angle (`CreateFNeg(θ)`). No `cqrt_ry/rz_<W>_inv` symbol exists;
//     the rotation is void and mints no handle, so the returned "current
//     handle" is the input handle (arg0), threaded unchanged.
//   * Self-adjoint involution `cqrt_x(q)` / `cqrt_cswap(c,a,b)`: emit AS-IS
//     (no `_inv` lookup — X and SWAP are their own inverse). Void; returns the
//     handle operand (arg0) for chain threading.
//
// Template `_inv` twins (`cq_template_*` → `_inv`, fresh-handle threading) land
// in Step 2 (ChainWalk); the controlled `_controlled_inv` path lands in Step 4
// (InShadowAdjoint). Until then `emitInverseCall` returns nullptr for those
// callees (the conservative Step-1 Uncomputation only feeds it rotations).
//
// ABI width, when needed, is recovered from the forward callee NAME or
// `taint.HandleWidth` — NEVER the i32-laundered SSA type (PRD §2.3).

#ifndef CQ_IRPASS_EMIT_INVERSE_H_
#define CQ_IRPASS_EMIT_INVERSE_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace cq {

class WidthDispatch;
class ControlledSymbols;

// Emit the inverse of a single forward call at `B`'s insertion point. Returns
// the data handle the next reversed link should consume (the input handle for
// in-place rotations / involutions; a fresh template result once Step 2 lands),
// or nullptr if the callee is not (yet) an invertible Phase-5 target. `Flag`,
// when non-null, supplies the i32 control flag for the controlled path
// (Step 4); it is unused for the uncontrolled cases handled in Step 1.
llvm::Value *emitInverseCall(llvm::IRBuilder<> &B, llvm::CallInst *Forward,
                             WidthDispatch &wd, ControlledSymbols &csyms,
                             llvm::Value *Flag = nullptr);

// Emit the adjoint of a whole forward chain: walk `ForwardChain` in REVERSE
// (`Chain[N-1] … Chain[0]`), calling `emitInverseCall` per link. `ForwardChain`
// is in FORWARD program order. In Step 1 every link is an in-place rotation, so
// each gate already carries the correct handle (arg 0) and the per-link return
// is a no-op; once Step 2 adds the non-in-place template `_inv` (which mints a
// FRESH handle), this routes each produced SSA value into the next reversed
// link's emission — and `emitInverseCall` gains a threaded-handle parameter.
void emitInverseChain(llvm::IRBuilder<> &B,
                      llvm::ArrayRef<llvm::CallInst *> ForwardChain,
                      WidthDispatch &wd, ControlledSymbols &csyms,
                      llvm::Value *Flag = nullptr);

}  // namespace cq

#endif  // CQ_IRPASS_EMIT_INVERSE_H_
