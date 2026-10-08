// LiftedCallReads.h — the LIFTED-CALL reader family of the stale-record fence
// (bd test_C_libtooling-r2j3.6, P1 silent miscompile).
//
// A Phase-6 lifted call (`call @f(%q)` before `specialize()`, `call @__cq_q_f_<mask>`
// after it) reads its quantum arguments WHERE IT RUNS: the clone's Bennett wrap
// copies each argument register's basis label into its own rails at the call
// (Bennett.jl `lower_call!`, src/lowering/call.jl:140-147 @824458d, "Connect caller
// arguments -> callee input wires (CNOT copy)"; BennettVM.jl reads the caller's
// bindings at the call too, `_handle_call_dispatch!` in
// src/interpreter/Interpreter.jl:1568 @23d28e6, ADR 0019 Amendment A.1: an argument
// transfer is a COPY). So a lifted call is a stale reader exactly as a pure op is,
// and `declineStaleRecordOps` asks it the same question through the same policy.
//
// Before r2j3.6 nothing asked it: `int q2 = q; cq_theta(&q2, .3); r = f(q);` ran f on
// the rotated register at exit 0 (also with a QROM read in the callee, through a
// lifted one-register merge phi, and for every math.h call `tools/cqc` lifts).
//
// READER OR PURE OP? (review round 1 F1.) For POSITION a lifted call is a reader:
// its wrap copies the argument's basis label where it runs, as a measurement reads
// in place, and WireWalk.h says the dominance precondition is not what carries
// soundness (legs 1/2 do). The pure-op policy keeps it for one hazard: under TAINTED
// control a value arm is hoisted into the pred, so CFG-exclusive arms both run in an
// emitter-chosen order. That hazard is the arm's, not the opcode's, so a lifted call
// under tainted control keeps the pure-op policy (and its 01po.7 grant); off it, the
// reader policy (`classical_sibling_arm_accept` vs `reject_tainted_sibling_arms`).
// "Under tainted control" is EXACT control dependence (TaintedControlDependence.h,
// review round 2 R2-3), and because round 2 can taint a branch that was classical
// at the early sweep, it is re-asked before every detection
// (`declineTaintedArmLiftedReads`, OpcodeLowering.h, R2-2). For RAILS a lifted call
// is a pure op: its out rail is fresh, and its `_unc` twin RE-READS the arguments
// wherever the uncompute spine puts it (bd p3kd.13); that later read is the spine's
// to keep fresh, not the stale fence's.

#ifndef CQ_IRPASS_LIFTED_CALL_READS_H_
#define CQ_IRPASS_LIFTED_CALL_READS_H_

#include "llvm/ADT/SmallVector.h"

namespace llvm {
class Instruction;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct SpecPlan;
struct TaintSet;

// True iff `I` is a lifted call, with its quantum reads appended to `Reads`: every
// tainted argument except one in a slot the built clone is RECORDED never to read
// (`isRecordedDeadSlot`; `resolvePhantomCloneArgReads` neutralises those later, so
// they are not reads). Membership is asked of the two owning records, never
// re-derived: before `specialize()` the plan (`shouldSpecialize(I, *Plan)`, when
// `Plan` is given), after it the specializer's own clone record
// (`taint.SpecHandleArgMask`). With `WouldLift`, also a call detection WOULD admit
// on current taint (`isProvenSpecSite`, SpecializeDetect.h): a bd 9paa round-2
// candidate is pushed onto the plan only after round-2 detection, and the re-ask
// before that detection must see it (review round 3 R3-2). A call with no such read
// returns false.
bool liftedCallReads(const llvm::Instruction &I, const TaintSet &taint,
                     const SpecPlan *Plan,
                     llvm::SmallVectorImpl<llvm::Value *> &Reads,
                     WidthDispatch *WouldLift = nullptr);

}  // namespace cq

#endif  // CQ_IRPASS_LIFTED_CALL_READS_H_
