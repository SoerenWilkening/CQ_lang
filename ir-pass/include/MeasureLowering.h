// MeasureLowering.h — Lower `@cq_measure_<sfx>` to `@cqrt_measure_<W>`.
// Was inline in `CQLoweringPass.cpp` step 6 (pre-Phase-2-M12).
//
// M17 contract: walk every `@cq_measure_<sfx>` call collected by
// `TaintPropagation` (14 frontend suffixes collapse to 7 ABI widths
// per PRD §"Width unification"), resolve its struct/handle operand via
// one of three shapes, and emit `@cqrt_measure_<W>(handle)` in its
// place — `W` derived per call site through the measure intrinsic's
// name (`cq_measure_<sfx>`) → `WidthDispatch::abiWidthFor(sfx)` →
// `WidthDispatch::measureRtFn(W)`.
//
// Operand shapes (Phase 1 invariants, all pinned by LIT/e2e fixtures):
//
//   (a) Direct init result: the measure arg is a known `@cq_init_<sfx>`
//       call recorded in `rebind.StructToHandle`. Used by
//       `measure_only.ll`.
//   (b) Insertvalue: the measure arg is `insertvalue %q<T>_mid_t poison,
//       <T> %h, 0`. Pulls the handle out of the insertvalue; erases
//       the insertvalue if it's only used here. Used by
//       `lowering_basic.ll`, `lowering_q_plus_c.ll`,
//       `lowering_q_plus_arg.ll`.
//   (c) Flattened i32: the measure arg is already an i32 SSA value in
//       `taint.Tainted` — for example, a `cq_template_add_<W>` result
//       or a SROA-flattened init result. Used by the e2e fixtures
//       worked_example / mixed_operand / full_example via the
//       CastRewrite path.
//
// The handle argument is always i32 across every width per PRD §"Width
// unification"; only the return-value type varies per ABI width
// (i1/i8/i16/i32/i64/float/double).
//
// Unrecognized shapes emit an LLVM diagnostic and leave the call in
// place. This is intentionally loud rather than silent so a future
// front-end shape that we missed surfaces as a build break instead of
// a wrong trace.

#ifndef CQ_IRPASS_MEASURE_LOWERING_H_
#define CQ_IRPASS_MEASURE_LOWERING_H_

#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch;
struct TaintSet;
struct RebindMap;

// Walks `taint.MeasureCalls` (already collected by `propagate`), emits
// `cqrt_measure_<W>(handle)` (W derived per call from the measure
// intrinsic suffix) for each, and erases the original measure call
// (and any single-use insertvalue feeding it).
void lowerMeasures(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
                   RebindMap &rebind);

}  // namespace cq

#endif  // CQ_IRPASS_MEASURE_LOWERING_H_
