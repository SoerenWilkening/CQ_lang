// QramIndexWidth.h — every QRAM index rail has LOGICAL width 32.
//
// Every `cqrt_qram_load_<W>` / `cqrt_qram_store_<W>[_controlled]` (forward and
// `_unc`) takes its index as an i32 handle whose rail is 32 bits wide
// (`runtime/cq_runtime.h`, QRAM section preamble; libcqops handoff b6a,
// 2026-09-28). The `<W>` suffix names only the CELL width, so the index width
// is fixed by contract, not by the symbol.
//
// TWO HALVES, BECAUSE A CAST RAIL MUST NOT OUTLIVE ITS CALL. The narrowing
// `cq_template_trunc_<W>_to_i32` (or re-extending `sext`/`zext`) is a CNOT copy
// of the index register. Minted once and kept until the access is reversed,
// it is a live derived record: a later non-diagonal gate on the index register
// acts on a register entangled with the copy (wrong unitary), and a store is
// often never reversed at all. So:
//   1. `resolveQramIndex` (at the two emitters) strips the -O1 widening cast,
//      decides the cast from the LOGICAL width while the IR type still says it,
//      and hands back the stripped index. The emitter passes that index to the
//      QRAM call exactly as before and `tagQramIndexCast` records the decision
//      on the call (`!cq.qram.idxcast`), which `emitInverseCall` copies onto
//      each `_unc` it mints from that call. Everything up to `uncompute` sees
//      the pre-b6a IR.
//   2. `bracketQramIndexCasts` runs after `uncompute` and wraps EACH QRAM call,
//      forward and `_unc`, in its own `t = cast(idx); call(.., t, ..);
//      cast_unc(t, idx); cqrt_free(t)`. Only the QRAM call runs between the
//      cast and its `_unc`, and it only reads `t`, so `t` is |0⟩ again at the
//      free and is never live across any other gate.
//
// Why a trunc is exact: the array count N is an i32 (`cqrt_qram_alloc_<W>`'s
// `count`), so every in-bounds index fits in 32 bits. An out-of-bounds index is
// source UB (top-level reads) or excluded by the pass's own bound (the
// under-control claim's proof-or-mask, the Bennett-clone fence).

#ifndef CQ_IRPASS_QRAM_INDEX_WIDTH_H_
#define CQ_IRPASS_QRAM_INDEX_WIDTH_H_

#include "llvm/ADT/StringRef.h"

namespace llvm {
class CallInst;
class Instruction;
class Module;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;
class WidthDispatch;

// The resolved index of one QRAM access.
struct QramIndex {
  llvm::Value *Idx = nullptr;             // the index the call takes (stripped)
  llvm::Instruction *DeadCast = nullptr;  // stripped one-use cast to erase
  llvm::StringRef CastOp;                 // "trunc"/"sext"/"zext", or empty
  llvm::StringRef FromW;                  // Idx's logical width when CastOp set
};

// The pre-emission check: true iff the index resolves to the i32 width; else a
// loud diagnostic at `At`. `processShadowAlloca` asks it for every access before
// emitting any, so a failing access never leaves an alloca half-lowered on a
// host that does not exit on `DS_Error`.
bool checkQramIndexWidth(llvm::Value *GepIdx, llvm::Instruction *At,
                         TaintSet &taint);

// Resolve the access gep's trailing operand `GepIdx`:
//   * a `sext`/`zext` over a tainted operand is stripped (the -O1 widening);
//   * logical width 32 (the `HandleWidth` record wins over a laundered i32
//     type) -> no cast;
//   * wider -> `trunc`; narrower -> the stripped cast's own kind, else `sext`
//     (GEP sign-extends a narrow index).
// Returns `Idx == nullptr` after the loud diagnostic when no in-scope cast
// reaches i32 (the caller skips the access). Emits nothing.
QramIndex resolveQramIndex(llvm::Value *GepIdx, llvm::Instruction *At,
                           TaintSet &taint);

// Record `R`'s cast decision on the QRAM call `Q` the emitter just minted;
// `Slot` is the index operand (1 for load/store, 2 for the guarded store).
void tagQramIndexCast(llvm::CallInst *Q, unsigned Slot, const QramIndex &R);

// `emitInverseCall`'s hook: the `_unc` it just minted from `Forward` inherits
// `Forward`'s tag, so the reversal is bracketed with its OWN forward's cast
// (never another access's that happens to share the callee and index value —
// round-2 review G1: a `sext` and a `zext` of one i8 under two guards).
void inheritQramIndexTag(const llvm::CallInst *Forward, llvm::CallInst *Inv);

// At pass entry, before either emitter runs: drop any `!cq.qram.idxcast` the
// INPUT carries. The tag is compiler-owned; a forged one on, say, a classical
// call would otherwise be bracketed as if it were a QRAM index (round-3 H1).
void stripForeignQramIndexTags(llvm::Module &M);

// After `uncompute`, before the literal-integrity guard: bracket every tagged
// QRAM call (forward, or a `_unc` that inherited its forward's tag) and drop
// the tags. Returns true if it changed the module.
bool bracketQramIndexCasts(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_QRAM_INDEX_WIDTH_H_
