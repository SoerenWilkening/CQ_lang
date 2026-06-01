// CompareLowering.h — Lower tainted data-position `CmpInst` (`icmp`/`fcmp`)
// to compare templates. Split out of `OpcodeLowering` in Phase 3 (PRD §1,
// IMPLEMENTATION §3/§5.2): the driver owns collection / ordering / erase;
// this TU owns the data-position gate, operand-shape classification, the
// predicate-flip canonicalization, the emit + cross-type RAUW + taint
// bookkeeping.
//
// The flag-handle invariant (IMPLEMENTATION §1.2): a tainted compare lowers
// to a template that returns an `i32` flag handle (logically 1-qubit),
// NEVER an `i1`. RAUW therefore replaces the `i1` compare result with an
// `i32` handle — a cross-type RAUW, laundered by erasure: every user of the
// compare result is itself tainted (a measured compare carries Clang's own
// `zext i1→i32` bridge), hence itself lowered to a call consuming the i32
// handle and then erased, so the transient mistyped instruction never
// reaches the verifier. Verified clean on this assertions-OFF LLVM-19
// (risk R2); a `verify` RUN line on every compare fixture guards it.
//
// Operand shape (PRD §2.4):
//   * One tainted, one classical: classical on the RIGHT → `_hl(handle,
//     classical)`; classical on the LEFT → `flipPredicate` (so the handle
//     moves left) then `_hl(handle, classical)`. There are NO `_lh` compare
//     templates — the literal-on-left case is always a predicate flip
//     (e.g. `5 < x` ⇒ `x > 5` ⇒ `icmp sgt _hl(handle, 5)`).
//   * Q+Q (both tainted): UNSUPPORTED in Phase 3 — diagnosed loudly via
//     `diagnoseNoTemplate` and left un-lowered. The logical width is
//     genuinely unrecoverable post-rotation-lowering (both operands are
//     i32-laundered handles, so there is no classical operand to read a real
//     width from); falling back to a laundered i32 width would silently emit
//     a wrong/nonexistent symbol. Deferred to a later phase.
//
// Width is the ABI width of the OPERAND type (the i1 result type would be
// wrong), read from the classical operand. `op` ∈ {"icmp","fcmp"}; `pred` =
// `getPredicateName(getPredicate())`.
//
// Data-position gate (PRD §2.8, risk R3): a compare is lowered ONLY when its
// result is in pure data/measure position. A result feeding a `br i1` *or* a
// `select i1` condition (even partially) is left UNTOUCHED — it stays the
// original `i1`, IR stays well-typed, and the flag handle never reaches a
// terminator. Such a compare is owned by Phase 4.

#ifndef CQ_IRPASS_COMPARE_LOWERING_H_
#define CQ_IRPASS_COMPARE_LOWERING_H_

#include "llvm/ADT/StringRef.h"

namespace llvm {
class CmpInst;
class Instruction;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// A tainted compare is lowered ONLY when its result is in pure data/measure
// position: no user is a `BranchInst`, nor a `SelectInst` using it as the
// condition (PRD §2.8, risk R3). A branch/select-feeding compare is left
// untouched (owned by Phase 4). The driver calls this to GATE compare
// collection — a gated-out compare is never enqueued, hence never rewritten
// or erased.
bool isDataPositionCompare(llvm::CmpInst *cmp);

// Lower one tainted, data-position `CmpInst` to its compare template.
// Returns true if the op was rewritten (cross-type RAUW'd, bookkept) and is
// therefore safe for the driver to erase; false if it was diagnosed/left
// un-lowered (unsupported width, or an unsupported Q+Q compare — the driver
// must NOT erase it). literal-on-right→`_hl`; literal-on-left→`flipPredicate`
// + `_hl` (no `_lh` compares); Q+Q→diagnosed unsupported. A lowered result is
// always an i32 flag handle.
bool rewriteCompare(llvm::CmpInst *cmp, WidthDispatch &wd, TaintSet &taint);

// Mint the compare-template flag for `cmp` WITHOUT touching `cmp` itself
// (Phase 4 control path; PRD §2.3, IMPLEMENTATION §5.2). Extracted from
// `rewriteCompare`'s flag-minting guts so the data path and the control path
// share one symbol/predicate-flip implementation: it classifies operands by
// taint, applies the literal-on-left predicate flip, and emits the i32 flag
// call `cq_template_icmp_<pred>_<W>_hl[_inv](handle, classical)` (HL only —
// there are no `_lh` compares). Returns the i32 flag `Value*`, or nullptr on
// an unsupported width / unsupported Q+Q (diagnosed loudly, like the data
// path). Unlike `rewriteCompare` it does NOT RAUW or bookkeep `cmp` — the
// original compare survives until linearization erases it, keeping the
// `br i1` well-typed at the WP boundary (§1.3).
//
//   * `qqWidth` empty → HL-only (the WP3 / Phase-3 behavior): a Q+Q compare
//     is unsupported and returns nullptr.
//   * `qqWidth` set (a Q+Q control condition, PRD §2.4) → emit the HH
//     template `cq_template_icmp_<pred>_<W>` at that width. (Forward seam for
//     WP6; unused by WP3.)
//   * `inverse` → spell the `_inv` twin for the flag UNCOMPUTE (§1.5).
//
// The insertion point is `before` when non-null, else immediately before
// `cmp` (the forward compute). For the uncompute, callers pass the region's
// post-body insertion point.
llvm::Value *lowerCompareToFlag(llvm::CmpInst *cmp, WidthDispatch &wd,
                                TaintSet &taint, llvm::StringRef qqWidth = {},
                                bool inverse = false,
                                llvm::Instruction *before = nullptr);

}  // namespace cq

#endif  // CQ_IRPASS_COMPARE_LOWERING_H_
