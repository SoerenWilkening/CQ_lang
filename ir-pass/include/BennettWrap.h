// BennettWrap.h — the thin Bennett compute-copy-uncompute synthesizer (DD-3).
//
// Reuses existing primitives, mints NO new ABI (Rule 14): `cqrt_alloc_<W>` /
// `cqrt_copy_<W>` / `cqrt_free` from `WidthDispatch`, the `emitInverseChain`
// void `_unc` adjoint spine from `EmitInverse`. Over a clone's captured forward
// `cq_template_*` stream it emits, before the `ret`:
//   (a) `isInverseEmittable` pre-scan of the WHOLE stream → loud decline with NO
//       emission on the first un-invertible link (no half-reversed chain, C11);
//   (b) `out = cqrt_alloc_<W>(0)`; (c) `cqrt_copy_<W>(result_rail, out)` — copy
//       BEFORE the reverse (the reverse zeroes `result_rail` in place);
//   (d) `emitInverseChain` reverse-program-order adjoint; bool checked and
//       returned BEFORE any free;
//   (e) `cqrt_free` each `ScratchRails` entry (every forward result, incl. the
//       result rail, zeroed by (d)) — ONLY after (d) returns true; `out` escapes
//       via `ret`, never freed; borrowed params are read-only, never freed.
// The copy-out is sound iff the clone return is basis-valued, GUARANTEED by the
// `cq_*` body rejection (DD-3 (c′), Rule 7) — a pure-classical body has no phase.
//
// `ResultRail` is null when the clone return is NOT tainted (a classical
// no-output / classical-derived return): then only (a)+(d)+(e) run (uncompute
// any tainted scratch, keep the classical `ret`). Returns `false` (loud-declined)
// on a pre-scan failure or a half-reversed chain.

#ifndef CQ_IRPASS_BENNETT_WRAP_H_
#define CQ_IRPASS_BENNETT_WRAP_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"

namespace llvm {
class CallInst;
class Function;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

bool emitBennettWrap(llvm::Function &Clone,
                     llvm::ArrayRef<llvm::CallInst *> ForwardStream,
                     llvm::Value *ResultRail,
                     llvm::ArrayRef<llvm::Value *> ScratchRails,
                     llvm::StringRef RetAbiWidth, WidthDispatch &wd,
                     TaintSet &cloneTaint);

}  // namespace cq

#endif  // CQ_IRPASS_BENNETT_WRAP_H_
