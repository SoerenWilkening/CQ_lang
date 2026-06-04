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
//   * Uncontrolled data template `cq_template_<op>_<W>[_hl|_lh](…)`: emit the
//     declared `_inv` twin (FunctionType byte-identical to the forward — minted
//     from the forward callee's name + type). This MINTS A FRESH handle, so the
//     threaded `CurHandle` is substituted for the data operand and the fresh
//     result is returned for the next reversed link (R-template-inv-fresh-handle).
//
// The controlled `_controlled_inv` path lands in Step 4 (InShadowAdjoint); until
// then `emitInverseCall` returns nullptr for those callees.
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
// the data handle the next reversed link should consume (the threaded handle for
// in-place rotations / involutions; a fresh template result for the data-template
// `_inv` case), or nullptr if the callee is not (yet) an invertible Phase-5
// target. `Flag`, when non-null, supplies the i32 control flag for the controlled
// path (Step 4). `CurHandle`, when non-null, is the live register handle threaded
// in from the previous reversed link — substituted for this gate's data operand
// so a chain of fresh-handle-minting `_inv` twins stays connected; null means
// "use the forward call's own handle operand" (the head of a single-link chain).
llvm::Value *emitInverseCall(llvm::IRBuilder<> &B, llvm::CallInst *Forward,
                             WidthDispatch &wd, ControlledSymbols &csyms,
                             llvm::Value *Flag = nullptr,
                             llvm::Value *CurHandle = nullptr);

// Emit the adjoint of a whole forward chain: walk `ForwardChain` in REVERSE
// (`Chain[N-1] … Chain[0]`), calling `emitInverseCall` per link and threading the
// live handle through. `ForwardChain` is in FORWARD program order; `Terminal` is
// the live head handle the first reversed link consumes. Each non-in-place
// template `_inv` mints a FRESH handle that feeds the next link; in-place
// rotations pass the handle through. Returns the FINAL threaded handle (the one
// to `cqrt_free`), or nullptr if any link was not invertible.
llvm::Value *emitInverseChain(llvm::IRBuilder<> &B,
                              llvm::ArrayRef<llvm::CallInst *> ForwardChain,
                              WidthDispatch &wd, ControlledSymbols &csyms,
                              llvm::Value *Flag, llvm::Value *Terminal);

}  // namespace cq

#endif  // CQ_IRPASS_EMIT_INVERSE_H_
