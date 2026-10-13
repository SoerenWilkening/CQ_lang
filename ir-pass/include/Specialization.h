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
class Function;
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

// bd `test_C_libtooling-vsfp` (P1) / bd `tzfa` (P1) — THE PHANTOM READ, RESOLVED
// (bd vsfp round 3). The observing half of `dropDeadCallArguments`
// (SpecializeDetect.h): after `specialize()`, the specializer's record
// (`isRecordedDeadSlot`: `taint.SpecDeadArgMask`, taken by `buildClone` with the
// pass's ONE liveness predicate, `DeadValueLiveness.h`) names the slots each built
// clone never reads — EXACTLY since bd vsfp round 4: `buildClone` deletes the dead
// cone of every recorded-dead parameter right after taking the record (bd sqjq;
// round 3's record left a dead-but-lowered op on the slot, which then read runtime
// handle h0 once the caller's slot was a constant, r3A F-XA-2). A call in a
// NON-clone function that passes a value in such a slot is a read only the
// compiler performs.
//
// (1) It NEUTRALISES every one: the operand becomes a null constant OF THE CALLEE
// PARAMETER'S TYPE (on a slot the drop's eligibility admits — bd `91k9`: never a
// pointer, `byval`/`byref`/`sret`/`inalloca`/`preallocated` or non-allowlisted slot;
// a QUANTUM operand in such a slot declines instead — `range`/`nofpclass` stripped; bd f061 —
// round 3 took the caller operand's fp type for an `i32` handle slot and the
// verifier aborted), so no later stage can see the phantom read. That is the fix for bd tzfa: the read did not keep the operand's rail
// ALIVE, it kept the uncompute SPINE from DISCHARGING it — an extra consumer of a
// template rail the twin uncomputes (r2B `k19`: `h1 = 3q` left dirty across a
// phase oracle, `q` fully dephased). With the read gone, the spine sees the
// hand-inlined twin's consumer set.
//
// (2) It DECLINES (`cq specialization: quantum argument to a parameter the lifted
// callee never reads`, DS_Error on the call, returns true) when a neutralised
// operand is QUANTUM (tainted, or a control-emitted rail) and the user program no
// longer reads it (every use but the DESTINATION slot of a basis copy is a read —
// bd xh17): the twin never computes such a value, and what the pass
// already built for it cannot be taken back — a 4.4 `%out` minted for the
// phantom is a which-path rail no stage uncomputes, and a dead tainted op is not
// reliably uncomputed. The one exemption is a `cq_theta` RESULT (the user's own
// register; Rule-13 r1B, nine shapes, mutant B2). "Reads" is asked positively —
// see `userProgramReads` in Specialization.cpp for the list, and for the one
// named over-decline it leaves (a `%out` read only by a later control-emitted
// compare).
//
// ⚠ WHAT IT IS NOT (L7). Not "TOTAL" (round 1): it acts on phantom reads THROUGH
// A CLONE CALL; a dead operand kept alive by something else (a dead intrinsic, a
// dead φ cycle) is the drop's (`deleteDeadCones`). And not round 2's "a value
// kept alive elsewhere adds nothing" — that exemption was accepted with the
// phantom still in the use list, which was bd tzfa. What reaches this point at
// all is a slot the CLONE's own pipeline made dead (its scoped PredMux flatten)
// that the drop could not predict from the original callee, or one a drop
// precondition refused. Clone BODIES are not scanned: every rail an inner call
// there could keep is uncomputed by the enclosing Bennett wrap.
//
// THE SLOT (both entry points): last in the post-`specialize()` decline chain,
// before `lowerRotations` (which RAUWs every `cq_theta` result to its handle), so
// the neutralisation happens before every stage that builds a consumer set.
bool resolvePhantomCloneArgReads(llvm::Module &M, const TaintSet &taint);

// bd test_C_libtooling-p3kd.13 — synthesize `<Clone>_unc`, the void Bennett twin
// (`out ^= f(args)`), with the recipe the 6.3 inner-call drain uses (`ensureTwin`).
// The caller owns every precondition: `Clone` is a wrapped ReturnTainted clone, no
// `<Clone>_unc` symbol exists, and `findUndefOperandInBody(Clone)` is null (the bd
// xy9n duplication fence). Its one caller is `materializeCloneTwins`
// (CloneProducer.h), for a top-level clone result the uncompute spine owns.
llvm::Function *synthesizeCloneUncTwin(llvm::Function &Clone);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZATION_H_
