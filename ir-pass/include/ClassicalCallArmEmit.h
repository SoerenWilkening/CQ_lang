// ClassicalCallArmEmit.h — The mutating emitter for an accepted 6.5
// classical-call-under-quantum-control region (DD-7, PRD §2.13).
//
// A pure classical call (all-classical-args) inside a tainted-condition
// `br`-diamond arm runs CLASSICALLY — it is pure, so executing it unconditionally
// and discarding it on the inactive branch is observationally inert — and its
// i32 result is merged into the controlled register by the SAME controlled-XOR
// copy merge `SelectMergeEmit` uses for a tainted-condition `select` (4.4). NO
// clone, NO cswap/route, NO reverse-play, NO input-tainting, NO qubit allocation
// for the classical data (only the `|0>` out rail joins `taint.Tainted`).
//
// Two distinct reuses, kept separate (DD-7):
//   (1) the MERGE MECHANICS are verbatim `SelectMergeEmit` — `materializeCopySource`
//       + `copyControlledFn` + the ¬flag `cqrt_x` bracket + the `icmp_inv` strip +
//       the single `cqrt_free`;
//   (2) the INSERTION/CFG handling follows the VALUE-ARM / `RegionFlatten`
//       precedent — HOIST the call into `Pred`, emit before the conditional `br`,
//       capture block identities before the first erase (the block-lifetime
//       SIGSEGV class), then FLATTEN the diamond — NOT the select's inline
//       no-CFG path (the 6.5 region is a real diamond with a merge `φ`).
//
// Emitted into `Pred` before the conditional `br`, in this EXACT order (symbol
// order IS the contract; the §16.3 ¬flag-bracket hazard is verify-clean-invisible):
//
//   0 hoist       move the pure call to just before the `br` (inert)
//   1 mint        cq_template_icmp_<pred>_<Wc>_hl(q, k)              -> %f
//   2 rail        %out = cqrt_alloc_<Wd>(0)
//   3 true copy   cqrt_copy_<Wd>_controlled(%f, materialize(True),  %out)  (f=1)
//   4 ¬flag copy  cqrt_x(%f); cqrt_copy_<Wd>_controlled(%f, materialize(False), %out); cqrt_x(%f)
//   5 strip+free  cq_template_icmp_<pred>_<Wc>_hl_inv(q, k); cqrt_free(%f)
//   6 rewire      RAUW %phi -> %out; scrub; erase; FLATTEN the diamond
//
// `True`/`False` are the merge values on the cond-TRUE / cond-FALSE edges,
// oriented by `R.ArmNegated` (clang -O1 may make the gate arm the FALSE
// successor, Rule 9): un-negated diamond ⇒ True = the call result (arm edge),
// False = `q` (Pred edge); negated ⇒ swapped. The tainted `q` materializes to
// itself (identity); the classical call result materializes to a fresh
// `cqrt_alloc_<Wd>` handle. Exactly ONE `cqrt_free` (the flag, provably `|0>`
// after the strip — the copies write `%out`, never `q`); `%out`, `q`, the
// materialized scratch, and the hoisted call are LEFT ALLOCATED (Rule 6/8). The
// fp/i128 RESULT gate is the `copyControlledFn(Wd)` non-null check here (the
// f64-trap, DD-7) — an fp merge declines loudly, never mints dead ABI.
//
// Dispatched from `SwapRouteEmit::lowerControlRegions` on
// `R.Kind == ClassicalCallArm`. Runs BEFORE `lowerRotations` (the merge `φ` +
// the call still carry their real logical types, so `abiWidthFromType` is
// reliable — not the post-RAUW i32-laundering trap).

#ifndef CQ_IRPASS_CLASSICAL_CALL_ARM_EMIT_H_
#define CQ_IRPASS_CLASSICAL_CALL_ARM_EMIT_H_

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct ControlRegion;
struct TaintSet;

// Lower one accepted `ClassicalCallArm` region (`R.Merge` the 2-incoming merge
// `PHINode`, `R.Condition` its `CmpInst`, `R.Pred`/`R.Arm`/`R.MergeBB` the diamond
// CFG, `R.ArmNegated` the Rule-9 polarity) to the controlled-XOR copy merge over a
// flattened diamond. Mutates the module IR and `taint`. A malformed plan or an
// fp/i128 merge width (no `cqrt_copy_<W>_controlled`) declines LOUDLY and lowers
// nothing (Rule 1) — never a silent skip of quantum-controlled flow.
void emitClassicalCallArmRegion(const ControlRegion &R, WidthDispatch &wd,
                                ControlledSymbols &csyms, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CLASSICAL_CALL_ARM_EMIT_H_
