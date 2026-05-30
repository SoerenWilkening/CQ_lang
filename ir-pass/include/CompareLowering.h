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

namespace llvm {
class CmpInst;
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

}  // namespace cq

#endif  // CQ_IRPASS_COMPARE_LOWERING_H_
