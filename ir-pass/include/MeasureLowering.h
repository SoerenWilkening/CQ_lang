// MeasureLowering.h — Lower `@cq_measure_<sfx>` to `@cqrt_measure_<W>`.
// Originally inline in `CQLoweringPass.cpp` step 6.
//
// Contract: walk every `@cq_measure_<sfx>` call collected by
// `TaintPropagation` (14 frontend suffixes collapse to 7 ABI widths
// per PRD §"Width unification"), resolve its struct/handle operand via
// one of three shapes, and emit `@cqrt_measure_<W>(handle)` in its
// place — `W` derived per call site through the measure intrinsic's
// name (`cq_measure_<sfx>`) → `WidthDispatch::abiWidthFor(sfx)` →
// `WidthDispatch::measureRtFn(W)`.
//
// Operand shape (invariant pinned by LIT/e2e fixtures):
//
//   Tainted i32 handle: under the plain-SSA surface the measure arg is
//   always already an i32 SSA value in `taint.Tainted` — a theta result
//   RAUW'd to its alloc handle by `RotationLowering`, or a
//   `cq_template_add_<W>` result from `OpcodeLowering`. (The retired
//   mid-struct shapes — direct source result, insertvalue unwrap — have no
//   inputs under plain SSA and went away with the retired rebind module.)
//
// The handle argument is always i32 across every width per PRD §"Width
// unification"; only the return-value type varies per ABI width
// (i1/i8/i16/i32/i64/float/double).
//
// ── TWO DISPOSITIONS SINCE bd test_C_libtooling-21mg ────────────────────────
// The operand's TAINT, and nothing else, selects which (Rule 3):
//
//   * TAINTED   → the quantum measure: `@cqrt_measure_<W>(handle)` as above.
//   * CLASSICAL → the call is REPLACED BY ITS OPERAND. Measuring a value with
//     no quantum lineage is the identity on the state and its outcome is that
//     value, so nothing is emitted: no runtime symbol, no gate, NO
//     `cqrt_alloc_<W>` (minting a rail for classical data is the f64/angle
//     miscompile family), no trace line. `cq_measure(<classical>)` is a valid
//     (trivial) circuit; refusing it was an over-decline. `cq_measure` is
//     type-preserving (`T (T)`, enforced by `declMatchesPrototype`), so no
//     `zext`/`trunc` is owed. Pinned by `lowering_measure_classical_accept.ll`,
//     `lowering_measure_classical_mixed_accept.ll`,
//     `control_measure_classical_bool_owner.ll` and
//     `e2e-slice-measure-classical-bool{,-twin-identical}`.
//
// TWO CONSEQUENCES OF THAT DISPOSITION, both new public surface, both recorded
// here because they are semantic rulings and not accidents (review_C_r1 items
// 3 and 5):
//
//   * AN EXTERNALLY-LINKED WRAPPER IS NOW THE IDENTITY. `int api_measure(int x)
//     { return cq_measure(x); }` compiles to `ret i32 %x` with ZERO `cqrt_*`
//     symbols, because a function argument carries no taint. That is sound and
//     not a leak of a quantum handle across the ABI: a rail handle cannot cross
//     a translation unit (taint is intra-module), and an in-module quantum
//     caller does not reach this path at all — it declines earlier with
//     `cq specialization: callee measures under quantum lift`. Measured:
//     `$SES/trackC/review_C_r1_probes/{r27_measure_external_arg,
//     r17_measure_in_noinline}.c`.
//
//   * `cq_measure(cq_measure(q))` EMITS ONE MEASUREMENT, and both reads return
//     its outcome. The inner call is the quantum measure; its result is a SINK
//     and is never tainted, so the outer call takes the classical branch and
//     RAUWs to that outcome. One line is the RIGHT number, not a dropped gate:
//     a projective measurement is idempotent, so re-measuring a collapsed
//     register cannot change the state or the value. Pinned by
//     `f_measure_of_measure` in `lowering_measure_classical_mixed_accept.ll`;
//     measured as `review_C_r1_probes/r09_measure_of_measure.c`.
//
// A TAINTED operand that is not an i32 handle still emits an LLVM diagnostic
// and leaves the call in place. This is intentionally loud rather than
// silent so a future front-end shape that we missed surfaces as a build
// break instead of a wrong trace. An `undef`/`poison` CLASSICAL operand is a
// loud decline of its own (`lowering_reject_measure_undef_operand.ll`) — see
// `MeasureLowering.cpp` for both arguments.

#ifndef CQ_IRPASS_MEASURE_LOWERING_H_
#define CQ_IRPASS_MEASURE_LOWERING_H_

#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch;
struct TaintSet;

// Walks `taint.MeasureCalls` (already collected by `propagate`); for a TAINTED
// operand emits `cqrt_measure_<W>(handle)` (W derived per call from the measure
// intrinsic suffix) and for a CLASSICAL one emits nothing and RAUWs the call to
// its operand (bd 21mg); either way the original measure call is erased.
//
// ⚠ MUST run AFTER `repropagateControlMerges` — the taint it reads has to be
// FINAL, or a 6.5/4.5 round-2 merge rail measure degrades into a classical
// passthrough of an i32 handle (see `MeasureLowering.cpp`, the L1 note).
void lowerMeasures(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_MEASURE_LOWERING_H_
