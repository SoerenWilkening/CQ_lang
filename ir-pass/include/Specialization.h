// Specialization.h — the Phase 6 specialization driver + the `:419` carve-out's
// membership predicate.
//
// `specialize()` is the step-14 stage (between `declineClassicalMuxes` and — via
// the bd d88e lift re-ask and the bd 2qyz stale re-sweep — `lowerRotations`,
// DD-1): it DRAINS the already-classified `SpecPlan.Pending`,
// and per Accept candidate clones → seeds a FRESH disjoint `cloneTaint` → drives
// the clone through the scoped data lowering → captures the forward stream →
// Bennett-wraps → retargets via `setCalledFunction`, deduping clones by
// `(callee, mask)` (C7). After the drain it re-marks each retargeted call result
// into the ORIGINAL `taint.Tainted` per `SpecRecord.ReturnTainted` (§2.7,
// C-Taint) — scrubbing the conservative call-result taint when the clone proves
// a classical return. It NEVER calls `uncompute` (the single module-wide
// uncompute at `:115`/`:174` owns reversal; the clone bodies are invisible to it
// because `cloneTaint` is never unioned into `taint`, DD-2).
//
// `shouldSpecialize` is the thin pure plan-membership lookup the carve-out
// consults (no second classifier — Rule 14).

#ifndef CQ_IRPASS_SPECIALIZATION_H_
#define CQ_IRPASS_SPECIALIZATION_H_

namespace llvm {
class CallInst;
class Module;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct SpecPlan;

void specialize(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
                SpecPlan &plan);

// True iff `CI` is a proven-Accept site in `plan.Pending` (the carve-out
// suppresses `kMsgUnknownCallee` for it). The carve-out ALSO suppresses for
// `plan.Diagnosed` sites (already loud-declined with a specialization message);
// that check lives at the carve-out, not here.
bool shouldSpecialize(const llvm::CallInst *CI, const SpecPlan &plan);

// bd `test_C_libtooling-vsfp` (P1) — THE PHANTOM-READ POSTCONDITION, the total
// half of `dropDeadCallArguments` (SpecializeDetect.h). After `specialize()`, a
// call in a NON-clone function to a function the specializer built
// (`taint.SpecHandleArgMask`, its own record — never the `__cq_q_` name) that
// passes a TAINTED operand in a slot whose parameter the built body has NO USES of
// is a read only the compiler performs: the operand's rail is kept alive for a
// callee that never looks at it, which is how a which-path rail the hand-inlined
// twin never computes stays entangled across a later non-diagonal gate (bd
// vsfp's silent dephasing). Fires `cq specialization: quantum argument to a
// parameter the lifted callee never reads` (DS_Error, source-located on the
// call) and returns true.
//
// It OBSERVES rather than predicts: it reads the BUILT clone's parameters, so a
// use the clone pipeline removed after the drop ran (a dead read PredMux's sweep
// or `lowerCloneSelect`'s tree erase took) is caught too. It says nothing about
// a slot the clone DOES read (a spec-quantum clone, or a classical-verdict clone
// whose body computes from the argument and Bennett-reverses it) — that read is
// real, and the hand-inlined twin performs it as well. Clone BODIES are not
// scanned: every rail an inner call there could keep alive is uncomputed by the
// enclosing Bennett wrap before the clone returns.
bool declinePhantomCloneArgReads(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZATION_H_
