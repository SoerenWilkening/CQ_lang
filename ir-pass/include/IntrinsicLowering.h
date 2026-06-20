// IntrinsicLowering.h — lower curated reversible `llvm.*` idiom intrinsics to
// their `cq_template_<op>_<W>` ADDITIVE-PRODUCER templates (Phase 7.1 Increment
// E). Sibling of ArithLowering: the driver (OpcodeLowering) owns collection /
// ordering / erase; this TU owns the curated-set predicate, the per-intrinsic
// emit + RAUW + taint bookkeeping, and the shape/width gates.
//
// The curated set (PRD §2.6, owner full set) by mechanism class — every row
// carries a written adjoint proof (docs INTRINSIC_TABLE_CLEARANCE.md):
//   * Class 1 (bijection, fwd/inv/unc): bswap {i16,i32,i64} + bitreverse
//     {i8,i16,i32,i64} (involutions), fshl/fshr rotation {i8,i16,i32,i64}
//     (arg0==arg1, CONSTANT amount — rotate-back inverse).
//   * Class 2 (non-injective pure total, fwd/unc): smin/smax/umin/umax, abs,
//     ctpop, ctlz/cttz, uadd/usub/sadd/ssub.sat over {i8,i16,i32,i64}.
//     Reversible via the existing recompute-from-LIVE-sources `_unc` Bennett
//     spine (R-E source-liveness — Rule 8); ZERO new uncompute code.
//
// Lowered as additive producers (fresh out rail, sources preserved), mirroring
// ArithLowering::rewriteUnary/rewriteBinary EXACTLY, so the whole-DAG uncompute
// spine reverses them by the `cq_template_` prefix. The trailing i1 immarg flag
// of abs/ctlz/cttz is a CONSTANT dropped at lowering (the lowered op is the
// total reversible function; fwd and `_unc` use the same total f).
//
// EXCLUDED (the predicate returns false → driver leaves the call for the loud
// `kMsgUnknownCallee` escape decline): *.with.overflow ({iN,i1} aggregate),
// fp transcendentals, the general (x!=y) funnel shift, and any curated id at a
// width outside its table set. Membership is by EXACT `Intrinsic::ID`, NEVER by
// name prefix (the `cq_theta_evil` / `starts_with("llvm.")` hazard).

#ifndef CQ_IRPASS_INTRINSIC_LOWERING_H_
#define CQ_IRPASS_INTRINSIC_LOWERING_H_

namespace llvm {
class CallInst;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Is `CI` a curated reversible llvm.* idiom intrinsic this increment lowers?
// True iff: the callee is an IntrinsicInst with a curated `Intrinsic::ID`, its
// result width is in that id's table set (bswap excludes i8; all exclude i1 and
// the deferred i128), AND — for fshl/fshr only — it is the rotation form
// (arg0==arg1) with a CONSTANT amount. Used by BOTH the TaintPropagation
// escape-guard accept-skip and the OpcodeLowering enqueue, so the accept set and
// the lowered set are one predicate (no drift). Pure analysis; no mutation.
bool isCuratedReversibleIntrinsic(const llvm::CallInst *CI);

// Lower one curated intrinsic to its `cq_template_<op>_<W>` additive producer
// (emit + RAUW + taint/BirthOrder/HandleWidth bookkeeping). Returns true if
// rewritten (driver may erase); false if diagnosed/left un-lowered (driver must
// NOT erase). Precondition: isCuratedReversibleIntrinsic(CI) held at enqueue.
bool rewriteIntrinsic(llvm::CallInst *CI, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_INTRINSIC_LOWERING_H_
