// MeasureLowering.h — Lower `@cq_measure_<sfx>` to `@cqrt_measure_<W>`.
// Was inline in `CQLoweringPass.cpp` step 6 (pre-Phase-2-M12).
//
// M12 contract: walk every `@cq_measure_si32` call collected by
// `TaintPropagation`, resolve its struct/handle operand via one of three
// shapes, and emit `@cqrt_measure_i32(handle)` in its place.
//
// Operand shapes (Phase 1 invariants, all pinned by LIT/e2e fixtures):
//
//   (a) Direct init result: the measure arg is a known `@cq_init_si32`
//       call recorded in `rebind.StructToHandle`. Used by
//       `measure_only.ll`.
//   (b) Insertvalue: the measure arg is `insertvalue %qint_mid_t poison,
//       i32 %h, 0`. Pulls the handle out of the insertvalue; erases
//       the insertvalue if it's only used here. Used by
//       `lowering_basic.ll`, `lowering_q_plus_c.ll`,
//       `lowering_q_plus_arg.ll`.
//   (c) Flattened i32: the measure arg is already an i32 SSA value in
//       `taint.Tainted` — for example, a `cq_template_add_i32` result
//       or a SROA-flattened init result. Used by the e2e fixtures
//       worked_example / mixed_operand / full_example via the
//       CastRewrite path.
//
// Unrecognized shapes emit an LLVM diagnostic and leave the call in
// place. This is intentionally loud rather than silent so a future
// front-end shape that we missed surfaces as a build break instead of
// a wrong trace.
//
// M17 generalizes the front-end name set and ABI width selection;
// M12 keeps `cq_measure_si32 → cqrt_measure_i32`.
//
// Spec: phases/phase2/PLAN.md §4.12, §4.17.

#ifndef CQ_IRPASS_MEASURE_LOWERING_H_
#define CQ_IRPASS_MEASURE_LOWERING_H_

#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch;
struct TaintSet;
struct RebindMap;

// Walks `taint.MeasureCalls` (already collected by `propagate`), emits
// `cqrt_measure_i32(handle)` for each, and erases the original measure
// call (and any single-use insertvalue feeding it).
void lowerMeasures(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
                   RebindMap &rebind);

}  // namespace cq

#endif  // CQ_IRPASS_MEASURE_LOWERING_H_
