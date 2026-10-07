// BennettWrap.h — the Bennett compute-copy-uncompute synthesizer (DD-3) for a
// lifted clone.
//
// Reuses existing primitives, mints NO new ABI (Rule 14): `cqrt_alloc_<W>` /
// `cqrt_copy_<W>` / `cqrt_free` from `WidthDispatch` and the `emitInverseCall`
// adjoint spine from `EmitInverse`. Since bd p3kd.7.8 (owner ruling
// owner-ruling-clone-reversal-mechanical-2026-10-07) it is a MECHANICAL reverse of
// EVERY runtime gate of the clone's single-block body, not of a curated stream:
// main's control chain now runs on the clone and its emitters mint condition
// flags, Toffoli networks, controlled copies into a merge rail, and strip and
// free their own flags inline. Before the `ret` it emits:
//   (a) a pre-scan of the whole body: every call must be a gate this reverse
//       knows (below), else a loud decline with NO emission;
//   (b) `out = cqrt_alloc_<W>(0)`; (c) `cqrt_copy_<W>(result_rail, out)` — copy
//       BEFORE the reverse (the reverse zeroes `result_rail` in place);
//   (d) the body's gates in reverse program order, each replaced by its adjoint
//       through `emitInverseCall`: a template / QRAM load / inner clone call by its
//       void `_unc`/twin, an involution (x, toffoli, cnot, controlled copy, …) by
//       itself. Main's emitters strip and free their own flags inline; inside a
//       clone those strips are ELIDED first (`elideForwardStrips`: a gate that
//       writes only rail R after R's last read, plus R's free), so the reverse is
//       the exact operand-identical mirror and stage 2b pairs every adjoint. A strip
//       the elision cannot prove deletable fails loudly (no measured input has one);
//   (e) `cqrt_free` of every rail the forward minted, in program order (the
//       pre-p3kd.7.8 order for a pre-p3kd.7.8 body), once (d) zeroed it. `out`
//       escapes via `ret`, never freed; borrowed params are never freed; a
//       non-zero / runtime-valued alloc is a `|v>` product rail and stays
//       allocated (R5: only a provably-`|0>` rail is freed).
// The copy-out is sound iff the clone return is basis-valued, GUARANTEED by the
// `cq_*` body rejection (DD-3 (c′), Rule 7) — a pure-classical body has no phase.
//
// `ResultRail` is null when the clone return is NOT tainted: then only the
// reverse and the frees run. `LiftedCalls` are the inner clone calls whose result
// is a register (they have a twin); any other inner clone call restored its
// inputs and is classical here. Returns `false` (loud-declined) when the body is
// not one block ending in `ret`, or holds a call the reverse cannot invert.

#ifndef CQ_IRPASS_BENNETT_WRAP_H_
#define CQ_IRPASS_BENNETT_WRAP_H_

#include "llvm/ADT/SmallPtrSet.h"
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
                     const llvm::SmallPtrSetImpl<llvm::CallInst *> &LiftedCalls,
                     llvm::Value *ResultRail, llvm::StringRef RetAbiWidth,
                     WidthDispatch &wd, TaintSet &cloneTaint);

}  // namespace cq

#endif  // CQ_IRPASS_BENNETT_WRAP_H_
