// ByRefMath.h — canonicalize tainted by-ref libm math calls (bd g387).
//
// frexp/modf/remquo return one value AND write a SECOND result through a pointer
// out-param. CQ taint is a pure SSA use-def property (it never crosses memory),
// so the read-back load of the out-cell — and its whole downstream — is NOT
// tainted even though it is a function of the quantum input. `lowerByRefMath`
// closes that gap WITHOUT touching the propagation core: it recognizes the
// (alloca-cell, by-ref call, load) triple and rewrites it into two synthetic
// `@cq_byref_*` MARKER calls (a primary + a secondary producer) over the SAME
// live fp source(s), erasing the cell. The markers are ordinary curated libm
// calls (LibmLowering kLibmTable), so a subsequent re-propagate flows taint to
// the whole downstream via the normal mechanism, and lowerOps lowers the markers
// to `cq_template_*` producers. Off-pattern cells decline LOUDLY (Prime
// Directive). See docs/prd/phase-07-expressiveness/g387-byref-math/PRD.md and
// `bd memories g387-byref-math-design`.

#ifndef CQ_BYREF_MATH_H
#define CQ_BYREF_MATH_H

namespace llvm {
class Module;
class CallInst;
}  // namespace llvm

namespace cq {

struct TaintSet;
class WidthDispatch;

// True iff `CI` is a DIRECT call to a by-ref math libc extern (frexp/modf/remquo
// and their f/l spellings), by EXACT name. Used by `declineTaintEscapes` to
// carve these names (they are owned by `lowerByRefMath`, which has already
// emitted the loud decline for any off-pattern cell) so the generic
// kMsgUnknownCallee never double-fires.
bool isByRefMathCall(const llvm::CallInst *CI);

// Canonicalize every QUANTUM by-ref math call (fp arg tainted per `taint`) with
// a valid out-cell shape into `@cq_byref_*` marker calls; erase the cell.
// Off-pattern cells decline loudly. Returns true iff the IR changed — the caller
// MUST then re-run `propagate` so the markers' downstream is re-tainted.
bool lowerByRefMath(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_BYREF_MATH_H
