// EmitInverse.h — The standalone, reusable adjoint spine (Phase 5, PRD §2.3).
//
// Given a forward `CallInst` (or an ordered forward chain), emit the per-call
// adjoint at a caller-supplied `IRBuilder` insertion point. The adjoint of a
// forward op `out = f(src…)` is the inverse *step*, NOT the inverse *operation*:
// a VOID, IN-PLACE primitive that ZEROES `out`'s rail by recomputing `f` from
// the still-live sources (Bennett uncompute) — it produces NO new handle. This
// module owns NEITHER selection NOR placement — the caller positions the builder,
// supplies the forward call(s), and owns the `cqrt_free` of the rail it already
// holds (DD-1). The decoupling is deliberate: Phase 7 (manual `cq_invert_*`,
// beads test_C_libtooling-42t) reuses `emitInverseCall` on its own bracketed
// sequence with zero Phase-5 coupling.
//
// Dispatch is by callee-name suffix (the per-call inversion recipe, PRD §2.3):
//
//   * Uncontrolled rotation `cqrt_ry_<W>(h, θ)` / `cqrt_rz_<W>(h, θ)`
//     (arg_size 2, arg0 = handle): re-emit the SAME forward symbol with a
//     NEGATED angle (`CreateFNeg(θ)`). No `cqrt_ry/rz_<W>_inv` symbol exists;
//     the rotation is void and acts in place on its forward handle.
//   * Self-adjoint involution `cqrt_x(q)` / `cqrt_cswap(c,a,b)`: emit AS-IS
//     (no `_inv` lookup — X and SWAP are their own inverse). Void, in place.
//
//   * Uncontrolled data template `cq_template_<op>_<W>[_hl|_lh|_qq](…)`: emit its
//     VOID `_unc` form `cq_template_…_unc(out, src…)` (DD-3 slot convention: `out`
//     — the forward call's own result handle — is arg 0, then the forward operands
//     in their original order). The rail is zeroed in place; the live sources are
//     read and preserved. No fresh mint, no threaded handle. The fresh-minting
//     `_inv` twin is the inverse *operation* and is WRONG for uncompute (threading
//     it frees a dirty/entangled rail = a hidden measurement, Rule 6/8) — it is
//     never emitted here (DD-2; `_inv` generation survives only for Phase-7).
//
//   * Any other primitive (incl. the controlled callees) → no correct uncompute →
//     return the un-invertible signal (`false`) so the driver declines LOUDLY
//     (PRD §2.12) rather than leaving a half-reversed chain.
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

// Pure predicate (emits no IR): true iff `emitInverseCall` can emit a correct
// in-place adjoint for `Forward` — an uncontrolled rotation, a self-adjoint
// involution (`cqrt_x`/`cqrt_cswap`), or an uncontrolled `cq_template_*` whose
// void `_unc` form it mints. False for ANY other primitive (a controlled callee,
// a permutation gate like `cqrt_cnot`/`cqrt_toffoli` Phase 5 never emits for
// data, an `_inv`/`_unc` twin, an indirect call). The whole-DAG driver PRE-SCANS
// the recovered gates with this BEFORE emitting any adjoint, so an un-invertible
// primitive declines LOUDLY with NO half-reversed chain and NO dangling free
// (PRD §2.12, §2.10). It is the canonical ACCEPT set: `emitInverseCall` consults
// it first, so the two can never drift (Rule 14).
bool isInverseEmittable(const llvm::CallInst *Forward);

// Emit the void in-place adjoint of a single forward call at `B`'s insertion
// point. Returns `true` iff the callee is an invertible Phase-5 target (rotation,
// involution, or a `cq_template_*` whose `_unc` form is emitted); `false` for any
// un-invertible primitive (the loud-decline signal — PRD §2.12). `CurHandle`,
// when non-null, substitutes for an in-place gate's handle operand so a Phase-7
// caller can thread a relabeled register; the whole-DAG uncompute driver reads
// the forward operands directly (the void `_unc` zeroes the rail in place and
// mints nothing, so there is nothing to thread) and passes nullptr.
bool emitInverseCall(llvm::IRBuilder<> &B, llvm::CallInst *Forward,
                     WidthDispatch &wd, llvm::Value *CurHandle = nullptr);

// Emit the adjoint of a whole forward chain: walk `ForwardChain` in REVERSE
// (`Chain[N-1] … Chain[0]`), calling `emitInverseCall` per link. `ForwardChain`
// is in FORWARD program order; SSA dominance makes reverse program order a valid
// reverse-topological order, so each void `_unc` reads operands that are still
// live (a leaf is zeroed before the source it reads). Returns `true` iff EVERY
// link inverted; on any un-invertible link returns `false` (the caller owns the
// loud decline — DD-1). Mints no handle: the caller `cqrt_free`s the terminal /
// rail / recovered root it already holds.
bool emitInverseChain(llvm::IRBuilder<> &B,
                      llvm::ArrayRef<llvm::CallInst *> ForwardChain,
                      WidthDispatch &wd);

}  // namespace cq

#endif  // CQ_IRPASS_EMIT_INVERSE_H_
