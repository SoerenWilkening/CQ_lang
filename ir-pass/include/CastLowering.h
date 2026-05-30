// CastLowering.h — Lower tainted `CastInst` over the in-scope cast pairs to
// width-change templates. Split out of `OpcodeLowering` in Phase 3 (PRD §1,
// IMPLEMENTATION §3/§5.3): the driver owns collection / ordering / erase and
// the up-front width capture; this TU owns the per-instruction emit +
// cross-type RAUW + taint bookkeeping.
//
// Cast width capture before RAUW (IMPLEMENTATION §1.3, risk R1 — the single
// most error-prone point of the phase): `CastInst::getSrcTy()` reads
// `getOperand(0)->getType()`, so once a prior rewrite RAUWs that operand to
// an i32 handle the SOURCE width is GONE. The driver therefore captures
// `(From, To)` ABI widths for every tainted cast at COLLECTION time, before
// any rewrite mutates an operand, and hands them to `rewriteCast` as a
// `CastWidths`. `rewriteCast` MUST use those captured widths — it must NEVER
// call `getSrcTy()` at rewrite time. The struct lives here (not in the
// driver's anonymous namespace) so the driver's `CastW` map and this lowerer
// share one definition — the same pattern that moved `isDataPositionCompare`
// into `CompareLowering.h`.
//
// The worked example (the measured-compare bridge): Clang emits
// `%c = icmp/fcmp …` → `%z = zext i1 %c to i32` → `cqrt_measure_i32(%z)`.
// Lowering the compare RAUWs `%c`(i1) to an i32 flag handle, so the `zext` is
// transiently `zext i1 <i32-value>`. Because its `(i1→i32)` widths were
// captured BEFORE that RAUW, cast lowering emits
// `cq_template_zext_i1_to_i32(flag)` and the driver erases the malformed
// `zext`. The bridge is correct ONLY because of up-front capture.
//
// The template is unary: `(i32 handle) → i32 handle` — the handle's ABI
// width changes but the SSA type stays i32 on both sides. The original
// cast's RESULT type may be non-i32 (e.g. `sitofp i32→f64` yields f64,
// `fptrunc f64→f32` yields f32); RAUW then replaces that non-i32 SSA value
// with the i32 handle — a cross-type RAUW, laundered by erasure exactly as
// CompareLowering launders the i1 flag (IMPLEMENTATION §1.2 / risk R2;
// verified clean on this assertions-OFF LLVM-19, guarded by the per-fixture
// `verify` RUN line).
//
// Each rewriter performs emit + RAUW + taint/BirthOrder bookkeeping but does
// NOT erase the original — the driver owns erase (the work list IS the set of
// originals). An unsupported cast pair (or an unsupported width, i.e. an
// empty captured `From`/`To`) emits the loud `diagnoseNoTemplate` and leaves
// the cast un-lowered (the driver then must not erase it). Casts are unary so
// there is no BirthOrder operand-ordering concern.

#ifndef CQ_IRPASS_CAST_LOWERING_H_
#define CQ_IRPASS_CAST_LOWERING_H_

#include "llvm/ADT/StringRef.h"

namespace llvm {
class CastInst;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Captured ABI widths for a tainted cast, recorded by the driver at
// COLLECTION time — before any rewrite RAUWs the operand and loses the source
// type (IMPLEMENTATION §1.3 / risk R1). Keyed by the `CastInst*` in the
// driver's `CastW` map and handed to `rewriteCast`. `From`/`To` are ABI-width
// strings ("i1"/…/"i64"/"f32"/"f64"); either is "" for an unsupported width.
struct CastWidths {
  llvm::StringRef From;
  llvm::StringRef To;
};

// Lower one tainted `CastInst` to its width-change template. `cw` carries the
// driver's collection-time-captured widths; `rewriteCast` uses `cw.From` /
// `cw.To` for the symbol and NEVER reads `getSrcTy()` at rewrite time (RAUW
// destroyed it). Returns true if the cast was rewritten (cross-type RAUW'd,
// bookkept) and is therefore safe for the driver to erase; false if it was
// diagnosed/left un-lowered (unsupported pair or width — the driver must NOT
// erase it). A lowered result is always an i32 handle.
bool rewriteCast(llvm::CastInst *cast, CastWidths cw, WidthDispatch &wd,
                 TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CAST_LOWERING_H_
