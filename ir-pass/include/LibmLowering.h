// LibmLowering.h — lower curated DIRECT-libm math.h calls to their
// `cq_template_<…>` ADDITIVE-PRODUCER templates (bd 3c6m.2). Sibling of
// IntrinsicLowering: the driver (OpcodeLowering) owns collection / ordering /
// erase; this TU owns the curated NAME-set predicate, the per-call emit + RAUW
// + taint bookkeeping, and the shape/width gates.
//
// WHY A SEPARATE MODULE FROM IntrinsicLowering: clang -O1 leaves these math.h
// functions as DIRECT `@<name>` calls (NOT `@llvm.*` intrinsics), so they carry
// no `Intrinsic::ID` — recognition is by EXACT function NAME (a declaration-only
// libc extern), NEVER a name prefix (the `cq_theta_evil` hazard) and NEVER a
// prefix of `llvm.`. The one cross-width family clang DOES intrinsify
// (lrint/llrint/lround/llround → `@llvm.lrint.i64.f<W>`) is recognized in
// IntrinsicLowering; it shares this table's cross-width TEMPLATE surface only.
//
// The curated set (tools/libm_table.yaml, FROZEN ABI) by shape:
//   * same_unary  (fp→fp):        cbrt erf erfc tgamma lgamma expm1 log1p logb
//                                  acosh asinh atanh — `cq_template_<op>_<W>`.
//   * same_binary (fp,fp→fp):     atan2 remainder nextafter fdim (non-comm) +
//                                  hypot (comm) — `cq_template_<op>_<W>[_hl|_lh]`.
//   * cross_unary (fp→int):       ilogb — reuses the CAST naming
//                                  `cq_template_<op>_<from>_to_<to>` (a1/ua1).
//   * mixed_binary ((fp,int)→fp): ldexp scalbn (int exp) + scalbln (long exp) —
//                                  `cq_template_<op>_<wa>_<wb>[_hl|_lh]`.
//
// All are Class-2 non-injective pure-total producers lowered as additive
// producers (fresh out rail, sources kept LIVE), so the whole-DAG uncompute
// spine reverses them by the `cq_template_` prefix with ZERO new uncompute code
// (EmitInverse mints each `_unc` twin by string-append + operand-type copy, so
// cross-width / mixed-arg round-trip for free). The fp result is DATA, never a
// rotation angle: a tainted result reaching a rotation arg-1 STILL loud-declines,
// enforced UPSTREAM by declineTaintedAngle (RotationLowering runs before
// lowerOps), NOT here — the angle fence is positional and producer-agnostic.

#ifndef CQ_IRPASS_LIBM_LOWERING_H_
#define CQ_IRPASS_LIBM_LOWERING_H_

namespace llvm {
class CallInst;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Is `CI` a curated DIRECT-libm math.h call this increment lowers? True iff: a
// DIRECT CallInst to a DECLARATION-only libc extern whose EXACT name is in the
// curated set (both the `double` and the `…f` `float` spelling), carrying NO
// operand bundles, whose arity/result-type/operand-widths (read from the CALLEE
// signature — never laundered) match the curated shape at a supported width.
// Purely STRUCTURAL — no taint read, so it returns the SAME verdict at both
// phases it runs (the TaintPropagation escape-guard accept-skip PRE-lowering AND
// the OpcodeLowering enqueue/rewrite POST-RotationLowering); the accept set and
// the lowered set are one predicate (no drift). Pure analysis; no mutation.
bool isLibmCall(const llvm::CallInst *CI);

// Lower one curated libm call to its `cq_template_<…>` additive producer (emit
// + RAUW + taint/BirthOrder/HandleWidth bookkeeping). Returns true if rewritten
// (driver may erase); false if diagnosed/left un-lowered (driver must NOT
// erase). Precondition: isLibmCall(CI, taint) held at enqueue.
bool rewriteLibmCall(llvm::CallInst *CI, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_LIBM_LOWERING_H_
