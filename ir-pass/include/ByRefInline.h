// ByRefInline.h — inline the producer of a VISIBLE user by-ref out-param (bd g7ip).
//
// The GENERAL by-ref pointer-out-param capability that g387 (curated OPAQUE libm)
// does not cover: a user function `void f(v…, T* out)` whose body we can SEE,
// called with a tainted value arg, `*out = g(v…)`, then the caller reads `*out`
// back. CQ taint is a pure SSA use-def property (it never crosses the out-cell's
// memory), so the read-back load is not tainted even though it is a function of
// the quantum input.
//
// ARCHITECTURE A (owner decision 2026-07-01, over the issue's clone-on-taint +
// in-body Shadow store): since the out-cell is a single-write/single-read fresh
// SCALAR with a CLASSICAL address (only the VALUE is quantum), the reversible
// store→load round-trip ALGEBRAICALLY COLLAPSES — so we simply INLINE the
// callee's pure store-value expression into the caller and RAUW the read-back
// load. The result is byte-identical to the IR clang -O1 emits when the helper
// inlines (already lowering), so it flows through the normal propagate/lowerOps
// path with ZERO clone/Shadow/ABI machinery. See `bd memories
// g7ip-inline-producer-design`, [[g387-byref-math-design]], [[bennett-parity-map]].
//
// ACCEPT-ONLY / ADDITIVE: a call is rewritten ONLY when BOTH the callee body and
// the caller cell pass a TOTAL structural proof (drop nothing — miss-safety is
// STRUCTURAL, Prime Directive). Any off-pattern shape is left UNTOUCHED and falls
// through to the EXISTING loud declines (the specializer's "…(memory access)" or
// the escape guard), so this stage introduces NO new decline strings and a
// skipped call can never silent-miscompile.

#ifndef CQ_BYREF_INLINE_H
#define CQ_BYREF_INLINE_H

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Inline every provable VISIBLE-body by-ref producer whose out-param is written
// through a classical scalar cell, over ≥1 tainted value arg. Returns true iff it
// rewrote ≥1 call (the caller re-`propagate`s and re-runs — a FIXPOINT, so a
// nested by-ref producer whose input is another inlined producer is lowered on a
// later pass). Runs AFTER the g387 by-ref fixpoint and BEFORE
// detectSpecializations, so a provable shape is canonicalized to plain SSA before
// the specializer/escape guard ever sees it.
bool lowerByRefInline(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_BYREF_INLINE_H
