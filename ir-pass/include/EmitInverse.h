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
//   * Specialization clone `@__cq_q_<callee>_<mask>(args…)` (Phase 6.3 transitive):
//     emit its void `_unc` twin `@__cq_q_..._unc(out, args…)` (`out ^= f(args)`
//     zeroes the entangled out rail and restores the borrowed inputs). Same slot
//     convention as a data template (`out` is arg 0). The twin is specializer-
//     synthesized BEFORE the enclosing clone's wrap reverses this call.
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
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include "ScrubOnDelete.h"  // SpineOpSet (bd 8e5r)

#include <string>

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

// bd r2j3.33 — the adjoint SYMBOL of an in-place quantum-source gate: xor (and
// the i1 `cqrt_cnot`) itself, `cqrt_add_<W>` <-> `cqrt_sub_<W>`. The ONE spelling;
// the emission and the post-`uncompute` stale-read check both ask it.
std::string inPlaceQQAdjointName(llvm::StringRef Name);

// bd r2j3.33 (R11 round 2b) — the FORWARD call whose adjoint `Adj` is, by the
// recipes `emitInverseCall` emits (the inverse of those recipes, kept beside
// them): an out-first `<fwd>_unc(out, operands…)` (data template, compare, QRAM
// load, clone call) names its forward in slot 0; the QRAM store's same-args
// `<fwd>_unc(arr, idx, val)` is matched to the store with identical operands.
// Null when no recipe produced `Adj` (the `_inv` reserve, anything else).
llvm::CallInst *forwardOfAdjoint(const llvm::CallInst *Adj);

// Emit the void in-place adjoint of a single forward call at `B`'s insertion
// point. Returns `true` iff the callee is an invertible Phase-5 target (rotation,
// involution, or a `cq_template_*` whose `_unc` form is emitted); `false` for any
// un-invertible primitive (the loud-decline signal — PRD §2.12). `CurHandle`,
// when non-null, substitutes for an in-place gate's handle operand so a Phase-7
// caller can thread a relabeled register; the whole-DAG uncompute driver reads
// the forward operands directly (the void `_unc` zeroes the rail in place and
// mints nothing, so there is nothing to thread) and passes nullptr.
//
// `Rec` (M-A Inc 1, bd test_C_libtooling-6uqc): when non-null, EVERY adjoint call
// this function mints is inserted into it. Pass `&taint.SpineOps` so the late
// live-record guard can tell a re-emitted SELF-INVERSE gate (`cqrt_x`,
// `cqrt_cswap`, `cqrt_toffoli`, `cqrt_cnot`, `cqrt_copy_*_controlled`,
// `cqrt_xorc`/`cqrt_addc`) apart from a FORWARD one — they are the same call, so
// nothing in the lowered text distinguishes them.
//
// PASSING nullptr IS AN OVER-ACCEPT HAZARD, NOT AN OVER-DECLINE ONE — an
// unrecorded self-inverse gate is read as a USER DATA USE and EXEMPTS the record
// it names. (An earlier draft of this comment said the opposite; corrected by the
// Rule-13 round's F5 finding — see TaintSet::SpineOps for the full statement.)
// The one caller that passes nullptr is `BennettWrap`, and its safety is
// STRUCTURAL, not a fail-direction argument: its adjoints land inside a Phase-6
// clone BODY, SSA users are function-local, so a gate there can never appear in
// `R->users()` for a caller-side record — and a clone body itself holds no guard
// site, since `scanBody` rejects every `cq_theta`/`cq_phi` in a lifted callee
// (pinned by `spec_clone_theta_free.ll`). Any NEW site, or an existing one made
// reachable outside a clone body, MUST thread `&taint.SpineOps`.
bool emitInverseCall(llvm::IRBuilder<> &B, llvm::CallInst *Forward,
                     WidthDispatch &wd, llvm::Value *CurHandle = nullptr,
                     SpineOpSet *Rec = nullptr);

// Emit the adjoint of a whole forward chain: walk `ForwardChain` in REVERSE
// (`Chain[N-1] … Chain[0]`), calling `emitInverseCall` per link. `ForwardChain`
// is in FORWARD program order; SSA dominance makes reverse program order a valid
// reverse-topological order, so each void `_unc` reads operands that are still
// live (a leaf is zeroed before the source it reads). Returns `true` iff EVERY
// link inverted; on any un-invertible link returns `false` (the caller owns the
// loud decline — DD-1). Mints no handle: the caller `cqrt_free`s the terminal /
// rail / recovered root it already holds. `Rec` is forwarded to every per-link
// `emitInverseCall` (see there).
bool emitInverseChain(llvm::IRBuilder<> &B,
                      llvm::ArrayRef<llvm::CallInst *> ForwardChain,
                      WidthDispatch &wd,
                      SpineOpSet *Rec = nullptr);

}  // namespace cq

#endif  // CQ_IRPASS_EMIT_INVERSE_H_
