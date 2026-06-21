// IOSinkLowering.h — Phase 7.6: lower a tainted I/O output sink (`printf` /
// `putchar`) COHERENTLY to the reversible output tape, instead of declining at
// `declineTaintEscapes` (Rule 5 — the compiler inserts NO measurement).
//
// Each tainted INTEGER-SCALAR argument of a recognized sink is APPENDED to an
// output tape: one lazy `cqrt_tape_alloc()` per function, then one
// `cqrt_tape_write_<W>(tape, src)` per tainted arg. The returned `out_handle` is
// a KEPT |0> output rail (registered in `TaintSet::OutputRails`) — never freed,
// never uncomputed (a Bennett output tape). The original sink call is erased.
//
// Runs AFTER control lowering and BEFORE `lowerRotations` (CQLoweringPass::run),
// so the sink operand is still the pre-RAUW `@cq_theta`-derived SSA value, not
// the i32 runtime handle the rotation RAUW substitutes — capturing the i32 tag
// instead of the quantum value would be the opaque-call silent miscompile.
//
// Anything it cannot PROVE lowerable declines LOUDLY (Prime Directive): an fp
// (`%f`) arg, an i128 / non-`widthHasReversibleCopy` scalar, a non-constant
// classical co-arg, or a used sink result. `puts` / `%s` (a pointer) never
// reach here — a tainted value reaching them declines upstream at the store
// guard (`kMsgStore`); coherent string output is Phase 7.5.

#ifndef CQ_IRPASS_IO_SINK_LOWERING_H_
#define CQ_IRPASS_IO_SINK_LOWERING_H_

#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch;
struct TaintSet;

// Walk the module for direct `printf` / `putchar` calls reading a tainted value
// (a classical-only sink is left byte-untouched) and lower each to a
// `cqrt_tape_alloc` + `cqrt_tape_write_<W>` append sequence; register each kept
// output rail in `taint.OutputRails`. Declines loudly (opt exits non-zero) for
// any unprovable shape.
void lowerIOSinks(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_IO_SINK_LOWERING_H_
