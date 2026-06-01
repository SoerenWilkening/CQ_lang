// FlagConjunction.h — Combine two control flags into ONE fresh flag, the
// single code path shared by `&&`, `||`, and nesting (PRD §2.5/§2.7,
// IMPLEMENTATION §5.3). Every controlled op downstream is controlled by the
// SINGLE resulting flag (§1.2) — there is no doubly-controlled symbol;
// multi-condition control is always built upstream into one flag.
//
// The flag is Phase 4's own region-scoped ancilla, bracketed compute +
// uncompute, LIFO for nests (§1.5/§2.9). `combineFlags` emits the forward
// compute and returns the fresh combined flag; `uncombineFlags` emits the
// exact mirror-image uncompute (the operand order is correctness-critical and
// is fixed by the table below).
//
//   AND  : f = cqrt_alloc_i1(0); cqrt_toffoli(fa, fb, f)
//          uncompute: cqrt_toffoli_inv(fa, fb, f)
//   OR   : De Morgan, a||b = ¬(¬a ∧ ¬b):
//          f = cqrt_alloc_i1(0);
//          cqrt_x(fa); cqrt_x(fb); cqrt_toffoli(fa, fb, f);
//          cqrt_x(f); cqrt_x(fa); cqrt_x(fb)
//          uncompute (reverse): cqrt_x(fb); cqrt_x(fa); cqrt_x(f);
//                               cqrt_toffoli_inv(fa, fb, f);
//                               cqrt_x(fb); cqrt_x(fa)
//   nest : identical to AND, combining the enclosing flag with the inner
//          region's own condition flag into `f_both`.
//
// The X-bracket on fa/fb restores them to their original value (so the
// sub-flags are clean for their own uncompute); the single X on f is what
// turns the AND into an OR. `cqrt_alloc_i1` is minted via
// `WidthDispatch::allocFn("i1")`, `cqrt_toffoli[_inv]` via
// `ControlledSymbols::toffoliFn`, and `cqrt_x` via `ControlledSymbols::xFn`.

#ifndef CQ_IRPASS_FLAG_CONJUNCTION_H_
#define CQ_IRPASS_FLAG_CONJUNCTION_H_

#include "ControlPlan.h"  // cq::ControlRegion::ConjKind

namespace llvm {
class Instruction;
class Value;
}  // namespace llvm

namespace cq {

class ControlledSymbols;
class WidthDispatch;

// Emit the forward flag-combination compute and return the fresh i32 combined
// flag `f` (a `cqrt_alloc_i1(0)` ancilla driven by `cqrt_toffoli`). `kind`
// selects AND vs OR (nesting uses AND). All emitted ops are inserted before
// `before` (the same insertion point as the sub-flag compute, so the combined
// flag is computed right after its inputs). Returns nullptr if a required
// symbol is unavailable (`cqrt_alloc_i1` / `cqrt_toffoli` — diagnosed by the
// caller). `kind == ConjNone` is a programming error and also returns nullptr.
llvm::Value *combineFlags(llvm::Value *fa, llvm::Value *fb,
                          ControlRegion::ConjKind kind, ControlledSymbols &csyms,
                          WidthDispatch &wd, llvm::Instruction *before);

// Emit the uncompute for a flag previously produced by `combineFlags(fa, fb,
// kind, …)`, the exact mirror image of the compute (the LIFO bracket, §1.5).
// `f` is the combined flag returned by `combineFlags`; `fa`/`fb` are the same
// two sub-flags. All ops are inserted before `at`. No-op if `kind` is
// `ConjNone` or any operand is null.
void uncombineFlags(llvm::Value *fa, llvm::Value *fb, llvm::Value *f,
                    ControlRegion::ConjKind kind, ControlledSymbols &csyms,
                    llvm::Instruction *at);

}  // namespace cq

#endif  // CQ_IRPASS_FLAG_CONJUNCTION_H_
