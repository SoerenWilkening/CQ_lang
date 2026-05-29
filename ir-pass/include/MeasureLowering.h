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
// An operand that is not a tainted i32 handle emits an LLVM diagnostic
// and leaves the call in place. This is intentionally loud rather than
// silent so a future front-end shape that we missed surfaces as a build
// break instead of a wrong trace.

#ifndef CQ_IRPASS_MEASURE_LOWERING_H_
#define CQ_IRPASS_MEASURE_LOWERING_H_

#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch;
struct TaintSet;

// Walks `taint.MeasureCalls` (already collected by `propagate`), emits
// `cqrt_measure_<W>(handle)` (W derived per call from the measure
// intrinsic suffix) for each, and erases the original measure call.
void lowerMeasures(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_MEASURE_LOWERING_H_
