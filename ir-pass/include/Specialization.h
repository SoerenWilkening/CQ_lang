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

// bd `test_C_libtooling-vsfp` (P1) — THE PHANTOM-READ POSTCONDITION, the observing
// half of `dropDeadCallArguments` (SpecializeDetect.h). After `specialize()`, a
// call in a NON-clone function to a function the specializer built, passing in a
// slot the specializer RECORDED as dead in the built clone
// (`isRecordedDeadSlot`: `taint.SpecDeadArgMask`, taken by `buildClone` with the
// pass's ONE liveness predicate, `DeadValueLiveness.h`) a caller-side QUANTUM
// value (tainted, or a rail a control emitter minted — round-1 and round-2
// `%out`s included) that nothing else keeps alive, is a read only the compiler
// performs: that value's rail is kept alive for a callee that never looks at it,
// which is how a which-path rail the hand-inlined twin never computes stays
// entangled across a later non-diagonal gate (bd vsfp's silent dephasing). Fires
// `cq specialization: quantum argument to a parameter the lifted callee never
// reads` (DS_Error, source-located on the call) and returns true.
//
// "NOTHING ELSE KEEPS IT ALIVE" (bd vsfp r1B F-VB-4, `v12`): a value some other
// LIVE instruction reads, a user's `cq_measure`/`cq_theta` arg-0 reads, a `ret`
// returns, or a clone reads in a slot it does NOT ignore, is live for a reason of
// its own — the twin keeps it too, and the phantom read adds nothing. Runtime
// `cqrt_*`/`cq_template_*` calls are not counted as keepers (an emitter's copies
// into a `%out` rail are writes); the over-decline that leaves is named in
// TRACK_VSFP §4. The one exemption is a `cq_theta` RESULT operand (validated by
// Rule-13 r1B on nine shapes; its argument is at the definition).
//
// ⚠ WHAT IT IS NOT (L7; round 1 called it "TOTAL"). It observes phantom reads
// THROUGH A CLONE CALL. A dead operand kept alive by something that is not a
// clone call — a dead intrinsic, a dead φ cycle — is not its population; those
// are the dead-argument drop's (`deleteDeadCones`, the same predicate). And round
// 1's stated C customer, `volatile int z = a;` in the callee, was attributed to
// "the clone pipeline" when it was the MODULE pre-pass
// `eraseDeadVolatileScalarStores` acting on the ORIGINAL callee (r1B F-VB-3):
// since round 2 the drop's slot B predicts it, so that program lowers to its
// fenv-intended twin instead of declining. What reaches this fence now is a slot
// the CLONE's own pipeline made dead (its scoped PredMux flatten), or one a drop
// precondition refused (a `range`-less custom attribute, a `naked` or
// interposable callee cannot reach here — those callees decline at spec).
// Clone BODIES are not scanned: every rail an inner call there could keep alive
// is uncomputed by the enclosing Bennett wrap before the clone returns.
bool declinePhantomCloneArgReads(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZATION_H_
