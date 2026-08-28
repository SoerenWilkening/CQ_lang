// ArithLowering.h — Lower tainted data-arithmetic opcodes to template
// calls. Split out of `OpcodeLowering` in Phase 3 (PRD §1, IMPLEMENTATION
// §3): the driver owns collection / ordering / erase; this TU owns the
// per-instruction emit + RAUW + taint bookkeeping for the two data classes
// it covers:
//
//   * `BinaryOperator` — all 16 in-scope stems (int arith/bitwise + fp
//     arith), HH/HL/LH operand shapes, commutativity-gated BirthOrder.
//   * `UnaryOperator`  — `fneg` (fp only), the single unary data op.
//
// (`fneg` lives here rather than its own TU per Decision D3 — it is ~30 LOC
// and shares the data-handle bookkeeping. Split point if this TU nears
// 300.)
//
// Operand classification (PRD §2.4) reads `taint.Tainted` membership — NOT
// `isa<Constant>` — so it correctly treats tainted args/loads as handles
// and untainted args/literals/globals as classical:
//
//   * HH (both tainted): symmetric QQ template. Commutative stems order
//     operands by `BirthOrder` (lower-birth → LHS) for clang-version-stable
//     traces; non-commutative stems PRESERVE source operand order (the
//     BirthOrder swap is gated OFF — operand order is semantic).
//   * HL/LH (one tainted): commutative ops canonicalize the literal to the
//     RHS → `_hl(handle, classical)`. Non-commutative ops preserve order:
//     handle-on-left → `_hl(handle, classical)`; literal-on-left → `_lh`
//     `(classical, handle)` (e.g. `100 - x`, `3 << x`).
//
// Each rewriter performs emit + RAUW + taint/BirthOrder bookkeeping but
// does NOT erase the original — the driver owns erase (the work list IS the
// set of originals). An unsupported stem or width emits the loud
// `diagnoseNoTemplate` and leaves the op un-lowered (the driver then must
// not erase it; see the driver's erase contract).

#ifndef CQ_IRPASS_ARITH_LOWERING_H_
#define CQ_IRPASS_ARITH_LOWERING_H_

namespace llvm {
class BinaryOperator;
class DominatorTree;
class LoopInfo;
class UnaryOperator;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Lower one tainted `BinaryOperator` to its data template. Returns true if
// the op was rewritten (RAUW'd, bookkept) and is therefore safe for the
// driver to erase; false if it was diagnosed/left un-lowered (the driver
// must NOT erase it). All 16 in-scope stems; HH/HL/LH per the rules above.
bool rewriteBinary(llvm::BinaryOperator *bo, WidthDispatch &wd,
                   TaintSet &taint);

// Lower one tainted `UnaryOperator` (`fneg`) to `cq_template_fneg_<W>`.
// Same return contract as `rewriteBinary`. FP widths only.
bool rewriteUnary(llvm::UnaryOperator *uo, WidthDispatch &wd, TaintSet &taint);

// Issue dtzb — lower a recognized loop-rail SELF-UPDATE (`bo` ∈
// `taint.InPlaceRailOps`, a `lowerLoops`-proven `q = q OP c` with OP ∈
// {add, xor} and a classical immediate) to the IN-PLACE
// `cqrt_{addc,xorc}_<W>(handle, imm)` instead of the out-of-place data template
// `rewriteBinary` would emit (which mints a fresh per-iteration rail — the X1
// dirty rail). By this stage the rail operand is the i32 handle (rotation
// lowering already ran); `imm` is the classical operand at the rail's logical
// width. The result is RAUW'd to the handle (in-place keeps the same register).
// Same return contract as `rewriteBinary`; only reached for a proven in-place
// rail op (the caller gates on `InPlaceRailOps` membership).
bool rewriteInPlaceValueRail(llvm::BinaryOperator *bo, WidthDispatch &wd,
                             TaintSet &taint);

// ── M-C: STRAIGHT-LINE IN-PLACE REASSIGNMENT (bd test_C_libtooling-6uqc,
//    Increment 2a — `add` only) ────────────────────────────────────────────────
//
// Should this tainted binary op be lowered by `rewriteInPlaceValueRail` (one
// void `cqrt_addc_<W>(P, imm)` mutating the parent rail) instead of by
// `rewriteBinary` (a fresh `cq_template_add_<W>_hl` rail that KEEPS `P` alive)?
//
// WHY IT MATTERS — this is not an optimization. An out-of-place `q + c` leaves
// `P` standing as a perfect basis record of the wire it fed. `slice_control_
// seq_grover`'s committed golden is exactly that: `h0` and `h1` are live,
// entangled records of `h4` when the S† `cqrt_ry_i32(h4, -0.5)` fires, so the
// reflection the slice exists to demonstrate is DEPHASED (bd
// test_C_libtooling-nepx; verify-clean, byte-consistent trace, stage-2b clean —
// the silent-miscompile signature). Lowering the reassignment in place mints no
// ancestor, so there is nothing to dephase.
//
// THE FENCE IS POSITION-AWARE DEADNESS (owner ruling 2026-08-27, second round;
// the earlier "single-consumer-EVER" reading is WITHDRAWN). The op converts iff
// the parent handle has NO DATA USE AFTER IT. A PRIOR, COMPLETED reader — the
// canonical one is a tainted-condition region compare whose flag the Phase-4
// emitter has already stripped and freed — does NOT disqualify: it read `P` at
// its pre-op value, at a point that has already executed, and nothing will read
// it again. Excluding those was measured (SPIKE §9.8) to leave the campaign's
// own customer dephased.
//
// FAILING THE FENCE IS NOT A DECLINE. The fallback is the EXISTING out-of-place
// lowering — today's behavior, byte for byte. Nothing here ever emits a
// diagnostic (Rule 17's decline belongs to inputs outside the target shape, and
// an out-of-place `q + c` is a shape we lower correctly).
//
// THE SHIPPED FENCE IS STRICTLY NARROWER THAN CENSUS 0.2's `F4` COLUMN, AND ONE
// OF THOSE NARROWINGS IS A CORRECTION, NOT CAUTION. Census 0.2 (SPIKE §3.1)
// models F4 as "the parent has no LATER use OTHER THAN `cqrt_ry`/`cqrt_rz` on
// that same handle". THAT WHITELIST IS UNSOUND FOR M-C. A later rotation on the
// parent is not a passive reader: `Ry`/`Rz` act on whatever computational-basis
// value the rail holds, so mutating the rail first changes the state the
// rotation produces —
//     out of place:  rail(q)=|q>,  rail(d)=|q+3>,  Ry acts on |q>
//     in place:      ONE rail = |q+3>,             Ry acts on |q+3>
// which are different unitaries. The whitelist was written for the dtzb LOOP
// context, where the rotation is the rail's OWN gate and the mutation is the
// loop's own; carried over verbatim it would be an accept widening in the
// silent-miscompile direction. G6 therefore refuses ANY use after the op,
// rotations included (pinned by `@later_rotation` in
// lowering_mc_fence_fallback.ll).
//
// MEASURED, on the post-change corpus (census 0.2 re-run, read-only): 56 `add`
// sites the census's strict-F4 column still calls eligible are refused here —
// 49 by G7 (a prior undischarged producer, or a prior `cqrt_qram_store_` whose
// own `_unc` re-reads its operands), 4 by the G6 correction above, 2 by G4 (a
// formal-parameter immediate), 1 by G7's off-ABI-store exclusion. Every one of
// the 56 is accounted for; none is an unexplained decline.
//
// KNOWN, MEASURED SCOPE EFFECT — an ORPHANED TERMINAL, and it is a LEAK, never
// a wrong free. `Uncomputation` selects terminals among `isDataProducer` values
// (`cqrt_alloc_*`, `cqrt_qram_alloc/load_*`, `cq_template_*`). An out-of-place
// `q + c` MINTS such a producer; the in-place form does not. So when the parent
// is ITSELF not a data producer, the chain loses its only terminal and the whole
// DAG is simply never recovered — nothing reversed, nothing freed (Rule 6's safe
// direction: left allocated, never freed dirty). The reachable parents in that
// class are a Phase-6 clone-call return (`__cq_q_*`) and hand-written off-ABI
// primitives; the latter are exactly the four un-invertible DECLINE probes, whose
// terminals were re-based onto `mul` so they keep probing what they name.
// MEASURED over the e2e corpus: `cqrt_free` counts are IDENTICAL before and after
// on every changed slice — this class does not fire on real input. A `G8` fence
// (require the parent to be a data producer) was considered and NOT added: it
// would have to peel through this same pass's own pending in-place decisions to
// admit a chained `q += a; q += b`, and it excludes nothing the corpus contains.
//
// `DT`/`LI` are `bo`'s own function's, built by the driver.
bool classifyInPlaceReassignment(llvm::BinaryOperator *bo, WidthDispatch &wd,
                                 const TaintSet &taint,
                                 const llvm::DominatorTree &DT,
                                 const llvm::LoopInfo &LI);

}  // namespace cq

#endif  // CQ_IRPASS_ARITH_LOWERING_H_
